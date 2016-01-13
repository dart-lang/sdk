// Expectation for test: 
// main() {
//   var x = 122;
//   var a = () => x;
//   x = x + 1;
//   print(a());
//   return a;
// }

function() {
  var _box_0 = {}, a = new V.main_closure(_box_0), line;
  _box_0.x = 122;
  ++_box_0.x;
  line = H.S(a.call$0());
  if (typeof dartPrint == "function")
    dartPrint(line);
  else if (typeof console == "object" && typeof console.log != "undefined")
    console.log(line);
  else if (!(typeof window == "object")) {
    if (!(typeof print == "function"))
      throw "Unable to print message: " + String(line);
    print(line);
  }
  return a;
}
