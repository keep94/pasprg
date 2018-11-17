unit journent;

interface

uses lstr;

const JOURNENT_FIRST_REC = 4;
      JOURNENT_MAX_CACHE_SIZE = 800;
      JOURNENT_DEFAULT_CACHE_SIZE = 100;
type

  journalentrytype = record
    blockextent:longint;
    date:integer;
    title:string[65]
  end;

  journalfilecachetype=record
    posit:longint;
    data:journalentrytype
  end;

  journalfilecacheatype=array[0..JOURNENT_MAX_CACHE_SIZE-1] of journalfilecachetype;

  journalfilecacheptype=^journalfilecacheatype;

  journalfiletype = record
    f:file;
    key:string;
    cache:journalfilecacheptype;
    cachesize:longint
  end;

  Procedure journentinit(var je:journalentrytype);

  Procedure journentmarkdeleted(var je:journalentrytype);

  Function journentisdeleted(var je:journalentrytype):boolean;

  Procedure journentfilecreate(pathname:string;key:string);

  Function journentfileopen(var jf:journalfiletype;pathname:string;
             key:string):boolean;

  Procedure journentfileget(var jf:journalfiletype;recno:longint;var je:journalentrytype);

  Procedure journentfilegetall(var jf:journalfiletype;recno:longint;
        var je:journalentrytype;var content:longstr);

  Procedure journentfilesave(var jf:journalfiletype;recno:longint;
        var je:journalentrytype);

  Procedure journentfilesaveall(var jf:journalfiletype;var recno:longint;
        var je:journalentrytype;var content:longstr);

  Procedure journentfilechangekey(var jf:journalfiletype;newkey:string;var content:longstr);

  Procedure journentfileclose(var jf:journalfiletype);

  Procedure journentsetcachesize(var jf:journalfiletype;newsize:longint);


  implementation

  uses dos,dates,crc,encunit;

  const SEED = 314159265;

  { initializes journal entry.  Date initialized to current day, title
    set to untitled. }

  Procedure journentinit(var je:journalentrytype);

  var year,month,day,dayofweek:word;

  begin
    je.blockextent := 0;
    getdate(year,month,day,dayofweek);
    je.date := packit(month,day,year mod 100);
    je.title := 'untitled'
  end;


  { Marks a journal entry as deleted }

  Procedure journentmarkdeleted(var je:journalentrytype);

  begin
    je.date := -10517
  end;

  { Returns true if a journal entry is deleted }

  Function journentisdeleted(var je:journalentrytype):boolean;

  begin
    journentisdeleted := (je.date = -10517)
  end;

  { Creates a new journal file
    pathname - the path of new file
    key - the password for the new file
  }

  Procedure journentfilecreate(pathname:string;key:string);

  var f:file;
      checksum:longint;
      numwritten:word;

  begin
    assign(f,pathname);
    rewrite(f,1);
    checksum := crc32(key,SEED);
    blockwrite(f,checksum,sizeof(longint),numwritten);
    close(f)
  end;

  Procedure journentfileinitcache(var jf:journalfiletype);

  var cnt:integer;

  begin
    for cnt := 0 to jf.cachesize-1 do
        jf.cache^[cnt].posit := -1
  end;

  {
    Opens a journal file.
    jf - journal file object
    pathname - the path name of file to open
    key - the password for file
    returns true if file successfully opened, false otherwise
  }

  Function journentfileopen(var jf:journalfiletype;pathname:string;
             key:string):boolean;

  var checksum:longint;
      numread:word;
      result:boolean;

  begin
    assign(jf.f,pathname);
    reset(jf.f,1);
    blockread(jf.f,checksum,sizeof(longint),numread);
    if (checksum <> crc32(key,SEED)) then
      begin
        result := false;
        close(jf.f)
      end
    else
      begin
        result := true;
        jf.key := key;
        jf.cachesize := JOURNENT_DEFAULT_CACHE_SIZE;
        getmem(jf.cache,jf.cachesize*sizeof(journalfilecachetype));
        journentfileinitcache(jf)
      end;
    journentfileopen := result
  end;

  {
    Gets the journal entry at the given position in the file.
    jf - journal file
    recno - position in file to get entry
    je - journal entry returned here
  }

  Procedure journentfileget(var jf:journalfiletype;recno:longint;
      var je:journalentrytype);

  var numread:word;
      cacheindex:integer;

  begin
    cacheindex := recno mod jf.cachesize;
    if (jf.cache^[cacheindex].posit <> recno) then
      begin
        seek(jf.f,recno);
        blockread(jf.f,
         jf.cache^[cacheindex].data,
           sizeof(journalentrytype),numread);
        encdecode(jf.cache^[cacheindex].data,sizeof(journalentrytype),jf.key);
        jf.cache^[cacheindex].posit := recno
      end;
    je := jf.cache^[cacheindex].data
  end;

    {
    Gets the journal entry and the content of it at the given position
    in the file.
    jf - journal file
    recno - position in file to get entry
    je - journal entry returned here
    content - content of journal entry returned here
  }


  Procedure journentfilegetall(var jf:journalfiletype;recno:longint;
        var je:journalentrytype;var content:longstr);

  var numread:word;
      strsize:word;

  begin
    journentfileget(jf,recno,je);
    seek(jf.f,recno+sizeof(journalentrytype));
    blockread(jf.f,strsize,sizeof(word),numread);
    lstradjustforsize(content,strsize);
    blockread(jf.f,content.ptr^,strsize,numread);
    content.size := strsize;
    encdecodels(content,jf.key)
  end;

  {
    updates a journal entry at a given position in the file
    jf - journal file
    recno - position to save the journal entry
    je - the journal entry to be saved
  }

  Procedure journentfilesave(var jf:journalfiletype;recno:longint;
        var je:journalentrytype);

  var numwritten:word;
      tempje:journalentrytype;
      cacheindex:integer;

  begin
    tempje := je;
    enccode(tempje,sizeof(journalentrytype),jf.key);
    seek(jf.f,recno);
    blockwrite(jf.f,tempje,sizeof(journalentrytype),numwritten);
    cacheindex := recno mod jf.cachesize;
    jf.cache^[cacheindex].data := je;
    jf.cache^[cacheindex].posit := recno
  end;

  {
    Saves a journal entry and the content of that journal entry at
    a given position in the file.
    jf - journal file
    recno - position to save the journal entry
    je - the journal entry to be saved
    content - content to be saved
  }

  Procedure journentfilesaveall(var jf:journalfiletype;var recno:longint;
        var je:journalentrytype;var content:longstr);

  var numwritten:word;
      tempje:journalentrytype;
      newblocksize:longint;
      strsize:word;
      thefsize:longint;

  begin
    strsize := lstrlen(content);
    newblocksize := sizeof(journalentrytype);
    newblocksize := newblocksize + strsize;
    newblocksize := newblocksize + sizeof(word);
    thefsize := filesize(jf.f);
    if (je.blockextent < newblocksize) and (recno + je.blockextent < thefsize) then
      begin
        tempje := je;
        journentmarkdeleted(tempje);
        journentfilesave(jf,recno,tempje);
        recno := thefsize
      end;
    if (je.blockextent < newblocksize) then
      je.blockextent := newblocksize;
    journentfilesave(jf,recno,je);
    blockwrite(jf.f,strsize,sizeof(word),numwritten);
    enccodels(content,jf.key);
    blockwrite(jf.f,content.ptr^,strsize,numwritten)
  end;

  {
    Changes the password for a journal file
    jf - journal file
    newkey - the new password
  }

  Procedure journentfilechangekey(var jf:journalfiletype;newkey:string;var content:longstr);

  var checksum:longint;
      numwritten:word;
      oldkey:string;
      posit:longint;
      maxsize:longint;
      je:journalentrytype;

  begin
    checksum := crc32(newkey,SEED);
    seek(jf.f,0);
    blockwrite(jf.f,checksum,sizeof(longint),numwritten);
    oldkey := jf.key;
    posit := JOURNENT_FIRST_REC;
    maxsize := filesize(jf.f);
    while (posit < maxsize) do
      begin
        jf.key := oldkey;
        journentfilegetall(jf,posit,je,content);
        jf.key := newkey;
        journentfilesaveall(jf,posit,je,content);
        posit := posit + je.blockextent
      end;
    jf.key := newkey
  end;


  {
    closes a journal file
  }

  Procedure journentfileclose(var jf:journalfiletype);

  begin
    close(jf.f);
    freemem(jf.cache,jf.cachesize*sizeof(journalfilecachetype))
  end;

  Procedure journentsetcachesize(var jf:journalfiletype;newsize:longint);

  begin
    freemem(jf.cache,jf.cachesize*sizeof(journalfilecachetype));
    jf.cachesize := newsize;
    getmem(jf.cache,jf.cachesize*sizeof(journalfilecachetype));
    journentfileinitcache(jf)
  end;

begin
end.
