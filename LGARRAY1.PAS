unit lgarray;

interface

  const
    fieldnamesize = 15;
    maxfields = 18;

  type
    indivfieldtype = record
      name:string[fieldnamesize];
      typeoffield:char;
      recoffset:word
    end;

    fieldtype = array[1..maxfields] of indivfieldtype;

    arraytype = array[0..65519] of byte;

    bufptrtype = ^arraytype;

    indextype = array[0..16379] of longint;

    indexptrtype = ^indextype;

    dbasetype = record
      f:file;
      dosname:string[80];
      fsize:longint;
      recordsize:word;
      numfields:word;
      fields:fieldtype;
      bufptr:array[0..15] of bufptrtype;
      numsegs:integer;
      segsize:word;
      remainder:word;
      indexptr:indexptrtype;
      maxinmem:word;
      cblock:longint;
      cindiv:longint;
      altered1:boolean;
      altered0:boolean;
    end;

  Function blocknum(var alldata:dbasetype;recnum:longint):longint;

  Function indexnum(var alldata:dbasetype;recnum:longint):word;

  Function whichrecord(var alldata:dbasetype;cblock:longint;memrec:word):longint;

  Function bufloc(var alldata:dbasetype;memrec,fieldnum:word):longint;

  Procedure lowlowassign(var p:pointer;var alldata:dbasetype;bufposit:longint);

  Procedure lowassignptr(var p:pointer;var alldata:dbasetype;memrec,fieldnum:word);

  Function fieldsize(var alldata:dbasetype;fieldnum:word):word;

  Function recordsondisk(var alldata:dbasetype):longint;

  Procedure findondisk(var alldata:dbasetype;recno:longint;fieldnum:word);

  Procedure resetindiv(var alldata:dbasetype;recnum:longint);

  Procedure resetfile(var alldata:dbasetype;whatblock:longint);

  Procedure initfile(var alldata:dbasetype;filename:string);

  Procedure closeindiv(var alldata:dbasetype);

  Procedure closefile(var alldata:dbasetype);

  Procedure assignptr(var p:pointer;var alldata:dbasetype;recnum:longint;fieldnum:word;mode:integer);

  Function getvalue(var alldata:dbasetype;recnum:longint;fieldnum:word;mode:integer):string;

  Procedure assignvalue(var alldata:dbasetype;recnum:longint;fieldnum:word;temp:string;mode:integer);

  Function ismarked(var alldata:dbasetype;recnum:longint;mode:integer):boolean;

  Procedure markit(var alldata:dbasetype;recnum:longint;boolvar:boolean;mode:integer);

  Procedure appendrecord(var alldata:dbasetype);

  Procedure initfields(var alldata:dbasetype;filename:string);

  Procedure initlgarray(var alldata:dbasetype;bufsize:longint);

  Procedure resetlgarray(var alldata:dbasetype);

  Procedure purge(var alldata:dbasetype);

implementation

  Function blocknum(var alldata:dbasetype;recnum:longint):longint;

    begin
      blocknum := ((recnum - 1) div alldata.maxinmem) + 1
    end;

  Function indexnum(var alldata:dbasetype;recnum:longint):word;

    begin
      indexnum := ((recnum - 1) mod alldata.maxinmem) + 1
    end;

  Function whichrecord(var alldata:dbasetype;cblock:longint;memrec:word):longint;

    begin
      whichrecord := (cblock - 1)*alldata.maxinmem + memrec
    end;

  Function bufloc(var alldata:dbasetype;memrec,fieldnum:word):longint;

    begin
      if fieldnum = 0 then
        bufloc := alldata.indexptr^[memrec]
      else
        bufloc := alldata.indexptr^[memrec] + alldata.fields[fieldnum].recoffset
    end;

  Procedure lowlowassign(var p:pointer;var alldata:dbasetype;bufposit:longint);

    begin
      p := addr(alldata.bufptr[bufposit div alldata.segsize]^[bufposit mod alldata.segsize])
    end;

  Procedure lowassignptr(var p:pointer;var alldata:dbasetype;memrec,fieldnum:word);

    begin
      lowlowassign(p,alldata,bufloc(alldata,memrec,fieldnum))
    end;

  Function fieldsize(var alldata:dbasetype;fieldnum:word):word;

    begin
      if fieldnum = alldata.numfields then
        fieldsize := alldata.recordsize - alldata.fields[fieldnum].recoffset
      else
        fieldsize := alldata.fields[fieldnum+1].recoffset - alldata.fields[fieldnum].recoffset
    end;



  Function recordsondisk(var alldata:dbasetype):longint;

    var size:longint;

    begin
      size := filesize(alldata.f);
      recordsondisk := size div alldata.recordsize
    end;

  Procedure findondisk(var alldata:dbasetype;recno:longint;fieldnum:word);

    begin
      if fieldnum = 0 then
        seek(alldata.f,(recno-1)*alldata.recordsize)
      else
        seek(alldata.f,(recno-1)*alldata.recordsize+alldata.fields[fieldnum].recoffset)
    end;

  Procedure resetindiv(var alldata:dbasetype;recnum:longint);

    var p:pointer;
        numread:word;

    begin
      lowassignptr(p,alldata,0,0);
      findondisk(alldata,recnum,0);
      blockread(alldata.f,p^,alldata.recordsize,numread);
      alldata.cindiv := recnum;
      alldata.altered0 := false
    end;

  Procedure resetfile(var alldata:dbasetype;whatblock:longint);

    var cnt,numread:word;
        p:pointer;

    begin
      findondisk(alldata,whichrecord(alldata,whatblock,1),0);
      alldata.cblock := whatblock;
      alldata.cindiv := 0;
      alldata.altered0 := false;
      alldata.altered1 := false;
      alldata.fsize := recordsondisk(alldata);
      cnt := 0;
      while (cnt < alldata.maxinmem) and (whichrecord(alldata,whatblock,cnt) < alldata.fsize) do
        begin
          cnt := cnt + 1;
          lowassignptr(p,alldata,cnt,0);
          blockread(alldata.f,p^,alldata.recordsize,numread)
        end
    end;

  Procedure initfile(var alldata:dbasetype;filename:string);

    var cnt,numread:word;
        p:pointer;

    begin
      assign(alldata.f,filename);
      alldata.dosname := filename;
      reset(alldata.f,1);
      resetfile(alldata,1)
    end;


  Procedure closeindiv(var alldata:dbasetype);

    var numwritten:word;
        p:pointer;

    begin
      if (alldata.cindiv > 0) and (alldata.altered0) then
        begin
          findondisk(alldata,alldata.cindiv,0);
          lowassignptr(p,alldata,0,0);
          blockwrite(alldata.f,p^,alldata.recordsize,numwritten)
        end;
      alldata.altered0 := false;
      alldata.cindiv := 0
    end;


  Procedure closefile(var alldata:dbasetype);

    var cnt,numwritten:word;
        p:pointer;

    begin
      closeindiv(alldata);
      if alldata.altered1 then
        begin
          findondisk(alldata,whichrecord(alldata,alldata.cblock,1),0);
          cnt := 0;
          while (cnt < alldata.maxinmem) and (whichrecord(alldata,alldata.cblock,cnt) < alldata.fsize) do
            begin
              cnt := cnt + 1;
              lowassignptr(p,alldata,cnt,0);
              blockwrite(alldata.f,p^,alldata.recordsize,numwritten)
            end
        end;
      alldata.altered1 := false
    end;

  Procedure assignptr(var p:pointer;var alldata:dbasetype;recnum:longint;fieldnum:word;mode:integer);

    var cnt,numread,numwritten:word;
        oldposit:longint;

    begin
      if blocknum(alldata,recnum) = alldata.cblock then
        lowassignptr(p,alldata,indexnum(alldata,recnum),fieldnum)
      else if mode = 0 then
        begin
          if recnum = alldata.cindiv then
            lowassignptr(p,alldata,0,fieldnum)
          else
            begin
              closeindiv(alldata);
              resetindiv(alldata,recnum);
              lowassignptr(p,alldata,0,fieldnum)
            end
        end
      else
        begin
          oldposit := filepos(alldata.f);
          closefile(alldata);
          resetfile(alldata,blocknum(alldata,recnum));
          lowassignptr(p,alldata,indexnum(alldata,recnum),fieldnum);
          seek(alldata.f,oldposit)
        end
    end;

  Function getvalue(var alldata:dbasetype;recnum:longint;fieldnum:word;mode:integer):string;

    var p:^string;

    begin
      assignptr(pointer(p),alldata,recnum,fieldnum,mode);
      getvalue := p^
    end;

  Procedure assignvalue(var alldata:dbasetype;recnum:longint;fieldnum:word;temp:string;mode:integer);

    var p:^string;

    begin
      assignptr(pointer(p),alldata,recnum,fieldnum,mode);
      p^ := copy(temp,1,fieldsize(alldata,fieldnum)-1);
      if (mode = 0) and (blocknum(alldata,recnum) <> alldata.cblock) then alldata.altered0 := true
      else alldata.altered1 := true
    end;

  Function ismarked(var alldata:dbasetype;recnum:longint;mode:integer):boolean;

    var p:^boolean;

    begin
      assignptr(pointer(p),alldata,recnum,0,mode);
      ismarked := p^
    end;

  Procedure markit(var alldata:dbasetype;recnum:longint;boolvar:boolean;mode:integer);

    var p:^boolean;

    begin
      assignptr(pointer(p),alldata,recnum,0,mode);
      p^ := boolvar;
      if (mode = 0) and (blocknum(alldata,recnum) <> alldata.cblock) then alldata.altered0 := true
      else alldata.altered1 := true
    end;

  Procedure appendrecord(var alldata:dbasetype);

    var cnt:word;

    begin
      markit(alldata,alldata.fsize+1,false,1);
      for cnt := 1 to alldata.numfields do
        assignvalue(alldata,alldata.fsize+1,cnt,'',1);
      alldata.fsize := alldata.fsize + 1
    end;

  Procedure initfields(var alldata:dbasetype;filename:string);

    var infile:text;
        temp:string;
        posit,strsize:word;
        code:integer;

    begin
      assign(infile,filename);
      reset(infile);
      with alldata do
        begin
          numfields := 0;
          posit := 1;
          while not eof(infile) do
            begin
              numfields := numfields + 1;
              readln(infile,temp);
              fields[numfields].name := copy(temp,1,fieldnamesize);
              readln(infile,temp);
              fields[numfields].typeoffield := temp[1];
              fields[numfields].typeoffield := upcase(fields[numfields].typeoffield);
              fields[numfields].recoffset := posit;
              readln(infile,temp);
              val(temp,strsize,code);
              posit := posit + strsize + 1
            end;
          recordsize := posit
        end;
      close(infile)
    end;

  Procedure initlgarray(var alldata:dbasetype;bufsize:longint);

    var cnt:integer;

    begin
      if bufsize > 16380*longint(alldata.recordsize) then
        bufsize := 16380*longint(alldata.recordsize);
      alldata.segsize := (65520 div alldata.recordsize)*alldata.recordsize;
      if bufsize > longint(alldata.segsize)*16 then
        bufsize := longint(alldata.segsize)*16;
      alldata.maxinmem := (bufsize div alldata.recordsize) - 1;
      bufsize := (longint(alldata.maxinmem)+1)*longint(alldata.recordsize);
      alldata.numsegs := bufsize div alldata.segsize;
      for cnt := 0 to alldata.numsegs - 1 do
        getmem(alldata.bufptr[cnt],alldata.segsize);
      alldata.remainder := bufsize mod alldata.segsize;
      if alldata.remainder > 0 then
        getmem(alldata.bufptr[alldata.numsegs],alldata.remainder);
      getmem(alldata.indexptr,(alldata.maxinmem+1)*sizeof(longint));
      for cnt := 0 to alldata.maxinmem do
        alldata.indexptr^[cnt] := longint(alldata.recordsize)*longint(cnt)
    end;


  Procedure resetlgarray(var alldata:dbasetype);

    var cnt:integer;

    begin
      for cnt := 0 to alldata.numsegs-1 do
        freemem(alldata.bufptr[cnt],alldata.segsize);
      if alldata.remainder > 0 then
        freemem(alldata.bufptr[alldata.numsegs],alldata.remainder);
      freemem(alldata.indexptr,(alldata.maxinmem+1)*sizeof(longint))
    end;

  Procedure purge(var alldata:dbasetype);

    var temp:longint;
        cnt,newend:word;
        p:^boolean;

    begin
      newend := 0;
      for cnt := 1 to alldata.fsize do
        begin
          lowassignptr(pointer(p),alldata,cnt,0);
          if (not p^) then
            begin
              newend := newend + 1;
              temp := alldata.indexptr^[newend];
              alldata.indexptr^[newend] := alldata.indexptr^[cnt];
              alldata.indexptr^[cnt] := temp
            end
        end;
      alldata.fsize := newend;
      alldata.altered1 := true;
      seek(alldata.f,0);
      truncate(alldata.f)
    end;

  end.