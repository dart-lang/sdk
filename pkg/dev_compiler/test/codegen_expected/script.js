dart_library.library('script', null, /* Imports */[
  'dart_sdk'
], function load__script(exports, dart_sdk) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const script = Object.create(null);
  let ListOfString = () => (ListOfString = dart.constFn(core.List$(core.String)))();
  let ListOfStringTovoid = () => (ListOfStringTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [ListOfString()])))();
  script.main = function(args) {
    let name = args[dartx.join](' ');
    if (name == '') name = 'world';
    core.print(dart.str`hello ${name}`);
  };
  dart.fn(script.main, ListOfStringTovoid());
  // Exports:
  exports.script = script;
});
