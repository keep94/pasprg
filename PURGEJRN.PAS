program purgejrn;

uses crt,journent,iounit,lstr;

var oldfile,newfile:journalfiletype;
    je:journalentrytype;
    content:longstr;
    password:string;
    escpressed:boolean;
    oldposit,newposit:longint;
    maxposit:longint;
    oldname,newname:string;

begin
  oldname := paramstr(1);
  newname := paramstr(2);
  lstrinit(content);
  if not fileexists(oldname) then
    begin
      writeln('Cannot find source file.');
      halt(1)
    end;

  clrscr;
  write('Enter password: ');
  passinput(password,20,false,escpressed);
  writeln;
  if (not escpressed) then
    begin
      if (journentfileopen(oldfile,oldname,password)) then
        begin
          if not filecreation(newname) then
            begin
              writeln('Cannot create destination file.');
              halt(1)
            end;
          journentfilecreate(newname,password);
          if (not journentfileopen(newfile,newname,password)) then
            begin
              writeln('A serious error happened opening destination file');
              halt(0)
            end;
          maxposit := filesize(oldfile.f);
          oldposit := JOURNENT_FIRST_REC;
          newposit := JOURNENT_FIRST_REC;
          while (oldposit < maxposit) do
            begin
              journentfilegetall(oldfile,oldposit,je,content);
              oldposit := oldposit + je.blockextent;
              if (not journentisdeleted(je)) then
                begin
                  je.blockextent := sizeof(journalentrytype);
                  je.blockextent := je.blockextent + sizeof(word);
                  je.blockextent := je.blockextent + lstrlen(content);
                  journentfilesaveall(newfile,newposit,je,content);
                  newposit := newposit + je.blockextent
                end
            end;
          journentfileclose(newfile);
          journentfileclose(oldfile)
        end
      else
        begin
          writeln('Invalid password.')
        end
    end;
  lstrdestroy(content)
end.