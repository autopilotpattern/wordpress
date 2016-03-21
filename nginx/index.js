// provide empty data when upstream services are not available
var dummy = [{
    company: "Data not available",
    rep: "Data not available",
    client: "N/A",
    territory: "N/A",
    phone: "N/A",
    location: "N/A",
    source: "N/A"
}];


var trFromRow = function(rowData, keys) {
    var row = document.createElement('tr');
    for (var k = 0; k < keys.length; k++) {
        var td = document.createElement('td');
        td.textContent = rowData[keys[k]];
        row.appendChild(td);
    }
    return row;
}

var fillCustomerTable = function(rows) {
    var body = document.getElementById("customerTable");
    while (body.lastChild) {
        body.removeChild(body.lastChild);
    }
    for (var i = 0; i < rows.length; i++){
        var tr = trFromRow(rows[i],
                           ["company", "location", "rep", "source"]);
        body.appendChild(tr);
    }
}

var fillSalesTable = function(rows) {
    var body = document.getElementById("salesRepTable");
    while (body.lastChild) {
        body.removeChild(body.lastChild);
    }
    for (var i = 0; i < rows.length; i++){
        var tr = trFromRow(rows[i],
                            ["rep", "client", "phone",
                             "territory", "source"]);
        body.appendChild(tr);
    }
}


var fillTable = function(fillTableFn, url) {
    var req = new XMLHttpRequest();
    req.onreadystatechange = function() {
        if (req.readyState == XMLHttpRequest.DONE) {
            var rows = dummy;
            if (req.status === 200) {
                rows = JSON.parse(req.responseText);
            }
            fillTableFn(rows);
        }
    }
    req.open('GET', url, true);
    req.send(null);
}

window.onload = function() {
    fillTable(fillCustomerTable, "customers/");
    fillTable(fillSalesTable, "sales/");
};
