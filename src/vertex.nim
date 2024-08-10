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


const checkInterval = 200
const bounce = 20

let configFile = getEnv("HOME") & "/.config/vertex/config.toml"
if not fileExists(configFile):
  quit fmt"Config file [{configFile}] does not exists"

let config = parsetoml.parseFile(configFile)
echo config

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
  discard XWarpPointer(display, rootWindow, rootWindow, 0, 0, 0, 0, desX, desY)
  discard XFlush(display)


proc action(prop: Prop, loc: Location, desX, desY: cint) =
  try:
    let cmd = config[$prop][$loc].getStr()
    moveCursor(desX, desY)
    discard execCmd cmd & " &"
  except:
    discard


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

    if rootX == 0 and rootY == 0:
      action(Prop.Corner, Location.TopLeft, bounce, bounce)

    if rootX >= width - 1 and rootY == 0:
      action(Prop.Corner, Location.TopRight, -bounce, bounce)

    if rootX == 0 and rootY >= height - 1:
      action(Prop.Corner, Location.BottomLeft, bounce, -bounce)

    if rootX >= width - 1 and rootY >= height - 1:
      action(Prop.Corner, Location.BottomRight, -bounce, -bounce)


when isMainModule:
  init()
  discard XCloseDisplay(display)

