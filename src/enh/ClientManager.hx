package enh;

import enh.Constants;
import enh.Builders;


@:build(enh.macros.RPCMacro.addRpcUnserializeMethod())
class ClientManager
{
    private var enh:Enh;
    private var em:EntityManager;
    private var ec:EntityCreatowr;
    // private var entitiesById:Map<Int, String>;
    private var me:Entity;
    public static var myId:Int; // Workaround LD48

    public function new(enh:Enh)
    {
        // this.entitiesById = new Map();
        this.enh = enh;
        this.em = enh.em;
        this.ec = enh.ec;
    }

    public function processDatas(conn:Connection)
    {
        var ba = conn.input;
        var msgType = ba.readByte();

        // SWITCH PLEASE
        if(msgType == CONST.CONNECTION)  // MY connection
        {
            myId = ba.readShort();
            trace("CONNECTION " + myId);
            me = em.createEntity();

            conn.output.writeByte(CONST.CONNECTION);

            em.pushEvent("CONNECTION", me, {});
        }

        if(msgType == CONST.CREATE || msgType == CONST.CREATE_OWNED)
        {
            var ownerId = -1;  // UGLY TO FIX YES OK OK
            if(msgType == CONST.CREATE_OWNED)
                ownerId = ba.readByte();

            var argsLength = ba.readByte();
            var args:Array<Int> = [];
            if(argsLength > 0)
            {
                for(i in 0...argsLength)
                {
                    args.push(ba.readShort());
                }
            }

            var entityTypeId = ba.readShort();
            var entityId = ba.readShort();
            var event = ba.readBoolean();


            trace("create entity uuid " + entityId);

            var entityTypeName = ec.entityTypeNameById[entityTypeId];
            var entity = enh.ec.functionByEntityType[entityTypeName](args);
            em.setId(entity, entityId);
            trace("entity created " + entity);

            if(msgType == CONST.CREATE_OWNED)
                em.addComponent(entity, new CNetOwner(ownerId));

            if(event)
                em.pushEvent(entityTypeName.toUpperCase() + "_CREATE", entity, {id:ownerId});

            for(compId in enh.ec.componentsNameByEntityId[entityTypeId])
            {
                enh.ec.unserialize(compId, entity, ba);
            }

            trace("comps " + em.debugGetComponentsStringOfEntity(entity));

            // entitiesById[entityUUID] = entity;
        }

        // if(msgType == CONST.CREATE_OWNED)
        // {
        //     var ownerId = ba.readByte();
            
        //     var argsLength = ba.readByte();
        //     trace("argsLength " + argsLength);
        //     var args:Array<Int> = [];
        //     if(argsLength > 0)
        //     {
        //         for(i in 0...argsLength)
        //         {
        //             args.push(ba.readShort());
        //         }
        //     }
        //     trace("args " + args);

        //     var entityTypeId = ba.readShort();
        //     var entityId = ba.readShort();
        //     trace("create owned entity uuid " + entityId);

        //     var entityTypeName = ec.entityTypeNameById[entityTypeId];
        //     var entity = enh.ec.functionByEntityType[entityTypeName](args);
        //     em.addComponent(entity, new CNetOwner(ownerId));
        //     trace("entity owned created " + entity);

        //     for(compId in enh.ec.componentsNameByEntityId[entityTypeId])
        //     {
        //         enh.ec.unserialize(compId, entity, ba);
        //     }

        //     trace("comps " + em.debugGetComponentsStringOfEntity(entity));

        //     // entitiesById[entityUUID] = entity;
        //     em.setId(entity, entityId);
        // }


        if(msgType == CONST.UPDATE)
        {
            var entityTypeId = ba.readShort();
            var entityId = ba.readShort();
            // var entity = entitiesById[entityUUID];
            var entity = em.getEntityFromId(entityId);

            for(compId in enh.ec.componentsNameByEntityId[entityTypeId])
            {
                enh.ec.unserialize(compId, entity, ba);
            }
        }

        if(msgType == CONST.DELETE)
        {
            var entityId = ba.readShort();
            // var entity = entitiesById[entityUUID];
            var entity = em.getEntityFromId(entityId);
            em.killEntity(entity);
            // entitiesById.remove(entityUUID);
        }

        if(msgType == CONST.SYNC)
        {
            var entityTypeId = ba.readShort();
            var entityId = ba.readShort();
            // var entity = entitiesById[entityUUID];
            var entity = em.getEntityFromId(entityId);

            for(compId in enh.ec.componentsNameByEntityId[entityTypeId])
            {
                enh.ec.unserialize(compId, entity, ba);
            }
        }

        if(msgType == CONST.ADD_COMPONENT)
        {
            var entityId = ba.readShort();
            var compId = ba.readShort();
            var entity = em.getEntityFromId(entityId);

            enh.ec.addComponent(compId, entity);

            // enh.ec.createAndUnserialize(compId, entity, ba);
        }

        if(msgType == CONST.RPC)
        {
            // trace("RPC received");
            unserializeRpc(ba, -1);
        }
    }
}