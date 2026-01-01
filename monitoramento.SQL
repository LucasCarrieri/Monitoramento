CREATE DATABASE monitoramento;
USE monitoramento;

CREATE TABLE servidores (
    id INT AUTO_INCREMENT PRIMARY KEY,
    nome VARCHAR(100),
    ip VARCHAR(45),
    ambiente VARCHAR(50),
    criado_em TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE metricas (
    id INT AUTO_INCREMENT PRIMARY KEY,
    servidor_id INT,
    cpu_percent DECIMAL(5,2),
    ram_percent DECIMAL(5,2),
    disco_percent DECIMAL(5,2),
    coletado_em TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (servidor_id) REFERENCES servidores(id)
);


USE monitoramento;
SHOW TABLES;

USE monitoramento;
SELECT * FROM servidores;
SELECT * FROM metricas ORDER BY coletado_em DESC LIMIT 10;

