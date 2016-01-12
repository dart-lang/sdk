// Expectation for test: 
// main() {
//   var x = 122;
//   var a = () => x;
//   x = x + 1;
//   print(a());
// }

function() {
  var _captured_x_0 = 122 + 1, line = _captured_x_0 === 0 ? 1 / _captured_x_0 < 0 ? "-0.0" : "" + _captured_x_0 : "" + _captured_x_0;
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
