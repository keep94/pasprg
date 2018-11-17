uses dates;

  var
    x:integer;
    m,d,y:integer;

begin
  writeln('Today is: ',dateval('03/14/02'));
  x := dateval('03/14/02');
  writeln('today is: ',datestr(x));
  unpackit(x,m,d,y);
  writeln('month: ',m,' day: ',d,' year: ',y);
  writeln('TODAY IS: ',packit(m,d,y));
  readln;
end.