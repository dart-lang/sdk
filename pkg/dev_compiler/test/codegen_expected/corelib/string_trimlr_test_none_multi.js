dart_library.library('corelib/string_trimlr_test_none_multi', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__string_trimlr_test_none_multi(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const string_trimlr_test_none_multi = Object.create(null);
  let dynamicTodynamic = () => (dynamicTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [dart.dynamic])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  string_trimlr_test_none_multi.WHITESPACE = dart.constList([9, 10, 11, 12, 13, 32, 133, 160, 5760, 6158, 8192, 8193, 8194, 8195, 8196, 8197, 8198, 8199, 8200, 8201, 8202, 8232, 8233, 8239, 8287, 12288, 65279], core.int);
  string_trimlr_test_none_multi.main = function() {
    function test(ws) {
      expect$.Expect.equals("", dart.dsend(ws, 'trimLeft'), "K1");
      expect$.Expect.equals("", dart.dsend(dart.dsend(ws, '+', ws), 'trimLeft'), "L2");
      expect$.Expect.equals("a" + dart.notNull(core.String._check(ws)), ("a" + dart.notNull(core.String._check(ws)))[dartx.trimLeft](), "L3");
      expect$.Expect.equals("a", dart.dsend(dart.dsend(ws, '+', "a"), 'trimLeft'), "L4");
      expect$.Expect.equals("a" + dart.notNull(core.String._check(ws)) + dart.notNull(core.String._check(ws)), dart.dsend(dart.dsend(dart.dsend(dart.dsend(dart.dsend(ws, '+', ws), '+', "a"), '+', ws), '+', ws), 'trimLeft'), "L5");
      expect$.Expect.equals("a" + dart.notNull(core.String._check(ws)) + "a", dart.dsend(dart.dsend(dart.dsend(dart.dsend(dart.dsend(ws, '+', ws), '+', "a"), '+', ws), '+', "a"), 'trimLeft'), "L6");
      let untrimmable = "a" + dart.notNull(core.String._check(ws)) + "a";
      expect$.Expect.identical(untrimmable, untrimmable[dartx.trimLeft](), "L7");
      expect$.Expect.equals("", dart.dsend(ws, 'trimRight'), "R1");
      expect$.Expect.equals("", dart.dsend(dart.dsend(ws, '+', ws), 'trimRight'), "R2");
      expect$.Expect.equals("a", ("a" + dart.notNull(core.String._check(ws)))[dartx.trimRight](), "R3");
      expect$.Expect.equals(dart.dsend(ws, '+', "a"), dart.dsend(dart.dsend(ws, '+', "a"), 'trimRight'), "R4");
      expect$.Expect.equals(dart.dsend(dart.dsend(ws, '+', ws), '+', "a"), dart.dsend(dart.dsend(dart.dsend(dart.dsend(dart.dsend(ws, '+', ws), '+', "a"), '+', ws), '+', ws), 'trimRight'), "R5");
      expect$.Expect.equals("a" + dart.notNull(core.String._check(ws)) + "a", ("a" + dart.notNull(core.String._check(ws)) + "a" + dart.notNull(core.String._check(ws)) + dart.notNull(core.String._check(ws)))[dartx.trimRight](), "R6");
      expect$.Expect.identical(untrimmable, untrimmable[dartx.trimRight](), "R7");
    }
    dart.fn(test, dynamicTodynamic());
    for (let ws of string_trimlr_test_none_multi.WHITESPACE) {
      let c = core.String.fromCharCode(ws);
      test(c);
    }
    test(core.String.fromCharCodes(string_trimlr_test_none_multi.WHITESPACE));
    expect$.Expect.identical("", ""[dartx.trimLeft]());
    expect$.Expect.identical("", ""[dartx.trimRight]());
    for (let i = 0, j = 0; i <= 65536; i++) {
      if (j < dart.notNull(string_trimlr_test_none_multi.WHITESPACE[dartx.length]) && i == string_trimlr_test_none_multi.WHITESPACE[dartx.get](j)) {
        j++;
        continue;
      }
      let s = core.String.fromCharCode(i);
      expect$.Expect.identical(s, s[dartx.trimLeft]());
      expect$.Expect.identical(s, s[dartx.trimRight]());
    }
  };
  dart.fn(string_trimlr_test_none_multi.main, VoidTodynamic());
  // Exports:
  exports.string_trimlr_test_none_multi = string_trimlr_test_none_multi;
});
