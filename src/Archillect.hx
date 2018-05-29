
#if sys
import haxe.Http;
#end
#if neko
import neko.vm.Thread;
#end

/**
**/
class Archillect {

	//TODO
	macro public static function getMetaData( start : Int = 0, end : Int = 100000 ) : ExprOf<Array<Dynamic>> {
		var data = new Array<Dynamic>();
		for( i in start...end ) {
			data.push( File.getContent( '../meta/$i.json') );
		}
		/*
		for( f in FileSystem.readDirectory( '../meta' ) ) {
			data.push( File.getContent( '../meta/$f') );
		}
		*/
		return macro $v{data};
	}

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
	public static function getImageSize( path : String ) : { width : Int, height : Int } {
		var identify = new Process( 'identify', ['-ping','-format', '"%w %h"', path] );
		switch identify.exitCode() {
		case 0:
			var str = identify.stdout.readAll().toString().trim().substr(1);
			str = str.substr( 0, str.length-1 );
			var a = str.split( ' ' );
			return { width: Std.parseInt( a[0] ), height: Std.parseInt( a[1] ) };
		case 1:
			var error = identify.stderr.readAll().toString();
			trace(error);
			return throw error;
		}
		return null;
	}

	/**
	*/
	public static function getImageBrightness( path : String ) : Int {
		var identify = new Process( 'convert', [path,'-resize','1x1!','-format','"%[fx:int(255*r+.5)],%[fx:int(255*g+.5)],%[fx:int(255*b+.5)]"','info:-'] );
		var result = identify.stdout.readAll();
		var error = identify.stderr.readAll().toString();
		//trace(result);
		//trace(error);
		var brightness : Int;
		//TODO identify ping ?
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
		Run image recognition
	*/
	public static function classifyImage( path : String ) {
		var args = [
			'bin/classify_image.py',
			'--model_dir', TENSORFLOW_MODEL,
			'--image_file', path ];
		var proc = new Process( 'python', args );
		try {
			var code = proc.exitCode();
			var data = switch code {
			case 0:
				//TODO write json
				var result = proc.stdout.readAll().toString();
				var values = new Array<{name:String,precision:Float}>();
				trace(values);
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
				Sys.println('ERROR'+error);
				null;
			}
			proc.close();
			return data;
		} catch(e:Dynamic) {
			trace(e);
		}
		return null;
	}

	#end

}
