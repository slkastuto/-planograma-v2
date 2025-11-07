-- ===================================================================
-- Planograma v2 - schema.sql
-- ===================================================================
-- Se você estiver logado como root, pode descomentar as 3 linhas abaixo
-- para criar o DB e o usuário. Se já existem, mantenha comentado.
-- -------------------------------------------------------------------
-- CREATE DATABASE IF NOT EXISTS planograma_v2 CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
-- CREATE USER IF NOT EXISTS 'planouser'@'localhost' IDENTIFIED BY 'senhaSegura123';
-- GRANT ALL PRIVILEGES ON planograma_v2.* TO 'planouser'@'localhost';

-- Use o banco (necessário quando executado como root)
-- USE planograma_v2;

-- ===================================================================
-- TABELAS BÁSICAS
-- ===================================================================

CREATE TABLE IF NOT EXISTS lojas (
  id_loja      INT AUTO_INCREMENT PRIMARY KEY,
  nome         VARCHAR(80) NOT NULL,
  slug         VARCHAR(40) NOT NULL UNIQUE,
  ativa        TINYINT(1) NOT NULL DEFAULT 1,
  criado_em    TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS usuarios (
  id_usuario     INT AUTO_INCREMENT PRIMARY KEY,
  nome           VARCHAR(120) NOT NULL,
  email          VARCHAR(160) NOT NULL UNIQUE,
  senha_hash     VARCHAR(255) NOT NULL,
  perfil         ENUM('admin','aprovador','operador') NOT NULL DEFAULT 'operador',
  status         ENUM('pendente','aprovado','inativo') NOT NULL DEFAULT 'pendente',
  id_loja_padrao INT NULL,
  criado_em      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  atualizado_em  TIMESTAMP NULL DEFAULT NULL,
  CONSTRAINT fk_usuarios_loja_padrao
    FOREIGN KEY (id_loja_padrao) REFERENCES lojas(id_loja)
    ON UPDATE CASCADE ON DELETE SET NULL
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS usuarios_lojas (
  id_usuario INT NOT NULL,
  id_loja    INT NOT NULL,
  PRIMARY KEY (id_usuario,id_loja),
  CONSTRAINT fk_ul_usuario FOREIGN KEY (id_usuario) REFERENCES usuarios(id_usuario)
    ON UPDATE CASCADE ON DELETE CASCADE,
  CONSTRAINT fk_ul_loja FOREIGN KEY (id_loja) REFERENCES lojas(id_loja)
    ON UPDATE CASCADE ON DELETE CASCADE
) ENGINE=InnoDB;

-- Cadastros auxiliares (parametrizações)
CREATE TABLE IF NOT EXISTS ruas (
  id_rua    INT AUTO_INCREMENT PRIMARY KEY,
  id_loja   INT NOT NULL,
  nome      VARCHAR(40) NOT NULL,
  ordem     INT NULL,
  CONSTRAINT fk_rua_loja FOREIGN KEY (id_loja) REFERENCES lojas(id_loja)
    ON UPDATE CASCADE ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS setores (
  id_setor  INT AUTO_INCREMENT PRIMARY KEY,
  id_loja   INT NOT NULL,
  nome      VARCHAR(60) NOT NULL,
  CONSTRAINT fk_setor_loja FOREIGN KEY (id_loja) REFERENCES lojas(id_loja)
    ON UPDATE CASCADE ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS tipos_exposicao (
  id_tipo   INT AUTO_INCREMENT PRIMARY KEY,
  nome      VARCHAR(30) NOT NULL UNIQUE
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS tipos_preco (
  id_tipo_preco INT AUTO_INCREMENT PRIMARY KEY,
  nome          VARCHAR(40) NOT NULL UNIQUE
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS tamanhos_cartaz (
  id_tamanho INT AUTO_INCREMENT PRIMARY KEY,
  nome       VARCHAR(20) NOT NULL UNIQUE
) ENGINE=InnoDB;

-- ===================================================================
-- ESPAÇOS DE EXPOSIÇÃO (ponta/ilha/expositor/geladeira)
-- ===================================================================

CREATE TABLE IF NOT EXISTS espacos (
  id_espaco          INT AUTO_INCREMENT PRIMARY KEY,
  id_loja            INT NOT NULL,
  codigo             VARCHAR(80) NOT NULL,
  id_setor           INT NULL,
  id_rua             INT NULL,
  id_tipo_exposicao  INT NOT NULL,         -- FK tipos_exposicao
  preco_centavos     INT NULL,             -- ex: 35000 = R$ 350,00
  id_tipo_preco      INT NULL,             -- FK tipos_preco
  fornecedor         VARCHAR(120) NULL,
  precisa_cartaz     TINYINT(1) NOT NULL DEFAULT 0,
  id_tamanho_cartaz  INT NULL,             -- FK tamanhos_cartaz
  contrato_sim       TINYINT(1) NOT NULL DEFAULT 0,
  contrato_inicio    DATE NULL,
  contrato_fim       DATE NULL,
  criado_por         VARCHAR(120) NOT NULL,
  criado_em          TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  atualizado_por     VARCHAR(120) NULL,
  atualizado_em      TIMESTAMP NULL DEFAULT NULL,
  status             ENUM('ativo','inativo') NOT NULL DEFAULT 'ativo',
  CONSTRAINT fk_ep_loja   FOREIGN KEY (id_loja) REFERENCES lojas(id_loja)
    ON UPDATE CASCADE ON DELETE CASCADE,
  CONSTRAINT fk_ep_setor  FOREIGN KEY (id_setor) REFERENCES setores(id_setor)
    ON UPDATE CASCADE ON DELETE SET NULL,
  CONSTRAINT fk_ep_rua    FOREIGN KEY (id_rua) REFERENCES ruas(id_rua)
    ON UPDATE CASCADE ON DELETE SET NULL,
  CONSTRAINT fk_ep_tipo   FOREIGN KEY (id_tipo_exposicao) REFERENCES tipos_exposicao(id_tipo)
    ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT fk_ep_preco  FOREIGN KEY (id_tipo_preco)  REFERENCES tipos_preco(id_tipo_preco)
    ON UPDATE CASCADE ON DELETE SET NULL,
  CONSTRAINT fk_ep_cartaz FOREIGN KEY (id_tamanho_cartaz) REFERENCES tamanhos_cartaz(id_tamanho)
    ON UPDATE CASCADE ON DELETE SET NULL
) ENGINE=InnoDB;

CREATE INDEX idx_espacos_loja_status_codigo ON espacos(id_loja,status,codigo);

-- ===================================================================
-- PRODUTOS POR LADO (histórico de ocupações)
-- ===================================================================

CREATE TABLE IF NOT EXISTS ocupacoes (
  id_ocupacao  INT AUTO_INCREMENT PRIMARY KEY,
  id_espaco    INT NOT NULL,
  lado         ENUM('esquerda','frente','direita','unico') NOT NULL,
  cod_interno  VARCHAR(60) NULL,
  cod_ean      VARCHAR(20) NULL,
  produto      VARCHAR(200) NOT NULL,
  data_inicio  DATE NOT NULL,
  data_fim     DATE NULL,
  ativo        TINYINT(1) NOT NULL DEFAULT 1,
  criado_por   VARCHAR(120) NOT NULL,
  criado_em    TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_ocp_espaco FOREIGN KEY (id_espaco) REFERENCES espacos(id_espaco)
    ON UPDATE CASCADE ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE INDEX idx_ocp_espaco_lado_ativo ON ocupacoes(id_espaco,lado,ativo);
CREATE INDEX idx_ocp_espaco_inicio     ON ocupacoes(id_espaco,data_inicio);

CREATE TABLE IF NOT EXISTS fotos_ocupacao (
  id_foto      INT AUTO_INCREMENT PRIMARY KEY,
  id_ocupacao  INT NOT NULL,
  lado         ENUM('esquerda','frente','direita','unico') NOT NULL,
  caminho      VARCHAR(255) NOT NULL,
  criado_em    TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_foto_ocp FOREIGN KEY (id_ocupacao) REFERENCES ocupacoes(id_ocupacao)
    ON UPDATE CASCADE ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE INDEX idx_foto_ocp_lado_criado ON fotos_ocupacao(id_ocupacao,lado,criado_em);

-- ===================================================================
-- HISTÓRICO DE AÇÕES
-- ===================================================================

CREATE TABLE IF NOT EXISTS historico_alteracoes (
  id_hist     INT AUTO_INCREMENT PRIMARY KEY,
  id_espaco   INT NOT NULL,
  id_usuario  INT NULL,
  acao        VARCHAR(120) NOT NULL,
  detalhes    TEXT NULL,
  criado_em   TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_hist_espaco FOREIGN KEY (id_espaco) REFERENCES espacos(id_espaco)
    ON UPDATE CASCADE ON DELETE CASCADE,
  CONSTRAINT fk_hist_usuario FOREIGN KEY (id_usuario) REFERENCES usuarios(id_usuario)
    ON UPDATE CASCADE ON DELETE SET NULL
) ENGINE=InnoDB;

CREATE INDEX idx_hist_espaco_criado ON historico_alteracoes(id_espaco,criado_em);

-- ===================================================================
-- SEEDS (valores iniciais)
-- ===================================================================

INSERT IGNORE INTO lojas (id_loja,nome,slug,ativa) VALUES
  (7,'LOJA 7','loja7',1),
  (18,'LOJA 18','loja18',1);

INSERT IGNORE INTO tipos_exposicao (id_tipo,nome) VALUES
  (1,'ponta'),(2,'ilha'),(3,'expositor'),(4,'geladeira');

INSERT IGNORE INTO tipos_preco (id_tipo_preco,nome) VALUES
  (1,'etiqueta branca'),
  (2,'etiqueta laranja'),
  (3,'etiqueta amigo');

INSERT IGNORE INTO tamanhos_cartaz (id_tamanho,nome) VALUES
  (1,'A4'),(2,'A5'),(3,'A6');

-- Exemplos de ruas/setores (pode editar depois no painel)
INSERT IGNORE INTO ruas (id_rua,id_loja,nome,ordem) VALUES
  (1,7,'RUA 1',1),(2,7,'RUA 2',2),(3,7,'RUA 3',3),(4,7,'RUA 4',4),
  (5,18,'RUA 1',1),(6,18,'RUA 2',2);

INSERT IGNORE INTO setores (id_setor,id_loja,nome) VALUES
  (1,7,'MERCEARIA'),(2,7,'BEBIDAS'),(3,7,'LIMPEZA'),(4,7,'PERFUMARIA'),
  (5,18,'MERCEARIA'),(6,18,'BEBIDAS');

-- ===================================================================
-- TRIGGERS: normalização de lado E/F/D/U -> esquerda/frente/direita/unico
-- ===================================================================

DROP TRIGGER IF EXISTS ocupacoes_bi_normaliza_lado;
DELIMITER //
CREATE TRIGGER ocupacoes_bi_normaliza_lado
BEFORE INSERT ON ocupacoes
FOR EACH ROW
BEGIN
  IF NEW.lado IN ('E','e') THEN SET NEW.lado = 'esquerda';
  ELSEIF NEW.lado IN ('F','f') THEN SET NEW.lado = 'frente';
  ELSEIF NEW.lado IN ('D','d') THEN SET NEW.lado = 'direita';
  ELSEIF NEW.lado IN ('U','u') THEN SET NEW.lado = 'unico';
  END IF;
END//
DELIMITER ;

DROP TRIGGER IF EXISTS ocupacoes_bu_normaliza_lado;
DELIMITER //
CREATE TRIGGER ocupacoes_bu_normaliza_lado
BEFORE UPDATE ON ocupacoes
FOR EACH ROW
BEGIN
  IF NEW.lado IN ('E','e') THEN SET NEW.lado = 'esquerda';
  ELSEIF NEW.lado IN ('F','f') THEN SET NEW.lado = 'frente';
  ELSEIF NEW.lado IN ('D','d') THEN SET NEW.lado = 'direita';
  ELSEIF NEW.lado IN ('U','u') THEN SET NEW.lado = 'unico';
  END IF;
END//
DELIMITER ;

-- ===================================================================
-- ÍNDICES ÚTEIS
-- ===================================================================
CREATE INDEX idx_ruas_loja_nome    ON ruas(id_loja,nome);
CREATE INDEX idx_setores_loja_nome ON setores(id_loja,nome);

-- ===================================================================
-- FIM DO SCHEMA
-- ===================================================================

