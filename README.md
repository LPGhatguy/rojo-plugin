<h1 align="center">Rojo Plugin for Roblox Studio</h1>
<div align="center">
	<a href="https://travis-ci.org/LPGhatguy/rojo-plugin">
		<img src="https://api.travis-ci.org/LPGhatguy/rojo-plugin.svg?branch=master" alt="Travis-CI Build Status" />
	</a>
</div>

<div>&nbsp;</div>

## The rojo-plugin repository has been merged back into [the main Rojo repository](https://github.com/LPGhatguy/rojo). This repository only exists as an archive.

## Working on Rojo Plugin
Make sure you have the latest releases of:
* [Rojo Binary](https://github.com/LPGhatguy/rojo)
* [Rojo Plugin](https://www.roblox.com/library/1211549683/Rojo-Studio-Plugin-0-3-1)
* [Anaminus' HotSwap Plugin](https://www.roblox.com/library/184216383/HotSwap-v1-1)

After all those things are set up:
* Set `dev` to `true` in `src/Config.lua`
	* This changes the name of the plugins' toolbar to indicate it's the one you're working on
	* This also changes the default port from 8000 to 8001
* Open a new place and enable HTTP requests
* Run `rojo serve` in the root of this repository
* Use the stable version of the Rojo Plugin to sync into the place
* Use HotSwap to select `ReplicatedStorage.Rojo` as the swap target

Once all of that's done, just play (F5) and stop (shift+F5) to test plugin code.

The [main Rojo repository](https://github.com/LPGhatguy/rojo) has a `test-project` folder with a Rojo project pre-configured for use with the development mode of this plugin. From the root of that repository, you can use `cargo run -- serve test-project` when working on the server and client at the same time.

## License
Rojo is available under the terms of the MIT license. See [LICENSE.md](LICENSE.md) for details.