Program mselect;

  uses crt;

  type

    stringtype = string[80];

    arraytype = array[0..36] of stringtype;

    vidarraytype = array[0..3999] of byte;

   ptrtype = ^vidarraytype;

    configtype = record
      titlefor:integer;
      titlebk:integer;
      menufor:integer;
      highlightfor:integer;
      highlightbk:integer;
      messagefor:integer
    end;

    drivertype = record
      size:integer;
      scr:integer;
      posit:integer;
      drfile:stringtype;
      config:configtype;
      caption:arraytype
    end;

  var config:configtype;
      driver:drivertype;
      hellfreezesover:boolean;
      choice,schoice:char;
      excode:integer;


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

  Procedure highlight(var driver:drivertype;x,y,l:integer);

   var p:ptrtype;
       attr,posit,cnt:integer;

   begin
     p := ptr($B800,$0);
     attr := 16*driver.config.highlightbk + driver.config.highlightfor;
     posit := (y - 1)*160 + (x - 1)*2 + 1;
     for cnt := 1 to l do
       begin
         p^[posit] := attr;
         posit := posit + 2
       end
   end;

  Procedure unhighlight(var driver:drivertype;x,y,l:integer);

   var p:ptrtype;
       attr,posit,cnt:integer;

   begin
     p := ptr($B800,$0);
     attr := driver.config.menufor;
     posit := (y - 1)*160 + (x - 1)*2 + 1;
     for cnt := 1 to l do
       begin
         p^[posit] := attr;
         posit := posit + 2
       end
   end;

  Procedure getconfig(var config:configtype);

    var f:file;
        numread:word;

    begin
      assign(f,'mselect.xxx');
      reset(f,1);
      blockread(f,config,sizeof(config),numread);
      close(f)
    end;

  Procedure getmenu(filename:string;var c:configtype;var driver:drivertype);

    var g:text;
        cnt:integer;

    begin
      assign(g,filename);
      reset(g);
      cnt := 0;
      while not eof(g) do
        begin
          if cnt > 36 then halt(0);
          readln(g,driver.caption[cnt]);
          cnt := cnt + 1
        end;
      close(g);
      driver.size := cnt - 1;
      driver.scr := 0;
      driver.posit := 1;
      driver.drfile := filename;
      driver.config := c
    end;

  Procedure showmenu(var driver:drivertype;working:boolean);

    var cnt,count:integer;

    begin
      clrscr;
      textcolor(driver.config.titlefor);
      textbackground(driver.config.titlebk);
      write('':(80-length(driver.caption[0])) div 2);
      write(driver.caption[0]);
      write('':(81-length(driver.caption[0])) div 2);
      textcolor(driver.config.menufor);
      textbackground(0);
      cnt := 0;
      for count := 9*driver.scr + 1 to min(driver.size,9*driver.scr + 9) do
        begin
          cnt := cnt + 1;
          gotoxy(10,cnt + 2);
          case driver.scr of
            0:write('F');
            1:write('Shift-F');
            2:write('Ctrl-F');
            3:write('Alt-F')
          end;
        write(cnt,'.  ');
        write(driver.caption[count])
      end;
    gotoxy(10,cnt + 3);
    if caps(driver.drfile) = 'MAIN.DRV' then write('F10.  Exit to DOS')
    else write('F10.  Exit menu');
    highlight(driver,10,driver.posit + 2,71);
    gotoxy(1,14);
    if not working then
      begin
        textcolor(driver.config.messagefor);
        write('Make Your Selection: ')
      end
    else
      begin
        textcolor(driver.config.messagefor + 128);
        write('Working !!!')
      end
  end;

  Procedure arrowup(var driver:drivertype);

  begin
    if 9*driver.scr + driver.posit > 1 then
      begin
        if driver.posit = 1 then
          begin
            driver.scr := driver.scr - 1;
            driver.posit := 10;
            showmenu(driver,false)
          end
        else
          begin
            unhighlight(driver,10,driver.posit + 2,71);
            driver.posit := driver.posit - 1;
            highlight(driver,10,driver.posit + 2,71)
          end
      end
  end;

  Procedure arrowdown(var driver:drivertype);

  begin
    if 9*driver.scr + driver.posit <= driver.size then
      begin
        if driver.posit = 10 then
          begin
            driver.scr := driver.scr + 1;
            driver.posit := 1;
            showmenu(driver,false)
          end
        else
          begin
            unhighlight(driver,10,driver.posit + 2,71);
            driver.posit := driver.posit + 1;
            highlight(driver,10,driver.posit + 2,71)
          end
      end
  end;

  Procedure pgup(var driver:drivertype);

  begin
    if driver.scr > 0 then
      begin
        driver.scr := driver.scr - 1;
        showmenu(driver,false)
      end
    else
      begin
        unhighlight(driver,10,driver.posit + 2,71);
        driver.posit := 1;
        highlight(driver,10,driver.posit + 2,71)
      end
  end;

  Procedure pgdn(var driver:drivertype);

  begin
    if driver.scr*9 + 10 <= driver.size then
      begin
        driver.scr := driver.scr + 1;
        driver.posit := min(driver.posit,driver.size + 1 - 9*driver.scr);
        showmenu(driver,false)
      end
    else
      begin
        unhighlight(driver,10,driver.posit + 2,71);
        driver.posit := driver.size + 1 - 9*driver.scr;
        highlight(driver,10,driver.posit + 2,71)
      end
  end;


  begin
    getconfig(config);
    getmenu(paramstr(1),config,driver);
    showmenu(driver,false);
    hellfreezesover := false;
    repeat
      choice := readkey;
      if choice = chr(13) then
        begin
          showmenu(driver,true);
          gotoxy(1,16);
          if driver.scr*9 + driver.posit = driver.size + 1 then halt(0)
          else if driver.posit = 10 then halt(0)
          else halt(driver.scr*9 + driver.posit)
        end
      else if choice = chr(0) then
        begin
          schoice := readkey;
          if schoice = chr(72) then arrowup(driver)
          else if schoice = chr(80) then arrowdown(driver)
          else if schoice = chr(73) then pgup(driver)
          else if schoice = chr(81) then pgdn(driver)
          else if schoice = chr(68) then
            begin
              driver.scr := 0;
              driver.posit := min(10,driver.size + 1);
              showmenu(driver,true);
              gotoxy(1,16);
              halt(0)
            end
          else if (ord(schoice) > 58) and (ord(schoice) < 68) then
            begin
              excode := ord(schoice) - 58;
              if excode <= driver.size then
                begin
                  driver.scr := 0;
                  driver.posit := excode;
                  showmenu(driver,true);
                  gotoxy(1,16);
                  halt(excode)
                end
            end
          else if (ord(schoice) > 83) and (ord(schoice) < 113) then
            begin
              if ord(schoice) mod 10 <> 3 then
                begin
                  excode := ord(schoice) - 74 - ((ord(schoice) - 83) div 10);
                  if excode <= driver.size then
                    begin
                      driver.scr := (excode - 1) div 9;
                      driver.posit := excode - 9*driver.scr;
                      showmenu(driver,true);
                      gotoxy(1,16);
                      halt(excode)
                    end
                end
            end
        end
    until hellfreezesover
  end.