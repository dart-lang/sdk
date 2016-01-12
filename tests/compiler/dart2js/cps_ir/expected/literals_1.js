// Expectation for test: 
// main() {
//   print([]);
//   print([1]);
//   print([1, 2]);
//   print([1, [1, 2]]);
//   print({});
//   print({1: 2});
//   print({[1, 2]: [3, 4]});
// }

function() {
  P.print([]);
  P.print([1]);
  P.print([1, 2]);
  P.print([1, [1, 2]]);
  P.print(P.LinkedHashMap_LinkedHashMap$_empty());
  P.print(P.LinkedHashMap_LinkedHashMap$_literal([1, 2]));
  P.print(P.LinkedHashMap_LinkedHashMap$_literal([[1, 2], [3, 4]]));
}
