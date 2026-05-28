-- ============================================================
--  ARENA GAMER  –  otimizacao.sql  (VERSÃO CORRIGIDA)
--  EXPLAIN, ANALYZE e INDEX estratégico
-- ============================================================

USE arena_gamer;

-- ── 1. Diagnóstico ANTES de criar índices
EXPLAIN
SELECT s.id_sessao, cl.nome, co.numero, s.valor_total
FROM   sessoes s
JOIN   clientes     cl ON s.id_cliente    = cl.id_cliente
JOIN   computadores co ON s.id_computador = co.id_computador
WHERE  s.status = 'fechada'
ORDER  BY s.valor_total DESC;

-- ── 2. Criação dos índices estratégicos

-- a. Filtramos sessões pelo status com frequência
CREATE INDEX idx_sessoes_status
    ON sessoes (status);

-- b. JOIN sessoes → clientes
CREATE INDEX idx_sessoes_id_cliente
    ON sessoes (id_cliente);

-- c. JOIN sessoes → computadores
CREATE INDEX idx_sessoes_id_computador
    ON sessoes (id_computador);

-- d. Pesquisa de cliente por e-mail (login futuro)
--    Obs: email já é UNIQUE KEY (uq_clientes_email), portanto este índice
--    já existe implicitamente. A linha abaixo é mantida como documentação.
-- CREATE INDEX IF NOT EXISTS idx_clientes_email ON clientes (email);

-- ── 3. Diagnóstico APÓS criar índices – comparar com resultado anterior
EXPLAIN
SELECT s.id_sessao, cl.nome, co.numero, s.valor_total
FROM   sessoes s
JOIN   clientes     cl ON s.id_cliente    = cl.id_cliente
JOIN   computadores co ON s.id_computador = co.id_computador
WHERE  s.status = 'fechada'
ORDER  BY s.valor_total DESC;

-- ── 4. EXPLAIN FORMAT=JSON – versão detalhada (MySQL 8+)
EXPLAIN FORMAT=JSON
SELECT cl.nome, COUNT(*) AS sessoes, SUM(s.valor_total) AS total
FROM   clientes cl
JOIN   sessoes s ON cl.id_cliente = s.id_cliente
WHERE  s.status = 'fechada'
GROUP  BY cl.id_cliente
HAVING total > 30
ORDER  BY total DESC;

-- ── 5. Query com subquery correlacionada
EXPLAIN
SELECT cl.nome,
       SUM(s.valor_total)                     AS total_gasto,
       (SELECT AVG(valor_total) FROM sessoes
        WHERE  status = 'fechada')             AS media_geral
FROM   clientes cl
JOIN   sessoes  s ON cl.id_cliente = s.id_cliente AND s.status = 'fechada'
GROUP  BY cl.id_cliente, cl.nome
HAVING total_gasto > (SELECT AVG(valor_total) FROM sessoes WHERE status = 'fechada')
ORDER  BY total_gasto DESC;

-- ── 6. Ver todos os índices do banco
SELECT TABLE_NAME, INDEX_NAME, COLUMN_NAME, NON_UNIQUE
FROM   INFORMATION_SCHEMA.STATISTICS
WHERE  TABLE_SCHEMA = 'arena_gamer'
ORDER  BY TABLE_NAME, INDEX_NAME;
