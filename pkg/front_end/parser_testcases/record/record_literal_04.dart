void foo() {
  // OK.
  var r1 = const (42, );
  var r2 = const (1, 2, a: 3, b: 4);
  var r3 = const (1, a: 2, 3, b: 4);
  var r4 = const (hello: 42);

  // Error: Const makes it a record (I guess), but there's no trailing comma.
  var r5 = const (42);

  // Error: A record needs at least one element.
  var r6 = const ();
}

void bar({dynamic record1 = (42, 42), dynamic record2 = const (42, 42)}) {
  // Default record.
}
