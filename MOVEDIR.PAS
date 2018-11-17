program movetodir;

  uses dos;

  type
    ptrtype = ^node;
    node = record
      data:searchrec;
      next:ptrtype
    end;

  var newdir,path:string;
      top:ptrtype;
      dirinfo:searchrec;
      error:integer;

  Function backslash(x:string):boolean;

    var cnt:integer;
        found:boolean;

    begin
      cnt := 1;
      found := false;
      while (cnt <= length(x)) and (not found) do
        begin
          if x[cnt] = '\' then found := true
          else cnt := cnt + 1
        end;
      backslash := found
    end;

  Procedure insert(var top:ptrtype;var dirinfo:searchrec);

    var oldtop:ptrtype;

    begin
      oldtop := top;
      new(top);
      top^.next := oldtop;
      top^.data := dirinfo
    end;

  Procedure movedir(top:ptrtype;var newdir:string);

    var f:file;
        p:ptrtype;
        error:integer;

    begin
      p := top;
      while (p <> nil) do
        begin
          assign(f,p^.data.name);
          {$I-}
            rename(f,newdir+'\'+p^.data.name);
          {$I+}
          error := IOresult;
          if error <> 0 then
            writeln('Unable to move '+p^.data.name+' to selected directory.');
          p := p^.next
        end
    end;

  Procedure clearlist(var top:ptrtype);

    var p,q:ptrtype;

    begin
      p := top;
      while (p <> nil) do
        begin
          q := p^.next;
          dispose(p);
          p := q
        end;
      top := nil
    end;


    begin
      path := paramstr(1);
      if backslash(path) then
        begin
          writeln(chr(7)+'Illegal characters found in path.');
          exit
        end;
      newdir := paramstr(2);
      if newdir[ord(newdir[0])] = '\' then
        newdir := copy(newdir,1,length(newdir)-1);
      top := nil;
      findfirst(path,32,dirinfo);
      error := doserror;
      while error = 0 do
        begin
          insert(top,dirinfo);
          findnext(dirinfo);
          error := doserror
        end;
      movedir(top,newdir);
      clearlist(top)
    end.