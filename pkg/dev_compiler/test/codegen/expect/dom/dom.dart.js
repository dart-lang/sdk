var dom;
(function (dom) {
  'use strict';
  class JsType {
    constructor(opt$) {
      let name = opt$.name === undefined ? null : opt$.name;
      this.name = name;
    }
  }

  class JsGlobal {
    constructor() {
    }
  }

  class Overload {
    constructor() {
    }
  }

  let overload = /* Unimplemented lazy eval */new Overload();
  let document;
  class Document {
  }

  class Element {
    constructor() {
      this.textContent = null;
      super();
    }
  }

  class Event {
  }

  class InputElement extends Element {
    constructor() {
      this.value = null;
      super();
    }
  }

  class CanvasElement extends Element {
  }

  class RenderingContext {
  }

  class CanvasRenderingContext2D {
    constructor() {
      this.globalAlpha = null;
      this.globalCompositeOperation = null;
      this.strokeStyle = null;
      this.fillStyle = null;
      this.shadowOffsetX = null;
      this.shadowOffsetY = null;
      this.shadowBlur = null;
      this.shadowColor = null;
      super();
    }
  }

  class CanvasDrawingStyles {
    constructor() {
      this.lineWidth = null;
      this.lineCap = null;
      this.lineJoin = null;
      this.miterLimit = null;
      this.lineDashOffset = null;
      this.font = null;
      this.textAlign = null;
      this.textBaseline = null;
      super();
    }
  }

  class CanvasPathMethods {
  }

  class CanvasGradient {
  }

  class CanvasPattern {
  }

  class TextMetrics {
  }

  class ImageData {
  }

  // Exports:
  dom.JsType = JsType;
  dom.JsGlobal = JsGlobal;
  dom.Overload = Overload;
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
