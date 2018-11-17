program setpass;

  uses crt,dos;

  type keytype = array[1..8] of char;
       arraytype = array[0..65519] of byte;
       ptrtype = ^arraytype;
       tabletype = array[0..255] of byte;
       settype = set of byte;

  var seed:real;
      table:tabletype;
      oldpass,newpass,retyped,actual:keytype;
      passloc,whattime:longint;
      f:file;
      numread,numwritten:word;

  Function fileexists(filename:string):boolean;

    var f:file;
        error:integer;

    begin
      assign(f,filename);
      {$I-}
        reset(f);
      {$I+}
      error := IOresult;
      if error = 0 then
        begin
          close(f);
          fileexists := true
        end
      else fileexists := false
    end;

  Function myrandom:real;

    begin
      seed := sqr(seed+9.980537215) - trunc(sqr(seed+9.980537215));
      myrandom := seed
    end;

  Procedure gettable(var table:tabletype);

    var taken:settype;
        cnt,code:byte;

    begin
      taken := [];
      for cnt := 0 to 255 do
        begin
          code := trunc(myrandom*256);
          while (code in taken) do code := code + 1;
          table[cnt] := code;
          taken := taken + [code]
        end
    end;

  Procedure getkey(var key:keytype);

    var done:boolean;
        cnt:integer;
          c:char;

    Procedure initializekey(var key:keytype);

      begin
        key[1] := chr(40);
        key[2] := chr(203);
        key[3] := chr(7);
        key[4] := chr(54);
        key[5] := chr(149);
        key[6] := chr(248);
        key[7] := chr(73);
        key[8] := chr(177)
      end;

    begin
      initializekey(key);
      cnt := 0;
      done := false;
      while (not done) do
        begin
          c := readkey;
          if cnt < 8 then
            begin
              cnt := cnt + 1;
              key[cnt] := c
            end;
          if c = chr(13) then done := true
        end
    end;

  Procedure encript(var obj;size:word;start:byte;var table:tabletype);

    var p:ptrtype;
        cnt:word;

    begin
      p := addr(obj);
      for cnt := 0 to size - 1 do
        begin
          p^[cnt] := table[p^[cnt]]+table[start];
          start := start + 1
        end
    end;

  begin
    seed := 0.31;
    gettable(table);
    passloc := 5052;
    write('Enter old password: ');
    getkey(oldpass);
    writeln;
    write('Enter new password: ');
    getkey(newpass);
    writeln;
    write('Retype new password: ');
    getkey(retyped);
    writeln;
    encript(oldpass,sizeof(oldpass),passloc,table);
    encript(newpass,sizeof(newpass),passloc,table);
    encript(retyped,sizeof(retyped),passloc,table);
    if not fileexists('filer.exe') then
      begin
        writeln('Cannot find FILER.EXE');
        exit
      end;
    assign(f,'filer.exe');
    reset(f,1);
    getftime(f,whattime);
    seek(f,passloc);
    blockread(f,actual,sizeof(actual),numread);
    if actual <> oldpass then
      begin
        writeln('Access denied -- password has not been changed.');
        close(f);
        exit
      end;
    if newpass <> retyped then
      begin
        writeln('Password retyped incorrectly.  Password has not been changed.');
        close(f);
        exit
      end;
    seek(f,passloc);
    blockwrite(f,newpass,sizeof(newpass),numwritten);
    setftime(f,whattime);
    close(f);
    writeln('Password has been changed.')
  end.
