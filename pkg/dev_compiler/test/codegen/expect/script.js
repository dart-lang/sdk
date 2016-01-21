dart_library.library('script', null, /* Imports */[
  'dart/_runtime',
  'dart/core'
], /* Lazy imports */[
], function(exports, dart, core) {
  'use strict';
  let dartx = dart.dartx;
  function main(args) {
    let name = args[dartx.join](' ');
    if (name == '') name = 'world';
    core.print(`hello ${name}`);
  }
  dart.fn(main, dart.void, [core.List$(core.String)]);
  // Exports:
  exports.main = main;
});
