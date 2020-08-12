import options, strutils
import neverwinter/[gff, tlk, twoda]
import helper

type
  Creature* = object
    name*, resref*, tag*: string
    cr*, hp*: int
    level*: int
    class1*: string
    class1Level*: int
    class2*: string
    class2Level*: int
    class3*: string
    class3Level*: int
    faction*, parentFaction*: string

  Classes* = tuple
    class1, class2, class3: string
    level1, level2, level3: int

proc classes*(classList: GffList, classes: TwoDA, dlg: SingleTlk, tlk: Option[SingleTlk]): Classes =
  result.class1 = classes[classList[0]["Class", GffInt], "Name"].get.parseInt.StrRef.tlkText(dlg, tlk)
  result.level1 = classList[0]["ClassLevel", GffShort]
  if classList.len >= 2:
    result.class2 = classes[classList[1]["Class", GffInt], "Name"].get.parseInt.StrRef.tlkText(dlg, tlk)
    result.level2 = classList[1]["ClassLevel", GffShort]
  if classList.len == 3:
    result.class3 = classes[classList[2]["Class", GffInt], "Name"].get.parseInt.StrRef.tlkText(dlg, tlk)
    result.level3 = classList[2]["ClassLevel", GffShort]
