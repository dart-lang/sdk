// Expectation for test: 
// main() {
//   var x = int.parse('1233');
//   var y = int.parse('1234');
//   print(x / 2);
//   print(x is num);
//   print(y is num);
//   print(x + y);
//   print(y is num);
// }

function() {
  var x = P.int_parse("1233", null, null), y = P.int_parse("1234", null, null);
  if (typeof x !== "number")
    return x.$div();
  P.print(x / 2);
  P.print(true);
  P.print(typeof y === "number");
  if (typeof y !== "number")
    return H.iae(y);
  P.print(x + y);
  P.print(true);
}
