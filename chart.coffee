class Chart
  cols: 4
  rows: 4
  col_attr: 'type'
  row_attr: 'category'
  foci_points: () =>
    points = []
    d3.range(@cols).forEach((col) =>
      rows = []
      d3.range(@rows).forEach((row) =>
        rows.push {
          x: col * 250,
          y: row * 200
        }
      )
      points.push(rows)
    )
    points
  width: 1400
  height: 720
  fill: d3.scale.category20()
  data: null
  nodes: null
  cols_wrap: null
  rows_wrap: null

  color_index: (data) ->
    @types = _.uniq _.flatten(_.pluck(@data, "type")) if !@types
    _.indexOf @types, data.type[0]

  draw_labels: (col_titles, row_titles) ->
    foci = @foci_points()

    @vis.selectAll("text").remove()

    @cols_wrap = @vis
    d3.range(@cols).forEach (index) =>
      @cols_wrap.append("text")
                .attr("x", (foci[index][0].x / 2.5) + 400)
                .attr("y", (foci[index][0].y / 2.0) + 20)
                .text(col_titles[index])

    @rows_wrap = @vis
    d3.range(@rows).forEach (index) =>
      @rows_wrap.append("text")
                .attr("x", foci[0][index].x + (foci[0][index].x / 2.0) + 20)
                .attr("y", (foci[0][index].y / 2.5) + 200)
                .text(row_titles[index])

  prep_nodes: () =>
    col_titles = _.uniq _.flatten(_.pluck(@data, @col_attr))
    row_titles = _.uniq _.flatten(_.pluck(@data, @row_attr))
    @cols = col_titles.length
    @rows = row_titles.length

    @draw_labels(col_titles, row_titles)

    @nodes = [] if !@nodes
    count = 0
    @data.forEach (data_node) =>
      columns_indexes = (_.intersection data_node[@col_attr], col_titles).map (title) => _.indexOf col_titles, title
      rows_indexes    = (_.intersection data_node[@row_attr], row_titles).map (title) => _.indexOf row_titles, title
      columns_indexes.forEach (col_index) =>
        rows_indexes.forEach (row_index) =>
          node = null
          node = @nodes[count] if @nodes.length > count

          if !node
            node = {}
            @nodes.push(node)

          node.col   = col_index
          node.row   = row_index
          node.data  = data_node
          node.id    = count
          count += 1
    if @nodes.length > count
      @nodes.splice(count, @nodes.length - count)
    @nodes

  recolor: () =>
    @node.style("fill", (d, i) => @fill(@color_index(d.data));)
          .style("stroke", (d, i) => d3.rgb(@fill(@color_index(d.data))).darker(2);)

  redraw: () =>
    @node = @vis.selectAll("circle.node")
          .data(@nodes, (d) -> d.id;)

    @node.enter().insert("svg:circle")
          .attr("class", "node")
          .attr("cx", (d) => d.x;)
          .attr("cy", (d) => d.y;)
          .attr("r", 8)
          .style("stroke-width", 1.5)
          .call(@force.drag)
          .on("mouseover", (d) ->
            d3.select("#desc").style('display', 'block')
            attrs = ["name", "site", "model", "category", "type", "price", "description", "extra"]
            attrs.forEach (attr) =>
              val = d.data[attr]
              val = val.join(", ") if (typeof value) == "object"
              
              d3.select("#desc ##{attr}").text(val)
              if attr == "site"
                d3.select("#desc ##{attr}").attr("href", val)
          )

    @node.exit().remove()

    @recolor()

  restart: () =>
    @force.stop()
    @prep_nodes()
    @redraw()
    @force.start()

  init: ->
    @vis = d3.select("body").append("svg:svg")
        .attr("width", @width)
        .attr("height", @height)

    d3.csv "food.csv", (rows) =>
      rows.forEach (row) =>
        list_cols = ["model", "type", "category"]
        list_cols.forEach (col_name) =>
          row[col_name] = row[col_name].split(",").map((word) -> word.trim()) if row[col_name]
      @data = rows
      @prep_nodes()

      @force = d3.layout.force()
          .nodes(@nodes)
          .links([])
          .size([@width, @height])

      @redraw()

      @force.on "tick", (e) =>
        foci = @foci_points()
        k = .05 * e.alpha

        @nodes.forEach (o, i) =>
          o.y += (foci[o.col][o.row].y - o.y) * k
          o.x += (foci[o.col][o.row].x - o.x) * k

        @node.attr("cx", (d) -> d.x;)
              .attr("cy", (d) -> d.y;)

       @force.start()

window.chart = new Chart
chart.init()

