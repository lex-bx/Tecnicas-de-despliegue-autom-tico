from flask import Flask, render_template, request, redirect, url_for, jsonify
import sqlite3
import os

app = Flask(__name__)

DB_DIR = os.environ.get('DB_DIR', os.path.dirname(os.path.abspath(__file__)))
DB_PATH = os.path.join(DB_DIR, 'database.db')

def init_db():
    conn = sqlite3.connect(DB_PATH)
    conn.execute('PRAGMA journal_mode=WAL')
    conn.execute('PRAGMA busy_timeout=5000')
    c = conn.cursor()
    c.execute('''
        CREATE TABLE IF NOT EXISTS tasks (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT NOT NULL,
            description TEXT DEFAULT '',
            completed INTEGER DEFAULT 0,
            created_at TEXT DEFAULT CURRENT_TIMESTAMP
        )
    ''')
    conn.commit()
    conn.close()

init_db()

def get_db():
    conn = sqlite3.connect(DB_PATH)
    conn.row_factory = sqlite3.Row
    return conn

@app.route('/health')
def health():
    conn = get_db()
    journal_mode = conn.execute('PRAGMA journal_mode').fetchone()[0]
    busy_timeout = conn.execute('PRAGMA busy_timeout').fetchone()[0]
    conn.close()
    return jsonify({
        'status': 'ok',
        'database': DB_PATH,
        'journal_mode': journal_mode,
        'busy_timeout_ms': busy_timeout,
        'wal_enabled': journal_mode == 'wal'
    })

@app.route('/')
def index():
    conn = get_db()
    tasks = conn.execute('SELECT * FROM tasks ORDER BY created_at DESC').fetchall()
    conn.close()
    return render_template('index.html', tasks=tasks)

@app.route('/api/tasks', methods=['GET'])
def get_tasks():
    conn = get_db()
    tasks = [dict(row) for row in conn.execute('SELECT * FROM tasks ORDER BY created_at DESC').fetchall()]
    conn.close()
    return jsonify(tasks)

@app.route('/api/tasks', methods=['POST'])
def create_task():
    data = request.get_json()
    if not data or not data.get('title'):
        return jsonify({'error': 'Title is required'}), 400
    conn = get_db()
    conn.execute(
        'INSERT INTO tasks (title, description) VALUES (?, ?)',
        (data['title'], data.get('description', ''))
    )
    conn.commit()
    conn.close()
    return jsonify({'message': 'Task created'}), 201

@app.route('/api/tasks/<int:task_id>', methods=['PUT'])
def update_task(task_id):
    data = request.get_json()
    conn = get_db()
    task = conn.execute('SELECT * FROM tasks WHERE id = ?', (task_id,)).fetchone()
    if not task:
        conn.close()
        return jsonify({'error': 'Task not found'}), 404
    fields = []
    values = []
    if 'completed' in data:
        fields.append('completed = ?')
        values.append(data['completed'])
    if 'title' in data:
        fields.append('title = ?')
        values.append(data['title'])
    if 'description' in data:
        fields.append('description = ?')
        values.append(data['description'])
    if not fields:
        conn.close()
        return jsonify({'error': 'No fields to update'}), 400
    values.append(task_id)
    conn.execute(f'UPDATE tasks SET {", ".join(fields)} WHERE id = ?', values)
    conn.commit()
    conn.close()
    return jsonify({'message': 'Task updated'})

@app.route('/api/tasks/<int:task_id>', methods=['DELETE'])
def delete_task(task_id):
    conn = get_db()
    conn.execute('DELETE FROM tasks WHERE id = ?', (task_id,))
    conn.commit()
    conn.close()
    return jsonify({'message': 'Task deleted'})

@app.route('/add', methods=['POST'])
def add_task():
    title = request.form.get('title', '').strip()
    description = request.form.get('description', '').strip()
    if title:
        conn = get_db()
        conn.execute('INSERT INTO tasks (title, description) VALUES (?, ?)', (title, description))
        conn.commit()
        conn.close()
    return redirect(url_for('index'))

@app.route('/complete/<int:task_id>')
def complete_task(task_id):
    conn = get_db()
    conn.execute('UPDATE tasks SET completed = 1 WHERE id = ?', (task_id,))
    conn.commit()
    conn.close()
    return redirect(url_for('index'))

@app.route('/delete/<int:task_id>')
def delete_task_web(task_id):
    conn = get_db()
    conn.execute('DELETE FROM tasks WHERE id = ?', (task_id,))
    conn.commit()
    conn.close()
    return redirect(url_for('index'))

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=True)
