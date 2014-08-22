/************************************************************************************
	AJAX THREADS
	Version without comments
	2006-2007, Chris Marshall http://www.cmarshall.net/
*/

var	g_callback_array = new Array();
var g_av_encrypted = false;

function MakeNewAJAXCall(in_url, in_simple_callback, in_method, in_complex_callback, in_param, in_param2, in_timeout_callback, in_timeout_delay ){
	if(!in_method){
		in_method = "GET";
	}
	if(!in_timeout_delay){
		in_timeout_delay = 90;
	}
	var callback_index = 1;

	while(g_callback_array[callback_index]&&(typeof(g_callback_array[callback_index])!='undefined')){callback_index++};
	g_callback_array[callback_index] = new Array();
	g_callback_array[callback_index]['request_callback'] = in_simple_callback;
	g_callback_array[callback_index]['request_method'] = in_method;
	g_callback_array[callback_index]['request_complex_callback'] = in_complex_callback;
	g_callback_array[callback_index]['request_param'] = in_param;
	g_callback_array[callback_index]['request_param2'] = in_param2;
	g_callback_array[callback_index]['timeoutcallback'] = in_timeout_callback;

	var funcbody = 'var index='+callback_index+';';
	funcbody += 'var stage=g_callback_array[index]["request_object"].readyState;\
				var resp="";\
				if((navigator.appName!="Microsoft Internet Explorer") || (stage==4)){\
					resp=g_callback_array[index]["request_object"].responseText\
					};\
				if(g_callback_array[index]["request_complex_callback"]){\
					g_callback_array[index]["request_complex_callback"](stage, resp, g_callback_array[index]["request_param"], g_callback_array[index]["request_param2"], index)\
					};\
				if((stage==4) && g_callback_array[index]["request_callback"]){\
					if ( g_av_encrypted ) {\
						resp = av_decrypt ( resp );\
						}\
					g_callback_array[index]["request_callback"](resp, g_callback_array[index]["request_param"], g_callback_array[index]["request_param2"])\
					};\
				if(stage==4){\
					if(g_callback_array[index]["timeout_t"]){clearTimeout(g_callback_array[index]["timeout_t"])};\
					g_callback_array[index]["request_object"]=null;\
					g_callback_array[index]["request_callback"]=null;\
					g_callback_array[index]["request_method"]=null;\
					g_callback_array[index]["request_complex_callback"]=null;\
					g_callback_array[index]["request_param"]=null;\
					g_callback_array[index]["callback"]=null;\
					g_callback_array[index]["timeoutcallback"]=null;\
					g_callback_array[index]=null;\
					}';

	var funcbodytimeout = 'var index='+callback_index+';';
	funcbodytimeout += 'if(g_callback_array[index]["request_object"]){g_callback_array[index]["request_object"].onreadystatechange=null;g_callback_array[index]["request_object"].abort()};\
						if(g_callback_array[index]["timeoutcallback"]){g_callback_array[index]["timeoutcallback"](g_callback_array[index]["request_param"], g_callback_array[index]["request_param2"],index)};\
						g_callback_array[index]["request_object"]=null;\
						g_callback_array[index]["request_callback"]=null;\
						g_callback_array[index]["request_method"]=null;\
						g_callback_array[index]["request_complex_callback"]=null;\
						g_callback_array[index]["request_param"]=null;\
						g_callback_array[index]["callback"]=null;\
						g_callback_array[index]["timeoutcallback"]=null;\
						g_callback_array[index]=null;';

	g_callback_array[callback_index]['callback'] = new Function (funcbody);
	
	g_callback_array[callback_index]['timeout_t'] = setTimeout(new Function (funcbodytimeout),(in_timeout_delay * 1000));
	
	var ret = null;
	if(CallXMLHTTPObject ( in_url, in_method, g_callback_array[callback_index]['callback'], callback_index )){
		ret = callback_index;
	}
	return ret;
};

function CallXMLHTTPObject ( in_url, in_method, in_callback, in_index ) {
	try {
		var sVars = null;
		
		if ( in_method == "POST" ) {
			var rmatch = /^([^\?]*)\?(.*)$/.exec ( in_url );
			in_url = rmatch[1];
			sVars = unescape ( rmatch[2] );
		}
		
		g_callback_array[in_index]['request_object'] = MakeNewRequestObject();
		g_callback_array[in_index]['request_object'].open(in_method, in_url, true);

		if ( in_method == "POST" ) {
			g_callback_array[in_index]['request_object'].setRequestHeader("Method", "POST "+in_url+" HTTP/1.1");
			g_callback_array[in_index]['request_object'].setRequestHeader("Content-Type", "application/x-www-form-urlencoded");
		}
		g_callback_array[in_index]['request_object'].onreadystatechange = in_callback;
		g_callback_array[in_index]['request_object'].send(sVars);
		
		return true;
	} catch ( z ) {
	}
	
	return false;
};

function MakeNewRequestObject() {
	var	ret;
	if ( typeof XMLHttpRequest != 'undefined' ) {
		ret = new XMLHttpRequest();
	} else {
		if (typeof window.XMLHttpRequest != 'undefined') {
			ret = new XMLHttpRequest();
		} else {
				if (window.ActiveXObject) {
					if ( typeof dm_xmlhttprequest_type != 'undefined' ) {
						ret = new ActiveXObject(dm_xmlhttprequest_type);
					} else {
						var versions = ["Msxml2.XMLHTTP.7.0", "Msxml2.XMLHTTP.6.0", "Msxml2.XMLHTTP.5.0", "Msxml2.XMLHTTP.4.0", "MSXML2.XMLHTTP.3.0", "MSXML2.XMLHTTP", "Microsoft.XMLHTTP"];
						for (var i = 0; i < versions.length ; i++) {
							try {
								ret = new ActiveXObject(versions[i]);
								if (ret) {
									dm_xmlhttprequest_type = versions[i];
									break;
								}
							}
							catch (objException) {
							};
						};
					}
			}
		}
	}
	
	return ret;
};

if (typeof SupportsAjax == 'undefined'){
	function SupportsAjax ( ) {
		var test_obj = MakeNewRequestObject();
		
		if ( test_obj ) {
			test_obj = null;
			return true;
			}
		
		test_obj = null;
		
		return false;
	};
}

if ( typeof SimpleAJAXCall == 'undefined' ){
	
	function SimpleAJAXCall ( in_uri, in_callback, in_method, in_param ) {
		if ( (typeof in_method == 'undefined') || ((in_method != 'GET')&&(in_method != 'POST')) ) {
			in_method = 'GET';
			}
		
		in_method = in_method.toUpperCase();
		
		if ( SupportsAjax() && (typeof in_uri != 'undefined') && in_uri && (typeof in_callback == 'function') ) {
			return MakeNewAJAXCall ( in_uri, in_callback, in_method, null, in_param );
			}
		else {
			return false;
			}
	}
}