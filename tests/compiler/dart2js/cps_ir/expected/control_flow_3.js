// Expectation for test: 
// foo(a) { try { print(a); } finally { return a; } }
// 
// main() {
//   for (int i = 0; foo(true); i = foo(i)) {
//     print(1);
//     if (foo(false)) break;
//   }
//   print(2);
// }

function() {
  var i = 0;
  for (; V.foo(true) === true; i = V.foo(i)) {
    P.print(1);
    if (V.foo(false) === true)
      break;
  }
  P.print(2);
}
