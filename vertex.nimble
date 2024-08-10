# Package

version       = "0.1.0"
author        = "krishna"
description   = "hot corners and hot edges for x11"
license       = "GPL-3.0-or-later"
srcDir        = "src"
bin           = @["vertex"]


# Dependencies

requires "nim >= 2.0.4", "x11 >= 1.2", "parsetoml >= 0.7.1"
