# Align tool
var script_class = "tool"


var select_tool = null


func log_msg(msg):
  print("[Align Tool] ", msg)


func icon_name(name: String) -> String:
  return Global.Root + "icons/" + name + ".png"


var options = [
  "top_edges",
  "horizontal_center",
  "bottom_edges",
  "spacer",
  "left_edges",
  "vertical_center",
  "right_edges",
  "spacer",
  "distribute_vertical",
  "distribute_horizontal"
]


func add_button(name: String) -> Button:
  var button = Button.new()
  button.icon = load(Global.Root + "icons/" + name + ".png")
  button.connect("pressed", self, "on_" + name)
  button.hint_tooltip = name.capitalize()
  print("Added ", "on_" + name)
  return button


func load_images(tool_panel, names):
  for name in names:
    if name == "spacer":
      continue
    var b = tool_panel.CreateButton("blah", Global.Root + "icons/" + name + ".png")
    tool_panel.Align.remove_child(b)


var button_box = null
var button_off = true
var tool_panel = null
var separator = null
var label = null


func update(delta):
  # Add the UI when objects are selected, and remove it when they aren't.
  if len(get_selected_objects()) > 0 and button_off:
    tool_panel.Align.add_child(separator)
    tool_panel.Align.move_child(separator, 13)

    tool_panel.Align.add_child(button_box)
    tool_panel.Align.move_child(button_box, 13)

    tool_panel.Align.add_child(label)
    tool_panel.Align.move_child(label, 13)

    button_off = false
  elif len(get_selected_objects()) == 0 and not button_off:
    tool_panel.Align.remove_child(separator)
    tool_panel.Align.remove_child(button_box)
    tool_panel.Align.remove_child(label)
    button_off = true


func start():
  select_tool = Global.Editor.Tools["SelectTool"]

  # var tool_panel = Global.Editor.Toolset.GetToolPanel("SelectTool")
  var icon = Global.Root + "icons/align_icon.png"
  tool_panel = Global.Editor.Toolset.GetToolPanel("SelectTool")

  button_box = HBoxContainer.new()
  load_images(tool_panel, options)
  for name in options:
    if name == "spacer":
      print("Adding spacer")
      button_box.add_spacer()
      button_box.add_spacer()
      button_box.add_spacer()
      button_box.add_spacer()
    else:
      var button = add_button(name)
      button_box.add_child(button)
  tool_panel.CreateSeparator()
  separator = tool_panel.Align.get_children()[len(tool_panel.Align.get_children()) - 1]
  tool_panel.Align.remove_child(separator)

  tool_panel.CreateLabel("Align Objects")
  label = tool_panel.Align.get_children()[len(tool_panel.Align.get_children()) - 1]
  tool_panel.Align.remove_child(label)

  log_msg("Mod loaded.")


func get_selected_objects():
  # Returns all currently selected objects.
  var objects = []
  # Selectables will crash if the user has shift-clicked and selected the same
  # object twice. Use RawSelectables instead and skip duplicates.
  for raw in select_tool.RawSelectables:
    if raw.Type != 4 or raw.Thing in objects:
      continue
    objects.append(raw.Thing)
  return objects


func move(value, is_x: bool):
  for object in get_selected_objects():
    if is_x:
      object.global_position.x = value
    else:
      object.global_position.y = value


func get_points(object):
  var image = object.Sprite.texture.get_data()
  image.lock()
  var points = []
  var pos = null
  for y in range(image.get_height()):
    for x in range(image.get_width()):
      if image.get_pixel(x, y).a > 0:
        # Adjust the coordinates since the origin for the image is the corner
        # while the origin for to_global() is the center.
        var local = Vector2(
          x - image.get_width() / 2,
          y - image.get_height() / 2)
        points.append(object.to_global(local))
  image.unlock()
  return points


func on_top_edges():
  var objects = get_selected_objects()
  var min_y = Global.World.WoxelDimensions.y
  var tops = []
  for object in objects:
    var points = get_points(object)
    var p = points[0]
    for point in points:
      if point.y < p.y:
        p = point
    tops.append(p.y)
    min_y = min(min_y, p.y)

  for i in range(len(objects)):
    var delta = tops[i] - min_y
    objects[i].global_position.y -= delta
  select_tool.EnableTransformBox(true)



func on_vertical_center():
  var selected = get_selected_objects()
  if len(selected) == 0:
    return

  var sum = 0
  for object in selected:
    sum += object.global_position.x

  var mid_x = sum / len(selected)

  move(mid_x, true)
  select_tool.EnableTransformBox(true)


func on_bottom_edges():
  var objects = get_selected_objects()
  var max_y = 0
  var bots = []
  for object in objects:
    var points = get_points(object)
    var p = points[0]
    for point in points:
      if point.y > p.y:
        p = point
    bots.append(p.y)
    max_y = max(max_y, p.y)

  for i in range(len(objects)):
    var delta = max_y - bots[i]
    objects[i].global_position.y += delta
  select_tool.EnableTransformBox(true)


func on_left_edges():
  var objects = get_selected_objects()
  var min_x = Global.World.WoxelDimensions.x
  var lefts = []
  for object in objects:
    var points = get_points(object)
    var p = points[0]
    for point in points:
      if point.x < p.x:
        p = point
    lefts.append(p.x)
    min_x = min(min_x, p.x)

  for i in range(len(objects)):
    var delta = lefts[i] - min_x
    objects[i].global_position.x -= delta
  select_tool.EnableTransformBox(true)


func on_horizontal_center():
  var selected = get_selected_objects()
  if len(selected) == 0:
    return

  var sum = 0
  for object in selected:
    sum += object.global_position.y

  var mid_y = sum / len(selected)

  move(mid_y, false)
  select_tool.EnableTransformBox(true)


func on_right_edges():
  var objects = get_selected_objects()
  var max_x = 0
  var rights = []
  for object in objects:
    var points = get_points(object)
    var p = points[0]
    for point in points:
      if point.x > p.x:
        p = point
    rights.append(p.x)
    max_x = max(max_x, p.x)

  for i in range(len(objects)):
    var delta = max_x - rights[i]
    objects[i].global_position.x += delta
  select_tool.EnableTransformBox(true)


class PositionSorter:
  static func compare_y(a, b):
    return a.global_position.y < b.global_position.y

  static func compare_x(a, b):
    return a.global_position.x < b.global_position.x


func on_distribute_vertical():
  var objects = get_selected_objects()
  if len(objects) < 3:
    return

  objects.sort_custom(PositionSorter, "compare_y")
  var min_y = objects.front().global_position.y
  var max_y = objects.back().global_position.y
  var spacing = (max_y - min_y) / (len(objects) - 1)

  for i in range(1, len(objects) - 1):
    objects[i].global_position.y = min_y + i * spacing
  select_tool.EnableTransformBox(true)


func on_distribute_horizontal():
  var objects = get_selected_objects()
  if len(objects) < 3:
    return

  objects.sort_custom(PositionSorter, "compare_x")
  var min_x = objects.front().global_position.x
  var max_x = objects.back().global_position.x
  var spacing = (max_x - min_x) / (len(objects) - 1)

  for i in range(1, len(objects) - 1):
    objects[i].global_position.x = min_x + i * spacing
  select_tool.EnableTransformBox(true)
