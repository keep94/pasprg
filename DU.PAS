program du;

uses dos;

var path,dirname:string;
    error:integer;
    storage,numfiles,numdirs:longint;

Procedure getdu(path:string;var storage:longint;var numfiles:longint;var numdirs:longint);

  var srec:SearchRec;
      error:integer;
      tstorage,tnumfiles,tnumdirs:longint;

  begin
    storage := 0;
    numfiles := 0;
    numdirs := 0;
    FindFirst(path,63,srec);
    error := DosError;
    while error = 0 do
      begin
        if (srec.Attr and 10) > 0 then
          begin
          end
        else if (srec.Name = '.') or (srec.Name = '..') then
          begin
          end
        else
          begin
            if (srec.Attr and 16) > 0 then
              begin
                chdir(srec.Name);
                numdirs := numdirs + 1;
                getdu('*.*',tstorage,tnumfiles,tnumdirs);
                storage := storage + tstorage;
                numfiles := numfiles + tnumfiles;
                numdirs := numdirs + tnumdirs;
                chdir('..')
              end
            else
              begin
                storage := storage + srec.size;
                numfiles := numfiles + 1
              end
          end;
        FindNext(srec);
        error := DosError
      end
  end;

Function dirofpath(path:string):string;

var d:dirstr;
    n:namestr;
    e:extstr;

begin
  fsplit(fexpand(path),d,n,e);
  if ord(d[0]) > 3 then
    d[0] := chr(ord(d[0])-1);
  dirofpath := d
end;


Function fileofpath(path:string):string;

var d:dirstr;
    n:namestr;
    e:extstr;

begin
  fsplit(fexpand(path),d,n,e);
  fileofpath := n+e
end;


Function getcurrentdir:string;

  begin
    getcurrentdir := dirofpath('w')
  end;

begin
  path := paramstr(1);
  dirname := getcurrentdir;
  {$I-}
    chdir(dirofpath(path));
  {$I+}
  error := IOresult;
  if error <> 0 then
    begin
      writeln('Directory not found.');
      halt(1)
    end;
  getdu(fileofpath(path),storage,numfiles,numdirs);
  {$I-}
    chdir(dirname);
  {$I+}
  error := IOresult;
  if error <> 0 then
    begin
      writeln('Error changing to current directory');
      halt(1)
    end;
  writeln(storage,' bytes');
  writeln(numfiles,' files');
  writeln(numdirs,' directories')
end.