// Expectation for test: 
// class C<T> {
//   foo() => C;
// }
// main() {
//   print(new C<int>().foo());
// }

function() {
  var line;
  V.C$();
  line = H.S(C.Type_C_cdS);
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
