program setpass;

  uses crt,iounit;

  const MAXPASSLEN = 12;

  type
    passtype = string[MAXPASSLEN];
    passtabletype = array[1..36] of passtype;

  var
    passnumstr:string;
    passnum,code:integer;
    oldpasswd,newpasswd,renewpasswd:passtype;
    passtable:passtabletype;


  Procedure getpasswd(var passwd:passtype);

    var cnt:integer;
        keyinp:char;
        done:boolean;

    begin
      done := false;
      passwd := '';
      cnt := 1;
      repeat
        keyinp := readkey;
        if keyinp = chr(13) then
          begin
            passwd[0] := chr(cnt-1);
            done := true
          end
        else if cnt <= MAXPASSLEN then
          begin
            passwd[cnt] := keyinp;
            cnt := cnt + 1
          end
      until done
    end;


  Procedure getpasstable(var passtable:passtabletype);

    var f:file;
        numread:word;

    begin
      assign(f,'MSELECT.YYY');
      reset(f,1);
      seek(f,1);
      blockread(f,passtable,sizeof(passtabletype),numread);
      close(f)
    end;


  Procedure savepasstable(var passtable:passtabletype);

  var f:file;
      dummy:char;
      numwritten:word;


  begin
    assign(f,'MSELECT.YYY');
    rewrite(f,1);
    dummy := chr(26);
    blockwrite(f,dummy,sizeof(char),numwritten);
    blockwrite(f,passtable,sizeof(passtabletype),numwritten);
    close(f)
  end;



  begin
    textcolor(7);
    passnumstr := paramstr(1);
    val(passnumstr,passnum,code);
    if (passnum >= 1) and (passnum <= 36) then
      begin
        write('Enter old password: ');
        getpasswd(oldpasswd);
        writeln;
        write('Enter new password: ');
        getpasswd(newpasswd);
        writeln;
        write('Retype new password: ');
        getpasswd(renewpasswd);
        writeln;
        writeln;
        if (newpasswd <> renewpasswd) then
          begin
            writeln('Password retyped incorrectly.  Password has not been changed.');
            write('Press any key to continue.');
            pause
          end
        else
          begin
            getpasstable(passtable);
            if oldpasswd <> passtable[passnum] then
              begin
                writeln('Access denied.  Password has not been changed.');
                write('Press any key to continue.');
                pause
              end
            else
              begin
                passtable[passnum] := newpasswd;
                savepasstable(passtable);
                write('Password has been changed.  Press any key to continue.');
                pause
              end
          end
      end
  end.