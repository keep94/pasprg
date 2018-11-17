unit fileblck;

interface


type
  fileblcktype = record
    checksum:longint;
    nextfreeblock:longint;
    numBlocks:longint;
    blocksize:longint;
    fp:file
  end;

Procedure fileblck_open(var f:fileblcktype;pathName:string;var success:boolean);

Procedure fileblck_create(var f:fileblcktype;pathName:string;blcksize:word;var success:boolean);

Procedure fileblck_allocBlock(var f:fileblcktype;var blockNum:longint;var success:boolean);

Procedure fileblck_freeBlock(var f:fileblcktype;blockNum:longint;var success:boolean);

Procedure fileblck_readBlock(var f:fileblcktype;blockNum:longint;var buf;size:word;var success:boolean);

Procedure fileblck_writeBlock(var f:fileblcktype;blockNum:longint;var buf;size:word;var success:boolean);

Procedure fileblck_close(var f:fileblcktype);

implementation

Procedure fileblck_open(var f:fileblcktype;pathName:string;var success:boolean);

  var
    numRead:word;

  begin
    success := true;
    assign(f.fp,pathName);
    reset(f.fp,1);
    seek(f.fp,0);
    blockread(f.fp,f,4*sizeof(longint),numRead);
    if (f.checksum <> 107245923)  then
      begin
        success := false;
        close(f.fp)
      end
  end;

Procedure fileblck_create(var f:fileblcktype;pathName:string;blcksize:word;var success:boolean);

  var
    numwritten:word;
    p:pointer;

  begin
    success := true;
    f.checksum := 107245923;
    f.nextfreeblock := 0;
    f.numBlocks := 1;
    f.blocksize := blcksize;
    success := true;
    assign (f.fp,pathName);
    rewrite(f.fp,1);
    seek(f.fp,0);
    blockwrite(f.fp,f,4*sizeof(longint),numwritten);
    getmem(p,blcksize);
    blockwrite(f.fp,p^,blcksize-4*sizeof(longint),numwritten);
    freemem(p,blcksize)
  end; 

Procedure fileblck_allocblock(var f:fileblcktype;var blocknum:longint;var success:boolean);

  var
    numwritten,numread:word;
    p:pointer;

  begin
    success := true;
    if (f.nextfreeblock = 0) then
      begin
        seek(f.fp,f.blocksize*f.numBlocks);
        getmem(p,f.blocksize);
        blockwrite(f.fp,p^,f.blocksize,numwritten);
        freemem(p,f.blocksize);
        blocknum := f.numBlocks;
        f.numBlocks := f.numBlocks+1
      end
    else
      begin
        blocknum := f.nextfreeblock;
        seek(f.fp,blocknum*f.blocksize+1);
        blockread(f.fp,f.nextfreeblock,sizeof(longint),numread)
      end;
    seek(f.fp,0);
    blockwrite(f.fp,f,4*sizeof(longint),numwritten)
  end;

Procedure fileblck_freeblock(var f:fileblcktype;blocknum:longint;var success:boolean);

var
  numwritten,numread:word;
  deleted:boolean;

begin
  success := true;
  seek(f.fp,blocknum*f.blocksize);
  deleted := false;
  blockwrite(f.fp,deleted,1,numwritten);
  blockwrite(f.fp,f.nextfreeblock,sizeof(longint),numwritten);
  f.nextfreeblock := blocknum;
  seek(f.fp,0);
  blockwrite(f.fp,f,4*sizeof(longint),numwritten)
end;

Procedure fileblck_readblock(var f:fileblcktype;blocknum:longint;var buf;size:word;var success:boolean);

var
  numread:word;

begin
  success := true;
  seek(f.fp,blocknum*f.blocksize);
  blockread(f.fp,buf,size,numread);
  if (numread < size) then
    success := false
end;

Procedure fileblck_writeblock(var f:fileblcktype;blocknum:longint;var buf;size:word;var success:boolean);


  var
    numwritten:word;

begin
  success := true;
  seek(f.fp,blocknum*f.blocksize);
  blockwrite(f.fp,buf,size,numwritten);
  if (numwritten < size) then
      success := false
end;

Procedure fileblck_close(var f:fileblcktype);

  begin
    close(f.fp)
  end;


begin
end.
                

      
            

    

        

