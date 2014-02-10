// import enh.EntityManager;
import enh.Builders;

#if (flash || openfl)
import flash.display.Shape;
import Client;
#end

import enh.ByteArray;


@networked
class CPosition extends Component
{
    @short public var x:Int;
    @short public var y:Int;

    public function new(x:Int, y:Int)
    {
        super();
        this.x = x;
        this.y = y;
    }
}


@networked
class CComponentTest extends Component
{
    @short public var hp:Int;

    public function new() {super();}
}


@networked
class CPepito extends Component
{
    public function new() {super();}
}


class EntityCreator extends EntityCreatowr
{
    public function new() {super();}

    @networked
    public function mouse(args:Array<Int>):Entity
    {
        trace("Mouse spawn at : " + args);

        var x = args[0];
        var y = args[1];

        trace("mouse");
        var player = em.createEntity();
        em.addComponent(player, new CPosition(100, 100));
        // em.addComponent(player, new CComponentTest());
        @sync var wat = em.addComponent(player, new CComponentTest());

        #if client
        var shape = new Shape();
        shape.graphics.beginFill(0x3FBF2E);
        shape.graphics.drawRect(0, 0, x, y);
        shape.graphics.endFill();

        em.addComponent(player, new CDrawable(shape));
        #end

        return player;
    }
}


