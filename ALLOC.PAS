unit alloc;

interface

  type
    barraytype = array[0..65519] of byte;

    bufptrtype = ^barraytype;

    heaptype=record
      totalunits:word;
      unitsize:word;
      data:bufptrtype
    end;

  Function min(x,y:longint):longint;

  Function max(x,y:longint):longint;

  Procedure init_heap(var h:heaptype;size,usize:word);

  Procedure free_blk(var h:heaptype;ptr:word;size:word);

  Procedure get_blk(var h:heaptype;var ptr:word;size:word);

  Function lg_freeblk(h:heaptype):word;

  Procedure free_all(var h:heaptype);

  Procedure destroy_heap(var h:heaptype);

implementation

  Function min(x,y:longint):longint;

    begin
      if (x < y) then min := x
      else min := y
    end;

  Function max(x,y:longint):longint;

    begin
      if (x > y) then max := x
      else max := y
    end;

  Function convsize(x,y:word):word;

    begin
      if x = 0 then convsize := 0
      else convsize := ((x - 1) div y) + 1
    end;

  Function convaddr(x,y:word):word;

    begin
      convaddr := x div y
    end;

  Procedure init_heap(var h:heaptype;size,usize:word);

    var cnt:word;

    begin
      h.unitsize := usize;
      h.totalunits := convsize(size,h.unitsize);
      getmem(h.data,h.totalunits);
      for cnt := 0 to h.totalunits - 1 do h.data^[cnt] := 0
    end;

  Procedure free_blk(var h:heaptype;ptr:word;size:word);

    var cnt:word;

    begin
      for cnt := convaddr(ptr,h.unitsize) to convaddr(ptr,h.unitsize)
         + convsize(size,h.unitsize) - 1 do
        h.data^[cnt] := 0
    end;

  Procedure get_blk(var h:heaptype;var ptr:word;size:word);

    var optstart,laststart,blksneeded,optsize,lastsize,cnt:word;

    begin
      if size = 0 then ptr := h.unitsize*h.totalunits
      else
        begin
          blksneeded := convsize(size,h.unitsize);
          optsize := 65535;
          lastsize := 0;
          optstart := h.totalunits;
          for cnt := 0 to h.totalunits - 1 do
            begin
              if h.data^[cnt] = 0 then
                begin
                  if lastsize = 0 then
                    begin
                      lastsize := 1;
                      laststart := cnt
                    end
                  else lastsize := lastsize + 1
                end
              else
                begin
                  if (lastsize >= blksneeded) and (lastsize < optsize) then
                    begin
                      optsize := lastsize;
                      optstart := laststart
                    end;
                  lastsize := 0
                end
            end;
          if (lastsize >= blksneeded) and (lastsize < optsize) then
            begin
              optsize := lastsize;
              optstart := laststart
            end;
          if (optstart < h.totalunits) then
            for cnt := optstart to optstart + blksneeded - 1 do
              h.data^[cnt] := 1;
          ptr := h.unitsize*optstart
        end
    end;

  Function lg_freeblk(h:heaptype):word;

    var optsize,lastsize,cnt:word;

    begin
      optsize := 0;
      lastsize := 0;
      for cnt := 0 to h.totalunits - 1 do
        begin
          if h.data^[cnt] = 0 then lastsize := lastsize + 1
          else
            begin
              if (lastsize > optsize) then optsize := lastsize;
              lastsize := 0
            end
        end;
      if (lastsize > optsize) then optsize := lastsize;
      lg_freeblk := h.unitsize*optsize
    end;

  Procedure free_all(var h:heaptype);

    var cnt:word;

    begin
      for cnt := 0 to h.totalunits - 1 do h.data^[cnt] := 0
    end;

  Procedure destroy_heap(var h:heaptype);

    begin
      freemem(h.data,h.totalunits)
    end;

end.
