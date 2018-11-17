program tabulate;

  uses crt,IOunit;

  const
    fieldnamesize = 15;
    maxlencompcode = 10;

  type

    compcodetype = array[0..maxlencompcode-1] of byte;

    celltype = record
      cat:integer;
      date:integer;
      maxcoll:integer;
      amt:real
    end;

    arraytype = array[0..5458] of celltype;

    tabletype = record
      numinmem:integer;
      size:integer;
      data:arraytype
    end;

    tableptrtype = ^tabletype;

    nametype = string[fieldnamesize];

    recinfotype = record
      fieldname:array[1..18] of nametype;
      typeoffield:array[1..18] of char;
      recoffset:array[1..18] of integer;
      numfields:integer;
      recsize:integer
    end;

    parraytype = array[0..32767] of byte;

    recptrtype = ^parraytype;

  var
    compfile:file;
    g:text;
    h:file;
    cnt,memavail,code,expselcat,expstartdate,expenddate,catselcat:integer;
    curmonth,catbegdate,catstartdate,catenddate,expspan,catspan,catincr:integer;
    fileerror,exprequested,catrequested,expbin,catbin,escpressed:boolean;
    catoutfile,expoutfile,expfile,exptemplate,catfile,cattemplate,temp:string;
    exprecinfo,catrecinfo:recinfotype;
    t:tableptrtype;
    compcode:compcodetype;
    numread:word;
    response:char;

  Function hash(cat,date:longint;size:integer):integer;

    var x,y:integer;

    begin
      x := (sqr(cat+1253) div 100) mod 10000;
      y := (sqr(date+5527) div 100) mod 10000;
      hash := (x+y) mod size
    end;

  Function rehash(cat:integer;size:integer):integer;

    var x:integer;

    begin
      x := cat mod 1000;
      x := (x div 100)*10 + (x mod 10);
      if (x mod size = 0) then rehash := 1
      else rehash := x
    end;

  Function datestr(x:integer):string;

    var y,m:integer;
        ystr,mstr:string[2];

    begin
      m := (x - 1) mod 12 + 1;
      y := (x - 1) div 12 + 80;
      if y >= 100 then y := y - 100;
      str(y,ystr);
      str(m,mstr);
      if length(ystr) < 2 then ystr := '0'+ystr;
      if length(mstr) < 2 then mstr := '0'+mstr;
      datestr := mstr+'/01/'+ystr
    end;


  Function dateval(x:string):integer;

    var m,y,code:integer;

    begin
      val(copy(x,1,2),m,code);
      val(copy(x,7,2),y,code);
      if y >= 80 then y := y-80
        else y := y+20;
      dateval := y*12 + m
    end;

  Function fieldval(p:recptrtype;fieldno:integer;var recinfo:recinfotype):string;

    var q:^string;

    begin
      q := addr(p^[recinfo.recoffset[fieldno]]);
      fieldval := q^
    end;

  Function fieldsize(fieldno:integer;var recinfo:recinfotype):integer;

    begin
      if fieldno = recinfo.numfields then
        fieldsize := recinfo.recsize - recinfo.recoffset[fieldno]
      else fieldsize := recinfo.recoffset[fieldno + 1] - recinfo.recoffset[fieldno]
    end;

  Procedure assigntofield(x:string;p:recptrtype;fieldno:integer;var recinfo:recinfotype);

    var q:^string;

    begin
      q := addr(p^[recinfo.recoffset[fieldno]]);
      q^ := copy(x,1,fieldsize(fieldno,recinfo)-1)
    end;

  Procedure getrecinfo(var recinfo:recinfotype;filename:string);

    var infile:text;
        temp:string;
        posit,strsize,code:integer;

    begin
      assign(infile,filename);
      reset(infile);
      with recinfo do
        begin
          numfields := 0;
          posit := 6;
          while not eof(infile) do
            begin
              numfields := numfields + 1;
              readln(infile,temp);
              fieldname[numfields] := copy(temp,1,fieldnamesize);
              readln(infile,temp);
              typeoffield[numfields] := temp[1];
              typeoffield[numfields] := upcase(typeoffield[numfields]);
              recoffset[numfields] := posit;
              readln(infile,temp);
              val(temp,strsize,code);
              posit := posit + strsize + 1
            end;
          recsize := posit
        end;
      close(infile)
    end;

  Procedure inittable(var t:tableptrtype;size:integer);

    var cnt:integer;

    begin
      getmem(t,4+12*size);
      t^.numinmem := 0;
      t^.size := size;
      for cnt := 0 to size - 1 do
        begin
          t^.data[cnt].date := -1;
          t^.data[cnt].maxcoll := 0
        end
    end;

  Procedure cleartable(var t:tableptrtype);

    var size:integer;

    begin
      size := t^.size;
      freemem(t,4+12*size)
    end;

  Function addto(t:tableptrtype;cat,date:integer;amt:real):boolean;

    var h,c,coll,maxcoll,posit:integer;

    begin
      h := hash(cat,date,t^.size);
      c := rehash(cat,t^.size);
      maxcoll := t^.data[h].maxcoll;
      coll := 1;
      posit := h;
      while ((cat <> t^.data[posit].cat) or (date <> t^.data[posit].date))
            and (coll <= maxcoll) do
        begin
          coll := coll + 1;
          posit := (posit + c) mod t^.size
        end;
      if (coll <= maxcoll) then {node found}
        begin
          addto := true;
          t^.data[posit].amt := t^.data[posit].amt + amt
        end
      else if (t^.numinmem = t^.size) then addto := false
      else
        begin
          posit := h;
          coll := 1;
          while (t^.data[posit].date <> -1) do
            begin
              posit := (posit + c) mod t^.size;
              coll := coll + 1
            end;
          t^.numinmem := t^.numinmem + 1;
          if coll > maxcoll then t^.data[h].maxcoll := coll;
          t^.data[posit].date := date;
          t^.data[posit].cat := cat;
          t^.data[posit].amt := amt;
          addto := true
        end
    end;

  Function getval(t:tableptrtype;cat,date:integer):real;

    var h,c,coll,maxcoll,posit:integer;

    begin
      h := hash(cat,date,t^.size);
      c := rehash(cat,t^.size);
      maxcoll := t^.data[h].maxcoll;
      coll := 1;
      posit := h;
      while ((cat <> t^.data[posit].cat) or (date <> t^.data[posit].date))
            and (coll <= maxcoll) do
        begin
          coll := coll + 1;
          posit := (posit + c) mod t^.size
        end;
      if (coll <= maxcoll) then
        getval := t^.data[posit].amt
      else getval := 0
    end;

  Function recordvalid(p:recptrtype;var recinfo:recinfotype;selcat,startdate,enddate:integer;catrep:boolean):boolean;

    var vcat,vdate:boolean;
        x,y,code:integer;

    begin
      vcat := true;
      if catrep then
        begin
          x := 0;
          val(fieldval(p,3,recinfo),y,code)
        end
      else
        begin
          val(fieldval(p,2,recinfo),x,code);
          val(fieldval(p,3,recinfo),y,code)
        end;
      if (selcat > 0) and (selcat < 100) then
        vcat := (x div 100 = selcat) or (y div 100 = selcat);
      if (selcat >= 100) and (selcat <= 9999) then
        vcat := (x = selcat) or (y = selcat);
      vdate := true;
      if not catrep then
        begin
          y := dateval(fieldval(p,1,recinfo));
          vdate := (y >= startdate) and (y < enddate)
        end;
      recordvalid := vdate and vcat
    end;

  Procedure getcatinfo(filename:string;var recinfo:recinfotype;t:tableptrtype;selcat,startdate,enddate:integer);

    var p:recptrtype;
        f:file;
        date,cat,payment,code:integer;
        amt:real;
        numread:word;
        success:boolean;

    begin
      success := true;
      getmem(p,recinfo.recsize);
      assign(f,filename);
      reset(f,1);
      while not eof(f) do
        begin
          blockread(f,p^,recinfo.recsize,numread);
          if recordvalid(p,recinfo,selcat,startdate,enddate,false) then
            begin
              date := dateval(fieldval(p,1,recinfo));
              val(fieldval(p,2,recinfo),cat,code);
              val(fieldval(p,3,recinfo),payment,code);
              val(fieldval(p,4,recinfo),amt,code);
              success := success and addto(t,payment,date,amt);
              if (payment mod 100 <> 0) then success := success and addto(t,100*(payment div 100),date,amt);
              if (fieldval(p,5,recinfo) = 'Y') or (fieldval(p,5,recinfo) = 'y') then
                begin
                  success := success and addto(t,cat,date,-amt);
                  if (cat mod 100 <> 0) then success := success and addto(t,100*(cat div 100),date,-amt)
                end
              else
                begin
                  success := success and addto(t,cat,date,amt);
                  if (cat mod 100 <> 0) then success := success and addto(t,100*(cat div 100),date,amt)
                end
            end
        end;
      close(f);
      freemem(p,recinfo.recsize);
      if not success then
        begin
          writeln;
          writeln(chr(7)+'Out of memory.');
          halt
        end;
    end;

  Procedure getbalforward(filename:string;var recinfo:recinfotype;t:tableptrtype;
                          selcat,startdate,enddate:integer);

    var p:recptrtype;
        f:file;
        curcat,cnt,code:integer;
        numread:word;
        alloc,spent,oldbal:real;
        success:boolean;

    begin
      success := true;
      getmem(p,recinfo.recsize);
      assign(f,filename);
      reset(f,1);
      while not eof(f) do
        begin
          blockread(f,p^,recinfo.recsize,numread);
          if recordvalid(p,recinfo,selcat,startdate,enddate,true) then
            begin
              val(fieldval(p,3,recinfo),curcat,code);
              val(fieldval(p,5,recinfo),alloc,code);
              val(fieldval(p,8,recinfo),oldbal,code);
              spent := 0;
              for cnt := startdate to enddate - 1 do
                spent := spent + getval(t,curcat,cnt);
              success := success and addto(t,curcat,1300,oldbal+(enddate-startdate)*alloc - spent)
            end
        end;
      close(f);
      freemem(p,recinfo.recsize);
      if not success then
        begin
          writeln;
          writeln(chr(7)+'Out of memory.');
          halt
        end
    end;

  Procedure updaterecord(p:recptrtype;var recinfo:recinfotype;t:tableptrtype;
                         startdate,enddate:integer;var tamtspent:real);

    var curcat,code,cnt:integer;
        alloc,oldbal,spent,newbal:real;
        spentstr,oldbalstr,newbalstr:string[15];
        success:boolean;

    begin
      success := true;
      val(fieldval(p,3,recinfo),curcat,code);
      val(fieldval(p,5,recinfo),alloc,code);
      oldbal := getval(t,curcat,1300);
      spent := 0;
      for cnt := startdate to enddate - 1 do
        spent := spent + getval(t,curcat,cnt);
      if p^[0] <> 0 then tamtspent := tamtspent + spent;
      success := success and addto(t,curcat,1300,(enddate-startdate)*alloc - spent);
      newbal := oldbal + (enddate-startdate)*alloc - spent;
      str(spent:0:2,spentstr);
      str(oldbal:0:2,oldbalstr);
      str(newbal:0:2,newbalstr);
      assigntofield(datestr(startdate),p,1,recinfo);
      assigntofield(datestr(enddate),p,2,recinfo);
      assigntofield(spentstr,p,6,recinfo);
      assigntofield(oldbalstr,p,7,recinfo);
      assigntofield(newbalstr,p,8,recinfo);
      if not success then
        begin
          writeln;
          writeln(chr(7)+'Out of memory.');
          halt
        end
    end;


  Procedure printrecord(var g:text;p:recptrtype;var recinfo:recinfotype);

    var temp:string;
        count,cnt:integer;

    begin
      for count := 1 to recinfo.numfields do
        begin
          temp := fieldval(p,count,recinfo);
          if recinfo.typeoffield[count] = 'N' then
            begin
              for cnt := 1 to fieldsize(count,recinfo) - length(temp) - 1 do
                write(g,' ');
              write(g,temp)
            end
          else
            begin
              write(g,temp);
              for cnt := 1 to fieldsize(count,recinfo) - length(temp) - 1 do
                write(g,' ')
            end;
          if count <> recinfo.numfields then write(g,' ')
        end;
      writeln(g)
    end;


  Procedure printpage(var g:text;var f:file;pageno:integer;
                      var recinfo:recinfotype;t:tableptrtype;
                      selcat,startdate,enddate:integer;
                      catrep:boolean;var done:boolean;var tamtspent:real;
                      var cmo:integer;p:recptrtype;incr:integer);


    var cnt,cnt1,count,lineno:integer;
        temp:string;
        dummy:char;
        numread:word;
        vrec:boolean;

    begin
      for cnt := 1 to 3 do writeln(g);
      for cnt := 1 to 60 do write(g,' ');
      writeln(g,'Page: ',pageno);
      writeln(g);
      for cnt := 1 to recinfo.numfields do
        begin
          temp := recinfo.fieldname[cnt];
          temp := copy(temp,1,fieldsize(cnt,recinfo)-1);
          write(g,temp);
          for cnt1 := 1 to fieldsize(cnt,recinfo) - length(temp) - 1 do
            write(g,' ');
          if cnt <> recinfo.numfields then write(g,' ')
        end;
      writeln(g);
      for count := 1 to recinfo.numfields do
        begin
          for cnt := 1 to fieldsize(count,recinfo) - 1 do
            write(g,'-');
          if count <> recinfo.numfields then write(g,' ')
        end;
      writeln(g);
      lineno := 1;
      while (lineno <= 51) and (not ((eof(f)) and (cmo = startdate))) and (not done) do
        begin
          if (cmo = startdate) then
            begin
              vrec := false;
              while (not eof(f)) and (not vrec) do
                begin
                  blockread(f,p^,recinfo.recsize,numread);
                  vrec := recordvalid(p,recinfo,selcat,startdate,enddate,catrep)
                end
            end
          else vrec := true;
          if vrec then
            begin
              if catrep then
                begin
                  updaterecord(p,recinfo,t,cmo,cmo+incr,tamtspent);
                  cmo := cmo+incr;
                  if cmo >= enddate then cmo := startdate
                end;
              printrecord(g,p,recinfo);
              lineno := lineno + 1
            end;
          if keypressed then
            begin
              dummy := readkey;
              if dummy = chr(27) then done := true
              else if dummy = chr(0) then dummy := readkey
            end
        end;
      if (tamtspent <> 0) and (eof(f)) then
        begin
          writeln(g);
          writeln(g,'Total amount spent: ',tamtspent:0:2);
          for cnt := 1 to 58-lineno do writeln(g)
        end
      else for cnt := 1 to 60-lineno do writeln(g)
    end;



  Procedure printfile(var g:text;filename:string;var recinfo:recinfotype;
                      t:tableptrtype;var compcode:compcodetype;selcat,startdate,
                      enddate:integer;catrep:boolean;incr:integer);

    var pageno:word;
        done:boolean;
        cnt,cmo:integer;
        f:file;
        tamtspent:real;
        p:recptrtype;

    begin
      getmem(p,recinfo.recsize);
      cmo := startdate;
      tamtspent := 0.0;
      for cnt := 1 to compcode[0] do write(g,chr(compcode[cnt]));
      pageno := 1;
      done := false;
      assign(f,filename);
      reset(f,1);
      while (not ((eof(f)) and (cmo = startdate))) and (not done) do
        begin
          printpage(g,f,pageno,recinfo,t,selcat,startdate,enddate,catrep,done,tamtspent,cmo,p,incr);
          pageno := pageno + 1
        end;
      close(f);
      for cnt := compcode[0]+2 to compcode[0]+compcode[compcode[0]+1]+1 do
        write(g,chr(compcode[cnt]));
      freemem(p,recinfo.recsize)
    end;

  Procedure printbinary(var h:file;filename:string;var recinfo:recinfotype;
                      t:tableptrtype;selcat,startdate,
                      enddate:integer;catrep:boolean;incr:integer);

    var p:recptrtype;
        tamtspent:real;
        vrec:boolean;
        f:file;
        numread,numwritten:word;
        cmo:integer;

    begin
      tamtspent := 0.0;
      getmem(p,recinfo.recsize);
      assign(f,filename);
      reset(f,1);
      while not eof(f) do
        begin
          blockread(f,p^,recinfo.recsize,numread);
          vrec := recordvalid(p,recinfo,selcat,startdate,enddate,catrep);
          if vrec then
            begin
              if catrep then
                begin
                  cmo := startdate;
                  while (cmo < enddate) do
                    begin
                      updaterecord(p,recinfo,t,cmo,cmo+incr,tamtspent);
                      cmo := cmo + incr;
                      blockwrite(h,p^,recinfo.recsize,numwritten)
                    end
                end
              else blockwrite(h,p^,recinfo.recsize,numwritten)
            end
        end;
      close(f);
      freemem(p,recinfo.recsize)
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
      val(paramstr(1),memavail,code)
    else
      memavail := 5449;
    writeln;
    write('Enter expense file: ');
    getinput(expfile,escpressed);
    writeln;
    if escpressed then exit;
    if not fileexists(expfile) then
      begin
        writeln(chr(7)+'Cannot find that file.');
        exit
      end;
    write('Enter template for expense file: ');
    getinput(exptemplate,escpressed);
    writeln;
    if escpressed then exit;
    if not fileexists(exptemplate) then
      begin
        writeln(chr(7)+'Cannot find that file.');
        exit
      end;
    getrecinfo(exprecinfo,exptemplate);
    if not filevalid(expfile,exprecinfo.recsize) then
      begin
        writeln(chr(7)+'File does not correspond to template.');
        exit
      end;
    write('Enter category file: ');
    getinput(catfile,escpressed);
    writeln;
    if escpressed then exit;
    if not fileexists(catfile) then
      begin
        writeln(chr(7)+'Cannot find that file.');
        exit
      end;
    write('Enter template for category file: ');
    getinput(cattemplate,escpressed);
    writeln;
    if escpressed then exit;
    if not fileexists(cattemplate) then
      begin
        writeln(chr(7)+'Cannot find that file.');
        exit
      end;
    getrecinfo(catrecinfo,cattemplate);
    if not filevalid(catfile,catrecinfo.recsize) then
      begin
        writeln(chr(7)+'File does not correspond to template.');
        exit
      end;
    writeln;
    write('Print expenses<y,n>? ');
    getinput(temp,escpressed);
    writeln;
    if escpressed then exit;
    writeln;
    exprequested := temp[1] in ['Y','y'];
    if exprequested then
      begin
        write('Enter selected categories: ');
        getinput(temp,escpressed);
        writeln;
        if escpressed then exit;
        val(temp,expselcat,code);
        write('Enter start date: ');
        getinput(temp,escpressed);
        writeln;
        if escpressed then exit;
        expstartdate := dateval(temp);
        write('Enter end date: ');
        getinput(temp,escpressed);
        writeln;
        if escpressed then exit;
        expenddate := dateval(temp);
        write('Enter report span: ');
        getinput(temp,escpressed);
        writeln;
        if escpressed then exit;
        val(temp,expspan,code);
        writeln
      end;
    write('Print reports<y,n>? ');
    getinput(temp,escpressed);
    writeln;
    if escpressed then exit;
    writeln;
    catrequested := temp[1] in ['Y','y'];
    if catrequested then
      begin
        write('Enter category file date: ');
        getinput(temp,escpressed);
        writeln;
        if escpressed then exit;
        catbegdate := dateval(temp);
        write('Enter selected categories: ');
        getinput(temp,escpressed);
        writeln;
        if escpressed then exit;
        val(temp,catselcat,code);
        write('Enter start date: ');
        getinput(temp,escpressed);
        writeln;
        if escpressed then exit;
        catstartdate := dateval(temp);
        write('Enter end date: ');
        getinput(temp,escpressed);
        writeln;
        if escpressed then exit;
        catenddate := dateval(temp);
        write('Enter report span: ');
        getinput(temp,escpressed);
        writeln;
        if escpressed then exit;
        val(temp,catspan,code);
        write('Enter unit span: ');
        getinput(temp,escpressed);
        writeln;
        if escpressed then exit;
        val(temp,catincr,code);
        writeln
      end;
    if exprequested then
      begin
        repeat
          repeat
            response := 'Y';
            write('Write expenses to what file? ');
            getinput(temp,escpressed);
            writeln;
            if escpressed then exit;
            caps(temp);
            if (temp <> 'LPT1') then
              if fileexists(temp) then
                begin
                  write('That file already exists. Overwrite<y,n>? ');
                  readln(response)
                end
          until (response in ['Y','y']);
          if (temp <> 'LPT1') then
            if not filecreation(temp) then
              begin
                writeln(chr(7)+'File creation error.');
                fileerror := true
              end
            else fileerror := false
          else fileerror := false;
        until not fileerror;
        expoutfile := temp;
        if (expoutfile <> 'LPT1') then
          begin
            write('write in (B)inary or (T)ext? ');
            readln(response);
            expbin := response in ['B','b']
          end
        else expbin := false;
        writeln
      end;
    if catrequested then
      begin
        repeat
          repeat
            response := 'Y';
            write('Write reports to what file? ');
            getinput(temp,escpressed);
            writeln;
            if escpressed then exit;
            caps(temp);
            if temp <> 'LPT1' then
              if fileexists(temp) then
                begin
                  write('That file already exists. Overwrite<y,n>? ');
                  readln(response)
                end
          until (response in ['Y','y']);
          if (temp <> 'LPT1') then
            if not filecreation(temp) then
              begin
                writeln(chr(7)+'File creation error.');
                fileerror := true
              end
            else fileerror := false
          else fileerror := false;
        until not fileerror;
        catoutfile := temp;
        if (catoutfile <> 'LPT1') then
          begin
            write('write in (B)inary or (T)ext? ');
            readln(response);
            catbin := response in ['B','b']
          end
        else catbin := false;
        writeln
      end;
    inittable(t,memavail);
    if exprequested then
      begin
        if expbin then
          begin
            assign(h,expoutfile);
            rewrite(h,1);
            printbinary(h,expfile,exprecinfo,t,expselcat,expstartdate,
                        expenddate,false,1);
            close(h)
          end
        else
          begin
            assign(g,expoutfile);
            rewrite(g);
            curmonth := expstartdate;
            while (curmonth < expenddate) do
              begin
                printfile(g,expfile,exprecinfo,t,compcode,expselcat,curmonth,
                          curmonth + expspan,false,1);
                curmonth := curmonth + expspan
              end;
            close(g)
          end
      end;
    if catrequested then
      begin
        getcatinfo(expfile,exprecinfo,t,catselcat,catbegdate,catenddate);
        getbalforward(catfile,catrecinfo,t,catselcat,catbegdate,catstartdate);
        if catbin then
          begin
            assign(h,catoutfile);
            rewrite(h,1);
            printbinary(h,catfile,catrecinfo,t,catselcat,catstartdate,
                        catenddate,true,catincr);
            close(h)
          end
        else
          begin
            assign(g,catoutfile);
            rewrite(g);
            curmonth := catstartdate;
            while (curmonth < catenddate) do
              begin
                printfile(g,catfile,catrecinfo,t,compcode,catselcat,curmonth,
                          curmonth + catspan,true,catincr);
                curmonth := curmonth + catspan
              end;
            close(g)
          end
      end
  end.