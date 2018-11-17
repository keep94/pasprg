Program config;

  uses crt,IOunit;

  type
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
      data:array[1..2000] of linetype
    end;

    recptrtype = ^rectype;

    itemtype=record
      oldfieldnum:integer;
      name:string[20];
      price:real;
      taxable:boolean;
      cat:integer
    end;

    invtype = record
      maxnfield:integer;
      taxrate:real;
      oldnfield:integer;
      nfield:integer;
      ncat:integer;
      data:array[1..2000] of itemtype
    end;

    invptrtype = ^invtype;

  var
    choice,schoice,response:char;
    oldfile,newfile,temp:string;
    invptr:invptrtype;
    fieldno,code,source,dest,posit,size,maxsize:integer;
    done,escpressed:boolean;


  Function invlen(fieldamt:word):word;

    begin
      invlen := 32*fieldamt + 14
    end;

  Function reclen(fieldamt:word):word;

    begin
      reclen := 13*fieldamt + 39
    end;

  Procedure prevscrn(invptr:invptrtype;var fieldno:integer);

    begin
      fieldno := fieldno - 15;
      if fieldno < 1 then fieldno := 1
    end;

  Procedure nextscrn(invptr:invptrtype;var fieldno:integer);

    begin
      fieldno := fieldno + 15;
      if fieldno > invptr^.nfield then fieldno := invptr^.nfield
    end;


  Procedure loadfields(invptr:invptrtype;filename:string);

    var f:text;
        tax,x:real;
        numfields,numdept,cnt,y,z:integer;

    begin
      assign(f,filename);
      reset(f);
      readln(f,invptr^.taxrate);
      readln(f,invptr^.oldnfield);
      invptr^.nfield := invptr^.oldnfield;
      readln(f,invptr^.ncat);
      if invptr^.nfield > invptr^.maxnfield then invptr^.nfield := invptr^.maxnfield;
      for cnt := 1 to invptr^.nfield do
        begin
          invptr^.data[cnt].oldfieldnum := cnt;
          readln(f,invptr^.data[cnt].name);
          readln(f,x,y,z);
          invptr^.data[cnt].price := x;
          invptr^.data[cnt].taxable := (y <> 0);
          invptr^.data[cnt].cat := z
        end;
      close(f)
    end;

  Procedure displayplu(invptr:invptrtype;var fieldno:integer);

    var cnt,cnt1:integer;

    begin
      if fieldno < 1 then fieldno := 1
      else if fieldno > invptr^.nfield then fieldno := invptr^.nfield;
      clrscr;
      gotoxy(1,3);
      writeln('PLU# Description          Price      Taxable Dept. No');
      writeln('---- -------------------- ---------- ------- --------');
      for cnt := 15*((fieldno - 1) div 15) + 1 to 15*((fieldno - 1) div 15) + 15 do
        if (cnt <= invptr^.nfield) then
          begin
            write(cnt:4);
            write(' ');
            write(invptr^.data[cnt].name);
            for cnt1 := 1 to 20 - length(invptr^.data[cnt].name) do write(' ');
            write(invptr^.data[cnt].price:11:2);
            if invptr^.data[cnt].taxable then write(' YES    ')
            else write(' NO     ');
            writeln(invptr^.data[cnt].cat:9)
          end
        else writeln
    end;

  Procedure edititem(invptr:invptrtype;posit:integer;isold:boolean);

    var temp:string;
        code:integer;

    begin
      if not isold then
        begin
          invptr^.data[posit].name := '';
          invptr^.data[posit].price := 0.0;
          invptr^.data[posit].taxable := false;
          invptr^.data[posit].cat := 0
        end;
      clrscr;
      gotoxy(1,6);
      write('For PLU #',posit);
      gotoxy(1,8);
      write('Description: ');
      if isold then
        begin
          gotoxy(1,9);
          write('[ENTER] : ',invptr^.data[posit].name)
        end;
      gotoxy(14,8);
      readln(temp);
      if temp <> '' then invptr^.data[posit].name := temp;
      gotoxy(1,11);
      write('Price: ');
      if isold then
        begin
          gotoxy(1,12);
          write('[ENTER] : ',invptr^.data[posit].price:0:2)
        end;
      gotoxy(8,11);
      readln(temp);
      if temp <> '' then val(temp,invptr^.data[posit].price,code);
      gotoxy(1,14);
      write('Taxable<y,n>? ');
      if isold then
        begin
          gotoxy(1,15);
          write('[ENTER] : ');
          if invptr^.data[posit].taxable then write('YES') else write('NO')
        end;
      gotoxy(15,14);
      readln(temp);
      if temp <> '' then invptr^.data[posit].taxable := not (temp[1] in ['N','n']);
      gotoxy(1,17);
      write('Dept. No: ');
      if isold then
        begin
          gotoxy(1,18);
          write('[ENTER] : ',invptr^.data[posit].cat)
        end;
      gotoxy(11,17);
      readln(temp);
      if temp <> '' then val(temp,invptr^.data[posit].cat,code)
    end;

  Procedure editheading(invptr:invptrtype);

    var temp:string;
        code:integer;

    begin
      clrscr;
      gotoxy(1,10);
      write('Taxrate: ');
      gotoxy(1,11);
      write('[ENTER] : ',invptr^.taxrate:0:4);
      gotoxy(10,10);
      readln(temp);
      if temp <> '' then val(temp,invptr^.taxrate,code);
      gotoxy(1,13);
      write('Number of Departments: ');
      gotoxy(1,14);
      write('[ENTER] : ',invptr^.ncat);
      gotoxy(24,13);
      readln(temp);
      if temp <> '' then val(temp,invptr^.ncat,code);
    end;


  Procedure moveitem(invptr:invptrtype;source,dest:integer);

    var cnt:integer;
        temp:itemtype;

    begin
      if dest > source then
        begin
          temp := invptr^.data[source];
          for cnt := source to dest - 1 do
            invptr^.data[cnt] := invptr^.data[cnt+1];
          invptr^.data[dest] := temp
        end
      else if dest < source then
        begin
          temp := invptr^.data[source];
          for cnt := source downto dest + 1 do
            invptr^.data[cnt] := invptr^.data[cnt-1];
          invptr^.data[dest] := temp
        end
    end;

  Procedure insertitem(invptr:invptrtype;posit:integer);

    var cnt:integer;

    begin
      for cnt := invptr^.nfield downto posit do
        invptr^.data[cnt+1] := invptr^.data[cnt];
      invptr^.nfield := invptr^.nfield + 1;
      invptr^.data[posit].oldfieldnum := 0;
      edititem(invptr,posit,false)
    end;

  Procedure deleteitem(invptr:invptrtype;posit:integer);

    var cnt:integer;

    begin
      for cnt := posit to invptr^.nfield - 1 do
        invptr^.data[cnt] := invptr^.data[cnt + 1];
      invptr^.nfield := invptr^.nfield - 1
    end;

  Procedure savefields(invptr:invptrtype;filename:string);

    var f:text;
        tax:real;
        numfields,numdept,cnt:integer;

    begin
      assign(f,filename);
      rewrite(f);
      writeln(f,invptr^.taxrate:0:4);
      writeln(f,invptr^.nfield);
      writeln(f,invptr^.ncat);
      for cnt := 1 to invptr^.nfield do
        begin
          writeln(f,invptr^.data[cnt].name);
          write(f,invptr^.data[cnt].price:0:2,' ');
          if invptr^.data[cnt].taxable then write(f,'1 ')
          else write(f,'0 ');
          writeln(f,invptr^.data[cnt].cat)
        end;
      close(f)
    end;


  Procedure alter(invptr:invptrtype;oldfile,newfile:string);

    var f,g:file;
        oldrecptr,newrecptr:recptrtype;
        cnt,cnt1,sourcefield:integer;
        numread,numwritten:word;

    begin
      getmem(oldrecptr,reclen(invptr^.oldnfield));
      getmem(newrecptr,reclen(invptr^.nfield));
      assign(f,oldfile);
      assign(g,newfile);
      reset(f,1);
      rewrite(g,1);
      while not eof(f) do
        begin
          blockread(f,oldrecptr^,reclen(invptr^.oldnfield),numread);
          newrecptr^.marked := oldrecptr^.marked;
          newrecptr^.date := oldrecptr^.date;
          newrecptr^.taxrate := oldrecptr^.taxrate;
          for cnt := 1 to 5 do
            newrecptr^.totals[cnt] := oldrecptr^.totals[cnt];
          for cnt := 1 to invptr^.nfield do
            begin
              if invptr^.data[cnt].oldfieldnum = 0 then
                begin
                  newrecptr^.data[cnt].price := invptr^.data[cnt].price;
                  newrecptr^.data[cnt].taxable := invptr^.data[cnt].taxable;
                  for cnt1 := 1 to 3 do newrecptr^.data[cnt].col[cnt1] := 0
                end
              else
                begin
                  sourcefield := invptr^.data[cnt].oldfieldnum;
                  newrecptr^.data[cnt].price := oldrecptr^.data[sourcefield].price;
                  newrecptr^.data[cnt].taxable := oldrecptr^.data[sourcefield].taxable;
                  for cnt1 := 1 to 3 do newrecptr^.data[cnt].col[cnt1] := oldrecptr^.data[sourcefield].col[cnt1]
                end
            end;
          blockwrite(g,newrecptr^,reclen(invptr^.nfield),numwritten)
        end;
      close(f);
      close(g);
      freemem(oldrecptr,reclen(invptr^.oldnfield));
      freemem(newrecptr,reclen(invptr^.nfield))
    end;

  begin
    if paramstr(1) <> '' then
      val(paramstr(1),maxsize,code)
    else
      maxsize := 2000;
    if (maxsize < 1) or (maxsize > 2000) then maxsize := 2000;
    clrscr;
    getmem(invptr,invlen(maxsize));
    invptr^.maxnfield := maxsize;
    invptr^.oldnfield := 0;
    invptr^.nfield := 0;
    invptr^.taxrate := 0.0;
    invptr^.ncat := 0;
    fieldno := 1;
    done := false;
    repeat
      displayplu(invptr,fieldno);
      choice := readkey;
      case choice of
        chr(1):if invptr^.nfield < invptr^.maxnfield then
                 begin
                   size := invptr^.nfield;
                   insertitem(invptr,size + 1);
                   fieldno := invptr^.nfield
                 end;
        chr(2):editheading(invptr);
        chr(3):if (invptr^.nfield > 0) and (invptr^.oldnfield > 0) then
                begin
                 clrscr;
                 gotoxy(1,10);
                 write('Change configuration of what file? ');
                 getinput(temp,escpressed);
                 if not escpressed then
                   begin
                     if not fileexists(temp) then
                       begin
                         gotoxy(1,12);
                         write(chr(7)+'Cannot find that file.');
                         pause
                       end
                     else
                       begin
                         if not filevalid(temp,reclen(invptr^.oldnfield)) then
                           begin
                             gotoxy(1,12);
                             write(chr(7)+'That file does not correspond to template.');
                             pause
                           end
                         else
                           begin
                             oldfile := temp;
                             gotoxy(1,12);
                             write('Write new file to? ');
                             getinput(temp,escpressed);
                             if not escpressed then
                               begin
                                 if not filecreation(temp) then
                                   begin
                                     gotoxy(1,14);
                                     write(chr(7)+'File creation error.');
                                     pause
                                   end
                                 else
                                   begin
                                     newfile := temp;
                                     alter(invptr,oldfile,newfile)
                                   end
                               end
                           end
                       end
                   end
               end;
        chr(4):if invptr^.nfield > 0 then
                 begin
                   clrscr;
                   gotoxy(1,12);
                   write('Delete what PLU #: ');
                   getinput(temp,escpressed);
                   if not escpressed then
                     begin
                       val(temp,posit,code);
                       if (posit < 1) then posit := 1
                       else if (posit > invptr^.nfield) then posit := invptr^.nfield;
                       deleteitem(invptr,posit);
                       fieldno := posit;
                       if fieldno > invptr^.nfield then fieldno := invptr^.nfield;
                       if fieldno < 1 then fieldno := 1
                     end
                 end;
        chr(5):begin
                 clrscr;
                 gotoxy(1,12);
                 write('Edit what PLU #: ');
                 getinput(temp,escpressed);
                 if not escpressed then
                   begin
                     val(temp,posit,code);
                     if (posit < 1) then posit := 1
                     else if (posit > invptr^.nfield) then posit := invptr^.nfield;
                     edititem(invptr,posit,true);
                     fieldno := posit
                   end
               end;
        chr(9):if invptr^.nfield < invptr^.maxnfield then
                 begin
                   clrscr;
                   gotoxy(1,12);
                   write('Insert at what PLU #: ');
                   getinput(temp,escpressed);
                   if not escpressed then
                     begin
                       val(temp,posit,code);
                       if (posit < 1) then posit := 1
                       else if (posit > invptr^.nfield + 1) then posit := invptr^.nfield + 1;
                       insertitem(invptr,posit);
                       fieldno := posit
                     end
                 end;
       chr(12):begin
                 clrscr;
                 gotoxy(1,12);
                 write('Get item info from what file? ');
                 getinput(temp,escpressed);
                 if not fileexists(temp) then
                   begin
                     gotoxy(1,14);
                     write(chr(7)+'Cannot find that file.');
                     pause
                   end
                 else
                   begin
                     loadfields(invptr,temp);
                     fieldno := 1;
                   end
               end;
       chr(16):if invptr^.nfield > 1 then
                 begin
                   clrscr;
                   gotoxy(1,11);
                   write('Move item from PLU #: ');
                   getinput(temp,escpressed);
                   if not escpressed then
                     begin
                       val(temp,source,code);
                       if (source < 1) then source := 1
                       else if (source > invptr^.nfield) then source := invptr^.nfield;
                       gotoxy(1,13);
                       write('To PLU #: ');
                       getinput(temp,escpressed);
                       if not escpressed then
                         begin
                           val(temp,dest,code);
                           if (dest < 1) then dest := 1
                           else if (dest > invptr^.nfield) then dest := invptr^.nfield;
                           moveitem(invptr,source,dest);
                           fieldno := dest
                         end
                     end
                 end;
       chr(19):begin
                 clrscr;
                 gotoxy(1,10);
                 write('Save item info to? ');
                 getinput(temp,escpressed);
                 if not escpressed then
                   begin
                     response := 'Y';
                     if fileexists(temp) then
                       begin
                         gotoxy(1,12);
                         write('That file already exists.  Overwrite<y,n>? ');
                         readln(response)
                       end;
                     if response in ['Y','y'] then
                       begin
                         if not filecreation(temp) then
                           begin
                             gotoxy(1,12);
                             write(chr(7)+'File creation error.');
                             pause
                           end
                         else
                           savefields(invptr,temp)
                       end
                   end
               end;
        chr(0):begin
                 schoice := readkey;
                 case schoice of
                   chr(45):done := true;
                   chr(72):prevscrn(invptr,fieldno);
                   chr(80):nextscrn(invptr,fieldno)
                 end
               end
      end
    until done;
    size := invptr^.maxnfield;
    freemem(invptr,invlen(size))
  end.