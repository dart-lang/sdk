void foo() {
  var record1 = (1, 2, a: 3, b: 4);
  var record2 = (1, a: 2, 3, b: 4);
  print(record2.$1); // Prints "1".
  print(record2.a);  // Prints "2".
  print(record2.$2); // Prints "3".
  print(record2.b);  // Prints "4".
}
