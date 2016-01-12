// Expectation for test: 
// class C {}
// main() {
//   print(new C());
// }

function() {
  var v0 = "Instance of '" + H.Primitives_objectTypeName(V.C$()) + "'";
  if (typeof dartPrint == "function")
    dartPrint(v0);
  else if (typeof console == "object" && typeof console.log != "undefined")
    console.log(v0);
  else if (!(typeof window == "object")) {
    if (!(typeof print == "function"))
      throw "Unable to print message: " + String(v0);
    print(v0);
  }
}
