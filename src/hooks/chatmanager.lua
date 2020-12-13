_G.CloneClass(ChatManager)
function ChatManager:send_message(channel_id, sender, message)
    if ChatCommands then
        if string.sub(message, 1, 1) == ChatCommands.delimiter then
            managers.chat:_receive_message(1, ChatCommands.name, message, ChatCommands.colors.muted)
            ChatCommands.execute(message)
            return
        end
    end
    self.orig.send_message(self, channel_id, sender, message)
end