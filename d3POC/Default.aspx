<%@ Page Title="Home Page" Language="C#" MasterPageFile="~/Site.Master" AutoEventWireup="true" CodeBehind="Default.aspx.cs" Inherits="d3POC._Default" %>

<asp:Content ID="BodyContent" ContentPlaceHolderID="MainContent" runat="server">
    <script src="Scripts/d3/d3.min.js"></script>
    <style>
        .arc text, .outerarc text {
            font: 10px sans-serif;
            text-anchor: middle;
        }

        .arc path, .outerarc path {
            stroke: #fff;
            stroke-width: 3;
        }
    </style>
    <script>
        (function () {
            d3.legend = function (g) {
                g.each(function () {
                    var g = d3.select(this),
                        items = {},
                        svg = d3.select(g.property("nearestViewportElement")),
                        legendPadding = g.attr("data-style-padding") || 5,
                        lb = g.selectAll(".legend-box").data([true]),
                        li = g.selectAll(".legend-items").data([true])

                    lb.enter().append("rect").classed("legend-box", true)
                    li.enter().append("g").classed("legend-items", true)

                    svg.selectAll("[data-legend]").each(function () {
                        var self = d3.select(this)
                        items[self.attr("data-legend")] = {
                            pos: self.attr("data-legend-pos") || this.getBBox().y,
                            color: self.attr("data-legend-color") != undefined ? self.attr("data-legend-color") : self.style("fill") != 'none' ? self.style("fill") : self.style("stroke")
                        }
                    })

                    items = d3.entries(items).sort(function (a, b) { return a.value.pos - b.value.pos })


                    li.selectAll("text")
                        .data(items, function (d) { return d.key })
                        .call(function (d) { d.enter().append("text") })
                        .call(function (d) { d.exit().remove() })
                        .attr("y", function (d, i) { return i + "em" })
                        .attr("x", "1em")
                        .text(function (d) {; return d.key })

                    li.selectAll("circle")
                        .data(items, function (d) { return d.key })
                        .call(function (d) { d.enter().append("circle") })
                        .call(function (d) { d.exit().remove() })
                        .attr("cy", function (d, i) { return i - 0.25 + "em" })
                        .attr("cx", 0)
                        .attr("r", "0.4em")
                        .style("fill", function (d) { console.log(d.value.color); return d.value.color })

                    // Reposition and resize the box
                    var lbbox = li[0][0].getBBox()
                    lb.attr("x", (lbbox.x - legendPadding))
                        .attr("y", (lbbox.y - legendPadding))
                        .attr("height", (lbbox.height + 2 * legendPadding))
                        .attr("width", (lbbox.width + 2 * legendPadding))
                })
                return g
            }
        })();
        var width = 960,
            height = 500,
            radius = Math.min(width, height) / 2,
			r1 = radius * 0.9,
			r2 = radius * 0.5,
			r3 = radius * 0.7,
			r4 = radius * 0.4;

        var color = d3.scale.ordinal()
            .domain(["ToDo","In Progress", "Done"])
            .range(["#993300", "#ccff99", "#009933"]);

        var outerarc = d3.svg.arc()
            .outerRadius(r1)
            .innerRadius(r2);

        var innerarc = d3.svg.arc()
            .outerRadius(r3)
            .innerRadius(r4);

        var innerpie = d3.layout.pie()
            .sort(null)
            .value(function (d) { return d.size; });//if the json structure changes then you need to give proper properties for the size of the arc.

        var outerpie = d3.layout.pie()
            .sort(null)
            .value(function (d) { return d.size; });

        var svg = d3.select("body").append("svg")
            .attr("width", width)
            .attr("height", height)
          .append("g")
            .attr("transform", "translate(" + width / 2 + "," + height / 2 + ")");

        d3.json("Scripts/d3/flare.json", function (error, data) {
            if (error) throw error;

            for (var i = 0; i < data.Epics.length; i++) {
                if (data.Epics[i].status.length == 0) {
                    //deduce and substitute the status from the child epics
                    var todoCount = 0;
                    var inProcCount = 0;
                    var doneCount = 0;
                    for (var j = 0; j < data.Epics[i].children.length; j++) {
                        //All Todo the Todo
                        //any one in progress then inprogess
                        //All done then done
                        if (data.Epics[i].children[j].status.toLowerCase() == "todo") todoCount++;
                        if (data.Epics[i].children[j].status.toLowerCase() == "in progress") inProcCount++;
                        if (data.Epics[i].children[j].status.toLowerCase() == "done") doneCount++;
                    }
                    if (data.Epics[i].children.length == todoCount) data.Epics[i].status = "Todo";
                    else if (data.Epics[i].children.length == doneCount) data.Epics[i].status = "Done";
                    else data.Epics[i].status = "In Progress";
                }
                if (data.Epics[i].size.length == 0) {
                    //deduce and substitute the size from the child epics
                    var size = 0;
                    for (var j = 0; j < data.Epics[i].children.length; j++) {
                        size += data.Epics[i].children[j].size;
                    }
                    data.Epics[i].size = size;
                }
                
            }
            //outer donut.
            var epicData = data.Epics;
            var outergrroup = svg.selectAll(".outerarc")
                .data(outerpie(epicData))
              .enter().append("g")
                .attr("class", "outerarc");
            outergrroup.append("path")
                .attr("d", outerarc)
                .attr("data-legend", function (d) {  return d.data.status })
                .style("fill", function (d) { return color(d.data.status); });

            //Inner donut.
            var pbidata = data.Epics[0].children;
            var innergroup = svg.selectAll(".arc")
                .data(innerpie(pbidata))
              .enter().append("g")
                .attr("class", "arc");

            innergroup.append("path")
                .attr("d", innerarc)
                .attr("data-legend", function (d) {  return d.data.status })
                .style("fill", function (d) { return color(d.data.status); });//value to be passed to get the mapped/dynamic color .

            innergroup.append("text")
                .attr("transform", function (d) { return "translate(" + innerarc.centroid(d) + ")"; })
                .attr("dy", ".35em")                
                .text(function (d) { return d.data.name + "(" + d.data.status + ")"; });//text for the arc.

            var legend = svg.append("g")
                    .attr("class", "legend")
                    .attr("transform", "translate(250,0)")
                    .style("font-size", "12px")
                    .call(d3.legend);
            d3.select(".legend rect").style("fill", "transparent")
        });        

    </script>
</asp:Content>
