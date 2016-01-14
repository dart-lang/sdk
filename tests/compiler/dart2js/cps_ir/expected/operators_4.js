// Expectation for test: 
// var x = 1;
// get foo => ++x > 10;
// main() { print(foo && foo); }

function() {
  var v0 = $.x + 1, line;
  $.x = v0;
  L0: {
    if (v0 > 10) {
      $.x = v0 = $.x + 1;
      if (v0 > 10) {
        line = "true";
        break L0;
      }
      v0 = false;
    } else
      v0 = false;
    line = v0 ? String(v0) : "false";
  }
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
