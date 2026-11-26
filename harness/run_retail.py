import lupa,sys,glob,os
L=lupa.LuaRuntime(unpack_returned_tuples=True)
base=sys.argv[1]
L.execute(open("wowstub.lua",encoding="utf-8").read()); L.execute(open("retailstub.lua",encoding="utf-8").read())
NS=L.table()
toc=[l.strip() for l in open(base+'/PiolinCodex.toc',encoding='utf-8') if l.strip().endswith('.lua')]
loader=L.eval('function(src,name,ns) local f,e=load(src,"@"..name); if not f then error(e) end; f("PiolinCodex",ns) end')
for f in toc:
    loader(open(base+'/'+f,encoding='utf-8').read(), f, NS); print('cargado',f)
fire=L.globals().__fire
fire('ADDON_LOADED','PiolinCodex'); fire('PLAYER_LOGIN')
run=L.eval('function() for _,t in ipairs(__timers) do t() end; __timers={} end')
run()
L.execute('''
local NS=...
''') if False else None
test=L.eval('''function(NS)
  NS.Toggle()
  for i=1,#NS.TABS do NS.ShowTab(i) end
  NS.RefreshLive(); NS.UpdateProgress()
  local n=0
  for id,row in pairs(NS.cbById) do n=n+1; if n<4 then row.__scripts.OnClick(row) end end
  NS.AutoCheck(false)
  for _,c in ipairs({"", "", "macros","tienda","avisos","equipo","reparar","ayudante","vender","compras","precios","probar","ayuda","basura","objetivo"}) do SlashCmdList.PIOLINCODEX(c) end
  NS.RefreshLive()
  return n
end''')
print('filas con casilla:',test(NS))
fire('PLAYER_LEVEL_UP',25); fire('MERCHANT_SHOW'); fire('AUCTION_HOUSE_SHOW'); fire('PLAYER_REGEN_DISABLED'); fire('SKILL_LINES_CHANGED'); fire('TRAINER_SHOW'); fire('UPDATE_INVENTORY_DURABILITY')
run(); run()
print('chat:'); [print('  ',m) for m in list(L.globals().__chat.values())[-8:]]
fold=L.eval('''function(NS)
  local p = NS.pages.misiones
  return p and "ok" or "sin pagina"
end''')
print('pagina misiones', fold(NS))
t=L.eval('''function()
  local n=0
  for _,f in ipairs(__frames) do if rawget(f,"fold") and f.fold.__scripts.OnClick then f.fold.__scripts.OnClick(f.fold); f.fold.__scripts.OnClick(f.fold); n=n+1 end end
  return n
end''')
print('tarjetas plegadas y desplegadas:', t())
ex=L.eval('''function(NS)
  NS.SetWaypoint(1433, 9.6, 71.0, "Marcy Baker")
  local a = _G.PiolinCodexArrow
  a.__scripts.OnUpdate(a, 0.1)
  local r1 = a.dist:GetText()
  NS.GoTo({1433, 10, 72.6, "Daniel"})
  SlashCmdList.PIOLINCODEX("ir 40 50"); SlashCmdList.PIOLINCODEX("ir")
  SlashCmdList.PIOLINCODEX("opciones"); SlashCmdList.PIOLINCODEX("misiones")
  local p = _G.PiolinCodexOptions
  p.__scripts.OnShow(p)
  for _, cb in ipairs(p.checks) do cb.__scripts.OnClick(cb) end
  -- captura de tecla
  local cap
  for _, f in ipairs(__frames) do if f.__scripts.OnKeyDown then cap = f end end
  cap.__scripts.OnKeyDown(cap, "C")
  __fire("QUEST_LOG_UPDATE"); for _, t in ipairs(__timers) do t() end; __timers = {}
  __fire("QUEST_ACCEPTED", 3, 166); for _, t in ipairs(__timers) do t() end; __timers = {}
  NS.ShowTab(2); NS.RefreshLive()
  PiolinCodex_Toggle(); PiolinCodex_ClearWay()
  return r1, GetBindingKey("PIOLINCODEX_TOGGLE"), tostring(rawget(NS.cbById.dm7,"questState")), tostring(rawget(NS.cbById.dm1,"questState"))
end''')
print('extras:', ex(NS))
chk=L.eval('''function(NS) return tostring(PiolinCodexDB.checks.dm7), NS.QuestStatus(166), tostring(PiolinCodexDB.checks.dm4), NS.cbById.dm4 and tostring(rawget(NS.cbById.dm4,"questState")) end''')
print('dm7 tildada:', chk(NS))
dbg=L.eval('''function(NS)
  local p = NS.pages.misiones
  local r = rawget(p, "refreshers")
  local out = {"refreshers=" .. tostring(r and #r)}
  if r then r[1]() end
  table.insert(out, "dm7=" .. tostring(rawget(NS.cbById.dm7,"questState")))
  table.insert(out, "ql=" .. tostring(NS.questLog and NS.questLog.total))
  return table.concat(out, " ")
end''')
print(dbg(NS))
snd=L.eval('''function(NS)
  local out = {}
  NS.Sound("combat")
  table.insert(out, "dialog durante=" .. __cv.Sound_DialogVolume)
  for _, t in ipairs(__timers) do t() end; __timers = {}
  table.insert(out, "dialog despues=" .. __cv.Sound_DialogVolume)
  local p = NS.soundPanel
  p.__scripts.OnShow(p)
  for _, d in ipairs(__dd) do d.fn(d.f, 1); if __lastInfo and __lastInfo.func then __lastInfo.func() end end
  for _, t in ipairs(__timers) do t() end; __timers = {}
  local sl = _G.PiolinCodexVolume
  sl.__scripts.OnValueChanged(sl, 0.3)
  table.insert(out, "vol=" .. tostring(PiolinCodexDB.soundVolume))
  NS.Alert("tent", "x"); NS.Alert("q123", "y")
  table.insert(out, "sonidos=" .. #__played .. " ultimo=" .. __played[#__played])
  __fire("PLAYER_LOGOUT")
  table.insert(out, "final=" .. __cv.Sound_DialogVolume)
  return table.concat(out, " | ")
end''')
print(snd(NS))
an=L.eval('''function(NS)
  local d = __frames
  local drv
  local out = {}
  -- disparar todas las animaciones y correr el motor varios cuadros
  NS.Toggle(); NS.Toggle()
  NS.ShowTab(3); NS.ShowTab(1)
  local row = NS.cbById.dm5; row.__scripts.OnClick(row)
  NS.AnimSection("Minas de la Muerte", 9)
  NS.AnimLevel(25)
  NS.AnimFloat(NS.cbById.dm5, "+1 Peletería")
  for _, t in ipairs(__timers) do t() end; __timers = {}
  for _, f in ipairs(__frames) do
    local u = rawget(f, "__scripts") and f.__scripts.OnUpdate
    if u then for i = 1, 120 do u(f, 0.05) end end
  end
  for _, f in ipairs(__frames) do if rawget(f,"__scripts") and f.__scripts.OnShow then pcall(f.__scripts.OnShow, f) end end
  return "ok, sonidos=" .. #__played .. " error=" .. tostring(NS.lastAnimError)
end''')
print('animaciones:', an(NS))
rt=L.eval('''function(NS)
  local out = {}
  table.insert(out, "oficios=" .. GetNumSkillLines() .. " (" .. (GetSkillLineInfo(1)) .. ")")
  table.insert(out, "tooltips enganchados=" .. #__tdp)
  for _, f in ipairs(__tdp) do f(GameTooltip, {}) end
  NS.GoTo(NS.WAYPOINTS.tc1)
  table.insert(out, "mapa resuelto=" .. tostring(PiolinCodexDB.way and PiolinCodexDB.way[1]))
  table.insert(out, "anim error=" .. tostring(NS.lastAnimError))
  return table.concat(out, " | ")
end''')
print('moderno:', rt(NS))
ah=L.eval('''function(NS)
  local out = {}
  table.insert(out, "talentos libres=" .. tostring(NS.FreeTalentPoints()))
  local rk = NS.TalentRanks() or {}
  local n = 0 for _ in pairs(rk) do n = n + 1 end
  table.insert(out, "rangos=" .. n .. " golpes de trueno " .. tostring(rk["golpes de trueno"]))
  table.insert(out, "oficio=" .. tostring((NS.Skill("Peletería"))))
  table.insert(out, "verde=" .. GetQuestGreenRange())
  __fire("AUCTION_HOUSE_SHOW")
  -- escaneo
  local btn
  for _, f in ipairs(__frames) do if rawget(f, "__text") == "Escanear materiales" then btn = f end end
  btn.__scripts.OnClick(btn)
  for i = 1, 200 do
    for _, tk in ipairs(__tickers) do if not tk.dead then pcall(tk.f) end end
    __fire("COMMODITY_SEARCH_RESULTS_UPDATED", __ahq[#__ahq])
  end
  table.insert(out, "consultas=" .. #__ahq .. " precio guardado=" .. tostring(PiolinCodexDB.prices[2318] and PiolinCodexDB.prices[2318].p))
  for _, f in ipairs(__hooks) do f() end
  for _, t in ipairs(__timers) do pcall(t) end; __timers = {}
  table.insert(out, "hooks=" .. #__hooks)
  -- aviso antes de pelear
  __fire("PLAYER_TARGET_CHANGED")
  __inCombat = true; __fire("PLAYER_REGEN_DISABLED"); __inCombat = false
  table.insert(out, "lista click")
  NS.AHSearch(2321)
  return table.concat(out, " | ")
end''')
print('forever:', ah(NS))
chk2=L.eval('''function()
  for _, f in ipairs(__frames) do local t = rawget(f, "__text"); if type(t) == "string" and t:find("pelear") then return t end end
  return "sin aviso"
end''')
print('aviso:', chk2())
chk3=L.eval('''function()
  PiolinCodexDB.noReminders = nil
  __fire("PLAYER_TARGET_CHANGED")
  for _, f in ipairs(__frames) do local t = rawget(f, "__text"); if type(t) == "string" and t:find("Antes de pelear") then return t end end
  return "sin aviso"
end''')
print('aviso2:', chk3())
au=L.eval('''function(NS)
  PiolinCodexDB.checks = {}
  NS.SetFlag("lure"); NS.SetFlag("caught6308")
  for _, t in ipairs(__timers) do pcall(t) end; __timers = {}
  NS.AutoCheck(false)
  local got = {}
  for _, id in ipairs({"t21","t24","t25","tr1","ah1","ah3","f2b","f2c","f4b","f5a","r20a","lp4","lw1"}) do
    table.insert(got, id .. "=" .. (PiolinCodexDB.checks[id] and "si" or "no"))
  end
  return table.concat(got, " ")
end''')
print('auto:', au(NS))
sk=L.eval('''function(NS)
  PiolinCodexDB.noSkinTips = nil
  local lines = {}
  GameTooltip.AddLine = function(self, t) table.insert(lines, t) end
  for _, f in ipairs(__tdp) do f(GameTooltip, {}) end
  return NS.SkinRequired(16) .. "/" .. NS.SkinRequired(25) .. " | " .. table.concat(lines, " || ")
end''')
print('desuello:', sk(NS))
dbg=L.eval('''function(NS)
  local r = {}
  table.insert(r, "tdp=" .. #__tdp)
  table.insert(r, "skill=" .. tostring((NS.Skill("Desuello"))))
  table.insert(r, "exists=" .. tostring(UnitExists("mouseover")))
  table.insert(r, "noSkin=" .. tostring(PiolinCodexDB.noSkinTips))
  return table.concat(r, " ")
end''')
print('dbg:', dbg(NS))
tr=L.eval('''function(NS)
  local out = {}
  local l = NS.RankedTrainers("Peletería")
  table.insert(out, "pelet1=" .. l[1].t[2] .. (l[1].same and " (zona)" or ""))
  local c = NS.RankedTrainers("Chamán")
  table.insert(out, "chaman1=" .. c[1].t[2])
  PiolinCodexDB.noAutoTrack = nil; __fire("ZONE_CHANGED_NEW_AREA"); for _, t in ipairs(__timers) do pcall(t) end; __timers = {}
  table.insert(out, "rastreo=" .. tostring(__TR[2].active) .. "/" .. tostring(__TR[3].active) .. " hierbas=" .. tostring(__TR[1].active))
  SlashCmdList.PIOLINCODEX("instructor pesca")
  table.insert(out, "flecha=" .. tostring(PiolinCodexDB.way and PiolinCodexDB.way[4]))
  NS.ShowTab(5); NS.RefreshLive()
  return table.concat(out, " | ")
end''')
print('instructores:', tr(NS))
