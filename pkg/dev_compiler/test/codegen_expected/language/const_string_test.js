dart_library.library('language/const_string_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__const_string_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const const_string_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  const_string_test.main = function() {
    expect$.Expect.isTrue(core.identical("abcd", 'abcd'));
    expect$.Expect.isTrue(core.identical('abcd', "abcd"));
    expect$.Expect.isTrue(core.identical("ab\"cd", 'ab"cd'));
    expect$.Expect.isTrue(core.identical('ab\'cd', "ab'cd"));
    expect$.Expect.isTrue(core.identical("abcd", "ab" + "cd"));
    expect$.Expect.isTrue(core.identical("abcd", "ab" + 'cd'));
    expect$.Expect.isTrue(core.identical("abcd", 'ab' + 'cd'));
    expect$.Expect.isTrue(core.identical("abcd", 'ab' + "cd"));
    expect$.Expect.isTrue(core.identical("abcd", "a" + "b" + "cd"));
    expect$.Expect.isTrue(core.identical("abcd", "a" + "b" + "c" + "d"));
    expect$.Expect.isTrue(core.identical('abcd', 'a' + 'b' + 'c' + 'd'));
    expect$.Expect.isTrue(core.identical("abcd", "a" + "b" + 'c' + "d"));
    expect$.Expect.isTrue(core.identical("abcd", 'a' + 'b' + 'c' + 'd'));
    expect$.Expect.isTrue(core.identical("abcd", 'a' + "b" + 'c' + "d"));
    expect$.Expect.isTrue(core.identical("a'b'cd", "a" + "'b'" + 'c' + "d"));
    expect$.Expect.isTrue(core.identical("a\"b\"cd", "a" + '"b"' + 'c' + "d"));
    expect$.Expect.isTrue(core.identical("a\"b\"cd", "a" + '"b"' + 'c' + "d"));
    expect$.Expect.isTrue(core.identical("a'b'cd", 'a' + "'b'" + 'c' + "d"));
    expect$.Expect.isTrue(core.identical('a\'b\'cd', "a" + "'b'" + 'c' + "d"));
    expect$.Expect.isTrue(core.identical('a"b"cd', 'a' + '"b"' + 'c' + "d"));
    expect$.Expect.isTrue(core.identical("a\"b\"cd", 'a' + '"b"' + 'c' + "d"));
  };
  dart.fn(const_string_test.main, VoidTodynamic());
  // Exports:
  exports.const_string_test = const_string_test;
});
