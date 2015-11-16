dart_library.library('dom/dom', window, /* Imports */[
  "dart/_runtime",
  'dart/core'
], /* Lazy imports */[
], function(exports, dart, core) {
  'use strict';
  let dartx = dart.dartx;
  class Overload extends core.Object {
    Overload() {
    }
  }
  dart.setSignature(Overload, {
    constructors: () => ({Overload: [Overload, []]})
  });
  let overload = dart.const(new Overload());
  class CustomEvent extends core.Object {}
  dart.setSignature(CustomEvent, {
    constructors: () => ({CustomEvent: [CustomEvent, [core.String], {detail: dart.dynamic, bubbles: dart.dynamic, cancelable: dart.dynamic}]})
  });
  class HTMLCollection extends core.Object {}
  dart.setSignature(HTMLCollection, {
    methods: () => ({get: [Element, [core.num]]})
  });
  let EventListener = dart.typedef('EventListener', () => dart.functionType(dart.void, [Event]));
  let InputElement = HTMLInputElement;
  let CanvasElement = HTMLCanvasElement;
  let DivElement = HTMLDivElement;
  let ScriptElement = HTMLScriptElement;
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
  exports.Overload = Overload;
  exports.overload = overload;
  exports.CustomEvent = CustomEvent;
  exports.HTMLCollection = HTMLCollection;
  exports.EventListener = EventListener;
  exports.InputElement = InputElement;
  exports.CanvasElement = CanvasElement;
  exports.DivElement = DivElement;
  exports.ScriptElement = ScriptElement;
  exports.RenderingContext = RenderingContext;
  exports.CanvasDrawingStyles = CanvasDrawingStyles;
  exports.CanvasPathMethods = CanvasPathMethods;
});
