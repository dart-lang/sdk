// Expectation for test: 
// main() {
//   var x = int.parse('1233');
//   var y = int.parse('1234');
//   var z = int.parse('1235');
//   print(x is int);
//   print(y is int);
//   print(z is int);
//   print(x.modPow(y, z));
//   print(x is int);
//   print(y is int);
//   print(z is int);
// }

function() {
  var x = P.int_parse("1233", null, null), y = P.int_parse("1234", null, null), z = P.int_parse("1235", null, null);
  P.print(typeof x === "number" && Math.floor(x) === x);
  P.print(typeof y === "number" && Math.floor(y) === y);
  P.print(typeof z === "number" && Math.floor(z) === z);
  P.print(J.modPow$2$i(x, y, z));
  P.print(true);
  P.print(true);
  P.print(true);
}
