CREATE OR REPLACE VIEW vw_farol_credito AS
SELECT
    c.id_cliente,
    c.nome_cliente,
    c.cpf,
    c.telefone,
    c.email,
    c.score,

    -- ── DADOS DAS CONTAS ─────────────────────────
    COUNT(DISTINCT co.id_conta)                                        AS qtd_contas,
    COUNT(DISTINCT co.id_conta) FILTER (WHERE co.status = 'ATIVA')    AS contas_ativas,
    COALESCE(SUM(co.saldo), 0)                                         AS saldo_total,

    -- ── DADOS DOS EMPRÉSTIMOS ─────────────────────
    COUNT(DISTINCT e.id_emprestimo)                                        AS qtd_emprestimos,
    COUNT(DISTINCT e.id_emprestimo) FILTER (WHERE e.status = 'ATIVO')     AS emprestimos_ativos,
    COUNT(DISTINCT e.id_emprestimo) FILTER (WHERE e.status = 'QUITADO')   AS emprestimos_quitados,
    COALESCE(SUM(e.valor_total) FILTER (WHERE e.status = 'ATIVO'), 0)     AS valor_em_aberto,

    -- ── DADOS DAS TRANSAÇÕES ──────────────────────
    COUNT(DISTINCT t.id_transacao)       AS qtd_transacoes,
    COALESCE(SUM(t.valor), 0)           AS volume_transacionado,

    -- ── DADOS DOS CARTÕES ─────────────────────────
    COUNT(DISTINCT ca.id_cartao)                                         AS qtd_cartoes,
    COUNT(DISTINCT ca.id_cartao) FILTER (WHERE ca.status = 'ATIVO')     AS cartoes_ativos,

    -- ── FAROL ─────────────────────────────────────
    CASE
        WHEN c.score >= 700
             AND COUNT(DISTINCT e.id_emprestimo) FILTER (WHERE e.status = 'ATIVO') <= 1
             AND COALESCE(SUM(co.saldo), 0) >= 1000
        THEN 'VERDE'

        WHEN c.score >= 400
             OR (
                 c.score >= 300
                 AND COUNT(DISTINCT e.id_emprestimo) FILTER (WHERE e.status = 'ATIVO') <= 2
             )
        THEN 'AMARELO'

        ELSE 'VERMELHO'
    END AS farol,

    CASE
        WHEN c.score >= 700
             AND COUNT(DISTINCT e.id_emprestimo) FILTER (WHERE e.status = 'ATIVO') <= 1
             AND COALESCE(SUM(co.saldo), 0) >= 1000
        THEN 'Cliente seguro. Baixo risco de inadimplência.'

        WHEN c.score >= 400
             OR (
                 c.score >= 300
                 AND COUNT(DISTINCT e.id_emprestimo) FILTER (WHERE e.status = 'ATIVO') <= 2
             )
        THEN 'Cliente requer atenção. Avaliar antes de conceder crédito.'

        ELSE 'Cliente de alto risco. Evitar concessão de crédito.'
    END AS parecer

FROM Cliente c
LEFT JOIN Conta      co ON co.id_cliente  = c.id_cliente
LEFT JOIN Emprestimo e  ON e.id_conta     = co.id_conta
LEFT JOIN Transacao  t  ON t.id_conta     = co.id_conta
LEFT JOIN Cartao     ca ON ca.id_conta    = co.id_conta
GROUP BY
    c.id_cliente,
    c.nome_cliente,
    c.cpf,
    c.telefone,
    c.email,
    c.score;