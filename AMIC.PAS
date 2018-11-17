unit amic;

interface

  const MAXSIGSIZE = 32760;

  type
    sigarraytype = array[1..MAXSIGSIZE] of word;
    sigmatype = ^sigarraytype;

implementation

  Function powersum(x,y:word):word;

    var cnt,temp:word;


    begin
      temp := 1;
      for cnt := 1 to y do
        temp := temp*x + 1;
      powersum := temp
    end;

  Procedure buildsigma(var p:sigmatype);

    var temp,cnt,cnt1,cnt2:word;
        done:boolean;

    begin
      getmem(p,2*MAXSIGSIZE);
      p^[1] := 1;
      for cnt := 2 to MAXSIGSIZE do
        begin
          cnt1 := 2;
          done := false;
          while (cnt1 <= trunc(sqrt(cnt))) and (not done) do
            begin
              if cnt mod cnt1 = 0 then done := true
              else cnt1 := cnt1 + 1
            end;
          if cnt1 > trunc(sqrt(cnt)) then
            p^[cnt] := cnt + 1
          else
            begin
              cnt2 := 0;
              temp := cnt;
              while (temp mod cnt1 = 0) do
                begin
                  temp := temp div cnt1;
                  cnt2 := cnt2 + 1
                end;
              p^[cnt] := p^[temp] * powersum(cnt1,cnt2)
            end
        end
    end;

  end.