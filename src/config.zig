pub const Database = struct {
    db_host: []const u8,
    db_port: u16,
    db_database: []const u8,
    db_username: []const u8,
    db_password: []const u8,
};
