// Expectation for test: 
// // Constant folding
// main() {
//   print('A'.codeUnitAt(0));
// }

function() {
  var v0 = "" + 65;
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
