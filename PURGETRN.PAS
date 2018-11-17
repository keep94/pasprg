program purgetrn;

uses trans,iounit;

var oldfile,newfile:file of transtype;
    tran:transtype;

begin
  if not fileexists(paramstr(1)) then
    begin
      writeln('Cannot find source file.');
      halt(1)
    end;

  if not filecreation(paramstr(2)) then
    begin
      writeln('Cannot create destination file.');
      halt(1)
    end;

  assign(oldfile,paramstr(1));
  assign(newfile,paramstr(2));
  reset(oldfile);
  rewrite(newfile);

  while not eof(oldfile) do
    begin
      read(oldfile,tran);
      if not transisdeleted(tran) then
        write(newfile,tran)
    end;

  close(newfile);
  close(oldfile)
end.