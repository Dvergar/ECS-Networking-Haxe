import enh.EntityManager;
import enh.Builders;

#if (flash || openfl)
import flash.display.Shape;
import Client;
#end

// TODO : remove super() ?


@networked
class CPosition extends Component
{
    @short("netx") public var x:Float;
    @short("nety") public var y:Float;
    public var netx:Float;
    public var nety:Float;

    public function new(x:Int, y:Int)
    {
        this.x = x;
        this.y = y;
    }
}


@networked
class CHealth extends Component
{
    @short public var value:Int = 100;

    public function new() {}
}


@networked
class CPepito extends Component
{
    public function new() {}
}


class EntityCreator extends EntityCreatorBase
{
    public function new() {super();}

    @networked
    public function square(datas:Dynamic):Entity
    {
        trace("square spawn at : " + datas);

        var x:Int = datas.x;
        var y:Int = datas.y;

        var square = em.createEntity();
        trace("square entity " + square);
        @sync em.addComponent(square, new CPosition(100, 100));
        @sync var hp = em.addComponent(square, new CHealth());

        #if client
        var shape = new Shape();
        shape.graphics.beginFill(0x3FBF2E);
        shape.graphics.drawRect(0, 0, x, y);
        shape.graphics.endFill();

        em.addComponent(square, new CDrawable(shape));
        #end

        return square;
    }
}


