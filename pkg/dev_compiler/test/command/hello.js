dart_library.library('hello', null, /* Imports */[
  'dart_sdk'
], function(exports, dart_sdk) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const hello = Object.create(null);
  hello.main = function() {
    return core.print('hello!');
  };
  dart.fn(hello.main);
  // Exports:
  exports.hello = hello;
});

//# sourceMappingURL=hello.js.map
