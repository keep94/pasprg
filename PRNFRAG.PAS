  Function caps(x:string):string;

    var cnt:integer;

    begin
      for cnt := 1 to length(x) do
        if (ord(x[cnt]) > 96) and (ord(x[cnt]) < 123) then
          x[cnt] := chr(ord(x[cnt]) - 32);
      caps := x
    end;

  Procedure gensetup;

    var g:text;
        linestr,literal,token:string;
        index:integer;
        done,endline,endfile:boolean;

    begin
      if fileexists('gensetup.ini') then
        begin
          assign(g,'gensetup.ini');
          reset(g);
          linestr := '';
          done := false;
          repeat
            getliteral(g,linestr,index,literal,endline,endfile);
            if endfile then done := true
            else
              begin
                token := literal;
                if caps(token) = 'PRINTER' then
                  begin
                    GLOBAL_printer := '';
                    while (not endline) do
                      begin
                        getliteral(g,linestr,index,literal,endline,endfile);
                        GLOBAL_printer := copy(literal,1,10)
                      end;
                    if GLOBAL_printer = '' then
                      begin
                        writeln(chr(7)+'Error in '+caps(token)+' line of GENSETUP.INI');
                        halt
                      end;
                    GLOBAL_printer := caps(GLOBAL_printer)
                  end
              end
          until done;
          close(g)
        end
      else GLOBAL_printer := ''
    end;