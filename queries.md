# Example queries for nwn_sqlite tables
Some useful, interesting or funny example queries.

## Area related

### Total surface of a world in tiles
![Surface area](screenshots/surface.png)

### Most used tilesets
![Tilesets used](screenshots/tilesets.png)

### Surface by type
![Surface by type](screenshots/surface-by-type.png)
```sql
select
(select sum(height * width) from areas  group by _FlagUnderground having _FlagUnderground = 1) as under_ground,
(select sum(height * width) from areas  group by _FlagUnderground having _FlagUnderground = 0) as above_ground,
(select sum(height * width) from areas  group by _FlagNatural having _FlagNatural = 1) as natural,
(select sum(height * width) from areas  group by _FlagNatural having _FlagNatural = 0) as urban,
(select sum(height * width) from areas  group by _FlagInterior having _FlagInterior = 1) as interior,
(select sum(height * width) from areas  group by _FlagInterior having _FlagInterior = 0) as exterior;
```

## Lower case name in unicode
SQL lower() function only works on ASCII.  
![Lower case name unicode](screenshots/namelower.png)
