program printaddresses;

  uses crt,IOunit;

  const
    ADDRSIZE = 133;
    SIZEFIRST = 15;
    SIZELAST = 20;
    SIZEADR1 = 30;
    SIZEADR2 = 30;
    SIZECITY = 15;
    SIZESTATE = 5;
    SIZEZIP = 10;

  type
    custrectype=record
      marked:boolean;
      last:string[SIZELAST];
      first:string[SIZEFIRST];
      adr1:string[SIZEADR1];
      adr2:string[SIZEADR2];
      city:string[SIZECITY];
      state:string[SIZESTATE];
      zip:string[SIZEZIP]
    end;

  var
    temp,filename:string;
    markedonly:boolean;
    error,code,numlines:integer;
    recsize:word;
    g:text;
    escpressed:boolean;
    response:char;


  Procedure printlabels(var g:text;filename:string;markedonly:boolean;numlines:integer;recsize:longint);

    var f:file;
        cnt,numrecs:longint;
        linesprin,cnt1:integer;
        done:boolean;
        currec:custrectype;
        dummy:char;
        numread:word;

    begin
      assign(f,filename);
      reset(f,1);
      numrecs := filesize(f) div recsize;
      cnt := 0;
      done := false;
      while (cnt < numrecs) and (not done) do
        begin
          seek(f,cnt*recsize);
          blockread(f,currec,ADDRSIZE,numread);
          if (not markedonly) or (currec.marked) then
            begin
              if currec.first <> '' then writeln(g,currec.first+' '+currec.last)
              else writeln(g,currec.last);
              writeln(g,currec.adr1);
              if currec.adr2 <> '' then
                begin
                  linesprin := 4;
                  writeln(g,currec.adr2)
                end
              else linesprin := 3;
              writeln(g,currec.city+', '+currec.state+'  '+currec.zip);
              for cnt1 := linesprin + 1 to numlines do writeln(g)
            end;
          if keypressed then
            begin
              dummy := readkey;
              if dummy = chr(27) then done := true
              else if dummy = chr(0) then dummy := readkey
            end;
          cnt := cnt + 1
        end;
      close(f)
    end;



  begin
    write('Print labels from what file? ');
    getinput(filename,escpressed);
    writeln;
    writeln;
    if escpressed then exit;
    if not fileexists(filename) then
      begin
        writeln(chr(7)+'Cannot find that file.');
        exit
      end;
    write('Record length: ');
    getinput(temp,escpressed);
    writeln;
    writeln;
    if escpressed then exit;
    val(temp,recsize,code);
    if (recsize < ADDRSIZE) or (not filevalid(filename,recsize)) then
      begin
        writeln(chr(7)+'Record size entered is incorrect.');
        exit
      end;
    write('Number of lines per label: ');
    getinput(temp,escpressed);
    writeln;
    writeln;
    if escpressed then exit;
    val(temp,numlines,code);
    if numlines < 4 then numlines := 6;
    write('Print labels for marked records only? ');
    getinput(temp,escpressed);
    writeln;
    writeln;
    if escpressed then exit;
    if length(temp) >= 1 then markedonly := (temp[1] in ['Y','y'])
    else markedonly := false;
    write('Send output to: ');
    getinput(temp,escpressed);
    writeln;
    writeln;
    if escpressed then exit;
    caps(temp);
    if temp <> 'LPT1' then
      if fileexists(temp) then
        begin
          write('That file already exists.  Overwrite? ');
          readln(response);
          writeln;
          if not (response in ['Y','y']) then exit
        end;
    assign(g,temp);
    {$I-}
      rewrite(g);
    {$I+}
    error := IOresult;
    if error = 0 then
      begin
        write('Press ESC to stop printing.');
        printlabels(g,filename,markedonly,numlines,recsize);
        close(g)
      end
    else
      writeln(chr(7)+'File creation error.')
  end.