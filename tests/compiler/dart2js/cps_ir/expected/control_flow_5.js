// Expectation for test: 
// foo(a) { try { print(a); } finally { return a; } }
// 
// main() {
//  foo(false);
//  if (foo(true)) {
//    print(1);
//    print(1);
//  } else {
//    print(2);
//    print(2);
//  }
//  print(3);
// }

function() {
  V.foo(false);
  if (V.foo(true)) {
    P.print(1);
    P.print(1);
  } else {
    P.print(2);
    P.print(2);
  }
  P.print(3);
}
