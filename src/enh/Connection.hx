package enh;

import enh.Builders;
import enh.EntityManager;


class Connection
{
    public var id:Int;
    public var entity:Entity;
    public var activityTime:Float;
    public var anette:anette.Connection;

    public function new(anetteConnection, ?id:Int=0)
    {
        this.anette = anetteConnection;
        this.id = id;
        this.activityTime = enh.Timer.getTime();
    }
}