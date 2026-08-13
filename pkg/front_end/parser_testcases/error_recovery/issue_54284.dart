var x = throw 0..isEven;

void foo() {
  var x;
  print(x = throw 0..isEven);
}

class A {
  var x;
  A() : x = throw 1.isEven;
  A() : this.x = throw 2.isEven;
}

class A {
  var x;
  A() : x = (throw 3..isEven);
  A() : this.x = (throw 4..isEven);
}

class A {
  var x;
  A() : x = throw 5..isEven;
  A() : this.x = throw 6..isEven;
}
