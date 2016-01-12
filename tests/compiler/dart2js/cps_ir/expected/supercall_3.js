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
  var v0 = "" + (10 + V.Sub$().field);
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
