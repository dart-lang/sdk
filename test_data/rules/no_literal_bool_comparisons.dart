class TestClass {
  bool x = false;
}

void foo() {
  var x = false;
  if (x == true) // LINT
  {
    print('oh');
  }
  var f = true;
  while (true == f) // LINT
  {
    print('oh');
    f = false;
  }

  var c = TestClass();
  if (c.x == true) // LINT
  {
    print('oh');
  }

  print((x && f) != true); // LINT
  print(x && (f != true)); // LINT
}

void bar(bool x, bool? y) {
  print(x == true); // LINT
  print(x != true); // LINT
  print(y == true); // OK

  if (x && true) print('oh'); // OK
}
