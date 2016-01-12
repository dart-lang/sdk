// Expectation for test: 
// class Foo {
//   operator[]=(index, value) {
//     print(value);
//   }
// }
// main() {
//   var foo = new Foo();
//   foo[5] = 6;
// }

function() {
  var v0 = "" + 6;
  V.Foo$();
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
