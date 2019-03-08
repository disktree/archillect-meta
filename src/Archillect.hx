
import haxe.Http;

/**
	Hacks for gathering data.
**/
class Archillect {

	public static inline var URI = "http://archillect.com";

	/**
		Resolve the current index. HACK
	**/
	public static function resolveCurrentIndex() : Int {
		var searchTerm = '<div class="overlay">';
		var lines = Http.requestUrl( URI ).split('\n');
		for( line in lines ) {
			if( (line = line.trim()).startsWith( searchTerm ) ) {
				var str = line.substr( searchTerm.length );
				return Std.parseInt( str.substr( 0, str.length-'</div>'.length ).trim() );
			}
		}
		return throw 'failed to resolve current index';
	}

	/**
		Retrieve image url for given index.
	**/
	public static function resolveImageUrl( index : Int ) : String {
		var url = URI +'/'+ index;
		var html = Http.requestUrl( url );
		var line = StringTools.trim( html.split( '\n' )[19] );
		line = line.substr( 0, line.length-1 )+'/>';
		return Xml.parse( line ).firstElement().get( 'content' );
	}

	/**
		Download image and save it to given path.
	**/
	public static function downloadImage( url : String, dst : String ) : String {
		var status : Int;
		var req = new Http( url );
        var status : Int;
		req.onError = function(e) {
			url = null;
		}
		req.onStatus = function (e:Int) status = e;
        req.onData = function(e) {
            switch status {
            case 404:
				url = null;
            case 301:
                var location = url = req.responseHeaders.get( 'Location' );
				url = downloadImage( location, dst );
            case 200:
				File.saveBytes( dst, Bytes.ofString( e ) );
            }
        }
        req.request();
		return url;
	}

}
