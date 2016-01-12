// Expectation for test: 
// main() {
//   var a;
//   for (var i=0; i<10; i++) {
//     a = () => i;
//   }
//   print(a());
// }

function() {
  var a = null, i = 0, line;
  for (; i < 10; a = new V.main_closure(i), ++i)
    ;
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
}
