// Expectation for test: 
// class C<T> {
//   foo() => print(T);
// }
// 
// main() {
//   new C<int>().foo();
// }

function() {
  var v0 = H.createRuntimeType(H.runtimeTypeToString(H.getTypeArgumentByIndex(V.C$(P.$int), 0))), v1 = v0._unmangledName;
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
