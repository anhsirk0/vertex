import
  std/[os, osproc, strformat],
  parsetoml,
  xcb/xcb

type
  Prop = enum
    Corner = "corner", Edge = "edge"

  Location = enum
    TopLeft = "top_left",
    TopRight = "top_right",
    BottomLeft = "bottom_left",
    BottomRight = "bottom_right",
    LeftTop = "left_top",
    RightTop = "right_top",
    LeftBottom = "left_bottom",
    RightBottom = "right_bottom",

  CornerLocation = TopLeft..BottomRight

func getCommands[T: enum](toml: TomlValueRef, t: typedesc[T]): array[T, string] =
  for v in T:
    result[v] = toml{$v}.getStr

proc moveCursor(conn: ptr XcbConnection, desX, desY: int16) =
  discard conn.warpPointer(0.XcbWindow, 0.XcbWindow, 0, 0, 0, 0, desX, desY)
  discard conn.flush

proc actionCorner(conn: ptr XcbConnection, cmd: string, timeout: int, desX, desY: int16) =
  if cmd != "":
    discard execCmd cmd & " &"
    if desX != 0 or desY != 0:
      conn.moveCursor(desX, desY)
    sleep(timeout)

proc actionEdge(conn: ptr XcbConnection, cmd: string, timeout: int) =
  if cmd != "":
    discard execCmd cmd & " &"
    sleep(timeout)

proc init() =
  let configFile = getConfigDir() / "vertex/config.toml"
  if not fileExists(configFile):
    quit fmt"Config file [{configFile}] does not exists"

  let
    config = parsetoml.parseFile(configFile)

    # config vars
    checkInterval = config{"check_interval"}.getInt(200)
    bounce = config{"bounce"}.getInt(10).int16
    edgeOffset = config{"edge_offset"}.getInt(10)
    cornerReactivation = config{"corner", "reactivation"}.getInt(1000)
    edgeReactivation = config{"edge", "reactivation"}.getInt(500)
    cornerCommands = config{"corner"}.getCommands(CornerLocation)
    edgeCommands = config{"edge"}.getCommands(Location)

    conn = xcbConnect(nil, nil)
    screen = conn.getSetup.rootsIterator.data[0].addr
    rootWindow = screen.root
    width = screen.widthInPixels.int16
    height = screen.heightInPixels.int16

  while true:
    sleep checkInterval

    let
      pointerQuery = conn.reply(conn.queryPointer(rootWindow), nil)
      rootX = pointerQuery.rootX
      rootY = pointerQuery.rootY

    if pointerQuery.sameScreen == 0: continue

    # Corners
    if rootX == 0 and rootY == 0:
      actionCorner(conn, cornerCommands[TopLeft], cornerReactivation, bounce, bounce)

    elif rootX >= width - 1 and rootY == 0:
      actionCorner(conn, cornerCommands[TopRight], cornerReactivation, -bounce, bounce)

    elif rootX == 0 and rootY >= height - 1:
      actionCorner(conn, cornerCommands[BottomLeft], cornerReactivation, bounce, -bounce)

    elif rootX >= width - 1 and rootY >= height - 1:
      actionCorner(conn, cornerCommands[BottomRight], cornerReactivation, -bounce, -bounce)

    # Edges
    elif rootX > edgeOffset and rootX < width div 2 and rootY == 0:
      actionEdge(conn, edgeCommands[TopLeft], edgeReactivation)

    elif rootX < width - edgeOffset and rootX > width div 2 and rootY == 0:
      actionEdge(conn, edgeCommands[TopRight], edgeReactivation)

    elif rootX > edgeOffset and rootX < width div 2 and rootY >= height - 1:
      actionEdge(conn, edgeCommands[BottomLeft], edgeReactivation)

    elif rootX < width - edge_offset and rootX > width div 2 and rootY >= height - 1:
      actionEdge(conn, edgeCommands[BottomRight], edgeReactivation)

    elif rootX == 0 and rootY > edgeOffset and rootY < height div 2:
      actionEdge(conn, edgeCommands[LeftTop], edgeReactivation)

    elif rootX == 0 and rootY < height - edgeOffset and rootY > height div 2:
      actionEdge(conn, edgeCommands[LeftBottom], edgeReactivation)

    elif rootX == width - 1 and rootY > edgeOffset and rootY < height div 2:
      actionEdge(conn, edgeCommands[RightTop], edgeReactivation)

    elif rootX == width - 1 and rootY < height - edge_offset and rootY > height div 2:
      actionEdge(conn, edgeCommands[RightBottom], edgeReactivation)

when isMainModule:
  init()
