program classaid;

  uses crt,dos,printer;

  const maxsize = 12800;
        numstmax = 80;
        numasmax = 80;
        toplineconst = 6;
        bottomlineconst = 20;

  type
    screentype = array[1..25,0..159] of byte;

    datetype = record
      month:byte;
      day:byte;
      year:byte
    end;

    arraytype = array[1..maxsize] of integer;
    gradetype = record
      depth:word;
      data:arraytype
    end;

    stringtype = string[20];

    stptrtype = ^stringtype;
    stentrytype=record
      stptr:stptrtype;
      grptr:integer
    end;
    starraytype=array[1..numstmax] of stentrytype;
    studenttype=record
      data:starraytype;
      size:word
    end;

    asrectype = record
      name:stringtype;
      date:datetype;
      weight:integer
    end;
    asptrtype = ^asrectype;
    asentrytype=record
      asptr:asptrtype;
      grptr:integer
    end;
    asarraytype=array[1..numasmax] of asentrytype;
    assignmenttype=record
      data:asarraytype;
      size:word
    end;

  var path,dummy,temp,classname:string;
      olddirectory,newdirectory:dirstr;
      n:namestr;
      e:extstr;
      opennewfile,userquit,breakout,escpressed,studentfound,done,correctdiskin:boolean;
      diskspaceleft,spaceleft,filespace:longint;
      c:integer;
      response:char;
      grades:gradetype;
      assignments:assignmenttype;
      students:studenttype;
      posit,scol,assignno,studentnum,error:integer;


  Procedure pause;

    var dummy:char;

    begin
      dummy := readkey;
      if dummy = chr(0) then dummy := readkey
    end;

  Function fileexists(filename:string):boolean;

    var error:integer;
            f:file;

    begin
      assign(f,filename);
      {$I-}
        reset(f);
      {$I+}
      error := IOresult;
      if error = 0 then
        begin
          close(f);
          fileexists := true
        end
      else fileexists := false
    end;

  Function filecreation(filename:string):boolean;

    var error:integer;
            f:file;

    begin
      assign(f,filename);
      {$I-}
        rewrite(f);
      {$I+}
      error := IOresult;
      if error = 0 then
        begin
          close(f);
          erase(f);
          filecreation := true
        end
      else filecreation := false
    end;

  Function filevalid(var filename:string):boolean;

    var code:longint;
        f:file;
        numread:word;

    begin
      code := 0;
      assign(f,filename);
      reset(f,1);
      blockread(f,code,sizeof(code),numread);
      if code = 1367231489 then filevalid := true
      else filevalid := false;
      close(f)
    end;

  Procedure getinput(var x:string;var escpressed:boolean);

    var done:boolean;
        temp:char;

    begin
      done := false;
      x := '';
      while (not done) do
        begin
          temp := readkey;
          if temp = chr(27) then
            begin
              done := true;
              escpressed := true
            end
          else if temp = chr(13) then
            begin
              done := true;
              escpressed := false
            end
          else if temp = chr(8) then
            begin
              if length(x) > 0 then
                begin
                  x := copy(x,1,length(x) - 1);
                  gotoxy(wherex - 1,wherey);
                  write(' ');
                  gotoxy(wherex - 1,wherey)
                end
            end
          else if wherex < 80 then
            begin
              x := x + temp;
              write(temp)
            end
        end
    end;

  Procedure getentry(var x:string;c:char;var escpressed:boolean);

    begin
      write(c);
      x := '';
      x := x + c;
      repeat
        c := readkey;
        if c = chr(0) then c := readkey
        else if c = chr(8) then
          begin
            if length(x)<>0 then
              begin
                gotoxy(wherex-1,wherey);
                write(' ');
                gotoxy(wherex-1,wherey);
                x := copy(x,1,length(x)-1)
              end
          end
        else if (c<>chr(13)) and (c<>chr(27)) then
          begin
            if (wherex<80) then
              begin
                x := x + c;
                write(c)
              end
          end
      until (c=chr(13)) or (c=chr(27));
      if c=chr(13) then escpressed := false
      else escpressed := true
    end;

  Procedure displaymessage(x:string;posit:integer;var lx,ly:integer);

    begin
      lx := wherex;
      ly := wherey;
      gotoxy(1,posit);
      write(x)
    end;

  Procedure clearmessage(posit,lx,ly:integer);

    begin
      gotoxy(1,posit);
      write('':80);
      gotoxy(lx,ly)
    end;

  Procedure usermessage(x:string;posit:integer);

    var lx,ly:integer;

    begin
      displaymessage('',posit,lx,ly);
      clearmessage(posit,lx,ly);
      displaymessage(chr(7)+x,posit,lx,ly);
      pause;
      clearmessage(posit,lx,ly)
    end;

  Function getdepth(var x:gradetype):word;

    begin
      getdepth := x.depth;
    end;

  Function getvalue(var x:gradetype;row,col:word):integer;

    var posit:word;

    begin
      posit := (row-1)*x.depth + col;
      getvalue := x.data[posit]
    end;

  Procedure assignvalue(var x:gradetype;row,col:word;val:integer);

    var posit:word;

    begin
      posit := (row-1)*x.depth + col;
      x.data[posit] := val
    end;

  Procedure addcolumn(var x:gradetype;rowsize:word);

    var cnt,count:word;
        temp:word;

    begin
      temp := x.depth + 1;
      for count := rowsize downto 1 do
        for cnt := x.depth downto 1 do
          x.data[temp*(count - 1) + cnt] := x.data[x.depth*(count - 1) + cnt];
      x.depth := temp
    end;

  Procedure deletecol(var x:gradetype;col:word;rowsize:word);

    var cnt,count,temp:word;

    begin
      temp := x.depth - 1;
      for count := 1 to rowsize do
        for cnt := 1 to x.depth do
          begin
            if cnt < col then
              x.data[temp*(count - 1) + cnt] := x.data[x.depth*(count - 1) + cnt]
            else if cnt > col then
              x.data[temp*(count - 1) + cnt - 1] := x.data[x.depth*(count - 1) + cnt]
          end;
      x.depth := temp
    end;

  Procedure deleterow(var x:gradetype;row:word;rowsize:word);

    var cnt,cnt1:word;
        tempval:integer;

    begin
      for cnt := row to rowsize - 1 do
        for cnt1 := 1 to x.depth do
          begin
            tempval := getvalue(x,cnt+1,cnt1);
            assignvalue(x,cnt,cnt1,tempval)
          end
    end;

  Function comparedates(var x,y:datetype):integer;

    begin
      if x.year > y.year then comparedates := 1
      else if x.year < y.year then comparedates := -1
      else if x.month > y.month then comparedates := 1
      else if x.month < y.month then comparedates := -1
      else if x.day > y.day then comparedates := 1
      else if x.day < y.day then comparedates := -1
      else comparedates := 0
    end;

  Procedure getdate(var x:datetype;var escpressed:boolean;var success:boolean);

    var tempdate:string[6];
        cnt,posit,code:integer;
        done:boolean;
        ch:char;

    Function remap(x:integer):integer;

      var section,posit:integer;

      begin
        section := (x - 1) div 2;
        posit := (x - 1) mod 2;
        remap := 3*section + posit
      end;

    begin
      if wherex > 72 then success := false
      else
        begin
          tempdate[0] := chr(6);
          posit := wherex;
          write('  /  /  ');
          gotoxy(posit,wherey);
          cnt := 1;
          done := false;
          while (not done) do
            begin
              if (cnt < 7) then gotoxy(posit+remap(cnt),wherey)
              else gotoxy(posit + 8,wherey);
              ch := readkey;
              if ch = chr(0) then ch := readkey;
              if (ch = chr(8)) and (cnt > 1) then
                begin
                  cnt := cnt - 1;
                  gotoxy(posit+remap(cnt),wherey);
                  write(' ')
                end
              else
                if ch = chr(27) then
                  begin
                    escpressed := true;
                    done := true
                  end
              else
                if (ch = chr(13)) and (cnt = 7) then
                  begin
                    escpressed := false;
                    done := true
                  end
              else
                if (ch in ['0'..'9']) and (cnt < 7) then
                  begin
                    write(ch);
                    tempdate[cnt] := ch;
                    cnt := cnt + 1
                  end
            end;
          if not escpressed then
            begin
              val(copy(tempdate,5,2),x.year,code);
              if x.year < 80 then x.year := x.year + 100;
              val(copy(tempdate,1,2),x.month,code);
              val(copy(tempdate,3,2),x.day,code)
            end
        end
    end;

  Function printdate(var x:datetype):string;

    var m,d,y:string[2];
        tempyear:byte;

    begin
      str(x.month,m);
      if length(m) < 2 then m := '0'+m;
      str(x.day,d);
      if length(d) < 2 then d := '0'+d;
      tempyear := x.year;
      if tempyear > 99 then tempyear := tempyear - 100;
      str(tempyear,y);
      if length(y) < 2 then y := '0'+y;
      printdate := m+'/'+d+'/'+y
    end;

  Procedure placestudent(var students:studenttype;var posit:integer);

    var done:boolean;
        cnt:integer;
        temp:stentrytype;

    begin
      if posit > 1 then
        if students.data[posit].stptr^<students.data[posit-1].stptr^ then
          begin
            temp := students.data[posit];
            cnt := posit;
            done := false;
            repeat
              students.data[cnt] := students.data[cnt-1];
              cnt := cnt - 1;
              if cnt = 1 then done := true
              else
                if temp.stptr^>=students.data[cnt-1].stptr^ then done := true
            until done;
            students.data[cnt] := temp;
            posit := cnt
          end;
      if posit < students.size then
        if students.data[posit].stptr^>students.data[posit+1].stptr^ then
          begin
            temp := students.data[posit];
            cnt := posit;
            done := false;
            repeat
              students.data[cnt] := students.data[cnt+1];
              cnt := cnt + 1;
              if cnt = students.size then done := true
              else
                if temp.stptr^<=students.data[cnt+1].stptr^ then done := true
            until done;
            students.data[cnt] := temp;
            posit := cnt
          end
    end;

  Procedure placeassignment(var assignments:assignmenttype;var posit:integer);

    var done:boolean;
        cnt:integer;
        temp:asentrytype;
        first,next:datetype;

    begin
      if posit > 1 then
        begin
          next := assignments.data[posit].asptr^.date;
          first := assignments.data[posit-1].asptr^.date;
          if comparedates(next,first) = - 1 then
            begin
              temp := assignments.data[posit];
              cnt := posit;
              done := false;
              repeat
                assignments.data[cnt] := assignments.data[cnt-1];
                cnt := cnt - 1;
                if cnt = 1 then done := true
                else
                  begin
                    next := temp.asptr^.date;
                    first := assignments.data[cnt-1].asptr^.date;
                    if comparedates(next,first) > -1 then done := true
                  end
              until done;
              assignments.data[cnt] := temp;
              posit := cnt
            end
        end;
      if posit < assignments.size then
        begin
          first := assignments.data[posit].asptr^.date;
          next := assignments.data[posit+1].asptr^.date;
          if comparedates(first,next) = 1 then
            begin
              temp := assignments.data[posit];
              cnt := posit;
              done := false;
              repeat
                assignments.data[cnt] := assignments.data[cnt+1];
                cnt := cnt + 1;
                if cnt = assignments.size then done := true
                else
                  begin
                    first := temp.asptr^.date;
                    next := assignments.data[cnt+1].asptr^.date;
                    if comparedates(first,next) < 1 then done := true
                  end
              until done;
              assignments.data[cnt] := temp;
              posit := cnt
            end
        end
    end;

  Procedure searchforstudent(var students:studenttype;var skey:string;var posit:integer;var found:boolean);

    var cnt:integer;

    begin
      found := false;
      cnt := 1;
      while (cnt<=students.size) and (not found) do
        if skey = students.data[cnt].stptr^ then found := true
        else cnt := cnt + 1;
      if found then posit := cnt
    end;

  Procedure searchforassignment(var assignments:assignmenttype;var skey:string;var posit:integer;var found:boolean);

    var cnt:integer;

    begin
      found := false;
      cnt := 1;
      while (cnt<=assignments.size) and (not found) do
        if skey = assignments.data[cnt].asptr^.name then found := true
        else cnt := cnt + 1;
      if found then posit := cnt
    end;


  Procedure addstudent(var students:studenttype;var grades:gradetype;rowsize:word;var posit:integer;var scol:integer);

    var name:string;
        cnt:integer;
        p:stptrtype;
        dummy:integer;
        escpressed,studentfound:boolean;

    begin
      clrscr;
      gotoxy(1,12);
      write('Enter name of new student: ');
      getinput(name,escpressed);
      if (not escpressed) then
        begin
          if name[0] > chr(20) then name[0] := chr(20);
          searchforstudent(students,name,dummy,studentfound);
          if (not studentfound) then
            begin
              addcolumn(grades,rowsize);
              new(p);
              p^ := copy(name,1,20);
              students.size := students.size + 1;
              students.data[students.size].stptr := p;
              students.data[students.size].grptr := students.size;
              for cnt := 1 to rowsize do
                assignvalue(grades,cnt,students.size,-1);
              posit := students.size;
              placestudent(students,posit);
              scol := (toplineconst + bottomlineconst) div 2
            end
          else usermessage('That student already exists.',14)
        end
    end;

  Procedure addassignment(var assignments:assignmenttype;var grades:gradetype;var posit:integer);

    var n,temp:string;
        d:datetype;
        w:integer;
        cnt,code:integer;
        dummy,escpressed:boolean;
        p:asptrtype;

    begin
      clrscr;
      gotoxy(1,10);
      write('Assignment name: ');
      getinput(n,escpressed);
      if escpressed then exit;
      gotoxy(1,12);
      write('Assignment date: ');
      getdate(d,escpressed,dummy);
      if escpressed then exit;
      gotoxy(1,14);
      write('Assignment weight: ');
      getinput(temp,escpressed);
      if escpressed then exit;
      val(temp,w,code);
      new(p);
      p^.name := copy(n,1,20);
      p^.date := d;
      p^.weight := w;
      assignments.size := assignments.size + 1;
      assignments.data[assignments.size].asptr := p;
      assignments.data[assignments.size].grptr := assignments.size;
      for cnt := 1 to grades.depth do
        assignvalue(grades,assignments.size,cnt,-1);
      posit := assignments.size;
      placeassignment(assignments,posit)
    end;

  Procedure showgrade(x:integer);

    begin
      if x < 0 then write('NG   ')
      else write(x:5)
    end;

  Procedure highlight(row,column,size:integer);

    var p:^screentype;
        cnt:integer;

    begin
      p := ptr($b800,$0);
      cnt := column;
      while (cnt<column+size) and (cnt<80) do
        begin
          p^[row,2*cnt-1] := 112;
          cnt := cnt + 1
        end
    end;

  Procedure unhighlight(row,column,size:integer);

    var p:^screentype;
        cnt:integer;

    begin
      p := ptr($b800,$0);
      cnt := column;
      while (cnt<column+size) and (cnt<80) do
        begin
          p^[row,2*cnt-1] := 7;
          cnt := cnt + 1
        end
    end;

  Procedure displayfilename(var filename:string);

    var lx,ly:integer;

    begin
      lx := wherex;
      ly := wherey;
      gotoxy(1,1);
      write('':80);
      gotoxy(1,1);
      write('FILENAME: ',copy(filename,1,70));
      gotoxy(lx,ly)
    end;


  Procedure displayassignment(var assignments:assignmenttype;var assignno:integer);

    var lx,ly,cnt:integer;

    begin
      lx := wherex;
      ly := wherey;
      if assignno > assignments.size then assignno := assignments.size
      else if assignno < 1 then assignno := 1;
      gotoxy(1,3);
      write('':80);
      gotoxy(1,3);
      write('NO.: ',assignno);
      gotoxy(50,3);
      write('DATE: ',printdate(assignments.data[assignno].asptr^.date));
      gotoxy(1,4);
      write('':80);
      gotoxy(1,4);
      write('NAME: ',assignments.data[assignno].asptr^.name);
      gotoxy(50,4);
      write('WEIGHT: ',assignments.data[assignno].asptr^.weight);
      gotoxy(1,5);
      for cnt := 1 to 80 do write(chr(196));
      gotoxy(wherex,wherey)
    end;

  Procedure displaygrades(var grades:gradetype;var students:studenttype;var assignments:assignmenttype;
                          var assignno:integer;var posit:integer;var scol:integer);

    var cnt:integer;

    begin
      for cnt := toplineconst to bottomlineconst do
        begin
          gotoxy(1,cnt);
          write('':80)
        end;
      if assignno > assignments.size then assignno := assignments.size
      else if assignno < 1 then assignno := 1;
      if posit > students.size then posit := students.size
      else if posit < 1 then posit := 1;
      if scol < toplineconst then scol := toplineconst
      else if scol > bottomlineconst then scol := bottomlineconst;
      if scol > posit + toplineconst - 1 then scol := posit + toplineconst - 1;
      for cnt := posit - scol + toplineconst to posit - scol + bottomlineconst do
        begin
          if cnt <= students.size then
            begin
              gotoxy(1,cnt-posit + scol);
              write(students.data[cnt].stptr^);
              gotoxy(40,cnt-posit + scol);
              showgrade(getvalue(grades,assignments.data[assignno].grptr,students.data[cnt].grptr))
            end
          else
            begin
              gotoxy(1,cnt-posit+scol);
              write('':80)
            end
        end;
      highlight(scol,40,5)
    end;

  Procedure moveup(var grades:gradetype;var students:studenttype;var assignments:assignmenttype;
                   var assignno:integer;var posit:integer;var scol:integer);

    begin
      if posit > 1 then
        begin
          if scol > toplineconst then
            begin
              unhighlight(scol,40,5);
              scol := scol - 1;
              posit := posit - 1;
              highlight(scol,40,5)
            end
          else
            begin
              posit := posit - 1;
              displaygrades(grades,students,assignments,assignno,posit,scol)
            end
        end
    end;

  Procedure movedown(var grades:gradetype;var students:studenttype;var assignments:assignmenttype;
                     var assignno:integer;var posit:integer;var scol:integer);

    begin
      if posit < students.size then
        begin
          if scol < bottomlineconst then
            begin
              unhighlight(scol,40,5);
              scol := scol + 1;
              posit := posit + 1;
              highlight(scol,40,5)
            end
          else
            begin
              posit := posit + 1;
              displaygrades(grades,students,assignments,assignno,posit,scol)
            end
        end
    end;

  Procedure moveleft(var grades:gradetype;var students:studenttype;var assignments:assignmenttype;
                     var assignno:integer;var posit:integer;var scol:integer);

    begin
      assignno := assignno - 1;
      displayassignment(assignments,assignno);
      displaygrades(grades,students,assignments,assignno,posit,scol)
    end;

  Procedure moveright(var grades:gradetype;var students:studenttype;var assignments:assignmenttype;
                      var assignno:integer;var posit:integer;var scol:integer);

    begin
      assignno := assignno + 1;
      displayassignment(assignments,assignno);
      displaygrades(grades,students,assignments,assignno,posit,scol)
    end;

  Procedure pageup(var grades:gradetype;var students:studenttype;var assignments:assignmenttype;
                     var assignno:integer;var posit:integer;var scol:integer);

    begin
      posit := posit - bottomlineconst + toplineconst;
      displaygrades(grades,students,assignments,assignno,posit,scol)
    end;

  Procedure pagedown(var grades:gradetype;var students:studenttype;var assignments:assignmenttype;
                     var assignno:integer;var posit:integer;var scol:integer);

    begin
      posit := posit + bottomlineconst - toplineconst;
      displaygrades(grades,students,assignments,assignno,posit,scol)
    end;

  Procedure deletestudent(var grades:gradetype;var students:studenttype;rowsize:word;var posit:integer;var scol:integer);

    var cnt:integer;
        deletedcol:integer;

    begin
      deletedcol := students.data[posit].grptr;
      deletecol(grades,deletedcol,rowsize);
      dispose(students.data[posit].stptr);
      for cnt := posit to students.size - 1 do
        students.data[cnt] := students.data[cnt+1];
      students.size := students.size - 1;
      for cnt := 1 to students.size do
        if students.data[cnt].grptr > deletedcol then
          students.data[cnt].grptr := students.data[cnt].grptr - 1;
      if posit > students.size then
        begin
          posit := students.size;
          if scol > toplineconst then scol := scol - 1
        end
    end;

  Procedure deleteassignment(var grades:gradetype;var assignments:assignmenttype;var assignno:integer);

    var cnt:integer;
        deletedrow:integer;

    begin
      deletedrow := assignments.data[assignno].grptr;
      deleterow(grades,deletedrow,assignments.size);
      dispose(assignments.data[assignno].asptr);
      for cnt := assignno to assignments.size - 1 do
        assignments.data[cnt] := assignments.data[cnt+1];
      assignments.size := assignments.size - 1;
      for cnt := 1 to assignments.size do
        if assignments.data[cnt].grptr > deletedrow then
          assignments.data[cnt].grptr := assignments.data[cnt].grptr - 1;
      if assignno > assignments.size then assignno := assignments.size
    end;

  Procedure changestudent(var newname:string;var students:studenttype;var posit:integer);

    begin
      students.data[posit].stptr^ := copy(newname,1,20);
      placestudent(students,posit)
    end;

  Procedure changeassignment(var assignments:assignmenttype;var assignno:integer);

    var n:string;
        d:datetype;
        w:integer;
        escpressed:boolean;
        lx,ly,code:integer;
        dummy:boolean;
        tempw:string;

    begin
      displaymessage('',1,lx,ly);
      clearmessage(1,lx,ly);
      displaymessage('Enter assignment name: ',1,lx,ly);
      getinput(n,escpressed);
      clearmessage(1,lx,ly);
      if not escpressed then
        assignments.data[assignno].asptr^.name := copy(n,1,20);
      displaymessage('Enter assignment date: ',1,lx,ly);
      getdate(d,escpressed,dummy);
      clearmessage(1,lx,ly);
      if not escpressed then
        assignments.data[assignno].asptr^.date := d;
      displaymessage('Enter assignment weight: ',1,lx,ly);
      getinput(tempw,escpressed);
      clearmessage(1,lx,ly);
      if not escpressed then
        begin
          val(tempw,w,code);
          assignments.data[assignno].asptr^.weight := w
        end;
      placeassignment(assignments,assignno)
    end;

  Function average(var grades:gradetype;var students:studenttype;var assignments:assignmenttype;studentnum:integer):real;

    var total,score:real;
        cnt:integer;

    begin
      total := 0.0;
      score := 0.0;
      for cnt := 1 to assignments.size do
        begin
          if getvalue(grades,assignments.data[cnt].grptr,students.data[studentnum].grptr) >= 0 then
            begin
              total := total + assignments.data[cnt].asptr^.weight;
              score := score + getvalue(grades,assignments.data[cnt].grptr,students.data[studentnum].grptr)
            end
        end;
      if total = 0.0 then average := -1.0
      else average := score / total * 100
    end;

  Procedure mywrite(x:string;var success:boolean);

    var error:integer;

    begin
      {$I-}
        write(lst,x);
      {$I+}
      error := IOresult;
      if error <> 0 then success := false
      else success := true
    end;

   Procedure previewreport(var grades:gradetype;var students:studenttype;var assignments:assignmenttype;
                          studentnum:integer;var classname:string;var done:boolean);

    var cnt,cline,count:integer;
        dummy:char;
        pageno:integer;
        avg:real;

    begin
      clrscr;
      for cnt := 1 to 59 do write(' ');
      writeln('Page: 1');
      for cnt := 1 to 27 do write(' ');
      writeln('Individual Student Report');
      writeln;
      for cnt := 1 to 9 do write(' ');
      write('Student: '+students.data[studentnum].stptr^);
      for cnt := 1 to 26 - length(students.data[studentnum].stptr^) do write(' ');
      writeln('Class: '+copy(classname,1,20));
      writeln;
      for cnt := 1 to 14 do write(' ');
      write('Assignment');
      for cnt := 1 to 8 do write(' ');
      write('Date');
      for cnt := 1 to 3 do write(' ');
      write('Weight');
      write(' ');
      writeln('Grade');
      for cnt := 1 to 9 do write(' ');
      for cnt := 10 to 29 do write('-');
      write(' ');
      for cnt := 31 to 38 do write('-');
      write(' ');
      for cnt := 40 to 45 do write('-');
      write(' ');
      for cnt := 47 to 51 do write('-');
      writeln;
      done := false;
      cline := 8;
      count := 0;
      pageno := 1;
      while (count < assignments.size) and (not done) do
        begin
          count := count + 1;
          if getvalue(grades,assignments.data[count].grptr,students.data[studentnum].grptr) >= 0 then
            begin
              if cline > 20 then
                begin
                  gotoxy(17,24);
                  write('Press ENTER to continue or ESC to exit preview.');
                  repeat
                    dummy := readkey;
                    if dummy = chr(0) then dummy := readkey
                    else if dummy = chr(27) then
                      begin
                        gotoxy(1,21);
                        done := true
                      end
                  until (dummy = chr(13)) or (dummy = chr(27));
                  if (not done) then
                    begin
                      clrscr;
                      pageno := pageno + 1;
                      for cnt := 1 to 59 do write(' ');
                      writeln('Page: ',pageno);
                      writeln;
                      cline := 3
                    end
                end;
              if (not done) then
                begin
                  for cnt := 1 to 9 do write(' ');
                  write(assignments.data[count].asptr^.name);
                  for cnt := 1 to 21 - length(assignments.data[count].asptr^.name) do
                    write(' ');
                  write(printdate(assignments.data[count].asptr^.date));
                  write(' ');
                  write(assignments.data[count].asptr^.weight:6);
                  write(' ');
                  write(getvalue(grades,assignments.data[count].grptr,students.data[studentnum].grptr):5);
                  writeln;
                  cline := cline + 1
                end
            end
        end;
      writeln;
      for cnt := 1 to 33 do write(' ');
      avg := average(grades,students,assignments,studentnum);
      if avg = -1.0 then write('Average: NA')
      else write('Average: ',average(grades,students,assignments,studentnum):0:1);
      gotoxy(1,24);
      write('':80);
      gotoxy(27,24);
      write('Press any key to continue.');
      pause
    end;

  Procedure printreport(var grades:gradetype;var students:studenttype;var assignments:assignmenttype;
                        studentnum:integer;var classname:string;var done:boolean;var success:boolean);

    var cnt,cline,count:integer;
        dummy:char;
        temp:string;
        pageno:integer;
        avg:real;

    begin
      success := true;
      temp := '';
      for cnt := 1 to 5 do
        temp := temp + chr(13) + chr(10);
      mywrite(temp,success);
      if not success then exit;
      temp := '';
      for cnt := 1 to 59 do
        temp := temp + ' ';
      mywrite(temp,success);
      if not success then exit;
      mywrite('Page: 1'+chr(13)+chr(10),success);
      if not success then exit;
      temp := '';
      for cnt := 1 to 27 do
        temp := temp + ' ';
      mywrite(temp,success);
      if not success then exit;
      mywrite('Individual Student Report'+chr(13)+chr(10)+chr(13)+chr(10),success);
      if not success then exit;
      temp := '';
      for cnt := 1 to 9 do
        temp := temp + ' ';
      mywrite(temp,success);
      if not success then exit;
      mywrite('Student: '+students.data[studentnum].stptr^,success);
      if not success then exit;
      temp := '';
      for cnt := 1 to 26 - length(students.data[studentnum].stptr^) do
        temp := temp + ' ';
      mywrite(temp,success);
      if not success then exit;
      mywrite('Class: '+copy(classname,1,20)+chr(13)+chr(10)+chr(13)+chr(10),success);
      if not success then exit;
      temp := '';
      for cnt := 1 to 14 do
        temp := temp + ' ';
      mywrite(temp,success);
      if not success then exit;
      mywrite('Assignment',success);
      if not success then exit;
      temp := '';
      for cnt := 1 to 8 do
        temp := temp + ' ';
      mywrite(temp,success);
      if not success then exit;
      mywrite('Date',success);
      if not success then exit;
      temp := '';
      for cnt := 1 to 3 do
        temp := temp + ' ';
      mywrite(temp,success);
      if not success then exit;
      mywrite('Weight ',success);
      if not success then exit;
      mywrite('Grade'+chr(13)+chr(10),success);
      if not success then exit;
      temp := '';
      for cnt := 1 to 9 do
        temp := temp + ' ';
      mywrite(temp,success);
      if not success then exit;
      temp := '';
      for cnt := 10 to 29 do
        temp := temp + '-';
      mywrite(temp,success);
      if not success then exit;
      mywrite(' ',success);
      if not success then exit;
      temp := '';
      for cnt := 31 to 38 do
        temp := temp + '-';
      mywrite(temp,success);
      if not success then exit;
      mywrite(' ',success);
      if not success then exit;
      temp := '';
      for cnt := 40 to 45 do
        temp := temp + '-';
      mywrite(temp,success);
      if not success then exit;
      mywrite(' ',success);
      if not success then exit;
      temp := '';
      for cnt := 47 to 51 do
        temp := temp + '-';
      mywrite(temp+chr(13)+chr(10),success);
      if not success then exit;
      done := false;
      cline := 8;
      count := 0;
      pageno := 1;
      while (count < assignments.size) and (not done) do
        begin
          count := count + 1;
          if getvalue(grades,assignments.data[count].grptr,students.data[studentnum].grptr) >= 0 then
            begin
              if keypressed then dummy := readkey;
              if dummy = chr(0) then dummy := readkey
              else if dummy = chr(27) then done := true;
              if cline > 55 then
                begin
                  pageno := pageno + 1;
                  temp := '';
                  for cnt := 1 to 11 do
                    temp := temp + chr(13) + chr(10);
                  mywrite(temp,success);
                  if not success then exit;
                  temp := '';
                  for cnt := 1 to 59 do
                    temp := temp + ' ';
                  mywrite(temp,success);
                  if not success then exit;
                  mywrite('Page: ',success);
                  if not success then exit;
                  str(pageno,temp);
                  mywrite(temp+chr(13)+chr(10)+chr(13)+chr(10),success);
                  if not success then exit;
                  cline := 3
                end;
              temp := '';
              for cnt := 1 to 9 do
                temp := temp + ' ';
              mywrite(temp,success);
              if not success then exit;
              mywrite(assignments.data[count].asptr^.name,success);
              if not success then exit;
              temp := '';
              for cnt := 1 to 21 - length(assignments.data[count].asptr^.name) do
                temp := temp + ' ';
              mywrite(temp,success);
              if not success then exit;
              mywrite(printdate(assignments.data[count].asptr^.date)+' ',success);
              if not success then exit;
              str(assignments.data[count].asptr^.weight:6,temp);
              mywrite(temp+' ',success);
              if not success then exit;
              str(getvalue(grades,assignments.data[count].grptr,students.data[studentnum].grptr):5,temp);
              mywrite(temp,success);
              if not success then exit;
              mywrite(chr(13)+chr(10),success);
              if not success then exit;
              cline := cline + 1
            end
        end;
      mywrite(chr(13)+chr(10),success);
      if not success then exit;
      temp := '';
      for cnt := 1 to 33 do
        temp := temp + ' ';
      mywrite(temp,success);
      if not success then exit;
      mywrite('Average: ',success);
      if not success then exit;
      avg := average(grades,students,assignments,studentnum);
      if avg = -1.0 then
        begin
          mywrite('NA',success);
          if not success then exit
        end
      else
        begin
          str(avg:0:1,temp);
          mywrite(temp,success);
          if not success then exit
        end;
      mywrite(chr(12),success);
      if not success then exit;
    end;

  Procedure printindividualreport(var grades:gradetype;var students:studenttype;var assignments:assignmenttype;
                                  var studentnum:integer;var classname:string);

    var done,success:boolean;

    begin
      clrscr;
      success := true;
      gotoxy(1,10);
      write('Printing report for ',students.data[studentnum].stptr^);
      gotoxy(1,14);
      write('Press Esc to quit printing.');
      printreport(grades,students,assignments,studentnum,classname,done,success);
      if not success then usermessage('Check Printer.',16)
    end;

  Procedure edit(var grades:gradetype;var students:studenttype;var assignments:assignmenttype;
                 var assignno:integer;var posit:integer;var scol:integer;var filename:string);

    var choice,response:char;
        done,previewdone:boolean;
        temp,n:string;
        code,lx,ly:integer;
        entry:integer;
        escpressed:boolean;

    begin
      displayfilename(filename);
      displayassignment(assignments,assignno);
      displaygrades(grades,students,assignments,assignno,posit,scol);
      done := false;
      repeat
        choice := readkey;
        if choice = chr(0) then
          begin
            choice := readkey;
            case choice of
              chr(60):begin
                        displaymessage('',1,lx,ly);
                        clearmessage(1,lx,ly);
                        displaymessage('Are you sure you want to delete student<y,n>? ',1,lx,ly);
                        readln(response);
                        clearmessage(1,lx,ly);
                        if response in ['Y','y'] then
                          begin
                            deletestudent(grades,students,assignments.size,posit,scol);
                            if students.size = 0 then done := true
                            else
                              begin
                                displaygrades(grades,students,assignments,assignno,posit,scol);
                                displayfilename(filename)
                              end
                          end
                        else displayfilename(filename)
                      end;
              chr(61):begin
                        displaymessage('',1,lx,ly);
                        clearmessage(1,lx,ly);
                        displaymessage('Change student name to? ',1,lx,ly);
                        getinput(n,escpressed);
                        clearmessage(1,lx,ly);
                        if not escpressed then
                          begin
                            changestudent(n,students,posit);
                            displaygrades(grades,students,assignments,assignno,posit,scol)
                          end;
                        displayfilename(filename);
                      end;
              chr(62):begin
                        displaymessage('',1,lx,ly);
                        clearmessage(1,lx,ly);
                        displaymessage('Are you sure you want to delete assignment<y,n>? ',1,lx,ly);
                        readln(response);
                        clearmessage(1,lx,ly);
                        if response in ['Y','y'] then
                          begin
                            deleteassignment(grades,assignments,assignno);
                            if assignno = 0 then done := true
                            else
                              begin
                                displayassignment(assignments,assignno);
                                displaygrades(grades,students,assignments,assignno,posit,scol);
                                displayfilename(filename)
                              end
                          end
                        else displayfilename(filename)
                      end;
              chr(63):begin
                        changeassignment(assignments,assignno);
                        displayassignment(assignments,assignno);
                        displayfilename(filename)
                      end;
              chr(64):begin
                        displaymessage('',1,lx,ly);
                        clearmessage(1,lx,ly);
                        displaymessage('Goto assignment number? ',1,lx,ly);
                        getinput(temp,escpressed);
                        clearmessage(1,lx,ly);
                        if not escpressed then
                          begin
                            val(temp,assignno,code);
                            displayassignment(assignments,assignno);
                            displaygrades(grades,students,assignments,assignno,posit,scol)
                          end;
                        displayfilename(filename)
                      end;
              chr(65):begin
                        clrscr;
                        gotoxy(1,12);
                        write('Enter class in which student is participating: ');
                        getinput(classname,escpressed);
                        if not escpressed then
                          previewreport(grades,students,assignments,posit,classname,previewdone);
                        clrscr;
                        displayassignment(assignments,assignno);
                        displaygrades(grades,students,assignments,assignno,posit,scol);
                        displayfilename(filename)
                      end;
              chr(66):begin
                        clrscr;
                        gotoxy(1,12);
                        write('Enter class in which student is participating for printout: ');
                        getinput(classname,escpressed);
                        if not escpressed then
                          begin
                            clrscr;
                            gotoxy(1,12);
                            write('Make sure printer is ready.  Press any key to continue.');
                            pause;
                            printindividualreport(grades,students,assignments,posit,classname)
                          end;
                        clrscr;
                        displayassignment(assignments,assignno);
                        displaygrades(grades,students,assignments,assignno,posit,scol);
                        displayfilename(filename)
                      end;
              chr(68):done := true;
              chr(72):moveup(grades,students,assignments,assignno,posit,scol);
              chr(75):moveleft(grades,students,assignments,assignno,posit,scol);
              chr(77):moveright(grades,students,assignments,assignno,posit,scol);
              chr(80):movedown(grades,students,assignments,assignno,posit,scol);
              chr(73):pageup(grades,students,assignments,assignno,posit,scol);
              chr(81):pagedown(grades,students,assignments,assignno,posit,scol)
            end
          end
        else if choice in ['0'..'9','-'] then
          begin
            displaymessage('',1,lx,ly);
            clearmessage(1,lx,ly);
            displaymessage('Grade? ',1,lx,ly);
            getentry(temp,choice,escpressed);
            clearmessage(1,lx,ly);
            if not escpressed then
              begin
                val(temp,entry,code);
                lx := wherex;
                ly := wherey;
                gotoxy(40,scol);
                showgrade(entry);
                highlight(scol,40,5);
                assignvalue(grades,assignments.data[assignno].grptr,students.data[posit].grptr,entry);
                gotoxy(lx,ly)
              end;
            displayfilename(filename)
          end;
      until done;
    end;

  Procedure clearmemory(var grades:gradetype;var students:studenttype;var assignments:assignmenttype);

    var cnt:integer;

    begin
      for cnt := 1 to students.size do
        dispose(students.data[cnt].stptr);
      for cnt := 1 to assignments.size do
        dispose(assignments.data[cnt].asptr);
      grades.depth := 0;
      students.size := 0;
      assignments.size := 0
    end;

  Function spacerequired(row,column:longint):longint;

    begin
      spacerequired := row*28+column*23+2*row*column+10
    end;

  Procedure initializefile(var filename:string);

    var f:file;
        dummy:longint;
        numwritten:word;
        it:array[1..6] of byte;
        cnt:integer;

    begin
      assign(f,filename);
      rewrite(f,1);
      dummy := 1367231489;
      blockwrite(f,dummy,sizeof(dummy),numwritten);
      for cnt := 1 to 6 do
        it[cnt] := 0;
      blockwrite(f,it,sizeof(it),numwritten);
      close(f)
    end;

  Procedure save(var grades:gradetype;var students:studenttype;var assignments:assignmenttype;var filename:string);

    var cnt:integer;
        dummy:longint;
        f:file;
        numwritten:word;

    begin
      assign(f,filename);
      rewrite(f,1);
      dummy := 1367231489;
      blockwrite(f,dummy,sizeof(dummy),numwritten);
      blockwrite(f,students.size,sizeof(students.size),numwritten);
      for cnt := 1 to students.size do
        begin
          blockwrite(f,students.data[cnt].grptr,sizeof(students.data[cnt].grptr),numwritten);
          blockwrite(f,students.data[cnt].stptr^,sizeof(students.data[cnt].stptr^),numwritten)
        end;
      blockwrite(f,assignments.size,sizeof(assignments.size),numwritten);
      for cnt := 1 to assignments.size do
        begin
          blockwrite(f,assignments.data[cnt].grptr,sizeof(assignments.data[cnt].grptr),numwritten);
          blockwrite(f,assignments.data[cnt].asptr^,sizeof(assignments.data[cnt].asptr^),numwritten)
        end;
      blockwrite(f,grades,assignments.size*students.size*2 + 2,numwritten);
      close(f)
    end;


  Procedure load(var grades:gradetype;var students:studenttype;var assignments:assignmenttype;var filename:string);

    var cnt:integer;
        dummy:longint;
        f:file;
        numread:word;

    begin
      assign(f,filename);
      reset(f,1);
      blockread(f,dummy,sizeof(dummy),numread);
      blockread(f,students.size,sizeof(students.size),numread);
      for cnt := 1 to students.size do
        begin
          blockread(f,students.data[cnt].grptr,sizeof(students.data[cnt].grptr),numread);
          new(students.data[cnt].stptr);
          blockread(f,students.data[cnt].stptr^,sizeof(students.data[cnt].stptr^),numread)
        end;
      blockread(f,assignments.size,sizeof(assignments.size),numread);
      for cnt := 1 to assignments.size do
        begin
          blockread(f,assignments.data[cnt].grptr,sizeof(assignments.data[cnt].grptr),numread);
          new(assignments.data[cnt].asptr);
          blockread(f,assignments.data[cnt].asptr^,sizeof(assignments.data[cnt].asptr^),numread)
        end;
      blockread(f,grades,assignments.size*students.size*2 + 2,numread);
      close(f)
    end;

  Procedure printallreports(var grades:gradetype;var students:studenttype;var assignments:assignmenttype;var classname:string);

    var success,done:boolean;
        count:integer;

    begin
      clrscr;
      success := true;
      done := false;
      count := 0;
      while (count < students.size) and (not done) and (success) do
        begin
          count := count + 1;
          clrscr;
          gotoxy(1,10);
          write('Printing report for ',students.data[count].stptr^);
          gotoxy(1,14);
          write('Press Esc to quit printing.');
          printreport(grades,students,assignments,count,classname,done,success)
        end;
      if not success then usermessage('Check Printer.',16)
    end;

  Procedure previewaverages(var grades:gradetype;var students:studenttype;var assignments:assignmenttype;
                          var classname:string;var done:boolean);

    var cnt,cline,count:integer;
        dummy:char;
        temp:string;
        pageno:integer;
        avg:real;

    begin
      clrscr;
      for cnt := 1 to 59 do write(' ');
      writeln('Page: 1');
      for cnt := 1 to 33 do write(' ');
      writeln('Class Averages');
      writeln;
      for cnt := 1 to 9 do write(' ');
      writeln('Class: '+copy(classname,1,20));
      writeln;
      for cnt := 1 to 16 do write(' ');
      write('Student');
      for cnt := 1 to 8 do write(' ');
      writeln('Average');
      for cnt := 1 to 9 do write(' ');
      for cnt := 10 to 29 do write('-');
      write(' ');
      for cnt := 31 to 39 do write('-');
      writeln;
      done := false;
      cline := 8;
      count := 0;
      pageno := 1;
      while (count < students.size) and (not done) do
        begin
          count := count + 1;
          if cline > 20 then
            begin
              gotoxy(17,24);
              write('Press ENTER to continue or ESC to exit preview.');
              repeat
                dummy := readkey;
                if dummy = chr(0) then dummy := readkey
                else if dummy = chr(27) then
                  begin
                    gotoxy(1,21);
                    done := true
                  end
              until (dummy = chr(13)) or (dummy = chr(27));
              if (not done) then
                begin
                  clrscr;
                  pageno := pageno + 1;
                  for cnt := 1 to 59 do write(' ');
                  writeln('Page: ',pageno);
                  writeln;
                  cline := 3
                end
            end;
          if (not done) then
            begin
              for cnt := 1 to 9 do write(' ');
              write(students.data[count].stptr^);
              for cnt := 1 to 21 - length(students.data[count].stptr^) do write(' ');
              avg := average(grades,students,assignments,count);
              if avg = -1.0 then
                write('NA')
              else
                begin
                  str(avg:9:1,temp);
                  write(temp)
                end;
              writeln;
              cline := cline + 1
            end
        end;
      gotoxy(1,24);
      write('':80);
      gotoxy(27,24);
      write('Press any key to continue.');
      pause
    end;

  Procedure printaverages(var grades:gradetype;var students:studenttype;var assignments:assignmenttype;
                          var classname:string;var done,success:boolean);

    var cnt,cline,count:integer;
        dummy:char;
        temp:string;
        pageno:integer;
        avg:real;

    begin
      success := true;
      temp := '';
      for cnt := 1 to 5 do
        temp := temp + chr(13) + chr(10);
      mywrite(temp,success);
      if not success then exit;
      temp := '';
      for cnt := 1 to 59 do
        temp := temp + ' ';
      mywrite(temp,success);
      if not success then exit;
      mywrite('Page: 1'+chr(13)+chr(10),success);
      if not success then exit;
      temp := '';
      for cnt := 1 to 33 do
        temp := temp + ' ';
      mywrite(temp,success);
      if not success then exit;
      mywrite('Class Averages'+chr(13)+chr(10)+chr(13)+chr(10),success);
      if not success then exit;
      temp := '';
      for cnt := 1 to 9 do
        temp := temp + ' ';
      mywrite(temp,success);
      if not success then exit;
      mywrite('Class: '+copy(classname,1,20)+chr(13)+chr(10)+chr(13)+chr(10),success);
      if not success then exit;
      temp := '';
      for cnt := 1 to 16 do
        temp := temp + ' ';
      mywrite(temp,success);
      if not success then exit;
      mywrite('Student',success);
      if not success then exit;
      temp := '';
      for cnt := 1 to 8 do
        temp := temp + ' ';
      mywrite(temp,success);
      if not success then exit;
      mywrite('Average'+chr(13)+chr(10),success);
      if not success then exit;
      temp := '';
      for cnt := 1 to 9 do
        temp := temp + ' ';
      mywrite(temp,success);
      if not success then exit;
      temp := '';
      for cnt := 10 to 29 do
        temp := temp + '-';
      mywrite(temp,success);
      if not success then exit;
      mywrite(' ',success);
      if not success then exit;
      temp := '';
      for cnt := 31 to 39 do
        temp := temp + '-';
      mywrite(temp+chr(13)+chr(10),success);
      if not success then exit;
      done := false;
      cline := 8;
      count := 0;
      pageno := 1;
      while (count < students.size) and (not done) do
        begin
          count := count + 1;
          if keypressed then dummy := readkey;
          if dummy = chr(0) then dummy := readkey
          else if dummy = chr(27) then done := true;
          if cline > 55 then
            begin
              pageno := pageno + 1;
              temp := '';
              for cnt := 1 to 11 do
                temp := temp + chr(13) + chr(10);
              mywrite(temp,success);
              if not success then exit;
              temp := '';
              for cnt := 1 to 59 do
                temp := temp + ' ';
              mywrite(temp,success);
              if not success then exit;
              mywrite('Page: ',success);
              if not success then exit;
              str(pageno,temp);
              mywrite(temp+chr(13)+chr(10)+chr(13)+chr(10),success);
              if not success then exit;
              cline := 3
            end;
          temp := '';
          for cnt := 1 to 9 do
            temp := temp + ' ';
          mywrite(temp,success);
          if not success then exit;
          mywrite(students.data[count].stptr^,success);
          if not success then exit;
          temp := '';
          for cnt := 1 to 21 - length(students.data[count].stptr^) do
            temp := temp + ' ';
          mywrite(temp,success);
          if not success then exit;
          avg := average(grades,students,assignments,count);
          if avg = -1.0 then
            begin
              mywrite('NA',success);
              if not success then exit
            end
          else
            begin
              str(avg:9:1,temp);
              mywrite(temp,success);
              if not success then exit
            end;
          mywrite(chr(13)+chr(10),success);
          if not success then exit;
          cline := cline + 1
        end;
      mywrite(chr(12),success);
      if not success then exit
    end;

  Procedure printaveragesdriver(var grades:gradetype;var students:studenttype;
                                var assignments:assignmenttype;var classname:string);

   var done,success:boolean;

    begin
      clrscr;
      success := true;
      gotoxy(1,10);
      write('Printing Averages. . .');
      gotoxy(1,14);
      write('Press Esc to quit printing.');
      printaverages(grades,students,assignments,classname,done,success);
      if not success then usermessage('Check Printer.',16)
    end;

  Procedure menu(var c:integer;var path:string);

    var temp:string;
        code:integer;
        escpressed:boolean;

    begin
      clrscr;
      displayfilename(path);
      gotoxy(1,3);
      writeln('M A I N   M E N U':48);
      gotoxy(10,5);
      write('1.  Add a student');
      gotoxy(10,6);
      write('2.  Add an assignment');
      gotoxy(10,7);
      write('3.  Edit gradebook');
      gotoxy(10,8);
      write('4.  Print all student reports');
      gotoxy(10,9);
      write('5.  Preview averages');
      gotoxy(10,10);
      write('6.  Print averages');
      gotoxy(10,11);
      write('7.  Exit and save');
      gotoxy(10,12);
      write('8.  Exit without saving');
      gotoxy(1,14);
      write('Pick one: ');
      getinput(temp,escpressed);
      val(temp,c,code)
    end;

  begin
    path := paramstr(1);
    opennewfile := false;
    if path = '' then
      begin
        writeln('Too few parameters');
        exit
      end;
    if not fileexists(path) then
      begin
        write('Cannot find that file.  Create a new one<y,n>? ');
        readln(response);
        writeln;
        if not (response in ['Y','y']) then exit
        else if not filecreation(path) then
          begin
            writeln('File creation error.');
            exit
          end
        else opennewfile := true
      end
    else if not filevalid(path) then
      begin
        writeln('That file is not a gradebook file.');
        exit
      end;
    dummy := 'a.pas';
    dummy := fexpand(dummy);
    fsplit(dummy,olddirectory,n,e);
    if olddirectory[0] > chr(3) then olddirectory[0] := chr(ord(olddirectory[0]) - 1);
    path := fexpand(path);
    fsplit(path,newdirectory,n,e);
    if newdirectory[0] > chr(3) then newdirectory[0] := chr(ord(newdirectory[0]) - 1);
    {$I-}
      chdir(newdirectory);
    {$I+}
    error := IOresult;
    if opennewfile then
      begin
        if diskfree(0) <= 0 then
          begin
            writeln('File creation error.');
            {$I-}
              chdir(olddirectory);
            {$I+}
            error := IOresult;
            exit
          end
        else initializefile(path)
      end;
    load(grades,students,assignments,path);
    diskspaceleft := diskfree(0);
    filespace := spacerequired(assignments.size,students.size);
    if filespace mod 1024 = 0 then spaceleft := diskspaceleft + filespace
    else spaceleft := diskspaceleft + (filespace div 1024)*1024 + 1024;
    userquit := false;
    posit := 1;
    assignno := 1;
    scol := toplineconst;
    repeat
      menu(c,path);
      case c of
        1:begin
              breakout := false;
              if spacerequired(assignments.size,students.size+1) > spaceleft then
                begin
                  usermessage('Not enough diskspace to add new student.  Press any key to continue.',16);
                  breakout := true
                end
              else if ((grades.depth + 1)*assignments.size > maxsize) or (students.size>=numstmax) then
                begin
                  usermessage('Not enough memory to add new student.  Press any key to continue.',16);
                  breakout := true
                end;
              if not breakout then addstudent(students,grades,assignments.size,posit,scol)
            end;
        2:begin
              breakout := false;
              if spacerequired(assignments.size + 1,students.size) > spaceleft then
                begin
                  usermessage('Not enough diskspace to add new assignment.  Press any key to conintue.',16);
                  breakout := true
                end
              else if (grades.depth*(assignments.size + 1) > maxsize) or (assignments.size >= numasmax) then
                begin
                  usermessage('Not enough memory to add new assignment.  Press any key to continue.',16);
                  breakout := true
                end;
              if not breakout then addassignment(assignments,grades,assignno)
            end;
        3:begin
              if (students.size > 0) and (assignments.size > 0) then
                edit(grades,students,assignments,assignno,posit,scol,path)
              else
                usermessage('An empty gradebook cannot be edited.  Press any key to continue',16)
            end;
        4:begin
              clrscr;
              gotoxy(1,12);
              write('Enter class in which students are participating: ');
              getinput(classname,escpressed);
              if not escpressed then
                begin
                  clrscr;
                  gotoxy(1,12);
                  write('Make sure printer is ready.  Press any key to continue.');
                  pause;
                  printallreports(grades,students,assignments,classname)
                end
            end;
        5:begin
              clrscr;
              gotoxy(1,12);
              write('Enter class in which student is participating: ');
              getinput(classname,escpressed);
              if not escpressed then
                previewaverages(grades,students,assignments,classname,done)
            end;
        6:begin
              clrscr;
              gotoxy(1,12);
              write('Enter class in which students are participating: ');
              getinput(classname,escpressed);
              if not escpressed then
                begin
                  clrscr;
                  gotoxy(1,12);
                  write('Make sure printer is ready.  Press any key to continue.');
                  pause;
                  printaveragesdriver(grades,students,assignments,classname)
                end
            end;
        7:begin
              correctdiskin := false;
              while not correctdiskin do
                begin
                  if fileexists(path) then
                    if diskfree(0) = diskspaceleft then correctdiskin := true;
                  if not correctdiskin then
                    usermessage('Insert disk with gradebook file in current drive.  Press any key to continue.',16)
                end;
              save(grades,students,assignments,path);
              clearmemory(grades,students,assignments);
              {$I-}
                chdir(olddirectory);
              {$I+}
              error := IOresult;
              userquit := true
            end;
        8:begin
              gotoxy(1,16);
              write('Exit with no save<y,n>? ');
              readln(response);
              if response in ['Y','y'] then
                begin
                  clearmemory(grades,students,assignments);
                  {$I-}
                    chdir(olddirectory);
                  {$I+}
                  error := IOresult;
                  userquit := true
                end
            end
      end
    until userquit
  end.