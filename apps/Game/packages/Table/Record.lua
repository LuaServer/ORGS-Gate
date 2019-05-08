
local Struct = {
    id = 0,
    rid = 0,
    home = '',
    player = '',
    missions = '',
}

local Define = {
    id = "int NOT NULL AUTO_INCREMENT PRIMARY KEY",
    rid = "int NOT NULL",
    home = "longblob NOT NULL",
    player = "longblob NOT NULL",
    missions = "longblob NOT NULL",
}

local Indexes = {
    "UNIQUE KEY `rid` (`rid`)  USING HASH",
}

return {
    Struct = Struct,
    Define = Define,
    Indexes = Indexes,
    Name = "Record",
}
