dart_library.library('dom', window, /* Imports */[
  "dart_runtime/dart",
  'dart/core'
], /* Lazy imports */[
], function(exports, dart, core) {
  'use strict';
  let dartx = dart.dartx;
  class JsName extends core.Object {
    JsName(opts) {
      let name = opts && 'name' in opts ? opts.name : null;
      this.name = name;
    }
  }
  dart.setSignature(JsName, {
    constructors: () => ({JsName: [JsName, [], {name: core.String}]})
  });
  class Overload extends core.Object {
    Overload() {
    }
  }
  dart.setSignature(Overload, {
    constructors: () => ({Overload: [Overload, []]})
  });
  let overload = dart.const(new Overload());
  let EventListener = dart.typedef('EventListener', () => dart.functionType(dart.void, [Event]));
  let InputElement = HTMLInputElement;
  let CanvasElement = HTMLCanvasElement;
  class RenderingContext extends core.Object {}
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
  class CanvasPathMethods extends core.Object {}
  // Exports:
  exports.JsName = JsName;
  exports.Overload = Overload;
  exports.overload = overload;
  exports.EventListener = EventListener;
  exports.InputElement = InputElement;
  exports.CanvasElement = CanvasElement;
  exports.RenderingContext = RenderingContext;
  exports.CanvasDrawingStyles = CanvasDrawingStyles;
  exports.CanvasPathMethods = CanvasPathMethods;
});
