program inflate;

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


  Procedure uncomprfile(oldfile,newfile:string;var errorcode:integer);

    var uncompr:iarraytype;
        ck:compkeytype;
        alphasize,cnt2,sum,cnt,token,ckindex,np,oblsize,nposit:integer;
        diff,oposit,obit,nblsize:integer;
        f,g:file;
        filetime,amtleft,oamtleft:longint;
        oldbuf,newbuf:bufptrtype;
        pow2:pow2type;
        numread,numwritten:word;
        byte1:byte1type;
        done:boolean;

    begin
      if not iscompr(oldfile) then
        begin
          errorcode := 2;
          exit
        end
      else errorcode := 0;
      getpow2table(pow2);
      assign(f,oldfile);
      reset(f,1);
      getftime(f,filetime);
      assign(g,newfile);
      rewrite(g,1);
      blockread(f,amtleft,sizeof(amtleft),numread);
      alphasize := 0;
      blockread(f,alphasize,1,numread);
      alphasize := alphasize + 1;
      if alphasize < 2 then
        begin
          getmem(newbuf,BUF_SIZE);
          blockread(f,byte1,1,numread);
          while (amtleft > 0) do
            begin
              nblsize := min(amtleft,BUF_SIZE);
              for cnt := 0 to nblsize - 1 do newbuf^[cnt] := byte1[0];
              blockwrite(g,newbuf^,nblsize,numwritten);
              if numwritten < nblsize then
                begin
                  close(f);
                  close(g);
                  erase(g);
                  freemem(newbuf,BUF_SIZE);
                  errorcode := 1;
                  exit
                end;
              amtleft := amtleft - nblsize
            end;
          close(f);
          setftime(g,filetime);
          close(g);
          freemem(newbuf,BUF_SIZE)
        end
      else
        begin
          cnt2 := 0;
          sum := 0;
          while (sum < alphasize) do
            begin
              cnt2 := cnt2 + 1;
              blockread(f,byte1,2,numread);
              ck[cnt2].num := byte1[0];
              ck[cnt2].pl := byte1[1];
              sum := sum + ck[cnt2].num + 1
            end;
          blockread(f,byte1,alphasize,numread);
          for cnt2 := 0 to alphasize - 1 do
            uncompr[cnt2] := byte1[cnt2];
          getmem(oldbuf,BUF_SIZE);
          getmem(newbuf,BUF_SIZE);
          oamtleft := filesize(f) - filepos(f) - 4;
          oblsize := min(BUF_SIZE-1,oamtleft);
          blockread(f,oldbuf^,oblsize,numread);
          oamtleft := oamtleft - oblsize;
          oposit := oblsize - 1;
          obit := 8;
          nposit := 0;
          done := false;
          while not done do
            begin
              ckindex := 0;
              diff := 0;
              token := 0;
              repeat
                ckindex := ckindex + 1;
                for cnt2 := 1 to ck[ckindex].pl do
                  begin
                    obit := obit - 1;
                    if obit < 0 then
                      begin
                        obit := obit + 8;
                        oposit := oposit - 1;
                        if oposit < 0 then
                          begin
                            oblsize := min(BUF_SIZE-1,oamtleft);
                            blockread(f,oldbuf^,oblsize,numread);
                            oamtleft := oamtleft - oblsize;
                            oposit := oblsize - 1;
                          end
                      end;
                    if (oldbuf^[oposit] and pow2[obit] > 0) then
                      diff := 2*diff + 1
                    else diff := 2*diff
                  end;
                np := min(diff,ck[ckindex].num + 1);
                token := token + np;
                diff :=  diff - np
              until (np < ck[ckindex].num + 1);
              newbuf^[nposit] := uncompr[token];
              nposit := nposit + 1;
              amtleft := amtleft - 1;
              if amtleft = 0 then done := true
              else if nposit = BUF_SIZE then
                begin
                  blockwrite(g,newbuf^,BUF_SIZE,numwritten);
                  if numwritten < BUF_SIZE then
                    begin
                      close(f);
                      close(g);
                      erase(g);
                      freemem(newbuf,BUF_SIZE);
                      freemem(oldbuf,BUF_SIZE);
                      errorcode := 1;
                      exit
                    end;
                  nposit := 0
                end
            end;
          blockwrite(g,newbuf^,nposit,numwritten);
          if numwritten < nposit then
            begin
              close(f);
              close(g);
              erase(g);
              freemem(newbuf,BUF_SIZE);
              freemem(oldbuf,BUF_SIZE);
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
        write('Enter files to inflate: ');
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
                uncomprfile(p^.data.name,'&%^.$$$',errorcode);
                if errorcode = 0 then
                  begin
                    removefile(p^.data.name);
                    renamefile('&%^.$$$',p^.data.name);
                    writeln(fexpand(p^.data.name)+' inflated successfully.');
                    filecount := filecount + 1
                  end
                else if errorcode = 2 then
                  writeln(fexpand(p^.data.name)+' is already inflated.')
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
    writeln(filecount,' files inflated successfully.');
    {$I-}
      chdir(lastdir);
    {$I+}
    cleardirectory(top)
  end.

