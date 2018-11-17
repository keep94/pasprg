program fcompare;

  type
    arraytype = array[0..65519] of byte;
    ptrtype = ^arraytype;

  var
    p1,p2:ptrtype;
    bufsize,numread:word;
    count,size1,size2:longint;
    desc,code:integer;
    file1,file2:string;
    f,g:file;
    done:boolean;

  Function hex(x:longint):string;

    var dig:longint;
        temp:string;

    begin
      if x <= 0 then
        hex := '0'
      else
        begin
          temp := '';
          repeat
            dig := x mod 16;
            if dig < 10 then temp := chr(48+dig)+temp
            else temp := chr(55+dig)+temp;
            x := x div 16
          until (x = 0);
          hex := temp
        end
    end;


  begin
    file1 := paramstr(1);
    file2 := paramstr(2);
    if paramstr(3) <> '' then
      val(paramstr(3),bufsize,code)
    else
      bufsize := 65520;
    writeln;
    write('Press ENTER begin file compare.');
    readln;
    writeln;
    assign(f,file1);
    assign(g,file2);
    reset(f,1);
    reset(g,1);
    size1 := filesize(f);
    size2 := filesize(g);
    if size1 <> size2 then
      begin
        writeln('Files are of unequal length.');
        exit
      end;
    getmem(p1,bufsize);
    getmem(p2,bufsize);
    desc := 0;
    count := 0;
    done := false;
    while (not done) do
      begin
        if count mod bufsize = 0 then
          begin
            blockread(f,p1^,bufsize,numread);
            blockread(g,p2^,bufsize,numread)
          end;
        if p1^[count mod bufsize] <> p2^[count mod bufsize] then
          begin
            write('Compare error at offset ',count:10,':  ');
            writeln('File 1: '+hex(p1^[count mod bufsize]));
            writeln('                                     File 2: '+hex(p2^[count mod bufsize]));
            desc := desc + 1
          end;
        if desc = 10 then
          begin
            writeln;
            writeln('File compare terminated.');
            done := true
          end;
        count := count + 1;
        if count > size1 - 1 then done := true
      end;
    if desc = 0 then
      writeln('Files compare OK.');
    close(f);
    close(g);
    freemem(p1,bufsize);
    freemem(p2,bufsize)
  end.