package enh;

import enh.Uuid;
import enh.macros.Template;
import enh.Builders;


class EntityManager
{
    var componentStores:Map<String, Map<String, Component>>;
    var parentChild:Map<String, Array<String>>;
    var listenerTypes:Map<String, Array<Dynamic>>;
    var killables:List<String>;
    public var entitiesById:Map<Int, String>; // switch to private, was just for ld debugging
    var ids:Int;

    public function new()
    {
        this.componentStores = new Map();
        this.listenerTypes = new Map<String, Array<Dynamic>>();
        this.parentChild = new Map<String, Array<String>>();
        this.entitiesById = new Map<Int, String>();
        this.killables = new List<String>();
        this.ids = 0;
    }

    public function createEntity()
    {
        var id = Uuid.uuid();
        return id;
    }

    //////////
    // EVENTS
    //////////

    public function registerListener(eventName:String, f:Dynamic)
    {
        // trace("register listener " + eventName);
        var listeners = listenerTypes.get(eventName);

        if(listeners == null)
        {
            listenerTypes.set(eventName, []);
            listeners = listenerTypes.get(eventName);
        }

        listeners.push(f);
    }

    public function pushEvent(eventName:String, entity:String, ?event:Dynamic,
                              ?cb:Dynamic)
    {
        // trace("pushEvent " + eventName);
        var listeners = listenerTypes.get(eventName);
        if(listeners == null) throw "No listener for event type : " + eventName;

        var success = true;
        if(event == null)
        {
            for(f in listeners)
            {
                if(f(entity) == false)
                {
                    trace("event blocked 1");
                    success = false;
                    break;
                }
            }
        }
        else
        {
            for(f in listeners)
            {
                if(f(entity, event) == false) 
                {
                    trace("event blocked 2");
                    success = false;
                    break;
                }
            }
        }

        if(success && cb != null) cb();
        return success;
    }

    //////////////
    // COMPONENTS
    //////////////

    public function assignId(entity:String):Int
    {
        var id = ids++;
        entitiesById.set(id, entity);
        addComponent(entity, new CId(id));
        return id;
    }

    // Switch argument order
    public function setId(id:Int, entity:String)
    {
        entitiesById.set(id, entity);
        addComponent(entity, new CId(id));
    }

    public function getEntityWithId(id:Int):String
    {
        return entitiesById.get(id);
    }

    public function getIdFromEntity(entity:String):Int
    {
        return getComponent(entity, CId).value;
    }

    public function addComponent<T>(entity:String, component:T):T
    {
        var className = Type.getClassName(Type.getClass(component));
        var store:Map<String, Component> = componentStores.get(className);

        if(store == null)
        {
            store = new Map<String, Component>();
            componentStores.set(className, store);
        }

        store.set(entity, cast component);
        return component;
    }

    public function removeComponent<T>(entity:String, component:T)
    {
        // Need to throw an error, this runs with removeComponentOfType args :( 
        var store:Map<String, Component> = componentStores.get(
                                            Type.getClassName(
                                            Type.getClass(component)));

        var c = cast component;
        c._detach();
        store.remove(entity);
    }

    public function removeComponentOfType<T>(entity:String,
                                             componentClass:Class<T>)
    {
        var className = Type.getClassName(componentClass);
        var store:Map<String, Component> = componentStores.get(className);

        // DEBUG
        if(!hasComponent(entity, componentClass))
        {
            throw("Remove failed : " + componentClass + 
                    " is not associated to the entity " + entity);
        }

        store.get(entity)._detach();
        store.remove(entity);
    }

    public function getAllComponentsOfType<T>(componentClass:Class<T>)
                                            :Iterator<T>
    {
        var className = Type.getClassName(componentClass);
        var store:Map<String, Component> = componentStores.get(className);

        if(store == null)
        {
            return new Map<String, T>().iterator();
        }

        return cast store.iterator();
    }

    public function getComponent<T>(entity:String, componentClass:Class<T>):T
    {
        var className = Type.getClassName(componentClass);
        var store:Map<String, Component> = componentStores.get(className);

        if (store == null)
        {
            throw("GET FAIL: there are no entities with a Component of class: "
                            + componentClass);
        }

        var result:Component = store.get(entity);

        if (result == null)
        {
            throw("GET FAIL: " + entity
                    + " does not possess Component of class\n   missing: "
                    + componentClass);
        }

        return cast result;
    }

    public function getEntitiesWithComponent<T>(componentClass:Class<T>)
                                                        :Iterator<String>
    {
        var className = Type.getClassName(componentClass);
        var store:Map<String, Component> = componentStores.get(className);

        if(store == null)
        {
            return new Map<String, Component>().keys();
        }

        return store.keys();
    }

    public function killEntity(entity:String)
    {
        // trace("killEntity " + entity);
        this.killables.push(entity);
    }

    public function killEntityNow(entity:String)
    {
        // trace("killEntityNow " + entity);

        // IDS
        if(hasComponent(entity, CId))
        {
            var id = getComponent(entity, CId).value;
            entitiesById.remove(id);
        }

        // ENTITY
        for(componentStore in componentStores.iterator())
        {
            if(componentStore.exists(entity))
            {
                componentStore.get(entity)._detach();
                componentStore.remove(entity);
            }
        }


        // PARENT CHILD
        var children = parentChild.get(entity);

        if(children != null) {
            for(child in children)
            {
                killEntity(child);
            }
        }

        parentChild.remove(entity);
    }

    public function processKills()
    {
        for(entity in killables.iterator())
        {
            killEntityNow(entity);
            killables.remove(entity);
        }
    }

    public function killEntitiesOfType<T>(componentClass:Class<T>)
    {
        var className = Type.getClassName(componentClass);
        var store:Map<String, Component> = componentStores.get(className);

        if(store != null)
        {
            for(entity in store.keys())
            {
                killEntity(entity);
            }
        }
    }

    public function hasComponent<T>(entity:String, componentClass:Class<T>)
                                                                      :Bool
    {
        var className = Type.getClassName(componentClass);
        var store:Map<String, Component> = componentStores.get(className);

        if(store == null)
        {
            return false;
        }
        else
        {
            return store.exists(entity);
        }
    }

    // SetLink name so that it's not confusing for not linked cases
    public function setChild(entity:String, parent:String)
    {
        var children = parentChild.get(entity);

        if(children == null)
        {
            parentChild.set(parent, new Array());
        }

        parentChild.get(parent).push(entity);
    }

    public function removeChild(entity:String, parent:String)
    {
        parentChild.get(parent).remove(entity);
    }

    public function debugGetComponentsStringOfEntity(entity:String):String
    {
        var components = "";

        for(componentType in componentStores.keys())
        {
            var tmpEntities = componentStores.get(componentType).keys();
            
            for(tmpEntity in tmpEntities)
            {
                if(tmpEntity == entity)
                {
                    components += componentType + ", ";
                }
            }
        }

        return components;
    }
}