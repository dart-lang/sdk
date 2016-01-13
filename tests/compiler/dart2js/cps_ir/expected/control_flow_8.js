// Expectation for test: 
// main() {
//   var list = [1,2,3,4,5,6];
//   for (var x in list) {
//     print(x);
//   }
// }

function() {
  var list = [1, 2, 3, 4, 5, 6], i = 0, line;
  for (; i < 6; ++i) {
    line = H.S(list[i]);
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
}
