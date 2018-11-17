program chebychev;

  type arraytype = array[0..10000] of real;
       ptrtype = ^arraytype;

  var p,q,r:ptrtype;
      degr:integer;
      startp,endp:real;
      maxind:integer;
      cnt:integer;


  Function myfunc(x:real):real;

    begin
      myfunc := sin(x);
    end;

  Function gettableval(p:ptrtype;x,y:integer):real;

    var indx:integer;

    begin
      indx := ((x+y)*(x+y)+3*x+y) div 2;
      gettableval := p^[indx]
    end;

  Procedure settableval(p:ptrtype;x,y:integer;e:real);

    var indx:integer;

    begin
      indx := ((x+y)*(x+y)+3*x+y) div 2;
      p^[indx] := e
    end;

  Procedure initxs(var q:ptrtype;degr:integer;startp,endp:real);

    var midp,difp:real;
        cnt:integer;

    begin
      getmem(q,6*(degr+1));
      midp := (startp + endp) / 2;
      difp := (endp - startp) / 2;
      for cnt := 0 to degr do
        q^[cnt] := midp - difp*cos( pi*(2.0*cnt + 1.0)/(2.0*(degr+1.0)) );
    end;

  Procedure initys(var p:ptrtype;q:ptrtype;degr:integer);

    var maxind,cnt:integer;


    begin
      maxind := ((degr+3)*degr) div 2;
      getmem(p,(maxind+1)*6);
      for cnt := 0 to degr do
        settableval(p,0,cnt,myfunc(q^[cnt]));
    end;

  Procedure gentable(p,q:ptrtype;degr:integer);

    var nx,cx,e:real;
        cnt,cnt1:integer;

    begin
      for cnt := 1 to degr do
        for cnt1 := 0 to degr-cnt do
          begin
            nx := gettableval(p,cnt-1,cnt1+1);
            cx := gettableval(p,cnt-1,cnt1);
            e := (nx-cx) / (q^[cnt1+cnt] - q^[cnt1]);
            settableval(p,cnt,cnt1,e)
          end
    end;


  Procedure genpoly(var r:ptrtype;q:ptrtype;degr:integer);

    var maxind,cnt,cnt1:integer;
        nx,cx:real;

    begin
      maxind := ((degr+3)*degr) div 2;
      getmem(r,(maxind+1)*6);
      settableval(r,0,degr,1);
      settableval(r,0,degr-1,-q^[0]);
      settableval(r,1,degr-1,1);
      for cnt := 2 to degr do
        begin
          cx := gettableval(r,0,degr-cnt+1);
          settableval(r,0,degr-cnt,cx*-q^[cnt-1]);
          for cnt1 := 1 to cnt-1 do
            begin
              cx := gettableval(r,cnt1,degr-cnt+1);
              nx := gettableval(r,cnt1-1,degr-cnt+1);
              settableval(r,cnt1,degr-cnt,nx-cx*q^[cnt-1])
            end;
          nx := gettableval(r,cnt-1,degr-cnt+1);
          settableval(r,cnt,degr-cnt,nx)
        end
    end;

   Procedure printcoef(p,r:ptrtype;degr:integer);

     var cnt,cnt1:integer;
         sum,coef,ddif:real;

     begin
       for cnt := 0 to degr do
         begin
           sum := 0.0;
           for cnt1 := cnt to degr do
             begin
               coef := gettableval(r,cnt,degr-cnt1);
               ddif := gettableval(p,cnt1,0);
               sum := sum + coef*ddif
             end;
           writeln('X^',cnt,' = ',sum:0:12)
         end
     end;


  begin
    write('Degree of chebychev polynomial: ');
    readln(degr);
    write('Start point: ');
    readln(startp);
    write('End point: ');
    readln(endp);
    writeln;
    initxs(q,degr,startp,endp);
    initys(p,q,degr);
    gentable(p,q,degr);
    genpoly(r,q,degr);
    printcoef(p,r,degr);
    maxind := ((degr+3)*degr) div 2;
    freemem(p,(maxind+1)*6);
    freemem(r,(maxind+1)*6);
    freemem(q,(degr+1)*6);
    readln
  end.