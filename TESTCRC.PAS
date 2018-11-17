program test;

uses crc;

var s:string;

begin
  write('Enter a string: ');
  readln(s);
  writeln(crc32(s,245893123));
  readln;
end.