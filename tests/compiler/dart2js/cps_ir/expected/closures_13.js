// Expectation for test: 
// class Foo {
//   instanceMethod(x) => x;
// }
// main(x) {
//   var tearOff = new Foo().instanceMethod;
//   print(tearOff(123));
//   print(tearOff(321));
// }

function(x) {
  V.Foo$();
  P.print(123);
  P.print(321);
}
