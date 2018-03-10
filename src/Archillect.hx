
import haxe.Json;
#if sys
import haxe.Http;
import haxe.io.Bytes;
import sys.FileSystem;
import sys.io.File;
import sys.io.Process;
import Sys.print;
import Sys.println;
#end
#if neko
import neko.vm.Thread;
#end

using StringTools;

typedef ImageMetaData = {
	var index : Int;
	var url : String;
	@:optional var type : String;
	@:optional var size : Int;
	@:optional var brightness : Int;
	@:optional var classification : Array<Dynamic>;
}

class Archillect {

	//TODO
	/*
	macro public static function getMetaData() : ExprOf<Array<Dynamic>> {
		var data = new Array<Dynamic>();
		for( f in FileSystem.readDirectory( '../meta' ) ) {
			data.push( File.getContent( '../meta/$f') );
		}
		return macro $v{data};
	}
	*/

	#if sys

	public static var TENSORFLOW_MODEL = '/home/tong/src/tensorflow/models/tutorials/image/imagenet/inception_v3_2016_08_28_frozen.pb';

	/**
		Retrieve archillect image url for given index.
	*/
	public static function resolveImageUrl( index : Int ) : String {
		var url = 'http://archillect.com/' + index;
		var html = Http.requestUrl( url );
		var line = StringTools.trim( html.split( '\n' )[18] );
		return line.substring( 17, line.length - 3 );
	}

	/**
		Download file and save it to given path.
	*/
	public static function downloadImage( url : String, dst : String ) : String {
		var status : Int;
		var request = new Http( url );
        var status : Int;
		request.onError = function(e) {
			url = null;
		}
		request.onStatus =function (e:Int) status = e;
        request.onData = function(e) {
		//	trace( status );
            switch status {
            case 404:
				url = null;
            case 301:
                var location = url = request.responseHeaders.get( 'Location' );
				url = downloadImage( location, dst );
            case 200:
				File.saveBytes( dst, Bytes.ofString( e ) );
            }
        }
        request.request();
		return url;
	}

	/**
	*/
	public static function getImageBrightness( path : String ) : Int {
		var brightness : Int;
		var identify = new Process( 'convert', [path,'-resize','1x1!','-format','"%[fx:int(255*r+.5)],%[fx:int(255*g+.5)],%[fx:int(255*b+.5)]"','info:'] );
		var result = identify.stdout.readAll();
		var error = identify.stderr.readAll().toString();
		if( error != "" ) {
			trace(error.toString());
			return null;
		} else {
			var val = result.toString().trim();
			val = val.substr( 1 );
			val = val.substr( 0, val.indexOf('"') );
			var rgb = val.split(',');
			brightness = ((Std.parseInt(rgb[0]) & 0xFF) << 16) | ((Std.parseInt(rgb[1]) & 0xFF) << 8) | ((Std.parseInt(rgb[2]) & 0xFF) << 0);
		}
		identify.close();
		return brightness;
	}

	/**
	*/
	public static function classifyImage( path : String ) {
		var args = [
			'script/classify_image.py',
			'--model_dir', TENSORFLOW_MODEL,
			'--image_file', path ];
		var proc = new Process( 'python', args );
		var data =switch proc.exitCode() {
		case 0:
			//TODO write json
			var result = proc.stdout.readAll().toString();
			var values = new Array<{name:String,precision:Float}>();
			var lines = result.split('\n');
			lines.pop();
			for( line in lines ) {
				var i = line.indexOf('(');
				var strWords = line.substr( 0, i-1 );
				var strPrecision = line.substring( i+9, line.length-1 );
				var words = strWords.split(', ');
				var precision = Std.parseFloat( strPrecision );
				//trace( words, precision );
				for( word in words ) {
					values.push( { name: word, precision: precision } );
				}
			}
			values;
		default:
			var error = proc.stderr.readAll();
			Sys.println('EEEEEEEEEEEEEEERROR'+error);
			null;
		}
		proc.close();
		return data;
	}

	#end

}
