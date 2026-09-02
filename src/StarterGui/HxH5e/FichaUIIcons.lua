--!strict
-- FichaUIIcons — um lugar só para trocar todos os ícones.
--
-- COMO TROCAR: suba o PNG em Creator Dashboard > Development Items > Decals,
-- copie o id e cole aqui. Use PNG BRANCO com fundo transparente para o
-- ImageColor3 seguir a cor da categoria de Nen.
--
-- Enquanto o id for 0, o widget desenha um quadro vazio no lugar do ícone
-- (nada quebra, só não aparece imagem).

local Icons = {
	-- Atributos (2 por atributo, como na ficha do webapp)
	FOR_1 = 0, FOR_2 = 0,   -- punho / halter
	DES_1 = 0, DES_2 = 0,   -- giro / tênis
	CON_1 = 0, CON_2 = 0,   -- corpo / cruz médica
	INT_1 = 0, INT_2 = 0,   -- livro / frasco
	SAB_1 = 0, SAB_2 = 0,   -- olho / meditação
	PRE_1 = 0, PRE_2 = 0,   -- diálogo / silhueta

	-- Abas
	Tab_Ficha = 0, Tab_Bio = 0, Tab_Nen = 0, Tab_Tracos = 0, Tab_Inv = 0,

	-- Cabeçalho da ficha
	Jogador = 0, Tendencia = 0, Proficiencia = 0, Categoria = 0,
	Deslocamento = 0, CA = 0, RDM = 0, Iniciativa = 0, TesteResistencia = 0,

	-- NEN
	Principios = 0, Hatsu = 0, Bloqueado = 0, Desbloqueado = 0,

	-- TRAÇOS
	Racial = 0, Antecedente = 0, Inclinacoes = 0, Combate = 0, Shingen = 0, Treinamentos = 0,
	Positiva = 0, Negativa = 0,

	-- INV
	Dinheiro = 0, Espaco = 0, Equipamento = 0,
	Slot_Cabeca = 0, Slot_Torso = 0, Slot_MaoPrincipal = 0, Slot_MaoSecundaria = 0,
	Slot_Costas = 0, Slot_Cintura = 0, Slot_Pernas = 0, Slot_Acessorio = 0,
	Item_Espada = 0, Item_Faca = 0, Item_Arma = 0, Item_Armadura = 0,
	Item_Kit = 0, Item_Cura = 0, Item_Mochila = 0, Item_Bolsa = 0, Item_Generico = 0,
}

-- Escolhe o ícone de um item pelo nome, como no mockup
function Icons.forItem(nome: string): number
	local n = string.lower(nome)
	local function has(s: string) return string.find(n, s, 1, true) ~= nil end
	if has("espada") or has("katana") or has("machado") or has("foice") then return Icons.Item_Espada end
	if has("adaga") or has("faca") or has("shuriken") then return Icons.Item_Faca end
	if has("pistola") or has("fuzil") or has("espingarda") or has("cartucho") or has("flecha") then return Icons.Item_Arma end
	if has("colete") or has("farda") or has("escudo") or has("casaco") then return Icons.Item_Armadura end
	if has("kit") then return Icons.Item_Kit end
	if has("pílula") or has("pilula") then return Icons.Item_Cura end
	if has("mochila") then return Icons.Item_Mochila end
	if has("pochete") or has("mala") then return Icons.Item_Bolsa end
	return Icons.Item_Generico
end

function Icons.asset(id: number): string
	if id == 0 then return "" end
	return "rbxassetid://" .. tostring(id)
end

return Icons
