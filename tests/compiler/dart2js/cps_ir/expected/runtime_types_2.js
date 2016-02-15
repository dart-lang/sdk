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
  var v0 = H.createRuntimeType(H.runtimeTypeToString(H.getRuntimeTypeArgument(V.D$(), "C", 1))), v1 = v0._unmangledName;
  v1 = H.S(v1 == null ? v0._unmangledName = function(str, names) {
    return str.replace(/[^<,> ]+/g, function(m) {
      return names[m] || m;
    });
  }(v0._typeName, init.mangledGlobalNames) : v1);
  if (typeof dartPrint == "function")
    dartPrint(v1);
  else if (typeof console == "object" && typeof console.log != "undefined")
    console.log(v1);
  else if (!(typeof window == "object")) {
    if (!(typeof print == "function"))
      throw "Unable to print message: " + String(v1);
    print(v1);
  }
}
