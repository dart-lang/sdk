foo(x) {
  print(x);
}
class Base {
  var x1 = foo('x1');
  var x2;
  var x3 = foo('x3');
  Base() : x2 = foo('x2');
}
class Sub extends Base {
  var y1 = foo('y1');
  var y2;
  var y3;
  Sub() : y2 = foo('y2'), super(), y3 = foo('y3');
}
main() {
  new Sub();
}

