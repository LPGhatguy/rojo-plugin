local Config = {
	pollingRate = 0.2,
	version = {0, 4, 0},
	expectedServerVersion = "0.4.0+",
	protocolVersion = 1,
	dev = false,
}

Config.versionString = table.concat(Config.version, ".")

return Config
