# k052109_verilog

!["052109"](https://github.com/RndMnkIII/k052109_verilog/blob/main/img/konami_052109.jpg)

This is a preliminar simulation written in Verilog for the Konami k052109 Tile Layer Generator
used in many Konami arcade game machines at the end of 80's and beginning of 90's. This is used together
with his twin k051962 IC and it is responsible for generate the tilemaps of the game. This code is based 
on the schematics released by @Furrtek which was able to trace the internal channeled gate array structure
of this IC and identify the functions that were used.

https://github.com/furrtek/VGChips/tree/master/Konami

Test Bench Usage:
```
iverilog -o k052109_tb.vvp k052109_tb.v k052109.v addr_sel.v  vram.v fujitsu_AV_UnitCellLibrary_DLY.v
vvp k052109_tb.vvp -lxt2
gtkwave k052109_tb.lxt&
```


