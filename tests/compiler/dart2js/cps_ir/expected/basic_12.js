// Expectation for test: 
// var foo = 42;
// main() { print(foo); }

function() {
  var v0 = $.foo, line = v0 === 0 ? 1 / v0 < 0 ? "-0.0" : "" + v0 : "" + v0;
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
