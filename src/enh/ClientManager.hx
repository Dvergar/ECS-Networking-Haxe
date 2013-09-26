package enh;

#if (flash || openfl)
import flash.utils.ByteArray;
#else
import enh.ByteArray;
#end

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

	public function readMessageFromTheInternetTubes(ba:ByteArray)
	{
		trace("mooga " + enh.ec);
		trace("NET IN " + ba.length + " / " + ba.bytesAvailable);
		var msgType = ba.readByte();
		trace("NET msgtype " + msgType);

		// SWITCH PLEASE
		if(msgType == CONST.CONNECTION)  // MY connection
		{
			trace("CONNECTION");
			myId = ba.readShort();
			me = em.createEntity();

			enh.output.writeByte(CONST.CONNECTION);

			em.pushEvent("CONNECTION", me, {});
		}

		if(msgType == CONST.CREATE)
		{
			var entityTypeId = ba.readShort();
			var entityUUID = ba.readShort();
			trace("create entity uuid " + entityUUID);

			var entityTypeName = ec.entityTypeNameById[entityTypeId];
			var entity = enh.ec.functionByEntityType[entityTypeName]();
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
			var entityTypeId = ba.readShort();
			var entityUUID = ba.readShort();
			trace("create owned entity uuid " + entityUUID);

			var entityTypeName = ec.entityTypeNameById[entityTypeId];
			var entity = enh.ec.functionByEntityType[entityTypeName]();
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
			trace("update entity uuid " + entityUUID);
			trace("entity update " + entity);

			for(compId in enh.ec.componentsNameByEntityId[entityTypeId])
			{
				trace("compid update " + compId);
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
			trace("sync entity " + entity);

			// var ecm:Array<Int> = enh.ec.componentsNameByEntityId[CONST.SYNC][entityTypeId];

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

		trace("NET OUT " + ba.length + " / " + ba.bytesAvailable);
	}
}