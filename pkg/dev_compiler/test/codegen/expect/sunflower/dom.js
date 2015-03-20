var dom;
(function(exports) {
  'use strict';
  class JsName extends core.Object {
    JsName(opt$) {
      let name = opt$ && 'name' in opt$ ? opt$.name : null;
      this.name = name;
    }
  }
  class Overload extends core.Object {
    Overload() {
    }
  }
  let overload = new Overload();
  class Event extends core.Object {
  }
  class RenderingContext extends core.Object {
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
  // Exports:
  exports.JsName = JsName;
  exports.Overload = Overload;
  exports.overload = overload;
  exports.Event = Event;
  exports.RenderingContext = RenderingContext;
  exports.CanvasDrawingStyles = CanvasDrawingStyles;
  exports.CanvasPathMethods = CanvasPathMethods;
})(dom || (dom = window));
