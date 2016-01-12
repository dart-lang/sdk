// Expectation for test: 
// main() {
//   var x = int.parse('1233');
//   var y = int.parse('1234');
//   print(x is num);
//   print(y is num);
//   print(x * y);
//   print(x is num);
//   print(y is num); // will stay as is-num because String could be a target of *
// }

function() {
  var x = P.int_parse("1233", null, null), y = P.int_parse("1234", null, null), v0 = typeof x === "number", v1 = typeof y === "number";
  P.print(v0);
  P.print(v1);
  P.print(J.$mul$ns(x, y));
  P.print(v0);
  P.print(v1);
}
