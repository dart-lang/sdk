var dom;
(function(exports) {
  'use strict';
  class JsType extends core.Object {
    JsType(opt$) {
      let name = opt$.name === void 0 ? null : opt$.name;
      this.name = name;
    }
  }
  class JsGlobal extends core.Object {
    JsGlobal() {
    }
  }
  class Overload extends core.Object {
    Overload() {
    }
  }
  let overload = new Overload();
  exports.document = null;
  class Document extends core.Object {
  }
  class Element extends core.Object {
    Element() {
      this.textContent = null;
    }
  }
  class Event extends core.Object {
  }
  class InputElement extends Element {
    InputElement() {
      this.value = null;
      super.Element();
    }
  }
  class CanvasElement extends Element {
  }
  class RenderingContext extends core.Object {
  }
  class CanvasRenderingContext2D extends core.Object {
    CanvasRenderingContext2D() {
      this.globalAlpha = null;
      this.globalCompositeOperation = null;
      this.strokeStyle = null;
      this.fillStyle = null;
      this.shadowOffsetX = null;
      this.shadowOffsetY = null;
      this.shadowBlur = null;
      this.shadowColor = null;
    }
  }
  class CanvasDrawingStyles extends core.Object {
    CanvasDrawingStyles() {
      this.lineWidth = null;
      this.lineCap = null;
      this.lineJoin = null;
      this.miterLimit = null;
      this.lineDashOffset = null;
      this.font = null;
      this.textAlign = null;
      this.textBaseline = null;
    }
  }
  class CanvasPathMethods extends core.Object {
  }
  class CanvasGradient extends core.Object {
  }
  class CanvasPattern extends core.Object {
  }
  class TextMetrics extends core.Object {
  }
  class ImageData extends core.Object {
  }
  // Exports:
  exports.JsType = JsType;
  exports.JsGlobal = JsGlobal;
  exports.Overload = Overload;
  exports.overload = overload;
  exports.Document = Document;
  exports.Element = Element;
  exports.Event = Event;
  exports.InputElement = InputElement;
  exports.CanvasElement = CanvasElement;
  exports.RenderingContext = RenderingContext;
  exports.CanvasRenderingContext2D = CanvasRenderingContext2D;
  exports.CanvasDrawingStyles = CanvasDrawingStyles;
  exports.CanvasPathMethods = CanvasPathMethods;
  exports.CanvasGradient = CanvasGradient;
  exports.CanvasPattern = CanvasPattern;
  exports.TextMetrics = TextMetrics;
  exports.ImageData = ImageData;
})(dom || (dom = {}));
