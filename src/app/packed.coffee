
angular.module('ham.Transform', ->
  xyValue = (newValue) ->
    return @private  if newValue is `undefined`
    newObj = undefined
    if typeof newValue is "number"
      newObj =
        x: newValue
        y: newValue
    else
      newObj = newValue
    @private = newObj
    @private
  xyString = ->
    @private.x + "," + @private.y
  xyIncrement = (transform) ->
    this_transform = transform
    (newValue) ->
      if typeof newValue is "number"
        this
          x: this().x + newValue
          y: this().y + newValue

      else
        this().x += newValue.x  if newValue.x or newValue.x
        this().y += newValue.y  if newValue.y or newValue.y
      this_transform
  rotation = (degree) ->
    return rotation.value or 0  if degree is `undefined`
    rotation.value = Math.round((degree % 360 + ((if degree >= 0 then 0 else 360))))  unless degree is rotation.value
    rotation.value
  rotationIncrement = (transform) ->
    this_transform = transform
    (value) ->
      this this() + value
      this_transform
  order = [
    "translate"
    "scale"
    "rotate"
  ]
  inner =
    translate:
      private:
        x: 0
        y: 0

      value: xyValue
      string: xyString
      increment: xyIncrement

    scale:
      private:
        x: 1
        y: 1

      value: xyValue
      string: xyString
      increment: xyIncrement

    rotate:
      value: rotation
      string: ->
        rotation()

      increment: rotationIncrement

  
  # add getters and setters for transform types in the order array
  order.forEach ((v) ->
    this[v] = (d) ->
      isFunction = (typeof inner[v].value is "function")
      return (if isFunction then inner[v].value() else inner[v].value)  if d is `undefined`
      new_value = (if (typeof d is "function") then d(element) else d)
      (if isFunction then inner[v].value(new_value) else inner[v].value = new_value)
      this

    this[v].incr = new inner[v].increment(this)
    return
  ), this
  @render = ->
    @attr "transform", @toString()

  @animate = (options) ->
    options = options or {}
    duration = options.duration or 500
    ease = options.ease or ""
    opacity = options.opacity or "1"
    @transition().duration(duration).ease(d3.ease(ease)).attr("transform", @toString()).attr "opacity", opacity

  @toString = ->
    order.map((v) ->
      v + "(" + inner[v].string() + ")"
    , this).join " "

  return
)

angular.module('ham.packed', (data) ->
    View = ->
      th = $("#ham_title").height()
      v =
        width: window.innerWidth
        height: window.innerHeight - th

      v.diameter = (if v.width > v.height then v.height else v.width)
      v
    scale_colors =
      good: "#37D7B2"
      med: "#EBC355"
      bad: "#F86C5F"

    color = d3.scale.quantile().domain([
      0
      1
    ]).range([
      scale_colors["bad"]
      scale_colors["med"]
      scale_colors["good"]
    ])
    fonts = d3.scale.quantile().domain([
      0
      3
    ]).range([
      10
      18
      12
      3
    ])
    viewport = new View()
    margin = 20
    diameter = viewport.diameter
    pack = d3.layout.pack().padding(2).size([
      diameter - margin
      diameter - margin
    ]).value((d) ->
      1 / d.score
    ).children(children = (d) ->
      d.elements
    )
    svg = d3.select("#canvas").attr("width", viewport.width).attr("height", viewport.height).append("g")
  
    # add d3 tranform sugar
    svg.call Transform
    focus = root
    nodes = pack.nodes(root)
    view = undefined
    circle = svg.selectAll("circle").data(nodes).enter().append("circle").attr("class", (d) ->
      (if d.parent then (if d.children then "node" else "node node--leaf") else "node node--root")
    ).style("fill", (d) ->
      score = ->
        d.elements.map((d) ->
          d.score
        ).reduce((p, c, i) ->
          p + c
        , 0) / d.elements.length

      (if d.score isnt `undefined` then color(d.score) else color(score()))
    ).attr(
      opacity: (d, i) ->
        (d.depth + 3) / 10

      r: (d) ->
        d.r

      cx: (d) ->
        d.x

      cy: (d) ->
        d.y
    ).on("click", (d) ->
      if focus isnt d
        zoom(d)
        d3.event.stopPropagation()
      return
    )
  
    # .style('font-size',function (d,i) {        
    #   return fonts(d.depth)
    # })
    text = svg.selectAll("text").data(nodes).enter().append("text").attr(
      class: "label"
      x: (d) ->
        d.x

      y: (d, i) ->
        return d.y
        l = 5
        (if i % 2 is 0 then d.y + l else d.y - l)
    ).text((d) ->
      d.label
    ).style("font-size", (d) ->
      Math.min(2 * d.r, (2 * d.r - 2) / @getComputedTextLength() * 16) + "px"
    ).attr("dy", ".35em").style("fill-opacity", (d) ->
      (if d.parent is root then 1 else 0)
    ).style("display", (d) ->
      (if d.parent is root then null else "none")
    )
  
    # var node = svg.selectAll("circle,text");
    d3.select("body").style("background", color(-1)).on "click", ->
      zoom root
      return

    $(window).on "orientationchange", (event) ->
      viewport = new View()
      diameter = viewport.diameter
      svg.attr("width", viewport.width).attr("height", viewport.height).translate diameter / 2
      zoom root
      return
)




