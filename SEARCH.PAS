program showprimes;

  uses crt;

  type filetype=file of longint;

  var f:filetype;
      filename:string;
      outfile:string;
      posit,fposit,x:longint;
      found,escpressed:boolean;
      choice:char;

  Function fileexists(filename:string):boolean;

    var error:integer;
            f:file;

    begin
      assign(f,filename);
      {$I-}
        reset(f);
      {$I+}
      error := IOresult;
      if error = 0 then
        begin
          close(f);
          fileexists := true
        end
      else fileexists := false
    end;

  Function filevalid(filename:string):boolean;

    var f:file of byte;
        size:longint;

    begin
      if not fileexists(filename) then filevalid := false
      else
        begin
          assign(f,filename);
          reset(f);
          size := filesize(f);
          if (size = 0) or (size mod 4 <> 0) then filevalid := false
          else filevalid := true
        end
    end;

  Procedure getinput(var x:string;var escpressed:boolean);

    var done:boolean;
        temp:char;

    begin
      done := false;
      x := '';
      while (not done) do
        begin
          temp := readkey;
          if temp = chr(27) then
            begin
              done := true;
              escpressed := true
            end
          else if temp = chr(13) then
            begin
              done := true;
              escpressed := false
            end
          else if temp = chr(8) then
            begin
              if length(x) > 0 then
                begin
                  x := copy(x,1,length(x)-1);
                  gotoxy(wherex - 1,wherey);
                  write(' ');
                  gotoxy(wherex - 1,wherey)
                end
            end
          else if wherex < 80 then
            begin
              x := x + temp;
              write(temp)
            end
        end
    end;

  Procedure findnum(var f:filetype;num:longint;var posit:longint;var found:boolean);

    var first,mid,last,valf,valm,vall:longint;

    begin
      last := filesize(f) - 1;
      first := 0;
      if last = 0 then
        begin
          posit := 0;
          seek(f,last);
          read(f,valf);
          if num = valf then found := true
          else found := false
        end
      else
        begin
          seek(f,first);
          read(f,valf);
          seek(f,last);
          read(f,vall);
          if (num <= valf) then
            begin
              posit := first;
              if (num = valf) then found := true
              else found := false
            end
          else if (num >= vall) then
            begin
              posit := last;
              if (num = vall) then found := true
              else found := false
            end
          else
            begin
              found := false;
              while (first + 1 < last) and (not found) do
                begin
                  mid := first + (last - first) div 2;
                  seek(f,mid);
                  read(f,valm);
                  if (valm = num) then
                    begin
                      found := true;
                      posit := mid
                    end
                  else if (valm < num) then
                    first := mid
                  else
                    last := mid
                end;
              if (not found) then posit := first
            end
        end
    end;

  Procedure showscreen(var f:filetype;var filename:string;fposit,posit:longint;found:boolean);

    var start,cnt,val:longint;

    begin
      clrscr;
      writeln('FILE:  ',filename);
      writeln;
      writeln('   LINE NO.   '+chr(179)+'     DATA     ');
      for cnt := 1 to 14 do write(chr(196));
      write(chr(197));
      for cnt := 1 to 14 do write(chr(196));
      writeln;
      start := 15 * (posit div 15);
      seek(f,start);
      for cnt := start to start + 14 do
        begin
          if eof(f) then
            writeln(chr(179):15)
          else
            begin
              read(f,val);
              if ((cnt = fposit) and (found)) then
                begin
                  textcolor(14);
                  write(cnt+1:10);
                  textcolor(7);
                  write(chr(179):5);
                  textcolor(14);
                  writeln(val:14);
                  textcolor(7);
                end
              else
                begin
                  write(cnt+1:10);
                  write(chr(179):5);
                  writeln(val:14)
                end
            end
        end
    end;

  Procedure printnumlist(var f:filetype;filename:string);

    var g:text;
        posit:integer;
        escpressed:boolean;
        dummy:char;
        val:longint;
        cnt:longint;

    procedure heading;

      var i:integer;

      begin
        for i := 1 to 5 do writeln(g);
        posit := posit + 5
      end;

    procedure ffeed;

      var i:integer;

      begin
        for i := 1 to 66-posit do writeln(g);
        posit := 0
      end;

    begin
      assign(g,filename);
      rewrite(g);
      { write(g,chr(27)+'6'); }
      escpressed := false;
      seek(f,0);
      cnt := 0;
      posit := 0;
      while (not escpressed) and (not eof(f)) do
        begin
          read(f,val);
          if cnt mod 250 = 0 then
            begin
              if cnt > 0 then
                ffeed;
              heading;
              write(g,cnt:5,':')
            end
          else if cnt mod 5 = 0 then
            begin
              writeln(g);
              posit := posit + 1;
              write(g,cnt:5,':')
            end;
          write(g,val:12);
          cnt := cnt + 1;
          if keypressed then
            begin
              dummy := readkey;
              if dummy = chr(0) then dummy := readkey;
              if dummy = chr(27) then escpressed := true
            end
        end;
      ffeed;
      close(g)
    end;


  Procedure menu(var filename:string;var choice:char);

    begin
      clrscr;
      writeln('FILE:  ',filename);
      gotoxy(1,3);
      writeln('M A I N   M E N U':48);
      gotoxy(29,6);
      writeln('1.  Go to line number');
      gotoxy(29,8);
      writeln('2.  Search for a number');
      gotoxy(29,10);
      writeln('3.  Display number list');
      gotoxy(29,12);
      writeln('4.  Print numbers');
      gotoxy(29,14);
      writeln('5.  Quit');
      writeln;
      write('Pick one: ');
      readln(choice)
    end;

  Procedure Openfile(var f:filetype;var filename:string;var fposit,posit:longint;var found:boolean);

    begin
      assign(f,filename);
      reset(f);
      fposit := 0;
      posit := 0;
      found := false
    end;

  Procedure getgotoinfo(var f:filetype;var posit:longint;var found,escpressed:boolean);

    var temp:string;
        code:integer;

    begin
      clrscr;
      gotoxy(1,12);
      write('Enter line number: ');
      getinput(temp,escpressed);
      if not escpressed then
        begin {user did not exit}
          val(temp,posit,code);
          posit := posit - 1;
          if ((posit >= 0) and (posit < filesize(f))) then
            found := true
          else
            begin {line number out of range}
              if (posit < 0) then posit := 0
              else posit := filesize(f) - 1;
              found := false
            end {line number out of range}
        end {user did not exit}
    end;

  Procedure getsearchinfo(var x:longint;var escpressed:boolean);

    var temp:string;
        code:integer;

    begin
      clrscr;
      gotoxy(1,12);
      write('Enter number to search for: ');
      getinput(temp,escpressed);
      if not escpressed then val(temp,x,code)
    end;

  Procedure getprintinfo(var x:string;var escpressed:boolean);

    begin
      clrscr;
      gotoxy(1,12);
      write('Enter output file name: ');
      getinput(x,escpressed)
    end;


  Procedure displaynumlist(var f:filetype;var filename:string;fposit:longint;var posit:longint;found:boolean);

    var choice,schoice:char;
        done:boolean;

    begin
      done := false;
      showscreen(f,filename,fposit,posit,found);
      repeat
        choice := readkey;
        if choice = chr(27) then done := true
        else if choice = chr(0) then
          begin
            schoice := readkey;
            if schoice = 'H' then
              begin
                if posit >= 15 then
                  begin
                    posit := posit - 15;
                    showscreen(f,filename,fposit,posit,found)
                  end
              end
            else if schoice = 'P' then
              begin
                if (15 * (posit div 15) < filesize(f) - 15) then
                  begin
                    posit := posit + 15;
                    showscreen(f,filename,fposit,posit,found)
                  end
              end
          end
      until done
    end;


  begin
    filename := paramstr(1);
    if not fileexists(filename) then
      begin
        writeln;
        writeln('Cannot find that file.');
        exit
      end;
    if not filevalid(filename) then
      begin
        writeln;
        writeln('That file is not a number file.');
        exit
      end;
    openfile(f,filename,fposit,posit,found);
    repeat
      menu(filename,choice);
      case choice of
        '1':begin
              getgotoinfo(f,fposit,found,escpressed);
              if not escpressed then
                begin
                  posit := fposit;
                  displaynumlist(f,filename,fposit,posit,found)
                end
            end;
        '2':begin
              getsearchinfo(x,escpressed);
              if not escpressed then
                begin
                  findnum(f,x,fposit,found);
                  posit := fposit;
                  displaynumlist(f,filename,fposit,posit,found)
                end
            end;
        '3':displaynumlist(f,filename,fposit,posit,found);
        '4':begin
              getprintinfo(outfile,escpressed);
              if not escpressed then
                printnumlist(f,outfile)
            end
      end
    until (choice = '5');
    close(f)
  end.
