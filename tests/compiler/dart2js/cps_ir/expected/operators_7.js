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
  V.Foo$();
  if (typeof dartPrint == "function")
    dartPrint("6");
  else if (typeof console == "object" && typeof console.log != "undefined")
    console.log("6");
  else if (!(typeof window == "object")) {
    if (!(typeof print == "function"))
      throw "Unable to print message: " + String("6");
    print("6");
  }
}
