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
  var x = P.int_parse("1233", null, null), y = P.int_parse("1234", null, null), v0 = typeof y === "number";
  P.print(J.$div$n(x, 2));
  P.print(true);
  P.print(v0);
  if (!v0)
    throw H.wrapException(H.argumentErrorValue(y));
  P.print(x + y);
  P.print(true);
}
