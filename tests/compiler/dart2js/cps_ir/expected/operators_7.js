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
  var line = "" + 6;
  V.Foo$();
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
