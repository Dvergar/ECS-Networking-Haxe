package enh;


#if(flash || openfl)
typedef ByteArray = flash.utils.ByteArray;
#else
typedef ByteArray = enh.moo.ByteArray;
#end
