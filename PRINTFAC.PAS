program printout;

  var f:file;
      g:text;
      x:array[1..180] of longint;
      rows,cnt,cnt1,start:integer;
      numread:word;

  begin
    assign(f,'f2357');
    reset(f,1);
    assign(g,'lpt1');
    rewrite(g);
    start := 0;
    while not eof(f) do
      begin
        blockread(f,x,720,numread);
        for cnt := 1 to 3 do writeln(g);
        rows := (((numread div 4) - 1) div 3) + 1;
        for cnt := 1 to rows do
          begin
            for cnt1 := 1 to 3 do
              if ((cnt1-1)*rows + cnt <= numread div 4) then
              write(g,start + (cnt1-1)*rows + cnt:12,x[(cnt1-1)*rows + cnt]:12);
            writeln(g)
          end;
        for cnt := 1 to 63 - rows do writeln(g);
        start := start + (numread div 4)
      end;
    close(g);
    close(f)
  end.
