var constructors;
(function (constructors) {
  // Class A
  var A = (function (_super) {
    var constructor = function A() {};
    dart_runtime.dextend(constructor, _super);
    return constructor;
  })(dart_core.Object);
  constructors.A = A;

  // Class B
  var B = (function (_super) {
    var constructor = function B() {
    };
    dart_runtime.dextend(constructor, _super);
    return constructor;
  })(dart_core.Object);
  constructors.B = B;

  // Class C
  var C = (function (_super) {
    var constructor = function C() {
      throw "no default constructor";
    }
    dart_runtime.dextend(constructor, _super);
    constructor.named = function C() {
    };
    constructor.named.prototype = constructor.prototype;
    return constructor;
  })(dart_core.Object);
  constructors.C = C;

  // Class C2
  var C2 = (function (_super) {
    var constructor = function C2() {
      throw "no default constructor";
    }
    dart_runtime.dextend(constructor, _super);
    constructor.named = function C2() {
      _super.named.call(this);
    };
    constructor.named.prototype = constructor.prototype;
    return constructor;
  })(C);
  constructors.C2 = C2;

  // Class D
  var D = (function (_super) {
    var constructor = function D() {
    };
    dart_runtime.dextend(constructor, _super);
    constructor.named = function D() {
    };
    constructor.named.prototype = constructor.prototype;
    return constructor;
  })(dart_core.Object);
  constructors.D = D;

  // Class E
  var E = (function (_super) {
    var _initializer = (function (_this, name) {
      _this.name = (name === void 0) ? null : name;
    });
    var constructor = function E(name) {
      _initializer(this, name);
    };
    dart_runtime.dextend(constructor, _super);
    return constructor;
  })(dart_core.Object);
  constructors.E = E;

  // Class F
  var F = (function (_super) {
    var constructor = function F(name) {
      _super.call(this, name);
    };
    dart_runtime.dextend(constructor, _super);
    return constructor;
  })(E);
  constructors.F = F;

  // Class G
  var G = (function (_super) {
    var constructor = function G(p1) {
      if (p1 !== undefined) { p1 = null;}
    };
    dart_runtime.dextend(constructor, _super);
    return constructor;
  })(dart_core.Object);
  constructors.G = G;

  // Class H
  var H = (function (_super) {
    var constructor = function H(opt$) {
      var p1 = opt$.p1 === undefined ? null : opt$.p1;
    };
    dart_runtime.dextend(constructor, _super);
    return constructor;
  })(dart_core.Object);
  constructors.H = H;

  // Class I
  var I = (function (_super) {
    var _initializer = (function (_this, name) {
      _this.name = (name === void 0) ? null : name;
    });
    var constructor = function I() {
      _initializer(this, "default");
    };
    dart_runtime.dextend(constructor, _super);
    constructor.named = function I(name) {
      _initializer(this, name);
    };
    constructor.named.prototype = constructor.prototype;
    return constructor;
  })(dart_core.Object);
  constructors.I = I;

  // Class J
  var J = (function (_super) {
    var _initializer = (function (_this, initialized) {
      _this.nonInitialized = null;
      _this.initialized = (initialized === void 0) ? null : initialized;
    });
    var constructor = function J() {
      _initializer(this, true);
    };
    dart_runtime.dextend(constructor, _super);
    return constructor;
  })(dart_core.Object);
  constructors.J = J;

  // Class K
  var K = (function (_super) {
    var _initializer = (function (_this, s) {
      _this.s = "a";
      _this.s = (s === void 0) ? null : s;
    });
    var constructor = function K() {
      _initializer(this, undefined);
    };
    dart_runtime.dextend(constructor, _super);
    constructor.withS = function K(s) {
      _initializer(this, s);
    };
    constructor.withS.prototype = constructor.prototype;
    return constructor;
  })(dart_core.Object);
  constructors.K = K;

})(constructors || (constructors = {}));
