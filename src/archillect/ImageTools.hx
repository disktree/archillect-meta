package archillect;

import haxe.EnumTools.EnumValueTools;
import om.color.ColorParser;

class ImageTools {

	//public static var TENSORFLOW_MODEL = '/home/tong/src/tensorflow/models/tutorials/image/imagenet/inception_v3_2016_08_28_frozen.pb';
	public static var TENSORFLOW_MODEL_DIR = '/home/tong/src/tensorflow-models/inception-2015-12-05/';
	public static var TENSORFLOW_MODEL = '/home/tong/src/tensorflow-models/inception-2015-12-05/classify_image_graph_def.pb';

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
		switch proc.exitCode() {
		case 0:
			var str = proc.stdout.readAll().toString();
			proc.close();
			var i = str.indexOf('""');
			if( i != -1 ) str = str.substr( 0, i+1 );
			str = str.substr( 1, str.length-2 );
			return str;
		default:
			var error = proc.stdout.readAll().toString();
			proc.close();
			return throw error;
		}
	}

	/**
	*/
	public static function dominantColorToRGBA( str : String ) : { r : Int, g : Int, b : Int, a : Float } {
		switch str {
		case null:
			return null;
		case 'black':
			return { r : 0, g : 0, b : 0, a : 1.0 };
		default:
			var info = ColorParser.parseColor( str );
			if( info == null ) {
				println( 'WARNING: failed to parse color info [$str]' );
				return null;
			}
			switch info.name {
			case null:
				println( 'WARNING: failed to parse color info [$str]' );
				return null;
			case 'lineargray','lineargraya':
				println( 'WARNING: failed to parse color info [$str]' );
				return null;
			case 'white','black','cmyk':
				return { r : 0, g : 0, b : 0, a : 1.0 };
			case 'rgb','srgb':
				var a = ColorParser.getInt8Channels( info.channels, 3 );
				return { r : a[0], g : a[1], b : a[2], a : 1.0 };
			case 'rgba','srgba':
				return {
					r : EnumValueTools.getParameters( info.channels[0] )[0],
					g : EnumValueTools.getParameters( info.channels[1] )[0],
					b : EnumValueTools.getParameters( info.channels[2] )[0],
					a : EnumValueTools.getParameters( info.channels[3] )[0]
				};
			case 'gray','graya':
				var v = ColorParser.getInt8Channel( info.channels[0] );
				return { r : v, g : v, b : v, a : 1.0 };
			default:
				return throw 'unknown color space [$str]';
			}
		}
	}

	/**
		Run image recognition
	*/
	public static function classifyImage( path : String ) : Array<{name:String,precision:Float}> {
		var args = [
			'bin/classify_image.py',
			//'--model_dir', TENSORFLOW_MODEL,
			'--model_dir', TENSORFLOW_MODEL_DIR,
			'--image_file', path ];
		var proc = new Process( 'python', args );
		var code = proc.exitCode();
		var data : Array<{name:String,precision:Float}> = null;
		switch code {
	   	case 0:
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
			data = values;
		default:
			var error = proc.stderr.readAll();
			Sys.println('ERROR'+error);
	   	}
		proc.close();
		return data;
		/*
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
		*/
		return null;
	}

}
