dart_library.library('corelib/uri_parameters_all_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__uri_parameters_all_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const _interceptors = dart_sdk._interceptors;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const uri_parameters_all_test = Object.create(null);
  let JSArrayOfString = () => (JSArrayOfString = dart.constFn(_interceptors.JSArray$(core.String)))();
  let MapOfString$dynamic = () => (MapOfString$dynamic = dart.constFn(core.Map$(core.String, dart.dynamic)))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  let ListTodynamic = () => (ListTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [core.List])))();
  let dynamicAnddynamicTodynamic = () => (dynamicAnddynamicTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [dart.dynamic, dart.dynamic])))();
  uri_parameters_all_test.main = function() {
    uri_parameters_all_test.testAll(JSArrayOfString().of(["a", "b", "c"]));
    uri_parameters_all_test.testAll(JSArrayOfString().of([""]));
    uri_parameters_all_test.testAll(JSArrayOfString().of(["a"]));
    uri_parameters_all_test.testAll(JSArrayOfString().of(["", ""]));
    uri_parameters_all_test.testAll(JSArrayOfString().of(["baz"]));
    uri_parameters_all_test.testParse("z&y&w&z", dart.map({z: JSArrayOfString().of(["", ""]), y: JSArrayOfString().of([""]), w: JSArrayOfString().of([""])}));
    uri_parameters_all_test.testParse("x=42&y=42&x=37&y=37", dart.map({x: JSArrayOfString().of(["42", "37"]), y: JSArrayOfString().of(["42", "37"])}));
    uri_parameters_all_test.testParse("x&x&x&x&x", dart.map({x: JSArrayOfString().of(["", "", "", "", ""])}));
    uri_parameters_all_test.testParse("x=&&y", dart.map({x: JSArrayOfString().of([""]), y: JSArrayOfString().of([""])}));
  };
  dart.fn(uri_parameters_all_test.main, VoidTodynamic());
  uri_parameters_all_test.testAll = function(values) {
    let uri = core.Uri.new({scheme: "foo", path: "bar", queryParameters: dart.map({baz: values})});
    let list = uri.queryParametersAll[dartx.get]("baz");
    expect$.Expect.listEquals(values, list);
  };
  dart.fn(uri_parameters_all_test.testAll, ListTodynamic());
  uri_parameters_all_test.testParse = function(query, results) {
    let uri = core.Uri.new({scheme: "foo", path: "bar", query: core.String._check(query)});
    let params = uri.queryParametersAll;
    for (let k of core.Iterable._check(dart.dload(results, 'keys'))) {
      expect$.Expect.listEquals(core.List._check(dart.dindex(results, k)), params[dartx.get](k));
    }
    uri = core.Uri.new({scheme: "foo", path: "bar", queryParameters: MapOfString$dynamic()._check(results)});
    params = uri.queryParametersAll;
    for (let k of core.Iterable._check(dart.dload(results, 'keys'))) {
      expect$.Expect.listEquals(core.List._check(dart.dindex(results, k)), params[dartx.get](k));
    }
  };
  dart.fn(uri_parameters_all_test.testParse, dynamicAnddynamicTodynamic());
  // Exports:
  exports.uri_parameters_all_test = uri_parameters_all_test;
});
