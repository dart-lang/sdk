// Expectation for test: 
// // Bounds checking
// foo(s) {
//   var sum = 0;
//   for (int i = 0; i < s.length; i++) sum += s.codeUnitAt(i);
//   return sum;
// }
// main() {
//   print(foo('ABC'));
//   print(foo('Hello'));
// }

function() {
  var sum = 0, i = 0;
  for (; i < 3; sum += "ABC".charCodeAt(i), ++i)
    ;
  P.print(sum);
  sum = 0;
  for (i = 0; i < 5; sum += "Hello".charCodeAt(i), ++i)
    ;
  P.print(sum);
}
