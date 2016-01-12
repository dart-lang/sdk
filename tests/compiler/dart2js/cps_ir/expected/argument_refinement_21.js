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
  var x = P.int_parse("1233", null, null), y = P.int_parse("1234", null, null), v0 = typeof y === "number";
  P.print(J.$div$n(x, 2));
  P.print(true);
  P.print(v0);
  if (!v0)
    throw H.wrapException(H.argumentErrorValue(y));
  if (x < y)
    v0 = -1;
  else if (x > y)
    v0 = 1;
  else if (x === y) {
    v0 = x === 0;
    v0 = v0 ? (y === 0 ? 1 / y < 0 : y < 0) === (v0 ? 1 / x < 0 : x < 0) ? 0 : (v0 ? 1 / x < 0 : x < 0) ? -1 : 1 : 0;
  } else
    v0 = isNaN(x) ? isNaN(y) ? 0 : 1 : -1;
  P.print(v0);
  P.print(true);
}
