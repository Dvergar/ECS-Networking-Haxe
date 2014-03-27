package enh;

import enh.Builders;
import enh.Tools;
import enh.Constants;


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
    public var socket:ServerSocket;  // WORKAROUND FOR LD28, need to clean up
    private var enh:Enh;
    private var em:EntityManager;
    private var ec:EntityCreatowr;
    // private var ids:IdManager;
    private var netEntityByEntity:Map<Entity, NetEntity>;
    private var syncingEntities:Array<NetEntity>;
    // private var entityIdByConnectionEntity:Map<String, Int>;
    public var connectionsByEntity:Map<Entity, Connection>;
    public var numConnections(get, never):Int;
    public var connectionsEntities(get, never):Iterator<Entity>;

    public function new(enh:Enh)
    {
        this.connectionsByEntity = new Map();
        this.netEntityByEntity = new Map();
        // this.entityIdByConnectionEntity = new Map();
        this.syncingEntities = new Array();
        // this.ids = new IdManager(500);

        this.enh = enh;
        this.em = Enh.em;
        this.ec = enh.ec;

        trace("functionByEntityType1 " + ec.functionByEntityType);
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
            sendCreate(netEntity, conn.output);
        }
    }

    public function connect(conn:Connection) {}

    // FIX : Too much back&forth
    public function disconnect(connectionEntity:Entity)
    {
        trace("sm disconnect");
        var conn = connectionsByEntity.get(connectionEntity);
        var s = socket.getSocketFromConnection(conn);
        socket.disconnect(conn, s);
        _disconnect(conn);
    }

    public function _disconnect(conn:Connection)
    {
        trace("sm _disconnect");
        em.pushEvent("DISCONNECTION", conn.entity, {});
        var entity = conn.entity;
        connectionsByEntity.remove(entity);
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
            conn.output.writeByte(CONST.ADD_COMPONENT);
            conn.output.writeShort(em.getIdFromEntity(entity));
            conn.output.writeShort(c._id);
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
            conn.output.writeByte(CONST.ADD_COMPONENT2);
            conn.output.writeShort(em.getIdFromEntity(entity));
            conn.output.writeShort(c._id);
            ec.serialize(c._id, entity, conn.output);
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
        var entity = ec.functionByEntityType[entityType](args);
        // var conn = connectionsByEntity[owner];

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

        // if(owner != null && netEntity.ownerId == null)
        // {
        //     throw("Owner can only be a connection entity");
        // }
        // else
        // {
            em.addComponent(entity, new CNetOwner(netEntity.ownerId));
        // }

        for(conn in connectionsByEntity)
        {
            sendCreate(netEntity, conn.output);
        }

        if(ec.syncedEntities[entityTypeId]) syncingEntities.push(netEntity);
        trace("syncedEntities " + syncingEntities + " / " + ec.syncedEntities);

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

        output.writeByte(netEntity.args.length);
        for(arg in netEntity.args)
        {
            output.writeShort(arg);
        }

        output.writeShort(netEntity.typeId);
        output.writeShort(netEntity.id);
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
            var output = conn.output;

            output.writeByte(CONST.UPDATE);
            output.writeShort(netEntity.typeId);
            output.writeShort(netEntity.id);

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
            var output = conn.output;

            output.writeByte(CONST.SYNC);
            output.writeShort(netEntity.typeId);
            output.writeShort(netEntity.id);

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
            var output = conn.output;

            output.writeByte(CONST.DELETE);
            output.writeShort(netEntity.id);
        }

        // // var entity = getEntityFromId(entityUUID);
        // var entity = entitiesById[entityUUID];
        netEntityByEntity.remove(entity);
        em.killEntityNow(entity);
        syncingEntities.remove(netEntity);
        // entitiesById.remove(entityUUID);
        // idsByEntity.remove(entity);

        // TODO kill entity from syncentities
    }

    public function processDatas(conn:Connection)
    {
        // handle this for SYNC as well
        // trace("datas from " + conn.entity);

        var msgType = conn.input.readByte();
        // trace("msgtype " + msgType);

        if(msgType == CONST.CONNECTION)
        {
            var entity = em.createEntity();
            em.setId(entity);
            conn.entity = entity;
            connectionsByEntity[entity] = conn;

            trace("plop");
            socket.connect(conn);
            em.pushEvent("CONNECTION", conn.entity, {});
        }

        if(!connectionsByEntity.exists(conn.entity)) return;
        if(msgType == CONST.RPC)
        {
            // unserializeRpc(conn.input, conn.entity);
            unserializeRpc(conn.input);
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