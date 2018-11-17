program settime;

  uses dos;

  var dt:datetime;
      time:longint;
      f:file;
      filename:string;

  begin
    write('Enter file to change time of: ');
    readln(filename);
    writeln;
    write('Enter year: ');
    readln(dt.year);
    write('Enter month: ');
    readln(dt.month);
    write('Enter day: ');
    readln(dt.day);
    write('Enter hour: ');
    readln(dt.hour);
    write('Enter minute: ');
    readln(dt.min);
    dt.sec := 0;
    packtime(dt,time);
    assign(f,filename);
    reset(f,1);
    setftime(f,time);
    close(f)
  end.