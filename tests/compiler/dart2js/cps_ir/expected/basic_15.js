// Expectation for test: 
// set foo(x) { print(x); }
// main() { foo = 42; }

function() {
  var v0 = "" + 42;
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
