// Expectation for test: 
// class Bar {
//   Bar(x, {y, z: 'z', w: '_', q}) {
//     print(x);
//     print(y);
//     print(z);
//     print(w);
//     print(q);
//   }
// }
// class Foo extends Bar {
//   Foo() : super('x', y: 'y', w: 'w');
// }
// main() {
//   new Foo();
// }

function() {
  P.print("x");
  P.print("y");
  P.print("z");
  P.print("w");
  P.print(null);
}
