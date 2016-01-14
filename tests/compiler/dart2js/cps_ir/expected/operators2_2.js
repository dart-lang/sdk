// Expectation for test: 
// // Method to test: function(foo)
// foo(a) => ~a;
// main() {
//   print(foo.toString());
//   print(foo(1));
//   print(foo(10));
// }

function(a) {
  return ~a >>> 0;
}
