program findit;

  const FILENAME = 'unencript.exe';
        STRSIZE = 10;
        STR = '1234567890';

  var f:file;
      curpos,filelength:longint;
      regno:string;
      numread:word;

  begin
    assign(f,FILENAME);
    reset(f,1);
    curpos := 0;
    filelength := filesize(f);
    while curpos <= filelength - STRSIZE - 1 do
      begin
        seek(f,curpos);
        blockread(f,regno,STRSIZE + 1,numread);
        if regno = STR then writeln('Position: ',curpos);
        if not (regno[STRSIZE] in ['0'..'9']) then curpos := curpos + STRSIZE
        else curpos := curpos + 1
      end;
    close(f)
  end.