const express = require('express');
const router  = express.Router();
const db      = require('../db');

// GET /api/produtos
router.get('/', async (req, res) => {
    const [rows] = await db.query(
        'SELECT * FROM produtos ORDER BY categoria, nome'
    );
    res.json(rows);
});

// GET /api/produtos/mais-vendidos  (deve vir antes de /:id)
router.get('/mais-vendidos', async (req, res) => {
    const [rows] = await db.query('SELECT * FROM vw_produtos_mais_vendidos');
    res.json(rows);
});

// POST /api/produtos/vender
router.post('/vender', async (req, res) => {
    const { id_sessao, id_produto, quantidade } = req.body;
    if (!id_sessao || !id_produto || !quantidade)
        return res.status(400).json({ error: 'id_sessao, id_produto e quantidade são obrigatórios.' });
    try {
        // 1. Busca preço atual do produto
        const [prod] = await db.query(
            'SELECT preco FROM produtos WHERE id_produto = ?', [id_produto]
        );
        if (prod.length === 0)
            return res.status(404).json({ error: 'Produto não encontrado.' });

        const preco_unitario = prod[0].preco;

        // 2. Insere venda (triggers trg_valida_estoque e trg_atualiza_estoque atuam automaticamente)
        await db.query(
            'INSERT INTO vendas (id_sessao, id_produto, quantidade, preco_unitario) VALUES (?, ?, ?, ?)',
            [id_sessao, id_produto, quantidade, preco_unitario]
        );

        res.json({ message: 'Venda registrada.' });
    } catch (err) {
        res.status(400).json({ error: err.message });
    }
});

module.exports = router;
