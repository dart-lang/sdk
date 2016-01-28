// Expectation for test: 
// class Base {
//   m(x) {
//     try { print(x+1); } finally { }
//   }
// }
// class Sub extends Base {
//   m(x) => super.m(x+10);
// }
// main() {
//   new Sub().m(100);
// }

function() {
  var v0 = V.Sub$();
  V.Base.prototype.m$1.call(v0, 110);
}
