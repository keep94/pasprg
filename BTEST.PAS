program btest;

uses buddy;

type barraytype = array[0..65519] of byte;
     pbarraytype = ^barraytype;

Procedure checkBlock(p:pbarraytype;size:word;fill:word);

var cnt:word;

begin
  cnt := 0;
  while ((cnt < size) and (p^[cnt] = fill)) do
    cnt := cnt + 1;

  if (cnt < size) then
    begin
      writeln('Critical error: Size: ',size,' Fill: ',fill,' Act: ',p^[cnt]);
      writeln('Offset: ',cnt);
      halt(0)
    end
end;

Function MemChange(nsize,osize:word):longint;

var temp:longint;

begin
  if (nsize > 0) then
    temp := 2*indexToWSize(userSizeToIndex(nsize))
  else
    temp := 0;
  if (osize > 0) then
    temp := temp - 2*indexToWSize(userSizeToIndex(osize));
  MemChange := temp
end;


var
  p:array[0..99] of pbarraytype;
  q:pointer;
  ps:array[0..99] of word;
  oldmemused,newmemused:word;
  blockSize:word;
  iter:longint;
  cnt,i:word;

begin
  iter := 0;
  for cnt := 0 to 99 do
    begin
      p[cnt] := nil;
      ps[cnt] := 0
    end;

  repeat
    iter := iter + 1;
    if (iter mod 100 = 0) then
      begin
        writeln('Memory usage: ',MemUsed);
        writeln('Iteration: ',iter div 100)
      end;
    for cnt := 0 to 99 do
      begin
        if (iter = 128) and (cnt = 20) then
          begin
          end;
        checkBlock(p[cnt],ps[cnt],cnt);
        blockSize := random(700);
        q := p[cnt];
        oldmemused := MemUsed;
        q := ReAlloc(p[cnt],blockSize);
        if (q = nil) and (blockSize > 0) then
          begin
            writeln('Allocation error:  Index: ',cnt,' Size: ',blockSize);
            writeln('Iterations: ',iter);
            blockSize := ps[cnt]
          end
        else
          p[cnt] := q;
        newmemused := MemUsed;
        if (newmemused <> oldmemused + MemChange(blockSize,ps[cnt])) then
          begin
            writeln('Memory Error');
            halt(0)
          end;
        if (blockSize >= ps[cnt]) then
          checkBlock(p[cnt],ps[cnt],cnt)
        else
          checkBlock(p[cnt],blockSize,cnt);
        if (blockSize > ps[cnt]) then
          for i := ps[cnt] to blockSize-1 do
            p[cnt]^[i] := cnt;
        ps[cnt] := blockSize
      end
  until False
end.








