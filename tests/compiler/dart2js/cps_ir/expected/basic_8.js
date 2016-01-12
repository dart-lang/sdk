// Expectation for test: 
// main() {
//   print(new Set());
//   print(new Set.from([1, 2, 3]));
// }

function() {
  P.print(P._LinkedHashSet$(null));
  P.print(P.LinkedHashSet_LinkedHashSet$from([1, 2, 3], null));
}
