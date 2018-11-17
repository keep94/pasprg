program peek;

  uses crt;

  type
    stringtype=string[80];
    bytestringtype=string[3];
    arraytype=array[1..128] of byte;
    filetype=file of byte;
    ptrtype=^node;
    node=record
      back:ptrtype;
      data:arraytype;
      next:ptrtype
    end; {record}

  var  beginning,ending,sector:ptrtype;
       sectornum,totalsectors,bytenum:integer;
       numberinlast:integer;
       base,choice,schoice:char;
       altered,didinriment,ascii:boolean;
       f:filetype;

  Procedure mainsetup;

    var lx,ly:integer;

    begin
      lx := wherex;
      ly := wherey;
      gotoxy(3,21);
      write('':78);
      gotoxy(3,22);
      write('':78);
      gotoxy(3,21);
      write(chr(26),' = Next sector  ',chr(27),' = Previous sector  H = Hex  D = Decimal  O = Octal');
      gotoxy(3,22);
      write('Q = Quit  E = Edit  F2 = Save file  F3 = Get file  F6 = Go to a certain sector');
      gotoxy(lx,ly)
    end;

  Procedure Editsetup;

    var lx,ly:integer;

    begin
      lx := wherex;
      ly := wherey;
      gotoxy(3,21);
      write('':78);
      gotoxy(3,22);
      write('':78);
      gotoxy(3,21);
      write(chr(24),chr(25),chr(27),chr(26),' = Move cursor  Toggles:  Ins = Insert Mode  Tab = Ascii edit mode');
      gotoxy(3,22);
      write('Insert:  ^N=Line F4=Sector Delete: Del=Byte ^Y=Line F5=Sector F10=Main menu');
      gotoxy(lx,ly)
    end;


  Procedure displaymessage(s:string;var lx,ly:integer);

    begin
      lx := wherex;
      ly := wherey;
      gotoxy(15,23);
      write(s)
    end;

  Procedure clearmessage(lx,ly:integer);

    var cnt:integer;

    begin
      gotoxy(15,23);
      for cnt := 1 to 64 do write(' ');
      gotoxy(lx,ly)
    end;

  Function filexists(filename:stringtype):boolean;

    var f:filetype;
        error:integer;

    begin
      assign(f,filename);
      {$I-}
      reset(f);
      Error := IOresult;
      {$I+}
      if Error = 0 then
        begin
          close(f);
          filexists := true
        end
      else filexists := false
    end;


  Procedure displayfilesize(tsector:integer);

    var lx,ly:integer;

    begin
      lx := wherex;
      ly := wherey;
      gotoxy(35,1);
      write('SECTORS IN FILE: ',tsector:5);
      gotoxy(lx,ly)
    end;

  Procedure displaysectornum(sectornum:integer);

    var lx,ly:integer;

    begin
      lx := wherex;
      ly := wherey;
      gotoxy(10,1);
      write('SECTOR: ',sectornum:5);
      gotoxy(lx,ly)
    end;

  Procedure displayinsert(insertion:boolean);

    var lx,ly:integer;

    begin
      lx := wherex;
      ly := wherey;
      gotoxy(65,1);
      if insertion then write('INSERT ON')
        else write('         ');
      gotoxy(lx,ly)
    end;


  Procedure initialize(var beginning,ending,sector:ptrtype;
                       var tsector,sectornum:integer;var numberinlast:integer;
                       var base:char;var altered:boolean;var bytenum:integer;
                       var ascii:boolean);

    var cnt:integer;

    begin
      new(beginning);
      for cnt := 1 to 128 do beginning^.data[cnt] := 0;
      beginning^.back := nil;
      beginning^.next := nil;
      ending := beginning;
      sector := beginning;
      tsector := 1;
      sectornum := 1;
      displayfilesize(tsector);
      displaysectornum(sectornum);
      numberinlast := 0;
      base := 'h';
      altered := false;
      bytenum := 1;
      ascii := false
    end;

  Procedure getinteger(var x:integer;var enterpressed,error:boolean);

    var count,cnt:integer;
              dummy:char;
                dig:array [1..7] of char;
           done,neg:boolean;

    begin
      count := 1;
      enterpressed := false;
      error := false;
      done := false;
      x := 0;
      while (not enterpressed) and (not done) do
        begin
          dig[count] := readkey;
          if dig[count]=chr(8) then
            begin
              if count>1 then
                begin
                  count := count - 1;
                  gotoxy(wherex-1,wherey);
                  write(' ');
                  gotoxy(wherex-1,wherey)
                end
            end
          else if dig[count]=chr(13) then
            begin
              if count = 1 then enterpressed := true else done := true
            end
               else if count<7 then
                 begin
                   write(dig[count]);
                   count := count + 1
                 end
        end;
      if not enterpressed then
        begin
          count := count - 1;
          if dig[1]='-' then neg := true else neg := false;
          if neg then cnt := 2 else cnt := 1;
          while (cnt<=count) and (not error) do
            begin
              if (ord(dig[cnt])>47) and (ord(dig[cnt])<58) then
                begin
                  if (x<=3276) then
                    begin
                      x := x * 10;
                      x := x - 48 + ord(dig[cnt]);
                      if x<0 then error := true;
                      cnt := cnt + 1
                    end
                  else error := true
                end
              else error := true
            end;
          if neg then x := -x
        end
    end;




  Procedure plotend(n:byte;base:char;setit:boolean);

    var lx,ly,vtab,htab,selement:integer;

    begin
      lx := wherex;
      ly := wherey;
      vtab := (n-1) div 8;
      htab := ((n-1) mod 8)+1;
      case base of
        'd','o':selement := 4;
        'h':selement := 3
      end; {case}
      gotoxy(22+selement*htab,4+vtab);
      if setit then write(']') else write(' ');
      gotoxy(lx,ly)
    end;

  Procedure changebase(var base:char;nbase:char);

    begin
      base := nbase
    end;

  Procedure Decriment(var sector:ptrtype;var sectornum:integer);

    begin
      if sectornum>1 then
        begin
          sector := sector^.back;
          sectornum := sectornum - 1;
          displaysectornum(sectornum)
        end
    end;

  Procedure incriment(var ending,sector:ptrtype;var sectornum,tsector:integer;
                      var numberinlast:integer;var didincriment:boolean);

    var lx,ly,cnt:integer;
        reply:char;
        q:ptrtype;


    begin
      if sector^.next<>nil then
        begin
          sector := sector^.next;
          sectornum := sectornum + 1;
          displaysectornum(sectornum);
          didincriment := true
        end
      else
        begin {able to expand}
          displaymessage('End of file.  Do you wish to expand<y,n>: ',lx,ly);
          readln(reply);
          clearmessage(lx,ly);
          if reply in ['Y','y'] then
            begin {expand}
              numberinlast := 0;
              new(q); {start initializing block}
              for cnt := 1 to 128 do q^.data[cnt] := 0; {clear new block}
              sector^.next := q;
              q^.back := sector;
              q^.next := nil; {finish initializing block}
              sector := sector^.next;
              tsector := tsector + 1;
              sectornum := sectornum + 1;
              ending := sector;
              displaysectornum(sectornum);
              displayfilesize(tsector);
              didincriment := true
            end {expand}
          else didincriment := false
        end {able to expand}
    end; {incriment}

  Procedure gotosector(tsector:integer;var sector:ptrtype;var sectornum:integer);

    var lx,ly,x,num:integer;
        dummy:char;
        enterpressed,error:boolean;

    begin
      displaymessage('Enter a sector: ',lx,ly);
      getinteger(x,enterpressed,error);
      clearmessage(lx,ly);
      if not enterpressed then
        begin
          if (x>tsector) or (x<1) or error then {error message}
            begin
              displaymessage('Sector not in file.  Press any key to continue.',lx,ly);
              dummy := readkey;
              clearmessage(lx,ly);
              enterpressed := true
            end
          else
            begin
              num := x - sectornum;
              if num>0 then
                while num>0 do
                  begin
                    sector := sector^.next;
                    num := num - 1
                  end;
              if num<0 then
                while num<0 do
                  begin
                    sector := sector^.back;
                    num := num + 1
                  end;
              sectornum := x;
            end
        end
    end;






  Function hexadecimal(num:byte):bytestringtype;

    var temp:bytestringtype;
        first,second:byte;
        dig:char;

    begin
      temp := '';
      first := num div 16;
      if first<10 then dig := chr(48+first) else dig := chr(55+first);
      temp := temp + dig;
      second := num-first*16;
      if second<10 then dig := chr(48+second) else dig := chr(55+second);
      temp := temp + dig;
      hexadecimal := temp
    end;

  Function decimal(num:byte):bytestringtype;

    var temp:bytestringtype;
        cnt :integer;
        place,dig:byte;


    begin
      temp := '';
      place := 100;
      for cnt := 2 downto 0 do
        begin
          dig := num div place;
          temp := temp + chr(dig+48);
          num := num - dig*place;
          place := place div 10
        end;
      decimal := temp
    end;

  Function octal(num:byte):bytestringtype;

    var temp:bytestringtype;
        cnt :integer;
        place,dig:byte;

    begin
      temp := '';
      place := 64;
      for cnt := 2 downto 0 do
        begin
          dig := num div place;
          temp := temp + chr(dig+48);
          num := num - dig*place;
          place := place div 8
        end;
      octal := temp
    end;

  Procedure display(sector:ptrtype;base:char;numberinlast:integer);

    var cnt,cnt1,asciitab:integer;

    begin
      for cnt := 0 to 15 do
        begin
          gotoxy(23,4+cnt);
          for cnt1 := 1 to 50 do write(' ')
        end;
      case base of
        'd','o':asciitab := 57;
            'h':asciitab := 49
      end;
      for cnt := 0 to 15 do
        begin
          gotoxy(15,4+cnt);
          write(cnt*8:3);
          gotoxy(23,4+cnt);
          for cnt1 := 1 to 8 do
            case base of
              'd':write(decimal(sector^.data[cnt*8+cnt1]),' ');
              'o':write(octal(sector^.data[cnt*8+cnt1]),' ');
              'h':write(hexadecimal(sector^.data[cnt*8+cnt1]),' ')
            end;
          gotoxy(asciitab,4+cnt);
          for cnt1 := 1 to 8 do
            if (sector^.data[cnt*8+cnt1]>122) or (sector^.data[cnt*8+cnt1]<32)
            then write('.') else write(chr(sector^.data[cnt*8+cnt1]));
        end; {big for}
      if (sector^.next=nil) and (numberinlast<>0) then plotend(numberinlast,base,true)
      else if (sector^.next^.next=nil) and (numberinlast=0) then plotend(128,base,true)
    end;

  Procedure Editsector(var sector,ending:ptrtype;var numberinlast:integer;
                       var tsector,sectornum,bytenum:integer;base:char;
                       var ascii:boolean);

    var lastx,lasty:integer;
        done,insertion,didincriment:boolean;
        choice,schoice:char;

    Procedure gotobyteloc(bytenum:integer;base:char;ascii:boolean);

      var selement,asciitab,htab,vtab:integer;

      begin
        if not ascii then
          begin
            case base of
              'd','o':selement := 4;
              'h':selement := 3
            end;
            htab := (bytenum-1) mod 8;
            vtab := (bytenum-1) div 8;
            gotoxy(23+htab*selement,4+vtab)
          end {in numbers}
        else
          begin
            case base of
              'd','o':asciitab := 57;
                  'h':asciitab := 49
            end;
            htab := (bytenum-1) mod 8;
            vtab := (bytenum-1) div 8;
            gotoxy(asciitab+htab,4+vtab)
          end
      end;

    Function beforend(sectornum,bytenum,tsector,numberinlast:integer):boolean;

      var diffsector,diffnum:integer;

      begin
        diffsector := tsector-sectornum;
        diffnum := numberinlast-bytenum;
        beforend := (diffsector>0) or ((diffsector=0) and (diffnum>=0))
      end;

    Procedure insertbytes(sector:ptrtype;bytenum:integer;var ending:ptrtype;
                          var numberinlast,tsector:integer;
                          response1,response2:integer);

      var lx,ly,amount,newnum,cnt:integer;
          sorcenum,destinationnum:integer;
          q,sorcesector,destinationsector:ptrtype;


      begin
        {add the new sectors}
        if numberinlast=0 then
          begin {is number in last zero}
            ending := ending^.back;
            numberinlast := 128;
            tsector := tsector - 1
          end; {is number in last zero}
        amount := response1;
        newnum := numberinlast + response2;
        if newnum>128 then
          begin
            newnum := newnum - 128;
            amount := amount + 1
          end;
        sorcesector := ending; {get original ending}
        sorcenum := numberinlast; {get original ending}
        {up date}
        numberinlast := newnum;
        tsector := tsector + amount;
        for cnt := 1 to amount do
          begin {add sectors}
            new(q);
            ending^.next := q;
            q^.back := ending;
            q^.next := nil;
            ending := ending^.next
          end; {add sectors} {assertion: ending,numberinlast updated}
        if amount>0 then for cnt := 1 to 128 do ending^.data[cnt] := 0;
          {set new sectors to zero}
        destinationsector := ending; {set to new ending}
        destinationnum := numberinlast; {set to new ending}
        while (sorcesector<>sector) or (sorcenum<>bytenum) do
          begin  {transfer}
            destinationsector^.data[destinationnum] := sorcesector^.data[sorcenum];
            if destinationnum=1 then {decriment destination pointer}
              begin
                destinationsector := destinationsector^.back;
                destinationnum := 128
              end
            else destinationnum := destinationnum - 1;
            if sorcenum=1 then {decriment sorce pointer}
              begin
                sorcesector := sorcesector^.back;
                sorcenum := 128
              end
            else sorcenum := sorcenum -1
          end; {transfer}
          {assertion sorce pointer at cursor}
        destinationsector^.data[destinationnum] := sector^.data[bytenum];
        while (sorcesector<>destinationsector) or (sorcenum<>destinationnum) do
          begin {set spaces allocated by insert to zero}
            sorcesector^.data[sorcenum]:=0;
            if sorcenum=128 then {incriment pointer}
              begin
                sorcesector := sorcesector^.next;
                sorcenum := 1
              end
            else sorcenum := sorcenum + 1
          end; {set spaces allocated to zero}
        displayfilesize(tsector)
      end; {insert}

    Procedure deletebytes(sector:ptrtype;sectornum,bytenum:integer;
                          var ending:ptrtype;
                          var numberinlast,tsector:integer;
                          response1,response2:integer);

    var lx,ly,cnt,newnum,amount,nsector,nbyte:integer;
        destinationsector,sorcesector,q:ptrtype;
        destinationnum,sorcenum:integer;
        finished:boolean;

    begin
      if numberinlast=0 then
        begin
          numberinlast := 128;
          ending := ending^.back;
          tsector := tsector - 1
        end;
      nsector := sectornum + response1;
      amount := response1;
      nbyte := bytenum + response2;
      if (nbyte>128) then
        begin
          nbyte := nbyte - 128;
          nsector := nsector + 1;
          amount := amount + 1
        end;
      if beforend(nsector,nbyte,tsector,numberinlast) then
        begin
          destinationsector := sector;
          destinationnum := bytenum;
          sorcesector := sector;
          for cnt := 1 to amount do sorcesector := sorcesector^.next;
          sorcenum := nbyte;
          while (sorcesector<>ending) or (sorcenum<>numberinlast) do
            begin
              destinationsector^.data[destinationnum] := sorcesector^.data[sorcenum];
              if destinationnum=128 then
                begin
                  destinationsector := destinationsector^.next;
                  destinationnum := 1
                end
              else destinationnum := destinationnum + 1;
              if sorcenum=128 then
                begin
                  sorcesector := sorcesector^.next;
                  sorcenum := 1
                end
              else sorcenum := sorcenum + 1
            end;
          destinationsector^.data[destinationnum] := ending^.data[numberinlast]
        end
      else
        begin
          destinationsector := sector;
          destinationnum := bytenum - 1;
        end;
      while (ending<>destinationsector) do
        begin
          q := ending^.back;
          dispose(ending);
          tsector := tsector - 1;
          ending := q
        end;
      ending^.next := nil;
      {assertion:  all excess sectors deleted}
      for cnt := destinationnum+1 to 128 do ending^.data[cnt] := 0;
      numberinlast := destinationnum;
      displayfilesize(tsector)
    end;

    Function editdecimal(choice:char):byte;

      var dig:char;
          temp:byte;

      begin
        temp := 255-(ord(choice)-48)*100;
        write(choice);
        repeat
          repeat
            dig := readkey
          until (ord(dig)<58) and (ord(dig)>47)
        until (ord(dig)-48)*10<=temp;
        temp := temp-(ord(dig)-48)*10;
        write(dig);
        repeat
          repeat
            dig := readkey
          until (ord(dig)<58) and (ord(dig)>47)
        until ord(dig)-48<=temp;
        temp := temp-ord(dig)+48;
        temp := 255 - temp;
        write(dig);
        editdecimal := temp
      end;

    Function editoctal(choice:char):byte;

      var dig:char;
          temp:byte;

      begin
        temp := 255-(ord(choice)-48)*64;
        write(choice);
        repeat
          repeat
            dig := readkey
          until (ord(dig)<56) and (ord(dig)>47)
        until (ord(dig)-48)*8<=temp;
        temp := temp-(ord(dig)-48)*8;
        write(dig);
        repeat
          repeat
            dig := readkey
        until (ord(dig)<56) and (ord(dig)>47)
        until ord(dig)-48<=temp;
        temp := temp-ord(dig)+48;
        temp := 255 - temp;
        write(dig);
        editoctal := temp
      end;

    Function edithex(choice:char):byte;

      var temp:integer;
          dig:char;

      begin
        if choice>='a' then temp := 16*(ord(choice)-87)
        else if choice>='A' then temp := 16*(ord(choice)-55)
             else temp := 16*(ord(choice)-48);
        if choice>='a' then write(chr(ord(choice)-32))
           else write(choice);
        repeat
          dig := readkey
        until dig in ['0'..'9','A'..'F','a'..'f'];
        if dig>='a' then temp := temp + ord(dig)-87
          else if dig>='A' then temp := temp + ord(dig)-55
               else temp := temp + ord(dig) - 48;
        if dig>='a' then write(chr(ord(dig)-32))
        else write(dig);
        edithex := temp
      end;

    Function inset(choice:char;base:char):boolean;

      var digit:set of char;

      begin
        case base of
          'd':digit := ['0'..'2'];
          'o':digit := ['0'..'3'];
          'h':digit := ['0'..'9','A'..'F','a'..'f']
        end;
        if choice in digit then inset := true else inset := false
      end;


    begin
      Editsetup;
      lastx := wherex;
      lasty := wherey;
      insertion := false;
      done := false;
      repeat
        if bytenum>128 then {go to next sector}
          begin
            incriment(ending,sector,sectornum,tsector,numberinlast,didincriment);
            display(sector,base,numberinlast);
            if didincriment then bytenum := bytenum - 128
            else if schoice=chr(80) then bytenum := bytenum - 8
                 else bytenum := bytenum - 1
          end {go to next sector}
        else
          if bytenum<1 then {go back a sector}
            begin
              if sector^.back = nil then bytenum := 1 {cant go back}
              else
                begin {go back}
                  decriment(sector,sectornum);
                  display(sector,base,numberinlast);
                  bytenum := bytenum + 128
                end {go back}
            end; {go back a sector}
        gotobyteloc(bytenum,base,ascii);
        choice := readkey;
        case choice of
          chr(9):ascii := not ascii; {change mode}
          chr(14):if beforend(sectornum,((bytenum-1) div 8)*8 + 1,tsector,numberinlast) then
                    begin {^N}
                      insertbytes(sector,((bytenum-1) div 8)*8 + 1,ending,numberinlast,tsector,0,8);
                      display(sector,base,numberinlast)
                    end;
          chr(25):if beforend(sectornum,((bytenum-1) div 8)*8 + 1,tsector,numberinlast) then
                    begin {^Y}
                      deletebytes(sector,sectornum,((bytenum-1) div 8)*8 + 1,ending,numberinlast,tsector,0,8);
                      display(sector,base,numberinlast)
                    end;
          chr(8):bytenum := bytenum - 1;
          chr(0):begin
                   schoice := readkey;
                   case schoice of
                     chr(62):if beforend(sectornum,((bytenum-1) div 128)*128 + 1,tsector,numberinlast) then
                               begin {F4}
                                 insertbytes(sector,((bytenum-1) div 128)*128 + 1,ending,numberinlast,tsector,1,0);
                                 display(sector,base,numberinlast)
                               end; {F4}
                     chr(63):if beforend(sectornum,((bytenum-1) div 128)*128 + 1,tsector,numberinlast) then
                               begin {F5}
                                 deletebytes(sector,sectornum,((bytenum-1) div 128)*128 + 1,ending,numberinlast,tsector,1,0);
                                 display(sector,base,numberinlast)
                               end; {F5}
                     chr(72):bytenum := bytenum-8;
                     chr(75):bytenum := bytenum-1;
                     chr(77):bytenum := bytenum+1;
                     chr(80):bytenum := bytenum+8;
                     chr(82):begin
                               insertion := not insertion;
                               displayinsert(insertion)
                             end;
                     chr(83):if beforend(sectornum,bytenum,tsector,numberinlast) then
                               begin {delete}
                                 deletebytes(sector,sectornum,bytenum,ending,numberinlast,tsector,0,1);
                                 display(sector,base,numberinlast)
                               end;
                     chr(68):done := true {F10}
                   end {schoice}
                 end {chr(0)}
        end; {choice}
        if (ord(choice)>31) and (ord(choice)<126) then
          begin
            if ascii then
              begin {it is in the letters}
                if insertion then
                  if beforend(sectornum,bytenum,tsector,numberinlast) then
                    begin {F4}
                      insertbytes(sector,bytenum,ending,numberinlast,tsector,0,1);
                      display(sector,base,numberinlast);
                      gotobyteloc(bytenum,base,ascii)
                    end;
                write(choice);
                sector^.data[bytenum] := ord(choice);
                gotobyteloc(bytenum,base,false);
                case base of
                  'd':write(decimal(ord(choice)));
                  'o':write(octal(ord(choice)));
                  'h':write(hexadecimal(ord(choice)))
                end;
                if (bytenum>numberinlast) and (sector^.next=nil) then
                  begin
                    plotend(numberinlast,base,false);
                    numberinlast := bytenum;
                    plotend(numberinlast,base,true)
                  end;
                bytenum := bytenum + 1
              end {it is in the letters}
            else if inset(choice,base) then
              begin {it is in the numbers}
                if insertion then
                  if beforend(sectornum,bytenum,tsector,numberinlast) then
                    begin {F4}
                      insertbytes(sector,bytenum,ending,numberinlast,tsector,0,1);
                      display(sector,base,numberinlast);
                      gotobyteloc(bytenum,base,ascii)
                    end;
                case base of
                  'd':sector^.data[bytenum] := editdecimal(choice);
                  'o':sector^.data[bytenum] := editoctal(choice);
                  'h':sector^.data[bytenum] := edithex(choice)
                end;
                gotobyteloc(bytenum,base,true);
                if (sector^.data[bytenum]>31) and (sector^.data[bytenum]<126) then
                  write(chr(sector^.data[bytenum]))
                else write('.');
                if (bytenum>numberinlast) and (sector^.next=nil) then
                  begin {new end of file}
                    plotend(numberinlast,base,false);
                    numberinlast := bytenum;
                    plotend(numberinlast,base,true)
                  end; {new end of file}
                bytenum := bytenum + 1
              end {if it is in numbers}
          end {If not command}
      until done;
      gotoxy(lastx,lasty);
      displayinsert(false)
    end;


  Procedure clearcurrentmemory(var beginning,ending,sector:ptrtype;
                               var numberinlast:integer;
                               var tsector,secnum:integer;var altered:boolean;
                               var bytenum:integer;var ascii:boolean);


    var p,q:ptrtype;
        cnt:integer;

    begin
      p := beginning;
      q := p^.next;
      while q<>nil do
        begin
          dispose(p);
          p := q;
          q := p^.next
        end;
      dispose(p);
      new(p);
      for cnt := 1 to 128 do p^.data[cnt] := 0;
      beginning := p;
      p^.next := nil;
      p^.back := nil;
      sector := beginning;
      ending := beginning;
      numberinlast := 0;
      tsector := 1;
      secnum := 1;
      altered := false;
      bytenum := 1;
      ascii := false
    end;



  Procedure savefile(var f:filetype;beginning:ptrtype;numberinlast:integer);

    var lx,ly,cnt:integer;
        nameoffile:stringtype;
        p:ptrtype;
        response:char;

    begin
      displaymessage('Save file as: ',lx,ly);
      readln(nameoffile);
      clearmessage(lx,ly);
      if nameoffile<>'' then
        begin
          if filexists(nameoffile) then
            repeat
              displaymessage('That file already exists.  Overwrite<y,n>: ',lx,ly);
              readln(response);
              clearmessage(lx,ly);
            Until response in ['Y','y','N','n']
          else response := 'Y';
          if response in ['Y','y'] then
            begin
              displaymessage('Saving ',lx,ly);
              write(nameoffile);
              assign(f,nameoffile);
              rewrite(f);
              p := beginning;
              while p^.next<>nil do
                begin
                  for cnt := 1 to 128 do write(f,p^.data[cnt]);
                  p := p^.next
                end;
              for cnt := 1 to numberinlast do write(f,p^.data[cnt]);
              close(f);
              clearmessage(lx,ly)
            end
        end; {save}
      clearmessage(lx,ly)
    end;



  Procedure makesure(var f:filetype;beginning:ptrtype;numberinlast:integer);

    var lx,ly:integer;
        choice:char;

    begin
      displaymessage('Current file not saved.  Save<y,n>: ',lx,ly);
      readln(choice);
      clearmessage(lx,ly);
      if choice in ['Y','y'] then savefile(f,beginning,numberinlast);
      clearmessage(lx,ly)
    end;

  Procedure getfile(var f:filetype;var beg,ending,sect:ptrtype;var numberinlast:integer;
                    var tsector,secnum:integer;var altered:boolean);

    var lx,ly,cnt:integer;
        nameoffile:stringtype;
        p,q:ptrtype;
        dummy:char;

    begin
      displaymessage('Get what file? ',lx,ly);
      readln(nameoffile);
      clearmessage(lx,ly);
      if nameoffile<>'' then
       if filexists(nameoffile) then
        begin
          if altered then makesure(f,beg,numberinlast);
          displaymessage('Getting ',lx,ly);
          write(nameoffile);
          clearcurrentmemory(beg,ending,sect,numberinlast,tsector,secnum,altered,bytenum,ascii);
          assign(f,nameoffile);
          reset(f);
          p := beg;
          tsector := tsector - 1;
          while not eof(f) do
            begin
              tsector := tsector + 1;
              cnt := 0;
              while (not eof(f)) and (cnt<128) do
                begin
                  cnt := cnt + 1;
                  read(f,p^.data[cnt])
                end;
              if not eof(f) then
                begin
                  new(q);
                  p^.next := q;
                  q^.back := p;
                  p := q
                end
            end; {loading}
          numberinlast := cnt;
          p^.next := nil;
          ending := p;
          for cnt := numberinlast + 1 to 128 do ending^.data[cnt] := 0;
          close(f);
          altered := false;
          displayfilesize(tsector);
          displaysectornum(secnum);
          clearmessage(lx,ly);
        end {preparing to load and all}
      else
        begin
          displaymessage('Cannot find that file.  Press any key to continue',lx,ly);
          dummy := readkey;
          clearmessage(lx,ly)
        end
    end;



  begin
    clrscr;
    initialize(beginning,ending,sector,totalsectors,sectornum,numberinlast,base,altered,bytenum,ascii);
    display(sector,base,numberinlast);
    repeat
      mainsetup;
      choice := readkey;
      case choice of
        'E','e':begin
                  Editsector(sector,ending,numberinlast,totalsectors,sectornum,bytenum,base,ascii);
                  altered := true
                end;
        'O','o':begin
                  changebase(base,'o');
                  display(sector,base,numberinlast)
                end;
        'D','d':begin
                  changebase(base,'d');
                  display(sector,base,numberinlast)
                end;
        'H','h':begin
                  changebase(base,'h');
                  display(sector,base,numberinlast)
                end;
        chr(0):begin
                 schoice := readkey;
                 case schoice of
                   chr(75):begin
                             Decriment(sector,sectornum);
                             display(sector,base,numberinlast)
                           end;
                   chr(77):begin
                             incriment(ending,sector,sectornum,totalsectors,numberinlast,didinriment);
                             display(sector,base,numberinlast)
                           end;
                   chr(59):begin
                             clearcurrentmemory(beginning,ending,sector,numberinlast,totalsectors,
                                                sectornum,altered,bytenum,ascii);
                             displaysectornum(sectornum);
                             displayfilesize(totalsectors);
                             display(sector,base,numberinlast)
                           end;
                   chr(60):begin
                             savefile(f,beginning,numberinlast);
                             altered := false;
                           end;
                   chr(61):begin
                             getfile(f,beginning,ending,sector,numberinlast,totalsectors,sectornum,altered);
                             display(sector,base,numberinlast)
                           end;
                   chr(64):begin
                             gotosector(totalsectors,sector,sectornum);
                             displaysectornum(sectornum);
                             display(sector,base,numberinlast)
                           end
                 end {case schoice}
               end {chr(0)}
      end {case choice}
    until choice in ['Q','q'];
    if altered then makesure(f,beginning,numberinlast)
  end.

