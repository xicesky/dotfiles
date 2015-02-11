
/*
    Author: Markus Dangl
    License: BSD
    !No warranties of any kind!

    TODO:
        - Find a hack to get the _SID cookie (it's HttpOnly...)

*/

// Array to put the extracted data in
var data = [];

// Those contain the actual download links
var pdfs = $(".pdf a").not(":contains('Einzelverbindungsnachweis')");

// For each of those:
pdfs.each(function(index) {
    var pdf = this;
    /* Find the title, its a p element in the span "scope" above */
    var e_title = $(pdf).parent().parent().siblings('.aufklappen,.zuklappen')[0];
    title = $(e_title).html();
    var url = pdf.href;
    if (!url.match(/showPDF/i)) return;

    // Additional fields
    var date = title.match(/(\d+)\.(\d+)\.(\d+)/);
    var fdate = '' + date[3] + '_' + date[2] + '_' + date[1] ;
    var fn = fdate + '_' + title.replace(/[^a-zA-Z0-9]/g, '_') + '.pdf';

    data.push({
        index: index,
        title: title,
        url: url,
        // Computed
        date: date,
        fdate: fdate,
        fn: fn,
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
    // console.log(d.title);
    // var dl = $('<a>', { text: d.title, href: d.url, download: d.fn});
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
    out_pre.append('curl "' + d.url + '" -H "Cookie: $COOKIE" -o "' + d.fn + '"').append('<br/>');
});
for (var i=0; i < 3; i++) out_pre.append('<br/>');

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
    shader.click(function(){ $('#output').hide(); $('#shader').hide(); });
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
