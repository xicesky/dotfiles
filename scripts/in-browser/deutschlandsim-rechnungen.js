
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
    output = $('<div>', { id: 'output' }).appendTo('#rechnungen');
}
output.html('');

data.forEach(function(d) {
    console.log(d.title);

    var fn = d.title.replace(/[^a-zA-Z0-9]/g, '_') + '.pdf';
    var dl = $('<a>', { text: d.title, href: d.url, download: fn});
    //var dl = $('<a>', { text: d.title, href: d.url });
    output.append(dl);
    output.append('<br/>');
});

// TODO: Float the div and hide the rest :)
// TODO: Generate a curl script, manual download sux

