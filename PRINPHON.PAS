program printit;

  type
    rectype = record
      marked:boolean;
      groups:array[1..5] of byte;
      dorm:string[12];
      room:string[3];
      phone:string[8]
    end;

    filetype = file of rectype;

  var
    f:filetype;
    g:text;
    filename,temp:string;
    start,numprint,numonpage,posit:longint;
    code:integer;
    line60:boolean;
    response:char;

  Function spaces(x:integer):string;

    var cnt:integer;
        temp:string;

    begin
      temp := '';
      for cnt := 1 to x do
        temp := temp + ' ';
      spaces := temp
    end;



  Procedure printpage(var f:filetype;var g:text;posit:longint;n:integer;line60:boolean);

    type arraytype = array[0..199] of rectype;

    var x:arraytype;
        cnt,cnt1,colincr:integer;

    begin
      seek(f,posit);
      for cnt := 0 to n - 1 do
        read(f,x[cnt]);
      for cnt := n to 199 do
        begin
          x[cnt].dorm := '';
          x[cnt].room := '';
          x[cnt].phone := ''
        end;
      colincr := (n - 1) div 3 + 1;
      for cnt := 0 to colincr - 1 do
        begin
          for cnt1 := 0 to 2 do
            write(g,x[cnt+cnt1*colincr].dorm+' '+x[cnt+cnt1*colincr].room+
            spaces(16 - length(x[cnt+cnt1*colincr].dorm)
            - length(x[cnt+cnt1*colincr].room))+x[cnt+cnt1*colincr].phone+' ');
          writeln(g)
        end;
      if line60 then for cnt := colincr to 59 do
        writeln(g)
      else for cnt := colincr to 65 do
        writeln(g)
    end;



  begin
    write('60 lines<y,n>: ');
    readln(response);
    line60 := response in ['Y','y'];
    write('Enter file name: ');
    readln(filename);
    assign(f,filename);
    reset(f);
    write('Print from record [0 is first record]: ');
    readln(temp);
    val(temp,start,code);
    if start < 0 then start := 0;
    if start >= filesize(f) then start := filesize(f) - 1;
    if start = -1 then
      begin
        writeln(chr(7)+'File is empty');
        close(f);
        exit
      end;
    write('Number of records to print: ');
    readln(temp);
    val(temp,numprint,code);
    if numprint < 0 then numprint := 0;
    if start + numprint > filesize(f) then numprint := filesize(f) - start;
    posit := start;
    assign(g,'lpt1');
    rewrite(g);
    while (posit < start + numprint) do
      begin
        if line60 then numonpage := 180
        else numonpage := 198;
        if (numonpage > start + numprint - posit) then
          numonpage := start + numprint - posit;
        printpage(f,g,posit,numonpage,line60);
        posit := posit + numonpage
      end;
    close(g);
    close(f)
  end.