package archillect.web;

import js.html.InputElement;

class App {

    static function search( term : String, ?precision : Float, ?limit : Int ) : Promise<Array<ImageMetaData>> {
        return window.fetch( 'http://localhost:7777', {
            method: "POST",
            body: Json.stringify( {
                term: term,
                precision: precision,
                limit: limit
            } )
        } ).then( function(r:js.html.Response){
            return r.json().then( function(found:Array<ImageMetaData>){
                return found;
            });
        });
    }

    static function main() {

        var images = document.querySelector( 'ol.images' );
        var term : InputElement = cast document.querySelector( 'form input[name=search]' );
        var precision : InputElement = cast document.querySelector( 'form input[name=precision]' );
        var limit : InputElement = cast document.querySelector( 'form input[name=limit]' );

        /*
        input.oninput = function(e) {
            var str = input.value.trim();
            trace(str);
            if( str.length >= 2 ) {
                search( str ).then( function(r){
                    trace(r);
                });
            }
        }
        */

        window.onkeydown = function(e) {
            switch e.keyCode {
            case 13:
                var str = term.value.trim();
                if( str.length >= 2 ) {
                    for( e in images.children ) images.removeChild( e );
                    var precisionValue = Std.parseFloat( precision.value );
                    var limitValue = Std.parseInt( limit.value );
                    search( str, precisionValue, limitValue ).then( function(found:Array<ImageMetaData>){
                        if( found.length == 0 ) {
                            window.alert( 'Nothing found' );
                        } else {
                            trace( found.length );
                            for( i in 0...found.length ) {

                                var meta = found[i];
                                var img = document.createImageElement();
                                img.src = meta.url;
                                img.title = meta.index+'';
                                images.appendChild( img );

                                if( i > limitValue )
                                    break;
                            }
                        }
                    });
                }
            }
        }

        /*
        var data = Archillect.getMetaData(1,1000);
        //trace(data);

        for( i in 1...100 ) {

            var meta = Json.parse( data[i] );
            trace( meta);

            var img = document.createImageElement();
            img.src = '../img/'+meta.index+'.'+meta.type;
            document.body.appendChild( img );
        }
        */
    }
}
