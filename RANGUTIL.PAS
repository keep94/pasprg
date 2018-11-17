unit rangutil;

interface

type
  rgreal=record
    lowpart:real;
    highpart:real;
    haslow:boolean;
    hashigh:boolean
  end;

  rgserial=record
    lowpart:string;
    highpart:string;
    haslow:boolean;
    hashigh:boolean;
    llen:integer;
    hlen:integer
  end;

Procedure rgrealinit(var x:rgreal;s:string);

Function rgrealcompare(var rg:rgreal;x:real):boolean;

Procedure rgserialinit(var x:rgserial;s:string);

Function rgserialcompare(var rg:rgserial;x:string):boolean;

implementation

uses strutil;

const epsilon=0.005;

Procedure rgrealinit(var x:rgreal;s:string);

var posit:integer;
    tr:real;
    code:word;
    temp:string;

begin
  posit := indexof(s,',');
  if (posit = -1) then
    begin
      val(s,tr,code);
      x.lowpart := tr - epsilon;
      x.highpart := tr + epsilon;
      x.haslow := true;
      x.hashigh := true
    end
  else
    begin
      temp := copy(s,1,posit-1);
      trim(temp);
      if (temp = '') then
        x.haslow := false
      else
        begin
          x.haslow := true;
          val(temp,tr,code);
          x.lowpart := tr - epsilon
        end;
      temp := copy(s,posit+1,length(s)-posit);
      trim(temp);
      if (temp = '') then
         x.hashigh := false
      else
        begin
          x.hashigh := true;
          val(temp,tr,code);
          x.highpart := tr + epsilon
        end
    end
end;

Function rgrealcompare(var rg:rgreal;x:real):boolean;

  var temp:boolean;

  begin
    temp := true;
    if rg.haslow then
      temp := (x > rg.lowpart);

    if (temp) and (rg.hashigh) then
        temp := (x < rg.highpart);

    rgrealcompare := temp
  end;

Procedure rgserialinit(var x:rgserial;s:string);

var posit:integer;
    tr:real;
    code:word;
    temp:string;

begin
  posit := indexof(s,',');
  if (posit = -1) then
    begin
      x.lowpart := s;
      x.highpart := s;
      x.haslow := true;
      x.hashigh := true;
      x.llen := length(s);
      x.hlen := x.llen
    end
  else
    begin
      temp := copy(s,1,posit-1);
      trim(temp);
      if (temp = '') then
        x.haslow := false
      else
        begin
          x.haslow := true;
          x.lowpart := temp;
          x.llen := length(temp)
        end;
      temp := copy(s,posit+1,length(s)-posit);
      trim(temp);
      if (temp = '') then
         x.hashigh := false
      else
        begin
          x.hashigh := true;
          x.highpart := temp;
          x.hlen := length(temp)
        end
    end
end;

Function rgserialcompare(var rg:rgserial;x:string):boolean;

  var temp:boolean;
      len:integer;

  begin
    trim(x);
    len := length(x);
    temp := true;
    if rg.haslow then
        if (len > rg.llen) then temp := true
        else if (len < rg.llen) then temp := false
        else temp := (x >= rg.lowpart);

    if (temp) and (rg.hashigh) then
        if (len > rg.hlen) then temp := false
        else if (len < rg.hlen) then temp := true
        else temp := (x <= rg.highpart);

    rgserialcompare := temp
  end;

begin
end.
