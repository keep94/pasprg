unit cmp;

interface

  Function compareques(x,y:string):boolean;

  Function comparewild(x,y:string;igcase:boolean):boolean;

  Function comparestr(x,y:string):integer;

  Function comparenumeric(x,y:string):integer;

  Function comparedates(x,y:string):integer;

implementation

  Function compareques(x,y:string):boolean;

  var count:word;
      equal:boolean;

  begin
    if length(x) <> length(y) then compareques := false
    else
      begin
        count := 1;
        equal := true;
        while (equal) and (count <= length(x)) do
          begin
            if x[count] <> '?' then
              equal := (x[count] = y[count]);
            count := count + 1
          end;
        compareques := equal
      end
  end;

  Function comparewild(x,y:string;igcase:boolean):boolean;

    var xposit,yposit,newxposit,newyposit:integer;
        yout,equal:boolean;
        cnt:word;

    begin
      if igcase then
        begin
          for cnt := 1 to length(x) do
            if (x[cnt] > chr(96)) and (x[cnt] < chr(123)) then x[cnt] := chr(ord(x[cnt]) - 32);
          for cnt := 1 to length(y) do
            if (y[cnt] > chr(96)) and (y[cnt] < chr(123)) then y[cnt] := chr(ord(y[cnt]) - 32)
        end;
      newxposit := 1;
      while (newxposit <= length(x)) and (x[newxposit] <> '*') do
        newxposit := newxposit + 1;
      yout := not compareques(copy(x,1,newxposit - 1),copy(y,1,newxposit - 1));
      xposit := newxposit + 1;
      yposit := newxposit;
      while (not yout) and (xposit <= length(x) + 1) do
        begin
          newxposit := xposit;
          while (newxposit <= length(x)) and (x[newxposit] <> '*') do
            newxposit := newxposit + 1;
          if newxposit = length(x) + 1 then
            yposit := length(y) + xposit - newxposit + 1;
          newyposit := yposit;
          equal := false;
          while (not equal) and (not yout) do
            begin
              if newyposit > length(y) + xposit - newxposit + 1 then
                yout := true
              else if compareques(copy(x,xposit,newxposit - xposit),copy(y,newyposit,newxposit - xposit)) then
                equal := true
              else newyposit := newyposit + 1
            end;
          yposit := newyposit + newxposit - xposit;
          xposit := newxposit + 1
        end;
      if yout then comparewild := false
      else if yposit < length(y) + 1 then comparewild := false
      else comparewild := true
    end;

  Function comparestr(x,y:string):integer;

    begin
      if x > y then comparestr := 1
      else if x < y then comparestr := -1
      else comparestr := 0
    end;

  Function comparenumeric(x,y:string):integer;

    var code:integer;
        valx,valy:real;

    begin
      val(x,valx,code);
      val(y,valy,code);
      if valx > valy then comparenumeric := 1
      else if valx < valy then comparenumeric := -1
      else comparenumeric := 0
    end;

  Function comparedates(x,y:string):integer;

    var xmo,ymo,xday,yday,xyear,yyear,code:integer;

    begin
      if (length(x) <> 8) and (length(y) <> 8) then comparedates := 0
      else if (length(x) <> 8) and (length(y) = 8) then comparedates := -1
      else if (length(x) = 8) and (length(y) <> 8) then comparedates := 1
      else
        begin
          val(copy(x,1,2),xmo,code);
          val(copy(x,4,2),xday,code);
          val(copy(x,7,2),xyear,code);
          val(copy(y,1,2),ymo,code);
          val(copy(y,4,2),yday,code);
          val(copy(y,7,2),yyear,code);
          if xyear < 80 then xyear := xyear + 100;
          if yyear < 80 then yyear := yyear + 100;
          if xyear > yyear then comparedates := 1
          else if xyear < yyear then comparedates := -1
          else if xmo > ymo then comparedates := 1
          else if xmo < ymo then comparedates := -1
          else if xday > yday then comparedates := 1
          else if xday < yday then comparedates := -1
          else comparedates := 0
        end
    end;

end.