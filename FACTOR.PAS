program factors;

  type
    tablearraytype = array[1..12000] of longint;
    tabletype = record
      size:integer;
      data:tablearraytype
    end;
    ptrtype = ^tabletype;
    arraytype = array[1..100] of integer;

    facttype = record
      size:integer;
      mantisa:arraytype;
      exponent:arraytype
    end;

  Function power(x,y:longint):longint;

    var temp,cnt:longint;

    begin
      temp := 1;
      for cnt := 1 to y do
          temp := temp * x;
      power := temp
    end;

  Function evalfact(var fact:facttype):longint;

    var cnt:integer;
        temp:longint;

    begin
      with fact do
        begin
          temp := 1;
          for cnt := 1 to size do
            temp := temp*power(mantisa[cnt],exponent[cnt])
        end;
      evalfact := temp
    end;


  Function incrfact(maxval:longint;var fact:facttype;var prod:longint):boolean;

    var posit:integer;


    begin
      posit := 1;
      while (posit <= fact.size) and
      (maxval div evalfact(fact) < fact.mantisa[posit]) do
        begin
          fact.exponent[posit] := 0;
          posit := posit + 1
        end;
      if (posit <= fact.size) then
        begin
          fact.exponent[posit] := fact.exponent[posit] + 1;
          prod := evalfact(fact);
          incrfact := true
        end
      else incrfact := false
    end;

  Procedure initfact(var fact:facttype);

    var cnt:integer;

    begin
      write('How many factors? ');
      readln(fact.size);
      writeln;
      for cnt := 1 to fact.size do
        begin
          write('Enter factor #',cnt,': ');
          readln(fact.mantisa[cnt]);
          fact.exponent[cnt] := 0
        end
    end;

  Procedure buildtable(maxval:longint;p:ptrtype;var fact:facttype);

    var cnt:integer;
        prod:longint;

    begin
      cnt := 1;
      p^.data[cnt] := 1;
      while incrfact(maxval,fact,prod) do
        begin
          cnt := cnt + 1;
          p^.data[cnt] := prod
        end;
      p^.size := cnt
    end;

  Procedure sorttable(p:ptrtype);

    var incr,posit,newposit,cnt,c1:integer;
        temp:longint;

    begin
      incr := 1;
      while (incr < p^.size div 9) do
        incr := incr*3 + 1;
      while (incr >= 1) do
        begin
          for cnt := 1 to incr do
            begin
              posit := cnt + incr;
              while (posit <= p^.size) do
                begin
                  newposit := posit - incr;
                  while (newposit >= cnt) and (p^.data[posit] < p^.data[newposit]) do
                    newposit := newposit - incr;
                  temp := p^.data[posit];
                  c1 := posit - incr;
                  while (c1 >= newposit + incr) do
                    begin
                      p^.data[c1 + incr] := p^.data[c1];
                      c1 := c1 - incr
                    end;
                  p^.data[newposit + incr] := temp;
                  posit := posit + incr
                end
            end;
          incr := incr div 3
        end
    end;

  var p:ptrtype;
      maxval:longint;
      cnt:integer;
      fact:facttype;
      f:file;
      numwritten:word;
      filename:string;

  begin
    getmem(p,sizeof(tabletype));
    write('Enter max value: ');
    readln(maxval);
    write('Save to? ');
    readln(filename);
    initfact(fact);
    buildtable(maxval,p,fact);
    sorttable(p);
    assign(f,filename);
    rewrite(f,1);
    blockwrite(f,p^.data[1],4*p^.size,numwritten);
    close(f);
    freemem(p,sizeof(tabletype))
  end.