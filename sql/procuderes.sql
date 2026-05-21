CREATE OR REPLACE PROCEDURE calcular_score(p_id_cliente INT)
LANGUAGE plpgsql
AS $$
DECLARE
    v_score             NUMERIC(15,2) := 0.00;
    v_saldo_total       NUMERIC(15,2);
    v_qtd_emp_ativos    INT;
    v_qtd_emp_quitados  INT;
    v_qtd_transacoes    INT;
    v_cliente_existe    INT;
BEGIN

    SELECT COUNT(*) INTO v_cliente_existe
    FROM Cliente WHERE id_cliente = p_id_cliente;

    IF v_cliente_existe = 0 THEN
        RAISE EXCEPTION 'Cliente com id % não encontrado.', p_id_cliente;
    END IF;

    -- Saldo total
    SELECT COALESCE(SUM(saldo), 0) INTO v_saldo_total
    FROM Conta WHERE id_cliente = p_id_cliente;

    -- Empréstimos ativos e quitados
    SELECT
        COUNT(*) FILTER (WHERE e.status = 'PENDENTE'),
        COUNT(*) FILTER (WHERE e.status = 'QUITADO')
    INTO v_qtd_emp_ativos, v_qtd_emp_quitados
    FROM Emprestimo e
    JOIN Conta c ON c.id_conta = e.id_conta
    WHERE c.id_cliente = p_id_cliente;

    -- Quantidade de transações
    SELECT COUNT(*) INTO v_qtd_transacoes
    FROM Transacao t
    JOIN Conta c ON c.id_conta = t.id_conta
    WHERE c.id_cliente = p_id_cliente;

    -- ── SALDO ────────────────────────────────────
    IF v_saldo_total >= 10000 THEN
        v_score := v_score + 300;
    ELSIF v_saldo_total >= 1000 THEN
        v_score := v_score + 150;
    ELSIF v_saldo_total >= 100 THEN
        v_score := v_score + 50;
    END IF;

    -- ── EMPRÉSTIMOS QUITADOS ─────────────────────
    IF v_qtd_emp_quitados >= 2 THEN
        v_score := v_score + 300;
    ELSIF v_qtd_emp_quitados = 1 THEN
        v_score := v_score + 150;
    END IF;

    -- ── EMPRÉSTIMOS ATIVOS (penaliza) ────────────
    IF v_qtd_emp_ativos >= 3 THEN
        v_score := v_score - 200;
    ELSIF v_qtd_emp_ativos = 2 THEN
        v_score := v_score - 100;
    ELSIF v_qtd_emp_ativos = 1 THEN
        v_score := v_score - 30;
    END IF;

    -- ── TRANSAÇÕES ───────────────────────────────
    IF v_qtd_transacoes >= 20 THEN
        v_score := v_score + 200;
    ELSIF v_qtd_transacoes >= 5 THEN
        v_score := v_score + 100;
    ELSIF v_qtd_transacoes >= 1 THEN
        v_score := v_score + 50;
    END IF;

    -- Limita entre 0 e 1000
    v_score := GREATEST(0, LEAST(1000, v_score));

    UPDATE Cliente SET score = v_score WHERE id_cliente = p_id_cliente;

    INSERT INTO log_cliente (id_cliente, cpf, id_endereco, score)
    SELECT id_cliente, cpf, id_endereco, v_score
    FROM Cliente WHERE id_cliente = p_id_cliente;

    RAISE NOTICE 'Score do cliente % atualizado para: %', p_id_cliente, v_score;

END;
$$;