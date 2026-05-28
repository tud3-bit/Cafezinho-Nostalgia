const express = require('express');
const router  = express.Router();
const db      = require('../db');

// GET /api/sessoes/ativas
router.get('/ativas', async (req, res) => {
    const [rows] = await db.query('SELECT * FROM vw_sessoes_ativas');
    res.json(rows);
});

// GET /api/sessoes/historico
router.get('/historico', async (req, res) => {
    const [rows] = await db.query(`
        SELECT s.id_sessao,
               cl.nome        AS cliente,
               co.numero      AS computador,
               s.inicio, s.fim, s.valor_total, s.status
        FROM   sessoes s
        JOIN   clientes     cl ON s.id_cliente    = cl.id_cliente
        JOIN   computadores co ON s.id_computador = co.id_computador
        ORDER  BY s.inicio DESC
        LIMIT  50
    `);
    res.json(rows);
});

// POST /api/sessoes/abrir
router.post('/abrir', async (req, res) => {
    const { id_cliente, id_computador } = req.body;
    if (!id_cliente || !id_computador)
        return res.status(400).json({ error: 'id_cliente e id_computador são obrigatórios.' });
    try {
        await db.query('CALL sp_abrir_sessao(?, ?)', [id_cliente, id_computador]);
        res.json({ message: 'Sessão aberta com sucesso.' });
    } catch (err) {
        res.status(400).json({ error: err.message });
    }
});

// POST /api/sessoes/fechar/:id
router.post('/fechar/:id', async (req, res) => {
    try {
        await db.query('CALL sp_fechar_sessao(?)', [req.params.id]);
        const [rows] = await db.query(
            'SELECT valor_total FROM sessoes WHERE id_sessao = ?', [req.params.id]
        );
        const valor_total = rows[0]?.valor_total ?? 0;
        res.json({ message: 'Sessão encerrada com sucesso.', valor_total });
    } catch (err) {
        res.status(400).json({ error: err.message });
    }
});

module.exports = router;
