program addcust;

  uses crt,dos,IOunit;

  const
    OUTPUTFILE = 'lpt1';
    SEQFILE = 'CURREG.ID';
    CUSTRECFILE = 'CUSTOMER';
    SALEFILE = 'PRSALES';
    LETTERFILE = 'REGLETT.TXT';
    SALERECSIZE = 16;
    CUSTRECSIZE = 169;
    MAXSIZE = 100;
    SIZEFIRST = 15;
    SIZELAST = 20;
    SIZEADR1 = 30;
    SIZEADR2 = 30;
    SIZECITY = 15;
    SIZESTATE = 5;
    SIZEZIP = 10;
    SIZEPHONE = 15;


  type
    salerectype=record
      marked:boolean;
      monthnum:string[8];
      itemssold:string[5];
    end;

    custrectype=record
      marked:boolean;
      last:string[SIZELAST];
      first:string[SIZEFIRST];
      adr1:string[SIZEADR1];
      adr2:string[SIZEADR2];
      city:string[SIZECITY];
      state:string[SIZESTATE];
      zip:string[SIZEZIP];
      phone:string[SIZEPHONE];
      date:string[8];
      custid:string[10]
    end;

    arraytype = array[1..MAXSIZE] of custrectype;

  var regseq:longint;
      cnt,choice,custidlen,numout:integer;
      dummy,regseqstr,lastname,firstname,adr1,adr2,city,state,zipcode,phonenum:string;
      escpressed,done,canceled:boolean;
      data:arraytype;
      year,month,day,dayofweek:word;
      response:char;

  Function datestr(year,month,day:integer):string;

    var yearstr,monthstr,daystr:string[2];

    begin
      year := year mod 100;
      str(year,yearstr);
      str(month,monthstr);
      str(day,daystr);
      if length(yearstr) < 2 then yearstr := '0'+yearstr;
      if length(monthstr) < 2 then monthstr := '0'+monthstr;
      if length(daystr) < 2 then daystr := '0'+daystr;
      datestr := monthstr+'/'+daystr+'/'+yearstr
    end;

  Function datestr1(x:integer):string;

    var yearstr,monthstr:string[2];
        month,year:integer;

    begin
      month := (x mod 12) + 1;
      year := x div 12;
      if year < 20 then year := year + 80
      else year := year - 20;
      str(year,yearstr);
      str(month,monthstr);
      if length(yearstr) < 2 then yearstr := '0'+yearstr;
      if length(monthstr) < 2 then monthstr := '0'+monthstr;
      datestr1 := monthstr+'/01/'+yearstr
    end;

  Function dateval(date:string):integer;

    var month,day,year,code:integer;

    begin
      val(copy(date,1,2),month,code);
      val(copy(date,4,2),day,code);
      val(copy(date,7,2),year,code);
      if year >= 80 then year := year - 80
      else year := year + 20;
      dateval := year*12 + month - 1
    end;

  Procedure clearline;

    begin
      write('':79);
      gotoxy(1,wherey)
    end;

  Procedure seeifcancel(var contin:boolean);

    var response:char;

    begin
      gotoxy(60,wherey);
      write('Cancel? ');
      readln(response);
      contin := not (response in ['Y','y']);
      gotoxy(60,wherey);
      write('':19)
    end;

  Procedure Getrecord(var lastname:string;var firstname:string;var adr1:string;
                      var adr2:string;var city:string;var state:string;
                      var zipcode:string;var phonenum:string;var contin:boolean);

  var escpressed:boolean;
      response:char;

  begin
   contin := true;
   repeat
    clrscr;
    if contin then repeat
      repeat
        gotoxy(1,1);
        clearline;
        write('Last name: ');
        getinput(lastname,escpressed);
        if escpressed then seeifcancel(contin)
      until (not escpressed) or (not contin);
      if contin then
        begin
          gotoxy(60,1);
          write('Correct? ');
          readln(response)
        end
    until (not contin) or (response in ['Y','y']);
    if contin then repeat
      repeat
        gotoxy(1,2);
        clearline;
        write('First name: ');
        getinput(firstname,escpressed);
        if escpressed then seeifcancel(contin)
      until (not escpressed) or (not contin);
      if contin then
        begin
          gotoxy(60,2);
          write('Correct? ');
          readln(response)
        end
    until (not contin) or (response in ['Y','y']);
    if contin then repeat
      repeat
        gotoxy(1,3);
        clearline;
        write('Address (1st line): ');
        getinput(adr1,escpressed);
        if escpressed then seeifcancel(contin)
      until (not escpressed) or (not contin);
      if contin then
        begin
          gotoxy(60,3);
          write('Correct? ');
          readln(response)
        end
    until (not contin) or (response in ['Y','y']);
    if contin then repeat
      repeat
        gotoxy(1,4);
        clearline;
        write('Address (2nd line): ');
        getinput(adr2,escpressed);
        if escpressed then seeifcancel(contin)
      until (not escpressed) or (not contin);
      if contin then
        begin
          gotoxy(60,4);
          write('Correct? ');
          readln(response)
        end
    until (not contin) or (response in ['Y','y']);
    if contin then repeat
      repeat
        gotoxy(1,5);
        clearline;
        write('City: ');
        getinput(city,escpressed);
        if escpressed then seeifcancel(contin)
      until (not escpressed) or (not contin);
      if contin then
        begin
          gotoxy(60,5);
          write('Correct? ');
          readln(response)
        end
    until (not contin) or (response in ['Y','y']);
    if contin then repeat
      repeat
        gotoxy(1,6);
        clearline;
        write('State: ');
        getinput(state,escpressed);
        if escpressed then seeifcancel(contin)
      until (not escpressed) or (not contin);
      if contin then
        begin
          gotoxy(60,6);
          write('Correct? ');
          readln(response)
        end
    until (not contin) or (response in ['Y','y']);
    if contin then repeat
      repeat
        gotoxy(1,7);
        clearline;
        write('Zip code: ');
        getinput(zipcode,escpressed);
        if escpressed then seeifcancel(contin)
      until (not escpressed) or (not contin);
      if contin then
        begin
          gotoxy(60,7);
          write('Correct? ');
          readln(response)
        end
    until (not contin) or (response in ['Y','y']);
    if contin then repeat
      repeat
        gotoxy(1,8);
        clearline;
        write('Phone #: ');
        getinput(phonenum,escpressed);
        if escpressed then seeifcancel(contin)
      until (not escpressed) or (not contin);
      if contin then
        begin
          gotoxy(60,8);
          write('Correct? ');
          readln(response)
        end
    until (not contin) or (response in ['Y','y']);
    if contin then
      begin
        gotoxy(1,10);
        write('Is all above information correct? ');
        readln(response)
      end
   until (not contin) or (response in ['Y','y']);
   contin := not contin
  end;

  Procedure getseq(var regseq:longint);

    var f:file;
        numread:word;

    begin
      assign(f,SEQFILE);
      reset(f,1);
      blockread(f,regseq,4,numread);
      close(f)
    end;

  Function curdatevalid:boolean;

    var f:file;
        numread:word;
        salerec:salerectype;
        year,month,day,dayofweek:word;

    begin
      assign(f,SALEFILE);
      reset(f,1);
      if filesize(f) = 0 then
        begin
          curdatevalid := true;
          close(f)
        end
      else
        begin
          seek(f,filesize(f)-SALERECSIZE);
          blockread(f,salerec,SALERECSIZE,numread);
          close(f);
          getdate(year,month,day,dayofweek);
          curdatevalid := (dateval(datestr(year,month,day)) >= dateval(salerec.monthnum))
        end
    end;


  Procedure updatecustfile(var custrec:custrectype);

    var f:file;
        numwritten:word;

    begin
      assign(f,CUSTRECFILE);
      reset(f,1);
      seek(f,filesize(f));
      blockwrite(f,custrec,CUSTRECSIZE,numwritten);
      close(f)
    end;

  Procedure updateseq(var custrec:custrectype);

    var f:file;
        temp:longint;
        numwritten:word;
        code:integer;

    begin
      assign(f,SEQFILE);
      reset(f,1);
      val(copy(custrec.custid,1,5),temp,code);
      blockwrite(f,temp,4,numwritten);
      close(f)
    end;

  Procedure updatesales(var custrec:custrectype);

    var f:file;
        salerec:salerectype;
        numwritten,numread:word;
        temp,code:integer;

    begin
      assign(f,SALEFILE);
      reset(f,1);
      if filesize(f) = 0 then
        begin
          salerec.marked := false;
          salerec.monthnum := datestr1(dateval(custrec.date));
          salerec.itemssold := '1';
          blockwrite(f,salerec,SALERECSIZE,numwritten)
        end
      else
        begin
          seek(f,filesize(f)-SALERECSIZE);
          blockread(f,salerec,SALERECSIZE,numread);
          if dateval(custrec.date) = dateval(salerec.monthnum) then
            begin
              val(salerec.itemssold,temp,code);
              temp := temp + 1;
              str(temp,salerec.itemssold);
              seek(f,filesize(f)-SALERECSIZE);
              blockwrite(f,salerec,SALERECSIZE,numwritten)
            end
          else
            begin
              salerec.marked := false;
              salerec.monthnum := datestr1(dateval(custrec.date));
              salerec.itemssold := '1';
              blockwrite(f,salerec,SALERECSIZE,numwritten)
            end
        end;
      close(f)
    end;

  Procedure printletter(var f:text);

    var g:text;
        curline:string;

    begin
      assign(g,LETTERFILE);
      reset(g);
      while not eof(g) do
        begin
          readln(g,curline);
          writeln(f,curline)
        end;
      close(g)
    end;

  Procedure printcustomer(var custrec:custrectype);

    var f:text;
        cnt:integer;

    begin
      assign(f,OUTPUTFILE);
      rewrite(f);
      for cnt := 1 to 5 do
        writeln(f);
      if custrec.first = '' then writeln(f,custrec.last)
      else writeln(f,custrec.first+' '+custrec.last);
      writeln(f,custrec.adr1);
      if custrec.adr2 <> '' then writeln(f,custrec.adr2);
      writeln(f,custrec.city+', '+custrec.state+'  '+custrec.zip);
      writeln(f);
      if custrec.first <> '' then writeln(f,'Dear '+custrec.first+':')
      else writeln(f,'Dear '+custrec.last+':');
      writeln(f);
      printletter(f);
      writeln(f);
      writeln(f,'REGISTRATION NUMBER: '+custrec.custid);
      write(f,chr(12));
      close(f)
    end;


  Procedure menu(var c:integer;numout:integer);

    var response:string;
        code:integer;

    begin
      clrscr;
      gotoxy(1,5);
      write('R E G I S T R A T I O N   M E N U':56);
      gotoxy(10,8);
      write('1.  Add a customer');
      gotoxy(10,10);
      write('2.  Print registration letters');
      gotoxy(10,12);
      write('3.  Quit');
      gotoxy(1,18);
      write(numout,' Letters are waiting to be printed.');
      gotoxy(1,15);
      write('Pick one: ');
      readln(response);
      val(response,c,code)
    end;


  begin
    if not curdatevalid then
      begin
        writeln(chr(7)+'Current date is set before last sale recorded.');
        exit
      end;
    getseq(regseq);
    numout := 0;
    done := false;
    repeat
      menu(choice,numout);
      case choice of
        1:if numout < MAXSIZE then begin
            getrecord(lastname,firstname,adr1,adr2,city,state,zipcode,phonenum,canceled);
            if not canceled then
              begin
                numout := numout + 1;
                data[numout].marked := false;
                data[numout].last := copy(lastname,1,SIZELAST);
                data[numout].first := copy(firstname,1,SIZEFIRST);
                data[numout].adr1 := copy(adr1,1,SIZEADR1);
                data[numout].adr2 := copy(adr2,1,SIZEADR2);
                data[numout].city := copy(city,1,SIZECITY);
                data[numout].state := copy(state,1,SIZESTATE);
                data[numout].zip := copy(zipcode,1,SIZEZIP);
                data[numout].phone := copy(phonenum,1,SIZEPHONE);
                getdate(year,month,day,dayofweek);
                data[numout].date := datestr(year,month,day);
                regseq := (regseq + 1) mod 100000;
                str(regseq,regseqstr);
                data[numout].custid := regseqstr+'62984';
                custidlen := length(data[numout].custid);
                for cnt := custidlen + 1 to 10 do
                  data[numout].custid := '0'+data[numout].custid;
              end
          end;
        2:begin
            clrscr;
            gotoxy(1,12);
            write('Check printer and press ENTER to continue or ESC for main menu: ');
            getinput(dummy,escpressed);
            if not escpressed then
              begin
                cnt := 0;
                while (cnt < numout) do
                  begin
                    cnt := cnt + 1;
                    printcustomer(data[cnt]);
                    updatecustfile(data[cnt]);
                    updateseq(data[cnt]);
                    updatesales(data[cnt])
                  end;
                numout := 0
              end
          end;
        3:begin
            if numout <> 0 then
              begin
                gotoxy(1,20);
                write('There are letters waiting to be printed.  Quit anyway? ');
                readln(response);
                done := response in ['Y','y']
              end
            else done := true
          end
      end {case}
    until done;
  end.
