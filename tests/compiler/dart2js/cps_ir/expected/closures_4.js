// Expectation for test: 
// main(x) {
//   a() {
//     return x;
//   }
//   print(a());
//   return a;
// }

function(x) {
  var a = new V.main_a(x);
  P.print(a.call$0());
  return a;
}
