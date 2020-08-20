# nwn_sqlite
Extracts information from a [Neverwinter Nights](https://www.beamdog.com/games/neverwinter-nights-enhanced/) module and saves it to a [sqlite3](https://www.sqlite.org/index.html) file. sqlite databases can be read and queried via nwscript beginning with version 8193.14.

This program is written in [Nim](https://nim-lang.org/) and uses the excellent [neverwinter.nim](https://github.com/niv/neverwinter.nim) library to do all the work.

![creaturepalcus.sqlite3 database view in gui](screenshots/creaturepalcus.png)

For [table schemas see below](#table-schemas).

If you are missing a column or a whole table that would be useful to you please contact me or open a GitHub issue and I'll add it.

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

Use the `-e:encoding` parameter to use a different input encoding (default is windows-1252). This can be used for Cyrillic (cp1251) for example.

## Why do I need this?
Having this sqlite table will allow you to query information comfortably and quickly via nwscript. Perhaps to select the most fitting creatures to spawn for an encounter. The sqlite database can be used by many other tools, too, like the graphical database tool seen in the screenshot above for a great overview.  

## Speed
On my computer with my module file it takes less than a second to create the sqlite3 file. This tool could possibly be run at each nwserver start to always have up to date information for the running module.

## Build
* Install [Nim](https://nim-lang.org/)
* Clone this repo
* A sqlite3 library (like libsqlite3 on Debian) needs to be installed on your system (or see the last point)
* Run `nimble build -d:release`
* For creating a static binary the nimble tasks defined in [nwn_sqlite.nimble](nwn_sqlite.nimble) can be used. The tasks `musl` and `win` assume you are building on Linux, `macos` needs to be run on macOS.

## Table schemas
Schemas for the tables in the sqlite3 database file that will be written.  
To generate schema output like what is seen below run:
```
sqlite3 dbname.sqlite3 < schemas.sqlite | sed -r 's/.{9}$//'
```
[schemas.sqlite](schemas.sqlite) contains the commands to generate the table info. Piping the output from above command to the [update_readme_schemas.rb](update_readme_schemas.rb) ruby script will directly update this readme file.

Column names match the names of the fields/keys in the corresponding gff. Additional columns beginn with an underscore.

**Tables**
* [areas](#areas)
* [creatures](#creatures)
* [items](#items)
* [placeables](#placeables)

### areas
```
cid  name                      type
---  ------------------------  -------
0    id                        integer
1    Name                      text
2    ResRef                    text
3    Tag                       text
4    Height                    integer
5    Width                     integer
6    Flags                     integer
7    _FlagInterior             integer
8    _FlagUnderground          integer
9    _FlagNatural              integer
10   NoRest                    integer
11   PlayerVsPlayer            integer
12   Tileset                   text
13   OnEnter                   text
14   OnExit                    text
15   LoadScreenID              integer
16   IsNight                   integer
17   DayNightCycle             integer
18   ChanceLightning           integer
19   ChanceRain                integer
20   ChanceSnow                integer
21   WindPower                 integer
22   FogClipDist               real
23   ModListenCheck            integer
24   ModSpotCheck              integer
25   Comments                  text
26   AmbientSndDay             integer
27   AmbientSndDayVol          integer
28   AmbientSndNight           integer
29   AmbientSndNitVol          integer
30   EnvAudio                  integer
31   MusicBattle               integer
32   MusicDay                  integer
33   MusicDelay                integer
34   MusicNight                integer
```

### creatures
```
cid  name                      type
---  ------------------------  -------
0    id                        integer
1    FirstName                 text
2    LastName                  text
3    _Name                     text
4    TemplateResRef            text
5    Tag                       text
6    PaletteID                 integer
7    _Palette                  text
8    _PaletteFull              text
9    ChallengeRating           integer
10   CRAdjust                  integer
11   MaxHitPoints              integer
12   _Level                    integer
13   _Class1                   integer
14   _Class1Name               text
15   _Class1Level              integer
16   _Class2                   integer
17   _Class2Name               text
18   _Class2Level              integer
19   _Class3                   integer
20   _Class3Name               text
21   _Class3Level              integer
22   FactionID                 integer
23   _ParentFactionID          integer
24   _FactionName              text
25   _ParentFactionName        text
26   Race                      integer
27   _RaceName                 text
28   Gender                    integer
29   _GenderName               text
30   LawfulChaotic             integer
31   GoodEvil                  integer
32   _Alignment                text
33   NaturalAC                 integer
34   Str                       integer
35   Dex                       integer
36   Con                       integer
37   Int                       integer
38   Wis                       integer
39   Cha                       integer
40   Lootable                  integer
41   Disarmable                integer
42   IsImmortal                integer
43   NoPermDeath               integer
44   Plot                      integer
45   Interruptable             integer
46   WalkRate                  integer
47   Conversation              text
48   Comment                   text
```

### items
```
cid  name                      type
---  ------------------------  -------
0    id                        integer
1    LocalizedName             text
2    TemplateResRef            text
3    Tag                       text
4    BaseItem                  integer
5    _BaseItemName             text
6    PaletteID                 integer
7    _Palette                  text
8    _PaletteFull              text
9    Identified                integer
10   StackSize                 integer
11   _StackingBaseitems2da     integer
12   Charges                   integer
13   Cost                      integer
14   AddCost                   integer
15   Cursed                    integer
16   Plot                      integer
17   Stolen                    integer
18   Comment                   text
```

### placeables
```
cid  name                      type
---  ------------------------  -------
0    id                        integer
1    LocName                   text
2    TemplateResRef            text
3    Tag                       text
4    PaletteID                 integer
5    _Palette                  text
6    _PaletteFull              text
7    Faction                   integer
8    _ParentFactionID          integer
9    _FactionName              text
10   _ParentFactionName        text
11   Static                    integer
12   Plot                      integer
13   Useable                   integer
14   HasInventory              integer
15   HP                        integer
16   Hardness                  integer
17   Fort                      integer
18   Will                      integer
19   Locked                    integer
20   Lockable                  integer
21   KeyRequired               integer
22   KeyName                   text
23   OpenLockDC                integer
24   CloseLockDC               integer
25   DisarmDC                  integer
26   Interruptable             integer
27   TrapDetectable            integer
28   TrapDetectDC              integer
29   TrapDisarmable            integer
30   TrapFlag                  integer
31   TrapOneShot               integer
32   TrapType                  integer
33   _TrapTypeName             text
34   Conversation              text
35   Comment                   text
```
