dart_library.library('script', null, /* Imports */[
  'dart_sdk'
], function(exports, dart_sdk) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const script = Object.create(null);
  script.main = function(args) {
    let name = args[dartx.join](' ');
    if (name == '') name = 'world';
    core.print(`hello ${name}`);
  };
  dart.fn(script.main, dart.void, [core.List$(core.String)]);
  // Exports:
  exports.script = script;
});
