const express = require('express');
const router  = express.Router();
const db      = require('../db');

// GET /api/clientes
router.get('/', async (req, res) => {
    const [rows] = await db.query('SELECT * FROM clientes ORDER BY nome');
    res.json(rows);
});

// GET /api/clientes/ranking  (deve vir antes de /:id)
router.get('/ranking', async (req, res) => {
    const [rows] = await db.query('SELECT * FROM vw_ranking_clientes');
    res.json(rows);
});

// GET /api/clientes/:id
router.get('/:id', async (req, res) => {
    const [rows] = await db.query(
        'SELECT * FROM clientes WHERE id_cliente = ?', [req.params.id]
    );
    if (rows.length === 0)
        return res.status(404).json({ error: 'Cliente não encontrado.' });
    res.json(rows[0]);
});

// POST /api/clientes
router.post('/', async (req, res) => {
    const { nome, email, telefone } = req.body;
    if (!nome || !email)
        return res.status(400).json({ error: 'Nome e e-mail são obrigatórios.' });
    try {
        const [result] = await db.query(
            'INSERT INTO clientes (nome, email, telefone) VALUES (?, ?, ?)',
            [nome, email, telefone || null]
        );
        res.status(201).json({ id: result.insertId, message: 'Cliente cadastrado com sucesso.' });
    } catch (err) {
        res.status(400).json({ error: err.message });
    }
});

module.exports = router;
