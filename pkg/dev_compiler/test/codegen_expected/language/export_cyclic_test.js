dart_library.library('language/export_cyclic_test', null, /* Imports */[
  'dart_sdk'
], function load__export_cyclic_test(exports, dart_sdk) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const export_cyclic_test = Object.create(null);
  const export_cyclic_helper1 = Object.create(null);
  const export_cyclic_helper2 = Object.create(null);
  const export_cyclic_helper3 = Object.create(null);
  let VoidTovoid = () => (VoidTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [])))();
  export_cyclic_test.A = class A extends core.Object {};
  export_cyclic_test.main = function() {
    core.print(new export_cyclic_test.A());
    core.print(new export_cyclic_helper1.B());
    core.print(new export_cyclic_helper2.C());
    core.print(new export_cyclic_helper3.D());
  };
  dart.fn(export_cyclic_test.main, VoidTovoid());
  export_cyclic_helper3.D = class D extends core.Object {};
  export_cyclic_test.D = export_cyclic_helper3.D;
  export_cyclic_helper2.C = class C extends core.Object {
    new() {
      this.a = null;
      this.b = null;
      this.c = null;
      this.d = null;
    }
  };
  export_cyclic_test.C = export_cyclic_helper2.C;
  export_cyclic_helper1.B = class B extends core.Object {
    new() {
      this.a = null;
      this.b = null;
      this.c = null;
      this.d = null;
    }
  };
  export_cyclic_test.B = export_cyclic_helper1.B;
  export_cyclic_helper1.A = export_cyclic_test.A;
  export_cyclic_helper1.C = export_cyclic_helper2.C;
  export_cyclic_helper1.D = export_cyclic_helper3.D;
  export_cyclic_helper1.main = export_cyclic_test.main;
  export_cyclic_helper2.A = export_cyclic_test.A;
  export_cyclic_helper2.D = export_cyclic_helper3.D;
  export_cyclic_helper2.B = export_cyclic_helper1.B;
  export_cyclic_helper2.main = export_cyclic_test.main;
  export_cyclic_helper2.D = export_cyclic_helper3.D;
  // Exports:
  exports.export_cyclic_test = export_cyclic_test;
  exports.export_cyclic_helper1 = export_cyclic_helper1;
  exports.export_cyclic_helper2 = export_cyclic_helper2;
  exports.export_cyclic_helper3 = export_cyclic_helper3;
});
