
local Struct = {
    id = 0,
    rid = 0,
    type = 0,
    count = 0, --完成次数
    totalCount = 0, --总次数
}

local Define = {
    id = "int NOT NULL AUTO_INCREMENT PRIMARY KEY",
    rid = "int NOT NULL",
    type = "int NOT NULL",
    count = "int NOT NULL",
    totalCount = "int NOT NULL",
}

local Indexes = {
    "UNIQUE KEY `crid` (`type`, `rid`)  USING HASH",
}

return {
    Struct = Struct,
    Define = Define,
    Indexes = Indexes,
    Name = "Chapter",
}
