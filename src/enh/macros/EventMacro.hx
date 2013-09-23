package enh.macros;

import haxe.macro.Expr;
import haxe.macro.Context;


class EventMacro
{	
	public static var eventsName2expr:Map<String, Expr> = new Map();

    public static inline function toUpperCaseFirst(value:String):String
    {
        return value.charAt(0).toUpperCase() + value.substr(1).toLowerCase();
    }

    public static function getMetaEventListeners(e:Expr) { 
        switch(e.expr) { 
            case EMeta(meta, link):
                if(meta.name == "registerListener")
                {
	                // trace("META FOUND !!! " + link);
                	// trace("META FOUND !!! meta " + meta);
                	// trace("EEEEE " + e);

                	var eventTypeString = "";
	                switch(link.expr)
	                {
						case EConst(const):
							switch(const)
							{
								case CString(eventString):
									trace("Event is : " + eventString);
									eventsName2expr.set(eventString, e);
								default: throw "orange";
							}
						default: throw "apple";
	                }
                }
            case _:
            	haxe.macro.ExprTools.iter(e, getMetaEventListeners);
        }
    }

	static public function addTypeToMethod(funcEventName:String, fields:Array<Field>):Void
	{
		var metas:Array<haxe.macro.MetadataEntry> = new Array();
		var typedefName = funcEventName.substr(2);

		var methodFound = false;
		// GET METAS & TYPE EVENT (for one function)
        for(f in fields)
        {
            if(f.name == funcEventName)
            {
                methodFound = true;

                switch(f.kind)
                {
                    case FFun(fun):
                    	// REPLACE DYNAMIC BY TYPEDEF NAME
                        trace("args before : " + fun.args);
                        // Maybe add exception if wrong argument type/name
                        fun.args[1].type = TPath({ name : typedefName, pack : [], params : [] });
                        trace("args after : " + fun.args);
                    default:
                }
            }
        }

        if(!methodFound) throw "Method 'on" + funcEventName + "' was not found !";
	}

	static public function getMetaTypes(funcEventName:String, fields:Array<Field>):Array<Array<String>>
	{
		var metaTypes = [];

        for(f in fields)
        {
            if(f.name == funcEventName)
            {
                trace("found " + f.meta.length);

				for(m in f.meta)
				{
					trace("wub " + m);

					var type = m.params[0].expr;
					switch(type)
					{
						case EConst(const):
							switch(const)
							{
								case CString(typeName):
									switch (typeName) {
										case "String":
											metaTypes.push([m.name, typeName]);
										case "Int":
											metaTypes.push([m.name, typeName]);
										default: throw "Type " + typeName + " not allowed";
									}

								default: throw "Banana2";
							}
						default: throw "cheese2";
					}
				}
			}
		}
        return metaTypes;
	}

	#if macro
	static public function replaceMetaListeners()
	{
        for(eventName in eventsName2expr.keys())
        {
	        var words = eventName.split("_");
	        var wordsLowerCase = Lambda.map(words, function(w) { return w.toLowerCase(); } );
	        var wordsUpperCaseFirst = Lambda.map(words, function(w) { return toUpperCaseFirst(w); } );
	        var functionName = "on" + wordsUpperCaseFirst.join("");

	        trace("WOOOOOOOOOOOOOOOOOOOOORDS : " + functionName);
        	
        	// PUSH FUNCTION
        	var registerEventExpr = macro em.registerListener($v{eventName}, $i{functionName});
        	trace("Expr for " + eventName + " : " + eventsName2expr.get(eventName));

        	trace("registerblabla " + registerEventExpr);

        	eventsName2expr.get(eventName).expr = registerEventExpr.expr;
        }
	}

	static public function typeEvents(fields:Array<Field>)
	{
		var pos = Context.currentPos();

		function mkPath(name:String):TypePath {
			var parts = name.split('.');
			return {
				sub: null,
				params: [],
				name: parts.pop(),
				pack: parts
			}
		}

		function mkType(s:String):ComplexType
			return TPath(mkPath(s));
			
		function mkField(name:String, type:ComplexType):Field 
			return {
				pos: pos,
				name: name,
				meta: [],
				kind: FVar(type),
				doc: null,
				access: []
			}
						
		function declare(name:String, fields:Array<Field>, ?superType:TypePath)
			Context.defineType({
				pos: pos, //the position the type is associated with - should probably point to your XML file
				params: [], //we have no type parameters in this example
				pack: [], //no package
				name: name,
				fields: [], //we use a different mechanism to add fields, so we pass none here
				isExtern: false, //not extern
				meta: [], //no metadata
				kind: TDAlias( //here we "alias" (which is what a typedef does) to a fitting ComplexType
					if (superType == null) 
						TAnonymous(fields)
					else 
						TExtend(superType, fields)
				)
			});



		// GET FUNCTION EVENTS
		var funcEventNames = [];
        for(f in fields)
        {
            if(f.name.substr(0, 2) == "on")
            {
            	// If function has metas to process push
            	if(f.meta.length > 0) funcEventNames.push(f.name);
            }
        }

        trace("funcEventNames " + funcEventNames);

        for(funcEventName in funcEventNames)
        {

        	addTypeToMethod(funcEventName, fields);

			var metaTypes = getMetaTypes(funcEventName, fields);
			trace("metaTypes " + metaTypes);

			var typedefFields = [];
			for(metaType in metaTypes)
			{
				var name = metaType[0];
				var type = metaType[1];
				typedefFields.push(mkField(name, mkType(type)));
			}

			// MAKE TYPEDEF
			declare(funcEventName.substr(2), typedefFields);
        }
	}

	static public function _processEvents(fields:Array<Field>):Array<Field> {
		var pos = Context.currentPos();
		trace("############# _processEvents #############");
		// GET EVENTS
        for (f in fields)
        {
	        switch(f.kind){
	            case FFun(fun):
	            	getMetaEventListeners(fun.expr);
	            default:
	        }
	    }

	    trace("WOOOT " + eventsName2expr);
		
        // REPLACE TO FUNCTION CALL
        replaceMetaListeners();

		// HELPERS + TYPEDEF
		typeEvents(fields);

        // for(f in fields)
        // {
        //     trace("honk : " + new haxe.macro.Printer().printField(f));
        // }

		return fields;
	}
	#end

	macro static public function processEvents():Array<haxe.macro.Field> {
		var pos = Context.currentPos();
		var fields:Array<haxe.macro.Field> = Context.getBuildFields();

		_processEvents(fields);



		return fields;
	}
}