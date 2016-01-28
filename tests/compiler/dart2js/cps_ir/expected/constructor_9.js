// Expectation for test: 
// // Method to test: generative_constructor(C#)
// class C<T> {
//   C() { print(T); }
//   foo() => print(T);
// }
// main() {
//   new C<int>();
// }

function($T) {
  var v0 = H.setRuntimeTypeInfo(new V.C(), [$T]);
  v0.C$0();
  return v0;
}
