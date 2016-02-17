// Expectation for test: 
// foo() { print(42); return 42; }
// main() { return foo(); }

function() {
  if (typeof dartPrint == "function")
    dartPrint("42");
  else if (typeof console == "object" && typeof console.log != "undefined")
    console.log("42");
  else if (!(typeof window == "object")) {
    if (!(typeof print == "function"))
      throw "Unable to print message: " + String("42");
    print("42");
  }
  return 42;
}
