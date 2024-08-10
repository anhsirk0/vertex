import
  os,
  osproc,
  parsetoml,
  strformat,
  x11/xlib,
  x11/x


type
  Prop {.pure.} = enum
    Corner = "corner", Edge = "edge"
  Location {.pure.} = enum
    TopLeft = "top_left",
    TopRight = "top_right",
    BottomLeft = "bottom_left",
    BottomRight = "bottom_right",
    LeftTop = "left_top",
    RightTop = "right_top",
    LeftBottom = "left_bottom",
    RightBottom = "right_bottom",


let configFile = getEnv("HOME") & "/.config/vertex/config.toml"
if not fileExists(configFile):
  quit fmt"Config file [{configFile}] does not exists"

let config = parsetoml.parseFile(configFile)
echo config

# config vars
let  
  checkInterval = config{"check_interval"}.getInt(200)
  bounce = config{"bounce"}.getInt(200)
  edgeOffset = config{"edge_offset"}.getInt(200)
  cornerReactivation = config{"corner", "reactivation"}.getInt(1000)
  edgeReactivation = config{"edge", "reactivation"}.getInt(500)  

var
  display: PDisplay
  cWindow: Window
  rWindow: Window
  rootWindow: Window
  wX: cint = 0
  wY: cint = 0
  rootX: cint = 0
  rootY: cint = 0
  mask: cuint = 0


proc moveCursor(desX, desY: cint) =
  discard XWarpPointer(display, cWindow, rootWindow, 0, 0, 0, 0, desX, desY)
  discard XFlush(display)
  # discard XSync(display, true.XBool)


proc action(prop: Prop, loc: Location, desX: int = 0, desY: int = 0) =
  let cmd = config{$prop, $loc}.getStr("")
  if cmd != "":
    discard execCmd cmd & " &"
    if desX != 0 and desY != 0:
      moveCursor(desX.cint, desY.cint)
    sleep(if prop == Prop.Corner: cornerReactivation else: edgeReactivation)


proc init() =
  display = XOpenDisplay(nil)
  if display == nil:
    quit "Failed to open display"

  let
    screen = XDefaultScreen(display)
    rootWindow = XRootWindow(display, screen)
    width = DisplayWidth(display, screen)
    height = DisplayHeight(display, screen)

  while true:
    sleep checkInterval
    let p = XQueryPointer(display, rootWindow, cWindow.addr, rWindow.addr,
                      rootX.addr, rootY.addr, wX.addr, wY.addr, mask.addr)

    if p != 1:
      quit "Could not read cursor position"

    # Corners
    if rootX == 0 and rootY == 0:
      action(Prop.Corner, Location.TopLeft, bounce, bounce)

    if rootX >= width - 1 and rootY == 0:
      action(Prop.Corner, Location.TopRight, -bounce, bounce)

    if rootX == 0 and rootY >= height - 1:
      action(Prop.Corner, Location.BottomLeft, bounce, -bounce)

    if rootX >= width - 1 and rootY >= height - 1:
      action(Prop.Corner, Location.BottomRight, -bounce, -bounce)

    # Edges
    if rootX > edgeOffset and rootX < width div 2 and rootY == 0:
      action(Prop.Edge, Location.TopLeft)

    if rootX < width - edgeOffset and rootX > width div 2 and rootY == 0:
      action(Prop.Edge, Location.TopRight)

    if rootX > edgeOffset and rootX < width div 2 and rootY >= height - 1:
      action(Prop.Edge, Location.BottomLeft)

    if rootX < width - edge_offset and rootX > width div 2 and rootY >= height - 1:
      action(Prop.Edge, Location.BottomRight)

    if rootX == 0 and rootY > edgeOffset and rootY < height div 2:
      action(Prop.Edge, Location.LeftTop)

    if rootX == 0 and rootY < height - edgeOffset and rootY > height div 2:
      action(Prop.Edge, Location.LeftBottom)

    if rootX == width - 1 and rootY > edgeOffset and rootY < height div 2:
      action(Prop.Edge, Location.RightTop)

    if rootX == width - 1 and rootY < height - edge_offset and rootY > height div 2:
      action(Prop.Edge, Location.RightBottom)


when isMainModule:
  init()
  discard XCloseDisplay(display)

