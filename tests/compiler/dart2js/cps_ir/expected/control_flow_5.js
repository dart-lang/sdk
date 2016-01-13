// Expectation for test: 
// foo(a) { print(a); return a; }
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
  P.print(false);
  P.print(true);
  if (true) {
    P.print(1);
    P.print(1);
  } else {
    P.print(2);
    P.print(2);
  }
  P.print(3);
}
