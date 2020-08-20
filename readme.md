# nwn_sqlite
Extracts information from a [Neverwinter Nights](https://www.beamdog.com/games/neverwinter-nights-enhanced/) module and saves it to a [sqlite3](https://www.sqlite.org/index.html) file. sqlite databases can be read and queried via nwscript beginning with version 8193.14.

This program is written in [Nim](https://nim-lang.org/) and uses the excellent [neverwinter.nim](https://github.com/niv/neverwinter.nim) library to do all the work.

![creaturepalcus.sqlite3 database view in gui](screenshots/creaturepalcus.png)

For [table schemas see below](#table-schemas).

If you are missing a column or a whole table that would be useful to you please contact me or open a GitHub issue and I'll add it.

## Download binaries
Binaries are available for download on the [releases](https://github.com/hendrikgit/nwn_sqlite/releases) page.

## What exactly does it do?
It reads the information from Neverwinter files. A .mod file can be read and/or various GFF files like `.are`, `.utc`, `.uti` and so on. Names are looked up by reading the relevant `.2da` files and looking up strrefs in `dialog.tlk` or a possible custom tlk. The paths to these additional resources can be provided as command line arguments. The tool will run without dialog.tlk or .2da files but then some columns might not be filled.

That data is then written to a sqlite3 database file.

## Usage
A good start is to run the program and keep adding paths until there are no more warning messages.  
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
2    _NameLowercase            text
3    ResRef                    text
4    Tag                       text
5    Height                    integer
6    Width                     integer
7    Flags                     integer
8    _FlagInterior             integer
9    _FlagUnderground          integer
10   _FlagNatural              integer
11   NoRest                    integer
12   PlayerVsPlayer            integer
13   Tileset                   text
14   OnEnter                   text
15   OnExit                    text
16   LoadScreenID              integer
17   IsNight                   integer
18   DayNightCycle             integer
19   ChanceLightning           integer
20   ChanceRain                integer
21   ChanceSnow                integer
22   WindPower                 integer
23   FogClipDist               real
24   ModListenCheck            integer
25   ModSpotCheck              integer
26   Comments                  text
27   AmbientSndDay             integer
28   AmbientSndDayVol          integer
29   AmbientSndNight           integer
30   AmbientSndNitVol          integer
31   EnvAudio                  integer
32   MusicBattle               integer
33   MusicDay                  integer
34   MusicDelay                integer
35   MusicNight                integer
```

### creatures
```
cid  name                      type
---  ------------------------  -------
0    id                        integer
1    FirstName                 text
2    LastName                  text
3    _Name                     text
4    _NameLowercase            text
5    TemplateResRef            text
6    Tag                       text
7    PaletteID                 integer
8    _Palette                  text
9    _PaletteFull              text
10   ChallengeRating           integer
11   CRAdjust                  integer
12   MaxHitPoints              integer
13   _Level                    integer
14   _Class1                   integer
15   _Class1Name               text
16   _Class1Level              integer
17   _Class2                   integer
18   _Class2Name               text
19   _Class2Level              integer
20   _Class3                   integer
21   _Class3Name               text
22   _Class3Level              integer
23   FactionID                 integer
24   _ParentFactionID          integer
25   _FactionName              text
26   _ParentFactionName        text
27   Race                      integer
28   _RaceName                 text
29   Gender                    integer
30   _GenderName               text
31   LawfulChaotic             integer
32   GoodEvil                  integer
33   _Alignment                text
34   NaturalAC                 integer
35   Str                       integer
36   Dex                       integer
37   Con                       integer
38   Int                       integer
39   Wis                       integer
40   Cha                       integer
41   Lootable                  integer
42   Disarmable                integer
43   IsImmortal                integer
44   NoPermDeath               integer
45   Plot                      integer
46   Interruptable             integer
47   WalkRate                  integer
48   Conversation              text
49   Comment                   text
```

### items
```
cid  name                      type
---  ------------------------  -------
0    id                        integer
1    LocalizedName             text
2    _NameLowercase            text
3    TemplateResRef            text
4    Tag                       text
5    BaseItem                  integer
6    _BaseItemName             text
7    PaletteID                 integer
8    _Palette                  text
9    _PaletteFull              text
10   Identified                integer
11   StackSize                 integer
12   _StackingBaseitems2da     integer
13   Charges                   integer
14   Cost                      integer
15   AddCost                   integer
16   Cursed                    integer
17   Plot                      integer
18   Stolen                    integer
19   Comment                   text
```

### placeables
```
cid  name                      type
---  ------------------------  -------
0    id                        integer
1    LocName                   text
2    _NameLowercase            text
3    TemplateResRef            text
4    Tag                       text
5    PaletteID                 integer
6    _Palette                  text
7    _PaletteFull              text
8    Faction                   integer
9    _ParentFactionID          integer
10   _FactionName              text
11   _ParentFactionName        text
12   Static                    integer
13   Plot                      integer
14   Useable                   integer
15   HasInventory              integer
16   HP                        integer
17   Hardness                  integer
18   Fort                      integer
19   Will                      integer
20   Locked                    integer
21   Lockable                  integer
22   KeyRequired               integer
23   KeyName                   text
24   OpenLockDC                integer
25   CloseLockDC               integer
26   DisarmDC                  integer
27   Interruptable             integer
28   TrapDetectable            integer
29   TrapDetectDC              integer
30   TrapDisarmable            integer
31   TrapFlag                  integer
32   TrapOneShot               integer
33   TrapType                  integer
34   Conversation              text
35   Comment                   text
```
