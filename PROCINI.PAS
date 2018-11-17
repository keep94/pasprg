unit procini;

interface

  Procedure getliteral(var g:text;var linestr:string;var index:integer;
                       var literal:string;var endline,endfile:boolean);

implementation


  Procedure getliteral(var g:text;var linestr:string;var index:integer;
                       var literal:string;var endline,endfile:boolean);

    var posit:integer;


    begin
      endline := false;
      endfile := false;
      while (not endfile) and (linestr = '') do
        begin
          if eof(g) then endfile := true
          else
            begin
              readln(g,linestr);
              index := 1
            end
        end;
      if linestr <> '' then
        begin
          posit := index;
          while (posit <= length(linestr)) and (not (linestr[posit] in [' ',',','='])) do
            posit := posit + 1;
          literal := copy(linestr,index,posit-index);
          while (posit <= length(linestr)) and (linestr[posit] in [' ',',','=']) do
            posit := posit + 1;
          if (posit > length(linestr)) then
            begin
              endline := true;
              linestr := '';
              index := 1
            end
          else index := posit
        end
    end;

end.