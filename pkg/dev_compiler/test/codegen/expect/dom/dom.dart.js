var dom;
(function (dom) {
  // Class JsType
  var JsType = (function (_super) {
    var _initializer = (function (_this) {
      _this.name = null;
    });
    var constructor = function JsType(opt$) {
      _initializer(this);
      var name = opt$.name === undefined ? null : opt$.name;
    };
    dart_runtime.dextend(constructor, _super);
    return constructor;
  })(dart_core.Object);
  dom.JsType = JsType;

  // Class JsGlobal
  var JsGlobal = (function (_super) {
    var constructor = function JsGlobal() {
    };
    dart_runtime.dextend(constructor, _super);
    return constructor;
  })(dart_core.Object);
  dom.JsGlobal = JsGlobal;

  // Class Overload
  var Overload = (function (_super) {
    var constructor = function Overload() {
    };
    dart_runtime.dextend(constructor, _super);
    return constructor;
  })(dart_core.Object);
  dom.Overload = Overload;

  var overload = function() { return new Overload(); }();
  var document;
  // Class Document
  var Document = (function (_super) {
    var constructor = function Document() {};
    dart_runtime.dextend(constructor, _super);
    return constructor;
  })(dart_core.Object);
  dom.Document = Document;

  // Class Element
  var Element = (function (_super) {
    var _initializer = (function (_this) {
      _this.textContent = null;
    });
    var constructor = function Element() {
      _initializer(this);
    };
    dart_runtime.dextend(constructor, _super);
    return constructor;
  })(dart_core.Object);
  dom.Element = Element;

  // Class Event
  var Event = (function (_super) {
    var constructor = function Event() {};
    dart_runtime.dextend(constructor, _super);
    return constructor;
  })(dart_core.Object);
  dom.Event = Event;

  // Class InputElement
  var InputElement = (function (_super) {
    var _initializer = (function (_this) {
      _this.value = null;
    });
    var constructor = function InputElement() {
      _initializer(this);
    };
    dart_runtime.dextend(constructor, _super);
    return constructor;
  })(Element);
  dom.InputElement = InputElement;

  // Class CanvasElement
  var CanvasElement = (function (_super) {
    var constructor = function CanvasElement() {};
    dart_runtime.dextend(constructor, _super);
    return constructor;
  })(Element);
  dom.CanvasElement = CanvasElement;

  // Class CanvasRenderingContext2D
  var CanvasRenderingContext2D = (function (_super) {
    var _initializer = (function (_this) {
      _this.globalAlpha = null;
      _this.globalCompositeOperation = null;
      _this.strokeStyle = null;
      _this.fillStyle = null;
      _this.shadowOffsetX = null;
      _this.shadowOffsetY = null;
      _this.shadowBlur = null;
      _this.shadowColor = null;
    });
    var constructor = function CanvasRenderingContext2D() {
      _initializer(this);
    };
    dart_runtime.dextend(constructor, _super);
    return constructor;
  })(dart_core.Object);
  dom.CanvasRenderingContext2D = CanvasRenderingContext2D;

  // Class CanvasDrawingStyles
  var CanvasDrawingStyles = (function (_super) {
    var _initializer = (function (_this) {
      _this.lineWidth = null;
      _this.lineCap = null;
      _this.lineJoin = null;
      _this.miterLimit = null;
      _this.lineDashOffset = null;
      _this.font = null;
      _this.textAlign = null;
      _this.textBaseline = null;
    });
    var constructor = function CanvasDrawingStyles() {
      _initializer(this);
    };
    dart_runtime.dextend(constructor, _super);
    return constructor;
  })(dart_core.Object);
  dom.CanvasDrawingStyles = CanvasDrawingStyles;

  // Class CanvasPathMethods
  var CanvasPathMethods = (function (_super) {
    var constructor = function CanvasPathMethods() {};
    dart_runtime.dextend(constructor, _super);
    return constructor;
  })(dart_core.Object);
  dom.CanvasPathMethods = CanvasPathMethods;

  // Class CanvasGradient
  var CanvasGradient = (function (_super) {
    var constructor = function CanvasGradient() {};
    dart_runtime.dextend(constructor, _super);
    return constructor;
  })(dart_core.Object);
  dom.CanvasGradient = CanvasGradient;

  // Class CanvasPattern
  var CanvasPattern = (function (_super) {
    var constructor = function CanvasPattern() {};
    dart_runtime.dextend(constructor, _super);
    return constructor;
  })(dart_core.Object);
  dom.CanvasPattern = CanvasPattern;

  // Class TextMetrics
  var TextMetrics = (function (_super) {
    var constructor = function TextMetrics() {};
    dart_runtime.dextend(constructor, _super);
    return constructor;
  })(dart_core.Object);
  dom.TextMetrics = TextMetrics;

  // Class ImageData
  var ImageData = (function (_super) {
    var constructor = function ImageData() {};
    dart_runtime.dextend(constructor, _super);
    return constructor;
  })(dart_core.Object);
  dom.ImageData = ImageData;

})(dom || (dom = {}));
