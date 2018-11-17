program open;

  var f:file;
      filename:string;

  begin
    write('Open whate file? ');
    readln(filename);
    assign(f,filename);
    rewrite(f,1);
    close(f)
  end.