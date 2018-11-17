program tranview;

uses crt,dos,iounit,dates,trans,strutil,afstore,rangutil;

const
  TOP_LINE = 4;
  LINES_PER_PAGE = 18;
  MAX_RESULTS = 5000;
  LOG_FILE_NAME = 'translog.dat';
  LOG_FILE_ENV = 'TRANSLOG';
  AUTO_FILL_MEMORY = 20000;

type
  resultentrytype = record
    date:integer;
    posit:longint;
    balance:real
  end;

  resulttype = record
    size:integer;
    nameaf:afstoretype;
    descaf:afstoretype;
    data:array[0..MAX_RESULTS-1] of resultentrytype
  end;

  querytype=record
    mindate:integer;
    maxdate:integer;
    category:integer;
    namestr:string;
    descstr:string;
    amountstr:string;
    checknostr:string
  end;

  searchworkspacetype=record
    namecaps:string;
    desccaps:string;
    rgamount:rgreal;
    rgcheckno:rgserial
  end;




  summarytype = record
    total:real;
    rctotal:real;
    balance:real;
    totalused:boolean;
    rctotalused:boolean;
    balanceused:boolean;
    showbalances:boolean;
    beginbalance:real
  end;

    scrarraytype = array[0..3999] of byte;
    scrptrtype = ^scrarraytype;


var geditenabled:boolean;
    tf:transfiletype;
    resultsptr:^resulttype;
    qptrinfo:^querytype;
    searchworkspaceptr:^searchworkspacetype;
    choice:integer;
    quitchoice:integer;
    g_logfile,namestr:string;
    tempfh:file of transtype;
    abortpressed:boolean;


Procedure tigetfieldinfo(fieldno:integer;var xcoord,ycoord,len:integer);

  begin
    if (fieldno = 0) then
      begin
        xcoord := 7;
        ycoord := 3;
        len := 8
      end
    else if (fieldno = 1) then
      begin
        xcoord := 7;
        ycoord := 4;
        len := 50
      end
    else if (fieldno = 2) then
      begin
        xcoord := 7;
        ycoord := 5;
        len := 73
      end
    else if (fieldno = 3) then
      begin
        xcoord := 10;
        ycoord := 6;
        len := 6
      end
    else if (fieldno = 4) then
      begin
        xcoord := 10;
        ycoord := 7;
        len := 4
      end
    else if (fieldno = 5) then
      begin
        xcoord := 15;
        ycoord := 7;
        len := 1
      end
    else if (fieldno mod 3 = 0) then
      begin
        xcoord := 5;
        ycoord := ((fieldno - 6) div 3) + 9;
        len := 4
      end
    else if (fieldno mod 3 = 1) then
      begin
        xcoord := 10;
        ycoord := ((fieldno - 6) div 3) + 9;
        len := 15
      end
    else
      begin
        xcoord := 26;
        ycoord := ((fieldno - 6) div 3) + 9;
        len := 1
      end
  end;


Procedure transinitnew(var trans:transtype);

var i:integer;

begin
  trans.date := -1;
  trans.name := '';
  trans.desc := '';
  trans.checkno := '';
  trans.payment := 0;
  trans.numsplits := 0;
  trans.reconciled := false;

  for i := 0 to 9 do
    begin
      trans.splits[i].amount := 0.0;
      trans.splits[i].cat := 0;
      trans.splits[i].reconciled := false
    end
end;


Procedure transcopytotemp(var temptrans:transtype;var trans:transtype);

var i:integer;

  begin
    temptrans := trans;
    for i := temptrans.numsplits to 9 do
      begin
        temptrans.splits[i].amount := 0.0;
        temptrans.splits[i].cat := 0;
        temptrans.splits[i].reconciled := false
      end
  end;


Function adjusttrans(var transrec:transtype;cat:integer;var dcat:string;
  var payment:string;var amount:real;var reconciled:boolean):boolean;

var index:integer;
    result:boolean;

begin
  result := true;
  reconciled := false;
  if (cat = transrec.payment) or (cat = 0) then
    begin
      amount := transtotal(transrec);
      reconciled := transrec.reconciled;
      if (transrec.numsplits > 1) then
         dcat := 'SPLT'
      else
         str(transrec.splits[0].cat:4,dcat);
      str(transrec.payment:4,payment)
    end
  else if (cat < 99) then
    begin
      result := transfindmetacat(transrec,cat,dcat,amount);
      if (result) then
        begin
          if (cat >= 90) then
              amount := -amount;
          reconciled := transrec.reconciled;
          str(transrec.payment:4,payment)
        end
      else
        begin
          amount := 0.0;
          reconciled := false;
          dcat := '*';
          payment := '*'
        end
    end
  else
    begin
      index := transfindcat(transrec,cat);
      if (index <> -1) then
        begin
          if (cat < 9000) then
            begin
              amount := transrec.splits[index].amount;
              reconciled := transrec.reconciled;
              str(cat:4,dcat);
              str(transrec.payment:4,payment)
            end
          else if (cat < 9900) then
            begin
              amount := -transrec.splits[index].amount;
              reconciled := transrec.reconciled;
              str(cat:4,dcat);
              str(transrec.payment:4,payment)
            end
          else
            begin
              amount := -transrec.splits[index].amount;
              reconciled := transrec.splits[index].reconciled;
              str(cat:4,payment);
              str(transrec.payment:4,dcat)
            end
        end
      else
        begin
          result := false;
          amount := 0.0;
          reconciled := false;
          dcat := '*';
          payment := '*'
        end
    end;
  adjusttrans := result
end;


Procedure transjoincats(var trans:transtype);

  var i:integer;
      posit:integer;

  begin
    trans.numsplits := 0;

    for i := 0 to 9 do
      begin
        if (trans.splits[i].cat > 0) and
        (trans.splits[i].amount <> 0.0) and
           (trans.splits[i].cat <> trans.payment) then
          begin
            posit := transfindcat(trans,trans.splits[i].cat);
            if (posit = -1) then
              begin
                posit := trans.numsplits;
                trans.numsplits := trans.numsplits+1;
                trans.splits[posit].cat := trans.splits[i].cat;
                trans.splits[posit].amount := trans.splits[i].amount;
                trans.splits[posit].reconciled := trans.splits[i].reconciled
              end
            else
              begin
                trans.splits[posit].amount := trans.splits[posit].amount +
                     trans.splits[i].amount
              end
          end
      end
  end;



Function validate(var trans:transtype;var msg:string):boolean;

var i:integer;
    foundnotzero:boolean;
    newtrans:transtype;
    isvalid:boolean;

begin
  msg := '';
  isvalid := true;
  if (trans.payment = 0) then
    begin
      msg := 'Valid payment code missing.';
      isvalid := false
    end;
  if (isvalid) and (trans.date < 0) then
    begin
      msg := 'Valid transaction date missing.';
      isvalid := false
    end;
  if isvalid then
    begin
      newtrans := trans;
      transjoincats(newtrans);
      if newtrans.numsplits = 0 then
        begin
          msg := 'Amounts missing.';
          isvalid := false
        end
    end;
  validate := isvalid
end;


Procedure summaryaddtrans(var summary:summarytype;var trans:transtype;
       cat:integer);

var success:boolean;
    dcat,payment:string;
    amount:real;
    reconciled:boolean;

begin
  success := adjusttrans(trans,cat,dcat,payment,amount,reconciled);
  if (summary.totalused) then
      summary.total := summary.total + amount;
  if (summary.balanceused) then
      summary.balance := summary.balance - amount;
  if (summary.rctotalused) then
     begin
       if (reconciled) then
         summary.rctotal := summary.rctotal - amount
     end
end;


Procedure summaryremovetrans(var summary:summarytype;var trans:transtype;
                             cat:integer);

var success:boolean;
    dcat,payment:string;
    amount:real;
    reconciled:boolean;

begin
  success := adjusttrans(trans,cat,dcat,payment,amount,reconciled);
  if (summary.totalused) then
      summary.total := summary.total - amount;
  if (summary.balanceused) then
      summary.balance := summary.balance + amount;
  if (summary.rctotalused) then
     begin
       if (reconciled) then
         summary.rctotal := summary.rctotal + amount
     end
end;


Procedure transmarkreconciled(var trans:transtype;cat:integer);

var posit:integer;

begin
  if (cat = trans.payment) or (not transisvalidpayment(cat)) then
    trans.reconciled := true
  else
    begin
      posit := transfindcat(trans,cat);
      if (posit <> -1) then
          trans.splits[posit].reconciled := true
    end
end;

Procedure transmarkunreconciled(var trans:transtype;cat:integer);

var posit:integer;

begin
  if (cat = trans.payment) or (not transisvalidpayment(cat)) then
    trans.reconciled := false
  else
    begin
      posit := transfindcat(trans,cat);
      if (posit <> -1) then
          trans.splits[posit].reconciled := false
    end
end;




Procedure transedit(var trans:transtype;var escpressed:boolean;var nameaf,descaf:afstoretype);

  var i,xcoord,ycoord,len:integer;
      posit:integer;
      ctrl,scan:settype;
      x,msg:string;
      choice,schoice:char;
      done:boolean;

  begin
    escpressed := false;
    clrscr;
    gotoxy(1,3);
    write('Date: ');
    gotoxy(1,4);
    write('Name: ');
    gotoxy(1,5);
    write('Desc: ');
    gotoxy(1,6);
    write('Check #: ');
    gotoxy(1,7);
    write('Payment: ');
    for i := 0 to 9 do
      begin
        gotoxy(1,9+i);
        write(i:2,': ')
      end;
    for i := 0 to TRANS_NUM_FIELDS - 1 do
      begin
        tigetfieldinfo(i,xcoord,ycoord,len);
        gotoxy(xcoord,ycoord);
        write(copy(transgetstring(trans,i),1,len))
      end;

    posit := 0;
    ctrl := [9,13,27];
    scan := [72,80];
    done := false;

    repeat
      tigetfieldinfo(posit,xcoord,ycoord,len);
      repeat
        gotoxy(xcoord,ycoord);
        x := transgetstring(trans,posit);
        if length(x) > len then
          x := '';
        if (posit =1 ) then
          fieldinputaf(x,len,choice,schoice,ctrl,scan,nameaf,1,1)
        else if (posit=2) then
          fieldinputaf(x,len,choice,schoice,ctrl,scan,descaf,1,1)
        else  
          fieldinput(x,len,choice,schoice,ctrl,scan);
        if (choice <> chr(27)) then
            transsetstring(trans,posit,x,msg)
        else
            msg := '';
        if (msg <> '') then
          begin
            gotoxy(1,1);
            write(msg);
            pause;
            gotoxy(1,1);
            write('':80)
          end
      until (msg = '');
      case choice of
        chr(9):begin
                 gotoxy(xcoord,ycoord);
                 write('':len);
                 gotoxy(xcoord,ycoord);
                 write(copy(transgetstring(trans,posit),1,len));
                 posit := posit + 1;
                 if (posit = TRANS_NUM_FIELDS) then posit := 0
               end;
        chr(13):begin
                  done := validate(trans,msg);
                  if not done then
                    begin
                      gotoxy(1,1);
                      write(msg);
                      pause;
                      gotoxy(1,1);
                      write('':80)
                    end
                end;
        chr(27):begin
                  done := true;
                  escpressed := true
                end;
        chr(0):begin
                 case schoice of
                   chr(72):begin
                             gotoxy(xcoord,ycoord);
                             write('':len);
                             gotoxy(xcoord,ycoord);
                             write(copy(transgetstring(trans,posit),1,len));
                             posit := posit - 1;
                             if (posit < 0) then posit := TRANS_NUM_FIELDS-1
                           end;
                   chr(80):begin
                             gotoxy(xcoord,ycoord);
                             write('':len);
                             gotoxy(xcoord,ycoord);
                             write(copy(transgetstring(trans,posit),1,len));
                             posit := posit + 1;
                             if (posit = TRANS_NUM_FIELDS) then posit := 0
                           end
                 end
               end
      end
    until done
  end;


Procedure reheap(posit:integer;size:integer;var results:resulttype);

  var done:boolean;
      piv:integer;
      temp:resultentrytype;

  begin
    done := false;
    while (not done) and (2*posit + 1 < size) do
      begin
        if 2*posit + 2 = size then
          piv := 2*posit + 1
        else if results.data[2*posit+1].date > results.data[2*posit+2].date then
          piv := 2*posit + 1
        else piv := 2*posit + 2;
        if results.data[posit].date < results.data[piv].date then
          begin
            temp := results.data[posit];
            results.data[posit] := results.data[piv];
            results.data[piv] := temp;
            posit := piv
          end
        else done := true
      end
  end;

Procedure transviewsort(var results:resulttype);

  var cnt:integer;
      temp:resultentrytype;

  begin
    for cnt := (results.size div 2)-1 downto 0 do
      reheap(cnt,results.size,results);
    for cnt := results.size-1 downto 1 do
      begin
        temp := results.data[0];
        results.data[0] := results.data[cnt];
        results.data[cnt] := temp;
        reheap(0,cnt,results)
      end
  end;


Procedure highlight(f,b,x,y,l:integer);

   var p:scrptrtype;
       attr,posit,cnt:integer;

   begin
     p := ptr($B800,$0);
     attr := 16*b + f;
     posit := (y - 1)*160 + (x - 1)*2 + 1;
     for cnt := 1 to l do
       begin
         p^[posit] := attr;
         posit := posit + 2
       end
   end;



Procedure displayamount(x:real;width:integer);

var negative:boolean;
    strn:string;
    px:integer;
    py:integer;

begin
  px := wherex;
  py := wherey;
  negative := (x < 0.0);
  if (negative) then x := -x;
  str(x:width:2,strn);
  if (length(strn) > width) then
    write('*':width)
  else
    write(strn);
  if (negative) then
    highlight(10,0,px,py,width)
  else
    highlight(12,0,px,py,width)
end;

Procedure displayHeader;

begin
  write('Date');
  gotoxy(10,wherey);
  write('Cat.');
  gotoxy(15,wherey);
  write('Chk No');
  gotoxy(22,wherey);
  write('Name');
  gotoxy(53,wherey);
  write('Pmt.');
  gotoxy(58,wherey);
  write('Amount':11);
  gotoxy(69,wherey);
  write('Balance':11)
end;

Procedure setupbalances(var results:resulttype;beginbalance:real);

var i:integer;
    runningtotal:real;

begin
  runningtotal := beginbalance;
  for i := 0 to results.size-1 do
    begin
      runningtotal := runningtotal - results.data[i].balance;
      results.data[i].balance := runningtotal
    end
end;

Procedure adjustBalances(var results:resulttype;startposit:integer;delta:real);

var i:integer;

begin
  for i := startposit to results.size-1 do
    results.data[i].balance := results.data[i].balance - delta;
end;


Procedure balancesAddTrans(var results:resulttype;startposit:integer;cat:integer;
         var trans:transtype);

var success:boolean;
    dcat,payment:string;
    amount:real;
    reconciled:boolean;

begin
  success := adjusttrans(trans,cat,dcat,payment,amount,reconciled);
  adjustBalances(results,startposit,amount)
end;


Procedure balancesRemoveTrans(var results:resulttype;startposit:integer;cat:integer;
         var trans:transtype);

var success:boolean;
    dcat,payment:string;
    amount:real;
    reconciled:boolean;

begin
  success := adjusttrans(trans,cat,dcat,payment,amount,reconciled);
  adjustBalances(results,startposit,-amount)
end;


Procedure balancesAdjustTrans(var results:resulttype;startposit:integer;cat:integer;
         var oldtrans:transtype;var newtrans:transtype);

var success:boolean;
    dcat,payment:string;
    oldamount,newamount:real;
    reconciled:boolean;

begin
  success := adjusttrans(oldtrans,cat,dcat,payment,oldamount,reconciled);
  success := adjusttrans(newtrans,cat,dcat,payment,newamount,reconciled);
  adjustBalances(results,startposit,newamount-oldamount)
end;






Procedure displayline(var f:transfiletype;var results:resulttype;
  i:integer;scrposit:integer;cat:integer;var summary:summarytype);

var
  transrec:transtype;
  dcat,payment:string;
  amount:real;
  success:boolean;
  reconciled:boolean;

begin
  gotoxy(1,scrposit+TOP_LINE);
  write('':79);

  if (i < results.size) then
    begin
      transfileget(f,results.data[i].posit,transrec);
      success := adjusttrans(transrec,cat,dcat,payment,amount,reconciled);
      gotoxy(1,scrposit+TOP_LINE);
      write(datestr(transrec.date));
      gotoxy(10,scrposit+TOP_LINE);
      write(dcat);
      gotoxy(15,scrposit+TOP_LINE);
      write(transrec.checkno);
      gotoxy(22,scrposit+TOP_LINE);
      write(copy(transrec.name,1,28));
      gotoxy(51,scrposit+TOP_LINE);
      if (reconciled) then write('X')
       else write(' ');
      gotoxy(53,scrposit+TOP_LINE);
      write(payment);
      gotoxy(58,scrposit+TOP_LINE);
      displayamount(amount,11);
      if (summary.showbalances) then
        begin
          gotoxy(69,scrposit+TOP_LINE);
          displayamount(-results.data[i].balance,11)
        end
    end
end;


Procedure displayresults(var f:transfiletype;var results:resulttype;posit:integer;
    var scrposit:integer;cat:integer;
    var summary:summarytype);

var i:integer;
    nextline:integer;


begin
  clrscr;
  gotoxy(1,3);
  displayHeader;
  if (scrposit < posit - results.size + LINES_PER_PAGE - 1) then
    scrposit := posit - results.size + LINES_PER_PAGE - 1;

  if (scrposit > posit) then
    scrposit := posit;

  for i := posit - scrposit to posit - scrposit + LINES_PER_PAGE - 1 do
    begin
      if (i < results.size) then
        displayline(f,results,i,i-posit+scrposit,cat,summary)
      else
        begin
          gotoxy(1,i-posit+scrposit+TOP_LINE);
          write('':79)
        end
    end;
  nextline := 0;
  if (summary.totalused) then
    begin
      gotoxy(1,TOP_LINE+LINES_PER_PAGE+1);
      write('Total: ');
      displayamount(summary.total,15);
      nextline := nextline+1
    end;
  if (summary.rctotalused) then
    begin
      gotoxy((nextline mod 2)*40 + 1,TOP_LINE+LINES_PER_PAGE+1+(nextline div 2));
      write('Reconciled Total: ');
      displayamount(-summary.rctotal,15);
      nextline := nextline+1
    end;
  if (summary.balanceused) then
    begin
      gotoxy((nextline mod 2)*40 + 1,TOP_LINE+LINES_PER_PAGE+1+(nextline div 2));
      write('Balance: ');
      displayamount(-summary.balance,15);
      nextline := nextline+1
    end;

   gotoxy((nextline mod 2)*40 + 1,TOP_LINE+LINES_PER_PAGE+1+(nextline div 2));
   write('Number of items: ',results.size);
   highlight(0,7,1,scrposit+TOP_LINE,79)
end;



Procedure uparrow(var f:transfiletype;var results:resulttype;
 var posit:integer;var scrposit:integer;cat:integer;
  var summary:summarytype);

begin
  if (posit > 0) then
    begin
      posit := posit-1;
      if (scrposit > 0) then
        begin
          displayline(f,results,posit+1,scrposit,cat,summary);
          scrposit := scrposit-1;
          highlight(0,7,1,scrposit+TOP_LINE,79)
        end
      else
        displayresults(f,results,posit,scrposit,cat,summary)
    end
end;


Procedure downarrow(var f:transfiletype;var results:resulttype;
  var posit:integer;var scrposit:integer;cat:integer;
  var summary:summarytype);

begin
  if (posit < results.size) then
    begin
      posit := posit+1;
      if (scrposit < LINES_PER_PAGE-1) then
        begin
          displayline(f,results,posit-1,scrposit,cat,summary);
          scrposit := scrposit+1;
          highlight(0,7,1,scrposit+TOP_LINE,79)
        end
      else
        displayresults(f,results,posit,scrposit,cat,summary)
    end
end;
           

Procedure pgup(var f:transfiletype;var results:resulttype;
  var posit:integer;var scrposit:integer;cat:integer;
  var summary:summarytype);

begin
  if (posit > 0) then
    begin
      posit := posit - LINES_PER_PAGE;
      if (posit < 0) then
        posit := 0;
      displayresults(f,results,posit,scrposit,cat,summary)
    end
end;





Procedure pgdn(var f:transfiletype;var results:resulttype;
  var posit:integer;var scrposit:integer;cat:integer;
  var summary:summarytype);

begin
  if (posit < results.size) then
    begin
      posit := posit + LINES_PER_PAGE;
      if (posit > results.size) then
        posit := results.size;
      displayresults(f,results,posit,scrposit,cat,summary)
    end
end;


Function menu(var qinfo:querytype):integer;

  var result,code:integer;
      choicestr:string;
      escpressed:boolean;

  begin
    gotoxy(1,1);
    writeln('M A I N   M E N U':48);
    gotoxy(1,3);
    if (qinfo.mindate > 0) then
      writeln('1.  Set start date: ',datestr(qinfo.mindate))
    else
      writeln('1.  Set start date: ');

    if (qinfo.maxdate > 0) then
      writeln('2.  Set end date: ',datestr(qinfo.maxdate))
    else
      writeln('2.  Set end date: ');

    if (qinfo.category > 0) then
      writeln('3.  Set category: ',qinfo.category)
    else
      writeln('3.  Set category: ');

    writeln('4.  Set name: ',qinfo.namestr);

    writeln('5.  Set description: ',qinfo.descstr);

    writeln('51. Set amount (use , for range): ',qinfo.amountstr);

    writeln('52. Set check # (use , for range): ',qinfo.checknostr);

    writeln('6.  Clear');

    writeln('7.  Do search');


    if (geditenabled) then
      begin
        writeln('8.  Reconcile transactions');
        writeln('9.  Add new transactions');
        writeln('10.  Quit')
      end
    else
      writeln('8.  Quit');

    writeln;
    write('Enter choice: ');
    getinput(choicestr,escpressed);
    val(choicestr,result,code);
    menu := result
  end;


Function getdate(x:string):integer;

var result:integer;
    str:string;
    done:boolean;
    escpressed:boolean;

begin

  done := false;
  repeat
    gotoxy(1,20);
    write(x);
    getinput(str,escpressed);
    if (str = '') then
      begin
        result := -1;
        done := true
      end
    else
      begin
        result := dateval(str);
        if (result > 0) then done := true
        else
          begin
            writeln;
            write('Invalid date.  Press any key.');
            pause;
            gotoxy(1,21);
            write('':80)
          end
      end;
    gotoxy(1,20);
    write('':80)
  until done;
  getdate := result
end;


Function getcategory(x:string):integer;

var result:integer;
    str:string;
    done:boolean;
    escpressed:boolean;
    code:integer;

begin

  done := false;
  repeat
    gotoxy(1,20);
    write(x);
    getinput(str,escpressed);
    if (str = '') then
      begin
        result := 0;
        done := true
      end
    else
      begin
        val(str,result,code);
        if (result > 0) then done := true
        else
          begin
            writeln;
            write('Invalid category.  Press any key.');
            pause;
            gotoxy(1,21);
            write('':80)
          end
      end;
    gotoxy(1,20);
    write('':80)
  until done;
  getcategory := result
end;



Function getname(x:string):string;

var result:string;
    str:string;
    done:boolean;
    escpressed:boolean;
    code:integer;

begin

  done := false;
  repeat
    gotoxy(1,20);
    write(x);
    getinput(str,escpressed);
    result := str;
    done := true;
    gotoxy(1,20);
    write('':80)
  until done;
  getname := result
end;

Procedure viewsingletrans(var tf:transfiletype;var results:resulttype;
    posit:integer);

var transrec:transtype;
    i:integer;

begin
  clrscr;
  transfileget(tf,results.data[posit].posit,transrec);
  writeln('Date: ',datestr(transrec.date));
  writeln('Name: ',transrec.name);
  writeln('Desc: ',transrec.desc);
  writeln('Check #: ',transrec.checkno);
  writeln;
  write('Total: ');
  displayamount(transtotal(transrec),17);
  gotoxy(40,wherey);
  write('Payment: ',transrec.payment);
  write(' ');
  if (transrec.reconciled) then
    write('X');
  writeln;
  for i := 0 to transrec.numsplits-1 do
    begin
      write(i+1:2,': ');
      write(transrec.splits[i].cat:4);
      write(' ');
      if (transrec.splits[i].cat >= 9000) and
           (transrec.splits[i].cat < 9900) then
        displayamount(-transrec.splits[i].amount,15)
      else
        displayamount(transrec.splits[i].amount,15);
      write(' ');
      if (transrec.splits[i].reconciled) then
        write('X');
      writeln
    end;
  writeln;
  write('Press any key to continue.');
  pause
end;



Procedure printamount(x:real;width:integer;var outfile:text);

var strn:string;

begin
  str(x:width:2,strn);
  if (length(strn) > width) then
    write(outfile,'*':width)
  else
    write(outfile,strn)
end;

Procedure printHeader(var outfile:text);

begin
  write(outfile,'Date     ');
  write(outfile,'Cat. ');
  write(outfile,'Chk No ');
  write(outfile,'Name                           ');
  write(outfile,'Pmt. ');
  write(outfile,'Amount':11);
  write(outfile,'Balance':11);
  writeln(outfile);
  writeln(outfile,
'-------------------------------------------------------------------------------')

end;




Procedure printline(var f:transfiletype;var results:resulttype;
  i:integer;cat:integer;var summary:summarytype;var outfile:text);

var
  transrec:transtype;
  dcat,payment:string;
  amount:real;
  success:boolean;
  reconciled:boolean;
  temp:string;

begin
  transfileget(f,results.data[i].posit,transrec);
  success := adjusttrans(transrec,cat,dcat,payment,amount,reconciled);
  temp := copy(datestr(transrec.date),1,8);
  write(outfile,temp);
  write(outfile,'':9-length(temp));
  temp := copy(dcat,1,4);
  write(outfile,temp);
  write(outfile,'':5-length(temp));
  temp := copy(transrec.checkno,1,6);
  write(outfile,temp);
  write(outfile,'':7-length(temp));
  temp := copy(transrec.name,1,28);
  write(outfile,temp);
  write(outfile,'':29-length(temp));
  if (reconciled) then write(outfile,'X ')
       else write(outfile,'  ');
  temp := copy(payment,1,4);
  write(outfile,temp);
  write(outfile,'':5-length(temp));
  printamount(amount,11,outfile);
  if (summary.showbalances) then
    printamount(results.data[i].balance,11,outfile);
  writeln(outfile)
end;


Procedure printresults(var f:transfiletype;var results:resulttype;
    cat:integer;
    var summary:summarytype;var outfile:text);

var i:integer;

begin
  printHeader(outfile);

  for i := 0 to results.size - 1 do
    begin
      printline(f,results,i,cat,summary,outfile)
    end;
  writeln(outfile);
  if (summary.totalused) then
    begin
      write(outfile,'Total:            ');
      printamount(summary.total,15,outfile);
      writeln(outfile)
    end;
  if (summary.rctotalused) then
    begin
      write(outfile,'Reconciled Total: ');
      printamount(summary.rctotal,15,outfile);
      writeln(outfile)
    end;
  if (summary.balanceused) then
    begin
      write(outfile,'Balance:          ');
      printamount(summary.balance,15,outfile);
      writeln(outfile)
    end;
  write(outfile,'Number of items:  ',results.size:15);
  writeln(outfile)
end;




Procedure viewresults(var tf:transfiletype;var results:resulttype;
         cat:integer;var summary:summarytype);

var x:string;
    ctrlset:settype;
    scanset:settype;
    choice:char;
    schoice:char;
    posit:integer;
    scrposit:integer;
    trans,newtrans:transtype;
    escpressed:boolean;
    fileposit:longint;
    i:integer;
    outfile:text;

begin
  ctrlset := [1,5,13,21,24,25,27];
  scanset := [67,72,73,80,81];
  posit := 0;
  scrposit := 0;
  displayresults(tf,results,posit,scrposit,cat,summary);
  repeat
    gotoxy(1,1);
    write('':80);
    gotoxy(1,1);
    returninput(x,choice,schoice,ctrlset,scanset);
    case choice of
      chr(0):begin
               case schoice of
                 chr(67):begin
                           gotoxy(1,1);
                           write('':80);
                           gotoxy(1,1);
                           write('Save output to: ');
                           getinput(x,escpressed);
                           if (not escpressed) then
                             begin
                               if (not filecreation(x)) then
                                 begin
                                   gotoxy(1,1);
                                   write('':80);
                                   gotoxy(1,1);
                                   write('File creation error.');
                                   pause
                                 end
                               else
                                 begin
                                   assign(outfile,x);
                                   rewrite(outfile);
                                   printresults(tf,results,cat,summary,outfile);
                                   close(outfile)
                                 end
                             end
                         end;
                 chr(72):begin
                           uparrow(tf,results,posit,scrposit,cat,summary)
                         end;
                 chr(73):begin
                           pgup(tf,results,posit,scrposit,cat,summary)
                         end;
                 chr(80):begin
                           downarrow(tf,results,posit,scrposit,cat,summary)
                         end;
                 chr(81):begin
                           pgdn(tf,results,posit,scrposit,cat,summary)
                         end
               end
             end;
     chr(1):begin
              if (geditenabled) and (results.size < MAX_RESULTS) then
                begin
                  transinitnew(newtrans);
                  transedit(newtrans,escpressed,results.nameaf,results.descaf);
                  if (not escpressed) then
                    begin
                      transjoincats(newtrans);
                      fileposit := filesize(tf.f);
                      transfilesave(tf,fileposit,newtrans);
                      posit := results.size;
                      results.data[posit].posit := fileposit;
                      results.data[posit].date := newtrans.date;
                      if (posit = 0) then
                        results.data[posit].balance := summary.beginbalance
                      else
                        results.data[posit].balance :=
                          results.data[posit-1].balance;
                      results.size := results.size + 1;
                      summaryaddtrans(summary,newtrans,cat);
                      if (summary.showbalances) then
                        balancesaddtrans(results,posit,cat,newtrans);
                      afstore_add(results.nameaf,newtrans.name);
                      afstore_add(results.descaf,newtrans.desc)
                    end;
                  displayresults(tf,results,posit,scrposit,cat,summary)
                end
             end;
     chr(5):begin
              if (geditenabled) and (posit < results.size) then
                begin
                  transfileget(tf,results.data[posit].posit,trans);
                  transcopytotemp(newtrans,trans);
                  transedit(newtrans,escpressed,results.nameaf,results.descaf);
                  if (not escpressed) then
                    begin
                      transjoincats(newtrans);
                      transfilesave(tf,results.data[posit].posit,newtrans);
                      results.data[posit].date := newtrans.date;
                      summaryremovetrans(summary,trans,cat);
                      summaryaddtrans(summary,newtrans,cat);
                      if (summary.showBalances) then
                        balancesadjusttrans(results,posit,cat,trans,newtrans);
                      afstore_add(results.nameaf,newtrans.name);
                      afstore_add(results.descaf,newtrans.desc)
                    end;
                  displayresults(tf,results,posit,scrposit,cat,summary)
                end
             end;
     chr(13):begin
               if (posit < results.size) then
                 begin
                   viewsingletrans(tf,results,posit);
                   displayresults(tf,results,posit,scrposit,cat,summary)
                 end
             end;
    chr(21):begin
              if (geditenabled) and (posit < results.size) then
                begin
                  gotoxy(1,1);
                  write('Unreconcile this transaction <y,n>? ');
                  getinput(x,escpressed);
                  if (not escpressed) and ((x = 'Y') or (x = 'y')) then
                    begin
                      transfileget(tf,results.data[posit].posit,trans);
                      newtrans := trans;
                      transmarkunreconciled(newtrans,cat);
                      transfilesave(tf,results.data[posit].posit,newtrans);
                      summaryremovetrans(summary,trans,cat);
                      summaryaddtrans(summary,newtrans,cat)
                    end;
                  displayresults(tf,results,posit,scrposit,cat,summary)
                end
             end;
     chr(24):begin
               if (geditenabled) and (posit < results.size) then
                 begin
                   transfileget(tf,results.data[posit].posit,trans);
                   newtrans := trans;
                   transmarkreconciled(newtrans,cat);
                   transfilesave(tf,results.data[posit].posit,newtrans);
                   summaryremovetrans(summary,trans,cat);
                   summaryaddtrans(summary,newtrans,cat);
                   displayresults(tf,results,posit,scrposit,cat,summary)
                 end
              end;
    chr(25):begin
              if (geditenabled) and (posit < results.size) then
                begin
                  gotoxy(1,1);
                  write('Delete this transaction <y,n>? ');
                  getinput(x,escpressed);
                  if (not escpressed) and ((x = 'Y') or (x = 'y')) then
                    begin
                      transfileget(tf,results.data[posit].posit,trans);
                      transmarkdeleted(trans);
                      transfilesave(tf,results.data[posit].posit,trans);
                      for i := posit to results.size-2 do
                        results.data[i] := results.data[i+1];
                      results.size := results.size-1;
                      summaryremovetrans(summary,trans,cat);
                      if (summary.showbalances) then
                        balancesremovetrans(results,posit,cat,trans)
                    end;
                  displayresults(tf,results,posit,scrposit,cat,summary)
                end
            end
   end;
  until (choice = chr(27));
end;

Procedure initAutoFill(var tf:transfiletype;var results:resulttype);

var transrec:transtype;

begin
  seek(tf.f,0);
  while (not eof(tf.f)) do
    begin
      read(tf.f,transrec);
      if not transisdeleted(transrec) then
        begin
          afstore_add(results.nameaf,transrec.name);
          afstore_add(results.descaf,transrec.desc)
        end
    end
end;


Procedure dothesearch(var tf:transfiletype;var results:resulttype;var qinfo:querytype;var workspace:searchworkspacetype);

var
  transrec:transtype;
  posit:longint;
  isincluded:boolean;
  escpressed:boolean;
  temp:string;
  success:boolean;
  dcat,payment:string;
  amount:real;
  total:real;
  ch:char;
  summary:summarytype;
  reconciled:boolean;


begin
  summary.balanceused := (qinfo.category > 9900) and (qinfo.category <= 9999);
  summary.showbalances := (summary.balanceused) and (qinfo.namestr = '') and (qinfo.descstr = '')
  and (qinfo.amountstr = '') and (qinfo.checknostr = '');
  summary.totalused := true;
  summary.rctotalused := false;
  summary.balance := 0.0;
  summary.total := 0.0;
  summary.beginbalance := 0.0;
  workspace.namecaps := qinfo.namestr;
  workspace.desccaps := qinfo.descstr;
  caps(workspace.namecaps);
  caps(workspace.desccaps);
  if (qinfo.amountstr <> '') then rgrealinit(workspace.rgamount,qinfo.amountstr);
  if (qinfo.checknostr <> '') then rgserialinit(workspace.rgcheckno,qinfo.checknostr);


  clrscr;
  gotoxy(1,12);
  write('Press ESC to cancel search');
  posit := 0;
  seek(tf.f,0);
  results.size := 0;
  escpressed := false;
  total := 0.0;
  while (not eof(tf.f)) and (not escpressed) do
    begin
      read(tf.f,transrec);
      if not transisdeleted(transrec) then
        begin
          isincluded := true;
          if (qinfo.mindate > 0) then
            begin
              if (transrec.date < qinfo.mindate) then
                isincluded := false
            end;

          if (qinfo.maxdate > 0) and (isincluded) then
            begin
              if (transrec.date > qinfo.maxdate) then
                isincluded := false
            end;

         if (qinfo.namestr <> '') and (isincluded) then
            begin
              temp := transrec.name;
              caps(temp);
              if indexof(temp,workspace.namecaps) = -1 then
                 isincluded := false
            end;
         if (qinfo.descstr <> '') and (isincluded) then
            begin
              temp := transrec.desc;
              caps(temp);
              if indexof(temp,workspace.desccaps) = -1 then
                isincluded := false
            end;
          if (qinfo.amountstr <> '') and (isincluded) then
            begin
              success := adjusttrans(transrec,qinfo.category,dcat,
                payment,amount,reconciled);
              if success then
                isIncluded := rgrealcompare(workspace.rgamount,amount)
               else
                 isIncluded := false
            end;

          if (qinfo.checknostr <> '') and (isincluded) then
            begin
              isIncluded := rgserialcompare(workspace.rgcheckno,transrec.checkno)
            end;

          if (summary.balanceused) then
            begin
              success := adjusttrans(transrec,qinfo.category,dcat,
                payment,amount,reconciled);
              if success then
                begin
                  summary.balance := summary.balance - amount;
                  if (summary.showbalances) and (qinfo.mindate > 0) and
                  (transrec.date < qinfo.mindate) then
                     summary.beginbalance := summary.beginbalance - amount
                end
            end;

          if (isincluded) then
            begin
              if not summary.balanceused then
                  success := adjusttrans(transrec,qinfo.category,dcat,
                    payment,amount,reconciled);

              if (success) then
                begin
                  results.data[results.size].date := transrec.date;
                  results.data[results.size].posit := posit;
                  results.data[results.size].balance := amount;
                  transfileput(tf,posit,transrec);
                  results.size := results.size + 1;
                  total := total + amount
                end
            end
        end;

      if (results.size = MAX_RESULTS) then
        escpressed := true;

      posit := posit + 1;
      if (keypressed) then
        begin
          ch := readkey;
          if ch = chr(27) then
            escpressed := true
        end
    end;
  if (escpressed) then
    begin
      if (results.size = MAX_RESULTS) then
        begin
          gotoxy(1,12);
          write('':80);
          gotoxy(1,12);
          write('To many results, use a more specific search criteria.');
          pause
        end
    end
  else
    begin
      if (results.size = 0) then
        begin
          gotoxy(1,12);
          write('':80);
          gotoxy(1,12);
          write('No results found for your search.  Press any key.');
          pause
        end
      else
        begin
          transviewsort(results);
          summary.totalused := true;
          summary.total := total;
          summary.rctotalused := false;
          if (summary.showBalances) then
            setupbalances(results,summary.beginbalance);
          viewresults(tf,results,qinfo.category,summary)
        end
    end
end;


Procedure doreconcilesearch(var tf:transfiletype;var results:resulttype;
   category:integer);

var
  transrec:transtype;
  posit:longint;
  isincluded:boolean;
  escpressed:boolean;
  temp:string;
  success:boolean;
  dcat,payment:string;
  amount:real;
  total:real;
  ch:char;
  summary:summarytype;
  reconciled:boolean;

begin
  summary.balanceused := true;
  summary.showbalances := false;
  summary.totalused := false;
  summary.rctotalused := true;
  summary.balance := 0.0;
  summary.rctotal := 0.0;

  clrscr;
  gotoxy(1,12);
  write('Press ESC to cancel search');
  posit := 0;
  seek(tf.f,0);
  results.size := 0;
  escpressed := false;
  total := 0.0;
  while (not eof(tf.f)) and (not escpressed) do
    begin
      read(tf.f,transrec);
      if not transisdeleted(transrec) then
        begin
          success := adjusttrans(transrec,category,dcat,
                payment,amount,reconciled);
          if success then
            begin
              summary.balance := summary.balance - amount;
              if (not reconciled) then
                begin
                  results.data[results.size].date := transrec.date;
                  results.data[results.size].posit := posit;
                  results.data[results.size].balance := amount;
                  transfileput(tf,posit,transrec);
                  results.size := results.size + 1

                end
              else
                summary.rctotal := summary.rctotal - amount
            end
        end;

      if (results.size = MAX_RESULTS) then
        escpressed := true;

      posit := posit + 1;
      if (keypressed) then
        begin
          ch := readkey;
          if ch = chr(27) then
            escpressed := true
        end
    end;
  if (escpressed) then
    begin
      if (results.size = MAX_RESULTS) then
        begin
          gotoxy(1,12);
          write('':80);
          gotoxy(1,12);
          write('To many results, use a more specific search criteria.');
          pause
        end
    end
  else
    begin
      if (results.size = 0) then
        begin
          gotoxy(1,12);
          write('':80);
          gotoxy(1,12);
          write('No unreconciled transactions found.  Balance is: ');
          displayAmount(-summary.balance,15);
          pause
        end
      else
        begin
          transviewsort(results);
          viewresults(tf,results,category,summary)
        end
    end
end;


Procedure doAddTransactions(var tf:transfiletype;var results:resulttype);

var summary:summarytype;

begin
  results.size := 0;
  summary.totalused := false;
  summary.rctotalused := false;
  summary.balanceused := false;
  summary.showbalances := false;
  viewresults(tf,results,0,summary)
end;


begin
  g_logfile := getenv(LOG_FILE_ENV);
  if g_logfile = '' then g_logfile := LOG_FILE_NAME;
  geditenabled := (paramstr(1) = '-edit');
  if (geditenabled) then quitchoice := 10
    else quitchoice := 8;
  if (not fileexists(g_logfile)) then
    begin
      if (not geditenabled) then
        begin
          writeln('Cannot find log file: ',g_logfile);
          writeln('Set environement variable ',LOG_FILE_ENV);
          halt(0)
        end
      else
        begin
          writeln('Cannot find log file: ',g_logfile);
          write('Create it<y,n>? ');
          getinput(namestr,abortpressed);
          writeln;
          if (not abortpressed) then caps(namestr);
          if ((not abortpressed) and (namestr = 'Y')) then
            begin
              if (not filecreation(g_logfile)) then
                begin
                  writeln('Cannot create file: ',g_logfile);
                  halt(0)
                end
              else
                begin
                  assign(tempfh,g_logfile);
                  rewrite(tempfh);
                  close(tempfh)
                end  {create file}
            end { yes }
          else
            begin
              halt(0)
            end { no }
        end  {edit enabled}
    end; {not file exist}

  new(resultsptr);
  resultsptr^.size := 0;
  afstore_init(resultsptr^.nameaf,AUTO_FILL_MEMORY);
  afstore_init(resultsptr^.descaf,AUTO_FILL_MEMORY);
  transfileassign(tf,g_logfile,200);
  reset(tf.f);
  initAutoFill(tf,resultsptr^);

  new(qptrinfo);
  new(searchworkspaceptr);

  qptrinfo^.mindate := -1;
  qptrinfo^.maxdate := -1;
  qptrinfo^.category := 0;
  qptrinfo^.namestr := '';
  qptrinfo^.descstr := '';
  qptrinfo^.amountstr := '';
  qptrinfo^.checknostr := '';

  repeat
    clrscr;
    choice := menu(qptrinfo^);
    case choice of
      1:qptrinfo^.mindate := getDate('Enter start date [ENTER] clears: ');
      2:qptrinfo^.maxdate := getDate('Enter end date [ENTER] clears: ');
      3:qptrinfo^.category := getCategory('Enter category [ENTER] clears: ');
      4:qptrinfo^.namestr := getName('Enter name [ENTER] clears: ');
      5:qptrinfo^.descstr := getName('Enter description [ENTER] clears: ');
      51:qptrinfo^.amountstr := getName('Enter amount range [ENTER] clears: ');
      52:qptrinfo^.checknostr := getName('Enter check # range [ENTER] clears: ');
      6:begin
          qptrinfo^.mindate := -1;
          qptrinfo^.maxdate := -1;
          qptrinfo^.category := 0;
          qptrinfo^.namestr := '';
          qptrinfo^.descstr := '';
          qptrinfo^.amountstr := '';
          qptrinfo^.checknostr := ''
        end;
      7:begin
          doTheSearch(tf,resultsptr^,qptrinfo^,searchworkspaceptr^)
        end;
      8:if (geditenabled) then
          begin
            if (transisvalidpayment(qptrinfo^.category)) then
              doreconcilesearch(tf,resultsptr^,qptrinfo^.category)
            else
              begin
                clrscr;
                gotoxy(1,12);
                write('Invalid payment code.');
                pause
              end
          end;
      9:if (geditenabled) then
          begin
            doaddtransactions(tf,resultsptr^)
          end;
    end
  until (choice = quitchoice);

  transfileclose(tf);
  afstore_destroy(resultsptr^.nameaf);
  afstore_destroy(resultsptr^.descaf);
  dispose(resultsptr);
  dispose(qptrinfo);
  dispose(searchworkspaceptr)
end.








