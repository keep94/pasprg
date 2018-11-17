unit crc;

interface

function crc32(x:string;seed:longint):longint;

implementation


function crc32(x:string;seed:longint):longint;

  var poly:longint;
      i,j:integer;
      ch:integer;
      crcbit,chbit:integer;
      result:longint;

  begin
    poly := $edb88320;
    result := seed;
    for i := 1 to length(x) do
      begin
        ch := ord(x[i]);
        for j := 1 to 8 do
          begin
            chbit := ch and 1;
            crcbit := result and 1;
            result := result shr 1;
            ch := ch shr 1;
            if ((chbit xor crcbit) = 1) then
              result := result xor poly
          end
      end;
    crc32 := result
  end;

begin
end.
