"""Explicit maintenance: remove expired unreferenced assets and orphan files.

Saved projects, active jobs and source images of retained rooms are protected.
Run with --apply to delete; without it this only lists candidates.
"""
import argparse
import json
import sys
import time
from pathlib import Path
sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from app.core.config import Settings
from app.core.database import Database

parser = argparse.ArgumentParser(); parser.add_argument('--apply', action='store_true'); args = parser.parse_args()
cfg = Settings(); db = Database(cfg.data_dir)
protected = set()
for kind in ('project', 'room', 'job'):
    for record in db.all(kind):
        payload = json.dumps(record)
        for asset in db.all('image'):
            if asset['id'] in payload: protected.add(asset['id'])
cutoff = time.time() - cfg.asset_retention_days * 86400
records = {asset['id']: asset for asset in db.all('image')}
for file in (cfg.data_dir / 'images').glob('*.png'):
    asset = records.get(file.stem)
    if file.stat().st_mtime >= cutoff or file.stem in protected: continue
    print(file.name, 'delete' if args.apply else 'candidate')
    if args.apply:
        file.unlink()
        if asset:
            with db.connect() as connection: connection.execute('DELETE FROM records WHERE id=?', (asset['id'],))
