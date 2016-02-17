// Expectation for test: 
// main() {
//   var g = 1;
// 
//   var x = g + 3;
//   print(x);
// }

function() {
  if (typeof dartPrint == "function")
    dartPrint("4");
  else if (typeof console == "object" && typeof console.log != "undefined")
    console.log("4");
  else if (!(typeof window == "object")) {
    if (!(typeof print == "function"))
      throw "Unable to print message: " + String("4");
    print("4");
  }
}
