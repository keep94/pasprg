program lstrtest;

uses lstred,lstr,crt;

var led:lstredittype;
    buffer:longstr;
    g:file;
    s:string;
    choice,schoice:char;
    numread:word;

begin
  clrscr;
  lstredinit(led);
  led.cset := [];
  led.sset := [60];
  led.toplineno := 0;
  led.posit := 0;
  led.topscrrow := 3;
  led.displaylinecount := 5;

  lstrinit(buffer);

  assign(g,'lstrtest.txt');
  reset(g,1);
  lstradjustforsize(buffer,filesize(g));
  blockread(g,buffer.ptr^,filesize(g),numread);
  buffer.size := filesize(g);
  close(g);

  lstrededit(led,buffer,choice,schoice);

  assign(g,'lstrtest.txt');
  rewrite(g,1);
  blockwrite(g,buffer.ptr^,buffer.size,numread);
  close(g);
  lstrdestroy(buffer);
  lstreddestroy(led)
end.  