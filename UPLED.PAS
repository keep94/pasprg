program process;

  uses IOunit;

  type
    ptrtype = ^node;
    node = record
      cat:integer;
      amt:real;
      next:ptrtype
    end;

    buckettype = record
      amt:real;
      next:ptrtype
    end;

    hashtype = array[1..99] of buckettype;

    exprectype = record
      marked:boolean;
      date:string[8];
      cat:string[4];
      name:string[15];
      description:string[50];
      amt:string[10];
      payment:string[4];
      transfer:string[1]
    end;

    ledrectype = record
      marked:boolean;
      startdate:string[8];
      enddate:string[8];
      cat:string[4];
      description:string[15];
      moneyallot:string[10];
      moneyspent:string[10];
      oldbalance:string[10];
      newbalance:string[10]
    end;

    ledgertype = array[1..100] of ledrectype;

  var
    expfile,temp:string;
    markedonly,escpressed,done:boolean;
    f:file of exprectype;
    g:file of ledrectype;
    exprec:exprectype;
    t:hashtype;
    segno,numread,cnt,code,charge,posit:integer;
    ma,ms,ob,nb,x,nummonths:real;
    ledger:ledgertype;


  Procedure inittable(var t:hashtype);

    var cnt:integer;

    begin
      for cnt := 1 to 99 do
        begin
          t[cnt].amt := 0.0;
          t[cnt].next := nil
        end
    end;

  Procedure add(var t:hashtype;posit:integer;x:real);

    var buckno:integer;
        p:ptrtype;
        done:boolean;

    begin
      if (posit >= 100) and (posit <= 9999) then
        begin
          buckno := posit div 100;
          t[buckno].amt := t[buckno].amt + x;
          if posit mod 100 <> 0 then
            begin
              p := t[buckno].next;
              done := false;
              while (p <> nil) and (not done) do
                begin
                  if p^.cat = posit then
                    done := true
                  else
                    p := p^.next
                end;
              if (not done) then
                begin
                  new(p);
                  p^.cat := posit;
                  p^.amt := x;
                  p^.next := t[buckno].next;
                  t[buckno].next := p
                end
              else p^.amt := p^.amt + x
            end
        end
    end;

  Function getamt(var t:hashtype;posit:integer):real;

    var buckno:integer;
        p:ptrtype;
        done:boolean;

    begin
      if (posit < 100) or (posit > 9999) then getamt := 0
      else
        begin
          buckno := posit div 100;
          if posit mod 100 = 0 then
            getamt := t[buckno].amt
          else
            begin
              p := t[buckno].next;
              done := false;
              while (p <> nil) and (not done) do
                begin
                  if p^.cat = posit then done := true
                  else p := p^.next
                end;
              if (not done) then
                getamt := 0
              else
                getamt := p^.amt
            end
        end
    end;

  Procedure resettable(var t:hashtype);

    var cnt:integer;
        p,q:ptrtype;

    begin
      for cnt := 1 to 99 do
        begin
          t[cnt].amt := 0.0;
          p := t[cnt].next;
          while p <> nil do
            begin
              q := p^.next;
              dispose(p);
              p := q
            end
        end
    end;

  begin
    repeat
      write('Process what file? ');
      getinput(expfile,escpressed);
      writeln;
      if escpressed then exit;
      if not fileexists(expfile) then
        begin
          writeln;
          writeln(chr(7)+'Cannot find that file.');
          writeln;
          done := false
        end
      else done := true
    until done;
    write('Process marked records only<y,n>? ');
    getinput(temp,escpressed);
    writeln;
    if escpressed then exit;
    if length(temp) > 0 then markedonly := temp[1] in ['Y','y']
    else markedonly := false;
    inittable(t);
    assign(f,expfile);
    reset(f);
    while not eof(f) do
      begin
        read(f,exprec);
        if (not markedonly) or (exprec.marked) then
          begin
            val(exprec.cat,posit,code);
            val(exprec.amt,x,code);
            val(exprec.payment,charge,code);
            if (exprec.transfer = 'Y') or (exprec.transfer = 'y') then
              add(t,posit,-x)
            else
              add(t,posit,x);
            add(t,charge,x)
          end
      end;
    close(f);
    writeln;
    repeat
      write('Update what ledger? ');
      getinput(expfile,escpressed);
      writeln;
      if escpressed then
        begin
          resettable(t);
          exit
        end;
      if not fileexists(expfile) then
        begin
          writeln;
          writeln(chr(7)+'Cannot find that file.');
          writeln;
          done := false
        end
      else done := true
    until done;
    write('Update marked records only<y,n>? ');
    getinput(temp,escpressed);
    writeln;
    if escpressed then
      begin
        resettable(t);
        exit
      end;
    if length(temp) > 0 then markedonly := temp[1] in ['Y','y']
    else markedonly := false;
    write('Number of months? ');
    getinput(temp,escpressed);
    writeln;
    if escpressed then
      begin
        resettable(t);
        exit
      end;
    val(temp,nummonths,code);
    assign(g,expfile);
    reset(g);
    segno := 0;
    while not eof(g) do
      begin
        seek(g,segno);
        numread := 0;
        while (numread < 100) and (not eof(g)) do
          begin
            numread := numread + 1;
            read(g,ledger[numread])
          end;
        for cnt := 1 to numread do
          if (not markedonly) or (ledger[cnt].marked) then
            begin
              val(ledger[cnt].cat,posit,code);
              val(ledger[cnt].moneyallot,ma,code);
              val(ledger[cnt].oldbalance,ob,code);
              ms := getamt(t,posit);
              nb := ob + nummonths*ma - ms;
              str(ms:0:2,ledger[cnt].moneyspent);
              str(nb:0:2,ledger[cnt].newbalance)
            end;
        seek(g,segno);
        for cnt := 1 to numread do
          write(g,ledger[cnt]);
        segno := segno + numread
      end;
    close(g);
    resettable(t);
  end.