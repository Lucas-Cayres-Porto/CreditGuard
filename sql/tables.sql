CREATE TABLE Endereco (
    id_endereco SERIAL PRIMARY KEY,
    cep VARCHAR(9) NOT NULL,
    rua VARCHAR(150) NOT NULL,
    numero VARCHAR(10) NOT NULL,
    complemento VARCHAR(100),
    bairro VARCHAR(100) NOT NULL,
    cidade VARCHAR(100) NOT NULL,
    estado CHAR(2) NOT NULL
);

CREATE TABLE Cliente (
    id_cliente SERIAL PRIMARY KEY,
    nome_cliente VARCHAR(150) NOT NULL,
    cpf CHAR(11) NOT NULL UNIQUE,
    telefone VARCHAR(15),
    email VARCHAR(150) UNIQUE,
    score  NUMERIC(15,2) DEFAULT 0.00,
    id_endereco INT,

    CONSTRAINT fk_cliente_endereco
        FOREIGN KEY (id_endereco)
        REFERENCES Endereco(id_endereco)
);

CREATE TABLE Conta (
    id_conta SERIAL PRIMARY KEY,
    numero_conta VARCHAR(20) NOT NULL UNIQUE,
    tipo_conta VARCHAR(30) NOT NULL,
    saldo NUMERIC(15,2) DEFAULT 0.00,
    data_abertura TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    status VARCHAR(20) DEFAULT 'ATIVA',
    senha VARCHAR(15),
    id_cliente INT NOT NULL,

    CONSTRAINT fk_conta_cliente
        FOREIGN KEY (id_cliente)
        REFERENCES Cliente(id_cliente)
        ON DELETE CASCADE
);

CREATE TABLE Cartao (
    id_cartao SERIAL PRIMARY KEY,
    numero_cartao VARCHAR(16) NOT NULL UNIQUE,
    validade DATE NOT NULL,
    cvv CHAR(3) NOT NULL,
    tipo_cartao VARCHAR(20) NOT NULL,
    status VARCHAR(20) DEFAULT 'ATIVO',
    id_conta INT NOT NULL,
    senha VARCHAR(15),
    limite_cartao NUMERIC(15,2) DEFAULT 0.00,

    CONSTRAINT fk_cartao_conta
        FOREIGN KEY (id_conta)
        REFERENCES Conta(id_conta)
        ON DELETE CASCADE
);

CREATE TABLE Transacao (
    id_transacao SERIAL PRIMARY KEY,
    valor NUMERIC(15,2) NOT NULL,
    tipo_transacao VARCHAR(50) NOT NULL,
    descricao TEXT,
    data_transacao TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    id_conta INT NOT NULL,
    id_cartao INT,
    status VARCHAR(20) DEFAULT 'INVALIDO',

    CONSTRAINT fk_transacao_conta
        FOREIGN KEY (id_conta)
        REFERENCES Conta(id_conta),

    CONSTRAINT fk_transacao_cartao
        FOREIGN KEY (id_cartao)
        REFERENCES Cartao(id_cartao)
);

CREATE TABLE Emprestimo (
    id_emprestimo SERIAL PRIMARY KEY,
    valor_total NUMERIC(15,2) NOT NULL,
    taxa_juros NUMERIC(5,2) NOT NULL,
    quantidade_parcelas INT NOT NULL,
    data_contratacao DATE DEFAULT CURRENT_DATE,
    status VARCHAR(20) DEFAULT 'PENDENTE',
    id_conta INT NOT NULL,

    CONSTRAINT fk_emprestimo_conta
        FOREIGN KEY (id_conta)
        REFERENCES Conta(id_conta)
);

-- TABELAS DE LOG

CREATE TABLE log_emprestimo (
    id_log SERIAL PRIMARY KEY,
    id_emprestimo INT NOT NULL,
    id_conta INT NOT NULL,
    valor_total NUMERIC(15,2),
    taxa_juros NUMERIC(5,2),
    quantidade_parcelas INT,
    data_contratacao DATE,
    status VARCHAR(20),
    id_conta INT NOT NULL,
    data_log TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE log_transacao (
    id_log SERIAL PRIMARY KEY,
    id_transacao INT NOT NULL,
    valor NUMERIC(15,2),
    id_conta INT,
    data_transacao TIMESTAMP,
    data_log TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    tipo_transacao VARCHAR(50) NOT NULL,
    status VARCHAR(20) DEFAULT 'INVALIDO'
);

CREATE TABLE log_cliente (
    id_log SERIAL PRIMARY KEY,
    id_cliente INT NOT NULL,
    cpf CHAR(11),
    id_endereco INT,
    score  NUMERIC(15,2) DEFAULT 0.00,
    data_log TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE log_cartao (
    id_log SERIAL PRIMARY KEY,
    id_cartao INT NOT NULL,
    numero_cartao VARCHAR(16),
    validade DATE,
    cvv CHAR(3),
    tipo_cartao VARCHAR(20),
    id_conta INT,
    data_log TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE log_conta (
    id_log SERIAL PRIMARY KEY,
    id_conta INT NOT NULL,
    numero_conta VARCHAR(20),
    tipo_conta VARCHAR(30),
    saldo NUMERIC(15,2),
    data_abertura TIMESTAMP,
    id_cliente INT,
    status VARCHAR(20),
    data_log TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);