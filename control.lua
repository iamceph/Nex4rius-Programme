--
--  Interactive stargate control program
--  Shows stargate state and allows dialling
--  addresses selected from a list
--  with automated Iris control
--  by DarknessShadow
--

dofile("config.lua")
dofile("compat.lua")
dofile("addresses.lua")

debug = false

gpu.setBackground(0x333333)

function pad(s, n)
  return s .. string.rep(" ", n - string.len(s))
end

function showMenu()
  setCursor(1, 1)
  print("Address Page " .. seite + 1)
  for i, na in pairs(addresses) do
    if i >= 1 + seite * 9 and i <= 9 + seite * 9 then
      print(i - seite * 9 .. " " .. na[1])
      if sg.energyToDial(na[2]) == nil then
        gpu.setForeground(0xFF0000)
        print("   <Error>")
        gpu.setForeground(0xFFFFFF)
      else
        print("   ".. string.format("%.1f", (sg.energyToDial(na[2])*energymultiplicator)/1000).." k")
      end
    end
    maxseiten = i / 9
  end
  iris = sg.irisState()
end

function getIrisState()
  ok, result = pcall(sg.irisState)
  return result
end

function iriscontroller()
  if state == "Dialing" then
    messageshow = true
  end
  if direction == "Incoming" and incode == IDC and control == "Off" then
    IDCyes = true
  end
  if direction == "Incoming" and incode == IDC and iriscontrol == "on" and control == "On" then
    if iris == "Offline" then
      sg.sendMessage("IDC Accepted Iris: Offline")
    else
      sg.openIris()
      os.sleep(2)
      sg.sendMessage("IDC Accepted Iris: Open")
    end
    iriscontrol = "off"
    IDCyes = true
  elseif direction == "Incoming" and send == true then
    sg.sendMessage("Iris Control: "..control.." Iris: "..iris)
    send = false
  end
  if wormhole == "in" and state == "Dialling" and iriscontrol == "on" and control == "On" then
    if iris == "Offline" then else
      sg.closeIris()
    end
    k = "close"
  end
  if iris == "Closing" and control == "On" then k = "open" end
  if state == "Idle" and k == "close" and control == "On" then
    outcode = nil
    if iris == "Offline" then else
      sg.openIris()
    end
    iriscontrol = "on"
    wormhole = "in"
    codeaccepted = "-"
    activationtime = 0
    entercode = false
    showidc = ""
    AddNewAddress = false
  end
  if state == "Idle" and control == "On" then
    iriscontrol = "on"
  end
  if state == "Closing" then
    send = true
    incode = "-"
    showMessage("")
    IDCyes = false
  end
  if state == "Idle" then
    incode = "-"
  end
  if state == "Closing" and control == "On" then
    k = "close"
  end
  if state == "Connected" and direction == "Outgoing" and send == true then
    if outcode == "-" or outcode == nil then else
      sg.sendMessage(outcode)
      send = false
    end
  end
  if codeaccepted == "-" or codeaccepted == nil then
  elseif messageshow == true then
    gpu.setForeground(0xFF0000)
    showMessage("Message received: "..codeaccepted)
    gpu.setForeground(0xFFFFFF)
    if codeaccepted == "Request: Disconnect Stargate" then
      os.sleep(1)
      sg.disconnect()
      os.sleep(1)
    end
    messageshow = false
    incode = "-"
    codeaccepted = "-"
  end
  if state == "Idle" then
    activationtime = 0
    entercode = false
    remoteName = ""
  end
end

function neueZeile(b)
  zeile = zeile + b
end

function newAddress(g)
  if AddNewAddress == true then
    f = io.open ("addresses.lua", "a")
    f:seek ("end", -1)
    f:write('  {"' .. g .. '", "' .. g .. '", ""},\n}')
    f:close ()
    AddNewAddress = false
    dofile("addresses.lua")
    showMenu()
  end
end

function destinationName()
  if remoteName == "" and state == "Dialling" and wormhole == "in" then
    for j, na in pairs(addresses) do
      if remAddr == na[2] then
        if na[1] == na[2] then
          remoteName = "Unknown"
        else
          remoteName = na[1]
          break
        end
      end
    end
    if remoteName == "" then
      newAddress(remAddr)
    end
  end
end

function getAddress(A)
  if A == "" or A == nil then
    return ""
  else
    return string.sub(A, 1, 4) .. "-" .. string.sub(A, 5, 7) .. "-" .. string.sub(A, 8, 9)
  end
end

function wormholeDirection()
  if wormhole == "in" then
    return "Incoming"
  end
end

function showState()
  gpu.setBackground(0x333333)
  locAddr = getAddress(sg.localAddress())
  remAddr = getAddress(sg.remoteAddress())
  destinationName()
  state, chevrons, direction = sg.stargateState()
  direction = wormholeDirection()
  iris = sg.irisState()
  iriscontroller()
  energy = sg.energyAvailable()*energymultiplicator
  zeile = 1
  showAt(40, zeile,  "Local Address:    " .. locAddr)
  neueZeile(1)
  showAt(40, zeile,  "Destination Addr: " .. remAddr)
  neueZeile(1)
  showAt(40, zeile,  "Destination Name: " .. remoteName)
  neueZeile(1)
  showAt(40, zeile,  "State:            " .. state)
  neueZeile(1)
  showenergy()
  neueZeile(1)
  showAt(40, zeile,  "Iris:             " .. iris)
  neueZeile(1)
  if iris == "Offline" then
  else
    showAt(40, zeile,  "Iris Control:     " .. control)
    neueZeile(1)
  end
  if IDCyes == true then
    showAt(40, zeile, "IDC:              Accepted")
    neueZeile(1)
  else
    showAt(40, zeile, "IDC:              " .. incode)
    neueZeile(1)
  end
  showAt(40, zeile,  "Engaged:          " .. chevrons)
  neueZeile(1)
  showAt(40, zeile,  "Direction:        " .. direction)
  neueZeile(1)
  activetime()
  neueZeile(1)
  autoclose()
  neueZeile(1)
  if debug == true then
    showAt(40, zeile, "Version:          1.3.8")
    neueZeile(1)
  end
  showControls()
end 

function showControls()
  neueZeile(3)
  showAt(40, zeile, "Controls")
  neueZeile(1)
  showAt(40, zeile, "D Disconnect")
  neueZeile(1)
  if iris == "Offline" then
    control = "Off"
  else
    showAt(40, zeile, "O Open Iris")
    neueZeile(1)
    showAt(40, zeile, "C Close Iris")
    neueZeile(1)
    showAt(40, zeile, "I Iris Control On/Off")
    neueZeile(1)
  end
  showAt(40, zeile, "E Enter IDC")
  neueZeile(1)
  if maxseiten > seite + 1 then
    showAt(40, zeile, "→ Next Page")
    neueZeile(1)
  end
  if seite >= 1 then
    showAt(40, zeile, "← Previous Page")
    neueZeile(1)
  end
  if debug == true then
    showAt(40, zeile, "Q Quit")
  end
end

function autoclose()
  if autoclosetime == false then
    showAt(40, zeile, "Autoclose:        Off")
  else
    showAt(40, zeile, "Autoclose:        " .. autoclosetime .. "s")
    if (activationtime - os.time()) / sectime > autoclosetime and state == "Connected" then
      sg.disconnect()
    end
  end
end

function showenergy()
  if energy < 10000000 then
    showAt(40, zeile, "Energy "..energytype..":        " .. string.format("%.1f", energy/1000) .. " k")
  else
    showAt(40, zeile, "Energy "..energytype..":        " .. string.format("%.1f", energy/1000000) .. " M")
  end
end

function activetime()
  if state == "Connected" then
    if activationtime == 0 then
      activationtime = os.time()
    end
    time = (activationtime - os.time())/sectime
    if time > 0 then
      showAt(40, zeile, "Time:             " .. string.format("%.1f", time) .. "s")
    end
  else
    showAt(40, zeile, "Time:")
  end
end

function showAt(x, y, s, h)
  setCursor(x, y)
  if h == nil then
    write(pad(s, 50))
  else
    write(pad(s, 1))
  end
end

function showMessage(mess)
  showAt(1, screen_height, mess)
end

function showError(mess)
  i = string.find(mess, ": ")
  if i then
    mess = "Error: " .. string.sub(mess, i + 2)
  end
  showMessage(mess)
end

handlers = {}

function dial(name, addr)
  showMessage(string.format("Dialling %s (%s)", name, addr))
  remoteName = name
  check(sg.dial(addr))
end

handlers[key_event_name] = function(e)
  c = key_event_char(e)
  if e[3] == 13 then
    entercode = false
    sg.sendMessage(enteridc)
  elseif entercode == true then
    enteridc = enteridc .. c
    showidc = showidc .. "*"
    showMessage("Enter IDC: " .. showidc)
  elseif c == "e" then
    if state == "Connected" and direction == "Outgoing" then
      enteridc = ""
      showidc = ""
      entercode = true
      showMessage("Enter IDC:")
    else
      showMessage("Stargate not Connected")
    end
  elseif c == "d" then
    if state == "Connected" and direction == "Incoming" then
        sg.sendMessage("Request: Disconnect Stargate")
    else
        sg.disconnect()
    end
  elseif c == "o" then
    if iris == "Offline" then else
      sg.openIris()
      if wormhole == "in" then
        if iris == "Offline" then
        else
          os.sleep(2)
          sg.sendMessage("Manual Override: Iris Open")
        end
      end
      if state == "Idle" then
        iriscontrol = "on"
      else iriscontrol = "off"
      end
    end
  elseif c == "c" then
    if iris == "Offline" then else
      sg.closeIris()
      iriscontrol = "off"
      if wormhole == "in" then
        sg.sendMessage("Manual Override: Iris Closed")
      end
    end
  elseif c == "q" then
    running = false
  elseif c >= "1" and c <= "9" then
    c = c + seite * 9
    na = addresses[tonumber(c)]
    iriscontrol = "off"
    wormhole = "out"
    if na then
      dial(na[1], na[2])
      if na[3] == "-" then
        else outcode = na[3]
      end
    end
  elseif c == "i" then
    if iris == "Offline" then else
      send = true
      if control == "On" then
        control = "Off"
      else
        control = "On"
      end
    end
  elseif e[3] == 0 and e[4] == 203 then
    if seite == 0 then
    else
      seite = seite - 1
      term.clear()
      showState()
      showMenu()
    end
  elseif e[3] == 0 and e[4] == 205 then
    if seite + 1 < maxseiten then
      seite = seite + 1
      term.clear()
      showState()
      showMenu()
    end
  end
end

function handlers.sgChevronEngaged(e)
  chevron = e[3]
  symbol = e[4]
  showMessage(string.format("Chevron %s engaged! (%s)", chevron, symbol))
end

function eventLoop()
  while running do
    showState()
    e = {pull_event()}
    if e[1] == nil then
    else
      name = e[1]
      f = handlers[name]
      if f then
        showMessage("")
        ok, result = pcall(f, e)
        if not ok then
          showError(result)
        end
      end
      if string.sub(e[1],1,3) == "sgM" and direction == "Incoming" and wormhole == "in" then
        if e[3] == "" then else
          incode = e[3]
          messageshow = true
        end
      end
      if string.sub(e[1],1,3) == "sgM" and direction == "Outgoing" then
        codeaccepted = e[3]
        messageshow = true
      end
    end
  end
end

function main()
  term.clear()
  showMenu()
  eventLoop()
  gpu.setBackground(0x00000)
  term.clear()
  setCursor(1, 1)
end

if sg.stargateState() == "Idle" and sg.irisState() == "Closed" then
  sg.openIris()
end

messageshow = true

running = true
main()
