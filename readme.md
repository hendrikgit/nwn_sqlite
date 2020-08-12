# nwn_palcus
Extracts information from a [Neverwinter Nights](https://www.beamdog.com/games/neverwinter-nights-enhanced/) module and saves it to a [sqlite3](https://www.sqlite.org/index.html) file. sqlite databases can be read and queried via nwscript beginning with version 8193.14.

This program is written in [Nim](https://nim-lang.org/) and uses the excellent [neverwinter.nim](https://github.com/niv/neverwinter.nim) library to do all the work.

![creaturepalcus.sqlite3 database view in gui](screenshots/creaturepalcus.png)

For [table schemas see below](#table-schemas).

## Download binaries
Binaries are available for download on the [releases](https://github.com/hendrikgit/nwn_palcus/releases/latest) page.

## What exactly does it do?
It reads the information from a Neverwinter module file contained in the *creaturepalcus.itp*. Some additional information about factions (*repute.fac*), so that the resulting table can be filtered by Hostile, Commoner and so on. More details for each creature are added from their *\*.utc* files, like hitpoints, classes and levels.

That data is then written to a sqlite3 database file.

The addition of other tables for *itempalcus* and *placeablepalcus* is planned.

## Usage
nwn_palcus expects at least 2 command line arguments. The first one always has to be a module `.mod` file.  
All the other arguments will be treated as directory paths where nwn_palcus looks for `.key` (and `.bif` referenced in that key), `.tlk` and `.hak` files.

At minimum a path to a `dialog.tlk` and `classes.2da` file is needed (in additon to the module, as first argument). The .2da can be in a hak or in a .bif referenced by a .key.

A good start can be to run the program and keep adding directories, there should be (hopefully) helpful error messages.

A database file with the name `creaturepalcus.sqlite3` will be written. **Warning: If that file already exists and is a sqlite database the existing table called `creaturepalcus` in there will be dropped.**

Example program call on Linux:
```
./nwn_palcus ~/sfee/server/modules/SoulForge.mod ~/Beamdog\ Library/00785/lang/en/data/ ~/sfee/server/tlk/ ~/sfee/server/hak
```

## Language
A dialog.tlk file of any language should work. That will lead to class names in the chosen language but table headers will not change.

## Why do I need this?
Having the sqlite table will allow you to query information comfortably and quickly via nwscript. Perhaps to select the most fitting creatures to spawn for an encounter. The sqlite database can be used by many other tools, too, like the graphical database tool seen in the screenshot above for a great overview.  

## Speed
On my computer with my module file it took less than 200ms to create the sqlite3 file for 1430 creatures. So to always have up to date information this tool could possibly be run on each nwserver start.

## Build
* Install [Nim](https://nim-lang.org/)
* Clone this repo
* A sqlite3 library (like libsqlite3 on Debian) needs to be installed on your system (or see the last point)
* Run `nimble build -d:release`
* For creating a static binary use the nimble tasks defined in [nwn_palcus.nimble](nwn_palcus.nimble). Run `nimble musl`. This assumes you are on Linux.

## Table schemas
### creaturepalcus.sqlite3
Table: creaturepalcus
```
cid         name           type
----------  -------------  ----------
0           id             integer     (primary key)
1           name           text
2           resref         text
3           tag            text
4           cr             integer
5           hp             integer
6           level          integer
7           class1         text
8           class1Level    integer
9           class2         text
10          class2Level    integer
11          class3         text
12          class3Level    integer
13          faction        text
14          parentFaction  text
```
