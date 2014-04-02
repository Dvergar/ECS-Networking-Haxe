// import enh.EntityManager;
import enh.Builders;

#if (flash || openfl)
import flash.display.Shape;
import Client;
#end


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
class CHealth extends Component
{
    @short public var value:Int = 100;

    public function new() {super();}
}


@networked
class CPepito extends Component
{
    public function new() {super();}
}


class EntityCreator extends EntityCreatorBase
{
    public function new() {super();}

    @networked
    public function square(args:Array<Int>):Entity
    {
        trace("square spawn at : " + args);

        var x = args[0];
        var y = args[1];

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


