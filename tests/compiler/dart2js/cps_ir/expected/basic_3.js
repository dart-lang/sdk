// Expectation for test: 
// foo(a) {
//   print(a);
//   return a;
// }
// main() {
//   var a = 10;
//   var b = 1;
//   var t;
//   t = a;
//   a = b;
//   b = t;
//   print(a);
//   print(b);
//   print(b);
//   print(foo(a));
// }

function() {
  P.print(1);
  P.print(10);
  P.print(10);
  P.print(1);
  P.print(1);
}
