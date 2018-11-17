program journal;

uses crt,dos,iounit,dates,journent,lstr,lstrnav,lstred,strutil;

const
  TOP_LINE = 4;
  LINES_PER_PAGE = 18;
  MAX_RESULTS = 10000;
  LOG_FILE_NAME = 'journal.dat';
  LOG_FILE_ENV = 'JOURNAL';

type
  resultentrytype = record
    date:integer;
    posit:longint
  end;

  resulttype = record
    size:integer;
    data:array[0..MAX_RESULTS-1] of resultentrytype
  end;

  scrarraytype = array[0..3999] of byte;
  scrptrtype = ^scrarraytype;


var
    jf:journalfiletype;
    resultsptr:^resulttype;
    minDate:integer;
    maxDate:integer;
    namestr:string;
    descstr:string;
    choice:integer;
    g_logfile:string;
    abortpressed:boolean;
    temp:string;
    geditparams:lstredittype;
    gcontent:longstr;


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

Procedure journalsort(var results:resulttype);

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


Procedure displayHeader;

begin
  write('Date');
  gotoxy(10,wherey);
  write('Title');

end;



Procedure displayline(var f:journalfiletype;var results:resulttype;
  i:integer;scrposit:integer);

var
  journalrec:journalentrytype;

begin
  gotoxy(1,scrposit+TOP_LINE);
  write('':79);

  if (i < results.size) then
    begin
      journentfileget(f,results.data[i].posit,journalrec);
      gotoxy(1,scrposit+TOP_LINE);
      write(datestr(journalrec.date));
      gotoxy(10,scrposit+TOP_LINE);
      write(journalrec.title)
    end
end;


Procedure displayresults(var f:journalfiletype;var results:resulttype;posit:integer;
    var scrposit:integer);

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
        displayline(f,results,i,i-posit+scrposit)
      else
        begin
          gotoxy(1,i-posit+scrposit+TOP_LINE);
          write('':79)
        end
    end;
   highlight(0,7,1,scrposit+TOP_LINE,79)
end;



Procedure uparrow(var f:journalfiletype;var results:resulttype;
 var posit:integer;var scrposit:integer);

begin
  if (posit > 0) then
    begin
      posit := posit-1;
      if (scrposit > 0) then
        begin
          displayline(f,results,posit+1,scrposit);
          scrposit := scrposit-1;
          highlight(0,7,1,scrposit+TOP_LINE,79)
        end
      else
        displayresults(f,results,posit,scrposit)
    end
end;


Procedure downarrow(var f:journalfiletype;var results:resulttype;
  var posit:integer;var scrposit:integer);

begin
  if (posit < results.size) then
    begin
      posit := posit+1;
      if (scrposit < LINES_PER_PAGE-1) then
        begin
          displayline(f,results,posit-1,scrposit);
          scrposit := scrposit+1;
          highlight(0,7,1,scrposit+TOP_LINE,79)
        end
      else
        displayresults(f,results,posit,scrposit)
    end
end;     
           

Procedure pgup(var f:journalfiletype;var results:resulttype;
  var posit:integer;var scrposit:integer);

begin
  if (posit > 0) then
    begin
      posit := posit - LINES_PER_PAGE;
      if (posit < 0) then
        posit := 0;
      displayresults(f,results,posit,scrposit)
    end
end;





Procedure pgdn(var f:journalfiletype;var results:resulttype;
  var posit:integer;var scrposit:integer);

begin
  if (posit < results.size) then
    begin
      posit := posit + LINES_PER_PAGE;
      if (posit > results.size) then
        posit := results.size;
      displayresults(f,results,posit,scrposit)
    end
end;


Function menu(mindate,maxdate:integer;name,desc:string):integer;

  var result,code:integer;
      choicestr:string;
      escpressed:boolean;

  begin
    gotoxy(1,1);
    writeln('M A I N   M E N U':48);
    gotoxy(1,3);
    if (mindate > 0) then
      writeln('1.  Set start date: ',datestr(mindate))
    else
      writeln('1.  Set start date: ');

    if (maxdate > 0) then
      writeln('2.  Set end date: ',datestr(maxdate))
    else
      writeln('2.  Set end date: ');

    writeln('4.  Set name: ',name);

    writeln('5.  Set description: ',desc);

    writeln('6.  Clear');

    writeln('7.  Do search');
    writeln('8.  Add new entry');
    writeln('9.  Change password');
    writeln('10.  Quit');
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


Procedure printentry(var je:journalentrytype;var content:longstr;var outfile:text);

  var lin,nlin,ncol:integer;
      sposit,eposit:word;
      done:boolean;
      s:string;

  begin
    done := false;
    write(outfile,'Date: '+datestr(je.date));
    write(outfile,' ');
    writeln(outfile,'Title: '+copy(je.title,1,55));
    writeln(outfile);
    lin := 0;
    lstrnavsetstr(geditparams.nav,content);
    repeat
      nlin := lin;
      ncol := 0;
      sposit := lstrnavfromlinecol(geditparams.nav,nlin,ncol);
      if (nlin = lin) then
        begin
          nlin := nlin+1;
          eposit := lstrnavfromlinecol(geditparams.nav,nlin,ncol);
          if (nlin = lin) then
            eposit := lstrlen(content);
          s := lstrsubstrs(content,sposit,eposit-sposit);
          if s[length(s)] = chr(13) then s[length(s)] := ' ';
          writeln(outfile,s);
          lin := lin+1
        end
      else done := true
    until done
  end;





Function editContent(var je:journalentrytype;var content:longstr):boolean;

var result:boolean;
    done:boolean;
    x:string;
    escpressed:boolean;
    choice,schoice:char;
    touched:boolean;
    outfile:text;

begin
  geditparams.toplineno := 0;
  geditparams.posit := 0;
  geditparams.cset := [27];
  geditparams.sset := [67,68];
  geditparams.topscrrow := 4;
  geditparams.displaylinecount := 18;
  done := false;
  result := false;
  touched := false;
  repeat
    clrscr;
    gotoxy(1,2);
    write('Date: '+datestr(je.date));
    write(' ');
    write('Title: '+copy(je.title,1,55));
    lstrededit(geditparams,content,choice,schoice);
    if (geditparams.touched) then
        touched := true;
    case choice of
      chr(27):begin
                if (touched) then
                  begin
                    gotoxy(1,1);
                    write('Abort without saving <y,n>? ');
                    getinput(x,escpressed);
                    if (not escpressed) and ((x = 'Y') or (x = 'y')) then
                      begin
                        done := true;
                        result := false
                      end
                  end
                else
                  begin
                    done := true;
                    result := false
                  end
             end;
      chr(0):begin
               case schoice of
                 chr(67):begin
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
                                   printentry(je,content,outfile);
                                   close(outfile)
                                 end
                             end
                         end;
                 chr(68):begin
                           done := true;
                           result := true
                         end
                end
      end
    end
  until done;
  editContent := result
end;



Procedure viewresults(var jf:journalfiletype;var results:resulttype);

var x:string;
    ctrlset:settype;
    scanset:settype;
    choice:char;
    schoice:char;
    posit:integer;
    scrposit:integer;
    escpressed:boolean;
    fileposit:longint;
    i:integer;
    je:journalentrytype;
    done:boolean;
    newdate:integer;


begin
  ctrlset := [1,4,13,20,25,27];
  scanset := [72,73,80,81];
  posit := 0;
  scrposit := 0;
  displayresults(jf,results,posit,scrposit);
  repeat
    gotoxy(1,1);
    write('':80);
    gotoxy(1,1);
    returninput(x,choice,schoice,ctrlset,scanset);
    case choice of
      chr(0):begin
               case schoice of
                 chr(72):begin
                           uparrow(jf,results,posit,scrposit)
                         end;
                 chr(73):begin
                           pgup(jf,results,posit,scrposit)
                         end;
                 chr(80):begin
                           downarrow(jf,results,posit,scrposit)
                         end;
                 chr(81):begin
                           pgdn(jf,results,posit,scrposit)
                         end
               end
             end;
     chr(1):begin
              if (results.size < MAX_RESULTS) then
                begin
                  journentinit(je);
                  lstrclear(gcontent);
                  if editcontent(je,gcontent) then
                    begin
                      fileposit := filesize(jf.f);
                      journentfilesaveall(jf,fileposit,je,gcontent);
                      posit := results.size;
                      results.data[posit].posit := fileposit;
                      results.data[posit].date := je.date;
                      results.size := results.size + 1
                    end;
                  displayresults(jf,results,posit,scrposit)
                end
            end;
     chr(4):begin
              if (posit < results.size) then
                begin
                  gotoxy(1,1);
                  write('Enter new date: ');
                  getinput(x,escpressed);
                  if (not escpressed) then
                     newdate := dateval(x)
                  else
                     newdate := -1;
                  if (newdate > 0) then
                    begin
                      journentfileget(jf,results.data[posit].posit,je);
                      je.date := newdate;
                      journentfilesave(jf,results.data[posit].posit,je)
                    end;
                  displayresults(jf,results,posit,scrposit)
                end
            end;                  
    chr(13):begin
              if (posit < results.size) then
                begin
                  journentfilegetall(jf,results.data[posit].posit,je,gcontent);
                  if editcontent(je,gcontent) then
                    begin
                      journentfilesaveall(jf,results.data[posit].posit,je,gcontent)
                    end;
                  displayresults(jf,results,posit,scrposit)
                end
             end;
     chr(20):begin
              if (posit < results.size) then
                begin
                  gotoxy(1,1);
                  write('Enter new title: ');
                  getinput(x,escpressed);
                  if (not escpressed) then
                    begin
                      journentfileget(jf,results.data[posit].posit,je);
                      je.title := x;
                      journentfilesave(jf,results.data[posit].posit,je)
                    end;
                  displayresults(jf,results,posit,scrposit)
                end
            end;
    chr(25):begin
              if (posit < results.size) then
                begin
                  gotoxy(1,1);
                  write('Delete this entry <y,n>? ');
                  getinput(x,escpressed);
                  if (not escpressed) and ((x = 'Y') or (x = 'y')) then
                    begin
                      journentfileget(jf,results.data[posit].posit,je);
                      journentmarkdeleted(je);
                      journentfilesave(jf,results.data[posit].posit,je);
                      for i := posit to results.size-2 do
                        results.data[i] := results.data[i+1];
                      results.size := results.size-1
                    end;
                  displayresults(jf,results,posit,scrposit)
                end
            end      
   end;
  until (choice = chr(27))
end;


Procedure dothesearch(var jf:journalfiletype;var results:resulttype;
mindate,maxdate:integer;namestr,descstr:string);

var
  journalrec:journalentrytype;
  posit:longint;
  isincluded:boolean;
  escpressed:boolean;
  temp:string;
  ch:char;
  maxposit:longint;
  tempword:word;


begin
  clrscr;
  gotoxy(1,12);
  write('Press ESC to cancel search');
  caps(namestr);
  caps(descstr);
  posit := JOURNENT_FIRST_REC;
  maxposit := filesize(jf.f);
  results.size := 0;
  escpressed := false;
  while (posit < maxposit) and (not escpressed) do
    begin
      if (descstr = '') then
        journentfileget(jf,posit,journalrec)
      else
        begin
          journentfilegetall(jf,posit,journalrec,gcontent);
          lstrcaps(gcontent)
        end;
      if not journentisdeleted(journalrec) then
        begin
          isincluded := true;
          if (mindate > 0) then
            begin
              if (journalrec.date < mindate) then
                isincluded := false
            end;

          if (maxdate > 0) and (isincluded) then
            begin
              if (journalrec.date > maxdate) then
                isincluded := false
            end;

         if (namestr <> '') and (isincluded) then
            begin
              temp := journalrec.title;
              caps(temp);
              if indexof(temp,namestr) = -1 then
                 isincluded := false
            end;
         if (descstr <> '') and (isincluded) then
            begin
              tempword := 0;
              isincluded := lstrboyermoore(gcontent,descstr,tempword)
            end;

          if (isincluded) then
            begin
              results.data[results.size].date := journalrec.date;
              results.data[results.size].posit := posit;
              results.size := results.size + 1
            end
        end;

      if (results.size = MAX_RESULTS) then
        escpressed := true;

      posit := posit + journalrec.blockextent;
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
          journalsort(results);
          viewresults(jf,results)
        end
    end
end;


Procedure doAddEntries(var jf:journalfiletype;var results:resulttype);

begin
  results.size := 0;
  viewresults(jf,results)
end;


Function getnewpassword(var x:string):boolean;

var temp:string;
    escpressed:boolean;
    result:boolean;

begin
  result := false;
  write('Enter new password: ');
  passinput(temp,20,false,escpressed);
  writeln;
  if (not escpressed) then
    begin
      write('Re-type password: ');
      passinput(x,20,false,escpressed);
      writeln;
      if (not escpressed) then
        begin
          if (x <> temp) then
            begin
              writeln('Password re-typed incorrectly.  Press any key');
              pause
            end
          else
            begin
              result := true
            end
        end
    end;
  getnewpassword := result
end;


begin
  g_logfile := paramstr(1);
  if g_logfile = '' then g_logfile := getenv(LOG_FILE_ENV);
  if g_logfile = '' then g_logfile := LOG_FILE_NAME;
  if (not fileexists(g_logfile)) then
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
              clrscr;
              gotoxy(1,12);
              if (getnewpassword(namestr)) then
                begin
                  journentfilecreate(g_logfile,namestr);
                  if (not journentfileopen(jf,g_logfile,namestr)) then
                    begin
                      writeln('Password error creating file');
                      halt(0)
                    end
                end  {get password}
              else
                begin
                  halt(0)
                end
            end { create file }
        end { yes }
      else
        begin
          halt(0)
        end { no }
    end {not file exist}
  else
    begin
      clrscr;
      gotoxy(1,12);
      write('Enter password: ');
      passinput(namestr,20,false,abortpressed);
      writeln;
      if (not abortpressed) then
        begin
          if (not journentfileopen(jf,g_logfile,namestr)) then
            begin
              writeln('Invalid password.');
              halt(0)
            end
        end
      else
        begin
          halt(0)
        end
    end;


  new(resultsptr);
  lstrinit(gcontent);
  lstredinit(geditparams);
  resultsptr^.size := 0;

  journentsetcachesize(jf,500);

  mindate := -1;
  maxdate := -1;
  namestr := '';
  descstr := '';

  repeat
    clrscr;
    choice := menu(mindate,maxdate,namestr,descstr);
    case choice of
      1:mindate := getDate('Enter start date [ENTER] clears: ');
      2:maxdate := getDate('Enter end date [ENTER] clears: ');
      4:namestr := getName('Enter name [ENTER] clears: ');
      5:descstr := getName('Enter description [ENTER] clears: ');
      6:begin
          mindate := -1;
          maxdate := -1;
          namestr := '';
          descstr := ''
        end;
      7:begin
          doTheSearch(jf,resultsptr^,mindate,maxdate,namestr,descstr)
        end;
      8:begin
          doAddEntries(jf,resultsptr^)
        end;
      9:begin
          clrscr;
          write('Enter old password: ');
          passinput(temp,20,false,abortpressed);
          writeln;
          if (not abortpressed) then
            begin
              if (temp = jf.key) then
                begin
                  if (getnewpassword(temp)) then
                    begin
                      writeln('Please wait...');
                      journentfilechangekey(jf,temp,gcontent);
                      writeln('Password successfully changed.  Press any key');
                      pause
                    end
                end
              else
                begin
                  writeln('Invalid password.  Press any key');
                  pause
                end
            end
        end
    end
  until (choice = 10);
  lstreddestroy(geditparams);
  lstrdestroy(gcontent);
  dispose(resultsptr);
  journentfileclose(jf)
end.








