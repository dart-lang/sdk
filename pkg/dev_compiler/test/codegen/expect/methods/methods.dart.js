var methods;
(function (methods) {
  // Class A
  var A = (function (_super) {
    var constructor = function A() {};
    dart_runtime.dextend(constructor, _super);
    return constructor;
  })(dart_core.Object);

  constructor.prototype.x = function x() {
    return 42;
  }

  constructor.prototype.y = function y(a) {
    return a;
  }

  constructor.prototype.z = function z(b) {
    if (b !== undefined) { b = null;}
    return b;
  }

  constructor.prototype.zz = function zz(b) {
    if (b !== undefined) { b = 0;}
    return b;
  }

  constructor.prototype.w = function w(a, opt$) {
    var b = opt$.b === undefined ? null : opt$.b;
    return a + b;
  }

  constructor.prototype.ww = function ww(a, opt$) {
    var b = opt$.b === undefined ? 0 : opt$.b;
    return a + b;
  }
  methods.A = A;

})(methods || (methods = {}));
