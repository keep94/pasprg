program deflate;

  uses dos,crt,iounit;

  const BUF_SIZE = 32000;
        SENTINAL = 1091489509;
        REMINDFILE = 'REGISMES.TXT';

  type
    larraytype = array[0..255] of longint;
    iarraytype = array[0..255] of integer;
    tabletype = array[0..255] of byte;
    barraytype = array[0..65519] of byte;
    pow2type = array[0..15] of word;
    byte1type = array[0..511] of byte;

    bufptrtype = ^barraytype;

    comprectype = record
      num:integer;
      pl:integer
    end;

    compkeytype = array[1..256] of comprectype;

    ptrtype=^node;
       node=record
         data:searchrec;
         next:ptrtype
       end;

  var lastdir,username,userid,temp,path:string;
      subdir:dirstr;
      name:namestr;
      ext:extstr;
      subdirlen,filecount,error,errorcode:integer;
      done,escpressed:boolean;
      p,top:ptrtype;



  Function min(x,y:longint):longint;

    begin
      if x < y then min := x
      else min := y
    end;

  Procedure getpow2table(var pow2:pow2type);

    var prod,cnt:word;

    begin
      prod := 1;
      for cnt := 0 to 15 do
        begin
          pow2[cnt] := prod;
          prod := prod*2
        end
    end;

  Procedure getpower(x:real;var prod:real;var iexp:integer);

    var i:integer;
        temp:real;

    begin
      temp := 1.0;
      i := 0;
      repeat
        i := i + 1;
        temp := temp / 2.0
      until (temp <= x);
      if x > 1.5*temp then
        begin
          prod := 2.0*temp;
          iexp := i - 1
        end
      else
        begin
          prod := temp;
          iexp := i
        end
    end;

  Procedure get_bit_dist(var p:larraytype;var q:iarraytype;size:integer);

    var i,numleft,idist:integer;
        lpower,power,frac,fimp:real;
        amtleft:longint;


    begin
      numleft := size;
      frac := 1.0;
      amtleft := 0;
      for i := 0 to size - 1 do
        amtleft := amtleft + p[i];
      for i := 0 to size - 1 do
        begin
          fimp := (p[i]/amtleft)*frac;
          getpower(fimp,power,idist);
          if power < (frac / numleft) then
            begin
              power := power*2.0;
              idist := idist - 1
            end;
          if (numleft > 1) and (power >= frac) then
            begin
              power := power / 2.0;
              idist := idist + 1
            end;
          if (i > 0) and (idist < q[i-1]) then
            begin
              power := lpower;
              idist := q[i-1]
            end;
          q[i] := idist;
          numleft := numleft - 1;
          frac := frac - power;
          lpower := power;
          amtleft := amtleft - p[i]
        end
    end;

  Procedure get_comp_key(var q:iarraytype;var ck:compkeytype;size:integer);

    var lastdist,i,cnt:integer;


    begin
      i := 0;
      lastdist := 0;
      for cnt := 0 to size-1 do
        begin
          if q[cnt] > lastdist then
            begin
              i := i + 1;
              ck[i].pl := q[cnt] - lastdist;
              ck[i].num := -1;
              lastdist := q[cnt]
            end;
          ck[i].num := ck[i].num + 1
        end
    end;


  Procedure sort(var freq:larraytype;var uncompr:iarraytype);

    var cnt,incr,posit,newposit,count,size:integer;
        temp:longint;
        temp1:integer;
        done:boolean;

    begin
      size := 256;
      incr := 1;
      while incr < size div 9 do
        incr := incr*3 + 1;
      while incr > 0 do
        begin
          for cnt := 1 to incr do
            begin
              posit := cnt + incr;
              while posit <= size do
                begin
                  newposit := posit - incr;
                  done := false;
                  while not done do
                    begin
                      if freq[posit-1] <= freq[newposit-1] then done := true
                      else newposit := newposit - incr;
                      if newposit < cnt then done := true
                    end;
                  temp := freq[posit-1];
                  temp1 := uncompr[posit-1];
                  count := posit - incr;
                  while count >= newposit + incr do
                    begin
                      freq[count+incr-1] := freq[count-1];
                      uncompr[count+incr-1] := uncompr[count-1];
                      count := count - incr
                    end;
                  freq[newposit+incr-1] := temp;
                  uncompr[newposit+incr-1] := temp1;
                  posit := posit + incr
                end
            end;
          incr := incr div 3
        end
    end;

  Procedure inituncompr(var uncompr:iarraytype);

    var cnt:integer;

    begin
      for cnt := 0 to 255 do uncompr[cnt] := cnt
    end;


  Function getalphasize(var freq:larraytype):integer;

    var cnt:integer;

    begin
      cnt := 0;
      while (cnt < 256) and (freq[cnt] > 0) do
        cnt := cnt + 1;
      getalphasize := cnt
    end;


  Procedure getcompr(var uncompr:iarraytype;var compr:iarraytype);

    var cnt:integer;

    begin
      for cnt := 0 to 255 do
        compr[uncompr[cnt]] := cnt
    end;


  Procedure getfrequency(filename:string;var freq:larraytype);

    var buf:bufptrtype;
        amtleft:longint;
        blsize,cnt,numread:word;
        f:file;

    begin
      for cnt := 0 to 255 do
        freq[cnt] := 0;
      getmem(buf,BUF_SIZE);
      assign(f,filename);
      reset(f,1);
      amtleft := filesize(f);
      while (amtleft > 0) do
        begin
          blsize := min(amtleft,BUF_SIZE);
          blockread(f,buf^,blsize,numread);
          amtleft := amtleft - blsize;
          for cnt := 0 to blsize - 1 do
            freq[buf^[cnt]] := freq[buf^[cnt]] + 1
        end;
      close(f);
      freemem(buf,BUF_SIZE)
    end;


  Function iscompr(filename:string):boolean;

    var earmark,fsize:longint;
        f:file;
        numread:word;

    begin
      assign(f,filename);
      reset(f,1);
      fsize := filesize(f);
      if fsize >= sizeof(earmark) then
        begin
          seek(f,fsize - sizeof(earmark));
          blockread(f,earmark,sizeof(earmark),numread);
          if earmark = SENTINAL then
            iscompr := true
          else iscompr := false
        end
      else iscompr := false;
      close(f)
    end;


  Procedure comprfile(oldfile,newfile:string;var errorcode:integer);

    var freq:larraytype;
        uncompr,compr,dist:iarraytype;
        ck:compkeytype;
        alphasize,cnt2,sum,cnt1,token,ckindex,np,oblsize,nposit:integer;
        oposit,nbit:integer;
        f,g:file;
        amtleft,filetime,earmark:longint;
        oldbuf,newbuf:bufptrtype;
        pow2:pow2type;
        numread,numwritten:word;
        byte1:byte1type;
        done:boolean;
        pw:^word;

    begin
      if iscompr(oldfile) then
        begin
          errorcode := 2;
          exit
        end
      else errorcode := 0;
      getpow2table(pow2);
      getfrequency(oldfile,freq);
      inituncompr(uncompr);
      sort(freq,uncompr);
      getcompr(uncompr,compr);
      alphasize := getalphasize(freq);
      if alphasize < 2 then
        begin
          assign(f,oldfile);
          reset(f,1);
          assign(g,newfile);
          rewrite(g,1);
          getftime(f,filetime);
          amtleft := filesize(f);
          blockwrite(g,amtleft,sizeof(amtleft),numwritten);
          if numwritten < sizeof(amtleft) then
            begin
              close(f);
              close(g);
              erase(g);
              errorcode := 1;
              exit
            end;
          alphasize := alphasize - 1;
          blockwrite(g,alphasize,1,numwritten);
          if numwritten < 1 then
            begin
              close(f);
              close(g);
              erase(g);
              errorcode := 1;
              exit
            end;
          alphasize := alphasize + 1;
          byte1[0] := uncompr[0];
          blockwrite(g,byte1,1,numwritten);
          if numwritten < 1 then
            begin
              close(f);
              close(g);
              erase(g);
              errorcode := 1;
              exit
            end;
          earmark := SENTINAL;
          blockwrite(g,earmark,sizeof(earmark),numwritten);
          if numwritten < sizeof(earmark) then
            begin
              close(f);
              close(g);
              erase(g);
              errorcode := 1;
              exit
            end;
          setftime(g,filetime);
          close(g);
          close(f)
        end
      else
        begin
          get_bit_dist(freq,dist,alphasize);
          get_comp_key(dist,ck,alphasize);
          getmem(oldbuf,BUF_SIZE);
          getmem(newbuf,BUF_SIZE);
          assign(f,oldfile);
          reset(f,1);
          assign(g,newfile);
          rewrite(g,1);
          getftime(f,filetime);
          amtleft := filesize(f);
          blockwrite(g,amtleft,sizeof(amtleft),numwritten);
          if numwritten < sizeof(amtleft) then
            begin
              close(f);
              close(g);
              erase(g);
              freemem(newbuf,BUF_SIZE);
              freemem(oldbuf,BUF_SIZE);
              errorcode := 1;
              exit
            end;
          alphasize := alphasize - 1;
          blockwrite(g,alphasize,1,numwritten);
          if numwritten < 1 then
            begin
              close(f);
              close(g);
              erase(g);
              freemem(newbuf,BUF_SIZE);
              freemem(oldbuf,BUF_SIZE);
              errorcode := 1;
              exit
            end;
          alphasize := alphasize + 1;
          cnt2 := 0;
          sum := 0;
          while (sum < alphasize) do
            begin
              cnt2 := cnt2 + 1;
              byte1[2*cnt2 - 2] := ck[cnt2].num;
              byte1[2*cnt2 - 1] := ck[cnt2].pl;
              sum := sum + ck[cnt2].num + 1
            end;
          blockwrite(g,byte1,2*cnt2,numwritten);
          if numwritten < 2*cnt2 then
            begin
              close(f);
              close(g);
              erase(g);
              freemem(newbuf,BUF_SIZE);
              freemem(oldbuf,BUF_SIZE);
              errorcode := 1;
              exit
            end;
          for cnt2 := 0 to alphasize - 1 do
            byte1[cnt2] := uncompr[cnt2];
          blockwrite(g,byte1,alphasize,numwritten);
          if numwritten < alphasize then
            begin
              close(f);
              close(g);
              erase(g);
              freemem(newbuf,BUF_SIZE);
              freemem(oldbuf,BUF_SIZE);
              errorcode := 1;
              exit
            end;
          oblsize := min(BUF_SIZE,amtleft);
          blockread(f,oldbuf^,oblsize,numread);
          amtleft := amtleft - oblsize;
          oposit := 0;
          for cnt1 := 0 to BUF_SIZE - 1 do
            newbuf^[cnt1] := 0;
          nposit := BUF_SIZE - 1;
          nbit := 8;
          done := false;
          while not done do
            begin
              token := compr[oldbuf^[oposit]];
              ckindex := 0;
              repeat
                ckindex := ckindex + 1;
                nbit := nbit - (ck[ckindex].pl mod 8);
                nposit := nposit - (ck[ckindex].pl div 8);
                if nbit < 0 then
                  begin
                    nbit := nbit + 8;
                    nposit := nposit - 1
                  end;
                if nposit < 0 then
                  begin
                    blockwrite(g,newbuf^[1],BUF_SIZE - 1,numwritten);
                    if numwritten < BUF_SIZE - 1 then
                      begin
                        close(f);
                        close(g);
                        erase(g);
                        freemem(newbuf,BUF_SIZE);
                        freemem(oldbuf,BUF_SIZE);
                        errorcode := 1;
                        exit
                      end;
                    newbuf^[BUF_SIZE - 1] := newbuf^[0];
                    for cnt1 := 0 to BUF_SIZE - 2 do
                      newbuf^[cnt1] := 0;
                    nposit := nposit + BUF_SIZE - 1
                  end;
                pw := addr(newbuf^[nposit]);
                np := min(ck[ckindex].num+1,token);
                pw^ := pw^ + np*pow2[nbit];
                token := token - np
              until (np < ck[ckindex].num+1);
              oposit := oposit + 1;
              if oposit = oblsize then
                begin
                  if amtleft = 0 then done := true
                  else
                    begin
                      oblsize := min(BUF_SIZE,amtleft);
                      blockread(f,oldbuf^,oblsize,numread);
                      amtleft := amtleft - oblsize;
                      oposit := 0
                    end
                end
            end;
          if nposit = 0 then
            begin
              blockwrite(g,newbuf^[1],BUF_SIZE - 1,numwritten);
              if numwritten < BUF_SIZE - 1 then
                begin
                  close(f);
                  close(g);
                  erase(g);
                  freemem(newbuf,BUF_SIZE);
                  freemem(oldbuf,BUF_SIZE);
                  errorcode := 1;
                  exit
                end;
              blockwrite(g,newbuf^[0],1,numwritten);
              if numwritten < 1 then
                begin
                  close(f);
                  close(g);
                  erase(g);
                  freemem(newbuf,BUF_SIZE);
                  freemem(oldbuf,BUF_SIZE);
                  errorcode := 1;
                  exit
                end
            end
          else
            begin
              blockwrite(g,newbuf^[nposit],BUF_SIZE - nposit,numwritten);
              if (numwritten < BUF_SIZE - nposit) then
                begin
                  close(f);
                  close(g);
                  erase(g);
                  freemem(newbuf,BUF_SIZE);
                  freemem(oldbuf,BUF_SIZE);
                  errorcode := 1;
                  exit
                end
            end;
          earmark := SENTINAL;
          blockwrite(g,earmark,sizeof(earmark),numwritten);
          if numwritten < sizeof(earmark) then
            begin
              close(f);
              close(g);
              erase(g);
              errorcode := 1;
              exit
            end;
          close(f);
          setftime(g,filetime);
          close(g);
          freemem(oldbuf,BUF_SIZE);
          freemem(newbuf,BUF_SIZE)
        end
    end;

  Procedure removefile(filename:string);

    var f:file;

    begin
      assign(f,filename);
      erase(f)
    end;

  Procedure renamefile(oldname,newname:string);

    var f:file;

    begin
      assign(f,oldname);
      rename(f,newname)
    end;


  Function fileacc(filename:string):boolean;

    var f:file;
        numread,numwritten:word;
        error:integer;
        dummy:byte;
        dt:longint;

    begin
      error := 0;
      assign(f,filename);
      {$I-}
        reset(f,1);
      {$I+}
      error := IOresult;
      if error = 0 then
        begin
          {$I-}
            getftime(f,dt);
            seek(f,0);
            blockread(f,dummy,1,numread);
          {$I+}
          error := IOresult;
          if error = 0 then
            begin
              {$I-}
                seek(f,0);
                blockwrite(f,dummy,1,numwritten);
              {$I+}
              error := IOresult;
              if error = 0 then
                begin
                  {$I-}
                    setftime(f,dt);
                  {$I+}
                  error := IOresult
                end
            end;
          close(f)
        end;
      fileacc := (error = 0)
    end;



  Procedure getcurdir(var x:string);

    var path:pathstr;
        d:dirstr;
        n:namestr;
        e:extstr;

    begin
      path := 'dummy.pas';
      path := fexpand(path);
      fsplit(path,d,n,e);
      if d[0]>chr(3) then d[0] := chr(ord(d[0])-1);
      x := d
    end;



{  procedure gentable(var t:tabletype);

    var cnt:integer;
        pos,temp:byte;

    begin
      for cnt := 0 to 255 do
        t[cnt] := cnt;
      for cnt := 256 downto 2 do
        begin
          setmax(cnt);
          pos := longrnd;
          temp := t[cnt - 1];
          t[cnt - 1] := t[pos];
          t[pos] := temp
        end
    end;
}

{  function codestr(x:string):string;

    var cnt:integer;
        offset:byte;
        lastseed:rndinfotype;
        pt:tabletype;

    begin
      getrndstat(lastseed);
      initrnd(925241837);
      gentable(pt);
      for cnt := 1 to length(x) do
        begin
          offset := rnd;
          x[cnt] := chr((pt[ord(x[cnt])] + offset) mod 256)
        end;
      codestr := x;
      setrndstat(lastseed)
    end;
 }
{  Procedure printauthor;

    begin
      write(codestr(chr(21)+chr(41)+chr(111)+chr(204)+chr(208)+chr(130)+
                    chr(223)+chr(126)+chr(108)+chr(225)+chr(145)+chr(99)+
                    chr(89)+chr(12)))
    end;
 }


  Procedure getdirectory(path:string;var top:ptrtype);

    var bottom,p:ptrtype;
        error:integer;
        dirinfo:searchrec;

    begin
      top := nil;
      bottom := nil;
      findfirst(path,32,dirinfo);
      error := doserror;
      while error = 0 do
        begin
          new(p);
          p^.data := dirinfo;
          p^.next := nil;
          if top = nil then
            begin
              top := p;
              bottom := p
            end
          else
            begin
              bottom^.next := p;
              bottom := p
            end;
          findnext(dirinfo);
          error := doserror
        end
    end;

  Procedure cleardirectory(var top:ptrtype);

    var p,q:ptrtype;

    begin
      p := top;
      while p <> nil do
        begin
          q := p^.next;
          dispose(p);
          p := q
        end
    end;

{  Procedure registrationinfo;

    var g:text;
        curline:string;

    begin
      clrscr;
      if not fileexists(REMINDFILE) then
        begin
          writeln(chr(7)+'Cannot find '+REMINDFILE);
          halt
        end;
      assign(g,REMINDFILE);
      reset(g);
      write(chr(7));
      while not eof(g) do
        begin
          readln(g,curline);
          writeln(curline)
        end;
      writeln;
      write('Written by: ');
      printauthor;
      gotoxy(1,24);
      write('Press ENTER to continue: ':52);
      readln;
      clrscr
    end;
}

  begin
{    userid := '1234567890';
    username := '12345678901234567890';
    if codestr(copy(userid,6,5)) <> chr(130)+chr(14)+chr(234)+chr(11)+chr(7) then
      registrationinfo
    else
      begin
        write('Written by: ');
        printauthor;
        writeln;
        writeln('This copy licensed to: '+username);
        writeln
      end;
}
    if paramstr(1) = '' then
      begin
        write('Enter files to deflate: ');
        getinput(temp,escpressed);
        writeln;
        writeln;
        if escpressed then exit
      end
    else temp := paramstr(1);
    fsplit(temp,subdir,name,ext);
    subdirlen := length(subdir);
    if subdirlen > 3 then
      if subdir[subdirlen] = '\' then
        subdir := copy(subdir,1,subdirlen-1);
    path := name+ext;
    getcurdir(lastdir);
    {$I-}
      chdir(subdir);
    {$I+}
    error := IOresult;
    if error <> 0 then
      begin
        writeln(chr(7)+'Path does not exist.');
        exit
      end;
    getdirectory(path,top);
    p := top;
    done := false;
    filecount := 0;
    while (p <> nil) and (not done) do
      begin
        if p^.data.size > 0 then
          begin
            if fileacc(p^.data.name) then
              begin
                comprfile(p^.data.name,'#@!.$$$',errorcode);
                if errorcode = 0 then
                  begin
                    removefile(p^.data.name);
                    renamefile('#@!.$$$',p^.data.name);
                    writeln(fexpand(p^.data.name)+' deflated successfully.');
                    filecount := filecount + 1
                  end
                else if errorcode = 2 then
                  writeln(fexpand(p^.data.name)+' is already deflated.')
                else if errorcode = 1 then
                  begin
                    writeln('Disk is full.  Unable to create temporary file.');
                    done := true
                  end
              end
            else writeln('Access denied to '+fexpand(p^.data.name))
          end
        else writeln(fexpand(p^.data.name)+' is empty.');
        p := p^.next
      end;
    writeln;
    writeln(filecount,' files deflated successfully.');
    {$I-}
      chdir(lastdir);
    {$I+}
    cleardirectory(top)
  end.

