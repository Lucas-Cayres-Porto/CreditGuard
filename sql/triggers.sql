--criação de log transacao
create or replace function fn_log_transacao()

returns trigger language plpgsql as $$

begin

	insert into log_transacao(id_transacao, valor, id_conta, status, data_transacao, tipo_transacao, data_log)

	values (new.id_transacao, new.valor, new.id_conta, new.status, new.data_transacao, new.tipo_transacao, now());
	
	return new;
end; $$;

create trigger trg_log_transacao

after insert on transacao

for each row execute function fn_log_transacao();

--criação de log pra emprestimoa

create or replace function fn_log_emprestimo()

returns trigger language plpgsql as $$

begin

	insert into log_emprestimo(id_emprestimo, valor_total, taxa_juros, quantidade_parcelas, data_contratacao, status, id_conta, data_log)

	values (new.id_emprestimo, new.valor_total, new.taxa_juros, new.quantidade_parcelas, new.data_contratacao, new.status, new.id_conta, now());
	
	return new;
end; $$;
 
create trigger trg_log_emprestimo

after insert on emprestimo

for each row execute function fn_log_emprestimo();

--criação de log pra cliente
CREATE OR REPLACE FUNCTION fn_log_cliente()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
    INSERT INTO log_cliente (id_cliente, cpf, id_endereco ,score, data_log)
    VALUES (NEW.id_cliente, NEW.cpf, NEW.id_endereco, new.score ,now());
    
    RETURN NEW;
END; $$;
CREATE TRIGGER trg_log_cliente
AFTER INSERT ON cliente
FOR EACH ROW EXECUTE FUNCTION fn_log_cliente();

--criação de log para conta
create or replace function fn_log_conta()
returns trigger language plpgsql as $$
begin
    insert into log_conta(id_conta, numero_conta, tipo_conta, saldo, data_abertura, status ,id_cliente,data_log)
    values (new.id_conta, new.numero_conta, new.tipo_conta, new.saldo, new.data_abertura, new.status,new.id_cliente, now());
    
    return new;
end; $$;
create trigger trg_log_conta
after insert on conta
for each row execute function fn_log_conta();

--criação de log para cartão
create or replace function fn_log_cartao()
returns trigger language plpgsql as $$
begin
    insert into log_cartao (id_cartao, numero_cartao, validade, cvv, tipo_cartao, id_conta, data_log)
    values (new.id_cartao, new.numero_cartao, new.validade, new.cvv, new.tipo_cartao, new.id_conta, now());
    
    return new;
end; $$;
create trigger trg_log_cartao
after insert on cartao
for each row execute function fn_log_cartao();

--verificação se é maior que 0
create or replace function fn_validar_pagamento()
returns trigger language plpgsql as $$
begin
	if new.valor<=0 then
		raise exception
		 'Valor inválido:R$ %. Deve ser maior que 0!', new.valor;
	end if;
	return new;
end; $$;
create trigger trg_validar_pagamento
before insert on transacao
for each row execute function fn_validar_pagamento();

--verificação se existe dinheiro na conta e coloca valido ou invalido

create or replace function fn_validar_transacao_saldo()
returns trigger language plpgsql as $$
declare
    v_saldo_atual decimal;
begin
    -- Busca o saldo atual da conta
    select saldo into v_saldo_atual from conta where id_conta = new.id_conta;

    -- Se o valor for maior que o saldo, marca como invalido
    if new.valor > v_saldo_atual then
        new.status := 'INVALIDO';
    else
        new.status := 'VALIDO';
    end if;

    return new;
end; $$;

create trigger trg_validar_transacao_saldo
before insert on transacao
for each row execute function fn_validar_transacao_saldo();

--proteje os dados
create or replace function fn_atualizar_saldo_conta()
returns trigger language plpgsql as $$
begin
    -- Só mexe no saldo se a transação foi marcada como válida pela trigger anterior
    if new.status = 'valido' then
        update conta 
        set saldo = saldo - new.valor 
        where id_conta = new.id_conta;
    end if;

    return new;
end; $$;

create trigger trg_atualizar_saldo_pos_transacao
after insert on transacao
for each row execute function fn_atualizar_saldo_conta();

--trigger de bloquear o cartão
create or replace function fn_verificar_limite()
returns trigger language plpgsql as $$
DECLARE
    total_gasto_24h DECIMAL(10,2);
	fn_limite_cartao   DECIMAL(10,2);
begin
    SELECT limite_cartao INTO fn_limite_cartao FROM cartao WHERE id_cartao = NEW.id_cartao;
	SELECT SUM(valor) INTO total_gasto_24h 
    FROM transacao
    WHERE id_cartao = NEW.id_cartao 
    AND data_transacao >= NOW() - INTERVAL '24 hours';
	IF total_gasto_24h >= (fn_limite_cartao * 0.90) THEN
        -- 3. Bloqueia o cartão preventivamente
        UPDATE cartao 
        SET status = 'bloqueado_preventivo' 
        WHERE id_cartao = NEW.id_cartao;
        
        RAISE NOTICE 'Cartão % bloqueado: Gasto de 90%% do limite atingido em 24h.', NEW.id_cartao;
    END IF;

    return new;
end; $$;

create trigger trg_verificar_limite
after insert on transacao
for each row execute function fn_verificar_limite();
