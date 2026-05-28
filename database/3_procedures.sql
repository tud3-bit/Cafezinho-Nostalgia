-- ============================================================
--  ARENA GAMER  –  procedures.sql  (VERSÃO CORRIGIDA)
--  Functions, Stored Procedures, Triggers e Views
--  Execute APÓS schema.sql e seed.sql
-- ============================================================

USE arena_gamer;

DELIMITER //

-- ──────────────────────────────────────────────────────────────
--  FUNCTIONS
-- ──────────────────────────────────────────────────────────────

-- fn_duracao_minutos: retorna diferença em minutos entre dois DATETIME
CREATE FUNCTION IF NOT EXISTS fn_duracao_minutos(
    p_inicio DATETIME,
    p_fim    DATETIME
)
RETURNS INT
DETERMINISTIC
BEGIN
    RETURN TIMESTAMPDIFF(MINUTE, p_inicio, p_fim);
END //

-- fn_calcular_valor: calcula o valor proporcional por minuto e arredonda para 2 casas
CREATE FUNCTION IF NOT EXISTS fn_calcular_valor(
    p_inicio     DATETIME,
    p_fim        DATETIME,
    p_valor_hora DECIMAL(6,2)
)
RETURNS DECIMAL(8,2)
DETERMINISTIC
BEGIN
    DECLARE v_minutos INT;
    SET v_minutos = fn_duracao_minutos(p_inicio, p_fim);
    RETURN ROUND((v_minutos / 60.0) * p_valor_hora, 2);
END //

-- ──────────────────────────────────────────────────────────────
--  STORED PROCEDURES
-- ──────────────────────────────────────────────────────────────

-- sp_abrir_sessao: valida disponibilidade e abre sessão em transação
CREATE PROCEDURE IF NOT EXISTS sp_abrir_sessao(
    IN p_id_cliente    INT,
    IN p_id_computador INT
)
BEGIN
    DECLARE v_status VARCHAR(20);

    -- 1. Verifica se o computador existe e está disponível
    SELECT status INTO v_status
    FROM computadores
    WHERE id_computador = p_id_computador;

    IF v_status IS NULL THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Computador não encontrado.';
    END IF;

    IF v_status <> 'disponivel' THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Computador nao esta disponivel.';
    END IF;

    -- 2. Abre transação, insere sessão e marca computador como ocupado
    START TRANSACTION;
        INSERT INTO sessoes (id_cliente, id_computador)
        VALUES (p_id_cliente, p_id_computador);

        UPDATE computadores
        SET    status = 'ocupado'
        WHERE  id_computador = p_id_computador;
    COMMIT;
END //

-- sp_fechar_sessao: calcula valor (uso + produtos), fecha sessão em transação
CREATE PROCEDURE IF NOT EXISTS sp_fechar_sessao(
    IN p_id_sessao INT
)
BEGIN
    DECLARE v_inicio        DATETIME;
    DECLARE v_id_computador INT;
    DECLARE v_valor_hora    DECIMAL(6,2);
    DECLARE v_valor_uso     DECIMAL(8,2);
    DECLARE v_valor_vendas  DECIMAL(8,2);
    DECLARE v_valor_total   DECIMAL(8,2);

    -- 1. Busca dados da sessão aberta
    SELECT s.inicio, s.id_computador, c.valor_hora
    INTO   v_inicio, v_id_computador, v_valor_hora
    FROM   sessoes s
    JOIN   computadores c ON s.id_computador = c.id_computador
    WHERE  s.id_sessao = p_id_sessao
      AND  s.status    = 'aberta';

    IF v_inicio IS NULL THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Sessão não encontrada ou já encerrada.';
    END IF;

    -- 2. Calcula valor do tempo de uso
    SET v_valor_uso = fn_calcular_valor(v_inicio, NOW(), v_valor_hora);

    -- 3. Soma total de vendas na sessão (COALESCE garante 0 se não houver)
    SELECT COALESCE(SUM(quantidade * preco_unitario), 0)
    INTO   v_valor_vendas
    FROM   vendas
    WHERE  id_sessao = p_id_sessao;

    -- 4. Total geral
    SET v_valor_total = v_valor_uso + v_valor_vendas;

    -- 5. Fecha sessão e libera computador em transação
    START TRANSACTION;
        UPDATE sessoes
        SET    fim         = NOW(),
               valor_total = v_valor_total,
               status      = 'fechada'
        WHERE  id_sessao = p_id_sessao;

        UPDATE computadores
        SET    status = 'disponivel'
        WHERE  id_computador = v_id_computador;
    COMMIT;
END //

-- ──────────────────────────────────────────────────────────────
--  TRIGGERS
-- ──────────────────────────────────────────────────────────────

-- trg_auditoria_sessao: registra entrada no caixa ao fechar sessão
CREATE TRIGGER IF NOT EXISTS trg_auditoria_sessao
AFTER UPDATE ON sessoes
FOR EACH ROW
BEGIN
    IF OLD.status = 'aberta' AND NEW.status = 'fechada' THEN
        INSERT INTO auditoria_caixa (tipo, valor, descricao, id_sessao)
        VALUES (
            'entrada',
            NEW.valor_total,
            CONCAT('Sessão #', NEW.id_sessao, ' encerrada – cliente ', NEW.id_cliente),
            NEW.id_sessao
        );
    END IF;
END //

-- trg_valida_estoque: bloqueia venda se estoque insuficiente (BEFORE INSERT)
CREATE TRIGGER IF NOT EXISTS trg_valida_estoque
BEFORE INSERT ON vendas
FOR EACH ROW
BEGIN
    DECLARE v_estoque INT;

    SELECT estoque INTO v_estoque
    FROM   produtos
    WHERE  id_produto = NEW.id_produto;

    IF v_estoque < NEW.quantidade THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Estoque insuficiente para a venda.';
    END IF;
END //

-- trg_atualiza_estoque: decrementa estoque após registrar venda (AFTER INSERT)
CREATE TRIGGER IF NOT EXISTS trg_atualiza_estoque
AFTER INSERT ON vendas
FOR EACH ROW
BEGIN
    UPDATE produtos
    SET    estoque = estoque - NEW.quantidade
    WHERE  id_produto = NEW.id_produto;
END //

DELIMITER ;

-- ──────────────────────────────────────────────────────────────
--  VIEWS
-- ──────────────────────────────────────────────────────────────

-- vw_sessoes_ativas: sessões abertas com tempo e valor parcial calculados
CREATE OR REPLACE VIEW vw_sessoes_ativas AS
SELECT
    s.id_sessao,
    cl.nome                                                       AS cliente,
    co.numero                                                     AS computador,
    co.descricao                                                  AS descricao_computador,
    s.inicio,
    TIMESTAMPDIFF(MINUTE, s.inicio, NOW())                        AS minutos_em_uso,
    ROUND((TIMESTAMPDIFF(MINUTE, s.inicio, NOW()) / 60.0) * co.valor_hora, 2) AS valor_parcial
FROM   sessoes s
JOIN   clientes     cl ON s.id_cliente    = cl.id_cliente
JOIN   computadores co ON s.id_computador = co.id_computador
WHERE  s.status = 'aberta';

-- vw_ranking_clientes: clientes ranqueados pelo total gasto em sessões fechadas
CREATE OR REPLACE VIEW vw_ranking_clientes AS
SELECT
    cl.id_cliente,
    cl.nome,
    COUNT(s.id_sessao)               AS total_sessoes,
    COALESCE(SUM(s.valor_total), 0)  AS total_gasto,
    COALESCE(AVG(s.valor_total), 0)  AS gasto_medio
FROM  clientes cl
LEFT JOIN sessoes s
    ON cl.id_cliente = s.id_cliente
   AND s.status = 'fechada'
GROUP BY cl.id_cliente, cl.nome
ORDER BY total_gasto DESC;

-- vw_produtos_mais_vendidos: produtos ranqueados pela quantidade vendida
CREATE OR REPLACE VIEW vw_produtos_mais_vendidos AS
SELECT
    p.nome,
    p.categoria,
    COALESCE(SUM(v.quantidade), 0)                   AS total_vendido,
    COALESCE(SUM(v.quantidade * v.preco_unitario), 0) AS receita_total
FROM  produtos p
LEFT JOIN vendas v ON p.id_produto = v.id_produto
GROUP BY p.id_produto, p.nome, p.categoria
ORDER BY total_vendido DESC;
