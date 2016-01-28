// Expectation for test: 
// class Base0 {
//   Base0() {
//     print('Base0');
//   }
// }
// class Base extends Base0 {
//   var x;
//   Base(x1) : x = (() => ++x1) {
//     print(x1); // use boxed x1
//   }
// }
// class Sub extends Base {
//   var y;
//   Sub(x, this.y) : super(x) {
//     print(x);
//   }
// }
// main() {
//   print(new Sub(1, 2).x);
// }

function() {
  var _box_0 = {};
  _box_0.x1 = 1;
  P.print("Base0");
  P.print(_box_0.x1);
  P.print(1);
  P.print(new V.Base_closure(_box_0));
}
