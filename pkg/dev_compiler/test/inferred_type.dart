class A {
  int x = 2;
}

test1() {
  var a = new A();
  print(a.x);
}

test2() {
  var a = new A();
  print(a.x + 2);
}

test3() {
  int x = 3;
  x = "hi"; // invalid, declared type is `int`.
}

test4() {
  var x = 3;
  x = "hi"; // invalid, inferred type is `int`.
}

test5() {
  var a = new A();
  a.x = "hi"; // invalid, declared type is `int`.
}
