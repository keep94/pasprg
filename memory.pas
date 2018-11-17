unit memory;

interface

const
  HEAP_NUM_BLOCKS = 4096;
  HEAP_BLOCK_SIZE = 15;

type
  heapblocktype = record
    control:byte;
    data:array[0..HEAP_BLOCK_SIZE-2] of byte
  end;

  heaparraytype = array[0..HEAP_NUM_BLOCKS-1] of heapblocktype;

  heaptype = ^heaparraytype;  



Procedure malloc(var ht:heaptype;var p:pointer;var size:word);

Procedure mfree(var ht:heaptype;var p:pointer);

Procedure heapinit(var ht:heaptype);

Procedure heapdestroy(var ht:heaptype);

implementation


Procedure heapinit(var ht:heaptype);

begin
    getmem(ht,HEAP_NUM_BLOCKS*sizeof(heapblocktype));
    ht^[0].control := ilog(HEAP_NUM_BLOCKS)*16
end;

Procedure heapdestroy(var ht:heaptype);

begin
  freemem(ht,HEAP_NUM_BLOCKS*HEAP_BLOCK_SIZE)
end;

Procedure malloc(var ht:heaptype;var p:pointer;var size:word);


begin
  size := (size div HEAP_BLOCK_SIZE) + 1;
  size := ilog(2*size-1);
  posit := 0;
  done := false;
  while (posit < HEAP_NUM_BLOCKS) and (not done) do
    begin
      bsize := (ht^[posit].control div 16) - 1;
      bused := (ht^[posit].control mod 16 > 0);
      if (bused) then
        begin
          if (bsize > size) then
            posit := posit + iexp(bsize)
          else
            posit := posit +iexp(size)
        end
      else
        if (bsize < size) then
          posit := posit + iexp(size)
        else
          done := true 
    end;

  if (done) then
    begin
      divideup(ht,posit,size,true);
      ht^[posit].control := 17*size + 17;
      p := addr(ht^[posit].data);
      while (join(ht,posit,size)) do size := size + 1
    end
  else
    p := nil
end;


Procedure mfree(var ht:heaptype;p:pointer);


begin
  posit := (offset(p) - offset(ht)) div HEAP_BLOCK_SIZE;
  size := (ht^[posit].control mod 16) - 1;
  divideup(ht,posit,size,false);
  ht^[posit].control := 16*size+16;
  while (join(ht,posit,size)) do size := size + 1
end;

Function ilog(x:integer):integer;

begin
  result := 0;
  while (x > 1) do
    begin
      result := result + 1;
      x := x div 2
    end;
  ilog := result
end;

Function iexp(x:integer):integer;

begin
  result := 1;
  for i := 1 to x do
      result := 2*result;
  iexp := result
end;

Function join(var ht:heaptype;var posit:integer;size:integer):boolean;

begin
  expsize :=  iexp(size);
  chunk := posit div expsize;
  if (chunk mod 1 > 0) then
    nposit := (chunk - 1)*expsize;
  else
    nposit := (chunk + 1)*expsize;

  bused :=  (ht^[posit].control mod 16 > 0);
  nused := (ht^[nposit].control mod 16 > 0);

  if (nused = bused) then
    begin
      result := true;
      if (nposit < posit) then
        begin
          ht^[posit].control := ht^[posit].control mod 16;
          posit := nposit
        end
      else
        begin
          ht^[nposit].control := ht^[nposit].control mod 16
        end
    end
  else
    result := false;
  join := result
end;         


Procuedure divideup(var ht:heaptype;posit:integer;size:integer;markUnused:boolan);

begin
  expsize := iexp(size);
  lposit := posit;
  nsize := size;
  while (ht^[lposit].control < 16) do
    begin
      markSize(ht,lposit,nsize,markUnused)
      lchunk := lposit;
      mult := 1;
      while (lchunk mod 2 = 0) do
        begin
          lchunk := lchunk div 2;
          mult := mult * 2
        end;
      lposit := (lchunk -1)*mult;
      nsize := ilog(mult)
    end;

  bsize := (ht^[lposit].control div 16) - 1;
  endposit := lposit + iexp(bsize);

  rposit := posit + expsize;
  
  while (rposit < endposit) do
    begin
      rchunk := rposit;
      mult := 1;
      while (rchunk mod 2 = 0) do
        begin
          rchunk := rchunk div 2;
          mult := mult * 2
        end;
      markSize(ht,rposit,ilog(mult),markUnused);
      rposit := (rchunk+1)*mult
    end
end;

Procedure markSize(var ht:heaptype;posit:integer;size:integer;markUnused:boolean);

begin
  if (markUnused) then
    ht^[posit].control := 16*size+16;
  else
    ht^[posit].control := 16*size+16 + (ht^[posit].control mod 16)
end;

begin
end. 
  


