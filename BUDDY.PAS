unit Buddy;

interface
type barraytype = array[0..65519] of byte;
     pbarraytype = ^barraytype;
     warraytype = array[0..32759] of word;
     pwarraytype = ^warraytype;

var heapBptr:pbarraytype;
    heapWptr:pwarraytype;
    indexPtr:pwarraytype;

Function Alloc(size:word):pointer;
Procedure Free(p:pointer);
Function ReAlloc(p:pointer;size:word):pointer;
Function MemUsed:word;
Function userSizeToIndex(size:word):word;
Function indexToWSize(size:word):word;

implementation

const NULLptr = 32767;


{------------------------------------------------------------------------}
Procedure initBuddy;

var blockSize,sum,cnt:word;

begin
  getmem(heapBptr,65520);
  heapWptr := addr(heapBptr^);
  indexPtr := addr(heapWptr^[32704]);

  blockSize := 16384;
  cnt := 13;
  sum := 0;

  while (sum < 32704) do
    begin
      heapWptr^[sum] := NULLptr;
      indexPtr^[cnt] := sum;
      sum := sum + blockSize;
      blockSize := blockSize div 2;
      cnt := cnt - 1
    end;

  cnt := cnt + 1;
  while (cnt > 0) do
    begin
      cnt := cnt - 1;
      indexPtr^[cnt] := NULLptr
    end
end;


Function sizeToIndex(size:word):word;

var temp:word;

begin
  temp := 0;
  if (size > 0) then
    size := size - 1;
  while (size >= 4) do
    begin
      temp := temp + 1;
      size := size div 2
    end;
  sizeToIndex := temp
end;


Function indexToWSize(size:word):word;

var temp,cnt:word;

begin
  temp := 2;
  for cnt := 1 to size do
    temp := temp * 2;
  indexToWSize := temp
end;


Function userSizeToIndex(size:word):word;

var temp:word;

begin
  if (size >= 65534) then
    temp := 14
  else
    temp := sizeToIndex(size+2);
  userSizeToIndex := temp
end;


Function Alloc(size:word):pointer;

var desiredIndex,listIndex,cnt,sum,blockSize,newLoc:word;
    temp:pointer;

begin
  if (size = 0) then
    begin
      temp := nil
    end
  else
    begin
      listIndex := userSizeToIndex(size);
      desiredIndex := listIndex;
      while ((listIndex <= 13) and (indexPtr^[listIndex] = NULLptr)) do
        listIndex := listIndex + 1;

      if (listIndex = 14) then
        temp := nil
      else
        begin
          newLoc := indexPtr^[listIndex];
          indexPtr^[listIndex] := heapWptr^[newLoc];

          blockSize := indexToWSize(desiredIndex);
          sum := newLoc + blockSize;
          if (listIndex > desiredIndex) then
            for cnt := desiredIndex to listIndex-1 do
              begin
                indexPtr^[cnt] := sum;
                heapWptr^[sum] := NULLptr;
                sum := sum + blockSize;
                blockSize := blockSize * 2
              end;

          if (newLoc = 0) then
            indexPtr^[14] := desiredIndex
          else
            heapBptr^[2*newLoc - 1] := desiredIndex;

          temp := addr(heapWptr^[newLoc])
        end
    end;
  Alloc := temp
end;

Function FindBuddy(loc:word;index:word):word;

var cLoc,tLoc,cSize,dLoc,temp:word;

begin
  if (index >= 13) then
    temp := NULLptr
  else
    begin
      cSize := indexToWSize(index) * 2;
      cLoc := indexPtr^[index];
      dLoc := loc div cSize;
      tLoc := NULLptr;

      while ((cLoc <> NULLptr) and ((cLoc div cSize) <> dLoc)) do
        begin
          tLoc := cLoc;
          cLoc := heapWptr^[cLoc]
        end;

      if (cLoc = NULLptr) then
        temp := NULLptr
      else if (tLoc = NULLptr) then
        begin
          indexPtr^[index] := heapWptr^[cLoc];
          indexPtr^[16+index] := cLoc;
          temp := dLoc * cSize
        end
      else
        begin
          heapWptr^[tLoc] := heapWptr^[cLoc];
          indexPtr^[16+index] := cLoc;
          temp := dLoc * cSize
        end
    end;
  FindBuddy := temp
end;


Procedure Free(p:pointer);

var nextLoc,newLoc,desiredIndex:word;

begin
  indexPtr^[30] := NULLptr;
  if (p = nil) then
    exit;
  newLoc := Ofs(p^) - Ofs(heapWptr^);
  if (newLoc = 0) then
    desiredIndex := indexPtr^[14]
  else
    desiredIndex := heapBptr^[newLoc - 1];

  indexPtr^[31] := desiredIndex;
  newLoc := newLoc div 2;

  repeat
    nextLoc := FindBuddy(newLoc,desiredIndex);
    if (nextLoc <> NULLptr) then
      begin
        newLoc := nextLoc;
        desiredIndex := desiredIndex + 1
      end
  until (nextLoc = NULLptr);

  heapWptr^[newLoc] := indexPtr^[desiredIndex];
  indexPtr^[desiredIndex] := newLoc;
  indexPtr^[30] := desiredIndex
end;

Procedure UnFree;

var cnt,newLoc:word;

begin
  if (indexPtr^[30] = NULLptr) then
    exit;
  newLoc := indexPtr^[indexPtr^[30]];
  indexPtr^[indexPtr^[30]] := heapWptr^[newLoc];
  if (indexPtr^[31] < indexPtr^[30]) then
    for cnt := indexPtr^[31] to indexPtr^[30]-1 do
      begin
        heapWptr^[indexPtr^[16+cnt]] := indexPtr^[cnt];
        indexPtr^[cnt] := indexPtr^[16+cnt]
      end
end;


Function ReAlloc(p:pointer;size:word):pointer;

var temp:pointer;
    linkTab,newLoc,dLoc,cIndex,dIndex,cnt,oSize,toCopy:word;

begin
  if (p = nil) then
    temp := Alloc(size)
  else if (size = 0) then
    begin
      Free(p);
      temp := nil
    end
  else
    begin
      newLoc := Ofs(p^) - Ofs(heapWptr^);
      if (newLoc = 0) then
        cIndex := indexPtr^[14]
      else
        cIndex := heapBptr^[newLoc-1];
      dIndex := userSizeToIndex(size);
      if (dIndex = cIndex) then
        temp := p
      else
        begin
          oSize := 2*indexToWSize(cIndex) - 2;
          newLoc := newLoc div 2;
          linkTab := heapWptr^[newLoc];
          Free(p);
          temp := Alloc(size);
          if (temp = nil) then
            begin
              UnFree;
              dLoc := newLoc
            end
          else
            begin
              dLoc := Ofs(temp^) - Ofs(heapWptr^);
              dLoc := dLoc div 2
            end;
          heapWptr^[dLoc] := linkTab;
          if (dLoc <> newLoc) then
            begin
              if (oSize < size) then
                toCopy := oSize div 2
              else
                toCopy := (size + 1) div 2;
              for cnt := 2 to toCopy do
                heapWptr^[dLoc+cnt-1] := heapWptr^[newLoc+cnt-1];
            end
        end
    end;
  ReAlloc := temp
end;

Function MemUsed:word;

var cnt,i:word;
    temp:word;
    posit:word;

begin
  temp := 0;
  for cnt := 0 to 13 do
    begin
      posit := indexPtr^[cnt];
      i := 0;
      while (posit <> NULLptr) do
        begin
          posit := heapWptr^[posit];
          i := i + 1
        end;
      temp := temp + indexToWSize(cnt)*i
    end;
  temp := temp * 2;
  MemUsed := 65408 - temp
end;


begin
  initBuddy;
end.











