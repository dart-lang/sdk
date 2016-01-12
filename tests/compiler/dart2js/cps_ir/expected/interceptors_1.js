// Expectation for test: 
// main() {
//   var g = 1;
// 
//   var x = g + 3;
//   print(x);
// }

function() {
  var v0 = "" + 4;
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
