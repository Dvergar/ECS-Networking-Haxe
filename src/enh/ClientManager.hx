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

		if(msgType == CONST.CREATE)
		{
			var entityType = ba.readShort();
			var entityUUID = ba.readShort();
			trace("create entity uuid " + entityUUID);

			var entity = enh.ec.entityFunctionsMap[entityType]();
			trace("entity created " + entity);

			var ecm:Array<Int> = enh.ec.entityComponentsMap[CONST.CREATE][entityType];

			for(compId in ecm)
			{
				enh.ec.unserializeCreate(compId, entity, ba);
			}

			trace("comps " + em.debugGetComponentsStringOfEntity(entity));

			entitiesById[entityUUID] = entity;
		}

		if(msgType == CONST.UPDATE)
		{
			var entityType = ba.readShort();
			var entityUUID = ba.readShort();
			var entity = entitiesById[entityUUID];
			trace("update entity uuid " + entityUUID);
			trace("entity update " + entity);

			var ecm:Array<Int> = enh.ec.entityComponentsMap[CONST.UPDATE][entityType];

			for(compId in ecm)
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
			var entityType = ba.readShort();
			var entityUUID = ba.readShort();
			var entity = entitiesById[entityUUID];

			var ecm:Array<Int> = enh.ec.entityComponentsMap[CONST.SYNC][entityType];

			for(compId in ecm)
			{
				enh.ec.unserializeUpdate(compId, entity, ba);
			}
		}

		if(msgType == CONST.RPC)
		{
			trace("RPC");
			unserializeRpc(ba);
		}

		trace("NET OUT " + ba.length + " / " + ba.bytesAvailable);
	}
}