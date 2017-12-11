# Rojo Studio Plugin Change Log

## Current Master
* Factored out the plugin into a separate repository
* Fixed using a service as the target of a partition (part of #11)
	* There are still cases that will trigger errors, like putting an `init.lua` file inside of a service.
	* **Note that the contents of the service will be synced with the filesystem, so any existing items will be deleted!**