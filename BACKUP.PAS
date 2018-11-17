program backup;

{---------------------------------------------------------------------}
{Author:  Travis Keep
Modification history:
  3-1-97  Added drive letter as second argument of command line}
{---------------------------------------------------------------------}

uses dos;

type
  backuptype=record
    f:file;
    disknum:integer;
    drivenum:integer;
    control:word;
    isopened:boolean
  end;

var b:backuptype;
    path:string;
    thedrive:string[2];
    g_buffer:pointer;

Function checksum(var b:backuptype):longint;

  var temp:longint;

  begin
    if b.disknum = 1 then
      begin
        b.control := random(256);
        b.control := 256*b.control + random(256)
      end;
    temp := b.control;
    temp := temp*65536 + b.disknum;
    checksum := temp
  end;


Procedure backupinit(var b:backuptype;drive:char);

  begin
    b.disknum := 0;
    b.drivenum := (ord(drive) and 95) - 64;
    b.isopened := false
  end;

Function backupdriveletter(var b:backuptype):char;

begin
  backupdriveletter := chr(b.drivenum + 64)
end;

Procedure backupprompt(var b:backuptype);

  var error:integer;
       done:boolean;
       cs:longint;
       result:word;
       fname:string[20];

  begin
    b.disknum := b.disknum + 1;
    write('Insert disk ',b.disknum,' and press ENTER to resume.');
    readln;
    cs := checksum(b);
    done := false;
    fname := '?:\tar.dat';
    fname[1] := backupdriveletter(b);
    repeat
      assign(b.f,fname);
      {$I-}
      rewrite(b.f,1);
      {$I+}
      error := IOresult;
      if error <> 0 then
        begin
          write('Error writing to drive ',backupdriveletter(b),'.  Press ENTER to retry.');
          readln
        end
      else
        begin
          blockwrite(b.f,cs,sizeof(cs),result);
          if result < sizeof(cs) then
            begin
              write('Disk full in drive ',backupdriveletter(b),'.  Press ENTER to retry.');
              readln;
              close(b.f)
            end
          else
            begin
              b.isopened := true;
              done := true
            end
        end
    until done
  end;


Procedure backupwrite(var b:backuptype;var buffer;count:word);

  var lefttowrite,result:word;
      segment,offset:word;
      spaceleft:longint;
      p:pointer;

  begin
    lefttowrite := count;
    segment := Seg(buffer);
    offset := Ofs(buffer);
    while lefttowrite > 0 do
      begin
        if not b.isopened then
          backupprompt(b);
        p := ptr(segment,offset);
        blockwrite(b.f,p^,lefttowrite,result);
        if result = 0 then
          begin
            spaceleft := diskfree(b.drivenum);
            blockwrite(b.f,p^,spaceleft,result);
            if result < spaceleft then
              begin
                writeln('Critical error in backupwrite');
                halt(1)
              end
          end;
        if result < lefttowrite then
          begin
            close(b.f);
            b.isopened := false;
            lefttowrite := lefttowrite - result;
            offset := offset + result
          end
        else
          lefttowrite := 0
      end
  end;

Procedure backupclose(var b:backuptype);

  begin
    if b.isopened then
      close(b.f)
  end;

Procedure curattrwrite(var b:backuptype;var srec:SearchRec);

  begin
    backupwrite(b,srec,sizeof(SearchRec))
  end;

Procedure curfilewrite(var b:backuptype;var srec:SearchRec);

  var f:file;
      numread:word;

  begin
    assign(f,srec.Name);
    reset(f,1);
    repeat
      blockread(f,g_buffer^,65520,numread);
      backupwrite(b,g_buffer^,numread)
    until (numread = 0);
    close(f)
  end;


Procedure enddirwrite(var b:backuptype);

  var
    srec:SearchRec;

  begin
    srec.size := -1;
    curattrwrite(b,srec)
  end;

Procedure endallwrite(var b:backuptype);

  var srec:SearchRec;

  begin
    srec.size := -2;
    curattrwrite(b,srec)
  end;


Procedure curdirwrite(var b:backuptype;path:string); forward;

Procedure curfiledirwrite(var b:backuptype;var srec:SearchRec);

  begin
    if (srec.Attr and 10) > 0 then
      begin
      end
    else if (srec.Name = '.') or (srec.Name = '..') then
      begin
      end
    else
      begin
        curattrwrite(b,srec);
        if (srec.Attr and 16) > 0 then
          begin
            chdir(srec.Name);
            curdirwrite(b,'*.*');
            enddirwrite(b);
            chdir('..')
          end
        else
          curfilewrite(b,srec)
      end
  end;


Procedure curdirwrite(var b:backuptype;path:string);

  var srec:SearchRec;
      error:integer;

  begin
    FindFirst(path,63,srec);
    error := DosError;
    while error = 0 do
      begin
        curfiledirwrite(b,srec);
        FindNext(srec);
        error := DosError
      end
  end;

Function incurrentdir(var path:string):boolean;

var i:integer;
    temp:boolean;

begin
  temp := true;
  i := 1;
  while (temp) and (i <= length(path)) do
    begin
      if (path[i] = ':') or (path[i] = '\') then
        temp := false;
      i := i + 1
    end;
  incurrentdir := temp
end;


begin
  FileMode := 0;
  randomize;
  getmem(g_buffer,65520);
  path := paramstr(1);
  if path = '' then
    begin
      writeln('You must specify files and directories to back up.');
      halt(1)
    end;
  if not incurrentdir(path) then
    begin
      writeln('You must back up from the current directory');
      halt(1)
    end;
  thedrive := paramstr(2);
  if thedrive = '' then
    backupinit(b,'a')
  else
    begin
      if not (thedrive[1] in ['A'..'Z','a'..'z']) then
        begin
          writeln('Invalid drive letter on command line');
          halt(1)
        end;
      backupinit(b,thedrive[1])
    end;
  curdirwrite(b,path);
  if (b.disknum = 0) then
    begin
      writeln('File not found.');
      halt(1)
    end
  else
    endallwrite(b)
end.