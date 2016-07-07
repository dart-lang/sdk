dart_library.library('lib/convert/utf82_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__utf82_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const convert = dart_sdk.convert;
  const _interceptors = dart_sdk._interceptors;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const utf82_test = Object.create(null);
  let ListOfint = () => (ListOfint = dart.constFn(core.List$(core.int)))();
  let JSArrayOfint = () => (JSArrayOfint = dart.constFn(_interceptors.JSArray$(core.int)))();
  let JSArrayOfListOfint = () => (JSArrayOfListOfint = dart.constFn(_interceptors.JSArray$(ListOfint())))();
  let JSArrayOfObject = () => (JSArrayOfObject = dart.constFn(_interceptors.JSArray$(core.Object)))();
  let ListOfObject = () => (ListOfObject = dart.constFn(core.List$(core.Object)))();
  let JSArrayOfListOfObject = () => (JSArrayOfListOfObject = dart.constFn(_interceptors.JSArray$(ListOfObject())))();
  let ListOfintToString = () => (ListOfintToString = dart.constFn(dart.definiteFunctionType(core.String, [ListOfint()])))();
  let ListOfintToIterable = () => (ListOfintToIterable = dart.constFn(dart.definiteFunctionType(core.Iterable, [ListOfint()])))();
  let ListOfObjectToListOfObject = () => (ListOfObjectToListOfObject = dart.constFn(dart.definiteFunctionType(ListOfObject(), [ListOfObject()])))();
  let VoidToString = () => (VoidToString = dart.constFn(dart.definiteFunctionType(core.String, [])))();
  let dynamicTobool = () => (dynamicTobool = dart.constFn(dart.definiteFunctionType(core.bool, [dart.dynamic])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  utf82_test.decode = function(bytes) {
    return new convert.Utf8Decoder().convert(bytes);
  };
  dart.fn(utf82_test.decode, ListOfintToString());
  utf82_test.decodeAllowMalformed = function(bytes) {
    return new convert.Utf8Decoder({allowMalformed: true}).convert(bytes);
  };
  dart.fn(utf82_test.decodeAllowMalformed, ListOfintToString());
  utf82_test.decode2 = function(bytes) {
    return convert.UTF8.decode(bytes);
  };
  dart.fn(utf82_test.decode2, ListOfintToString());
  utf82_test.decodeAllowMalformed2 = function(bytes) {
    return convert.UTF8.decode(bytes, {allowMalformed: true});
  };
  dart.fn(utf82_test.decodeAllowMalformed2, ListOfintToString());
  utf82_test.decode3 = function(bytes) {
    return new convert.Utf8Codec().decode(bytes);
  };
  dart.fn(utf82_test.decode3, ListOfintToString());
  utf82_test.decodeAllowMalformed3 = function(bytes) {
    return new convert.Utf8Codec({allowMalformed: true}).decode(bytes);
  };
  dart.fn(utf82_test.decodeAllowMalformed3, ListOfintToString());
  utf82_test.decode4 = function(bytes) {
    return new convert.Utf8Codec().decoder.convert(bytes);
  };
  dart.fn(utf82_test.decode4, ListOfintToString());
  utf82_test.decodeAllowMalformed4 = function(bytes) {
    return new convert.Utf8Codec({allowMalformed: true}).decoder.convert(bytes);
  };
  dart.fn(utf82_test.decodeAllowMalformed4, ListOfintToString());
  dart.defineLazy(utf82_test, {
    get TESTS() {
      return JSArrayOfListOfint().of([JSArrayOfint().of([195]), JSArrayOfint().of([226, 130]), JSArrayOfint().of([240, 164, 173]), JSArrayOfint().of([240, 130, 130, 172]), JSArrayOfint().of([192]), JSArrayOfint().of([193]), JSArrayOfint().of([245]), JSArrayOfint().of([246]), JSArrayOfint().of([247]), JSArrayOfint().of([248]), JSArrayOfint().of([249]), JSArrayOfint().of([250]), JSArrayOfint().of([251]), JSArrayOfint().of([252]), JSArrayOfint().of([253]), JSArrayOfint().of([254]), JSArrayOfint().of([255]), JSArrayOfint().of([192, 128]), JSArrayOfint().of([193, 128]), JSArrayOfint().of([244, 191, 191, 191]), JSArrayOfint().of([-1]), JSArrayOfint().of([-255]), JSArrayOfint().of([-2147483648]), JSArrayOfint().of([-1073741824]), JSArrayOfint().of([-147573952589676412928])]);
    }
  });
  dart.defineLazy(utf82_test, {
    get TESTS2() {
      return JSArrayOfListOfObject().of([JSArrayOfObject().of([JSArrayOfint().of([192, 128, 97]), "Xa"]), JSArrayOfObject().of([JSArrayOfint().of([193, 128, 97]), "Xa"]), JSArrayOfObject().of([JSArrayOfint().of([245, 128]), "XX"]), JSArrayOfObject().of([JSArrayOfint().of([246, 128]), "XX"]), JSArrayOfObject().of([JSArrayOfint().of([247, 128]), "XX"]), JSArrayOfObject().of([JSArrayOfint().of([248, 128]), "XX"]), JSArrayOfObject().of([JSArrayOfint().of([249, 128]), "XX"]), JSArrayOfObject().of([JSArrayOfint().of([250, 128]), "XX"]), JSArrayOfObject().of([JSArrayOfint().of([251, 128]), "XX"]), JSArrayOfObject().of([JSArrayOfint().of([252, 128]), "XX"]), JSArrayOfObject().of([JSArrayOfint().of([253, 128]), "XX"]), JSArrayOfObject().of([JSArrayOfint().of([254, 128]), "XX"]), JSArrayOfObject().of([JSArrayOfint().of([255, 128]), "XX"]), JSArrayOfObject().of([JSArrayOfint().of([245, 128, 97]), "XXa"]), JSArrayOfObject().of([JSArrayOfint().of([246, 128, 97]), "XXa"]), JSArrayOfObject().of([JSArrayOfint().of([247, 128, 97]), "XXa"]), JSArrayOfObject().of([JSArrayOfint().of([248, 128, 97]), "XXa"]), JSArrayOfObject().of([JSArrayOfint().of([249, 128, 97]), "XXa"]), JSArrayOfObject().of([JSArrayOfint().of([250, 128, 97]), "XXa"]), JSArrayOfObject().of([JSArrayOfint().of([251, 128, 97]), "XXa"]), JSArrayOfObject().of([JSArrayOfint().of([252, 128, 97]), "XXa"]), JSArrayOfObject().of([JSArrayOfint().of([253, 128, 97]), "XXa"]), JSArrayOfObject().of([JSArrayOfint().of([254, 128, 97]), "XXa"]), JSArrayOfObject().of([JSArrayOfint().of([255, 128, 97]), "XXa"]), JSArrayOfObject().of([JSArrayOfint().of([245, 128, 128, 97]), "XXXa"]), JSArrayOfObject().of([JSArrayOfint().of([246, 128, 128, 97]), "XXXa"]), JSArrayOfObject().of([JSArrayOfint().of([247, 128, 128, 97]), "XXXa"]), JSArrayOfObject().of([JSArrayOfint().of([248, 128, 128, 97]), "XXXa"]), JSArrayOfObject().of([JSArrayOfint().of([249, 128, 128, 97]), "XXXa"]), JSArrayOfObject().of([JSArrayOfint().of([250, 128, 128, 97]), "XXXa"]), JSArrayOfObject().of([JSArrayOfint().of([251, 128, 128, 97]), "XXXa"]), JSArrayOfObject().of([JSArrayOfint().of([252, 128, 128, 97]), "XXXa"]), JSArrayOfObject().of([JSArrayOfint().of([253, 128, 128, 97]), "XXXa"]), JSArrayOfObject().of([JSArrayOfint().of([254, 128, 128, 97]), "XXXa"]), JSArrayOfObject().of([JSArrayOfint().of([255, 128, 128, 97]), "XXXa"])]);
    }
  });
  utf82_test.main = function() {
    let allTests = utf82_test.TESTS[dartx.expand](dart.dynamic)(dart.fn(test => JSArrayOfListOfObject().of([JSArrayOfObject().of([test, "�"]), JSArrayOfObject().of([(() => {
          let _ = core.List.from(JSArrayOfint().of([97]));
          _[dartx.addAll](test);
          return _;
        })(), "a�"]), JSArrayOfObject().of([(() => {
          let _ = core.List.from(JSArrayOfint().of([97]));
          _[dartx.addAll](test);
          _[dartx.add](97);
          return _;
        })(), "a�a"]), JSArrayOfObject().of([(() => {
          let _ = core.List.from(test);
          _[dartx.add](97);
          return _;
        })(), "�a"]), JSArrayOfObject().of([(() => {
          let _ = core.List.from(test);
          _[dartx.addAll](test);
          return _;
        })(), "��"]), JSArrayOfObject().of([(() => {
          let _ = core.List.from(test);
          _[dartx.add](97);
          _[dartx.addAll](test);
          return _;
        })(), "�a�"]), JSArrayOfObject().of([(() => {
          let _ = core.List.from(JSArrayOfint().of([195, 165]));
          _[dartx.addAll](test);
          return _;
        })(), "å�"]), JSArrayOfObject().of([(() => {
          let _ = core.List.from(JSArrayOfint().of([195, 165]));
          _[dartx.addAll](test);
          _[dartx.addAll](JSArrayOfint().of([195, 165]));
          return _;
        })(), "å�å"]), JSArrayOfObject().of([(() => {
          let _ = core.List.from(test);
          _[dartx.addAll](JSArrayOfint().of([195, 165]));
          return _;
        })(), "�å"]), JSArrayOfObject().of([(() => {
          let _ = core.List.from(test);
          _[dartx.addAll](JSArrayOfint().of([195, 165]));
          _[dartx.addAll](test);
          return _;
        })(), "�å�"])]), ListOfintToIterable()));
    let allTests2 = utf82_test.TESTS2[dartx.map](ListOfObject())(dart.fn(test => {
      let expected = core.String.as(test[dartx.get](1))[dartx.replaceAll]("X", "�");
      return JSArrayOfObject().of([test[dartx.get](0), expected]);
    }, ListOfObjectToListOfObject()));
    for (let test of (() => {
      let _ = [];
      _[dartx.addAll](allTests);
      _[dartx.addAll](allTests2);
      return _;
    })()) {
      let bytes = ListOfint()._check(dart.dindex(test, 0));
      expect$.Expect.throws(dart.fn(() => utf82_test.decode(bytes), VoidToString()), dart.fn(e => core.FormatException.is(e), dynamicTobool()));
      expect$.Expect.throws(dart.fn(() => utf82_test.decode2(bytes), VoidToString()), dart.fn(e => core.FormatException.is(e), dynamicTobool()));
      expect$.Expect.throws(dart.fn(() => utf82_test.decode3(bytes), VoidToString()), dart.fn(e => core.FormatException.is(e), dynamicTobool()));
      expect$.Expect.throws(dart.fn(() => utf82_test.decode4(bytes), VoidToString()), dart.fn(e => core.FormatException.is(e), dynamicTobool()));
      let expected = core.String._check(dart.dindex(test, 1));
      expect$.Expect.equals(expected, utf82_test.decodeAllowMalformed(bytes));
      expect$.Expect.equals(expected, utf82_test.decodeAllowMalformed2(bytes));
      expect$.Expect.equals(expected, utf82_test.decodeAllowMalformed3(bytes));
      expect$.Expect.equals(expected, utf82_test.decodeAllowMalformed4(bytes));
    }
  };
  dart.fn(utf82_test.main, VoidTodynamic());
  // Exports:
  exports.utf82_test = utf82_test;
});
