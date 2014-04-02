package enh;

import enh.Builders;
import enh.Tools;
import enh.Constants;

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

    public function new(){};
}


@:build(enh.macros.RPCMacro.addRpcUnserializeMethod())
class ServerManager
{
    var em:EntityManager;
    var ec:EntityCreatorBase;
    var netEntityByEntity:Map<Entity, NetEntity>;
    var syncingEntities:Array<NetEntity>;
    public var socket:ServerSocket;
    public var connectionsByEntity:Map<Entity, Connection>;
    public var numConnections(get, never):Int;
    public var connectionsEntities(get, never):Iterator<Entity>;

    public function new(em:EntityManager, ec:EntityCreatorBase)
    {
        this.connectionsByEntity = new Map();
        this.netEntityByEntity = new Map();
        this.syncingEntities = new Array();

        this.em = em;
        this.ec = ec;
    }

    public function get_numConnections():Int
    {
        return Lambda.count(connectionsByEntity);
    }

    public function get_connectionsEntities():Iterator<Entity>
    {
        return connectionsByEntity.keys();
    }

    public function sendWorldStateTo(connectionEntity:Entity)
    {
        var conn = connectionsByEntity[connectionEntity];

        for(netEntity in netEntityByEntity.iterator())
        {
            if(netEntity.owner == connectionEntity) continue;
            sendCreate(netEntity, conn.anette.output);
        }
    }

    public function connect(conn:Connection) {}

    public function disconnect(connectionEntity:Entity)
    {
        trace("sm disconnect");
        var conn = connectionsByEntity.get(connectionEntity);
        _disconnect(conn);
    }

    public function _disconnect(conn:Connection)
    {
        trace("sm _disconnect");
        em.pushEvent("DISCONNECTION", conn.entity, {});
        var entity = conn.entity;  // ?
        connectionsByEntity.remove(entity);
        killEntityNow(entity);
    }

    public function setConnectionEntityFromTo(connectionEntity:Entity,
                                              newConnectionEntity:Entity)
    {
        var conn = connectionsByEntity[connectionEntity];
        conn.entity = newConnectionEntity;

        connectionsByEntity.remove(connectionEntity);
        connectionsByEntity[newConnectionEntity] = conn;
    }

    public function addComponent<T:{var _id:Int;}>(entity:Entity, component:T):T
    {
        var c = em.addComponent(entity, component);
        var c2 = cast component;

        for(conn in connectionsByEntity)
        {
            conn.anette.output.writeByte(CONST.ADD_COMPONENT);
            conn.anette.output.writeInt16(em.getIdFromEntity(entity));
            conn.anette.output.writeInt16(c._id);
            // ec.serialize(c._id, entity, conn.output);
        }

        return component;
    }

    public function addComponent2<T:{var _id:Int;}>(entity:Entity, component:T):T
    {
        var c = em.addComponent(entity, component);
        var c2 = cast component;

        for(conn in connectionsByEntity)
        {
            conn.anette.output.writeByte(CONST.ADD_COMPONENT2);
            conn.anette.output.writeInt16(em.getIdFromEntity(entity));
            conn.anette.output.writeInt16(c._id);
            ec.serialize(c._id, entity, conn.anette.output);
        }

        return component;
    }

    public function createNetworkEntity(entityType:String,
                                        ?owner:Entity,
                                        ?args:Array<Int>,
                                        ?event:Bool):Entity
    {
        if(args == null) args = new Array();

        var entityTypeId = ec.entityTypeIdByEntityTypeName[entityType];
        trace("createNetworkEntity type id " + entityTypeId);
        var entity = ec.functionByEntityType[entityType](args);

        var netEntity = new NetEntity();
        netEntity.entity = entity;
        netEntity.id = em.setId(entity);
        netEntity.typeName = entityType;
        netEntity.typeId = entityTypeId;
        netEntity.args = args;
        netEntity.event = event;

        if(owner == null)
        {
            netEntity.owner = netEntity.entity;
            netEntity.ownerId = netEntity.id;
        }
        else
        {
            netEntity.owner = owner;
            netEntity.ownerId = em.getIdFromEntity(owner);
        }

        netEntityByEntity[entity] = netEntity;
        em.addComponent(entity, new CNetOwner(netEntity.ownerId));

        for(conn in connectionsByEntity)
        {
            sendCreate(netEntity, conn.anette.output);
        }

        if(ec.syncedEntities[entityTypeId]) syncingEntities.push(netEntity);
        trace("syncedEntities " + syncingEntities + " / " + ec.syncedEntities);

        return entity;
    }

    private function sendCreate(netEntity:NetEntity, output:BytesOutputEnhanced)
    {
        trace("sendcreate " + netEntity.id);

        if(netEntity.ownerId != null)
        {
            output.writeByte(CONST.CREATE_OWNED);
            output.writeByte(netEntity.ownerId);
        }
        else
        {
            output.writeByte(CONST.CREATE);
        }

        output.writeByte(netEntity.args.length);
        for(arg in netEntity.args)
        {
            output.writeInt16(arg);
        }

        output.writeInt16(netEntity.typeId);
        output.writeInt16(netEntity.id);
        output.writeBoolean(netEntity.event);

        for(compId in ec.componentsNameByEntityId[netEntity.typeId])
        {
            ec.serialize(compId, netEntity.entity, output);
        }
    }

    public function updateNetworkEntity(entity:Entity)
    {
        var netEntity = netEntityByEntity[entity];

        for(conn in connectionsByEntity)
        {
            trace("update");
            var output = conn.anette.output;

            output.writeByte(CONST.UPDATE);
            output.writeInt16(netEntity.typeId);
            output.writeInt16(netEntity.id);

            for(compId in ec.componentsNameByEntityId[netEntity.typeId])
            {
                trace("comp update id " + compId);
                ec.serialize(compId, netEntity.entity, output);
            }
        }
    }

    public function syncNetworkEntity(netEntity:NetEntity)
    {
        for(conn in connectionsByEntity)
        {
            var output = conn.anette.output;

            output.writeByte(CONST.SYNC);
            output.writeInt16(netEntity.typeId);
            output.writeInt16(netEntity.id);

            for(compId in ec.syncComponentsNameByEntityId[netEntity.typeId])
            {
                ec.serialize(compId, netEntity.entity, output);
            }
        }
    }

    public function killEntityNow(entity:Entity)
    {
        var netEntity = netEntityByEntity[entity];

        for(conn in connectionsByEntity)
        {
            var output = conn.anette.output;

            output.writeByte(CONST.DELETE);
            output.writeInt16(netEntity.id);
        }

        netEntityByEntity.remove(entity);
        em.killEntityNow(entity);
        syncingEntities.remove(netEntity);
    }

    public function processDatas(anconn:anette.Connection)
    {
        // handle this for SYNC as well
        var conn = socket.connections.get(anconn);
        var msgType = anconn.input.readByte();
        // trace("msgtype " + msgType);

        if(msgType == CONST.CONNECTION)
        {
            var entity = em.createEntity();
            em.setId(entity);
            conn.entity = entity;
            connectionsByEntity[entity] = conn;

            socket.connect(conn);
            em.pushEvent("CONNECTION", conn.entity, {});
        }

        if(!connectionsByEntity.exists(conn.entity)) return;
        if(msgType == CONST.RPC)
        {
            // unserializeRpc(conn.input, conn.entity);
            unserializeRpc(anconn.input);
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