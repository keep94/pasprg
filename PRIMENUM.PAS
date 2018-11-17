program primes;

  uses crt;

  type arraytype = array[0..65519] of boolean;
       ptrtype = ^arraytype;
       filetype = file of longint;

  var choice:char;

  Procedure menu(var choice:char);

    begin
      clrscr;
      gotoxy(1,5);
      write('M A I N   M E N U':43);
      gotoxy(1,8);
      write('1.  Create a prime number file':50);
      gotoxy(1,10);
      write('2.  Append to a prime number file':53);
      gotoxy(1,12);
      write('3.  Truncate a prime number file':52);
      gotoxy(1,14);
      write('4.  Quit':28);
      gotoxy(1,17);
      write('Pick one: ');
      readln(choice)
    end;

  Procedure truncmenu(var choice:char);

    begin
      clrscr;
      gotoxy(1,5);
      write('T R U N C A T E   M E N U':47);
      gotoxy(1,8);
      write('1.  Truncate at line number':48);
      gotoxy(1,10);
      write('2.  Truncate at data':41);
      gotoxy(1,12);
      write('3.  Go back to main menu':45);
      gotoxy(1,15);
      write('Pick one: ');
      readln(choice)
    end;

  Procedure waitesc;

    var dummy:char;

    begin
      repeat
        dummy := readkey
      until (dummy = chr(27))
    end;

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
          if (size mod 4 <> 0) then filevalid := false
          else filevalid := true;
          close(f)
        end
    end;

  Function isnumfile(filename:string):boolean;

    begin
      if (not fileexists(filename)) then
        begin
          writeln;
          writeln;
          write('That file does not exist.  Press ESC to continue.');
          waitesc;
          isnumfile := false
        end
      else if (not filevalid(filename)) then
        begin
          writeln;
          writeln;
          write('That file is not a number file.  Press ESC to continue.');
          waitesc;
          isnumfile := false
        end
      else isnumfile := true
    end;

  Procedure initprimes(p:ptrtype);

    var cnt:word;

    begin
      for cnt := 0 to 65519 do p^[cnt] := true
    end;

  Procedure getprimes(p:ptrtype;start:longint);

    var sqvalue,offset,nextone,cnt:longint;

    begin
      initprimes(p);
      sqvalue := trunc(sqrt(start + 131039));
      for cnt := 1 to (sqvalue - 1) div 2 do
        begin
          if sqr(2*cnt + 1) > start then offset := sqr(2*cnt + 1)
          else offset := (4*cnt + 2) * ((start - 2*cnt - 1) div (4*cnt + 2)) + 6*cnt + 3;
          offset := offset - start;
          offset := (offset - 1) div 2;
          nextone := offset;
          while (nextone < 65520) do
            begin
              p^[nextone] := false;
              nextone := nextone + 2*cnt + 1
            end
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

  Procedure getgotoinfo(var f:filetype;var posit:longint;var found:boolean;var escpressed:boolean);

    var temp:string;
        code:integer;

    begin
      gotoxy(6,8);
      write('Truncate at what line number? ');
      getinput(temp,escpressed);
      if escpressed then exit;
      val(temp,posit,code);
      posit := posit - 1;
      if ((posit >= 0) and (posit < filesize(f))) then
        found := true
      else
        begin
          if (posit < 0) then posit := 0
          else posit := filesize(f) - 1;
          found := false
        end
    end;

  Procedure getsearchinfo(var x:longint;var escpressed:boolean);

    var temp:string;
        code:integer;

    begin
      gotoxy(6,10);
      write('Truncate at what data? ');
      getinput(temp,escpressed);
      if escpressed then exit;
      val(temp,x,code)
    end;

  Procedure newfile;

    var f:filetype;
        response:char;
        filename:string;
        escpressed:boolean;
        pri:longint;
        error:integer;

    begin
      clrscr;
      gotoxy(1,3);
      write('Open what new file? ');
      getinput(filename,escpressed);
      if escpressed then exit;
      response := 'Y';
      writeln;
      if fileexists(filename) then
        begin
          writeln;
          write('That file already exists.  Overwrite<y,n>? ');
          readln(response)
        end;
      if response in ['Y','y'] then
        begin {user selected yes}
          writeln;
          if filecreation(filename) then
            begin {file able to be created}
              assign(f,filename);
              rewrite(f);
              close(f);
              writeln('File ',filename,' has been created.  Press ESC to continue.')
            end {file able to be created}
          else writeln('File creation error.  Press ESC to continue.');
          waitesc
        end {user selected yes}
    end;

  Procedure appendnumfile;

    var escpressed,prgabort,done,finished,iserror:boolean;
        lastprimesaved,pri,lastnum,fromnum,howmany,templast,cnt,dummy1:longint;
        tempstr,filename:string;
        f:filetype;
        code,error:integer;
        p:ptrtype;
        dummy:char;


    begin
      clrscr;
      gotoxy(1,3);
      write('Name of file to append: ');
      getinput(filename,escpressed);
      if escpressed then exit;
      if not isnumfile(filename) then exit;
      assign(f,filename);
      reset(f);
      if eof(f) then lastnum := 0
      else
        begin
          seek(f,filesize(f)-1);
          read(f,lastnum);
          lastnum := 2*((lastnum - 1) div 2) + 2
        end;
      gotoxy(6,6);
      write('Append prime numbers that exceed[');
      write(lastnum);
      write(']: ');
      getinput(tempstr,escpressed);
      if escpressed then
        begin
          close(f);
          exit
        end;
      if tempstr <> '' then
        begin
          val(tempstr,templast,code);
          if templast < 2 then templast := 0
          else templast := 2*((templast - 1) div 2) + 2;
          if templast < lastnum then
            begin
              writeln;
              writeln;
              write('Value entered must be greater than default value.  Press ESC to continue');
              waitesc;
              close(f);
              exit
            end;
          lastnum := templast
        end;
      if lastnum = 0 then
        begin
          dummy1 := 2;
          write(f,dummy1);
          lastnum := 2
        end;
      gotoxy(6,8);
      write('Process to what number? ');
      getinput(tempstr,escpressed);
      if escpressed then
        begin
          close(f);
          exit
        end;
      if tempstr = '' then howmany := 2147483647
      else
        begin
          val(tempstr,howmany,code);
          if howmany < lastnum then
            begin
              writeln;
              writeln;
              write('This number is smaller than starting number.  Press ESC to continue.');
              waitesc;
              close(f);
              exit
            end
        end;
      clrscr;
      new(p);
      seek(f,filesize(f));
      write('C A L C U L A T I N G   P R I M E S':57);
      gotoxy(1,4);
      write('FROM:');
      gotoxy(1,10);
      write('TO:');
      fromnum := lastnum;
      done := false;
      lastprimesaved := lastnum;
      while (fromnum < 2147352608) and (not done) do
        begin
          gotoxy(7,4);
          write(fromnum);
          if (howmany <= fromnum + 131040) then
            begin
              done := true;
              gotoxy(5,10);
              write(howmany)
            end
          else
            begin
              gotoxy(5,10);
              write(fromnum + 131040)
            end;
          getprimes(p,fromnum);
          error := 0;
          finished := false;
          prgabort := false;
          cnt := 0;
          iserror := false;
          while (not iserror) and (cnt < 65520) and (not finished) do
            begin {while}
              if (fromnum + 2*cnt + 1 <= howmany) then
                begin {if}
                  if p^[cnt] then
                    begin {if number is prime}
                      pri := fromnum + 2*cnt + 1;
                      {$I-}
                        write(f,pri);
                      {$I+}
                      error := IOresult;
                      if error > 0 then
                        begin
                          iserror := true;
                          prgabort := true;
                          done := true
                        end;
                      if keypressed then
                        begin
                          dummy := readkey;
                          if dummy = chr(27) then
                          finished := true;
                          prgabort := true;
                          done := true
                        end;
                      if not iserror then lastprimesaved := fromnum + 2*cnt + 1;
                    end; {if number is prime}
                  cnt := cnt + 1
                end {if not done}
              else finished := true;
            end; {while with finished}
          fromnum := fromnum + 131040
        end; {big while with done}
      clrscr;
      close(f);
      if iserror then
        writeln(chr(7)+'Insufficient disk space');
      if prgabort then writeln('Prime number appending aborted.');
      gotoxy(1,4);
      writeln('P R I M E   N U M B E R S   A P P E N D E D':60);
      gotoxy(1,7);
      write('FROM: ',lastnum);
      gotoxy(1,13);
      write('TO: ',lastprimesaved);
      gotoxy(1,17);
      write('Press ESC to continue.');
      waitesc;
      dispose(p)
    end;

  Procedure truncatefile;

    var choice:char;
        filename:string;
        escpressed,found:boolean;
        f:filetype;
        posit,x,firstnum,lastnum:longint;


    begin
      repeat
        truncmenu(choice);
        case choice of
          '1':begin {by line number}
                clrscr;
                gotoxy(1,3);
                write('Enter file to truncate: ');
                getinput(filename,escpressed);
                if not escpressed then
                  begin {user did not exit}
                    if isnumfile(filename) then
                      begin {valid file}
                        assign(f,filename);
                        reset(f);
                        gotoxy(6,6);
                        writeln('Number of lines: ',filesize(f));
                        getgotoinfo(f,posit,found,escpressed);
                        close(f);
                        if not escpressed then
                          begin {user did not exit late}
                            gotoxy(1,12);
                            write('Truncating file ',filename);
                            assign(f,filename);
                            reset(f);
                            seek(f,posit+1);
                            truncate(f);
                            close(f);
                            gotoxy(1,12);
                            write('':80)
                          end {user did not exit late}
                      end {valid file}
                  end {user did not exit}
              end; {by line number}
          '2':begin
                clrscr;
                gotoxy(1,3);
                write('Enter file to truncate: ');
                getinput(filename,escpressed);
                if not escpressed then
                  begin {user did not exit}
                    if isnumfile(filename) then
                      begin {valid file}
                        assign(f,filename);
                        reset(f);
                        read(f,firstnum);
                        seek(f,filesize(f)-1);
                        read(f,lastnum);
                        close(f);
                        gotoxy(6,6);
                        writeln('First data in file: ',firstnum);
                        gotoxy(6,8);
                        writeln('Last data in file: ',lastnum);
                        getsearchinfo(x,escpressed);
                        if not escpressed then
                          begin {user did not exit late}
                            gotoxy(1,14);
                            write('Truncating file ',filename);
                            assign(f,filename);
                            reset(f);
                            findnum(f,x,posit,found);
                            seek(f,posit+1);
                            truncate(f);
                            close(f);
                            gotoxy(1,14);
                            write('':80)
                          end {user did not exit late}
                      end {valid file}
                  end {user did not exit}
              end; {by data}
        end;
      until choice = '3'
    end;


  begin
    repeat
      menu(choice);
      case choice of
        '1':newfile;
        '2':appendnumfile;
        '3':truncatefile
      end
    until (choice = '4')
  end.
