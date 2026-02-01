-- ============================================================================
-- SEED: Flow de teste conforme PROMPT UNIVERSAL DE REFERÊNCIA - FLOW EDITOR v1.0
-- Executar após flow_editor_tables.sql.
-- Estrutura: 1 tenant = 1 cliente; esse tenant tem N assistentes; cada assistente
-- tem 1 flow. Aqui o tenant "tenant-teste-001" tem 3 assistentes (3 flows).
-- ============================================================================

-- 1) FLOW (vinculado ao assistente — troque assistente-teste-001 pelo ID real do assistente se quiser)
INSERT INTO flows (id, tenant_id, assistente_id, name, description, prompt_base, status, is_active, version)
VALUES (
  'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11',
  'tenant-teste-001',
  'assistente-teste-001',
  'Flow Universal de Teste - Voz',
  'Flow de teste com todos os tipos de blocos (PM, MSG, AG, CAM, FER, ENC) conforme schema de referência.',
  E'# IA DE VOZ PARA LIGAÇÕES TELEFÔNICAS\n- "Falar" = O que a IA diz em voz alta.\n- "Aguardar" = A IA para e escuta o lead.\n- "Caminhos" = Decisões baseadas no que o lead FALOU.\n',
  'draft',
  true,
  1
)
ON CONFLICT (id) DO UPDATE SET
  assistente_id = EXCLUDED.assistente_id,
  name = EXCLUDED.name,
  description = EXCLUDED.description,
  prompt_base = EXCLUDED.prompt_base,
  updated_at = now();

-- 2) BLOCOS (flow_id fixo acima)
-- Limpar blocos/rotas existentes deste flow para re-seed
DELETE FROM flow_routes WHERE flow_id = 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11';
DELETE FROM flow_blocks WHERE flow_id = 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11';

INSERT INTO flow_blocks (flow_id, block_key, block_type, content, next_block_key, order_index, position_x, position_y) VALUES
-- Primeira mensagem
('a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11', 'PM001', 'primeira_mensagem',
 E'Olá! Tudo bem? Aqui é a [Nome da IA], assistente virtual da [Empresa]. Estou falando com [Nome do Lead]?',
 'AG001', 1, 100, 50),

-- Mensagens
('a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11', 'MSG001', 'mensagem',
 E'Perfeito, [Nome]! Essa ligação é bem rápida e objetiva. Me conta, o que te despertou o interesse em conhecer nossa solução?',
 'AG002', 2, 100, 150),
('a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11', 'MSG002', 'mensagem',
 E'Caraca, muito bacana! E me conta uma coisa, quantas pessoas trabalham na área comercial com vocês hoje?',
 'AG003', 3, 100, 250),
('a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11', 'MSG003', 'mensagem',
 E'Entendi! E qual tem sido o maior desafio de vocês na área comercial hoje? Queria entender o que te levou a buscar uma solução como a nossa.',
 'AG004', 4, 100, 350),
('a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11', 'MSG004', 'mensagem',
 E'Entendi... E esse desafio tá impactando muito os resultados de vocês?',
 NULL, 5, 100, 450),

-- Aguardar
('a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11', 'AG001', 'aguardar',
 E'Pare de falar e escute a resposta do lead.', 'CAM001', 10, 300, 50)
  ,('a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11', 'AG002', 'aguardar',
 E'Pare de falar e escute o lead explicar seu interesse.', 'CAM002', 11, 300, 150)
  ,('a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11', 'AG003', 'aguardar',
 E'Pare de falar e escute quantas pessoas tem na equipe.', 'MSG003', 12, 300, 250)
  ,('a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11', 'AG004', 'aguardar',
 E'Pare de falar e escute qual é o maior desafio.', 'CAM003', 13, 300, 350)
  ,('a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11', 'AG005', 'aguardar',
 E'Pare e escute: tudo bem com você?', 'MSG001', 14, 300, 450)
  ,('a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11', 'AG006', 'aguardar',
 E'Escute: como falo com [Nome do Lead]?', NULL, 15, 300, 550)
  ,('a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11', 'AG007', 'aguardar',
 E'Escute o que contaram sobre a gente.', 'MSG002', 16, 300, 650)
  ,('a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11', 'AG008', 'aguardar',
 E'Escute: já tentam prospecção ativa?', NULL, 17, 300, 750)
  ,('a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11', 'AG009', 'aguardar',
 E'Escute: quanto tempo para responder lead novo?', NULL, 18, 300, 850)
  ,('a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11', 'AG010', 'aguardar',
 E'Escute: alguém dedicado só pra prospecção?', NULL, 19, 300, 950);

-- Colunas extras para aguardar (variable_name)
UPDATE flow_blocks SET variable_name = 'confirmacao_nome'  WHERE flow_id = 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11' AND block_key = 'AG001';
UPDATE flow_blocks SET variable_name = 'resposta_interesse' WHERE flow_id = 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11' AND block_key = 'AG002';
UPDATE flow_blocks SET variable_name = 'tamanho_equipe'     WHERE flow_id = 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11' AND block_key = 'AG003';
UPDATE flow_blocks SET variable_name = 'resposta_dor'      WHERE flow_id = 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11' AND block_key = 'AG004';

-- Caminhos (roteadores)
INSERT INTO flow_blocks (flow_id, block_key, block_type, content, analyze_variable, order_index, position_x, position_y) VALUES
('a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11', 'CAM001', 'caminhos',
 E'É a pessoa certa?', '{{confirmacao_nome}}', 20, 500, 50),
('a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11', 'CAM002', 'caminhos',
 E'Qual o tipo de interesse do lead?', '{{resposta_interesse}}', 21, 500, 150),
('a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11', 'CAM003', 'caminhos',
 E'Qual a principal dor do lead?', '{{resposta_dor}}', 22, 500, 250);

-- Ferramentas
INSERT INTO flow_blocks (flow_id, block_key, block_type, content, tool_type, tool_config, next_block_key, order_index, position_x, position_y) VALUES
('a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11', 'FER001', 'ferramenta',
 E'Buscar dados do lead no sistema antes de falar.', 'buscar_dados', '{"acao":"busca_memoria","descricao":"Buscar nome, empresa, cargo e origem do lead"}', 'PM001', 30, 700, 50),
('a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11', 'FER002', 'ferramenta',
 E'Verificar horários livres na agenda. Antes de falar horários, diga: Deixa eu verificar aqui os horários disponíveis...', 'verificar_agenda', '{"acao":"verificar_disponibilidade","parametro":"data"}', NULL, 31, 700, 150),
('a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11', 'FER003', 'ferramenta',
 E'Agendar demonstração no calendário (data, horário, e-mail).', 'agendar', '{"acao":"agendar_reuniao","parametros":{"data_hora":"{{data_agendamento}}","nome":"{{nome_lead}}","email":"{{email_lead}}"}}', NULL, 32, 700, 250),
('a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11', 'FER004', 'ferramenta',
 E'Consultar FAQ ou documentação para responder dúvidas técnicas.', 'consultar_documento', '{"documento_id":"doc_faq","nome":"FAQ e Respostas Padrão"}', NULL, 33, 700, 350),
('a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11', 'FER005', 'ferramenta',
 E'Enviar mensagem de WhatsApp após a ligação (resumo, material, confirmação).', 'enviar_whatsapp', '{"mensagem":"Oi {{nome_lead}}! Conforme conversamos, segue o link para nossa demonstração: {{link_demo}}"}', 'ENC002', 34, 700, 450);

-- Encerrar
INSERT INTO flow_blocks (flow_id, block_key, block_type, content, end_type, end_metadata, order_index, position_x, position_y) VALUES
('a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11', 'ENC001', 'encerrar',
 E'Perfeito! Vou encerrar por aqui e o time de especialistas já entra em contato pra dar continuidade. Foi um prazer falar com você, [Nome]!', 'transferir', '{"motivo":"compra_direta","prioridade":"alta","fila":"vendas"}', 40, 900, 50),
('a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11', 'ENC002', 'encerrar',
 E'Pronto, [Nome], tá agendado! Você vai receber o convite no e-mail com o link da reunião. Foi ótimo conversar com você! Até [dia da reunião]!', 'finalizar', '{"motivo":"agendamento_realizado","status":"qualificado"}', 41, 900, 150),
('a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11', 'ENC003', 'encerrar',
 E'Entendi, [Nome]! Pelo que você me contou, talvez não seja o momento ideal pra nossa solução. Mas fico feliz que conheceu a gente! Se o cenário mudar, é só nos procurar. Valeu pelo papo!', 'nao_qualificado', '{"motivo":"sem_fit","status":"nao_qualificado"}', 42, 900, 250),
('a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11', 'ENC004', 'encerrar',
 E'Combinado, [Nome]! Vou anotar aqui e te ligo {{quando_retornar}}. Obrigada pelo tempo! Até breve!', 'agendar_retorno', '{"motivo":"retorno_agendado","data_retorno":"{{data_retorno}}"}', 43, 900, 350),
('a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11', 'ENC005', 'encerrar',
 E'Sem problemas! Vou tentar novamente em outro momento. Até mais!', 'finalizar', '{"motivo":"indisponivel","tentativas":"{{numero_tentativas}}"}', 44, 900, 450);

-- 3) ROTAS (caminhos) — CAM001
INSERT INTO flow_routes (flow_id, block_id, route_key, label, ordem, cor, keywords, response, destination_type, destination_block_key, max_loop_attempts, is_fallback)
SELECT f.id, b.id, 'confirmou', 'Confirmou que é ele (verde)', 1, '#22c55e',
  ARRAY['sim','sou eu','eu mesmo','isso','sou','pode falar'],
  'Perfeito, [Nome]! Tudo bem com você?', 'continuar', 'AG005', 2, false
FROM flows f JOIN flow_blocks b ON b.flow_id = f.id AND b.block_key = 'CAM001' WHERE f.id = 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11';

INSERT INTO flow_routes (flow_id, block_id, route_key, label, ordem, cor, keywords, response, destination_type, destination_block_key, max_loop_attempts, is_fallback)
SELECT f.id, b.id, 'nao_e_ele', 'Não é a pessoa (vermelho)', 2, '#ef4444',
  ARRAY['não','não sou','engano','número errado','quem'],
  'Ah, desculpa pelo engano! Você saberia me informar como falo com [Nome do Lead]?', 'goto', 'AG006', 2, false
FROM flows f JOIN flow_blocks b ON b.flow_id = f.id AND b.block_key = 'CAM001' WHERE f.id = 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11';

INSERT INTO flow_routes (flow_id, block_id, route_key, label, ordem, cor, keywords, response, destination_type, destination_block_key, max_loop_attempts, is_fallback)
SELECT f.id, b.id, 'fallback', 'Não entendi (padrão/fallback)', 3, '#6b7280',
  ARRAY[]::TEXT[],
  'Desculpa, não entendi bem. Estou falando com [Nome do Lead]?', 'loop', 'AG001', 2, true
FROM flows f JOIN flow_blocks b ON b.flow_id = f.id AND b.block_key = 'CAM001' WHERE f.id = 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11';

-- CAM002
INSERT INTO flow_routes (flow_id, block_id, route_key, label, ordem, cor, keywords, response, destination_type, destination_block_key, max_loop_attempts, is_fallback)
SELECT f.id, b.id, 'compra_direta', 'Quer Comprar Agora (vermelho)', 1, '#ef4444',
  ARRAY['comprar','preço','valor','quanto custa','quero contratar','fechar'],
  'Perfeito! Pra agilizar sua compra, o melhor é você falar direto com um especialista nosso que vai te passar todas as condições. Vou encerrar aqui e o time já entra em contato, tudo bem?', 'encerrar', 'ENC001', 2, false
FROM flows f JOIN flow_blocks b ON b.flow_id = f.id AND b.block_key = 'CAM002' WHERE f.id = 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11';

INSERT INTO flow_routes (flow_id, block_id, route_key, label, ordem, cor, keywords, response, destination_type, destination_block_key, max_loop_attempts, is_fallback)
SELECT f.id, b.id, 'consultivo', 'Quer Entender Melhor (verde)', 2, '#22c55e',
  ARRAY['conhecer','entender','saber mais','como funciona','projeto','planejando'],
  'Que legal! Me conta um pouco mais sobre o cenário de vocês hoje...', 'continuar', 'MSG002', 2, false
FROM flows f JOIN flow_blocks b ON b.flow_id = f.id AND b.block_key = 'CAM002' WHERE f.id = 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11';

INSERT INTO flow_routes (flow_id, block_id, route_key, label, ordem, cor, keywords, response, destination_type, destination_block_key, max_loop_attempts, is_fallback)
SELECT f.id, b.id, 'indicacao', 'Veio por Indicação (amarelo)', 3, '#f59e0b',
  ARRAY['indicação','indicaram','fulano me falou','recomendação','amigo'],
  'Que massa! Indicação é sempre bom sinal. E o que te contaram sobre a gente? Queria entender o que você já sabe...', 'continuar', 'AG007', 2, false
FROM flows f JOIN flow_blocks b ON b.flow_id = f.id AND b.block_key = 'CAM002' WHERE f.id = 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11';

INSERT INTO flow_routes (flow_id, block_id, route_key, label, ordem, cor, keywords, response, destination_type, destination_block_key, max_loop_attempts, is_fallback)
SELECT f.id, b.id, 'fallback', 'Não entendi (padrão/fallback)', 4, '#6b7280',
  ARRAY[]::TEXT[],
  'Entendi... me conta um pouco mais sobre o que você tá buscando?', 'loop', 'AG002', 2, true
FROM flows f JOIN flow_blocks b ON b.flow_id = f.id AND b.block_key = 'CAM002' WHERE f.id = 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11';

-- CAM003
INSERT INTO flow_routes (flow_id, block_id, route_key, label, ordem, cor, keywords, response, destination_type, destination_block_key, max_loop_attempts, is_fallback)
SELECT f.id, b.id, 'falta_leads', 'Falta de Leads (azul)', 1, '#3b82f6',
  ARRAY['poucos leads','falta lead','prospecção','não consigo gerar','demanda baixa'],
  'Nossa, isso é super comum! E vocês já tentam fazer algum tipo de prospecção ativa hoje? Como tem sido?', 'continuar', 'AG008', 2, false
FROM flows f JOIN flow_blocks b ON b.flow_id = f.id AND b.block_key = 'CAM003' WHERE f.id = 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11';

INSERT INTO flow_routes (flow_id, block_id, route_key, label, ordem, cor, keywords, response, destination_type, destination_block_key, max_loop_attempts, is_fallback)
SELECT f.id, b.id, 'demora_atendimento', 'Demora no Atendimento (roxo)', 2, '#8b5cf6',
  ARRAY['demora','lento','não consigo atender','lead esfria','perde oportunidade'],
  'Pois é, velocidade faz toda diferença! Sabia que a chance de fechar cai muito depois dos primeiros cinco minutos? Quanto tempo em média vocês levam pra responder um lead novo?', 'continuar', 'AG009', 2, false
FROM flows f JOIN flow_blocks b ON b.flow_id = f.id AND b.block_key = 'CAM003' WHERE f.id = 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11';

INSERT INTO flow_routes (flow_id, block_id, route_key, label, ordem, cor, keywords, response, destination_type, destination_block_key, max_loop_attempts, is_fallback)
SELECT f.id, b.id, 'equipe_sobrecarregada', 'Equipe Sobrecarregada (laranja)', 3, '#f97316',
  ARRAY['equipe pequena','sobrecarregado','não dá conta','falta gente','muito trabalho'],
  'Entendo demais! Quando a equipe fica no operacional, sobra pouco tempo pro estratégico, né? Hoje vocês têm alguém dedicado só pra prospecção ou todo mundo faz um pouco de tudo?', 'continuar', 'AG010', 2, false
FROM flows f JOIN flow_blocks b ON b.flow_id = f.id AND b.block_key = 'CAM003' WHERE f.id = 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11';

INSERT INTO flow_routes (flow_id, block_id, route_key, label, ordem, cor, keywords, response, destination_type, destination_block_key, max_loop_attempts, is_fallback)
SELECT f.id, b.id, 'fallback', 'Não entendi (padrão/fallback)', 4, '#6b7280',
  ARRAY[]::TEXT[],
  'Entendi... E esse desafio tá impactando muito os resultados de vocês?', 'continuar', 'MSG004', 2, true
FROM flows f JOIN flow_blocks b ON b.flow_id = f.id AND b.block_key = 'CAM003' WHERE f.id = 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11';

-- ============================================================================
-- FLOWS 2 e 3: mesmo tenant, outros 2 assistentes (cliente com 2–3 assistentes)
-- ============================================================================
INSERT INTO flows (id, tenant_id, assistente_id, name, description, prompt_base, status, is_active, version)
VALUES
  ('b1eebc99-9c0b-4ef8-bb6d-6bb9bd380a22', 'tenant-teste-001', 'assistente-teste-002', 'Flow Assistente 2 - Voz', 'Flow do segundo assistente do tenant.', E'# IA DE VOZ\nAssistente 2.\n', 'draft', true, 1),
  ('c2eebc99-9c0b-4ef8-bb6d-6bb9bd380a33', 'tenant-teste-001', 'assistente-teste-003', 'Flow Assistente 3 - Voz', 'Flow do terceiro assistente do tenant.', E'# IA DE VOZ\nAssistente 3.\n', 'draft', true, 1)
ON CONFLICT (id) DO UPDATE SET
  assistente_id = EXCLUDED.assistente_id,
  name = EXCLUDED.name,
  description = EXCLUDED.description,
  prompt_base = EXCLUDED.prompt_base,
  updated_at = now();

DELETE FROM flow_routes WHERE flow_id IN ('b1eebc99-9c0b-4ef8-bb6d-6bb9bd380a22', 'c2eebc99-9c0b-4ef8-bb6d-6bb9bd380a33');
DELETE FROM flow_blocks WHERE flow_id IN ('b1eebc99-9c0b-4ef8-bb6d-6bb9bd380a22', 'c2eebc99-9c0b-4ef8-bb6d-6bb9bd380a33');

INSERT INTO flow_blocks (flow_id, block_key, block_type, content, next_block_key, order_index, position_x, position_y)
VALUES
  ('b1eebc99-9c0b-4ef8-bb6d-6bb9bd380a22', 'PM001', 'primeira_mensagem', 'Olá, aqui é o assistente 2. Com quem falo?', 'AG001', 1, 100, 50),
  ('b1eebc99-9c0b-4ef8-bb6d-6bb9bd380a22', 'AG001', 'aguardar', 'Escute o nome do lead.', NULL, 2, 300, 50),
  ('c2eebc99-9c0b-4ef8-bb6d-6bb9bd380a33', 'PM001', 'primeira_mensagem', 'Olá, aqui é o assistente 3. Com quem falo?', 'AG001', 1, 100, 50),
  ('c2eebc99-9c0b-4ef8-bb6d-6bb9bd380a33', 'AG001', 'aguardar', 'Escute o nome do lead.', NULL, 2, 300, 50);

UPDATE flow_blocks SET variable_name = 'nome_lead' WHERE flow_id = 'b1eebc99-9c0b-4ef8-bb6d-6bb9bd380a22' AND block_key = 'AG001';
UPDATE flow_blocks SET variable_name = 'nome_lead' WHERE flow_id = 'c2eebc99-9c0b-4ef8-bb6d-6bb9bd380a33' AND block_key = 'AG001';

-- ============================================================================
-- Testar via API após rodar o seed (tenant = tenant-teste-001, 3 assistentes):
--   GET /api/flows?tenant_id=tenant-teste-001
--       → lista os 3 flows (só desse tenant)
--   GET /api/flows/by-assistant/assistente-teste-001?tenant_id=tenant-teste-001  → flow completo do assistente 1
--   GET /api/flows/by-assistant/assistente-teste-002?tenant_id=tenant-teste-001  → flow completo do assistente 2
--   GET /api/flows/by-assistant/assistente-teste-003?tenant_id=tenant-teste-001  → flow completo do assistente 3
--   GET /api/flows/by-assistant/assistente-teste-001/prompt  → prompt do assistente 1 (IA de voz)
-- ============================================================================
