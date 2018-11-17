program savemark;

  type
    arraytype = array[1..16380] of longint;
    recarraytype = array[0..65519] of byte;
    arrayptrtype = ^arraytype;
    recptrtype = ^recarraytype;
    ptrtype = ^string;

  var
    idfile,mainfile,markfile:string;
    marksize,numwritten,maxmem,numread:word;
    code,recsize,recidloc:integer;
    currecptr:recptrtype;
    markarrayptr:arrayptrtype;
    f:file;
    p:ptrtype;
    lastid,recid,curpos:longint;

  Procedure sort(mptr:arrayptrtype;size:integer);

    var cnt,incr,posit,newposit,count:integer;
        temp:longint;
        done:boolean;

    begin
      incr := 1;
      while incr < size div 9 do
        incr := incr*3 + 1;
      while incr > 0 do
        begin
          for cnt := 1 to incr do
            begin
              posit := cnt + incr;
              while posit <= size do
                begin
                  newposit := posit - incr;
                  done := false;
                  while not done do
                    begin
                      if mptr^[posit] >= mptr^[newposit] then done := true
                      else newposit := newposit - incr;
                      if newposit < cnt then done := true
                    end;
                  temp := mptr^[posit];
                  count := posit - incr;
                  while count >= newposit + incr do
                    begin
                      mptr^[count+incr] := mptr^[count];
                      count := count - incr
                    end;
                  mptr^[newposit+incr] := temp;
                  posit := posit + incr
                end
            end;
          incr := incr div 3
        end
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
    blockread(f,idfile,13,numread);
    close(f);
    assign(f,idfile);
    reset(f,1);
    blockread(f,lastid,4,numread);
    close(f);
    getmem(currecptr,recsize);
    marksize := 0;
    assign(f,mainfile);
    reset(f,1);
    while (not eof(f)) do
      begin
        blockread(f,currecptr^,recsize,numread);
        if currecptr^[0] <> 0 then
          begin
            marksize := marksize + 1;
            if marksize > (maxmem div 4) then
              begin
                close(f);
                assign(f,idfile);
                rewrite(f,1);
                blockwrite(f,lastid,4,numwritten);
                close(f);
                writeln(chr(7)+'Out of memory.');
                exit
              end;
            p := addr(currecptr^[recidloc]);
            val(p^,recid,code);
            if recid <> 0 then
              markarrayptr^[marksize] := recid
            else
              begin
                lastid := lastid + 1;
                markarrayptr^[marksize] := lastid;
                str(lastid,p^);
                curpos := filepos(f);
                seek(f,curpos-recsize);
                blockwrite(f,currecptr^,recsize,numwritten)
              end
          end
      end;
    freemem(currecptr,recsize);
    close(f);
    assign(f,idfile);
    rewrite(f,1);
    blockwrite(f,lastid,4,numwritten);
    close(f);
    sort(markarrayptr,marksize);
    assign(f,markfile);
    reset(f,1);
    seek(f,30);
    blockwrite(f,markarrayptr^,4*marksize,numwritten);
    truncate(f);
    close(f);
    freemem(markarrayptr,maxmem)
  end.
