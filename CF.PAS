program cf;

  uses crt,IOunit;

  type
    arraytype = array[0..65519] of byte;
    ptrtype = ^arraytype;

  var
    oldfilename,newfilename,temp:string;
    escpressed,deletebytes,error:boolean;
    recordsize,newrecordsize,numread,numwritten,start,numbytes,cnt:word;
    p:ptrtype;
    f,g:file;
    code:integer;
    response:char;

  begin
    write('Enter file with records to be modified: ');
    getinput(oldfilename,escpressed);
    writeln;
    if escpressed then exit;
    if not fileexists(oldfilename) then
      begin
        writeln;
        writeln('Cannot find that file.');
        exit
      end;
    write('Enter recordsize: ');
    getinput(temp,escpressed);
    writeln;
    if escpressed then exit;
    val(temp,recordsize,code);
    if not filevalid(oldfilename,recordsize) then
      begin
        writeln;
        writeln('The record size selected is incorrect.');
        exit
      end;
    write('Enter file that will hold modified records: ');
    getinput(newfilename,escpressed);
    writeln;
    if escpressed then exit;
    if fileexists(newfilename) then
      begin
        write('That file already exits.  Overwrite<y,n>? ');
        readln(response);
        if not (response in ['Y','y']) then exit
      end;
    if not filecreation(newfilename) then
      begin
        writeln;
        writeln('File creation error.');
        exit
      end;
    write('Insert or delete bytes<i,d>? ');
    getinput(temp,escpressed);
    writeln;
    if escpressed then exit;
    if length(temp) > 0 then deletebytes := temp[1] in ['D','d']
    else deletebytes := false;
    write('Starting position: ');
    getinput(temp,escpressed);
    writeln;
    if escpressed then exit;
    val(temp,start,code);
    if start > recordsize then start := recordsize;
    write('Number of bytes: ');
    getinput(temp,escpressed);
    writeln;
    if escpressed then exit;
    val(temp,numbytes,code);
    assign(f,oldfilename);
    assign(g,newfilename);
    reset(f,1);
    rewrite(g,1);
    error := false;
    if deletebytes then
      begin
        if numbytes > recordsize - start then numbytes := recordsize - start;
        getmem(p,recordsize);
        newrecordsize := recordsize - numbytes
      end
    else
      begin
        if numbytes > 65520 - recordsize then numbytes := 65520 - recordsize;
        newrecordsize := recordsize + numbytes;
        getmem(p,newrecordsize)
      end;
    while (not eof(f)) and (not error) do
      begin
        blockread(f,p^,recordsize,numread);
        if deletebytes then
          for cnt := start to recordsize - numbytes - 1 do
            p^[cnt] := p^[cnt + numbytes]
        else
          begin
            for cnt := recordsize - 1 downto start do
              p^[cnt + numbytes] := p^[cnt];
            for cnt := start to start + numbytes - 1 do
              p^[cnt] := 0
          end;
        blockwrite(g,p^,newrecordsize,numwritten);
        if numwritten < newrecordsize then error := true
      end;
    if deletebytes then
      freemem(p,recordsize)
    else
      freemem(p,newrecordsize);
    if error then
      begin
        writeln;
        writeln('Insufficient disk space.')
      end
  end.