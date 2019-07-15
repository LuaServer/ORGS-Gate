
local config = {
    numOfJobWorkers = 0,
    
    mysql = {
        --path = "/tmp/mysql.sock",
        
        host = "192.168.0.55",
        port = 3306,
        user = "funkii",
        password = "12345678",
        
        -- path = "/var/run/mysqld/mysqld.sock",
        -- user = "root",
        -- password = "qcfs_db20180628",
        
        database = "loginMaster",
        max_packet_size = 1024 * 1024,
    },
}

return config
