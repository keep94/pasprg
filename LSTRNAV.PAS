unit lstrnav;

interface

uses lstr;

type
  lstrnavcacheatype=array[0..32759] of word;
  lstrnavcacheptype=^lstrnavcacheatype;

  lstrnavtype=record
    firstlineincache:integer;
    lastlineincache:integer;
    cachesize:integer;
    maxcharsperline:word;
    cache:lstrnavcacheptype;
    sptr:^longstr;
  end;

Procedure lstrnavinit(var nav:lstrnavtype);

Procedure lstrnavdestroy(var nav:lstrnavtype);

Procedure lstrnavsetcharsperline(var nav:lstrnavtype;numchars:word);

Procedure lstrnavsetcachesize(var nav:lstrnavtype;newsize:integer);

Procedure lstrnavsetstr(var nav:lstrnavtype;var ls:longstr);

Procedure lstrnavinvalidate(var nav:lstrnavtype;lin:integer);

Function lstrnavfromlinecol(var nav:lstrnavtype;var lin:integer;var col:integer):word;

Procedure lstrnavtolinecol(var nav:lstrnavtype;posit:word;var lin:integer;var col:integer);


implementation


Procedure lstrnavcacheinit(var nav:lstrnavtype);

begin
  nav.firstlineincache := 0;
  nav.lastlineincache := 0;
  nav.cache^[0] := 0
end;


Procedure lstrnavinit(var nav:lstrnavtype);

begin
  nav.cachesize := 100;
  nav.maxcharsperline := 80;
  getmem(nav.cache,nav.cachesize*sizeof(word));
  lstrnavcacheinit(nav)
end;

Procedure lstrnavdestroy(var nav:lstrnavtype);

begin
  freemem(nav.cache,nav.cachesize*sizeof(word))
end;



Procedure lstrnavsetcharsperline(var nav:lstrnavtype;numchars:word);

begin
  nav.maxcharsperline := numchars;
  lstrnavcacheinit(nav)
end;

Procedure lstrnavsetcachesize(var nav:lstrnavtype;newsize:integer);

begin
  freemem(nav.cache,nav.cachesize*sizeof(word));
  nav.cachesize := newsize;
  getmem(nav.cache,nav.cachesize*sizeof(word));
  lstrnavcacheinit(nav)
end;

Procedure lstrnavsetstr(var nav:lstrnavtype;var ls:longstr);

begin
  nav.sptr := addr(ls);
  lstrnavcacheinit(nav)
end;



Procedure lstrnavinvalidate(var nav:lstrnavtype;lin:integer);

begin
  if (lin <= nav.firstlineincache) then
    lstrnavcacheinit(nav)
  else if (lin <= nav.lastlineincache) then
      nav.lastlineincache := lin-1
end;


Procedure lstrnavcacheput(var nav:lstrnavtype;newposit:word);

begin
  nav.lastlineincache := nav.lastlineincache + 1;
  if (nav.lastlineincache - nav.firstlineincache >= nav.cachesize) then
    nav.firstlineincache := nav.lastlineincache - nav.cachesize + 1;
  nav.cache^[nav.lastlineincache mod nav.cachesize] := newposit
end;


{
  Returns the position in the string for the beginning of a given
  line number
  nav - the navigation object
  lin - the line number starting at 0.
  s - the long string
  returns the position in the string starting at 0 that the first character
  of the given line is.
  If lin exceeds the last line of the string, it is set to be the last line
  of the string.
}

Function lstrnavcacheget(var nav:lstrnavtype;var lin:integer):word;

var result:word;
    posit:word;

begin
  if (lin >= nav.firstlineincache) and (lin <= nav.lastlineincache) then
    result := nav.cache^[lin mod nav.cachesize]
  else
    begin
      if (lin < nav.firstlineincache) then
         lstrnavinvalidate(nav,0);
      posit := lstrnavcacheget(nav,nav.lastlineincache);
      result := posit;
      while (lin > nav.lastlineincache) and (posit < lstrlen(nav.sptr^)) do
        begin
          posit := lstrnextwordwrap(nav.sptr^,posit,nav.maxcharsperline);
          if (posit < lstrlen(nav.sptr^)) then
            begin
              lstrnavcacheput(nav,posit);
              result := posit
            end
          else if (posit = lstrlen(nav.sptr^)) and (posit > 0) and (lstrcharat(nav.sptr^,posit-1) = chr(13)) then
            begin
              lstrnavcacheput(nav,posit);
              result := posit
            end
        end;
      lin := nav.lastlineincache
    end;
  lstrnavcacheget := result
end;



{
  Converts a line and column to a offset in the string.
  nav - the navigation object
  lin - the current line.  Starts at 0.
  col - the current column.  Starts at 0.
  If col goes past end of line, it is adjusted
  If lin and col go past end of string, they are both adjusted.
}

Function lstrnavfromlinecol(var nav:lstrnavtype;var lin:integer;var col:integer):word;

var sposit:word;
    eposit:word;
    nlin:integer;
    result:word;

begin
  sposit := lstrnavcacheget(nav,lin);
  nlin := lin+1;
  eposit := lstrnavcacheget(nav,nlin);

  { if we are at last line, assume position of next line is end of string }
  if (nlin = lin) then
    begin
      eposit := lstrlen(nav.sptr^);
      if (col > eposit - sposit) then col := eposit - sposit;
      result := sposit + col
    end
  else
    begin
      if (col >= eposit - sposit) then col := eposit - sposit - 1;
      result := sposit + col
    end;
  lstrnavfromlinecol := result
end;



{
  Converts a position in a string to a line and column
  nav - navigation object
  posit - the position in the string starting at 0
  lin - line starting at 0 stored here
  col - col starting at 0 stored here
}

Procedure lstrnavtolinecol(var nav:lstrnavtype;posit:word;var lin:integer;var col:integer);

var plower,pupper,pmiddle,cposit:word;
    lower,upper,middle:integer;
    nlin:integer;

begin
  plower := lstrnavcacheget(nav,nav.firstlineincache);
  pupper := lstrnavcacheget(nav,nav.lastlineincache);

  if (posit >= plower) and (posit < pupper) then
    begin
      lower := nav.firstlineincache;
      upper := nav.lastlineincache;
      while (upper-lower>1) do
        begin
          middle := (lower + upper) div 2;
          pmiddle := lstrnavcacheget(nav,middle);
          if (pmiddle <= posit) then lower := middle
          else upper := middle
        end;
      col := posit - lstrnavcacheget(nav,lower);
      lin := lower
    end
  else
    begin
      if (posit < plower) then
        lin := 0
      else
        lin := nav.lastlineincache;

      repeat
        lin := lin+1;
        nlin := lin;
        pupper := lstrnavcacheget(nav,nlin)
      until (posit < pupper) or (nlin < lin);
      lin := lin-1;
      col := posit - lstrnavcacheget(nav,lin)
    end
end;


begin
end.





  
