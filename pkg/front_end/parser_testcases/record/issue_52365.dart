void main() {
  var f0 = () => print("hello");

  f0 > 42;
  (() => print("hello")) > 42;

  f0 >> 42;
  (() => print("hello")) >> 42;

  f0 >>> 42;
  (() => print("hello")) >>> 42;

  var f1 = (x) => print("hello $x");

  f1 > 42;
  ((x) => print("hello $x")) > 42;

  f1 >> 42;
  ((x) => print("hello $x")) >> 42;

  f1 >>> 42;
  ((x) => print("hello $x")) >>> 42;

  var f2 = (x, y) => print("hello $x $y");

  f2 > 42;
  ((x, y) => print("hello $x $y")) > 42;

  f2 >> 42;
  ((x, y) => print("hello $x $y")) >> 42;

  f2 >>> 42;
  ((x, y) => print("hello $x $y")) >>> 42;

  // Records
  (() => print("hello"), ) > 42;
  (() => print("hello"), ) >> 42;
  (() => print("hello"), ) >>> 42;
  (() => print("hello"), () => print("hello")) > 42;
  (() => print("hello"), () => print("hello")) >> 42;
  (() => print("hello"), () => print("hello")) >>> 42;
}

extension FunctionExtension on Function {
  operator>(dynamic x) {
    print("You did > with '$x' on '$this' (Function)");
  }
  operator>>(dynamic x) {
    print("You did >> with '$x' on '$this' (Function)");
  }
  operator>>>(dynamic x) {
    print("You did >>> with '$x' on '$this' (Function)");
  }
}

extension RecordExtension on Record {
  operator>(dynamic x) {
    print("You did > with '$x' on '$this' (Record)");
  }
  operator>>(dynamic x) {
    print("You did >> with '$x' on '$this' (Record)");
  }
  operator>>>(dynamic x) {
    print("You did >>> with '$x' on '$this' (Record)");
  }
}