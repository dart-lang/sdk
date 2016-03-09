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
  var line = H.S(H.createRuntimeType(H.runtimeTypeToString($T)));
  if (typeof dartPrint == "function")
    dartPrint(line);
  else if (typeof console == "object" && typeof console.log != "undefined")
    console.log(line);
  else if (!(typeof window == "object")) {
    if (!(typeof print == "function"))
      throw "Unable to print message: " + String(line);
    print(line);
  }
  return H.setRuntimeTypeInfo(new V.C(), [$T]);
}
