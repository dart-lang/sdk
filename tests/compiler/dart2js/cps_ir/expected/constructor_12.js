// Expectation for test: 
// class Foo {
//   factory Foo.make(x) {
//     print('Foo');
//     return new Foo.create(x);
//   }
//   var x;
//   Foo.create(this.x);
// }
// main() {
//   print(new Foo.make(5));
// }

function() {
  P.print("Foo");
  P.print(new V.Foo(5));
}
