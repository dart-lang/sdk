// Expectation for test: 
// foo(a, b) => ((a & 0xff0000) >> 1) & b;
// main() {
//   print(foo(123, 234));
//   print(foo(0, 2));
// }

function() {
  P.print((123 & 16711680) >>> 1 & 234);
  P.print((0 & 16711680) >>> 1 & 2);
}
