program database;

  uses crt,dos,printer;

  const maxsize = 4096;

  type
    screentype = array[1..25,0..159] of byte;
    lsizetype = array[3..25] of byte;
    node = array[0..65519] of byte;
    ptrtype = ^node;
    entrytype=record
      scr:ptrtype;
      delflag:boolean
    end;
    arraytype=array[1..maxsize] of entrytype;
    dbasetype=record
      size:integer;
      data:arraytype
    end;

    dirlink=^node1;

    node1=record
      next:dirlink;
      dirinfo:string[12]
    end;

  var recname,newfilename,filename,srchkey,nsrchkey,firstfilename,secondfilename:string;
      lsize:lsizetype;
      escpressed,autosort,done,found,firstexist,secondexist:boolean;
      choice,schoice,response,status:char;
      posit,lx,ly,start,saveopt:integer;
      n:dbasetype;


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

  Procedure displaymessage(x:string;var lx,ly:integer);

    begin
      lx := wherex;
      ly := wherey;
      gotoxy(1,1);
      textcolor(7);
      textbackground(0);
      write(x)
    end;

  Procedure clearmessage(lx,ly:integer);

    begin
      gotoxy(1,1);
      textcolor(7);
      textbackground(0);
      write('':80);
      gotoxy(lx,ly)
    end;

  Procedure usermessage(x:string);

    var dummy:char;
        lx,ly:integer;

    begin
      displaymessage('',lx,ly);
      clearmessage(lx,ly);
      displaymessage(chr(7)+x,lx,ly);
      dummy := readkey;
      if dummy = chr(0) then dummy := readkey;
      clearmessage(lx,ly)
    end;

  Procedure printrecordname(var recname:string);

    var cnt,lx,ly:integer;

    begin
      lx := wherex;
      ly := wherey;
      gotoxy(1,1);
      textcolor(7);
      textbackground(0);
      writeln('Record name: ',copy(recname,1,66));
      for cnt := 1 to 80 do write(chr(196));
      gotoxy(lx,ly)
    end;

  Function editrecsize(var recname:string;var lsize:lsizetype):integer;

    var cnt,posit:integer;

    begin
      posit := length(recname) + 1;
      for cnt := 3 to 25 do
        posit := posit + 2*word(lsize[cnt]) + 1;
      editrecsize := posit
    end;

  Function recsize(recptr:ptrtype):integer;

    var cnt:integer;
        posit:integer;

    begin
      posit := recptr^[0]+1;
      for cnt := 3 to 25 do
        posit := posit + 2*word(recptr^[posit]) + 1;
      recsize := posit
    end;

  Procedure puttomemory(var recptr:ptrtype;var recname:string;var lsize:lsizetype);

    var p:^screentype;
        posit:word;
        cnt:word;

    begin
      posit := editrecsize(recname,lsize);
      getmem(recptr,posit);
      move(recname,recptr^,length(recname)+1);
      p := ptr($b800,$0);
      posit := word(recptr^[0]) + 1;
      for cnt := 3 to 25 do
        begin
          recptr^[posit] := lsize[cnt];
          move(p^[cnt,0],recptr^[posit + 1],2*lsize[cnt]);
          posit := posit + 2*word(lsize[cnt]) + 1
        end
    end;

  Procedure show(var recptr:ptrtype;var recname:string;var lsize:lsizetype);

    var p:^screentype;
        posit:word;
        cnt:word;

    begin
      clrscr;
      move(recptr^,recname,recptr^[0]+1);
      p := ptr($b800,$0);
      posit := word(recptr^[0]) + 1;
      for cnt := 3 to 25 do
        begin
          lsize[cnt] := recptr^[posit];
          move(recptr^[posit + 1],p^[cnt,0],2*lsize[cnt]);
          posit := posit + 2*word(lsize[cnt]) + 1
        end;
      printrecordname(recname);
      freemem(recptr,posit)
    end;

  Procedure initialize(var recname:string;var lsize:lsizetype);

    var cnt:integer;

    begin
      clrscr;
      printrecordname(recname);
      for cnt := 3 to 25 do lsize[cnt] := 0
    end;

  Procedure moveup(var xpos,ypos:integer);

    begin
      if ypos = 3 then ypos := 25
      else  ypos := ypos - 1;
      gotoxy(xpos,ypos)
    end;

  Procedure moveleft(var xpos,ypos:integer);

    begin
      if xpos = 1 then
        begin
          xpos := 80;
          ypos := ypos - 1;
          if ypos = 2 then ypos := 25
        end
      else
        xpos := xpos - 1;
      gotoxy(xpos,ypos)
    end;

  Procedure moveright(var xpos,ypos:integer);

    begin
      if xpos = 80 then
        begin
          xpos := 1;
          ypos := ypos + 1;
          if ypos = 26 then ypos := 3
        end
      else
        xpos := xpos + 1;
      gotoxy(xpos,ypos)
    end;

  Procedure movedown(var xpos,ypos:integer);

    begin
      if ypos = 25 then ypos := 3
      else ypos := ypos + 1;
      gotoxy(xpos,ypos)
    end;

  Procedure plotletter(x:char;color:byte;var lsize:lsizetype;var xpos,ypos:integer);

    var p:^screentype;

    begin
      p := ptr($b800,$0);
      if lsize[ypos]<xpos then lsize[ypos] := xpos;
      p^[ypos,2*xpos-2] := ord(x);
      p^[ypos,2*xpos-1] := color;
      moveright(xpos,ypos)
    end;

  Procedure backspace(var lsize:lsizetype;var xpos,ypos:integer);

    var p:^screentype;

    begin
      p := ptr($b800,$0);
      moveleft(xpos,ypos);
      if lsize[ypos] = xpos then lsize[ypos] := lsize[ypos] - 1;
      p^[ypos,2*xpos-2] := 0;
      p^[ypos,2*xpos-1] := 7
    end;

  Procedure carragereturn(var xpos,ypos:integer);

    begin
      if ypos = 25 then ypos := 3
      else ypos := ypos + 1;
      xpos := 1;
      gotoxy(xpos,ypos)
    end;

  Procedure begline(var xpos,ypos:integer);

    begin
      xpos := 1;
      gotoxy(xpos,ypos)
    end;

  Procedure endline(var lsize:lsizetype;var xpos,ypos:integer);

    begin
      xpos := lsize[ypos] + 1;
      if xpos > 80 then xpos := 80;
      gotoxy(xpos,ypos)
    end;

  Procedure insertspace(var lsize:lsizetype;var xpos,ypos:integer);

    var p:^screentype;
        cnt:integer;

    begin
      if xpos<=lsize[ypos] then
        begin
          p := ptr($b800,$0);
          if lsize[ypos] = 80 then lsize[ypos] := lsize[ypos] - 1;
          for cnt := 2*lsize[ypos] - 1 downto 2*xpos-2 do
            p^[ypos,cnt+2] := p^[ypos,cnt];
          p^[ypos,2*xpos-2] := 0;
          p^[ypos,2*xpos-1] := 7;
          lsize[ypos] := lsize[ypos] + 1
        end
    end;

  Procedure deletespace(var lsize:lsizetype;var xpos,ypos:integer);

    var p:^screentype;
        cnt:integer;

    begin
      if xpos<=lsize[ypos] then
        begin
          p := ptr($b800,$0);
          for cnt := 2*xpos-2 to 2*integer(lsize[ypos]) - 3 do
            p^[ypos,cnt] := p^[ypos,cnt+2];
          p^[ypos,2*lsize[ypos]-2] := 0;
          p^[ypos,2*lsize[ypos]-1] := 7;
          if lsize[ypos]>0 then lsize[ypos] := lsize[ypos] - 1
        end
    end;

  Procedure insertline(var lsize:lsizetype;var xpos,ypos:integer);

    var p:^screentype;
        cnt,cnt1:integer;

    begin
      p := ptr($b800,$0);
      for cnt := 24 downto ypos do
        begin
          lsize[cnt+1] := lsize[cnt];
          for cnt1 := 0 to 159 do
           p^[cnt+1,cnt1] := p^[cnt,cnt1]
        end;
      lsize[ypos] := 0;
      p^[ypos,0] := 0;
      for cnt := 1 to 159 do
        p^[ypos,cnt] := 7-p^[ypos,cnt-1];
    end;

  Procedure deleteline(var lsize:lsizetype;var xpos,ypos:integer);

    var p:^screentype;
        cnt,cnt1:integer;

    begin
      p := ptr($b800,$0);
      for cnt := ypos to 24 do
        begin
          lsize[cnt] := lsize[cnt+1];
          for cnt1 := 0 to 159 do
            p^[cnt,cnt1] := p^[cnt+1,cnt1]
        end;
      lsize[25] := 0;
      p^[25,0] := 0;
      for cnt := 1 to 159 do
        p^[25,cnt] := 7-p^[25,cnt-1]
    end;

  Function lineempty(row:word):boolean;

    var p:^screentype;
        cnt:word;
        done:boolean;

    begin
      p := ptr($b800,$0);
      cnt := 0;
      done := false;
      while (cnt<=79) and (not done) do
        if not (p^[row,2*cnt] in [0,32,255]) then done := true
        else cnt := cnt + 1;
      lineempty := not done
    end;

  Function findchar(row:word;ch:char):word;

    var p:^screentype;
        cnt:word;
        done:boolean;

    begin
      p := ptr($b800,$0);
      cnt := 0;
      done := false;
      while (cnt<=79) and (not done) do
        if p^[row,2*cnt] = ord(ch) then done := true
        else cnt := cnt + 1;
      if not done then findchar := 0
      else findchar := cnt + 1
    end;

  Procedure printline(row:word;col:word);

    var p:^screentype;
        cnt,cnt1,spaces:word;

    begin
      if col = 0 then exit;
      p := ptr($b800,$0);
      cnt := col - 1;
      spaces := 0;
      while cnt<=79 do
        begin
          if p^[row,2*cnt] in [0,32,255] then spaces := spaces + 1
          else
            begin
              for cnt1 := 1 to spaces do write(lst,' ');
              write(lst,chr(p^[row,2*cnt]));
              spaces := 0
            end;
          cnt := cnt + 1
        end;
      write(lst,chr(13)+chr(10))
    end;

  Procedure editrecord(var recname:string;var lsize:lsizetype);

    var done:boolean;
        xpos,ypos,lx,ly,code,cnt:integer;
        choice,schoice:char;
        letters:set of char;
        color:byte;
        temp:string;
        escpressed:boolean;
        posit,skips:word;
        pdone:boolean;

    begin
      color := 7;
      letters := [' '..chr(126)];
      xpos := 1;
      ypos := 3;
      gotoxy(xpos,ypos);
      done := false;
      repeat
        choice := readkey;
        case choice of
          chr(8):backspace(lsize,xpos,ypos);
          chr(9):for cnt := 1 to 5 do
                   moveright(xpos,ypos);
          chr(13):carragereturn(xpos,ypos);
          chr(14):insertline(lsize,xpos,ypos);
          chr(25):deleteline(lsize,xpos,ypos);
          chr(27):done := true;
          chr(0):begin
                   schoice := readkey;
                   case schoice of
                   chr(15):for cnt := 1 to 5 do
                             moveleft(xpos,ypos);
                   chr(25):begin
                             cnt := 2;
                             pdone := false;
                             while (cnt<25) and (not pdone) do
                               begin
                                 cnt := cnt + 1;
                                 pdone := not lineempty(cnt)
                               end;
                             if pdone then
                               begin
                                 posit := findchar(cnt,':');
                                 if posit = 80 then posit := 0;
                                 pdone := false;
                                 skips := 0;
                                 while (cnt<=25) and (not pdone) do
                                   begin
                                     skips := skips + 1;
                                     printline(cnt,posit+1);
                                     cnt := cnt + 1;
                                     if cnt<=25 then pdone := lineempty(cnt)
                                   end;
                                 skips := 6 - (skips mod 6);
                                 for cnt := 1 to skips do write(lst,chr(13)+chr(10))
                               end
                           end;
                   chr(46):begin
                             displaymessage('',lx,ly);
                             clearmessage(lx,ly);
                             displaymessage('Enter color: ',lx,ly);
                             getinput(temp,escpressed);
                             if not escpressed then
                             val(temp,color,code);
                             clearmessage(lx,ly);
                             printrecordname(recname)
                           end;
                   chr(19):begin
                             displaymessage('',lx,ly);
                             clearmessage(lx,ly);
                             displaymessage('Enter new record name: ',lx,ly);
                             getinput(temp,escpressed);
                             if not escpressed then
                             recname := temp;
                             clearmessage(lx,ly);
                             printrecordname(recname)
                           end;
                     'G':begline(xpos,ypos);
                     'H':moveup(xpos,ypos);
                     'K':moveleft(xpos,ypos);
                     'M':moveright(xpos,ypos);
                     'O':endline(lsize,xpos,ypos);
                     'P':movedown(xpos,ypos);
                     'R':insertspace(lsize,xpos,ypos);
                     'S':deletespace(lsize,xpos,ypos);
                   end
                 end
        end;
        if choice in letters then plotletter(choice,color,lsize,xpos,ypos)
      until done
    end;

  Function getname(recptr:pointer):string;

    begin
      getname := string(recptr^)
    end;

  Procedure highlight(row,column,size:integer);

    var p:^screentype;
        cnt:integer;

    begin
      p := ptr($b800,$0);
      cnt := column;
      while (cnt<column+size) and (cnt<80) do
        begin
          p^[row,2*cnt-1] := 112;
          cnt := cnt + 1
        end
    end;

  Procedure unhighlight(row,column,size:integer);

    var p:^screentype;
        cnt:integer;

    begin
      p := ptr($b800,$0);
      cnt := column;
      while (cnt<column+size) and (cnt<80) do
        begin
          p^[row,2*cnt-1] := 7;
          cnt := cnt + 1
        end
    end;

  Procedure eraserecord(var recptr:ptrtype);

    var posit:integer;

    begin
      posit := recsize(recptr);
      freemem(recptr,posit)
    end;

  Procedure placerecord(var n:dbasetype;var posit:integer);

    var done:boolean;
        cnt:integer;
        temp:entrytype;

    begin
      if posit > 1 then
        if getname(n.data[posit].scr)<getname(n.data[posit-1].scr) then
          begin
            temp := n.data[posit];
            cnt := posit;
            done := false;
            repeat
              n.data[cnt] := n.data[cnt-1];
              cnt := cnt - 1;
              if cnt = 1 then done := true
              else
                if getname(temp.scr)>=getname(n.data[cnt-1].scr) then done := true
            until done;
            n.data[cnt] := temp;
            posit := cnt
          end;
      if posit < n.size then
        if getname(n.data[posit].scr)>getname(n.data[posit+1].scr) then
          begin
            temp := n.data[posit];
            cnt := posit;
            done := false;
            repeat
              n.data[cnt] := n.data[cnt+1];
              cnt := cnt + 1;
              if cnt = n.size then done := true
              else
                if getname(temp.scr)<=getname(n.data[cnt+1].scr) then done := true
            until done;
            n.data[cnt] := temp;
            posit := cnt
          end
    end;

  Procedure linearsearch(var n:dbasetype;start:integer;var skey:string;var posit:integer;var found:boolean);

    var cnt:integer;

    begin
      found := false;
      cnt := start + 1;
      while (cnt<=n.size) and (not found) do
        if skey = getname(n.data[cnt].scr) then found := true
        else cnt := cnt + 1;
      if found then posit := cnt
    end;

  Procedure binarysearch(var n:dbasetype;skey:string;var posit:integer;var found:boolean);

    var first,mid,last:longint;

    begin
      last := n.size;
      first := 1;
      if last = 1 then
        begin
          posit := 1;
          if skey = getname(n.data[1].scr) then found := true
          else found := false
        end
      else
        begin
          if skey <= getname(n.data[1].scr) then
            begin
              posit := 1;
              if (skey = getname(n.data[1].scr)) then found := true
              else found := false
            end
          else if (skey >= getname(n.data[last].scr)) then
            begin
              posit := last;
              if (skey = getname(n.data[last].scr)) then found := true
              else found := false
            end
          else
            begin
              found := false;
              while (first + 1 < last) and (not found) do
                begin
                  mid := first + (last - first) div 2;
                  if (skey = getname(n.data[mid].scr)) then
                    begin
                      found := true;
                      posit := mid
                    end
                  else if (getname(n.data[mid].scr) < skey) then
                    first := mid
                  else
                    last := mid
                end;
              if (not found) then posit := last
            end
        end
    end;


  Procedure eraseall(var n:dbasetype);

    var cnt:integer;

    begin
      for cnt := 1 to n.size do
        eraserecord(n.data[cnt].scr);
      n.size := 0;
    end;

  Procedure recoverall(var n:dbasetype);

    var cnt:integer;

    begin
      for cnt := 1 to n.size do
        n.data[cnt].delflag := false
    end;

  Procedure markall(var n:dbasetype);

    var cnt:integer;

    begin
      for cnt := 1 to n.size do
        n.data[cnt].delflag := true
    end;

  Procedure deleterecords(var n:dbasetype);

    var oldcnt,newcnt:integer;

    begin
      oldcnt := 0;
      newcnt := 0;
      while oldcnt<n.size do
        begin
          oldcnt := oldcnt + 1;
          if n.data[oldcnt].delflag then
            eraserecord(n.data[oldcnt].scr)
          else
            begin
              newcnt := newcnt + 1;
              n.data[newcnt] := n.data[oldcnt]
            end
        end;
      n.size := newcnt
    end;

  Procedure sort(var n:dbasetype);

    var cnt,cnt1,inter,posit,exam,st:integer;
        temp:entrytype;
        done:boolean;

    begin
      inter := 1;
      while inter < n.size do
        inter := inter * 3 + 1;
      inter := (inter div 3) div 3;
      if inter = 0 then inter := 1;
      repeat
        for cnt := 1 to inter do
          begin
            posit := cnt+inter;
            while (posit<=n.size) do
              begin
                temp := n.data[posit];
                exam := posit - inter;
                done := false;
                while (exam >= 1) and (not done) do
                  begin
                    if getname(temp.scr)>=getname(n.data[exam].scr) then done := true
                    else exam := exam - inter
                  end;
                st := exam + inter;
                cnt1 := posit - inter;
                while (cnt1 >= st) do
                  begin
                    n.data[cnt1+inter] := n.data[cnt1];
                    cnt1 := cnt1 - inter
                  end;
                n.data[st] := temp;
                posit := posit + inter
              end;
          end;
        inter := inter div 3
      until (inter = 0)
    end;



  Procedure savedatabase(var n:dbasetype;var autosort:boolean;var filename:string;marked:integer);

    var cnt,size,numwritten:integer;
        f:file;
        writeit:boolean;

    begin
      assign(f,filename);
      rewrite(f,1);
      blockwrite(f,autosort,sizeof(autosort),numwritten);
      if numwritten < sizeof(autosort) then
        begin
          usermessage('Insufficient disk space.');
          close(f);
          erase(f);
          exit
        end;
      cnt := 0;
      while (cnt < n.size) do
        begin
          cnt := cnt + 1;
          writeit := not n.data[cnt].delflag;
          if marked = 1 then writeit := not writeit
          else if marked = 2 then writeit := true;
          if writeit then
            begin
              size := recsize(n.data[cnt].scr);
              blockwrite(f,size,sizeof(size),numwritten);
              if numwritten < sizeof(size) then
                begin
                  usermessage('Insufficient disk space.');
                  close(f);
                  erase(f);
                  exit
                end;
              blockwrite(f,n.data[cnt].scr^,size,numwritten);
              if numwritten < size then
                begin
                  usermessage('Insufficient disk space.');
                  close(f);
                  erase(f);
                  exit
                end
            end
        end;
      close(f)
    end;

  Procedure appenddatabase(var n:dbasetype;var filename:string;marked:integer);

    var f:file;
        dummy,writeit:boolean;
        cnt,size,numread,numwritten:integer;

    begin
      assign(f,filename);
      reset(f,1);
      dummy := false;
      blockwrite(f,dummy,sizeof(dummy),numwritten);
      if numwritten < sizeof(dummy) then
        begin
          usermessage('Insufficient disk space.');
          close(f);
          erase(f);
          exit
        end;
      seek(f,filesize(f));
      cnt := 0;
      while (cnt < n.size) do
        begin
          cnt := cnt + 1;
          writeit := not n.data[cnt].delflag;
          if marked = 1 then writeit := not writeit
          else if marked = 2 then writeit := true;
          if writeit then
            begin
              size := recsize(n.data[cnt].scr);
              blockwrite(f,size,sizeof(size),numwritten);
              if numwritten < sizeof(size) then
                begin
                  usermessage('Insufficient disk space.');
                  close(f);
                  erase(f);
                  exit
                end;
              blockwrite(f,n.data[cnt].scr^,size,numwritten);
              if numwritten < size then
                begin
                  usermessage('Insufficient disk space.');
                  close(f);
                  erase(f);
                  exit
                end
            end
        end;
      close(f)
    end;

  Procedure getdatabase(var n:dbasetype;var autosort:boolean;var filename:string);

    var cnt,size,numread:integer;
        f:file;

    begin
      assign(f,filename);
      reset(f,1);
      blockread(f,autosort,sizeof(autosort),numread);
      cnt := 0;
      while (cnt < maxsize) and (not eof(f)) do
        begin
          cnt := cnt + 1;
          blockread(f,size,sizeof(size),numread);
          getmem(n.data[cnt].scr,size);
          n.data[cnt].delflag := false;
          blockread(f,n.data[cnt].scr^,size,numread)
        end;
      n.size := cnt;
      close(f)
    end;

  Procedure printheading(var filename:string;size:integer;autosort:boolean);

    var lx,ly,cnt:integer;

    begin
      lx := wherex;
      ly := wherey;
      gotoxy(1,1);
      write('FILE: ',filename);
      gotoxy(50,1);
      write(size,' RECORDS');
      gotoxy(70,1);
      if autosort then
        writeln('AUTO SORT')
      else
        writeln('         ');
      for cnt := 1 to 80 do write(chr(196));
      gotoxy(lx,ly)
    end;

  Function getrow(posit:integer):integer;

    begin
      getrow := posit - 18*((posit - 1) div 18) + 2
    end;

  Procedure clearrecordnames;

    var cnt:integer;

    begin
      gotoxy(1,3);
      for cnt := 3 to 21 do
        write('':80)
    end;

  Procedure displayrecordnames(var n:dbasetype;var posit:integer);

    var start,cnt:integer;
        p:^screentype;
        done:boolean;

    begin
      clearrecordnames;
      if posit<1 then posit := 1;
      if posit>n.size then posit := n.size;
      if posit = 0 then
        begin
          gotoxy(1,3);
          write('--------  End of database  --------':57);
          posit := 1
        end
      else
        begin
          p := ptr($b800,$0);
          start := 18*((posit - 1) div 18) + 1;
          done := false;
          cnt := start - 1;
          while (cnt < start + 17) and (not done) do
            begin
              cnt := cnt + 1;
              gotoxy(2,getrow(cnt));
              if cnt > n.size then
                begin
                  write('--------  End of database  --------':57);
                  done := true
                end
              else
                begin
                  if n.data[cnt].delflag then
                    begin
                      p^[getrow(cnt),0] := 7;
                      p^[getrow(cnt),1] := 7
                    end;
                  write(copy(getname(n.data[cnt].scr),1,78))
                end
            end;
          if start + 17 = n.size then
            begin
              gotoxy(2,21);
              write('--------  End of database  --------':57)
            end;
          highlight(getrow(posit),2,length(getname(n.data[posit].scr)))
        end
    end;

  Procedure mainup(var n:dbasetype;var posit:integer);

    begin
      if posit > 1 then
        begin
          posit := posit - 1;
          if posit - 18*(posit div 18) = 0 then
            displayrecordnames(n,posit)
          else
            begin
              unhighlight(getrow(posit+1),2,length(getname(n.data[posit + 1].scr)));
              highlight(getrow(posit),2,length(getname(n.data[posit].scr)))
            end
        end
    end;

  Procedure maindown(var n:dbasetype;var posit:integer);

    begin
      if posit < n.size then
        begin
          posit := posit + 1;
          if posit - 18*(posit div 18) = 1 then
            displayrecordnames(n,posit)
          else
            begin
              unhighlight(getrow(posit - 1),2,length(getname(n.data[posit - 1].scr)));
              highlight(getrow(posit),2,length(getname(n.data[posit].scr)))
            end
        end
    end;

  Procedure pageup(var n:dbasetype;var posit:integer);

    begin
      posit := posit - 18;
      displayrecordnames(n,posit)
    end;

  Procedure pagedown(var n:dbasetype;var posit:integer);

    begin
      posit := posit + 18;
      displayrecordnames(n,posit)
    end;

  Procedure markfordel(var n:dbasetype;posit:integer);

    var p:^screentype;

    begin
      p := ptr($b800,$0);
      n.data[posit].delflag := true;
      p^[getrow(posit),0] := 7;
      p^[getrow(posit),1] := 7
    end;

  Procedure clearfromdel(var n:dbasetype;posit:integer);

    var p:^screentype;

    begin
      p := ptr($b800,$0);
      n.data[posit].delflag := false;
      p^[getrow(posit),0] := 0;
      p^[getrow(posit),1] := 7
    end;

  Procedure dosfunctions(var filename:string;numrec:integer;autosort:boolean);

    var tempstr,newname:string;
        choice:char;
        success:boolean;
        error:integer;
        f:file;

    Procedure filemenu(var c:char);

      begin
        clearrecordnames;
        gotoxy(1,3);
        write('F I L E   M E N U':46);
        gotoxy(26,6);
        write('1.  List a directory');
        gotoxy(26,8);
        write('2.  Change current directory');
        gotoxy(26,10);
        write('3.  Rename a file');
        gotoxy(26,12);
        write('4.  Erase a file');
        gotoxy(26,14);
        write('5.  Exit file menu');
        gotoxy(1,17);
        write('Pick one: ');
        readln(c)
      end;

  Procedure dirusermessage(x:string);

    var lx,ly:integer;
        dummy:char;

    begin
      lx := wherex;
      ly := wherey;
      gotoxy(1,23);
      write(x);
      dummy := readkey;
      if dummy = chr(0) then dummy :=readkey;
      gotoxy(1,23);
      write('':80);
      gotoxy(lx,ly)
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
      writeln('Directory of ',fexpand(mask),':');
      textcolor(7);
      writeln;
      getfiles(mask,beg);
      if beg = nil then
        begin
          writeln('File not found.');
          textcolor(15);
          dirusermessage('Press any key to continue.');
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
              dirusermessage('Press any key to continue.');
              textcolor(7)
            end
        end;
      cleardir(beg)
    end;

    begin
      repeat
        filemenu(choice);
        case choice of
          '1':begin
                displaymessage('',lx,ly);
                clearmessage(lx,ly);
                displaymessage('Enter directory mask[*.*]: ',lx,ly);
                getinput(tempstr,escpressed);
                clearmessage(lx,ly);
                if not escpressed then
                  begin
                    if tempstr = '' then tempstr := '*.*';
                    directory(tempstr);
                    clrscr
                  end;
                printheading(filename,numrec,autosort)
              end;
          '2':begin
                displaymessage('',lx,ly);
                clearmessage(lx,ly);
                displaymessage('Enter new current directory: ',lx,ly);
                getinput(tempstr,escpressed);
                clearmessage(lx,ly);
                if not escpressed then
                  begin
                    {$I-}
                      chdir(tempstr);
                    {$I+}
                    error := IOresult;
                    if error <> 0 then
                      usermessage('Cannot find that directory.')
                  end;
                printheading(filename,numrec,autosort)
              end;
          '3':begin
                displaymessage('',lx,ly);
                clearmessage(lx,ly);
                displaymessage('Enter file to be renamed: ',lx,ly);
                getinput(tempstr,escpressed);
                clearmessage(lx,ly);
                if not escpressed then
                  begin
                    if fileexists(tempstr) then
                      begin
                        assign(f,tempstr);
                        success := true
                      end
                    else
                      begin
                        usermessage('Cannot find that file.');
                        success := false
                      end;
                    if success then
                      begin
                        displaymessage('Enter new name for file: ',lx,ly);
                        getinput(newname,escpressed);
                        clearmessage(lx,ly);
                        if not escpressed then
                          begin
                            {$I-}
                            rename(f,newname);
                            {$I+}
                            error := IOresult;
                            if error <> 0 then
                              usermessage('A file already exists by that name.')
                          end
                      end
                  end;
                printheading(filename,numrec,autosort)
              end;
          '4':begin
                displaymessage('',lx,ly);
                clearmessage(lx,ly);
                displaymessage('Enter file to be erased: ',lx,ly);
                getinput(tempstr,escpressed);
                clearmessage(lx,ly);
                if not escpressed then
                  begin
                    if fileexists(tempstr) then
                      begin
                        assign(f,tempstr);
                        erase(f)
                      end
                    else
                      usermessage('Cannot find that file.')
                  end;
                printheading(filename,numrec,autosort)
              end
        end
      until (choice = '5')
    end;

  begin
    clrscr;
    textcolor(7);
    textbackground(0);
    posit := 1;
    filename := fexpand('noname');
    n.size := 0;
    autosort := true;
    done := false;
    printheading(filename,n.size,autosort);
    displayrecordnames(n,posit);
    repeat
      choice := readkey;
      case choice of
        chr(12):if n.size > 0 then
                  if autosort then
                    begin
                      binarysearch(n,srchkey,posit,found);
                      displayrecordnames(n,posit)
                    end
                  else
                    begin
                      start := posit;
                      linearsearch(n,start,srchkey,posit,found);
                      if not found then
                        begin
                          usermessage('Record not found.');
                          printheading(filename,n.size,autosort)
                        end
                      else
                        displayrecordnames(n,posit)
                    end;
        chr(13):if n.size > 0 then
                  begin
                    show(n.data[posit].scr,recname,lsize);
                    editrecord(recname,lsize);
                    puttomemory(n.data[posit].scr,recname,lsize);
                    if autosort then placerecord(n,posit);
                    textcolor(7);
                    textbackground(0);
                    clrscr;
                    printheading(filename,n.size,autosort);
                    displayrecordnames(n,posit)
                  end;
        chr(0):begin
                 schoice := readkey;
                 case schoice of
                    chr(45):begin
                              displaymessage('',lx,ly);
                              clearmessage(lx,ly);
                              displaymessage('Are you sure you want to exit<y,n>? ',lx,ly);
                              readln(response);
                              if response in ['Y','y'] then done := true;
                              clearmessage(lx,ly);
                              printheading(filename,n.size,autosort)
                            end;
                    chr(30):begin
                              if n.size < maxsize then
                                begin
                                  displaymessage('',lx,ly);
                                  clearmessage(lx,ly);
                                  displaymessage('Name of new record: ',lx,ly);
                                  getinput(recname,escpressed);
                                  clearmessage(lx,ly);
                                  printheading(filename,n.size,autosort);
                                  if not escpressed then
                                    begin
                                      initialize(recname,lsize);
                                      editrecord(recname,lsize);
                                      n.size := n.size + 1;
                                      n.data[n.size].delflag := false;
                                      posit := n.size;
                                      puttomemory(n.data[n.size].scr,recname,lsize);
                                      if autosort then placerecord(n,posit);
                                      textcolor(7);
                                      textbackground(0);
                                      clrscr;
                                      printheading(filename,n.size,autosort);
                                      displayrecordnames(n,posit)
                                    end
                                end
                              else
                                begin
                                  usermessage('Out of memory.');
                                  printheading(filename,n.size,autosort)
                                end
                            end;
                    chr(31):if n.size > 0 then
                              begin
                                displaymessage('',lx,ly);
                                clearmessage(lx,ly);
                                displaymessage('Search for? ',lx,ly);
                                getinput(nsrchkey,escpressed);
                                clearmessage(lx,ly);
                                if not escpressed then
                                  begin
                                    srchkey := nsrchkey;
                                    if autosort then
                                      begin
                                        binarysearch(n,srchkey,posit,found);
                                        displayrecordnames(n,posit)
                                      end
                                    else
                                      begin
                                        linearsearch(n,0,srchkey,posit,found);
                                        if not found then
                                          usermessage('Record not found.')
                                        else
                                          displayrecordnames(n,posit)
                                      end
                                  end;
                                printheading(filename,n.size,autosort)
                              end;
                    chr(32):if n.size > 0 then
                              markfordel(n,posit);
                    chr(19):if n.size > 0 then
                              clearfromdel(n,posit);
                    chr(72):if n.size > 0 then
                              mainup(n,posit);
                    chr(80):if n.size > 0 then
                              maindown(n,posit);
                    chr(73):if n.size > 0 then
                              pageup(n,posit);
                    chr(81):if n.size > 0 then
                              pagedown(n,posit);
                    chr(60):begin
                              saveopt := 0;
                              displaymessage('',lx,ly);
                              clearmessage(lx,ly);
                              displaymessage('Save file as['+filename+']? ',lx,ly);
                              getinput(newfilename,escpressed);
                              clearmessage(lx,ly);
                              if not escpressed then
                                begin
                                  displaymessage('Save marked, unmarked records or both<m,u,b>? ',lx,ly);
                                  readln(status);
                                  clearmessage(lx,ly);
                                  if status in ['M','m'] then saveopt := 1
                                  else if status in ['B','b'] then saveopt := 2
                                end;
                              if not escpressed then
                                begin
                                  if newfilename='' then newfilename := filename;
                                  newfilename := fexpand(newfilename);
                                  response := 'Y';
                                  if (fileexists(newfilename)) and (newfilename <> filename) then
                                    begin
                                      displaymessage('That file already exists.  Overwrite<y,n>? ',lx,ly);
                                      readln(response);
                                      clearmessage(lx,ly)
                                    end;
                                  if response in ['Y','y'] then
                                    begin
                                      If filecreation(newfilename) then
                                        begin
                                          displaymessage('SAVING '+newfilename,lx,ly);
                                          savedatabase(n,autosort,newfilename,saveopt);
                                          clearmessage(lx,ly);
                                          filename := newfilename
                                        end
                                      else
                                        usermessage('File creation error.')
                                    end
                                end;
                              printheading(filename,n.size,autosort)
                            end;
                    chr(61):begin
                              displaymessage('',lx,ly);
                              clearmessage(lx,ly);
                              displaymessage('Get what file? ',lx,ly);
                              getinput(newfilename,escpressed);
                              clearmessage(lx,ly);
                              if (not escpressed) and (newfilename<>'') then
                                begin
                                  newfilename := fexpand(newfilename);
                                  if fileexists(newfilename) then
                                    begin
                                      eraseall(n);
                                      displaymessage('Getting '+newfilename,lx,ly);
                                      getdatabase(n,autosort,newfilename);
                                      clearmessage(lx,ly);
                                      filename := newfilename;
                                      posit := 1;
                                      displayrecordnames(n,posit)
                                    end
                                  else
                                    usermessage('Cannot find that file.')
                                end;
                              printheading(filename,n.size,autosort)
                            end;
                    chr(62):begin
                              displaymessage('',lx,ly);
                              clearmessage(lx,ly);
                              if autosort then displaymessage('Turn autosort off<y,n>? ',lx,ly)
                              else displaymessage('Turn autosort on<y,n>? ',lx,ly);
                              readln(response);
                              clearmessage(lx,ly);
                              autosort := autosort xor (response in ['Y','y']);
                              printheading(filename,n.size,autosort);
                              if response in ['Y','y'] then
                                if autosort then
                                  begin
                                    sort(n);
                                    posit := 1;
                                    displayrecordnames(n,posit)
                                  end
                            end;
                    chr(63):begin
                              displaymessage('',lx,ly);
                              clearmessage(lx,ly);
                              displaymessage('Mark all records<y,n>? ',lx,ly);
                              readln(response);
                              clearmessage(lx,ly);
                              if response in ['Y','y'] then
                                begin
                                  markall(n);
                                  displayrecordnames(n,posit)
                                end;
                              printheading(filename,n.size,autosort);
                            end;
                    chr(64):begin
                              saveopt := 0;
                              displaymessage('',lx,ly);
                              clearmessage(lx,ly);
                              displaymessage('Append records to? ',lx,ly);
                              getinput(newfilename,escpressed);
                              clearmessage(lx,ly);
                              if newfilename = '' then escpressed := true;
                              if not escpressed then
                                begin
                                  displaymessage('Save marked, unmarked records, or both<m,u,b>? ',lx,ly);
                                  readln(status);
                                  clearmessage(lx,ly);
                                  if status in ['M','m'] then saveopt := 1
                                  else if status in ['B','b'] then saveopt := 2;
                                  if fileexists(newfilename) then
                                    begin
                                      newfilename := fexpand(newfilename);
                                      displaymessage('APPENDING TO '+newfilename,lx,ly);
                                      appenddatabase(n,newfilename,saveopt);
                                      clearmessage(lx,ly)
                                    end
                                  else usermessage('Cannot find that file.')
                                end;
                              printheading(filename,n.size,autosort)
                            end;
                    chr(65):begin
                              displaymessage('',lx,ly);
                              clearmessage(lx,ly);
                              displaymessage('Unmark all records<y,n>? ',lx,ly);
                              readln(response);
                              clearmessage(lx,ly);
                              if response in ['Y','y'] then
                                begin
                                  recoverall(n);
                                  displayrecordnames(n,posit)
                                end;
                              printheading(filename,n.size,autosort);
                            end;
                    chr(66):begin
                              displaymessage('',lx,ly);
                              clearmessage(lx,ly);
                              displaymessage('Delete marked records<y,n>? ',lx,ly);
                              readln(response);
                              clearmessage(lx,ly);
                              if response in ['Y','y'] then
                                begin
                                  deleterecords(n);
                                  posit := 1;
                                  displayrecordnames(n,posit)
                                end;
                              printheading(filename,n.size,autosort);
                            end;
                    chr(67):begin
                              displaymessage('',lx,ly);
                              clearmessage(lx,ly);
                              displaymessage('Clear all memory<y,n>? ',lx,ly);
                              readln(response);
                              clearmessage(lx,ly);
                              if response in ['Y','y'] then
                                begin
                                  eraseall(n);
                                  posit := 1;
                                  filename := fexpand('noname');
                                  displayrecordnames(n,posit)
                                end;
                              printheading(filename,n.size,autosort);
                            end;
                    chr(68):begin
                              dosfunctions(filename,n.size,autosort);
                              clrscr;
                              printheading(filename,n.size,autosort);
                              displayrecordnames(n,posit)
                            end;
                  end
                end
      end
    until done
  end.
