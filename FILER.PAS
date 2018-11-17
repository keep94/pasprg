Program filer;

  uses dos,crt;

  const toplineconst = 4;
        maxline = 15;


  type arraytype = array[0..65519] of byte;
       screentype=^arraytype;
       keytype=array[1..8] of char;
       tabletype=array[0..255] of byte;
       settype=set of byte;
       ptrtype=^node;
       node=record
         data:searchrec;
         flag:boolean;
         next:ptrtype;
         back:ptrtype
       end;
       posittype=record
         num:word;
         ptr:ptrtype
       end;

  var done,nofile,escpressed:boolean;
      cdir,path,x:string;
      response,ch,schoice:char;
      fileattr,size:word;
      top:ptrtype;
      posit:posittype;
      error,code:integer;
      seed:real;
      passloc:longint;
      table:tabletype;
      passkey:keytype;
      f:file;

  Procedure pause;

    var dummy:char;

    begin
      dummy := readkey;
      if dummy = chr(0) then dummy := readkey
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

    var p:screentype;
        cnt:word;

    begin
      p := addr(obj);
      for cnt := 0 to size - 1 do
        begin
          p^[cnt] := table[p^[cnt]]+table[start];
          start := start + 1
        end
    end;

  Procedure clearheading;

    var cnt:word;

    begin
      gotoxy(1,1);
      for cnt := 1 to 2 do write(' ':80)
    end;

  Procedure displaymessage(x:string);

    begin
      clearheading;
      gotoxy(1,1);
      write(x)
    end;

  Procedure usermessage(x:string);

    begin
      clearheading;
      displaymessage(chr(7)+x);
      pause
    end;

  Procedure cleardisplay;

    var cnt:word;

    begin
      gotoxy(1,toplineconst);
      for cnt := 1 to maxline do
        write('':80)
    end;

  Function gety(x:word):word;

    begin
      gety := (x-1) mod maxline + toplineconst
    end;

  Procedure printheading(var cdir,path:string;size:word);

    var cnt:word;

    begin
      clearheading;
      gotoxy(1,1);
      write('Path: ',path);
      gotoxy(60,1);
      write(size,' FILES');
      gotoxy(1,2);
      write('Directory: ',cdir);
      writeln;
      for cnt := 1 to 80 do write(chr(196))
    end;

  Procedure getinput(var x:string;var escpressed:boolean);

    var done:boolean;
        temp:char;

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
          else if wherex < 80 then
            begin
              x := x + temp;
              write(temp)
            end
        end
    end;

  Procedure displayline(p:ptrtype);

    var sc:screentype;
        ycoord,cnt:word;

    begin
      sc := ptr($b800,$0);
      ycoord := wherey;
      for cnt := 1 to 80 do
        sc^[ycoord*160-162+2*cnt] := 32;
      if p^.flag then write(chr(16))
      else write(chr(32));
      if p^.data.attr and 16 = 16 then write('\');
      write(p^.data.name);
      gotoxy(15,wherey);
      write(p^.data.size:10);
      write(' ');
      write(p^.data.attr:5);
      writeln
    end;

  Procedure getfiles(var path:string;var top:ptrtype;var size:word);

    var error:integer;
        dirinfo:searchrec;

    Function compare(x,y:searchrec):integer;

      begin
        if (x.attr and 16 <> y.attr and 16) then
          begin
            if (x.attr and 16 = 16) then compare := 1
            else compare := -1
          end
        else
          begin
            if x.name < y.name then compare := 1
            else if x.name = y.name then compare := 0
            else compare := -1
          end
      end;

    Procedure insert(var top:ptrtype;var dirinfo:searchrec);

      var p,q,r:ptrtype;
          done:boolean;

      begin
        if top = nil then
          begin
            new(top);
            top^.data := dirinfo;
            top^.next := nil;
            top^.back := nil;
            top^.flag := false
          end
        else
          begin
            done := false;
            p := top;
            while (p<>nil) and (not done) do
              begin
                if compare(dirinfo,p^.data) = 1 then
                  begin
                    done := true;
                    new(q);
                    q^.data := dirinfo;
                    q^.flag := false;
                    if p^.back<>nil then p^.back^.next := q
                    else top := q;
                    q^.back := p^.back;
                    q^.next := p;
                    p^.back := q
                  end
                else
                  begin
                    if p^.next = nil then r := p;
                    p := p^.next
                  end
              end;
            if (not done) then
              begin
                new(q);
                q^.data := dirinfo;
                q^.flag := false;
                q^.back := r;
                r^.next := q;
                q^.next := nil
              end
          end
      end;

    begin
      top := nil;
      size := 0;
      findfirst(path,63,dirinfo);
      error := doserror;
      while error = 0 do
        begin
          size := size + 1;
          insert(top,dirinfo);
          findnext(dirinfo);
          error := doserror
        end
    end;

  Procedure clearmemory(var top:ptrtype);

    var p,q:ptrtype;

    begin
      p := top;
      while (p<>nil) do
        begin
          q := p^.next;
          dispose(p);
          p := q
        end;
      top := nil
    end;

  Procedure getdirectory(var x:string);

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

  Procedure highlight(posit:word);

    var p:screentype;
        cnt:word;

    begin
      p := ptr($b800,$0);
      for cnt := 2 to 80 do p^[posit*160-161+2*cnt] := 112
    end;

  Procedure unhighlight(posit:word);

    var p:screentype;
        cnt:word;

    begin
      p := ptr($b800,$0);
      for cnt := 2 to 80 do p^[posit*160-161+2*cnt] := 7
    end;

  Procedure printnofile;

    var cnt:word;

    begin
      cleardisplay;
      gotoxy(1,toplineconst);
      write('File not found.')
    end;

  Procedure displayfiles(var posit:posittype);

    var scrloc,cnt:word;
        p:ptrtype;

    begin
      cleardisplay;
      scrloc := gety(posit.num);
      p := posit.ptr;
      for cnt := scrloc downto toplineconst+1 do p := p^.back;
      gotoxy(1,toplineconst);
      for cnt := 1 to maxline do
        if p<>nil then
          begin
            displayline(p);
            p := p^.next
          end;
      highlight(scrloc)
    end;

  Procedure init(var path:string;var cdir:string;var top:ptrtype;var posit:posittype;var size:word;var nofile:boolean);

    begin
      clearmemory(top);
      getdirectory(cdir);
      getfiles(path,top,size);
      if size = 0 then
        begin
          printnofile;
          nofile := true
        end
      else
        begin
          nofile := false;
          posit.num := 1;
          posit.ptr := top;
          displayfiles(posit)
        end
    end;

  Procedure moveup(var posit:posittype);

    var scrloc:word;

    begin
      if posit.num>1 then
        begin
          scrloc := gety(posit.num);
          posit.num := posit.num - 1;
          posit.ptr := posit.ptr^.back;
          if scrloc = toplineconst then
            displayfiles(posit)
          else
            begin
              unhighlight(scrloc);
              highlight(scrloc-1)
            end
        end
    end;

  Procedure movedown(var posit:posittype);

    var scrloc:word;

    begin
      if posit.ptr^.next <> nil then
        begin
          scrloc := gety(posit.num + 1);
          posit.num := posit.num + 1;
          posit.ptr := posit.ptr^.next;
          if scrloc=toplineconst then
            displayfiles(posit)
          else
            begin
              unhighlight(scrloc-1);
              highlight(scrloc)
            end
        end
    end;

  Procedure pageup(var posit:posittype);

    var cnt:word;

    begin
      cnt := 0;
      while (posit.num >1) and (cnt<maxline) do
        begin
          posit.num := posit.num - 1;
          posit.ptr := posit.ptr^.back;
          cnt := cnt+1
        end;
      displayfiles(posit)
    end;

  Procedure pagedown(var posit:posittype);

    var cnt:word;

    begin
      cnt := 0;
      while (posit.ptr^.next<>nil) and (cnt<maxline) do
        begin
          posit.num := posit.num + 1;
          posit.ptr := posit.ptr^.next;
          cnt := cnt + 1
        end;
      displayfiles(posit)
    end;

  Procedure toggle(var posit:posittype);

    begin
      posit.ptr^.flag := posit.ptr^.flag xor true;
      gotoxy(1,gety(posit.num));
      unhighlight(gety(posit.num));
      displayline(posit.ptr);
      highlight(gety(posit.num))
    end;

  Procedure markall(top:ptrtype;var posit:posittype);

    var p:ptrtype;

    begin
      p := top;
      while p<>nil do
        begin
          p^.flag := true;
          p := p^.next
        end;
      displayfiles(posit)
    end;

  Procedure unmarkall(top:ptrtype;var posit:posittype);

    var p:ptrtype;

    begin
      p := top;
      while p<>nil do
        begin
          p^.flag := false;
          p := p^.next
        end;
      displayfiles(posit)
    end;

  Procedure update(top:ptrtype;var posit:posittype;newattr:word);

    var p:ptrtype;
        f:file;
        dummy:word;

    begin
      p := top;
      while p<>nil do
        begin
          if p^.flag then
            begin
              if p^.data.name[1] <> '.' then
                begin
                  assign(f,p^.data.name);
                  setfattr(f,newattr);
                  getfattr(f,dummy);
                  p^.data.attr := dummy
                end
            end;
          p := p^.next
        end;
      displayfiles(posit)
    end;

  Procedure eraseupdate(top:ptrtype);

    var p:ptrtype;
        f:file;
        error:integer;

    begin
      p := top;
      while p<>nil do
        begin
          if (p^.flag) then
            begin
              assign(f,p^.data.name);
              {$I-}
                erase(f);
              {$I+}
              error := IOresult
            end;
          p := p^.next
        end
    end;

  begin
    passloc := 5052;
    seed := 0.31;
    gettable(table);
    write('Password: ');
    getkey(passkey);
    writeln;
    encript(passkey,sizeof(passkey),passloc,table);
    if passkey <> 'aardvark' then
      begin
        writeln('Access denied');
        exit
      end;
    done := false;
    clrscr;
    path := '*.*';
    top := nil;
    init(path,cdir,top,posit,size,nofile);
    printheading(cdir,path,size);
    repeat
      ch := readkey;
      case ch of
        chr(13):if not nofile then toggle(posit);
        chr(32):if (not nofile) and (posit.ptr^.data.attr and 16 = 16) then
                  begin
                    {$I-}
                      chdir(posit.ptr^.data.name);
                    {$I-}
                    error := IOresult;
                    init(path,cdir,top,posit,size,nofile);
                    printheading(cdir,path,size)
                  end;
        chr(0):begin
                 schoice := readkey;
                 case schoice of
        chr(45):begin
                 displaymessage('Are you sure you want to exit<y,n>? ');
                 readln(response);
                 if response in ['Y','y'] then done := true;
                 printheading(cdir,path,size)
                end;
        chr(60):begin
                  displaymessage('Enter new directory: ');
                  getinput(x,escpressed);
                  if not escpressed then
                    begin
                      {$I-}
                        chdir(x);
                      {$I+}
                      error := IOresult;
                      init(path,cdir,top,posit,size,nofile)
                    end;
                  printheading(cdir,path,size)
                end;
        chr(61):begin
                  displaymessage('Enter new path: ');
                  getinput(x,escpressed);
                  if not escpressed then
                    begin
                      path := x;
                      init(path,cdir,top,posit,size,nofile)
                    end;
                  printheading(cdir,path,size)
                end;
        chr(62):if (not nofile) then
                 begin
                  displaymessage('Enter attribute: ');
                  getinput(x,escpressed);
                  if not escpressed then
                    begin
                      val(x,fileattr,code);
                      fileattr := fileattr mod 256;
                      update(top,posit,fileattr)
                    end;
                  printheading(cdir,path,size)
                end;
        chr(63):if (not nofile) then markall(top,posit);
        chr(64):if (not nofile) then unmarkall(top,posit);
        chr(65):if (not nofile) then
                  begin
                    displaymessage('Erase files<y,n>? ');
                    readln(response);
                    if response in ['Y','y'] then
                      begin
                        eraseupdate(top);
                        init(path,cdir,top,posit,size,nofile)
                      end;
                    printheading(cdir,path,size)
                  end;
        chr(66):if (not nofile) then
                  begin
                    displaymessage('Enter new name for file: ');
                    getinput(x,escpressed);
                    if not escpressed then
                      begin
                        assign(f,posit.ptr^.data.name);
                        {$I-}
                          rename(f,x);
                        {$I-}
                        error := IOresult;
                        if error = 0 then init(path,cdir,top,posit,size,nofile)
                      end;
                    printheading(cdir,path,size)
                  end;
        chr(72):if (not nofile) then moveup(posit);
        chr(73):if (not nofile) then pageup(posit);
        chr(80):if (not nofile) then movedown(posit);
        chr(81):if (not nofile) then pagedown(posit);
      end
      end
      end
    until done;
   clrscr
  end.