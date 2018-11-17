program transfer;

  type
    oldrectype = record
      marked:boolean;
      date:string[8];
      cat:string[4];
      name:string[15];
      description:string[50];
      amt:string[10];
      payment:string[4];
      t:string[1]
    end;

    newrectype = record
      marked:boolean;
      date:string[8];
      cat:string[4];
      payment:string[4];
      amt:string[10];
      t:string[1];
      name:string[15];
      description:string[50]
    end;

  var oldrec:oldrectype;
      newrec:newrectype;
      f:file of oldrectype;
      g:file of newrectype;
      oldfilename,newfilename:string;

  begin
    readln(oldfilename);
    readln(newfilename);
    assign(f,oldfilename);
    assign(g,newfilename);
    reset(f);
    rewrite(g);
    while not eof(f) do
      begin
        read(f,oldrec);
        newrec.marked := oldrec.marked;
        newrec.date := oldrec.date;
        newrec.cat := oldrec.cat;
        newrec.name := oldrec.name;
        newrec.description := oldrec.description;
        newrec.amt := oldrec.amt;
        newrec.payment := oldrec.payment;
        newrec.t := oldrec.t;
        write(g,newrec)
      end;
    close(f);
    close(g)
  end.
