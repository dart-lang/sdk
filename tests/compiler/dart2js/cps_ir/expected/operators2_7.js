// Expectation for test: 
// // Method to test: function(foo)
// foo(a) => a ~/ 13;
// main() {
//   print(foo.toString());
//   print(foo(5));
//   print(foo(100));
// }

function(a) {
  return a / 13 | 0;
}
