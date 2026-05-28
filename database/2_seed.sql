-- ============================================================
--  ARENA GAMER  /  seed.sql  (VERSÃO CORRIGIDA)
--  Dados iniciais para desenvolvimento e testes
--  Execute APÓS schema.sql
-- ============================================================

USE arena_gamer;

-- ──────────────────────────────────────────────────────────────
--  COMPUTADORES (6 máquinas com perfis variados)
-- ──────────────────────────────────────────────────────────────
INSERT INTO computadores (numero, descricao, valor_hora) VALUES
(1, 'PC Gamer RTX 4070',        9.00),
(2, 'PC Gamer RTX 4060',        8.00),
(3, 'PC Gamer RX 7600',         7.50),
(4, 'PC Standard Core i5',      5.00),
(5, 'PC Standard Core i5',      5.00),
(6, 'PC XUXA STANDART / RTX 4090', 12.00);

-- ──────────────────────────────────────────────────────────────
--  CLIENTES (5 clientes)
-- ──────────────────────────────────────────────────────────────
INSERT INTO clientes (nome, email, telefone, saldo_creditos) VALUES
('Hiago Tude',  'naodenemagua@email.com',   '(81) 99111-2222', 30.00),
('Emmanuelle Geraldo',       'patroa@email.com',     '(81) 98222-3333',  0.00),
('Matheus Papai',      'uberpracomprarfralda@email.com',   '(81) 97333-4444', 15.00),
('Victor Xavier',   'euabalopontocom@email.com', '(81) 96444-5555',  0.00),
('Andressa Sorriso', 'sorrisofroxo@email.com',  '(81) 95555-6666', 50.00);

-- ──────────────────────────────────────────────────────────────
--  PRODUTOS (bebidas, snacks, lanches, acessórios)
-- ──────────────────────────────────────────────────────────────
INSERT INTO produtos (nome, categoria, preco, estoque) VALUES
('Coca-Cola Lata',       'Bebidas',    6.00,  40),
('Red Bull 250ml',       'Bebidas',   12.00,  20),
('Agua Mineral 500ml',   'Bebidas',    3.00,  60),
('Salgadinho Doritos',   'Snacks',     5.00,  30),
('Barra de Chocolate',   'Snacks',     4.50,  25),
('X-Burguer',            'Lanches',   18.00,  15),
('Misto Quente',         'Lanches',   10.00,  20),
('Mouse Pad Extra',      'Acessorios', 8.00,  10),
('Headset Emprestado',   'Acessorios', 5.00,   8),
('Combo Gamer (lanche + bebida)', 'Combos', 22.00, 12);

-- ──────────────────────────────────────────────────────────────
--  SESSÕES HISTÓRICAS (status = 'fechada')
--  Inserção direta — não usa stored procedures
-- ──────────────────────────────────────────────────────────────
INSERT INTO sessoes (id_cliente, id_computador, inicio, fim, valor_total, status) VALUES
(1, 1, '2026-04-20 14:00:00', '2026-04-20 16:30:00', 22.50, 'fechada'),
(2, 3, '2026-04-21 10:00:00', '2026-04-21 12:00:00', 15.00, 'fechada'),
(3, 4, '2026-04-22 09:00:00', '2026-04-22 11:30:00', 12.50, 'fechada'),
(4, 6, '2026-04-23 15:00:00', '2026-04-23 18:00:00', 36.00, 'fechada'),
(5, 2, '2026-04-24 13:00:00', '2026-04-24 15:00:00', 16.00, 'fechada'),
(1, 5, '2026-04-25 18:00:00', '2026-04-25 20:30:00', 12.50, 'fechada'),
(3, 6, '2026-04-26 11:00:00', '2026-04-26 14:00:00', 36.00, 'fechada'),
(2, 1, '2026-04-27 16:00:00', '2026-04-27 17:30:00', 13.50, 'fechada');

-- ──────────────────────────────────────────────────────────────
--  VENDAS (vinculadas às sessões históricas)
-- ──────────────────────────────────────────────────────────────
INSERT INTO vendas (id_sessao, id_produto, quantidade, preco_unitario, data_venda) VALUES
(1, 1, 2,  6.00, '2026-04-20 14:30:00'),
(1, 4, 1,  5.00, '2026-04-20 15:00:00'),
(2, 2, 1, 12.00, '2026-04-21 10:45:00'),
(2, 5, 1,  4.50, '2026-04-21 11:00:00'),
(3, 3, 2,  3.00, '2026-04-22 09:30:00'),
(4, 6, 1, 18.00, '2026-04-23 16:00:00'),
(4, 1, 2,  6.00, '2026-04-23 17:00:00'),
(5, 7, 1, 10.00, '2026-04-24 13:30:00'),
(6, 2, 1, 12.00, '2026-04-25 19:00:00'),
(7, 10,1, 22.00, '2026-04-26 12:00:00'),
(8, 4, 2,  5.00, '2026-04-27 16:30:00');

-- Ajusta estoque para refletir as vendas do seed (já que triggers só atuam em INSERTs futuros)
UPDATE produtos SET estoque = estoque - 2 WHERE id_produto = 1;  -- Coca-Cola: -4 total
UPDATE produtos SET estoque = estoque - 1 WHERE id_produto = 2;  -- Red Bull: -3 total
UPDATE produtos SET estoque = estoque - 2 WHERE id_produto = 3;  -- Água: -2 total
UPDATE produtos SET estoque = estoque - 1 WHERE id_produto = 4;  -- Doritos: -3 total
UPDATE produtos SET estoque = estoque - 1 WHERE id_produto = 5;  -- Chocolate: -1
UPDATE produtos SET estoque = estoque - 1 WHERE id_produto = 6;  -- X-Burguer: -1
UPDATE produtos SET estoque = estoque - 1 WHERE id_produto = 7;  -- Misto: -1
UPDATE produtos SET estoque = estoque - 1 WHERE id_produto = 10; -- Combo: -1

-- ──────────────────────────────────────────────────────────────
--  AUDITORIA_CAIXA (lançamentos correspondentes às sessões históricas)
-- ──────────────────────────────────────────────────────────────
INSERT INTO auditoria_caixa (tipo, valor, descricao, data_hora, id_sessao) VALUES
('entrada', 22.50, 'Sessao #1 encerrada / cliente 1', '2026-04-20 16:30:00', 1),
('entrada', 15.00, 'Sessao #2 encerrada / cliente 2', '2026-04-21 12:00:00', 2),
('entrada', 12.50, 'Sessao #3 encerrada / cliente 3', '2026-04-22 11:30:00', 3),
('entrada', 36.00, 'Sessao #4 encerrada / cliente 4', '2026-04-23 18:00:00', 4),
('entrada', 16.00, 'Sessao #5 encerrada / cliente 5', '2026-04-24 15:00:00', 5),
('entrada', 12.50, 'Sessao #6 encerrada / cliente 1', '2026-04-25 20:30:00', 6),
('entrada', 36.00, 'Sessao #7 encerrada / cliente 3', '2026-04-26 14:00:00', 7),
('entrada', 13.50, 'Sessao #8 encerrada / cliente 2', '2026-04-27 17:30:00', 8),
('saida',    80.00, 'Reposicao de estoque / bebidas e snacks', '2026-04-28 09:00:00', NULL);
