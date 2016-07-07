dart_library.library('language/export_test', null, /* Imports */[
  'dart_sdk'
], function load__export_test(exports, dart_sdk) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const export_test = Object.create(null);
  const export_helper1 = Object.create(null);
  const export_helper2 = Object.create(null);
  const export_helper3 = Object.create(null);
  const export_helper4 = Object.create(null);
  let VoidTovoid = () => (VoidTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [])))();
  export_test.main = function() {
    core.print(new export_helper1.Exported());
    core.print(new export_helper2.ReExported());
    core.print(new export_helper3.Exported());
    core.print(new export_helper4.ReExported());
  };
  dart.fn(export_test.main, VoidTovoid());
  export_helper2.ReExported = class ReExported extends core.Object {};
  export_helper1.Exported = class Exported extends export_helper2.ReExported {};
  export_helper1.ReExported = export_helper2.ReExported;
  export_helper4.ReExported = class ReExported extends core.Object {};
  export_helper3.Exported = class Exported extends export_helper4.ReExported {};
  export_helper3.ReExported = export_helper4.ReExported;
  // Exports:
  exports.export_test = export_test;
  exports.export_helper1 = export_helper1;
  exports.export_helper2 = export_helper2;
  exports.export_helper3 = export_helper3;
  exports.export_helper4 = export_helper4;
});
