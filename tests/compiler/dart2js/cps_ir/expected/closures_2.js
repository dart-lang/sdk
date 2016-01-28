// Expectation for test: 
// main(x) {
//   a() {
//     return x;
//   }
//   x = x + '1';
//   print(a());
//   return a;
// }

function(x) {
  var _box_0 = {}, a = new V.main_a(_box_0);
  _box_0.x = x;
  _box_0.x = J.$add$ns(_box_0.x, "1");
  P.print(a.call$0());
  return a;
}
