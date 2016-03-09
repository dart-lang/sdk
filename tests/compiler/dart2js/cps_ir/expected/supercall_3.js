// Expectation for test: 
// class Base {
//   var field = 123;
// }
// class Sub extends Base {
//   m(x) => x + super.field;
// }
// main() {
//   print(new Sub().m(10));
// }

function() {
  var line = H.S(10 + V.Sub$().field);
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
