// Expectation for test: 
// class Base {
//   var x;
//   Base(this.x);
// }
// class Sub extends Base {
//   var y;
//   Sub(x, this.y) : super(x);
// }
// main() {
//   print(new Sub(1, 2).x);
// }

function() {
  var line = 1 === 0 ? 1 / 1 < 0 ? "-0.0" : "" + 1 : "" + 1;
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
