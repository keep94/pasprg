program numbersup;

 uses crt,dos;

 type
   boardtype = array[0..19] of integer;

   timertype = record
     shour:integer;
     sminute:integer;
     ssecond:integer;
     ssec100:integer;
     offset:real;
     running:boolean
   end;


   gametype = record
     inprog:boolean;
     timeelapsed:timertype;
     seq:integer;
     posx:integer;
     posy:integer;
     lasttime:integer;
     numbers:boardtype
   end;


 Function gettimer(var t:timertype):real;

   var h,m,s,s100:word;
       ch,cm,cs,cs100:integer;
       temp:real;
       newoffset:real;

   begin
     if t.running then
       begin
         gettime(h,m,s,s100);
         ch := h;
         cm := m;
         cs := s;
         cs100 := s100;
         temp := 3600.0*(ch - t.shour)+60.0*(cm - t.sminute)+
           (cs - t.ssecond) + (cs100 - t.ssec100) / 100;
         if temp < 0.0 then temp := temp + 86400.0
       end
     else
       temp := 0.0;
     newoffset := t.offset - temp;
     if newoffset < 0.0 then
       begin
         newoffset := 0.0;
         t.running := false;
         t.offset := newoffset
       end;
     gettimer := newoffset
   end;


 Procedure starttimer(var t:timertype);

   var h,m,s,s100:word;

   begin
     if not t.running then
       begin
         gettime(h,m,s,s100);
         t.shour := h;
         t.sminute := m;
         t.ssecond := s;
         t.ssec100 := s100;
         t.running := true
       end
   end;

 Procedure stoptimer(var t:timertype);

   begin
     if t.running then
       begin
         t.offset := gettimer(t);
         t.running := false
       end
   end;


 Procedure settimer(var t:timertype;x:real);

   begin
     t.running := false;
     t.offset := x
   end;


 Function timertostr(x:real):string;

   var temp:string;
       len:integer;
       t:longint;
       i:integer;

   begin
     t := trunc(x);
     if t < 600 then len := 4
     else if t < 3600 then len := 5
     else if t < 36000 then len := 7
     else len := 8;
     temp[0] := chr(len);
     i := len;
     while i > 0 do
       begin
         temp[i] := chr((t mod 10)+48);
         t := t div 10;
         i := i - 1;
         if i > 0 then
           begin
             temp[i] := chr((t mod 6)+48);
             t := t div 6;
             i := i - 1;
             if i > 0 then
               begin
                 temp[i] := ':';
                 i := i - 1
               end
           end
       end;
     timertostr := temp
   end;



 Procedure initgame(var g:gametype);

   var i:integer;
       temp:integer;
       index:integer;

   begin
     g.inprog := false;
     g.seq := 0;
     g.posx := 18;
     g.posy := 3;
     settimer(g.timeelapsed,0.0);
     g.lasttime := -1;
     for i := 0 to 19 do
       g.numbers[i] := i+1;
     for i := 19 downto 1 do
       begin
         index := random(i+1);
         temp := g.numbers[index];
         g.numbers[index] := g.numbers[i];
         g.numbers[i] := temp
       end
   end;


 Procedure pausegame(var g:gametype);

   begin
     if g.inprog then
       begin
         g.inprog := false;
         stoptimer(g.timeelapsed)
       end
     else if gettimer(g.timeelapsed) > 0.0 then
       begin
         g.inprog := true;
         starttimer(g.timeelapsed)
       end
   end;


 Procedure showtime(var g:gametype);

   var temp:real;
       wasrunning:boolean;
       curtime:integer;
       lx,ly:integer;

   begin
     wasrunning := g.timeelapsed.running;
     temp := gettimer(g.timeelapsed);
     curtime := trunc(temp+0.99);
     if curtime <> g.lasttime then
       begin
         lx := wherex;
         ly := wherey;
         gotoxy(1,7);
         write('Time: ',timertostr(temp+0.99):8);
         gotoxy(lx,ly);
         g.lasttime := curtime
       end;
     if (temp = 0.0) and (wasrunning) then
       begin
         write(chr(7));
         pausegame(g)
       end
   end;

 Procedure showscore(var g:gametype);

   begin
     gotoxy(1,10);
     write('Score: ',g.seq:7)
   end;

 Procedure showobject(obj:integer;state:integer);

   var lx,ly:integer;

   begin
     lx := wherex;
     ly := wherey;

     if state = 1 then
       textcolor(14)
     else
       textcolor(7);

     if obj = 20 then
       begin
         gotoxy(4,13);
         write('[Start]')
       end
     else if obj = 21 then
       begin
         gotoxy(4,15);
         write('[Pause]')
       end
     else if obj = 22 then
       begin
         gotoxy(4,17);
         write('[Quit]')
       end;
     textcolor(7);
     gotoxy(lx,ly)
   end;

 Procedure showbuttons(var g:gametype);

   begin
     showobject(20,0);
     showobject(21,0);
     showobject(22,0)
   end;

 Procedure showseq(var g:gametype);

   var i:integer;

     begin
       gotoxy(1,21);
       for i := 1 to 20 do
         if i <= g.seq then write(i:3)
         else write('':3)
     end;


 Procedure showboard(var g:gametype);

   var i,j:integer;

   begin
     for i := 0 to 16 do
       begin
         gotoxy(g.posx,i+g.posy);
         for j := 0 to 45 do
           begin
             if (i=0) and (j=0) then
               write(chr(218))
             else if (i=0) and (j=45) then
               write(chr(191))
             else if (i=16) and (j=0) then
               write(chr(192))
             else if (i=16) and (j=45) then
               write(chr(217))
             else if (i=0) and (j mod 9 = 0) then
               write(chr(194))
             else if (i=16) and (j mod 9 = 0) then
               write(chr(193))
             else if (i mod 4 = 0) and (j = 0) then
               write(chr(195))
             else if (i mod 4 = 0) and (j=45) then
               write(chr(180))
             else if (i mod 4 = 0) and (j mod 9 = 0) then
               write(chr(197))
             else if (i mod 4 = 0) then
               write(chr(196))
             else if (j mod 9 = 0) then
               write(chr(179))
             else if (i mod 4 = 2) and ((j mod 9 = 4) or (j mod 9 = 5))
             and (g.numbers[5*(i div 4) + (j div 9)] > g.seq) then
               write('X')
             else
               write(' ')
           end
       end
   end;


 Procedure startgame(var g:gametype);

   begin
     initgame(g);
     settimer(g.timeelapsed,60.0);
     showboard(g);
     showscore(g);
     showseq(g);
     g.inprog := true;
     starttimer(g.timeelapsed);
     showtime(g)
   end;


 Procedure displaygame(var g:gametype);

   var i,j:integer;

   begin
     clrscr;
     writeln('N U M B E R S   U P':49);
     writeln;
     showboard(g);
     showtime(g);
     showscore(g);
     showbuttons(g);
     showseq(g)
   end;


  Function mousetosquare(var g:gametype;x,y:integer):integer;

    var cornerx,cornery:integer;
        temp:integer;

    begin
      cornerx := (g.posx - 1)*8;
      cornery := (g.posy - 1)*8;
      if (x < cornerx) or (x >= cornerx + 360) or
         (y < cornery) or (y >= cornery + 128) then
        begin
          if (y >= 96) and (y < 104) and (x >= 24) and (x < 80) then
            temp := 20
          else if (y >= 112) and (y < 120) and (x >= 24) and (x < 80) then
            temp := 21
          else if (y >= 128) and (y < 136) and (x >= 24) and (x < 72) then
            temp := 22
          else temp := -1
        end
      else
        temp := ((y - cornery) div 32)*5 + (x - cornerx) div 72;
      mousetosquare := temp
    end;


  Procedure shownumberonboard(var g:gametype;x:integer);

  var colx,coly:integer;
      lx,ly:integer;

  begin
    colx := x mod 5;
    coly := x div 5;
    lx := wherex;
    ly := wherey;
    if g.numbers[x] > g.seq then
      begin
        gotoxy(g.posx + 9*colx + 4,g.posy + 4*coly + 2);
        if (g.numbers[x] = g.seq + 1) then
          begin
            write('  ');
            g.seq := g.seq + 1;
            showscore(g);
            showseq(g);
            if g.seq = 20 then
              begin
              end
          end
        else
          write(g.numbers[x]:2);
        gotoxy(lx,ly)
      end
  end;


Procedure hidenumberonboard(var g:gametype;x:integer);

  var colx,coly:integer;
      lx,ly:integer;

  begin
    colx := x mod 5;
    coly := x div 5;
    lx := wherex;
    ly := wherey;
    if g.numbers[x] > g.seq then
      begin
        gotoxy(g.posx + 9*colx + 4,g.posy + 4*coly + 2);
        write('XX');
        gotoxy(lx,ly)
      end
  end;


Procedure nextstate(x,y:integer;leftbutton:boolean;var focus:integer;
var state:integer;var g:gametype;var done:boolean);

  var newfocus:integer;

  begin
    newfocus := mousetosquare(g,x,y);
    if (focus >= 0) and (focus < 20) and (g.inprog) then
      begin
        if newfocus <> focus then
          begin
            if state = 1 then
              hidenumberonboard(g,focus)
          end
        else if (state = 1) and (not leftbutton) then
          begin
            hidenumberonboard(g,focus);
            state := 0
          end
        else if (state = 0) and (leftbutton) then
          begin
            shownumberonboard(g,focus);
            state := 1
          end
        else if (state = -1) and (not leftbutton) then
          state := 0
      end
    else if (focus >= 20) and (focus <= 22) then
      begin
        if newfocus <> focus then
          begin
            if state = 1 then
              showobject(focus,0)
          end
        else if (state = 1) and (not leftbutton) then
          begin
            state := 0;
            showobject(focus,state);
            if focus = 20 then
              startgame(g)
            else if focus = 21 then
              pausegame(g)
            else if focus = 22 then
              done := true
          end
        else if (state = 0) and leftbutton then
          begin
            state := 1;
            showobject(focus,state)
          end
        else if (state = -1) and (not leftbutton) then
          state := 0
      end;
    if newfocus <> focus then
      begin
        focus := newfocus;
        if leftbutton then
          state := -1
        else
          state := 0
      end
  end;




  Procedure convertbx(bx:word;var lb:boolean);

  begin
    lb := bx and 1 = 1
  end;


  Procedure initmouse;

  begin
    Inline($b8/$00/$00/          {mov ax,0 }
           $cd/$33/              {int 33}
           $b8/$01/$00/          {mov ax,1 }
           $cd/$33)              {int 33}
  end;

  Procedure cleanup;

  begin
    Inline($b8/$02/$00/            {mov ax,2 }
           $cd/$33)                {int 33}
  end;

  Procedure pollmouse(var x:integer;var y:integer;var bx:word);

  begin
    Inline($b8/$03/$00/           {mov ax,3 }
           $cd/$33/               {int 33}
           $c4/$7e/$04/           {les di,[bp+04]}
           $26/                   {es: }
           $89/$1d/               {mov [di],bx}
           $c4/$7e/$08/           {les di,[bp+08]}
           $26/                   {es: }
           $89/$15/               {mov [di],dx}
           $c4/$7e/$0c/           {les di,[bp+0c]}
           $26/                   {es: }
           $89/$0d)               {mov [di],cx}
  end;


  var g:gametype;
      done:boolean;
      x,y:integer;
      bx:word;
      leftbutton:boolean;
      focus,state:integer;

  begin
    randomize;
    initgame(g);
    displaygame(g);
    done := false;
    initmouse;
    focus := -1;
    state := -1;
    repeat
      pollmouse(x,y,bx);
      convertbx(bx,leftbutton);
      nextstate(x,y,leftbutton,focus,state,g,done);
      showtime(g)
    until done;
    cleanup
  end.
