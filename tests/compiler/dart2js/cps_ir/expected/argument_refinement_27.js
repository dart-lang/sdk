// Expectation for test: 
// main() {
//   var x = int.parse('3');
//   var y = int.parse('a', onError: (e) => 'abcde');
//   print(x is int);
//   print(y is String);
//   print(y.codeUnitAt(x));
//   print(x is int);
//   print(y is String);
// }

function() {
  var x = P.int_parse("3", null, null), y = P.int_parse("a", new V.main_closure(), null);
  P.print(typeof x === "number" && Math.floor(x) === x);
  P.print(typeof y === "string");
  P.print(J.codeUnitAt$1$s(y, x));
  P.print(true);
  P.print(true);
}
