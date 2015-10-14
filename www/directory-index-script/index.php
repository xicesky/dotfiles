<?php
// Configuration and defaults

$config = array(
    "url_host" => "https://dev.georeach.com",
    "url_subdir" => dirname($_SERVER['SCRIPT_NAME']),
);

// This makes the intent much clearer, as PHP refs are a mess
function array_clear(&$a) {
    $a = array();
}

function array_drop_keys(&$a) {
    ksort($a);
    $a = array_values($a);
    return $a;
}

function four_oh_four() {
    header('HTTP/1.0 404 Not Found'); ?>
<html>
<head><title>404 Not Found</title></head>
<body bgcolor="white">
<center><h1>404 Not Found</h1></center>
<hr><center>The page that you have requested could not be found.</center>
</body>
</html>
<?php
    exit();
}

function redirect($url, $code = 302) {
    header("Location: $url", true, $code);
    exit(0);
}

function passthrough_json($data) {
    header('Content-type: application/json');
    header('Cache-Control: no-cache, must-revalidate');
    header('Expires: '.gmdate('D, d M Y H:i:s \G\M\T'));
    echo json_encode($data, JSON_PRETTY_PRINT|JSON_UNESCAPED_SLASHES);
    exit(0);
}

function human_filesize($bytes, $decimals = 2) {
    $sz = 'BKMGTP';
    $factor = floor((strlen($bytes) - 1) / 3);
    return sprintf("%.{$decimals}f", $bytes / pow(1024, $factor)) . @$sz[$factor];
}

function file_filter($fn) {
    return !is_link($fn);
}

$file_exts_allowed = array(
    ".zip", ".pdf", ".png", ".jpeg", ".jpg", ".xls", ".doc", ".ppt"
);

$files = array();
foreach ($file_exts_allowed as $xt) {
    $files = array_merge($files, glob("*$xt"));
}
$files = array_filter($files, "file_filter");
sort($files);

// Check "path" parameter
$pathparam = substr($_SERVER['REQUEST_URI'], strlen($_SERVER['SCRIPT_NAME']));
if (substr($pathparam, 0, 1) == '/')
    $pathparam = substr($pathparam, 1);
if (strlen($pathparam) > 0) {

    // Not found
    four_oh_four();
}

// Normal HTML output
?>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="utf-8">
    <title>File uploads</title>
    <link rel="stylesheet" href="https://maxcdn.bootstrapcdn.com/bootstrap/3.3.2/css/bootstrap.min.css">
    <link rel="stylesheet" href="https://maxcdn.bootstrapcdn.com/bootstrap/3.3.4/css/bootstrap-theme.min.css">
    <style type="text/css">
        .collapse-box .panel-heading a {
            color: #000000;
        }
    </style>
</head>
<body>
    <div class="jumbotron">
        <div class="container">
            <h1>File uploads</h1>
        </div>
    </div>    
    <div class="container">
    <div class="row">
    <div class="col-md-12">
    <h1>Files</h1>
    <table class="table table-hover">
        <thead>
            <tr><th>Filename</th><th>Size</th><th>Modification time</th></tr>
        </thead>
<?php

    foreach ($files as $fn) {
        echo "    <tr>";
        echo "<td><a href=\"$fn\">" . htmlentities($fn) . "</a></td>";
        echo "<td>" . htmlentities(human_filesize(filesize($fn))) . "</td>";
        echo "<td>" . htmlentities(date("l, Y.m.d H:i:s",filemtime($fn))) . "</td>";
        echo "</tr>\r\n";
    }
?>
    </table>
    </div><!-- col-md-12 -->
    </div><!-- row -->
    </div><!-- container -->
    <script src="https://ajax.googleapis.com/ajax/libs/jquery/1.11.2/jquery.min.js"></script>
    <script src="https://maxcdn.bootstrapcdn.com/bootstrap/3.3.4/js/bootstrap.min.js"></script>
<!--
<?php
    #print_r($_SERVER);
    #print_r($GLOBALS);
    $fn = substr($_SERVER['REQUEST_URI'], strlen($_SERVER['SCRIPT_NAME']));
    echo "$fn\r\n";
    echo "Path param: \"$pathparam\"\r\n";
    print_r( explode('/', $pathparam) );
?>
-->
</body>
