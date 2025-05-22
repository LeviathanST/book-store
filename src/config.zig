pub const Database = struct {
    host: []const u8,
    port: u16,
    database: []const u8,
    username: []const u8,
    password: []const u8,
};

pub const GlobalConfig = struct {
    port: u16,
    round_hashing: u6,
    secret: []const u8,
    client_url: []const u8,
};
