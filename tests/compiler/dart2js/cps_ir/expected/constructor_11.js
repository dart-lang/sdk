// Expectation for test: 
// class A {
//   var x;
//   A() : this.b(1);
//   A.b(this.x);
// }
// main() {
//   print(new A().x);
// }

function() {
  var line = 1 === 0 ? 1 / 1 < 0 ? "-0.0" : "" + 1 : "" + 1;
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
