package archillect;

import haxe.Http;
import neko.vm.Thread;

using haxe.io.Path;

class Update {

    static function run( i : Int, classify = false ) {

        println( i );
        var metaFile = 'meta/$i.json';

        var meta : ImageMetaData = if( FileSystem.exists( metaFile ) ) {
            Json.parse( File.getContent( metaFile ) );
        } else {
            {
                index: i,
                url: Archillect.resolveImageUrl( i ),
                brightness: null,
                size: null,
                classification: null
            };
        }

        var imageName = meta.url.substr( meta.url.lastIndexOf('/')+1 );
        var imageExt = imageName.extension().toLowerCase();
        var imagePath = 'img/$i.$imageExt';

        //tmp cleanup from mess before
        if( imageExt != 'jpg'  ) {
            if( FileSystem.exists( 'img/$i.jpg' ) ) FileSystem.deleteFile(  'img/$i.jpg' );
        }

        var exists = FileSystem.exists( imagePath );
        if( !exists ) {
            var _url = Archillect.downloadImage( meta.url, imagePath );
            if( _url == null ) {
                println( 'Image not found: '+meta.url );
                exists = false;
            } else if( _url != meta.url ) {
                meta.url = _url;
                imageName = meta.url.substr( meta.url.lastIndexOf('/')+1 );
                imagePath = 'img/$i.$imageExt';
                exists = true;
            } else {
                exists = true;
            }
        }

        if( meta.url == null ) {
            meta.url = Archillect.resolveImageUrl( i );
        }
        if( meta.type == null ) {
            meta.type = imageExt;
        }

        if( exists ) {
            if( meta.size == null ) {
                meta.size = FileSystem.stat( imagePath ).size;
            }
            if( meta.width == null || meta.height == null ) {
                var size = Archillect.getImageSize( imagePath );
                meta.width = size.width;
                meta.height = size.height;
            }
            if( meta.brightness == null ) {
                try {
                    meta.brightness = Archillect.getImageBrightness( imagePath );
                } catch(e:Dynamic) {
                    trace(e);
                }
            }
            if( classify && meta.classification == null ) {
                switch imageExt {
                case 'jpg','jpeg':
                    meta.classification = Archillect.classifyImage( imagePath );
                default:
                    var tmpJpg = 'img/$i.jpg';
                    var imgPathCommand = imagePath;
                    if( imageExt == 'gif' ) {
                        imgPathCommand = '"$imagePath[0]"';
                    }
                    Sys.command( 'convert "$imgPathCommand" $tmpJpg' );
                    meta.classification = Archillect.classifyImage( tmpJpg );
                    FileSystem.deleteFile( tmpJpg );
                }
            }
            if( meta.face == null ) {

            }
        }

        var json = Json.stringify( meta, '  ' );
        println( json );
        File.saveContent( metaFile, json );
    }

    static function main() {

        if( Sys.systemName() != 'Linux' ) {
			println( 'Linux only' );
			Sys.exit( 1 );
		}

        //var cnx = sys.db.Sqlite.open("mybase.db");
        //sys.db.Manager.cnx = cnx;
        //sys.db.TableCreate.create(User.manager);

        var cmd : String;
        //var path : String;
        var start = 1;
        var end = 1000; //164269;
        var numThreads = 1;
        var classify = true;

        /*
        for( f in readDirectory('/mnt/HD1/images/archillect/archillect_0-50000.anal') ) {
            var id = Std.parseInt( f.substr( 0, f.indexOf( '-' ) ) );
            var ext = f.extension();
            var meta : Dynamic;
            var cl = Json.parse( File.getContent('/mnt/HD1/images/archillect/archillect_0-50000.anal/$f') );
            if( exists('meta/$id.json') ) {
                meta = Json.parse( File.getContent('meta/$id.json') );
                if( meta.classification == null ) {
                    meta.classification = cl;

                }
            } else {
                meta = {
                    index: id,
                    url: Archillect.resolveImageUrl( id ),
                    brightness: null,
                    size: null,
                    classification: cl
                };
            }
            var json = Json.stringify( meta, '  ' );
            println( json );
            File.saveContent( 'meta/$id.json', json );
        }
        return;
        */

        var argsHandler : Dynamic;
        argsHandler = hxargs.Args.generate([
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
            ["-classify"] => function(v:Bool) {
                classify = v;
            },
            _ => (arg:String) -> {
                println( 'Unknown command: $arg' );
                println( 'Usage : neko archillect.n <cmd> [params]' );
                println( argsHandler.getDoc() );
                Sys.exit(1);
	        }
        ]);

        var args = Sys.args();
        if( args.length == 0 ) {
            println( argsHandler.getDoc() );
            Sys.exit(1);
        } else {
            //cmd = args.pop();
            argsHandler.parse( args );
        }

        if( start >= end ) {
            println( 'Invalid index range' );
            Sys.exit(1);
        }

        if( classify ) {
            if( numThreads > 1 ) {
                println( 'Cannot run classification in multiple threads' );
                numThreads = 1;
            }
        }

        if( !FileSystem.exists( 'img' ) ) FileSystem.createDirectory( 'img' );
        if( !FileSystem.exists( 'meta' ) ) FileSystem.createDirectory( 'meta' );

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
                    for( i in start...end ) run( i, classify );
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
                run( i, classify );
            }
        }

    }

}
