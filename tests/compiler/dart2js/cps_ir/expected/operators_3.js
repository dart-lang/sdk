// Expectation for test: 
// var x = 1;
// get foo => ++x > 10;
// main() {
//   print(foo ? "hello world" : "bad bad");
// }

function() {
  var v0 = $.x + 1;
  $.x = v0;
  v0 = v0 > 10 ? "hello world" : "bad bad";
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
