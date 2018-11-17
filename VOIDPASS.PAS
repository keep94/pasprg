program voidpassword;

  uses IOunit;

  var f:file;
      voidpass:array[1..9] of byte;
      cnt:integer;
      numwritten:word;

  begin
    voidpass[1] := 0;
    for cnt := 2 to 9 do
      voidpass[cnt] := 32;
    if not fileexists('system.dat') then
      begin
        writeln(chr(7)+'SYSTEM.DAT is not in current directory');
        exit
      end;
    assign(f,'system.dat');
    reset(f,1);
    seek(f,3588);
    blockwrite(f,voidpass,9,numwritten);
    close(f)
  end.