const express = require('express');
const router  = express.Router();
const db      = require('../db');

// GET /api/caixa
router.get('/', async (req, res) => {
    const [rows] = await db.query(
        'SELECT id_auditoria, tipo, valor, descricao, data_hora FROM auditoria_caixa ORDER BY data_hora DESC LIMIT 100'
    );
    res.json(rows);
});

// GET /api/caixa/resumo
router.get('/resumo', async (req, res) => {
    const [rows] = await db.query(
        'SELECT tipo, COUNT(*) AS quantidade, SUM(valor) AS total FROM auditoria_caixa GROUP BY tipo'
    );
    res.json(rows);
});

module.exports = router;
