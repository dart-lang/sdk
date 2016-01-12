// Expectation for test: 
// class Base {
//   m(x) {
//     print(x+1);
//   }
// }
// class Sub extends Base {
//   m(x) => super.m(x+10);
// }
// main() {
//   new Sub().m(100);
// }

function() {
  var v0 = "" + (100 + 10 + 1);
  V.Sub$();
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
