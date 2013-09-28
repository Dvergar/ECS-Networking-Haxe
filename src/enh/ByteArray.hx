package enh;
#if(flash || openfl)
typedef ByteArray = flash.utils.ByteArray;
#end

// import flash.errors.EOFError;
// import flash.utils.CompressionAlgorithm;
// import flash.Lib;
// import openfl.utils.IMemoryRange;

#if(!flash || !openfl)
#if neko
import neko.Lib;
import neko.zip.Compress;
import neko.zip.Uncompress;
import neko.zip.Flush;
#else
import cpp.Lib;
import cpp.zip.Compress;
import cpp.zip.Uncompress;
import cpp.zip.Flush;
#end

import haxe.io.Bytes;
import haxe.io.BytesData;

class Endian {
	public static inline var BIG_ENDIAN : String = "bigEndian";
	public static inline var LITTLE_ENDIAN : String = "littleEndian";
}


// @:autoBuild(openfl.Assets.embedFile())
class ByteArray extends Bytes implements ArrayAccess<Int> {
	

	public var bigEndian:Bool;
	public var bytesAvailable (get, null):Int;
	public var endian (get, set):String;
	public var position:Int;
	public var byteLength (get, null):Int;
	
	#if neko
	private var allocated:Int;
	#end
	
	
	public function new (size = 0) {
		
		bigEndian = true;
		position = 0;
		
		if (size >= 0) {
			
			#if neko
			
			allocated = size < 16 ? 16 : size;
			var bytes = untyped __dollar__smake (allocated);
			super (size, bytes);
			
			#else
			
			var data = new BytesData ();
			
			if (size > 0) {
				
				untyped data[size - 1] = 0;
				
			}
			
			super (size, data);
			
			#end
			
		}
		
	}
	
	
	public function asString ():String {
		
		return readUTFBytes (length);
		
	}
	
	
	public function checkData (length:Int) {
		
		if (length + position > this.length) {
			
			__throwEOFi();
			
		}
		
	}
	
	
	public function clear ():Void {
		
		position = 0;
		length = 0;
		
	}
	
	
	// public function compress (algorithm:CompressionAlgorithm = null):Void {
		
	// 	#if neko
	// 	var src = allocated == length ? this : sub(0, length);
	// 	#else
	// 	var src = this;
	// 	#end
		
	// 	if (algorithm == null) {
			
	// 		algorithm = CompressionAlgorithm.ZLIB;
			
	// 	}
		
	// 	var result:Bytes;
		
	// 	if (algorithm == CompressionAlgorithm.LZMA) {
			
	// 		result = Bytes.ofData (nme_lzma_encode (src.getData ()));
			
	// 	} else {
			
	// 		var windowBits = switch (algorithm) {
				
	// 			case DEFLATE: -15;
	// 			case GZIP: 31;
	// 			default: 15;
				
	// 		}
			
	// 		#if enable_deflate
	// 		result = Compress.run (src, 8, windowBits);
	// 		#else
	// 		result = Compress.run (src, 8);
	// 		#end
			
	// 	}
		
	// 	b = result.b;
	// 	length = result.length;
	// 	position = length;
	// 	#if neko
	// 	allocated = length;
	// 	#end
		
	// }
	
	
	// public function deflate():Void {
		
	// 	compress (CompressionAlgorithm.DEFLATE);
		
	// }
	
	
	private function ensureElem (size:Int, updateLength:Bool):Void {
		var len = size + 1;

		#if neko
		if (allocated < len) {
			
			allocated = ((len+1) * 3) >> 1;
			var new_b = untyped __dollar__smake (allocated);
			untyped __dollar__sblit (new_b, 0, b, 0, length);
			b = new_b;
			
		}
		#else
		if (b.length < len) {
			
			untyped b.__SetSize(len);
			
		}
		#end
		
		if (updateLength && length < len) {
			
			length = len;
			
		}
		
	}
	
	
	static public function fromBytes (bytes:Bytes):ByteArray {
		
		var result = new ByteArray ( -1);
		result.__fromBytes (bytes);
		return result;
		
	}
	
	
	public function getByteBuffer ():ByteArray {
		
		return this;
		
	}
	
	
	public function getLength ():Int {
		
		return length;
		
	}
	
	
	public function getStart ():Int {
		
		return 0;
		
	}
	
	
	// public function inflate ():Void {
		
	// 	uncompress (CompressionAlgorithm.DEFLATE);
		
	// }
	
	
	public inline function readBoolean ():Bool {
		
		return (position < length) ? __get (position++) != 0 : __throwEOFi () != 0;
		
	}
	
	
	public inline function readByte ():Int {
		
		var value:Int = readUnsignedByte ();
		return ((value & 0x80) != 0) ? (value - 0x100) : value;
		
	}
	
	
	public function readBytes (data:ByteArray, offset:Int = 0, length:Int = 0):Void {
		
		if (length == 0) {
			
			length = this.length - position;
			
		}
		
		if (position + length > this.length) {
			
			__throwEOFi();
			
		}
		
		if (data.length < offset + length) {
			
			data.ensureElem (offset + length - 1, true);
			
		}
		
		#if neko
		data.blit (offset, this, position, length);
		#else
		var b1 = b;
		var b2 = data.b;
		var p = position;
		for (i in 0...length) {
			
			b2[offset + i] = b1[p + i];
			
		}
		#end
		
		position += length;
		
	}
	
	
	public function readDouble ():Float {
		
		if (position + 8 > length) {
			
			__throwEOFi ();
			
		}
		
		#if neko
		var bytes = new Bytes (8, untyped __dollar__ssub (b, position, 8));
		#elseif cpp
		var bytes = new Bytes (8, b.slice (position, position + 8));
		#end
		
		position += 8;
		return _double_of_bytes (bytes.b, bigEndian);
		
	}
	
	
	// #if !no_nme_io
	
	// static public function readFile (path:String):ByteArray {
		
	// 	return nme_byte_array_read_file (path);
		
	// }
	
	// #end
	
	
	public function readFloat ():Float {
		
		if (position + 4 > length) {
			
			__throwEOFi ();
			
		}
		
		#if neko
		var bytes = new Bytes (4, untyped __dollar__ssub (b, position, 4));
		#elseif cpp
		var bytes = new Bytes (4, b.slice (position, position + 4));
		#end
		
		position += 4;
		return _float_of_bytes (bytes.b, bigEndian);
		
	}
	
	
	public function readInt ():Int {
		
		var ch1 = readUnsignedByte ();
		var ch2 = readUnsignedByte ();
		var ch3 = readUnsignedByte ();
		var ch4 = readUnsignedByte ();
		
		return bigEndian ? (ch1 << 24) | (ch2 << 16) | (ch3 << 8) | ch4 : (ch4 << 24) | (ch3 << 16) | (ch2 << 8) | ch1;
		
	}
	
	
	public inline function readMultiByte (length:Int, charSet:String):String {
		
		return readUTFBytes (length);
		
	}
	
	
	public function readShort ():Int {
		
		var ch1 = readUnsignedByte ();
		var ch2 = readUnsignedByte ();
		
		var value = bigEndian ? ((ch1 << 8) | ch2) : ((ch2 << 8) | ch1);
		
		return ((value & 0x8000) != 0) ? (value - 0x10000) : value;
		
	}
	
	
	inline public function readUnsignedByte ():Int {
		
		return (position < length) ? __get (position++) : __throwEOFi ();
		
	}
	
	
	public function readUnsignedInt ():Int {
		
		var ch1 = readUnsignedByte ();
		var ch2 = readUnsignedByte ();
		var ch3 = readUnsignedByte ();
		var ch4 = readUnsignedByte ();
		
		return bigEndian ? (ch1 << 24) | (ch2 << 16) | (ch3 << 8) | ch4 : (ch4 << 24) | (ch3 << 16) | (ch2 << 8) | ch1;
		
	}
	
	
	public function readUnsignedShort ():Int {
		
		var ch1 = readUnsignedByte ();
		var ch2 = readUnsignedByte ();
		
		return bigEndian ? (ch1 << 8) | ch2 : (ch2 << 8) + ch1;
		
	}
	
	
	public function readUTF ():String {
		
		var len = readUnsignedShort ();
		return readUTFBytes (len);
		
	}
	
	
	public function readUTFBytes (length:Int):String {
		
		if (position + length > this.length) {
			
			__throwEOFi ();
			
		}
		
		var p = position;
		position += length;
		
		#if neko
		return new String (untyped __dollar__ssub (b, p, length));
		#elseif cpp
		var result = "";
		untyped __global__.__hxcpp_string_of_bytes (b, result, p, length);
		return result;
		#end
		
	}
	
	
	public function setLength (length:Int):Void {
		
		if (length > 0) {
			
			ensureElem (length - 1, false);
			
		}
		
		this.length = length;
		
	}
	
	
	public function slice (begin:Int, end:Null<Int> = null):ByteArray {
		
		if (begin < 0) {
			
			begin += length;
			
			if (begin < 0) {
				
				begin = 0;
				
			}
			
		}
		
		if (end == null) {
			
			end = length;
			
		}
		
		if (end < 0) {
			
			end += length;
			
			if (end < 0) {
				
				end = 0;
				
			}
			
		}
		
		if (begin >= end) {
			
			return new ByteArray ();
			
		}
		
		var result = new ByteArray (end - begin);
		
		var opos = position;
		result.blit (0, this, begin, end - begin);
		
		return result;
		
	}
	
	
	// public function uncompress (algorithm:CompressionAlgorithm = null):Void {
		
	// 	if (algorithm == null) algorithm = CompressionAlgorithm.ZLIB;
		
	// 	#if neko
	// 	var src = allocated == length ? this : sub (0, length);
	// 	#else
	// 	var src = this;
	// 	#end
		
	// 	var result:Bytes;
		
	// 	if (algorithm == CompressionAlgorithm.LZMA) {
			
	// 		result = Bytes.ofData (nme_lzma_decode (src.getData ()));
			
	// 	} else {
			
	// 		var windowBits = switch (algorithm) {
				
	// 			case DEFLATE: -15;
	// 			case GZIP: 31;
	// 			default: 15;
				
	// 		}
			
	// 		#if enable_deflate
	// 		result = Uncompress.run (src, null, windowBits);
	// 		#else
	// 		result = Uncompress.run (src, null);
	// 		#end
			
	// 	}
		
	// 	b = result.b;
	// 	length = result.length;
	// 	position = 0;
	// 	#if neko
	// 	allocated = length;
	// 	#end
		
	// }
	
	
	private inline function write_uncheck (byte:Int):Void {
		
		#if cpp
		untyped b.__unsafe_set (position++, byte);
		#else
		untyped __dollar__sset (b, position++, byte & 0xff);
		#end
		
	}
	
	
	public function writeBoolean (value:Bool):Void {
		
		writeByte (value ? 1 : 0);
		
	}
	
	
	inline public function writeByte (value:Int):Void {
		
		ensureElem (position, true);
		
		#if cpp
		b[position++] = untyped value;
		#else
		untyped __dollar__sset (b, position++, value & 0xff);
		#end
		
	}
	
	
	public function writeBytes (bytes:Bytes, offset:Int = 0, length:Int = 0):Void {
		
		if (length == 0) length = bytes.length - offset;
		ensureElem (position + length - 1, true);
		var opos = position;
		position += length;
		blit (opos, bytes, offset, length);
		
	}
	
	
	public function writeDouble (x:Float):Void {
		
		#if neko
		var bytes = new Bytes (8, _double_bytes (x, bigEndian));
		#elseif cpp
		var bytes = Bytes.ofData (_double_bytes (x, bigEndian));
		#end
		
		writeBytes (bytes, 0, 0);
		
	}
	
	
	// #if !no_nme_io
	
	// public function writeFile (path:String):Void {
		
	// 	nme_byte_array_overwrite_file(path, this);
		
	// }
	
	// #end
	
	
	public function writeFloat (x:Float):Void {
		
		#if neko
		var bytes = new Bytes (4, _float_bytes (x, bigEndian));
		#elseif cpp
		var bytes = Bytes.ofData (_float_bytes (x, bigEndian));
		#end
		
		writeBytes (bytes, 0, 0);
		
	}
	
	
	public function writeInt (value:Int):Void {
		
		ensureElem (position + 3, true);
		
		if (bigEndian) {
			
			write_uncheck (value >> 24);
			write_uncheck (value >> 16);
			write_uncheck (value >> 8);
			write_uncheck (value);
			
		} else {
			
			write_uncheck (value);
			write_uncheck (value >> 8);
			write_uncheck (value >> 16);
			write_uncheck (value >> 24);
			
		}
		
	}
	
	
	public function writeShort (value:Int):Void {
		
		ensureElem (position + 1, true);
		
		if (bigEndian) {
			
			write_uncheck (value >> 8);
			write_uncheck (value);
			
		} else {
			
			write_uncheck (value);
			write_uncheck (value >> 8);
			
		}
		
	}
	
	
	public function writeUnsignedInt (value:Int):Void {
		
		writeInt (value);
		
	}
	
	
	public function writeUTF (s:String):Void {
		
		#if neko
		var bytes = new Bytes (s.length, untyped s.__s);
		#else
		var bytes = Bytes.ofString (s);
		#end
		
		writeShort (bytes.length);
		writeBytes (bytes, 0, 0);
		
	}
	
	
	public function writeUTFBytes(s:String):Void {
		
		#if neko
		var bytes = new Bytes (s.length, untyped s.__s);
		#else
		var bytes = Bytes.ofString (s);
		#end
		
		writeBytes (bytes, 0, 0);
		
	}
	
	
	@:noCompletion private inline function __fromBytes (bytes:Bytes):Void {
		
		b = bytes.b;
		length = bytes.length;
		
		#if neko
		allocated = length;
		#end
		
	}
	
	
	@:noCompletion @:keep inline public function __get (pos:Int):Int {
		
		#if cpp
		return untyped b[pos];
		#else
		return get (pos);
		#end
		
	}
	
	
	// #if !no_nme_io
	
	// @:noCompletion private static function __init__ ():Void {
		
	// 	var factory = function (length:Int) { return new ByteArray (length); };
	// 	var resize = function (bytes:ByteArray, length:Int):Void {
			
	// 		if (length > 0) {
				
	// 			bytes.ensureElem (length - 1, true);
				
	// 		}
			
	// 		bytes.length = length;
			
	// 	};
		
	// 	var bytes = function (bytes:ByteArray) { return bytes == null ? null : bytes.b; }
	// 	var slen = function(bytes:ByteArray) { return bytes == null ? 0 : bytes.length; }
		
	// 	var init = Lib.load ("nme", "nme_byte_array_init", 4);
	// 	init (factory, slen, resize, bytes);
		
	// }
	
	// #end
	
	
	@:noCompletion @:keep inline public function __set (pos:Int, v:Int):Void {
		
		#if cpp
		untyped b[pos] = v;
		#else
		set (pos, v);
		#end
		
	}
	
	
	@:noCompletion private function __throwEOFi ():Int {
		
		// throw new EOFError ();
		throw "EOF ERROR : __throwEOFi";
		return 0;
		
	}
	
	
	
	
	// Getters & Setters
	
	
	
	
	private function get_bytesAvailable ():Int { return length - position; }
	private function get_byteLength ():Int { return length; }
	private function get_endian ():String { return bigEndian ? Endian.BIG_ENDIAN : Endian.LITTLE_ENDIAN; }
	private function set_endian (value:String):String { bigEndian = (value == Endian.BIG_ENDIAN); return value; }
	
	
	
	
	// Native Methods
	
	
	
	
	private static var _double_bytes = Lib.load ("std", "double_bytes", 2);
	private static var _double_of_bytes = Lib.load ("std", "double_of_bytes", 2);
	private static var _float_bytes = Lib.load ("std", "float_bytes", 2);
	private static var _float_of_bytes = Lib.load ("std", "float_of_bytes", 2);
	// #if !no_nme_io
	// private static var nme_byte_array_overwrite_file = Lib.load ("nme", "nme_byte_array_overwrite_file", 2);
	// private static var nme_byte_array_read_file = Lib.load ("nme", "nme_byte_array_read_file", 1);
	// #end
	// private static var nme_lzma_encode = Lib.load ("nme", "nme_lzma_encode", 1);
	// private static var nme_lzma_decode = Lib.load ("nme", "nme_lzma_decode", 1);
	
}
#end