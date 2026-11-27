import lupa,sys,glob,os
L=lupa.LuaRuntime(unpack_returned_tuples=True)
base=sys.argv[1]
L.execute(open('wowstub.lua',encoding='utf-8').read())
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
  local p = NS.pages.guia
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
chk=L.eval('''function(NS) return tostring(PiolinCodexCharDB.checks.dm7), NS.QuestStatus(166), tostring(PiolinCodexCharDB.checks.dm4), NS.cbById.dm4 and tostring(rawget(NS.cbById.dm4,"questState")) end''')
print('dm7 tildada:', chk(NS))
dbg=L.eval('''function(NS)
  local p = NS.pages.guia
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
  table.insert(out, "vol=" .. tostring(PiolinCodexCharDB.soundVolume))
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
