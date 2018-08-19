--1

local version = 1

local latest = http.get("https://raw.githubusercontent.com/jakedacatman/ChatLogger/master/ChatLogger.lua")
if latest ~= nil then
    local latestVersion = tonumber(string.sub(latest.readLine(), 3))

    if latestVersion > version then
        print("Out of date; upgrading.")
        fs.delete(shell.getRunningProgram())
        shell.run("wget https://raw.githubusercontent.com/jakedacatman/ChatLogger/master/ChatLogger.lua chatLogger.lua")
        print("Update complete!")
        print("If you wish to run the new version, then hold CTRL+R and run chatLogger.lua.")
    end
else
    print("Failed to check for new version.")
end

local chatbox = peripheral.find("chat_box")
local monitor = peripheral.find("monitor", function(name, object) return object.isColor() end)
if not monitor then print("This works best with Advanced monitors; consider upgrading.") end

local modem = peripheral.find("modem", function(name, object) return object.isWireless() end)

term.redirect(monitor)

monitor.clear()
monitor.setCursorPos(1,1)
monitor.setTextScale(0.5)

if modem then
    modem.open(2)
end

--print("chat booted!")

while true do
    local vars = {os.pullEvent()}
    if vars[1] == "chat" then
        term.setTextColor(colors.green)
        write(vars[2])
        term.setTextColor(colors.white)
        print(": "..vars[3])
    elseif vars[1] == "death" then
        term.setTextColor(colors.white)
        if vars[3] == nil then
            print(vars[2].." died")
        else
            if vars[4] == "mob" then
                print(vars[2].." was killed by a/an "..vars[3])
            elseif vars[4] == "arrow" then
                print(vars[2].." was shot by "..vars[3])
            else
                print(vars[2].." was slain by "..vars[3])
            end
        end
    elseif vars[1] == "join" then
        term.setTextColor(colors.green)
        write("+ "..vars[2])
        term.setTextColor(colors.yellow)
        print(" joined the game")
    elseif vars[1] == "leave" then
        term.setTextColor(colors.red)
        write("- ")
        term.setTextColor(colors.green)
        write(vars[2])
        term.setTextColor(colors.yellow)
        print(" left the game")
    elseif vars[1] == "modem_message" then
        if vars[3] == 2 and vars[4] == 2 then
            term.setTextColor(colors.cyan)
            write(vars[5].username)
            term.setTextColor(colors.white)
            print(": "..textutils.serialize(vars[5].message))
        end
    end
end
