// Expectation for test: 
// var foo = 0;
// main() { print(foo = 42); }

function() {
  var line = "" + 42;
  $.foo = 42;
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
