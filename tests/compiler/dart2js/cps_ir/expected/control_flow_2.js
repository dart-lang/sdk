// Expectation for test: 
// foo(a) { try { print(a); } finally { return a; } }
// 
// main() {
//   while (true) {
//     l: while (true) {
//       while (foo(true)) {
//         if (foo(false)) break l;
//       }
//       print(1);
//     }
//     print(2);
//   }
// }

function() {
  L0:
    for (;;)
      for (;;) {
        while (V.foo(true))
          if (V.foo(false)) {
            P.print(2);
            continue L0;
          }
        P.print(1);
      }
}
