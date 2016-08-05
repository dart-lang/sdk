dart_library.library('lib/convert/json_lib_test', null, /* Imports */[
  'dart_sdk',
  'unittest'
], function load__json_lib_test(exports, dart_sdk, unittest) {
  'use strict';
  const core = dart_sdk.core;
  const convert = dart_sdk.convert;
  const _interceptors = dart_sdk._interceptors;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const unittest$ = unittest.unittest;
  const src__matcher__expect = unittest.src__matcher__expect;
  const src__matcher__core_matchers = unittest.src__matcher__core_matchers;
  const src__matcher__iterable_matchers = unittest.src__matcher__iterable_matchers;
  const src__matcher__throws_matcher = unittest.src__matcher__throws_matcher;
  const json_lib_test = Object.create(null);
  let JSArrayOfObject = () => (JSArrayOfObject = dart.constFn(_interceptors.JSArray$(core.Object)))();
  let JSArrayOfList = () => (JSArrayOfList = dart.constFn(_interceptors.JSArray$(core.List)))();
  let JSArrayOfint = () => (JSArrayOfint = dart.constFn(_interceptors.JSArray$(core.int)))();
  let ListOfObject = () => (ListOfObject = dart.constFn(core.List$(core.Object)))();
  let JSArrayOfListOfObject = () => (JSArrayOfListOfObject = dart.constFn(_interceptors.JSArray$(ListOfObject())))();
  let MapOfString$dynamic = () => (MapOfString$dynamic = dart.constFn(core.Map$(core.String, dart.dynamic)))();
  let JSArrayOfMap = () => (JSArrayOfMap = dart.constFn(_interceptors.JSArray$(core.Map)))();
  let MapOfString$int = () => (MapOfString$int = dart.constFn(core.Map$(core.String, core.int)))();
  let JSArrayOfToJson = () => (JSArrayOfToJson = dart.constFn(_interceptors.JSArray$(json_lib_test.ToJson)))();
  let isInstanceOfOfJsonUnsupportedObjectError = () => (isInstanceOfOfJsonUnsupportedObjectError = dart.constFn(src__matcher__core_matchers.isInstanceOf$(convert.JsonUnsupportedObjectError)))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  let VoidToString = () => (VoidToString = dart.constFn(dart.definiteFunctionType(core.String, [])))();
  let dynamicTodynamic = () => (dynamicTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [dart.dynamic])))();
  json_lib_test.main = function() {
    unittest$.test('Parse', dart.fn(() => {
      src__matcher__expect.expect(convert.JSON.decode(' 5 '), src__matcher__core_matchers.equals(5));
      src__matcher__expect.expect(convert.JSON.decode(' -42 '), src__matcher__core_matchers.equals(-42));
      src__matcher__expect.expect(convert.JSON.decode(' 3e0 '), src__matcher__core_matchers.equals(3));
      src__matcher__expect.expect(convert.JSON.decode(' 3.14 '), src__matcher__core_matchers.equals(3.14));
      src__matcher__expect.expect(convert.JSON.decode('true '), src__matcher__core_matchers.isTrue);
      src__matcher__expect.expect(convert.JSON.decode(' false'), src__matcher__core_matchers.isFalse);
      src__matcher__expect.expect(convert.JSON.decode(' null '), src__matcher__core_matchers.isNull);
      src__matcher__expect.expect(convert.JSON.decode('\n\rnull\t'), src__matcher__core_matchers.isNull);
      src__matcher__expect.expect(convert.JSON.decode(' "hi there\\" bob" '), src__matcher__core_matchers.equals('hi there" bob'));
      src__matcher__expect.expect(convert.JSON.decode(' "" '), src__matcher__core_matchers.isEmpty);
      src__matcher__expect.expect(convert.JSON.decode(' [] '), src__matcher__core_matchers.isEmpty);
      src__matcher__expect.expect(convert.JSON.decode('[ ]'), src__matcher__core_matchers.isEmpty);
      src__matcher__expect.expect(convert.JSON.decode(' [3, -4.5, true, "hi", false] '), src__matcher__core_matchers.equals(JSArrayOfObject().of([3, -4.5, true, 'hi', false])));
      src__matcher__expect.expect(convert.JSON.decode('[null]'), src__matcher__iterable_matchers.orderedEquals([null]));
      src__matcher__expect.expect(convert.JSON.decode(' [3, -4.5, null, true, "hi", false] '), src__matcher__core_matchers.equals(JSArrayOfObject().of([3, -4.5, null, true, 'hi', false])));
      src__matcher__expect.expect(convert.JSON.decode('[[null]]'), src__matcher__core_matchers.equals(JSArrayOfList().of([[null]])));
      src__matcher__expect.expect(convert.JSON.decode(' [ [3], [], [null], ["hi", true]] '), src__matcher__core_matchers.equals(JSArrayOfListOfObject().of([JSArrayOfint().of([3]), [], [null], JSArrayOfObject().of(['hi', true])])));
      src__matcher__expect.expect(convert.JSON.decode(' {} '), src__matcher__core_matchers.isEmpty);
      src__matcher__expect.expect(convert.JSON.decode('{ }'), src__matcher__core_matchers.isEmpty);
      src__matcher__expect.expect(convert.JSON.decode(' {"x":3, "y": -4.5,  "z" : "hi","u" : true, "v": false } '), src__matcher__core_matchers.equals(dart.map({x: 3, y: -4.5, z: "hi", u: true, v: false}, core.String, core.Object)));
      src__matcher__expect.expect(convert.JSON.decode(' {"x":3, "y": -4.5,  "z" : "hi" } '), src__matcher__core_matchers.equals(dart.map({x: 3, y: -4.5, z: "hi"}, core.String, core.Object)));
      src__matcher__expect.expect(convert.JSON.decode(' {"y": -4.5,  "z" : "hi" ,"x":3 } '), src__matcher__core_matchers.equals(dart.map({y: -4.5, z: "hi", x: 3}, core.String, core.Object)));
      src__matcher__expect.expect(convert.JSON.decode('{ " hi bob " :3, "": 4.5}'), src__matcher__core_matchers.equals(dart.map({" hi bob ": 3, "": 4.5}, core.String, core.num)));
      src__matcher__expect.expect(convert.JSON.decode(' { "x" : { } } '), src__matcher__core_matchers.equals(dart.map({x: dart.map()}, core.String, core.Map)));
      src__matcher__expect.expect(convert.JSON.decode('{"x":{}}'), src__matcher__core_matchers.equals(dart.map({x: dart.map()}, core.String, core.Map)));
      src__matcher__expect.expect(convert.JSON.decode('{"w":null}'), src__matcher__core_matchers.equals(dart.map({w: null}, core.String, dart.dynamic)));
      src__matcher__expect.expect(convert.JSON.decode('{"x":{"w":null}}'), src__matcher__core_matchers.equals(dart.map({x: dart.map({w: null}, core.String, dart.dynamic)}, core.String, MapOfString$dynamic())));
      src__matcher__expect.expect(convert.JSON.decode(' {"x":3, "y": -4.5,  "z" : "hi",' + '"w":null, "u" : true, "v": false } '), src__matcher__core_matchers.equals(dart.map({x: 3, y: -4.5, z: "hi", w: null, u: true, v: false}, core.String, core.Object)));
      src__matcher__expect.expect(convert.JSON.decode('{"x": {"a":3, "b": -4.5}, "y":[{}], ' + '"z":"hi","w":{"c":null,"d":true}, "v":null}'), src__matcher__core_matchers.equals(dart.map({x: dart.map({a: 3, b: -4.5}, core.String, core.num), y: JSArrayOfMap().of([dart.map()]), z: "hi", w: dart.map({c: null, d: true}, core.String, core.bool), v: null}, core.String, core.Object)));
    }, VoidTodynamic()));
    unittest$.test('stringify', dart.fn(() => {
      src__matcher__expect.expect(convert.JSON.encode(5), src__matcher__core_matchers.equals('5'));
      src__matcher__expect.expect(convert.JSON.encode(-42), src__matcher__core_matchers.equals('-42'));
      json_lib_test.validateRoundTrip(3.14);
      src__matcher__expect.expect(convert.JSON.encode(true), src__matcher__core_matchers.equals('true'));
      src__matcher__expect.expect(convert.JSON.encode(false), src__matcher__core_matchers.equals('false'));
      src__matcher__expect.expect(convert.JSON.encode(null), src__matcher__core_matchers.equals('null'));
      src__matcher__expect.expect(convert.JSON.encode(' hi there" bob '), src__matcher__core_matchers.equals('" hi there\\" bob "'));
      src__matcher__expect.expect(convert.JSON.encode('hi\\there'), src__matcher__core_matchers.equals('"hi\\\\there"'));
      src__matcher__expect.expect(convert.JSON.encode('hi\nthere'), src__matcher__core_matchers.equals('"hi\\nthere"'));
      src__matcher__expect.expect(convert.JSON.encode('hi\r\nthere'), src__matcher__core_matchers.equals('"hi\\r\\nthere"'));
      src__matcher__expect.expect(convert.JSON.encode(''), src__matcher__core_matchers.equals('""'));
      src__matcher__expect.expect(convert.JSON.encode([]), src__matcher__core_matchers.equals('[]'));
      src__matcher__expect.expect(convert.JSON.encode(core.List.new(0)), src__matcher__core_matchers.equals('[]'));
      src__matcher__expect.expect(convert.JSON.encode(core.List.new(3)), src__matcher__core_matchers.equals('[null,null,null]'));
      json_lib_test.validateRoundTrip(JSArrayOfObject().of([3, -4.5, null, true, 'hi', false]));
      src__matcher__expect.expect(convert.JSON.encode(JSArrayOfListOfObject().of([JSArrayOfint().of([3]), [], [null], JSArrayOfObject().of(['hi', true])])), src__matcher__core_matchers.equals('[[3],[],[null],["hi",true]]'));
      src__matcher__expect.expect(convert.JSON.encode(dart.map()), src__matcher__core_matchers.equals('{}'));
      src__matcher__expect.expect(convert.JSON.encode(core.Map.new()), src__matcher__core_matchers.equals('{}'));
      src__matcher__expect.expect(convert.JSON.encode(dart.map({x: dart.map()}, core.String, core.Map)), src__matcher__core_matchers.equals('{"x":{}}'));
      src__matcher__expect.expect(convert.JSON.encode(dart.map({x: dart.map({a: 3}, core.String, core.int)}, core.String, MapOfString$int())), src__matcher__core_matchers.equals('{"x":{"a":3}}'));
      json_lib_test.validateRoundTrip(dart.map({x: 3, y: -4.5, z: 'hi', w: null, u: true, v: false}, core.String, core.Object));
      json_lib_test.validateRoundTrip(dart.map({x: 3, y: -4.5, z: 'hi'}, core.String, core.Object));
      json_lib_test.validateRoundTrip(dart.map({' hi bob ': 3, '': 4.5}, core.String, core.num));
      json_lib_test.validateRoundTrip(dart.map({x: dart.map({a: 3, b: -4.5}, core.String, core.num), y: JSArrayOfMap().of([dart.map()]), z: 'hi', w: dart.map({c: null, d: true}, core.String, core.bool), v: null}, core.String, core.Object));
      src__matcher__expect.expect(convert.JSON.encode(new json_lib_test.ToJson(4)), "4");
      src__matcher__expect.expect(convert.JSON.encode(new json_lib_test.ToJson(JSArrayOfObject().of([4, "a"]))), '[4,"a"]');
      src__matcher__expect.expect(convert.JSON.encode(new json_lib_test.ToJson(JSArrayOfObject().of([4, new json_lib_test.ToJson(dart.map({x: 42}, core.String, core.int))]))), '[4,{"x":42}]');
      src__matcher__expect.expect(dart.fn(() => {
        convert.JSON.encode(JSArrayOfToJson().of([new json_lib_test.ToJson(new json_lib_test.ToJson(4))]));
      }, VoidTodynamic()), json_lib_test.throwsJsonError);
      src__matcher__expect.expect(dart.fn(() => {
        convert.JSON.encode(JSArrayOfObject().of([new core.Object()]));
      }, VoidTodynamic()), json_lib_test.throwsJsonError);
    }, VoidTodynamic()));
    unittest$.test('stringify throws if argument cannot be converted', dart.fn(() => {
      src__matcher__expect.expect(dart.fn(() => convert.JSON.encode(new json_lib_test.TestClass()), VoidToString()), json_lib_test.throwsJsonError);
    }, VoidTodynamic()));
    unittest$.test('stringify throws if toJson throws', dart.fn(() => {
      src__matcher__expect.expect(dart.fn(() => convert.JSON.encode(new json_lib_test.ToJsoner("bad", {throws: true})), VoidToString()), json_lib_test.throwsJsonError);
    }, VoidTodynamic()));
    unittest$.test('stringify throws if toJson returns non-serializable value', dart.fn(() => {
      src__matcher__expect.expect(dart.fn(() => convert.JSON.encode(new json_lib_test.ToJsoner(new json_lib_test.TestClass())), VoidToString()), json_lib_test.throwsJsonError);
    }, VoidTodynamic()));
    unittest$.test('stringify throws on cyclic values', dart.fn(() => {
      let a = [];
      let b = a;
      for (let i = 0; i < 50; i++) {
        b = JSArrayOfList().of([b]);
      }
      a[dartx.add](b);
      src__matcher__expect.expect(dart.fn(() => convert.JSON.encode(a), VoidToString()), json_lib_test.throwsJsonError);
    }, VoidTodynamic()));
  };
  dart.fn(json_lib_test.main, VoidTodynamic());
  json_lib_test.TestClass = class TestClass extends core.Object {
    new() {
      this.x = 3;
      this.y = 'joe';
    }
  };
  dart.setSignature(json_lib_test.TestClass, {
    constructors: () => ({new: dart.definiteFunctionType(json_lib_test.TestClass, [])})
  });
  json_lib_test.ToJsoner = class ToJsoner extends core.Object {
    new(returnValue, opts) {
      let throws = opts && 'throws' in opts ? opts.throws : null;
      this.returnValue = returnValue;
      this.throws = throws;
    }
    toJson() {
      if (dart.test(this.throws)) dart.throw(this.returnValue);
      return this.returnValue;
    }
  };
  dart.setSignature(json_lib_test.ToJsoner, {
    constructors: () => ({new: dart.definiteFunctionType(json_lib_test.ToJsoner, [core.Object], {throws: core.bool})}),
    methods: () => ({toJson: dart.definiteFunctionType(core.Object, [])})
  });
  json_lib_test.ToJson = class ToJson extends core.Object {
    new(object) {
      this.object = object;
    }
    toJson() {
      return this.object;
    }
  };
  dart.setSignature(json_lib_test.ToJson, {
    constructors: () => ({new: dart.definiteFunctionType(json_lib_test.ToJson, [dart.dynamic])}),
    methods: () => ({toJson: dart.definiteFunctionType(dart.dynamic, [])})
  });
  dart.defineLazy(json_lib_test, {
    get throwsJsonError() {
      return src__matcher__throws_matcher.throwsA(new (isInstanceOfOfJsonUnsupportedObjectError())());
    },
    set throwsJsonError(_) {}
  });
  json_lib_test.validateRoundTrip = function(expected) {
    src__matcher__expect.expect(convert.JSON.decode(convert.JSON.encode(expected)), src__matcher__core_matchers.equals(expected));
  };
  dart.fn(json_lib_test.validateRoundTrip, dynamicTodynamic());
  // Exports:
  exports.json_lib_test = json_lib_test;
});
