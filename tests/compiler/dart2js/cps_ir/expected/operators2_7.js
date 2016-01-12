// Expectation for test: 
// foo(a) => a ~/ 13;
// main() {
//   print(foo(5));
//   print(foo(100));
// }

function() {
  P.print(5 / 13 | 0);
  P.print(100 / 13 | 0);
}
