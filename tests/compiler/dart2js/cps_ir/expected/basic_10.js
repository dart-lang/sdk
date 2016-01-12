// Expectation for test: 
// main() {
//   print(new DateTime.now().isBefore(new DateTime.now()));
// }

function() {
  var v0 = Date.now() < Date.now(), line = v0 ? "true" : false === v0 ? "false" : String(v0);
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
