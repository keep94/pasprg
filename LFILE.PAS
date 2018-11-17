program test;

  const
    MAXFT = 500;
    MAXBUFSIZE = 32000;
    MAXFWRITE = 16000;
    UNITSIZE = 64;

  type
    ftrectype = record
      ftindex:longint;
      b_size:word;
      b_loc:word
    end;

    ftarraytype = array[0..MAXFT + 1] of ftrectype;

    fttype = record
      default:word;
      data:ftarraytype;
      posit:integer;
      size:integer
    end;

    barraytype = array[0..65519] of byte;

    bufptrtype = ^barraytype;

    heaptype=record
      totalunits:word;
      data:bufptrtype
    end;

    lftype = record
      f:file;
      blnum:longint;
      blsize:word;
      altered:boolean;
      blseg:longint;
      bloff:word;
      fposit:longint;
      fsize:longint;
      ft:^fttype;
      h:heaptype;
      bufptr:bufptrtype;
      overbufptr:bufptrtype;
    end;

  var h:heaptype;
      size,ptr:word;
      choice:integer;
      bsize,bloc:word;
      bnum:longint;
      ft:fttype;

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

  Function convsize(x:word):word;

    begin
      if x = 0 then convsize := 0
      else convsize := ((x - 1) div UNITSIZE) + 1
    end;

  Function convaddr(x:word):word;

    begin
      convaddr := x div UNITSIZE
    end;

  Procedure init_heap(var h:heaptype;size:word);

    var cnt:word;

    begin
      h.totalunits := convsize(size);
      getmem(h.data,h.totalunits);
      for cnt := 0 to h.totalunits - 1 do h.data^[cnt] := 0
    end;

  Procedure free_blk(var h:heaptype;ptr:word;size:word);

    var cnt:word;

    begin
      for cnt := convaddr(ptr) to convaddr(ptr) + convsize(size) - 1 do
        h.data^[cnt] := 0
    end;

  Procedure get_blk(var h:heaptype;var ptr:word;size:word);

    var optstart,laststart,blksneeded,optsize,lastsize,cnt:word;

    begin
      if size = 0 then ptr := UNITSIZE*h.totalunits
      else
        begin
          blksneeded := convsize(size);
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
          ptr := UNITSIZE*optstart
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
      lg_freeblk := UNITSIZE*optsize
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


  Procedure init_ft(var ft:fttype;bufsize:word);

    begin
      ft.default := bufsize;
      ft.data[0].ftindex := -2147483647;
      ft.data[1].ftindex :=  2147483647;
      ft.posit := 1;
      ft.size := 0
    end;

  Procedure get_ft(var ft:fttype;index:longint;var size:word;var loc:word);

    begin
      while ft.data[ft.posit].ftindex < index do
        ft.posit := ft.posit + 1;
      while ft.data[ft.posit].ftindex > index do
        ft.posit := ft.posit - 1;
      if ft.data[ft.posit].ftindex = index then
        begin
          size := ft.data[ft.posit].b_size;
          loc := ft.data[ft.posit].b_loc
        end
      else size := ft.default
    end;

  Procedure put_ft(var ft:fttype;index:longint;size,loc:word);

    var cnt:integer;

    begin
      while ft.data[ft.posit].ftindex < index do
        ft.posit := ft.posit + 1;
      while ft.data[ft.posit].ftindex > index do
        ft.posit := ft.posit - 1;
      if ft.data[ft.posit].ftindex = index then
        begin
          if size <> ft.default then
            begin
              ft.data[ft.posit].b_size := size;
              ft.data[ft.posit].b_loc := loc
            end
          else
            begin
              for cnt := ft.posit to ft.size do
                ft.data[cnt] := ft.data[cnt+1];
              ft.size := ft.size - 1
            end
        end
      else
        begin
          if size <> ft.default then
            begin
              for cnt := ft.size + 1 downto ft.posit + 1 do
                ft.data[cnt+1] := ft.data[cnt];
              ft.size := ft.size + 1;
              ft.posit := ft.posit + 1;
              ft.data[ft.posit].ftindex := index;
              ft.data[ft.posit].b_size := size;
              ft.data[ft.posit].b_loc := loc
            end
        end
    end;


  Procedure initf(var lf:lftype);

    begin
      getmem(lf.ft^,sizeof(fttype));
      init_ft(lf.ft^,MAXFWRITE);
      init_heap(lf.h,MAXFWRITE);
      getmem(lf.bufptr^,MAXBUFSIZE);
      getmem(lf.overbufptr^,MAXFWRITE)
    end;



  Procedure closeblock(var lf:lftype);

    var
      cnt,towrite,sizeofbl,memptr,numwritten:word;


    begin
      if lf.altered then
        begin
          sizeofbl := lf.blsize;
          towrite := min(MAXFWRITE,sizeofbl);
          seek(lf.f,MAXFWRITE*lf.blnum);
          blockwrite(lf.f,lf.bufptr^,towrite,numwritten);
          sizeofbl := sizeofbl - towrite;
          if sizeofbl > 0 then
            begin
              get_blk(lf.h,memptr,sizeofbl);
              for cnt := 0 to sizeofbl - 1 do
                lf.overbufptr^[memptr+cnt] := lf.bufptr^[towrite + cnt]
            end;
          put_ft(lf.ft^,lf.blnum,lf.blsize,memptr);
          lf.altered := false
        end
    end;


{  Procedure openblock(var lf:lftype;x:longint);

    begin
      get_ft(lf.ft^,x,lf.blsize,memptr);
      lf.blnum := x;
      lf.altered := false;
      sizeofbl := lf.blsize;
      toread := min(MAXFWRITE,sizeofbl);
      seek(lf.f,MAXFWRITE*lf.blnum);
      blockread(lf.f,lf.bufptr^,toread,numread);
      sizeofbl := sizeofbl - toread;
      if sizeofbl > 0 then
        begin
          for cnt := 0 to sizeofbl - 1 do
            lf.bufptr^[toread + cnt] := lf.overbufptr^[memptr + cnt];
          free_blk(lf.h,memptr,sizeofbl)
        end
    end;




  Procedure lfseek(var lf:lftype;x:longint);

    begin
      if x < 0 then x := 0;
      if x > lf.fsize then x := lf.fsize;
      lf.fposit := x;
      if lf.ft^.size = MAXFT - 2 then
        lfflush(lf)
      else
        begin
          if x = lf.fsize then
            begin
              if lf.lastbl <> lf.blnum then
                begin
                  closeblock(lf);
                  openblock(lf,lf.lastbl)
                end;
              if lf.blsize = lg_freeblk(lf.h) then
                lfflush(lf)
              else
                begin
                  lf.blseg := lf.fsize - lf.blsize;
                  lf.bloff := lf.blsize;
                  lf.fsize := lf.fsize + 1;
                  lf.blsize := lf.blsize + 1
                end
            end
          else
            begin
              newblnum := lf.blnum;
              while (lf.blseg <= x) do
                begin
                  get_ft(lf.ft^,newblnum,cbsize,cbloc);
                  lf.blseg := lf.blseg + cbsize;
                  newblnum := newblnum + 1
                end;
              while (lf.blseg > x) do
                begin
                  newblnum := newblnum - 1;
                  get_ft(lf.ft^,newblnum,cbsize,cbloc);
                  lf.blseg := lf.blseg - cbsize
                end;
              if newblnum <> lf.blnum then
                begin
                  closeblock(lf);
                  openblock(lf,newblnum)
                end;
              lf.bloff := x - lf.blseg
            end
        end
    end;



 }
  begin
    init_ft(ft,16000);
    repeat
      writeln('1.  Assign values');
      writeln('2.  Get values');
      writeln('3.  Check size');
      writeln('4.  Quit');
      writeln;
      write('Pick one: ');
      readln(choice);
      writeln;
      case choice of
        1:begin
            write('Enter block num: ');
            readln(bnum);
            write('Enter size of block: ');
            readln(bsize);
            write('Enter location of block: ');
            readln(bloc);
            put_ft(ft,bnum,bsize,bloc);
            writeln
          end;
        2:begin
            write('Enter block num: ');
            readln(bnum);
            get_ft(ft,bnum,bsize,bloc);
            writeln('Size of block: ',bsize);
            writeln('Location of block: ',bloc);
            writeln
          end;
        3:begin
            writeln('Size of table: ',ft.size);
            writeln
          end
      end
    until (choice = 4)
  end.

{  begin
    init_heap(h,16000);
    repeat
      writeln('1.  Allocate');
      writeln('2.  Deallocate');
      writeln('3.  Largest free block');
      writeln('4.  Free all');
      writeln('5.  Quit');
      writeln;
      write('Pick one: ');
      readln(choice);
      writeln;
      case choice of
        1:begin
            write('Enter size: ');
            readln(size);
            get_blk(h,ptr,size);
            writeln('Location: ',ptr);
            writeln
          end;
        2:begin
            write('Enter location: ');
            readln(ptr);
            write('Enter size: ');
            readln(size);
            free_blk(h,ptr,size);
            writeln
          end;
        3:begin
            writeln('Largest free block: ',lg_freeblk(h));
            writeln
          end;
        4:free_all(h)
      end;
    until (choice = 5);
      destroy_heap(h)
  end.
}