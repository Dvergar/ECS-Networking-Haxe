package enh;

import enh.Constants;
import enh.Builders;
import enh.EntityManager;
import anette.Bytes;


class NetEntity
{
    public var entity:Entity;
    public var id:Int;
    public var typeName:String;
    public var typeId:Int;
    public var owner:Null<Entity>;
    public var ownerId:Null<Int>;
    public var args:Null<Array<Int>>;
    public var event:Bool;
    public var componentsIds:Array<Int>;
    public var syncComponentsIds:Array<Int>;

    public function new(){};
}


@:build(enh.macros.RPCMacro.addRpcUnserializeMethod())
class ClientManager
{
    var em:EntityManager;
    var ec:EntityCreatorBase;
    var me:Entity;
    var id:Int;
    var netEntityByEntity:Map<Entity, NetEntity> = new Map();

    public var socket:Socket;

    public function new(em:EntityManager, ec:EntityCreatorBase)
    {
        this.em = em;
        this.ec = ec;
    }

    public function processDatas(anconn:anette.Connection)
    {
        var input = anconn.input;
        var msgType = input.readByte();

        // SWITCH PLEASE
        if(msgType == CONST.CONNECTION)  // MY connection
        {
            this.id = input.readInt16();
            trace("CONNECTION " + id);
            me = em.createEntity();

            anconn.output.writeByte(CONST.CONNECTION);

            em.pushEvent("CONNECTION", me, {});
        }

        if(msgType == CONST.CREATE || msgType == CONST.CREATE_OWNED)
        {
            var ownerId = -1;  // UGLY TO FIX YES OK OK
            if(msgType == CONST.CREATE_OWNED)
                ownerId = input.readByte();

            // GET ENTITY ARGUMENTS
            var args:Dynamic = haxe.Unserializer.run(input.readUTF());
            if(args.entity != null)
                args.entity = em.getEntityFromId(args.entity);

            // GET NETWORK DATAS
            var entityTypeId = input.readInt16();
            var entityId = input.readInt16();
            var event = input.readBoolean();

            // GET ENTITY SHIT & ASSIGN IDS
            var entityName = ec.entities[entityTypeId].name;
            var entity = ec.functionByEntityName[entityName](args);
            em.setId(entity, entityId);

            // CREATE NETWORK ENTITY VIEW
            var netEntity = new NetEntity();
            netEntity.id = entityId;
            netEntity.typeId = entityTypeId;
            netEntity.componentsIds = ec.entities[entityTypeId].componentsIds.copy();
            netEntity.syncComponentsIds = ec.entities[entityTypeId].syncComponentsIds.copy();
            netEntityByEntity.set(entity, netEntity);

            if(msgType == CONST.CREATE_OWNED)
                em.addComponent(entity, new CNetOwner(ownerId));

            if(event)
                em.pushEvent(entityName.toUpperCase() + "_CREATE",
                             entity,
                             {ownerId:ownerId, x:args.x, y:args.y});

            for(compId in netEntity.componentsIds)
            {
                ec.unserialize(compId, entity, input);
            }

            trace("comps " + em.debugGetComponentsStringOfEntity(entity));
        }

        if(msgType == CONST.UPDATE)
        {
            trace("update");
            var entityTypeId = input.readInt16();
            var entityId = input.readInt16();
            var entity = em.getEntityFromId(entityId);
            var netEntity = netEntityByEntity.get(entity);

            for(compId in netEntity.componentsIds)
            {
                ec.unserialize(compId, entity, input);
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
            var netEntity = netEntityByEntity.get(entity);
            // trace('entitytypeid $entityTypeId / entityid $entityId / entity $entity');

            for(compId in netEntity.syncComponentsIds)
            {
                ec.unserialize(compId, entity, input);
            }
        }

        if(msgType == CONST.ADD_COMPONENT)
        {
            var entityId = input.readInt16();
            var compId = input.readInt16();
            var entity = em.getEntityFromId(entityId);

            ec.addComponent(compId, entity);
        }

        if(msgType == CONST.ADD_COMPONENT2)
        {
            trace("ADD_COMPONENT2");
            var entityId = input.readInt16();
            var compId = input.readInt16();
            var entity = em.getEntityFromId(entityId);

            ec.addComponent(compId, entity);
            ec.unserialize(compId, entity, input);
        }

        if(msgType == CONST.RPC)
        {
            unserializeRpc(input);
        }

        if(msgType == CONST.CLIENT_DISCONNECTION)
        {
            trace("CLIENT_DISCONNECTION");

            var entityId = input.readInt16();
            var entity = em.getEntityFromId(entityId);

            em.pushEvent("CLIENT_DISCONNECTION", entity, {});
        }
    }
}