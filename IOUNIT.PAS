unit IOunit;

interface

uses afstore;

  type
    settype = set of byte;

  Procedure pause;

  Procedure caps(var x:string);

  Function printerready:boolean;

  Function fileexists(filename:string):boolean;

  Function filecreation(filename:string):boolean;

  Procedure createnewfile(filename:string);

  Function filevalid(filename:string;recsize:word):boolean;

  Procedure getinput(var x:string;var escpressed:boolean);

  Procedure returninput(var x:string;var choice,schoice:char;var ctrl,scan:settype);

  Procedure fieldinput(var x:string;inplen:integer;var choice,schoice:char;var ctrl,scan:settype);

  Procedure fieldinputaf(var x:string;inplen:integer;var choice,schoice:char;
  var ctrl,scan:settype;var a:afstoretype;posx,posy:integer);

  Procedure passinput(var x:string;inplen:integer;numonly:boolean;var escpressed:boolean);

  Procedure usermessage(x:string);

implementation

  uses crt,dos;

  type
    scrtype = array[0..3999] of byte;

  Procedure pause;

    var dummy:char;

    begin
      dummy := readkey;
      if dummy = chr(0) then dummy := readkey
    end;

  Procedure caps(var x:string);

    var cnt:word;

    begin
      for cnt := 1 to length(x) do
        if (ord(x[cnt]) > 96) and (ord(x[cnt]) < 123) then
          x[cnt] := chr(ord(x[cnt]) - 32)
    end;

  Function printerready:boolean;

  var x:registers;

  begin
    x.ah := 2;
    x.dx := 0;
    intr(23,x);
    printerready := ((x.ah and 8) = 0)
  end;

  Function fileexists(filename:string):boolean;

    var error:integer;
            f:file;

    begin
      if filename = '' then fileexists := false
      else
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
        end
    end;

  Function filecreation(filename:string):boolean;

    var error:integer;
            f:file;

    begin
      if filename = '' then filecreation := false
      else
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
        end
    end;

  Procedure createnewfile(filename:string);

    var f:file;

    begin
      assign(f,filename);
      rewrite(f);
      close(f)
    end;

  Function filevalid(filename:string;recsize:word):boolean;

    var f:file;
        size:longint;

    begin
      assign(f,filename);
      reset(f,1);
      size := filesize(f);
      close(f);
      filevalid := ((size mod recsize) = 0)
    end;

  Procedure getinput(var x:string;var escpressed:boolean);

    var done:boolean;
        temp,stemp:char;

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
                  x := copy(x,1,length(x) - 1);
                  gotoxy(wherex - 1,wherey);
                  write(' ');
                  gotoxy(wherex - 1,wherey)
                end
            end
          else if temp = chr(0) then
            begin
              stemp := readkey;
              if stemp = chr(75) then
                begin
                  if length(x) > 0 then
                    begin
                      x := copy(x,1,length(x) - 1);
                      gotoxy(wherex - 1,wherey);
                      write(' ');
                      gotoxy(wherex - 1,wherey)
                    end
                end
            end
          else if wherex < 80 then
            begin
              x := x + temp;
              write(temp)
            end
        end
    end;

  Procedure returninput(var x:string;var choice,schoice:char;var ctrl,scan:settype);

    var done:boolean;
        temp:char;

    begin
      done := false;
      x := '';
      while (not done) do
        begin
          temp := readkey;
          if temp = chr(13) then
            begin
              done := true;
              choice := chr(13)
            end
          else if temp = chr(8) then
            begin
              if length(x) > 0 then
                begin
                  x := copy(x,1,length(x) - 1);
                  gotoxy(wherex - 1,wherey);
                  write(' ');
                  gotoxy(wherex - 1,wherey)
                end
            end
          else if ord(temp) in ctrl then
            begin
              done := true;
              choice := temp
            end
          else if temp = chr(0) then
            begin
              temp := readkey;
              if ord(temp) in scan then
                begin
                  done := true;
                  choice := chr(0);
                  schoice := temp
                end
            end
          else if wherex < 80 then
            begin
              x := x + temp;
              write(temp)
            end
        end
    end;


  Procedure fieldinput(var x:string;inplen:integer;var choice,schoice:char;var ctrl,scan:settype);

    var done:boolean;
        temp:char;
        cnt,posit,lx,ly:integer;

    begin
      done := false;
      x := copy(x,1,inplen);
      lx := wherex;
      ly := wherey;
      write(x);
      for cnt := length(x)+1 to inplen do write('_');
      gotoxy(lx,ly);
      posit := 1;
      while (not done) do
        begin
          temp := readkey;
          if temp = chr(13) then
            begin
              done := true;
              choice := chr(13)
            end
          else if temp = chr(8) then
            begin
              if (posit = length(x) + 1) and (length(x) > 0) then
                begin
                  posit := posit - 1;
                  x := copy(x,1,length(x) - 1);
                  gotoxy(wherex - 1,wherey);
                  write('_');
                  gotoxy(wherex - 1,wherey)
                end
              else if (posit > 1) then
                begin
                  posit := posit - 1;
                  gotoxy(wherex - 1,wherey)
                end
            end
          else if ord(temp) in ctrl then
            begin
              done := true;
              choice := temp
            end
          else if temp = chr(0) then
            begin
              temp := readkey;
              if (temp = chr(75)) and (posit > 1) then
                begin
                  posit := posit - 1;
                  gotoxy(wherex - 1,wherey)
                end
              else if (temp = chr(77)) and (posit < length(x) + 1) then
                begin
                  posit := posit + 1;
                  gotoxy(wherex + 1,wherey)
                end
              else if (temp = chr(83)) then
                begin
                  x := copy(x,1,posit - 1);
                  lx := wherex;
                  ly := wherey;
                  for cnt := posit to inplen do write('_');
                  gotoxy(lx,ly)
                end
              else if ord(temp) in scan then
                begin
                  done := true;
                  choice := chr(0);
                  schoice := temp
                end
            end
          else if (posit < inplen + 1) then
            begin
              if (posit = length(x) + 1) then
                begin
                  x := x + temp;
                  write(temp);
                  posit := posit + 1
                end
              else
                begin
                  x[posit] := temp;
                  write(temp);
                  posit := posit + 1
                end
            end
        end;
      lx := wherex;
      ly := wherey;
      gotoxy(lx+length(x) + 1 - posit,ly);
      for cnt := length(x) + 1 to inplen do write(' ');
      gotoxy(lx,ly)
    end;


Procedure displayaf(posx,posy,len:integer;x:string);

var lx:integer;
    ly:integer;

begin
  lx := wherex;
  ly := wherey;
  gotoxy(posx,posy);
  write('':len+4);
  if (x <> '') then
    begin
      gotoxy(posx,posy);
      write('AF: '+copy(x,1,len))
    end;
  gotoxy(lx,ly)
end;


  Procedure fieldinputaf(var x:string;inplen:integer;var choice,schoice:char;
  var ctrl,scan:settype;var a:afstoretype;posx,posy:integer);

    var done:boolean;
        temp:char;
        cnt,posit,lx,ly:integer;
        match:string;
        context:afsearchcontexttype;
        beginContext:afsearchcontexttype;
        startx,starty:integer;

    begin
      match := '';
      beginContext.posit := a.start;
      beginContext.done := false;
      context := beginContext;
      done := false;
      x := copy(x,1,inplen);
      lx := wherex;
      ly := wherey;
      startx := lx;
      starty := wherey;
      write(x);
      for cnt := length(x)+1 to inplen do write('_');
      gotoxy(lx,ly);
      posit := 1;
      while (not done) do
        begin
          temp := readkey;
          if temp = chr(13) then
            begin
              done := true;
              match := '';
              displayaf(posx,posy,inplen,match);
              choice := chr(13)
            end
          else if temp = chr(8) then
            begin
              context := beginContext;
              match := '';
              displayaf(posx,posy,inplen,match);
              if (posit = length(x) + 1) and (length(x) > 0) then
                begin
                  posit := posit - 1;
                  x := copy(x,1,length(x) - 1);
                  gotoxy(wherex - 1,wherey);
                  write('_');
                  gotoxy(wherex - 1,wherey)
                end
              else if (posit > 1) then
                begin
                  posit := posit - 1;
                  gotoxy(wherex - 1,wherey)
                end
            end
          else if ord(temp) in ctrl then
            begin
              done := true;
              match := '';
              displayaf(posx,posy,inplen,match);
              choice := temp
            end
          else if temp = chr(0) then
            begin
              temp := readkey;
              if (temp = chr(75)) and (posit > 1) then
                begin
                  context := beginContext;
                  match := '';
                  displayaf(posx,posy,inplen,match);
                  posit := posit - 1;
                  gotoxy(wherex - 1,wherey)
                end
              else if (temp = chr(77)) and (posit < length(x) + 1) then
                begin
                  context := beginContext;
                  match := '';
                  displayaf(posx,posy,inplen,match);
                  posit := posit + 1;
                  gotoxy(wherex + 1,wherey)
                end
              else if (temp = chr(83)) then
                begin
                  context := beginContext;
                  match := '';
                  displayaf(posx,posy,inplen,match);
                  x := copy(x,1,posit - 1);
                  lx := wherex;
                  ly := wherey;
                  for cnt := posit to inplen do write('_');
                  gotoxy(lx,ly)
                end
              else if (temp = chr(82)) and (match <> '') then
                begin
                  x := copy(match,1,inplen);
                  posit := 1 + length(x);
                  gotoxy(startx,starty);
                  write(x);
                  lx := wherex;
                  ly := wherey;
                  for cnt := posit to inplen do write('_');
                  gotoxy(lx,ly);
                  match := '';
                  displayaf(posx,posy,inplen,match)
                end
              else if ord(temp) in scan then
                begin
                  match := '';
                  displayaf(posx,posy,inplen,match);
                  done := true;
                  choice := chr(0);
                  schoice := temp
                end
            end
          else if (posit < inplen + 1) then
            begin
              if (posit = length(x) + 1) then
                begin
                  x := x + temp;
                  write(temp);
                  if (not afstore_find_next(a,x,match,context)) then
                     match := '';
                  displayaf(posx,posy,inplen,match);
                  posit := posit + 1
                end
              else
                begin
                  context := beginContext;
                  match := '';
                  displayaf(posx,posy,inplen,match);
                  x[posit] := temp;
                  write(temp);
                  posit := posit + 1
                end
            end
        end;
      lx := wherex;
      ly := wherey;
      gotoxy(lx+length(x) + 1 - posit,ly);
      for cnt := length(x) + 1 to inplen do write(' ');
      gotoxy(lx,ly)
    end;


  Procedure passinput(var x:string;inplen:integer;numonly:boolean;var escpressed:boolean);

    var done,addchar:boolean;
        temp:char;
        cnt,x1,y1:integer;
        p:^scrtype;

    begin
      p := ptr($b800,$0);
      x1 := wherex;
      y1 := wherey;
      for cnt := 1 to inplen do
        write(chr(219));
      gotoxy(x1,y1);
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
                  x := copy(x,1,length(x) - 1);
                  gotoxy(wherex - 1,wherey);
                  write(chr(219));
                  gotoxy(wherex - 1,wherey)
                end
            end
          else if length(x) < inplen then
            begin
              if numonly then
                addchar := temp in ['0'..'9']
              else addchar := true;
              if addchar then
                begin
                  x1 := wherex;
                  y1 := wherey;
                  p^[2*(x1-1)+160*(y1-1)] := 8;
                  x := x + temp;
                  x1 := x1 + 1;
                  if x1 > 80 then
                    begin
                      x1 := x1 - 80;
                      y1 := y1 + 1
                    end;
                  if y1 > 25 then y1 := y1 - 25;
                  gotoxy(x1,y1)
                end
            end
        end
    end;

  Procedure usermessage(x:string);

    begin
      write(chr(7)+x);
      pause
    end;

end.