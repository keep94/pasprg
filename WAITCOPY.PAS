Program waitcopy;

  uses dos;

  type
    rectype=record
      name:string[12];
      size:longint;
      time:longint
    end;


    ptrtype=^node;
    node=record
      data:rectype;
      next:ptrtype
    end;

    marktype = record
      fileptr:ptrtype;
      offset:longint
    end;

  arraytype=array[0..65519] of byte;

  segptrtype = ^arraytype;

  buffertype = record
    size:longint;
    ptr:array[0..15] of segptrtype
  end;

  var
    b:buffertype;
    start,current:marktype;
    top,bottom:ptrtype;
    sourcedir,destdir:dirstr;
    name:namestr;
    ext:extstr;
    posit,memleft,bufsize,amtread:longint;
    code,subdirlen:integer;
    path:string;
    f:file;



  Function min(x,y:longint):longint;

    begin
      if x > y then min := y
      else min := x
    end;

  Procedure initbuffer(var b:buffertype;size:longint);

    var cnt:integer;
        lastblocknum:longint;
        lastblocksize:word;

    begin
      b.size := size;
      for cnt := 1 to size div 65520 do
        getmem(b.ptr[cnt-1],65520);
      lastblocknum := size div 65520;
      lastblocksize := size - 65520*lastblocknum;
      if lastblocksize > 0 then getmem(b.ptr[lastblocknum],lastblocksize)
    end;


  Procedure freebuffer(var b:buffertype);

    var cnt:integer;
        lastblocknum:longint;
        lastblocksize:word;

    begin
      for cnt := 1 to b.size div 65520 do
        freemem(b.ptr[cnt-1],65520);
      lastblocknum := b.size div 65520;
      lastblocksize := b.size - 65520*lastblocknum;
      if lastblocksize > 0 then freemem(b.ptr[lastblocknum],lastblocksize)
    end;


  Procedure superread(var f:file;var b:buffertype;start,size:longint);

    var segment:integer;
        numread,offset:word;

    begin
      segment := start div 65520;
      offset := start mod 65520;
      while (size > 0) do
        begin
          blockread(f,b.ptr[segment]^[offset],min(size,65520-offset),numread);
          size := size - min(size,65520-offset);
          if size > 0 then
            begin
              offset := 0;
              segment := segment + 1
            end
        end
    end;

  Procedure superwrite(var f:file;var b:buffertype;start,size:longint);

    var segment:integer;
        numwritten,offset:word;

    begin
      segment := start div 65520;
      offset := start mod 65520;
      while (size > 0) do
        begin
          blockwrite(f,b.ptr[segment]^[offset],min(size,65520-offset),numwritten);
          size := size - min(size,65520-offset);
          if size > 0 then
            begin
              offset := 0;
              segment := segment + 1
            end
        end
    end;


  Procedure Addfile(var top,bottom:ptrtype;var dirinfo:searchrec);

    var p:ptrtype;

    begin
      new(p);
      p^.data.name := dirinfo.name;
      p^.data.size := dirinfo.size;
      p^.data.time := dirinfo.time;
      p^.next := nil;
      if (top = nil) then
        begin
          top := p;
          bottom := p
        end
      else
        begin
          bottom^.next := p;
          bottom := p
        end
    end;

  Function numfiles(top,bottom:ptrtype):integer;

    var cnt:integer;
        p:ptrtype;

    begin
      p := top;
      cnt := 0;
      while (p <> nil) do
        begin
          cnt := cnt + 1;
          p := p^.next
        end;
      numfiles := cnt
    end;


  Procedure clearlist(var top,bottom:ptrtype);

    var p,q:ptrtype;

    begin
      p := top;
      while (p <> nil) do
        begin
          q := p^.next;
          dispose(p);
          p := q
        end;
      top := nil;
      bottom := nil
    end;


  Procedure Getfilenames(var top,bottom:ptrtype;path:string);

    var dirinfo:searchrec;

    begin
      top := nil;
      bottom := nil;
      findfirst(path,archive,dirinfo);
      while DosError = 0 do
        begin
          addfile(top,bottom,dirinfo);
          findnext(dirinfo)
        end
    end;


  begin
    if (paramstr(1) = '') or (paramstr(2) = '') then
      begin
        writeln(chr(7)+'Correct syntax:  WAITCOPY <files> <destination>');
        exit
      end;
    fsplit(paramstr(1),sourcedir,name,ext);
    subdirlen := length(sourcedir);
    if subdirlen > 3 then
      if sourcedir[subdirlen] = '\' then
        sourcedir := copy(sourcedir,1,subdirlen-1);
    path := name+ext;
    destdir := paramstr(2);
    subdirlen := length(destdir);
    if subdirlen > 3 then
      if destdir[subdirlen] = '\' then
        destdir := copy(destdir,1,subdirlen-1);
    if paramstr(3) <> '' then
      val(paramstr(3),bufsize,code)
    else bufsize := 360000;
    initbuffer(b,bufsize);
    writeln('Waitcopy  Ver 2.0');
    writeln;
    writeln('Enter source diskette.  Press ENTER to continue.');
    readln;
    chdir(sourcedir);
    getfilenames(top,bottom,path);
    start.fileptr := top;
    start.offset := 0;
    current.fileptr := top;
    current.offset := 0;
    posit := 0;
    memleft := bufsize;
    while (current.fileptr <> nil) do
      begin
        assign(f,current.fileptr^.data.name);
        reset(f,1);
        seek(f,current.offset);
        amtread := min(memleft,current.fileptr^.data.size - current.offset);
        superread(f,b,posit,amtread);
        close(f);
        posit := posit + amtread;
        memleft := memleft - amtread;
        if memleft > 0 then
          begin
            current.fileptr := current.fileptr^.next;
            current.offset := 0
          end
        else
          begin
            current.offset := current.offset + amtread;
            writeln('Enter target diskette.  Press ENTER to continue.');
            readln;
            chdir(destdir);
            posit := 0;
            while (start.fileptr <> current.fileptr) do
              begin
                assign(f,start.fileptr^.data.name);
                if start.offset = 0 then rewrite(f,1)
                else
                  begin
                    reset(f,1);
                    seek(f,start.offset)
                  end;
                amtread := start.fileptr^.data.size - start.offset;
                superwrite(f,b,posit,amtread);
                setftime(f,start.fileptr^.data.time);
                close(f);
                posit := posit + amtread;
                start.fileptr := start.fileptr^.next;
                start.offset := 0
              end;
            assign(f,start.fileptr^.data.name);
            if start.offset = 0 then rewrite(f,1)
            else
              begin
                reset(f,1);
                seek(f,start.offset)
              end;
            superwrite(f,b,posit,current.offset - start.offset);
            close(f);
            start.offset := current.offset;
            writeln('Enter source diskette.  Press ENTER to continue.');
            readln;
            chdir(sourcedir);
            posit := 0;
            memleft := bufsize
          end
      end;
    writeln('Enter target diskette.  Press ENTER to continue.');
    readln;
    chdir(destdir);
    posit := 0;
    while (start.fileptr <> current.fileptr) do
      begin
        assign(f,start.fileptr^.data.name);
        if start.offset = 0 then rewrite(f,1)
        else
          begin
            reset(f,1);
            seek(f,start.offset)
          end;
        amtread := start.fileptr^.data.size - start.offset;
        superwrite(f,b,posit,amtread);
        setftime(f,start.fileptr^.data.time);
        close(f);
        posit := posit + amtread;
        start.fileptr := start.fileptr^.next;
        start.offset := 0
      end;
    writeln('Copy Complete.  ',numfiles(top,bottom),' files copied.');
    clearlist(top,bottom);
    freebuffer(b)
  end.


