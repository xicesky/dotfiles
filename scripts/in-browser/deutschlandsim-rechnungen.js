
/*
    Author: Markus Dangl
    License: BSD
    !No warranties of any kind!
*/

// Array to put the extracted data in
var data = [];

// Those contain the actual download links
var pdfs = $(".pdf a").not(":contains('Einzelverbindungsnachweis')");

// For each of those:
pdfs.each(function(index) {
    var pdf = this;
    /* Find the title, its a p element in the span "scope" above:
        <span>
            <p class="aufklappen">Rechnung vom 31.01.2015</p>
            <div class="infotext">
                <p class="pdf"><a href="/mytariff/invoice/showPDF/21341234213" target="_blank">Rechnung</a></p>
                
                <p class="pdf"><a href="/mytariff/invoice/showPDF/12341243231" target="_blank">Einzelverbindungsnachweis</a></p>
            </div>
        </span>
    */
    var e_title = $(pdf).parent().parent().siblings('.aufklappen,.zuklappen')[0];
    title = $(e_title).html();
    var url = pdf.href;
    if (!url.match(/showPDF/i)) return;
    data.push({
        index: index,
        title: title,
        url: url,
        // Rest is for fun
        element1: pdf,
        element2: e_title,
    });
    // console.log(index, url, title);

});

// TODO: Sort data?

// Generate a new div and output
var output = $('#output');
if (!output.length) {
    output = $('<div>', { id: 'output' }).appendTo('body');
}
output.html('');

var out_links = $('#output p');
if (!out_links.length) {
    out_links = $('<p>').appendTo('#output');
}

var out_pre = $('#output pre');
if (!out_pre.length) {
    $('<hr>').appendTo('#output')
    out_pre = $('<pre>').appendTo('#output');
}

// Output as download link
out_links.html('');
data.forEach(function(d) {

    var fn = d.title.replace(/[^a-zA-Z0-9]/g, '_') + '.pdf';
    // var dl = $('<a>', { text: d.title, href: d.url, download: fn});
    var dl = $('<a>', { text: d.title, href: d.url });
    out_links.append(dl);
    out_links.append('<br/>');
});

// Output as CURL
out_pre.html('');
// Does not display HttpOnly cookies :(
//out_pre.append('COOKIE="' + document.cookie + '"').append('<br/>');
out_pre.append('# Fetch the real cookie from the network page in the developer tools').append('<br/>');
out_pre.append('# and save it as COOKIE environment variable').append('<br/>');
out_pre.append('COOKIE=""').append('<br/>');
data.forEach(function(d) {
    /* CURL:
        curl "https://service.deutschlandsim.de/mytariff/invoice/showPDF/180816885"
        -H "Pragma: no-cache"
        -H "Cache-Control: no-cache"
        -H "Referer: https://service.deutschlandsim.de/mytariff/invoice/show"
        -H "Cookie: _ga=GA1.2.749832728.1423602770; isCookieAllowed=true; _SID=salr01qvm9f0einv5avb20gl86; sw_UNC=MDAwMjY0NjU3NTc079T"%"2FVMJWnVM"%"3D; __utma=177079856.749832728.1423602770.1423611747.1423651526.4; __utmb=177079856.8.10.1423651526; __utmc=177079856; __utmz=177079856.1423602770.1.1.utmgclid=Cj0KEQiA9eamBRDqvIz_qPbVteABEiQAnIBTEEMLCdyjHbYvRWByKDfowgJ5A-DhrY15ncBeoMD4dVYaAsbu8P8HAQ|utmccn=(not"%"20set)|utmcmd=(not"%"20set)|utmctr=(not"%"20provided)"
    */
    // -H "Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8"
    // -H "User-Agent: Mozilla/5.0 (Windows NT 6.1; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/40.0.2214.111 Safari/537.36"
    // -H "Accept-Encoding: gzip, deflate, sdch"
    // -H "Accept-Language: de-DE,de;q=0.8,en-GB;q=0.6,en;q=0.4,en-US;q=0.2" 
    // -H "Connection: keep-alive"
    // --compressed

    var fn = d.title.replace(/[^a-zA-Z0-9]/g, '_') + '.pdf';
    var p = out_pre;
    p.append('curl "' + d.url + '" -H "Cookie: $COOKIE" -o "' + fn + '"').append('<br/>');
});

output.css({
    backgroundColor: '#EEEEEE',
    border: '2px solid black',
    padding: '10px',
});

output.css({
    position: "absolute",
    // position: "fixed",
    width: "800px",
    height: "auto",
    left: "0",
    right: "0",
    top: "20px",
    marginLeft: "auto",
    marginRight: "auto",
});


// Generate a new div for shading
var shader = $('#shader');
if (!shader.length) {
    shader = $('<div>', { id: 'shader' }).appendTo('body');
}
shader.html('');

shader.css({
    position: "fixed",
    left: "0",
    right: "0",
    top: "0",
    bottom: "0",
    margin: "0",
});

output.css({zIndex: 10});
shader.css({backgroundColor: 'rgba(0,0,0,0.7)'});
