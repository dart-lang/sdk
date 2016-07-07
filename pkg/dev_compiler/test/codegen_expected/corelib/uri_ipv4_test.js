dart_library.library('corelib/uri_ipv4_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__uri_ipv4_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const _interceptors = dart_sdk._interceptors;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const uri_ipv4_test = Object.create(null);
  let ListOfint = () => (ListOfint = dart.constFn(core.List$(core.int)))();
  let JSArrayOfint = () => (JSArrayOfint = dart.constFn(_interceptors.JSArray$(core.int)))();
  let StringAndListOfintTovoid = () => (StringAndListOfintTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [core.String, ListOfint()])))();
  let VoidToListOfint = () => (VoidToListOfint = dart.constFn(dart.definiteFunctionType(ListOfint(), [])))();
  let dynamicTobool = () => (dynamicTobool = dart.constFn(dart.definiteFunctionType(core.bool, [dart.dynamic])))();
  let StringTovoid = () => (StringTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [core.String])))();
  let VoidTovoid = () => (VoidTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [])))();
  uri_ipv4_test.testParseIPv4Address = function() {
    function pass(host, out) {
      expect$.Expect.listEquals(core.Uri.parseIPv4Address(host), out);
    }
    dart.fn(pass, StringAndListOfintTovoid());
    function fail(host) {
      expect$.Expect.throws(dart.fn(() => core.Uri.parseIPv4Address(host), VoidToListOfint()), dart.fn(e => core.FormatException.is(e), dynamicTobool()));
    }
    dart.fn(fail, StringTovoid());
    pass('127.0.0.1', JSArrayOfint().of([127, 0, 0, 1]));
    pass('128.0.0.1', JSArrayOfint().of([128, 0, 0, 1]));
    pass('255.255.255.255', JSArrayOfint().of([255, 255, 255, 255]));
    pass('0.0.0.0', JSArrayOfint().of([0, 0, 0, 0]));
    fail('127.0.0.-1');
    fail('255.255.255.256');
    fail('0.0.0.0.');
    fail('0.0.0.0.0');
    fail('a.0.0.0');
    fail('0.0..0');
  };
  dart.fn(uri_ipv4_test.testParseIPv4Address, VoidTovoid());
  uri_ipv4_test.main = function() {
    uri_ipv4_test.testParseIPv4Address();
  };
  dart.fn(uri_ipv4_test.main, VoidTovoid());
  // Exports:
  exports.uri_ipv4_test = uri_ipv4_test;
});
