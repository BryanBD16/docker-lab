const express = require('express');
const mysql = require('mysql2/promise');

const app = express();
app.use(express.json());

// Connection settings come from environment variables (set in docker-compose.yaml)
const pool = mysql.createPool({
  host: process.env.DB_HOST,        // "db" = the service name, NOT localhost
  port: 3306,
  user: process.env.DB_USER,
  password: process.env.DB_PASSWORD,
  database: process.env.DB_NAME,
});

// Health check: proves the backend can talk to MySQL
app.get('/api/health', async (req, res) => {
  await pool.query('SELECT 1');
  res.json({ status: 'ok' });
});

// List all tasks
app.get('/api/tasks', async (req, res) => {
  const [rows] = await pool.query('SELECT * FROM tasks ORDER BY created_at DESC');
  res.json(rows);
});

// Create a task
app.post('/api/tasks', async (req, res) => {
  const { title, description = null, priority = 'medium', due_date = null } = req.body;
  const [result] = await pool.query(
    'INSERT INTO tasks (title, description, priority, due_date) VALUES (?, ?, ?, ?)',
    [title, description, priority, due_date]
  );
  res.status(201).json({ id: result.insertId });
});

// Mark a task completed / not completed
app.put('/api/tasks/:id', async (req, res) => {
  await pool.query('UPDATE tasks SET is_completed = ? WHERE id = ?', [req.body.is_completed, req.params.id]);
  res.sendStatus(204);
});

// Delete a task
app.delete('/api/tasks/:id', async (req, res) => {
  await pool.query('DELETE FROM tasks WHERE id = ?', [req.params.id]);
  res.sendStatus(204);
});

app.listen(3000, '0.0.0.0', () => console.log('API listening on port 3000'));
// The ? placeholders make mysql2 escape the values, which protects against SQL injection. Never build SQL by joining strings together.
// npm install gives you Express 5, which catches errors thrown in async routes automatically.