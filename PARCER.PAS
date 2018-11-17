unit parcer;

interface

  type
    keytype = array[1..256] of byte;

  Procedure makekey(var key:keytype;var size:integer;x:string;var code:integer);

implementation

  Procedure makekey(var key:keytype;var size:integer;x:string;var code:integer);

    var kpos,epos,mode,cnt,error:integer;
        bptr:^byte;
        iptr:^integer;
        lptr:^longint;
        rptr:^real;
        num:array[0..7] of byte;
         ch:char;
        temp:string;

    begin
      x := x + '~';
      kpos := 1;
      epos := 1;
      error := 0;
      mode := 0;
      bptr := addr(num);
      iptr := addr(num);
      lptr := addr(num);
      rptr := addr(num);
      while (error = 0) and (epos <= length(x)) and (kpos <= 256) do
        begin
          ch := x[epos];
          case mode of
            0:begin
                if ch in ['H','h'] then
                  begin
                    bptr^ := 0;
                    mode := 1
                  end
                else if ch in ['D','d'] then
                  begin
                    bptr^ := 0;
                    mode := 2
                  end
                else if ch in ['O','o'] then
                  begin
                    bptr^ := 0;
                    mode := 3
                  end
                else if ch in ['I','i'] then
                  begin
                    temp := '';
                    mode := 4
                  end
                else if ch in ['L','l'] then
                  begin
                    temp := '';
                    mode := 5
                  end
                else if ch in ['S','s'] then
                  begin
                    temp := '';
                    mode := 6
                  end
                else if ch in ['P','p'] then
                  begin
                    temp := '';
                    mode := 7
                  end
                else if ch in ['X','x'] then
                  begin
                    temp := '';
                    mode := 8
                  end
                else if ch in ['T','t'] then mode := 9
                else error := 1
              end;
            1:begin
                if ch in ['0'..'9','A'..'F','a'..'f'] then
                  begin
                    if ch >= 'a' then bptr^ := bptr^*16 + (ord(ch) - 87)
                    else if ch >= 'A' then bptr^ := bptr^*16 + (ord(ch) - 55)
                    else bptr^ := bptr^*16 + (ord(ch) - 48)
                  end
                else if ch = '~' then
                  begin
                    key[((kpos - 1) mod 256) + 1] := bptr^;
                    kpos := kpos + 1;
                    mode := 0
                  end
                else error := 1
              end;
            2:begin
                if ch in ['0'..'9'] then
                  bptr^ := bptr^*10 + (ord(ch) - 48)
                else if ch = '~' then
                  begin
                    key[((kpos - 1) mod 256) + 1] := bptr^;
                    kpos := kpos + 1;
                    mode := 0
                  end
                else error := 1
              end;
            3:begin
                if ch in ['0'..'7'] then
                  bptr^ := bptr^*8 + (ord(ch) - 48)
                else if ch = '~' then
                  begin
                    key[((kpos - 1) mod 256) + 1] := bptr^;
                    kpos := kpos + 1;
                    mode := 0
                  end
                else error := 1
              end;
            4:begin
                if ch = '~' then
                  begin
                    val(temp,iptr^,code);
                    if code <> 0 then
                      error := 1
                    else
                      begin
                        for cnt := 0 to 1 do
                          begin
                            key[((kpos - 1) mod 256) + 1] := num[cnt];
                            kpos := kpos + 1
                          end;
                        mode := 0
                      end
                  end
                else temp := temp + ch
              end;
            5:begin
                if ch = '~' then
                  begin
                    val(temp,lptr^,code);
                    if code <> 0 then
                      error := 1
                    else
                      begin
                        for cnt := 0 to 3 do
                          begin
                            key[((kpos - 1) mod 256) + 1] := num[cnt];
                            kpos := kpos + 1
                          end;
                        mode := 0
                      end
                  end
                else temp := temp + ch
              end;
            6:begin
                if ch = '~' then
                  begin
                    val(temp,rptr^,code);
                    if code <> 0 then
                      error := 1
                    else
                      begin
                        for cnt := 0 to 3 do
                          begin
                            key[((kpos - 1) mod 256) + 1] := num[(cnt + 3) mod 6];
                            kpos := kpos + 1
                          end;
                        mode := 0
                      end
                  end
                else temp := temp + ch
              end;
            7:begin
                if ch = '~' then
                  begin
                    val(temp,rptr^,code);
                    if code <> 0 then
                      error := 1
                    else
                      begin
                        for cnt := 0 to 5 do
                          begin
                            key[((kpos - 1) mod 256) + 1] := num[cnt];
                            kpos := kpos + 1
                          end;
                        mode := 0
                      end
                  end
                else temp := temp + ch
              end;
            8:begin
                if ch = '~' then
                  begin
                    val(temp,rptr^,code);
                    if code <> 0 then
                      error := 1
                    else
                      begin
                        for cnt := 0 to 1 do
                          begin
                            key[((kpos - 1) mod 256) + 1] := 0;
                            kpos := kpos + 1
                          end;
                        for cnt := 2 to 7 do
                          begin
                            key[((kpos - 1) mod 256) + 1] := num[(cnt - 1) mod 6];
                            kpos := kpos + 1
                          end;
                        mode := 0
                      end
                  end
                else temp := temp + ch
              end;
            9:begin
                if ch = '~' then mode := 0
                else
                  begin
                    key[((kpos - 1) mod 256) + 1] := ord(ch);
                    kpos := kpos + 1
                  end
              end
          end;
          epos := epos + 1
        end;
      if error = 0 then
        begin
          if (epos <= length(x)) or (kpos - 1 > 256) then error := 2
        end;
      code := error;
      size := kpos - 1
    end;

end.