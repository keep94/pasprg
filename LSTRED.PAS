unit lstred;

interface

uses lstr,lstrnav;

type
  lstredittype=record
    cset:set of byte;
    sset:set of byte;
    toplineno:integer;
    posit:word;
    startBlock:longint;
    clipboard:longstr;
    topscrrow:integer;
    displayLineCount:integer;
    touched:boolean;
    displayposits:array[0..50] of word;
    lastaction:integer;
    laposit:word;
    lanumber:word;
    nav:lstrnavtype
  end;

Procedure lstredinit(var editparams:lstredittype);

Procedure lstreddestroy(var editparams:lstredittype);

Procedure lstrededit(var editparams:lstredittype;var editstr:longstr;var choice:char;var schoice:char);


implementation

uses crt;

const
  LSTRED_NO_ACTION = 0;
  LSTRED_INSERT = 1;
  LSTRED_DELETE = 2;


type
    arraytype = array[0..3999] of byte;
    scrptrtype = ^arraytype;


Procedure lstredinit(var editparams:lstredittype);

begin
  lstrinit(editparams.clipboard);
  editparams.posit := 0;
  editparams.startBlock := -1;
  editparams.touched := false;
  editparams.lastaction := LSTRED_NO_ACTION;
  lstrnavinit(editparams.nav)
end;


Procedure lstreddestroy(var editparams:lstredittype);

begin
  lstrdestroy(editparams.clipboard);
  lstrnavdestroy(editparams.nav)
end;




{
  Highlights text on screen
  f - foreground color
  b - backgroundcolor
  x1 - start column starts at 1
  y1 - start line starts at 1
  x2 - end column starts at 1
  y2 - end line starts at 1
}

  Procedure lstredhl(f,b,x1,y1,x2,y2:integer);

   var p:scrptrtype;
       attr,sposit,eposit,cnt:integer;

   begin
     p := ptr($B800,$0);
     attr := 16*b + f;
     sposit := (y1 - 1)*160 + (x1 - 1)*2 + 1;
     eposit := (y2 - 1)*160 + (x2 - 1)*2 + 1;
     cnt := sposit;
     while cnt <= eposit do
       begin
         p^[cnt] := attr;
         cnt := cnt + 2
       end
   end;

{
  Highlights part of text being edited
  editparams -
  editstr - the string being edited
  sb,eb - beginning and ending position in string to be highlighted starts at 0
  f,b - foreground and background respectively
}


Procedure lstredhighl(var editparams:lstredittype;var editstr:longstr;sb,eb:word;f,b:integer);

var lin1,col1,lin2,col2:integer;
    x1,y1,x2,y2:integer;

begin
  lstrnavtolinecol(editparams.nav,sb,lin1,col1);
  lstrnavtolinecol(editparams.nav,eb,lin2,col2);

  { region to be highlighted starts before but ends in what is viewed }
  if (lin1 < editparams.toplineno) and
     (lin2 >= editparams.toplineno) and
     (lin2 < editparams.toplineno + editparams.displayLineCount) then
        begin
          lstredhl(f,b,1,editparams.topscrrow,col2+1,
              lin2-editparams.toplineno+editparams.topscrrow)
        end
  { region to be highlighted starts in what is viewed but ends after it }
  else if (lin1 >= editparams.toplineno) and
     (lin1 < editparams.toplineno + editparams.displayLineCount) and
     (lin2 >= editparams.toplineno + editparams.displayLineCount) then
     begin
       lstredhl(f,b,col1+1,lin1-editparams.toplineno+editparams.topscrrow,
          80,editparams.displayLineCount+editparams.topscrrow-1)
     end
  { region to be highlighted is completely enclosed in what is being viewed }
  else if (lin1 >= editparams.toplineno) and
     (lin1 < editparams.toplineno + editparams.displayLineCount) and
     (lin2 >= editparams.toplineno) and
     (lin2 < editparams.toplineno + editparams.displayLineCount) then
    begin
      lstredhl(f,b,col1+1,lin1-editparams.toplineno+editparams.topscrrow,
           col2+1,lin2-editparams.toplineno+editparams.topscrrow)
    end
  { region starts before but ends after what is being viewed }
  else if (lin1 < editparams.toplineno) and 
       (lin2 >= editparams.toplineno + editparams.displayLineCount) then
    begin
      lstredhl(f,b,1,editparams.topscrrow,
        80,editparams.displayLIneCount+editparams.topscrrow-1)
    end
end;

{
  Based on the start point of the block in editparams and a cursor position,
  gets the start and end position of the block.  Can only be called when
  the star point in block of edit params actually exists.

  editparams -
  cursorposit - the cursor position relative to the start of the string
                starting at 0.
  sb,eb - start and end of block relative to beginning of string starting at 0
          returned here
}

Procedure lstredgetblock(var editparams:lstredittype;cursorposit:word;
   var sb:word;var eb:word);

  var realsb:word;

  begin
    realsb := editparams.startblock;
    if (cursorposit < realsb) then
      begin
        sb := cursorposit;
        eb := realsb
      end
    else
      begin
        sb := realsb;
        eb := cursorposit
      end
  end;    

{
  Only if there is a starting point in edit params, highlights selected block
  of text with white bg and black foreground.  To be called after screen is
  refreshed.
  editparams -
  editstr - string being edited
}

Procedure lstredhighlight(var editparams:lstredittype;var editstr:longstr);

var sb,eb:word;

begin
  if (editparams.startBlock <> -1) then
    begin
      lstredgetblock(editparams,editparams.posit,sb,eb);
      lstredhighl(editparams,editstr,sb,
       eb,0,7)
    end
end;


{
  Only if there is a starting point in edit params, unhighlights selected block
  of text by giving it white foreground and black background
  editparams -
  editstr - string being edited
}

Procedure lstredunhighlight(var editparams:lstredittype;var editstr:longstr);

var sb,eb:word;

begin
  if (editparams.startBlock <> -1) then
    begin
      lstredgetblock(editparams,editparams.posit,sb,eb);
      lstredhighl(editparams,editstr,sb,
       eb,7,0)
    end
end;


{
  Updates the highlighted area on the screen.  Only works when the screen is
  not refreshed but the cursor has moved.  Only does its work if there is
  a starting point of block stored in editparams.
  editparams -
  editstr - string being edited
  lastposit - Place where cursor was before relative to start of string
              being edited starting at 0
}


Procedure lstredupdatehl(var editparams:lstredittype;var editstr:longstr;
      lastPosit:word);

var lastsb,lasteb:word;
    sb,eb:word;

begin
  if (editparams.startblock <> -1) then
    begin
      lstredgetblock(editparams,lastposit,lastsb,lasteb);
      lstredgetblock(editparams,editparams.posit,sb,eb);

      { highlighted area has not changed do nothing }
      if (lastsb = sb) and (lasteb = eb) then
        begin
        end
      {
         highlighted area begins at the same place, but the end has moved
         to make block bigger
      }
      else if (lastsb = sb) and (lasteb < eb) then
        lstredhighl(editparams,editstr,lasteb,eb,0,7)

      {
        highlighted area begins at same place, but end has moved to make
        block smaller
      }
      else if (lastsb = sb) and (lasteb > eb) then
        begin
          lstredhighl(editparams,editstr,eb,lasteb,7,0);
          lstredhighl(editparams,editstr,eb,eb,0,7)
        end

      {
         highlighted are ends at same place, but beginning has moved forward
         to make block smaller
      }
      else if (lasteb = eb) and (lastsb < sb) then
        begin
          lstredhighl(editparams,editstr,lastsb,sb,7,0);
          lstredhighl(editparams,editstr,sb,sb,0,7)
        end

      {
         ends at same place but beginning moved to make block bigger
      }
      else if (lasteb = eb) and (lastsb > sb) then
        lstredhighl(editparams,editstr,sb,lastsb,0,7)

      {
         beginnings and ends of blocks don't match at all
      }
      else
        begin
          lstredhighl(editparams,editstr,lastsb,lasteb,7,0);
          lstredhighl(editparams,editstr,sb,eb,0,7)
        end
    end
end;


Function lstredshoulddisp(var editparams:lstredittype;currentrow:integer;posit:integer):boolean;

var result:boolean;

begin
  result := true;
  if (editparams.lastaction = LSTRED_INSERT) then
    begin
      if (posit >= editparams.laposit + editparams.lanumber)
      and (posit = editparams.displayposits[currentrow] + editparams.lanumber) then
         result := false
    end
  else if (editparams.lastaction = LSTRED_DELETE) then
    begin
      if (posit >= editparams.laposit)
      and (posit = editparams.displayposits[currentrow] - editparams.lanumber) then
         result := false
    end;
  lstredshoulddisp := result
end; 


Procedure lstreddisplay(var editparams:lstredittype;var editstr:longstr;startlin:integer);

var i:integer;
    s:string;
    nlin,ncol:integer;
    sposit,eposit:word;
    currentrow:integer;

begin
  if (startlin < editparams.toplineno) then startlin := editparams.toplineno;
  for i := startlin to editparams.toplineno+editparams.displayLineCount-1 do
    begin
      currentrow := i-editparams.toplineno;
      nlin := i;
      ncol := 0;
      sposit := lstrnavfromlinecol(editparams.nav,nlin,ncol);
      if (nlin = i) then
        begin
          if (lstredshoulddisp(editparams,currentrow,sposit)) then
            begin
              nlin := nlin+1;
              eposit := lstrnavfromlinecol(editparams.nav,nlin,ncol);
              if (nlin = i) then
                eposit := lstrlen(editstr);

              s := lstrsubstrs(editstr,sposit,eposit-sposit);
              if s[length(s)] = chr(13) then s[length(s)] := ' ';
              gotoxy(1,currentrow+editparams.topscrrow);
              write('':80);
              gotoxy(1,currentrow+editparams.topscrrow);
              write(s)
            end;
          editparams.displayposits[currentrow] := sposit
        end
      else
        begin
          sposit := lstrlen(editstr);
          if (lstredshoulddisp(editparams,currentrow,sposit)) then
            begin
              gotoxy(1,currentrow+editparams.topscrrow);
              write('':80)
            end;
          editparams.displayposits[currentrow] := sposit
        end
    end;
  editparams.lastaction := LSTRED_NO_ACTION
end;


Procedure lstredshowcursor(var editparams:lstredittype;var editstr:longstr;lastposit:longint);

var lin,col:integer;

begin
  lstrnavtolinecol(editparams.nav,editparams.posit,lin,col);
  if (lin < editparams.toplineno) then
    begin
      editparams.toplineno := lin;
      lstreddisplay(editparams,editstr,editparams.toplineno);
      lstredhighlight(editparams,editstr)
    end
  else if (lin >= editparams.toplineno+editparams.displayLineCount) then
    begin
      editparams.toplineno := lin - editparams.displayLineCount+1;
      lstreddisplay(editparams,editstr,editparams.toplineno);
      lstredhighlight(editparams,editstr)
    end
  else
    begin
      if (lastposit < 0) then
        lstredhighlight(editparams,editstr)
      else
        lstredupdatehl(editparams,editstr,lastposit)
    end;
  gotoxy(col+1,lin-editparams.toplineno+editparams.topscrrow)
end;


Procedure lstredupdatedisplay(var editparams:lstredittype;var editstr:longstr;lin:integer);


begin
  lstrnavinvalidate(editparams.nav,lin);
  if (lin > 0) then
    lstreddisplay(editparams,editstr,lin-1)
  else
    lstreddisplay(editparams,editstr,0);
  lstredshowcursor(editparams,editstr,-1)
end;


Procedure lstrededit(var editparams:lstredittype;var editstr:longstr;var choice:char;var schoice:char);

var done:boolean;
    lin,col,nlin:integer;
    sb,eb:word;
    oldposit:word;



begin
  editparams.startBlock := -1;
  editparams.touched := false;
  lstrnavsetstr(editparams.nav,editstr);
  {display it}
  lstreddisplay(editparams,editstr,0);
  lstredshowcursor(editparams,editstr,-1);

  done := false;
  repeat
    choice := readkey;
    if (choice = chr(0)) then
      begin
        schoice := readkey;
        if (schoice = chr(72)) then
          begin
            oldposit := editparams.posit;
            lstrnavtolinecol(editparams.nav,editparams.posit,lin,col);
            if (lin > 0) then lin := lin - 1;
            editparams.posit := lstrnavfromlinecol(editparams.nav,lin,col);
            lstredshowcursor(editparams,editstr,oldposit)
          end
        else if (schoice = chr(75)) then
          begin
            oldposit := editparams.posit;
            if (editparams.posit > 0) then
              editparams.posit := editparams.posit - 1;
            lstredshowcursor(editparams,editstr,oldposit)
          end
        else if (schoice = chr(77)) then
          begin
            oldposit := editparams.posit;
            if (editparams.posit < lstrlen(editstr)) then
              editparams.posit := editparams.posit + 1;
            lstredshowcursor(editparams,editstr,oldposit)
          end
        else if (schoice = chr(80)) then
          begin
            oldposit := editparams.posit;
            lstrnavtolinecol(editparams.nav,editparams.posit,lin,col);
            lin := lin + 1;
            editparams.posit := lstrnavfromlinecol(editparams.nav,lin,col);
            lstredshowcursor(editparams,editstr,oldposit)
          end
        else if (schoice = chr(73)) then
          begin
            oldposit := editparams.posit;
            lstrnavtolinecol(editparams.nav,editparams.posit,lin,col);
            lin := lin - editparams.displaylinecount+1;
            if (lin < 0) then lin := 0;
            editparams.posit := lstrnavfromlinecol(editparams.nav,lin,col);
            lstredshowcursor(editparams,editstr,oldposit)
          end
        else if (schoice = chr(81)) then
          begin
            oldposit := editparams.posit;
            lstrnavtolinecol(editparams.nav,editparams.posit,lin,col);
            lin := lin + editparams.displaylinecount-1;
            editparams.posit := lstrnavfromlinecol(editparams.nav,lin,col);
            lstredshowcursor(editparams,editstr,oldposit)
          end
        else if (schoice = chr(83)) then
          begin
            editparams.touched := true;
            lstredunhighlight(editparams,editstr);
            editparams.startBlock := -1;
            lstrnavtolinecol(editparams.nav,editparams.posit,lin,col);
            lstrremove(editstr,editparams.posit,1);
            editparams.lastaction := LSTRED_DELETE;
            editparams.lanumber := 1;
            editparams.laposit := editparams.posit;
            lstredupdatedisplay(editparams,editstr,lin)
          end
        else if (ord(schoice) in editparams.sset) then done := true
      end
    else
      begin
        if (choice = chr(8)) then
          begin
            if (editparams.posit > 0) then
              begin
                editparams.touched := true;
                lstredunhighlight(editparams,editstr);
                editparams.startBlock := -1;
                editparams.posit := editparams.posit-1;
                lstrnavtolinecol(editparams.nav,editparams.posit,lin,col);
                lstrremove(editstr,editparams.posit,1);
                editparams.lastaction := LSTRED_DELETE;
                editparams.lanumber := 1;
                editparams.laposit := editparams.posit;
                lstredupdatedisplay(editparams,editstr,lin)
              end
          end
        else if (choice = chr(9)) then
          begin
            editparams.touched := true;
            lstredunhighlight(editparams,editstr);
            editparams.startBlock := -1;
            lstrnavtolinecol(editparams.nav,editparams.posit,lin,col);
            lstrinserts(editstr,editparams.posit,'     ');
            editparams.laposit := editparams.posit;
            editparams.posit := editparams.posit+5;
            editparams.lastaction := LSTRED_INSERT;
            editparams.lanumber := 5;
            lstredupdatedisplay(editparams,editstr,lin)
          end
        else if (choice = chr(11)) then
          begin
            choice := readkey;
            if (choice = 'b') then
              begin
                lstredunhighlight(editparams,editstr);
                editparams.startBlock := editparams.posit;
                lstredhighlight(editparams,editstr)
              end
            else if (choice = 'h') then
              begin
                lstredunhighlight(editparams,editstr);
                editparams.startBlock := -1
              end
            else if (choice = 'x') then
              begin
                if (editparams.startBlock <> -1) then
                  begin
                    editparams.touched := true;
                    lstredgetblock(editparams,editparams.posit,sb,eb);
                    lstrsubstrls(editstr,sb,
                         eb-sb+1,
                          editparams.clipboard);
                    lstrremove(editstr,sb,
                         eb-sb+1);
                    editparams.posit := sb;
                    editparams.startBlock := -1;
                    { no unhighlight needed here since we are updating
                      entire display }
                    lstredupdatedisplay(editparams,editstr,0)
                  end
              end
            else if (choice = 'c') then
              begin
                if (editparams.startBlock <> -1) then
                  begin
                    lstredgetblock(editparams,editparams.posit,sb,eb);
                    lstrsubstrls(editstr,sb,eb-sb+1,editparams.clipboard);
                    lstredunhighlight(editparams,editstr);
                    editparams.startBlock := -1
                  end
              end
            else if (choice = 'v') then
              begin
                editparams.touched := true;
                editparams.startBlock := -1;
                lstrinsertls(editstr,editparams.posit,editparams.clipboard);
                editparams.posit := editparams.posit + lstrlen(editparams.clipboard);
                lstredupdatedisplay(editparams,editstr,0)
              end
          end
        else if (choice = chr(17)) then
          begin
            oldposit := editparams.posit;
            lstrnavtolinecol(editparams.nav,editparams.posit,lin,col);
            choice := readkey;
            if (choice = 'r') then
              begin
                editparams.posit := 0;
                lstredshowcursor(editparams,editstr,oldposit)
              end
            else if (choice = 'c') then
              begin
                editparams.posit := lstrlen(editstr);
                lstredshowcursor(editparams,editstr,oldposit)
              end
            else if (choice = 's') then
              begin
                col := 0;
                editparams.posit := lstrnavfromlinecol(editparams.nav,lin,col);
                lstredshowcursor(editparams,editstr,oldposit)
              end
            else if (choice = 'd') then
              begin
                nlin := lin+1;
                col := 0;
                editparams.posit := lstrnavfromlinecol(editparams.nav,nlin,col);
                if (nlin = lin) then
                    editparams.posit := lstrlen(editstr);
                if (editparams.posit > 0) then
                    editparams.posit := editparams.posit-1;
                lstredshowcursor(editparams,editstr,oldposit)
              end
          end
        else if (ord(choice) in editparams.cset) then done := true
        else if (ord(choice) > 31) or (ord(choice) = 13) then
          begin
            editparams.touched := true;
            lstredunhighlight(editparams,editstr);
            editparams.startBlock := -1;
            lstrnavtolinecol(editparams.nav,editparams.posit,lin,col);
            lstrinsertc(editstr,editparams.posit,choice);
            editparams.laposit := editparams.posit;
            editparams.posit := editparams.posit+1;
            editparams.lastaction := LSTRED_INSERT;
            editparams.lanumber := 1;
            lstredupdatedisplay(editparams,editstr,lin)
          end
      end
  until done
end;

begin

end.



