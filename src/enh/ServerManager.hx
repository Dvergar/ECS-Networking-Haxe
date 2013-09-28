package enh;

import enh.Builders;
import enh.Constants;
import enh.Tools;


class NetEntity
{
    public var entity:String;
    public var id:Int;
    public var typeName:String;
    public var typeId:Int;
    public var owner:Null<String>;
    public var ownerId:Null<Int>;

    public function new(){};
}


@:build(enh.macros.RPCMacro.addRpcUnserializeMethod())
class ServerManager
{
    private var enh:Enh;
    private var em:EntityManager;
    private var ec:EntityCreatowr;
    private var ids:IdManager;
    private var netEntityByEntity:Map<String, NetEntity>;
    private var syncingEntities:Array<NetEntity>;
    private var entityIdByConnectionEntity:Map<String, Int>;
    private var connectionsByEntity:Map<String, Connection>;

    public function new(enh:Enh)
    {
        this.connectionsByEntity = new Map();
        this.netEntityByEntity = new Map();
        this.entityIdByConnectionEntity = new Map();
        this.syncingEntities = new Array();
        this.ids = new IdManager(500);

        this.enh = enh;
        this.em = enh.em;
        this.ec = enh.ec;

        trace("functionByEntityType1 " + ec.functionByEntityType);
    }

    public function sendWorldStateTo(connectionEntity:String)
    {
        var conn = connectionsByEntity[connectionEntity];

        for(netEntity in netEntityByEntity.iterator())
        {
            sendCreate(netEntity, conn.output);
        }
    }

    public function setConnectionEntityFromTo(connectionEntity:String,
                                              newConnectionEntity:String)
    {
        var conn = connectionsByEntity[connectionEntity];
        conn.entity = newConnectionEntity;

        connectionsByEntity.remove(connectionEntity);
        connectionsByEntity[newConnectionEntity] = conn;
    }

    public function onConnect(conn:Connection)
    {
        conn.output.writeByte(CONST.CONNECTION);
        conn.output.writeShort(conn.id);

        trace("SOCKET : onConnect " + conn.entity);
    }

    public function createNetworkEntity(entityType:String, ?owner:String):String
    {
        var entityTypeId = ec.entityTypeIdByEntityTypeName[entityType];
        var entity = ec.functionByEntityType[entityType]();
        var conn = connectionsByEntity[owner];

        var netEntity = new NetEntity();
        netEntity.entity = entity;
        netEntity.id = ids.get();
        netEntity.typeName = entityType;
        netEntity.typeId = entityTypeId;
        netEntity.owner = owner;
        netEntity.ownerId = conn.id;

        netEntityByEntity[entity] = netEntity;

        if(owner != null && netEntity.ownerId == null)
        {
            throw("Owner can only be a connection entity");
        }
        else
        {
            em.addComponent(entity, new CNetOwner(netEntity.ownerId));
        }

        for(conn in connectionsByEntity)
        {
            sendCreate(netEntity, conn.output);
        }

        if(ec.syncedEntities[entityTypeId]) syncingEntities.push(netEntity);

        return entity;
    }

    private function sendCreate(netEntity:NetEntity, output:ByteArray)
    {
        if(netEntity.ownerId != null)
        {
            output.writeByte(CONST.CREATE_OWNED);
            output.writeByte(netEntity.ownerId);
        }
        else
        {
            output.writeByte(CONST.CREATE);
        }

        output.writeShort(netEntity.typeId);
        output.writeShort(netEntity.id);

        for(compId in ec.componentsNameByEntityId[netEntity.typeId])
        {
            ec.serializeCreate(compId, netEntity.entity, output);
        }
    }

    public function updateNetworkEntity(entity:String)
    {
        var netEntity = netEntityByEntity[entity];

        for(conn in connectionsByEntity)
        {
            var output = conn.output;

            output.writeByte(CONST.UPDATE);
            output.writeShort(netEntity.typeId);
            output.writeShort(netEntity.id);

            for(compId in ec.componentsNameByEntityId[netEntity.typeId])
            {
                trace("comp update id " + compId);
                ec.serializeUpdate(compId, netEntity.entity, output);
            }
        }
    }

    public function syncNetworkEntity(netEntity:NetEntity)
    {
        for(conn in connectionsByEntity)
        {
            var output = conn.output;

            output.writeByte(CONST.SYNC);
            output.writeShort(netEntity.typeId);
            output.writeShort(netEntity.id);

            for(compId in ec.componentsNameByEntityId[netEntity.typeId])
            {
                ec.serializeUpdate(compId, netEntity.entity, output);            
            }
        }
    }

    public function deleteNetworkEntity(entityUUID:Int)
    {
        // enh.output.writeByte(CONST.DELETE);
        // enh.output.writeShort(entityUUID);

        // // var entity = getEntityFromId(entityUUID);
        // var entity = entitiesById[entityUUID];
        // em.killEntity(entity);
        // entitiesById.remove(entityUUID);
        // idsByEntity.remove(entity);
    }

    public function processDatas(conn:Connection)
    {
        var msgType = conn.input.readByte();

        if(msgType == CONST.CONNECTION)
        {
            var entity = em.createEntity();
            conn.entity = entity;
            connectionsByEntity[entity] = conn;

            em.pushEvent("CONNECTION", conn.entity, {});
        }

        if(msgType == CONST.RPC)
        {
            unserializeRpc(conn.input, conn.entity);
        }
    }

    public function pumpSyncedEntities()
    {
        for(netEntity in syncingEntities)
        {
            syncNetworkEntity(netEntity);
        }
    }
}