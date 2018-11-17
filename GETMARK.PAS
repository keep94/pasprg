program getmark;

  type
    arraytype = array[1..16380] of longint;
    recarraytype = array[0..65519] of byte;
    arrayptrtype = ^arraytype;
    recptrtype = ^recarraytype;
    ptrtype = ^string;

  var
    mainfile,markfile:string;
    numwritten,maxmem,marksize,numread:word;
    choice,code,recsize,recidloc:integer;
    currecptr:recptrtype;
    markarrayptr:arrayptrtype;
    f:file;
    p:ptrtype;
    recid,curpos:longint;
    tempbool:boolean;


  Function inlist(mptr:arrayptrtype;size:integer;item:longint):boolean;

    var first,last,mid:integer;
        found:boolean;

    begin
      if size <= 0 then inlist := false
      else
        begin
          first := 1;
          last := size;
          if (mptr^[first] = item) or (mptr^[last] = item) then inlist := true
          else if (item < mptr^[first]) or (item > mptr^[last]) then inlist := false
          else
            begin
              found := false;
              while ((last - first) > 1) and (not found) do
                begin
                  mid := (first + last) div 2;
                  if (item = mptr^[mid]) then found := true
                  else if (item > mptr^[mid]) then first := mid
                  else if (item < mptr^[mid]) then last := mid
                end;
              inlist := found
            end
        end
    end;

  Function tobemarked(x,y:boolean;c:integer):boolean;

    begin
      case c of
        1:tobemarked := y;
        2:tobemarked := not y;
        3:tobemarked := x and y;
        4:tobemarked := x or y;
        5:tobemarked := x xor y;
        6:tobemarked := x and (not y);
        7:tobemarked := x or (not y);
        8:tobemarked := x xor (not y)
      end
    end;

  Procedure menu(var c:integer);

    var temp:string;
        code:integer;

    begin
      writeln;
      writeln;
      writeln('        1.  Default option');
      writeln('        2.  NOT option');
      writeln('        3.  AND option');
      writeln('        4.  OR option');
      writeln('        5.  XOR option');
      writeln('        6.  AND NOT option');
      writeln('        7.  OR NOT option');
      writeln('        8.  XOR NOT option');
      writeln('        9.  Quit');
      writeln;
      write('Pick one: ');
      readln(temp);
      val(temp,c,code)
    end;

  begin
    markfile := paramstr(1);
    if markfile = '' then
      begin
        writeln(chr(7)+'Too few parameters.');
        exit
      end;
    if paramstr(2) <> '' then
      begin
        val(paramstr(1),maxmem,code);
        if maxmem > 65520 then maxmem := 65520;
        if maxmem <= 0 then maxmem := 65520
      end
    else maxmem := 65520;
    maxmem := 4*(maxmem div 4);
    getmem(markarrayptr,maxmem);
    assign(f,markfile);
    reset(f,1);
    blockread(f,recsize,2,numread);
    blockread(f,recidloc,2,numread);
    blockread(f,mainfile,13,numread);
    seek(f,30);
    blockread(f,markarrayptr^,maxmem,numread);
    marksize := numread div 4;
    close(f);
    menu(choice);
    if (choice < 1) or (choice > 8) then
      begin
        freemem(markarrayptr,maxmem);
        exit
      end;
    getmem(currecptr,recsize);
    assign(f,mainfile);
    reset(f,1);
    while (not eof(f)) do
      begin
        blockread(f,currecptr^,recsize,numread);
        p := addr(currecptr^[recidloc]);
        val(p^,recid,code);
        tempbool := tobemarked(boolean(currecptr^[0]),inlist(markarrayptr,marksize,recid),choice);
        currecptr^[0] := byte(tempbool);
        curpos := filepos(f);
        seek(f,curpos-recsize);
        blockwrite(f,currecptr^,recsize,numwritten)
      end;
    close(f);
    freemem(currecptr,recsize);
    freemem(markarrayptr,maxmem)
  end.
