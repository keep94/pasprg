program fm;

  uses crt,IOunit,cmp,lgarray,dateacc,group;

  const pagesize = 15;
        maxlencompcode = 10;

  type
    searchenttype = record
      num:word;
      igcase:boolean;
      neg:boolean;
      typeofsearch:word;
      srchstr:string
    end;

    searcharraytype = array[1..maxfields] of searchenttype;

    searchtype = record
      neg:boolean;
      oropt:boolean;
      numentries:word;
      data:searcharraytype
    end;

    sortenttype = record
      num:word;
      order:char;
      igcase:boolean
    end;

    sortarraytype = array[1..maxfields] of sortenttype;

    sorttype = record
      numentries:word;
      data:sortarraytype
    end;

    printarraytype = array[1..maxfields] of word;

    printtype = record
      numentries:word;
      data:printarraytype
    end;

    operstype = array[1..6] of string[2];

    compcodetype = array[0..maxlencompcode-1] of byte;

  var temploaded,escpressed:boolean;
      filename:string;
      choice:word;
      numread:word;
      memavail:longint;
      code:integer;
      done:boolean;
      alldata:dbasetype;
      response:char;
      compcode:compcodetype;
      g:file;

  Function comparefields(x,y:string;typeoffield:char;igcase:boolean):integer;

    begin
      if igcase then
        begin
          caps(x);
          caps(y)
        end;
        case typeoffield of
          'A':comparefields := comparestr(x,y);
          'N':comparefields := comparenumeric(x,y);
          'D':comparefields := comparedates(x,y)
        end
    end;


  Function inentry(var alldata:dbasetype;var sdata:searchenttype;recnum:longint;mode:integer):boolean;

    var fieldnum:word;
        tempreturn:boolean;
        result:integer;
        cptr:^string;

    begin
      fieldnum := sdata.num;
      if fieldnum > alldata.numfields then fieldnum := alldata.numfields
      else if fieldnum = 0 then fieldnum := 1;
      assignptr(pointer(cptr),alldata,recnum,fieldnum,mode);
      if sdata.typeofsearch < 6 then
        begin
          result := comparefields(cptr^,sdata.srchstr,alldata.fields[fieldnum].typeoffield,sdata.igcase);
          case sdata.typeofsearch of
            1:tempreturn := (result = 0);
            2:tempreturn := (result = 1);
            3:tempreturn := (result = -1);
            4:tempreturn := (result <> -1);
            5:tempreturn := (result <> 1)
          end
        end
      else tempreturn := comparewild(sdata.srchstr,cptr^,sdata.igcase);
      tempreturn := tempreturn xor sdata.neg;
      inentry := tempreturn
    end;


  Function insearch(var alldata:dbasetype;var searchkey:searchtype;recnum:longint;mode:integer):boolean;

    var cnt:word;
        found:boolean;

    begin
      cnt := 0;
      found := not searchkey.oropt;
      while (cnt < searchkey.numentries) and (found xor searchkey.oropt) do
        begin
          cnt := cnt + 1;
          if searchkey.oropt then
            found := found or inentry(alldata,searchkey.data[cnt],recnum,mode)
          else
            found := found and inentry(alldata,searchkey.data[cnt],recnum,mode)
        end;
      insearch := found xor searchkey.neg
    end;

  Function comparewithentry(var alldata:dbasetype;var sdata:sortenttype;firstmem,secmem:word):integer;

    var temp:integer;
        fieldnum:word;
        f,s:^string;

    begin
      fieldnum := sdata.num;
      if fieldnum > alldata.numfields then fieldnum := alldata.numfields
      else if fieldnum = 0 then fieldnum := 1;
      lowassignptr(pointer(f),alldata,firstmem,fieldnum);
      lowassignptr(pointer(s),alldata,secmem,fieldnum);
      temp := comparefields(f^,s^,alldata.fields[fieldnum].typeoffield,sdata.igcase);
      if sdata.order = 'D' then temp := temp * -1;
      comparewithentry := temp
    end;


  Function comparerecords(var alldata:dbasetype;var sortkey:sorttype;firstmem,secmem:word):integer;

    var cnt:word;
        temp:integer;

    begin
      temp := 0;
      cnt := 0;
      while (cnt < sortkey.numentries) and (temp = 0) do
        begin
          cnt := cnt + 1;
          temp := comparewithentry(alldata,sortkey.data[cnt],firstmem,secmem)
        end;
      comparerecords := temp
    end;


  Procedure findprevmarked(var alldata:dbasetype;var crecord:longint);

    var count:longint;

    begin
      count := crecord;
      repeat
        if count = 1 then count := alldata.fsize
        else count := count - 1
      until (count = crecord) or ismarked(alldata,count,1);
      crecord := count
    end;

  Procedure findnextmarked(var alldata:dbasetype;var crecord:longint);

    var count:longint;

    begin
      count := crecord;
      repeat
        if count = alldata.fsize then count := 1
        else count := count + 1
      until (count = crecord) or ismarked(alldata,count,1);
      crecord := count
    end;

  Procedure findprev(var alldata:dbasetype;var searchkey:searchtype;var crecord:longint);

    var count:longint;

    begin
      count := crecord;
      repeat
        if count = 1 then count := alldata.fsize
        else count := count - 1
      until (count = crecord) or insearch(alldata,searchkey,count,1);
      crecord := count
    end;

  Procedure findnext(var alldata:dbasetype;var searchkey:searchtype;var crecord:longint);

    var count:longint;

    begin
      count := crecord;
      repeat
        if count = alldata.fsize then count := 1
        else count := count + 1
      until (count = crecord) or insearch(alldata,searchkey,count,1);
      crecord := count
    end;


  Procedure displayrecord(var alldata:dbasetype;crecord:longint;cfield:word);

    var cnt:word;

    begin
      clrscr;
      gotoxy(1,1);
      write('File: ',alldata.dosname);
      gotoxy(45,1);
      write('Record ',crecord,' out of ',alldata.fsize);
      gotoxy(1,3);
      if ismarked(alldata,crecord,1) then writeln('Marked') else writeln;
      for cnt := 1 to alldata.numfields do
        if (cnt <> cfield) then writeln('  ',alldata.fields[cnt].name,': ',getvalue(alldata,crecord,cnt,1))
        else writeln('->',alldata.fields[cnt].name,': ',getvalue(alldata,crecord,cnt,1))
    end;

  Procedure deletemarked(var alldata:dbasetype);

    var p:pointer;
        count:longint;
        numwritten:word;

    begin
      if alldata.fsize <= alldata.maxinmem then
        purge(alldata)
      else
        begin
          assignptr(p,alldata,1,0,1);
          alldata.altered1 := false;
          findondisk(alldata,1,0);
          for count := 1 to alldata.fsize do
            if not ismarked(alldata,count,1) then
              begin
                assignptr(p,alldata,count,0,1);
                blockwrite(alldata.f,p^,alldata.recordsize,numwritten)
              end;
          truncate(alldata.f);
          resetfile(alldata,1)
        end
    end;

  Procedure initsearchkey(var searchkey:searchtype);

    begin
      searchkey.neg := false;
      searchkey.oropt := false;
      searchkey.numentries := 0
    end;

  Procedure initopers(var opers:operstype);

    begin
      opers[1] := 'EQ';
      opers[2] := 'GT';
      opers[3] := 'LT';
      opers[4] := 'GE';
      opers[5] := 'LE';
      opers[6] := 'WI'
    end;

  Procedure displayentry(var sdata:searcharraytype;entrynum:word);

    var opers:operstype;

    begin
      initopers(opers);
      gotoxy(1,entrynum+2);
      write('':80);
      gotoxy(1,entrynum+2);
      write(entrynum);
      gotoxy(4,entrynum+2);
      write(sdata[entrynum].num);
      gotoxy(7,entrynum+2);
      if sdata[entrynum].igcase then write('U');
      gotoxy(9,entrynum+2);
      if sdata[entrynum].neg then write('NOT');
      gotoxy(13,entrynum+2);
      write(opers[sdata[entrynum].typeofsearch]);
      gotoxy(16,entrynum+2);
      write(sdata[entrynum].srchstr)
    end;

  Procedure editentry(var sdata:searcharraytype;entrynum:word;var alldata:dbasetype);

    var opers:operstype;
        cnt:word;
        dv,escpressed:boolean;
        tempstr:string;
        tempnum:word;
        code:integer;

    begin
      initopers(opers);
      repeat
        gotoxy(4,entrynum+2);
        for cnt := 1 to 77 do
          write(' ');
        gotoxy(4,entrynum+2);
        getinput(tempstr,escpressed)
      until not escpressed;
      val(tempstr,tempnum,code);
      sdata[entrynum].num := tempnum;
      gotoxy(4,entrynum+2);
      for cnt := 1 to 77 do
        write(' ');
      gotoxy(4,entrynum+2);
      write(tempnum);
      repeat
        gotoxy(7,entrynum+2);
        for cnt := 1 to 74 do
          write(' ');
        gotoxy(7,entrynum+2);
        getinput(tempstr,escpressed)
      until not escpressed;
      if length(tempstr) > 0 then sdata[entrynum].igcase := (tempstr[1] in ['U','u'])
      else sdata[entrynum].igcase := false;
      gotoxy(7,entrynum+2);
      for cnt := 1 to 74 do
        write(' ');
      gotoxy(7,entrynum+2);
      if sdata[entrynum].igcase then write('U');
      repeat
        gotoxy(9,entrynum+2);
        for cnt := 1 to 72 do
          write(' ');
        gotoxy(9,entrynum+2);
        getinput(tempstr,escpressed)
      until not escpressed;
      if length(tempstr) > 0 then sdata[entrynum].neg := (tempstr[1] in ['N','n'])
      else sdata[entrynum].neg := false;
      gotoxy(9,entrynum+2);
      for cnt := 1 to 72 do
        write(' ');
      gotoxy(9,entrynum+2);
      if sdata[entrynum].neg then write('NOT');
      repeat
        gotoxy(13,entrynum+2);
        for cnt := 1 to 68 do
          write(' ');
        gotoxy(13,entrynum+2);
        getinput(tempstr,escpressed)
      until not escpressed;
      val(tempstr,tempnum,code);
      if (tempnum < 1) or (tempnum > 6) then tempnum := 1;
      sdata[entrynum].typeofsearch := tempnum;
      gotoxy(13,entrynum+2);
      for cnt := 1 to 68 do
        write(' ');
      gotoxy(13,entrynum+2);
      write(opers[tempnum]);
      repeat
        gotoxy(16,entrynum+2);
        for cnt := 1 to 65 do
          write(' ');
        gotoxy(16,entrynum+2);
        getinput(tempstr,escpressed)
      until not escpressed;
      if (alldata.fields[sdata[entrynum].num].typeoffield = 'D') and
      (sdata[entrynum].typeofsearch <> 6) then dateexpand(tempstr,dv);
      sdata[entrynum].srchstr := tempstr;
      gotoxy(16,entrynum+2);
      for cnt := 1 to 65 do
        write(' ');
      gotoxy(16,entrynum+2);
      write(tempstr)
    end;


  Procedure displaysearchkey(var searchkey:searchtype);

    var cnt:word;

    begin
      gotoxy(1,2);
      for cnt := 1 to maxfields+1 do
        write('':80);
      if searchkey.neg then
        begin
          gotoxy(1,2);
          write('NOT')
        end;
      if searchkey.oropt then
        begin
          gotoxy(10,2);
          write('OR')
        end;
      for cnt := 1 to searchkey.numentries do
        displayentry(searchkey.data,cnt);
      gotoxy(1,searchkey.numentries + 3);
      for cnt := searchkey.numentries + 1 to maxfields do
        writeln(cnt);
    end;


  Procedure setupsearchkey(var searchkey:searchtype;var alldata:dbasetype);

    var done,escpressed:boolean;
        choice:string;
        code:integer;
        entrynum,cnt:word;

    begin
      clrscr;
      displaysearchkey(searchkey);
      done := false;
      repeat
        repeat
          gotoxy(1,22);
          write('':80);
          gotoxy(1,22);
          write('Command: ');
          getinput(choice,escpressed)
        until not escpressed;
        caps(choice);
        case choice[1] of
          'A':if searchkey.numentries < maxfields then
                begin
                  searchkey.numentries := searchkey.numentries + 1;
                  editentry(searchkey.data,searchkey.numentries,alldata)
                end;
          'C':begin
                searchkey.numentries := 0;
                searchkey.neg := false;
                searchkey.oropt := false;
                displaysearchkey(searchkey)
              end;
          'E':begin
                val(copy(choice,2,length(choice)-1),entrynum,code);
                if (entrynum <= searchkey.numentries) and (entrynum > 0) then
                  editentry(searchkey.data,entrynum,alldata)
              end;
          'D':begin
                val(copy(choice,2,length(choice)-1),entrynum,code);
                if (entrynum > 0) and (entrynum <= searchkey.numentries) then
                  begin
                    for cnt := entrynum to searchkey.numentries - 1 do
                      searchkey.data[cnt] := searchkey.data[cnt+1];
                    searchkey.numentries := searchkey.numentries - 1;
                    displaysearchkey(searchkey)
                  end
              end;
          'N':begin
                searchkey.neg := not searchkey.neg;
                displaysearchkey(searchkey)
              end;
          'O':begin
                searchkey.oropt := not searchkey.oropt;
                displaysearchkey(searchkey)
              end;
          'Q':done := true
        end
      until done
    end;

  Procedure markmenu(var c:word);

    var temp:string;
        escpressed:boolean;
        code:integer;

    begin
      clrscr;
      gotoxy(1,2);
      write('M A R K   M E N U':48);
      gotoxy(10,4);
      write('1.  AND option');
      gotoxy(10,6);
      write('2.  OR option');
      gotoxy(10,8);
      write('3.  XOR option');
      gotoxy(10,10);
      write('4.  Default option');
      gotoxy(10,12);
      write('5.  Leave menu');
      gotoxy(1,14);
      write('Pick one: ');
      repeat
        getinput(temp,escpressed)
      until not escpressed;
      val(temp,c,code)
    end;


  Procedure markdriver(var alldata:dbasetype;var searchkey:searchtype);

    var count:longint;
        choice:word;
        done,flagged,cmarkstatus,newmarkstatus:boolean;

    begin
      done := false;
      repeat
        markmenu(choice);
        if (choice > 0) and (choice < 5) then
          begin
            for count := 1 to alldata.fsize do
              begin
                flagged := insearch(alldata,searchkey,count,1);
                cmarkstatus := ismarked(alldata,count,1);
                case choice of
                  1:newmarkstatus := cmarkstatus and flagged;
                  2:newmarkstatus := cmarkstatus or flagged;
                  3:newmarkstatus := cmarkstatus xor flagged;
                  4:newmarkstatus := flagged
                end;
                markit(alldata,count,newmarkstatus,1)
              end
          end
        else done := true
      until done
    end;

  Procedure writemarkedrecords(var g:file;var alldata:dbasetype;var diskfilled:boolean;markedonly:boolean);

    var cnt:longint;
        p:pointer;
        numwritten:word;

    begin
      cnt := 0;
      diskfilled := false;
      while (cnt < alldata.fsize) and (not diskfilled) do
        begin
          cnt := cnt + 1;
          if markedonly then
            while (cnt <= alldata.fsize) and (not ismarked(alldata,cnt,1)) do cnt := cnt + 1;
          if cnt <= alldata.fsize then
            begin
              assignptr(p,alldata,cnt,0,1);
              blockwrite(g,p^,alldata.recordsize,numwritten);
              if numwritten < alldata.recordsize then
                diskfilled := true
            end
        end
    end;

  Procedure displaysortentry(var sdata:sortarraytype;entrynum:word);

    begin
      gotoxy(1,entrynum+2);
      write('':80);
      gotoxy(1,entrynum+2);
      write(entrynum);
      gotoxy(4,entrynum+2);
      write(sdata[entrynum].num);
      gotoxy(7,entrynum+2);
      write(sdata[entrynum].order);
      gotoxy(10,entrynum+2);
      if sdata[entrynum].igcase then write('U')
    end;

  Procedure editsortentry(var sdata:sortarraytype;entrynum:word);

    var cnt:word;
        escpressed:boolean;
        tempstr:string;
        tempnum:word;
        code:integer;

    begin
      repeat
        gotoxy(4,entrynum+2);
        for cnt := 1 to 77 do
          write(' ');
        gotoxy(4,entrynum+2);
        getinput(tempstr,escpressed)
      until not escpressed;
      val(tempstr,tempnum,code);
      sdata[entrynum].num := tempnum;
      gotoxy(4,entrynum+2);
      for cnt := 1 to 77 do
        write(' ');
      gotoxy(4,entrynum+2);
      write(tempnum);
      repeat
        gotoxy(7,entrynum+2);
        for cnt := 1 to 74 do
          write(' ');
        gotoxy(7,entrynum+2);
        getinput(tempstr,escpressed)
      until not escpressed;
      caps(tempstr);
      if length(tempstr) > 0 then sdata[entrynum].order := tempstr[1]
      else sdata[entrynum].order := 'A';
      gotoxy(7,entrynum+2);
      for cnt := 1 to 74 do
        write(' ');
      gotoxy(7,entrynum+2);
      write(sdata[entrynum].order);
      repeat
        gotoxy(10,entrynum+2);
        for cnt := 1 to 71 do
          write(' ');
        gotoxy(10,entrynum+2);
        getinput(tempstr,escpressed)
      until not escpressed;
      if length(tempstr) > 0 then sdata[entrynum].igcase := (tempstr[1] in ['U','u'])
      else sdata[entrynum].igcase := false;
      gotoxy(10,entrynum+2);
      for cnt := 1 to 71 do
        write(' ');
      gotoxy(10,entrynum+2);
      if sdata[entrynum].igcase then write('U')
    end;


  Procedure displaysortkey(var sortkey:sorttype);

    var cnt:word;

    begin
      gotoxy(1,2);
      for cnt := 1 to maxfields+1 do
        write('':80);
      for cnt := 1 to sortkey.numentries do
        displaysortentry(sortkey.data,cnt);
      gotoxy(1,sortkey.numentries + 3);
      for cnt := sortkey.numentries + 1 to maxfields do
        writeln(cnt);
    end;


  Procedure setupsortkey(var sortkey:sorttype);

    var done,escpressed:boolean;
        choice:string;
        code:integer;
        entrynum,cnt:word;

    begin
      clrscr;
      displaysortkey(sortkey);
      done := false;
      repeat
        repeat
          gotoxy(1,22);
          write('':80);
          gotoxy(1,22);
          write('Command: ');
          getinput(choice,escpressed)
        until not escpressed;
        caps(choice);
        case choice[1] of
          'A':if sortkey.numentries < maxfields then
                begin
                  sortkey.numentries := sortkey.numentries + 1;
                  editsortentry(sortkey.data,sortkey.numentries)
                end;
          'C':begin
                sortkey.numentries := 0;
                displaysortkey(sortkey)
              end;
          'E':begin
                val(copy(choice,2,length(choice)-1),entrynum,code);
                if (entrynum <= sortkey.numentries) and (entrynum > 0) then
                  editsortentry(sortkey.data,entrynum)
              end;
          'D':begin
                val(copy(choice,2,length(choice)-1),entrynum,code);
                if (entrynum > 0) and (entrynum <= sortkey.numentries) then
                  begin
                    for cnt := entrynum to sortkey.numentries - 1 do
                      sortkey.data[cnt] := sortkey.data[cnt+1];
                    sortkey.numentries := sortkey.numentries - 1;
                    displaysortkey(sortkey)
                  end
              end;
          'Q':done := true
        end
      until done
    end;

  Procedure displayprintentry(var pdata:printarraytype;entrynum:word);

    begin
      gotoxy(1,entrynum+2);
      write('':80);
      gotoxy(1,entrynum+2);
      write(entrynum);
      gotoxy(4,entrynum+2);
      write(pdata[entrynum])
    end;

  Procedure editprintentry(var pdata:printarraytype;entrynum:word);

    var cnt:word;
        escpressed:boolean;
        tempstr:string;
        tempnum:word;
        code:integer;

    begin
      repeat
        gotoxy(4,entrynum+2);
        for cnt := 1 to 77 do
          write(' ');
        gotoxy(4,entrynum+2);
        getinput(tempstr,escpressed)
      until not escpressed;
      val(tempstr,tempnum,code);
      pdata[entrynum] := tempnum;
      gotoxy(4,entrynum+2);
      for cnt := 1 to 77 do
        write(' ');
      gotoxy(4,entrynum+2);
      write(tempnum)
    end;


  Procedure displayprintkey(var printkey:printtype);

    var cnt:word;

    begin
      gotoxy(1,2);
      for cnt := 1 to maxfields+1 do
        write('':80);
      for cnt := 1 to printkey.numentries do
        displayprintentry(printkey.data,cnt);
      gotoxy(1,printkey.numentries + 3);
      for cnt := printkey.numentries + 1 to maxfields do
        writeln(cnt);
    end;


  Procedure setupprintkey(var printkey:printtype);

    var done,escpressed:boolean;
        choice:string;
        code:integer;
        entrynum,cnt:word;

    begin
      clrscr;
      displayprintkey(printkey);
      done := false;
      repeat
        repeat
          gotoxy(1,22);
          write('':80);
          gotoxy(1,22);
          write('Command: ');
          getinput(choice,escpressed)
        until not escpressed;
        caps(choice);
        case choice[1] of
          'A':if printkey.numentries < maxfields then
                begin
                  printkey.numentries := printkey.numentries + 1;
                  editprintentry(printkey.data,printkey.numentries)
                end;
          'C':begin
                printkey.numentries := 0;
                displayprintkey(printkey)
              end;
          'E':begin
                val(copy(choice,2,length(choice)-1),entrynum,code);
                if (entrynum <= printkey.numentries) and (entrynum > 0) then
                  editprintentry(printkey.data,entrynum)
              end;
          'D':begin
                val(copy(choice,2,length(choice)-1),entrynum,code);
                if (entrynum > 0) and (entrynum <= printkey.numentries) then
                  begin
                    for cnt := entrynum to printkey.numentries - 1 do
                      printkey.data[cnt] := printkey.data[cnt+1];
                    printkey.numentries := printkey.numentries - 1;
                    displayprintkey(printkey)
                  end
              end;
          'Q':done := true
        end
      until done
    end;

  Procedure shellsort(var alldata:dbasetype;var sortkey:sorttype;begnum,endnum:integer);

    var cnt,size,incr,posit,newposit,count:integer;
        temp:longint;
        done:boolean;

    begin
      size := endnum-begnum;
      incr := 1;
      while incr < size div 9 do
        incr := incr*3 + 1;
      while incr > 0 do
        begin
          for cnt := begnum to begnum+incr-1 do
	    begin
              posit := cnt + incr;
              while posit <= endnum do
                begin
                  newposit := posit - incr;
                  done := false;
                  while not done do
                    begin
                      if comparerecords(alldata,sortkey,posit,newposit) <> -1 then done := true
                      else newposit := newposit - incr;
                      if newposit < cnt then done := true
                    end;
                  temp := alldata.indexptr^[posit];
                  count := posit - incr;
                  while count >= newposit+incr do
                    begin
                      alldata.indexptr^[count+incr] := alldata.indexptr^[count];
                      count := count - incr
                    end;
                  alldata.indexptr^[newposit+incr] := temp;
                  posit := posit + incr
                end
            end;
          incr := incr div 3
        end
    end;

  Procedure sortfile(var alldata:dbasetype;var sortkey:sorttype);

    var halfinmem,numread,numwritten:word;
        count,oldfileposit,newfileposit,tempoldposit,tempnewposit,cnt:longint;
        divider1,divider2,divider3,ptr1,ptr2:integer;
        p:pointer;
        done1,done2:boolean;

    begin
      if alldata.fsize <= alldata.maxinmem then
        begin
          shellsort(alldata,sortkey,1,alldata.fsize);
          alldata.altered1 := true
        end
      else
        begin
          halfinmem := alldata.maxinmem div 2;
          assignptr(p,alldata,1,0,1);
          shellsort(alldata,sortkey,1,alldata.maxinmem);
          alldata.altered1 := true;
          closefile(alldata);
          count := alldata.maxinmem+1;
          while (count <= alldata.fsize) do
            begin
              oldfileposit := count;
              newfileposit := oldfileposit + halfinmem;
              if newfileposit > alldata.fsize + 1 then newfileposit := alldata.fsize+1;
              count := newfileposit;
              findondisk(alldata,oldfileposit,0);
              for cnt := oldfileposit to newfileposit - 1 do
                begin
                  lowassignptr(p,alldata,cnt-oldfileposit+1,0);
                  blockread(alldata.f,p^,alldata.recordsize,numread)
                end;
              divider2 := newfileposit - oldfileposit;
              shellsort(alldata,sortkey,1,divider2);
              done1 := false;
              while not done1 do
                begin
                  tempoldposit := oldfileposit - alldata.maxinmem + divider2;
                  if tempoldposit < 1 then
                    begin
                      done1 := true;
                      tempoldposit := 1
                    end;
                  findondisk(alldata,tempoldposit,0);
                  for cnt := tempoldposit to oldfileposit - 1 do
                    begin
                      lowassignptr(p,alldata,cnt - tempoldposit + divider2 +1,0);
                      blockread(alldata.f,p^,alldata.recordsize,numread)
                    end;
                  divider3 := divider2 + oldfileposit - tempoldposit;
                  oldfileposit := tempoldposit;
                  cnt := 1;
                  done2 := false;
                  while (not done2) do
                    begin
                      if cnt > divider2 then done2 := true
                      else
                        begin
                          if comparerecords(alldata,sortkey,cnt,divider2+1) = 1 then done2 := true
                          else cnt := cnt + 1
                        end
                    end;
                  divider1 := cnt - 1;
                  ptr1 := divider1 + 1;
                  ptr2 := divider2 + 1;
                  tempnewposit := newfileposit - divider3 + divider1;
                  findondisk(alldata,tempnewposit,0);
                  while (ptr1 <= divider2) and (ptr2 <= divider3) do
                    begin
                      if comparerecords(alldata,sortkey,ptr1,ptr2) = 1 then
                        begin
                          lowassignptr(p,alldata,ptr2,0);
                          blockwrite(alldata.f,p^,alldata.recordsize,numwritten);
                          ptr2 := ptr2 + 1
                        end
                      else
                        begin
                          lowassignptr(p,alldata,ptr1,0);
                          blockwrite(alldata.f,p^,alldata.recordsize,numwritten);
                          ptr1 := ptr1 + 1
                        end
                    end;
                  if ptr1 > divider2 then
                    while (ptr2 <= divider3) do
                      begin
                        lowassignptr(p,alldata,ptr2,0);
                        blockwrite(alldata.f,p^,alldata.recordsize,numwritten);
                        ptr2 := ptr2 + 1
                      end
                  else if ptr2 > divider3 then
                    while (ptr1 <= divider2) do
                      begin
                        lowassignptr(p,alldata,ptr1,0);
                        blockwrite(alldata.f,p^,alldata.recordsize,numwritten);
                        ptr1 := ptr1 + 1
                      end;
                  newfileposit := tempnewposit;
                  divider2 := divider1;
                  if divider2 = 0 then done1 := true
                end;
              findondisk(alldata,1,0);
              for cnt := 1 to divider2 do
                begin
                  lowassignptr(p,alldata,cnt,0);
                  blockwrite(alldata.f,p^,alldata.recordsize,numwritten)
                end
            end;
          resetfile(alldata,1)
        end
    end;


  Procedure binarysearch(var alldata:dbasetype;fieldnum:word;keystr:string;igcase:boolean;var recnum:longint;
                         var found:boolean);

    var str1,str2,tempstr:string;
        first,last,mid:longint;


    begin
      if fieldnum < 1 then fieldnum := 1
      else if fieldnum > alldata.numfields then fieldnum := alldata.numfields;
      str1 := getvalue(alldata,1,fieldnum,0);
      str2 := getvalue(alldata,alldata.fsize,fieldnum,0);
      if comparefields(str1,str2,alldata.fields[fieldnum].typeoffield,igcase) = 1 then
        begin
          last := 1;
          first := alldata.fsize;
          tempstr := str1;
          str1 := str2;
          str2 := tempstr
        end
      else
        begin
          first := 1;
          last := alldata.fsize
        end;
      if comparefields(keystr,str1,alldata.fields[fieldnum].typeoffield,igcase) = 0 then
        begin
          recnum := first;
          found := true
        end
      else if comparefields(keystr,str2,alldata.fields[fieldnum].typeoffield,igcase) = 0 then
        begin
          recnum := last;
          found := true
        end
      else if comparefields(keystr,str1,alldata.fields[fieldnum].typeoffield,igcase) = -1 then
        begin
          recnum := first;
          found := false
        end
      else if comparefields(keystr,str2,alldata.fields[fieldnum].typeoffield,igcase) = 1 then
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
              if comparefields(keystr,getvalue(alldata,mid,fieldnum,0),alldata.fields[fieldnum].typeoffield,igcase) = 0 then
                begin
                  recnum := mid;
                  found := true
                end
              else if comparefields(keystr,getvalue(alldata,mid,fieldnum,0),
              alldata.fields[fieldnum].typeoffield,igcase) = 1 then
                first := mid
              else if comparefields(keystr,getvalue(alldata,mid,fieldnum,0),
              alldata.fields[fieldnum].typeoffield,igcase) = -1 then
                last := mid
            end;
          if not found then recnum := last
        end
    end;

  Procedure printrecord(var g:text;var alldata:dbasetype;var printkey:printtype;recnum:longint);

    var temp:string;
        count,cnt,fieldnum:word;

    begin
      for count := 1 to printkey.numentries do
        begin
          fieldnum := printkey.data[count];
          if fieldnum < 1 then fieldnum := 1
          else if fieldnum > alldata.numfields then fieldnum := alldata.numfields;
          temp := getvalue(alldata,recnum,fieldnum,1);
          if alldata.fields[fieldnum].typeoffield = 'N' then
            begin
              for cnt := 1 to fieldsize(alldata,fieldnum) - length(temp) - 1 do
                write(g,' ');
              write(g,temp)
            end
          else
            begin
              write(g,temp);
              for cnt := 1 to fieldsize(alldata,fieldnum) - length(temp) - 1 do
                write(g,' ')
            end;
          if count <> printkey.numentries then write(g,' ')
        end;
      writeln(g)
    end;

  Procedure printpage(var g:text;pageno:word;var alldata:dbasetype;var printkey:printtype;var recnum:longint;
                      markedonly:boolean;var done:boolean);

    var cnt,cnt1,count,lineno,fieldnum:word;
        temp:string;
        dummy:char;

    begin
      for cnt := 1 to 3 do writeln(g);
      for cnt := 1 to 60 do write(g,' ');
      writeln(g,'Page: ',pageno);
      writeln(g);
      for cnt := 1 to printkey.numentries do
        begin
          fieldnum := printkey.data[cnt];
          if fieldnum < 1 then fieldnum := 1
          else if fieldnum > alldata.numfields then fieldnum := alldata.numfields;
          temp := alldata.fields[fieldnum].name;
          temp := copy(temp,1,fieldsize(alldata,fieldnum)-1);
          write(g,temp);
          for cnt1 := 1 to fieldsize(alldata,fieldnum)-length(temp)-1 do
            write(g,' ');
          if cnt <> printkey.numentries then write(g,' ')
        end;
      writeln(g);
      for count := 1 to printkey.numentries do
        begin
          fieldnum := printkey.data[count];
          if fieldnum < 1 then fieldnum := 1
          else if fieldnum > alldata.numfields then fieldnum := alldata.numfields;
          for cnt := 1 to fieldsize(alldata,fieldnum) - 1 do
            write(g,'-');
          if count <> printkey.numentries then write(g,' ')
        end;
      writeln(g);
      lineno := 1;
      while (lineno <= 51) and (recnum <= alldata.fsize) and (not done) do
        begin
          if markedonly then
            while (recnum <= alldata.fsize) and (not ismarked(alldata,recnum,1)) do
              recnum := recnum + 1;
          if recnum <= alldata.fsize then
            begin
              printrecord(g,alldata,printkey,recnum);
              recnum := recnum + 1;
              lineno := lineno + 1
            end;
          if keypressed then
            begin
              dummy := readkey;
              if dummy = chr(27) then done := true
              else if dummy = chr(0) then dummy := readkey
            end
        end;
      for cnt := 1 to 60-lineno do writeln(g)
    end;

Procedure printfile(var g:text;var alldata:dbasetype;var printkey:printtype;markedonly:boolean;
compressed:boolean;var compcode:compcodetype);

var recnum:longint;
pageno:word;
done:boolean;
cnt:word;

begin
      if compressed then
        for cnt := 1 to compcode[0] do write(g,chr(compcode[cnt]));
      recnum := 1;
      pageno := 1;
      done := false;
      while (recnum <= alldata.fsize) and (not done) do
        begin
          printpage(g,pageno,alldata,printkey,recnum,markedonly,done);
          pageno := pageno + 1
        end;
      if compressed then
        for cnt := compcode[0]+2 to compcode[0]+compcode[compcode[0]+1]+1 do
          write(g,chr(compcode[cnt]))
    end;

Procedure adjustwidth(var alldata:dbasetype);

var count:longint;
fieldnum:word;
p:^byte;

begin
for count := 1 to alldata.fsize do
for fieldnum := 1 to alldata.numfields do
begin
 assignptr(pointer(p),alldata,count,fieldnum,1);
 if p^ > fieldsize(alldata,fieldnum) - 1 then
  begin
   p^ := fieldsize(alldata,fieldnum) - 1;
   alldata.altered1 := true
  end
 end
end;

  Procedure printlabels(var g:text;var alldata:dbasetype;markedonly:boolean;labelsize:word);

var recnum:longint;
dummy:char;
linesprinted,cnt:integer;
done:boolean;
p:^string;

    begin
      recnum := 1;
      done := false;
      while (recnum <= alldata.fsize) and (not done) do
        begin
          if markedonly then
            while (recnum <= alldata.fsize) and (not ismarked(alldata,recnum,1)) do
              recnum := recnum + 1;
          if recnum <= alldata.fsize then
            begin
              linesprinted := 2;
              assignptr(pointer(p),alldata,recnum,3,1);
              if p^ <> '' then writeln(g,p^)
              else begin
              assignptr(pointer(p),alldata,recnum,2,1);
              if p^ <> '' then
                write(g,p^+' ');
              assignptr(pointer(p),alldata,recnum,1,1);
              writeln(g,p^)
end;
              assignptr(pointer(p),alldata,recnum,4,1);
              if p^ <> '' then
                begin
                  writeln(g,p^);
                  linesprinted := linesprinted+1
                end;
              assignptr(pointer(p),alldata,recnum,5,1);
              if p^ <> '' then
                begin
                  writeln(g,p^);
                  linesprinted := linesprinted + 1
                end;
              assignptr(pointer(p),alldata,recnum,6,1);
              write(g,p^+', ');
              assignptr(pointer(p),alldata,recnum,7,1);
              write(g,p^+'  ');
              assignptr(pointer(p),alldata,recnum,8,1);
              writeln(g,p^);
              for cnt := 1 to labelsize - linesprinted do
                writeln(g);
              recnum := recnum + 1;
              if keypressed then
                begin
                  dummy := readkey;
                  if dummy = chr(27) then done := true
                  else if dummy = chr(0) then dummy := readkey
                end
            end
        end
    end;

Procedure fillfield(var alldata:dbasetype;fieldnum:word;fieldval:string;markedonly:boolean);

var cnt:longint;

begin
for cnt := 1 to alldata.fsize do
if (ismarked(alldata,cnt,1)) or (not markedonly) then
 assignvalue(alldata,cnt,fieldnum,fieldval,1)
end;

Procedure totaloffield(var alldata:dbasetype;fieldnum:word;markedonly:boolean;var total:real;var num:longint);

var cnt:longint;
x:real;
code:integer;

begin
total := 0.0;
num := 0;
for cnt := 1 to alldata.fsize do
 if (ismarked(alldata,cnt,1)) or (not markedonly) then
  begin
   val(getvalue(alldata,cnt,fieldnum,1),x,code);
   total := total + x;
   num := num + 1
  end
end;

Procedure countfield(var alldata:dbasetype;fieldnum:word;start,incr:real;decpl:integer;markedonly:boolean);

var cnt:longint;
fieldval:string;

begin
for cnt := 1 to alldata.fsize do
 if (ismarked(alldata,cnt,1)) or (not markedonly) then
  begin
   str(start:0:decpl,fieldval);
   assignvalue(alldata,cnt,fieldnum,fieldval,1);
   start := start + incr
  end
end;


  Procedure editfile(var alldata:dbasetype;var compcode:compcodetype);

    var ctrlcodes,scancodes:settype;
        crecord,numberfound:longint;
        grpfilename,temp,filename,markstr:string;
        choice,schoice,response:char;
        datevalid,escpressed,done,found,diskfilled,pmarked,markedonly,compressed,fileerror:boolean;
        code,error:integer;
        cfield,fieldnum,labelsize,whatfield,decpl:word;
        searchkey:searchtype;
        sortkey:sorttype;
        printkey:printtype;
        g:text;
        h:file;
        start,incr,total:real;
        groupdata:grouptype;
        p:memberptrtype;

    begin
      grpfilename := '';
      if alldata.fsize = 0 then exit;
      searchkey.numentries := 0;
      searchkey.neg := false;
      searchkey.oropt := false;
      sortkey.numentries := 0;
      printkey.numentries := 0;
      ctrlcodes := [1,3,7,9,11,12,14,16,17,21,23,26];
      scancodes := [59..68,72,73,75,77,80,81];
      crecord := 1;
      cfield := 1;
      done := false;
      repeat
        if alldata.fsize = 0 then
          begin
            close(alldata.f);
            exit
          end;
        displayrecord(alldata,crecord,cfield);
        gotoxy(1,23);
        write('Field ',cfield,': ');
        returninput(temp,choice,schoice,ctrlcodes,scancodes);
        if choice = chr(13) then
          begin
            if alldata.fields[cfield].typeoffield = 'D' then
              dateexpand(temp,datevalid);
            assignvalue(alldata,crecord,cfield,temp,1);
            if cfield = alldata.numfields then cfield := 1
            else cfield := cfield + 1
          end
        else
        case choice of
          chr(1):begin
                   appendrecord(alldata);
                   crecord := alldata.fsize;
                   cfield := 1
                 end;
          chr(3):if grpfilename <> '' then begin
                   assignptr(pointer(p),alldata,crecord,0,1);
                   showmembership(p,groupdata)
                 end;
          chr(7):begin
                   clrscr;
                   gotoxy(1,12);
                   write('Go to record number? ');
                   getinput(temp,escpressed);
                   if not escpressed then
                     begin
                       val(temp,crecord,code);
                       if crecord < 1 then crecord := 1
                       else if crecord > alldata.fsize then crecord := alldata.fsize
                     end
                 end;
          chr(9):findnextmarked(alldata,crecord);
          chr(11):findprev(alldata,searchkey,crecord);
          chr(12):findnext(alldata,searchkey,crecord);
          chr(14):markit(alldata,crecord,not ismarked(alldata,crecord,1),1);
          chr(16):begin
                    clrscr;
                    gotoxy(1,10);
                    write('Send output to what file? ');
                    getinput(filename,escpressed);
                    if not escpressed then
                      begin
                        gotoxy(1,12);
                        write('Print marked records only<y,n>? ');
                        getinput(temp,escpressed);
                        if not escpressed then
                          begin
                            if length(temp) > 0 then pmarked := (temp[1] in ['Y','y'])
                            else pmarked := false;
                            gotoxy(1,14);
                            write('Print in compressed mode<y,n>? ');
                            getinput(temp,escpressed);
                            if not escpressed then
                              begin
                                if length(temp) > 0 then compressed := (temp[1] in ['Y','y'])
                                else compressed := false;
                                assign(g,filename);
                                {$I-}
                                  rewrite(g);
                                {$I+}
                                error := IOresult;
                                if error = 0 then
                                  begin
                                    gotoxy(1,16);
                                    write('Press ESC to stop printing.');
                                    printfile(g,alldata,printkey,pmarked,compressed,compcode);
                                    close(g)
                                  end
                                else
                                  begin
                                    gotoxy(1,16);
                                    usermessage('File creation error.')
                                  end
                              end
                          end
                      end
                  end;
          chr(17):begin
                    schoice := readkey;
                    if schoice in ['R','r','C','c','T','t'] then
                      case schoice of
                        'R','r':begin
                                  clrscr;
                                  gotoxy(1,10);
                                  write('Enter field number: ');
                                  getinput(temp,escpressed);
                                  if not escpressed then
                                    begin
                                      val(temp,whatfield,code);
                                      if whatfield < 1 then whatfield := 1
                                      else if whatfield > alldata.numfields then whatfield := alldata.numfields;
                                      gotoxy(1,12);
                                      write('Change field value to: ');
                                      getinput(temp,escpressed);
                                      if alldata.fields[whatfield].typeoffield = 'D' then
                                        dateexpand(temp,datevalid);
                                      if not escpressed then
                                        begin
                                          gotoxy(1,14);
                                          write('Change marked records only<y,n>? ');
                                          getinput(markstr,escpressed);
                                          if not escpressed then
                                            begin
                                              if length(markstr) > 0 then markedonly := (markstr[1] in ['Y','y'])
                                              else markedonly := false;
                                              fillfield(alldata,whatfield,temp,markedonly)
                                            end
                                        end
                                    end
                                end;
                        'C','c':begin
                                  clrscr;
                                  gotoxy(1,8);
                                  write('Enter field number: ');
                                  getinput(temp,escpressed);
                                  if not escpressed then
                                    begin
                                      val(temp,whatfield,code);
                                      if whatfield < 1 then whatfield := 1
                                      else if whatfield > alldata.numfields then whatfield := alldata.numfields;
                                      gotoxy(1,10);
                                      write('Enter starting field value: ');
                                      getinput(temp,escpressed);
                                      if alldata.fields[whatfield].typeoffield <> 'N' then
                                        begin
                                          writeln;
                                          writeln;
                                          write('This operation can only be used on numeric fields.  Press any key.');
                                          pause;
                                          escpressed := true
                                        end;
                                      if not escpressed then
                                        begin
                                          val(temp,start,code);
                                          gotoxy(1,12);
                                          write('Enter incriment: ');
                                          getinput(temp,escpressed);
                                          if not escpressed then
                                            begin
                                              val(temp,incr,code);
                                              gotoxy(1,14);
                                              write('Number of decimal places: ');
                                              getinput(temp,escpressed);
                                              if not escpressed then
                                                begin
                                                  val(temp,decpl,code);
                                                  if decpl > 12 then decpl := 12;
                                                  gotoxy(1,16);
                                                  write('Change marked records only<y,n>? ');
                                                  getinput(temp,escpressed);
                                                  if not escpressed then
                                                    begin
                                                      if length(temp) > 0 then markedonly := (temp[1] in ['Y','y'])
                                                      else markedonly := false;
                                                      countfield(alldata,whatfield,start,incr,decpl,markedonly)
                                                    end
                                                end
                                            end
                                        end
                                    end
                                end;
                        'T','t':begin
                                  clrscr;
                                  gotoxy(1,9);
                                  write('Enter field number: ');
                                  getinput(temp,escpressed);
                                  if not escpressed then
                                    begin
                                      val(temp,whatfield,code);
                                      if whatfield < 1 then whatfield := 1
                                      else if whatfield > alldata.numfields then whatfield := alldata.numfields;
                                      gotoxy(1,11);
                                      write('Total marked records only<y,n>? ');
                                      getinput(markstr,escpressed);
                                      if not escpressed then
                                        begin
                                          if length(markstr) > 0 then markedonly := (markstr[1] in ['Y','y'])
                                          else markedonly := false;
                                          totaloffield(alldata,whatfield,markedonly,total,numberfound);
                                          gotoxy(1,13);
                                          write('Records totalled: ',numberfound);
                                          gotoxy(1,15);
                                          write('Total: ',total:0:6);
                                          pause
                                        end
                                    end
                                end
                      end
                  end;
          chr(21):findprevmarked(alldata,crecord);
          chr(23):adjustwidth(alldata);
          chr(26):begin
                    clrscr;
                    if alldata.numfields < 8 then
                      begin
                        gotoxy(1,12);
                        usermessage('Not enough fields defined to print an address label.')
                      end
                    else
                      begin
                        gotoxy(1,10);
                        write('Send output to what file? ');
                        getinput(filename,escpressed);
                        if not escpressed then
                          begin
                            gotoxy(1,12);
                            write('Print marked records only<y,n>? ');
                            getinput(temp,escpressed);
                            if not escpressed then
                              begin
                                if length(temp) > 0 then pmarked := (temp[1] in ['Y','y'])
                                else pmarked := false;
                                gotoxy(1,14);
                                write('Number of lines per label: ');
                                getinput(temp,escpressed);
                                if not escpressed then
                                  begin
                                    val(temp,labelsize,code);
                                    assign(g,filename);
                                    {$I-}
                                      rewrite(g);
                                    {$I+}
                                    error := IOresult;
                                    if error = 0 then
                                      begin
                                        gotoxy(1,16);
                                        write('Press ESC to stop printing.');
                                        printlabels(g,alldata,pmarked,labelsize);
                                        close(g)
                                      end
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
          chr(0):case schoice of
                   chr(59):maindriver(groupdata,alldata,crecord,grpfilename);
                   chr(60):setupsearchkey(searchkey,alldata);
                   chr(61):markdriver(alldata,searchkey);
                   chr(62):setupsortkey(sortkey);
                   chr(63):begin
                             clrscr;
                             gotoxy(1,12);
                             write('Sort records<y,n>? ');
                             readln(response);
                             if response in ['Y','y'] then
                               begin
                                 sortfile(alldata,sortkey);
                                 crecord := 1
                               end
                           end;
                   chr(64):begin
                             clrscr;
                             gotoxy(1,10);
                             write('Enter field number: ');
                             getinput(temp,escpressed);
                             if not escpressed then
                               begin
                                 val(temp,fieldnum,code);
                                 gotoxy(1,12);
                                 write('Search for? ');
                                 getinput(temp,escpressed);
                                 if alldata.fields[fieldnum].typeoffield = 'D' then dateexpand(temp,datevalid);
                                 if not escpressed then
                                   begin
                                     gotoxy(1,14);
                                     write('Ignore case<y,n>? ');
                                     readln(response);
                                     binarysearch(alldata,fieldnum,temp,response in ['Y','y'],crecord,found)
                                   end
                               end
                           end;
                   chr(65):begin
                             clrscr;
                             gotoxy(1,10);
                             write('Name of file to hold marked records: ');
                             getinput(filename,escpressed);
                             if not escpressed then
                               begin
                                 gotoxy(1,12);
                                 write('Write marked records only<y,n>? ');
                                 getinput(temp,escpressed);
                                 if not escpressed then
                                   begin
                                     if length(temp) > 0 then markedonly := temp[1] in ['Y','y']
                                     else markedonly := false;
                                     response := 'N';
                                     if fileexists(filename) then
                                       begin
                                         gotoxy(1,14);
                                         write('That file already exists.  Append instead of overwrite<y,n>? ');
                                         getinput(temp,escpressed);
                                         if length(temp) > 0 then response := temp[1]
                                         else response := 'N';
                                       end;
                                     if not escpressed then
                                       begin
                                         if response in ['N','n'] then
                                           begin
                                             if filecreation(filename) then
                                               begin
                                                 assign(h,filename);
                                                 rewrite(h,1);
                                                 fileerror := false;
                                               end
                                             else
                                               begin
                                                 gotoxy(1,16);
                                                 usermessage('File creation error.');
                                                 fileerror := true
                                               end
                                           end
                                         else
                                           begin
                                             if filevalid(filename,alldata.recordsize) then
                                               begin
                                                 assign(h,filename);
                                                 reset(h,1);
                                                 seek(h,filesize(h));
                                                 fileerror := false
                                               end
                                             else
                                               begin
                                                 gotoxy(1,16);
                                                 usermessage('Records are not compatible.');
                                                 fileerror := true
                                               end
                                           end;
                                         if not fileerror then
                                           begin
                                             writemarkedrecords(h,alldata,diskfilled,markedonly);
                                             if diskfilled then
                                               begin
                                                 gotoxy(1,16);
                                                 usermessage('Insufficient disk space.')
                                               end;
                                             close(h)
                                           end
                                       end
                                   end
                               end
                           end;
                   chr(66):begin
                             clrscr;
                             gotoxy(1,12);
                             write('Delete marked records<y,n>? ');
                             readln(response);
                             if response in ['Y','y'] then
                               begin
                                 deletemarked(alldata);
                                 crecord := 1
                               end
                           end;
                   chr(67):setupprintkey(printkey);
                   chr(68):begin
                             done := true;
                             if grpfilename <> '' then savegroup(groupdata,grpfilename)
                           end;
                   chr(72):if cfield = 1 then cfield := alldata.numfields
                           else cfield := cfield - 1;
                   chr(73):if crecord > pagesize then crecord := crecord - pagesize
                           else crecord := 1;
                   chr(75):if crecord > 1 then crecord := crecord - 1;
                   chr(77):if crecord < alldata.fsize then crecord := crecord + 1;
                   chr(80):if cfield = alldata.numfields then cfield := 1
                           else cfield := cfield + 1;
                   chr(81):if crecord+pagesize <= alldata.fsize then crecord := crecord + pagesize
                           else crecord := alldata.fsize
                 end
        end
      until done;
      closefile(alldata);
      close(alldata.f)
    end;



  Procedure mainmenu(var c:word);

    var temp:string;
        escpressed:boolean;
        code:integer;

    begin
      clrscr;
      gotoxy(1,2);
      write('M A I N   M E N U':48);
      gotoxy(10,4);
      write('1.  Get a template');
      gotoxy(10,6);
      write('2.  Open a file');
      gotoxy(10,8);
      write('3.  Quit');
      gotoxy(1,10);
      write('Pick one: ');
      getinput(temp,escpressed);
      val(temp,c,code)
    end;

  begin
     if not fileexists('compcode.dat') then
       begin
         writeln('Cannot find COMPCODE.DAT');
         exit
       end;
     assign(g,'compcode.dat');
     reset(g,1);
     blockread(g,compcode,maxlencompcode,numread);
     close(g);
     if paramstr(1) <> '' then
      val(paramstr(1),memavail,code)
    else
      memavail := 64000;
    temploaded := false;
    done := false;
    repeat
      mainmenu(choice);
      case choice of
        1:begin
            clrscr;
            gotoxy(1,12);
            write('Get template from what file? ');
            getinput(filename,escpressed);
            if not escpressed then
              begin
                if fileexists(filename) then
                  begin
                    if temploaded then resetlgarray(alldata);
                    initfields(alldata,filename);
                    temploaded := true;
                    initlgarray(alldata,memavail)
                  end
                else
                  begin
                    gotoxy(1,14);
                    usermessage('Cannot find that file.')
                  end
              end
          end;
        2:begin
            if temploaded then
              begin
                clrscr;
                gotoxy(1,10);
                write('Open what file? ');
                getinput(filename,escpressed);
                if not escpressed then
                  begin
                    if not fileexists(filename) then
                      begin
                        gotoxy(1,12);
                        write('Cannot find that file.  Create a new one<y,n>? ');
                        readln(response);
                        if response in ['Y','y'] then
                          begin
                            if filecreation(filename) then
                              createnewfile(filename)
                            else
                              begin
                                gotoxy(1,14);
                                usermessage('File creation error.')
                              end
                          end
                      end;
                    if fileexists(filename) then
                      begin
                        if filevalid(filename,alldata.recordsize) then
                          begin
                            initfile(alldata,filename);
                            if alldata.fsize = 0 then appendrecord(alldata);
                            editfile(alldata,compcode)
                          end
                        else
                          begin
                            gotoxy(1,12);
                            usermessage('File does not correspond to template.')
                          end
                      end
                  end
              end
            else
              begin
                clrscr;
                gotoxy(1,12);
                usermessage('A template has not been loaded.')
              end
          end;
        3:begin
            if temploaded then resetlgarray(alldata);
            done := true
          end
      end
    until done
  end.