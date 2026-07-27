import os
import tempfile
import shutil

os.environ['DB_DIR'] = tempfile.mkdtemp()

from app import app

app.config['TESTING'] = True

with app.test_client() as client:
    resp = client.get('/api/tasks')
    assert resp.status_code == 200

    resp = client.post('/api/tasks', json={'title': 'Test'})
    assert resp.status_code == 201

    resp = client.get('/api/tasks')
    data = resp.get_json()
    assert len(data) == 1
    assert data[0]['title'] == 'Test'

print('All tests passed')
