program music;

  uses crt,printer;

  const
    numfields = 9;
    maxsize = 1000;
    str1size = 30;
    str2size = 30;
    str3size = 30;
    str4size = 14;
    str5size = 2;
    str6size = 10;
    str7size = 15;
    str8size = 15;
    str9size = 30;
    strasize = 30;
    recsize = 235;

  type
    datetype = record
      year:byte;
      month:byte;
      day:byte
    end;

    arraytype = array[1..numfields] of word;

    stringtype1 = string[str1size];
    stringtype2 = string[str2size];
    stringtype3 = string[str3size];
    stringtype4 = string[str4size];
    stringtype5 = string[str5size];
    stringtype6 = string[str6size];
    stringtype7 = string[str7size];
    stringtype8 = string[str8size];
    stringtype9 = string[str9size];
    stringtypea = string[strasize];

    rectype=record
      loc:arraytype;
      name:stringtype1;
      heading:stringtype2;
      address:stringtype3;
      city:stringtype4;
      state:stringtype5;
      zip:stringtype6;
      phone:stringtype7;
      work:stringtype8;
      subject:stringtype9;
      mail:boolean;
      extra:stringtypea;
    end;

    ptrtype=^rectype;

    rarraytype = array[1..numfields,1..maxsize] of ptrtype;

    indextype=record
      size:word;
      data:rarraytype
    end;

    filetype = file of rectype;

  var choice:integer;
      indexes:indextype;
      response:char;
      temp,resstr:string;
      escpressed,done:boolean;

  Procedure pause;

    var dummy:char;

    begin
      dummy := readkey;
      if dummy = chr(0) then dummy := readkey
    end;

  Function caps(x:string):string;

    var cnt:word;

    begin
      for cnt := 1 to length(x) do
        if (ord(x[cnt]) > 96) and (ord(x[cnt]) < 123) then
          x[cnt] := chr(ord(x[cnt]) - 32);
      caps := x
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

    var f:file;
        size:longint;

    begin
      assign(f,filename);
      reset(f,1);
      size := filesize(f);
      close(f);
      filevalid := ((size mod recsize) = 0)
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

  Procedure usermessage(x:string);

    begin
      write(chr(7)+x);
      pause
    end;

  Function comparebirth(var x,y:datetype):integer;

    begin
      if x.month > y.month then comparebirth := 1
      else if x.month < y.month then comparebirth := -1
      else if x.day > y.day then comparebirth := 1
      else if x.day < y.day then comparebirth := -1
      else comparebirth := 0
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


  Function comparewild(x,y:string):boolean;

    var xposit,yposit,newxposit,newyposit:integer;
        yout,equal:boolean;

    begin
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
          xposit := newxposit + 1;
        end;
      if yout then comparewild := false
      else if yposit < length(y) + 1 then comparewild := false
      else comparewild := true
    end;


  Function comparerecords(var x,y:rectype;fieldnum:word):integer;

    begin
      case fieldnum of
        1:if caps(x.name) > caps(y.name) then comparerecords := 1
          else if caps(x.name) < caps(y.name) then comparerecords := -1
          else comparerecords := 0;
        2:if caps(x.heading) > caps(y.heading) then comparerecords := 1
          else if caps(x.heading) < caps(y.heading) then comparerecords := -1
          else comparerecords := 0;
        3:if caps(x.address) > caps(y.address) then comparerecords := 1
          else if caps(x.address) < caps(y.address) then comparerecords := -1
          else comparerecords := 0;
        4:if caps(x.city) > caps(y.city) then comparerecords := 1
          else if caps(x.city) < caps(y.city) then comparerecords := -1
          else comparerecords := 0;
        5:if caps(x.state) > caps(y.state) then comparerecords := 1
          else if caps(x.state) < caps(y.state) then comparerecords := -1
          else comparerecords := 0;
        6:if caps(x.zip) > caps(y.zip) then comparerecords := 1
          else if caps(x.zip) < caps(y.zip) then comparerecords := -1
          else comparerecords := 0;
        7:if caps(x.phone) > caps(y.phone) then comparerecords := 1
          else if caps(x.phone) < caps(y.phone) then comparerecords := -1
          else comparerecords := 0;
        8:if caps(x.work) > caps(y.work) then comparerecords := 1
          else if caps(x.work) < caps(y.work) then comparerecords := -1
          else comparerecords := 0;
        9:if caps(x.subject) > caps(y.subject) then comparerecords := 1
          else if caps(x.subject) < caps(y.subject) then comparerecords := -1
          else comparerecords := 0;
      end
    end;

  Function comparepart(var x,y:rectype;fieldnum:word):boolean;


    begin
      case fieldnum of
        1:comparepart := comparewild(caps(x.name),caps(y.name));
        2:comparepart := comparewild(caps(x.heading),caps(y.heading));
        3:comparepart := comparewild(caps(x.address),caps(y.address));
        4:comparepart := comparewild(caps(x.city),caps(y.city));
        5:comparepart := comparewild(caps(x.state),caps(y.state));
        6:comparepart := comparewild(caps(x.zip),caps(y.zip));
        7:comparepart := comparewild(caps(x.phone),caps(y.phone));
        8:comparepart := comparewild(caps(x.work),caps(y.work));
        9:comparepart := comparewild(caps(x.subject),caps(y.subject))
      end
    end;


  Procedure displaysize(x:word);

    begin
      clrscr;
      gotoxy(1,12);
      write('This file has ',x,' records.');
      pause
    end;

  Procedure clearmemory(var indexes:indextype);

    var cnt:word;

    begin
      for cnt := 1 to indexes.size do
        dispose(indexes.data[1,cnt]);
      indexes.size := 0
    end;

  Function binarysearch(var indexes:indextype;var key:rectype;fieldnum:word;var found:boolean):word;

    var first,last,mid:word;

    begin
      found := false;
      if indexes.size = 0 then binarysearch := 1
      else
      if indexes.size = 1 then
        begin
          if comparerecords(key,indexes.data[fieldnum,1]^,fieldnum) = 1 then binarysearch:=2
          else binarysearch := 1;
          if comparerecords(key,indexes.data[fieldnum,1]^,fieldnum) = 0 then found := true
        end
      else
        begin
          if comparerecords(key,indexes.data[fieldnum,1]^,fieldnum) = 0 then
            begin
              binarysearch := 1;
              found := true
            end
          else if comparerecords(key,indexes.data[fieldnum,indexes.size]^,fieldnum) = 0 then
            begin
              binarysearch := indexes.size;
              found := true
            end
          else if comparerecords(key,indexes.data[fieldnum,1]^,fieldnum) < 1 then binarysearch := 1
          else if comparerecords(key,indexes.data[fieldnum,indexes.size]^,fieldnum) >=0 then
            binarysearch := indexes.size + 1
          else
            begin
              first := 1;
              last := indexes.size;
              found := false;
              while (not found) and (first + 1< last) do
                begin
                  mid := first + (last-first) div 2;
                  if comparerecords(key,indexes.data[fieldnum,mid]^,fieldnum) = 0 then
                    begin
                      found := true;
                      binarysearch := mid
                    end
                  else
                    if comparerecords(key,indexes.data[fieldnum,mid]^,fieldnum) = 1 then first := mid
                    else last := mid
                end;
              if not found then binarysearch := last
            end
        end
    end;

  Procedure addrecord(var indexes:indextype;p:ptrtype);

    var cnt,cnt1:word;
    found:boolean;

    begin
      for cnt := 1 to numfields do
        p^.loc[cnt] := binarysearch(indexes,p^,cnt,found);
      for cnt := 1 to numfields do
        begin
          for cnt1 := indexes.size downto p^.loc[cnt] do
            begin
              indexes.data[cnt,cnt1+1] := indexes.data[cnt,cnt1];
              indexes.data[cnt,cnt1+1]^.loc[cnt] := cnt1 + 1
            end;
          indexes.data[cnt,p^.loc[cnt]] := p
        end;
      indexes.size := indexes.size + 1
    end;

  Procedure getrecords(var indexes:indextype);

    var p:ptrtype;
        temp:string;
        escpressed,success,hellfreezesover:boolean;

    begin
      clrscr;
      hellfreezesover := false;
      repeat
        if indexes.size >= maxsize then exit;
        new(p);
        write('Enter name: ');
        getinput(temp,escpressed);
        p^.name := copy(temp,1,str1size);
        if escpressed then
          begin
            dispose(p);
            exit
          end;
        writeln;
        write('Enter heading: ');
        getinput(temp,escpressed);
        p^.heading := copy(temp,1,str2size);
        if escpressed then
          begin
            dispose(p);
            exit
          end;
        writeln;
        write('Enter address: ');
        getinput(temp,escpressed);
        p^.address := copy(temp,1,str3size);
        if escpressed then
          begin
            dispose(p);
            exit
          end;
        writeln;
        write('Enter city: ');
        getinput(temp,escpressed);
        p^.city := copy(temp,1,str4size);
        if escpressed then
          begin
            dispose(p);
            exit
          end;
        writeln;
        write('Enter state: ');
        getinput(temp,escpressed);
        p^.state := copy(temp,1,str5size);
        if escpressed then
          begin
            dispose(p);
            exit
          end;
        writeln;
        write('Enter zip code: ');
        getinput(temp,escpressed);
        p^.zip := copy(temp,1,str6size);
        if escpressed then
          begin
            dispose(p);
            exit
          end;
        writeln;
        write('Enter home phone: ');
        getinput(temp,escpressed);
        p^.phone := copy(temp,1,str7size);
        if escpressed then
          begin
            dispose(p);
            exit
          end;
        writeln;
        write('Enter work phone: ');
        getinput(temp,escpressed);
        p^.work := copy(temp,1,str8size);
        if escpressed then
          begin
            dispose(p);
            exit
          end;
        writeln;
        write('Enter subject: ');
        getinput(temp,escpressed);
        p^.subject := copy(temp,1,str9size);
        if escpressed then
          begin
            dispose(p);
            exit
          end;
        writeln;
        write('Mailing list? ');
        getinput(temp,escpressed);
        p^.mail := temp[1] in ['Y','y'];
        if temp = '' then p^.mail := false;
        if escpressed then
          begin
            dispose(p);
            exit
          end;
        writeln;
        write('Extra line? ');
        getinput(temp,escpressed);
        p^.extra := copy(temp,1,strasize);
        if escpressed then
          begin
            dispose(p);
            exit
          end;
        writeln;
        writeln;
        addrecord(indexes,p)
      until hellfreezesover
    end;

  Procedure deleterecord(var indexes:indextype;fieldnum,posit:word);

    var p:ptrtype;
        cnt,cnt1:word;

    begin
      p := indexes.data[fieldnum,posit];
      for cnt := 1 to numfields do
        for cnt1 := p^.loc[cnt] to indexes.size - 1 do
          begin
            indexes.data[cnt,cnt1] := indexes.data[cnt,cnt1+1];
            indexes.data[cnt,cnt1]^.loc[cnt] := cnt1
          end;
      dispose(p);
      indexes.size := indexes.size - 1
    end;

  Procedure cleanout(var indexes:indextype);

    var count,cnt,cnt1,csize:word;

    begin
      for count := 1 to numfields - 1 do
        begin
          csize := indexes.size;
          for cnt := indexes.size downto 1 do
            begin
              if not (indexes.data[count,cnt]^.mail) then
                begin
                  for cnt1 := cnt to csize - 1 do
                    begin
                      indexes.data[count,cnt1] := indexes.data[count,cnt1+1];
                      indexes.data[count,cnt1]^.loc[count] := cnt1
                    end;
                  csize := csize - 1
                end
            end
        end;
      csize := indexes.size;
      for cnt := indexes.size downto 1 do
        begin
          if not (indexes.data[numfields,cnt]^.mail) then
            begin
              dispose(indexes.data[numfields,cnt]);
              for cnt1 := cnt to csize - 1 do
                begin
                  indexes.data[numfields,cnt1] := indexes.data[numfields,cnt1+1];
                  indexes.data[numfields,cnt1]^.loc[numfields] := cnt1
                end;
              csize := csize - 1
            end
        end;
      indexes.size := csize
    end;


  Procedure displayrecord(var indexes:indextype;fieldnum:word;var posit:word);

    begin
      if posit > indexes.size then posit := indexes.size;
      clrscr;
      gotoxy(1,5);
      write('Name: ',indexes.data[fieldnum,posit]^.name);
      gotoxy(1,6);
      write('Heading: ',indexes.data[fieldnum,posit]^.heading);
      gotoxy(1,7);
      write('Address: ',indexes.data[fieldnum,posit]^.address);
      gotoxy(1,8);
      write('City: ',indexes.data[fieldnum,posit]^.city);
      gotoxy(1,9);
      write('State: ',indexes.data[fieldnum,posit]^.state);
      gotoxy(1,10);
      write('Zip code: ',indexes.data[fieldnum,posit]^.zip);
      gotoxy(1,11);
      write('Home phone: ',indexes.data[fieldnum,posit]^.phone);
      gotoxy(1,12);
      write('Work phone: ',indexes.data[fieldnum,posit]^.work);
      gotoxy(1,13);
      write('Subject: ',indexes.data[fieldnum,posit]^.subject);
      gotoxy(1,14);
      write('Mailing list: ');
      if indexes.data[fieldnum,posit]^.mail then write('YES')
      else write('NO');
      if indexes.data[fieldnum,posit]^.extra <> '' then
        begin
          gotoxy(1,15);
          write('Extra line: ',indexes.data[fieldnum,posit]^.extra)
        end
    end;

  Procedure placerecord(var indexes:indextype;cfieldnum:word;var posit:word;fieldnum:word);

    var p:ptrtype;
        newposit,oldposit,cnt:word;
        found:boolean;

    begin
      if indexes.size <= 1 then exit;
      p := indexes.data[cfieldnum,posit];
      oldposit := p^.loc[fieldnum];
      if oldposit = 1 then indexes.data[fieldnum,oldposit] := indexes.data[fieldnum,oldposit + 1]
      else indexes.data[fieldnum,oldposit] := indexes.data[fieldnum,oldposit - 1];
      newposit := binarysearch(indexes,p^,fieldnum,found);
      if newposit < p^.loc[fieldnum] then
        begin
          for cnt := p^.loc[fieldnum]-1 downto newposit do
            begin
              indexes.data[fieldnum,cnt+1] := indexes.data[fieldnum,cnt];
              indexes.data[fieldnum,cnt+1]^.loc[fieldnum] := cnt + 1
            end;
          indexes.data[fieldnum,newposit] := p;
          p^.loc[fieldnum] := newposit;
          if fieldnum = cfieldnum then posit := newposit
        end
      else
        if newposit > p^.loc[fieldnum] then
          begin
            for cnt := p^.loc[fieldnum]+1 to newposit - 1 do
              begin
                indexes.data[fieldnum,cnt-1] := indexes.data[fieldnum,cnt];
                indexes.data[fieldnum,cnt-1]^.loc[fieldnum] := cnt-1
              end;
            indexes.data[fieldnum,newposit-1] := p;
            p^.loc[fieldnum] := newposit - 1;
            if fieldnum = cfieldnum then posit := newposit - 1
          end
      else
        if newposit = p^.loc[fieldnum] then
          begin
            indexes.data[fieldnum,newposit] := p;
            p^.loc[fieldnum] := newposit;
            if fieldnum = cfieldnum then posit := newposit
          end
    end;

  Procedure viewdata(var indexes:indextype;fieldnum,posit:word);

    var choice,schoice:char;
        done,escpressed,success:boolean;
        temp:string;
        numsearched:word;

    begin
      if posit < 1 then posit := 1
      else if posit > indexes.size then posit := indexes.size;
      displayrecord(indexes,fieldnum,posit);
      done := false;
      repeat
        choice := readkey;
        case choice of
          chr(11):begin
                    numsearched := 0;
                    repeat
                      if posit = 1 then posit := indexes.size
                      else posit := posit - 1;
                      numsearched := numsearched + 1
                    until (numsearched = indexes.size) or (indexes.data[fieldnum,posit]^.mail);
                    displayrecord(indexes,fieldnum,posit)
                  end;
          chr(12):begin
                    numsearched := 0;
                    repeat
                      if posit = indexes.size then posit := 1
                      else posit := posit + 1;
                      numsearched := numsearched + 1
                    until (numsearched = indexes.size) or (indexes.data[fieldnum,posit]^.mail);
                    displayrecord(indexes,fieldnum,posit)
                  end;
          chr(27):done := true;
          '1':begin
                gotoxy(1,17);
                write('Enter new name: ');
                getinput(temp,escpressed);
                if not escpressed then
                  begin
                    indexes.data[fieldnum,posit]^.name := copy(temp,1,str1size);
                    placerecord(indexes,fieldnum,posit,1)
                  end;
                displayrecord(indexes,fieldnum,posit)
              end;
          '2':begin
                gotoxy(1,17);
                write('Enter new heading: ');
                getinput(temp,escpressed);
                if not escpressed then
                  begin
                    indexes.data[fieldnum,posit]^.heading := copy(temp,1,str2size);
                    placerecord(indexes,fieldnum,posit,2)
                  end;
                displayrecord(indexes,fieldnum,posit)
              end;
          '3':begin
                gotoxy(1,17);
                write('Enter new address: ');
                getinput(temp,escpressed);
                if not escpressed then
                  begin
                    indexes.data[fieldnum,posit]^.address := copy(temp,1,str3size);
                    placerecord(indexes,fieldnum,posit,3)
                  end;
                displayrecord(indexes,fieldnum,posit)
              end;
          '4':begin
                gotoxy(1,17);
                write('Enter new city: ');
                getinput(temp,escpressed);
                if not escpressed then
                  begin
                    indexes.data[fieldnum,posit]^.city := copy(temp,1,str4size);
                    placerecord(indexes,fieldnum,posit,4)
                  end;
                displayrecord(indexes,fieldnum,posit)
              end;
          '5':begin
                gotoxy(1,17);
                write('Enter new state: ');
                getinput(temp,escpressed);
                if not escpressed then
                  begin
                    indexes.data[fieldnum,posit]^.state := copy(temp,1,str5size);
                    placerecord(indexes,fieldnum,posit,5)
                  end;
                displayrecord(indexes,fieldnum,posit)
              end;
          '6':begin
                gotoxy(1,17);
                write('Enter new zip code: ');
                getinput(temp,escpressed);
                if not escpressed then
                  begin
                    indexes.data[fieldnum,posit]^.zip := copy(temp,1,str6size);
                    placerecord(indexes,fieldnum,posit,6)
                  end;
                displayrecord(indexes,fieldnum,posit)
              end;
          '7':begin
                gotoxy(1,17);
                write('Enter new home phone: ');
                getinput(temp,escpressed);
                if not escpressed then
                  begin
                    indexes.data[fieldnum,posit]^.phone := copy(temp,1,str7size);
                    placerecord(indexes,fieldnum,posit,7)
                  end;
                displayrecord(indexes,fieldnum,posit)
              end;
          '8':begin
                gotoxy(1,17);
                write('Enter new work phone: ');
                getinput(temp,escpressed);
                if not escpressed then
                  begin
                    indexes.data[fieldnum,posit]^.work := copy(temp,1,str8size);
                    placerecord(indexes,fieldnum,posit,8)
                  end;
                displayrecord(indexes,fieldnum,posit)
              end;
          '9':begin
                gotoxy(1,17);
                write('Enter new subject: ');
                getinput(temp,escpressed);
                if not escpressed then
                  begin
                    indexes.data[fieldnum,posit]^.subject := copy(temp,1,str9size);
                    placerecord(indexes,fieldnum,posit,9)
                  end;
                displayrecord(indexes,fieldnum,posit)
              end;
      'Y','y':begin
                indexes.data[fieldnum,posit]^.mail := true;
                displayrecord(indexes,fieldnum,posit)
              end;
      'N','n':begin
                indexes.data[fieldnum,posit]^.mail := false;
                displayrecord(indexes,fieldnum,posit)
              end;
          'A':begin
                gotoxy(1,17);
                write('Extra line? ');
                getinput(temp,escpressed);
                if not escpressed then
                  indexes.data[fieldnum,posit]^.extra := copy(temp,1,strasize);
                displayrecord(indexes,fieldnum,posit)
              end;
          chr(0):begin
                   schoice := readkey;
                   case schoice of
                     chr(72):begin
                               if posit = 1 then posit := indexes.size
                               else posit := posit - 1;
                               displayrecord(indexes,fieldnum,posit)
                             end;
                     chr(80):begin
                               if posit = indexes.size then posit := 1
                               else posit := posit + 1;
                               displayrecord(indexes,fieldnum,posit)
                             end;
                     chr(83):begin
                               deleterecord(indexes,fieldnum,posit);
                               if indexes.size > 0 then displayrecord(indexes,fieldnum,posit)
                               else done := true
                             end
                   end {schoice}
                 end {chr(0)}
          end {choice}
      until done
    end;



  Procedure searchmenu(var c:word);

    var temp:string;
        code:integer;
        escpressed:boolean;

    begin
      clrscr;
      gotoxy(1,2);
      writeln('S E A R C H   M E N U':50);
      gotoxy(10,4);
      write('1.  Search by name');
      gotoxy(10,5);
      write('2.  Search by heading');
      gotoxy(10,6);
      write('3.  Search by address');
      gotoxy(10,7);
      write('4.  Search by city');
      gotoxy(10,8);
      write('5.  Search by state');
      gotoxy(10,9);
      write('6.  Search by zip code');
      gotoxy(10,10);
      write('7.  Search by home phone');
      gotoxy(10,11);
      write('8.  Search by work phone');
      gotoxy(10,12);
      write('9.  Search by subject');
      gotoxy(9,13);
      write('10.  Return to main menu');
      gotoxy(1,15);
      write('Pick one: ');
      getinput(temp,escpressed);
      val(temp,c,code)
    end;

  Procedure searchdriver(var indexes:indextype);

    var choice:word;
        done,success,escpressed,found:boolean;
        key:rectype;
        temp:string;

    begin
      done := false;
      repeat
        searchmenu(choice);
        if (choice >= 1) and (choice <= numfields) then
          begin
            clrscr;
            gotoxy(1,12);
            case choice of
              1:begin
                  write('Enter name: ');
                  getinput(temp,escpressed);
                  key.name := copy(temp,1,str1size)
                end;
              2:begin
                  write('Enter heading: ');
                  getinput(temp,escpressed);
                  key.heading := copy(temp,1,str2size)
                end;
              3:begin
                  write('Enter address: ');
                  getinput(temp,escpressed);
                  key.address := copy(temp,1,str3size)
                end;
              4:begin
                  write('Enter city: ');
                  getinput(temp,escpressed);
                  key.city := copy(temp,1,str4size)
                end;
              5:begin
                  write('Enter state: ');
                  getinput(temp,escpressed);
                  key.state := copy(temp,1,str5size)
                end;
              6:begin
                  write('Enter zip code: ');
                  getinput(temp,escpressed);
                  key.zip := copy(temp,1,str6size)
                end;
              7:begin
                  write('Enter home phone: ');
                  getinput(temp,escpressed);
                  key.phone := copy(temp,1,str7size)
                end;
              8:begin
                  write('Enter work phone: ');
                  getinput(temp,escpressed);
                  key.work := copy(temp,1,str8size)
                end;
              9:begin
                  write('Enter subject: ');
                  getinput(temp,escpressed);
                  key.subject := copy(temp,1,str9size)
                end
            end;
            if not escpressed then
              viewdata(indexes,choice,binarysearch(indexes,key,choice,found));
            if indexes.size <= 0 then done := true
          end
        else if choice = numfields + 1 then done := true
      until done
    end;

  Procedure clearmailinglist(var indexes:indextype);

    var cnt:word;

    begin
      for cnt := 1 to indexes.size do
        indexes.data[1,cnt]^.mail := false
    end;

  Procedure setmailinglist(var indexes:indextype);

    var cnt:word;

    begin
      for cnt := 1 to indexes.size do
        indexes.data[1,cnt]^.mail := true
    end;

  Procedure invertmailinglist(var indexes:indextype);

    var cnt:word;

    begin
      for cnt := 1 to indexes.size do
        indexes.data[1,cnt]^.mail := not indexes.data[1,cnt]^.mail
    end;

  Function addgroup(var indexes:indextype;var key:rectype;fieldnum:word;stat,wildcard:boolean):word;

    var cnt,numadded:word;
        done:boolean;

    begin
      if not wildcard then
        begin
          done := false;
          cnt := 1;
          numadded := 0;
          while (cnt <= indexes.size) and (not done) do
            begin
              if comparerecords(key,indexes.data[fieldnum,cnt]^,fieldnum) < 1 then
                done := true
              else
                cnt := cnt + 1
            end;
          done := false;
          while (cnt <= indexes.size) and (not done) do
            begin
              if comparerecords(key,indexes.data[fieldnum,cnt]^,fieldnum) = 0 then
                begin
                  indexes.data[fieldnum,cnt]^.mail := stat;
                  cnt := cnt + 1;
                  numadded := numadded + 1
                end
              else
                done := true
            end;
          addgroup := numadded
        end
      else
        begin
          numadded := 0;
          for cnt := 1 to indexes.size do
            begin
              if comparepart(key,indexes.data[fieldnum,cnt]^,fieldnum) then
                begin
                  indexes.data[fieldnum,cnt]^.mail := stat;
                  numadded := numadded + 1
                end
            end;
          addgroup := numadded
        end
    end;

  Procedure addgroupmenu(var c:word);

    var temp:string;
        code:integer;
        escpressed:boolean;

    begin
      clrscr;
      gotoxy(1,2);
      writeln('A D D / R E M O V E   M E N U':54);
      gotoxy(10,4);
      write('1.  By name');
      gotoxy(10,5);
      write('2.  By heading');
      gotoxy(10,6);
      write('3.  By address');
      gotoxy(10,7);
      write('4.  By city');
      gotoxy(10,8);
      write('5.  By state');
      gotoxy(10,9);
      write('6.  By zip code');
      gotoxy(10,10);
      write('7.  By home phone');
      gotoxy(10,11);
      write('8.  By work phone');
      gotoxy(10,12);
      write('9.  By subject');
      gotoxy(9,13);
      write('10.  Return to main menu');
      gotoxy(1,15);
      write('Pick one: ');
      getinput(temp,escpressed);
      val(temp,c,code)
    end;


  Procedure addgroupdriver(var indexes:indextype);

    var choice,numadded:word;
        done,success,escpressed,found:boolean;
        key:rectype;
        temp,response:string;

    begin
      done := false;
      repeat
        addgroupmenu(choice);
        if (choice >= 1) and (choice <= numfields) then
          begin
            clrscr;
            gotoxy(1,9);
            case choice of
              1:begin
                  write('Enter name: ');
                  getinput(temp,escpressed);
                  key.name := copy(temp,1,str1size)
                end;
              2:begin
                  write('Enter heading: ');
                  getinput(temp,escpressed);
                  key.heading := copy(temp,1,str2size)
                end;
              3:begin
                  write('Enter address: ');
                  getinput(temp,escpressed);
                  key.address := copy(temp,1,str3size)
                end;
              4:begin
                  write('Enter city: ');
                  getinput(temp,escpressed);
                  key.city := copy(temp,1,str4size)
                end;
              5:begin
                  write('Enter state: ');
                  getinput(temp,escpressed);
                  key.state := copy(temp,1,str5size)
                end;
              6:begin
                  write('Enter zip code: ');
                  getinput(temp,escpressed);
                  key.zip := copy(temp,1,str6size)
                end;
              7:begin
                  write('Enter home phone: ');
                  getinput(temp,escpressed);
                  key.phone := copy(temp,1,str7size)
                end;
              8:begin
                  write('Enter work phone: ');
                  getinput(temp,escpressed);
                  key.work := copy(temp,1,str8size)
                end;
              9:begin
                  write('Enter subject: ');
                  getinput(temp,escpressed);
                  key.subject := copy(temp,1,str9size)
                end
            end;
            if not escpressed then
              begin
                repeat
                  gotoxy(1,11);
                  write('':80);
                  gotoxy(1,11);
                  write('Wild card search<y,n>? ');
                  getinput(temp,escpressed)
                until (escpressed) or (temp[1] in ['Y','y','N','n']);
                if not escpressed then
                  begin
                    repeat
                      gotoxy(1,13);
                      write('':80);
                      gotoxy(1,13);
                      write('Add or remove<a,r>? ');
                      getinput(response,escpressed)
                    until (escpressed) or (response[1] in ['A','a','R','r']);
                    if not escpressed then
                      begin
                        numadded := addgroup(indexes,key,choice,response[1] in ['A','a'],temp[1] in ['Y','y']);
                        gotoxy(1,15);
                        write('Specified group contains ',numadded,' people.');
                        pause
                      end
                  end
              end
          end
      until choice = numfields + 1
    end;


  Procedure displayscreenful(var indexes:indextype;var count:word);

    var srow,scol:word;

    begin
      srow := 3;
      scol := 0;
      while (count < indexes.size) and (srow <= 22) do
        begin
          count := count + 1;
          if indexes.data[1,count]^.mail then
            begin
              gotoxy(1+40*scol,srow);
              write(indexes.data[1,count]^.name);
              scol := 1 - scol;
              if scol = 0 then srow := srow + 1
            end
        end
    end;

  Procedure displaymail(var indexes:indextype);

   var count:word;
       done:boolean;
       dummy:char;

   begin
      count := 0;
      done := false;
      while (not done) and (count < indexes.size) do
        begin
          clrscr;
          write('CURRENT MAILING LIST':50);
          gotoxy(1,24);
          write('Press RETURN to continue or ESC to exit':59);
          displayscreenful(indexes,count);
          repeat
            dummy := readkey
          until (dummy = chr(27)) or (dummy = chr(13));
          done := (dummy = chr(27))
        end
    end;

  Procedure dupscreenful(var indexes:indextype;var count:word);

    var num,numdups,first:word;
        dupval:string;
        duplicate:boolean;

    begin
      num := 1;
      while (num <= 20) and (count <= indexes.size) do
        begin
          dupval := indexes.data[1,count]^.name;
          first := count;
          count := count + 1;
          duplicate := true;
          while (count <= indexes.size) and (duplicate) do
            begin
              if caps(indexes.data[1,count]^.name) <> caps(dupval) then
                duplicate := false
              else
                count := count + 1
            end;
          numdups := count - first;
          if numdups > 1 then
            begin
              gotoxy(1,num+2);
              write(dupval);
              gotoxy(40,num+2);
              write(numdups:6);
              num := num + 1
            end
        end
    end;


  Procedure displayduplicates(var indexes:indextype);

   var count,cnt:word;
       done:boolean;
       dummy:char;

   begin
      count := 1;
      done := false;
      while (not done) and (count <= indexes.size) do
        begin
          clrscr;
          gotoxy(14,1);
          write('NAME');
          gotoxy(36,1);
          writeln('# OF DUPLICATES');
          for cnt := 1 to 30 do
            write('-');
          for cnt := 31 to 34 do
            write(' ');
          for cnt := 35 to 51 do
            write('-');
          gotoxy(1,24);
          write('Press RETURN to continue or ESC to exit':59);
          dupscreenful(indexes,count);
          repeat
            dummy := readkey
          until (dummy = chr(27)) or (dummy = chr(13));
          done := (dummy = chr(27))
        end
    end;


  Procedure savemailinglist(var filename:string;var indexes:indextype);

    var f:text;
        cnt:word;
        error:integer;

    begin
      assign(f,filename);
      rewrite(f);
      cnt := 0;
      while (cnt < indexes.size) do
        begin
          cnt := cnt + 1;
          if indexes.data[1,cnt]^.mail then
            begin
              {$I-}
                writeln(f,indexes.data[1,cnt]^.name);
              {$I+}
              error := IOresult;
              if error <> 0 then
                begin
                  close(f);
                  erase(f);
                  gotoxy(1,14);
                  usermessage('Insufficient disk space.');
                  exit
                end
            end
        end;
      close(f)
    end;

  Procedure getmailinglist(var filename:string; var indexes:indextype);

    var f:text;
        key:rectype;
        found:boolean;
        posit:word;

    begin
      assign(f,filename);
      reset(f);
      while (not eof(f)) do
        begin
          readln(f,key.name);
          posit := binarysearch(indexes,key,1,found);
          if found then
            indexes.data[1,posit]^.mail := true
        end;
      close(f)
    end;

  Function mailsize(var indexes:indextype):word;

    var cnt,num:word;

    begin
      num := 0;
      for cnt := 1 to indexes.size do
        if indexes.data[1,cnt]^.mail then
          num := num + 1;
      mailsize := num
    end;


  Procedure configmenu(var c:word);

    var temp:string;
        code:integer;
        escpressed:boolean;

    begin
      clrscr;
      gotoxy(1,4);
      write('M A I L I N G   L I S T   M E N U':57);
      gotoxy(10,7);
      write('1.  Place all on mailing list');
      gotoxy(10,8);
      write('2.  Remove all from mailing list');
      gotoxy(10,9);
      write('3.  Invert mailing list');
      gotoxy(10,10);
      write('4.  Add / remove from mailing list');
      gotoxy(10,11);
      write('5.  Display mailing list');
      gotoxy(10,12);
      write('6.  Display duplicates');
      gotoxy(10,13);
      write('7.  Save mailing list');
      gotoxy(10,14);
      write('8.  Get mailing list');
      gotoxy(10,15);
      write('9.  List size of mailing list');
      gotoxy(9,16);
      write('10.  Return to main menu');
      gotoxy(1,18);
      write('Pick one: ');
      getinput(temp,escpressed);
      val(temp,c,code)
    end;

  Procedure configdriver(var indexes:indextype);

    var done,escpressed:boolean;
        temp:string;
        response:char;
        choice:word;

    begin
      done := false;
      repeat
        configmenu(choice);
        case choice of
          1:begin
              gotoxy(1,20);
              write('Are you sure<y,n>? ');
              readln(response);
              if response in ['Y','y'] then setmailinglist(indexes)
            end;
          2:begin
              gotoxy(1,20);
              write('Are you sure<y,n>? ');
              readln(response);
              if response in ['Y','y'] then clearmailinglist(indexes)
            end;
          3:begin
              gotoxy(1,20);
              write('Are you sure<y,n>? ');
              readln(response);
              if response in ['Y','y'] then invertmailinglist(indexes)
            end;
          4:addgroupdriver(indexes);
          5:displaymail(indexes);
          6:displayduplicates(indexes);
          7:begin
              clrscr;
              gotoxy(1,12);
              write('Save mailing list under? ');
              getinput(temp,escpressed);
              if not escpressed then
                begin
                  response := 'Y';
                  if fileexists(temp) then
                    begin
                      gotoxy(1,14);
                      write('That file already exists.  Overwrite<y,n>? ');
                      readln(response)
                    end;
                  if response in ['Y','y'] then
                    begin
                      if filecreation(temp) then
                        savemailinglist(temp,indexes)
                      else
                        begin
                          gotoxy(1,14);
                          usermessage('File creation error.')
                        end
                    end
                end
            end;
          8:begin
              clrscr;
              gotoxy(1,12);
              write('Get mailing list: ');
              getinput(temp,escpressed);
              if not escpressed then
                begin
                  if fileexists(temp) then
                    getmailinglist(temp,indexes)
                  else
                    begin
                      gotoxy(1,14);
                      usermessage('Cannot find that file.')
                    end
                end
            end;
         9:begin
             clrscr;
             gotoxy(1,12);
             write('Current mailing list contains ',mailsize(indexes),' people.');
             pause
           end;
         10:done := true
        end
      until done
    end;


  Procedure printlable(var x:rectype);

    begin
      writeln(lst,x.heading);
      if x.extra <> '' then
        writeln(lst,x.extra);
      writeln(lst,x.address);
      writeln(lst,x.city+', ',+x.state+'  '+x.zip);
      writeln(lst);
      writeln(lst);
      if x.extra = '' then
        writeln(lst)
    end;

  Procedure printmailinglist(var indexes:indextype;order:word);

    var cnt:word;
        done:boolean;
        dummy:char;

    begin
      cnt := 0;
      done := false;
      while (cnt < indexes.size) and (not done) do
        begin
          cnt := cnt + 1;
          if indexes.data[order,cnt]^.mail then
            printlable(indexes.data[order,cnt]^);
          if keypressed then
            begin
              dummy := readkey;
              if dummy = chr(0) then dummy := readkey;
              if dummy = chr(27) then done := true
            end
        end
    end;


  Procedure printrecord(var x:rectype);

    var cnt:word;

    begin
      for cnt := 1 to 6 do write(lst,' ');
      write(lst,x.name);
      for cnt := 1 to (31-length(x.name)) do write(lst,' ');
      write(lst,x.address);
      for cnt := 1 to (31-length(x.address)) do write(lst,' ');
      write(lst,x.city);
      for cnt := 1 to (15-length(x.city)) do write(lst,' ');
      write(lst,x.state);
      for cnt := 1 to (3-length(x.state)) do write(lst,' ');
      write(lst,x.zip);
      for cnt := 1 to (11-length(x.zip)) do write(lst,' ');
      write(lst,x.phone:15);
      write(lst,' ');
      writeln(lst,x.work:15)
    end;


  Procedure printlines(var indexes:indextype;var count:word;order:word;var done:boolean);

    var cnt:word;
        dummy:char;

    begin
      cnt := 0;
      while (cnt < 53) and (count < indexes.size) and (not done) do
        begin
          count := count + 1;
          if indexes.data[order,count]^.mail then
            begin
              cnt := cnt + 1;
              printrecord(indexes.data[order,count]^)
            end;
          if keypressed then
            begin
              dummy := readkey;
              if dummy=chr(0) then dummy := readkey;
              if dummy=chr(27) then done := true
            end
        end
    end;


  Procedure printtitle;

    var cnt:word;

    begin
      for cnt := 1 to 19 do write(lst,' ');
      write(lst,'Name');
      for cnt := 24 to 48 do write(lst,' ');
      write(lst,'Address');
      for cnt := 56 to 73 do write(lst,' ');
      write(lst,'City');
      for cnt := 78 to 83 do write(lst,' ');
      write(lst,'St');
      for cnt := 86 to 87 do write(lst,' ');
      write(lst,'Zip code');
      for cnt := 96 to 99 do write(lst,' ');
      write(lst,'Home phone');
      for cnt := 110 to 115 do write(lst,' ');
      writeln(lst,'Work phone');
      for cnt := 1 to 6 do write(lst,' ');
      for cnt := 7 to 36 do write(lst,'-');
      write(lst,' ');
      for cnt := 38 to 67 do write(lst,'-');
      write(lst,' ');
      for cnt := 69 to 82 do write(lst,'-');
      write(lst,' ');
      for cnt := 84 to 85 do write(lst,'-');
      write(lst,' ');
      for cnt := 87 to 96 do write(lst,'-');
      write(lst,' ');
      for cnt := 98 to 112 do write(lst,'-');
      write(lst,' ');
      for cnt := 114 to 128 do write(lst,'-');
      writeln(lst)
    end;


  Procedure printfile(var indexes:indextype;order:word);

    var pageno,cnt,count:word;
        done:boolean;

    begin
      pageno := 1;
      done := false;
      count := 0;
      write(lst,chr(15));
      while (count < indexes.size) and (not done) do
        begin
          for cnt := 1 to 3 do writeln(lst);
          for cnt := 1 to 120 do write(lst,' ');
          writeln(lst,'Page: ',pageno);
          writeln(lst);
          printtitle;
          printlines(indexes,count,order,done);
          write(lst,chr(12));
          pageno := pageno + 1
        end;
      write(lst,chr(18))
    end;


  Procedure printlablemenu(var c:word);

    var temp:string;
        escpressed:boolean;
        code:integer;

    begin
      clrscr;
      gotoxy(1,2);
      writeln('P R I N T   M E N U':49);
      gotoxy(10,4);
      write('1.  Print sorted by name');
      gotoxy(10,5);
      write('2.  Print sorted by heading');
      gotoxy(10,6);
      write('3.  Print sorted by address');
      gotoxy(10,7);
      write('4.  Print sorted by city');
      gotoxy(10,8);
      write('5.  Print sorted by state');
      gotoxy(10,9);
      write('6.  Print sorted by zip code');
      gotoxy(10,10);
      write('7.  Print sorted by home phone');
      gotoxy(10,11);
      write('8.  Print sorted by work phone');
      gotoxy(10,12);
      write('9.  Print sorted by subject');
      gotoxy(9,13);
      write('10.  Return to main menu');
      gotoxy(1,15);
      write('Pick one: ');
      getinput(temp,escpressed);
      val(temp,c,code)
    end;

  Procedure printdriver(var indexes:indextype);

    var choice:word;
        temp:string;
        escpressed:boolean;
        response:char;

    begin
      repeat
        printlablemenu(choice);
        if (choice >= 1) and (choice <= numfields) then
          begin
            clrscr;
            gotoxy(1,12);
            write('Print labels<y,n>? ');
            getinput(temp,escpressed);
            if not escpressed then
              begin
                clrscr;
                response := temp[1];
                gotoxy(1,12);
                write('Position paper in printer and press ESC to exit or RETURN to continue: ');
                getinput(temp,escpressed);
                if not escpressed then
                  begin
                    clrscr;
                    gotoxy(1,12);
                    write('Press ESC to stop printing.');
                    if response in ['Y','y'] then
                      printmailinglist(indexes,choice)
                    else
                      printfile(indexes,choice)
                  end
              end
          end
      until (choice = numfields + 1)
    end;


  Procedure save(filename:string;var indexes:indextype);

    var f:filetype;
        cnt:word;
        error:integer;

    begin
      assign(f,filename);
      rewrite(f);
      cnt := 0;
      while (cnt<indexes.size) do
        begin
          cnt := cnt + 1;
          {$I-}
            write(f,indexes.data[1,cnt]^);
          {$I+}
          error := IOresult;
          if error <> 0 then
            begin
              close(f);
              erase(f);
              gotoxy(1,14);
              usermessage('Insufficient diskspace.');
              exit
            end
        end;
      close(f)
    end;

  Procedure getfile(filename:string;var indexes:indextype);

    var f:filetype;
        cnt:word;
        p:ptrtype;

    begin
      indexes.size := 0;
      assign(f,filename);
      reset(f);
      while not eof(f) do
        begin
          indexes.size := indexes.size + 1;
          new(p);
          read(f,p^);
          for cnt := 1 to numfields do
            indexes.data[cnt,p^.loc[cnt]] := p
        end;
      close(f)
    end;


  Procedure append(filename:string;var indexes:indextype;noduplicates:boolean);

    var f:filetype;
        p:ptrtype;
        dummy:word;
        found,success:boolean;

    begin
      assign(f,filename);
      reset(f);
      success := true;
      while (not eof(f)) and (success) do
        begin
          new(p);
          read(f,p^);
          if noduplicates then
            begin
              dummy := binarysearch(indexes,p^,1,found);
              if not found then
                begin
                  if indexes.size >= maxsize then
                    begin
                      gotoxy(1,16);
                      usermessage('Not enough memory available to continue.');
                      success := false
                    end
                  else addrecord(indexes,p)
                end
            end
          else
            begin
              if indexes.size >= maxsize then
                begin
                  gotoxy(1,16);
                  usermessage('Not enough memory available to continue.');
                  success := false
                end
              else addrecord(indexes,p)
            end
        end;
      close(f)
    end;


  Procedure menu(var c:integer);

    var temp:string;
        code:integer;
        escpressed:boolean;

    begin
      clrscr;
      gotoxy(1,3);
      writeln('M A I N   M E N U':48);
      gotoxy(10,6);
      write('1.  Add records');
      gotoxy(10,7);
      write('2.  Search file');
      gotoxy(10,8);
      write('3.  Clear memory');
      gotoxy(10,9);
      write('4.  Delete those not on mailing list');
      gotoxy(10,10);
      write('5.  Save file');
      gotoxy(10,11);
      write('6.  Get file');
      gotoxy(10,12);
      write('7.  Add records from file');
      gotoxy(10,13);
      write('8.  List size of file');
      gotoxy(10,14);
      write('9.  Mailing list menu');
      gotoxy(9,15);
      write('10.  Print menu');
      gotoxy(9,16);
      write('11.  Quit');
      gotoxy(1,18);
      write('Pick one: ');
      getinput(temp,escpressed);
      val(temp,c,code)
    end;


  begin
    done := false;
    indexes.size := 0;
    repeat
      menu(choice);
      case choice of
          1:getrecords(indexes);
          2:if indexes.size>0 then searchdriver(indexes);
          3:begin
              gotoxy(1,20);
              write('Are you sure<y,n>? ');
              readln(response);
              if response in ['Y','y'] then clearmemory(indexes)
            end;
          4:begin
              gotoxy(1,20);
              write('Are you sure<y,n>? ');
              readln(response);
              if response in ['Y','y'] then cleanout(indexes)
            end;
          5:begin
              clrscr;
              gotoxy(1,12);
              write('Save under? ');
              getinput(temp,escpressed);
              if not escpressed then
                begin
                  response := 'Y';
                  if fileexists(temp) then
                    begin
                      gotoxy(1,14);
                      write('That file already exists.  Overwrite<y,n>? ');
                      readln(response)
                    end;
                  if response in ['Y','y'] then
                    begin
                      if filecreation(temp) then
                        save(temp,indexes)
                      else
                        begin
                          gotoxy(1,14);
                          usermessage('File creation error.')
                        end
                    end
                end
            end;
          6:begin
              clrscr;
              gotoxy(1,12);
              write('Get file: ');
              getinput(temp,escpressed);
              if not escpressed then
                begin
                  if fileexists(temp) then
                    begin
                      if filevalid(temp) then
                        begin
                          clearmemory(indexes);
                          getfile(temp,indexes)
                        end
                      else
                        begin
                          gotoxy(1,14);
                          usermessage('That file is not an address file.')
                        end
                    end
                  else
                    begin
                      gotoxy(1,14);
                      usermessage('Cannot find that file.')
                    end
                end
            end;
          7:begin
              clrscr;
              gotoxy(1,10);
              write('Use what file to add records: ');
              getinput(temp,escpressed);
              if not escpressed then
                begin
                  gotoxy(1,14);
                  write('Check for duplicate records<y,n>? ');
                  getinput(resstr,escpressed);
                  if not escpressed then
                    begin
                      if fileexists(temp) then
                        begin
                          if filevalid(temp) then
                            append(temp,indexes,not (resstr[1] in ['N','n']))
                          else
                            begin
                              gotoxy(1,16);
                              usermessage('That file is not an address file.')
                            end
                        end
                      else
                        begin
                          gotoxy(1,16);
                          usermessage('Cannot find that file.')
                        end
                    end
                end
            end;
          8:displaysize(indexes.size);
          9:configdriver(indexes);
          10:printdriver(indexes);
          11:begin
              gotoxy(1,20);
              write('Are you sure<y,n>? ');
              readln(response);
              if response in ['Y','y'] then done := true
            end
      end {case of choice}
    until done
  end.