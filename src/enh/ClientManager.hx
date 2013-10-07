package enh;

import enh.Constants;
import enh.Builders;


@:build(enh.macros.RPCMacro.addRpcUnserializeMethod())
class ClientManager
{
    private var enh:Enh;
    private var em:EntityManager;
    private var ec:EntityCreatowr;
    private var entitiesById:Map<Int, String>;
    private var me:String;
    private var myId:Int;

    public function new(enh:Enh)
    {
        this.entitiesById = new Map();
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
            trace("CONNECTION");
            myId = ba.readShort();
            me = em.createEntity();

            conn.output.writeByte(CONST.CONNECTION);

            em.pushEvent("CONNECTION", me, {});
        }

        if(msgType == CONST.CREATE)
        {
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
            var entityUUID = ba.readShort();
            trace("create entity uuid " + entityUUID);

            var entityTypeName = ec.entityTypeNameById[entityTypeId];
            var entity = enh.ec.functionByEntityType[entityTypeName](args);
            trace("entity created " + entity);

            for(compId in enh.ec.componentsNameByEntityId[entityTypeId])
            {
                enh.ec.unserializeCreate(compId, entity, ba);
            }

            trace("comps " + em.debugGetComponentsStringOfEntity(entity));

            entitiesById[entityUUID] = entity;
        }

        if(msgType == CONST.CREATE_OWNED)
        {
            var ownerId = ba.readByte();
            
            var argsLength = ba.readByte();
            trace("argsLength " + argsLength);
            var args:Array<Int> = [];
            if(argsLength > 0)
            {
                for(i in 0...argsLength)
                {
                    args.push(ba.readShort());
                }
            }
            trace("args " + args);

            var entityTypeId = ba.readShort();
            var entityUUID = ba.readShort();
            trace("create owned entity uuid " + entityUUID);

            var entityTypeName = ec.entityTypeNameById[entityTypeId];
            var entity = enh.ec.functionByEntityType[entityTypeName](args);
            em.addComponent(entity, new CNetOwner(ownerId));
            trace("entity owned created " + entity);

            for(compId in enh.ec.componentsNameByEntityId[entityTypeId])
            {
                enh.ec.unserializeCreate(compId, entity, ba);
            }

            trace("comps " + em.debugGetComponentsStringOfEntity(entity));

            entitiesById[entityUUID] = entity;
        }


        if(msgType == CONST.UPDATE)
        {
            var entityTypeId = ba.readShort();
            var entityUUID = ba.readShort();
            var entity = entitiesById[entityUUID];

            for(compId in enh.ec.componentsNameByEntityId[entityTypeId])
            {
                enh.ec.unserializeUpdate(compId, entity, ba);
            }
        }

        if(msgType == CONST.DELETE)
        {
            var entityUUID = ba.readShort();
            var entity = entitiesById[entityUUID];
            em.killEntity(entity);
            entitiesById.remove(entityUUID);
        }

        if(msgType == CONST.SYNC)
        {
            var entityTypeId = ba.readShort();
            var entityUUID = ba.readShort();
            var entity = entitiesById[entityUUID];

            for(compId in enh.ec.componentsNameByEntityId[entityTypeId])
            {
                enh.ec.unserializeUpdate(compId, entity, ba);
            }
        }

        if(msgType == CONST.RPC)
        {
            trace("RPC received");
            unserializeRpc(ba, "dummy");
        }
    }
}