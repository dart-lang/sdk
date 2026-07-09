void foo() {
  // Record: 1 record entry with trailing comma.
  var r1 = (42, );

  // Record: 1 named record entry without trailing comma.
  var r2 = (hello: 42);

  // Record: 1 named record entry with trailing comma.
  var r3 = (hello: 42, );

  // Not records: In parenthesis without trailing comma.
  var r4 = (42);
}
