// Expectation for test: 
// main() {
//   var list = [1, 2, 3];
//   list[1] = 6;
//   print(list);
// }

function() {
  var list = [1, 2, 3], res;
  list[1] = 6;
  res = P.IterableBase_iterableToFullString(list, "[", "]");
  if (typeof dartPrint == "function")
    dartPrint(res);
  else if (typeof console == "object" && typeof console.log != "undefined")
    console.log(res);
  else if (!(typeof window == "object")) {
    if (!(typeof print == "function"))
      throw "Unable to print message: " + String(res);
    print(res);
  }
}
