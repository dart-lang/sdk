// Expectation for test: 
// foo() { print('2'); return 2; }
// main() {
//   if (foo()) {
//     print('bad');
//   } else {
//     print('good');
//   }
// }

function() {
  P.print("2");
  P.print("good");
}
