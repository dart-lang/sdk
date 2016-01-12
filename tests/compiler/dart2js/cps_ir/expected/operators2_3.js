// Expectation for test: 
// // Method to test: function(foo)
// foo(a) => a % 13;
// main() {
//   print(foo(5));
//   print(foo(-100));
// }

function(a) {
  var result = a % 13;
  return result === 0 ? 0 : result > 0 ? result : 13 < 0 ? result - 13 : result + 13;
}
