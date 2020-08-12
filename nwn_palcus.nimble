# Package
version       = "0.1.0"
author        = "Hendrik Albers"
description   = "read and convert nwn module *palcus and other info to sqlite"
license       = "MIT"
srcDir        = "src"
bin           = @["nwn_palcus"]

# Dependencies
requires "nim >= 1.2.6"
requires "neverwinter >= 1.2.10"

task getsqlite3, "Download amalgamated sqlite3.c source from https://www.sqlite.org":
  const
    zip = "sqlite-amalgamation-3320300.zip"
    url = "https://www.sqlite.org/2020/" & zip
  if not fileExists zip:
    echo "Downloading " & url & " to " & zip
    if findExe("wget") != "":
      exec "wget " & url & " -O " & zip
    elif findExe("curl") != "":
      exec "curl " & url & " --output " & zip
    else:
      echo "wget and curl not found"
      quit(QuitFailure)
  echo "Extracting sqlite3.c from " & zip
  exec "unzip -j " & zip & " " & zip[0 .. ^5] & "/sqlite3.c"

task sqlite3a, "Create static library archive sqlite3.a with musl":
  if not fileExists "sqlite3.c":
    echo "sqlite3.c not found. Running task getsqlite3 first."
    getsqlite3Task()
  echo "Compiling sqlite3.a with musl"
  exec "musl-gcc -O2 -c -o sqlite3.o sqlite3.c"
  exec "ar rcs sqlite3.a sqlite3.o"

task musl, "Build static binary with musl":
  if not fileExists "sqlite3.a":
    echo "sqlite3.a not found. Running task sqlite3a first."
    sqlite3aTask()
  echo "Building static binary with musl"
  let file = bin[0]
  const muslOpts = ["--gcc.exe:musl-gcc", "--gcc.linkerexe:musl-gcc"].join(" ")
  exec "nimble build -d:release " & muslOpts & " --passL:-static --dynlibOverrideAll --passL:sqlite3.a " & file
  if findExe("strip") != "":
    echo "Stripping symbols"
    exec "strip -s " & file
  if findExe("upx") != "":
    echo "Compressing with upx"
    exec "upx --best " & file

task sqlite3dll, "Create sqlite3.dll with mingw":
  if not fileExists "sqlite3.c":
    echo "sqlite3.c not found. Running task getsqlite3 first."
    getsqlite3Task()
  echo "Compiling sqlite3.dll with mingw"
  exec "x86_64-w64-mingw32-gcc -O2 -shared sqlite3.c -o sqlite3.dll"

task win, "Cross compile windows binary with mingw":
  if not fileExists "sqlite3.dll":
    echo "sqlite3.dll not found. Running task sqlite3dll first."
    sqlite3dllTask()
  echo "Building windows binary with mingw"
  let file = bin[0]
  exec "nimble build -d:mingw -d:release --passL:-static --dynlibOverrideAll --passL:sqlite3.dll " & file
