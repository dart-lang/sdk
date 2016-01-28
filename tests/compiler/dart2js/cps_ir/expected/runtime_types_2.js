// Expectation for test: 
// class C<T, U> {
//   foo() => print(U);
// }
// 
// class D extends C<int, double> {}
// 
// main() {
//   new D().foo();
// }

function() {
  var line = H.S(H.createRuntimeType(H.runtimeTypeToString(H.getRuntimeTypeArgument(V.D$(), "C", 1))));
  if (typeof dartPrint == "function")
    dartPrint(line);
  else if (typeof console == "object" && typeof console.log != "undefined")
    console.log(line);
  else if (!(typeof window == "object")) {
    if (!(typeof print == "function"))
      throw "Unable to print message: " + String(line);
    print(line);
  }
}
