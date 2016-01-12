// Expectation for test: 
// class Foo {
//   factory Foo.make(x) = Foo.create;
//   var x;
//   Foo.create(this.x);
// }
// main() {
//   print(new Foo.make(5));
// }

function() {
  var v0 = "Instance of '" + H.Primitives_objectTypeName(new V.Foo(5)) + "'";
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
