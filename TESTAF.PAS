program testaf;

uses afstore;

var af:afstoretype;
    match:string;
    pattern:string;
    found:boolean;
begin
  afstore_init(af,20);
  afstore_add(af,'solong');
  afstore_add(af,'goodbye');
  afstore_add(af,'hello');
  pattern := 'g';
  found := afstore_search(af,pattern,match);
  writeln('found: ',found);
  writeln('Match: '+match);
  readln
end.