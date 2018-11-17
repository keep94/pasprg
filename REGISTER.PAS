program register;

  uses dos,crt,IOunit,rand;

  const
    ENCPROGNAME = 'ENCRYPT.EXE';
    UNENCPROGNAME = 'UNENCRYP.EXE';
    ENREGNAMELOC = 5012;
    ENREGNUMLOC = 5001;
    UNENREGNAMELOC = 5134;
    UNENREGNUMLOC = 5123;
    NAMELEN = 20;
    IDLEN = 10;

  type
    tabletype = array[0..255] of byte;

  var
    f:file;
    response,progreg,username,userreg:string;
    numread,numwritten:word;
    escpressed:boolean;
    filetime:longint;

  function spaces(x:integer):string;

    var temp:string;
        cnt:integer;

    begin
      temp := '';
      for cnt := 1 to x do
        temp := temp + ' ';
      spaces := temp
    end;

  procedure gentable(var t:tabletype);

    var cnt:integer;
        pos,temp:byte;

    begin
      for cnt := 0 to 255 do
        t[cnt] := cnt;
      for cnt := 256 downto 2 do
        begin
          setmax(cnt);
          pos := longrnd;
          temp := t[cnt - 1];
          t[cnt - 1] := t[pos];
          t[pos] := temp
        end
    end;

  function codestr(x:string):string;

    var cnt:integer;
        offset:byte;
        lastseed:rndinfotype;
        pt:tabletype;

    begin
      getrndstat(lastseed);
      initrnd(925241837);
      gentable(pt);
      for cnt := 1 to length(x) do
        begin
          offset := rnd;
          x[cnt] := chr((pt[ord(x[cnt])] + offset) mod 256)
        end;
      codestr := x;
      setrndstat(lastseed)
    end;

  begin
    clrscr;
    repeat
      write('Enter your name (20 characters max): ');
      getinput(username,escpressed);
      writeln;
      writeln;
      if escpressed then exit;
      write('Is your name correct<y,n>? ');
      getinput(response,escpressed);
      writeln;
      writeln;
      if escpressed then exit;
    until (length(response) >= 1) and (response[1] in ['Y','y']);
    if length(username) > NAMELEN then username := copy(username,1,NAMELEN);
    username := username + spaces(NAMELEN - length(username));
    write('Enter your registration number: ');
    getinput(userreg,escpressed);
    writeln;
    writeln;
    if escpressed then exit;
    if length(userreg) > IDLEN then userreg := copy(userreg,1,IDLEN);
    userreg := userreg + spaces(IDLEN - length(userreg));
    if not fileexists(ENCPROGNAME) then
      writeln(chr(7)+'Cannot find '+ENCPROGNAME+'.')
    else
      begin
        assign(f,ENCPROGNAME);
        reset(f,1);
        seek(f,ENREGNUMLOC);
        blockread(f,progreg,IDLEN + 1,numread);
        if codestr(copy(progreg,6,5)) = chr(130)+chr(14)+chr(234)+chr(11)+chr(7) then
          writeln(chr(7)+ENCPROGNAME+' is already registered.')
        else
          begin
            if codestr(copy(userreg,6,5)) <> chr(130)+chr(14)+chr(234)+chr(11)+chr(7) then
              begin
                writeln(chr(7)+'The registration number that you entered is invalid.');
                close(f);
                exit
              end
            else
              begin
                getftime(f,filetime);
                seek(f,ENREGNAMELOC);
                blockwrite(f,username,NAMELEN + 1,numwritten);
                seek(f,ENREGNUMLOC);
                blockwrite(f,userreg,IDLEN + 1,numwritten);
                setftime(f,filetime)
              end
          end;
        close(f)
      end;
    if not fileexists(UNENCPROGNAME) then
      writeln(chr(7)+'Cannot find '+UNENCPROGNAME+'.')
    else
      begin
        assign(f,UNENCPROGNAME);
        reset(f,1);
        seek(f,UNENREGNUMLOC);
        blockread(f,progreg,IDLEN + 1,numread);
        if codestr(copy(progreg,6,5)) = chr(130)+chr(14)+chr(234)+chr(11)+chr(7) then
          writeln(chr(7)+UNENCPROGNAME+' is already registered.')
        else
          begin
            if codestr(copy(userreg,6,5)) <> chr(130)+chr(14)+chr(234)+chr(11)+chr(7) then
              begin
                writeln(chr(7)+'The registration number that you entered is invalid.');
                close(f);
                exit
              end
            else
              begin
                getftime(f,filetime);
                seek(f,UNENREGNAMELOC);
                blockwrite(f,username,NAMELEN + 1,numwritten);
                seek(f,UNENREGNUMLOC);
                blockwrite(f,userreg,IDLEN + 1,numwritten);
                setftime(f,filetime)
              end
          end;
        close(f)
      end
  end.