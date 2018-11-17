program convertit;

  type oldlinetype = record
         cat:string[4];
         desc:string[15];
         data:array[3..7] of real
       end;

       newlinetype = record
         cat:string[4];
         desc:string[18];
         data:array[3..7] of real
       end;

  var f:file of oldlinetype;
      g:file of newlinetype;
      fname,nname:string;
      x:oldlinetype;
      y:newlinetype;
      cnt:integer;

  begin
    write('old Filename: ');
    readln(fname);
    write('New filename: ');
    readln(nname);
    assign(f,fname);
    reset(f);
    assign(g,nname);
    rewrite(g);
    while not eof(f) do
      begin
        read(f,x);
        y.cat := x.cat;
        y.desc := x.desc;
        for cnt := 3 to 7 do y.data[cnt] := x.data[cnt];
        write(g,y)
      end;
    close(f);
    close(g)
  end.
