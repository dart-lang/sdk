// Expectation for test: 
// foo(a) { print(a); return a; }
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
  L1:
    for (;;)
      L0:
        for (;;)
          for (;;) {
            P.print(true);
            if (false) {
              P.print(1);
              continue L0;
            }
            P.print(false);
            if (false) {
              P.print(2);
              continue L1;
            }
          }
}
