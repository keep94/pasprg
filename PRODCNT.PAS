program countit;

  type
    arraytype = array[1..25] of integer;

  var factors:arraytype;
      index:integer;
      maxprod:longint;

  Function countprod(var factors:arraytype;index:integer;maxprod:longint):longint;

    var temp:longint;
        cnt:longint;

    begin
      if (index = 0) then
        countprod := 1
      else
        begin
          temp := 0;
          cnt := 1;
          while (cnt <= maxprod) do
            begin
              temp := temp + countprod(factors,index - 1,maxprod div cnt);
              cnt := cnt*factors[index]
            end;
          countprod := temp
        end
    end;

  Function factorial(n:integer):real;

    var temp:real;
        cnt:integer;

    begin
      temp := 1;
      for cnt := 1 to n do
        temp := temp*cnt;
      factorial := temp
    end;

  Function approx(var factors:arraytype;index:integer;maxprod:longint):real;

    var temp,a:real;
        cnt:integer;

    begin
      temp := 1;
      a := ln(maxprod);
      for cnt := 1 to index do
        temp := temp*(a/ln(factors[cnt])+index/2);
      approx := temp / factorial(index)
    end;


  begin
    factors[1] := 2;
    factors[2] := 3;
    factors[3] := 5;
    factors[4] := 7;
    factors[5] := 11;
    factors[6] := 13;
    factors[7] := 17;
    factors[8] := 19;
    factors[9] := 23;
    factors[10] := 29;
    index := 3;
    writeln;
    write('Enter an integer: ');
    readln(maxprod);
    writeln;
    writeln('Number of products between 1 and ',maxprod,' : ',countprod(factors,index,maxprod));
    writeln('Estimated number of products between 1 and ',maxprod,' : ',approx(factors,index,maxprod):0:4);
    readln
  end.
