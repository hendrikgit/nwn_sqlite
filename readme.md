# nwn_sqlite
Extracts information from a [Neverwinter Nights](https://www.beamdog.com/games/neverwinter-nights-enhanced/) module and saves it to a [sqlite3](https://www.sqlite.org/index.html) file. sqlite databases can be read and queried via nwscript beginning with version 8193.14.

This program is written in [Nim](https://nim-lang.org/) and uses the excellent [neverwinter.nim](https://github.com/niv/neverwinter.nim) library to do all the work.

![creaturepalcus.sqlite3 database view in gui](screenshots/creaturepalcus.png)

For [table schemas see below](#table-schemas).

## Download binaries
Binaries are available for download on the [releases](https://github.com/hendrikgit/nwn_sqlite/releases) page.

## What exactly does it do?
It reads the information from Neverwinter files. A .mod file could be read. Also various GFF files like `.utc`, `.uti` and so on. Names are looked up by reading the relevant `.2da` files and looking up strrefs in `dialog.tlk` or a possible custom tlk. The paths to these additional resources have to be provided as command line arguments.

That data is then written to a sqlite3 database file.

## Usage
A good start is to run the program and keep adding paths, there should be (hopefully) helpful error messages.  
Don't forget the servers override folder.

**Warning: Existing tables in the sqlite database file will be dropped (and recreated and filled with new data).**

Example program call on Linux:
```
./nwn_sqlite -o:sf.sqlite3 ~/server/modules/SoulForge.mod ~/Beamdog\ Library/00785/lang/en/data/ ~/Beamdog\ Library/00785/data/ ~/server/tlk/ ~/server/hak ~/server/override
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
* For creating a static binary use the nimble tasks defined in [nwn_sqlite.nimble](nwn_sqlite.nimble). Run `nimble musl`. This assumes you are on Linux.

## Table schemas
Schemas for the tables in the sqlite3 database file that will be written.  
To generate schema output like what is seen below run:
```
sqlite3 dbname.sqlite3 < schemas.sqlite | sed -r 's/.{9}$//'
```
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
5    cr_adjust                 integer
6    hp                        integer
7    level                     integer
8    class1                    text   
9    class1_id                 integer
10   class1_level              integer
11   class2                    text   
12   class2_id                 integer
13   class2_level              integer
14   class3                    text   
15   class3_id                 integer
16   class3_level              integer
17   faction                   text   
18   faction_id                integer
19   parent_faction            text   
20   parent_faction_id         integer
21   race                      text   
22   race_id                   integer
23   gender                    text   
24   gender_id                 integer
25   alignment                 text   
26   alignment_lawful_chaotic  integer
27   alignment_good_evil       integer
28   natural_ac                integer
29   str                       integer
30   dex                       integer
31   con                       integer
32   int                       integer
33   wis                       integer
34   cha                       integer
35   lootable                  integer
36   disarmable                integer
37   is_immortal               integer
38   no_perm_death             integer
39   plot                      integer
40   interruptable             integer
41   walk_rate                 integer
42   conversation              text   
43   comment                   text
```
