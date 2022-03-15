local P, S, R, Cf, Cc, Ct, V, Cs, Cg, Cb, B, C, Cmt =
  lpeg.P, lpeg.S, lpeg.R, lpeg.Cf, lpeg.Cc, lpeg.Ct, lpeg.V,
  lpeg.Cs, lpeg.Cg, lpeg.Cb, lpeg.B, lpeg.C, lpeg.Cmt

local specialchar = S("`")
local wordchar = 1 - specialchar

local function trim(s)
  return (s:gsub("^%s*(.-)%s*$", "%1"))
end
local spacechar = S(" \t")
local newline = P"\r"^-1 * P"\n"
local blankline = spacechar^0 * newline

local backticks = P"`"^1
local open = Cg(backticks, "init")
local close = C(backticks)
local closeeq = Cmt(close * Cb("init"), function (s, i, a, b) return a == b end)
local _engine = Cg((R("az", "AZ", "09") + P("_"))^1, "engine")
local _label = Cg((R("az", "AZ", "09") + S("-_."))^1, "label")
local _args = Cg((1 - P"}")^1, "args")
local _sep = P" "^0 * P"," * P" "
local _sep_first = _sep + P" "^1
local _attr_name = _engine * _sep_first * ( _label - ((1 - S"=}")^1 * P"=" * (1 - P"}")^1) )
local _attr_args = _engine * _sep_first * _args
local _attr_full = _engine * _sep_first * _label * _sep * _args
local _attr = _attr_full + _attr_name + _attr_args + _engine
local attr = P"{" * _attr * P"}"
local code = open * Ct(Cg((P(1) - closeeq)^0, "code") * close * attr)

local code_classic = open * Ct(Cg(P"r", "engine") * P" "^1 * Cg((P(1) - closeeq)^0, "code") * close)

G = P{ "Doc",
  Doc = Ct(V"Block"^0) / pandoc.Pandoc ;
  Block = blankline^0 * V"Para" ;
  Para = Ct(V"Inline"^1) ;
  Inline = V"Code" + V"Str" ;
  Code = (code + code_classic) / function(t)
    local ret = pandoc.Code(trim(t["code"]))
    ret.attr = {
      id = t["label"] or '',
      class = '',
      engine = t["engine"],
      args = t["args"] or ''
    }
    return ret
  end;
  Str = wordchar^1 / pandoc.Str ;
}

function Reader(input, reader_options)
  return lpeg.match(G, tostring(input))
end
