package archillect;

//import sys.db.Sqlite;

/*
@:id(index)
class Image extends sys.db.Object {
    public var index : SId;
}
*/

class DB {

    static function main() {

        //var db = sys.db.Sqlite.open("archillect.db");
        //db.close();

        var argsHandler : Dynamic;
        argsHandler = hxargs.Args.generate([

            @doc("Create archillect.json") ["-json"] => () -> {
                var start = 1;
                var end = 165800;
                var data = new Array<ImageMetaData>();
                for( i in start...(end+1) ) {
                    Sys.println(i);
                    var json = Json.parse( File.getContent('meta/$i.json') );
                    data.push( json );
                }
                File.saveContent( 'archillect.json', haxe.format.JsonPrinter.print( data, '\t' ) );
            },

            @doc("Create wordlist.json") ["-wordlist"] => () -> {
                //var wordlist : Dynamic = {};

                println( 'Reading meta/*' );

                var wordlist = new Map<String,Array<Int>>();
                var files = FileSystem.readDirectory( 'meta' );
                for( i in 1...files.length ) {
                    var meta : ImageMetaData = Json.parse( File.getContent('meta/$i.json') );
                    if( meta.classification != null ) {
                        for( cl in meta.classification ) {
                            /*
                            if( Reflect.hasField( wordlist, cl.name ) ) {
                                Reflect.field( wordlist, cl.name ).push( meta.index );
                                //wordlist.field( cl.name ).push( meta.index );
                            } else {
                                Reflect.setField( wordlist, cl.name, [meta.index] );
                            }
                            */
                            if( wordlist.exists( cl.name ) ) {
                                wordlist.get( cl.name ).push( meta.index );
                            } else {
                                wordlist.set( cl.name, [meta.index] );
                            }
                        }
                    }
                }

                println( '...' );

                /*
                println( 'Sorting' );

                var sorted = new Array<{name:String,indexes:Array<Int>}>();
                for( f in wordlist.keys() ) {
                    var arr : Array<Int> = wordlist.get( f );
                    trace(sorted.length );
                    if( sorted.length == 0 ) {
                        sorted = [{name:f,indexes:arr}];
                    } else {
                        for( i in 0...sorted.length ) {
                            if( arr.length >= sorted[i].indexes.length ) {
                                sorted.insert( i, { name: f, indexes: arr } );
                            }
                        }
                    }
                }
                trace(sorted.length);
                */

                /*
                trace(Reflect.fields(wordlist).length);
                var sorted = new Array<{name:String,indexes:Array<Int>}>();
                for( f in Reflect.fields( wordlist ) ) {
                    var arr : Array<Int> = Reflect.field( wordlist, f );
                    for( i in 0...sorted.length ) {
                        if( arr.length >= sorted[i].indexes.length ) {
                            sorted.insert( i, { name: f, indexes: arr } );
                        }
                    }
                }

                trace(sorted.length);

                //File.saveContent( 'wordlist.json', Json.stringify( wordlist ) );
                */
            },

            _ => (arg:String) -> {
                println( 'Unknown command: $arg' );
                println( argsHandler.getDoc() );
                Sys.exit(1);
	        }
        ]);
        argsHandler.parse( Sys.args() );
    }

}
