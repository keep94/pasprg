program printcopies;

  uses IOunit;

  const
    DEFLEFT = 3;
    DEFTOP = 2;
    DEFBOTTOM = 2;
    DEFPAGESIZE = 60;
    DEFDEVICE = 'lpt1';

  var
    code,leftmarg,top,bottom,pagesize,numcopies,cnt:integer;
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


  Procedure send(var filename:string;pagesize,left,top,bottom:integer;var g:text);

    var f:text;
        lineno,cnt:integer;
        linecont:string;

  begin
    assign(f,filename);
    reset(f);
    for cnt := 1 to top do writeln(g);
    lineno := top + 1;
    while not eof(f) do
      begin
        readln(f,linecont);
        writeln(g,spaces(left)+linecont);
        lineno := lineno + 1;
        if lineno > pagesize - bottom then
          begin
            if bottom > 0 then write(g,chr(12));
            for cnt := 1 to top do writeln(g);
            lineno := top + 1
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
        val(paramstr(2),top,code);
        if (top < 0) or (top > 255) then top := DEFTOP
      end
    else top := DEFTOP;
    if paramstr(3) <> '' then
      begin
        val(paramstr(3),bottom,code);
        if (bottom < 0) or (bottom > 255) then bottom := DEFBOTTOM
      end
    else bottom := DEFBOTTOM;
    if paramstr(4) <> '' then
      begin
        val(paramstr(4),pagesize,code);
        if (pagesize < 0) or (pagesize > 255) then pagesize := DEFPAGESIZE
      end
    else pagesize := DEFPAGESIZE;
    if paramstr(5) <> '' then device := paramstr(5)
    else device := DEFDEVICE;
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
      send(filename,pagesize,leftmarg,top,bottom,g);
    close(g);
    writeln;
    writeln;
    writeln('Printing completed.')
  end.
