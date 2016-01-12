// Expectation for test: 
// class C {}
// main() {
//   print(new C());
// }

function() {
  var res = "Instance of '" + H.Primitives_objectTypeName(V.C$()) + "'";
  if (typeof dartPrint == "function")
    dartPrint(res);
  else if (typeof console == "object" && typeof console.log != "undefined")
    console.log(res);
  else if (!(typeof window == "object")) {
    if (!(typeof print == "function"))
      throw "Unable to print message: " + String(res);
    print(res);
  }
}
