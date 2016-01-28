// Expectation for test: 
// main() {
//   print(new DateTime.now().isBefore(new DateTime.now()));
// }

function() {
  var line = Date.now() < Date.now() ? "true" : "false";
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
