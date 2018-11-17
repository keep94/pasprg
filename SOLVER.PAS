program solvit;

  type
    carraytype = array[1..5] of real;

    complextype = record
      rpart:real;
      ipart:real
    end;

    sarraytype = array[1..4] of complextype;

  var coef:carraytype;
      sol:sarraytype;
      hellfreezesover:boolean;
      cnt,polysize:word;
      temp:string;
      code:integer;


  function caps(x:string):string;

    var cnt:word;

    begin
      for cnt := 1 to length(x) do
        if (ord(x[cnt]) > 96) and (ord(x[cnt]) < 123) then
          x[cnt] := chr(ord(x[cnt]) - 32);
      caps := x;
    end;


  Function cubr(x:real):real;

    begin
      if (x > 0) then
        cubr := exp(ln(x)/3)
      else if (x < 0) then
        cubr := -exp(ln(-x)/3)
      else cubr := 0;
    end;

  Function invcos(x:real):real;

    var angle:real;

    begin
      if x = 0 then angle := pi/2
      else if x = 1 then angle := 0
      else if x = -1 then angle := pi
      else
        begin
          angle := arctan(sqrt(1 - x*x)/x);
          if (angle < 0) then angle := angle + pi
        end;
      invcos := angle
    end;

  Procedure squareroot(var x,y:complextype);

    var angle,mag:real;

    begin
      if x.ipart = 0 then
        begin
          if x.rpart >= 0 then
            begin
              y.rpart := sqrt(x.rpart);
              y.ipart := 0
            end
          else
            begin
              y.rpart := 0;
              y.ipart := sqrt(-x.rpart)
            end
        end
      else
        begin
          mag := sqrt(x.rpart*x.rpart + x.ipart*x.ipart);
          angle := invcos(x.rpart / mag);
          if x.ipart < 0 then angle := 2*pi - angle;
          y.rpart := cos(angle/2)*sqrt(mag);
          y.ipart := sin(angle/2)*sqrt(mag)
        end
    end;

  Function degree(var coef:carraytype):word;

    var cnt:word;
        done:boolean;

    begin
      cnt := 0;
      done := false;
      while (not done) and (cnt < 5) do
        begin
          cnt := cnt + 1;
          done := (coef[cnt] <> 0.0)
        end;
      degree := 5 - cnt
    end;


  Procedure linear(a,b:real;var sol:complextype);

    begin
      sol.rpart := -b / a;
      sol.ipart := 0
    end;

  Procedure quadratic(a,b,c:real;var sol1,sol2:complextype);

    begin
      if (b*b - 4*a*c) >= 0 then
        begin
          sol1.rpart := (-b + sqrt(b*b - 4*a*c))/(2*a);
          sol1.ipart := 0;
          sol2.rpart := (-b - sqrt(b*b - 4*a*c))/(2*a);
          sol2.ipart := 0
        end
      else
        begin
          sol1.rpart := -b/(2*a);
          sol1.ipart := sqrt(4*a*c - b*b)/(2*a);
          sol2.rpart := sol1.rpart;
          sol2.ipart := -sqrt(4*a*c - b*b)/(2*a)
        end
    end;

  Procedure cubic(a1,b1,c1,d1:real;var sol1,sol2,sol3:complextype);

    var a,b,x,angle:real;
        complexroot:boolean;
        r1,r2:complextype;

    begin
      a := c1/a1 - (b1*b1)/(3*a1*a1);
      b := d1/a1 - (c1*b1)/(3*a1*a1) + (2*b1*b1*b1)/(27*a1*a1*a1);
      if (a < 0) then
        begin
          x := sqrt(-a/3);
          complexroot := (abs(b) >= 2*x*x*x)
        end
      else complexroot := true;
      if complexroot then
        begin
          quadratic(1,b,-a*a*a/27,r1,r2);
          sol1.rpart := cubr(r1.rpart)+cubr(r2.rpart);
          sol1.ipart := 0;
          sol2.rpart := -0.5 * sol1.rpart;
          sol2.ipart := sqrt(3)/2*(cubr(r1.rpart)-cubr(r2.rpart));
          sol3.rpart := sol2.rpart;
          sol3.ipart := -sol2.ipart;
          sol1.rpart := sol1.rpart - b1/(3*a1);
          sol2.rpart := sol2.rpart - b1/(3*a1);
          sol3.rpart := sol3.rpart - b1/(3*a1)
        end
      else
        begin
          angle := invcos(-b/(2*sqrt(-a*a*a/27)));
          sol1.rpart := 2*sqrt(-a/3)*cos(angle/3) - b1/(3*a1);
          sol1.ipart := 0;
          sol2.rpart := 2*sqrt(-a/3)*cos(angle/3+2*pi/3) - b1/(3*a1);
          sol2.ipart := 0;
          sol3.rpart := 2*sqrt(-a/3)*cos(angle/3+4*pi/3) - b1/(3*a1);
          sol3.ipart := 0
        end
    end;

  Procedure quartic(a1,b1,c1,d1,e1:real;var sol1,sol2,sol3,sol4:complextype);

    var a,b,c,x,y:real;
        xsol,r1,r2:complextype;

    begin
      a := c1/a1 - (3*b1*b1)/(8*a1*a1);
      b := d1/a1 - (c1*b1)/(2*a1*a1) + (b1*b1*b1)/(8*a1*a1*a1);
      c := e1/a1 - (d1*b1)/(4*a1*a1) + (c1*b1*b1)/(16*a1*a1*a1) - (3*b1*b1*b1*b1)/(256*a1*a1*a1*a1);
      if b = 0 then
        begin
          quadratic(1,a,c,r1,r2);
          squareroot(r1,sol1);
          sol2.rpart := -sol1.rpart;
          sol2.ipart := -sol1.ipart;
          squareroot(r2,sol3);
          sol4.rpart := -sol3.rpart;
          sol4.ipart := -sol3.ipart
        end
      else
        begin
          cubic(1,2*a,a*a-4*c,-b*b,xsol,r1,r2);
          x := sqrt(xsol.rpart);
          y := (a*x + x*x*x - b)/(2*x);
          quadratic(1,x,y,sol1,sol2);
          quadratic(1,-x,(x*y+b)/x,sol3,sol4)
        end;
      sol1.rpart := sol1.rpart - b1/(4*a1);
      sol2.rpart := sol2.rpart - b1/(4*a1);
      sol3.rpart := sol3.rpart - b1/(4*a1);
      sol4.rpart := sol4.rpart - b1/(4*a1)
    end;

  begin
    hellfreezesover := false;
    repeat
      for cnt := 1 to 5 do
        begin
          write('X^',5-cnt,' coefficient: ');
          readln(temp);
          if caps(temp) = 'EXIT' then exit;
          val(temp,coef[cnt],code)
        end;
      writeln;
      writeln('The solutions are:');
      writeln;
      polysize := degree(coef);
      case polysize of
        4:begin
            quartic(coef[1],coef[2],coef[3],coef[4],coef[5],sol[1],sol[2],sol[3],sol[4]);
            for cnt := 1 to 4 do
              writeln(sol[cnt].rpart:0:10,' + ',sol[cnt].ipart:0:10,'i');
            writeln
          end;
        3:begin
            cubic(coef[2],coef[3],coef[4],coef[5],sol[1],sol[2],sol[3]);
            for cnt := 1 to 3 do
              writeln(sol[cnt].rpart:0:10,' + ',sol[cnt].ipart:0:10,'i');
            writeln
          end;
        2:begin
            quadratic(coef[3],coef[4],coef[5],sol[1],sol[2]);
            for cnt := 1 to 2 do
              writeln(sol[cnt].rpart:0:10,' + ',sol[cnt].ipart:0:10,'i');
            writeln
          end;
        1:begin
            linear(coef[4],coef[5],sol[1]);
            for cnt := 1 to 1 do
              writeln(sol[cnt].rpart:0:10,' + ',sol[cnt].ipart:0:10,'i');
            writeln
          end
      end {case}
    until hellfreezesover
  end.
