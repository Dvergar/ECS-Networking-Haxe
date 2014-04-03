package enh.macros;

import enh.macros.EventMacro;
import enh.macros.RPCMacro;
import enh.macros.AddSystemMacro;

import haxe.macro.Expr;
import haxe.macro.Context;


class Template
{
    macro static public function system():Array<haxe.macro.Field>
    {
        var fields = Context.getBuildFields();

        fields = RPCMacro._processRPCs(fields);
        fields = EventMacro._processEvents(fields);
        fields = AddSystemMacro._replaceMetas(fields);

        return fields;
    }

    macro static public function main():Array<haxe.macro.Field>
    {
        var fields = Context.getBuildFields();

        fields = RPCMacro._processRPCs(fields);
        fields = EventMacro._processEvents(fields);
        fields = AddSystemMacro._replaceMetas(fields);

        return fields;
    }
}