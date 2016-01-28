// Expectation for test: 
// // This test illustrates an opportunity to remove redundant code by
// // propagating inforamtion after inlining.
// //
// // The code below inlines `foo` twice, but we don't propagate that we already
// // know from the first `foo` that `a` is an int, so the second check can be
// // removed entirely.
// 
// import 'package:expect/expect.dart';
// 
// main() {
//   var a = nextNumber();
//   action(foo(a));
//   action(foo(a));
// }
// 
// foo(x) {
//   if (x is! int) throw "error 1";
//   return x + 5 % 100;
// }
// 
// @NoInline() @AssumeDynamic()
// nextNumber() => int.parse('33');
// 
// @NoInline()
// action(v) => print(v);

function() {
  var a = V.nextNumber();
  if (!(typeof a === "number" && Math.floor(a) === a))
    throw H.wrapException("error 1");
  a += 5;
  V.action(a);
  V.action(a);
}
