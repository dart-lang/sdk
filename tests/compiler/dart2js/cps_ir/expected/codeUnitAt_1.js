// Expectation for test: 
// // Constant folding
// main() {
//   print('A'.codeUnitAt(0));
// }

function() {
  if (typeof dartPrint == "function")
    dartPrint("65");
  else if (typeof console == "object" && typeof console.log != "undefined")
    console.log("65");
  else if (!(typeof window == "object")) {
    if (!(typeof print == "function"))
      throw "Unable to print message: " + String("65");
    print("65");
  }
}
