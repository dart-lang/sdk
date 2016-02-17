// Expectation for test: 
// class C<T> {
//   foo() => print(T);
// }
// 
// main() {
//   new C<int>().foo();
// }

function() {
  var line = H.S(H.createRuntimeType(H.runtimeTypeToString(H.getTypeArgumentByIndex(V.C$(P.$int), 0))));
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
