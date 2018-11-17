unit rand;

interface

  type
    rndinfotype=record
      seed:array[1..4] of integer;
      maxrnd:longint;
      maxrndexp:integer
    end;

  Procedure initrnd(x:longint);

  Procedure setmax(x:longint);

  Function rnd:byte;

  Function longrnd:longint;

  Function realrnd:real;

  Procedure getrndstat(var x:rndinfotype);

  Procedure setrndstat(var x:rndinfotype);

implementation

  const
    prime1 = 263;
    prime2 = 251;
    prime3 = 241;
    prime4 = 239;

  type

    seedtype=array[1..4] of byte;

  var rndinfo:rndinfotype;

  Procedure initrnd(x:longint);

    var p:^seedtype;

    begin
      p := addr(x);
      with rndinfo do
        begin
          seed[1] := p^[1];
          seed[2] := p^[2] mod prime2;
          seed[3] := p^[3] mod prime3;
          seed[4] := p^[4] mod prime4
        end
    end;

  Procedure setmax(x:longint);

    var y:longint;
        exp:integer;

    begin
      if x < 1 then x := 1;
      y := x - 1;
      exp := 0;
      while (y > 0) do
        begin
          y := y div 2;
          exp := exp + 1
        end;
      with rndinfo do
        begin
          maxrnd := x;
          maxrndexp := exp
        end
    end;

  Function rnd:byte;

    begin
      with rndinfo do
        begin
          repeat
            seed[1] := (seed[1]*101 + 137) mod prime1
          until seed[1] < 256;
          repeat
            seed[2] := (seed[2]*101 + 137) mod prime1
          until seed[2] < prime2;
          repeat
            seed[3] := (seed[3]*101 + 137) mod prime1
          until seed[3] < prime3;
          repeat
            seed[4] := (seed[4]*101 + 137) mod prime1
          until seed[4] < prime4;
          rnd := (seed[1] + seed[2] + seed[3] + seed[4]) mod 256
        end
    end;


  Function longrnd:longint;

    var rndnum:longint;
        cnt:integer;

    begin
      repeat
        cnt := 0;
        rndnum := 0;
        while (cnt < rndinfo.maxrndexp) do
          begin
            rndnum := 256*rndnum + rnd;
            cnt := cnt + 8
          end;
        while (cnt > rndinfo.maxrndexp) do
          begin
            rndnum := rndnum div 2;
            cnt := cnt - 1
          end
      until (rndnum < rndinfo.maxrnd);
      longrnd := rndnum
    end;

  Function realrnd:real;

    var x:real;
        cnt:integer;

    begin
      x := 0.0;
      for cnt := 1 to 4 do
        x := (x + rnd) / 256.0;
      realrnd := x
    end;

  Procedure getrndstat(var x:rndinfotype);

    begin
      x := rndinfo
    end;

  Procedure setrndstat(var x:rndinfotype);

    begin
      rndinfo := x
    end;

end.