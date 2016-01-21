dart_library.library('js/js', null, /* Imports */[
  'dart/_runtime',
  'dart/js',
  'dart/core'
], /* Lazy imports */[
], function(exports, dart, js, core) {
  'use strict';
  let dartx = dart.dartx;
  dart.export(exports, js, ['allowInterop', 'allowInteropCaptureThis'], []);
  class JS extends core.Object {
    JS(name) {
      if (name === void 0) name = null;
      this.name = name;
    }
  }
  dart.setSignature(JS, {
    constructors: () => ({JS: [JS, [], [core.String]]})
  });
  class _Anonymous extends core.Object {
    _Anonymous() {
    }
  }
  dart.setSignature(_Anonymous, {
    constructors: () => ({_Anonymous: [_Anonymous, []]})
  });
  const anonymous = dart.const(new _Anonymous());
  // Exports:
  exports.JS = JS;
  exports.anonymous = anonymous;
});
