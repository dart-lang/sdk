// Expectation for test: 
// var foo = 0;
// main() { print(foo = 42); }

function() {
  $.foo = 42;
  if (typeof dartPrint == "function")
    dartPrint("42");
  else if (typeof console == "object" && typeof console.log != "undefined")
    console.log("42");
  else if (!(typeof window == "object")) {
    if (!(typeof print == "function"))
      throw "Unable to print message: " + String("42");
    print("42");
  }
}
