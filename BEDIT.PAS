program bedit;

  uses crt,dos,IOunit,btree,parcer;

  const TRSIZE = 16000;
        TRSTR = '16000';

  type

    barraytype = array[0..65519] of byte;

    bufptrtype = ^barraytype;

    blocktype = record
      st:longint;
      fin:longint;
      dataptr:bufptrtype
    end;

    lftype = record
      f:file;
      altered:boolean;
      b:btreetype
    end;


  var success,escpressed,done:boolean;
      choice:integer;
      temp,filename:string;


  Function min(x,y:longint):longint;

    begin
      if x < y then min := x
      else min := y
    end;

  Function max(x,y:longint):longint;

    begin
      if x > y then max := x
      else max := y
    end;


  Procedure initlf(var lf:lftype);

    begin
    end;


  Procedure lfassign(var lf:lftype;filename:string);

    begin
      assign(lf.f,filename)
    end;




  Function lfcurpos(var lf:lftype):longint;

    begin
      lfcurpos := btree_posit(lf.b)
    end;


  Function lfsize(var lf:lftype):longint;

    begin
      lfsize := btree_size(lf.b)
    end;


  Function lfread(var lf:lftype):byte;

    begin
      lfread := btree_read(lf.b)
    end;


  Procedure lfwrite(var lf:lftype;x:byte);

    begin
      btree_write(lf.b,x);
      lf.altered := true
    end;


  Procedure lfinsert(var lf:lftype;x:longint;var success:boolean);

    var cnt:longint;
        oldfsize:longint;
        dummyptr:pointer;
        numwritten:word;

    begin
      success := true;
      oldfsize := filesize(lf.f);
      seek(lf.f,oldfsize);
      blockwrite(lf.f,dummyptr^,x,numwritten);
      if numwritten < x then
        begin
          success := false;
          seek(lf.f,oldfsize);
          truncate(lf.f);
          exit
        end;
      btree_insert(lf.b,x,success);
      if not success then
        begin
          seek(lf.f,oldfsize);
          truncate(lf.f)
        end
      else lf.altered := true
    end;


  Procedure lfdelete(var lf:lftype;x:longint);

    var oldfsize:longint;

    begin
      if x <= 0 then exit;
      if x > lfsize(lf) - lfcurpos(lf) - 1 then
        x := lfsize(lf) - lfcurpos(lf) - 1;
      oldfsize := filesize(lf.f);
      seek(lf.f,oldfsize - x);
      truncate(lf.f);
      btree_del(lf.b,x);
      lf.altered := true
    end;


  Procedure lfseek(var lf:lftype;x:longint);

    var success:boolean;
        temp:byte;


    begin
      if x < 0 then x := 0;
      if x > lfsize(lf) then x := lfsize(lf);
      if x = lfsize(lf) then
        begin
          lfseek(lf,x-1);
          temp := lfread(lf);
          lfwrite(lf,0);
          lfinsert(lf,1,success);
          lfwrite(lf,temp);
          if success then lfseek(lf,x)
        end
      else btree_seek(lf.b,x)
    end;


  Procedure lfopen(var lf:lftype;var success:boolean);

    var numread:word;
        fsize:longint;

    begin
      reset(lf.f,1);
      fsize := filesize(lf.f);
      init_btree(lf.b,fsize,success);
      if success then
        begin
          btree_fromdisk(lf.b,lf.f);
          lfseek(lf,fsize);
          if lfsize(lf) = fsize then
            begin
              success := false;
              destroy_btree(lf.b);
              close(lf.f)
            end
          else
            begin
              lfseek(lf,0);
              lf.altered := false
            end
        end
      else close(lf.f)
    end;


  Procedure lfclose(var lf:lftype);

    var numwritten:word;
        fsize:longint;

    begin
      if lf.altered then
        btree_todisk(lf.b,lf.f);
      fsize := filesize(lf.f);
      seek(lf.f,fsize - 1);
      truncate(lf.f);
      close(lf.f);
      destroy_btree(lf.b)
    end;

  Procedure lfdestroy(var lf:lftype);

    begin
    end;


  Function printerready:boolean;

  var x:registers;

  begin
    x.ah := 2;
    x.dx := 0;
    intr(23,x);
    printerready := ((x.ah and 8) = 0)
  end;

  Procedure displaymessage(x:string;var lx,ly:integer);


    begin
      lx := wherex;
      ly := wherey;
      gotoxy(1,23);
      write(x)
    end;


  Procedure displayinst(inedit:boolean;curmode:integer;insscr:integer);

    var lx,ly:integer;

    begin
      lx := wherex;
      ly := wherey;
      gotoxy(1,20);
      write('':79);
      gotoxy(1,21);
      write('':79);
      if (curmode = 0) and (insscr = 0) then
        begin
          gotoxy(1,20);
          write(chr(24),chr(25),chr(27),chr(26));
          if not inedit then
            begin
              writeln('=Move cursor GoTo: PgUp=Prev. screen PgDn=Next screen F2=Byte#');
              write('F3=Change base F4=Edit mode on F5=Block ^T=TabSize ^S=Search F10=Close file')
            end
          else
            begin
              writeln('=Move cursor GoTo: PgUp=Prev. screen PgDn=Next screen F2=Byte# F1=Edit');
              write('F3=Change base F4=Edit mode off F5=Block ^T=TabSize ^S=Search F10=Close file')
            end
        end
      else if (curmode = 0) and (insscr = 1) then
        begin
          gotoxy(1,20);
          writeln('F1=Main menu Ins=Insert/overwrite Tab=ASCII/binary edit ENTER=Tab right');
          write('Bksp=Tab left ^N=Insert multiple bytes  Delete: Del=Byte ^Y=Multiple bytes')
        end
      else if (curmode = 1) then
        begin
          gotoxy(1,20);
          if not inedit then
            begin
              writeln('^B=Mark start ^E=Mark end  F1=Print');
              write('F5=Save  F10=Main menu')
            end
          else
            begin
              writeln('^B=Mark start ^E=Mark end  F1=Print F5=Save');
              write('F6=Get F7=Move F8=Copy F9=Delete F10=Main menu')
            end
        end;
      gotoxy(lx,ly)
    end;


  Procedure clearmessage(lx,ly:integer);

    begin
      gotoxy(1,23);
      write('':79);
      gotoxy(lx,ly)
    end;


  Procedure displayinsert(insert:boolean);

    var lx,ly:integer;

    begin
      lx := wherex;
      ly := wherey;
      gotoxy(60,25);
      if insert then write('INSERT ON')
      else write('         ');
      gotoxy(lx,ly)
    end;


  Procedure displayblock(x,y:longint);

    var lx,ly:integer;

    begin
      lx := wherex;
      ly := wherey;
      gotoxy(50,20);
      write('Start: ');
      if x >= 0 then write(x:12)
      else write('':12);
      gotoxy(50,21);
      write('  End: ');
      if y >= 0 then write(y:12)
      else write('':12);
      gotoxy(lx,ly)
    end;


  Procedure positcursor(diff:integer;ascii:boolean;base:integer);

    begin
      if ascii then
        case base of
          0:gotoxy(49 + (diff mod 8),3+(diff div 8));
          1:gotoxy(57 + (diff mod 8),3+(diff div 8));
          2:gotoxy(57 + (diff mod 8),3+(diff div 8))
        end
      else
        case base of
          0:gotoxy(23 + (diff mod 8)*3,3+(diff div 8));
          1:gotoxy(23 + (diff mod 8)*4,3+(diff div 8));
          2:gotoxy(23 + (diff mod 8)*4,3+(diff div 8))
        end
    end;


   Function editoct(choice:char):byte;

     var dig:char;
         temp:byte;

     begin
       temp := 255 - (ord(choice)-48)*64;
       write(choice);
       repeat
         repeat
           dig := readkey
         until (ord(dig) < 56) and (ord(dig) > 47)
       until (ord(dig)-48)*8 <= temp;
       temp := temp-(ord(dig)-48)*8;
       write(dig);
       repeat
         repeat
           dig := readkey
         until (ord(dig) < 56) and (ord(dig) > 47)
       until ord(dig)-48 <= temp;
       temp := temp-(ord(dig)-48);
       temp := 255 - temp;
       write(dig);
       editoct := temp
     end;

  Function editdec(choice:char):byte;

    var dig:char;
        temp:byte;

    begin
      temp := 255-(ord(choice)-48)*100;
      write(choice);
      repeat
        repeat
          dig := readkey
        until (ord(dig)<58) and (ord(dig)>47)
      until (ord(dig)-48)*10 <= temp;
      temp := temp - (ord(dig)-48)*10;
      write(dig);
      repeat
        repeat
          dig := readkey
        until (ord(dig)<58) and (ord(dig)>47)
      until ord(dig)-48 <= temp;
      temp := temp - (ord(dig)-48);
      temp := 255 - temp;
      write(dig);
      editdec := temp
    end;

  Function edithex(choice:char):byte;

    var temp:integer;
        dig:char;

    begin
      if choice >='a' then temp := 16*(ord(choice)-87)
      else if choice >= 'A' then temp := 16*(ord(choice)-55)
      else temp := 16*(ord(choice)-48);
      if choice >='a' then write(chr(ord(choice)-32))
        else write(choice);
      repeat
        dig := readkey
      until dig in ['0'..'9','A'..'F','a'..'f'];
      if dig >= 'a' then temp := temp + (ord(dig)-87)
      else if dig >= 'A' then temp := temp + (ord(dig)-55)
      else temp := temp + (ord(dig)-48);
      if dig >= 'a' then write(chr(ord(dig)-32))
      else write(dig);
      edithex := temp
    end;

  Procedure printoct(x:byte);

    var cnt:integer;
        place,dig:byte;

    begin
      place := 64;
      for cnt := 2 downto 0 do
        begin
          dig := x div place;
          write(chr(dig+48));
          x := x mod place;
          place := place div 8
        end
    end;


  Procedure printdec(x:byte);

    var cnt:integer;
        place,dig:byte;

    begin
      place := 100;
      for cnt := 2 downto 0 do
        begin
          dig := x div place;
          write(chr(dig+48));
          x := x mod place;
          place := place div 10
        end
    end;

  Procedure printhex(x:byte);

    var dig:byte;

    begin
      dig := x div 16;
      if dig < 10 then
        write(chr(dig+48))
      else write(chr(dig+55));
      dig := x mod 16;
      if dig < 10 then
        write(chr(dig+48))
      else write(chr(dig+55))
    end;


  Procedure lineoct(var g:text;x:byte);

    var cnt:integer;
        place,dig:byte;

    begin
      place := 64;
      for cnt := 2 downto 0 do
        begin
          dig := x div place;
          write(g,chr(dig+48));
          x := x mod place;
          place := place div 8
        end
    end;


  Procedure linedec(var g:text;x:byte);

    var cnt:integer;
        place,dig:byte;

    begin
      place := 100;
      for cnt := 2 downto 0 do
        begin
          dig := x div place;
          write(g,chr(dig+48));
          x := x mod place;
          place := place div 10
        end
    end;

  Procedure linehex(var g:text;x:byte);

    var dig:byte;

    begin
      dig := x div 16;
      if dig < 10 then
        write(g,chr(dig+48))
      else write(g,chr(dig+55));
      dig := x mod 16;
      if dig < 10 then
        write(g,chr(dig+48))
      else write(g,chr(dig+55))
    end;


  Procedure display(var lf:lftype;ascii:boolean;base:integer);

    var cnt,cnt1,posit,diff,stpos:longint;


    begin
      gotoxy(1,3);
      posit := lfcurpos(lf);
      stpos := 128*(posit div 128);
      for cnt := 0 to 15 do
        begin
          write(stpos+8*cnt:19);
          write(' : ');
          for cnt1 := 0 to 7 do
            begin
              if stpos+8*cnt+cnt1 >= lfsize(lf) then
                case base of
                  0:printhex(0);
                  1:printdec(0);
                  2:printoct(0)
                end
              else
                begin
                  lfseek(lf,stpos+8*cnt+cnt1);
                  case base of
                    0:printhex(lfread(lf));
                    1:printdec(lfread(lf));
                    2:printoct(lfread(lf))
                  end
                end;
              if stpos+8*cnt+cnt1 = lfsize(lf) - 2 then
                write(']')
              else write(' ')
            end;
          write('  ');
          for cnt1 := 0 to 7 do
            begin
              if stpos+8*cnt+cnt1 >= lfsize(lf) then
                write('.')
              else
                begin
                  lfseek(lf,stpos+8*cnt+cnt1);
                  if (lfread(lf) > 31) and (lfread(lf) < 126) then
                    write(chr(lfread(lf)))
                  else write('.')
                end
            end;
          if base = 0 then writeln('':8)
          else writeln
        end;
      lfseek(lf,posit);
      diff := posit - stpos;
      positcursor(diff,ascii,base)
    end;


  Procedure displayend(x:integer;ascii:boolean;base:integer);

    var lx,ly,lx1,ly1:integer;

    begin
      if x < 0 then exit;
      lx1 := wherex;
      ly1 := wherey;
      positcursor(x,false,base);
      lx := wherex;
      ly := wherey;
      case base of
        0:gotoxy(lx+2,ly);
        1:gotoxy(lx+3,ly);
        2:gotoxy(lx+3,ly)
      end;
      write(']');
      gotoxy(lx1,ly1)
    end;


  Procedure clearend(x:integer;ascii:boolean;base:integer);

    var lx,ly:integer;

    begin
      if x < 0 then exit;
      positcursor(x,false,base);
      lx := wherex;
      ly := wherey;
      case base of
        0:gotoxy(lx+2,ly);
        1:gotoxy(lx+3,ly);
        2:gotoxy(lx+3,ly)
      end;
      write(' ');
      positcursor(x,ascii,base)
    end;


  Procedure updatebyte(var lf:lftype;ascii:boolean;base:integer);

    var posit,stpos,diff:longint;
        curbyte:byte;

    begin
      posit := lfcurpos(lf);
      stpos := 128*(posit div 128);
      diff := posit - stpos;
      curbyte := lfread(lf);
      case base of
        0:gotoxy(49 + (diff mod 8),3+(diff div 8));
        1:gotoxy(57 + (diff mod 8),3+(diff div 8));
        2:gotoxy(57 + (diff mod 8),3+(diff div 8))
      end;
      if (curbyte > 31) and (curbyte < 126) then
        write(chr(curbyte))
      else write('.');
      case base of
        0:gotoxy(23 + (diff mod 8)*3,3+(diff div 8));
        1:gotoxy(23 + (diff mod 8)*4,3+(diff div 8));
        2:gotoxy(23 + (diff mod 8)*4,3+(diff div 8))
      end;
      case base of
        0:printhex(curbyte);
        1:printdec(curbyte);
        2:printoct(curbyte)
      end;
      positcursor(diff,ascii,base)
    end;


  Procedure moveup(var lf:lftype;ascii:boolean;base:integer);

    var posit,ostpos:longint;

    begin
      posit := lfcurpos(lf);
      ostpos := 128*(posit div 128);
      posit := posit - 8;
      lfseek(lf,posit);
      posit := lfcurpos(lf);
      if 128*(posit div 128) = ostpos then
        positcursor(posit-ostpos,ascii,base)
      else
        display(lf,ascii,base)
    end;


  Procedure moveleft(var lf:lftype;ascii:boolean;base:integer);

    var posit,ostpos:longint;

    begin
      posit := lfcurpos(lf);
      ostpos := 128*(posit div 128);
      posit := posit - 1;
      lfseek(lf,posit);
      posit := lfcurpos(lf);
      if 128*(posit div 128) = ostpos then
        positcursor(posit-ostpos,ascii,base)
      else
        display(lf,ascii,base)
    end;


  Procedure moveright(var lf:lftype;ascii:boolean;base:integer);

    var posit,ostpos:longint;

    begin
      posit := lfcurpos(lf);
      ostpos := 128*(posit div 128);
      if posit = lfsize(lf) - 1 then
        clearend(posit-ostpos-1,ascii,base);
      posit := posit + 1;
      lfseek(lf,posit);
      posit := lfcurpos(lf);
      if 128*(posit div 128) = ostpos then
        begin
          positcursor(posit-ostpos,ascii,base);
          if posit = lfsize(lf) - 1 then
            displayend(posit-ostpos-1,ascii,base)
        end
      else
        display(lf,ascii,base)
    end;


  Procedure movedown(var lf:lftype;ascii:boolean;base:integer);

    var posit,ostpos:longint;

    begin
      posit := lfcurpos(lf);
      ostpos := 128*(posit div 128);
      posit := posit + 8;
      if posit >= lfsize(lf) then posit := lfsize(lf) - 1;
      lfseek(lf,posit);
      posit := lfcurpos(lf);
      if 128*(posit div 128) = ostpos then
        positcursor(posit-ostpos,ascii,base)
      else
        display(lf,ascii,base)
    end;


  Procedure pgup(var lf:lftype;ascii:boolean;base:integer);

    var posit,ostpos:longint;

    begin
      posit := lfcurpos(lf);
      ostpos := 128*(posit div 128);
      posit := posit - 128;
      lfseek(lf,posit);
      posit := lfcurpos(lf);
      if 128*(posit div 128) = ostpos then
        positcursor(posit-ostpos,ascii,base)
      else
        display(lf,ascii,base)
    end;


  Procedure pgdn(var lf:lftype;ascii:boolean;base:integer);

    var posit,ostpos:longint;

    begin
      posit := lfcurpos(lf);
      ostpos := 128*(posit div 128);
      posit := posit + 128;
      if posit >= lfsize(lf) then posit := lfsize(lf) - 1;
      lfseek(lf,posit);
      posit := lfcurpos(lf);
      if 128*(posit div 128) = ostpos then
        positcursor(posit-ostpos,ascii,base)
      else
        display(lf,ascii,base)
    end;

  Procedure xpgup(var lf:lftype;ascii:boolean;base:integer;x:longint);

    var posit,ostpos:longint;

    begin
      posit := lfcurpos(lf);
      ostpos := 128*(posit div 128);
      posit := posit - x;
      lfseek(lf,posit);
      posit := lfcurpos(lf);
      if 128*(posit div 128) = ostpos then
        positcursor(posit-ostpos,ascii,base)
      else
        display(lf,ascii,base)
    end;


  Procedure xpgdn(var lf:lftype;ascii:boolean;base:integer;x:longint);

    var posit,ostpos:longint;

    begin
      posit := lfcurpos(lf);
      ostpos := 128*(posit div 128);
      posit := posit + x;
      if posit >= lfsize(lf) then posit := lfsize(lf) - 1;
      lfseek(lf,posit);
      posit := lfcurpos(lf);
      if 128*(posit div 128) = ostpos then
        positcursor(posit-ostpos,ascii,base)
      else
        display(lf,ascii,base)
    end;


  Procedure setstblock(var lf:lftype;var blkdata:blocktype;x:longint);

    var lx,ly:integer;
        cnt,oldst,oldposit:longint;

    begin
      oldposit := lfcurpos(lf);
      oldst := blkdata.st;
      blkdata.st := x;
      if (blkdata.st >= 0) and (blkdata.st <= blkdata.fin) then
        begin
          if blkdata.fin - blkdata.st >= TRSIZE then
            begin
              blkdata.st := oldst;
              clearmessage(wherex,wherey);
              displaymessage(chr(7)+'Block cannot exceed '+TRSTR+' bytes.  Press any key.',lx,ly);
              pause;
              clearmessage(lx,ly)
            end
          else
            for cnt := blkdata.st to blkdata.fin do
              begin
                lfseek(lf,cnt);
                blkdata.dataptr^[cnt-blkdata.st] := lfread(lf)
              end
        end;
      lfseek(lf,oldposit)
    end;


  Procedure setendblock(var lf:lftype;var blkdata:blocktype;x:longint);

    var lx,ly:integer;
        oldposit,cnt,oldfin:longint;

    begin
      oldposit := lfcurpos(lf);
      oldfin := blkdata.fin;
      blkdata.fin := x;
      if (blkdata.st >= 0) and (blkdata.st <= blkdata.fin) then
        begin
          if blkdata.fin - blkdata.st >= TRSIZE then
            begin
              blkdata.fin := oldfin;
              clearmessage(wherex,wherey);
              displaymessage(chr(7)+'Block cannot exceed '+TRSTR+' bytes.  Press any key.',lx,ly);
              pause;
              clearmessage(lx,ly)
            end
          else
            for cnt := blkdata.st to blkdata.fin do
              begin
                lfseek(lf,cnt);
                blkdata.dataptr^[cnt-blkdata.st] := lfread(lf)
              end
        end;
      lfseek(lf,oldposit)
    end;


  Procedure moveblock(var lf:lftype;var blkdata:blocktype);

    var bdiff,oldposit,cnt:longint;
        lx,ly:integer;
        success:boolean;

    begin
      oldposit := lfcurpos(lf);
      lfinsert(lf,blkdata.fin - blkdata.st + 1,success);
      if success then
        begin
          for cnt := 0 to blkdata.fin - blkdata.st do
            begin
              lfseek(lf,oldposit+cnt);
              lfwrite(lf,blkdata.dataptr^[cnt])
            end;
          if oldposit < blkdata.st then
            begin
              lfseek(lf,blkdata.fin + 1);
              lfdelete(lf,blkdata.fin - blkdata.st + 1);
              bdiff := blkdata.fin - blkdata.st;
              blkdata.st := oldposit;
              blkdata.fin := oldposit + bdiff
            end
          else
            begin
              lfseek(lf,blkdata.st);
              lfdelete(lf,blkdata.fin - blkdata.st + 1);
              bdiff := blkdata.fin - blkdata.st;
              oldposit := oldposit - bdiff - 1;
              blkdata.st := oldposit;
              blkdata.fin := oldposit + bdiff
            end
        end
      else
        begin
          displaymessage(chr(7)+'Not enough memory to move block.  Press any key.',lx,ly);
          pause;
          clearmessage(lx,ly)
        end;
      lfseek(lf,oldposit)
    end;


  Procedure copyblock(var lf:lftype;var blkdata:blocktype);

    var bdiff,oldposit,cnt:longint;
        lx,ly:integer;
        success:boolean;


    begin
      oldposit := lfcurpos(lf);
      lfinsert(lf,blkdata.fin - blkdata.st + 1,success);
      if success then
        begin
          for cnt := 0 to blkdata.fin - blkdata.st do
            begin
              lfseek(lf,oldposit+cnt);
              lfwrite(lf,blkdata.dataptr^[cnt])
            end;
          bdiff := blkdata.fin - blkdata.st;
          blkdata.st := oldposit;
          blkdata.fin := oldposit + bdiff
        end
      else
        begin
          displaymessage(chr(7)+'Not enough memory to copy block.  Press any key.',lx,ly);
          pause;
          clearmessage(lx,ly)
        end;
      lfseek(lf,oldposit)
    end;


  Procedure deleteblock(var lf:lftype;var blkdata:blocktype);

    var oldposit:longint;
        lx,ly:integer;
        response:char;

    begin
      displaymessage('Delete block<y,n>? ',lx,ly);
      readln(response);
      clearmessage(lx,ly);
      if not (response in ['Y','y']) then exit;
      oldposit := lfcurpos(lf);
      lfseek(lf,blkdata.st);
      lfdelete(lf,blkdata.fin - blkdata.st + 1);
      if (oldposit >= blkdata.st) and (oldposit <= blkdata.fin) then
        oldposit := blkdata.st
      else if oldposit > blkdata.fin then
        oldposit := oldposit - blkdata.fin + blkdata.st - 1;
      blkdata.st := -1;
      blkdata.fin := -1;
      lfseek(lf,oldposit)
    end;


  Procedure getblock(filename:string;var lf:lftype;var blkdata:blocktype);

    var g:file;
        bdiff,oldposit,cnt:longint;
        lx,ly:integer;
        success:boolean;
        numread:word;

    begin
      oldposit := lfcurpos(lf);
      assign(g,filename);
      reset(g,1);
      if filesize(g) > TRSIZE then
        begin
          clearmessage(wherex,wherey);
          displaymessage(chr(7)+'Block exceeds '+TRSTR+' bytes.  Press any key.',lx,ly);
          pause;
          clearmessage(lx,ly)
        end
      else
        begin
          bdiff := filesize(g) - 1;
          lfinsert(lf,bdiff+1,success);
          if success then
            begin
              blockread(g,blkdata.dataptr^,bdiff + 1,numread);
              blkdata.st := oldposit;
              blkdata.fin := blkdata.st + bdiff;
              for cnt := 0 to blkdata.fin - blkdata.st do
                begin
                  lfseek(lf,blkdata.st + cnt);
                  lfwrite(lf,blkdata.dataptr^[cnt])
                end
            end
          else
            begin
              clearmessage(wherex,wherey);
              displaymessage(chr(7)+'Not enough memory for block.  Press any key.',lx,ly);
              pause;
              clearmessage(lx,ly)
            end
        end;
      close(g);
      lfseek(lf,oldposit)
    end;


  Procedure saveblock(filename:string;var lf:lftype;var blkdata:blocktype);

    var g:file;
        numwritten:word;
        lx,ly:integer;


    begin
      assign(g,filename);
      rewrite(g,1);
      blockwrite(g,blkdata.dataptr^,blkdata.fin - blkdata.st + 1,numwritten);
      if numwritten < blkdata.fin - blkdata.st + 1 then
        begin
          clearmessage(wherex,wherey);
          displaymessage(chr(7)+'Disk is full.  Press any key.',lx,ly);
          pause;
          clearmessage(lx,ly)
        end;
      close(g)
    end;


    Procedure printblock(var lf:lftype;var blkdata:blocktype;base:integer);

    var g:text;
        error,lineno,c,lx,ly:integer;
        cnt,cnt1:longint;
        dummy:char;
        cbyte:byte;
        done:boolean;

    begin
      clearmessage(wherex,wherey);
      displaymessage('Press ESC to abort print.',lx,ly);
      assign(g,'lpt1');
      rewrite(g);
      for c := 0 to 4 do writeln(g);
      cnt := blkdata.st div 8;
      done := false;
      lineno := 0;
      while not done do
        begin
          write(g,8*cnt:19);
          write(g,' : ');
          for cnt1 := 0 to 7 do
            begin
              if (8*cnt + cnt1 < blkdata.st) or (8*cnt + cnt1 > blkdata.fin) then
                case base of
                  0:write(g,'':3);
                  1:write(g,'':4);
                  2:write(g,'':4)
                end
              else
                begin
                  case base of
                    0:linehex(g,blkdata.dataptr^[8*cnt + cnt1 - blkdata.st]);
                    1:linedec(g,blkdata.dataptr^[8*cnt + cnt1 - blkdata.st]);
                    2:lineoct(g,blkdata.dataptr^[8*cnt + cnt1 - blkdata.st])
                  end;
                  write(g,' ')
                end
            end;
          write(g,'  ');
          for cnt1 := 0 to 7 do
            begin
              if (8*cnt + cnt1 < blkdata.st) or (8*cnt + cnt1 > blkdata.fin) then
                write(g,' ')
              else
                begin
                  cbyte := blkdata.dataptr^[8*cnt + cnt1 - blkdata.st];
                  if (cbyte > 31) and (cbyte < 126) then
                    write(g,chr(cbyte))
                  else write(g,'.')
                end
            end;
          writeln(g);
          lineno := lineno + 1;
          cnt := cnt + 1;
          if keypressed then
            begin
              dummy := readkey;
              if dummy = chr(0) then dummy := readkey;
              if dummy = chr(27) then done := true
            end;
          if (cnt > blkdata.fin div 8) then done := true;
          if (not done) and (lineno >= 50) then
            begin
              write(g,chr(12));
              for c := 0 to 4 do writeln(g);
              lineno := 0
            end
        end;
      write(g,chr(12));
      close(g);
      clearmessage(lx,ly)
    end;



  Procedure boyermoore(var lf:lftype;var key:keytype;ksize:integer;var found:boolean;
       direction:integer);

    var npos:longint;
        kpos:integer;
        cval:byte;
        lastacc:array[0..255] of integer;
        cnt:integer;

    begin
      npos := lfcurpos(lf);
      if direction = 1 then
        begin
          for cnt := 0 to 255 do
            lastacc[cnt] := 0;
          for cnt := 1 to ksize do
            lastacc[key[cnt]] := cnt;
          npos := npos + ksize;
          kpos := ksize;
          while (kpos > 0) and (npos < lfsize(lf) - 1) do
            begin
              lfseek(lf,npos);
              cval := lfread(lf);
              if key[kpos] = cval then
                begin
                  kpos := kpos - 1;
                  npos := npos - 1
                end
              else
                begin
                  npos := npos + max(ksize - lastacc[cval], ksize - kpos + 1);
                  kpos := ksize
                end
            end;
          if kpos = 0 then found := true
          else found := false
        end
      else
        begin
          for cnt := 0 to 255 do
            lastacc[cnt] := ksize + 1;
          for cnt := ksize downto 1 do
            lastacc[key[cnt]] := cnt;
          npos := npos - ksize;
          kpos := 1;
          while (kpos <= ksize) and (npos >= 0) do
            begin
              lfseek(lf,npos);
              cval := lfread(lf);
              if key[kpos] = cval then
                begin
                  kpos := kpos + 1;
                  npos := npos + 1
                end
              else
                begin
                  npos := npos - max(lastacc[cval] - 1,kpos);
                  kpos := 1
                end
            end;
          if kpos > ksize then
            begin
              found := true;
              lfseek(lf,npos - ksize)
            end
          else found := false
        end
    end;




  Procedure editfile(filename:string);

    var ctab,iter,c,numclass,code,ksize,kerror,base,lx,ly,lx1,ly1,insscr,curmode:integer;
        done,ascii,insert,inedit,found,success,escpressed:boolean;
        choice,schoice,response:char;
        lposit,tempval,posit,pposit:longint;
        lf:lftype;
        temp:string;
        blkdata:blocktype;
        iptr:^integer;
        lptr:^longint;
        rptr:^real;
        num:array[0..7] of byte;
        key:keytype;

    begin
      getmem(blkdata.dataptr,TRSIZE);
      clrscr;
      gotoxy(1,1);
      write('File: ');
      write(fexpand(filename));
      base := 0;
      insscr := 0;
      curmode := 0;
      numclass := 0;
      kerror := 1;
      iter := 1;
      ctab := 1;
      iptr := addr(num);
      lptr := addr(num);
      rptr := addr(num);
      ascii := false;
      insert := true;
      displayinsert(insert);
      done := false;
      inedit := false;
      initlf(lf);
      lfassign(lf,filename);
      lfopen(lf,success);
      if not success then
        begin
          displaymessage('File to large to fit in memory.  Press any key.',lx,ly);
          pause;
          clearmessage(lx,ly);
          freemem(blkdata.dataptr,TRSIZE);
          lfdestroy(lf);
          exit
        end;
      display(lf,ascii,base);
      displayinst(inedit,curmode,insscr);
      repeat
        choice := readkey;
        if choice = chr(0) then
          begin
            schoice := readkey;
            case schoice of
              chr(20):begin
                        displaymessage('Size: ',lx,ly);
                        getinput(temp,escpressed);
                        if not escpressed then
                          begin
                            val(temp,tempval,code);
                            if tempval <=0 then tempval := 1;
                            if tempval > TRSIZE then
                              begin
                                clearmessage(lx,ly);
                                displaymessage(chr(7)+'Cannot exceed 16000 bytes.  Press any key.',lx,ly);
                                pause
                              end
                            else
                              begin
                                ctab := tempval;
                                iter := tempval
                              end
                          end;
                        clearmessage(lx,ly)
                      end;
              chr(59):if curmode = 0 then
                        begin
                          if inedit then
                            begin
                              insscr := insscr xor 1;
                              displayinst(inedit,curmode,insscr)
                            end
                        end
                      else if (curmode = 1) and (blkdata.st >= 0) and
                        (blkdata.fin >= blkdata.st) then
                        begin
                          displaymessage('Print block<y,n>? ',lx,ly);
                          readln(response);
                          if response in ['Y','y'] then
                            begin
                              if printerready then
                                printblock(lf,blkdata,base)
                              else
                                begin
                                  clearmessage(lx,ly);
                                  displaymessage(chr(7)+'Check printer.',lx,ly);
                                  pause
                                end
                            end;
                          clearmessage(lx,ly)
                        end;
              chr(60):begin
                        displaymessage('Go to? ',lx,ly);
                        getinput(temp,escpressed);
                        if (length(temp) > 0) and (not escpressed) then
                          begin
                            if copy(temp,1,1) = '+' then
                              begin
                                temp := copy(temp,2,length(temp)-1);
                                val(temp,tempval,code);
                                tempval := tempval + lfcurpos(lf);
                                if (tempval > lfsize(lf) - 1) then
                                  tempval := lfsize(lf) - 1;
                                lfseek(lf,tempval)
                              end
                            else if copy(temp,1,1) = '-' then
                              begin
                                temp := copy(temp,2,length(temp)-1);
                                val(temp,tempval,code);
                                tempval := lfcurpos(lf) - tempval;
                                lfseek(lf,tempval)
                              end
                            else
                              begin
                                val(temp,tempval,code);
                                if (tempval > lfsize(lf) - 1) then
                                  tempval := lfsize(lf) - 1;
                                lfseek(lf,tempval)
                              end;
                            display(lf,ascii,base);
                            clearmessage(wherex,wherey)
                          end
                        else clearmessage(lx,ly)
                      end;
              chr(61):begin
                        base := (base + 1) mod 3;
                        display(lf,ascii,base)
                      end;
              chr(62):begin
                        inedit := not inedit;
                        if curmode = 0 then insscr := 0;
                        displayinst(inedit,curmode,insscr);
                        if curmode = 1 then displayblock(blkdata.st,blkdata.fin)
                      end;
              chr(63):if curmode = 0 then
                        begin
                          curmode := 1;
                          insscr := 0;
                          displayinst(inedit,curmode,insscr);
                          blkdata.st := -1;
                          blkdata.fin := -1;
                          displayblock(blkdata.st,blkdata.fin)
                        end
                      else if (curmode = 1) and (blkdata.st >= 0) and
                          (blkdata.fin >= blkdata.st)  then
                        begin
                          displaymessage('Save block as? ',lx,ly);
                          getinput(temp,escpressed);
                          if not escpressed then
                            begin
                              response := 'Y';
                              if fileexists(temp) then
                                begin
                                  clearmessage(lx,ly);
                                  displaymessage('That file already exists.  Overwrite<y,n>? ',lx,ly);
                                  readln(response)
                                end;
                              if response in ['Y','y'] then
                                begin
                                  if filecreation(temp) then
                                      saveblock(temp,lf,blkdata)
                                  else
                                    begin
                                      clearmessage(lx,ly);
                                      displaymessage(chr(7)+'File creation error.  Press any key',lx,ly);
                                      pause
                                    end
                                end
                            end;
                          clearmessage(lx,ly)
                        end;
              chr(64):if (curmode = 1) and (inedit) then
                        begin
                          displaymessage('Get block from what file? ',lx,ly);
                          getinput(temp,escpressed);
                          if not escpressed then
                            begin
                              if fileexists(temp) then
                                begin
                                  getblock(temp,lf,blkdata);
                                  display(lf,ascii,base);
                                  lx := wherex;
                                  ly := wherey;
                                  displayblock(blkdata.st,blkdata.fin)
                                end
                              else
                                begin
                                  clearmessage(lx,ly);
                                  displaymessage(chr(7)+'Cannot find that file.  Press any key',lx,ly);
                                  pause
                                end
                            end;
                          clearmessage(lx,ly)
                        end;
              chr(65):if (curmode = 1) and (inedit) and (blkdata.st >= 0)
                         and (blkdata.fin >= blkdata.st) then
                        begin
                          if (lfcurpos(lf) < blkdata.st) or (lfcurpos(lf) > blkdata.fin + 1) then
                            begin
                              moveblock(lf,blkdata);
                              display(lf,ascii,base);
                              displayblock(blkdata.st,blkdata.fin)
                            end
                        end;
              chr(66):if (curmode = 1) and (inedit) and (blkdata.st >= 0)
                          and (blkdata.fin >= blkdata.st) then
                        begin
                          copyblock(lf,blkdata);
                          display(lf,ascii,base);
                          displayblock(blkdata.st,blkdata.fin)
                        end;
              chr(67):if (curmode = 1) and (inedit) and (blkdata.st >= 0)
                          and (blkdata.fin >= blkdata.st) then
                        begin
                          deleteblock(lf,blkdata);
                          display(lf,ascii,base);
                          displayblock(blkdata.st,blkdata.fin)
                        end;
              chr(68):if curmode = 0 then
                        begin
                          done := true;
                          lfclose(lf);
                          lfdestroy(lf)
                        end
                      else if curmode = 1 then
                        begin
                          curmode := 0;
                          insscr := 0;
                          displayinst(inedit,curmode,insscr)
                        end;
              chr(72):moveup(lf,ascii,base);
              chr(75):moveleft(lf,ascii,base);
              chr(77):begin
                        posit := lfcurpos(lf);
                        if (inedit) or (posit < lfsize(lf) - 1) then
                          moveright(lf,ascii,base)
                      end;
              chr(80):movedown(lf,ascii,base);
              chr(73):pgup(lf,ascii,base);
              chr(81):pgdn(lf,ascii,base);
              chr(82):begin
                        insert := not insert;
                        displayinsert(insert)
                      end;
              chr(83):if (curmode <> 1) and (inedit) then
                        begin
                          lfdelete(lf,1);
                          display(lf,ascii,base)
                        end
            end
          end
        else if choice = chr(2) then
          begin
            if (curmode = 1) then
              begin
                displaymessage('Start of block (ENTER for cursor position): ',lx,ly);
                getinput(temp,escpressed);
                if not escpressed then
                  begin
                    if temp = '' then tempval := lfcurpos(lf)
                    else val(temp,tempval,code);
                    if tempval >= lfsize(lf) - 1 then tempval := lfsize(lf) - 2;
                    setstblock(lf,blkdata,tempval);
                    displayblock(blkdata.st,blkdata.fin)
                  end;
                clearmessage(lx,ly)
              end
          end
        else if choice = chr(5) then
          begin
            if (curmode = 1) then
              begin
                displaymessage('End of block (ENTER for cursor position): ',lx,ly);
                getinput(temp,escpressed);
                if not escpressed then
                  begin
                    if temp = '' then tempval := lfcurpos(lf)
                    else val(temp,tempval,code);
                    if tempval >= lfsize(lf) - 1 then tempval := lfsize(lf) - 2;
                    setendblock(lf,blkdata,tempval);
                    displayblock(blkdata.st,blkdata.fin)
                  end;
                clearmessage(lx,ly)
              end
          end
        else if choice = chr(8) then
          begin
            if iter <= 8 then for c := 1 to iter do moveleft(lf,ascii,base)
            else xpgup(lf,ascii,base,iter)
          end
        else if choice = chr(9) then
          begin
            ascii := not ascii;
            posit := lfcurpos(lf);
            positcursor(posit - 128*(posit div 128),ascii,base)
          end
        else if (kerror = 0) and (choice = chr(11)) then
          begin
            pposit := lfcurpos(lf);
            boyermoore(lf,key,ksize,found,-1);
            if found then
              display(lf,ascii,base)
            else
              begin
                displaymessage(chr(7)+'Not found.  Press any key.',lx,ly);
                pause;
                lfseek(lf,pposit);
                clearmessage(lx,ly)
              end
          end
        else if (kerror = 0) and (choice = chr(12)) then
          begin
            pposit := lfcurpos(lf);
            boyermoore(lf,key,ksize,found,1);
            if found then
              display(lf,ascii,base)
            else
              begin
                displaymessage(chr(7)+'Not found.  Press any key.',lx,ly);
                pause;
                lfseek(lf,pposit);
                clearmessage(lx,ly)
              end
          end
        else if choice = chr(13) then
          begin
            if (inedit) or (lfcurpos(lf) < lfsize(lf) - iter) then
              begin
                if iter <= 8 then for c := 1 to iter do moveright(lf,ascii,base)
                else xpgdn(lf,ascii,base,iter)
              end
          end
        else if choice = chr(14) then
          begin
            if (curmode <> 1) and (inedit) then
              begin
                displaymessage('Insert how many bytes? ',lx,ly);
                getinput(temp,escpressed);
                if not escpressed then
                  begin
                    val(temp,tempval,code);
                    if tempval > TRSIZE then
                      begin
                        clearmessage(lx,ly);
                        displaymessage(chr(7)+'Inserted block cannot exceed '+TRSTR+' bytes.  Press any key.',lx,ly);
                        pause;
                        clearmessage(lx,ly)
                      end
                    else
                      begin
                        lfinsert(lf,tempval,success);
                          if not success then
                            begin
                              clearmessage(lx,ly);
                              displaymessage(chr(7)+'Out of disk space.  Press any key.',lx1,ly1);
                              pause
                            end;
                        display(lf,ascii,base);
                        clearmessage(wherex,wherey)
                      end
                  end
                else clearmessage(lx,ly)
              end
          end
        else if choice = chr(19) then
          begin
            displaymessage('Find: ',lx,ly);
            getinput(temp,escpressed);
            if not escpressed then
              begin
                makekey(key,ksize,temp,kerror);
                if kerror <> 0 then
                  begin
                    clearmessage(lx,ly);
                    displaymessage(chr(7)+'Incorrect format.  Press any key.',lx,ly);
                    pause
                  end
                else
                  begin
                    pposit := lfcurpos(lf);
                    boyermoore(lf,key,ksize,found,1);
                    if found then
                      begin
                        display(lf,ascii,base);
                        lx := wherex;
                        ly := wherey
                      end
                    else
                      begin
                        clearmessage(lx,ly);
                        displaymessage(chr(7)+'Not found.  Press any key.',lx,ly);
                        pause;
                        lfseek(lf,pposit)
                      end
                  end
              end;
            clearmessage(lx,ly)
          end
        else if choice = chr(20) then
          begin
            numclass := (numclass + 1) mod 7;
            case numclass of
              0: iter := 1;
              1: iter := 2;
              2: iter := 4;
              3: iter := 4;
              4: iter := 6;
              5: iter := 8;
              6: iter := ctab
            end
          end
        else if choice = chr(25) then
          begin
            if (curmode <> 1) and (inedit) then
              begin
                displaymessage('Delete how many bytes? ',lx,ly);
                getinput(temp,escpressed);
                if not escpressed then
                  begin
                    val(temp,tempval,code);
                    lfdelete(lf,tempval);
                    display(lf,ascii,base);
                    clearmessage(wherex,wherey)
                  end
                else clearmessage(lx,ly)
              end
          end
        else if (inedit) and (not ascii) and (choice in ['I','i']) then
          begin
            displaymessage('Integer: ',lx,ly);
            getinput(temp,escpressed);
            if not escpressed then
              begin
                val(temp,iptr^,code);
                if insert then
                  begin
                    lfinsert(lf,2,success);
                    if not success then
                      begin
                        clearmessage(lx,ly);
                        displaymessage(chr(7)+'Out of disk space.  Press any key.',lx,ly);
                        pause
                      end;
                    display(lf,ascii,base)
                  end;
                for c := 0 to 1 do
                  begin
                    lfwrite(lf,num[c]);
                    updatebyte(lf,ascii,base);
                    moveright(lf,ascii,base)
                  end;
                lx := wherex;
                ly := wherey
              end;
            clearmessage(lx,ly)
          end
        else if (inedit) and (not ascii) and (choice in ['L','l']) then
          begin
            displaymessage('Longint: ',lx,ly);
            getinput(temp,escpressed);
            if not escpressed then
              begin
                val(temp,lptr^,code);
                if insert then
                  begin
                    lfinsert(lf,4,success);
                    if not success then
                      begin
                        clearmessage(lx,ly);
                        displaymessage(chr(7)+'Out of disk space.  Press any key.',lx,ly);
                        pause
                      end;
                    display(lf,ascii,base)
                  end;
                for c := 0 to 3 do
                  begin
                    lfwrite(lf,num[c]);
                    updatebyte(lf,ascii,base);
                    moveright(lf,ascii,base)
                  end;
                lx := wherex;
                ly := wherey
              end;
            clearmessage(lx,ly)
          end
        else if (inedit) and (not ascii) and (choice in ['S','s']) then
          begin
            displaymessage('Single: ',lx,ly);
            getinput(temp,escpressed);
            if not escpressed then
              begin
                val(temp,rptr^,code);
                if insert then
                  begin
                    lfinsert(lf,4,success);
                    if not success then
                      begin
                        clearmessage(lx,ly);
                        displaymessage(chr(7)+'Out of disk space.  Press any key.',lx,ly);
                        pause
                      end;
                    display(lf,ascii,base)
                  end;
                for c := 0 to 3 do
                  begin
                    lfwrite(lf,num[(c + 3) mod 6]);
                    updatebyte(lf,ascii,base);
                    moveright(lf,ascii,base)
                  end;
                lx := wherex;
                ly := wherey
              end;
            clearmessage(lx,ly)
          end
        else if (inedit) and (not ascii) and (choice in ['P','p']) then
          begin
            displaymessage('6-byte: ',lx,ly);
            getinput(temp,escpressed);
            if not escpressed then
              begin
                val(temp,rptr^,code);
                if insert then
                  begin
                    lfinsert(lf,6,success);
                    if not success then
                      begin
                        clearmessage(lx,ly);
                        displaymessage(chr(7)+'Out of disk space.  Press any key.',lx,ly);
                        pause
                      end;
                    display(lf,ascii,base)
                  end;
                for c := 0 to 5 do
                  begin
                    lfwrite(lf,num[c]);
                    updatebyte(lf,ascii,base);
                    moveright(lf,ascii,base)
                  end;
                lx := wherex;
                ly := wherey
              end;
            clearmessage(lx,ly)
          end
        else if (inedit) and (not ascii) and (choice in ['X','x']) then
          begin
            displaymessage('Double: ',lx,ly);
            getinput(temp,escpressed);
            if not escpressed then
              begin
                val(temp,rptr^,code);
                if insert then
                  begin
                    lfinsert(lf,8,success);
                    if not success then
                      begin
                        clearmessage(lx,ly);
                        displaymessage(chr(7)+'Out of disk space.  Press any key.',lx,ly);
                        pause
                      end;
                    display(lf,ascii,base)
                  end;
                for c := 0 to 1 do
                  begin
                    lfwrite(lf,0);
                    updatebyte(lf,ascii,base);
                    moveright(lf,ascii,base)
                  end;
                for c := 2 to 7 do
                  begin
                    lfwrite(lf,num[(c - 1) mod 6]);
                    updatebyte(lf,ascii,base);
                    moveright(lf,ascii,base)
                  end;
                lx := wherex;
                ly := wherey
              end;
            clearmessage(lx,ly)
          end
        else if (curmode <> 1) and (choice > chr(31)) and
             (choice < chr(126)) and (inedit) then
          begin
            if ascii then
              begin
                if insert then
                  begin
                    lfinsert(lf,1,success);
                    if not success then
                      begin
                        displaymessage(chr(7)+'Out of disk space.  Press any key.',lx,ly);
                        pause;
                        clearmessage(lx,ly)
                      end;
                    display(lf,ascii,base)
                  end;
                lfwrite(lf,ord(choice));
                updatebyte(lf,ascii,base);
                moveright(lf,ascii,base)
              end
            else
              begin
                case base of
                  0:if choice in ['0'..'9','A'..'F','a'..'f'] then
                      begin
                        if insert then
                          begin
                            lfinsert(lf,1,success);
                            if not success then
                              begin
                                displaymessage(chr(7)+
                                  'Out of disk space.  Press any key.',lx,ly);
                                pause;
                                clearmessage(lx,ly)
                              end;
                            display(lf,ascii,base)
                          end;
                        lfwrite(lf,edithex(choice));
                        updatebyte(lf,ascii,base);
                        moveright(lf,ascii,base)
                      end;
                  1:if choice in ['0'..'2'] then
                      begin
                        if insert then
                          begin
                            lfinsert(lf,1,success);
                            if not success then
                              begin
                                displaymessage(chr(7)+
                                  'Out of disk space.  Press any key.',lx,ly);
                                pause;
                                clearmessage(lx,ly)
                              end;
                            display(lf,ascii,base)
                          end;
                        lfwrite(lf,editdec(choice));
                        updatebyte(lf,ascii,base);
                        moveright(lf,ascii,base)
                      end;
                  2:if choice in ['0'..'3'] then
                      begin
                        if insert then
                          begin
                            lfinsert(lf,1,success);
                            if not success then
                              begin
                                displaymessage(chr(7)+
                                  'Out of disk space.  Press any key.',lx,ly);
                                pause;
                                clearmessage(lx,ly)
                              end;
                            display(lf,ascii,base)
                          end;
                        lfwrite(lf,editoct(choice));
                        updatebyte(lf,ascii,base);
                        moveright(lf,ascii,base)
                      end
                end
              end
          end;
        lx := wherex;
        ly := wherey;
        lposit := lfcurpos(lf);
        gotoxy(1,24);
        case numclass of
          0:write('':33);
          1:begin
              write('Integer: ');
              if lposit < lfsize(lf) - 2 then
                begin
                  for c := 0 to 1 do
                    begin
                      lfseek(lf,lposit + c);
                      num[c] := lfread(lf)
                    end;
                  write(iptr^:16);
                  write('':8)
                end
              else write('':24)
            end;
          2:begin
              write('Longint: ');
              if lposit < lfsize(lf) - 4 then
                begin
                  for c := 0 to 3 do
                    begin
                      lfseek(lf,lposit + c);
                      num[c] := lfread(lf)
                    end;
                  write(lptr^:16);
                  write('':8)
                end
              else write('':24)
            end;
          3:begin
              write('Single: ');
              if lposit < lfsize(lf) - 4 then
                begin
                  for c := 1 to 2 do
                    num[c] := 0;
                  for c := 0 to 3 do
                    begin
                      lfseek(lf,lposit + c);
                      num[(c + 3) mod 6] := lfread(lf)
                    end;
                  write(rptr^:17);
                  write('':8)
                end
              else write('':25)
            end;
          4:begin
              write('6-byte: ');
              if lposit < lfsize(lf) - 6 then
                begin
                  for c := 0 to 5 do
                    begin
                      lfseek(lf,lposit + c);
                      num[c] := lfread(lf)
                    end;
                  write(rptr^:17);
                  write('':8)
                end
              else write('':25)
            end;
          5:begin
              write('Double: ');
              if lposit < lfsize(lf) - 8 then
                begin
                  for c := 2 to 7 do
                    begin
                      lfseek(lf,lposit + c);
                      num[(c - 1) mod 6] := lfread(lf)
                    end;
                  write(rptr^:17);
                  write('':8)
                end
              else write('':25)
            end;
          6:begin
              write(ctab,'-byte (Alt-T changes size): ');
              write('':4)
            end
        end;
        gotoxy(lx,ly);
        lfseek(lf,lposit)
      until done;
      freemem(blkdata.dataptr,TRSIZE)
    end;





  Function filevalid(filename:string):boolean;

    var f:file;

    begin
      if fileexists(filename) then
        begin
          assign(f,filename);
          reset(f,1);
          filevalid := (filesize(f) > 0)
        end
      else filevalid := false
    end;

  Procedure createfile(filename:string;var success:boolean);

    var f:file;
        dummy:byte;
        numwritten:word;

    begin
      success := true;
      assign(f,filename);
      rewrite(f,1);
      dummy := 0;
      blockwrite(f,dummy,1,numwritten);
      if numwritten < 1 then success := false;
      close(f)
    end;


  Procedure menu(var c:integer);

    var temp:string;
        code:integer;
        escpressed:boolean;

    begin
      clrscr;
      gotoxy(1,7);
      writeln('M A I N   M E N U':48);
      gotoxy(10,10);
      write('1.  Open file');
      gotoxy(10,12);
      write('2.  Quit');
      gotoxy(1,14);
      write('Pick one: ');
      getinput(temp,escpressed);
      val(temp,c,code)
    end;


  begin
    done := false;
    repeat
      menu(choice);
      case choice of
        1:begin
            clrscr;
            gotoxy(1,12);
            write('Open what file? ');
            getinput(filename,escpressed);
            if not escpressed then
              begin
                if filevalid(filename) then
                  editfile(filename)
                else
                  begin
                    gotoxy(1,14);
                    write('Cannot find that file.  Create a new one <y,n>? ');
                    getinput(temp,escpressed);
                    if (length(temp) >= 1) and (temp[1] in ['Y','y']) then
                      begin
                        if filecreation(filename) then
                          begin
                            createfile(filename,success);
                            if not success then
                              begin
                                writeln;
                                write(chr(7)+'Out of disk space.  Press any key.')
                              end
                            else editfile(filename)
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
        2:done := true
      end
    until done
  end.