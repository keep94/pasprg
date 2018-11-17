program budget;

  uses crt,dos,iounit,procini,trans,dates;

  const
    LOG_MAX_SIZE = 200;
    LOG_FILE_NAME = 'translog.dat';
    LOG_FILE_ENV = 'TRANSLOG';

  type
    linerectype = record
      cat:string[4];
      description:string[18];
      numinfo:array[3..6] of real
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

    transarraytype = array[0..199] of transtype;

    logtype = record
      size:integer;
      data:transarraytype
    end;

    logptrtype = ^logtype;

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
      g_filename:string;
      logptr:logptrtype;
      thmn,thyr:integer;
      g_logfile:string;



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
        bal:real;

    begin
      if posit < 1 then posit := 1;
      if posit > 7 then posit := 7;
      if posit = 1 then getstring := p^.cat
      else if posit = 2 then getstring := p^.description
      else if posit = 7 then
        begin
          bal := p^.numinfo[4] - p^.numinfo[6];
          if (bal > 9999999.99) or (bal < -999999.99) then
            temp := '*'
          else str(bal:0:2,temp);
          getstring := temp
        end
      else
        begin
          if (p^.numinfo[posit] > 9999999.99) or (p^.numinfo[posit] < -999999.99) then
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
      else if posit = 7 then getval := p^.numinfo[4] - p^.numinfo[6]
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
      else if posit = 7 then
        begin
          writeln('Trying to set posit=7');
          halt
        end
      else p^.numinfo[posit] := x
    end;

  Procedure setstring(p:lineptrtype;posit:integer;x:string);

    var q:^string;
        temp:real;
        code:integer;

    begin
      if posit = 2 then
        p^.description := copy(x,1,18)
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
      setstring(p,2,'Total Earned');
      for cnt := 3 to 6 do
        setval(p,cnt,0);
      sheet.data[1] := p;
      new(p);
      setval(p,1,1);
      setstring(p,2,'Total Spent');
      for cnt := 3 to 6 do
        setval(p,cnt,0);
      sheet.data[2] := p;
      new(p);
      setval(p,1,2);
      setstring(p,2,'Total Saved');
      for cnt := 3 to 6 do
        setval(p,cnt,0);
      sheet.data[3] := p;
      sheet.size := 3
    end;

  Procedure clear(var sheet:sheettype);

    var cnt:integer;

    begin
      for cnt := 1 to sheet.size do
        dispose(sheet.data[cnt]);
      sheet.size := 0
    end;

  Procedure updatetotals(var sheet:sheettype);

    var income:array[3..6] of real;
        expense:array[3..6] of real;
        cnt,cnt1:integer;

    begin
      if sheet.size >= 3 then
        begin
          for cnt := 3 to 6 do
            begin
              income[cnt] := 0.0;
              expense[cnt] := 0.0
            end;
          for cnt := 4 to sheet.size do
            begin
              if (trunc(getval(sheet.data[cnt],1)) mod 100 <> 0) and
                 (trunc(getval(sheet.data[cnt],1)) div 100 > 0) then
                if (getval(sheet.data[cnt],1) < 9000) then
                  for cnt1 := 3 to 6 do
                    expense[cnt1] := expense[cnt1] + getval(sheet.data[cnt],cnt1)
                else if (trunc(getval(sheet.data[cnt],1)) < 9900) then
                  for cnt1 := 3 to 6 do
                    income[cnt1] := income[cnt1] + getval(sheet.data[cnt],cnt1)
            end;
          if getval(sheet.data[1],1) = 0 then
            for cnt1 := 3 to 6 do
              setval(sheet.data[1],cnt1,income[cnt1]);
          if getval(sheet.data[2],1) = 1 then
            for cnt1 := 3 to 6 do
              setval(sheet.data[2],cnt1,expense[cnt1]);
          if getval(sheet.data[3],1) = 2 then
            for cnt1 := 3 to 6 do
              setval(sheet.data[3],cnt1,income[cnt1] - expense[cnt1])
        end
    end;



  Procedure update100(var sheet:sheettype;lineno:integer);

    var x:array[3..6] of real;
        cnt,posit:integer;

    begin
      posit := lineno + 1;
      for cnt := 3 to 6 do
        x[cnt] := 0.0;
      while (posit <= sheet.size) and (trunc(getval(sheet.data[posit],1))
      div 100 = trunc(getval(sheet.data[lineno],1)) div 100) do
        begin
          for cnt := 3 to 6 do
            x[cnt] := x[cnt] + getval(sheet.data[posit],cnt);
          posit := posit + 1
        end;
      for cnt := 3 to 6 do
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
        update100(sheet,posit);
      updatetotals(sheet)
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
      for cnt := 3 to 6 do
        setval(p,cnt,0);
      sheet.data[lineno] := p;
      if trunc(getval(sheet.data[lineno],1)) div 100 = 0 then
        updatetotals(sheet)
      else if trunc(getval(sheet.data[lineno],1)) mod 100 = 0 then
        update100(sheet,lineno)
    end;

  Procedure deleteline(var sheet:sheettype;lineno:integer);

    var cnt:integer;

    begin
      for cnt := 3 to 6 do
        setval(sheet.data[lineno],cnt,0);
      update(sheet,lineno);
      dispose(sheet.data[lineno]);
      for cnt := lineno + 1 to sheet.size do
        sheet.data[cnt-1] := sheet.data[cnt];
      sheet.size := sheet.size - 1
    end;

  Function findline(var sheet:sheettype;code:integer):integer;

    var start,finish,middle,currentVal:integer;
        done:boolean;

    begin
      done := false;
      start := 1;
      finish := sheet.size;
      while (not done) do
        begin
          if (finish < start) then
            begin
              findline := -1;
              done := true
            end
          else
            begin
              middle := (start + finish) div 2;
              currentVal := trunc(getVal(sheet.data[middle],1));
              if (currentVal = code) then
                begin
                  done := true;
                  findline := middle
                end
              else if (currentVal < code) then
                 start := middle + 1
              else
                 finish := middle - 1
            end
        end
    end;

  Procedure setlineasvalue(var sheet:sheettype;var lin:integer;col:integer;xval:real);

    var
        code,cnt,posit,cnt1:integer;
        c:array[3..6] of real;
        p:lineptrtype;

    begin
      if col = 1 then
        begin
          new(p);
          if xval > 9999 then xval := 9999;
          if xval < 0 then xval := 0;
          xval := trunc(xval);
          setval(p,1,getval(sheet.data[lin],1));
          setstring(p,2,getstring(sheet.data[lin],2));
          for cnt := 3 to 6 do
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
      else if col = 3 then
        begin
          
          if xval > 9999999.99 then xval := 9999999.99;
          if xval < -999999.99 then xval := -999999.99;
          c[3] := getval(sheet.data[lin],3);
          c[4] := getval(sheet.data[lin],4);
          c[4] := c[4] + xval - c[3];
          c[3] := xval;
          setval(sheet.data[lin],3,c[3]);
          setval(sheet.data[lin],4,c[4]);
          update(sheet,lin)
        end
      else if col = 4 then
        begin
          
          if xval > 9999999.99 then xval := 9999999.99;
          if xval < -999999.99 then xval := -999999.99;
          c[4] := xval;
          setval(sheet.data[lin],4,c[4]);
          update(sheet,lin)
        end
      else if col = 5 then
        begin
          
          if xval > 9999999.99 then xval := 9999999.99;
          if xval < -999999.99 then xval := -999999.99;
          c[5] := getval(sheet.data[lin],5);
          c[6] := getval(sheet.data[lin],6);
          c[6] := c[6] + xval - c[5];
          c[5] := xval;
          setval(sheet.data[lin],5,c[5]);
          if getval(sheet.data[lin],1) < 9900 then
            setval(sheet.data[lin],6,c[6]);
          update(sheet,lin)
        end
      else if col = 6 then
        begin
          
          if xval > 9999999.99 then xval := 9999999.99;
          if xval < -999999.99 then xval := -999999.99;
          c[5] := getval(sheet.data[lin],5);
          c[6] := getval(sheet.data[lin],6);
          c[5] := c[5] + xval - c[6];
          c[6] := xval;
          setval(sheet.data[lin],6,c[6]);
          if getval(sheet.data[lin],1) >= 9900 then
            setval(sheet.data[lin],5,c[5]);
          update(sheet,lin)
        end
    end;




  Procedure setline(var sheet:sheettype;var lin:integer;col:integer;x:string);

    var xval:real;
        code:integer;

    begin      
      if col = 2 then setstring(sheet.data[lin],2,x)
      else
        begin
          val(x,xval,code);
          setlineasvalue(sheet,lin,col,xval)
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
      write('Cat.'+' Description       '+'  Alloc    '+'  YTD      '+'  Spent    '+'  YTD      '+'  Balance  ');
      scr := (lin - 1) div 18;
      for cnt := 1 to 18 do
        begin
          posit := 18*scr + cnt;
          if posit <= sheet.size then
            begin
              gotoxy(1,3+cnt);
              write(getstring(sheet.data[posit],1));
              gotoxy(6,3+cnt);
              write(getstring(sheet.data[posit],2));
              for cnt1 := 3 to 7 do
                begin
                  gotoxy(1+offset[cnt1],3+cnt);
                  write(getstring(sheet.data[posit],cnt1):10)
               end
            end
        end;
      highlight(0,7,1+offset[col],3+lin - 18*scr,offset[col+1] - offset[col] - 1);
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
              highlight(7,0,1+offset[col],4+lin - 18*scr,offset[col+1] - offset[col] - 1);
              highlight(0,7,1+offset[col],3+lin - 18*scr,offset[col+1] - offset[col] - 1);
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
              highlight(7,0,1+offset[col],2+lin - 18*scr,offset[col+1] - offset[col] - 1);
              highlight(0,7,1+offset[col],3+lin - 18*scr,offset[col+1] - offset[col] - 1);
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
      highlight(7,0,1+offset[col],3+lin - 18*scr,offset[col+1] - offset[col] - 1);
      col := col - 1;
      if col = 0 then col := 6;
      highlight(0,7,1+offset[col],3+lin - 18*scr,offset[col+1] - offset[col] - 1);
      inputprompt(lin,col)
    end;

  Procedure rightarrow(var sheet:sheettype;var lin,col:integer);

    var scr:integer;

    begin
      scr := (lin - 1) div 18;
      highlight(7,0,1+offset[col],3+lin - 18*scr,offset[col+1] - offset[col] - 1);
      col := col + 1;
      if col = 7 then col := 1;
      highlight(0,7,1+offset[col],3+lin - 18*scr,offset[col+1] - offset[col] - 1);
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
          temp.numinfo[4] := temp.numinfo[4] + temp.numinfo[3];
          temp.numinfo[5] := 0.0;
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
        write(g,'|'+'Cat.'+'|'+'Description');
        write(g,stringrep(7,32)+'|'+'Alloc     '+'|'+'YTD       ');
        write(g,'|'+'Spent     '+'|'+'YTD       '+'|');
        writeln(g,'Balance   '+'|');
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
      top := top + '+' + stringrep(4,ord('-'));
      mid := mid + '+' + stringrep(4,ord('-'));
      bot := bot + '+' + stringrep(4,ord('-'));
      top := top + '+' + stringrep(18,ord('-'));
      mid := mid + '+' + stringrep(18,ord('-'));
      bot := bot + '+' + stringrep(18,ord('-'));
      for cnt := 3 to 7 do
        begin
          top := top + '+' + stringrep(10,ord('-'));
          mid := mid + '+' + stringrep(10,ord('-'));
          bot := bot + '+' + stringrep(10,ord('-'))
        end;
      top := top + '+';
      mid := mid + '+';
      bot := bot + '+';
      assign(g,filename);
      rewrite(g);
      { write(g,chr(27)+'6'); }
      cnt := 1;
      posit := 1;
      escpressed := false;
      heading;
      while (cnt <= sheet.size) and (not escpressed) do
        begin
          write(g,'|');
          write(g,getstring(sheet.data[cnt],1));
          write(g,'|');
          temp := getstring(sheet.data[cnt],2);
          write(g,temp+stringrep(18 - length(temp),32));
          write(g,'|');
          for cnt1 := 3 to 7 do
            begin
              write(g,getstring(sheet.data[cnt],cnt1):10);
              write(g,'|')
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

  Procedure printCatInfo(var sheet:sheettype;catCode,catLine:integer);

    begin
      if (catCode < 9000) then
        writeln(getstring(sheet.data[catLine],2)+': Alloc: '+
          getstring(sheet.data[catLine],3)+' Spent: '+
          getstring(sheet.data[catLine],5)+' Bal: '+
          getstring(sheet.data[catLine],7))
        else if (catCode < 9900) then
          writeln(getstring(sheet.data[catLine],2)+': Alloc: '+
            getstring(sheet.data[catLine],3)+' Made: '+getstring(sheet.data[catline],5))
        else
          writeln(getstring(sheet.data[catLine],2)+': '+getstring(sheet.data[catLine],6))
    end;


  Function applyToPayment(var sheet:sheettype;paycode:integer;amount:real;before:boolean):boolean;

  var result:boolean;
      payLine:integer;
      oldAmount,newAmount,oldamount2:real;


  begin
    if (payCode <= 9900) then
      result := false
    else
      begin
        payLine := findline(sheet,paycode);
        if (payline = -1) then
          result := false
        else
          begin
            result := true;
            oldAmount := getval(sheet.data[payLine],6);
            if before then
              oldamount2 := getval(sheet.data[payLine],5);
            newAmount := oldAmount - amount;
            setlineasvalue(sheet,payLine,6,newAmount);
            if before then
              setlineasvalue(sheet,payLine,5,oldamount2)
          end
      end;
    applyToPayment := result
  end;


  Function applytocategory(var sheet:sheettype;catcode:integer;
             amount:real;before:boolean):boolean;

  var result:boolean;
      catLine:integer;
      oldAmount,newAmount:real;


  begin
    if (not transisvalidcat(catcode)) or (catcode >= 9900) then
      result := false
    else
      begin
        catLine := findline(sheet,catcode);
        if (catline = -1) then
          result := false
        else
          begin
            result := true;
            if (before) then
              oldAmount := getval(sheet.data[catLine],6)
            else
              oldAmount := getval(sheet.data[catLine],5);
            newAmount := oldAmount + amount;
            if before then
              setlineasvalue(sheet,catLine,6,newAmount)
            else
              setlineasvalue(sheet,catLine,5,newAmount)
          end
      end;
    applyTocategory := result
  end;


  Function applyTransBalanceOnly(var sheet:sheettype;catcode,paycode:integer;amount:real):boolean;

  var result,temp:boolean;

  begin
    if (catcode >= 9000) and (catcode < 9900) then
      result := applytopayment(sheet,paycode,-amount,true)
    else
      result := applytopayment(sheet,paycode,amount,true);

    if (catcode >= 9900) then
      begin
        temp := applytopayment(sheet,catcode,-amount,true);
        result := result and temp
      end;

    applytransbalanceonly := result
  end;



  Function applyTransFromBefore(var sheet:sheettype;catcode,paycode:integer;amount:real):boolean;

  var result,temp:boolean;

  begin
    result := applyTransBalanceOnly(sheet,catcode,paycode,amount);
    if (catcode < 9900) then
      begin
        temp := applytocategory(sheet,catcode,amount,true);
        result := result and temp
      end;
    applyTransFromBefore := result
  end;


  Function applyTrans(var sheet:sheettype;catcode,paycode:integer;amount:real):boolean;

  var result,temp:boolean;

  begin
    if (catcode >= 9000) and (catcode < 9900) then
      result := applytopayment(sheet,paycode,-amount,false)
    else
      result := applytopayment(sheet,paycode,amount,false);

    if (catcode < 9900) then
      begin
        temp := applytocategory(sheet,catcode,amount,false);
        result := result and temp
      end
    else
      begin
        temp := applytopayment(sheet,catcode,-amount,false);
        result := result and temp
      end;
    applyTrans := result
  end;


  Function applyWholeTrans(var sheet:sheettype;var trans:transtype;month,year:integer):boolean;

  var tyear,tmonth,tday:integer;
      i:integer;
      success:boolean;
      result:boolean;

  begin
    result := true;
    if (trans.date > 0) then
      begin
        unpackit(trans.date,tmonth,tday,tyear);
        if (year < 80) then year := year+100;
        if (tyear < 80) then tyear := tyear+100;
        for i := 0 to trans.numsplits-1 do
          begin
            if ((tmonth = month) and (tyear = year)) then
              begin
                success := applytrans(sheet,trans.splits[i].cat,trans.payment,
                   trans.splits[i].amount);
                if (not success) and (trans.splits[i].cat <> 9899) then
                   result := false
              end
            else if ((tmonth < month) and (tyear = year)) then
              success := applytransfrombefore(sheet,trans.splits[i].cat,trans.payment,
                   trans.splits[i].amount)
            else if (tyear < year) then
              success := applytransbalanceonly(sheet,trans.splits[i].cat,trans.payment,
                   trans.splits[i].amount)
          end
      end;
    applyWholeTrans := result
  end;


Function getMonthYearFromFile(filename:string;var month,year:integer):boolean;

var i:integer;
    found:boolean;
    mnames:array[0..11] of string[3];
    mpart:string[3];
    ypart:string[4];
    code:integer;

begin
  filename := caps(filename);
  mnames[0] := 'JAN';
  mnames[1] := 'FEB';
  mnames[2] := 'MAR';
  mnames[3] := 'APR';
  mnames[4] := 'MAY';
  mnames[5] := 'JUN';
  mnames[6] := 'JUL';
  mnames[7] := 'AUG';
  mnames[8] := 'SEP';
  mnames[9] := 'OCT';
  mnames[10] := 'NOV';
  mnames[11] := 'DEC';

  mpart := copy(filename,1,3);
  ypart := copy(filename,4,4);
  i := 0;
  found := false;
  while (i < 12) and (not found) do
    begin
      if (mpart = mnames[i]) then
        found := true
      else
        i := i + 1
    end;
  if (found) then
    begin
      month := i + 1;
      val(ypart,year,code);
      year := year mod 100;
      getmonthyearfromfile := true
    end
  else
    getmonthyearfromfile := false
end;


Procedure clearSpentColumns(var sheet:sheettype);

var cnt:integer;

begin
  for cnt := 1 to sheet.size do
    begin
      sheet.data[cnt]^.numinfo[5] := 0.0;
      sheet.data[cnt]^.numinfo[6] := 0.0
    end
end;




Procedure applyWholeTransFile(var sheet:sheettype;month,year:integer);

var f:file of transtype;
    trans:transtype;
    success:boolean;
    errors:boolean;

begin
  errors := false;
  clearspentcolumns(sheet);
  assign(f,g_logfile);
  reset(f);
  while not eof(f) do
    begin
      read(f,trans);
      if (not transisdeleted(trans)) then
        begin
          success := applywholetrans(sheet,trans,month,year);
          if (not success) then
            begin
              if (not errors) then 
                begin
                  clrscr;
                  writeln('The following transaction dates contain unrecognized codes: ');
                  writeln;
                  errors := true
                end;
              writeln(datestr(trans.date))
            end
        end
    end;
  close(f);
  if (errors) then
    begin
      write('Press any key.');
      pause
    end
end;
  




  Procedure loginit(var l:logptrtype);

  begin
    new(l);
    l^.size := 0
  end;

  Function logaddtrans(l:logptrtype;cat:integer;payment:integer;amount:real;
   date:integer;name:string;desc:string;checkno:string):boolean;


  var result:boolean;

  begin
    if (l^.size = LOG_MAX_SIZE) then
      result := false
    else
      begin
        result := true;
        l^.data[l^.size].date := date;
        l^.data[l^.size].reconciled := false;
        l^.data[l^.size].payment := payment;
        l^.data[l^.size].name := copy(name,1,50);
        l^.data[l^.size].desc := copy(desc,1,75);
        l^.data[l^.size].checkno := copy(checkno,1,6);
        l^.data[l^.size].numsplits := 1;
        l^.data[l^.size].splits[0].reconciled := false;
        l^.data[l^.size].splits[0].cat := cat;
        l^.data[l^.size].splits[0].amount := amount;
        l^.size := l^.size+1
      end;
    logaddtrans := result
  end;

  Function logpayment(l:logptrtype):integer;

    var result:integer;

  begin
    result := -1;
    if (l^.size > 0) then
       result := l^.data[l^.size-1].payment;
    logpayment := result
  end;


  Function logaddsplit(l:logptrtype;cat:integer;amount:real):boolean;

  var result:boolean;
      splitnum:integer;
      posit:integer;

  begin
    if (l^.size = 0) then
       result := false
    else if (cat = l^.data[l^.size-1].payment) then
       result := false
    else
      begin
        posit := transfindcat(l^.data[l^.size-1],cat);
        if (posit <> -1) then
          begin
            l^.data[l^.size-1].splits[posit].amount :=
              l^.data[l^.size-1].splits[posit].amount + amount;
            result := true
          end
        else if (l^.data[l^.size-1].numsplits = 10) then
          result := false
        else
          begin
            result := true;
            splitnum := l^.data[l^.size-1].numsplits;
            l^.data[l^.size-1].splits[splitnum].reconciled := false;
            l^.data[l^.size-1].splits[splitnum].cat := cat;
            l^.data[l^.size-1].splits[splitnum].amount := amount;
            l^.data[l^.size-1].numsplits := splitnum + 1
          end
      end;
    logaddsplit := result
  end;

  Procedure logclear(l:logptrtype);

    begin
      l^.size := 0
    end;


  Procedure logsave(l:logptrtype);

    var
      f:file of transtype;
      i:integer;

    begin
      assign(f,g_logfile);
      reset(f);
      seek(f,filesize(f));
      for i := 0 to l^.size-1 do
          write(f,l^.data[i]);
      close(f);
      logclear(l)
    end;

  Function logrollback(var sheet:sheettype;l:logptrtype):boolean;

  var result:boolean;
      i:integer;
      pmt:integer;
      cat:integer;
      amount:real;
      success:boolean;

  begin
    if (l^.size = 0) then
      result := false
    else
      begin
        result := true;
        pmt := l^.data[l^.size-1].payment;
        for i := 0 to l^.data[l^.size-1].numsplits-1 do
          begin
            cat := l^.data[l^.size-1].splits[i].cat;
            amount := l^.data[l^.size-1].splits[i].amount;
            success := applytrans(sheet,cat,pmt,-amount)
          end;
        l^.size := l^.size-1
      end;
    logrollback := result
  end;




  Procedure doshentry(var sheet:sheettype;l:logptrtype);

    var
      x,amountstr:string;
      tname:string;
      tdesc:string;
      tcheckNo:string;
      thedate:integer;
      catLine,payLine,catCode,payCode,code:integer;
      oldamount,amount,newamount:real;
      hellfreezesover:boolean;
      success:boolean;
      escpressed:boolean;
      inputvalid:boolean;

  begin
    hellfreezesover := false;
    repeat
      write('cat code: ');
      getinput(x,escpressed);
      writeln;
      x := caps(x);
      if (not escpressed) and (x = 'ROLLBACK') then
        begin
          success := logrollback(sheet,l);
          if (not success) then
            writeln('Rollback failed.')
          else
            writeln('Rollback succeeded.')
        end
      else if ((not escpressed) and (length(x) > 2) and ((x[1] = 'b') or (x[1] = 'B'))) then
        begin
          x := copy(x,3,length(x)-2);
          val(x,catCode,code);
          catLine := findline(sheet,catCode);
          if (catLine = -1) then
              writeln('Category code ',catCode,' not found.')
          else
              printcatinfo(sheet,catCode,catLine)
        end
      else if ((not escpressed) and (length(x) > 2) and ((x[1] = 'a') or (x[1] = 'A'))) then
        begin
          x := copy(x,3,length(x)-2);
          val(x,catCode,code);
          catLine := findline(sheet,catCode);
          if (catCode <= 9900) then
              writeln('Invalid category')
          else if (catLine = -1) then
              writeln('Category code ',catCode,' not found.')
          else
            begin
              write('Enter beginning balance: ');
              getinput(x,escpressed);
              writeln;
              if (not escpressed) then
                begin
                  val(x,amount,code);
                  oldAmount := getval(sheet.data[catLine],5);
                  newAmount := amount + oldAmount;
                  str(newAmount:0:2,amountStr);
                  setline(sheet,catLine,6,amountStr);
                  str(oldAmount:0:2,amountStr);
                  setline(sheet,catLine,5,amountStr);
                  printcatinfo(sheet,catCode,catLine)
                end
            end
        end
      else if (not escpressed) then
        begin
          val(x,catCode,code);
          catLine := findline(sheet,catCode);
          if (catline = -1) then
            begin
              writeln('Category code ',catCode,' not found.');
              escpressed := true
            end
          else if (catcode mod 100 = 0) or (catcode < 100) then
            begin
              writeln('Category code ',catcode,' invalid.');
              escpressed := true
            end;

          if (not escpressed) then
            begin
              gotoxy(25,wherey-1);
              write('amount: ');
              getinput(x,escpressed);
              writeln
            end;

          if (not escpressed) then
            begin
              val(x,amount,code);
              gotoxy(50,wherey-1);
              write('pay code: ');
              getinput(x,escpressed);
              writeln
            end;

          repeat
            inputvalid := true;
            if (not escpressed) then
              begin
                x := caps(x);
                if (x = 'SPLT') then
                  begin
                    success := logaddsplit(l,catcode,amount);
                    if (not success) then
                      begin
                        writeln('Adding of split failed.');
                        escpressed := true
                      end
                    else
                      begin
                        success := applytrans(sheet,catcode,logpayment(l),amount);
                        if (not success) then
                          writeln('A very serious problem happened!');
                        printcatinfo(sheet,catCode,catLine);
                        printcatinfo(sheet,payCode,payLine);
                        escpressed := true
                      end
                  end
                else
                  begin
                    val(x,payCode,code);
                    payline := findline(sheet,paycode);
                    if (payline = -1) then
                      begin
                        writeln('Payment code ',paycode,' not found.');
                        inputvalid := false
                      end
                    else if (paycode <= 9900) then
                      begin
                        writeln('Payment code ',paycode,' invalid.');
                        inputvalid := false
                      end
                  end
              end;
            if (not escpressed) and (not inputvalid) then
              begin
                write('pay code: ');
                getinput(x,escpressed);
                writeln
              end
            until inputvalid;

          if (not escpressed) then
            begin
              write('date: ');
              getinput(x,escpressed);
              writeln
            end;
          repeat
            inputvalid := true;
            if (not escpressed) then
              begin
                thedate := dateval(x);
                if (thedate < 0) then
                  begin
                    writeln('The date entered is invalid.');
                    inputvalid := false
                  end
              end;

            if (not escpressed) and (not inputvalid) then
              begin
                write('date: ');
                getinput(x,escpressed);
                writeln
              end
          until inputvalid;

          if (not escpressed) then
            begin
              gotoxy(20,wherey-1);
              write('name: ');
              getinput(x,escpressed);
              writeln
            end;

          if (not escpressed) then
            begin
              tname := x;
              write('Desc: ');
              getinput(x,escpressed);
              writeln
            end;

          if (not escpressed) then
            begin
              tdesc := x;
              write('Check No: ');
              getinput(x,escpressed);
              writeln
            end;

          if (not escpressed) then
            begin
              tcheckno := x;
              success := logaddtrans(l,catcode,paycode,amount,thedate,tname,tdesc,tcheckno);
              if (not success) then
                writeln('Transaction failed.  Save work.  Then re-add this transaction')
              else
                begin
                  success := applytrans(sheet,catcode,paycode,amount);
                  if (not success) then
                      writeln('a very serious error happened.');
                  printcatinfo(sheet,catCode,catLine);
                  printcatinfo(sheet,payCode,payLine)
                end
            end
        end
      else
        hellfreezesover := true
    until (hellfreezesover)
  end;








  begin
    g_logfile := getenv(LOG_FILE_ENV);
    if g_logfile = '' then g_logfile := LOG_FILE_NAME;
    if (not fileexists(g_logfile)) then
      begin
        writeln('The transaction log file ',g_logfile,' does not exist.');
        writeln('Set environment variable ',LOG_FILE_ENV);
        halt(0)
      end;
    gensetup;
    g_filename := '';
    offset[1] := 0;
    offset[2] := 5;
    offset[3] := 24;
    offset[4] := 35;
    offset[5] := 46;
    offset[6] := 57;
    offset[7] := 68;
    offset[8] := 79;
    name[1] := 'Cat.';
    name[2] := 'Description';
    name[3] := 'Alloc';
    name[4] := 'YTD';
    name[5] := 'Spent';
    name[6] := 'YTD';
    name[7] := 'Balance';
    initialize(sheet);
    { loginit(logptr); }
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
                                       else
                                         begin
                                           savesheet(sheet,filename);
                                           { logsave(logptr); }
                                           g_filename := filename
                                         end
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
                                   if (getMonthYearFromFile(filename,thmn,thyr)) then
                                     begin
                                       gotoxy(1,1);
                                       write('':79);
                                       gotoxy(1,1);
                                       write('Update from transaction log<y,n>? ');
                                       readln(response);
                                       if (response in ['Y','y']) then
                                         begin
                                           applywholetransfile(sheet,thmn,thyr);
                                           clrscr
                                         end
                                     end;
                                   { logclear(logptr); }
                                   g_filename := filename;
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
                   chr(63):begin
                             {
                                 clrscr;
                                 gotoxy(1,1);
                                 doshentry(sheet,logptr);
                                 displayscreen(sheet,lin,col);
                                 inputprompt(lin,col)
                             }
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
                                 g_filename := '';
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