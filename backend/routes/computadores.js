const express = require('express');
const router  = express.Router();
const db      = require('../db');

// GET /api/computadores
router.get('/', async (req, res) => {
    const [rows] = await db.query('SELECT * FROM computadores ORDER BY numero');
    res.json(rows);
});

// GET /api/computadores/disponiveis
router.get('/disponiveis', async (req, res) => {
    const [rows] = await db.query(
        "SELECT * FROM computadores WHERE status = 'disponivel' ORDER BY numero"
    );
    res.json(rows);
});

// PATCH /api/computadores/:id/status
router.patch('/:id/status', async (req, res) => {
    const { status } = req.body;
    const validos = ['disponivel', 'ocupado', 'manutencao'];
    if (!validos.includes(status))
        return res.status(400).json({ error: 'Status inválido.' });
    const [result] = await db.query(
        'UPDATE computadores SET status = ? WHERE id_computador = ?',
        [status, req.params.id]
    );
    if (result.affectedRows === 0)
        return res.status(404).json({ error: 'Computador não encontrado.' });
    res.json({ message: `Status atualizado para '${status}'.` });
});

module.exports = router;
