dart_library.library('corelib/format_exception_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__format_exception_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const format_exception_test = Object.create(null);
  let dynamicAnddynamicAnddynamic__Todynamic = () => (dynamicAnddynamicAnddynamic__Todynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [dart.dynamic, dart.dynamic, dart.dynamic, dart.dynamic, dart.dynamic])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  format_exception_test.test = function(exn, message, source, offset, toString) {
    expect$.Expect.equals(message, dart.dload(exn, 'message'));
    expect$.Expect.equals(source, dart.dload(exn, 'source'));
    expect$.Expect.equals(offset, dart.dload(exn, 'offset'));
    expect$.Expect.equals(toString, dart.toString(exn));
  };
  dart.fn(format_exception_test.test, dynamicAnddynamicAnddynamic__Todynamic());
  format_exception_test.main = function() {
    let e = null;
    e = new core.FormatException();
    format_exception_test.test(e, "", null, null, "FormatException");
    e = new core.FormatException("");
    format_exception_test.test(e, "", null, null, "FormatException");
    e = new core.FormatException(null);
    format_exception_test.test(e, null, null, null, "FormatException");
    e = new core.FormatException("message");
    format_exception_test.test(e, "message", null, null, "FormatException: message");
    e = new core.FormatException("message", "source");
    format_exception_test.test(e, "message", "source", null, "FormatException: message\nsource");
    e = new core.FormatException("message", "source"[dartx['*']](25));
    format_exception_test.test(e, "message", "source"[dartx['*']](25), null, "FormatException: message\n" + "source"[dartx['*']](12) + "sou...");
    e = new core.FormatException("message", "source"[dartx['*']](25));
    format_exception_test.test(e, "message", "source"[dartx['*']](25), null, "FormatException: message\n" + "source"[dartx['*']](12) + "sou...");
    e = new core.FormatException("message", "s1\nsource\ns2");
    format_exception_test.test(e, "message", "s1\nsource\ns2", null, "FormatException: message\n" + "s1\nsource\ns2");
    let o = new core.Object();
    e = new core.FormatException("message", o, 10);
    format_exception_test.test(e, "message", o, 10, "FormatException: message (at offset 10)");
    e = new core.FormatException("message", "source", 3);
    format_exception_test.test(e, "message", "source", 3, "FormatException: message (at character 4)\nsource\n   ^\n");
    e = new core.FormatException("message", "s1\nsource\ns2", 6);
    format_exception_test.test(e, "message", "s1\nsource\ns2", 6, "FormatException: message (at line 2, character 4)\nsource\n   ^\n");
    let longline = "watermelon cantaloupe "[dartx['*']](8) + "watermelon";
    let longsource = (longline + "\n")[dartx['*']](25);
    let line10 = (dart.notNull(longline[dartx.length]) + 1) * 9;
    e = new core.FormatException("message", longsource, line10);
    format_exception_test.test(e, "message", longsource, line10, "FormatException: message (at line 10, character 1)\n" + dart.str`${longline[dartx.substring](0, 75)}...\n^\n`);
    e = new core.FormatException("message", longsource, line10 - 1);
    format_exception_test.test(e, "message", longsource, line10 - 1, "FormatException: message (at line 9, " + dart.str`character ${dart.notNull(longline[dartx.length]) + 1})\n` + dart.str`...${longline[dartx.substring](dart.notNull(longline[dartx.length]) - 75)}\n` + dart.str`${' '[dartx['*']](78)}^\n`);
    let half = (dart.notNull(longline[dartx.length]) / 2)[dartx.truncate]();
    e = new core.FormatException("message", longsource, line10 + half);
    format_exception_test.test(e, "message", longsource, line10 + half, dart.str`FormatException: message (at line 10, character ${half + 1})\n` + dart.str`...${longline[dartx.substring](half - 36, half + 36)}...\n` + dart.str`${' '[dartx['*']](39)}^\n`);
  };
  dart.fn(format_exception_test.main, VoidTodynamic());
  // Exports:
  exports.format_exception_test = format_exception_test;
});
