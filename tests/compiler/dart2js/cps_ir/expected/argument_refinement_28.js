// Expectation for test: 
// import 'dart:math';
// main() {
//   var x = int.parse('3');
//   var y = int.parse('1234');
//   var z = int.parse('1236');
//   var w = int.parse('2');
//   print(x is num);
//   print(sin(x));
//   print(x is num);
// 
//   print(y is num);
//   print(log(y));
//   print(y is num);
// 
//   print(z is num);
//   print(w is num);
//   print(pow(z, w));
//   print(z is num);
//   print(w is num);
// }

function() {
  var x = P.int_parse("3", null, null), y = P.int_parse("1234", null, null), z = P.int_parse("1236", null, null), w = P.int_parse("2", null, null), v0 = typeof x === "number", v1;
  P.print(v0);
  if (!v0)
    throw H.wrapException(H.argumentErrorValue(x));
  P.print(Math.sin(x));
  P.print(true);
  v0 = typeof y === "number";
  P.print(v0);
  if (!v0)
    throw H.wrapException(H.argumentErrorValue(y));
  P.print(Math.log(y));
  P.print(true);
  v1 = typeof z === "number";
  P.print(v1);
  v0 = typeof w === "number";
  P.print(v0);
  if (!v1)
    throw H.wrapException(H.argumentErrorValue(z));
  if (!v0)
    throw H.wrapException(H.argumentErrorValue(w));
  P.print(Math.pow(z, w));
  P.print(true);
  P.print(true);
}
