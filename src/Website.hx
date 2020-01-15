
import haxe.Http;

/**
	Hacks for gathering data.
**/
class Website {

	public static inline var URI = "https://archillect.com";

	/**
		HACK: Resolve the current index.
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
		var curl = new Process( 'curl', [url] );
		var html = curl.stdout.readAll().toString();
		curl.close();
		for( line in  html.split( '\n' ) ) {
			if( line.indexOf('name="twitter:image"') != -1 ) {
				line = line.substr( 0, line.length-1 )+'/>';
				return Xml.parse( line ).firstElement().get( 'content' );
			}

		}
		return null;
		/*
		var url = URI +'/'+ index;
		var html = Http.requestUrl( url );
		for( line in  html.split( '\n' ) ) {
			if( line.indexOf('name="twitter:image"') != -1 ) {
				line = line.substr( 0, line.length-2 )+'/>';
				//trace(line);
				return Xml.parse( line ).firstElement().get( 'content' );
			}

		}
		return null;
		*/
		/*
		var line = StringTools.trim( html.split( '\n' )[19] );
		line = line.substr( 0, line.length-1 )+'/>';
		trace(line);
		return Xml.parse( line ).firstElement().get( 'content' );
		*/
	}

	/**
		Download image and save it to given path.
	**/
	public static function downloadImage( url : String, dst : String ) : String {
	//	var curl = new Process( 'curl', ['-o',dst,'-s','-w',"%{http_code}\n",url] );
		var curl = new Process( 'curl', ['-o',dst,url] );
		var code = curl.exitCode();
		//trace(code);
		switch code {
		case 0:
			//var data = curl.stdout.readAll();
			//curl.close();
			//File.saveBytes( dst, data );
			curl.close();
			return url;
		default:
			curl.close();
			return null;
		}
		
		return url;
		/*
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
		*/
	}

	/*
	function request( url : String ) {
		var curl = new Process( 'curl', [url] );
		var html = curl.stdout.readAll().toString();
		curl.close();
	}
	*/

}
