# nwn_palcus
Extracts information from a [Neverwinter Nights](https://www.beamdog.com/games/neverwinter-nights-enhanced/) module and saves it to a [sqlite3](https://www.sqlite.org/index.html) file. sqlite databases can be read and queried via nwscript beginning with version 8193.14.

This program is written in [Nim](https://nim-lang.org/) and uses the excellent [neverwinter.nim](https://github.com/niv/neverwinter.nim) library to do all the work.

## What exactly does it do?
It reads the information from a Neverwinter module file contained in the *creaturepalcus.itp*. Some additional information about factions (*repute.fac*), so that the resulting table can be filtered by Hostile, Commoner and so on. More details for each creature are added from their *\*.utc* files, like hitpoints, classes and levels.

That data is then written to a sqlite3 database file.

The addition of other tables for *itempalcus* and *placeablepalcus* is planned.

## Screenshot
![creaturepalcus.sqlite3 database view in gui](screenshots/creaturepalcus.png)

## Build
* Install [Nim](https://nim-lang.org/)
* Clone this repo
* Run `nimble build -d:release`
