unit btree;

interface

  const
    MAXESIZE = 1024;
    ESIZE = 512;

  type
    btarraytype = array[0..MAXESIZE - 1] of byte;

    bptrtype = ^node;

    node = record
      data:btarraytype;
      size:integer;
      next:bptrtype;
      prev:bptrtype
    end;

    btreetype = record
      size:longint;
      posit:longint;
      ofs:longint;
      top:bptrtype;
      cptr:bptrtype
    end;

  Procedure init_btree(var b:btreetype;size:longint;var success:boolean);

  Procedure btree_fromdisk(var b:btreetype;var f:file);

  Procedure btree_todisk(var b:btreetype;var f:file);

  Procedure btree_write(var b:btreetype;x:byte);

  Function btree_read(var b:btreetype):byte;

  Function btree_size(var b:btreetype):longint;

  Function btree_posit(var b:btreetype):longint;

  Procedure btree_insert(var b:btreetype;x:longint;var success:boolean);

  Procedure btree_seek(var b:btreetype; x:longint);

  Procedure btree_del(var b:btreetype;x:longint);

  Procedure destroy_btree(var b:btreetype);

implementation

  {$F+} function heapfunc(size:word):integer; {$F-}

    begin
      heapfunc := 1
    end;

  Function min(x,y:longint):longint;

    begin
      if x < y then min := x
      else min := y
    end;

  Procedure init_btree(var b:btreetype;size:longint;var success:boolean);

    var cnt:longint;
        p,q:bptrtype;
          c:integer;

    begin
      success := true;
      if size <= 0 then
        begin
          success := false;
          exit
        end;
      b.size := size;
      b.ofs := 0;
      b.posit := 0;
      new(b.top);
      if b.top = nil then
        begin
          success := false;
          exit
        end;
      b.cptr := b.top;
      b.top^.prev := nil;
      b.top^.next := nil;
      if size < MAXESIZE then
        begin
          b.top^.size := size
        end
      else
        begin
          b.top^.size := (size mod ESIZE) + ESIZE;
          p := b.top;
          for cnt := 0 to (size - MAXESIZE) div ESIZE do
            begin
              new(q);
              if q = nil then
                begin
                  success := false;
                  while (p <> nil) do
                    begin
                      q := p^.prev;
                      dispose(p);
                      p := q
                    end;
                  exit
                end;
              q^.prev := p;
              p^.next := q;
              q^.next := nil;
              q^.size := ESIZE;
              p := q
            end
        end
    end;


  Procedure btree_fromdisk(var b:btreetype;var f:file);

    var p:bptrtype;
        numread:word;

    begin
      p := b.top;
      seek(f,0);
      while p <> nil do
        begin
          blockread(f,p^.data,p^.size,numread);
          p := p^.next
        end
    end;

  Procedure btree_todisk(var b:btreetype;var f:file);

    var p:bptrtype;
        numwritten:word;

    begin
      p := b.top;
      seek(f,0);
      while p <> nil do
        begin
          blockwrite(f,p^.data,p^.size,numwritten);
          p := p^.next
        end;
      truncate(f)
    end;

  Procedure btree_write(var b:btreetype;x:byte);

    begin
      b.cptr^.data[b.ofs] := x
    end;

  Function btree_read(var b:btreetype):byte;

    begin
      btree_read := b.cptr^.data[b.ofs]
    end;

  Function btree_size(var b:btreetype):longint;

    begin
      btree_size := b.size
    end;


  Function btree_posit(var b:btreetype):longint;

    begin
      btree_posit := b.posit
    end;


  Procedure btree_insert(var b:btreetype;x:longint;var success:boolean);

    var newposit,oldsize,c:integer;
        q,p,r,q1:bptrtype;
        cnt:longint;

    begin
      success := true;
      if x <= 0 then
        begin
          success := false;
          exit
        end;
      if b.cptr^.size + x < MAXESIZE then
        begin
          for c := b.cptr^.size - 1 downto b.ofs do
            b.cptr^.data[c + x] := b.cptr^.data[c];
          for c := 0 to x-1 do
            b.cptr^.data[b.ofs + c] := 0;
          b.cptr^.size := b.cptr^.size + x;
          b.size := b.size + x
        end
      else
        begin
          b.size := b.size + x;
          q := b.cptr^.next;
          q1 := q;
          for cnt := 0 to (b.cptr^.size + x - MAXESIZE) div ESIZE do
            begin
              new(p);
              if p = nil then
                begin
                  success := false;
                  b.size := b.size - x;
                  while (q <> q1) do
                    begin
                      p := q^.next;
                      dispose(q);
                      q := p
                    end;
                  exit
                end;
              if cnt = 0 then r := p;
              p^.size := ESIZE;
              for c := 0 to ESIZE - 1 do p^.data[c] := 0;
              p^.next := q;
              if q <> nil then q^.prev := p;
              p^.prev := b.cptr;
              b.cptr^.next := p;
              q := p
            end;
          oldsize := b.cptr^.size;
          b.cptr^.size := ((b.cptr^.size + x - MAXESIZE) mod ESIZE) + ESIZE;
          newposit := ESIZE - 1;
          for c := oldsize - 1 downto b.ofs do
            begin
              r^.data[newposit] := b.cptr^.data[c];
              if newposit = 0 then
                begin
                  r := r^.prev;
                  newposit := r^.size
                end;
              newposit := newposit - 1
            end;
          if b.ofs - 1 >= b.cptr^.size then
           for c := b.ofs - 1 downto b.cptr^.size do
             b.cptr^.next^.data[c-b.cptr^.size] := b.cptr^.data[c]
          else
            for c := b.ofs to min(b.cptr^.size - 1,b.ofs + x - 1) do
              b.cptr^.data[c] := 0;
          if b.ofs >= b.cptr^.size then
            begin
              b.ofs := b.ofs - b.cptr^.size;
              b.cptr := b.cptr^.next
            end
        end
    end;

  Procedure btree_seek(var b:btreetype; x:longint);

    var tdiff,diff:longint;
        temp:byte;
        success:boolean;

    begin
      if x < 0 then x := 0;
      if x > b.size then x := b.size;
      if x = b.size then
        begin
          btree_seek(b,x-1);
          temp := btree_read(b);
          btree_write(b,0);
          btree_insert(b,1,success);
          btree_write(b,temp);
          if success then btree_seek(b,x)
        end
      else
        begin
          if x > b.posit then
            begin
              diff := x - b.posit;
              while (diff > 0) do
                begin
                  tdiff := min(diff,b.cptr^.size - b.ofs);
                  b.ofs := b.ofs + tdiff;
                  diff := diff - tdiff;
                  if b.ofs = b.cptr^.size then
                    begin
                      b.cptr := b.cptr^.next;
                      b.ofs := 0
                    end
                end
            end
          else
            begin
              diff := b.posit - x;
              while (diff > 0) do
                begin
                  if b.ofs = 0 then
                    begin
                      b.cptr := b.cptr^.prev;
                      b.ofs := b.cptr^.size
                    end;
                  tdiff := min(diff,b.ofs);
                  b.ofs := b.ofs - tdiff;
                  diff := diff - tdiff
                end
            end;
          b.posit := x
        end
    end;

  Procedure comb_btree(p:bptrtype;x:integer);

    var c:integer;
        q:bptrtype;

    begin
      if x = -1 then
        begin
          q := p^.prev;
          for c := p^.size - 1 downto 0 do
            p^.data[c + q^.size] := p^.data[c];
          for c := 0 to q^.size - 1 do
            p^.data[c] := q^.data[c];
          p^.size := p^.size + q^.size;
          q^.prev^.next := p;
          p^.prev := q^.prev;
          dispose(q)
        end
      else
        begin
          q := p^.next;
          for c := 0 to q^.size - 1 do
            p^.data[p^.size + c] := q^.data[c];
          p^.size := p^.size + q^.size;
          q^.next^.prev := p;
          p^.next := q^.next;
          dispose(q)
        end
    end;


  Procedure bal_btree(p:bptrtype;x:integer);

    var c:integer;
        q:bptrtype;

    begin
      if x = - 1 then
        begin
          q := p^.prev;
          for c := p^.size - 1 downto 0 do
            p^.data[c + ESIZE - p^.size] := p^.data[c];
          for c := 0 to ESIZE - p^.size - 1 do
            p^.data[c] := q^.data[q^.size + p^.size - ESIZE + c];
          q^.size := q^.size + p^.size - ESIZE;
          p^.size := ESIZE
        end
      else
        begin
          q := p^.next;
          for c := p^.size to ESIZE - 1 do
            p^.data[c] := q^.data[c - p^.size];
          for c := 0 to q^.size + p^.size - ESIZE - 1 do
            q^.data[c] := q^.data[c + ESIZE - p^.size];
          q^.size := q^.size + p^.size - ESIZE;
          p^.size := ESIZE
        end
    end;


  Procedure btree_del(var b:btreetype;x:longint);

    var diff,tdiff:longint;
        p,q:bptrtype;
        lposit:longint;
        oldsize,c:integer;

    begin
      if x <= 0 then exit;
      if x > b.size - b.posit - 1 then x := b.size - b.posit - 1;
      lposit := b.posit;
      if x < b.cptr^.size - b.ofs then
        begin
          for c := b.ofs to b.cptr^.size - 1 - x do
            b.cptr^.data[c] := b.cptr^.data[c+x];
          b.cptr^.size := b.cptr^.size - x;
          if b.cptr^.size < ESIZE then
            begin
              if b.cptr^.prev <> nil then
                begin
                  if b.cptr^.size + b.cptr^.prev^.size < MAXESIZE then
                    begin
                      if b.cptr^.prev = b.top then b.top := b.cptr;
                      comb_btree(b.cptr,-1)
                    end
                  else bal_btree(b.cptr,-1)
                end
              else if b.cptr^.next <> nil then
                begin
                  if b.cptr^.size + b.cptr^.next^.size < MAXESIZE then
                    comb_btree(b.cptr,1)
                  else bal_btree(b.cptr,1)
                end
            end
        end
      else
        begin
          diff := x;
          if b.ofs > 0 then
            begin
              tdiff := b.cptr^.size - b.ofs;
              b.cptr^.size := b.ofs;
              diff := diff - tdiff;
              b.cptr := b.cptr^.next
            end;
          while (diff > 0) do
            begin
              oldsize := b.cptr^.size;
              tdiff := min(diff, b.cptr^.size);
              b.cptr^.size := b.cptr^.size - tdiff;
              diff := diff - tdiff;
              if b.cptr^.size = 0 then
                begin
                  p := b.cptr^.prev;
                  q := b.cptr^.next;
                  if p = nil then
                    begin
                      b.top := q;
                      q^.prev := nil
                    end
                  else
                    begin
                      p^.next := q;
                      q^.prev := p
                    end;
                  dispose(b.cptr);
                  b.cptr := q
                end
              else
                for c := 0 to b.cptr^.size - 1 do
                  b.cptr^.data[c] := b.cptr^.data[c+oldsize-b.cptr^.size]
            end;
          if b.cptr^.prev <> nil then
            begin
              if b.cptr^.prev^.size + b.cptr^.size < MAXESIZE then
                begin
                  if b.cptr^.prev = b.top then b.top := b.cptr;
                  comb_btree(b.cptr,-1);
                  if b.cptr^.size < ESIZE then
                    begin
                      if b.cptr^.prev <> nil then
                        begin
                          if b.cptr^.size + b.cptr^.prev^.size < MAXESIZE then
                            begin
                              if b.cptr^.prev = b.top then b.top := b.cptr;
                              comb_btree(b.cptr,-1)
                            end
                          else bal_btree(b.cptr,-1)
                        end
                      else if b.cptr^.next <> nil then
                        begin
                          if b.cptr^.size + b.cptr^.next^.size < MAXESIZE then
                            comb_btree(b.cptr,1)
                          else bal_btree(b.cptr,1)
                        end
                    end
                end
              else
                begin
                  if (b.cptr^.prev^.size < ESIZE) then
                    begin
                      b.cptr := b.cptr^.prev;
                      bal_btree(b.cptr,1)
                    end
                  else if b.cptr^.size < ESIZE then bal_btree(b.cptr,-1)
                end
            end
          else if b.cptr^.next <> nil then
            begin
              if b.cptr^.size + b.cptr^.next^.size < MAXESIZE then
                comb_btree(b.cptr,1)
              else bal_btree(b.cptr,1)
            end
        end;
      b.cptr := b.top;
      b.ofs := 0;
      b.posit := 0;
      b.size := b.size - x;
      btree_seek(b,lposit)
    end;

  Procedure destroy_btree(var b:btreetype);

    var p,q:bptrtype;

    begin
      p := b.top;
      while (p <> nil) do
        begin
          q := p^.next;
          dispose(p);
          p := q
        end
    end;

  begin
    heaperror := @heapfunc

end.



