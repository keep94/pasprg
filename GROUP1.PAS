unit group1;

interface

  uses crt,IOunit;

  const
    MAXGRPLEN = 14;
    MAXGRP = 40;
  type
    grouprectype = record
      index:integer;
      name:string[MAXGRPLEN]
    end;

    grouptype = record
      size:integer;
      data:array[1..MAXGRP] of grouprectype
    end;

    itype = 0..39;

    memberinfotype = record
      marked:boolean;
      membership:set of itype
    end;

    memberptrtype = ^memberinfotype;


  Procedure initgroups(var groupdata:grouptype);

  Procedure addgroup(var groupdata:grouptype;x:string);

  Procedure editgroup(var groupdata:grouptype;num:integer;x:string);

  Function numgroups(var groupdata:grouptype):integer;

  Function groupname(var groupdata:grouptype;num:integer):string;

  Function groupindex(var groupdata:grouptype;num:integer):integer;

  Procedure removegroup(var groupdata:grouptype;num:integer);

  Procedure loadgroup(var groupdata:grouptype;var f:file);

  Procedure savegroup(var groupdata:grouptype;var f:file);

  Procedure showmembership(p:memberptrtype;var groupdata:grouptype);

  Procedure showgroups(var groupdata:grouptype);

  Procedure addrecgroup(p:memberptrtype;var groupdata:grouptype;num:integer);

  Procedure removerecgroup(p:memberptrtype;var groupdata:grouptype;num:integer);

  Procedure markgroup(p:memberptrtype;var groupdata:grouptype;num:integer;ctrl:integer);

implementation

  type
    videotype = array[0..65519] of byte;

    videoptrtype = ^videotype;


  Procedure initgroups(var groupdata:grouptype);

    var cnt:integer;

    begin
      for cnt := 1 to MAXGRP do
        groupdata.data[cnt].index := cnt - 1;
      groupdata.size := 0
    end;


  Procedure addgroup(var groupdata:grouptype;x:string);

    var cnt,c:integer;
        temp:grouprectype;

    begin
      x := copy(x,1,MAXGRPLEN);
      groupdata.size := groupdata.size + 1;
      groupdata.data[groupdata.size].name := x;
      cnt := groupdata.size - 1;
      while (cnt > 0) and (groupdata.data[groupdata.size].name < groupdata.data[cnt].name) do
        cnt := cnt - 1;
      temp := groupdata.data[groupdata.size];
      for c := groupdata.size downto cnt + 2 do
        groupdata.data[c] := groupdata.data[c - 1];
      groupdata.data[cnt + 1] := temp
    end;

  Procedure editgroup(var groupdata:grouptype;num:integer;x:string);

   var c,cnt:integer;
       temp:grouprectype;

   begin
     cnt := groupdata.size;
     while (cnt > 0) and (x < groupdata.data[cnt].name) do
       cnt := cnt - 1;
     groupdata.data[num].name := copy(x,1,MAXGRPLEN);
     temp := groupdata.data[num];
     if cnt < num then
       begin
         for c := num downto cnt + 2 do
           groupdata.data[c] := groupdata.data[c - 1];
         groupdata.data[cnt + 1] := temp
       end
     else if cnt > num then
       begin
         for c := num to cnt - 1 do
           groupdata.data[c] := groupdata.data[c + 1];
         groupdata.data[cnt] := temp
       end
  end;

  Function numgroups(var groupdata:grouptype):integer;

    begin
      numgroups := groupdata.size
    end;

  Function groupname(var groupdata:grouptype;num:integer):string;

    begin
      groupname := groupdata.data[num].name
    end;

  Function groupindex(var groupdata:grouptype;num:integer):integer;

    begin
      groupindex := groupdata.data[num].index
    end;

  Procedure removegroup(var groupdata:grouptype;num:integer);

    var cnt:integer;
        temp:grouprectype;

    begin
      temp := groupdata.data[num];
      for cnt := num to groupdata.size - 1 do
        groupdata.data[cnt] := groupdata.data[cnt + 1];
      groupdata.data[groupdata.size] := temp;
      groupdata.size := groupdata.size - 1
    end;


  Procedure loadgroup(var groupdata:grouptype;var f:file);

    var numread:word;

    begin
      blockread(f,groupdata,sizeof(groupdata),numread)
    end;

  Procedure savegroup(var groupdata:grouptype;var f:file);

    var numwritten:word;

    begin
      blockwrite(f,groupdata,sizeof(groupdata),numwritten)
    end;


  Procedure showmembership(p:memberptrtype;var groupdata:grouptype);

    var c1,cnt:integer;
        q:videoptrtype;

    begin
      q := ptr($b800,$0);
      for cnt := 1 to numgroups(groupdata) do
        begin
          if groupindex(groupdata,cnt) in p^.membership then
            for c1 := 0 to 18 do
              q^[1761 + 160*((cnt-1) div 4) + 38*((cnt-1) mod 4) + 2*c1] := 14
          else
            for c1 := 0 to 18 do
              q^[1761 + 160*((cnt-1) div 4) + 38*((cnt-1) mod 4) + 2*c1] := 8
        end
    end;


  Procedure showgroups(var groupdata:grouptype);

    var cnt:integer;

    begin
      gotoxy(1,12);
      for cnt := 0 to 9 do write('':80);
      for cnt := 1 to numgroups(groupdata) do
        begin
          gotoxy(1 + 19*((cnt-1) mod 4), 12 + (cnt-1) div 4);
          write(cnt:2,'. '+groupname(groupdata,cnt))
        end
    end;


  Procedure addrecgroup(p:memberptrtype;var groupdata:grouptype;num:integer);

    var cnt:integer;

    begin
      if num = 0 then
        begin
          for cnt := 1 to numgroups(groupdata) do
            p^.membership := p^.membership + [groupindex(groupdata,cnt)]
        end
      else
        p^.membership := p^.membership + [groupindex(groupdata,num)]
    end;

  Procedure removerecgroup(p:memberptrtype;var groupdata:grouptype;num:integer);

    begin
      if num = 0 then
        p^.membership := []
      else
        p^.membership := p^.membership - [groupindex(groupdata,num)]
    end;


  Procedure markgroup(p:memberptrtype;var groupdata:grouptype;num:integer;ctrl:integer);

    var ingrp:boolean;

    begin
      ingrp := groupindex(groupdata,num) in p^.membership;
      case ctrl of
        1:p^.marked := ingrp;
        2:p^.marked := p^.marked and ingrp;
        3:p^.marked := p^.marked or ingrp;
        4:p^.marked := p^.marked xor ingrp;
        5:p^.marked := p^.marked and (not ingrp);
        6:p^.marked := p^.marked or (not ingrp);
        7:p^.marked := p^.marked xor (not ingrp)
      end
    end;

end.