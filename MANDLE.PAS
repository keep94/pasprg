program manlebraunt;

  uses graph,crt,IOunit;

type
  complextype=record
    realp:real;
    imagp:real
  end;

  mangraphtype = record
    lolim:complextype;
    hilim:complextype;
    incrx:real;
    incry:real;
    gcolor:integer;
    ccolor:integer;
    scale:integer;
    iter:integer;
    xcoord:integer;
    ycoord:integer
  end;

var
  filename,temp:string;
  success,done1,done2,escpressed:boolean;
  response,choice,schoice:char;
  code,mode,driver,g,c,r,i:integer;
  l,h:complextype;
  rr,ir:real;
  mangraph:mangraphtype;
  p:pointer;
  isize:word;


Function spaces(x:integer):string;

  var temp:string;
      cnt:integer;

  begin
    temp := '';
    for cnt := 1 to x do temp := temp + ' ';
    spaces := temp
  end;

Procedure assignz(var z:complextype;r,i:real);

  begin
    with z do
      begin
        realp := r;
        imagp := i
      end
  end;

Function displayz(z:complextype):string;

  var temp1,temp2:string;

  begin
    with z do
      begin
        str(realp:0:6,temp1);
        str(imagp:0:6,temp2)
      end;
    displayz := temp1+' + '+temp2+'i'
  end;

Function rpart(z:complextype):real;

  begin
    rpart := z.realp
  end;

Function ipart(z:complextype):real;

  begin
    ipart := z.imagp
  end;

Function norm(z:complextype):real;

  begin
    with z do
      norm := sqrt(realp*realp + imagp*imagp)
  end;

Procedure addz(var z:complextype;x,y:complextype);

  begin
    z.realp := x.realp + y.realp;
    z.imagp := x.imagp + y.imagp
  end;

Procedure multz(var z:complextype;x,y:complextype);

  begin
    z.realp := x.realp*y.realp - x.imagp*y.imagp;
    z.imagp := x.realp*y.imagp + x.imagp*y.realp
  end;

Function isman(c:complextype;iter:integer):boolean;

  var cnt:integer;
      z:complextype;

  begin
    assignz(z,0,0);
    cnt := 0;
    while (cnt < iter) and (norm(z) <= 0.5 + sqrt(norm(c) + 0.25)) do
      begin
        multz(z,z,z);
        addz(z,z,c);
        cnt := cnt + 1
      end;
    isman := (norm(z) <= 0.5 + sqrt(norm(c) + 0.25))
  end;

  Procedure showcursor(var mangraph:mangraphtype);

    var cnt,tempx,tempy,c:integer;

    begin
      with mangraph do
        begin
          for cnt := -5 to 5 do
            begin
              tempx := 31 + (xcoord-1)*(32 div scale) + (16 div scale) + 1+cnt;
              tempy := (ycoord-1)*(16 div scale) + (8 div scale) + 1;
              c := getpixel(tempx,tempy);
              c := c xor ccolor;
              putpixel(tempx,tempy,c)
            end;
          for cnt := -2 to 2 do
            begin
              tempx := 31 + (xcoord-1)*(32 div scale) + (16 div scale) + 1;
              tempy := (ycoord-1)*(16 div scale) + (8 div scale) + 1 + cnt;
              c := getpixel(tempx,tempy);
              c := c xor ccolor;
              putpixel(tempx,tempy,c)
            end
        end
    end;

  Procedure displayinfo(var mangraph:mangraphtype);

    var z,offset:complextype;
        incrx,incry:real;

    begin
      with mangraph do
        begin
          incrx := (rpart(hilim) - rpart(lolim))/18/scale;
          incry := (ipart(hilim) - ipart(lolim))/9/scale;
          assignz(offset,(xcoord-0.5)*incrx,(9*scale-ycoord+0.5)*incry);
          addz(z,lolim,offset)
        end;
      settextstyle(0,0,1);
      settextjustify(lefttext,toptext);
      setfillstyle(1,0);
      bar(31,150,608,160);
      setcolor(15);
      outtextXY(31,150,displayz(z));
    end;


  Procedure Createmangraph(var mangraph:mangraphtype;lo,hi:complextype;
                           g,c,r,i:integer);

    var
      cntx,cnty,cnt,s,x,y:integer;
      offset,z:complextype;

    begin
      mangraph.lolim := lo;
      mangraph.hilim := hi;
      mangraph.gcolor := g;
      mangraph.ccolor := c;
      s := 1;
      for cnt := 1 to r do s := s*2;
      mangraph.scale := s;
      mangraph.iter := i;
      setgraphmode(0);
      setcolor(15);
      rectangle(31,0,608,145);
      with mangraph do
        begin
          incrx := (rpart(hilim) - rpart(lolim))/18/scale;
          incry := (ipart(hilim) - ipart(lolim))/9/scale;
          for y := 1 to 9*scale do
            for x := 1 to 18*scale do
              begin
                assignz(offset,(x-0.5)*incrx,(9*scale-y+0.5)*incry);
                addz(z,lolim,offset);
                if isman(z,iter) then
                  for cnty := 1 to 16 div scale do
                    for cntx := 1 to 32 div scale do
                      putpixel(31+cntx+(x-1)*(32 div scale),
                      cnty + (y-1)*(16 div scale),gcolor);
              end;
          xcoord := 18*scale div 2;
          ycoord := 9*scale div 2
        end;
      showcursor(mangraph);
      displayinfo(mangraph)
    end;

  Procedure goleft(var mangraph:mangraphtype);

    begin
      showcursor(mangraph);
      with mangraph do
        if xcoord > 1 then xcoord := xcoord - 1
        else xcoord := 18*scale;
      showcursor(mangraph);
      displayinfo(mangraph)
    end;


  Procedure goright(var mangraph:mangraphtype);

    begin
      showcursor(mangraph);
      with mangraph do
        if xcoord < 18*scale then xcoord := xcoord + 1
        else xcoord := 1;
      showcursor(mangraph);
      displayinfo(mangraph)
    end;

  Procedure goup(var mangraph:mangraphtype);

    begin
      showcursor(mangraph);
      with mangraph do
        if ycoord > 1 then ycoord := ycoord - 1
        else ycoord := 9*scale;
      showcursor(mangraph);
      displayinfo(mangraph)
    end;


  Procedure godown(var mangraph:mangraphtype);

    begin
      showcursor(mangraph);
      with mangraph do
        if ycoord < 9*scale then ycoord := ycoord + 1
        else ycoord := 1;
      showcursor(mangraph);
      displayinfo(mangraph)
    end;

  Procedure getmandlegraph(p:pointer);

    begin
      getimage(31,0,608,145,p^)
    end;

  Procedure putmandlegraph(p:pointer);

    begin
      putimage(31,0,p^,0)
    end;

  Procedure getfromdisk(filename:string;p:pointer;var mangraph:mangraphtype);

  var f:file;
      numread:word;

    begin
      assign(f,filename);
      reset(f,1);
      blockread(f,mangraph,sizeof(mangraph),numread);
      blockread(f,p^,isize,numread);
      close(f)
    end;

  Procedure savetodisk(filename:string;p:pointer;var mangraph:mangraphtype);

  var f:file;
      numwritten:word;

  begin
    assign(f,filename);
    rewrite(f,1);
    blockwrite(f,mangraph,sizeof(mangraph),numwritten);
    blockwrite(f,p^,isize,numwritten);
    close(f)
  end;

  Procedure printmandlegraph(var mangraph:mangraphtype);

    var g:text;
        code,c,cnt,cnt1,cnt2:integer;

    begin
      assign(g,'lpt1');
      rewrite(g);
      for cnt := 1 to 10 do writeln(g);
      write(g,chr(27)+'3'+chr(24));
      write(g,spaces(16));
      write(g,chr(27)+'K'+chr(34)+chr(1));
      for cnt := 1 to 290 do write(g,chr(1));
      writeln(g);
      for cnt := 1 to 18 do
        begin
          write(g,spaces(16));
          write(g,chr(27)+'K'+chr(34)+chr(1));
          write(g,chr(255));
          for cnt1 := 1 to 288 do
            begin
              code := 0;
              for cnt2 := 1 to 8 do
                begin
                  c := getpixel(30+2*cnt1,(cnt-1)*8+cnt2);
                  if c = 0 then code := 2*code
                  else code := 2*code + 1
                end;
              write(g,chr(code))
            end;
          write(g,chr(255));
          writeln(g)
        end;
      write(g,spaces(16));
      write(g,chr(27)+'K'+chr(34)+chr(1));
      for cnt := 1 to 290 do write(g,chr(128));
      writeln(g);
      write(g,chr(27)+'3'+chr(30));
      writeln(g);
      with mangraph do
        write(g,spaces(16)+'RANGE: '+displayz(lolim)+' TO '+displayz(hilim));
      write(g,chr(12));
      close(g)
    end;

  begin
  driver := 9;
  mode := 0;
  initgraph(driver,mode,'');
  isize := Imagesize(31,0,608,145);
  getmem(p,isize);
  done1 := false;
  restorecrtmode;
  repeat
    write('Enter graph file (ENTER for new file): ');
    getinput(filename,escpressed);
    writeln;
    if escpressed then exit;
    if filename = '' then
   begin
    write('Enter real part of lower bound: ');
    getinput(temp,escpressed);
    writeln;
    if escpressed then exit;
    val(temp,rr,code);
    write('Enter imaginary part of lower bound: ');
    getinput(temp,escpressed);
    writeln;
    if escpressed then exit;
    val(temp,ir,code);
    assignz(l,rr,ir);
    write('Enter real part of upper bound: ');
    getinput(temp,escpressed);
    writeln;
    if escpressed then exit;
    val(temp,rr,code);
    write('Enter imaginary part of upper bound: ');
    getinput(temp,escpressed);
    writeln;
    if escpressed then exit;
    val(temp,ir,code);
    assignz(h,rr,ir);
    repeat
      write('Enter graph color (1-15): ');
      getinput(temp,escpressed);
      writeln;
      if escpressed then exit;
      val(temp,g,code);
    until (g > 0) and (g < 16);
    repeat
      write('Enter cursor color (1-15): ');
      getinput(temp,escpressed);
      writeln;
      if escpressed then exit;
      val(temp,c,code);
    until (c > 0) and (c < 16);
    repeat
      write('Enter resolution (0-4): ');
      getinput(temp,escpressed);
      writeln;
      if escpressed then exit;
      val(temp,r,code);
    until (r >= 0) and (r < 5);
    repeat
      write('Enter level of accuracy (1-9999): ');
      getinput(temp,escpressed);
      writeln;
      if escpressed then exit;
      val(temp,i,code);
    until (i > 0) and (i < 10000);
    createmangraph(mangraph,l,h,g,c,r,i);
    success := true;
  end
  else
    begin
      if fileexists(filename) then
        begin
          success := true;
          setgraphmode(0);
          getfromdisk(filename,p,mangraph);
          putmandlegraph(p);
          showcursor(mangraph);
          displayinfo(mangraph)
        end
      else
        begin
          success := false;
          writeln(chr(7)+'Cannot find that file.')
        end
    end;
    if success then
    begin
    done2 := false;
    repeat
      choice := readkey;
      case choice of
        chr(0):begin
                 schoice := readkey;
                 case schoice of
                   chr(45):begin
                             done2 := true;
                             done1 := true
                           end;
                   chr(60):begin
                             showcursor(mangraph);
                             getmandlegraph(p);
                             restorecrtmode;
                             write('Save file as? ');
                             getinput(temp,escpressed);
                             writeln;
                             if not escpressed then
                               begin
                                 response := 'Y';
                                 if fileexists(temp) then
                                   begin
                                     write('That file already exists.  Overwrite<y,n>? ');
                                     readln(response)
                                   end;
                                if response in ['Y','y'] then
                                  begin
                                    if filecreation(temp) then
                                     savetodisk(temp,p,mangraph)
                                    else
                                      begin
                                        write(chr(7)+'File creation error.');
                                        readln
                                       end
                                   end
                               end;
                             setgraphmode(0);
                             putmandlegraph(p);
                             showcursor(mangraph);
                             displayinfo(mangraph)
                           end;
                   chr(67):begin
                             showcursor(mangraph);
                             printmandlegraph(mangraph);
                             showcursor(mangraph)
                           end;
                   chr(68):done2 := true;
                   chr(72):goup(mangraph);
                   chr(75):goleft(mangraph);
                   chr(77):goright(mangraph);
                   chr(80):godown(mangraph)
                 end
               end
      end
    until done2;
    if done1 then closegraph
    else restorecrtmode
   end
  until done1;
  freemem(p,isize)
end.
