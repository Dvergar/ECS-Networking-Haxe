import enh.EntityManager;
import enh.Builders;

#if (flash || openfl)
import flash.display.Shape;
import Client;
#end
import enh.ByteArray;


@networked @sync
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


@:build(enh.macros.MacroTest.buildMap())
class EntityCreator extends EntityCreatowr
{
    public function new() {
        super();
    }

    @freeze
    public function mouse():String
    {
        trace("mouse");
        var player = em.createEntity();
        em.addComponent(player, new CPosition(100, 100));
        em.addComponent(player, new CComponentTest());

        #if client
        var shape = new Shape();
        shape.graphics.beginFill(0x3FBF2E);
        shape.graphics.drawRect(0, 0, 100, 100);
        shape.graphics.endFill();

        em.addComponent(player, new CDrawable(shape));
        #end

        return player;
    }
}


