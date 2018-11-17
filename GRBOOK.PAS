program grader;

uses crt;

const MAXASS = 20;
      MAXST = 400;
      MAXFORM = 6;
type
  studenttype = record
    name:string[25];
    id:string[9];
    major:string[4];
    class:string[2];
    grades:array[1..MAXASS] of integer;
    forms:array[1..MAXASS] of integer
  end;

  grbooktype = record
    size:integer;
    data:array[1..MAXST] of studenttype
  end;

  ptrtype = ^grbooktype;

  var
    gr:ptrtype;
    st,en,avgst,avgen,curass,lineno,formnum,pts,assnum,cnt,code,posit:integer;
    endp1,endp2,dummy:integer;
    sid,filename,key,comm,temp:string;
    done:boolean;
    response:char;
    g:text;
    maxtotal,grtotal:real;

  Function caps(x:string):string;

    var cnt:integer;

    begin
      for cnt := 1 to length(x) do
        if (ord(x[cnt]) > 96) and (ord(x[cnt]) < 123) then
          x[cnt] := chr(ord(x[cnt]) - 32);
      caps := x
    end;

  Function spaces(x:integer):string;

    var temp:string;
        cnt:integer;

    begin
      temp := '';
      for cnt := 1 to x do
        temp := temp + ' ';
      spaces := temp
    end;

  Function findstudent(gr:ptrtype;key:string):integer;

    var temp,cnt:integer;
        done:boolean;

    begin
      if (length(key) > 0) and (key[1] in ['0'..'9']) then
        begin
          cnt := 1;
          done := false;
          key := copy(key,1,9);
          temp := 0;
          while (cnt <= gr^.size) and (not done) do
            begin
              if key = copy(gr^.data[cnt].id,10-length(key),length(key)) then
                begin
                  if temp > 0 then done := true
                  else temp := cnt
                end;
              cnt := cnt + 1
            end;
          if done then findstudent := 0
          else if temp = 0 then findstudent := -1
          else findstudent := temp
        end
      else
        begin
          cnt := 1;
          done := false;
          temp := 0;
          while (cnt <= gr^.size) and (not done) do
            begin
              if caps(key) = caps(copy(gr^.data[cnt].name,1,length(key))) then
                begin
                  if temp > 0 then done := true
                  else temp := cnt
                end;
              cnt := cnt + 1
            end;
          if done then findstudent := 0
          else if temp = 0 then findstudent := -1
          else findstudent := temp
        end
    end;


  Procedure getgrbook(gr:ptrtype;filename:string);

    var f:file of studenttype;
        cnt:integer;

    begin
      assign(f,filename);
      reset(f);
      cnt := 0;
      while not eof(f) do
        begin
          cnt := cnt + 1;
          read(f,gr^.data[cnt])
        end;
      gr^.size := cnt;
      close(f)
    end;


  Procedure savegrbook(gr:ptrtype;filename:string);

    var f:file of studenttype;
        cnt:integer;

    begin
      assign(f,filename);
      rewrite(f);
      for cnt := 1 to gr^.size do
        write(f,gr^.data[cnt]);
      close(f)
    end;

  Function comparerecords(gr:ptrtype;key1,key2,p1,p2:integer):integer;

    begin
      if key1 = 1 then
        begin
          if gr^.data[p1].name > gr^.data[p2].name then comparerecords := 1
          else if gr^.data[p1].name < gr^.data[p2].name then comparerecords := -1
          else comparerecords := 0
        end
      else if key1 = 2 then
        begin
          if gr^.data[p1].id > gr^.data[p2].id then comparerecords := 1
          else if gr^.data[p1].id < gr^.data[p2].id then comparerecords := -1
          else comparerecords := 0
        end
      else if key1 = 3 then
        begin
          if gr^.data[p1].grades[key2] > gr^.data[p2].grades[key2] then comparerecords := 1
          else if gr^.data[p1].grades[key2] < gr^.data[p2].grades[key2] then comparerecords := -1
          else comparerecords := 0
        end
      else comparerecords := 0
    end;

  Procedure shellsort(gr:ptrtype;key1,key2:integer);

    var cnt,size,incr,posit,newposit,count:integer;
        temp:studenttype;
        done:boolean;

    begin
      size := gr^.size-1;
      incr := 1;
      while incr < size div 9 do
        incr := incr*3 + 1;
      while incr > 0 do
        begin
          for cnt := 1 to incr do
	    begin
              posit := cnt + incr;
              while posit <= gr^.size do
                begin
                  newposit := posit - incr;
                  done := false;
                  while not done do
                    begin
                      if comparerecords(gr,key1,key2,posit,newposit) <> -1 then done := true
                      else newposit := newposit - incr;
                      if newposit < cnt then done := true
                    end;
                  temp := gr^.data[posit];
                  count := posit - incr;
                  while count >= newposit+incr do
                    begin
                      gr^.data[count+incr] := gr^.data[count];
                      count := count - incr
                    end;
                  gr^.data[newposit+incr] := temp;
                  posit := posit + incr
                end
            end;
          incr := incr div 3
        end
    end;

  procedure printstats(gr:ptrtype;assnum:integer);

    type
      statformtype = record
        frequency:integer;
        total:integer
      end;

      statarraytype = array[0..MAXFORM] of statformtype;

    var
      s,m:statarraytype;
      cnt,tn,pts:integer;
      r1,r2,tf,sum:real;

    begin
      shellsort(gr,3,assnum);
      for cnt := 0 to MAXFORM do
        begin
          s[cnt].total := 0;
          s[cnt].frequency := 0;
          m[cnt].total := 0;
          m[cnt].frequency := 0
        end;
      for cnt := 1 to gr^.size do
        begin
          tn := gr^.data[cnt].forms[assnum];
          pts := gr^.data[cnt].grades[assnum];
          s[tn].frequency := s[tn].frequency + 1;
          s[tn].total := s[tn].total + pts
        end;
      for cnt := 1 to gr^.size do
        begin
          tn := gr^.data[cnt].forms[assnum];
          pts := gr^.data[cnt].grades[assnum];
          m[tn].frequency := m[tn].frequency + 1;
          if (abs(2*m[tn].frequency - s[tn].frequency - 1) <= 1) then
            m[tn].total := m[tn].total + pts
        end;
      writeln;
      for cnt := 0 to MAXFORM do
        begin
          write('Form '+chr(64+cnt)+' Average: ');
          if s[cnt].frequency > 0 then
            begin
              r1 := s[cnt].total;
              r2 := s[cnt].frequency;
              write(r1/r2:10:2);
              write('     Form '+chr(64+cnt)+' Median: ');
              r1 := m[cnt].total;
              if s[cnt].frequency mod 2 = 0 then
                write(r1/2:10:2)
              else
                write(r1:10:2);
              write('     Form '+chr(64+cnt)+' Count: ');
              writeln(s[cnt].frequency)
            end
          else
            begin
              write('':15);
              write('Form '+chr(64+cnt)+' Median: ');
              write('':15);
              writeln('Form '+chr(64+cnt)+' Count: ')
            end
        end;
      tf := 0.0;
      sum := 0.0;
      for cnt := 0 to MAXFORM do
        begin
          tf := tf + s[cnt].frequency;
          sum := sum + s[cnt].total
        end;
      writeln;
      write('Total Average: ');
      write(sum/tf:11:2);
      write('     Total Median: ');
      r1 := gr^.data[trunc(tf) div 2].grades[assnum];
      r2 := gr^.data[(trunc(tf) div 2) + 1].grades[assnum];
      if trunc(tf) mod 2 = 0 then
        write((r1 + r2) / 2:11:2)
      else
        write(r2:11:2);
      write('     Total Count: ');
      writeln(tf:0:0)
    end;

  procedure printdist(gr:ptrtype;assnum:integer;endp1,endp2:integer);

    type starraytype = array[0..MAXFORM] of integer;

    var s:starraytype;
        tf,cnt,pts,tn:integer;

    begin
      writeln;
      writeln('Distribution from ',endp1,' to ',endp2,':');
      for cnt := 0 to MAXFORM do
        s[cnt] := 0;
      tf := 0;
      for cnt := 1 to gr^.size do
        begin
          tn := gr^.data[cnt].forms[assnum];
          pts := gr^.data[cnt].grades[assnum];
          if (pts >= endp1) and (pts <= endp2) then
            begin
              s[tn] := s[tn] + 1;
              tf := tf + 1
            end
        end;
      writeln;
      for cnt := 0 to MAXFORM do
        writeln('Form '+chr(64+cnt)+' Count: ',s[cnt]);
      writeln;
      writeln('Total Count: ',tf)
    end;


  begin
    assnum := 1;
    formnum := 1;
    write('Enter file name: ');
    readln(filename);
    getmem(gr,sizeof(grbooktype));
    getgrbook(gr,filename);
    clrscr;
    done := false;
    repeat
      write('- ');
      readln(comm);
      if (caps(comm) = 'ADD') and (gr^.size < MAXST) then
        begin
          gr^.size := gr^.size + 1;
          write('Name: ');
          readln(gr^.data[gr^.size].name);
          gr^.size := gr^.size - 1;
          repeat
            write('Id: ');
            readln(sid);
            if (length(sid) <> 9) or
            (findstudent(gr,sid) >= 0) then write(chr(7))
          until (length(sid) = 9) and
          (findstudent(gr,sid) < 0);
          gr^.size := gr^.size + 1;
          gr^.data[gr^.size].id := sid;
          write('Class: ');
          readln(gr^.data[gr^.size].class);
          write('Major: ');
          readln(gr^.data[gr^.size].major);
          for cnt := 1 to MAXASS do
            begin
              gr^.data[gr^.size].grades[cnt] := 0;
              gr^.data[gr^.size].forms[cnt] := 0
            end
        end
      else if (caps(comm) = 'DEL') and (gr^.size > 0) then
        begin
          write('Id: ');
          readln(key);
          posit := findstudent(gr,key);
          if posit = 0 then writeln(chr(7)+'Id is not unique.')
          else if posit < 0 then writeln(chr(7)+'Id not found.');
          if posit > 0 then
            begin
              write('Delete '+gr^.data[posit].name+'<y,n>? ');
              readln(response);
              if response in ['Y','y'] then
                begin
                  for cnt := posit to gr^.size - 1 do
                    gr^.data[cnt] := gr^.data[cnt + 1];
                  gr^.size := gr^.size - 1
                end
            end
        end
      else if caps(comm) = 'SETASSIGN' then
        begin
          repeat
            write('Assignment #: ');
            readln(temp);
            val(temp,assnum,code)
          until (Assnum > 0) and (assnum <= MAXASS)
        end
      else if caps(comm) = 'SETFORM' then
        begin
          repeat
            write('Form #: ');
            readln(temp);
            val(temp,formnum,code)
          until (formnum >= 0) and (formnum <= MAXFORM)
        end
      else if caps(comm) = 'EDIT' then
        begin
         repeat
          repeat
            writeln('Assignment #',assnum);
            writeln('Form: '+chr(64+formnum));
            write('Id: ');
            readln(key);
            if caps(key) <> 'EXIT' then
              begin
                posit := findstudent(gr,key);
                if posit = 0 then writeln(chr(7)+'Id is not unique.')
                else if posit < 0 then writeln(chr(7)+'Id not found.')
              end
            else
              posit := 1
          until (posit > 0);
          if caps(key) <> 'EXIT' then
            begin
              write('Grade: ');
              readln(temp);
              val(temp,pts,code);
              gr^.data[posit].grades[assnum] := pts;
              gr^.data[posit].forms[assnum] := formnum;
            end
          until caps(key) = 'EXIT'
        end
      else if caps(comm) = 'PRINT' then
        begin
          shellsort(gr,1,0);
          savegrbook(gr,filename);
          assign(g,'lpt1');
          rewrite(g);
          for cnt := 1 to 5 do writeln(g);
          writeln(g,'Assignment #',assnum);
          writeln(g);
          writeln(g,'Name'+spaces(22)+'Grade'+' '+'Form');
          for cnt := 1 to 36 do
            write(g,'-');
          writeln(g);
          lineno := 0;
          while (lineno < gr^.size) do
            begin
              lineno := lineno + 1;
              write(g,gr^.data[lineno].name+spaces(26-length(gr^.data[lineno].name)));
              write(g,gr^.data[lineno].grades[assnum]:5,' ');
              if gr^.data[lineno].forms[assnum] > 0 then
                writeln(g,chr(64+gr^.data[lineno].forms[assnum]))
              else
                writeln(g);
              if lineno mod 48 = 0 then
                begin
                  write(g,chr(12));
                  for cnt := 1 to 5 do writeln(g);
                  writeln(g,'Assignment #',assnum);
                  writeln(g);
                  writeln(g,'Name'+spaces(22)+'Grade'+' '+'Form');
                  for cnt := 1 to 36 do
                    write(g,'-');
                  writeln(g)
                end
            end;
          write(g,chr(12));
          close(g)
        end
      else if caps(comm) = 'LONGPR' then
        begin
          repeat
            write('From: ');
            readln(temp);
            val(temp,st,code)
          until (st >= 1) and (st <= MAXASS);
          repeat
            write('To: ');
            readln(temp);
            val(temp,en,code)
          until (en >= 0) AND (en <= MAXASS);
          repeat
            write('Average from (ENTER for all): ');
            readln(temp);
            val(temp,avgst,code)
          until (avgst >= 0) and (avgst <= MAXASS);
          if (avgst > 0) then repeat
            write('Average to: ');
            readln(temp);
            val(temp,avgen,code)
          until (avgen >= 1) and (avgen <= MAXASS);
          if avgst = 0 then
            begin
              avgst := 1;
              avgen := MAXASS
            end;
          repeat
            write('Total possible points: ');
            readln(temp);
            val(temp,maxtotal,code)
          until (maxtotal > 0);
          writeln;
          write('Type "EXIT" to abort print.  Otherwise press ENTER: ');
          readln(temp);
          if temp = '' then
            begin
              shellsort(gr,1,0);
              savegrbook(gr,filename);
              assign(g,'lpt1');
              rewrite(g);
              for cnt := 1 to 5 do writeln(g);
              if (avgst = 1) and (avgen = MAXASS) then
                writeln(g,'Assignments averaged: ALL')
              else
                writeln(g,'Assignments averaged: ',avgst,'-',avgen);
              writeln(g);
              write(g,'Name'+spaces(22));
              for cnt := st to en do
                write(g,cnt:4);
              writeln(g,' Average');
              if en < st - 1 then en := st - 1;
              for cnt := 1 to 34 + (en - st + 1)*4 do
                write(g,'-');
              writeln(g);
              lineno := 0;
              while (lineno < gr^.size) do
                begin
                  lineno := lineno + 1;
                  write(g,gr^.data[lineno].name+spaces(26-length(gr^.data[lineno].name)));
                  for curass := st to en do
                    begin
                      write(g,gr^.data[lineno].grades[curass]:3);
                      if gr^.data[lineno].forms[curass] > 0 then
                        write(g,chr(64+gr^.data[lineno].forms[curass]))
                      else
                        write(g,' ')
                    end;
                  grtotal := 0.0;
                  for curass := avgst to avgen do
                    grtotal := grtotal + gr^.data[lineno].grades[curass];
                  writeln(g,grtotal / maxtotal * 100:8:2);
                  if lineno mod 48 = 0 then
                    begin
                      write(g,chr(12));
                      for cnt := 1 to 5 do writeln(g);
                      if (avgst = 1) and (avgen = MAXASS) then
                        writeln(g,'Assignments averaged: ALL')
                      else
                        writeln(g,'Assignments averaged: ',avgst,'-',avgen);
                      writeln(g);
                      write(g,'Name'+spaces(22));
                      for cnt := st to en do
                        write(g,cnt:4);
                      writeln(g,' Average');
                      if en < st - 1 then en := st - 1;
                      for cnt := 1 to 34 + (en - st + 1)*4 do
                        write(g,'-');
                      writeln(g)
                    end
                end;
              write(g,chr(12));
              close(g)
            end
        end
      else if caps(comm) = 'VIEW' then
        begin
          write('Id: ');
          readln(key);
          posit := findstudent(gr,key);
          if posit = 0 then writeln(chr(7)+'Id is not unique.')
          else if posit < 0 then writeln(chr(7)+'Id not found.');
          if posit > 0 then
            begin
              writeln;
              write('Name: '+gr^.data[posit].name);
              writeln(spaces(40 - length(gr^.data[posit].name))+'Id: '+gr^.data[posit].id);
              write('Major: '+gr^.data[posit].major);
              writeln(spaces(39 - length(gr^.data[posit].major))+'Class: '+gr^.data[posit].class);
              writeln;
              for cnt := 1 to MAXASS do
                begin
                  write(cnt:2,': ',gr^.data[posit].grades[cnt]:3);
                  if gr^.data[posit].forms[cnt] > 0 then
                    writeln(' '+chr(64+gr^.data[posit].forms[cnt]))
                  else
                    writeln
                end;
              writeln
            end
        end
      else if (caps(comm) = 'STAT') and (gr^.size > 0) then
        printstats(gr,assnum)
      else if (caps(comm) = 'DIST') then
        begin
          write('From: ');
          readln(temp);
          val(temp,endp1,code);
          write('To: ');
          readln(temp);
          val(temp,endp2,code);
          if endp1 > endp2 then
            begin
              dummy := endp1;
              endp1 := endp2;
              endp2 := dummy
            end;
          printdist(gr,assnum,endp1,endp2)
        end
      else if caps(comm) = 'EXIT' then done := true
    until done;
    savegrbook(gr,filename);
    freemem(gr,sizeof(grbooktype))
  end.

