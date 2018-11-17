unit encunit;

interface

uses lstr;

function enccodes(x:string;passkey:string):string;

function encdecodes(x:string;passkey:string):string;

procedure enccodels(var ls:longstr;passkey:string);

procedure encdecodels(var ls:longstr;passkey:string);

procedure enccode(var x;len:word;passkey:string);

procedure encdecode(var x;len:word;passkey:string);

implementation

  uses rand;

  type
    tabletype = array[0..255] of byte;
    arraytype = array[0..65520] of byte;
    ptrtype = ^arraytype;


  function encpord(x:char):longint;

    begin
      if x in ['0'..'9'] then
        encpord := ord(x) - 21
      else if x in ['A'..'Z'] then
        encpord := ord(x) - 64
      else if x in ['a'..'z'] then
        encpord := ord(x) - 96
      else encpord := -1
    end;

  procedure encgetkey(x:string;var ekey:longint);

    var cnt:integer;

    begin
      ekey := 0;
      for cnt := 1 to length(x) do
        ekey := ekey*37+encpord(x[cnt])
    end;

  procedure encgentable(var t:tabletype);

    var cnt:integer;
        pos,temp:byte;

    begin
      for cnt := 0 to 255 do
        t[cnt] := cnt;
      for cnt := 256 downto 2 do
        begin
          setmax(cnt);
          pos := longrnd;
          temp := t[cnt - 1];
          t[cnt - 1] := t[pos];
          t[pos] := temp
        end
    end;

  procedure encgeninvtable(var t:tabletype;var invt:tabletype);

    var cnt:integer;

    begin
      for cnt := 0 to 255 do
        invt[t[cnt]] := cnt
    end;

  function enccodes(x:string;passkey:string):string;

    var cnt:integer;
        offset:byte;
        pt:tabletype;
        ekey:longint;

    begin
      encgetkey(passkey,ekey);
      initrnd(ekey);
      encgentable(pt);
      for cnt := 1 to length(x) do
        begin
          offset := rnd;
          x[cnt] := chr((pt[ord(x[cnt])] + offset) mod 256)
        end;
      enccodes := x
    end;


  function encdecodes(x:string;passkey:string):string;

    var cnt:integer;
        offset:byte;
        pt,invpt:tabletype;
        ekey:longint;

    begin
      encgetkey(passkey,ekey);
      initrnd(ekey);
      encgentable(pt);
      encgeninvtable(pt,invpt);
      for cnt := 1 to length(x) do
        begin
          offset := rnd;
          x[cnt] := chr(invpt[byte(ord(x[cnt]) - offset)]);
        end;
      encdecodes := x
    end;



  Procedure enccodels(var ls:longstr;passkey:string);

    var cnt:word;
        offset:byte;
        pt:tabletype;
        ekey:longint;
        ch:char;

    begin
      encgetkey(passkey,ekey);
      initrnd(ekey);
      encgentable(pt);
      for cnt := 1 to lstrlen(ls) do
        begin
          offset := rnd;
          ch := lstrcharat(ls,cnt-1);
          ch := chr((pt[ord(ch)] + offset) mod 256);          
          lstrsetchar(ls,cnt-1,ch)
        end
    end;


  procedure encdecodels(var ls:longstr;passkey:string);

    var cnt:word;
        offset:byte;
        pt,invpt:tabletype;
        ekey:longint;
        ch:char;

    begin
      encgetkey(passkey,ekey);
      initrnd(ekey);
      encgentable(pt);
      encgeninvtable(pt,invpt);
      for cnt := 1 to lstrlen(ls) do
        begin
          offset := rnd;
          ch := lstrcharat(ls,cnt-1);
          ch := chr(invpt[byte(ord(ch) - offset)]);
          lstrsetchar(ls,cnt-1,ch)
        end
    end;

procedure enccode(var x;len:word;passkey:string);

    var cnt:word;
        offset:byte;
        pt:tabletype;
        ekey:longint;
        p:ptrtype;
        b:byte;

    begin
      p := addr(x);
      encgetkey(passkey,ekey);
      initrnd(ekey);
      encgentable(pt);
      for cnt := 1 to len do
        begin
          offset := rnd;
          b := p^[cnt-1];
          b := (pt[b] + offset) mod 256;
          p^[cnt-1] := b
        end
    end;

  procedure encdecode(var x;len:word;passkey:string);

    var cnt:word;
        offset:byte;
        pt,invpt:tabletype;
        ekey:longint;
        p:ptrtype;
        b:byte;

    begin
      p := addr(x);
      encgetkey(passkey,ekey);
      initrnd(ekey);
      encgentable(pt);
      encgeninvtable(pt,invpt);
      for cnt := 1 to len do
        begin
          offset := rnd;
          b := p^[cnt-1];
          b := invpt[byte(b - offset)];
          p^[cnt-1] := b
        end
    end;


begin
end.

