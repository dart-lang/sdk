// Expectation for test: 
// class C {}
// main() {
//   print(new C());
// }

function() {
  var line = "Instance of '" + H.Primitives_objectTypeName(V.C$()) + "'";
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
