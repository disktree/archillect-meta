package archillect;

class ImageTools {

	public static var TENSORFLOW_MODEL = '/home/tong/src/tensorflow/models/tutorials/image/imagenet/inception_v3_2016_08_28_frozen.pb';

	/**
	*/
	public static function getImageSize( path : String ) : { width : Int, height : Int } {
		var result : { width : Int, height : Int };
		var identify = new Process( 'identify', ['-ping','-format','"%w %h"',path] );
		switch identify.exitCode() {
		case 0:
			var str = identify.stdout.readAll().toString().trim().substr(1);
			identify.close();
			str = str.substr( 0, str.length-1 );
			var a = str.split( ' ' );
			return { width: Std.parseInt( a[0] ), height: Std.parseInt( a[1] ) };
		default:
			var error = identify.stderr.readAll().toString();
			identify.close();
			return throw error;
		}
		return null;
	}

	/**
	*/
	public static function getDominantColor( path : String ) : String {
		var proc = new Process( 'convert', [path,'-resize','1x1!','-format','"%[pixel:u]"','info:-'] );
		return switch proc.exitCode() {
		case 0:
			var result = proc.stdout.readAll().toString();
			proc.close();
			result;
		default:
			var error = proc.stdout.readAll().toString();
			proc.close();
			throw error;
		}
	}

	/**
	*/
	/*
	public static function getImageBrightness( path : String ) : Int {
		var identify = new Process( 'convert', [path,'-resize','1x1!','-format','"%[fx:int(255*r+.5)],%[fx:int(255*g+.5)],%[fx:int(255*b+.5)]"','info:-'] );
		switch identify.exitCode() {
		case 0:
			trace(">>>>>>>>>>>>>>>");
			var str = identify.stdout.readAll();
			trace(str);
			return 0;
		default:
			trace("eeeeeeeeeeeeee");
			identify.close();
			return throw "ererer";

		}
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
			trace(val);
			val = val.substr( 1 );
			val = val.substr( 0, val.indexOf('"') );
			var rgb = val.split(',');
			trace(rgb);
			brightness = ((Std.parseInt(rgb[0]) & 0xFF) << 16) | ((Std.parseInt(rgb[1]) & 0xFF) << 8) | ((Std.parseInt(rgb[2]) & 0xFF) << 0);
		}
		identify.close();
		return brightness;
	}
	*/

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

	/*
	public static function gifToVideo( src : String, dst : String ) {
		Sys.command( 'ffmpeg -f gif -i $src $dst' );
	}
	*/
}
