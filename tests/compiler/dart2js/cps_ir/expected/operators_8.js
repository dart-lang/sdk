// Expectation for test: 
// main() {
//   var list = [1, 2, 3];
//   list[1] = 6;
//   print(list);
// }

function() {
  var list = [1, 2, 3], v0;
  list[1] = 6;
  v0 = P.IterableBase_iterableToFullString(list, "[", "]");
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
