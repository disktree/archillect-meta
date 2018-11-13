
import haxe.Http;

/**
**/
class Archillect {

	public static inline var URI = "http://archillect.com";

	//TODO
	/*
	macro public static function getMetaData( start : Int = 0, end : Int = 100000 ) : ExprOf<Array<Dynamic>> {
		var data = new Array<Dynamic>();
		for( i in start...end ) {
			data.push( File.getContent( '../meta/$i.json') );
		}
		/*
		for( f in FileSystem.readDirectory( '../meta' ) ) {
			data.push( File.getContent( '../meta/$f') );
		}
		* /
		return macro $v{data};
	}
	*/

	//public static var TENSORFLOW_MODEL = '/home/tong/src/tensorflow/models/tutorials/image/imagenet/inception_v3_2016_08_28_frozen.pb';

	/**
		Retrieve archillect image url for given index.
	*/
	public static function resolveImageUrl( index : Int ) : String {
		var url = URI +'/'+ index;
		var html = Http.requestUrl( url );
		//TODO parse source link
		//TODO parse xml ?
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
		request.onStatus = function (e:Int) status = e;
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

}
