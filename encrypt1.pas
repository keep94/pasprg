program encrypt;

  uses crt,dos,rand,IOunit;

  const MAXARRAY = 32760;
        MAXARRAY2 = 16380;
        SENTINAL  = 315926832;
        REMINDFILE = 'REGISMES.TXT';

  type arraytype = array[1..MAXARRAY] of byte;
       tabletype = array[0..255] of byte;
       paritytype = array[1..MAXARRAY2] of integer;
       parraytype = ^arraytype;
       ptrtype=^node;
       node=record
         data:searchrec;
         next:ptrtype
       end;


  var lastdir,username,userid,passkey,temp,path:string;
      subdir:dirstr;
      name:namestr;
      ext:extstr;
      subdirlen,filecount,error,errorcode:integer;
      done,escpressed:boolean;
      p,top:ptrtype;


  Function fileacc(filename:string):boolean;

    var f:file;
        numread,numwritten:word;
        error:integer;
        dummy:byte;
        dt:longint;

    begin
      error := 0;
      assign(f,filename);
      {$I-}
        reset(f,1);
      {$I+}
      error := IOresult;
      if error = 0 then
        begin
          {$I-}
            getftime(f,dt);
            seek(f,0);
            blockread(f,dummy,1,numread);
          {$I+}
          error := IOresult;
          if error = 0 then
            begin
              {$I-}
                seek(f,0);
                blockwrite(f,dummy,1,numwritten);
              {$I+}
              error := IOresult;
              if error = 0 then
                begin
                  {$I-}
                    setftime(f,dt);
                  {$I+}
                  error := IOresult
                end
            end;
          close(f)
        end;
      fileacc := (error = 0)
    end;


  Function minval(x,y:longint):longint;

    begin
      if y < x then minval := y
      else minval := x
    end;


  Procedure getcurdir(var x:string);

    var path:pathstr;
        d:dirstr;
        n:namestr;
        e:extstr;

    begin
      path := 'dummy.pas';
      path := fexpand(path);
      fsplit(path,d,n,e);
      if d[0]>chr(3) then d[0] := chr(ord(d[0])-1);
      x := d
    end;


  procedure encinput(var x:string;inplen:integer;var escpressed:boolean);

    var done:boolean;
        temp,stemp:char;
        cnt:integer;

    begin
      done := false;
      x := '';
      while (not done) do
        begin
          temp := readkey;
          if temp = chr(27) then
            begin
              done := true;
              escpressed := true
            end
          else if temp = chr(13) then
            begin
              done := true;
              escpressed := false
            end
          else if temp = chr(8) then
            begin
              if length(x) > 0 then
                begin
                  x := copy(x,1,length(x) - 1);
                  gotoxy(wherex - 1,wherey);
                  write(' ');
                  gotoxy(wherex - 1,wherey)
                end
            end
          else if temp = chr(0) then
            begin
              stemp := readkey;
              if stemp = chr(75) then
                begin
                  if length(x) > 0 then
                    begin
                      x := copy(x,1,length(x) - 1);
                      gotoxy(wherex - 1,wherey);
                      write(' ');
                      gotoxy(wherex - 1,wherey)
                    end
                end
            end
          else if length(x) < inplen then
            begin
              if (temp in ['0'..'9','A'..'Z','a'..'z']) then
                begin
                  x := x + temp;
                  write('X')
                end
            end
        end
    end;


  function pord(x:char):longint;

    begin
      if x in ['0'..'9'] then
        pord := ord(x) - 21
      else if x in ['A'..'Z'] then
        pord := ord(x) - 64
      else if x in ['a'..'z'] then
        pord := ord(x) - 96
      else pord := -1
    end;

  procedure getkeys(x:string;var ekey:longint;var ikey:integer);

    var cnt:integer;

    begin
      ekey := 0;
      ikey := 0;
      for cnt := 1 to 3 do
        ikey := ikey*37+pord(x[cnt]);
      for cnt := 4 to 9 do
        if cnt <= length(x) then ekey := ekey*37+pord(x[cnt])
        else ekey := ekey*37
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

  Procedure printauthor;

    begin
      write(codestr(chr(21)+chr(41)+chr(111)+chr(204)+chr(208)+chr(130)+
                    chr(223)+chr(126)+chr(108)+chr(225)+chr(145)+chr(99)+
                    chr(89)+chr(12)))
    end;

  procedure encriptseg(var x:arraytype;size:integer;var t:tabletype;var parity:integer);

    var cnt:integer;
        p:^paritytype;
        offset:byte;

    begin
      p := addr(x);
      for cnt := 1 to size div 2 do
        parity := parity xor p^[cnt];
      if (size mod 2 > 0) then parity := parity xor x[size];
      for cnt := 1 to size do
        begin
          offset := rnd;
          x[cnt] := byte(t[x[cnt]] + offset)
        end
    end;

  procedure encriptfile(filename:string;passkey:string;var errorcode:integer);

    var x:parraytype;
        t:tabletype;
        numread,numwritten:word;
        endfile,earmark,fsize,enckey,curpos,filetime:longint;
        error,signature,parity,code,parkey:integer;
        f:file;
        alreadyenc:boolean;

    begin
      getmem(x,MAXARRAY);
      getkeys(passkey,enckey,parkey);
      initrnd(enckey);
      gentable(t);
      assign(f,filename);
      reset(f,1);
      fsize := filesize(f);
      alreadyenc := false;
      if fsize >= 6 then
        begin
          seek(f,fsize-4);
          blockread(f,earmark,4,numread);
          alreadyenc := (earmark = SENTINAL);
          seek(f,0)
        end;
      if not alreadyenc then
        begin
          getftime(f,filetime);
          endfile := filesize(f);
          seek(f,endfile);
          {$I-}
            blockwrite(f,signature,2,numwritten);
            blockwrite(f,earmark,4,numwritten);
          {$I+}
          error := IOresult;
          if error <> 0 then
            begin
              seek(f,endfile);
              truncate(f);
              errorcode := 1
            end
          else
            begin
              seek(f,0);
              errorcode := 0;
              parity := 0;
              curpos := 0;
              while (curpos < endfile) do
                begin
                  blockread(f,x^,minval(MAXARRAY,endfile - curpos),numread);
                  encriptseg(x^,numread,t,parity);
                  seek(f,curpos);
                  blockwrite(f,x^,numread,numwritten);
                  curpos := curpos + numread
                end;
              signature := parity + parkey;
              earmark := SENTINAL;
              blockwrite(f,signature,2,numwritten);
              blockwrite(f,earmark,4,numwritten)
            end;
          setftime(f,filetime)
        end
      else errorcode := 2;
      close(f);
      freemem(x,MAXARRAY)
    end;

  Procedure getdirectory(path:string;var top:ptrtype);

    var bottom,p:ptrtype;
        error:integer;
        dirinfo:searchrec;

    begin
      top := nil;
      bottom := nil;
      findfirst(path,32,dirinfo);
      error := doserror;
      while error = 0 do
        begin
          new(p);
          p^.data := dirinfo;
          p^.next := nil;
          if top = nil then
            begin
              top := p;
              bottom := p
            end
          else
            begin
              bottom^.next := p;
              bottom := p
            end;
          findnext(dirinfo);
          error := doserror
        end
    end;

  Procedure cleardirectory(var top:ptrtype);

    var p,q:ptrtype;

    begin
      p := top;
      while p <> nil do
        begin
          q := p^.next;
          dispose(p);
          p := q
        end
    end;

  Procedure registrationinfo;

    var g:text;
        curline:string;

    begin
      clrscr;
      if not fileexists(REMINDFILE) then
        begin
          writeln(chr(7)+'Cannot find '+REMINDFILE);
          halt
        end;
      assign(g,REMINDFILE);
      reset(g);
      write(chr(7));
      while not eof(g) do
        begin
          readln(g,curline);
          writeln(curline)
        end;
      writeln;
      write('Written by: ');
      printauthor;
      gotoxy(1,24);
      write('Press ENTER to continue: ':52);
      readln;
      clrscr
    end;


  begin
    userid := '1234567890';
    username := '12345678901234567890';
    if codestr(copy(userid,6,5)) <> chr(130)+chr(14)+chr(234)+chr(11)+chr(7) then
      registrationinfo
    else
      begin
        write('Written by: ');
        printauthor;
        writeln;
        writeln('This copy licensed to: '+username);
        writeln
      end;
    write('Enter files to encrypt: ');
    getinput(temp,escpressed);
    writeln;
    writeln;
    if escpressed then exit;
    fsplit(temp,subdir,name,ext);
    subdirlen := length(subdir);
    if subdirlen > 3 then
      if subdir[subdirlen] = '\' then
        subdir := copy(subdir,1,subdirlen-1);
    path := name+ext;
    repeat
      repeat
        write('Enter encryption key: ');
        encinput(temp,9,escpressed);
        writeln;
        writeln;
        if escpressed then exit;
        caps(temp);
        if length(temp) < 4 then
          begin
            writeln(chr(7)+'Encryption key must be at least 4 characters.');
            writeln
          end
      until length(temp) >= 4;
      passkey := temp;
      write('Verification: ');
      encinput(temp,9,escpressed);
      writeln;
      writeln;
      if escpressed then exit;
      caps(temp);
      if passkey <> temp then
        begin
          writeln(chr(7)+'Encryption key was retyped incorrectly.');
          writeln
        end
    until passkey = temp;
    getcurdir(lastdir);
    {$I-}
      chdir(subdir);
    {$I+}
    error := IOresult;
    if error <> 0 then
      begin
        writeln(chr(7)+'Path does not exist.');
        exit
      end;
    getdirectory(path,top);
    p := top;
    done := false;
    filecount := 0;
    while (p <> nil) and (not done) do
      begin
        if p^.data.size > 0 then
          begin
            if fileacc(p^.data.name) then
              begin
                encriptfile(p^.data.name,passkey,errorcode);
                if errorcode = 0 then
                  begin
                    writeln(fexpand(p^.data.name)+' encrypted successfully.');
                    filecount := filecount + 1
                  end
                else if errorcode = 2 then
                  writeln(fexpand(p^.data.name)+' is already encrypted.')
                else if errorcode = 1 then
                  begin
                    writeln('Disk is full.');
                    done := true
                  end
              end
            else writeln('Access denied to '+fexpand(p^.data.name))
          end
        else writeln(fexpand(p^.data.name)+' is empty.');
        p := p^.next
      end;
    writeln;
    writeln(filecount,' files encrypted successfully.');
    {$I-}
      chdir(lastdir);
    {$I+}
    cleardirectory(top)
  end.