ChatCommands = {}

ChatCommands.name = "COMMAND"
ChatCommands.delimiter = "/"
ChatCommands.colors = {
    info = Color("2980b9"),
    success = Color("27ae60"),
    warning = Color("d35400"),
    danger = Color("c0392b"),
    muted = Color("bdc3c7"),
    white = Color("ffffff")
}

ChatCommands.commands = {
    spawn = {
        conditions = {
            isInGame = true,
            isHost = true
        },
        callback = function(parameters)
            local count = ChatCommands.count(parameters)
            if count ~= 0 then
                ChatCommands.usage("spawn")
                return
            end
            managers.network:session():spawn_players()
        end,
        help = ChatCommands.delimiter .. "spawn"
    },
    restart = {
        conditions = {
            isInHeist = true,
            isHost = true
        },
        callback = function(parameters)
            local count = ChatCommands.count(parameters)
            if count ~= 0 then
                ChatCommands.usage("restart")
                return
            end
            managers.game_play_central:restart_the_game()
        end,
        help = ChatCommands.delimiter .. "restart"
    },
    tp = {
        conditions = {
            isInHeist = true,
            IsNotInCustody = true
        },
        callback = function(parameters)
            local count = ChatCommands.count(parameters)
            local rotation = managers.player:player_unit():camera():rotation()
            if count == 1 then
                local peer = ChatCommands.getPeer(parameters[1])
                if not peer then
                    ChatCommands.playerNotFound(parameters[1])
                    return
                end
                local position = peer:unit():position()
                managers.player:warp_to(position, rotation)
            elseif count == 3 then
                local x = tonumber(parameters[1]) or 0
                local y = tonumber(parameters[2]) or 0
                local z = tonumber(parameters[3]) or 0
                local position = Vector3(x, y, z)
                managers.player:warp_to(position, rotation)
            else
                ChatCommands.usage("tp")
            end
        end,
        help = ChatCommands.delimiter .. "tp <player_number> | <player_color> | <x> <y> <z>"
    },
    kick = {
        conditions = {
            isHost = true
        },
        callback = function(parameters)
            local count = ChatCommands.count(parameters)
            if count ~= 1 then
                ChatCommands.usage("kick")
                return
            end
            local peer = ChatCommands.getPeer(parameters[1])
            if not peer then
                ChatCommands.playerNotFound(parameters[1])
                return
            end
            if ChatCommands.isPeerSelf(peer) then
                ChatCommands.message("You cannot kick yourself", ChatCommands.colors.warning)
                return
            end
            local session = managers.network:session()
            session:send_to_peers("kick_peer", peer:id(), 0)
            session:on_peer_kicked(peer, peer:id(), 0)
        end,
        help = ChatCommands.delimiter .. "kick <player_number> | <player_color>"
    },
    ban = {
        conditions = {
        },
        callback = function(parameters)
            local count = ChatCommands.count(parameters)
            if count ~= 1 then
                ChatCommands.usage("ban")
                return
            end
            local peer = ChatCommands.getPeer(parameters[1])
            if not peer then
                ChatCommands.playerNotFound(parameters[1])
                return
            end
            if ChatCommands.isPeerSelf(peer) then
                ChatCommands.message("You cannot ban yourself", ChatCommands.colors.warning)
                return
            end
            managers.ban_list:ban(peer:user_id(), peer:name())
            ChatCommands.message(peer:name() .. " has been banned", ChatCommands.colors.info)
            if Network:is_server() then
                local session = managers.network:session()
                session:send_to_peers("kick_peer", peer:id(), 6)
                session:on_peer_kicked(peer, peer:id(), 6)
            end
        end,
        help = ChatCommands.delimiter .. "ban <player_number> | <player_color>"
    },
    profile = {
        conditions = {
        },
        callback = function(parameters)
            local count = ChatCommands.count(parameters)
            if count ~= 1 then
                ChatCommands.usage("profile")
                return
            end
            local peer = ChatCommands.getPeer(parameters[1])
            if not peer then
                ChatCommands.playerNotFound(parameters[1])
                return
            end
            local url = "https://steamcommunity.com/profiles/" .. peer:user_id() .. "/stats/PAYDAY2"
            Steam:overlay_activate("url", url)
        end,
        help = ChatCommands.delimiter .. "profile <player_number> | <player_color>"
    },
    mods = {
        conditions = {
        },
        callback = function(parameters)
            local count = ChatCommands.count(parameters)
            if count ~= 1 then
                ChatCommands.usage("mods")
                return
            end
            local peer = ChatCommands.getPeer(parameters[1])
            if not peer then
                ChatCommands.playerNotFound(parameters[1])
                return
            end
            if ChatCommands.isPeerSelf(peer) then
                ChatCommands.message("You cannot get your own mod list", ChatCommands.colors.warning)
                return
            end
            local mods = peer:synced_mods()
            local count = 0
            local message = "\n"
            for key, mod in ipairs(mods) do
                if not mod.name then
                    goto continue
                end
                if mod.name == "SuperBLT" then
                    goto continue
                end
                count = count + 1
                message = message .. "- " .. mod.name .. "\n"
                ::continue::
            end
            if count > 0 then
                message = message .. tostring(count) .. " mod" .. (count > 1 and "s" or "") .. " installed"
            else
                message = "No mod installed"
            end
            ChatCommands.message(message, ChatCommands.colors.info)
        end,
        help = ChatCommands.delimiter .. "mods <player_number> | <player_color>"
    },
    exit = {
        conditions = {
        },
        callback = function(parameters)
            local count = ChatCommands.count(parameters)
            if count ~= 0 then
                ChatCommands.usage("exit")
                return
            end
            os.exit()
        end,
        help = ChatCommands.delimiter .. "exit"
    },
    help = {
        conditions = {
        },
        callback = function(parameters)
            local count = ChatCommands.count(parameters)
            if count == 0 then
                local message = "\n"
                message = message .. ChatCommands.commands["spawn"].help .. "\n"
                message = message .. ChatCommands.commands["restart"].help .. "\n"
                message = message .. ChatCommands.commands["tp"].help .. "\n"
                message = message .. ChatCommands.commands["kick"].help .. "\n"
                message = message .. ChatCommands.commands["ban"].help .. "\n"
                message = message .. ChatCommands.commands["profile"].help .. "\n"
                message = message .. ChatCommands.commands["mods"].help .. "\n"
                message = message .. ChatCommands.commands["exit"].help .. "\n"
                message = message .. ChatCommands.commands["help"].help
                ChatCommands.message(message, ChatCommands.colors.info)
            elseif count == 1 then
                if ChatCommands.commands[parameters[1]] then
                    ChatCommands.message(ChatCommands.commands[parameters[1]].help, ChatCommands.colors.info)
                else
                    ChatCommands.message("Invalid command", ChatCommands.colors.danger)
                end
            else
                ChatCommands.usage("help")
            end
        end,
        help = ChatCommands.delimiter .. "help [command_name]"
    }
}

ChatCommands.aliases = {
    s = "spawn",
    r = "restart",
    k = "kick",
    b = "ban",
    p = "profile",
    m = "mods",
    h = "help"
}

function ChatCommands.execute(message)
    ChatCommands.previousCommand = message
    local parameters = ChatCommands.split(message)
    local name = string.sub(table.remove(parameters, 1), 2)
    if ChatCommands.aliases[name] then
        name = ChatCommands.aliases[name]
    end
    local command = ChatCommands.commands[name]
    
    if not command then
        ChatCommands.message("Invalid command", ChatCommands.colors.danger)
        return
    end
    
    if command.conditions.isInGame then
        if not Utils:IsInGameState() then
            ChatCommands.message("In game only command", ChatCommands.colors.warning)
            return
        end
    end
    
    if command.conditions.isInHeist then
        if not Utils:IsInHeist() then
            ChatCommands.message("In heist only command", ChatCommands.colors.warning)
            return
        end
    end
    
    if command.conditions.IsNotInCustody then
        if Utils:IsInCustody() then
            ChatCommands.message("Not in custody only command", ChatCommands.colors.warning)
            return
        end
    end
    
    if command.conditions.isHost then
        if not Network:is_server() then
            ChatCommands.message("Host only command", ChatCommands.colors.warning)
            return
        end
    end
    
    command.callback(parameters)
end

function ChatCommands.split(string)
    local result = {}
    for element in string:gmatch("%S+") do
        table.insert(result, element)
    end
    return result
end

function ChatCommands.count(table)
    local count = 0
    for key, value in pairs(table) do
        count = count + 1
    end
    return count
end

function ChatCommands.message(message, color)
    managers.chat:_receive_message(1, ChatCommands.name, tostring(message), color or ChatCommands.colors.white)
end

function ChatCommands.usage(name)
    ChatCommands.message("Usage: " .. ChatCommands.commands[name].help, ChatCommands.colors.danger)
end

function ChatCommands.getPeer(value)
    local name = value
    local colors = {
        green = 1,
        blue = 2,
        red = 3,
        yellow = 4,
        orange = 4
    }
    local number = nil
    if colors[value] then
        number = colors[value]
    else
        number = tonumber(value)
    end
    if number == nil then
        return false
    end
    local session = managers.network:session()
    return session:peer(number)
end

function ChatCommands.playerNotFound(value)
    ChatCommands.message("Player " .. tostring(value) .. " not found", ChatCommands.colors.warning)
end

function ChatCommands.isPeerSelf(peer)
    return tostring(peer:user_id()) == tostring(Steam:userid())
end