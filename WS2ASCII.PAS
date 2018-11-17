program ws2ascii;

  uses IOunit;

  type arraytype = array[1..65520] of byte;

  var
    temp,oldfile,newfile:string;
    maxmem:word;
    escpressed,filevalid:boolean;
    code:integer;
    response:char;

  Procedure convert(var oldf,newf:string;maxmem:word);

    var f,g:file;
        p:^arraytype;
        numread,numwritten,cnt:word;


    begin
      getmem(p,maxmem);
      assign(f,oldf);
      reset(f,1);
      assign(g,newf);
      rewrite(g,1);
      while not eof(f) do
        begin
          blockread(f,p^,maxmem,numread);
          for cnt := 1 to numread do
            if (p^[cnt] >= 128) then p^[cnt] := p^[cnt] - 128;
          blockwrite(g,p^,numread,numwritten);
          if numwritten < numread then
            begin
              writeln(chr(7)+'Disk full.');
              close(f);
              close(g);
              halt
            end
        end;
      close(f);
      close(g);
      freemem(p,maxmem)
    end;


  begin
    if paramstr(1) <> '' then
      begin
        val(paramstr(1),maxmem,code);
        if (maxmem < 1) or (maxmem > 65520) then maxmem := 65520
      end
    else maxmem := 65520;
    repeat
      write('Enter name of file to convert: ');
      getinput(temp,escpressed);
      writeln;
      writeln;
      if escpressed then exit;
      filevalid := fileexists(temp);
      if not filevalid then
        begin
          writeln(chr(7)+'Cannot find that file.');
          writeln
        end
    until filevalid;
    oldfile := temp;
    repeat
      write('Store converted text to: ');
      getinput(temp,escpressed);
      writeln;
      writeln;
      if escpressed then exit;
      response := 'Y';
      if fileexists(temp) then
        begin
          write('That file already exists.  Overwrite<y,n>? ');
          readln(response);
          writeln
        end;
      if response in ['Y','y'] then
        begin
          filevalid := filecreation(temp);
          if not filevalid then
            begin
              writeln(chr(7)+'File creation error.');
              writeln
            end
        end
      else filevalid := false
    until filevalid;
    newfile := temp;
    write('Converting. . .');
    convert(oldfile,newfile,maxmem);
    writeln;
    writeln;
    writeln('Coversion completed.')
  end.

