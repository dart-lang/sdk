// Expectation for test: 
// main() {
//   var x = int.parse('1233');
//   var y = int.parse('1234');
//   print(x is num);
//   print(y is num);
//   print(x - y);
//   print(x is num);
//   print(y is num); // will be compiled to `true` if we know the type of `y`.
// }

function() {
  var x = P.int_parse("1233", null, null), y = P.int_parse("1234", null, null);
  P.print(typeof x === "number");
  P.print(typeof y === "number");
  if (typeof x !== "number" || typeof y !== "number")
    return J.$sub$n(x, y);
  P.print(x - y);
  P.print(true);
  P.print(true);
}
