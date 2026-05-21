CREATE OR REPLACE FUNCTION calcular_score_cliente(p_id_cliente INT)
RETURNS INT
LANGUAGE plpgsql
AS $$
DECLARE
    v_score INT := 0;
BEGIN

    -- Contas ativas
    v_score := v_score + (SELECT COUNT(*) * 20 FROM Conta WHERE id_cliente = p_id_cliente AND status = 'ATIVA');

    -- Contas inativas
    v_score := v_score - (SELECT COUNT(*) * 10 FROM Conta WHERE id_cliente = p_id_cliente AND status != 'ATIVA');

    -- Saldo total
    v_score := v_score + (
        SELECT CASE
            WHEN COALESCE(SUM(saldo), 0) >= 10000 THEN 100
            WHEN COALESCE(SUM(saldo), 0) >= 3000  THEN 60
            WHEN COALESCE(SUM(saldo), 0) >= 500   THEN 30
            WHEN COALESCE(SUM(saldo), 0) < 0      THEN -80
            ELSE 0
        END
        FROM Conta WHERE id_cliente = p_id_cliente
    );

    -- Transações nos últimos 90 dias
    v_score := v_score + (
        SELECT CASE
            WHEN COUNT(*) >= 30 THEN 60
            WHEN COUNT(*) >= 10 THEN 35
            WHEN COUNT(*) >= 1  THEN 10
            ELSE -20
        END
        FROM Transacao t
        JOIN Conta c ON t.id_conta = c.id_conta
        WHERE c.id_cliente = p_id_cliente
          AND t.data_transacao >= NOW() - INTERVAL '90 days'
    );

    -- Empréstimos
    v_score := v_score + (SELECT COUNT(*) *  50 FROM Emprestimo e JOIN Conta c ON e.id_conta = c.id_conta WHERE c.id_cliente = p_id_cliente AND e.status = 'QUITADO');
    v_score := v_score - (SELECT COUNT(*) *  20 FROM Emprestimo e JOIN Conta c ON e.id_conta = c.id_conta WHERE c.id_cliente = p_id_cliente AND e.status = 'ATIVO');
    v_score := v_score - (SELECT COUNT(*) * 150 FROM Emprestimo e JOIN Conta c ON e.id_conta = c.id_conta WHERE c.id_cliente = p_id_cliente AND e.status = 'INADIMPLENTE');

    -- Cartões
    v_score := v_score + (SELECT COUNT(*) * 15 FROM Cartao ca JOIN Conta c ON ca.id_conta = c.id_conta WHERE c.id_cliente = p_id_cliente AND ca.status = 'ATIVO');
    v_score := v_score - (SELECT COUNT(*) * 25 FROM Cartao ca JOIN Conta c ON ca.id_conta = c.id_conta WHERE c.id_cliente = p_id_cliente AND ca.status = 'BLOQUEADO');

    RETURN GREATEST(0, LEAST(1000, v_score));

END;
$$;