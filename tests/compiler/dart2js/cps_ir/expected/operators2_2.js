// Expectation for test: 
// foo(a) => ~a;
// main() {
//   print(foo(1));
//   print(foo(10));
// }

function() {
  P.print(~1 >>> 0);
  P.print(~10 >>> 0);
}
