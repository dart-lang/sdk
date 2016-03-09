// Expectation for test: 
// main() {
//   var x = int.parse('1233');
//   var y = int.parse('1234');
//   print(x / 2);
//   print(x is num);
//   print(y is num);
//   print(x.compareTo(y));
//   print(y is num);
// }

function() {
  var x = P.int_parse("1233", null, null), y = P.int_parse("1234", null, null), v0;
  if (typeof x !== "number")
    return x.$div();
  P.print(x / 2);
  P.print(true);
  v0 = typeof y === "number";
  P.print(v0);
  if (!v0)
    throw H.wrapException(H.argumentErrorValue(y));
  P.print(x < y ? -1 : x > y ? 1 : x === y ? x === 0 ? 1 / x < 0 === (y === 0 ? 1 / y < 0 : y < 0) ? 0 : 1 / x < 0 ? -1 : 1 : 0 : isNaN(x) ? isNaN(y) ? 0 : 1 : -1);
  P.print(true);
}
