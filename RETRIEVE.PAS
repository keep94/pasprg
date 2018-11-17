program retrieve;

{-----------------------------------------------------------------------}
{Author:  Travis Keep
Modifications:
    3-1-97  Added drive letter to command line}
{-----------------------------------------------------------------------}

uses dos;

type
  retrievetype=record
    f:file;
    disknum:integer;
    drivenum:integer;
    control:word;
    isopened:boolean
  end;

var r:retrievetype;
    g_buffer:pointer;

Function ischecksumvalid(var r:retrievetype;cs:longint):boolean;

  var temp:boolean;
      hipart:word;
      lopart:word;
      p:^word;
      segment,offset:word;

  begin
    segment := seg(cs);
    offset := ofs(cs);
    p := ptr(segment,offset);
    lopart := p^;
    p := ptr(segment,offset+sizeof(word));
    hipart := p^;
    if r.disknum = 1 then
      r.control := hipart;
    if (r.control = hipart) and (r.disknum = lopart) then
      temp := true
    else
      temp := false;
    ischecksumvalid := temp
  end;


Procedure retrieveinit(var r:retrievetype;drive:char);

  begin
    r.disknum := 0;
    r.drivenum := (ord(drive) and 95) - 64;
    r.isopened := false
  end;

Function retrievedriveletter(var r:retrievetype):char;

begin
  retrievedriveletter := chr(r.drivenum + 64)
end;

Procedure retrieveprompt(var r:retrievetype);

  var error:integer;
       done:boolean;
       cs:longint;
       result:word;
       fname:string[20];

  begin
    r.disknum := r.disknum + 1;
    write('Insert disk ',r.disknum,' and press ENTER to resume.');
    readln;
    done := false;
    fname := '?:\tar.dat';
    fname[1] := retrievedriveletter(r);
    repeat
      assign(r.f,fname);
      {$I-}
      reset(r.f,1);
      {$I+}
      error := IOresult;
      if error <> 0 then
        begin
          write('Error reading drive ',retrievedriveletter(r),'.  Press ENTER to retry.');
          readln
        end
      else
        begin
          blockread(r.f,cs,sizeof(cs),result);
          if (result < sizeof(cs)) then
            begin
              write('Error reading drive ',retrievedriveletter(r),'.  Press ENTER to retry.');
              readln;
              close(r.f)
            end
          else if not ischecksumvalid(r,cs) then
            begin
              write('Wrong disk! ');
              write('Insert disk ',r.disknum,' and press ENTER.');
              readln;
              close(r.f)
            end
          else
            begin
              r.isopened := true;
              done := true
            end
        end
    until done
  end;

Procedure retrieveread(var r:retrievetype;var buffer;count:word);

  var lefttoread,result:word;
      segment,offset:word;
      p:pointer;

  begin
    lefttoread := count;
    segment := Seg(buffer);
    offset := Ofs(buffer);
    while lefttoread > 0 do
      begin
        if not r.isopened then
          retrieveprompt(r);
        p := ptr(segment,offset);
        blockread(r.f,p^,lefttoread,result);
        if result < lefttoread then
          begin
            close(r.f);
            r.isopened := false;
            lefttoread := lefttoread - result;
            offset := offset + result
          end
        else
          lefttoread := 0
      end
  end;

Procedure retrieveclose(var r:retrievetype);

  begin
    if r.isopened then
      close(r.f)
  end;

Procedure curattrread(var r:retrievetype;var srec:SearchRec);

  begin
    retrieveread(r,srec,sizeof(SearchRec))
  end;

Procedure curfileread(var r:retrievetype;var srec:SearchRec);

  var f:file;
      numwritten:word;
      blocksize:word;
      lefttoread:longint;
      error:integer;

  begin
    assign(f,srec.Name);
    {$I-}
      rewrite(f,1);
    {$I+}
    error := IOresult;
    if (error <> 0) then
      writeln('Could not create '+fexpand(srec.Name));
    lefttoread := srec.size;
    while (lefttoread > 0) do
      begin
        if (lefttoread < 65520) then
          blocksize := lefttoread
        else
          blocksize := 65520;
        retrieveread(r,g_buffer^,blocksize);
        if error = 0 then
          blockwrite(f,g_buffer^,blocksize,numwritten)
        else
          numwritten := blocksize;
        if (numwritten < blocksize) then
          begin
            writeln('Out of disk space');
            halt(1)
          end;
        lefttoread := lefttoread - blocksize
      end;
    if error = 0 then
      begin
        setftime(f,srec.time);
        close(f);
        setfattr(f,srec.attr)
      end
  end;


Procedure curdirsetattr(var srec:searchrec);

  var f:file;

  begin
    assign(f,srec.name);
    setfattr(f,(srec.attr and 239))
  end;

Function isenddir(var srec:searchrec):boolean;

  begin
    isenddir := (srec.size = -1)
  end;


Function isendall(var srec:searchrec):boolean;

  begin
    isendall := (srec.size = -2)
  end;


Procedure retrievefiles;

  var r:retrievetype;
      srec:searchrec;
      done:boolean;
      error:integer;
      thedrive:string[2];

  begin
    thedrive := paramstr(1);
    if thedrive = '' then
      retrieveinit(r,'a')
    else
      begin
        if not (thedrive[1] in ['A'..'Z','a'..'z']) then
          begin
            writeln('Invalid drive letter on command line');
            halt(1)
          end;
        retrieveinit(r,thedrive[1])
      end;
    done := false;
    repeat
      curattrread(r,srec);
      if isendall(srec) then
        done := true
      else if isenddir(srec) then
        chdir('..')
      else if (srec.Attr and 16) > 0 then
        begin
          {$I-}
            mkdir(srec.Name);
          {$I+}
          error := IOresult;
          chdir(srec.Name)
        end
      else
        curfileread(r,srec)
    until done;
    retrieveclose(r)
  end;


begin
  FileMode := 0;
  getmem(g_buffer,65520);
  retrievefiles
end.