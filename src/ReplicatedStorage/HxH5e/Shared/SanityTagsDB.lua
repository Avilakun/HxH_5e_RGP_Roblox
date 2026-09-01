--[[
    HxH5e SanityTagsDB (Shared) — catalogo de Gostos e Desgostos, a
    mecanica de "tags de personalidade" pedida pelo Lucas pra
    conectar a Sanidade a coisas que acontecem de verdade no jogo.

    Baseado na tabela real de Recuperacao de Sanidade do livro:
    "Realizando/Cumprindo o que gosta/ama... Recupere 2d6+INT" -- essa
    e a formula usada pra TODOS os Gostos.

    Desgostos: confirmado com o Lucas que o dano e sempre 1 de
    Estresse (fixo, nao rola dado), pode acumular, tem cooldown de 3h
    de JOGO por tag (nao real), e NAO recupera automaticamente so
    porque a situacao mudou -- so recupera pelos metodos normais de
    recuperacao de Sanidade.

    ⚠️ Dos 6 gatilhos de recuperacao do livro, so consigo automatizar
    3 hoje: Descanso Longo (ja existe), Gostos (aqui), Nat 20 (da pra
    rastrear). "Acao Protagonista" e "Foco de Caca" ficam pendentes --
    nao sao mecanismos implementados no jogo ainda.
]]

local SanityTagsDB = {}

SanityTagsDB.Tags = {
	-- ===== GOSTOS (recuperam Sanidade: 2d6+INT, cooldown 3h de jogo) =====
	{ id = "companhia_aliados", nome = "Companhia de aliados", tipo = "gosto",
		descricao = "Sente-se bem perto de outras pessoas." },
	{ id = "paz_diurna", nome = "Paz e solidão diurna", tipo = "gosto",
		descricao = "Gosta de ficar sozinho durante o dia." },
	{ id = "vitoria_combate", nome = "Vitória em combate", tipo = "gosto",
		descricao = "Sente prazer em derrotar um inimigo." },
	{ id = "descanso_seguro", nome = "Descanso seguro", tipo = "gosto",
		descricao = "Aprecia um bom descanso em segurança." },
	{ id = "disciplina_nen", nome = "Disciplina do Nen", tipo = "gosto",
		descricao = "Gosta de praticar Ten, Ren ou Zetsu." },
	{ id = "prosperidade", nome = "Prosperidade", tipo = "gosto",
		descricao = "Fica satisfeito ao receber dinheiro." },
	{ id = "reconhecimento", nome = "Reconhecimento", tipo = "gosto",
		descricao = "Gosta de ser reconhecido numa organização." },
	{ id = "seguranca", nome = "Sensação de segurança", tipo = "gosto",
		descricao = "Sente-se bem em lugares seguros." },
	{ id = "superar_desafios", nome = "Superar desafios", tipo = "gosto",
		descricao = "Gosta de superar seus próprios limites." },
	{ id = "emocao_risco", nome = "Emoção do risco", tipo = "gosto",
		descricao = "Sente-se vivo ao escapar de um perigo real." },

	-- ===== DESGOSTOS (1 de Estresse na Sanidade, cooldown 3h de jogo) =====
	{ id = "solidao_noturna", nome = "Solidão à noite", tipo = "desgosto",
		descricao = "Detesta ficar sozinho durante a noite." },
	{ id = "exaustao", nome = "Exaustão", tipo = "desgosto",
		descricao = "Sofre ao se sentir fisicamente exausto." },
	{ id = "beira_morte", nome = "À beira da morte", tipo = "desgosto",
		descricao = "Aterroriza-se ao ficar com a vida muito baixa." },
	{ id = "miseria", nome = "Miséria", tipo = "desgosto",
		descricao = "Sofre ao ficar completamente sem dinheiro." },
	{ id = "rejeicao", nome = "Rejeição", tipo = "desgosto",
		descricao = "Sofre ao ser rejeitado por uma organização." },
	{ id = "perigo_constante", nome = "Perigo constante", tipo = "desgosto",
		descricao = "Sofre ao ser perseguido por um inimigo." },
	{ id = "derrota", nome = "Derrota", tipo = "desgosto",
		descricao = "Sofre profundamente ao ser derrotado." },
	{ id = "multidoes", nome = "Multidões", tipo = "desgosto",
		descricao = "Incomoda-se com muita gente por perto." },
	{ id = "isolamento", nome = "Isolamento prolongado", tipo = "desgosto",
		descricao = "Sofre ao ficar muito tempo sozinho." },
	{ id = "esgotamento", nome = "Esgotamento", tipo = "desgosto",
		descricao = "Sofre ao esgotar quase toda sua Aura." },
}

local byId = {}
for _, tag in ipairs(SanityTagsDB.Tags) do
	byId[tag.id] = tag
end
SanityTagsDB.ById = byId

function SanityTagsDB.Get(id)
	return byId[id]
end

return SanityTagsDB
