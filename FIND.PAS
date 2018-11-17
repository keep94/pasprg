program find;

  var srchkey,temp:string[8];
      cnt:longint;
      f:file;
      done:boolean;
      numread:word;

  begin
    readln(srchkey);
    assign(f,'a:\pascal\filer.exe');
    reset(f,1);
    done := false;
    cnt := 0;
    while (cnt <= filesize(f) - 9) and (not done) do
      begin
        seek(f,cnt);
        blockread(f,temp,sizeof(temp),numread);
        if temp = srchkey then
          begin
            writeln(cnt);
            done := true
          end
        else cnt := cnt + 1
      end;
    close(f);
    readln
  end.