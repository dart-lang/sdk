dart_library.library('language/const_constructor_syntax_test_none_multi', null, /* Imports */[
  'dart_sdk'
], function load__const_constructor_syntax_test_none_multi(exports, dart_sdk) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const const_constructor_syntax_test_none_multi = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  let const$;
  let const$0;
  const_constructor_syntax_test_none_multi.main = function() {
    let c1 = const$ || (const$ = dart.const(new const_constructor_syntax_test_none_multi.C1()));
    let c3 = const$0 || (const$0 = dart.const(new const_constructor_syntax_test_none_multi.C3()));
  };
  dart.fn(const_constructor_syntax_test_none_multi.main, VoidTodynamic());
  const_constructor_syntax_test_none_multi.I0 = class I0 extends core.Object {
    static new() {
      return new const_constructor_syntax_test_none_multi.C0();
    }
  };
  dart.setSignature(const_constructor_syntax_test_none_multi.I0, {
    constructors: () => ({new: dart.definiteFunctionType(const_constructor_syntax_test_none_multi.I0, [])})
  });
  const_constructor_syntax_test_none_multi.C0 = class C0 extends core.Object {
    new() {
    }
  };
  const_constructor_syntax_test_none_multi.C0[dart.implements] = () => [const_constructor_syntax_test_none_multi.I0];
  dart.setSignature(const_constructor_syntax_test_none_multi.C0, {
    constructors: () => ({new: dart.definiteFunctionType(const_constructor_syntax_test_none_multi.C0, [])})
  });
  const_constructor_syntax_test_none_multi.C1 = class C1 extends core.Object {
    new() {
    }
  };
  dart.setSignature(const_constructor_syntax_test_none_multi.C1, {
    constructors: () => ({new: dart.definiteFunctionType(const_constructor_syntax_test_none_multi.C1, [])})
  });
  const_constructor_syntax_test_none_multi.C2 = class C2 extends core.Object {
    new() {
    }
  };
  dart.setSignature(const_constructor_syntax_test_none_multi.C2, {
    constructors: () => ({new: dart.definiteFunctionType(const_constructor_syntax_test_none_multi.C2, [])})
  });
  const_constructor_syntax_test_none_multi.C3 = class C3 extends core.Object {
    new() {
      this.field = null;
    }
  };
  dart.setSignature(const_constructor_syntax_test_none_multi.C3, {
    constructors: () => ({new: dart.definiteFunctionType(const_constructor_syntax_test_none_multi.C3, [])})
  });
  // Exports:
  exports.const_constructor_syntax_test_none_multi = const_constructor_syntax_test_none_multi;
});
