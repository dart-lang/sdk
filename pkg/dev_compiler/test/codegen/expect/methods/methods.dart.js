var methods;
(function (methods) {
  // Class A
  var A = (function (_super) {
    var _initializer = (function (_this) {
      _this._c = 3;
    });
    var constructor = function A() {
      _initializer(this);
    };
    dart_runtime.dextend(constructor, _super);

    Object.defineProperties(constructor.prototype, {
      a: {
        "get": function() { return this.x(); },
      },
      b: {
        "set": function(b) {
        },
      },
      c: {
        "get": function() { return this._c; },
        "set": function(c) {
          this._c = c;
        },
      },
    });

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
    return constructor;
  })(dart_core.Object);
  methods.A = A;

})(methods || (methods = {}));
