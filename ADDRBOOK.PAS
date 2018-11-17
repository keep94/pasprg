program test;

  uses crt,group1,iounit,procini;

  const
    MAXKEYSIZE = 15;
    MAXLINESIZE = 30;
    MAXPHONESIZE = 15;
    SIGNATURE = -1341563592;
  type
    labeltype = record
      g:memberinfotype;
      key:string[MAXKEYSIZE];
      lines:array[1..5] of string[MAXLINESIZE];
      phones:array[1..2] of string[MAXPHONESIZE]
    end;

    linkptrtype = ^node;

    node = record
      prev:linkptrtype;
      next:linkptrtype;
      data:labeltype
    end;

    addrbooktype = record
      top:linkptrtype;
      cur:linkptrtype
    end;


    litype = 0..23;
    labelusetype = set of litype;

    sheettype = record
      noleft:integer;
      posit:integer;
      p:linkptrtype;
      luse:labelusetype
    end;


  var GLOBAL_printer:string[10];
      GLOBAL_label:labelusetype;
      success,escpressed,done:boolean;
      choice:integer;
      temp,filename:string;
      f:file;
      numread,numwritten:word;


  Function caps(x:string):string;

    var cnt:integer;

    begin
      for cnt := 1 to length(x) do
      if (ord(x[cnt]) > 96) and (ord(x[cnt]) < 123) then
        x[cnt] := chr(ord(x[cnt]) - 32);
      caps := x
    end;


  Procedure gensetup;

    var g:text;
        linestr,literal,token:string;
        index:integer;
        done,endline,endfile:boolean;

    begin
      if fileexists('gensetup.ini') then
        begin
          assign(g,'gensetup.ini');
          reset(g);
          linestr := '';
          done := false;
          repeat
            getliteral(g,linestr,index,literal,endline,endfile);
            if endfile then done := true
            else
              begin
                token := literal;
                if caps(token) = 'PRINTER' then
                  begin
                    GLOBAL_printer := '';
                    while (not endline) do
                      begin
                        getliteral(g,linestr,index,literal,endline,endfile);
                        GLOBAL_printer := copy(literal,1,10)
                      end;
                    if GLOBAL_printer = '' then
                      begin
                        writeln(chr(7)+'Error in '+caps(token)+' line of GENSETUP.INI');
                        halt
                      end;
                    GLOBAL_printer := caps(GLOBAL_printer)
                  end
              end
          until done;
          close(g)
        end
      else GLOBAL_printer := ''
    end;


  Function spaces(x:integer):string;

    var temp:string;
        cnt:integer;

    begin
      temp := '';
      for cnt := 1 to x do temp := temp + ' ';
      spaces := temp
    end;


  Procedure initaddrbook(var addrbook:addrbooktype);

    var p,q:linkptrtype;

    begin
      new(p);
      new(q);
      p^.data.key := '';
      q^.data.key := chr(255);
      p^.next := q;
      q^.prev := p;
      p^.prev := nil;
      q^.next := nil;
      addrbook.top := p;
      addrbook.cur := p
    end;


  Function numlabels(addrbook:addrbooktype):integer;

    var count:integer;
        p:linkptrtype;

    begin
      count := 0;
      p := addrbook.top;
      while (p <> nil) do
        begin
          p := p^.next;
          count := count + 1
        end;
      numlabels := count - 2
    end;


  Procedure searchaddrbook(var addrbook:addrbooktype;key:string;var found:boolean);

    begin
      if addrbook.cur^.data.key <> key then
        begin
          while addrbook.cur^.data.key < key do
            addrbook.cur := addrbook.cur^.next;
          while addrbook.cur^.data.key > key do
            addrbook.cur := addrbook.cur^.prev
        end;
      found := (addrbook.cur^.data.key = key);
      if addrbook.cur = addrbook.top then addrbook.cur := addrbook.cur^.next
    end;

  Procedure settonull(var labels:labeltype);

    var cnt:integer;

    begin
      labels.g.marked := false;
      labels.g.membership := [];
      labels.key := ' ';
      for cnt := 1 to 5 do labels.lines[cnt] := '';
      for cnt := 1 to 2 do labels.phones[cnt] := ''
    end;


  Procedure addlabel(var addrbook:addrbooktype);

    var p:linkptrtype;

    begin
      new(p);
      settonull(p^.data);
      p^.prev := addrbook.cur;
      p^.next := addrbook.cur^.next;
      addrbook.cur^.next^.prev := p;
      addrbook.cur^.next := p;
      addrbook.cur := addrbook.cur^.next
    end;


  Procedure deletelabel(var addrbook:addrbooktype);

    var p:linkptrtype;

    begin
      p := addrbook.cur;
      addrbook.cur := addrbook.cur^.next;
      addrbook.cur^.prev := p^.prev;
      p^.prev^.next := addrbook.cur;
      dispose(p);
      if addrbook.cur^.next = nil then addrbook.cur := addrbook.cur^.prev
    end;


  Procedure repositlabel(var addrbook:addrbooktype);

    var p:linkptrtype;

    begin
      if (addrbook.cur^.data.key < addrbook.cur^.prev^.data.key) or
         (addrbook.cur^.data.key > addrbook.cur^.next^.data.key) then
        begin
          p := addrbook.cur;
          addrbook.cur := addrbook.cur^.next;
          addrbook.cur^.prev := p^.prev;
          p^.prev^.next := addrbook.cur;
          while addrbook.cur^.data.key < p^.data.key do
            addrbook.cur := addrbook.cur^.next;
          while addrbook.cur^.data.key > p^.data.key do
            addrbook.cur := addrbook.cur^.prev;
          p^.prev := addrbook.cur;
          p^.next := addrbook.cur^.next;
          addrbook.cur^.next^.prev := p;
          addrbook.cur^.next := p;
          addrbook.cur := addrbook.cur^.next
        end
    end;


  Procedure getlabels(var addrbook:addrbooktype;var f:file);

    var numread:word;

    begin
      while not eof(f) do
        begin
          addlabel(addrbook);
          blockread(f,addrbook.cur^.data,sizeof(addrbook.cur^.data),numread)
        end;
      addrbook.cur := addrbook.top^.next
    end;

  Procedure savelabels(addrbook:addrbooktype;var f:file);

    var numwritten:word;
        p:linkptrtype;

    begin
      p := addrbook.top^.next;
      while (p^.next <> nil) do
        begin
          blockwrite(f,p^.data,sizeof(p^.data),numwritten);
          p := p^.next
        end
    end;

  Procedure markall(addrbook:addrbooktype);

    var p:linkptrtype;

    begin
      p := addrbook.top^.next;
      while (p^.next <> nil) do
        begin
          p^.data.g.marked := true;
          p := p^.next
        end
    end;

  Procedure unmarkall(addrbook:addrbooktype);

    var p:linkptrtype;

    begin
      p := addrbook.top^.next;
      while (p^.next <> nil) do
        begin
          p^.data.g.marked := false;
          p := p^.next
        end
    end;

  Procedure cleargroup(addrbook:addrbooktype;var groupdata:grouptype;groupnum:integer);

    var p:linkptrtype;

    begin
      p := addrbook.top^.next;
      while (p^.next <> nil) do
        begin
          p^.data.g.membership := p^.data.g.membership - [groupindex(groupdata,groupnum)];
          p := p^.next
        end
    end;

  Procedure markallgroup(addrbook:addrbooktype;var groupdata:grouptype;groupnum:integer);

    var p:linkptrtype;

    begin
      p := addrbook.top^.next;
      while (p^.next <> nil) do
        begin
          markgroup(addr(p^.data.g),groupdata,groupnum,3);
          p := p^.next
        end
    end;

  Procedure showreccount(addrbook:addrbooktype);

    var p:linkptrtype;
        total,markedonly:integer;

    begin
      p := addrbook.top^.next;
      total := 0;
      markedonly := 0;
      while (p^.next <> nil) do
        begin
          if p^.data.g.marked then markedonly := markedonly + 1;
          total := total + 1;
          p := p^.next
        end;
      gotoxy(1,1);
      write('Total records: ',total:5,spaces(5),'Marked records: ',markedonly:5,spaces(5));
      write('Press any key.')
    end;

  Procedure clearlabels(var addrbook:addrbooktype);

    var p,q:linkptrtype;

    begin
      p := addrbook.top^.next;
      while (p^.next <> nil) do
        begin
          q := p^.next;
          dispose(p);
          p := q
        end;
      addrbook.top^.next := p;
      p^.prev := addrbook.top;
      addrbook.cur := addrbook.top
    end;

  Procedure destroyaddrbook(var addrbook:addrbooktype);

    var p:linkptrtype;

    begin
      clearlabels(addrbook);
      p := addrbook.top^.next;
      dispose(p);
      dispose(addrbook.top)
    end;


  Procedure displaylabel(var labels:labeltype;var groupdata:grouptype);

    var cnt:integer;

    begin
      gotoxy(1,3);
      for cnt := 1 to 8 do write('':80);
      gotoxy(1,3);
      if labels.g.marked then
        write('*')
      else write(' ');
      writeln('Key: ',labels.key);
      for cnt := 1 to 5 do
        begin
          if labels.g.marked then
            write('*')
          else write(' ');
          writeln('Line ',cnt,': ',labels.lines[cnt])
        end;
      for cnt := 1 to 2 do
        begin
          if labels.g.marked then
            write('*')
          else write(' ');
          writeln('Phone ',cnt,': ',labels.phones[cnt])
        end;
      showmembership(addr(labels.g),groupdata)
    end;


  Procedure editlabel(var labels:labeltype);

    var ctrl,scan:settype;
         posit:integer;
         done:boolean;
         temp:string;
         choice,schoice:char;

    begin
      ctrl := [27];
      scan := [72,80];
      posit := 1;
      done := false;
      repeat
        if posit = 1 then
          begin
            gotoxy(7,3);
            temp := labels.key;
            fieldinput(temp,MAXKEYSIZE,choice,schoice,ctrl,scan);
            labels.key := temp
          end
        else if (posit >= 2) and (posit <= 6) then
          begin
            gotoxy(10,2+posit);
            temp := labels.lines[posit-1];
            fieldinput(temp,MAXLINESIZE,choice,schoice,ctrl,scan);
            labels.lines[posit-1] := temp
          end
        else if (posit >= 7) and (posit <= 8) then
          begin
            gotoxy(11,2+posit);
            temp := labels.phones[posit-6];
            fieldinput(temp,MAXPHONESIZE,choice,schoice,ctrl,scan);
            labels.phones[posit-6] := temp
          end;
        if choice = chr(27) then done := true
        else if (choice = chr(13)) and (posit < 8) then posit := posit + 1
        else if (choice = chr(0)) then
          begin
            if (schoice = chr(72)) and (posit > 1) then posit := posit - 1
            else if (schoice = chr(80)) and (posit < 8) then posit := posit + 1
          end
      until done;
      if labels.key = '' then labels.key := ' '
      else labels.key := caps(labels.key)
    end;

  Procedure printlabels(addrbook:addrbooktype;markedonly:boolean);

    var cnt:integer;
        g:text;
        p:linkptrtype;
        dummy:char;
        escpressed:boolean;

    begin
      assign(g,'lpt1');
      rewrite(g);
      p := addrbook.top^.next;
      gotoxy(1,1);
      write('Press ESC to abort print.');
      escpressed := false;
      while (p^.next <> nil) and (not escpressed) do
        begin
          if (not markedonly) or (p^.data.g.marked) then
            begin
              for cnt := 1 to 5 do
                writeln(g,p^.data.lines[cnt]);
              writeln(g)
            end;
          p := p^.next;
          if keypressed then
            begin
              dummy := readkey;
              if dummy = chr(0) then dummy := readkey;
              if dummy = chr(27) then escpressed := true
            end
        end;
      close(g);
      gotoxy(1,1);
      write('':80)
    end;


  Procedure initsheet(var sheet:sheettype);

    var cnt:integer;

    begin
      sheet.luse := GLOBAL_label;
      sheet.p := nil;
      sheet.posit := 0;
      sheet.noleft := 0;
      for cnt := 0 to 19 do
        if (cnt in sheet.luse) then sheet.noleft := sheet.noleft + 1
    end;


  Procedure labelsnew(var sheet:sheettype);

    var cnt:integer;

    begin
      for cnt := 0 to 19 do
        sheet.luse := sheet.luse + [cnt];
      sheet.noleft := 20;
      sheet.posit := 0;
      sheet.p := nil
    end;


  Procedure labelsused(var sheet:sheettype);

    begin
      sheet.luse := [];
      sheet.noleft := 0;
      sheet.posit := 0;
      sheet.p := nil
    end;


  Procedure updatelabeluse(var sheet:sheettype;var done:boolean);

    var code,lnum,cnt,cnt1:integer;
        escpressed,exitloop:boolean;
        temp:string;

    begin
      exitloop := false;
      clrscr;
      writeln('CURRENT LABEL SHEET':50);
      writeln;
      sheet.posit := 0;
      sheet.p := nil;
      for cnt := 1 to 20 do
        begin
          write(cnt:2);
          if ((cnt - 1) in sheet.luse) then
            begin
              write('.'+spaces(32));
              if cnt mod 2 <> 0 then write(spaces(5))
            end
          else
            begin
              write('.  ');
              for cnt1 := 1 to 30 do write('X');
              if cnt mod 2 <> 0 then for cnt1 := 1 to 5 do write(' ')
            end;
          if cnt mod 2 = 0 then writeln
        end;
      gotoxy(1,13);
      writeln;
      writeln('XX = Used label');
      writeln;
      writeln('Enter U,N,P,A or number of label to change: ');
      writeln;
      writeln('U = Make all labels used       P = Start/ continue print');
      writeln('N = Make all labels new        A = Abort print');
      repeat
        gotoxy(45,16);
        getinput(temp,escpressed);
        gotoxy(45,16);
        write('':34);
        if caps(temp) = 'U' then
          begin
            labelsused(sheet);
            gotoxy(1,3);
            for cnt := 1 to 20 do
              begin
                write(cnt:2);
                write('.  ');
                for cnt1 := 1 to 30 do write('X');
                if cnt mod 2 <> 0 then for cnt1 := 1 to 5 do write(' ');
                if cnt mod 2 = 0 then writeln
              end
          end
        else if caps(temp) = 'N' then
          begin
            labelsnew(sheet);
            gotoxy(1,3);
            for cnt := 1 to 20 do
              begin
                write(cnt:2);
                write('.'+spaces(32));
                if cnt mod 2 <> 0 then write(spaces(5));
                if cnt mod 2 = 0 then writeln
              end
          end
        else if caps(temp) = 'P' then
          begin
            done := false;
            exitloop := true
          end
        else if caps(temp) = 'A' then
          begin
            done := true;
            exitloop := true
          end
        else
          begin
            val(temp,lnum,code);
            if (lnum >= 1) and (lnum <= 20) then
              begin
                if ((lnum - 1) in sheet.luse) then
                  begin
                    sheet.luse := sheet.luse - [lnum - 1];
                    gotoxy(6+40*((lnum-1) mod 2),3+((lnum-1) div 2));
                    for cnt := 1 to 30 do write('X');
                    sheet.noleft := sheet.noleft - 1
                  end
                else
                  begin
                    sheet.luse := sheet.luse + [lnum - 1];
                    gotoxy(6+40*((lnum-1) mod 2),3+((lnum-1) div 2));
                    for cnt := 1 to 30 do write(' ');
                    sheet.noleft := sheet.noleft + 1
                  end
              end
          end
      until exitloop
    end;


  Procedure sendtosheet(var g:text;var sheet:sheettype;q:linkptrtype);

    var cnt:integer;


    begin
      if sheet.noleft > 0 then
        begin
          while (not ((2*sheet.posit) in sheet.luse)) and
            (not ((2*sheet.posit + 1) in sheet.luse)) do
              begin
                sheet.posit := sheet.posit + 1;
                for cnt := 1 to 6 do writeln(g)
              end;
          if ((2*sheet.posit) in sheet.luse) and
            ((2*sheet.posit + 1) in sheet.luse) then
              begin
                if sheet.p = nil then
                  sheet.p := q
                else
                  begin
                    writeln(g);
                    for cnt := 1 to 5 do
                      begin
                        write(g,spaces(4)+sheet.p^.data.lines[cnt]);
                        write(g,spaces(41-length(sheet.p^.data.lines[cnt])));
                        writeln(g,q^.data.lines[cnt])
                      end;
                    sheet.luse := sheet.luse - [(2*sheet.posit),(2*sheet.posit+1)];
                    sheet.noleft := sheet.noleft - 2;
                    sheet.p := nil;
                    sheet.posit := sheet.posit + 1
                  end
              end
          else
            begin
              if ((2*sheet.posit) in sheet.luse) then
                begin
                  writeln(g);
                  for cnt := 1 to 5 do
                    writeln(g,spaces(4)+q^.data.lines[cnt]);
                  sheet.luse := sheet.luse - [(2*sheet.posit)];
                  sheet.noleft := sheet.noleft - 1;
                  sheet.posit := sheet.posit + 1
                end
              else
                begin
                  writeln(g);
                  for cnt := 1 to 5 do
                    writeln(g,spaces(45)+q^.data.lines[cnt]);
                  sheet.luse := sheet.luse - [(2*sheet.posit + 1)];
                  sheet.noleft := sheet.noleft - 1;
                  sheet.posit := sheet.posit + 1
                end
            end;
          if sheet.noleft = 0 then
            while (sheet.posit < 10) do
              begin
                for cnt := 1 to 6 do writeln(g);
                sheet.posit := sheet.posit + 1
              end
        end
    end;


  Procedure flushsheet(var g:text;var sheet:sheettype);

    var cnt:integer;


    begin
      if sheet.p <> nil then
        begin
          writeln(g);
          for cnt := 1 to 5 do
            writeln(g,spaces(4)+sheet.p^.data.lines[cnt]);
          sheet.luse := sheet.luse - [(2*sheet.posit)];
          sheet.noleft := sheet.noleft - 1;
          sheet.posit := sheet.posit + 1
        end;
      while (sheet.posit < 10) do
        begin
          for cnt := 1 to 6 do writeln(g);
           sheet.posit := sheet.posit + 1
         end
    end;

  Function nolabels(var sheet:sheettype):boolean;

    begin
      nolabels := (sheet.noleft = 0)
    end;


  Procedure destroysheet(var sheet:sheettype);

    begin
      GLOBAL_label := sheet.luse
    end;


  Procedure sheetlabels(addrbook:addrbooktype;markedonly:boolean);

    var cnt:integer;
        g:text;
        p:linkptrtype;
        dummy:char;
        done:boolean;
        sheet:sheettype;

    begin
      initsheet(sheet);
      updatelabeluse(sheet,done);
      clrscr;
      gotoxy(1,12);
      write('Printing labels. . .');
      if not done then
        begin
          assign(g,'lpt1');
          rewrite(g);
          p := addrbook.top^.next;
          while (p^.next <> nil) and (not done) do
            begin
              if nolabels(sheet) then
                begin
                  labelsnew(sheet);
                  updatelabeluse(sheet,done);
                  clrscr;
                  gotoxy(1,12);
                  write('Printing labels. . .')
                end
              else
                begin
                  if (not markedonly) or (p^.data.g.marked) then
                    sendtosheet(g,sheet,p);
                  p := p^.next;
                end
            end;
          if (not done) and (not nolabels(sheet)) then flushsheet(g,sheet);
          if nolabels(sheet) then labelsnew(sheet);
          close(g)
        end;
      destroysheet(sheet)
    end;

  Procedure printaddrbook(addrbook:addrbooktype;markedonly:boolean);

    var lineno,tlineno,cnt:integer;
        g:text;
        p:linkptrtype;
        dummy:char;
        escpressed:boolean;

    begin
      assign(g,'lpt1');
      rewrite(g);
      p := addrbook.top^.next;
      if GLOBAL_printer = 'HP540' then
        for cnt := 1 to 2 do writeln(g)
      else for cnt := 1 to 5 do writeln(g);
      lineno := 0;
      gotoxy(1,1);
      write('Press ESC to abort print.');
      escpressed := false;
      while (p^.next <> nil) and (not escpressed) do
        begin
          if (not markedonly) or (p^.data.g.marked) then
            begin
              for cnt := 1 to 2 do
                begin
                  write(g,p^.data.lines[cnt]);
                  write(g,spaces(40-length(p^.data.lines[cnt])));
                  if cnt = 1 then
                    write(g,'hm: ')
                  else write(g,'wk: ');
                  writeln(g,p^.data.phones[cnt])
                end;
              tlineno := 2;
              for cnt := 3 to 5 do
                if p^.data.lines[cnt] <> spaces(length(p^.data.lines[cnt])) then
                  tlineno := cnt;
              for cnt := 3 to tlineno do
                writeln(g,p^.data.lines[cnt]);
              writeln(g);
              lineno := lineno + tlineno + 1;
              if lineno >= 50 then
                begin
                  if GLOBAL_printer = 'HP540' then
                    for cnt := 1 to 60-lineno do writeln(g)
                  else for cnt := 1 to 66-lineno do writeln(g);
                  lineno := 0
                end
            end;
          p := p^.next;
          if keypressed then
            begin
              dummy := readkey;
              if dummy = chr(0) then dummy := readkey;
              if dummy = chr(27) then escpressed := true
            end
        end;
      if GLOBAL_printer = 'HP540' then
        for cnt := 1 to 58-lineno do writeln(g)
      else for cnt := 1 to 61-lineno do writeln(g);
      close(g);
      gotoxy(1,1);
      write('':80)
    end;


  Procedure editaddrbook(filename:string);

    var f:file;
        ctrl,scan,set1,set2:settype;
        choice,schoice,char1,char2:char;
        x,temp:string;
        addrbook:addrbooktype;
        groupdata:grouptype;
        done,found,escpressed:boolean;
        sig:longint;
        numwritten:word;
        tempval,code:integer;

    begin
      assign(f,filename);
      reset(f,1);
      seek(f,4);
      loadgroup(groupdata,f);
      initaddrbook(addrbook);
      getlabels(addrbook,f);
      close(f);
      showgroups(groupdata);
      ctrl := [1,5,11,12,13,25,27];
      scan := [60,61,62,63,64,65,66,67,68,72,80];
      done := false;
      repeat
        displaylabel(addrbook.cur^.data,groupdata);
        writeln;
        gotoxy(1,1);
        x := '';
        fieldinput(x,MAXKEYSIZE,choice,schoice,ctrl,scan);
        gotoxy(1,1);
        write('':80);
        case choice of
          chr(0):case schoice of
          chr(60):begin
                    gotoxy(1,1);
                    write('Name of new group? ');
                    set1 := [27];
                    set2 := [];
                    temp := '';
                    fieldinput(temp,MAXGRPLEN,char1,char2,set1,set2);
                    escpressed := (char1 = chr(27));
                    gotoxy(1,1);
                    write('':80);
                    if (not escpressed) and (numgroups(groupdata) < MAXGRP) then
                      begin
                        temp := copy(temp,1,MAXGRPLEN);
                        addgroup(groupdata,temp);
                        showgroups(groupdata)
                      end
                  end;
          chr(61):if numgroups(groupdata) > 0 then
                    begin
                      gotoxy(1,1);
                      write('Enter group number: ');
                      getinput(temp,escpressed);
                      gotoxy(1,1);
                      write('':80);
                      if (not escpressed) then
                        begin
                          val(temp,tempval,code);
                          if (tempval >= 1) and (tempval <= numgroups(groupdata)) then
                            begin
                              gotoxy(1,1);
                              write('Rename group as (ENTER deletes group): ');
                              set1 := [27];
                              set2 := [];
                              temp := '';
                              fieldinput(temp,MAXGRPLEN,char1,char2,set1,set2);
                              escpressed := (char1 = chr(27));
                              gotoxy(1,1);
                              write('':80);
                              if not escpressed then
                                begin
                                  temp := copy(temp,1,MAXGRPLEN);
                                  if temp = '' then
                                    begin
                                      cleargroup(addrbook,groupdata,tempval);
                                      removegroup(groupdata,tempval)
                                    end
                                  else editgroup(groupdata,tempval,temp);
                                  showgroups(groupdata)
                                end
                            end
                        end
                    end;
          chr(62):if numgroups(groupdata) > 0 then
                    begin
                      gotoxy(1,1);
                      write('Mark records belonging to group number: ');
                      getinput(temp,escpressed);
                      gotoxy(1,1);
                      write('':80);
                      if (not escpressed) then
                        begin
                          val(temp,tempval,code);
                          if (tempval >= 1) and (tempval <= numgroups(groupdata)) then
                            markallgroup(addrbook,groupdata,tempval);
                        end
                    end;
          chr(63):markall(addrbook);
          chr(64):unmarkall(addrbook);
          chr(65):begin
                    showreccount(addrbook);
                    pause;
                    gotoxy(1,1);
                    write('':80)
                  end;
          chr(66):begin
                    gotoxy(1,1);
                    write('Print labels for marked records only<y,n>? ');
                    getinput(temp,escpressed);
                    gotoxy(1,1);
                    write('':80);
                    if not escpressed then
                      begin
                        assign(f,filename);
                        rewrite(f,1);
                        sig := SIGNATURE;
                        blockwrite(f,sig,4,numwritten);
                        savegroup(groupdata,f);
                        savelabels(addrbook,f);
                        close(f);
                        if (temp = 'Y') or (temp = 'y') then
                          begin
                            if GLOBAL_printer = 'HP540' then
                              sheetlabels(addrbook,true)
                            else printlabels(addrbook,true)
                          end
                        else
                          begin
                            if GLOBAL_printer = 'HP540' then
                              sheetlabels(addrbook,false)
                            else printlabels(addrbook,false)
                          end
                      end;
                    clrscr;
                    showgroups(groupdata);
                    gotoxy(1,1);
                    write('':80)
                  end;
          chr(67):begin
                    gotoxy(1,1);
                    write('Print marked records only<y,n>? ');
                    getinput(temp,escpressed);
                    gotoxy(1,1);
                    write('':80);
                    if not escpressed then
                      begin
                        assign(f,filename);
                        rewrite(f,1);
                        sig := SIGNATURE;
                        blockwrite(f,sig,4,numwritten);
                        savegroup(groupdata,f);
                        savelabels(addrbook,f);
                        close(f);
                        if (temp = 'Y') or (temp = 'y') then
                          printaddrbook(addrbook,true)
                        else printaddrbook(addrbook,false)
                      end
                  end;
          chr(68):begin
                    assign(f,filename);
                    rewrite(f,1);
                    sig := SIGNATURE;
                    blockwrite(f,sig,4,numwritten);
                    savegroup(groupdata,f);
                    savelabels(addrbook,f);
                    destroyaddrbook(addrbook);
                    close(f);
                    done := true
                  end;
          chr(72):if addrbook.cur^.prev <> addrbook.top then
                    addrbook.cur := addrbook.cur^.prev;
          chr(80):if addrbook.cur^.next^.next <> nil then
                    addrbook.cur := addrbook.cur^.next
                 end;
          chr(1):begin
                   addlabel(addrbook);
                   if x = '' then x := ' ';
                   addrbook.cur^.data.key := caps(x);
                   displaylabel(addrbook.cur^.data,groupdata);
                   editlabel(addrbook.cur^.data);
                   repositlabel(addrbook)
                 end;
          chr(5):begin
                   editlabel(addrbook.cur^.data);
                   repositlabel(addrbook)
                 end;
          chr(11):begin
                    if addrbook.cur^.prev <> addrbook.top then
                      begin
                        addrbook.cur := addrbook.cur^.prev;
                        while (addrbook.cur^.prev <> addrbook.top) and
                          (not addrbook.cur^.data.g.marked) do
                            addrbook.cur := addrbook.cur^.prev
                      end
                  end;
          chr(12):begin
                    if addrbook.cur^.next^.next <> nil then
                      begin
                        addrbook.cur := addrbook.cur^.next;
                        while (addrbook.cur^.next^.next <> nil) and
                          (not addrbook.cur^.data.g.marked) do
                            addrbook.cur := addrbook.cur^.next
                      end
                  end;
          chr(13):begin
                    if x = '' then
                      addrbook.cur^.data.g.marked := not addrbook.cur^.data.g.marked
                    else if (x >= '0') and (x < ':') then
                      begin
                        val(x,tempval,code);
                        if (tempval >= 1) and (tempval <= numgroups(groupdata)) then
                          begin
                            if groupindex(groupdata,tempval) in addrbook.cur^.data.g.membership then
                              addrbook.cur^.data.g.membership :=
                                addrbook.cur^.data.g.membership - [groupindex(groupdata,tempval)]
                            else
                               addrbook.cur^.data.g.membership :=
                                 addrbook.cur^.data.g.membership + [groupindex(groupdata,tempval)]
                          end
                      end
                    else
                      begin
                        searchaddrbook(addrbook,caps(x),found);
                        if not found then
                          begin
                            gotoxy(1,1);
                            write(caps(x)+' not found.  Add<y,n>? ');
                            getinput(temp,escpressed);
                            gotoxy(1,1);
                            write('':80);
                            if (not escpressed) and ((temp = 'Y') or (temp = 'y')) then
                              begin
                                addlabel(addrbook);
                                if x = '' then x := ' ';
                                addrbook.cur^.data.key := caps(x);
                                displaylabel(addrbook.cur^.data,groupdata);
                                editlabel(addrbook.cur^.data);
                                repositlabel(addrbook);
                              end
                            else if (addrbook.cur^.next^.next <> nil) and
                              (caps(x) > addrbook.cur^.data.key) then
                              addrbook.cur := addrbook.cur^.next
                          end
                      end
                  end;
          chr(25):begin
                    if numlabels(addrbook) > 1 then
                      deletelabel(addrbook)
                    end;
          chr(27):begin
                  end
        end
      until done;
    end;


  Function filevalid(filename:string):boolean;

    var f:file;
        sig:longint;
        numread:word;

    begin
      if fileexists(filename) then
        begin
          assign(f,filename);
          reset(f,1);
          if filesize(f) >= 4 then
            begin
              blockread(f,sig,sizeof(sig),numread);
              filevalid := (sig = SIGNATURE)
            end
          else filevalid := false;
          close(f)
        end
      else filevalid := false
    end;


  Procedure createfile(filename:string;var success:boolean);

    var f:file;
        dummy:longint;
        numwritten:word;
        labels:labeltype;
        groupdata:grouptype;

    begin
      success := true;
      settonull(labels);
      assign(f,filename);
      rewrite(f,1);
      dummy := SIGNATURE;
      blockwrite(f,dummy,4,numwritten);
      initgroups(groupdata);
      blockwrite(f,groupdata,sizeof(groupdata),numwritten);
      blockwrite(f,labels,sizeof(labels),numwritten);
      close(f)
    end;


  Procedure menu(var c:integer);

    var temp:string;
        code:integer;
        escpressed:boolean;

    begin
      clrscr;
      gotoxy(1,7);
      writeln('M A I N   M E N U':48);
      gotoxy(10,10);
      write('1.  Open file');
      gotoxy(10,12);
      write('2.  Quit');
      gotoxy(1,14);
      write('Pick one: ');
      getinput(temp,escpressed);
      val(temp,c,code)
    end;


  begin
    textcolor(7);
    textbackground(0);
    gensetup;
    if GLOBAL_printer = 'HP540' then
      begin
        if fileexists('labeluse.ini') then
          begin
            assign(f,'labeluse.ini');
            reset(f,1);
            blockread(f,GLOBAL_label,sizeof(labelusetype),numread);
            close(f)
          end
        else
          begin
            write(chr(7)+'Cannot find LABELUSE.INI');
            halt
          end
      end;
    done := false;
    repeat
      menu(choice);
      case choice of
        1:begin
            clrscr;
            gotoxy(1,12);
            write('Open what file? ');
            getinput(filename,escpressed);
            if not escpressed then
              begin
                if filevalid(filename) then
                  editaddrbook(filename)
                else if not fileexists(filename) then
                  begin
                    gotoxy(1,14);
                    write('Cannot find that file.  Create a new one <y,n>? ');
                    getinput(temp,escpressed);
                    if (length(temp) >= 1) and (temp[1] in ['Y','y']) then
                      begin
                        if filecreation(filename) then
                          begin
                            createfile(filename,success);
                            if not success then
                              begin
                                writeln;
                                write(chr(7)+'Out of disk space.  Press any key.')
                              end
                            else editaddrbook(filename)
                          end
                        else
                          begin
                            gotoxy(1,16);
                            write(chr(7)+'File creation error.  Press any key');
                            pause
                          end
                      end
                  end
                else
                  begin
                    gotoxy(1,16);
                    write(chr(7)+'That file is not an address book file.  Press any key');
                    pause
                  end
              end
          end;
        2:done := true
      end
    until done;
    if GLOBAL_printer = 'HP540' then
      begin
        assign(f,'labeluse.ini');
        rewrite(f,1);
        blockwrite(f,GLOBAL_label,sizeof(labelusetype),numwritten);
        close(f)
      end
  end.