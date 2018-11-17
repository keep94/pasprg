unit lstr;

{ This is the unit for the longstr datatype.  All procedures and functions
are of the form lstrXXX.  The longstr datatype is a string that can be between
0 and 65520 characters.  Memory is allocated as needed as string grows
}

interface

type
  lstrarraytype = array[0..65519] of char;
  lstrptrtype = ^lstrarraytype;
  longstr = record
    size:word;
    extent:word;
    ptr:lstrptrtype
  end;

Procedure lstradjustforsize(var s:longstr;newsize:longint);

Function lstrlen(var s:longstr):word;

Procedure lstrinit(var s:longstr);

Procedure lstrdestroy(var s:longstr);

Function lstrcharat(var s:longstr;index:word):char;

Procedure lstrsetchar(var s:longstr;index:word;c:char);

Procedure lstrremove(var s:longstr;start:word;numBytes:word);

Procedure lstrinsertc(var s:longstr;start:word;c:char);

Procedure lstrinserts(var s:longstr;start:word;ss:string);

Procedure lstrinsertls(var s:longstr;start:word;var ls:longstr);

Procedure lstrappendc(var s:longstr;c:char);

Procedure lstrappends(var s:longstr;ss:string);

Procedure lstrappendls(var s:longstr;var ls:longstr);

Procedure lstrclear(var s:longstr);

Function lstrtostring(var s:longstr):string;

Function lstrsubstrs(var s:longstr;start:word;len:byte):string;

Procedure lstrsubstrls(var s:longstr;start:word;len:word;var substr:longstr);

Function lstrnextwordwrap(var s:longstr;start:word;charsperline:word):word;

Function lstrboyermoore(var ls:longstr;s:string;var posit:word):boolean;

Procedure lstrcaps(var ls:longstr);

implementation


{
  Returns the length of the string
}

Function lstrlen(var s:longstr):word;

begin
  lstrlen := s.size
end;


{
  Initializes a longstr.
}

Procedure lstrinit(var s:longstr);

begin
  s.size := 0;
  s.extent := 16;
  getmem(s.ptr,16)
end;


{
  Frees resources used by a longstr.
}

Procedure lstrdestroy(var s:longstr);

begin
  freemem(s.ptr,s.extent)
end;

{
  Returns 2^x.
  x - exponent.
}

Function lstrexp(x:integer):longint;

var result:longint;
    i:integer;
begin
  result := 1;
  for i := 1 to x do  result := result * 2;
  lstrexp := result
end;


{
  Returns the largest integer of log base 2 x.
  For 0, return 0.  For 1, return 0. for 2-3 returns 1.  For 4-7 returns 2
  etc.
}

Function lstrlog(x:longint):integer;

var result:integer;

begin
  result := 0;
  while (x > 1) do
    begin
      result := result + 1;
      x := x div 2
    end;
  lstrlog := result
end; 


{
  Copies characters from one memory location to another.
  src - characters copied from here
  dest - characters copied to here
  numBytes - number of bytes to copy.
}

Procedure lstrcopycontent(src:lstrptrtype;dest:lstrptrtype;numBytes:word);

var i:word;

begin
  for i := 1 to numBytes do dest^[i-1] := src^[i-1]
end;  

{
  Makes the longstr have a given capacity.
  s - the longstr
  newextent - the new capacity.
}

Procedure lstrchangeextent(var s:longstr;newextent:word);

var
  nptr:lstrptrtype;

begin
  getmem(nptr,newextent);
  if (newextent >= s.size) then
    lstrcopycontent(s.ptr,nptr,s.size)
  else
    begin
      lstrcopycontent(s.ptr,nptr,newextent);
      s.size := newextent
    end;
  freemem(s.ptr,s.extent);
  s.extent := newextent;
  s.ptr := nptr
end;


    

{
  Adjusts the amount of memory allocated for the longstr.
  16 smalles block.  Then 32, 64, 128, ..., 32768, 65520.
  s - the long str
  newsize - the number of chars the longstr will have.
}

Procedure lstradjustforsize(var s:longstr;newsize:longint);

begin
  { minimum capacity is 16 }
  if (newsize < 16) then newsize := 16;

  { Choose next power of 2 that is equal to or greater than needed capacity }
  newsize := lstrexp(lstrlog(2*newsize-1));

  { Can't have capacity bigger than 65520 }
  if (newsize > 65520) then newsize := 65520;

  { only adjust capacity if it differs from original }
  if (newsize <> s.extent) then
      lstrchangeextent(s,newsize);
end;

{
Returns the character at the index th position of a long str.
s - the long string
index - the position.  Starts at 0.
}

Function lstrcharat(var s:longstr;index:word):char;

begin
  lstrcharat := s.ptr^[index]
end;

{
  Sets the character at a given position in a long string
  s - the long string.
  index - the position to set the character.  Starts at 0.
  c - new value of the character.
}

Procedure lstrsetchar(var s:longstr;index:word;c:char);

begin
  s.ptr^[index] := c
end;


{
  Removes characters from a longstr
  s - longstr.
  start - starting place where characters are to be deleted.  These start at 0.
  numBytes - the number of characters to delete.
}


Procedure lstrremove(var s:longstr;start:word;numBytes:word);

var i:word;

begin
  if (start > s.size) then start := s.size;
  if (numBytes > s.size - start) then numBytes := s.size - start;

  for i := start+1 to s.size - numBytes do
    s.ptr^[i-1] := s.ptr^[i+numBytes-1];

  s.size := s.size - numBytes;
  lstradjustforsize(s,s.size)
end;

{
  Makes room for numBytes characters at start by moving everything down
  numBytes.
  s - the longstr.
  start - the place to make room.  Starts at 0.
  numBytes - the number of characters for which to make room
}

Procedure lstrmakeroom(var s:longstr;start:word;numBytes:word);

var i:word;

begin
  lstradjustforsize(s,s.size+numBytes);
  for i := s.size downto start+1 do
      s.ptr^[i+numBytes-1] := s.ptr^[i-1];
  s.size := s.size + numBytes
end;

{
  Inserts a single character into a string
  s- the long string.
  start-Place to insert the character. starts at 0.
  c - the char to insert
}

Procedure lstrinsertc(var s:longstr;start:word;c:char);

begin
  lstrmakeroom(s,start,1);
  s.ptr^[start] := c
end;

{
  Inserts a string of characters into a longstr.
  s - the long string
  start - place to insert string.  starts at 0.
  ss - the string.
}

Procedure lstrinserts(var s:longstr;start:word;ss:string);

var i:word;

begin
  lstrmakeroom(s,start,length(ss));
  for i := 1 to length(ss) do
    s.ptr^[start+i-1] := ss[i]
end;

{
  Inserts a longstr of characters into a longstr
  s - the long string
  start - place to insert string.  starts at 0.
  ls - the longstr to insert.
}

Procedure lstrinsertls(var s:longstr;start:word;var ls:longstr);

var i:word;

begin
  lstrmakeroom(s,start,lstrlen(ls));
  for i := 1 to lstrlen(ls) do
    s.ptr^[start+i-1] := lstrcharat(ls,i-1)
end;

{
  Appends a character to the end of a long string
}


Procedure lstrappendc(var s:longstr;c:char);

begin
  lstrinsertc(s,s.size,c)
end;

{
  Appends a string to the end of a long string
}

Procedure lstrappends(var s:longstr;ss:string);

begin
  lstrinserts(s,s.size,ss)
end;

{
  Appends a long string to the end of another longstr.
  s - the long string to which characters are being appended.
  ls - the long string that contains the characters that are being appended.
}

Procedure lstrappendls(var s:longstr;var ls:longstr);

begin
  lstrinsertls(s,s.size,ls)
end;

{
  Makes the length of the long string be 0
}

Procedure lstrclear(var s:longstr);

begin
  s.size := 0;
  lstradjustforsize(s,0)
end;



{
  Converts a long string to a regular string
}

Function lstrtostring(var s:longstr):string;

var result:string;
    i:word;

begin
  if (s.size > 255) then
    result[0] := chr(255)
  else
    result[0] := chr(s.size);

  for i := 1 to ord(result[0]) do
    result[i] := s.ptr^[i-1];
  lstrtostring := result
end;

{
  Finds a substring of a long string.  Returns as a reglar string.
  s - the long string.
  start - the starting position of the substring.  starts at 0.
  len - the length of the substring.
}

Function lstrsubstrs(var s:longstr;start:word;len:byte):string;

var result:string;
    i:word;

begin
  if (start > s.size) then start := s.size;
  if (len > s.size-start) then len := s.size-start;

  result[0] := chr(len);
  for i := 1 to len do
    result[i] := s.ptr^[start+i-1];
  lstrsubstrs := result
end;

{
  Finds a substring of a long string.  Result returned in a long string.
  s - the long string
  start - Place where substring is to start
  len - number of characters in substring
  substr - substring returned here
}

Procedure lstrsubstrls(var s:longstr;start:word;len:word;var substr:longstr);

var i:word;


begin
  if (start > s.size) then start := s.size;
  if (len > s.size-start) then len := s.size-start;

  lstradjustforsize(substr,len);
  for i := 1 to len do
    substr.ptr^[i-1] := lstrcharat(s,start+i-1);
  substr.size := len
end;


{
  Finds the next place to word wrap.
  s - the long string
  start - the starting place of current line.  Starts at 0
  returns the position of the beginning of the next line or the size
  of s if end of string is reached.
}


Function lstrnextwordwrap(var s:longstr;start:word;charsperline:word):word;

var lastwordbegin:word;
    index:word;
    done:boolean;
    ch:char;
    result:word;
    state:integer;

begin

{ only look if we aren't at end of string already otherwise we are done }

if (start >= lstrlen(s)) then
  lstrnextwordwrap := start
else
begin
  { state=0 means not in spaces.  state=1 means in spaces. }
  state := 0;

  { start looking for wordwrap at beginning of current line }
  index := start;

  { Last beginning of a word stored here.  For now, it is start.
    It is the value of lastwordbegin that gets returned. }
  lastwordbegin := start;


  done := false;
  while (not done) do
    begin
      { if we've gone 80 chars past the start, we are done, we return
        the position of the beginning of the last word. }
      if (index-start = charsperline) then
            done := true

      { if we get to the end of the string, we are done.
        store position in lastwordbegin since we will be
        returning the size of the string }

      else if (index = lstrlen(s)) then
        begin
          lastwordbegin := index;
          done := true
        end

      else
        begin

          { Otherwise, we are not at the end of the string.
            Get the contents. }

          ch := lstrcharat(s,index);

          {  If its a carriage return, we will return the position of the
             next character. }

          if (ch = chr(13)) then
            begin
              lastwordbegin := index + 1;
              done := true
            end

          { If we are at a space, the state becomes 1 }
          else if (ch = ' ') then
            state := 1

          { Else, we've been in spaces and we have encountered a non space
            store this position in lastwordbegin, but we still aren't done }
          else if (state = 1) then
            begin
              lastwordbegin := index;
              state := 0
            end;


        end;
      index := index + 1
    end;

  { if we haven't found the beginning of a word except for the beginning of this
    line, just return 80 chars past. }
  if (lastwordbegin = start) then
      lstrnextwordwrap := start + charsperline
  else
      lstrnextwordwrap := lastwordbegin
end
end;



Function lstrboyermoore(var ls:longstr;s:string;var posit:word):boolean;

  var boyer:array[0..255] of byte;
      i:integer;
      found:boolean;
      cposit:longint;
      sposit:longint;
      boyerindex:longint;

  begin
    for i := 0 to 255 do boyer[i] := 0;
    for i := 1 to length(s) do
      boyer[ord(s[i])] := i;
    found := false;
    sposit := posit;
    while (sposit+length(s) <= lstrlen(ls)) and (not found) do
      begin
        cposit := sposit+length(s)-1;
        while (cposit >= sposit) and (s[cposit-sposit+1] = lstrcharat(ls,cposit)) do
          cposit := cposit-1;
        if (cposit < sposit) then
          found := true
        else
          begin
            boyerindex := boyer[ord(lstrcharat(ls,cposit))];
            boyerindex := cposit - sposit + 1 - boyerindex;
            if (boyerindex < 1) then boyerindex := 1;
            sposit := sposit + boyerindex
          end
      end;
    if (found) then
        posit := sposit;
    lstrboyermoore := found
  end;

Procedure lstrcaps(var ls:longstr);

var i:word;

begin
  for i := 1 to ls.size do
    ls.ptr^[i-1] := upcase(ls.ptr^[i-1])
end;


begin
end.







