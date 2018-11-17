program birthday;

uses dos,crt,IOunit;

const
  SCSIZE = 15;
  MAXDATASIZE = 2000;
  TOPSC = 4;

type
  arraytype = array[0..65519] of byte;

  datetype = record
    day:integer;
    month:integer;
    year:integer;
  end;

  node = record
    last:string[15];
    first:string[20];
    date:datetype
  end;

  ptrtype = ^node;

  datatype = array[0..MAXDATASIZE-1] of ptrtype;

var
  CDATE:datetype;
  newdate:datetype;
  data:datatype;
  size,cnt,numdays:integer;
  daystr:string;
  code:integer;
  yr,m,d,dw:word;

  Function caps(x:string):string;

    var cnt:integer;

    begin
      for cnt := 1 to length(x) do
        if (ord(x[cnt]) > 96) and (ord(x[cnt]) < 123) then
          x[cnt] := chr(ord(x[cnt]) - 32);
      caps := x
    end;


  Function min(x,y:integer):integer;

    begin
      if (x <= y) then min := x
      else min := y
    end;


  Function stringrep(x:integer;c:integer):string;

    var temp:string;
        cnt:integer;

    begin
      temp := '';
      for cnt := 1 to x do
        temp := temp + chr(c);
      stringrep := temp
    end;


Function isnum(x:char):boolean;

  begin
    isnum := (x >= '0') and (x <= '9')
  end;

Procedure getcurrentdate(var date:datetype);

  var yr,m,d,dw:word;

  begin
    date := CDATE;
  end;


Procedure daystodate(x:longint;var d:datetype);

  var mon:array[1..13] of longint;
  var year400,year4,year1:longint;
      cnt:integer;

  begin
    mon[1] := 0;
    mon[2] := 31;
    mon[3] := 60;
    mon[4] := 91;
    mon[5] := 121;
    mon[6] := 152;
    mon[7] := 182;
    mon[8] := 213;
    mon[9] := 244;
    mon[10] := 274;
    mon[11] := 305;
    mon[12] := 335;
    mon[13] := 366;
    year400 := x div 146097;
    x := x - 146097*year400;
    if x >= 60 then
      x := x + ((x - 60) div 36524);
    year4 := x div 1461;
    x := x - 1461*year4;
    if x >= 60 then
      x := x + ((x - 60) div 365);
    year1 := x div 366;
    x := x - 366*year1;
    cnt := 1;
    while mon[cnt] <= x do
      cnt := cnt + 1;
    cnt := cnt - 1;
    d.year := year400*400 + year4*4 + year1;
    d.month := cnt;
    d.day := x - mon[cnt] + 1
  end;



Function datetodays(x:datetype):longint;

  var mon:array[1..12] of longint;
      temp:longint;
      leaps:longint;

  begin
    mon[1] := 0;
    mon[2] := 31;
    mon[3] := 59;
    mon[4] := 90;
    mon[5] := 120;
    mon[6] := 151;
    mon[7] := 181;
    mon[8] := 212;
    mon[9] := 243;
    mon[10] := 273;
    mon[11] := 304;
    mon[12] := 334;
    temp := x.year;
    if x.month < 3 then
      leaps := temp - 1
    else
      leaps := temp;
    temp := 365*temp;
    temp := temp + (leaps div 4) - (leaps div 100) + (leaps div 400);
    temp := temp + mon[x.month] + x.day;
    datetodays := temp
  end;


Procedure dateplusdays(x:datetype;days:longint;var y:datetype);

  begin
    daystodate(datetodays(x)+days,y);
  end;



Function yearsold(x:datetype):integer;

  var current:datetype;
      temp:integer;

  begin
    getcurrentdate(current);
    temp := current.year - x.year;
    if current.month < x.month then
      temp := temp - 1
    else if current.month = x.month then
      begin
        if current.day < x.day then
          temp := temp - 1
      end;
    yearsold := temp
  end;

Function daysold(x:datetype):longint;

  var current:datetype;
      temp:longint;

  begin
    getcurrentdate(current);
    temp := datetodays(current) - datetodays(x);
    daysold := temp
  end;


Function datevalid(x:datetype):boolean;

  var mon:array[1..12] of integer;
      temp:boolean;

  begin
    mon[1] := 31;
    mon[3] := 31;
    mon[4] := 30;
    mon[5] := 31;
    mon[6] := 30;
    mon[7] := 31;
    mon[8] := 31;
    mon[9] := 30;
    mon[10] := 31;
    mon[11] := 30;
    mon[12] := 31;
    if (x.year mod 100 = 0) then
      begin
        if (x.year mod 400 = 0) then mon[2] := 29
        else mon[2] := 28
      end
    else if (x.year mod 4 = 0)  then mon[2] := 29
    else mon[2] := 28;
    if (x.month < 1) or (x.month > 12) then temp := false
    else if (x.day < 1) or (x.day > mon[x.month]) then temp := false
    else temp := true;
    datevalid := temp
  end;


Function datetostr(var date:datetype):string;

  var temp:string;

  begin
    temp[0] := chr(10);
    temp[1] := chr((date.month div 10) + 48);
    temp[2] := chr((date.month mod 10) + 48);
    temp[3] := '/';
    temp[4] := chr((date.day div 10) + 48);
    temp[5] := chr((date.day mod 10) + 48);
    temp[6] := '/';
    temp[7] := chr((date.year div 1000) + 48);
    temp[8] := chr(((date.year div 100) mod 10) + 48);
    temp[9] := chr(((date.year div 10) mod 10) + 48);
    temp[10] := chr((date.year mod 10) + 48);
    datetostr := temp
  end;


Function comparedate(x,y:datetype):integer;

  var temp:integer;

  begin
    if x.month > y.month then temp := 1
    else if x.month < y.month then temp := -1
    else if x.day > y.day then temp := 1
    else if x.day < y.day then temp := -1
    else temp := 0;
    comparedate := temp
  end;


Function comparedob(x,y:datetype):integer;

  var temp:integer;

  begin
    if x.year > y.year then temp := 1
    else if x.year < y.year then temp := -1
    else temp := comparedate(x,y);
    comparedob := temp
  end;

Function comparedays(x,y:datetype):integer;

  var temp:integer;
      nx,ny:longint;

  begin
    nx := ((daysold(x)-1) mod 1000) + 1;
    ny := ((daysold(y)-1) mod 1000) + 1;
    if nx > ny then temp := -1
    else if nx < ny then temp := 1
    else temp := 0;
    comparedays := temp
  end;

Function comparebday(x,y:datetype):integer;

  var temp:integer;

  begin
    if (comparedate(CDATE,x) = 1) and (comparedate(CDATE,y) <> 1) then temp := 1
    else if (comparedate(CDATE,y) = 1) and (comparedate(CDATE,x) <> 1) then temp := -1
    else temp := comparedate(x,y);
    comparebday := temp
  end;


Function comparerec(meth:integer;p,q:ptrtype):integer;

  var temp:integer;

  begin
    case meth of
      0:begin
          if (caps(p^.last) < caps(q^.last)) then temp := -1
          else if (caps(p^.last) > caps(q^.last)) then temp := 1
          else if (caps(p^.first) < caps(q^.first)) then temp := -1
          else if (caps(p^.first) > caps(q^.first)) then temp := 1
          else temp := 0
        end;
      1:begin
          temp := comparedate(p^.date,q^.date);
          if temp = 0 then
            temp := comparerec(0,p,q)
        end;
      2:begin
          temp := comparedob(p^.date,q^.date);
          if temp = 0 then
            temp := comparerec(0,p,q)
        end;
      3:begin
          temp := comparebday(p^.date,q^.date);
          if temp = 0 then
            temp := comparerec(0,p,q)
        end;
      4:begin
          temp := comparedays(p^.date,q^.date);
          if temp = 0 then
            temp := comparerec(0,p,q)
        end
    end;
    comparerec := temp
  end;


Procedure reheap(meth:integer;posit:integer;size:integer;var data:datatype);

  var done:boolean;
      piv:integer;
      temp:ptrtype;

  begin
    done := false;
    while (not done) and (2*posit + 1 < size) do
      begin
        if 2*posit + 2 = size then
          piv := 2*posit + 1
        else if comparerec(meth,data[2*posit+1],data[2*posit+2]) = 1 then
          piv := 2*posit + 1
        else piv := 2*posit + 2;
        if comparerec(meth,data[posit],data[piv]) = -1 then
          begin
            temp := data[posit];
            data[posit] := data[piv];
            data[piv] := temp;
            posit := piv
          end
        else done := true
      end
  end;


Procedure sort(meth,size:integer;var data:datatype);

  var cnt:integer;
      temp:ptrtype;

  begin
    for cnt := (size div 2)-1 downto 0 do
      reheap(meth,cnt,size,data);
    for cnt := size-1 downto 1 do
      begin
        temp := data[0];
        data[0] := data[cnt];
        data[cnt] := temp;
        reheap(meth,0,cnt,data)
      end
  end;


Procedure clearall(var size:integer;var data:datatype);

  var cnt:integer;

  begin
    for cnt := 0 to size-1 do
      dispose(data[cnt]);
    size := 0
  end;

Function isleapyear(x:integer):boolean;

  var temp:boolean;

  begin
    if (x mod 100 = 0) then
      temp := (x mod 400 = 0)
    else temp := (x mod 4 = 0);
    isleapyear := temp
  end;


Function bdaydiff(c:datetype;x:datetype):integer;

  var mon:array[1..12] of integer;
      leappt:integer;
      xday,cday:integer;

  begin
    mon[1] := 0;
    mon[2] := 31;
    mon[3] := 59;
    mon[4] := 90;
    mon[5] := 120;
    mon[6] := 151;
    mon[7] := 181;
    mon[8] := 212;
    mon[9] := 243;
    mon[10] := 273;
    mon[11] := 304;
    mon[12] := 334;
    if (c.month < 3) and (isleapyear(c.year)) then leappt := 59
    else if (c.month >= 3) and (isleapyear(c.year+1)) then leappt := 424
    else leappt := 1461;
    cday := mon[c.month] + c.day;
    if (x.month > 12) then
      xday := mon[12]
    else if (x.month < 1) then
      xday := mon[1]
    else xday := mon[x.month];
    if comparedate(c,x) = 1 then xday := xday + 365;
    if xday >= leappt then xday := xday + 1;
    xday := xday + x.day;
    bdaydiff := xday - cday
  end;


Procedure checkenvread;

  begin
    if getenv('BDAYFILE') = '' then
      begin
        writeln('Environment variable BDAYFILE is undefined.');
        halt(0)
      end;
    if not fileexists(getenv('BDAYFILE')) then
      begin
        writeln('File read error.  Check environment variable BDAYFILE.');
        halt(0)
      end
  end;


Procedure getseldata(numdays:integer;var size:integer;var data:datatype);

  var f:file of node;
      cnt:integer;
        x:node;

  begin
    checkenvread;
    clearall(size,data);
    assign(f,getenv('BDAYFILE'));
    reset(f);
    cnt := 0;
    while not eof(f) do
      begin
        read(f,x);
        if bdaydiff(CDATE,x.date) < numdays then
          begin
            new(data[cnt]);
            data[cnt]^ := x;
            cnt := cnt + 1
          end
      end;
    close(f);
    size := cnt
  end;


Procedure newgetseldata(numdays:integer;var size:integer;var data:datatype);

  var f:file of node;
      cnt:integer;
        x:node;
        nx:longint;

  begin
    checkenvread;
    clearall(size,data);
    assign(f,getenv('BDAYFILE'));
    reset(f);
    cnt := 0;
    while not eof(f) do
      begin
        read(f,x);
        if (datevalid(x.date)) and (x.date.year > 0) then
          nx := ((daysold(x.date)-1) mod 1000) + 1
        else
          nx := -1;
        if nx > (1000 - numdays) then
          begin
            new(data[cnt]);
            data[cnt]^ := x;
            cnt := cnt + 1
          end
      end;
    close(f);
    size := cnt
  end;


  begin
    size := 0;
    daystr := paramstr(1);
    val(daystr,numdays,code);
    if (numdays < 1) or (numdays > 365) then
      begin
        writeln(chr(7)+'Usage: REMIND days (1-365)');
        exit
      end;
    getdate(yr,m,d,dw);
    CDATE.year := yr;
    CDATE.month := m;
    CDATE.day := d;
    if paramstr(2) <> '/d' then
      begin
        getseldata(numdays,size,data);
        sort(3,size,data)
      end
    else
      begin
        newgetseldata(numdays,size,data);
        sort(4,size,data)
      end;
    writeln;
    writeln('UPCOMING BIRTHDAYS');
    writeln(stringrep(61,ord('-')));
    for cnt := 0 to size-1 do
      begin
        if paramstr(2) <> '/d' then
          begin
            if comparedate(CDATE,data[cnt]^.date) = 0 then
              begin
                write('*'+data[cnt]^.first,' ',data[cnt]^.last);
                write(stringrep(39-length(data[cnt]^.first)-length(data[cnt]^.last),32));
                newdate := data[cnt]^.date;
                newdate.year := newdate.year + yearsold(data[cnt]^.date);
                write(datetostr(newdate));
                writeln(yearsold(data[cnt]^.date):10)
              end
            else
              begin
                write(' '+data[cnt]^.first,' ',data[cnt]^.last);
                write(stringrep(39-length(data[cnt]^.first)-length(data[cnt]^.last),32));
                newdate := data[cnt]^.date;
                newdate.year := newdate.year + yearsold(data[cnt]^.date) + 1;
                write(datetostr(newdate));
                if data[cnt]^.date.year > 0 then
                  write(yearsold(data[cnt]^.date)+1:10);
                writeln
              end
          end
        else
          begin
            if daysold(data[cnt]^.date) mod 1000 = 0 then
              write('*'+data[cnt]^.first+' '+data[cnt]^.last)
            else
              write(' '+data[cnt]^.first+' '+data[cnt]^.last);
            write(stringrep(39-length(data[cnt]^.first)-length(data[cnt]^.last),32));
            dateplusdays(data[cnt]^.date,
            1000*((daysold(data[cnt]^.date)+999) div 1000),newdate);
            write(datetostr(newdate));
            writeln(1000*((daysold(data[cnt]^.date)+999) div 1000):10)
          end
      end;
    clearall(size,data)
  end.