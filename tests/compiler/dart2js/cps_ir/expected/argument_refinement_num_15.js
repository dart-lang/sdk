// Expectation for test: 
// main() {
//   var x = int.parse('1233');
//   var y = int.parse('1234');
//   var z = int.parse('1236');
//   print(x is num);
//   print(y is num);
//   print(z is num);
//   print(x.clamp(y, z));
//   print(x is num);
//   print(y is num); // will be compiled to `true` if we know the type of `y`.
//   print(z is num);
// }

function() {
  var x = P.int_parse("1233", null, null), y = P.int_parse("1234", null, null), z = P.int_parse("1236", null, null);
  P.print(typeof x === "number");
  P.print(typeof y === "number");
  P.print(typeof z === "number");
  P.print(J.clamp$2$n(x, y, z));
  P.print(true);
  P.print(true);
  P.print(true);
}
