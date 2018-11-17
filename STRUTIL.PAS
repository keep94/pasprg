unit strutil;

interface

Function indexOf(var x:string;s:string):integer;

Procedure trim(var s:string);

implementation

Function indexOf(var x:string;s:string):integer;

  var textpos:integer;
      patternpos:integer;
      textlen:integer;
      patternlen:integer;
      result:integer;
      nomatch:boolean;

  begin
    textlen := ord(x[0]);
    patternlen := ord(s[0]);

    if (textlen < 0) then textlen := textlen + 256;
    if (patternlen < 0) then patternlen := patternlen + 256;

    textpos := 1;
    result := -1;

    while (textpos <= textlen-patternlen+1) and (result = -1) do
      begin
        nomatch := false;
        patternpos := 1;
        while (patternpos <= patternlen) and (not nomatch) do
          begin
            if (x[textpos+patternpos-1] <> s[patternpos]) then
                nomatch := true
            else
                patternpos := patternpos + 1
          end;

        if (nomatch) then
          textpos := textpos + 1
        else
          result := textpos
      end;
    indexof := result
  end;

Procedure trim(var s:string);

var textlen:integer;
    i:integer;
    lowp,highp:integer;
    found:boolean;

begin
  textlen := ord(s[0]);
  if (textlen < 0) then textlen := textlen + 256;

  found := false;

  i := textlen;
  while (i > 0) and (not found) do
    begin
      if s[i] <> ' ' then found := true else i := i-1
    end;
  highp := i;
  i := 1;
  found := false;
  while (i <= highp) and (not found) do
    begin
      if s[i] <> ' ' then found := true else i := i+1
    end;
  lowp := i;
  if (highp >= lowp) then
     s := copy(s,lowp,highp-lowp+1)
  else
     s := ''

end;


begin
end.

