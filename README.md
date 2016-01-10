ECS-Networking-Haxe
===================

_Check out [OSIS](https://github.com/Dvergar/OSIS) for a better architecture of this ECS._

Entity Component System architecture with networking support, component state synchronization + RPC (kinda).

### Goal
Remove the hassle of serializing, unserializing and dispatching datas. Abstract most of the network code without killing the bandwidth. Having both abstraction and flexibility. Profiting of the ECS architecture to easily share and synchronize datas.

### Features
* Network oriented ECS architecture
* Automatic serialization per component/entity
* `startServer("127.0.0.1", 9999);` to start a server
* `connect("127.0.0.1", 9999);` to connect to a server
* `@RPC("NET_ATTACK", 50) {dmg:Int};` to send a message
* `private function onNetAttack(entity:String, ev:Dynamic){}` to catch it
* `@networked` on addComponent to broadcast a component add
* `@sync` on addComponent (in EntityCreator only) to synchronize it
* `@short`, `@string`... in front of a component member variable will define the proper network serialization
* Hooks for client sockets


### Road Map (sorted by priority)
* More types : @bit @array
* Network type inference
* Typed events
* Benchmarking
* Network culling


### What kind of ECS is it ?
This is a [T=Machine](http://t-machine.org/index.php/2007/09/03/entity-systems-are-the-future-of-mmog-development-part-1/)-like ECS where an entity is just an ID, components are only datas, systems handles the logic and act on components.
