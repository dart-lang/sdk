var dom;
(function(dom) {
  'use strict';
  class JsType extends dart.Object {
    JsType(opt$) {
      let name = opt$.name === void 0 ? null : opt$.name;
      this.name = name;
    }
  }
  class JsGlobal extends dart.Object {
    JsGlobal() {
    }
  }
  class Overload extends dart.Object {
    Overload() {
    }
  }
  let overload = new Overload();
  dom.document = null;
  class Document extends dart.Object {
  }
  class Element extends dart.Object {
    Element() {
      this.textContent = null;
    }
  }
  class Event extends dart.Object {
  }
  class InputElement extends Element {
    InputElement() {
      this.value = null;
      super.Element();
    }
  }
  class CanvasElement extends Element {
  }
  class RenderingContext extends dart.Object {
  }
  class CanvasRenderingContext2D extends dart.Object {
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
  class CanvasDrawingStyles extends dart.Object {
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
  class CanvasPathMethods extends dart.Object {
  }
  class CanvasGradient extends dart.Object {
  }
  class CanvasPattern extends dart.Object {
  }
  class TextMetrics extends dart.Object {
  }
  class ImageData extends dart.Object {
  }
  // Exports:
  dom.JsType = JsType;
  dom.JsGlobal = JsGlobal;
  dom.Overload = Overload;
  dom.overload = overload;
  dom.Document = Document;
  dom.Element = Element;
  dom.Event = Event;
  dom.InputElement = InputElement;
  dom.CanvasElement = CanvasElement;
  dom.RenderingContext = RenderingContext;
  dom.CanvasRenderingContext2D = CanvasRenderingContext2D;
  dom.CanvasDrawingStyles = CanvasDrawingStyles;
  dom.CanvasPathMethods = CanvasPathMethods;
  dom.CanvasGradient = CanvasGradient;
  dom.CanvasPattern = CanvasPattern;
  dom.TextMetrics = TextMetrics;
  dom.ImageData = ImageData;
})(dom || (dom = {}));
