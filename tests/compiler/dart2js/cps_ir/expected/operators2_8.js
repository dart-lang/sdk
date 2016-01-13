// Expectation for test: 
// // Method to test: function(foo)
// foo(a) => a ~/ 13;
// main() {
//   print(foo(5));
//   print(foo(8000000000));
// }

function(a) {
  return (a | 0) === a && (13 | 0) === 13 ? a / 13 | 0 : C.JSNumber_methods.toInt$0(a / 13);
}
