program setup;

  type
    passtype = string[12];
    passtabletype = array[1..36] of passtype;

  var
    cnt:integer;
    f:file;
    dummy:char;
    numwritten:word;
    passtable:passtabletype;

  begin
    for cnt := 1 to 36 do passtable[cnt] := '';
    assign(f,'MSELECT.YYY');
    rewrite(f,1);
    dummy := chr(26);
    blockwrite(f,dummy,sizeof(char),numwritten);
    blockwrite(f,passtable,sizeof(passtabletype),numwritten);
    close(f)
  end.