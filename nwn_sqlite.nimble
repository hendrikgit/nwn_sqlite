# Package
version       = "0.12.1"
author        = "Hendrik Albers"
description   = "Reads data from a Neverwinter Nights module and writes it to a sqlite database"
license       = "MIT"
srcDir        = "src"
bin           = @["nwn_sqlite"]

# Dependencies
requires "nim >= 1.6.10"
requires "neverwinter == 1.5.8"

task getsqlite3, "Download amalgamated sqlite3.c source from https://www.sqlite.org":
  const
    zip = "sqlite-amalgamation-3410000.zip"
    url = "https://sqlite.org/2023/" & zip
  if not fileExists zip:
    echo "Downloading " & url & " to " & zip
    if findExe("wget") != "":
      exec "wget --no-verbose " & url & " -O " & zip
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
  echo "Creating sqlite3.a with musl and ar"
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

task winsqlite3a, "Create static winsqlite3.a with mingw":
  if not fileExists "sqlite3.c":
    echo "sqlite3.c not found. Running task getsqlite3 first."
    getsqlite3Task()
  echo "Creating winsqlite3.a with mingw and ar"
  exec "x86_64-w64-mingw32-gcc -O2 -c -o winsqlite3.o sqlite3.c"
  exec "ar rcs winsqlite3.a winsqlite3.o"

task win, "Cross compile windows binary with mingw":
  if not fileExists "winsqlite3.a":
    echo "winsqlite3.a not found. Running task winsqlite3a first."
    winsqlite3aTask()
  echo "Building windows binary with mingw"
  let file = bin[0]
  exec "nimble build -d:mingw -d:release --passL:-static --dynlibOverrideAll --passL:winsqlite3.a " & file

task macsqlite3a, "Create static library archive macsqlite3.a":
  if not fileExists "sqlite3.c":
    echo "sqlite3.c not found. Running task getsqlite3 first."
    getsqlite3Task()
  echo "Creating macsqlite3.a"
  exec "clang -O2 -c -o macsqlite3.o sqlite3.c"
  exec "ar rcs macsqlite3.a macsqlite3.o"

task macos, "Build macOS binary with sqlite3 statically linked":
  if not fileExists "macsqlite3.a":
    echo "macsqlite3.a not found. Running task macsqlite3a first."
    macsqlite3aTask()
  echo "Building macOS binary"
  let file = bin[0]
  exec "nimble build -d:release --dynlibOverride:sqlite3 --passL:macsqlite3.a " & file

task clean, "Remove downloaded and compiled SQLite files":
  var removeFiles = @[
    "sqlite3.c",
    "sqlite3.o",
    "sqlite3.a",
    "winsqlite3.a",
    "macsqlite3.o",
    "macsqlite3.a",
  ]
  for f in bin:
    removeFiles &= f
    removeFiles &= f & ".exe"
  for f in removeFiles:
    if fileExists f:
      try:
        rmFile(f)
        echo "Removed file: " & f
      except OSError:
       echo "Error: Could not remove file: " & f
