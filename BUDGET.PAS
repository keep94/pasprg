program budget;

  uses crt,dos;

  type
    fieldtype=record
      posit:integer;
      whattype:integer;
      scol:integer;
      slength:integer
    end;

    fieldarraytype=array[1..5] of fieldtype;

    formattype=record
      fieldnum:integer;
      accessnum:integer;
      entrysize:integer;
      heading:string;
      fields:fieldarraytype
    end;

  datatype=array[0..32767] of byte;

  ptrtype=^node;

  node=record
    next:ptrtype;
    back:ptrtype;
    list:ptrtype;
    listsize:integer;
    isblock:boolean;
    hidden:boolean;
    data:datatype
  end;



  dirlink=^node1;

    node1=record
      next:dirlink;
      dirinfo:string[12]
    end;

  cursortype=record
    linenum:integer;
    entry:ptrtype
  end;

  blocktype=record
    first:cursortype;
    last:cursortype;
    list:^ptrtype;
     scr:boolean;
  end;

  totaltype=record
    tmoneyalloc:real;
    tmoneyspent:real;
    toldbal:real;
    tnewbal:real;
    init:real;
    remain:real
  end;

  settype = set of char;

  var totals:totaltype;
      beginning:ptrtype;
      cursorpos:cursortype;
      row,column,lx,ly:integer;
      entryformat,listformat:formattype;
      readyquit,coutb:boolean;
      choice,schoice,response:char;
      x,filename,mask:string;
      letters:settype;
      block:blocktype;


  Procedure getformat(var e:formattype);

    var cnt:integer;

    begin
      e.fieldnum := 5;
      e.accessnum := 5;
      e.entrysize := 55;
      e.fields[1].posit := 0;
      e.fields[1].whattype := 3;
      e.fields[1].scol := 5;
      e.fields[1].slength := 14;
      e.fields[2].posit := 15;
      e.fields[2].whattype := 4;
      e.fields[2].scol := 19;
      e.fields[2].slength := 14;
      e.fields[3].posit := 21;
      e.fields[3].whattype := 4;
      e.fields[3].scol := 33;
      e.fields[3].slength := 14;
      e.fields[4].posit := 27;
      e.fields[4].whattype := 4;
      e.fields[4].scol := 47;
      e.fields[4].slength := 14;
      e.fields[5].posit := 33;
      e.fields[5].whattype := 4;
      e.fields[5].scol := 61;
      e.fields[5].slength := 14;
      with e do
        begin
          heading := '';
          for cnt := 1 to 4 do heading := heading + ' ';
          for cnt := 1 to 9 do heading := heading + ' ';
          heading := heading + 'Entry';
          for cnt := 1 to 3 do heading := heading + ' ';
          heading := heading + 'Money alloc';
          for cnt := 1 to 3 do heading := heading + ' ';
          heading := heading + 'Money Spent';
          for cnt := 1 to 3 do heading := heading + ' ';
          heading := heading + 'Old Balance';
          for cnt := 1 to 3 do heading := heading + ' ';
          heading := heading + 'New Balance'
        end
    end;

  Procedure getlistformat(var l:formattype);

    var cnt:integer;

    begin
      l.fieldnum := 4;
      l.accessnum := 4;
      l.entrysize := 79;
      l.fields[1].posit := 0;
      l.fields[1].whattype := 3;
      l.fields[1].scol := 5;
      l.fields[1].slength := 18;
      l.fields[2].posit := 19;
      l.fields[2].whattype := 3;
      l.fields[2].scol := 23;
      l.fields[2].slength := 18;
      l.fields[3].posit := 38;
      l.fields[3].whattype := 3;
      l.fields[3].scol := 41;
      l.fields[3].slength := 18;
      l.fields[4].posit := 57;
      l.fields[4].whattype := 4;
      l.fields[4].scol := 59;
      l.fields[4].slength := 18;
      with l do
        begin
          heading := '';
          for cnt := 1 to 4 do heading := heading + ' ';
          for cnt := 1 to 11 do heading := heading + ' ';
          heading := heading + 'Check #';
          for cnt := 1 to 14 do heading := heading + ' ';
          heading := heading + 'Date';
          for cnt := 1 to 14 do heading := heading + ' ';
          heading := heading + 'Name';
          for cnt := 1 to 14 do heading := heading + ' ';
          heading := heading + 'Cost'
        end
    end;

  Procedure instructions;

    var dummy:char;

    begin
      clrscr;
      textcolor(15);
      write('I N S T R U C T I O N S':51);
      gotoxy(1,4);
      writeln('-- Main Spreadsheet File Commands --  -- Main Spreadsheet Commands --');
      writeln;
      textcolor(7);
      writeln('   F2 : Save file                        F4 : Edit worksheet of cursor category');
      writeln('   F3 : Get file                         F5 : Change initial balance');
      writeln('   F6 : Erase file                       F9 : Clear all memory');
      writeln('   F7 : Start new month');
      writeln('   F8 : List directory');
      writeln('   ^E : Quit');
      writeln;
      textcolor(15);
      writeln('-- Edit Commands --                   -- Worksheet Commands --');
      writeln;
      textcolor(7);
      writeln('   '+chr(24)+chr(25)+chr(26)+chr(27)+' : Move cursor                    F9 : Clear worksheet');
      writeln('  PG UP : Move up a screen              F10 : Go back to main spreadsheet');
      writeln('  PG DN : Move down a screen');
      writeln('     ^Y : Delete cursor line');
      writeln('     ^N : Insert line above cursor');
      writeln('    Del : Clear what is highlighted');
      writeln;
      gotoxy(1,23);
      textcolor(15);
      writeln('Press any key to continue.');
      dummy := readkey;
      if dummy = chr(0) then dummy := readkey;
      clrscr;
      write('I N S T R U C T I O N S (cont.)':59);
      gotoxy(1,4);
      writeln('-- Block Commands --');
      writeln;
      textcolor(7);
      writeln('   ^KB : Mark beginning');
      writeln('   ^KK : Mark end');
      writeln('   ^KV : Move block');
      writeln('   ^KC : Copy block');
      writeln('   ^KS : Hide block');
      writeln('   ^KR : Reveal block');
      writeln('   ^KH : Turn off display');
      gotoxy(1,23);
      textcolor(15);
      write('Press any key to continue.');
      dummy := readkey;
      if dummy=chr(0) then dummy := readkey;
      textcolor(7);
      clrscr
    end;

  Procedure Displaymessage(x:string;var lx,ly:integer);

    begin
      lx := wherex;
      ly := wherey;
      gotoxy(1,16);
      write(x)
    end;

  Procedure clearmessage(lx,ly:integer);

    begin
      gotoxy(1,16);
      write('':80);
      gotoxy(lx,ly)
    end;

  Procedure displaycommand(x:string;var lx,ly:integer);

    begin
      lx := wherex;
      ly := wherey;
      gotoxy(1,1);
      write(x)
    end;

  Procedure clearcommand(lx,ly:integer);

  begin
    gotoxy(1,1);
    write('':80);
    gotoxy(lx,ly)
  end;

  Procedure Usermessage(x:string);

    var lx,ly:integer;
        dummy:char;

    begin
      displaymessage(x,lx,ly);
      dummy := readkey;
      if dummy = chr(0) then dummy := readkey;
      clearmessage(lx,ly)
    end;

  Function getreal(var entry:node;column:integer;var entryformat:formattype):real;

    var temp:real;
        code:integer;

    begin
      with entryformat.fields[column] do
        case whattype of
          3:begin
              val(string((@entry.data[posit])^),temp,code);
              getreal := temp
            end;
          4:getreal := real((@entry.data[posit])^)
        end
    end;

  Procedure assignreal(x:real;var entry:node;column:integer;var entryformat:formattype);

    var temp:string;

    begin
      with entryformat.fields[column] do
        case whattype of
          3:begin
              str(x:0:2,temp);
              string((@entry.data[posit])^) := copy(temp,1,slength)
            end;
          4:real((@entry.data[posit])^) := x
        end
    end;


  Function getstring(var entry:node;column:integer;var entryformat:formattype):string;

    var temp:string;

    begin
      with entryformat.fields[column] do
        case whattype of
          3:getstring := copy(string((@entry.data[posit])^),1,slength);
          4:begin
              str(real((@entry.data[posit])^):0:2,temp);
              getstring := copy(temp,1,slength)
            end
        end
    end;

  Procedure assignstring(x:string;var entry:node;column:integer;var entryformat:formattype);

    var code:integer;

    begin
      with entryformat.fields[column] do
        case whattype of
          3:string((@entry.data[posit])^) := copy(x,1,slength);
          4:val(x,real((@entry.data[posit])^),code)
        end
    end;

  Procedure initblock(var block:blocktype);

    begin
      block.first.entry := nil;
      block.last.entry := nil
    end;


  Procedure inittotals(var totals:totaltype);

    begin
      totals.tmoneyalloc := 0.0;
      totals.tmoneyspent := 0.0;
      totals.toldbal := 0.0;
      totals.tnewbal := 0.0;
      totals.remain := 0.0
    end;


  Procedure displaytotals(totals:totaltype);


    begin
      with totals do
        begin
          gotoxy(5,18);
          write('':76);
          gotoxy(5,19);
          write('':76);
          gotoxy(5,20);
          write('':76);
          gotoxy(5,18);
          write('Total money allocated: ',tmoneyalloc:0:2);
          gotoxy(9,19);
          write('Total money spent: ',tmoneyspent:0:2);
          gotoxy(12,20);
          write('Initial amount: ',init:0:2);
          gotoxy(45,18);
          write('Total old balance: ',toldbal:0:2);
          gotoxy(45,19);
          write('Total new balance: ',tnewbal:0:2);
          gotoxy(46,20);
          write('Amount Remaining: ',remain:0:2);
        end
    end;

  Procedure clearline(var entry:node;var entryformat:formattype);

    var cnt:integer;

    begin
      for cnt := 1 to entryformat.fieldnum do
        with entryformat.fields[cnt] do
          case whattype of
            3:assignstring('',entry,cnt,entryformat);
            4:assignreal(0.0,entry,cnt,entryformat)
          end
    end;

  Procedure Getnewline(var p:ptrtype;var entryformat:formattype;h,b:boolean);

    begin
      getmem(p,entryformat.entrysize);
      clearline(p^,entryformat);
      p^.next := nil;
      p^.back := nil;
      p^.list := nil;
      p^.listsize := 0;
      p^.hidden := h;
      p^.isblock := b
    end;

  Procedure highlight(row,column,size:integer);

    var p:^datatype;
        offset:integer;
        cnt:integer;

    begin
      p := ptr($b800,$0);
      offset := (row-1)*80+column-1;
      for cnt := offset to offset+size-1 do
        if p^[2*cnt+1]<16 then
          begin
            if p^[2*cnt+1]=8 then p^[2*cnt+1] := 120
            else if p^[2*cnt+1]>7 then p^[2*cnt+1] := 17*p^[2*cnt+1]-128
                 else p^[2*cnt+1] := 16*p^[2*cnt+1]
          end
    end;

  Procedure unhighlight(row,column,size:integer);

    var p:^datatype;
        offset:integer;
        cnt:integer;

    begin
      p := ptr($b800,$0);
      offset := (row-1)*80+column-1;
      for cnt := offset to offset+size-1 do
        if p^[2*cnt+1] > 15 then
          begin
            if p^[2*cnt+1] = 120 then p^[2*cnt+1] := 8
            else if p^[2*cnt+1] mod 16 = 0 then p^[2*cnt+1] := p^[2*cnt+1] div 16
                 else p^[2*cnt+1] := (p^[2*cnt+1] + 128) div 17
          end
      end;


  Procedure initialize(var beginning:ptrtype;var cursorpos:cursortype;var row,column:integer;var letters:settype;
                       var ready:boolean;var entryformat:formattype);

    begin
      getnewline(beginning,entryformat,false,false);
      cursorpos.entry := beginning;
      cursorpos.linenum := 1;
      row := 3;
      column := 1;
      letters := [' '..chr(126)];
      ready := false;
    end;



  Procedure getinput(var x:string;c:char);

    begin
      write(c);
      x := '';
      x := x + c;
      repeat
        c := readkey;
        if c = chr(0) then c := readkey
        else if c = chr(8) then
          begin
            if length(x)<>0 then
              begin
                gotoxy(wherex-1,wherey);
                write(' ');
                gotoxy(wherex-1,wherey);
                x := copy(x,1,length(x)-1)
              end
          end
             else if c<>chr(13) then
                    begin
                      if (wherex<80) then
                        begin
                          x := x + c;
                          write(c)
                        end
                    end
      until c=chr(13)
    end;


  Procedure displayline(var entry:node;row:integer;var entryformat:formattype);

    var cnt,color:integer;

    begin
      if (entry.hidden) and (entry.isblock) then color := 4
      else if (entry.hidden) then color := 8
           else if (entry.isblock) then color := 12
                else color := 7;
      textcolor(color);
      for cnt := 1 to entryformat.fieldnum do
        begin
          gotoxy(entryformat.fields[cnt].scol,row);
          with entryformat.fields[cnt] do
            write(getstring(entry,cnt,entryformat):slength)
        end;
      textcolor(7)
   end;


  Procedure displayscreen(cursorpos:cursortype;var row:integer;column:integer;var entryformat:formattype);

    var p:ptrtype;
        cnt:integer;


    begin
      for cnt := 2 to 14 do
        begin
          gotoxy(1,cnt);
          write('':80)
        end;
      textcolor(0);
      textbackground(7);
      gotoxy(1,2);
      write(entryformat.heading);
      textcolor(7);
      textbackground(0);
      gotoxy(1,22);
      writeln('Press F1 for help.');
      if row>cursorpos.linenum+2 then row := cursorpos.linenum+2;
      p := cursorpos.entry;
      for cnt := row downto 4 do p := p^.back;
      for cnt := 3 to 14 do
        begin
          gotoxy(1,cnt);
          textcolor(0);
          textbackground(7);
          write(cursorpos.linenum-row+cnt:4);
          textcolor(7);
          textbackground(0);
          if p<>nil then
            begin
              displayline(p^,cnt,entryformat);
              p := p^.next
            end;
        end;
      highlight(row,entryformat.fields[column].scol,entryformat.fields[column].slength);
    end;

  Procedure backwd(var cursorpos:cursortype;var row:integer;column:integer;var entryformat:formattype);


    begin
      if cursorpos.linenum > 1 then
        begin
          cursorpos.entry := cursorpos.entry^.back;
          cursorpos.linenum := cursorpos.linenum - 1;
          if row = 3 then
            displayscreen(cursorpos,row,column,entryformat)
          else
            with entryformat.fields[column] do
              begin
                unhighlight(row,scol,slength);
                row := row - 1;
                highlight(row,scol,slength)
              end
        end
    end;

  Procedure left(row:integer;var column:integer;var entryformat:formattype);

    begin
      with entryformat.fields[column] do
        unhighlight(row,scol,slength);
      if column = 1 then column := entryformat.accessnum
        else column := column - 1;
      with entryformat.fields[column] do
        highlight(row,scol,slength)
    end;

  Procedure right(row:integer;var column:integer;var entryformat:formattype);

    begin
      with entryformat.fields[column] do
        unhighlight(row,scol,slength);
      if column = entryformat.accessnum then column := 1
        else column := column + 1;
      with entryformat.fields[column] do
        highlight(row,scol,slength)
    end;

  Procedure forwd(var cursorpos:cursortype;var row:integer;column:integer;var entryformat:formattype);

    var p:ptrtype;


    begin
      if cursorpos.entry^.next = nil then
        begin
          getnewline(p,entryformat,false,false);
          p^.back := cursorpos.entry;
          cursorpos.entry^.next := p;
          if row < 14 then
            displayline(p^,row+1,entryformat)
        end;
      cursorpos.entry := cursorpos.entry^.next;
      cursorpos.linenum := cursorpos.linenum + 1;
      if row = 14 then
        displayscreen(cursorpos,row,column,entryformat)
      else
        with entryformat.fields[column] do
          begin
            unhighlight(row,scol,slength);
            row := row + 1;
            highlight(row,scol,slength)
          end
    end;

  Procedure Pageup(var cursorpos:cursortype;var row:integer;column:integer;var entryformat:formattype);

    var cnt:integer;

    begin
      cnt := 0;
      while (cnt<11) and (cursorpos.linenum>1) do
        begin
          cursorpos.linenum := cursorpos.linenum-1;
          cursorpos.entry := cursorpos.entry^.back;
          cnt := cnt + 1
        end;
      displayscreen(cursorpos,row,column,entryformat)
    end;

  Procedure pagedown(var cursorpos:cursortype;var row:integer;column:integer;var entryformat:formattype);

    var cnt:integer;

    begin
      cnt :=0;
      while (cnt<11) and (cursorpos.entry^.next<>nil) do
        begin
          cursorpos.linenum := cursorpos.linenum + 1;
          cursorpos.entry := cursorpos.entry^.next;
          cnt := cnt + 1
        end;
      displayscreen(cursorpos,row,column,entryformat)
    end;

  Function nullblock(var block:blocktype):boolean;

    begin
      if (block.first.entry = nil)
      and (block.last.entry = nil)
       then nullblock := true
      else nullblock := false
    end;

  Procedure insertentry(var beginning:ptrtype;var cursorpos:cursortype;var entryformat:formattype;var block:blocktype);

    var q:ptrtype;

    begin
      if not nullblock(block) then
        if (block.list = addr(beginning)) then
          begin
            if (cursorpos.linenum<=block.first.linenum) then
              begin
                block.first.linenum := block.first.linenum + 1;
                block.last.linenum := block.last.linenum + 1
              end
            else if (cursorpos.linenum>block.first.linenum) and
                    (cursorpos.linenum<=block.last.linenum) then
            block.last.linenum := block.last.linenum + 1
          end;
      if cursorpos.entry^.back = nil then
        begin
          getnewline(q,entryformat,false,false);
          q^.next := cursorpos.entry;
          cursorpos.entry^.back := q;
          beginning := q
        end
      else
        begin
          if (cursorpos.entry^.isblock) and (cursorpos.entry^.back^.isblock) then
            getnewline(q,entryformat,false,true)
          else getnewline(q,entryformat,false,false);
          cursorpos.entry^.back^.next := q;
          q^.back := cursorpos.entry^.back;
          q^.next := cursorpos.entry;
          cursorpos.entry^.back := q
        end;
      cursorpos.entry := q
    end;

  Procedure deleteentry(var beginning:ptrtype;var cursorpos:cursortype;
           var row:integer;var entryformat:formattype;var block:blocktype);

    var q:ptrtype;

    begin
      if cursorpos.entry^.list <> nil then
        usermessage('Worksheet is not empty.  Press any key to continue.')
      else
        begin
          if not nullblock(block) then
            if (block.list = addr(beginning)) then
              begin
                if (cursorpos.linenum=block.first.linenum) and
                   (block.first.linenum=block.last.linenum) then
                     initblock(block)
                else if (cursorpos.linenum<block.first.linenum) then
                  begin
                    block.first.linenum := block.first.linenum - 1;
                    block.last.linenum := block.last.linenum - 1
                  end
                else if (cursorpos.linenum=block.first.linenum) then
                  begin
                    block.first.entry := block.first.entry^.next;
                    block.last.linenum := block.last.linenum - 1
                  end
                else if (cursorpos.linenum>block.first.linenum) and
                        (cursorpos.linenum<block.last.linenum) then
                  block.last.linenum := block.last.linenum - 1
                else if (cursorpos.linenum=block.last.linenum) then
                  begin
                    block.last.entry := block.last.entry^.back;
                    block.last.linenum := block.last.linenum - 1
                  end
              end;
          if cursorpos.entry^.next = nil then
            begin
              if cursorpos.linenum=1 then
                begin
                  clearline(cursorpos.entry^,entryformat);
                  cursorpos.entry^.hidden := false;
                  cursorpos.entry^.isblock := false
                end
              else
                begin
                  q := cursorpos.entry;
                  cursorpos.entry := cursorpos.entry^.back;
                  cursorpos.entry^.next := nil;
                  cursorpos.linenum := cursorpos.linenum-1;
                  if row>3 then row := row - 1;
                  freemem(q,entryformat.entrysize)
                end
            end
          else
            begin
              q := cursorpos.entry;
              cursorpos.entry := cursorpos.entry^.next;
              if cursorpos.entry^.back^.back = nil then
                begin
                  cursorpos.entry^.back := nil;
                  beginning := cursorpos.entry;
                  freemem(q,entryformat.entrysize)
                end
              else
                begin
                  q^.back^.next := cursorpos.entry;
                  cursorpos.entry^.back := q^.back;
                  freemem(q,entryformat.entrysize)
                end
            end
        end
    end;


  Procedure updateline(var entry:node;var entryformat:formattype);

    var newbal:real;

    begin
      newbal := getreal(entry,4,entryformat)+getreal(entry,2,entryformat)-getreal(entry,3,entryformat);
      assignreal(newbal,entry,5,entryformat)
    end;

  Procedure updatetotals(beginning:ptrtype;var totals:totaltype;var entryformat:formattype);

    var p:ptrtype;

    begin
      inittotals(totals);
      p := beginning;
      with totals do
        while p<>nil do
          begin
            if not p^.hidden then
              begin
                tmoneyalloc := tmoneyalloc + getreal(p^,2,entryformat);
                tmoneyspent := tmoneyspent + getreal(p^,3,entryformat);
                toldbal := toldbal + getreal(p^,4,entryformat);
                tnewbal := tnewbal + getreal(p^,5,entryformat)
              end;
            p := p^.next
          end;
      with totals do
        remain := init - tmoneyspent;
    end;

   Procedure clearlist(var beginning:ptrtype;var listformat:formattype;var block:blocktype);

    var p,q:ptrtype;

    begin
      p := beginning;
      while p<>nil do
        begin
          q := p^.next;
          freemem(p,listformat.entrysize);
          p := q
        end;
      beginning := nil;
      if block.list = addr(beginning) then initblock(block)
    end;

  Procedure clearentries(var beginning:ptrtype;var entryformat,listformat:formattype;var block:blocktype);

    var p,q:ptrtype;

    begin
      p := beginning;
      while p<>nil do
        begin
          q := p^.next;
          clearlist(p^.list,listformat,block);
          freemem(p,entryformat.entrysize);
          p := q
        end;
      beginning := nil;
      initblock(block)
    end;

  Procedure getoldbal(var x:real);

    var oldbal:string;
        code:integer;

    begin
      displaymessage('Enter initial balance: ',lx,ly);
      readln(oldbal);
      val(oldbal,x,code);
      clearmessage(lx,ly)
    end;



  Function notblock(x1,x2:pointer;first,last:cursortype):boolean;

    begin
      if x1<>x2 then notblock := true
      else if first.linenum>last.linenum then notblock := true
           else notblock := false
    end;

  Procedure highblock(block:blocktype);

 {Pre conditions:  block is a valid block.
  Post conditions:  entries are higlighted specified by boundries by block.
  Exceptional cases: block is an invalid block.
  }

    var p:ptrtype;

    begin
      p := block.first.entry;
      while (p<>block.last.entry) do
        begin
          p^.isblock := true;
          p := p^.next
        end;
      block.last.entry^.isblock := true
    end;

  Procedure unhighblock(block:blocktype);

 {Pre conditions:  block is a valid block.
  Post conditions:  contents of block are unhighlighted.
  Exceptional cases:  block is not a valid block.
  }

    var p:ptrtype;

    begin
      p := block.first.entry;
      while (p<>block.last.entry) do
        begin
          p^.isblock := false;
          p := p^.next
        end;
      block.last.entry^.isblock := false
    end;


  Procedure markbeg(var block:blocktype;cursorpos:cursortype;listadr:pointer;whatscreen:boolean);

    begin
      if nullblock(block) then
        begin
          block.first := cursorpos;
          block.last := cursorpos;
          block.list := listadr;
          block.scr := whatscreen;
          cursorpos.entry^.isblock := true
        end
      else
        begin
          unhighblock(block);
          if notblock(listadr,block.list,cursorpos,block.last) then
            begin
              block.first := cursorpos;
              block.last := cursorpos;
              block.list := listadr;
              block.scr := whatscreen
            end
          else
            block.first := cursorpos;
          highblock(block)
        end
    end;

  Procedure markend(var block:blocktype;cursorpos:cursortype;listadr:pointer;whatscreen:boolean);

    begin
      if nullblock(block) then
        begin
          block.first := cursorpos;
          block.last := cursorpos;
          block.list := listadr;
          block.scr := whatscreen;
          cursorpos.entry^.isblock := true
        end
      else
        begin
          unhighblock(block);
          if notblock(listadr,block.list,block.first,cursorpos) then
            begin
              block.first := cursorpos;
              block.last := cursorpos;
              block.list := listadr;
              block.scr := whatscreen
            end
          else
            block.last := cursorpos;
          highblock(block)
        end
    end;

    Procedure updatelistinfo(var entry:node;var entryformat,listformat:formattype);

      var p:ptrtype;
          cnt:integer;
          tcost:real;

      begin
        p := entry.list;
        cnt := 0;
        tcost := 0.0;
        while (p<>nil) do
          begin
            if not p^.hidden then tcost := tcost + getreal(p^,4,listformat);
            cnt := cnt + 1;
            p := p^.next
          end;
        entry.listsize := cnt;
        assignreal(tcost,entry,3,entryformat)
      end;

  Procedure popblock(var block:blocktype;var beginning:ptrtype;
    var cursorpos:cursortype;var entryformat,listformat:formattype);

 {Pre conditions:  block is a valid block.
  Post conditions:  block is removed and beginning and cursorpos are
                    changed if necessary.
  Exceptional cases:  none.
  }

    var s,o:word;
        blocksize:integer;
        p:ptrtype;

    begin
      if (block.first.entry^.back=nil)
      and (block.last.entry^.next=nil) then
        block.list^ := nil
      else if (block.first.entry^.back=nil) then
        begin
          block.last.entry^.next^.back := nil;
          block.list^ := block.last.entry^.next
        end
      else if (block.last.entry^.next = nil) then
        block.first.entry^.back^.next := nil
      else
        begin
          block.first.entry^.back^.next := block.last.entry^.next;
          block.last.entry^.next^.back := block.first.entry^.back
        end;
      if (block.list = addr(beginning)) then
        if cursorpos.linenum>block.last.linenum then
          begin
            blocksize := block.last.linenum - block.first.linenum + 1;
            cursorpos.linenum := cursorpos.linenum - blocksize
          end;
      if block.scr then
        begin
          o := ofs(block.list^);
          s := seg(block.list^);
          p := ptr(s,o-8);
          updatelistinfo(p^,entryformat,listformat);
          updateline(p^,entryformat)
        end
    end;


  Procedure moveblock(var block:blocktype;var beginning:ptrtype;var cursorpos:cursortype);


 {Pre conditions:  block is a valid block.
  Post conditions:  area defined by block is inserted below cursor.
  Exceptional cases:  block is not a valid block.
  }

    var sizeblock:integer;

    begin
      if (cursorpos.entry^.back = nil) then
        begin
          block.first.entry^.back := nil;
          block.last.entry^.next := cursorpos.entry;
          cursorpos.entry^.back := block.last.entry;
          beginning := block.first.entry;
        end
      else
        begin
          cursorpos.entry^.back^.next := block.first.entry;
          block.first.entry^.back := cursorpos.entry^.back;
          block.last.entry^.next := cursorpos.entry;
          cursorpos.entry^.back := block.last.entry
        end;
      cursorpos.entry := block.first.entry;
      sizeblock := block.last.linenum - block.first.linenum;
      block.first.linenum := cursorpos.linenum;
      block.last.linenum := cursorpos.linenum + sizeblock;
      block.list := addr(beginning);
    end;

  Procedure copyblock(var block:blocktype;var entryformat:formattype);

 {Pre conditions:  block is a valid block.
  Post conditions:  the block denoted by block is copied and then
                    block is set to the new copied block.
  Exceptional cases:  block is not a valid block.
  }

    var nbeg,ldest,cdest,source:ptrtype;
        cnt:integer;

    begin
      getmem(nbeg,entryformat.entrysize);
      move(block.first.entry^,nbeg^,entryformat.entrysize);
      nbeg^.back := nil;
      nbeg^.next := nil;
      source := block.first.entry;
      cdest := nbeg;
      ldest := nbeg;
      for cnt := block.first.linenum + 1 to block.last.linenum do
        begin
          source := source^.next;
          getmem(cdest,entryformat.entrysize);
          move(source^,cdest^,entryformat.entrysize);
          cdest^.back := ldest;
          ldest^.next := cdest;
          cdest^.next := nil;
          ldest := cdest
        end;
      unhighblock(block);
      block.first.entry := nbeg;
      block.last.entry := cdest
    end;


  Procedure hideblock(var block:blocktype;var entryformat,listformat:formattype);

    var p:ptrtype;
      o,s:word;

    begin
      p := block.first.entry;
      while (p<>block.last.entry) do
        begin
          p^.hidden := true;
          p := p^.next
        end;
      block.last.entry^.hidden := true;
      if block.scr then
        begin
          o := ofs(block.list^);
          s := seg(block.list^);
          p := ptr(s,o-8);
          updatelistinfo(p^,entryformat,listformat);
          updateline(p^,entryformat)
        end
    end;

  Procedure unhideblock(var block:blocktype;var entryformat,listformat:formattype);

    var p:ptrtype;
      o,s:word;

    begin
      p := block.first.entry;
      while (p<>block.last.entry) do
        begin
          p^.hidden := false;
          p := p^.next
        end;
      block.last.entry^.hidden := false;
      if block.scr then
        begin
          o := ofs(block.list^);
          s := seg(block.list^);
          p := ptr(s,o-8);
          updatelistinfo(p^,entryformat,listformat);
          updateline(p^,entryformat)
        end
    end;

  Procedure editlist(var entry:node;var entryformat,listformat:formattype;var block:blocktype);

    var choice,schoice,response:char;
        lx,ly,row,column:integer;
        readyquit,coutb:boolean;
        letters:settype;
        cursorpos:cursortype;


    begin
      clrscr;
      if entry.list = nil then
        initialize(entry.list,cursorpos,row,column,letters,readyquit,listformat)
      else
        begin
          cursorpos.entry := entry.list;
          cursorpos.linenum := 1;
          row := 3;
          column := 1;
          letters := [' '..chr(126)];
          readyquit := false
        end;
      displayscreen(cursorpos,row,column,listformat);
      repeat
        choice := readkey;
        case choice of
          chr(11):begin
                    displaycommand('^K',lx,ly);
                    schoice := readkey;
                    write(schoice);
                    case schoice of
                      'B','b':begin
                                markbeg(block,cursorpos,addr(entry.list),true);
                                displayscreen(cursorpos,row,column,listformat)
                              end;
                      'C','c':begin
                                if (block.scr) and (not nullblock(block)) then
                                  begin
                                    copyblock(block,listformat);
                                    moveblock(block,entry.list,cursorpos);
                                    displayscreen(cursorpos,row,column,listformat)
                                  end
                                else if nullblock(block) then
                                  usermessage('No block has been defined.  Press any key to continue.')
                                else
                                  usermessage('Illegal destination for block.  Press any key to continue.')
                              end;
                      'H','h':begin
                                if (not nullblock(block)) then
                                  begin
                                    unhighblock(block);
                                    initblock(block);
                                    displayscreen(cursorpos,row,column,listformat)
                                  end
                              end;
                      'K','k':begin
                                markend(block,cursorpos,addr(entry.list),true);
                                displayscreen(cursorpos,row,column,listformat)
                              end;
                      'S','s':begin
                                if not nullblock(block) then
                                  begin
                                    hideblock(block,entryformat,listformat);
                                    displayscreen(cursorpos,row,column,listformat)
                                  end
                                else usermessage('No block has been defined.  Press any key to continue.')
                              end;
                      'R','r':begin
                                if not nullblock(block) then
                                  begin
                                    unhideblock(block,entryformat,listformat);
                                    displayscreen(cursorpos,row,column,listformat)
                                  end
                                else usermessage('No block has been defined.  Press any key to continue.')
                              end;
                      'V','v':begin
                                if (block.list=addr(entry.list)) then
                                  begin
                                    if (cursorpos.linenum<block.first.linenum)
                                    or (cursorpos.linenum>block.last.linenum) then
                                      coutb := true
                                    else coutb := false
                                  end
                                else coutb := true;
                                if nullblock(block) then coutb := false;
                                if (block.scr) and (coutb) then
                                  begin
                                    popblock(block,entry.list,cursorpos,entryformat,listformat);
                                    moveblock(block,entry.list,cursorpos);
                                    displayscreen(cursorpos,row,column,listformat)
                                  end
                                else if nullblock(block) then
                                  usermessage('No block has been defined.  Press any key to continue.')
                                else
                                  usermessage('Illegal destination for block.  Press any key to continue.')
                              end;
                    end; {schoice}
                    clearcommand(lx,ly)
                  end; {chr(11)}

          chr(14):begin
                    insertentry(entry.list,cursorpos,listformat,block);
                    displayscreen(cursorpos,row,column,listformat)
                  end;
          chr(25):begin
                    deleteentry(entry.list,cursorpos,row,listformat,block);
                    displayscreen(cursorpos,row,column,listformat)
                  end;
          chr(0):begin
                   schoice := readkey;
                   case schoice of
                     chr(59):begin
                               instructions;
                               displayscreen(cursorpos,row,column,listformat)
                             end;
                     'C':begin
                           displaymessage('Are you sure<y,n>? ',lx,ly);
                           readln(response);
                           if response in ['Y','y'] then
                             begin
                               clearlist(entry.list,listformat,block);
                               updatelistinfo(entry,entryformat,listformat);
                               readyquit := true
                             end;
                           clearmessage(lx,ly)
                         end;
                     'D':begin
                           updatelistinfo(entry,entryformat,listformat);
                           readyquit := true
                         end;
                     'H':backwd(cursorpos,row,column,listformat);
                     'I':pageup(cursorpos,row,column,listformat);
                     'K':left(row,column,listformat);
                     'M':right(row,column,listformat);
                     'P':forwd(cursorpos,row,column,listformat);
                     'Q':pagedown(cursorpos,row,column,listformat);
                     'S':begin
                           assignstring('',cursorpos.entry^,column,listformat);
                           with listformat.fields[column] do
                             unhighlight(row,scol,slength);
                           displayline(cursorpos.entry^,row,listformat);
                           with listformat.fields[column] do
                             highlight(row,scol,slength)
                         end
                   end
                 end {schoice}
        end; {choice}
        if choice in letters then
          begin
            displaymessage('',lx,ly);
            write(cursorpos.linenum,': ');
            getinput(x,choice);
            clearmessage(lx,ly);
            assignstring(x,cursorpos.entry^,column,listformat);
            with listformat.fields[column] do
              unhighlight(row,scol,slength);
            displayline(cursorpos.entry^,row,listformat);
            with listformat.fields[column] do
              highlight(row,scol,slength);
          end;
      until readyquit
    end;

  Function fileexists(filename:string):boolean;

    var f:file;
        error:integer;

    begin
      assign(f,filename);
      {$I-}
        reset(f);
      {$I+}
      error := IOresult;
      if error=0 then
        begin
          close(f);
          fileexists := true
        end
      else
        fileexists := false
    end;

  Function filecreation(filename:string):boolean;

    var f:file;
        error:integer;

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

  Procedure savefile(filename:string;beginning:ptrtype;totals:totaltype;var entryformat,listformat:formattype);

    var f:file;
        p,q:ptrtype;
        result:word;

    begin
      p := beginning;
      assign(f,filename);
      rewrite(f,1);
      blockwrite(f,totals,sizeof(totals),result);
      if result<sizeof(totals) then
        begin
          usermessage('Insufficient disk space.  Press any key to continue');
          close(f);
          erase(f);
          exit
        end;
      while p<>nil do
        begin
          blockwrite(f,p^.hidden,entryformat.entrysize-15,result);
          if result<entryformat.entrysize-15 then
            begin
              usermessage('Insufficient disk space.  Press any key to continue');
              close(f);
              erase(f);
              exit
            end;
          blockwrite(f,p^.listsize,sizeof(p^.listsize),result);
          if result<sizeof(p^.listsize) then
            begin
              usermessage('Insufficient disk space.  Press any key to continue');
              close(f);
              erase(f);
              exit
            end;
          q := p^.list;
          while q<>nil do
            begin
              blockwrite(f,q^.hidden,listformat.entrysize-15,result);
              if result<listformat.entrysize-15 then
                begin
                  usermessage('Insufficient disk space.  Press any key to continue');
                  close(f);
                  erase(f);
                  exit
                end;
              q := q^.next
            end;
          p := p^.next;
        end;
      close(f)
    end;

  Procedure Getfile(filename:string;var beginning:ptrtype;var totals:totaltype;var entryformat,listformat:formattype);

    var f:file;
        p,q,p1,q1:ptrtype;
        cnt:integer;
        result:word;

    begin
      assign(f,filename);
      reset(f,1);
      blockread(f,totals,sizeof(totals),result);
      getnewline(beginning,entryformat,false,false);
      p := beginning;
      while not eof(f) do
        begin
          blockread(f,p^.hidden,entryformat.entrysize-15,result);
          blockread(f,p^.listsize,sizeof(p^.listsize),result);
          if p^.listsize = 0 then
            p^.list := nil
          else
            begin
              getnewline(p^.list,listformat,false,false);
              q := p^.list;
              cnt := 0;
              while (not eof(f)) and (cnt<p^.listsize) do
                begin
                  cnt := cnt + 1;
                  blockread(f,q^.hidden,listformat.entrysize-15,result);
                  if cnt < p^.listsize then
                    begin
                      q1 := q;
                      getnewline(q,listformat,false,false);
                      q^.back := q1;
                      q1^.next := q
                    end
                end
            end;
          if not eof(f) then
            begin
              p1 := p;
              getnewline(p,entryformat,false,false);
              p^.back := p1;
              p1^.next := p
            end
        end;
      close(f);
    end;

  Procedure savenewfile(filename:string;beginning:ptrtype;totals:totaltype;var entryformat:formattype);

    var   result:integer;
               p,newentry:ptrtype;
               f:file;
    oldbal,alloc:real;

    begin
      getmem(newentry,entryformat.entrysize);
      assign(f,filename);
      rewrite(f,1);
      with totals do
        begin
          init := remain;
          tmoneyspent := 0.0;
          toldbal := tnewbal;
          tnewbal := toldbal + tmoneyalloc
        end;
      blockwrite(f,totals,sizeof(totals),result);
      if result<sizeof(totals) then
        begin
          usermessage('Insufficient disk space.  Press any key to continue');
          close(f);
          erase(f);
          exit
        end;
      p := beginning;
      while p<>nil do
        begin
          move(p^,newentry^,entryformat.entrysize);
          assignreal(0.0,newentry^,3,entryformat);
          oldbal := getreal(newentry^,5,entryformat);
          assignreal(oldbal,newentry^,4,entryformat);
          alloc := getreal(newentry^,2,entryformat);
          assignreal(oldbal+alloc,newentry^,5,entryformat);
          newentry^.listsize  := 0;
          blockwrite(f,newentry^.hidden,entryformat.entrysize-15,result);
          if result<entryformat.entrysize-15 then
            begin
              usermessage('Insufficient disk space.  Press any key to continue.');
              close(f);
              erase(f);
              exit
            end;
          blockwrite(f,newentry^.listsize,sizeof(newentry^.listsize),result);
          if result<sizeof(newentry^.listsize) then
            begin
              usermessage('Insufficient disk space.  Press any key to continue.');
              close(f);
              erase(f);
              exit
            end;
          p := p^.next
        end;
      close(f);
      freemem(newentry,entryformat.entrysize)
    end;

  Procedure eraseit(filename:string);

    var f:file;

    begin
      assign(f,filename);
      erase(f)
    end;

  Procedure getfiles(mask:string;var beg:dirlink);

    var whatfile:searchrec;
           error:integer;
           p,q,r:dirlink;

    begin
      findfirst(mask,directory,whatfile);
      error := doserror;
      beg := nil;
      while (error=0) do
        begin
          new(p);
          if whatfile.attr = 16 then
            whatfile.name := '\'+whatfile.name;
          p^.dirinfo := whatfile.name;
          p^.next := nil;
          if beg = nil then beg := p
          else
            begin
              q := beg;
              r := nil;
              while (q<>nil) and (q^.dirinfo<p^.dirinfo) do
                begin
                  r := q;
                  q := q^.next
                end;
              if r = nil then
                begin
                  p^.next := beg;
                  beg := p
                end
              else
                begin
                  r^.next := p;
                  p^.next := q
                end
            end;
          findnext(whatfile);
          error := doserror
        end
    end;

  Procedure displayfiles(p:dirlink;var q:dirlink);

    var cnt,cnt1:integer;

    begin
      for cnt := 2 to 14 do
        begin
          gotoxy(1,cnt);
          write('':80)
        end;
      gotoxy(1,3);
      for cnt := 1 to 12 do
        begin
          for cnt1 := 1 to 5 do
            begin
              if p<>nil then
                begin
                  write(p^.dirinfo);
                  write('':15-length(p^.dirinfo));
                  p := p^.next
                end
            end;
          writeln
        end;
      q := p
    end;

  Procedure cleardir(var beg:dirlink);

    var p,q:dirlink;

    begin
      p := beg;
      while p<>nil do
        begin
          q := p;
          p := p^.next;
          dispose(q)
        end;
      beg := nil
    end;


  Procedure directory(mask:string);

    var p,q,beg:dirlink;

    begin
      clrscr;
      textcolor(15);
      writeln('Directory of ',mask,':');
      textcolor(7);
      writeln;
      getfiles(mask,beg);
      if beg = nil then
        begin
          writeln('File not found.');
          textcolor(15);
          usermessage('Press any key to continue.');
          textcolor(7)
        end
      else
        begin
          p := beg;
          while p<>nil do
            begin
              displayfiles(p,q);
              p := q;
              textcolor(15);
              usermessage('Press any key to continue.');
              textcolor(7)
            end
        end;
      cleardir(beg)
    end;


  begin
    clrscr;
    initblock(block);
    getformat(entryformat);
    getlistformat(listformat);
    inittotals(totals);
    totals.init := 0.0;
    initialize(beginning,cursorpos,row,column,letters,readyquit,entryformat);
    displayscreen(cursorpos,row,column,entryformat);
    displaytotals(totals);
    repeat
      choice := readkey;
      case choice of
        chr(5):begin
                 displaymessage('Are you sure you want to exit<y,n>? ',lx,ly);
                 readln(response);
                 if response in ['Y','y'] then readyquit := true;
                 clearmessage(lx,ly)
               end;
        chr(11):begin
                  displaycommand('^K',lx,ly);
                  schoice := readkey;
                  write(schoice);
                  case schoice of
                    'B','b':begin
                              markbeg(block,cursorpos,addr(beginning),false);
                              displayscreen(cursorpos,row,column,entryformat)
                            end;
                    'H','h':begin
                              if (not nullblock(block)) then
                                begin
                                  unhighblock(block);
                                  initblock(block);
                                  displayscreen(cursorpos,row,column,entryformat)
                                end
                            end;
                    'K','k':begin
                              markend(block,cursorpos,addr(beginning),false);
                              displayscreen(cursorpos,row,column,entryformat)
                            end;
                      'S','s':begin
                                if not nullblock(block) then
                                  begin
                                    hideblock(block,entryformat,listformat);
                                    updatetotals(beginning,totals,entryformat);
                                    displayscreen(cursorpos,row,column,entryformat);
                                    displaytotals(totals)
                                  end
                                else usermessage('No block has been defined.  Press any key to continue.')
                              end;
                      'R','r':begin
                                if not nullblock(block) then
                                  begin
                                    unhideblock(block,entryformat,listformat);
                                    updatetotals(beginning,totals,entryformat);
                                    displayscreen(cursorpos,row,column,entryformat);
                                    displaytotals(totals)
                                  end
                                else usermessage('No block has been defined.  Press any key to continue.')
                              end;
                      'V','v':begin
                                if (block.list=addr(beginning)) then
                                  begin
                                    if (cursorpos.linenum<block.first.linenum)
                                    or (cursorpos.linenum>block.last.linenum) then
                                      coutb := true
                                    else coutb := false
                                  end
                                else coutb := true;
                                if nullblock(block) then coutb := false;
                                if (not block.scr) and (coutb) then
                                  begin
                                    popblock(block,beginning,cursorpos,entryformat,listformat);
                                    moveblock(block,beginning,cursorpos);
                                    displayscreen(cursorpos,row,column,entryformat)
                                  end
                                else if nullblock(block) then
                                  usermessage('No block has been defined.  Press any key to continue.')
                                else
                                  usermessage('Illegal destination for block.  Press any key to continue.')
                              end;
                  end; {schoice}
                  clearcommand(lx,ly)
                end; {chr(11)}
        chr(14):begin
                  insertentry(beginning,cursorpos,entryformat,block);
                  displayscreen(cursorpos,row,column,entryformat)
                end;
        chr(25):begin
                  deleteentry(beginning,cursorpos,row,entryformat,block);
                  updatetotals(beginning,totals,entryformat);
                  displayscreen(cursorpos,row,column,entryformat);
                  displaytotals(totals)
                end;
        chr(0):begin
                 schoice := readkey;
                 case schoice of
                   chr(59):begin
                             instructions;
                             displayscreen(cursorpos,row,column,entryformat);
                             displaytotals(totals)
                           end;
                   chr(60):begin
                             displaymessage('Save file under [ENTER to exit]: ',lx,ly);
                             readln(filename);
                             clearmessage(lx,ly);
                             if filename<>'' then
                               begin
                                 response := 'Y';
                                 if fileexists(filename) then
                                   begin
                                     displaymessage(filename+' already exists.  Overwrite<y,n>? ',lx,ly);
                                     readln(response);
                                     clearmessage(lx,ly)
                                   end;
                                 if response in ['Y','y'] then
                                   if filecreation(filename) then
                                     begin
                                       displaymessage('Saving ',lx,ly);
                                       write(filename);
                                       savefile(filename,beginning,totals,entryformat,listformat);
                                       clearmessage(lx,ly)
                                     end
                                   else
                                     usermessage('File creation error.  Press any key to continue.')
                               end
                           end;
                       'A':begin
                             displaymessage('Save new file under [ENTER to exit]: ',lx,ly);
                             readln(filename);
                             clearmessage(lx,ly);
                             if filename<>'' then
                               begin
                                 response := 'Y';
                                 if fileexists(filename) then
                                   begin
                                     displaymessage(filename+' already exists.  Overwrite<y,n>? ',lx,ly);
                                     readln(response);
                                     clearmessage(lx,ly)
                                   end;
                                 if response in ['Y','y'] then
                                   if filecreation(filename) then
                                     begin
                                       displaymessage('Saving ',lx,ly);
                                       write(filename);
                                       savenewfile(filename,beginning,totals,entryformat);
                                       clearmessage(lx,ly)
                                     end
                                   else
                                     usermessage('File creation error.  Press any key to continue.')
                               end
                           end;
                   chr(61):begin
                             displaymessage('Get file [ENTER to exit]: ',lx,ly);
                             readln(filename);
                             clearmessage(lx,ly);
                             if filename<>'' then
                               begin
                                 if fileexists(filename) then
                                   begin
                                     clearentries(beginning,entryformat,listformat,block);
                                     displaymessage('Getting '+filename,lx,ly);
                                     getfile(filename,beginning,totals,entryformat,listformat);
                                     clearmessage(lx,ly);
                                     cursorpos.entry := beginning;
                                     cursorpos.linenum := 1;
                                     row := 3;
                                     column := 1;
                                     displayscreen(cursorpos,row,column,entryformat);
                                     displaytotals(totals)
                                   end
                                 else
                                   usermessage('Cannot find '+filename+'.  Press any key to continue.')
                               end
                           end;
                   chr(62):begin
                             editlist(cursorpos.entry^,entryformat,listformat,block);
                             clrscr;
                             updateline(cursorpos.entry^,entryformat);
                             updatetotals(beginning,totals,entryformat);
                             displayscreen(cursorpos,row,column,entryformat);
                             displaytotals(totals)
                           end;
                   chr(63):begin
                             getoldbal(totals.init);
                             updatetotals(beginning,totals,entryformat);
                             displaytotals(totals)
                           end;
                   chr(64):begin
                             displaymessage('Erase file [ENTER to exit]: ',lx,ly);
                             readln(filename);
                             clearmessage(lx,ly);
                             if filename<>'' then
                               begin
                                 if fileexists(filename) then
                                   begin
                                     displaymessage('Erasing '+filename,lx,ly);
                                     eraseit(filename);
                                     clearmessage(lx,ly)
                                   end
                                 else
                                   usermessage('Cannot find '+filename+'.  Press any key to continue.')
                               end
                           end;
                   'B':begin
                         clrscr;
                         gotoxy(1,12);
                         write('Enter directory name [ENTER for default directory]: ');
                         readln(mask);
                         if mask='' then mask := '*.*';
                         directory(mask);
                         clrscr;
                         displayscreen(cursorpos,row,column,entryformat);
                         displaytotals(totals)
                       end;
                   'C':begin
                         displaymessage('Are you sure<y,n>? ',lx,ly);
                         readln(response);
                         clearmessage(lx,ly);
                         if response in ['Y','y'] then
                           begin
                             clearentries(beginning,entryformat,listformat,block);
                             inittotals(totals);
                             totals.init := 0.0;
                             getnewline(beginning,entryformat,false,false);
                             cursorpos.entry := beginning;
                             cursorpos.linenum := 1;
                             row := 3;
                             column := 1;
                             clrscr;
                             displayscreen(cursorpos,row,column,entryformat);
                             displaytotals(totals)
                           end
                       end;
                   'H':backwd(cursorpos,row,column,entryformat);
                   'K':left(row,column,entryformat);
                   'I':pageup(cursorpos,row,column,entryformat);
                   'M':right(row,column,entryformat);
                   'P':forwd(cursorpos,row,column,entryformat);
                   'Q':pagedown(cursorpos,row,column,entryformat);
                   'S':begin
                         assignstring('',cursorpos.entry^,column,entryformat);
                         updateline(cursorpos.entry^,entryformat);
                         updatetotals(beginning,totals,entryformat);
                         with entryformat.fields[column] do
                           unhighlight(row,scol,slength);
                         displayline(cursorpos.entry^,row,entryformat);
                         with entryformat.fields[column] do
                           highlight(row,scol,slength);
                         displaytotals(totals)
                       end
                 end
               end {schoice}
      end; {choice}
      if choice in letters then
        begin
          displaymessage('',lx,ly);
          write(cursorpos.linenum,': ');
          getinput(x,choice);
          clearmessage(lx,ly);
          assignstring(x,cursorpos.entry^,column,entryformat);
          updateline(cursorpos.entry^,entryformat);
          updatetotals(beginning,totals,entryformat);
          with entryformat.fields[column] do
            unhighlight(row,scol,slength);
          displayline(cursorpos.entry^,row,entryformat);
          with entryformat.fields[column] do
            highlight(row,scol,slength);
          displaytotals(totals)
        end;
    until readyquit
  end.
