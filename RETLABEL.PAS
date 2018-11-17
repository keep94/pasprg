program retlabels;

  uses crt;

  type
    stringtype = string[40];
    arraytype = array[1..6] of stringtype;

  var
    x:arraytype;
    cnt,cnt1,numlines,labelsize,numcopies,code:integer;
    temp:stringtype;
    g:text;
    dummy:char;
    done:boolean;

  begin
    numlines := 0;
    repeat
      write('Line ',numlines + 1,': ');
      readln(temp);
      if temp <> '' then
        begin
          numlines := numlines + 1;
          x[numlines] := temp
        end
    until (temp = '') or (numlines = 6);
    repeat
      write('Number of lines per label: ');
      readln(temp);
      val(temp,labelsize,code)
    until labelsize >= numlines;
    repeat
      write('Number of labels to print: ');
      readln(temp);
      val(temp,numcopies,code)
    until numcopies >= 1;
    assign(g,'lpt1');
    rewrite(g);
    done := false;
    cnt := 0;
    while not done do
      begin
        for cnt1 := 1 to numlines do writeln(g,x[cnt1]);
        for cnt1 := numlines + 1 to labelsize do writeln(g);
        cnt := cnt + 1;
        if cnt = numcopies then done := true;
        if keypressed then
          begin
            dummy := readkey;
            if dummy = chr(0) then dummy := readkey;
            if dummy = chr(27) then done := true
          end
      end;
    close(g)
  end.
