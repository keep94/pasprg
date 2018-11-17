program wordhunt;

uses iounit;

const
  MAXSIZE = 39;
  MAXWORDS = 80;

type
  wordhunttype = record
    width:integer;
    height:integer;
    letters:array[0..MAXSIZE-1,0..MAXSIZE-1] of char;
    freq:array['A'..'Z'] of integer;
  end;

var temp:string;
    error,i,count,code:integer;
    width,height,x,y,direction:integer;
    wordlist:array[0..MAXWORDS-1] of string[18];
    escpressed:boolean;
    g:text;
    w:wordhunttype;

Procedure MakeAtoZ(var temp:string);

var i,len:integer;

begin
  len := length(temp);
  for i := 1 to len do
    begin
      temp[i] := chr(ord(temp[i]) and 95);
      if (temp[i] > 'Z') then
        temp[i] := 'Z'
      else if (temp[i] < 'A') then
        temp[i] := 'A'
    end
end;


Procedure wordhuntinit(var w:wordhunttype;wd,ht:integer);

  var i,j:integer;
      k:char;

  begin
    randomize;
    for i := 0 to wd-1 do
      for j := 0 to ht-1 do
        w.letters[i,j] := ' ';
    w.width := wd;
    w.height := ht;
    for k := 'A' to 'Z' do
      w.freq[k] := 0;
  end;

Function wordhuntplacevalid(var w:wordhunttype;var newstr:string;
         x,y,direction:integer):boolean;

  var temp:boolean;
      len:integer;
      i:integer;

  begin
    len := length(newstr);
    case direction of
      0:begin
          if y < len-1 then
            temp := false
          else
            begin
              i := 0;
              temp := true;
              while (temp) and (i < len) do
                begin
                  temp := (w.letters[x,y-i] = ' ') or
                     (w.letters[x,y-i] = newstr[i+1]);
                  i := i + 1
                end
            end
        end;
      1:begin
          if (y < len-1) or (x > w.width - len) then
            temp := false
          else
            begin
              i := 0;
              temp := true;
              while (temp) and (i < len) do
                begin
                  temp := (w.letters[x+i,y-i] = ' ') or
                     (w.letters[x+i,y-i] = newstr[i+1]);
                  i := i + 1
                end
            end
        end;
      2:begin
          if (x > w.width - len) then
            temp := false
          else
            begin
              i := 0;
              temp := true;
              while (temp) and (i < len) do
                begin
                  temp := (w.letters[x+i,y] = ' ') or
                     (w.letters[x+i,y] = newstr[i+1]);
                  i := i + 1
                end
            end
        end;
      3:begin
          if (x > w.width - len) or (y > w.height - len) then
            temp := false
          else
            begin
              i := 0;
              temp := true;
              while (temp) and (i < len) do
                begin
                  temp := (w.letters[x+i,y+i] = ' ') or
                     (w.letters[x+i,y+i] = newstr[i+1]);
                  i := i + 1
                end
            end
        end;
      4:begin
          if (y > w.height - len) then
            temp := false
          else
            begin
              i := 0;
              temp := true;
              while (temp) and (i < len) do
                begin
                  temp := (w.letters[x,y+i] = ' ') or
                     (w.letters[x,y+i] = newstr[i+1]);
                  i := i + 1
                end
            end
        end;
      5:begin
          if (x < len-1) or (y > w.height - len) then
            temp := false
          else
            begin
              i := 0;
              temp := true;
              while (temp) and (i < len) do
                begin
                  temp := (w.letters[x-i,y+i] = ' ') or
                     (w.letters[x-i,y+i] = newstr[i+1]);
                  i := i + 1
                end
            end
        end;
      6:begin
          if (x < len-1) then
            temp := false
          else
            begin
              i := 0;
              temp := true;
              while (temp) and (i < len) do
                begin
                  temp := (w.letters[x-i,y] = ' ') or
                     (w.letters[x-i,y] = newstr[i+1]);
                  i := i + 1
                end
            end
        end;
      7:begin
          if (x < len-1) or (y < len-1) then
            temp := false
          else
            begin
              i := 0;
              temp := true;
              while (temp) and (i < len) do
                begin
                  temp := (w.letters[x-i,y-i] = ' ') or
                     (w.letters[x-i,y-i] = newstr[i+1]);
                  i := i + 1
                end
            end
        end
    end;
    wordhuntplacevalid := temp
  end;


Procedure wordhuntplaceword(var w:wordhunttype;var newstr:string;
         x,y,direction:integer);

  var len:integer;
      i:integer;

  begin
    len := length(newstr);
    for i := 0 to len-1 do
      begin
        case direction of
          0:w.letters[x,y-i] := newstr[i+1];
          1:w.letters[x+i,y-i] := newstr[i+1];
          2:w.letters[x+i,y] := newstr[i+1];
          3:w.letters[x+i,y+i] := newstr[i+1];
          4:w.letters[x,y+i] := newstr[i+1];
          5:w.letters[x-i,y+i] := newstr[i+1];
          6:w.letters[x-i,y] := newstr[i+1];
          7:w.letters[x-i,y-i] := newstr[i+1]
        end;
        w.freq[newstr[i+1]] := w.freq[newstr[i+1]]+1
      end
  end;


Function wordhuntadd(var w:wordhunttype;newstr:string;
         var x,y:integer;var direction:integer):boolean;

  var done:boolean;
      len:integer;
      temp:boolean;
      counter:integer;

  begin
    len := length(newstr);
    if (len > w.width) and (len > w.height) then
      temp := false
    else
      begin
        counter := 0;
        done := false;
        repeat
          x := random(w.width);
          y := random(w.height);
          direction := random(8);
          if wordhuntplacevalid(w,newstr,x,y,direction) then
            begin
              done := true;
              wordhuntplaceword(w,newstr,x,y,direction)
            end
          else
            counter := counter + 1
        until (counter > 10000) or done;
        temp := done
      end;
    wordhuntadd := temp
  end;

Procedure wordhuntfillrest(var w:wordhunttype);

  var i,j:integer;
      k:char;
      total:integer;
      seed:integer;
      fill:char;

  begin
    total := 0;
    for k := 'A' to 'Z' do
      total := total + w.freq[k];

    for i := 0 to w.width-1 do
      for j := 0 to w.height-1 do
        begin
          if (w.letters[i,j] = ' ') then
            begin
              seed := random(total);
              fill := 'A';
              while (fill < 'Z') and (seed >= w.freq[fill]) do
                begin
                  seed := seed - w.freq[fill];
                  fill := succ(fill)
                end;
              w.letters[i,j] := fill
            end
        end
  end;

Procedure wordhuntprint(var g:text;var w:wordhunttype);

  var i,j:integer;

  begin
    for i := 0 to w.height-1 do
      begin
        for j := 0 to w.width-1 do
          write(g,w.letters[j,i]:2);
        writeln(g)
      end
  end;




begin
  write('Enter output file: ');
  getinput(temp,escpressed);
  writeln;
  if escpressed then
    halt(0);
  assign(g,temp);
  {$I-}
    rewrite(g);
  {$I+}
  error := IOresult;
  if error <> 0 then
    begin
      writeln('Error writing to output file');
      halt(1)
    end;
  write('Enter number of columns: ');
  getinput(temp,escpressed);
  writeln;
  if escpressed then
    halt(0);
  val(temp,width,code);
  write('Enter number of rows: ');
  getinput(temp,escpressed);
  writeln;
  if escpressed then
    halt(0);
  val(temp,height,code);
  wordhuntinit(w,width,height);
  count := 0;
  repeat
    write('Enter a word or press ESC: ');
    getinput(temp,escpressed);
    writeln;
    if not escpressed then
      begin
        makeAtoZ(temp);
        if not wordhuntadd(w,temp,x,y,direction) then
          writeln('Cannot add ',temp,' to puzzle.')
        else
          begin
            wordlist[count] := temp;
            count := count + 1
          end
      end
  until (escpressed) or (count >= MAXWORDS);
  wordhuntfillrest(w);
  wordhuntprint(g,w);
  writeln(g);
  for i := 0 to count-1 do
    begin
      write(g,wordlist[i]:19);
      if (i+1) mod 4 = 0 then
        writeln(g)
    end;
  if i mod 4 <> 0 then
    writeln(g);
  write(g,chr(12));
  close(g)
end.
