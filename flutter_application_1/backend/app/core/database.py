import json
import sqlite3
import time
import uuid
from pathlib import Path


class Database:
    def __init__(self, root: Path):
        root.mkdir(parents=True, exist_ok=True)
        self.path = root / 'sanaa.sqlite3'
        with self.connect() as db:
            db.execute('PRAGMA journal_mode=WAL')
            db.execute('CREATE TABLE IF NOT EXISTS records (id TEXT PRIMARY KEY, owner TEXT NOT NULL, kind TEXT NOT NULL, data TEXT NOT NULL, created REAL NOT NULL)')
            db.execute('CREATE INDEX IF NOT EXISTS records_owner_kind ON records(owner, kind)')

    def connect(self):
        connection = sqlite3.connect(self.path, timeout=30)
        connection.row_factory = sqlite3.Row
        return connection

    def put(self, owner, kind, data, record_id=None):
        record_id = record_id or uuid.uuid4().hex
        with self.connect() as db:
            db.execute('INSERT INTO records VALUES (?, ?, ?, ?, ?)', (record_id, owner, kind, json.dumps(data, ensure_ascii=False), time.time()))
        return self.get(record_id, owner, kind)

    def get(self, record_id, owner, kind=None):
        with self.connect() as db:
            row = db.execute('SELECT * FROM records WHERE id=? AND owner=?', (record_id, owner)).fetchone()
        if row is None or (kind is not None and row['kind'] != kind):
            from .errors import ServiceError
            raise ServiceError(404, 'not_found', 'Мэдээлэл олдсонгүй.')
        return dict(json.loads(row['data']), id=row['id'], created=row['created'])

    def update(self, record_id, owner, **values):
        # One transaction prevents a progress update from overwriting cancellation.
        with self.connect() as db:
            db.execute('BEGIN IMMEDIATE')
            row = db.execute('SELECT data FROM records WHERE id=? AND owner=?', (record_id, owner)).fetchone()
            if row is None:
                return
            data = json.loads(row['data'])
            if data.get('status') == 'cancelled' and values.get('status') != 'cancelled':
                return
            data.update(values)
            db.execute('UPDATE records SET data=? WHERE id=? AND owner=?', (json.dumps(data, ensure_ascii=False), record_id, owner))

    def list(self, owner, kind):
        with self.connect() as db:
            rows = db.execute('SELECT * FROM records WHERE owner=? AND kind=? ORDER BY created DESC', (owner, kind)).fetchall()
        return [dict(json.loads(r['data']), id=r['id'], created=r['created']) for r in rows]

    def all(self, kind):
        with self.connect() as db:
            rows = db.execute('SELECT * FROM records WHERE kind=? ORDER BY created', (kind,)).fetchall()
        return [dict(json.loads(r['data']), id=r['id'], owner=r['owner'], created=r['created']) for r in rows]
