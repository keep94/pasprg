program process;

  uses IOunit;

  type

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
    oldfilename,newfilename:string;
    escpressed,done:boolean;
    f,g:file of ledrectype;
    segno,numread,cnt:integer;
    ledger:ledgertype;


  begin
    repeat
      write('Ledger file name? ');
      getinput(oldfilename,escpressed);
      writeln;
      if escpressed then exit;
      if not fileexists(oldfilename) then
        begin
          writeln;
          writeln(chr(7)+'Cannot find that file.');
          writeln;
          done := false
        end
      else done := true
    until done;
    repeat
      write('Save new ledger under? ');
      getinput(newfilename,escpressed);
      writeln;
      if escpressed then exit;
      if not filecreation(newfilename) then
        begin
          writeln;
          writeln(chr(7)+'File creation error.');
          writeln;
          done := false
        end
      else done := true
    until done;
    assign(f,oldfilename);
    assign(g,newfilename);
    reset(f);
    rewrite(g);
    segno := 0;
    while not eof(f) do
      begin
        seek(f,segno);
        numread := 0;
        while (numread < 100) and (not eof(f)) do
          begin
            numread := numread + 1;
            read(f,ledger[numread])
          end;
        for cnt := 1 to numread do
          begin
            ledger[cnt].startdate := ledger[cnt].enddate;
            ledger[cnt].moneyspent := '0.00';
            ledger[cnt].oldbalance := ledger[cnt].newbalance;
            write(g,ledger[cnt])
          end;
        segno := segno + numread
      end;
    close(g);
    close(f)
  end.