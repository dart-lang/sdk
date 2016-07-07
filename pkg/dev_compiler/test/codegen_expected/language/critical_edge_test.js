dart_library.library('language/critical_edge_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__critical_edge_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const critical_edge_test = Object.create(null);
  let VoidTovoid = () => (VoidTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [])))();
  let StringToString = () => (StringToString = dart.constFn(dart.definiteFunctionType(core.String, [core.String])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  critical_edge_test.parse = function(uri) {
    let index = 0;
    let char = -1;
    function parseAuth() {
      index;
      char;
    }
    dart.fn(parseAuth, VoidTovoid());
    let state = 0;
    while (true) {
      char = uri[dartx.codeUnitAt](index);
      if (char == 1234) {
        state = index == 0 ? 1 : 2;
        break;
      }
      if (char == 58) {
        return "good";
      }
      index++;
    }
    if (state == 1) {
      core.print(char == 1234);
      core.print(index == uri[dartx.length]);
    }
    return "bad";
  };
  dart.fn(critical_edge_test.parse, StringToString());
  critical_edge_test.main = function() {
    expect$.Expect.equals("good", critical_edge_test.parse("dart:_foreign_helper"));
  };
  dart.fn(critical_edge_test.main, VoidTodynamic());
  // Exports:
  exports.critical_edge_test = critical_edge_test;
});
