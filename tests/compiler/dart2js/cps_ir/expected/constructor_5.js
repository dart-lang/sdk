// Expectation for test: 
// foo(x) {
//   print(x);
// }
// class Base {
//   var x1 = foo('x1');
//   var x2;
//   var x3 = foo('x3');
//   Base() : x2 = foo('x2');
// }
// class Sub extends Base {
//   var y1 = foo('y1');
//   var y2;
//   var y3;
//   Sub() : y2 = foo('y2'), super(), y3 = foo('y3');
// }
// main() {
//   new Sub();
// }

function() {
  V.foo("y1");
  V.foo("y2");
  V.foo("x1");
  V.foo("x3");
  V.foo("x2");
  V.foo("y3");
}
