dart_library.library('language/raw_string_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__raw_string_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const raw_string_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  raw_string_test.RawStringTest = class RawStringTest extends core.Object {
    static testMain() {
      expect$.Expect.equals("abcd", "abcd");
      expect$.Expect.equals("", "");
      expect$.Expect.equals("", '');
      expect$.Expect.equals("", "");
      expect$.Expect.equals("", '');
      expect$.Expect.equals("''''", "''''");
      expect$.Expect.equals('""""', '""""');
      expect$.Expect.equals("1\n2\n3", "1\n2\n3");
      expect$.Expect.equals("1\n2\n3", '1\n2\n3');
      expect$.Expect.equals("1", "1");
      expect$.Expect.equals("1", '1');
      expect$.Expect.equals("'", "'");
      expect$.Expect.equals('"', '"');
      expect$.Expect.equals("1", "1");
      expect$.Expect.equals("1", "1");
      expect$.Expect.equals("$", "$");
      expect$.Expect.equals("\\", "\\");
      expect$.Expect.equals("\\", '\\');
      expect$.Expect.equals("${12}", "${12}");
      expect$.Expect.equals("\\a\\b\\c\\d\\e\\f\\g\\h\\i\\j\\k\\l\\m", "\\a\\b\\c\\d\\e\\f\\g\\h\\i\\j\\k\\l\\m");
      expect$.Expect.equals("\\n\\o\\p\\q\\r\\s\\t\\u\\v\\w\\x\\y\\z", "\\n\\o\\p\\q\\r\\s\\t\\u\\v\\w\\x\\y\\z");
    }
  };
  dart.setSignature(raw_string_test.RawStringTest, {
    statics: () => ({testMain: dart.definiteFunctionType(dart.dynamic, [])}),
    names: ['testMain']
  });
  raw_string_test.main = function() {
    raw_string_test.RawStringTest.testMain();
  };
  dart.fn(raw_string_test.main, VoidTodynamic());
  // Exports:
  exports.raw_string_test = raw_string_test;
});
