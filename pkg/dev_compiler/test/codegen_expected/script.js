define(['dart_sdk'], function(dart_sdk) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const _root = Object.create(null);
  const script = Object.create(_root);
  const $join = dartx.join;
  let ListOfString = () => (ListOfString = dart.constFn(core.List$(core.String)))();
  let ListOfStringTovoid = () => (ListOfStringTovoid = dart.constFn(dart.fnType(dart.void, [ListOfString()])))();
  script.main = function(args) {
    let name = args[$join](' ');
    if (name === '') name = 'world';
    core.print(dart.str`hello ${name}`);
  };
  dart.fn(script.main, ListOfStringTovoid());
  dart.trackLibraries("script", {
    "script.dart": script
  }, null);
  // Exports:
  return {
    script: script
  };
});
