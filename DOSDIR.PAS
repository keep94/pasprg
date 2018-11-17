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
      writeln('Directory of ',mask,':');
      textcolor(7);
      writeln;
      getfiles(mask,beg);
      if beg = nil then
        begin
          writeln('File not found.');
          textcolor(15);
          usermessage('Press any key to continue.');
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
              usermessage('Press any key to continue.');
              textcolor(7)
            end
        end;
      cleardir(beg)
    end;