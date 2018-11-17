unit group;

interface

  uses crt,lgarray,IOunit;

  const
    MAXGRPLEN = 30;
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

  Procedure savegroup(var groupdata:grouptype;filename:string);

  Procedure showmembership(p:memberptrtype;var groupdata:grouptype);

  Procedure maindriver(var groupdata:grouptype;var alldata:dbasetype;currec:longint;var filename:string);

implementation

  Function spaces(x:integer):string;

    var cnt:integer;
        temp:string;

    begin
      temp := '';
      for cnt := 1 to x do temp := temp + ' ';
      spaces := temp
    end;


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

  Procedure inputgroup(var groupdata:grouptype;var num:integer);

    var cnt,code:integer;
        temp:string;
        done,escpressed:boolean;

    begin
      done := false;
      repeat
        clrscr;
        writeln('G R O U P S':45);
        writeln;
        for cnt := 1 to (numgroups(groupdata) + 1) div 2 do
          begin
            write(cnt:2,'.  '+groupname(groupdata,cnt)+spaces(34-length(groupname(groupdata,cnt))));
            if cnt + (numgroups(groupdata) + 1) div 2 <= numgroups(groupdata) then
              writeln(cnt + (numgroups(groupdata) + 1) div 2:2,'. '+groupname(groupdata,cnt+ (numgroups(groupdata) + 1) div 2))
            else writeln
          end;
        writeln;
        write('Pick one: ');
        getinput(temp,escpressed);
        if escpressed then temp := '';
        if temp = '' then
          begin
            num := -1;
            done := true
          end
        else if temp = '0' then
          begin
            num := 0;
            done := true
          end
        else
          begin
            val(temp,num,code);
            if (num >= 1) and (num <= numgroups(groupdata)) then done := true
          end
      until done
    end;

  Procedure loadgroup(var groupdata:grouptype;filename:string);

    var f:file;
        numread:word;

    begin
      assign(f,filename);
      reset(f,1);
      blockread(f,groupdata,sizeof(groupdata),numread);
      close(f)
    end;

  Procedure savegroup(var groupdata:grouptype;filename:string);

    var f:file;
        numwritten:word;

    begin
      assign(f,filename);
      rewrite(f,1);
      blockwrite(f,groupdata,sizeof(groupdata),numwritten);
      close(f)
    end;


  Procedure showmembership(p:memberptrtype;var groupdata:grouptype);

    var c1,cnt:integer;

    begin
      clrscr;
      writeln('MEMBERSHIP OF CURRENT RECORD':54);
      writeln;
      c1 := 0;
      for cnt := 1 to numgroups(groupdata) do
        begin
          if groupindex(groupdata,cnt) in p^.membership then
            begin
              gotoxy(1 + 39*(c1 mod 2),3 + (c1 div 2));
              write(groupname(groupdata,cnt));
              c1 := c1 + 1
            end
        end;
      pause
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

  Procedure addmarkedgroup(var alldata:dbasetype;var groupdata:grouptype;num:integer);

    var count:longint;
        p:memberptrtype;

    begin
      for count := 1 to alldata.fsize do
        begin
          assignptr(pointer(p),alldata,count,0,1);
          if p^.marked then
            begin
              addrecgroup(p,groupdata,num);
              alldata.altered1 := true
            end
        end
    end;

  Procedure removemarkedgroup(var alldata:dbasetype;var groupdata:grouptype;num:integer);

    var count:longint;
        p:memberptrtype;

    begin
      for count := 1 to alldata.fsize do
        begin
          assignptr(pointer(p),alldata,count,0,1);
          if p^.marked then
            begin
              removerecgroup(p,groupdata,num);
              alldata.altered1 := true
            end
        end
    end;

  Procedure addallgroup(var alldata:dbasetype;var groupdata:grouptype;num:integer);

    var count:longint;
        p:memberptrtype;

    begin
      for count := 1 to alldata.fsize do
        begin
          assignptr(pointer(p),alldata,count,0,1);
          addrecgroup(p,groupdata,num);
          alldata.altered1 := true
        end
    end;

  Procedure removeallgroup(var alldata:dbasetype;var groupdata:grouptype;num:integer);

    var count:longint;
        p:memberptrtype;

    begin
      for count := 1 to alldata.fsize do
        begin
          assignptr(pointer(p),alldata,count,0,1);
          removerecgroup(p,groupdata,num);
          alldata.altered1 := true
        end
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

  Procedure groupeditmenu(var choice:integer);

    var temp:string;
        code:integer;
        escpressed:boolean;

    begin
      clrscr;
      gotoxy(1,5);
      write('ADD / REMOVE GROUPS MENU':52);
      gotoxy(10,7);
      write('1.  Add Group');
      gotoxy(10,9);
      write('2.  Change Group Name');
      gotoxy(10,11);
      write('3.  Remove Group');
      gotoxy(10,13);
      write('4.  Return to Main Menu');
      gotoxy(1,15);
      write('Pick one: ');
      getinput(temp,escpressed);
      val(temp,choice,code)
    end;


  Procedure groupeditdriver(var groupdata:grouptype;var alldata:dbasetype);

    var escpressed,done:boolean;
        choice,num:integer;
        temp:string;

    begin
      done := false;
      repeat
        groupeditmenu(choice);
        case choice of
          1:if numgroups(groupdata) < MAXGRP then
              begin
                clrscr;
                gotoxy(1,12);
                write('Enter name of new group: ');
                getinput(temp,escpressed);
                if not escpressed then addgroup(groupdata,temp)
              end;
          2:if numgroups(groupdata) > 0 then
              begin
                inputgroup(groupdata,num);
                if num > 0 then
                  begin
                    clrscr;
                    gotoxy(1,12);
                    write('Enter new name for group: ');
                    getinput(temp,escpressed);
                    if not escpressed then editgroup(groupdata,num,temp)
                  end
              end;
          3:if numgroups(groupdata) > 0 then
              begin
                inputgroup(groupdata,num);
                if num > 0 then
                  begin
                    removeallgroup(alldata,groupdata,num);
                    removegroup(groupdata,num)
                  end
              end;
          4:done := true
        end
      until done
    end;


  Procedure grouprecmenu(var choice:integer);

    var code:integer;
        temp:string;
        escpressed:boolean;

    begin
      clrscr;
      gotoxy(1,5);
      write('CHANGE MEMBERSHIPS MENU':51);
      gotoxy(10,7);
      write('1.  Show Memberships of Current Record');
      gotoxy(10,8);
      write('2.  Add Current Record to a Group');
      gotoxy(10,9);
      write('3.  Add Marked Records to a Group');
      gotoxy(10,10);
      write('4.  Add All Records to a Group');
      gotoxy(10,11);
      write('5.  Remove Current Record from a Group');
      gotoxy(10,12);
      write('6.  Remove Marked Records from a Group');
      gotoxy(10,13);
      write('7.  Remove All Records from a Group');
      gotoxy(10,14);
      write('8.  Return to Main Menu');
      gotoxy(1,16);
      write('Pick one: ');
      getinput(temp,escpressed);
      val(temp,choice,code)
    end;

  Procedure grouprecdriver(var groupdata:grouptype;var alldata:dbasetype;currec:longint);

    var done,escpressed:boolean;
        choice,num:integer;
        p:memberptrtype;

    begin
      done := false;
      repeat
        grouprecmenu(choice);
        case choice of
          1:begin
              assignptr(pointer(p),alldata,currec,0,1);
              showmembership(p,groupdata)
            end;
          2:begin
              inputgroup(groupdata,num);
              if num >= 0 then
                begin
                  assignptr(pointer(p),alldata,currec,0,1);
                  addrecgroup(p,groupdata,num);
                  alldata.altered1 := true
                end
            end;
          3:begin
              inputgroup(groupdata,num);
              if num >= 0 then
                addmarkedgroup(alldata,groupdata,num)
            end;
          4:begin
              inputgroup(groupdata,num);
              if num >= 0 then
                addallgroup(alldata,groupdata,num)
            end;
          5:begin
              inputgroup(groupdata,num);
              if num >= 0 then
                begin
                  assignptr(pointer(p),alldata,currec,0,1);
                  removerecgroup(p,groupdata,num);
                  alldata.altered1 := true
                end
            end;
          6:begin
              inputgroup(groupdata,num);
              if num >= 0 then
                removemarkedgroup(alldata,groupdata,num)
            end;
          7:begin
              inputgroup(groupdata,num);
              if num >= 0 then
                removeallgroup(alldata,groupdata,num)
            end;
          8:done := true
        end
      until done
    end;

  Procedure groupmarkmenu(var choice:integer);

    var temp:string;
        code:integer;
        escpressed:boolean;

    begin
      clrscr;
      gotoxy(1,5);
      write('MARK GROUPS MENU':48);
      gotoxy(10,7);
      write('1.  Default Option');
      gotoxy(10,8);
      write('2.  AND Option');
      gotoxy(10,9);
      write('3.  OR Option');
      gotoxy(10,10);
      write('4.  XOR Option');
      gotoxy(10,11);
      write('5.  AND NOT Option');
      gotoxy(10,12);
      write('6.  OR NOT Option');
      gotoxy(10,13);
      write('7.  XOR NOT Option');
      gotoxy(10,14);
      write('8.  Return to Main Menu');
      gotoxy(1,16);
      write('Pick one: ');
      getinput(temp,escpressed);
      val(temp,choice,code)
    end;

  Procedure groupmarkdriver(var groupdata:grouptype;var alldata:dbasetype);

    var count:longint;
        choice,num:integer;
        done:boolean;
        p:memberptrtype;

    begin
      done := false;
      repeat
        groupmarkmenu(choice);
        if (choice < 1) or (choice > 7) then done := true
        else
          begin
            inputgroup(groupdata,num);
            if num > 0 then
              begin
                for count := 1 to alldata.fsize do
                  begin
                    assignptr(pointer(p),alldata,count,0,1);
                    markgroup(p,groupdata,num,choice);
                    alldata.altered1 := true
                  end
              end
          end
      until done
    end;

  Procedure groupmainmenu(var choice:integer);

    var temp:string;
        code:integer;
        escpressed:boolean;

    begin
      clrscr;
      gotoxy(1,5);
      write('G R O U P   M A I N   M E N U':54);
      gotoxy(10,7);
      write('1.  Load Group File');
      gotoxy(10,9);
      write('2.  Add / Remove Groups');
      gotoxy(10,11);
      write('3.  Change Memberships');
      gotoxy(10,13);
      write('4.  Mark Groups');
      gotoxy(10,15);
      write('5.  Quit');
      gotoxy(1,17);
      write('Pick one: ');
      getinput(temp,escpressed);
      val(temp,choice,code)
    end;


  Procedure maindriver(var groupdata:grouptype;var alldata:dbasetype;currec:longint;var filename:string);

   var choice:integer;
       done,escpressed:boolean;
       temp,tempfile:string;


    begin
      done := false;
    repeat
      groupmainmenu(choice);
      case choice of
        1:if filename = '' then begin
            clrscr;
            gotoxy(1,12);
            write('Enter name of group file: ');
            getinput(tempfile,escpressed);
            if not escpressed then
              begin
                if not fileexists(tempfile) then
                  begin
                    gotoxy(1,14);
                    write('Cannot find that file.  Create a new one<y,n>? ');
                    getinput(temp,escpressed);
                    if (length(temp) > 0) and (temp[1] in ['Y','y']) then
                      begin
                        if not filecreation(tempfile) then
                          begin
                            gotoxy(1,16);
                            write(chr(7)+'File creation error.');
                            pause
                          end
                        else
                          begin
                            initgroups(groupdata);
                            filename := tempfile
                          end
                      end
                  end
                else
                  begin
                    loadgroup(groupdata,tempfile);
                    filename := tempfile
                  end
              end
          end;
        2:if filename <> '' then
            groupeditdriver(groupdata,alldata);
        3:if (filename <> '') and (numgroups(groupdata) > 0) then
            grouprecdriver(groupdata,alldata,currec);
        4:if (filename <> '') and (numgroups(groupdata) > 0) then
           groupmarkdriver(groupdata,alldata);
        5:done := true
      end
    until done
  end;

end.