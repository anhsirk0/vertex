import
  os,
  osproc,
  parsetoml,
  strformat,
  x11/xlib,
  x11/x

const checkInterval = 200
const bounce = 20

let configFile = getEnv("HOME") & "/.config/vertex/config.toml"

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


proc moveCursor(posX, posY: cint) =
  discard XWarpPointer(display, rootWindow, rootWindow, 0, 0, 0, 0, posX, posY)
  discard XFlush(display)

proc init() =
  if not fileExists(configFile):
    quit fmt"Config file [{configFile}] does not exists"

  let config = parsetoml.parseFile(configFile)
  echo config

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
      try:
        let cmd = config["corners"]["top_left"].getStr()
        moveCursor(bounce, bounce)
        discard execCmd cmd & " &"
      except:
        discard "No top left"

    if rootX >= width - 1 and rootY == 0:
      try:
        let cmd = config["corners"]["top_right"].getStr()
        moveCursor(-bounce, bounce)
        discard execCmd cmd & " &"
      except:
        discard "No top right"

    if rootX == 0 and rootY >= height - 1:
      try:
        let cmd = config["corners"]["bottom_left"].getStr()
        moveCursor(bounce, -bounce)
        discard execCmd cmd & " &"
      except:
        discard "No bottom left"

    if rootX >= width - 1 and rootY >= height - 1:
      try:
        let cmd = config["corners"]["bottom_right"].getStr()
        moveCursor(-bounce, -bounce)
        discard execCmd cmd & " &"
      except:
        discard "No bottom right"


when isMainModule:
  init()
  discard XCloseDisplay(display)

