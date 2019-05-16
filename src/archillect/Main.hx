package archillect;

import archillect.ImageMetaData;
import haxe.Http;
import haxe.EnumTools.EnumValueTools;
import om.Thread;
import om.color.ColorParser;

using haxe.io.Path;

class Main {

	static var argsHandler : {getDoc:Void->String,parse:Array<Dynamic>->Void};

    static function update( index : Int, imagePath : String, metaPath : String, classify = false, ocr = false ) {

		print( index+' ' );

		function printAction( t : String ) print( '/$t' );

		var metaFile = '$metaPath/$index.json';
		var meta : ImageMetaData;
		if( FileSystem.exists( metaFile ) ) {
			meta = Json.parse( File.getContent( metaFile ) );
		} else {
			printAction( 'N' );
			meta = {
                index: index,
                url: null, //Archillect.resolveImageUrl( index ),
				type: null,
				size: null,
				width: null,
				height: null,
                color: null,
                brightness: null,
                classification: null,
				text: null
            };
		}

		if( meta.url == null ) {
			printAction( 'URL' );
            meta.url = Archillect.resolveImageUrl( index );
        }
		if( meta.url == null ) {
			println( 'URL not resoved' );
			return;
        }

		//var imageName = meta.url.substr( meta.url.lastIndexOf('/')+1 );
        //var imageExt = imageName.extension().toLowerCase();
        var imageExt = meta.url.extension().toLowerCase();
        var imagePath = '$imagePath/$index.$imageExt';

		meta.type = imageExt;

		var exists = FileSystem.exists( imagePath );

		if( !exists ) {
			printAction( 'DL' );
			var _url = Archillect.downloadImage( meta.url, imagePath );
			if( _url == null ) {
				println( 'Image not found: '+meta.url );
				exists = false;
			} else if( _url != meta.url ) {
				println( 'Image changed url: '+meta.url );
				meta.url = _url;
				//imageName = meta.url.substr( meta.url.lastIndexOf('/')+1 );
				imagePath = 'img/$index.$imageExt';
				exists = true;
			} else {
				exists = true;
			}
		}

		if( exists ) {
			if( meta.size == null ) {
                meta.size = FileSystem.stat( imagePath ).size;
            }
			if( meta.width == null || meta.height == null ) {
				printAction( 'SZE' );
                var size = ImageTools.getImageSize( imagePath );
                meta.width = size.width;
                meta.height = size.height;
            }
			if( meta.brightness == null || meta.brightness == 0 ) {
				printAction( 'COL' );
				var colorStr = ImageTools.getDominantColor( imagePath );
				/*
				var colorStr :String = null; //= ImageTools.getDominantColor( imagePath );
				try {
					colorStr = ImageTools.getDominantColor( imagePath );
				} catch(e:Dynamic) {
					throw 'failed to determine color';
					trace(e);
					return;
				}
				if( colorStr == null )
				*/
				//var colorStr = ImageTools.getDominantColor( imagePath );
				var rgba = ImageTools.dominantColorToRGBA( colorStr );
				if( rgba == null ) {
					println( 'WARNING: failed to get image color [$colorStr]' );
				} else {
					meta.color = rgba;
					var rgb = om.color.space.RGB.create( meta.color.r, meta.color.g, meta.color.b );
					meta.brightness = rgb.toGrey();
				}
			}
			if( meta.color == null ) {
				meta.color = ImageTools.dominantColorToRGBA( ImageTools.getDominantColor( imagePath ) );
			}
			if( classify && meta.classification == null ) {
				printAction( 'CLS' );
				switch imageExt {
                case 'jpg','jpeg':
                    meta.classification = ImageTools.classifyImage( imagePath );
                default:
                    var tmpJpg = 'img/$index.jpg';
                    var imgPathCommand = imagePath;
                    if( imageExt == 'gif' ) {
                        imgPathCommand = '"$imagePath[0]"';
                    }
                    Sys.command( 'convert "$imgPathCommand" $tmpJpg' );
                    meta.classification = ImageTools.classifyImage( tmpJpg );
                    FileSystem.deleteFile( tmpJpg );
                }
			}
			if( ocr && meta.text == null ) {
				printAction( 'TXT' );
				var text = try ImageTools.findText( imagePath ) catch(e:Dynamic) {
					Sys.println(e);
					null;
				}
				if( text != null ) {
					//Sys.println( 'TEXT: '+text) ;
					meta.text = text;
				}
			}
		} else {
			println('Image not available [$index]');
			meta.size = null;
			meta.width = null;
			meta.height = null;
			meta.color = null;
			meta.brightness = null;
		}

		var json = Json.stringify( meta, '  ' );
        File.saveContent( metaFile, json );

		println( '' );
    }

	static function exit( ?msg : String, code = 0 ) {
		if( msg != null ) println( msg );
		Sys.exit( code );
	}

	static function error( msg : String, code = 1 ) {
		exit( msg, code );
	}

    static function main() {

        if( Sys.systemName() != 'Linux' )
			error( 'Linux only' );

        var cmd : String;
		var imagePath = 'img';
		var metaPath = 'meta';
        var start : Null<Int>;
        var end : Null<Int>;
        var numThreads = 1;
        var classify = true;
        var ocr = true;

        argsHandler = hxargs.Args.generate([
            @doc("Update db")
	        ["update"] => function() {
				cmd = "update";
            },
			@doc("Export meta data as single json file")
			["export"] => function(file:String) {
				var entries = new Array<ImageMetaData>();
				for( f in FileSystem.readDirectory( metaPath ) )
 				   	entries.push( Json.readFile( '$metaPath/$f' ) );
 			   	entries.sort( (a,b) -> return (a.index > b.index) ? 1 : (a.index < b.index) ? -1 : 0 );
 			   	File.saveContent( file, Json.stringify( entries ) );
 			   	Sys.exit(0);
			},
			/*
			@doc("Export classification word index")
			["wordlist"] => function() {
				cmd = "wordindex";
			},
			*/
			@doc("Path to image directory")
	        ["-image_path"] => function(path:String) {
				imagePath = path;
				if( !FileSystem.exists( imagePath ) )
		            error( 'Image directory not exists' );
            },
			@doc("Path to meta directory")
	        ["-meta_path"] => function(path:String) {
				metaPath = path;
            },
            @doc("Start index")
	        ["-start"] => function(i:Int) {
                start = i;
            },
            @doc("End index")
            ["-end"] => function(i:Int) {
                end = i;
            },
            @doc("Num threads to use")
            ["-threads"] => function(i:Int) {
                numThreads = i;
            },
            @doc("Run image classification")
            ["--classify"] => function() {
                classify = true;
            },
			@doc("Don't run image classification")
            ["--no-classify"] => function() {
                classify = false;
            },
			@doc("Don't run text recognition")
            ["--no-ocr"] => function() {
                ocr = false;
            },
			@doc("Print usage")
			["--help"] => function() {
				exit( argsHandler.getDoc() );
			},
            _ => (arg:String) -> {
                println( 'Unknown command: $arg' );
                println( 'Usage : neko archillect.n <cmd> [params]' );
                println( argsHandler.getDoc() );
                Sys.exit(1);
	        }
        ]);

		argsHandler.parse( Sys.args() );

		if( cmd == null ) cmd = 'update';
		if( start == null ) start = FileSystem.readDirectory( metaPath ).length;
		if( end == null ) end = Archillect.resolveCurrentIndex();
		if( start <= 0 || end <= 0 || start > end )
            error( 'Invalid index range' );
		//if( imagePath == null )
        //    error( 'No image directory specified' );
		if( classify ) {
            if( numThreads > 1 ) {
                println( 'Cannot run classification in multiple threads' );
                numThreads = 1;
            }
        }

		/*
        if( !FileSystem.exists( 'img' ) ) FileSystem.createDirectory( 'img' );
        if( !FileSystem.exists( 'meta' ) ) FileSystem.createDirectory( 'meta' );
		*/

		switch cmd {
		case "update":
			var numItems = (end-start);
			println( 'Start $start→$end / $numItems' );
			if( numThreads > 1 ) {
				var numDownloads = numItems;
	            if( numDownloads < numThreads ) numThreads = numDownloads;
	            var numUrlsPerThread = Std.int( numDownloads / numThreads );
	            var s = start;
	            for( i in 0...numThreads ) {
	                var t = Thread.create( function(){
	                    var main = Thread.readMessage(true);
	                    var start = Thread.readMessage(true);
	                    var num = Thread.readMessage(true);
	                    var end = start + num;
	                    for( i in start...end ) update( i, imagePath, metaPath, classify, ocr );
	                    main.sendMessage('ok');
	                });
	                t.sendMessage( Thread.current() );
	                t.sendMessage( s );
	                t.sendMessage( numUrlsPerThread );
	                s += numUrlsPerThread;
	            }
	            for( i in 0...numThreads ) {
	                var result = Thread.readMessage(true);
	                if( result != 'ok' ) {
	                    println(result);
	                    Sys.exit(1);
	                } else {
	                    trace("TODO load more in new threads");
	                }
	            }
			} else {
				for( i in start...(end+1) ) {
					update( i, imagePath, metaPath, classify, ocr );
				}
			}
			println( 'Done $numItems $start→$end' );
			/*
		case "wordindex":
			//TODO
			/*
			var wordlist = new Array<String>();
			function readMeta( i : Int ) {
				println(i+' '+ wordlist.length);
				//var classifications : Array<Classification> = Json.readFile( '$metaPath/$i.json' ).classification;
				var classifications : Array<Classification> = try Json.readFile( '$metaPath/$i.json' ).classification catch(e:Dynamic) {
					trace(e);
					return;
				}
				for( cl in classifications ) {
					if( wordlist.indexOf( cl.name ) == -1 ) {
						wordlist.push( cl.name );
					}
				}
				if( i == end ) {
					trace('DONE',wordlist.length);
					Sys.exit(0);
				} else {
					readMeta( ++i );
				}
			}
			readMeta( start );
			*/
			/*
			var map = new Map<String,Array<Int>>();
			function readMeta( i : Int ) {
				println(i);
				var meta : ImageMetaData = Json.readFile( '$metaPath/$i.json' );
				for( cl in meta.classification ) {
					if( map.exists( cl.name ) ) {
						map.get( cl.name ).push( i );
					} else {
						map.set( cl.name, [i] );
					}
				}
				if( ++i >= end ) {
					trace('DONE');
					var obj : Dynamic = {};
					for( k=>v in map ) {
						Reflect.setField( obj, k, v );
					}
					//File.saveContent( 'wordlist.json', Json.stringify( obj ) );
					File.saveContent( 'wordlist.json', haxe.format.JsonPrinter.print( obj, '\t' ) );
				} else {
					readMeta( i );
				}
			}
			readMeta( start );
			*/
		}
    }

}
