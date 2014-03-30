package enh;

import enh.Constants;
import enh.Builders;
import anette.Bytes;


@:build(enh.macros.RPCMacro.addRpcUnserializeMethod())
class ClientManager
{
    public static var myId:Int; // Workaround LD48
    var enh:Enh;
    var em:EntityManager;
    var ec:EntityCreatowr;
    var me:Entity;

    public function new(enh:Enh)
    {
        this.enh = enh;
        this.em = Enh.em;
        this.ec = enh.ec;
    }

    public function processDatas(anconn:anette.Connection)
    {
        var input = anconn.input;
        var msgType = input.readByte();

        // SWITCH PLEASE
        if(msgType == CONST.CONNECTION)  // MY connection
        {
            myId = input.readInt16();
            trace("CONNECTION " + myId);
            me = em.createEntity();

            anconn.output.writeByte(CONST.CONNECTION);

            em.pushEvent("CONNECTION", me, {});
        }

        if(msgType == CONST.CREATE || msgType == CONST.CREATE_OWNED)
        {
            var ownerId = -1;  // UGLY TO FIX YES OK OK
            if(msgType == CONST.CREATE_OWNED)
                ownerId = input.readByte();

            var argsLength = input.readByte();
            var args:Array<Int> = [];
            if(argsLength > 0)
            {
                for(i in 0...argsLength)
                {
                    args.push(input.readInt16());
                }
            }

            var entityTypeId = input.readInt16();
            var entityId = input.readInt16();
            var event = input.readBoolean();

            trace("entity type id " + entityTypeId);
            var entityTypeName = ec.entityTypeNameById[entityTypeId];
            trace("entityTypeName " + entityTypeName + " / entityTypeNameById " + ec.entityTypeNameById);
            var entity = enh.ec.functionByEntityType[entityTypeName](args);
            em.setId(entity, entityId);
            trace("entity unique id " + entityId);
            trace("entity local id " + entity);

            if(msgType == CONST.CREATE_OWNED)
                em.addComponent(entity, new CNetOwner(ownerId));

            if(event)
                em.pushEvent(entityTypeName.toUpperCase() + "_CREATE", entity, {ownerId:ownerId, x:args[0], y:args[1]});

            for(compId in enh.ec.componentsNameByEntityId[entityTypeId])
            {
                enh.ec.unserialize(compId, entity, input);
            }

            trace("comps " + em.debugGetComponentsStringOfEntity(entity));
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
        //             args.push(ba.readInt16());
        //         }
        //     }
        //     trace("args " + args);

        //     var entityTypeId = ba.readInt16();
        //     var entityId = ba.readInt16();
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
            trace("update");
            var entityTypeId = input.readInt16();
            var entityId = input.readInt16();
            var entity = em.getEntityFromId(entityId);

            for(compId in enh.ec.componentsNameByEntityId[entityTypeId])
            {
                enh.ec.unserialize(compId, entity, input);
            }
        }

        if(msgType == CONST.DELETE)
        {
            var entityId = input.readInt16();
            var entity = em.getEntityFromId(entityId);
            em.killEntity(entity);
        }

        if(msgType == CONST.SYNC)
        {
            var entityTypeId = input.readInt16();
            var entityId = input.readInt16();
            var entity = em.getEntityFromId(entityId);
            // trace('entitytypeid $entityTypeId / entityid $entityId / entity $entity');

            for(compId in enh.ec.syncComponentsNameByEntityId[entityTypeId])
            {
                enh.ec.unserialize(compId, entity, input);
            }
        }

        if(msgType == CONST.ADD_COMPONENT)
        {
            var entityId = input.readInt16();
            var compId = input.readInt16();
            var entity = em.getEntityFromId(entityId);

            enh.ec.addComponent(compId, entity);
        }

        if(msgType == CONST.ADD_COMPONENT2)
        {
            trace("ADD_COMPONENT2");
            var entityId = input.readInt16();
            var compId = input.readInt16();
            var entity = em.getEntityFromId(entityId);

            enh.ec.addComponent(compId, entity);
            enh.ec.unserialize(compId, entity, input);
        }

        if(msgType == CONST.RPC)
        {
            unserializeRpc(input);
        }
    }
}