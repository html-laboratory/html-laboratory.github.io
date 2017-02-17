<?php
declare(strict_types=1);
error_reporting(E_ALL);
call_user_func(function($time){
	if(array_key_exists('source',$_GET)){
		header('Content-Type:text/plain');
		$str=file_get_contents(__FILE__);
	}else{
		$array=[];
		$ServerName=$_ENV['SERVER_NAME'];
		$DocumentRoot=$_ENV['DOCUMENT_ROOT'];
		foreach($_ENV as $key => $value){
			if($value==="webmaster@${ServerName}"){
				$value='webmaster@example.com';
			}elseif(strpos((string)$value,$DocumentRoot)!==false){
				$value=strtr($value,array($DocumentRoot=>'/home/u0000/public_html'));
			}
			$array[htmlspecialchars((string)$key,ENT_COMPAT|ENT_HTML5,'UTF-8')]=htmlspecialchars((string)$value,ENT_COMPAT|ENT_HTML5,'UTF-8');
			if($key==='REMOTE_ADDR'&&!$_ENV['REMOTE_HOST']){
				$RemoteHost=gethostbyaddr($value);
				if($RemoteHost&&$value!==$RemoteHost){
					$array['REMOTE_HOST']=htmlspecialchars($RemoteHost,ENT_COMPAT|ENT_HTML5,'UTF-8');
				}
			}
		}
		$str=sprintf(<<<'HTML'
<!DOCTYPE html>
<html xmlns="http://www.w3.org/1999/xhtml">
	<head>
		<meta charset="UTF-8" />
		<title>Display environment variables</title>
		<meta name="viewport" content="width=device-width,initial-scale=1,user-scalable=no" />
		<meta name="format-detection" content="telephone=no,email=no,address=no" />
		<meta name="referrer" content="never" />
		<link rel="dns-prefetch" href="//secure.php.net" />
		<!--<link rel="preconnect" href="https://dns.google.com" crossorigin="crossorigin" />-->
		<style>
			@media all{
				body{
					background-color:Window;
					color:WindowText;
					overflow:auto;
					white-space:nowrap;
				}
				::selection{
					background-color:Highlight;
					color:HighlightText;
				}
				table{
					border-collapse:collapse;
				}
				tr>*{
					border:#000 solid 1px;
				}
			}
		</style>
	</head>
	<body role="application">
		<dl>
			<dt>Help</dt>
			<dd><a href="https://secure.php.net/manual/ja/reserved.variables.server.php" rel="external">PHP: $_SERVER - Manual</a></dd>
			<dt>Get source of this PHP file.</dt>
			<dd><a id="source"></a></dd>
		</dl>
		<script async="async">
			"use strict";
			(function(){
				addEventListener('load',function main(e){
					var blob=URL.createObjectURL(new Blob([document.querySelector('[type="text/js-worker"]').firstChild.nodeValue],{"type":"text/javascript"})),
						worker=new Worker(blob),
						filename=location.pathname.split('/').pop(),
						source=document.getElementById("source");
					document.body.insertBefore(document.createElement("header"),document.body.firstChild).appendChild(document.createElement("h1")).appendChild(document.createTextNode(document.title));
					worker.postMessage(document.querySelector('[type="apptication/json"]').firstChild.nodeValue);
					worker.addEventListener("message",function(e){
						document.getElementsByTagName("header")[0].insertAdjacentHTML("AfterEnd",e.data);
						e.target.terminate();
						URL.revokeObjectURL(blob);
					});
					source.href=`${filename}?source`;
					source.textContent=filename;
					console.log("Request time:%2$ums");
					e.target.removeEventListener(e.type,main);
				});
			}());
		</script>
		<script type="text/js-worker">
			"use strict";
			(function(){
				addEventListener("message",function(e){
					var data=JSON.parse(e.data),
						table="<table><tbody>",
						i;
					for(i in data){
						table+=`<tr><th>${i}</th><td>${data[i]}</td></tr>`;
					}
					table+="</tbody></table>";
					postMessage(table);
				});
			}());
		</script>
		<script type="apptication/json">
			%1$s
		</script>
	</body>
</html>
HTML
,json_encode($array,JSON_UNESCAPED_SLASHES|JSON_UNESCAPED_UNICODE|JSON_PARTIAL_OUTPUT_ON_ERROR),($_ENV['REQUEST_TIME_FLOAT']-$time)*1000);
		header('ETag:"'.hash('md5',$str).'"');
	}
	header('Last-Modified:'.date('r',filemtime(__FILE__)));
	ini_set('zlib.output_compression_level','9');
	//echo gzencode($str,9);
	echo $str;
},$_ENV['REQUEST_TIME_FLOAT']);