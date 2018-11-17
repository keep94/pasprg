unit dateacc;

interface

  Procedure dateexpand(var x:string;var valid:boolean);

implementation

  Procedure dateexpand(var x:string;var valid:boolean);

    var mlen:array[1..12] of integer;
        estr:array[1..3] of string[2];
        e:array[1..3] of integer;
        l,cnt,last,index,code:integer;


    begin
      if x <> '' then
        begin
          mlen[1] := 31;
          mlen[2] := 28;
          mlen[3] := 31;
          mlen[4] := 30;
          mlen[5] := 31;
          mlen[6] := 30;
          mlen[7] := 31;
          mlen[8] := 31;
          mlen[9] := 30;
          mlen[10] := 31;
          mlen[11] := 30;
          mlen[12] := 31;
          if length(x) >= 8 then l := 8
          else l := length(x);
          index := 1;
          last := 0;
          for cnt := 1 to l do
            if (x[cnt] = '/') and (index < 3) then
              begin
                val(copy(x,last+1,cnt-last-1),e[index],code);
                last := cnt;
                index := index + 1
              end;
          val(copy(x,last+1,l-last),e[index],code);
          if (index < 3) then
            valid := false
          else if (e[1] < 1) or (e[1] > 12) then
            valid := false
          else if (e[3] < 0) or (e[3] > 99) then
            valid := false
          else
            begin
              if (e[3] mod 4 = 0) then mlen[2] := 29;
              if (e[2] < 1) or (e[2] > mlen[e[1]]) then
                valid := false
              else
                valid := true
            end;
          if valid then
            begin
              for cnt := 1 to 3 do
                begin
                  str(e[cnt],estr[cnt]);
                  if length(estr[cnt]) < 2 then estr[cnt] := '0'+estr[cnt]
                end;
              x := estr[1]+'/'+estr[2]+'/'+estr[3]
            end
          else
            x := '01/01/80'
        end
    end;

  end.