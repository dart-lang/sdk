// Expectation for test: 
// class A {
//   a() => 1;
//   b() => () => a();
// }
// main() {
//   print(new A().b()());
// }

function() {
  var line = H.S(V.A$().a$0());
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
