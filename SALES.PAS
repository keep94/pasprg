program sales;

  uses crt,dates,IOunit;

  const
    maxlencompcode = 10;
    maxpluconst = 2000;
    maxdeptconst = 2100;

  type
    compcodetype = array[0..maxlencompcode-1] of byte;

    linetype = record
      price:real;
      taxable:boolean;
      col:array[1..3] of integer
    end;

    rectype = record
      marked:boolean;
      date:integer;
      taxrate:real;
      totals:array[1..5] of real;
      data:array[1..MAXPLUCONST] of linetype
    end;

    recptrtype = ^rectype;

    filearraytype = array[1..16000] of recptrtype;

    fileptrtype = ^filearraytype;

    itemtype=record
      name:string[20];
      price:real;
      taxable:boolean;
      cat:integer
    end;

    invtype = array[1..MAXPLUCONST] of itemtype;

    reporttype = array[1..MAXDEPTCONST,1..5] of real;

    invptrtype = ^invtype;

    reportptrtype = ^reporttype;

    tandrtype=record
      maxrec:integer;
      nrec:integer;
      ncat:integer;
      nfield:integer;
      key1:integer;
      key2:integer;
      inv:invptrtype;
      taxrate:real;
      p:fileptrtype
    end;

  var
    g:text;
    tandr:tandrtype;
    outfile,filename,printdev,temp,des:string;
    choice,schoice,response:char;
    mstat,markedonly,done,escpressed,found:boolean;
    dayofweek,error,startrec,endrec,cnt,sortkey,colkey,recno,fieldno,colno,ascend,code:integer;
    oldsum,oldtaxcoup,oldnontaxcoup,taxcoup,nontaxcoup,taxdiff,nontaxdiff,searchkey:real;
    compcode:compcodetype;
    reportptr:reportptrtype;
    compfile:file;
    numread:word;


  Function reclen(fieldamt:word):word;

    begin
      reclen := 13*fieldamt + 39
    end;

  Function getval(var tandr:tandrtype;recno,fieldno,colno:integer):real;

    var cnt,sum:integer;

    begin
      if fieldno <= 0 then
        getval := tandr.p^[recno]^.date
      else if fieldno <= tandr.nfield then
        begin
          if (colno <= 0) then getval := tandr.p^[recno]^.data[fieldno].price
          else if (colno > 0) and (colno <= 3) then getval := tandr.p^[recno]^.data[fieldno].col[colno]
          else if (colno = 4) then
            begin
              sum := 0;
              for cnt := 1 to 3 do
                sum := sum + tandr.p^[recno]^.data[fieldno].col[cnt];
              getval := sum
            end
          else if (colno = 5) then
            getval := tandr.p^[recno]^.data[fieldno].col[1]*tandr.p^[recno]^.data[fieldno].price
          else if (colno = 6) then
            begin
              if tandr.p^[recno]^.data[fieldno].taxable then
                with tandr.p^[recno]^ do
                  getval := data[fieldno].col[1]*data[fieldno].price*taxrate
              else getval := 0.0
            end
          else
            begin
              if tandr.p^[recno]^.data[fieldno].taxable then
                with tandr.p^[recno]^ do
                  getval := data[fieldno].col[1]*data[fieldno].price*(1 + taxrate)
              else getval := tandr.p^[recno]^.data[fieldno].col[1]*tandr.p^[recno]^.data[fieldno].price
            end
        end
      else if (colno > 0) and (colno <= 5) then
        getval := tandr.p^[recno]^.totals[colno]
      else getval := tandr.p^[recno]^.totals[1]
    end;

  Procedure setval(var tandr:tandrtype;recno,fieldno,colno:integer;x:real);

    begin
      if fieldno <= 0 then
        tandr.p^[recno]^.date := trunc(x)
      else if fieldno <= tandr.nfield then
        begin
          if (colno <= 0) then tandr.p^[recno]^.data[fieldno].price := x
          else if (colno > 0) and (colno <= 3) then
            tandr.p^[recno]^.data[fieldno].col[colno] := trunc(x)
        end
      else if (colno > 0) and (colno <= 5) then
        tandr.p^[recno]^.totals[colno] := x
    end;

  Function coupprofit(var tandr:tandrtype;recno:integer):real;

    begin
      coupprofit := getval(tandr,recno,tandr.nfield+1,4)+getval(tandr,recno,tandr.nfield+1,5)
    end;

  Function couptax(var tandr:tandrtype;recno:integer):real;

    begin
      couptax := getval(tandr,recno,tandr.nfield+1,4)*tandr.p^[recno]^.taxrate
    end;

  Function couptotal(var tandr:tandrtype;recno:integer):real;

    begin
      couptotal := coupprofit(tandr,recno)+couptax(tandr,recno)
    end;


  Function ismarked(var tandr:tandrtype;recno:integer):boolean;

    begin
      ismarked := tandr.p^[recno]^.marked
    end;

  Procedure markit(var tandr:tandrtype;recno:integer;stat:boolean;dayofweek:integer);

    var correctday:boolean;

    begin
      if dayofweek >= 7 then correctday := true
      else correctday := (trunc(getval(tandr,recno,0,0)) mod 7 = dayofweek);
      if correctday then
        tandr.p^[recno]^.marked := stat
    end;

  Procedure initfields(var tandr:tandrtype;var reportptr:reportptrtype;filename:string);

    var f:text;
        x:real;
        y,z,cnt:integer;

    begin
      assign(f,filename);
      reset(f);
      readln(f,tandr.taxrate);
      readln(f,tandr.nfield);
      readln(f,tandr.ncat);
      if (tandr.nfield < 1) then
        begin
          writeln;
          write(chr(7)+'No PLU''s defined');
          halt
        end;
      if (tandr.ncat < 0) then
        tandr.ncat := 0;
      if (tandr.nfield > MAXPLUCONST) or (tandr.nfield + tandr.ncat + 2 > MAXDEPTCONST) then
        begin
          writeln;
          write(chr(7)+'Too many PLU''s and departments defined.');
          halt
        end;
      getmem(tandr.inv,30*tandr.nfield);
      for cnt := 1 to tandr.nfield do
        begin
          readln(f,tandr.inv^[cnt].name);
          readln(f,x,y,z);
          tandr.inv^[cnt].price := x;
          tandr.inv^[cnt].taxable := (y <> 0);
          tandr.inv^[cnt].cat := z
        end;
      close(f);
      getmem(tandr.p,tandr.maxrec*4);
      for cnt := 1 to tandr.maxrec do
        getmem(tandr.p^[cnt],reclen(tandr.nfield));
      tandr.key1 := -1;
      getmem(reportptr,30*(tandr.nfield + tandr.ncat + 2))
    end;

  Procedure shutdown(var tandr:tandrtype;reportptr:reportptrtype);

    var cnt:integer;

    begin
      for cnt := 1 to tandr.maxrec do
        freemem(tandr.p^[cnt],reclen(tandr.nfield));
      freemem(tandr.p,tandr.maxrec*4);
      freemem(reportptr,30*(tandr.nfield + tandr.ncat + 2));
      freemem(tandr.inv,30*tandr.nfield)
    end;

  Procedure displayrecord(var tandr:tandrtype;recno,fieldno,colno:integer);

    var cnt,cnt1:integer;
        weekdays:weekdaytype;

    begin
      initweekdays(weekdays);
      clrscr;
      write('Date: '+weekdays[trunc(getval(tandr,recno,0,0)) mod 7]+'  '+datestr(trunc(getval(tandr,recno,0,0))));
      if ismarked(tandr,recno) then
        begin
          gotoxy(25,1);
          write('Marked')
        end;
      gotoxy(50,1);
      write('Record ',recno,' out of ',tandr.nrec);
      writeln;
      writeln;
      writeln('PLU# '+'Item                 '+'Sale '+'Ex.  '+'Coup '+'Total '+'Profit     '+'Tax        '+'Amt. Col  ');
      writeln('---- '+'-------------------- '+'---- '+'---- '+'---- '+'----- '+'---------- '+'---------- '+'----------');
      for cnt := 15*((fieldno-1) div 15) + 1 to 15*((fieldno-1) div 15) + 15 do
        begin
          if cnt <= tandr.nfield then
            begin
              write(cnt:4);
              write(' ');
              write(tandr.inv^[cnt].name);
              for cnt1 := 1 to 20 - length(tandr.inv^[cnt].name) do write(' ');
              for cnt1 := 1 to 3 do write(getval(tandr,recno,cnt,cnt1):5:0);
              write(getval(tandr,recno,cnt,4):6:0);
              for cnt1 := 5 to 7 do write(getval(tandr,recno,cnt,cnt1):11:2)
            end;
          writeln
        end;
      writeln;
      writeln('Profit:   ',getval(tandr,recno,tandr.nfield+1,1):0:2);
      writeln('Tax:      ',getval(tandr,recno,tandr.nfield+1,2):0:2);
      writeln('Amt. Col: ',getval(tandr,recno,tandr.nfield+1,3):0:2);
      gotoxy(40,21);
      write('Taxable Coupons:     ',getval(tandr,recno,tandr.nfield+1,4):0:2);
      gotoxy(40,22);
      write('Non Taxable Coupons: ',getval(tandr,recno,tandr.nfield+1,5):0:2);
      gotoxy(25+5*colno,5+(fieldno-1) mod 15)
    end;


  Procedure printshort(var g:text;var tandr:tandrtype;markedonly:boolean;var compcode:compcodetype);

    var cnt,count,printseq:integer;
        done:boolean;
        userreq:char;
        weekdays:weekdaytype;

    begin
      for cnt := 1 to compcode[0] do write(g,chr(compcode[cnt]));
      initweekdays(weekdays);
      write(g,'No.');
      for cnt := 1 to 2 do write(g,' ');
      write(g,'Date');
      for cnt := 1 to 10 do write(g,' ');
      write(g,'Profit     ');
      write(g,'Tax        ');
      write(g,'Total      ');
      write(g,'Coupons    ');
      write(g,'Coup. Tax  ');
      write(g,'Coup. Totl ');
      write(g,'Net Profit ');
      write(g,'Net Tax    ');
      writeln(g,'Net Total');
      for cnt := 1 to 4 do write(g,'-');
      write(g,' ');
      for cnt := 1 to 13 do write(g,'-');
      for count := 1 to 9 do
        begin
          write(g,' ');
          for cnt := 1 to 10 do write(g,'-')
        end;
      writeln(g);
      printseq := 0;
      count := 0;
      done := false;
      while (count < tandr.nrec) and (not done) do
        begin
          count := count + 1;
          if (ismarked(tandr,count)) or (not markedonly) then
            begin
              printseq := printseq + 1;
              write(g,printseq:4);
              write(g,' ');
              write(g,weekdays[trunc(getval(tandr,count,0,0)) mod 7]+'  '+datestr(trunc(getval(tandr,count,0,0))));
              write(g,getval(tandr,count,tandr.nfield+1,1)+coupprofit(tandr,count):11:2);
              write(g,getval(tandr,count,tandr.nfield+1,2)+couptax(tandr,count):11:2);
              write(g,getval(tandr,count,tandr.nfield+1,3)+couptotal(tandr,count):11:2);
              write(g,coupprofit(tandr,count):11:2);
              write(g,couptax(tandr,count):11:2);
              write(g,couptotal(tandr,count):11:2);
              write(g,getval(tandr,count,tandr.nfield+1,1):11:2);
              write(g,getval(tandr,count,tandr.nfield+1,2):11:2);
              writeln(g,getval(tandr,count,tandr.nfield+1,3):11:2);
              if keypressed then
                begin
                  userreq := readkey;
                  if userreq = chr(27) then done := true
                  else if userreq = chr(0) then userreq := readkey
                end
            end
        end;
      for cnt := compcode[0]+2 to compcode[0]+compcode[compcode[0]+1]+1 do
        write(g,chr(compcode[cnt]))
    end;


  Procedure prevrec(var tandr:tandrtype;var recno,fieldno,colno:integer);

    begin
      fieldno := 1;
      colno := 1;
      if recno > 1 then recno := recno - 1
      else recno := tandr.nrec
    end;

  Procedure nextrec(var tandr:tandrtype;var recno,fieldno,colno:integer);

    begin
      fieldno := 1;
      colno := 1;
      if recno < tandr.nrec then recno := recno + 1
      else recno := 1
    end;

  Procedure prevfield(var tandr:tandrtype;var fieldno:integer);

    begin
      if fieldno > 1 then fieldno := fieldno - 1
      else fieldno := tandr.nfield
    end;

  Procedure nextfield(var tandr:tandrtype;var fieldno:integer);

    begin
      if fieldno < tandr.nfield then fieldno := fieldno + 1
      else fieldno := 1
    end;

  Procedure prevcol(var colno:integer);

    begin
      if colno > 1 then colno := colno - 1
      else colno := 3
    end;

  Procedure nextcol(var colno:integer);

    begin
      if colno < 3 then colno := colno + 1
      else colno := 1
    end;

  Procedure add_digit(var tandr:tandrtype;recno,fieldno,colno:integer;x:char);

    var newcval,cval:integer;
        oldprofit,oldtax,oldtot,diffprof,difftax,difftot,oldsum:real;

    begin
      cval := trunc(getval(tandr,recno,fieldno,colno));
      newcval := 10*(cval mod 1000) - 48 + ord(x);
      oldprofit := getval(tandr,recno,fieldno,5);
      oldtax := getval(tandr,recno,fieldno,6);
      oldtot := getval(tandr,recno,fieldno,7);
      setval(tandr,recno,fieldno,colno,newcval);
      diffprof := getval(tandr,recno,fieldno,5) - oldprofit;
      difftax := getval(tandr,recno,fieldno,6) - oldtax;
      difftot := getval(tandr,recno,fieldno,7) - oldtot;
      oldsum := getval(tandr,recno,tandr.nfield+1,1);
      setval(tandr,recno,tandr.nfield+1,1,oldsum + diffprof);
      oldsum := getval(tandr,recno,tandr.nfield+1,2);
      setval(tandr,recno,tandr.nfield+1,2,oldsum + difftax);
      oldsum := getval(tandr,recno,tandr.nfield+1,3);
      setval(tandr,recno,tandr.nfield+1,3,oldsum + difftot)
    end;

  Procedure del_digit(var tandr:tandrtype;recno,fieldno,colno:integer);

    var newcval,cval:integer;
        oldprofit,oldtax,oldtot,diffprof,difftax,difftot,oldsum:real;

    begin
      cval := trunc(getval(tandr,recno,fieldno,colno));
      newcval := cval div 10;
      oldprofit := getval(tandr,recno,fieldno,5);
      oldtax := getval(tandr,recno,fieldno,6);
      oldtot := getval(tandr,recno,fieldno,7);
      setval(tandr,recno,fieldno,colno,newcval);
      diffprof := getval(tandr,recno,fieldno,5) - oldprofit;
      difftax := getval(tandr,recno,fieldno,6) - oldtax;
      difftot := getval(tandr,recno,fieldno,7) - oldtot;
      oldsum := getval(tandr,recno,tandr.nfield+1,1);
      setval(tandr,recno,tandr.nfield+1,1,oldsum + diffprof);
      oldsum := getval(tandr,recno,tandr.nfield+1,2);
      setval(tandr,recno,tandr.nfield+1,2,oldsum + difftax);
      oldsum := getval(tandr,recno,tandr.nfield+1,3);
      setval(tandr,recno,tandr.nfield+1,3,oldsum + difftot)
    end;


  Procedure append(var tandr:tandrtype;var recno,fieldno,colno:integer);

    var cnt,cnt1:integer;

    begin
      if (tandr.nrec < tandr.maxrec) then
        begin
          recno := tandr.nrec+1;
          fieldno := 1;
          colno := 1;
          tandr.nrec := tandr.nrec+1;
          markit(tandr,recno,false,7);
          setval(tandr,recno,0,0,getval(tandr,recno-1,0,0)+1);
          for cnt := 1 to tandr.nfield do
            for cnt1 := 1 to 3 do
              setval(tandr,recno,cnt,cnt1,0);
          for cnt := 1 to 5 do
              setval(tandr,recno,tandr.nfield+1,cnt,0);
          for cnt := 1 to tandr.nfield do
            setval(tandr,recno,cnt,0,tandr.inv^[cnt].price);
          for cnt := 1 to tandr.nfield do
            tandr.p^[recno]^.data[cnt].taxable := tandr.inv^[cnt].taxable;
          tandr.p^[recno]^.taxrate := tandr.taxrate
        end
    end;

  Procedure delrecord(var tandr:tandrtype;var recno,fieldno,colno:integer);

    var cnt:integer;
        delrec:recptrtype;

    begin
      if tandr.nrec > 1 then
        begin
          delrec := tandr.p^[recno];
          for cnt := recno to tandr.nrec - 1 do
            tandr.p^[cnt] := tandr.p^[cnt+1];
          tandr.p^[tandr.nrec] := delrec;
          tandr.nrec := tandr.nrec - 1;
          if recno > tandr.nrec then recno := tandr.nrec;
          fieldno := 1;
          colno := 1
        end
    end;

  Function comparerecords(var tandr:tandrtype;sortkey1,sortkey2:integer;ascend:integer;x,y:integer):integer;

    var firstval,secondval:real;
        temp:integer;

    begin
      firstval := getval(tandr,x,sortkey1,sortkey2);
      secondval := getval(tandr,y,sortkey1,sortkey2);
      if firstval > secondval then temp := 1
      else if firstval = secondval then temp := 0
      else temp := -1;
      temp := temp*ascend;
      comparerecords := temp
    end;

  Procedure sortfile(var tandr:tandrtype;sortkey1,sortkey2:integer;ascend:integer);

    var cnt,size,incr,posit,newposit,count:integer;
        temp:recptrtype;
        done:boolean;

    begin
      size := tandr.nrec;
      incr := 1;
      while incr < size div 9 do
        incr := incr*3 + 1;
      while incr > 0 do
        begin
          for cnt := 1 to incr do
            begin
              posit := cnt + incr;
              while posit <= size do
                begin
                  newposit := posit - incr;
                  done := false;
                  while not done do
                    begin
                      if comparerecords(tandr,sortkey1,sortkey2,ascend,posit,newposit) <> -1 then done := true
                      else newposit := newposit - incr;
                      if newposit < cnt then done := true
                    end;
                  temp := tandr.p^[posit];
                  count := posit - incr;
                  while count >= newposit+incr do
                    begin
                      tandr.p^[count+incr] := tandr.p^[count];
                      count := count - incr
                    end;
                  tandr.p^[newposit+incr] := temp;
                  posit := posit + incr
                end
            end;
          incr := incr div 3
        end
    end;

  Procedure binarysearch(var tandr:tandrtype;sortkey1,sortkey2:integer;keyval:real;var recnum:integer;var found:boolean);

    var val1,val2,tempval:real;
        first,last,mid:integer;

    begin
      val1 := getval(tandr,1,sortkey1,sortkey2);
      val2 := getval(tandr,tandr.nrec,sortkey1,sortkey2);
      if val1 > val2 then
        begin
          last := 1;
          first := tandr.nrec;
          tempval := val1;
          val1 := val2;
          val2 := tempval
        end
      else
        begin
          first := 1;
          last := tandr.nrec
        end;
      if keyval = val1 then
        begin
          recnum := first;
          found := true
        end
      else if keyval = val2 then
        begin
          recnum := last;
          found := true
        end
      else if keyval < val1 then
        begin
          recnum := first;
          found := false
        end
      else if keyval > val2 then
        begin
          recnum := last;
          found := false
        end
      else
        begin
          found := false;
          while (abs(last - first) > 1) and (not found) do
            begin
              mid := (first + last) div 2;
              if keyval = getval(tandr,mid,sortkey1,sortkey2) then
                begin
                  recnum := mid;
                  found := true
                end
              else if keyval > getval(tandr,mid,sortkey1,sortkey2) then
                first := mid
              else if keyval < getval(tandr,mid,sortkey1,sortkey2) then
                last := mid
            end;
          if not found then recnum := last
        end
    end;

  Procedure getfile(var tandr:tandrtype;filename:string);

    var f:file;
        cnt:integer;
        numread:word;

    begin
      assign(f,filename);
      reset(f,1);
      cnt := 0;
      while (not eof(f)) and (cnt < tandr.maxrec) do
        begin
          cnt := cnt + 1;
          blockread(f,tandr.p^[cnt]^,reclen(tandr.nfield),numread)
        end;
      close(f);
      tandr.nrec := cnt
    end;

  Procedure savefile(var tandr:tandrtype;filename:string;append,markedonly:boolean);

    var f:file;
        cnt:integer;
        numwritten:word;

    begin
      assign(f,filename);
      if append then
        begin
          reset(f,1);
          seek(f,filesize(f))
        end
      else rewrite(f,1);
      for cnt := 1 to tandr.nrec do
        if (ismarked(tandr,cnt)) or (not markedonly) then
          blockwrite(f,tandr.p^[cnt]^,reclen(tandr.nfield),numwritten);
      close(f)
    end;

  Procedure clearreport(var tandr:tandrtype;reportptr:reportptrtype);

    var cnt,cnt1:integer;

    begin
      for cnt := 1 to tandr.nfield + tandr.ncat + 2 do
        for cnt1 := 1 to 5 do
          reportptr^[cnt,cnt1] := 0.0
    end;

  Procedure addtoreport(var tandr:tandrtype;reportptr:reportptrtype;recno:integer);

    var cnt,cnt1:integer;
        cost:real;

    begin
      for cnt := 1 to tandr.nfield do
        begin
          for cnt1 := 1 to 3 do
            reportptr^[cnt,cnt1] := reportptr^[cnt,cnt1] + getval(tandr,recno,cnt,cnt1);
          reportptr^[cnt,4] := reportptr^[cnt,4] + getval(tandr,recno,cnt,5);
          reportptr^[cnt,5] := reportptr^[cnt,5] + getval(tandr,recno,cnt,6)
        end;
      reportptr^[tandr.nfield+tandr.ncat+2,4] := reportptr^[tandr.nfield+tandr.ncat+2,4] + coupprofit(tandr,recno);
      reportptr^[tandr.nfield+tandr.ncat+2,5] := reportptr^[tandr.nfield+tandr.ncat+2,5] + couptax(tandr,recno);
      reportptr^[tandr.nfield+tandr.ncat+1,4] := reportptr^[tandr.nfield+tandr.ncat+1,4] +
        getval(tandr,recno,tandr.nfield+1,1);
      reportptr^[tandr.nfield+tandr.ncat+1,5] := reportptr^[tandr.nfield+tandr.ncat+1,5] +
        getval(tandr,recno,tandr.nfield+1,2);
    end;

  Procedure updatetotals(var tandr:tandrtype;reportptr:reportptrtype);

    var cnt,cnt1:integer;

    begin
      for cnt := tandr.nfield + 1 to tandr.nfield + tandr.ncat do
        for cnt1 := 1 to 5 do
          reportptr^[cnt,cnt1] := 0.0;
      for cnt := 1 to 3 do reportptr^[tandr.nfield+tandr.ncat+1,cnt] := 0.0;
      for cnt := 1 to tandr.nfield do
        for cnt1 := 1 to 5 do
          begin
            if (tandr.inv^[cnt].cat >= 1) and (tandr.inv^[cnt].cat <= tandr.ncat) then
              reportptr^[tandr.nfield + tandr.inv^[cnt].cat,cnt1] :=
              reportptr^[tandr.nfield + tandr.inv^[cnt].cat,cnt1] + reportptr^[cnt,cnt1];
            if cnt1 <= 3 then
              reportptr^[tandr.nfield + tandr.ncat + 1,cnt1] :=
              reportptr^[tandr.nfield + tandr.ncat + 1,cnt1] + reportptr^[cnt,cnt1]
          end
    end;

  Function voidline(reportptr:reportptrtype;posit:integer):boolean;

    var cnt:integer;
        temp:boolean;

    begin
      temp := true;
      for cnt := 1 to 3 do
        temp := temp and (abs(reportptr^[posit,cnt]) < 0.5);
      voidline := temp
    end;

  Procedure sendreport(var g:text;var tandr:tandrtype;reportptr:reportptrtype;
                       des:string;numdays:integer;var compcode:compcodetype);

    var cnt,cnt1,linesinreport:integer;
        sum:real;

    begin
      linesinreport := 24 + tandr.nfield + tandr.ncat;
      for cnt := 1 to compcode[0] do write(g,chr(compcode[cnt]));
      for cnt := 1 to 3 do writeln(g);
      writeln(g,'Sales Report':74);
      writeln(g);
      writeln(g,'For: '+des);
      writeln(g);
      if (numdays <> -1) then
        begin
          linesinreport := linesinreport + 2;
          writeln(g,'Days in report: ',numdays);
          writeln(g)
        end;
      write(g,'PLU  Item                 Sales      Exchanges  Coupons    Total      ');
      write(g,'Profit     Tax        Amt. Col');
      writeln(g);
      write(g,'---- -------------------- ---------- ---------- ---------- ---------- ');
      write(g,'---------- ---------- ----------');
      writeln(g);
      for cnt := 1 to tandr.nfield do
        if not voidline(reportptr,cnt) then
          begin
            write(g,cnt:4);
            write(g,' ');
            write(g,tandr.inv^[cnt].name);
            for cnt1 := 1 to 20 - length(tandr.inv^[cnt].name) do write(g,' ');
            for cnt1 := 1 to 3 do write(g,reportptr^[cnt,cnt1]:11:0);
            sum := 0;
            for cnt1 := 1 to 3 do sum := sum + reportptr^[cnt,cnt1];
            write(g,sum:11:0);
            for cnt1 := 4 to 5 do write(g,reportptr^[cnt,cnt1]:11:2);
            sum := 0;
            for cnt1 := 4 to 5 do sum := sum + reportptr^[cnt,cnt1];
            writeln(g,sum:11:2)
          end
        else linesinreport := linesinreport - 1;
      writeln(g);
      for cnt := 1 to 102 do write(g,'-');
      writeln(g);
      writeln(g);
      for cnt := tandr.nfield + 1 to tandr.nfield + tandr.ncat do
        if not voidline(reportptr,cnt) then
          begin
            write(g,cnt - tandr.nfield:4);
            for cnt1 := 1 to 21 do write(g,' ');
            for cnt1 := 1 to 3 do write(g,reportptr^[cnt,cnt1]:11:0);
            sum := 0;
            for cnt1 := 1 to 3 do sum := sum + reportptr^[cnt,cnt1];
            write(g,sum:11:0);
            for cnt1 := 4 to 5 do write(g,reportptr^[cnt,cnt1]:11:2);
            sum := 0;
            for cnt1 := 4 to 5 do sum := sum + reportptr^[cnt,cnt1];
            writeln(g,sum:11:2)
          end
        else linesinreport := linesinreport - 1;
      writeln(g);
      for cnt := 1 to 102 do write(g,'-');
      writeln(g);
      writeln(g);
      write(g,'':5);
      write(g,'Total');
      for cnt1 := 1 to 15 do write(g,' ');
      for cnt1 := 1 to 3 do write(g,reportptr^[tandr.nfield + tandr.ncat + 1,cnt1]:11:0);
      sum := 0;
      for cnt1 := 1 to 3 do sum := sum + reportptr^[tandr.nfield + tandr.ncat + 1,cnt1];
      write(g,sum:11:0);
      for cnt1 := 4 to 5 do
        write(g,reportptr^[tandr.nfield + tandr.ncat + 1,cnt1] + reportptr^[tandr.nfield + tandr.ncat + 2,cnt1]:11:2);
      sum := 0;
      for cnt1 := 4 to 5 do
        sum := sum + reportptr^[tandr.nfield + tandr.ncat + 1,cnt1] + reportptr^[tandr.nfield + tandr.ncat + 2,cnt1];
      writeln(g,sum:11:2);
      writeln(g);
      for cnt := 1 to 102 do write(g,'-');
      writeln(g);
      writeln(g);
      write(g,'':5);
      write(g,'Coupons');
      for cnt1 := 1 to 13 do write(g,' ');
      for cnt1 := 1 to 4 do write(g,'':11);
      for cnt1 := 4 to 5 do write(g,reportptr^[tandr.nfield + tandr.ncat + 2,cnt1]:11:2);
      sum := 0;
      for cnt1 := 4 to 5 do sum := sum + reportptr^[tandr.nfield + tandr.ncat + 2,cnt1];
      writeln(g,sum:11:2);
      writeln(g);
      for cnt := 1 to 102 do write(g,'-');
      writeln(g);
      writeln(g);
      write(g,'':5);
      write(g,'Grand Total');
      for cnt1 := 1 to 9 do write(g,' ');
      for cnt1 := 1 to 3 do write(g,reportptr^[tandr.nfield + tandr.ncat + 1,cnt1]:11:0);
      sum := 0;
      for cnt1 := 1 to 3 do sum := sum + reportptr^[tandr.nfield + tandr.ncat + 1,cnt1];
      write(g,sum:11:0);
      for cnt1 := 4 to 5 do write(g,reportptr^[tandr.nfield + tandr.ncat + 1,cnt1]:11:2);
      sum := 0;
      for cnt1 := 4 to 5 do sum := sum + reportptr^[tandr.nfield + tandr.ncat + 1,cnt1];
      writeln(g,sum:11:2);
      for cnt := 1 to 65 - (linesinreport - 1) mod 66 do writeln(g);
      for cnt := compcode[0]+2 to compcode[0]+compcode[compcode[0]+1]+1 do
        write(g,chr(compcode[cnt]))
    end;


  Procedure sendall(var g:text;var tandr:tandrtype;reportptr:reportptrtype;
                    markedonly:boolean;des:string;var compcode:compcodetype);

    var desstr:string;
        cnt,numdays:integer;
        m:boolean;
        dummy:char;
        weekdays:weekdaytype;
        userexit:boolean;

    begin
      initweekdays(weekdays);
      if des = '' then
        begin
          cnt := 1;
          userexit := false;
          while (cnt <= tandr.nrec) and (not userexit) do
            begin
              m := ismarked(tandr,cnt);
              m := m or (not markedonly);
              if m then
                begin
                  clearreport(tandr,reportptr);
                  addtoreport(tandr,reportptr,cnt);
                  updatetotals(tandr,reportptr);
                  desstr := weekdays[trunc(getval(tandr,cnt,0,0)) mod 7]+'  '+datestr(trunc(getval(tandr,cnt,0,0)));
                  sendreport(g,tandr,reportptr,desstr,-1,compcode)
                end;
              cnt := cnt + 1;
              if keypressed then
                begin
                  dummy := readkey;
                  if dummy = chr(27) then userexit := true
                  else if dummy = chr(0) then dummy := readkey
                end
            end
        end
      else
        begin
          cnt := 1;
          numdays := 0;
          clearreport(tandr,reportptr);
          while (cnt <= tandr.nrec) do
            begin
              m := ismarked(tandr,cnt);
              m := m or (not markedonly);
              if m then
                begin
                  numdays := numdays + 1;
                  addtoreport(tandr,reportptr,cnt)
                end;
              cnt := cnt + 1
            end;
          updatetotals(tandr,reportptr);
          sendreport(g,tandr,reportptr,des,numdays,compcode)
        end
    end;


  Procedure openfile(var tandr:tandrtype;filename:string);

    var f:file;
        p:recptrtype;
        error,cnt,cnt1:integer;
        numwritten:word;

    begin
      assign(f,filename);
      {$I-}
        rewrite(f,1);
      {$I+}
      error := IOresult;
      if error <> 0 then
        begin
          writeln;
          writeln('Disk Full.');
          halt
        end;
      getmem(p,reclen(tandr.nfield));
      for cnt := 1 to tandr.nfield do
        begin
          p^.data[cnt].price := tandr.inv^[cnt].price;
          p^.data[cnt].taxable := tandr.inv^[cnt].taxable;
          for cnt1 := 1 to 3 do p^.data[cnt].col[cnt1] := 0
        end;
      p^.marked := false;
      p^.date := 2;
      p^.taxrate := tandr.taxrate;
      for cnt := 1 to 5 do p^.totals[cnt] := 0.0;
      blockwrite(f,p^,reclen(tandr.nfield),numwritten);
      close(f);
      freemem(p,reclen(tandr.nfield))
    end;

  Procedure displaytotals(var tandr:tandrtype;markedonly:boolean);

    var sums:array[1..6] of real;
        cnt,reccounted:integer;

    begin
      clrscr;
      for cnt := 1 to 6 do sums[cnt] := 0.0;
      reccounted := 0;
      for cnt := 1 to tandr.nrec do
        if (ismarked(tandr,cnt)) or (not markedonly) then
          begin
            reccounted := reccounted + 1;
            sums[1] := sums[1] + coupprofit(tandr,cnt);
            sums[2] := sums[2] + couptax(tandr,cnt);
            sums[3] := sums[3] + couptotal(tandr,cnt);
            sums[4] := sums[4] + getval(tandr,cnt,tandr.nfield+1,1);
            sums[5] := sums[5] + getval(tandr,cnt,tandr.nfield+1,2);
            sums[6] := sums[6] + getval(tandr,cnt,tandr.nfield+1,3)
          end;
      gotoxy(1,6);
      write('Records counted: ',reccounted);
      gotoxy(1,8);
      writeln('Profit:      ',sums[1]+sums[4]:0:2);
      writeln('Tax:         ',sums[2]+sums[5]:0:2);
      writeln('Total:       ',sums[3]+sums[6]:0:2);
      writeln;
      writeln('Less profit: ',sums[1]:0:2);
      writeln('Less tax:    ',sums[2]:0:2);
      writeln('Less total:  ',sums[3]:0:2);
      writeln;
      writeln('Net profit:  ',sums[4]:0:2);
      writeln('Net tax:     ',sums[5]:0:2);
      writeln('Net total:   ',sums[6]:0:2);
      gotoxy(28,25);
      write('Press any key to continue.');
      readln
    end;


  begin
    if not fileexists('compcode.dat') then
      begin
        writeln('Cannot find COMPCODE.DAT');
        exit
      end;
    assign(compfile,'compcode.dat');
    reset(compfile,1);
    blockread(compfile,compcode,maxlencompcode,numread);
    close(compfile);
    if paramstr(1) <> '' then
      val(paramstr(1),tandr.maxrec,code)
    else
      tandr.maxrec := 365;
    clrscr;
    gotoxy(1,12);
    write('Get item info from what file? ');
    getinput(filename,escpressed);
    if escpressed then exit;
    if not fileexists(filename) then
      begin
        writeln;
        writeln;
        writeln(chr(7)+'Cannot find that file.');
        exit
      end;
    initfields(tandr,reportptr,filename);
    clrscr;
    gotoxy(1,12);
    write('Get sales data from what file? ');
    getinput(filename,escpressed);
    if escpressed then exit;
    if not fileexists(filename) then
      begin
        clrscr;
        gotoxy(1,12);
        write('Cannot find that file.  Create a new one<y,n>? ');
        readln(response);
        if response in ['Y','y'] then openfile(tandr,filename)
        else exit
      end;
    if not filevalid(filename,reclen(tandr.nfield)) then
      begin
        writeln;
        writeln;
        writeln(chr(7)+'That file does not correspond to the item info file.');
        exit
      end;
    getfile(tandr,filename);
    if tandr.nrec = 0 then
      begin
        writeln;
        writeln;
        writeln(chr(7)+'File is empty!');
        exit
      end;
    recno := 1;
    fieldno := 1;
    colno := 1;
    done := false;
    repeat
      displayrecord(tandr,recno,fieldno,colno);
      choice := readkey;
      if not (choice in ['0'..'9']) then
      case choice of
        chr(1):append(tandr,recno,fieldno,colno);
        chr(2):begin
                 clrscr;
                 gotoxy(1,10);
                 write('Name of file to hold records: ');
                 getinput(temp,escpressed);
                 if not escpressed then
                   begin
                     outfile := temp;
                     gotoxy(1,12);
                     write('Write marked records only<y,n>? ');
                     getinput(temp,escpressed);
                     if not escpressed then
                       begin
                         if length(temp) > 0 then markedonly := temp[1] in ['Y','y']
                         else markedonly := false;
                         response := 'N';
                         if fileexists(outfile) then
                           begin
                             gotoxy(1,14);
                             write('That file already exists.  Append instead of overwrite<y,n>? ');
                             getinput(temp,escpressed);
                             if length(temp) > 0 then response := temp[1]
                             else response := 'N'
                           end;
                         if not escpressed then
                           begin
                             if response in ['Y','y'] then
                               begin
                                 if filevalid(outfile,reclen(tandr.nfield)) then
                                   savefile(tandr,outfile,true,markedonly)
                                 else
                                   begin
                                     gotoxy(1,16);
                                     usermessage('Records are not compatible.')
                                   end
                               end
                             else
                               begin
                                 if filecreation(outfile) then
                                   savefile(tandr,outfile,false,markedonly)
                                 else
                                   begin
                                     gotoxy(1,16);
                                     usermessage('File creation error.')
                                   end
                               end
                           end
                       end
                   end
               end;
        chr(3):begin
                 clrscr;
                 gotoxy(1,12);
                 write('Are you sure<y,n>? ');
                 readln(response);
                 if response in ['Y','y'] then
                   begin
                     shutdown(tandr,reportptr);
                     done := true
                   end
               end;
        chr(4):begin
                 clrscr;
                 gotoxy(1,12);
                 write('Are you sure<y,n>? ');
                 readln(response);
                 if response in ['Y','y'] then
                   delrecord(tandr,recno,fieldno,colno)
               end;
        chr(5):begin
                 clrscr;
                 gotoxy(1,12);
                 write('Go to what PLU# ? ');
                 getinput(temp,escpressed);
                 if not escpressed then
                   begin
                     val(temp,fieldno,code);
                     if (fieldno < 1) then fieldno := 1;
                     if (fieldno > tandr.nfield) then fieldno := tandr.nfield
                   end
               end;
        chr(6):begin
                 clrscr;
                 gotoxy(1,9);
                 write('Start at what record (ENTER for all)? ');
                 getinput(temp,escpressed);
                 if not escpressed then
                   begin
                     if temp = '' then
                       begin
                         startrec := 1;
                         endrec := tandr.nrec
                       end
                     else
                       begin
                         val(temp,startrec,code);
                         if (startrec < 1) or (startrec > tandr.nrec) then
                           startrec := 1;
                         gotoxy(1,11);
                         write('End at what record? ');
                         getinput(temp,escpressed);
                         if not escpressed then
                           begin
                             val(temp,endrec,code);
                             if (endrec < 1) or (endrec > tandr.nrec) then
                               endrec := tandr.nrec
                           end
                       end;
                     if not escpressed then
                       begin
                         gotoxy(1,13);
                         write('(M)ark or (U)nmark records? ');
                         getinput(temp,escpressed);
                         if not escpressed then
                           begin
                             mstat := not (temp[1] in ['U','u']);
                             gotoxy(1,15);
                             write('For what days of the week (7 for all)? ');
                             getinput(temp,escpressed);
                             if not escpressed then
                               begin
                                 val(temp,dayofweek,code);
                                 for cnt := startrec to endrec do
                                 markit(tandr,cnt,mstat,dayofweek)
                               end
                           end
                       end
                   end
               end;
        chr(7):begin
                 clrscr;
                 gotoxy(1,12);
                 write('Go to what record? ');
                 getinput(temp,escpressed);
                 if not escpressed then
                   begin
                     val(temp,recno,code);
                     if (recno < 1) then recno := 1;
                     if (recno > tandr.nrec) then recno := tandr.nrec;
                     fieldno := 1;
                     colno := 1
                   end
               end;
        chr(8):del_digit(tandr,recno,fieldno,colno);
        chr(11):begin
                  cnt := 0;
                  repeat
                    cnt := cnt + 1;
                    prevrec(tandr,recno,fieldno,colno)
                  until (ismarked(tandr,recno)) or (cnt = tandr.nrec)
                end;
        chr(12):begin
                  cnt := 0;
                  repeat
                    cnt := cnt + 1;
                    nextrec(tandr,recno,fieldno,colno)
                  until (ismarked(tandr,recno)) or (cnt = tandr.nrec)
                end;
        chr(14):markit(tandr,recno,not ismarked(tandr,recno),7);
        chr(15):begin
                  oldtaxcoup := getval(tandr,recno,tandr.nfield + 1,4);
                  oldnontaxcoup := getval(tandr,recno,tandr.nfield + 1,5);
                  clrscr;
                  gotoxy(1,10);
                  writeln('Taxable Coupons: ');
                  write('[ENTER] : ',getval(tandr,recno,tandr.nfield + 1,4):0:2);
                  gotoxy(18,10);
                  readln(temp);
                  if temp <> '' then
                    begin
                      val(temp,taxcoup,code);
                      setval(tandr,recno,tandr.nfield + 1,4,taxcoup)
                    end;
                  gotoxy(1,13);
                  writeln('Non Taxable Coupons: ');
                  write('[ENTER] : ',getval(tandr,recno,tandr.nfield + 1,5):0:2);
                  gotoxy(22,13);
                  readln(temp);
                  if temp <> '' then
                    begin
                      val(temp,nontaxcoup,code);
                      setval(tandr,recno,tandr.nfield + 1,5,nontaxcoup)
                    end;
                  taxdiff := getval(tandr,recno,tandr.nfield + 1,4) - oldtaxcoup;
                  nontaxdiff := getval(tandr,recno,tandr.nfield + 1,5) - oldnontaxcoup;
                  oldsum := getval(tandr,recno,tandr.nfield + 1,1);
                  setval(tandr,recno,tandr.nfield + 1,1,oldsum - taxdiff - nontaxdiff);
                  oldsum := getval(tandr,recno,tandr.nfield + 1,2);
                  setval(tandr,recno,tandr.nfield + 1,2,oldsum - taxdiff*tandr.p^[recno]^.taxrate);
                  oldsum := getval(tandr,recno,tandr.nfield + 1,3);
                  setval(tandr,recno,tandr.nfield + 1,3,oldsum - nontaxdiff - taxdiff*(1 + tandr.p^[recno]^.taxrate))
                end;
        chr(16):begin
                  clrscr;
                  gotoxy(1,10);
                  write('Send output to? ');
                  getinput(temp,escpressed);
                  if not escpressed then
                    begin
                      printdev := temp;
                      gotoxy(1,12);
                      write('Send marked records only<y,n>? ');
                      getinput(temp,escpressed);
                      if not escpressed then
                        begin
                          markedonly := temp[1] in ['Y','y'];
                          assign(g,printdev);
                          {$I-}
                            rewrite(g);
                          {$I+}
                          error := IOresult;
                          if error = 0 then
                            begin
                              gotoxy(1,14);
                              write('Press ESC to stop.');
                              printshort(g,tandr,markedonly,compcode);
                              close(g)
                            end
                          else
                            begin
                              gotoxy(1,14);
                              write(chr(7)+'File creation error.');
                              pause
                            end
                        end
                    end
                end;
        chr(17):if tandr.key1 >= 0 then
                  begin
                    clrscr;
                    gotoxy(1,12);
                    write('Find? ');
                    getinput(temp,escpressed);
                    if not escpressed then
                      begin
                        if tandr.key1 = 0 then searchkey := dateval(temp)
                        else val(temp,searchkey,code);
                        binarysearch(tandr,tandr.key1,tandr.key2,searchkey,recno,found);
                        fieldno := 1;
                        colno := 1
                      end
                  end;
        chr(18):begin
                  clrscr;
                  gotoxy(1,9);
                  write('Send output to? ');
                  getinput(temp,escpressed);
                  if not escpressed then
                    begin
                      printdev := temp;
                      gotoxy(1,11);
                      writeln('Summary description: ');
                      write('(Hit [ENTER] for daily reports)');
                      gotoxy(22,11);
                      getinput(des,escpressed);
                      if not escpressed then
                        begin
                          gotoxy(1,14);
                          write('Include marked records only<y,n>? ');
                          getinput(temp,escpressed);
                          if not escpressed then
                            begin
                              markedonly := temp[1] in ['Y','y'];
                              assign(g,printdev);
                              {$I-}
                                rewrite(g);
                              {$I+}
                              error := IOresult;
                              if error = 0 then
                                begin
                                  if des = '' then
                                    begin
                                      gotoxy(1,16);
                                      write('Press ESC to stop.')
                                    end;
                                  sendall(g,tandr,reportptr,markedonly,des,compcode);
                                  close(g)
                                end
                              else
                                begin
                                  gotoxy(1,16);
                                  write(chr(7)+'File creation error.');
                                  pause
                                end
                            end
                        end
                    end
                end;
        chr(19):begin
                  clrscr;
                  gotoxy(1,10);
                  write('Sort by what field number? ');
                  getinput(temp,escpressed);
                  if not escpressed then
                    begin
                      val(temp,sortkey,code);
                      if (sortkey < 0) or (sortkey > tandr.nfield+1) then
                        sortkey := 0;
                      if sortkey > 0 then
                        begin
                          gotoxy(1,12);
                          write('Sort by what column? ');
                          getinput(temp,escpressed)
                        end
                      else
                        begin
                          escpressed := false;
                          temp := '0'
                        end;
                      if not escpressed then
                        begin
                          val(temp,colkey,code);
                          gotoxy(1,14);
                          write('Sort in (A)scending or (D)escending order? ');
                          getinput(temp,escpressed);
                          if not escpressed then
                            begin
                              if not (temp[1] in ['A','a']) then ascend := -1
                              else ascend := 1;
                              sortfile(tandr,sortkey,colkey,ascend);
                              tandr.key1 := sortkey;
                              tandr.key2 := colkey;
                              recno := 1;
                              fieldno := 1;
                              colno := 1
                            end
                        end
                    end
                end;
        chr(20):begin
                  clrscr;
                  gotoxy(1,12);
                  write('Change date to: ');
                  getinput(temp,escpressed);
                  if not escpressed then
                    setval(tandr,recno,0,0,dateval(temp))
                end;
        chr(21):begin
                  clrscr;
                  gotoxy(1,12);
                  write('Total marked records only<y,n>? ');
                  getinput(temp,escpressed);
                  if not escpressed then
                    begin
                      markedonly := temp[1] in ['Y','y'];
                      displaytotals(tandr,markedonly)
                    end
                end;
        chr(26):begin
                  clrscr;
                  savefile(tandr,filename,false,false);
                  shutdown(tandr,reportptr);
                  done := true
                end;
        chr(0):begin
                 schoice := readkey;
                 case schoice of
                   chr(72):prevfield(tandr,fieldno);
                   chr(75):prevcol(colno);
                   chr(77):nextcol(colno);
                   chr(80):nextfield(tandr,fieldno);
                   chr(73):prevrec(tandr,recno,fieldno,colno);
                   chr(81):nextrec(tandr,recno,fieldno,colno)
                 end
               end;
      end
      else
        add_digit(tandr,recno,fieldno,colno,choice)
    until done
  end.
