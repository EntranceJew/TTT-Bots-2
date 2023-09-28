local FCVAR = FCVAR_ARCHIVE + FCVAR_NOTIFY + FCVAR_REPLICATED + FCVAR_LUA_SERVER

-- Gameplay-effecting cvars
-- todo

-- Naming cvars
CreateConVar("ttt_bot_names_allowcommunity", "1", FCVAR,
    "Enables community-suggested names, replacing many auto-generated names. WARNING: Potentially offensive, not family-friendly.")
CreateConVar("ttt_bot_names_communityonly", "1", FCVAR,
    "Disables auto-generated names, only using community-suggested names. NOTE: ttt_bot_names_allowcommunity must be enabled.")
CreateConVar("ttt_bot_names_canleetify", "1", FCVAR,
    "Enables leetifying of ALL names. (e.g. 'John' -> 'j0hn'). See ttt_bot_names_leetify_chance.")
CreateConVar("ttt_bot_names_canusenumbers", "1", FCVAR,
    "Enables adding numbers to autogenerated names. (e.g. 'John' -> 'John69')")
CreateConVar("ttt_bot_names_canusespaces", "1", FCVAR,
    "Enables using spaces in autogenerated names. (e.g. 'John Doe' -> 'JohnDoe')")
CreateConVar("ttt_bot_names_allowgeneric", "1", FCVAR,
    "Enables generic usernames, generated by ChatGPT. They're less appropriate than random names but more appropriate than community-suggested names.")

-- Debug cvars
CreateConVar("ttt_bot_debug_pathfinding", "1", FCVAR,
    "[May console spam. Development use only] Enables debug for pathfinding. Requires built-in developer convar to be 1 for drawings.")
CreateConVar("ttt_bot_debug_look", "1", FCVAR,
    "[May console spam. Development use only] Enables debug for looking at things. Requires built-in developer convar to be 1 for drawings.")
CreateConVar("ttt_bot_debug_misc", "1", FCVAR,
    "[May console spam. Development use only] Enables misc debug. Requires built-in developer convar to be 1 for drawings.")
CreateConVar("ttt_bot_debug_stuckpositions", "1", FCVAR,
    "[May console spam. Development use only] Enables debug for stuck positions. Requires built-in developer convar to be 1 for drawings.")
CreateConVar("ttt_bot_debug_obstacles", "1", FCVAR,
    "[May console spam. Development use only] Enables debug for recognized obstacles. Requires built-in developer convar to be 1 for drawings.")
CreateConVar("ttt_bot_debug_doors", "1", FCVAR,
    "[May console spam. Development use only] Enables debug for doors. Requires built-in developer convar to be 1 for drawings.")
CreateConVar("ttt_bot_debug_attack", "1", FCVAR,
    "[May console spam. Development use only] Enables debug for attacking. Requires built-in developer convar to be 1 for drawings.")
CreateConVar("ttt_bot_debug_evil", "1", FCVAR,
    "[May console spam. Development use only] Enables debug for the Evil Coordinator.")
CreateConVar("ttt_bot_debug_inventory", "1", FCVAR,
    "[May console spam. Development use only] Enables debug for inventory management.")

-- Pathfinding cvars
CreateConVar("ttt_bot_pathfinding_cpf", "50", FCVAR,
    "Don't change this unless you know what you are doing. How many pathfinding calculations to do per frame. Higher values = more CPU usage, but faster pathfinding.")
CreateConVar("ttt_bot_pathfinding_cpf_scaling", "1", FCVAR,
    "Don't change this unless you know what you are doing. Should we dynamically multiply the pathfinding calculations per frame by the number of bots? (e.g. 50 cpf * 2 bots = 100 cpf)")
CreateConVar("ttt_bot_enable_rdm", "0", FCVAR, -- TODO: Implement RDM
    "Enables RDM (random deathmatch). This isn't advised for most situations, but can offer some extra variety should you want it.")

-- Behavior cvars
CreateConVar("ttt_bot_radar_chance", "100", FCVAR,
    "Chance that a traitor bot will simulate having radar as a traitor (internally they must be an 'evil' role).")
CreateConVar("ttt_bot_disable_coordinator", "0", FCVAR,
    "Disables the Evil Coordinator module. Evil bots will not coordinate with each other.")
