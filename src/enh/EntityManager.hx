package enh;

// import enh.Uuid;
import enh.macros.Template;
import enh.Builders;
import enh.Constants;


typedef ComponentType = String;
typedef EventType = String;
typedef Entity = Int;


class EntityManager
{
    var componentStores:Map<ComponentType, Map<Entity, Component>> = new Map();
    var listenerTypes:Map<EventType, Array<Dynamic>> = new Map<ComponentType, Array<Dynamic>>();
    var killables:List<Entity> = new List<Entity>();
    var entitiesById:Map<Int, Entity> = new Map<Int, Entity>();
    var ids:Int;
    var entityIds:Int;

    public function new()
    {
        this.ids = 0;
        this.entityIds = 0;
    }

    public function createEntity()
    {
        return entityIds++;
    }

    //////////
    // EVENTS
    //////////

    public function registerListener(eventName:EventType, f:Dynamic)
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

    public function pushEvent(eventName:EventType, ?entity:Entity,
                              ?event:Dynamic, ?cb:Dynamic)
    {
        // trace("pushEvent " + eventName);
        var listeners = listenerTypes.get(eventName);
        if(listeners == null) throw "No listener for event type : " + eventName;

        var success = true;
        if(event == null)
        {
            for(func in listeners)
            {
                if(func(entity) == false)
                {
                    trace("event blocked 1");
                    success = false;
                    break;
                }
            }
        }
        else
        {
            for(func in listeners)
            {
                if(func(entity, event) == false) 
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

    public function getId():Int
    {
        return ids++;
    }

    public function setId(entity:Entity, ?id:Int):Int
    {
        if(id == null) id = ids++;

        entitiesById.set(id, entity);
        addComponent(entity, new CId(id));

        return id;
    }

    public function getEntityFromId(id:Int):Entity
    {
        return entitiesById.get(id);
    }

    public function getIdFromEntity(entity:Entity):Int
    {
        // RPCS need an id no matter what
        (entity != CONST.DUMMY) ?
            return getComponent(entity, CId).value:
            return CONST.DUMMY;
    }

    public function addComponent<T>(entity:Entity, component:T):T
    {
        var className:String = Type.getClassName(Type.getClass(component));
        var store:Map<Entity, Component> = componentStores.get(className);

        if(store == null)
        {
            store = new Map<Entity, Component>();
            componentStores.set(className, store);
        }

        store.set(entity, cast component);
        return component;
    }

    public function removeComponent<T>(entity:Entity, component:T)
    {
        // Need to throw an error, this runs with removeComponentOfType args :( 
        var store:Map<Entity, Component> = componentStores.get(
                                            Type.getClassName(
                                            Type.getClass(component)));

        var c = cast component;
        c._detach();
        store.remove(entity);
    }

    public function removeComponentOfType<T>(entity:Entity,
                                             componentClass:Class<T>)
    {
        var className:String = Type.getClassName(componentClass);
        var store:Map<Entity, Component> = componentStores.get(className);

        // DEBUG
        if(!hasComponent(entity, componentClass))
            throw("Remove failed : " + componentClass + 
                    " is not associated to the entity " + entity);

        store.get(entity)._detach();
        store.remove(entity);
    }

    public function getComponentsOfType<T>(componentClass:Class<T>)
                                            :Iterator<T>
    {
        var className = Type.getClassName(componentClass);
        var store:Map<Entity, Component> = componentStores.get(className);

        if(store == null)
            return new Map<Entity, T>().iterator();

        return cast store.iterator();
    }

    public function getComponent<T>(entity:Entity, componentClass:Class<T>):T
    {
        var className = Type.getClassName(componentClass);
        var store:Map<Entity, Component> = componentStores.get(className);

        if(store == null)
            throw("GET FAIL: there are no entities with a Component of class: "
                            + componentClass);

        var result:Component = store.get(entity);

        if(result == null)
            throw("GET FAIL: " + entity
                    + " does not possess Component of class\n   missing: "
                    + componentClass);

        return cast result;
    }

    public function getEntitiesWithComponent<T>(componentClass:Class<T>)
                                                        :Iterator<Entity>
    {
        var className = Type.getClassName(componentClass);
        var store:Map<Entity, Component> = componentStores.get(className);

        if(store == null)
            return new Map<Entity, Component>().keys();

        return store.keys();
    }

    public function killEntity(entity:Entity)
    {
        // trace("killEntity " + entity);
        this.killables.push(entity);
    }

    public function killEntityNow(entity:Entity)
    {
        trace("killEntityNow " + entity);
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
    }

    public function hasEntity(entity:Entity)
    {
        for(componentStore in componentStores.iterator())
            if(componentStore.exists(entity))
                return true;

        return false;
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
        var store:Map<Entity, Component> = componentStores.get(className);

        if(store != null)
        {
            for(entity in store.keys())
            {
                killEntity(entity);
            }
        }
    }

    public function hasComponent<T>(entity:Entity, componentClass:Class<T>)
                                                                      :Bool
    {
        var className = Type.getClassName(componentClass);
        var store:Map<Entity, Component> = componentStores.get(className);

        (store == null) ?
            return false:
            return store.exists(entity);
    }

    public function debugGetComponentsStringOfEntity(entity:Entity):String
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