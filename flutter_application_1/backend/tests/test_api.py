import hashlib
import io
import json
import pytest
from PIL import Image
from fastapi.testclient import TestClient
from app.main import create_app
from app.core.config import Settings


@pytest.fixture
def api(tmp_path):
    settings = Settings(data_dir=tmp_path, api_tokens='test-owner,test-other', segmentation_enabled=False, removal_enabled=False, generation_enabled=False, _env_file=None)
    app = create_app(settings)
    with TestClient(app) as client:
        client.headers['Authorization'] = 'Bearer test-owner'
        yield client, app, settings


def png(size=(96, 64), value='white', mode='RGB'):
    stream = io.BytesIO()
    Image.new(mode, size, value).save(stream, 'PNG')
    return stream.getvalue()


def upload(client):
    response = client.post('/api/rooms', files={'file': ('room.png', png(), 'image/png')})
    assert response.status_code == 201
    return response.json()


def test_health_is_honest_and_does_not_need_auth(api):
    client, _, _ = api
    result = client.get('/health').json()
    assert result['status'] == 'ok'
    assert result['capabilities']['generation'] is False
    assert result['capabilities']['inference_verified'] is False


def test_upload_decodes_and_strips_metadata(api):
    client, _, _ = api
    room = upload(client)
    assert room['image']['width'] == 96
    assert room['quality']['geometry_detected'] is False
    result = client.get('/api/images/' + room['image']['id'])
    assert result.status_code == 200
    assert Image.open(io.BytesIO(result.content)).size == (96, 64)


def test_corrupt_file_rejected_and_no_generic_photo_returned(api):
    client, _, _ = api
    result = client.post('/api/rooms', files={'file': ('fake.jpg', b'not-an-image', 'image/jpeg')})
    assert result.status_code == 422
    assert result.json()['error']['code'] == 'invalid_image'


def test_owner_authorization_and_cross_tenant_isolation(api):
    client, _, _ = api
    room = upload(client)
    url = '/api/images/' + room['image']['id']
    assert client.get(url, headers={'Authorization': 'Bearer test-other'}).status_code == 404
    assert client.get(url, headers={'Authorization': 'Bearer wrong'}).status_code == 401
    assert client.get('/api/images/../../outside').status_code == 404


def test_manual_mask_is_real_aligned_and_has_transparent_overlay(api):
    client, app, _ = api
    room = upload(client)
    result = client.post('/api/masks', data={'room_id': room['room_id'], 'image_id': room['image']['id']}, files={'file': ('mask.png', png(value=255, mode='L'), 'image/png')})
    assert result.status_code == 201
    mask = result.json()
    assert mask['metadata']['method'] == 'manual'
    result = client.get(f"/api/images/{mask['id']}?overlay=true")
    overlay = Image.open(io.BytesIO(result.content))
    assert overlay.size == (96, 64)
    assert overlay.mode == 'RGBA'
    assert 0 < overlay.getpixel((0, 0))[3] < 255


def test_empty_and_wrong_size_masks_rejected(api):
    client, _, _ = api
    room = upload(client)
    fields = {'room_id': room['room_id'], 'image_id': room['image']['id']}
    assert client.post('/api/masks', data=fields, files={'file': ('mask.png', png(value=0, mode='L'))}).status_code == 422
    assert client.post('/api/masks', data=fields, files={'file': ('mask.png', png(size=(2, 2), value=255, mode='L'))}).status_code == 422


def test_segmentation_unavailable_is_not_a_rectangle(api):
    client, _, _ = api
    room = upload(client)
    result = client.post('/api/segment', json={'room_id': room['room_id'], 'point': [10, 10]})
    assert result.status_code == 503
    assert result.json()['error']['code'] == 'segmentation_unavailable'
    assert client.post('/api/segment', json={'room_id': room['room_id'], 'point': [-1, 5]}).status_code == 422


def test_missing_generation_checkpoint_returns_service_unavailable(api):
    client, _, _ = api
    room = upload(client)
    result = client.post('/api/generate', json={'room_id': room['room_id'], 'prompt': 'A warm minimalist living room'})
    assert result.status_code == 503
    assert result.json()['error']['code'] == 'generation_unavailable'


def test_budget_and_prompt_validation(api):
    client, _, _ = api
    room = upload(client)
    assert client.post('/api/generate', json={'room_id': room['room_id'], 'prompt': 'x', 'budget': -5}).status_code == 422


def test_jobs_persist_and_cancel_without_fake_completion(api):
    client, app, settings = api
    owner = hashlib.sha256(b'test-owner').hexdigest()
    job = app.state.db.put(owner, 'job', {'status': 'queued', 'request': {}, 'progress': None})
    assert client.post(f"/api/jobs/{job['id']}/cancel").json()['status'] == 'cancelled'
    app.state.db.update(job['id'], owner, status='completed', progress=1)
    other_app = create_app(settings)
    assert other_app.state.db.get(job['id'], owner, 'job')['status'] == 'cancelled'


def test_project_cannot_be_saved_from_unfinished_job(api):
    client, app, _ = api
    owner = hashlib.sha256(b'test-owner').hexdigest()
    job = app.state.db.put(owner, 'job', {'status': 'failed', 'output_image_id': None})
    result = client.post('/api/projects', json={'job_id': job['id'], 'name': 'Test'})
    assert result.status_code == 409


def test_mask_cannot_cross_rooms_or_source_revisions(api):
    client, app, _ = api
    first, second = upload(client), upload(client)
    mask = client.post('/api/masks', data={'room_id': first['room_id'], 'image_id': first['image']['id']}, files={'file': ('mask.png', png(value=255, mode='L'))}).json()
    result = client.post('/api/remove-furniture', json={'room_id': second['room_id'], 'mask_ids': [mask['id']]})
    assert result.status_code == 422


def test_size_limit_before_image_processing(api):
    client, _, settings = api
    response = client.post('/api/rooms', content=b'x', headers={'Content-Length': str(settings.max_upload_bytes + 2 * 1024 * 1024)})
    assert response.status_code == 413


def test_missing_inpainting_model_does_not_modify_source(api):
    client, _, _ = api
    room = upload(client)
    source_url = '/api/images/' + room['image']['id']
    before = client.get(source_url).content
    mask = client.post('/api/masks', data={'room_id': room['room_id'], 'image_id': room['image']['id']}, files={'file': ('mask.png', png(value=255, mode='L'))}).json()
    result = client.post('/api/remove-furniture', json={'room_id': room['room_id'], 'mask_ids': [mask['id']]})
    assert result.status_code == 503
    assert result.json()['error']['code'] == 'removal_unavailable'
    assert client.get(source_url).content == before


def test_project_storage_contract_with_explicit_fixture_not_ai_inference(api):
    # Seeded storage fixture only. This does NOT test or claim successful AI inference.
    client, app, settings = api
    room = upload(client)
    owner = hashlib.sha256(b'test-owner').hexdigest()
    fixture = app.state.images.save(owner, Image.new('RGB', (96, 64), 'blue'), 'generated', room['room_id'], {'test_fixture_not_inferred': True})
    request = {'room_id': room['room_id'], 'image_id': room['image']['id'], 'room_type': 'living', 'style': 'classic', 'palette': 'sage', 'budget': 3000000, 'prompt': 'Storage fixture only, not an AI result', 'seed': 42, 'mask_ids': []}
    job = app.state.db.put(owner, 'job', {'status': 'completed', 'request': request, 'output_image_id': fixture['id'], 'parameters': {'test_fixture_not_inferred': True}})
    response = client.post('/api/projects', json={'job_id': job['id'], 'name': 'Storage contract fixture'})
    assert response.status_code == 201
    project = response.json()
    assert project['source_image_id'] == room['image']['id']
    assert project['preferences']['budget'] == 3000000
    assert client.get('/api/projects/' + project['id']).json()['id'] == project['id']
    assert client.get('/api/projects/' + project['id'], headers={'Authorization': 'Bearer test-other'}).status_code == 404
    assert create_app(settings).state.db.get(project['id'], owner, 'project')['output_image_id'] == fixture['id']
