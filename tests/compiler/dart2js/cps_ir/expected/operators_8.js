// Expectation for test: 
// main() {
//   var list = [1, 2, 3];
//   list[1] = 6;
//   print(list);
// }

function() {
  var list = [1, 2, 3], line;
  list[1] = 6;
  line = H.S(list);
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
