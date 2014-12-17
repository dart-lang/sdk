var fieldtest;
(function (fieldtest) {
  // Class A
  var A = (function (_super) {
    var _initializer = (function (_this) {
      _this.x = 42;
    });
    var constructor = function A() {
      _initializer(this);
    };
    dart_runtime.dextend(constructor, _super);
    return constructor;
  })(dart_core.Object);
  fieldtest.A = A;

  // Function foo: (A) → int
  function foo(a) {
    dart_core.print(a.x);
    return a.x;
  }
  fieldtest.foo = foo;

  // Function bar: (dynamic) → int
  function bar(a) {
    dart_core.print(dart_runtime.dload(a, "x"));
    return /* Unimplemented: DownCast: dynamic to int */ dart_runtime.dload(a, "x");
  }
  fieldtest.bar = bar;

  // Function baz: (A) → dynamic
  function baz(a) { return a.x; }
  fieldtest.baz = baz;

  // Function main: () → void
  function main() {
    var a = new A();
    fieldtest.foo(a);
    fieldtest.bar(a);
    dart_core.print(fieldtest.baz(a));
  }
  fieldtest.main = main;

})(fieldtest || (fieldtest = {}));
