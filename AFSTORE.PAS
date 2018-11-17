unit afstore;

interface

type
  afstorearraytype=array[0..65519] of byte;

  afstoretype=record
    start:word;
    front:word;
    size:word;
    p:^afstorearraytype
  end;

  afsearchcontexttype=record
    posit:word;
    done:boolean
  end;

Procedure afstore_init(var a:afstoretype;size:word);

Procedure afstore_destroy(var a:afstoretype);

Procedure afstore_add(var a:afstoretype;x:string);

Function afstore_search(var a:afstoretype;var pattern:string;var match:string):boolean;

Function afstore_find_first(var a:afstoretype;var pattern:string;var match:string;var context:afsearchcontexttype):boolean;

Function afstore_find_next(var a:afstoretype;var pattern:string;var match:string;var context:afsearchcontexttype):boolean;

implementation

  Procedure upper(var x:string);

    var cnt:word;

    begin
      for cnt := 1 to length(x) do
        if (ord(x[cnt]) > 96) and (ord(x[cnt]) < 123) then
          x[cnt] := chr(ord(x[cnt]) - 32)
    end;

Procedure afstore_init(var a:afstoretype;size:word);

begin
  getmem(a.p,size);
  a.size := size;
  a.start := size;
  a.front := size
end;

Procedure afstore_destroy(var a:afstoretype);

begin
  freemem(a.p,a.size)
end;

Procedure afstore_add(var a:afstoretype;x:string);

var len:word;
    ptr:^string;

begin
  if (x <> '') then
    begin
      len := length(x);
      if (len+1 <= a.start) then
        begin
          a.start := a.start - len - 1
        end
      else
        begin
          a.front := a.start;
          a.start :=a.size - len - 1
        end;
      ptr := addr(a.p^[a.start]);
      ptr^ := x
    end
end;

Function afstore_find_next(var a:afstoretype;var pattern:string;var match:string;var context:afsearchcontexttype):boolean;

var
    result:boolean;
    ptr:^string;
    len:word;
    cstring:string;
    cpattern:string;

begin
  cpattern := pattern;
  upper(cpattern);
  result := false;

  if (a.start = a.size) then
    context.done := true;

  while (not result) and (not context.done) do
    begin
      ptr := addr(a.p^[context.posit]);
      cstring := ptr^;
      upper(cstring);
      len := length(cstring);
      if (context.posit < a.start) and (context.posit + len + 1 > a.start) then
        begin
          context.done := true
        end
      else if (cpattern = copy(cstring,1,length(cpattern))) then
        begin
          result := true;
          match := ptr^
        end
      else
        begin
          if (context.posit < a.start) then
            begin
              context.posit := context.posit + len + 1;
              if (context.posit >= a.start) then
                 context.done := true
            end
          else
            begin
              context.posit := context.posit + len + 1;
              if (context.posit = a.size) then
                begin
                  context.posit := a.front;
                  if (context.posit >= a.start) then
                    context.done := true
                end
            end
        end
    end;
  afstore_find_next := result
end;

Function afstore_find_first(var a:afstoretype;var pattern:string;var match:string;var context:afsearchcontexttype):boolean;


begin
  context.posit := a.start;
  context.done := false;
  afstore_find_first := afstore_find_next(a,pattern,match,context)
end;


Function afstore_search(var a:afstoretype;var pattern:string;var match:string):boolean;

  var context:afsearchcontexttype;

  begin
    afstore_search := afstore_find_first(a,pattern,match,context)
  end;    
  

begin
end.
  