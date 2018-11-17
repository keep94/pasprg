unit trans;

interface

const
  TRANS_MAX_CACHE_SIZE = 250;
  TRANS_NUM_FIELDS = 36;

type
  splittype = record
    cat:integer;
    amount:real;
    reconciled:boolean;
  end;

  transtype = record
    date:integer;
    reconciled:boolean;
    payment:integer;
    name:string[50];
    desc:string[75];
    checkno:string[6];
    numsplits:integer;
    splits:array[0..9] of splittype
  end;

  transcachenode = record
    posit:longint;
    data:transtype
  end;

  transcachetype = array[0..TRANS_MAX_CACHE_SIZE] of transcachenode;
  transcacheptrtype = ^transcachetype;

  transfiletype = record
    f:file of transtype;
    cachesize:integer;
    ptr:transcacheptrtype
  end;

  Function transisvalidcat(cat:integer):boolean;

  Function transisvalidpayment(cat:integer):boolean;

  Function transisvaliddeposit(cat:integer):boolean;

  Procedure transmarkdeleted(var trans:transtype);

  Function transisdeleted(var trans:transtype):boolean;

  Function transgetstring(var trans:transtype;fieldno:integer):string;

  Procedure transsetstring(var trans:transtype;fieldno:integer;newval:string;
         var msg:string);

  Procedure transfileassign(var tf:transfiletype;pathname:string;size:integer);

  Procedure transfileget(var tf:transfiletype;recno:longint;var trans:transtype);

  Procedure transfilesave(var tf:transfiletype;recno:longint;var trans:transtype);

  Procedure transfileput(var tf:transfiletype;recno:longint;var trans:transtype);

  Procedure transfileclose(var tf:transfiletype);

  Function transtotal(var t:transtype):real;

  Function transfindcat(var t:transtype;x:integer):integer;

  Function transfindmetacat(var t:transtype;x:integer;var cat:string;var amount:real):boolean;

  implementation

  uses dates;

  Function transisvalidcat(cat:integer):boolean;

  begin
    transisvalidcat := (cat >= 101) and (cat <= 9999) and (not (cat mod 100 = 0));
  end;

  Function transisvalidpayment(cat:integer):boolean;

  begin
    transisvalidpayment := (cat >= 9901) and (cat <= 9999);
  end;

  Function transisvaliddeposit(cat:integer):boolean;

  begin
    transisvaliddeposit := (cat >= 9001) and (cat < 9900);
  end;


  Procedure transmarkdeleted(var trans:transtype);

  begin
    trans.date := -10517
  end;

  Function transisdeleted(var trans:transtype):boolean;

  begin
    transisdeleted := (trans.date = -10517)
  end;

  Function transgetstring(var trans:transtype;fieldno:integer):string;

  var tmpstr:string;

  begin
    if (fieldno = 0) then
      begin
        if (trans.date < 0) then
          transgetstring := ''
        else
          transgetstring := datestr(trans.date)
      end
    else if (fieldno = 1) then
      transgetstring := trans.name
    else if (fieldno = 2) then
      transgetstring := trans.desc
    else if (fieldno = 3) then
      transgetstring := trans.checkno
    else if (fieldno = 4) then
      begin
        if (trans.payment = 0) then
          transgetstring := ''
        else
          begin
            str(trans.payment,tmpstr);
            transgetstring := tmpstr
          end
      end
    else if (fieldno = 5) then
      begin
        if (trans.reconciled) then
          transgetstring := 'X'
        else
          transgetstring := ''
      end
    else if (fieldno mod 3 = 0) then
      begin
        if (trans.splits[(fieldno-6) div 3].cat = 0) then
          transgetstring := ''
        else
          begin
            str(trans.splits[(fieldno-6) div 3].cat,tmpstr);
            transgetstring := tmpstr
          end
      end
    else if (fieldno mod 3 = 1) then
      begin
        if (trans.splits[(fieldno-6) div 3].amount = 0.0) then
          transgetstring := ''
        else
          begin
            str(trans.splits[(fieldno-6) div 3].amount:0:2,tmpstr);
            transgetstring := tmpstr
          end
      end
    else
      begin
        if (trans.splits[(fieldno-6) div 3].reconciled) then
          transgetstring := 'X'
        else
          transgetstring := ''
      end
  end;


  Procedure transsetstring(var trans:transtype;fieldno:integer;newval:string;
     var msg:string);

  var code:integer;
      tempint:integer;
      tempreal:real;

  begin
    msg := '';
    if (fieldno = 0) then
      begin
        tempint := dateval(newval);
        if (tempint < 0) then
          msg := 'Invalid date.'
        else
          trans.date := tempint
      end
    else if (fieldno = 1) then
      trans.name := copy(newval,1,50)
    else if (fieldno = 2) then
      trans.desc := copy(newval,1,75)
    else if (fieldno = 3) then
      trans.checkno := copy(newval,1,6)
    else if (fieldno = 4) then
      begin
        val(newval,tempint,code);
        if not transisvalidpayment(tempint) then
          msg := 'Invalid payment code.'
        else
          trans.payment := tempint
      end
    else if (fieldno = 5) then
      begin
        if (newval = '') or (newval = ' ') then
          trans.reconciled := false
        else
          trans.reconciled := true
      end
    else if (fieldno mod 3 = 0) then
      begin
        val(newval,tempint,code);
        if (tempint <> 0) and not transisvalidcat(tempint) then
          msg := 'Invalid category code.'
        else
          trans.splits[(fieldno-6) div 3].cat := tempint
      end
    else if (fieldno mod 3 = 1) then
      begin
        val(newval,tempreal,code);
        trans.splits[(fieldno-6) div 3].amount := tempreal
      end
    else
      begin
        if (newval = '') or (newval = ' ') then
          trans.splits[(fieldno-6) div 3].reconciled := false
        else
          trans.splits[(fieldno-6) div 3].reconciled := true
      end
  end;     
    

  Procedure transfileassign(var tf:transfiletype;pathname:string;size:integer);

  var i:integer;
      wsize:word;

  begin
    assign(tf.f,pathname);
    tf.cachesize := size;
    wsize := size;
    getmem(tf.ptr,wsize*sizeof(transcachenode));
    for i:=0 to size-1 do
        tf.ptr^[i].posit := -1
  end;

  Procedure transfileget(var tf:transfiletype;recno:longint;var trans:transtype);

  var cposit:integer;

  begin
    cposit := recno mod tf.cachesize;
    if (tf.ptr^[cposit].posit <> recno) then
      begin
        seek(tf.f,recno);
        read(tf.f,tf.ptr^[cposit].data);
        tf.ptr^[cposit].posit := recno
      end;
    trans := tf.ptr^[cposit].data
  end;

  Procedure transfilesave(var tf:transfiletype;recno:longint;var trans:transtype);

  begin
    transfileput(tf,recno,trans);
    seek(tf.f,recno);
    write(tf.f,trans)
  end;

  Procedure transfileput(var tf:transfiletype;recno:longint;var trans:transtype);

  var cposit:integer;

  begin
    cposit := recno mod tf.cachesize;
    tf.ptr^[cposit].data := trans;
    tf.ptr^[cposit].posit := recno
  end;

  Procedure transfileclose(var tf:transfiletype);

  var wsize:word;

  begin
    wsize := tf.cachesize;
    freemem(tf.ptr,wsize*sizeof(transcachenode));
    close(tf.f)
  end;

  Function transtotal(var t:transtype):real;

  var
    sum:real;
    i:integer;

  begin
    sum := 0.0;

    for i:= 0 to t.numsplits-1 do
      begin
        if transisvaliddeposit(t.splits[i].cat) then
          sum := sum - t.splits[i].amount
        else
          sum := sum + t.splits[i].amount
      end;
    transtotal := sum
  end;

  Function transfindcat(var t:transtype;x:integer):integer;

  var
    i:integer;
    result:integer;
    found:boolean;

  begin
    found := false;
    result := -1;
    i := 0;

    while (i < t.numsplits) and (not found) do
      begin
        if (x = t.splits[i].cat) then
          begin
            result := i;
            found := true
          end
        else
          begin
            i := i + 1
          end
      end;
    transfindcat := result
  end;

  Function transfindmetacat(var t:transtype;x:integer;var cat:string;var amount:real):boolean;

  var
    i:integer;
    result:boolean;
    numfound:integer;
    lastcat:integer;

  begin
    i := 0;
    result := false;
    numfound := 0;
    lastcat := -1;

    cat := '*';
    amount := 0.0;

    for i := 0 to t.numsplits-1 do
      begin
        if (x = t.splits[i].cat div 100) then
          begin
            amount := amount + t.splits[i].amount;
            numfound := numfound + 1;
            lastcat := t.splits[i].cat;
            result := true
          end
      end;
    if (numfound = 1) then
        str(lastcat:4,cat)
    else if (numfound > 1) then
        cat := 'SPLT';
    transfindmetacat := result
  end;
        

begin
end.
