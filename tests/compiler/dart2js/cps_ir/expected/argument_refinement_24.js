// Expectation for test: 
// main() {
//   var x = int.parse('1233');
//   var y = int.parse('1234');
//   print(x is int);
//   print(y is int);
//   print(x.modInverse(y));
//   print(x is int);
//   print(y is int);
// }

function() {
  var x = P.int_parse("1233", null, null), y = P.int_parse("1234", null, null);
  P.print(typeof x === "number" && Math.floor(x) === x);
  P.print(typeof y === "number" && Math.floor(y) === y);
  P.print(J.modInverse$1$i(x, y));
  P.print(true);
  P.print(true);
}
