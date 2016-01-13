// Expectation for test: 
// foo(a) { print(a); return a; }
// 
// main() {
//   for (int i = 0; foo(true); i = foo(i)) {
//     print(1);
//     if (foo(false)) break;
//   }
//   print(2);
// }

function() {
  for (;;) {
    P.print(true);
    if (true === true) {
      P.print(1);
      P.print(false);
      if (false !== true) {
        P.print(0);
        continue;
      }
    }
    P.print(2);
    return null;
  }
}
