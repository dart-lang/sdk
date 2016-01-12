// Expectation for test: 
// foo() { print(42); return 42; }
// main() { return foo(); }

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
  return 42;
}
