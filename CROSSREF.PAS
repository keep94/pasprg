program addcrossref;

  uses crt;

  type
    rectype=record
      marked:boolean;
      groups:array[1..5] of byte;
      dorm:string[12];
      room:string[3];
      phone:string[8]
    end;

    filetype = file of rectype;

  Function caps(x:string):string;

    var cnt:integer;

    begin
      for cnt := 1 to length(x) do
        if (ord(x[cnt]) > 96) and (ord(x[cnt]) < 123) then
          x[cnt] := chr(ord(x[cnt]) - 32);
      caps := x
    end;

  var roomnum,command,phonnum,roomstr,phonstr:string;
      numback,numforwd,pval,rval,iter,incr,i,cnt,code,phlen,c1:integer;
      filename:string;
      f:filetype;
      x,y:rectype;
      done:boolean;


  begin
    write('Enter file name: ');
    readln(filename);
    clrscr;
    assign(f,filename);
    reset(f);
    seek(f,filesize(f));
    x.marked := false;
    for i := 1 to 5 do x.groups[i] := 0;
    done := false;
    repeat
      write('- ');
      readln(command);
      if caps(command) = 'CHANGEDORM' then
        begin
          write('Enter dorm: ');
          readln(x.dorm)
        end
      else if caps(command) = 'EDIT' then
        begin
          repeat
            write('Room: ');
            readln(roomstr);
            if caps(roomstr) <> 'EXIT' then
              begin
            i := 1;
            while (i <= length(roomstr)) and (roomstr[i] <> '+') do
              i := i + 1;
            if i >= length(roomstr) then
              begin
                roomnum := roomstr;
                iter := 1
              end
            else
              begin
                roomnum := copy(roomstr,1,i-1);
                val(copy(roomstr,i+1,length(roomstr)-i),iter,code);
                iter := iter + 1
              end;
            write('Phone #: ');
            readln(phonstr);
            writeln;
            i := 1;
            while (i <= length(phonstr)) and (phonstr[i] <> '+') do
              i := i + 1;
            if i >= length(phonstr) then
              begin
                phonnum := phonstr;
                incr := 1
              end
            else
              begin
                phonnum := copy(phonstr,1,i-1);
                val(copy(phonstr,i+1,length(phonstr)-i),incr,code)
              end;
            for cnt := 1 to iter do
              begin
                x.room := roomnum;
                x.phone := '847-'+phonnum;
                write(f,x);
                val(roomnum,rval,code);
                rval := rval + 1;
                str(rval,roomnum);
                val(phonnum,pval,code);
                pval := (pval + incr) mod 10000;
                str(pval,phonnum);
                phlen := length(phonnum);
                for c1 := phlen + 1 to 4 do
                  phonnum := '0'+phonnum
              end
              end
          until (caps(roomstr) = 'EXIT')
        end
      else if copy(caps(command),1,6) = 'BACKUP' then
        begin
          val(copy(command,7,length(command)-6),numback,code);
          if numback <= 1 then numback := 1;
          seek(f,filepos(f) - numback);
          read(f,y);
          writeln('Dorm: ',y.dorm);
          writeln('Room: ',y.room);
          writeln('Phone #: ',y.phone);
          writeln;
          seek(f,filepos(f) - 1)
        end
      else if copy(caps(command),1,7) = 'FORWARD' then
        begin
          val(copy(command,8,length(command)-7),numforwd,code);
          if numforwd <= 1 then numforwd := 1;
          if numforwd > filesize(f) - filepos(f) then
            numforwd := filesize(f) - filepos(f);
          seek(f,filepos(f) + numforwd);
          if filepos(f) < filesize(f) then
            begin
              read(f,y);
              writeln('Dorm ',y.dorm);
              writeln('Room: ',y.room);
              writeln('Phone #: ',y.phone);
              writeln;
              seek(f,filepos(f) - 1)
            end
        end
      else if caps(command) = 'EXIT' then
        begin
          close(f);
          done := true
        end
    until done
  end.