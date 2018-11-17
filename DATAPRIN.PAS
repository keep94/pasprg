program printcopies;

  uses IOunit;

  const
    DEFLEFT = 3;
    DEFRIGHT = 3;
    DEFTOP = 2;
    DEFBOTTOM = 2;
    DEFPAGESIZE = 60;
    DEFDEVICE = 'lpt1';
    DEFLINESIZE = 80;

  type
    lineinfotype = record
      l:integer;
      numlines:integer;
      off:array[1..20] of integer
    end;

  var
    linesize,rightmarg,cinpline,code,leftmarg,top,bottom,pagesize,numcopies,cnt:integer;
    temp,filename,device:string;
    escpressed,filevalid:boolean;
    g:text;

  Function spaces(x:integer):string;

    var temp:string;
        cnt:integer;

    begin
      temp := '';
      for cnt := 1 to x do
        temp := temp + ' ';
      spaces := temp
    end;

  Function lenwtab(x,y:integer):integer;

    begin
      if y <= 1 then lenwtab := x
      else lenwtab := x - 5
    end;

  Procedure getlineinfo(x:string;linesize,left,right:integer;var lineinfo:lineinfotype);

    var cnt,oldposit:integer;

    begin
      linesize := linesize - left - right;
      lineinfo.l := left;
      if x = '' then lineinfo.numlines := 0
      else
        begin
          lineinfo.numlines := 1;
          lineinfo.off[1] := 0;
          oldposit := 0;
          for cnt := 1 to length(x) do
            begin
              if x[cnt] = ' ' then
                begin
                  if cnt > lineinfo.off[lineinfo.numlines] + lenwtab(linesize,lineinfo.numlines) then
                    begin
                      lineinfo.numlines := lineinfo.numlines + 1;
                      lineinfo.off[lineinfo.numlines] := oldposit
                    end;
                  oldposit := cnt
                end
            end;
          if length(x) + 1 > lineinfo.off[lineinfo.numlines] + lenwtab(linesize,lineinfo.numlines) then
            begin
              lineinfo.numlines := lineinfo.numlines + 1;
              lineinfo.off[lineinfo.numlines] := oldposit
            end;
          lineinfo.off[lineinfo.numlines + 1] := length(x) + 1
        end
    end;

  Procedure getline(var f:text;var x:string;var endfile:boolean);

    var cnt:integer;

    begin
      if (cinpline = 51) then
        begin
          cinpline := 0;
          cnt := 0;
          while (not eof(f)) and (cnt < 15) do
            begin
              cnt := cnt + 1;
              readln(f)
            end;
        end;
      if not eof(f) then
        begin
          readln(f,x);
          if x = spaces(length(x)) then endfile := true
          else endfile := false;
          cinpline := cinpline + 1;
        end
      else endfile := true
    end;

  Procedure printline(var g:text;x:string;var lineinfo:lineinfotype);

    var cnt:integer;

    begin
      for cnt := 1 to lineinfo.numlines do
        begin
          if cnt > 1 then write(g,spaces(5));
          writeln(g,spaces(lineinfo.l)+copy(x,lineinfo.off[cnt]+1,lineinfo.off[cnt+1]-lineinfo.off[cnt]-1))
        end
    end;


  Procedure send(var filename:string;pagesize,linesize,left,right,top,bottom:integer;var g:text);

    var f:text;
        pageno,lineno,cnt:integer;
        linecont,heading,dividers:string;
        lineinfo:lineinfotype;
        endfile:boolean;

  begin
    assign(f,filename);
    reset(f);
    for cnt := 1 to 5 do readln(f);
    readln(f,heading);
    readln(f,dividers);
    cinpline := 0;
    getlineinfo(dividers,linesize,left,right,lineinfo);
    pageno := 1;
    for cnt := 1 to top do writeln(g);
    for cnt := 1 to linesize - 9 - right do write(g,' ');
    writeln(g,'Page: ',pageno);
    writeln(g);
    for cnt := 1 to lineinfo.numlines do
      begin
        if cnt > 1 then write(g,spaces(5));
        writeln(g,spaces(left)+copy(heading,lineinfo.off[cnt]+1,lineinfo.off[cnt+1]-lineinfo.off[cnt]-1));
        if cnt > 1 then write(g,spaces(5));
        writeln(g,spaces(left)+copy(dividers,lineinfo.off[cnt]+1,lineinfo.off[cnt+1]-lineinfo.off[cnt]-1))
      end;
    lineno := top + 3 + 2*lineinfo.numlines;
    endfile := false;
    while (not eof(f)) and (not endfile) do
      begin
        getline(f,linecont,endfile);
        if not endfile then
          begin
            printline(g,linecont,lineinfo);
            lineno := lineno + lineinfo.numlines;
            if lineno > pagesize - bottom - lineinfo.numlines + 1 then
              begin
                while (lineno < pagesize + 1) do
                  begin
                    writeln(g);
                    lineno := lineno + 1
                  end;
                for cnt := 1 to top do writeln(g);
                pageno := pageno + 1;
                for cnt := 1 to linesize - 9 - right do write(g,' ');
                writeln(g,'Page: ',pageno);
                writeln(g);
                for cnt := 1 to lineinfo.numlines do
                  begin
                    if cnt > 1 then write(g,spaces(5));
                    writeln(g,spaces(left)+copy(heading,lineinfo.off[cnt]+1,lineinfo.off[cnt+1]-lineinfo.off[cnt]-1));
                    if cnt > 1 then write(g,spaces(5));
                    writeln(g,spaces(left)+copy(dividers,lineinfo.off[cnt]+1,lineinfo.off[cnt+1]-lineinfo.off[cnt]-1))
                  end;
                lineno := top + 2 + 2*lineinfo.numlines + 1;
              end
          end
      end;
    while (lineno < pagesize + 1) do
      begin
        writeln(g);
        lineno := lineno + 1
      end;
    close(f)
  end;


  begin
    if paramstr(1) <> '' then
      begin
        val(paramstr(1),leftmarg,code);
        if (leftmarg < 0) or (leftmarg > 255) then leftmarg := DEFLEFT
      end
    else leftmarg := DEFLEFT;
    if paramstr(2) <> '' then
      begin
        val(paramstr(2),rightmarg,code);
        if (rightmarg < 0) or (rightmarg > 255) then rightmarg := DEFRIGHT
      end
    else rightmarg := DEFRIGHT;
    if paramstr(3) <> '' then
      begin
        val(paramstr(3),top,code);
        if (top < 0) or (top > 255) then top := DEFTOP
      end
    else top := DEFTOP;
    if paramstr(4) <> '' then
      begin
        val(paramstr(4),bottom,code);
        if (bottom < 0) or (bottom > 255) then bottom := DEFBOTTOM
      end
    else bottom := DEFBOTTOM;
    if paramstr(5) <> '' then
      begin
        val(paramstr(5),pagesize,code);
        if (pagesize < 0) or (pagesize > 255) then pagesize := DEFPAGESIZE
      end
    else pagesize := DEFPAGESIZE;
    if paramstr(6) <> '' then device := paramstr(6)
    else device := DEFDEVICE;
    if paramstr(7) <> '' then
      begin
        val(paramstr(7),linesize,code);
        if (linesize < 0) or (linesize > 255) then linesize := DEFLINESIZE
      end
    else linesize := DEFLINESIZE;
    repeat
      write('Enter file to print: ');
      getinput(temp,escpressed);
      writeln;
      writeln;
      if escpressed then exit;
      filevalid := fileexists(temp);
      if not filevalid then
        begin
          writeln(chr(7)+'Cannot find that file.');
          writeln
        end
    until filevalid;
    filename := temp;
    write('Number of copies: ');
    getinput(temp,escpressed);
    writeln;
    writeln;
    if escpressed then exit;
    val(temp,numcopies,code);
    write('Printing. . .');
    assign(g,device);
    rewrite(g);
    for cnt := 1 to numcopies do
      send(filename,pagesize,linesize,leftmarg,rightmarg,top,bottom,g);
    close(g);
    writeln;
    writeln;
    writeln('Printing completed.')
  end.
