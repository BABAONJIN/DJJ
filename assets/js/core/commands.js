Convos.commands = [
  {
    command: "me",
    description: "Send message as an action.",
    example: "/me <msg>"
  },
  {
    command: "say",
    description: 'Used when you want to send a message starting with "/".',
    example: "/say <msg>"
  },
  {
    command: "topic",
    description: "Show current topic, or set a new one.",
    example: "/topic or /topic <new topic>"
  },
  {
    command: "whois",
    description: "Show information about a user.",
    example: "/whois <nick>"
  },
  {
    command: "query",
    aliases: ["q"],
    description: "Open up a new chat window with nick.",
    example: "/query <nick>"
  },
  {
    command: "msg",
    description: "Send a direct message to nick.",
    example: "/msg <nick> <msg>"
  },
  {
    command: "names",
    description: "Show participants in the channel."
  },
  {
    command: "join",
    aliases: ["j"],
    description: "Join channel and open up a chat window.",
    example: "/join <#channel>"
  },
  {
    command: "nick",
    description: "Change your wanted nick.",
    example: "/nick <nick>"
  },
  {
    command: "part",
    description: "Leave channel, and close window.",
    example: "/part"
  },
  {
    command: "close",
    description: "Close conversation with nick, defaults to current active.",
    example: "/close <nick>"
  },
  {
    command: "kick",
    description: "Kick a user from the current channel.",
    example: "/kick <nick>"
  },
  {
    command: "oper",
    aliases: ["oper"],
    description: "Verify your self as operator of the network.",
    example: "/oper operid operpassword"
  },
  {
    command: "mode",
    description: "Change mode of yourself or a user"
  },
  {
    command: "reconnect",
    description: "Restart the current connection."
  },
  {
    command: "cs",
    alias_for: "/msg chanserv",
    description: 'Short for "/msg chanserv ...".',
    example: "/cs <msg>"
  },
  {
    command: "ns",
    alias_for: "/msg nickserv",
    description: 'Short for "/msg nickserv ...".',
    example: "/ns <msg>"
  },
  {
    command: "hs",
    alias_for: "/msg hostserv",
    description: 'Short for "/msg hostserv ...".',
    example: "/hs <msg>"
  },
    {
    command: "bs",
    alias_for: "/msg botserv",
    description: 'Short for "/msg botserv ...".',
    example: "/bs <msg>"
  }
];
