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
                .style("fill", function (d) { return color(d.data.status); });

            //Inner donut.
            var pbidata = data.Epics[0].children;
            var innergroup = svg.selectAll(".arc")
                .data(innerpie(pbidata))
              .enter().append("g")
                .attr("class", "arc");
            innergroup.append("path")
                .attr("d", innerarc)
                .style("fill", function (d) { return color(d.data.status); });//value to be passed to get the mapped/dynamic color .
            innergroup.append("text")
                .attr("transform", function (d) { return "translate(" + innerarc.centroid(d) + ")"; })
                .attr("dy", ".35em")
                .text(function (d) { return d.data.name + "("+d.data.status+")"; });//text for the arc.
        });        

    </script>
</asp:Content>
