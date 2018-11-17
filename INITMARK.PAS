program initmark;

  uses IOunit;

  var
    dummy:longint;
    dummyarray:array[1..30] of byte;
    temp,mainfile,markfile,idfile:string;
    cnt,recsize,recidloc,code:integer;
    escpressed,newrec:boolean;
    f,g:file;
    numread,numwritten:word;
    response:char;

  begin
    write('Enter marked records file: ');
    getinput(markfile,escpressed);
    writeln;
    if escpressed then exit;
    if not fileexists(markfile) then
      begin
        write('Cannot find that file.  Create a new one<y,n>? ');
        readln(response);
        if response in ['Y','y'] then
          begin
            assign(f,markfile);
            rewrite(f,1);
            for cnt := 1 to 30 do dummyarray[cnt] := 0;
            blockwrite(f,dummyarray,30,numwritten)
          end
        else exit
      end
    else
      begin
        assign(f,markfile);
        reset(f,1)
      end;
    seek(f,4);
    blockread(f,mainfile,13,numread);
    write('Enter data base file ['+mainfile+']: ');
    getinput(temp,escpressed);
    writeln;
    if escpressed then
      begin
        close(f);
        exit
      end;
    caps(temp);
    if temp <> '' then mainfile := temp;
    blockread(f,idfile,13,numread);
    write('Enter record ID file ['+idfile+']: ');
    getinput(temp,escpressed);
    writeln;
    if escpressed then
      begin
        close(f);
        exit
      end;
    caps(temp);
    if temp <> '' then idfile := temp;
    seek(f,0);
    blockread(f,recsize,2,numread);
    write('Enter record size [',recsize,']: ');
    getinput(temp,escpressed);
    writeln;
    if escpressed then
      begin
        close(f);
        exit
      end;
    if temp <> '' then val(temp,recsize,code);
    blockread(f,recidloc,2,numread);
    write('Enter record ID field position [',recidloc,']: ');
    getinput(temp,escpressed);
    writeln;
    if escpressed then
      begin
        close(f);
        exit
      end;
    if temp <> '' then val(temp,recidloc,code);
    if not fileexists(idfile) then
      begin
        assign(g,idfile);
        rewrite(g,1);
        dummy := 0;
        blockwrite(g,dummy,4,numwritten);
        close(g)
      end;
    seek(f,0);
    blockwrite(f,recsize,2,numwritten);
    blockwrite(f,recidloc,2,numwritten);
    blockwrite(f,mainfile,13,numwritten);
    blockwrite(f,idfile,13,numwritten);
    close(f)
  end.
