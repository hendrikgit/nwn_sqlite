# mod2sqlite
Extracts information from a [Neverwinter Nights](https://www.beamdog.com/games/neverwinter-nights-enhanced/) module and saves it to a [sqlite3](https://www.sqlite.org/index.html) file. sqlite databases can be read and queried via nwscript beginning with version 8193.14.

This program is written in [Nim](https://nim-lang.org/) and uses the excellent [neverwinter.nim](https://github.com/niv/neverwinter.nim) library to do all the work.

![creaturepalcus.sqlite3 database view in gui](screenshots/creaturepalcus.png)

For [table schemas see below](#table-schemas).

## Download binaries
Binaries are available for download on the [releases](https://github.com/hendrikgit/mod2sqlite/releases/latest) page.

## What exactly does it do?
It reads the information from a Neverwinter module file contained in `module.ifo`, `*palcus.itp` and various GFF files like `.utc`, `.utp` and so on. Names are looked up by reading the relevant `.2da` files and looking up strrefs in `dialog.tlk` or a possible custom tlk. The paths to these additional resources have to be provided as command line arguments.

That data is then written to a sqlite3 database file named as the module file but with the extension of .sqlite3.

## Usage
mod2sqlite expects at least 2 command line arguments. The first one always has to be a module `.mod` file.  
All the other arguments will be treated as directory paths where mod2sqlite looks for `.key` (and `.bif` referenced in that key), `.tlk` and `.hak` files.

At minimum paths to `dialog.tlk` and various .2da files are needed (in additon to the module, as first argument). The .2da files can be in a hak or in a .bif referenced by a .key. They could also just be in a folder directly.

A good start can be to run the program and keep adding directories, there should be (hopefully) helpful error messages.

A database file with the *name of the module file and the extension `.sqlite3`* will be written.  
**Warning: If that file already exists and is a sqlite database the existing tables in it will be dropped (and recreated and filled with new data).**

Example program call on Linux:
```
./mod2sqlite ~/sfee/server/modules/SoulForge.mod ~/Beamdog\ Library/00785/lang/en/data/ ~/Beamdog\ Library/00785/data/ ~/sfee/server/tlk/ ~/sfee/server/hak
```

## Language
A dialog.tlk file of any language should work. The language of the provided dialog.tlk will also be used when looking up localized strings. If a localized string has no entry for the language the dialog.tlk is in, then next english will be tried and lastly the first language with a value

Table column names will not change.

## Why do I need this?
Having this sqlite table will allow you to query information comfortably and quickly via nwscript. Perhaps to select the most fitting creatures to spawn for an encounter. The sqlite database can be used by many other tools, too, like the graphical database tool seen in the screenshot above for a great overview.  

## Speed
On my computer with my module file it takes less than a second to create the sqlite3 file. This tool could possibly be run at each nwserver start to always have up to date information for the running module.

## Build
* Install [Nim](https://nim-lang.org/)
* Clone this repo
* A sqlite3 library (like libsqlite3 on Debian) needs to be installed on your system (or see the last point)
* Run `nimble build -d:release`
* For creating a static binary use the nimble tasks defined in [mod2sqlite.nimble](mod2sqlite.nimble). Run `nimble musl`. This assumes you are on Linux.

## Table schemas
Schemas for the tables in the sqlite3 database file that will be written.  
To generate schema output like what is seen below run `sqlite3 dbname.sqlite3 < schemas.sqlite | sed -r 's/.{9}$//'`.  
[schemas.sqlite](schemas.sqlite) contains the commands to generate the table info.

### creatures
```
cid  name                      type   
---  ------------------------  -------
0    id                        integer
1    name                      text   
2    resref                    text   
3    tag                       text   
4    cr                        integer
5    hp                        integer
6    level                     integer
7    class1                    text   
8    class1_id                 integer
9    class1_level              integer
10   class2                    text   
11   class2_id                 integer
12   class2_level              integer
13   class3                    text   
14   class3_id                 integer
15   class3_level              integer
16   faction                   text   
17   faction_id                integer
18   parent_faction            text   
19   parent_faction_id         integer
20   race                      text   
21   race_id                   integer
22   gender                    text   
23   gender_id                 integer
24   alignment                 text   
25   alignment_lawful_chaotic  integer
26   alignment_good_evil       integer
```
