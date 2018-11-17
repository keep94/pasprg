program budget;

  uses crt,iounit,procini;

  type
    linerectype = record
      cat:string[4];
      description:string[15];
      numinfo:array[3..7] of real
    end;
    lineptrtype = ^linerectype;
    sheettype = record
      size:integer;
      data:array[1..2000] of lineptrtype
    end;
    offsettype = array[1..8] of integer;
    arraytype = array[0..3999] of byte;
    ptrtype = ^arraytype;

    nametype = array[1..7] of string[15];

  var GLOBAL_printer:string[10];
      offset:offsettype;
      name:nametype;
      sheet:sheettype;
      choice,schoice:char;
      x,filename:string;
      lin,col:integer;
      escpressed,done,next:boolean;
      ctrl,scan:settype;
      prevcat:real;
      response:char;


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

  Procedure highlight(f,b,x,y,l:integer);

   var p:ptrtype;
       attr,posit,cnt:integer;

   begin
     p := ptr($B800,$0);
     attr := 16*b + f;
     posit := (y - 1)*160 + (x - 1)*2 + 1;
     for cnt := 1 to l do
       begin
         p^[posit] := attr;
         posit := posit + 2
       end
   end;


  Function getstring(p:lineptrtype;posit:integer):string;

    var temp:string;

    begin
      if posit < 1 then posit := 1;
      if posit > 7 then posit := 7;
      if posit = 1 then getstring := p^.cat
      else if posit = 2 then getstring := p^.description
      else
        begin
          if (p^.numinfo[posit] > 999999.99) or (p^.numinfo[posit] < -99999.99) then
            temp := '*'
          else str(p^.numinfo[posit]:0:2,temp);
          getstring := temp
        end
    end;

  Function getval(p:lineptrtype;posit:integer):real;

    var temp:real;
        code:integer;

    begin
      if posit < 1 then posit := 1;
      if posit > 7 then posit := 7;
      if posit = 1 then
        begin
          val(p^.cat,temp,code);
          getval := temp
        end
      else if posit = 2 then getval := 0
      else getval := p^.numinfo[posit]
    end;

  Procedure setval(p:lineptrtype;posit:integer;x:real);

    var temp:string;
        intx,cnt,d,l:integer;

    begin
      if posit < 1 then posit := 1;
      if posit > 7 then posit := 7;
      if posit = 1 then
        begin
          intx := trunc(x);
          temp := '';
          for cnt := 1 to 4 do
            begin
              d := intx mod 10;
              intx := intx div 10;
              temp := chr(48 + d) + temp
            end;
          p^.cat := temp
        end
      else if posit = 2 then
        begin
          str(x:0:2,temp);
          p^.description := temp
        end
      else p^.numinfo[posit] := x
    end;

  Procedure setstring(p:lineptrtype;posit:integer;x:string);

    var q:^string;
        temp:real;
        code:integer;

    begin
      if posit = 2 then
        p^.description := copy(x,1,15)
      else
        begin
          val(x,temp,code);
          setval(p,posit,temp)
        end
    end;

  Procedure initialize(var sheet:sheettype);

    var cnt:integer;
          p:lineptrtype;

   begin
      new(p);
      setval(p,1,0);
      setstring(p,2,'');
      for cnt := 3 to 7 do
        setval(p,cnt,0);
      sheet.data[1] := p;
      sheet.size := 1
    end;

  Procedure clear(var sheet:sheettype);

    var cnt:integer;

    begin
      for cnt := 1 to sheet.size do
        dispose(sheet.data[cnt]);
      sheet.size := 0
    end;

  Procedure update100(var sheet:sheettype;lineno:integer);

    var x:array[3..7] of real;
        cnt,posit:integer;

    begin
      posit := lineno + 1;
      for cnt := 3 to 7 do
        x[cnt] := 0.0;
      while (posit <= sheet.size) and (trunc(getval(sheet.data[posit],1))
      div 100 = trunc(getval(sheet.data[lineno],1)) div 100) do
        begin
          for cnt := 3 to 7 do
            x[cnt] := x[cnt] + getval(sheet.data[posit],cnt);
          posit := posit + 1
        end;
      for cnt := 3 to 7 do
        setval(sheet.data[lineno],cnt,x[cnt])
    end;

  Procedure update(var sheet:sheettype;lineno:integer);

    var posit:integer;

    begin
      posit := lineno - 1;
      while (posit >= 1) and (trunc(getval(sheet.data[posit],1)) div 100 =
      trunc(getval(sheet.data[lineno],1)) div 100) do posit := posit - 1;
      posit := posit + 1;
      if trunc(getval(sheet.data[posit],1)) mod 100 = 0 then
        update100(sheet,posit)
    end;

  Procedure insertline(var sheet:sheettype;lineno:integer);

    var cnt:integer;
          p:lineptrtype;

    begin
      for cnt := sheet.size downto lineno do
        sheet.data[cnt + 1] := sheet.data[cnt];
      sheet.size := sheet.size + 1;
      new(p);
      if lineno = 1 then
        setval(p,1,0)
      else
        setval(p,1,getval(sheet.data[lineno-1],1) + 1);
      setstring(p,2,'');
      for cnt := 3 to 7 do
        setval(p,cnt,0);
      sheet.data[lineno] := p;
      if trunc(getval(sheet.data[lineno],1)) mod 100 = 0 then
        update100(sheet,lineno)
    end;

  Procedure deleteline(var sheet:sheettype;lineno:integer);

    var cnt:integer;

    begin
      for cnt := 3 to 7 do
        setval(sheet.data[lineno],cnt,0);
      update(sheet,lineno);
      dispose(sheet.data[lineno]);
      for cnt := lineno + 1 to sheet.size do
        sheet.data[cnt-1] := sheet.data[cnt];
      sheet.size := sheet.size - 1
    end;

  Procedure setline(var sheet:sheettype;var lin,col:integer;x:string);

    var xval:real;
        code,cnt,posit,cnt1:integer;
        c:array[3..7] of real;
        p:lineptrtype;

    begin
      if col = 1 then
        begin
          new(p);
          val(x,xval,code);
          if xval > 9999 then xval := 9999;
          if xval < 0 then xval := 0;
          xval := trunc(xval);
          setval(p,1,getval(sheet.data[lin],1));
          setstring(p,2,getstring(sheet.data[lin],2));
          for cnt := 3 to 7 do
            setval(p,cnt,getval(sheet.data[lin],cnt));
          deleteline(sheet,lin);
          posit := 1;
          while (posit <= sheet.size) and (xval > getval(sheet.data[posit],1)) do
            posit := posit + 1;
          if (posit > sheet.size) or (xval < getval(sheet.data[posit],1)) then
            begin
              for cnt1 := sheet.size downto posit do
                sheet.data[cnt1+1] := sheet.data[cnt1];
              sheet.size := sheet.size + 1;
              setval(p,1,xval);
              sheet.data[posit] := p;
              lin := posit;
              update(sheet,lin)
            end
          else
            begin
              for cnt1 := sheet.size downto lin do
                sheet.data[cnt1+1] := sheet.data[cnt1];
              sheet.size := sheet.size + 1;
              sheet.data[lin] := p;
              update(sheet,lin)
            end
        end
      else if col = 2 then setstring(sheet.data[lin],2,x)
      else if col = 3 then
        begin
          val(x,xval,code);
          if xval > 999999.99 then xval := 999999.99;
          if xval < -99999.99 then xval := -99999.99;
          c[3] := getval(sheet.data[lin],3);
          c[7] := getval(sheet.data[lin],7);
          c[7] := c[7] + xval - c[3];
          c[3] := xval;
          setval(sheet.data[lin],3,c[3]);
          setval(sheet.data[lin],7,c[7]);
          update(sheet,lin)
        end
      else if col = 4 then
        begin
          val(x,xval,code);
          if xval > 999999.99 then xval := 999999.99;
          if xval < -99999.99 then xval := -99999.99;
          c[4] := getval(sheet.data[lin],4);
          c[5] := getval(sheet.data[lin],5);
          c[7] := getval(sheet.data[lin],7);
          c[7] := c[7] - xval + c[4];
          c[5] := c[5] + xval - c[4];
          c[4] := xval;
          setval(sheet.data[lin],4,c[4]);
          setval(sheet.data[lin],5,c[5]);
          setval(sheet.data[lin],7,c[7]);
          update(sheet,lin)
        end
      else if col = 5 then
        begin
          val(x,xval,code);
          if xval > 999999.99 then xval := 999999.99;
          if xval < -99999.99 then xval := -99999.99;
          c[5] := getval(sheet.data[lin],5);
          c[6] := getval(sheet.data[lin],6);
          c[7] := getval(sheet.data[lin],7);
          c[7] := c[7] - xval + c[5];
          c[6] := c[6] - xval + c[5];
          c[5] := xval;
          setval(sheet.data[lin],5,c[5]);
          setval(sheet.data[lin],6,c[6]);
          setval(sheet.data[lin],7,c[7]);
          update(sheet,lin)
        end
      else if col = 6 then
        begin
          val(x,xval,code);
          if xval > 999999.99 then xval := 999999.99;
          if xval < -99999.99 then xval := -99999.99;
          c[6] := getval(sheet.data[lin],6);
          c[7] := getval(sheet.data[lin],7);
          c[7] := c[7] + xval - c[6];
          c[6] := xval;
          setval(sheet.data[lin],6,c[6]);
          setval(sheet.data[lin],7,c[7]);
          update(sheet,lin)
        end
      else if col = 7 then
        begin
          val(x,xval,code);
          if xval > 999999.99 then xval := 999999.99;
          if xval < -99999.99 then xval := -99999.99;
          setval(sheet.data[lin],7,xval);
          update(sheet,lin)
        end
    end;

  Procedure inputprompt(lin,col:integer);

    begin
      gotoxy(1,1);
      write('':79);
      gotoxy(1,1);
      write(lin,' ',name[col],' : ')
    end;


  Procedure displayscreen(var sheet:sheettype;lin,col:integer);

    var scr,cnt,cnt1,posit:integer;

    begin
      clrscr;
      gotoxy(1,3);
      write('No. '+' Cat.'+' Description    '+' Alloc    '+' Spent    '+' YTD      '+' Old bal  '+' New bal  ');
      scr := (lin - 1) div 18;
      for cnt := 1 to 18 do
        begin
          posit := 18*scr + cnt;
          if posit <= sheet.size then
            begin
              gotoxy(1,3+cnt);
              write(posit:4);
              gotoxy(6,3+cnt);
              write(getstring(sheet.data[posit],1));
              gotoxy(11,3+cnt);
              write(getstring(sheet.data[posit],2));
              for cnt1 := 3 to 7 do
                begin
                  gotoxy(6+offset[cnt1],3+cnt);
                  write(getstring(sheet.data[posit],cnt1):9)
               end
            end
        end;
      highlight(0,7,6+offset[col],3+lin - 18*scr,offset[col+1] - offset[col] - 1);
      inputprompt(lin,col)
    end;

  Procedure uparrow(var sheet:sheettype;var lin,col:integer);

    var scr:integer;

    begin
      if lin > 1 then
        begin
          lin := lin - 1;
          if (lin mod 18 = 0) then displayscreen(sheet,lin,col)
          else
            begin
              scr := (lin - 1) div 18;
              highlight(7,0,6+offset[col],4+lin - 18*scr,offset[col+1] - offset[col] - 1);
              highlight(0,7,6+offset[col],3+lin - 18*scr,offset[col+1] - offset[col] - 1);
              inputprompt(lin,col)
            end
        end
    end;

  Procedure downarrow(var sheet:sheettype;var lin,col:integer);

    var scr:integer;

    begin
      if lin < sheet.size then
        begin
          lin := lin + 1;
          if ((lin - 1) mod 18 = 0) then displayscreen(sheet,lin,col)
          else
            begin
              scr := (lin - 1) div 18;
              highlight(7,0,6+offset[col],2+lin - 18*scr,offset[col+1] - offset[col] - 1);
              highlight(0,7,6+offset[col],3+lin - 18*scr,offset[col+1] - offset[col] - 1);
              inputprompt(lin,col)
            end
        end
      else if (getval(sheet.data[lin],1) < 9999) and (sheet.size < 2000) then
        begin
          insertline(sheet,lin + 1);
          lin := lin + 1;
          displayscreen(sheet,lin,col)
        end
    end;

  Procedure leftarrow(var sheet:sheettype;var lin,col:integer);

    var scr:integer;

    begin
      scr := (lin - 1) div 18;
      highlight(7,0,6+offset[col],3+lin - 18*scr,offset[col+1] - offset[col] - 1);
      col := col - 1;
      if col = 0 then col := 7;
      highlight(0,7,6+offset[col],3+lin - 18*scr,offset[col+1] - offset[col] - 1);
      inputprompt(lin,col)
    end;

  Procedure rightarrow(var sheet:sheettype;var lin,col:integer);

    var scr:integer;

    begin
      scr := (lin - 1) div 18;
      highlight(7,0,6+offset[col],3+lin - 18*scr,offset[col+1] - offset[col] - 1);
      col := col + 1;
      if col = 8 then col := 1;
      highlight(0,7,6+offset[col],3+lin - 18*scr,offset[col+1] - offset[col] - 1);
      inputprompt(lin,col)
    end;

  Procedure pgup(var sheet:sheettype;var lin,col:integer);

    begin
      if lin > 1 then
        begin
          lin := lin - 18;
          if lin < 1 then lin := 1;
          displayscreen(sheet,lin,col)
        end
    end;


  Procedure pgdown(var sheet:sheettype;var lin,col:integer);

    begin
      if lin < sheet.size then
        begin
          lin := lin + 18;
          if lin > sheet.size then lin := sheet.size;
          displayscreen(sheet,lin,col)
        end
    end;

  Procedure savesheet(var sheet:sheettype;filename:string);

    var f:file of linerectype;
        cnt:integer;

    begin
      assign(f,filename);
      rewrite(f);
      for cnt := 1 to sheet.size do
        write(f,sheet.data[cnt]^);
      close(f)
    end;

  Procedure getsheet(var sheet:sheettype;filename:string);

    var f:file of linerectype;
        cnt:integer;
        p:lineptrtype;

    begin
      assign(f,filename);
      reset(f);
      clear(sheet);
      cnt := 0;
      while (not eof(f)) do
        begin
          cnt := cnt + 1;
          new(p);
          read(f,p^);
          sheet.data[cnt] := p
        end;
      sheet.size := cnt;
      close(f)
    end;


  Procedure savenext(var sheet:sheettype;filename:string);

    var f:file of linerectype;
        cnt:integer;
        temp:linerectype;

    begin
      assign(f,filename);
      rewrite(f);
      for cnt := 1 to sheet.size do
        begin
          temp := sheet.data[cnt]^;
          temp.numinfo[4] := 0.0;
          temp.numinfo[6] := temp.numinfo[7];
          temp.numinfo[7] := temp.numinfo[7] + temp.numinfo[3];
          write(f,temp)
        end;
      close(f)
    end;

  Procedure print(var sheet:sheettype;filename:string);

    var g:text;
        top,mid,bot,temp:string[80];
        cnt,posit,cnt1:integer;
        escpressed:boolean;
        dummy:char;

    procedure heading;

      var i:integer;

      begin
        if GLOBAL_printer = 'HP540' then
          for i := 1 to 2 do writeln(g)
        else for i := 1 to 5 do writeln(g);
        writeln(g,top);
        write(g,chr(179)+'No. '+chr(179)+'Cat.'+chr(179)+'Description');
        write(g,stringrep(4,32)+chr(179)+'Alloc    '+chr(179)+'Spent    ');
        write(g,chr(179)+'YTD      '+chr(179)+'Old bal  '+chr(179));
        writeln(g,'New bal  '+chr(179));
        writeln(g,mid)
      end;

    procedure ffeed;

      var i:integer;

      begin
        if GLOBAL_printer = 'HP540' then
          for i := 1 to 57 - 2*posit do writeln(g)
        else for i := 1 to 60 - 2*posit do writeln(g)
      end;

    begin
      top := '';
      mid := '';
      bot := '';
      top := top + chr(218) + stringrep(4,196);
      mid := mid + chr(195) + stringrep(4,196);
      bot := bot + chr(192) + stringrep(4,196);
      top := top + chr(194) + stringrep(4,196);
      mid := mid + chr(197) + stringrep(4,196);
      bot := bot + chr(193) + stringrep(4,196);
      top := top + chr(194) + stringrep(15,196);
      mid := mid + chr(197) + stringrep(15,196);
      bot := bot + chr(193) + stringrep(15,196);
      for cnt := 3 to 7 do
        begin
          top := top + chr(194) + stringrep(9,196);
          mid := mid + chr(197) + stringrep(9,196);
          bot := bot + chr(193) + stringrep(9,196)
        end;
      top := top + chr(191);
      mid := mid + chr(180);
      bot := bot + chr(217);
      assign(g,filename);
      rewrite(g);
      write(g,chr(27)+'6');
      cnt := 1;
      posit := 1;
      escpressed := false;
      heading;
      while (cnt <= sheet.size) and (not escpressed) do
        begin
          str(cnt:4,temp);
          write(g,chr(179));
          write(g,temp);
          write(g,chr(179));
          write(g,getstring(sheet.data[cnt],1));
          write(g,chr(179));
          temp := getstring(sheet.data[cnt],2);
          write(g,temp+stringrep(15 - length(temp),32));
          write(g,chr(179));
          for cnt1 := 3 to 7 do
            begin
              write(g,getstring(sheet.data[cnt],cnt1):9);
              write(g,chr(179))
            end;
          writeln(g);
          cnt := cnt + 1;
          posit := posit + 1;
          if (cnt > sheet.size) then
            begin
              writeln(g,bot);
              ffeed
            end
          else if (cnt - 1) mod 24 = 0 then
            begin
              writeln(g,bot);
              ffeed;
              heading;
              posit := 1
            end
          else writeln(g,mid);
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
    gensetup;
    offset[1] := 0;
    offset[2] := 5;
    offset[3] := 21;
    offset[4] := 31;
    offset[5] := 41;
    offset[6] := 51;
    offset[7] := 61;
    offset[8] := 71;
    name[1] := 'Cat.';
    name[2] := 'Description';
    name[3] := 'Alloc';
    name[4] := 'Spent';
    name[5] := 'YTD';
    name[6] := 'Old Bal';
    name[7] := 'New Bal';
    initialize(sheet);
    lin := 1;
    col := 1;
    displayscreen(sheet,lin,col);
    done := false;
    ctrl := [13,14,25];
    scan := [45,60,61,62,67,68,72,73,75,77,80,81];
    repeat
      returninput(x,choice,schoice,ctrl,scan);
      case choice of
        chr(0):begin
                 if schoice = chr(62) then
                   begin
                     schoice := chr(60);
                     next := true
                   end
                 else next := false;
                 case schoice of
                   chr(45):done := true;
                   chr(60):begin
                             gotoxy(1,1);
                             write('':79);
                             gotoxy(1,1);
                             if next then write('Save next month as: ')
                             else write('Save as: ');
                             getinput(filename,escpressed);
                             if not escpressed then
                               begin
                                 response := 'Y';
                                 if fileexists(filename) then
                                   begin
                                     gotoxy(1,1);
                                     write('':79);
                                     gotoxy(1,1);
                                     write('That file already exists overwrite<y,n>? ');
                                     readln(response)
                                   end;
                                 if response in ['Y','y'] then
                                   if filecreation(filename) then
                                     begin
                                       if next then savenext(sheet,filename)
                                       else savesheet(sheet,filename)
                                     end
                                   else
                                     begin
                                       gotoxy(1,1);
                                       write('':79);
                                       gotoxy(1,1);
                                       write(chr(7)+'File creation error.');
                                       pause
                                     end
                               end;
                             inputprompt(lin,col)
                           end;
                   chr(61):begin
                             gotoxy(1,1);
                             write('':79);
                             gotoxy(1,1);
                             write('Get file: ');
                             getinput(filename,escpressed);
                             if not escpressed then
                               if fileexists(filename) then
                                 begin
                                   getsheet(sheet,filename);
                                   lin := 1;
                                   col := 1;
                                   displayscreen(sheet,lin,col)
                                 end
                               else
                                 begin
                                   gotoxy(1,1);
                                   write('':79);
                                   gotoxy(1,1);
                                   write(chr(7)+'Cannot find that file.');
                                   pause
                                 end;
                             inputprompt(lin,col)
                           end;
                   chr(67):begin
                             gotoxy(1,1);
                             write('':79);
                             gotoxy(1,1);
                             write('Send output to? ');
                             getinput(filename,escpressed);
                             if not escpressed then
                               print(sheet,filename);
                             inputprompt(lin,col)
                           end;
                   chr(68):begin
                             gotoxy(1,1);
                             write('':79);
                             gotoxy(1,1);
                             write('Open new file<y,n>? ');
                             readln(response);
                             if response in ['Y','y'] then
                               begin
                                 clear(sheet);
                                 initialize(sheet);
                                 lin := 1;
                                 col := 1;
                                 displayscreen(sheet,lin,col)
                               end
                             else inputprompt(lin,col)
                           end;
                   chr(72):uparrow(sheet,lin,col);
                   chr(73):pgup(sheet,lin,col);
                   chr(75):leftarrow(sheet,lin,col);
                   chr(77):rightarrow(sheet,lin,col);
                   chr(80):downarrow(sheet,lin,col);
                   chr(81):pgdown(sheet,lin,col)
                 end
                end;
        chr(13):begin
                  setline(sheet,lin,col,x);
                  displayscreen(sheet,lin,col)
                end;
        chr(14):begin
                  if lin = 1 then prevcat := -1
                  else prevcat := getval(sheet.data[lin - 1],1);
                  if getval(sheet.data[lin],1) - prevcat > 1 then
                    begin
                      insertline(sheet,lin);
                      displayscreen(sheet,lin,col)
                    end
                end;
        chr(25):begin
                  if sheet.size > 1 then
                    begin
                      deleteline(sheet,lin);
                      if lin > sheet.size then lin := sheet.size;
                      displayscreen(sheet,lin,col)
                    end
                end
      end
    until done;
    clear(sheet);
    clrscr
  end.
