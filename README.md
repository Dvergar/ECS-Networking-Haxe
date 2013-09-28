ECS-Networking-Haxe
===================

Entity Component System architecture with networking support, component state synchronization + RPC.

***Still a work in progress...***

### Features
* Network oriented ECS architecture
* Automatic serialization per component/entity
* `startServer("127.0.0.1", 9999);` to start a server
* `connect("127.0.0.1", 9999);` to connect to a server
* `@RPC("NET_ATTACK", 50) {dmg:Int};` to send a message
* `private function onNetAttack(entity:String, ev:Dynamic){}` to catch it
* `@networked` on a component to share a component
* `@sync` on a component to synchronize it
* `@short`, `@string`... in front of a component will define the proper network serialization
* Hooks for client sockets


### Road Map
* Hooks for server socket
* Blocking & threaded sockets
* node.js server
* Plug Qookie
* Attach/detach id for lag compensation
* Network type inference
* Benchmarking
* Typed events
* @bit
