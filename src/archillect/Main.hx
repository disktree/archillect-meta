package archillect;

import haxe.Http;
import haxe.EnumTools.EnumValueTools;
import om.Thread;
import om.color.ColorParser;

using haxe.io.Path;

class Main {

	static var argsHandler : {getDoc:Void->String,parse:Array<Dynamic>->Void};

    static function update( index : Int, imagePath : String, metaPath : String, classify = false ) {

		println( index );

		var metaFile = '$metaPath/$index.json';
        var meta : ImageMetaData = if( FileSystem.exists( metaFile ) ) {
            Json.parse( File.getContent( metaFile ) );
        } else {
            {
                index: index,
                url: Archillect.resolveImageUrl( index ),
				type: null,
				size: null,
				width: null,
				height: null,
                color: null,
                brightness: null,
                classification: null
            };
        }

		var imageName = meta.url.substr( meta.url.lastIndexOf('/')+1 );
        var imageExt = imageName.extension().toLowerCase();
        var imagePath = '$imagePath/$index.$imageExt';

		meta.type = imageExt;

		if( meta.url == null ) {
            meta.url = Archillect.resolveImageUrl( index );
        }

		var exists = FileSystem.exists( imagePath );

		if( !exists ) {
			println('Downloading …');
			var _url = Archillect.downloadImage( meta.url, imagePath );
			if( _url == null ) {
				println( 'Image not found: '+meta.url );
				exists = false;
			} else if( _url != meta.url ) {
				println( 'Image changed url: '+meta.url );
				meta.url = _url;
				imageName = meta.url.substr( meta.url.lastIndexOf('/')+1 );
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
                var size = ImageTools.getImageSize( imagePath );
                meta.width = size.width;
                meta.height = size.height;
            }
			if( meta.brightness == null || meta.brightness == 0 ) {
				var colorStr = ImageTools.getDominantColor( imagePath );
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
		} else {
			println('Image not available [$index]');
			meta.size = null;
			meta.width = null;
			meta.height = null;
			meta.color = null;
			meta.brightness = null;
		}

		var json = Json.stringify( meta, '  ' );
        //println( json );
        File.saveContent( metaFile, json );
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

		/*
        for( i in 1...175000 ) {
            var meta = Json.parse( File.getContent( 'meta/$i.json' ) );
            if( meta.type == 'gif' ) {
                trace(i);
                Sys.command( 'ffmpeg -f gif -r 60 -i img/$i.gif video/$i.mp4' );
            }
        }
        return;
		*/

        var cmd : String;
		var imagePath : String;
		var metaPath = 'meta';
        var start : Null<Int>; //= 1;
        var end : Null<Int>; //= 1000;
        var numThreads = 1;
        var classify = false;

        argsHandler = hxargs.Args.generate([
            @doc("Update db")
	        ["update"] => function() {
				cmd = "update";
            },
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
            ["-classify"] => function() {
                classify = true;
            },
			@doc("Print usage")
			["--help"] => function() {
				exit( argsHandler.getDoc() );
			},
            /*
            @doc("Export json file")
            ["-json"] => function(file:String) {
            },
            */
            _ => (arg:String) -> {
                println( 'Unknown command: $arg' );
                println( 'Usage : neko archillect.n <cmd> [params]' );
                println( argsHandler.getDoc() );
                Sys.exit(1);
	        }
        ]);

		argsHandler.parse( Sys.args() );

		if( cmd == null ) {
			println( 'No command specified' );
			error( argsHandler.getDoc() );
		}
		if( start == null )
            error( 'No start index specified' );
		if( end == null )
            error( 'No end index specified' );
		if( start <= 0 || end <= 0 || start > end )
            error( 'Invalid index range' );
		if( imagePath == null )
            error( 'No image directory specified' );
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
			if( numThreads > 1 ) {
				var numDownloads = end - start;
	            if( numDownloads < numThreads ) numThreads = numDownloads;
	            var numUrlsPerThread = Std.int( numDownloads / numThreads );
	            var s = start;
	            for( i in 0...numThreads ) {
	                var t = Thread.create( function(){
	                    var main = Thread.readMessage(true);
	                    var start = Thread.readMessage(true);
	                    var num = Thread.readMessage(true);
	                    var end = start + num;
	                    for( i in start...end ) update( i, imagePath, metaPath, classify );
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
					update( i, imagePath, metaPath, classify );
				}
			}
		}
    }

}
