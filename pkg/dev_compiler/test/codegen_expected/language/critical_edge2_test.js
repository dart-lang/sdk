dart_library.library('language/critical_edge2_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__critical_edge2_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const critical_edge2_test = Object.create(null);
  let VoidTovoid = () => (VoidTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [])))();
  let StringToString = () => (StringToString = dart.constFn(dart.definiteFunctionType(core.String, [core.String])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  critical_edge2_test.parse = function(uri) {
    let index = 0;
    let char = -1;
    function parseAuth() {
      index;
      char;
    }
    dart.fn(parseAuth, VoidTovoid());
    while (index < 1000) {
      char = uri[dartx.codeUnitAt](index);
      if (char == 1234) {
        break;
      }
      if (char == 58) {
        return "good";
      }
      index++;
    }
    core.print(char);
    return "bad";
  };
  dart.fn(critical_edge2_test.parse, StringToString());
  critical_edge2_test.main = function() {
    expect$.Expect.equals("good", critical_edge2_test.parse("dart:_foreign_helper"));
  };
  dart.fn(critical_edge2_test.main, VoidTodynamic());
  // Exports:
  exports.critical_edge2_test = critical_edge2_test;
});
