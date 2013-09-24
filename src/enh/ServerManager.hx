package enh;

import enh.Builders;
import enh.Constants;
import enh.ServerSocket;
import enh.Tools;


class CId extends Component
{
    public var value:Int;
    public function new(value:Int)
    {
        super();
        this.value = value;
    }
}


class CConnexion extends Component
{
    public var bytes:ByteArray;
	public function new()
	{
		super();
		this.bytes = new ByteArray();
	}
}




@:build(enh.macros.RPCMacro.addRpcUnserializeMethod())
class ServerManager
{
    private var enh:Enh;
    private var em:EntityManager;
    private var ec:EntityCreatowr;
    private var entityTypeIdByEntity:Map<String, Int>;
    private var entitiesById:Map<Int, String>;
    private var idsByEntity:Map<String, Int>;
    private var ids:IdManager;

    public function new(enh:Enh)
    {
    	this.entitiesById = new Map();
    	this.entityTypeIdByEntity = new Map();
    	this.idsByEntity = new Map();
    	this.ids = new IdManager(500);
        this.enh = enh;
        this.em = enh.em;
        this.ec = enh.ec;

        trace("functionByEntityType1 " + ec.functionByEntityType);
    }

    public function getEntityFromId(id:Int):String
    {
        var allIds = em.getEntitiesWithComponent(CId);

        for(idEntity in allIds)
        {
            var itId = em.getComponent(idEntity, CId).value;

            if(itId == id)
            {
                return idEntity;
            }
        }
        throw "No entity was found";
        return "";
    }

	public function createNetworkEntity(entityType:String):String
	{
		trace("functionByEntityType2 " + ec.functionByEntityType);
		var entity = ec.functionByEntityType[entityType]();
		// em.addComponent(entity, new CId(42));
		var uuid = ids.get();
		entitiesById[uuid] = entity;
		idsByEntity[entity] = uuid;
		var entityTypeId = ec.entityTypeIdByEntityTypeName[entityType];
		entityTypeIdByEntity[entity] = entityTypeId;

		trace("entity " + entity);
		trace("create entity uuid " + uuid);
		trace("entityComponentsMap " + ec.entityComponentsMap);

		for(socket in enh.serverSocket.connectionsOut.keys())
		{
			var output = enh.serverSocket.connectionsOut[socket];

			output.writeByte(CONST.CREATE);
			output.writeShort(entityTypeId);  // ID
			output.writeShort(uuid);  // UUID

			var ecm:Array<Int> = ec.entityComponentsMap[CONST.CREATE][entityTypeId];

			for(compId in ecm)
			{
				trace("plop");
				ec.serializeCreate(compId, entity, output);
			}
		}

		return entity;
	}

	public function updateNetworkEntity(entity:String)
	{
		// var entity = getEntityFromId(entityUUID);
		// var entity = idsByEntity[entityUUID];
		// var entityTypeId = ec.entityTypeIdByEntityTypeName[entityType];
		var entityTypeId = entityTypeIdByEntity[entity];
		var entityUUID = idsByEntity[entity];
		trace("upate entity uuid " + entityUUID);

		for(socket in enh.serverSocket.connectionsOut.keys())
		{
			var output = enh.serverSocket.connectionsOut[socket];

			output.writeByte(CONST.UPDATE);
			output.writeShort(entityTypeId);
			output.writeShort(entityUUID);

			var ecm:Array<Int> = ec.entityComponentsMap[CONST.UPDATE][entityTypeId];

			for(compId in ecm)
			{
				trace("comp update id " + compId);
				ec.serializeUpdate(compId, entity, output);
			}
		}
	}

	public function syncNetworkEntity(entityUUID:Int, entityType:String)
	{
		// var entity = getEntityFromId(entityUUID);
		var entity = entitiesById[entityUUID];
		var entityTypeId = ec.entityTypeIdByEntityTypeName[entityType];

		for(socket in enh.serverSocket.connectionsOut.keys())
		{
			var output = enh.serverSocket.connectionsOut[socket];

			output.writeByte(CONST.SYNC);
			output.writeShort(entityTypeId);
			output.writeShort(entityUUID);

			trace("k " + output.length);

			var ecm:Array<Int> = ec.entityComponentsMap[CONST.SYNC][entityTypeId];

			for(compId in ecm)
			{
				trace("boop");
				ec.serializeUpdate(compId, entity, output);			
			}
		}
	}

	public function deleteNetworkEntity(entityUUID:Int)
	{
		enh.output.writeByte(CONST.DELETE);
		enh.output.writeShort(entityUUID);

		// var entity = getEntityFromId(entityUUID);
		var entity = entitiesById[entityUUID];
		em.killEntity(entity);
		entitiesById.remove(entityUUID);
		idsByEntity.remove(entity);
	}

	public function processDatas(ba:ByteArray)
	{
		trace("processDatas");
		var msgType = ba.readByte();

		if(msgType == CONST.RPC)
		{
			unserializeRpc(ba);
		}
	}
}