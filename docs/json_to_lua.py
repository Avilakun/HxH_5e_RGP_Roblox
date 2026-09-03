import json
import re

def lua_key(k):
    """Se a chave for um identificador Lua valido, usa notacao .chave;
    senao usa notacao ['chave']. Trata palavras reservadas do Lua."""
    RESERVED = {"and","break","do","else","elseif","end","false","for","function",
                "if","in","local","nil","not","or","repeat","return","then","true",
                "until","while"}
    if isinstance(k, str) and re.match(r'^[A-Za-z_][A-Za-z0-9_]*$', k) and k not in RESERVED:
        return k
    return None

def lua_str(s):
    s = str(s)
    s = s.replace('\\', '\\\\').replace('"', '\\"').replace('\n', '\\n')
    return '"' + s + '"'

def to_lua(obj, indent=0):
    pad = '\t' * indent
    pad_in = '\t' * (indent + 1)
    if obj is None:
        return "nil"
    if isinstance(obj, bool):
        return "true" if obj else "false"
    if isinstance(obj, (int, float)):
        return repr(obj)
    if isinstance(obj, str):
        return lua_str(obj)
    if isinstance(obj, list):
        if not obj:
            return "{}"
        linhas = ["{\n"]
        for item in obj:
            linhas.append(f"{pad_in}{to_lua(item, indent + 1)},\n")
        linhas.append(f"{pad}}}")
        return "".join(linhas)
    if isinstance(obj, dict):
        if not obj:
            return "{}"
        linhas = ["{\n"]
        for k, v in obj.items():
            key = lua_key(k)
            if key is not None:
                keypart = key
            else:
                keypart = f"[{lua_str(k)}]"
            linhas.append(f"{pad_in}{keypart} = {to_lua(v, indent + 1)},\n")
        linhas.append(f"{pad}}}")
        return "".join(linhas)
    raise ValueError(f"Tipo nao suportado: {type(obj)}")

if __name__ == "__main__":
    import sys
    infile, outfile, varname, header = sys.argv[1], sys.argv[2], sys.argv[3], sys.argv[4]
    with open(infile, encoding='utf-8') as f:
        data = json.load(f)
    with open(outfile, 'w', encoding='utf-8') as f:
        f.write(header)
        f.write(f"local {varname} = ")
        f.write(to_lua(data, 0))
        f.write("\n\nreturn " + varname + "\n")
    print("Gerado:", outfile)
