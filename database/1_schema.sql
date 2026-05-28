-- ============================================================
--  ARENA GAMER  –  schema.sql  
--  DDL: criação do banco e das tabelas
-- ============================================================

CREATE DATABASE IF NOT EXISTS arena_gamer
  CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

USE arena_gamer;

-- ──────────────────────────────────────────────────────────────
--  TABELA: clientes
-- ──────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS clientes (
    id_cliente     INT          NOT NULL AUTO_INCREMENT,
    nome           VARCHAR(100) NOT NULL,
    email          VARCHAR(100) NOT NULL,
    telefone       VARCHAR(20),
    saldo_creditos DECIMAL(8,2) NOT NULL DEFAULT 0.00,
    data_cadastro  DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id_cliente),
    UNIQUE KEY uq_clientes_email (email)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ──────────────────────────────────────────────────────────────
--  TABELA: computadores
-- ──────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS computadores (
    id_computador INT          NOT NULL AUTO_INCREMENT,
    numero        INT          NOT NULL,
    descricao     VARCHAR(100),
    status        ENUM('disponivel','ocupado','manutencao') NOT NULL DEFAULT 'disponivel',
    valor_hora    DECIMAL(6,2) NOT NULL DEFAULT 5.00,
    PRIMARY KEY (id_computador),
    UNIQUE KEY uq_computadores_numero (numero)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ──────────────────────────────────────────────────────────────
--  TABELA: sessoes
-- ──────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS sessoes (
    id_sessao     INT          NOT NULL AUTO_INCREMENT,
    id_cliente    INT          NOT NULL,
    id_computador INT          NOT NULL,
    inicio        DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    fim           DATETIME,
    valor_total   DECIMAL(8,2),
    status        ENUM('aberta','fechada') NOT NULL DEFAULT 'aberta',
    PRIMARY KEY (id_sessao),
    CONSTRAINT fk_sessoes_cliente
        FOREIGN KEY (id_cliente)    REFERENCES clientes(id_cliente),
    CONSTRAINT fk_sessoes_computador
        FOREIGN KEY (id_computador) REFERENCES computadores(id_computador)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ──────────────────────────────────────────────────────────────
--  TABELA: produtos
-- ──────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS produtos (
    id_produto INT          NOT NULL AUTO_INCREMENT,
    nome       VARCHAR(100) NOT NULL,
    categoria  VARCHAR(50),
    preco      DECIMAL(6,2) NOT NULL,
    estoque    INT          NOT NULL DEFAULT 0,
    PRIMARY KEY (id_produto)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ──────────────────────────────────────────────────────────────
--  TABELA: vendas
-- ──────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS vendas (
    id_venda       INT          NOT NULL AUTO_INCREMENT,
    id_sessao      INT          NOT NULL,
    id_produto     INT          NOT NULL,
    quantidade     INT          NOT NULL DEFAULT 1,
    preco_unitario DECIMAL(6,2) NOT NULL,
    data_venda     DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id_venda),
    CONSTRAINT fk_vendas_sessao
        FOREIGN KEY (id_sessao)  REFERENCES sessoes(id_sessao),
    CONSTRAINT fk_vendas_produto
        FOREIGN KEY (id_produto) REFERENCES produtos(id_produto)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ──────────────────────────────────────────────────────────────
--  TABELA: auditoria_caixa
-- ──────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS auditoria_caixa (
    id_auditoria INT          NOT NULL AUTO_INCREMENT,
    tipo         ENUM('entrada','saida') NOT NULL,
    valor        DECIMAL(8,2) NOT NULL,
    descricao    VARCHAR(255),
    data_hora    DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    id_sessao    INT,
    PRIMARY KEY (id_auditoria),
    CONSTRAINT fk_auditoria_sessao
        FOREIGN KEY (id_sessao) REFERENCES sessoes(id_sessao)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
