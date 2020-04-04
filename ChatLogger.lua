--27
--fixed sc discord chat bug (since username now has a #)
 
local version = 27
 
if not fs.exists("config.lua") then
    shell.run("wget https://raw.githubusercontent.com/jakedacatman/ChatLogger/master/config.lua config.lua")
end

if not fs.exists("json.lua") then shell.run("pastebin get 4nRg9CHU json.lua") end
os.loadAPI("json.lua")
 
local configFile = fs.open("config.lua", "r")
local configSerialized = configFile.readAll()
local config = textutils.unserialize(configSerialized)
configFile.close()

local id = config.webhookId
local token = config.token

if not token or type(id) ~= "number" then config.doWebhook = false else config.doWebhook = true end
 
local latest = http.get("https://raw.githubusercontent.com/jakedacatman/ChatLogger/master/ChatLogger.lua")
 
if latest ~= nil then
    local latestVersion = tonumber(string.sub(latest.readLine(), 3))
    if latestVersion > version then
        print("Out of date (version "..latestVersion.." is out).")
        print("Update notes: "..string.sub(latest.readLine(), 3))
        print("Do you wish to update? (y/n)")
        local timeout = os.startTimer(15)
        while true do
            local event = {os.pullEvent()}
            if event[1] == "char" then
                if event[2] == "y" then
                    fs.delete(shell.getRunningProgram())
                    shell.run("wget https://raw.githubusercontent.com/jakedacatman/ChatLogger/master/ChatLogger.lua "..shell.getRunningProgram())
                    print("Update complete!")
                    print("If you wish to run the new version, then hold CTRL+T and run chatLogger.lua.")
                else
                    print("Not updating.")
                    break
                end
            elseif event[1] == "timer" and event[2] == timeout then
                print("Not updating.")
                break
            end
        end
    else
        print("Up to date! (or Github hasn't pushed my update)")
    end
else
    print("Failed to check for new version.")
end
 
print("Running version "..version)
 
local chatbox = peripheral.find("chat_box")
 
local monitor
if type(config.monitorName) ~= "string" then
    print("Monitor not set in config.lua.")
    monitor = peripheral.find("monitor", function(name, object) return object.isColor() end)
    if not monitor then print("This works best with Advanced monitors; consider upgrading.") end
    monitor = peripheral.find("monitor")
else monitor = peripheral.wrap(config.monitorName)
end
 
local modem = peripheral.find("modem", function(name, object) return object.isWireless() end)
if not monitor then monitor = peripheral.find("monitor") end
term.redirect(monitor)
 
monitor.clear()
monitor.setCursorPos(1,1)
monitor.setTextScale(0.5)
 
local channel

if type(config.channel) == "number" and config.channel < 65536 and config.channel > 0 then channel = config.channel 
else 
    channel = 3 
    print("Using default channel (3).")
end
 
if modem then modem.open(channel) end
 
--print("chat booted!")
 
local function writeTime()
    term.setTextColor(colors.purple)
    write(textutils.formatTime(os.time("utc"), true).." ")
end

local function sendToWebhook(message, user)
     if config.doWebhook then
         local data = {}
         if user then 
             data["content"] = message 
             data["username"] = user 
         else 
             data["content"] = message 
         end
         http.post("https://discordapp.com/api/webhooks/"..id.."/"..token, json.encode(data))
     end
end
 
while true do
    local vars = {os.pullEvent()}
    if vars[1] == "chat" then
        writeTime()
        term.setTextColor(colors.green)
        write(vars[2])
        term.setTextColor(colors.white)
        print(": "..vars[3])
        sendToWebhook(vars[3], vars[2])
  elseif vars[1] == "chat_discord" then
        writeTime()
        term.setTextColor(colors.gray)
        write("[")
        term.setTextColor(colors.blue)
        write("D")
        term.setTextColor(colors.gray)
        write("] ")
        term.setTextColor(colors.blue)
        local string = vars[2]
        write(string:sub(1, #string-5))
        term.setTextColor(colors.white)
        print(": "..vars[3])
        sendToWebhook(vars[3], string:sub(1, #string-5))
    elseif vars[1] == "death" then
        writeTime()
        term.setTextColor(colors.white)
        local temp = vars[4]
        if temp and #{temp:find(vars[2])} > 0 then
            print(temp)
            sendToWebhook(temp)
        elseif temp == nil then
            print(vars[2].." died")
            sendToWebhook(vars[2].." died")
        else
            if vars[4] == "mob" then
                print(vars[2].." was killed by a/an "..vars[3])
                sendToWebhook(vars[2].." was killed by a/an "..vars[3])
            elseif vars[4] == "arrow" then
                print(vars[2].." was shot by "..vars[3])
                sendToWebhook(vars[2].." was shot by "..vars[3])
            else
                print(vars[2].." was slain by "..vars[3])
                sendToWebhook(vars[2].." was slain by "..vars[3])
            end
        end
    elseif vars[1] == "join" then
        writeTime()
        term.setTextColor(colors.green)
        write("+ "..vars[2])
        term.setTextColor(colors.yellow)
        print(" joined the game")
        sendToWebhook(vars[2].." joined the game")
    elseif vars[1] == "leave" then
        writeTime()
        term.setTextColor(colors.red)
        write("- ")
        term.setTextColor(colors.green)
        write(vars[2])
        term.setTextColor(colors.yellow)
        print(" left the game")
        sendToWebhook(vars[2].." left the game")
    elseif vars[1] == "command" then
        writeTime()
        term.setTextColor(colors.magenta)
        write(vars[2])
        term.setTextColor(colors.white)
        print(": \\"..vars[3].." "..table.concat(vars[4], " "))
    elseif vars[1] == "modem_message" then
        if vars[3] == 2 and vars[4] == 2 and vars[5].username and type(vars[5].message) == "table" then
            writeTime()
            term.setTextColor(colors.cyan)
            write(vars[5].username)
            term.setTextColor(colors.white)
            print(": "..textutils.serialize(vars[5].message))
        elseif vars[3] == channel and vars[4] == channel and vars[5].username and type(vars[5].message) == "string" then
            writeTime()
            term.setTextColor(colors.cyan)
            write(vars[5].username)
            term.setTextColor(colors.white)
            print(": "..vars[5].message)
        end
    end
end
