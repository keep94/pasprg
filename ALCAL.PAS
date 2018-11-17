program birthday;

uses crt,dos,IOunit;

const
  SCSIZE = 15;
  MAXDATASIZE = 2000;
  TOPSC = 4;
  TOPMAR = 5;
  PAGESIZE = 66;

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
  offset:array[0..5] of integer;
  name:array[0..5] of string[20];
  col,row,posit,size:integer;
  data:datatype;
  ctrl,scan:settype;
  choice,schoice:char;
  done,escpressed:boolean;
  x,temp:string;
  gshowdays:integer;


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


Procedure inputprompt(lin,col:integer);

    begin
      gotoxy(1,1);
      write('':79);
      gotoxy(1,1);
      write(lin+1,' ',name[col],' : ')
    end;


Procedure highlight(x:integer;y:integer;l:integer);

  var p:^arraytype;
      cnt:integer;

  begin
    p := ptr($b800,$0);
    for cnt := 80*y+x-81 to 80*y+x+l-82 do
      p^[2*cnt+1] := 112;
  end;

Procedure unhighlight(x:integer;y:integer;l:integer);

  var p:^arraytype;
      cnt:integer;

  begin
    p := ptr($b800,$0);
    for cnt := 80*y+x-81 to 80*y+x+l-82 do
      p^[2*cnt+1] := 7;
  end;

Function isnum(x:char):boolean;

  begin
    isnum := (x >= '0') and (x <= '9')
  end;

Procedure purgedel(var x:string);

  var cnt,newposit:integer;

  begin
    cnt := 1;
    newposit := 1;
    while cnt <= length(x) do
      begin
        if isnum(x[cnt]) then
          begin
            x[newposit] := x[cnt];
            newposit := newposit + 1
          end;
        cnt := cnt + 1
      end;
    x[0] := chr(newposit-1)
  end;

Procedure getcurrentdate(var date:datetype);

  var yr,m,d,dw:word;

  begin
    getdate(yr,m,d,dw);
    date.year := yr;
    date.month := m;
    date.day := d
  end;


Procedure setdate(var date:datetype;x:string);

  var cnt:integer;

  begin
    purgedel(x);
    cnt := 1;
    while (cnt <= length(x)) and (isnum(x[cnt])) do
      cnt := cnt + 1;
    if (cnt > length(x)) then
      begin
        if length(x) = 3 then
          begin
            date.month := ord(x[1]) - 48;
            date.day  := 10*ord(x[2]) + ord(x[3]) - 528;
            date.year := 0
          end
        else if length(x) = 4 then
          begin
            date.month := 10*ord(x[1]) + ord(x[2]) - 528;
            date.day := 10*ord(x[3]) + ord(x[4]) - 528;
            date.year := 0
          end
        else if length(x) = 5 then
          begin
            date.month := ord(x[1]) - 48;
            date.day := 10*ord(x[2]) + ord(x[3]) - 528;
            date.year := 10*ord(x[4]) + ord(x[5]) + 1372
          end
        else if length(x) = 6 then
          begin
            date.month := 10*ord(x[1]) + ord(x[2]) - 528;
            date.day := 10*ord(x[3]) + ord(x[4]) - 528;
            date.year := 10*ord(x[5]) + ord(x[6]) + 1372
          end
        else if length(x) = 7 then
          begin
            date.month := ord(x[1]) - 48;
            date.day := 10*ord(x[2]) + ord(x[3]) - 528;
            date.year := 1000*(ord(x[4])-48)+100*(ord(x[5])-48)+
                       10*(ord(x[6])-48)+ord(x[7])-48
          end
        else if length(x) = 8 then
          begin
            date.month := 10*ord(x[1]) + ord(x[2]) - 528;
            date.day := 10*ord(x[3]) + ord(x[4]) - 528;
            date.year := 1000*(ord(x[5])-48)+100*(ord(x[6])-48)+
                         10*(ord(x[7])-48)+ord(x[8])-48
          end
      end
  end;

Function datetostr(var date:datetype):string;

  var temp:string;
      cnt:integer;

  begin
    temp[0] := chr(10);
    temp[1] := chr((date.month div 10) + 48);
    temp[2] := chr((date.month mod 10) + 48);
    temp[3] := '/';
    temp[4] := chr((date.day div 10) + 48);
    temp[5] := chr((date.day mod 10) + 48);
    temp[6] := '/';
    if date.year = 0 then
        for cnt := 7 to 10 do
          temp[cnt] := '?'
    else
      begin
        temp[7] := chr((date.year div 1000) + 48);
        temp[8] := chr(((date.year div 100) mod 10) + 48);
        temp[9] := chr(((date.year div 10) mod 10) + 48);
        temp[10] := chr((date.year mod 10) + 48)
      end;
    datetostr := temp
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


Procedure displayheading;

  begin
    gotoxy(1,TOPSC-1);
    write('':80);
    gotoxy(1,TOPSC-1);
    if gshowdays = 0 then
      write('FIRST                LAST            DOB')
    else
      write('FIRST                LAST            DOB            YEARS      DAYS')
  end;

Procedure displayit(col:integer;var row:integer;posit:integer;
          size:integer;var data:datatype);

  var cnt:integer;

  begin
    for cnt := 0 to SCSIZE-1 do
      begin
        gotoxy(1,cnt+TOPSC);
        write('':80)
      end;
    if row > posit then row := posit;
    for cnt := posit-row to posit-row+SCSIZE-1 do
      if (cnt < size) then
        begin
          gotoxy(offset[0],cnt-posit+row+TOPSC);
          write(data[cnt]^.first);
          gotoxy(offset[1],cnt-posit+row+TOPSC);
          write(data[cnt]^.last);
          gotoxy(offset[2],cnt-posit+row+TOPSC);
          write(datetostr(data[cnt]^.date));
          if (gshowdays = 1) and (data[cnt]^.date.year > 0) and
          (datevalid(data[cnt]^.date)) then
            begin
              gotoxy(offset[3],cnt-posit+row+TOPSC);
              write(yearsold(data[cnt]^.date):(offset[4]-offset[3]));
              gotoxy(offset[4],cnt-posit+row+TOPSC);
              write(daysold(data[cnt]^.date):(offset[5]-offset[4]))
            end
        end;
    highlight(offset[col],row+TOPSC,offset[col+1]-offset[col]);
    inputprompt(posit,col)
  end;


Procedure init(var col:integer;var row:integer;var posit:integer;
                   var size:integer);

  begin
    col := 0;
    row := 0;
    posit := 0;
    size := 0
  end;


Procedure Up(col:integer;var row:integer;var posit:integer;
          size:integer;var data:datatype);

  var cnt:integer;

  begin
    if (row = 0) and (posit > 0) then
      begin
        posit := posit - 1;
        displayit(col,row,posit,size,data)
      end
    else if posit > 0 then
      begin
        unhighlight(offset[col],row+TOPSC,offset[col+1]-offset[col]);
        row := row - 1;
        posit := posit - 1;
        highlight(offset[col],row+TOPSC,offset[col+1]-offset[col])
      end;
    gotoxy(1,TOPSC+SCSIZE+1);
    write('':80);
    inputprompt(posit,col)
  end;

Procedure Down(col:integer;var row:integer;var posit:integer;
                               size:integer;var data:datatype);

  var cnt:integer;

  begin
    if (row = SCSIZE-1) and (posit < size) and (posit < MAXDATASIZE-1) then
      begin
        posit := posit + 1;
        displayit(col,row,posit,size,data)
      end
    else if (posit < size) and (posit < MAXDATASIZE-1) then
      begin
        unhighlight(offset[col],row+TOPSC,offset[col+1]-offset[col]);
        row := row + 1;
        posit := posit + 1;
        highlight(offset[col],row+TOPSC,offset[col+1]-offset[col])
      end;
    gotoxy(1,TOPSC+SCSIZE+1);
    write('':80);
    inputprompt(posit,col)
  end;

Procedure pgup(col:integer;var row:integer;var posit:integer;
                               size:integer;var data:datatype);

  begin
    posit := posit - SCSIZE + 1;
    if posit < 0 then posit := 0;
    gotoxy(1,TOPSC+SCSIZE+1);
    write('':80);
    displayit(col,row,posit,size,data)
  end;

Procedure pgdown(col:integer;var row:integer;var posit:integer;
                                 size:integer;var data:datatype);

  begin
    posit := posit + SCSIZE - 1;
    if posit > size then posit := size;
    if posit > MAXDATASIZE-1 then posit := MAXDATASIZE-1;
    gotoxy(1,TOPSC+SCSIZE+1);
    write('':80);
    displayit(col,row,posit,size,data)
  end;


Procedure Left(var col:integer;row:integer;posit:integer);

  begin
    unhighlight(offset[col],row+TOPSC,offset[col+1]-offset[col]);
    if (col = 0) then col := 2
    else col := col - 1;
    highlight(offset[col],row+TOPSC,offset[col+1]-offset[col]);
    inputprompt(posit,col)
  end;

Procedure Right(var col:integer;row:integer;posit:integer);

  begin
    unhighlight(offset[col],row+TOPSC,offset[col+1]-offset[col]);
    if (col = 2) then col := 0
    else col := col + 1;
    highlight(offset[col],row+TOPSC,offset[col+1]-offset[col]);
    inputprompt(posit,col)
  end;


Procedure Del(col:integer;row:integer;posit:integer;
                var size:integer;var data:datatype);

  var cnt:integer;

  begin
    if (posit < size) then
      begin
        dispose(data[posit]);
        for cnt := posit to size-2 do
          data[cnt] := data[cnt+1];
        size := size - 1;
        displayit(col,row,posit,size,data);
        gotoxy(1,TOPSC+SCSIZE+1);
        write('':80);
        inputprompt(posit,col)
      end
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



Function change(x:string;col,row,posit:integer;
          var size:integer;var data:datatype):integer;

  var cnt:integer;
      done:boolean;
      temp:integer;

  begin
    if posit = size then
      begin
        new(data[posit]);
        setdate(data[posit]^.date,'101');
        data[posit]^.first := '';
        data[posit]^.last := '';
        size := posit + 1
      end;
    case col of
      0:data[posit]^.first := x;
      1:data[posit]^.last := x;
      2:setdate(data[posit]^.date,x)
    end;
    gotoxy(1,row+TOPSC);
    write('':80);
    gotoxy(offset[0],row+TOPSC);
    write(data[posit]^.first);
    gotoxy(offset[1],row+TOPSC);
    write(data[posit]^.last);
    gotoxy(offset[2],row+TOPSC);
    write(datetostr(data[posit]^.date));
    if (gshowdays = 1) and (data[posit]^.date.year > 0) and
      (datevalid(data[posit]^.date)) then
      begin
        gotoxy(offset[3],row+TOPSC);
        write(yearsold(data[posit]^.date):(offset[4]-offset[3]));
        gotoxy(offset[4],row+TOPSC);
        write(daysold(data[posit]^.date):(offset[5]-offset[4]))
      end;
    highlight(offset[col],row+TOPSC,offset[col+1]-offset[col]);
    if (posit = size-1) and (col < 2) then
      begin
        cnt := 0;
        done := false;
        while (cnt < size-1) and (not done) do
          begin
            if comparerec(0,data[cnt],data[posit]) = 0 then
              begin
                gotoxy(1,TOPSC+SCSIZE+1);
                write(chr(7)+'WARNING: ',data[cnt]^.first,' ',data[cnt]^.last,' ');
                write(datetostr(data[cnt]^.date),' is already in database.');
                done := true;
                temp := 0
              end;
            cnt := cnt + 1
          end;
        if (not done) then
          begin
            gotoxy(1,TOPSC+SCSIZE+1);
            write('':80);
            temp := 1
          end
      end
    else if (col = 2) then
      begin
        if datevalid(data[posit]^.date) then
          begin
            gotoxy(1,TOPSC+SCSIZE+1);
            write('':80);
            temp := 1
          end
        else
          begin
            gotoxy(1,TOPSC+SCSIZE+1);
            write(chr(7)+'WARNING: Invalid date.');
            temp := 0
          end
      end
    else temp := 1;
    if temp = 0 then inputprompt(posit,col);
    change := temp
  end;



Procedure clearall(var size:integer;var data:datatype);

  var cnt:integer;

  begin
    for cnt := 0 to size-1 do
      dispose(data[cnt]);
    size := 0
  end;

Procedure checkenvwrite;

  begin
    if getenv('BDAYFILE') = '' then
      begin
        writeln('Environment variable BDAYFILE is undefined.');
        halt(0)
      end;
    if not filecreation(getenv('BDAYFILE')) then
      begin
        writeln('File write error.  Check environment variable BDAYFILE.');
        halt(0)
      end
  end;

Procedure checkenvread;

var temp:string;
    f:file;
    escpressed:boolean;

  begin
    if getenv('BDAYFILE') = '' then
      begin
        writeln('Environment variable BDAYFILE is undefined.');
        halt(0)
      end;
    if not fileexists(getenv('BDAYFILE')) then
      begin
        writeln('File in environment variable BDAYFILE does not exist.');
        write('Create it <y,n>? ');
        getinput(temp,escpressed);
        if (temp[0] = chr(0)) or (not (temp[1] in ['Y','y'])) then halt(0);
        checkenvwrite;
        assign(f,getenv('BDAYFILE'));
        rewrite(f);
        close(f)
      end
  end;

Procedure savedata(size:integer;var data:datatype);

  var f:file of node;
      cnt:integer;

  begin
    checkenvwrite;
    assign(f,getenv('BDAYFILE'));
    rewrite(f);
    for cnt := 0 to size-1 do
      write(f,data[cnt]^);
    close(f)
  end;

Procedure getdata(var size:integer;var data:datatype);

  var f:file of node;
      cnt:integer;

  begin
    checkenvread;
    clearall(size,data);
    assign(f,getenv('BDAYFILE'));
    reset(f);
    cnt := 0;
    while not eof(f) do
      begin
        new(data[cnt]);
        read(f,data[cnt]^);
        cnt := cnt + 1
      end;
    close(f);
    size := cnt
  end;


  Procedure print(size:integer;data:datatype);

    var g:text;
        cnt,posit:integer;
        escpressed:boolean;
        dummy:char;

    procedure heading;

      var i:integer;

      begin
        for i := 1 to TOPMAR do writeln(g);
        if gshowdays = 0 then
          begin
            writeln(g,'NAME'+stringrep(36,32)+'DOB');
            writeln(g,stringrep(50,ord('-')))
          end
        else
          begin
            writeln(g,'NAME'+stringrep(36,32)+'DOB'+stringrep(12,32)+'YEARS'+
            stringrep(6,32)+'DAYS');
            writeln(g,stringrep(70,ord('-')))
          end
      end;

    procedure ffeed;

      var i:integer;

      begin
        for i := 1 to  PAGESIZE-TOPMAR-posit-2 do writeln(g)
      end;

    begin
      assign(g,'lpt1');
      rewrite(g);
      cnt := 0;
      posit := 0;
      escpressed := false;
      heading;
      while (cnt < size) and (not escpressed) do
        begin
          write(g,data[cnt]^.first+' '+data[cnt]^.last);
          write(g,stringrep(39-length(data[cnt]^.first)-length(data[cnt]^.last),32));
          if (gshowdays = 1) and (data[cnt]^.date.year > 0) and
          (datevalid(data[cnt]^.date)) then
            begin
              write(g,datetostr(data[cnt]^.date));
              write(g,yearsold(data[cnt]^.date):10);
              writeln(g,daysold(data[cnt]^.date):10)
            end
          else
            writeln(g,datetostr(data[cnt]^.date));
          cnt := cnt + 1;
          posit := posit + 1;
          if (cnt >= size) then
            ffeed
          else if cnt mod (PAGESIZE-2*TOPMAR-2) = 0 then
            begin
              ffeed;
              heading;
              posit := 0
            end;
          if keypressed then
            begin
              dummy := readkey;
              if dummy = chr(0) then dummy := readkey;
              if dummy = chr(27) then escpressed := true
            end;
          if escpressed then
            ffeed
        end;
      close(g)
    end;


  begin
    gshowdays := 0;
    offset[0] := 1;
    offset[1] := 22;
    offset[2] := 38;
    offset[3] := 48;
    offset[4] := 58;
    offset[5] := 68;
    name[0] := 'First';
    name[1] := 'Last';
    name[2] := 'DOB';
    init(col,row,posit,size);
    getdata(size,data);
    clrscr;
    displayheading;
    displayit(col,row,posit,size,data);
    done := false;
    ctrl := [13,25];
    scan := [45,60,61,62,63,66,67,72,73,75,77,80,81];
    repeat
      returninput(x,choice,schoice,ctrl,scan);
      case choice of
        chr(0):begin
                 case schoice of
                   chr(45):done := true;
                   chr(60):savedata(size,data);
                   chr(61):begin
                             sort(0,size,data);
                             displayit(col,row,posit,size,data)
                           end;
                   chr(62):begin
                             sort(1,size,data);
                             displayit(col,row,posit,size,data)
                           end;
                   chr(63):begin
                             sort(2,size,data);
                             displayit(col,row,posit,size,data)
                           end;
                   chr(66):begin
                             gshowdays := 1 - gshowdays;
                             clrscr;
                             displayheading;
                             displayit(col,row,posit,size,data)
                           end;
                   chr(67):begin
                             gotoxy(1,1);
                             write('Position paper in printer.  Press ENTER to continue ESC to abort. ');
                             getinput(temp,escpressed);
                             if (not escpressed) then
                               begin
                                 gotoxy(1,1);
                                 write('':79);
                                 gotoxy(1,1);
                                 write('Press ESC to exit print.');
                                 print(size,data)
                               end;
                             inputprompt(posit,col)
                           end;
                   chr(72):up(col,row,posit,size,data);
                   chr(73):pgup(col,row,posit,size,data);
                   chr(75):left(col,row,posit);
                   chr(77):right(col,row,posit);
                   chr(80):down(col,row,posit,size,data);
                   chr(81):pgdown(col,row,posit,size,data)
                 end
                end;
        chr(13):begin
                  if change(x,col,row,posit,size,data) = 1 then
                    begin
                      right(col,row,posit);
                      if col = 0 then down(col,row,posit,size,data)
                    end
                end;
        chr(25):del(col,row,posit,size,data)
      end
    until done;
    savedata(size,data);
    clearall(size,data);
    clrscr
  end.