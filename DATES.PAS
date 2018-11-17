unit dates;

interface

  type
    weekdaytype = array[0..6] of string[3];

  Procedure initweekdays(var weekdays:weekdaytype);

  Function packit(m,d,y:integer):integer;

  Procedure unpackit(date:integer;var m,d,y:integer);

  Function dateval(x:string):integer;

  Function datestr(x:integer):string;

implementation

  type monthoffsettype = array[1..12] of integer;



  Procedure initmonthoffset(var moffset:monthoffsettype);

    begin
      moffset[1] := 0;
      moffset[2] := 31;
      moffset[3] := 59;
      moffset[4] := 90;
      moffset[5] := 120;
      moffset[6] := 151;
      moffset[7] := 181;
      moffset[8] := 212;
      moffset[9] := 243;
      moffset[10] := 273;
      moffset[11] := 304;
      moffset[12] := 334
    end;

  Procedure initweekdays(var weekdays:weekdaytype);

    begin
      weekdays[0] := 'Sun';
      weekdays[1] := 'Mon';
      weekdays[2] := 'Tue';
      weekdays[3] := 'Wed';
      weekdays[4] := 'Thu';
      weekdays[5] := 'Fri';
      weekdays[6] := 'Sat'
    end;


  Function packit(m,d,y:integer):integer;

    var temp:integer;
        moffset:monthoffsettype;

    begin
      if y >= 80 then y := y - 80 else y := y + 20;
      initmonthoffset(moffset);
      temp := 2 + y*365 + moffset[m] + d + (y div 4);
      if (y mod 4 = 0) and (m <= 2) then temp := temp - 1;
      packit := temp
    end;

  Procedure unpackit(date:integer;var m,d,y:integer);

    var y4,y1,cnt:integer;
        moffset:monthoffsettype;
        done:boolean;

    begin
      initmonthoffset(moffset);
      date := date - 2;
      y4 := date div 1461;
      date := date mod 1461;
      if date = 59 then
        begin
          y := 4*y4;
          if y < 20 then y := y + 80 else y := y - 20;
          m := 2;
          d := 29
        end
      else
        begin
          if date > 59 then date := date - 1;
          y1 := date div 365;
          date := date mod 365;
          y := 4*y4 + y1;
          if y < 20 then y := y + 80 else y := y - 20;
          cnt := 1;
          done := false;
          while not done do
            if cnt = 12 then done := true
            else if moffset[cnt + 1] > date then done := true
            else cnt := cnt + 1;
          m := cnt;
          date := date - moffset[cnt];
          d := date + 1
        end
    end;

  Function dateval(x:string):integer;

    var d:array[1..3] of integer;
        posit,un:integer;

    begin
      posit := 1;
      un := 1;
      while (posit <= length(x)) and (un <= 3) do
        begin
          d[un] := 0;
          while (posit <= length(x)) and (x[posit] <> '/') do
            begin
              d[un] := 10*d[un] - 48 + ord(x[posit]);
              posit := posit + 1
            end;
          un := un + 1;
          posit := posit + 1
        end;
      if (un <= 3) then
         dateval := -1
      else
        dateval := packit(d[1],d[2],d[3])
    end;

  Function datestr(x:integer):string;

    var d,m,y:integer;
        dstr,ystr,mstr:string[2];

    begin
      unpackit(x,m,d,y);
      str(m,mstr);
      str(d,dstr);
      str(y,ystr);
      if length(mstr) < 2 then mstr := '0'+mstr;
      if length(dstr) < 2 then dstr := '0'+dstr;
      if length(ystr) < 2 then ystr := '0'+ystr;
      datestr := mstr+'/'+dstr+'/'+ystr
    end;

end.