dart_library.library('corelib/collection_to_string_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__collection_to_string_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const math = dart_sdk.math;
  const _interceptors = dart_sdk._interceptors;
  const collection = dart_sdk.collection;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const collection_to_string_test = Object.create(null);
  let JSArrayOfint = () => (JSArrayOfint = dart.constFn(_interceptors.JSArray$(core.int)))();
  let JSArrayOfString = () => (JSArrayOfString = dart.constFn(_interceptors.JSArray$(core.String)))();
  let ListOfint = () => (ListOfint = dart.constFn(core.List$(core.int)))();
  let JSArrayOfListOfint = () => (JSArrayOfListOfint = dart.constFn(_interceptors.JSArray$(ListOfint())))();
  let MapOfString$int = () => (MapOfString$int = dart.constFn(core.Map$(core.String, core.int)))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  let VoidTovoid = () => (VoidTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [])))();
  let intAndStringBuffer__ToObject = () => (intAndStringBuffer__ToObject = dart.constFn(dart.definiteFunctionType(core.Object, [core.int, core.StringBuffer], {exact: core.bool})))();
  let intAndboolAndStringBuffer__ToObject = () => (intAndboolAndStringBuffer__ToObject = dart.constFn(dart.definiteFunctionType(core.Object, [core.int, core.bool, core.StringBuffer, core.List])))();
  let intAndboolAndStringBuffer__ToList = () => (intAndboolAndStringBuffer__ToList = dart.constFn(dart.definiteFunctionType(core.List, [core.int, core.bool, core.StringBuffer, core.List])))();
  let intAndboolAndStringBuffer__ToQueue = () => (intAndboolAndStringBuffer__ToQueue = dart.constFn(dart.definiteFunctionType(collection.Queue, [core.int, core.bool, core.StringBuffer, core.List])))();
  let intAndboolAndStringBuffer__ToSet = () => (intAndboolAndStringBuffer__ToSet = dart.constFn(dart.definiteFunctionType(core.Set, [core.int, core.bool, core.StringBuffer, core.List])))();
  let intAndboolAndStringBuffer__ToMap = () => (intAndboolAndStringBuffer__ToMap = dart.constFn(dart.definiteFunctionType(core.Map, [core.int, core.bool, core.StringBuffer, core.List])))();
  let intAndboolAndStringBuffer__Todynamic = () => (intAndboolAndStringBuffer__Todynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [core.int, core.bool, core.StringBuffer, core.List, dart.dynamic, core.String])))();
  let intAndboolAndStringBuffer__ToSet$ = () => (intAndboolAndStringBuffer__ToSet$ = dart.constFn(dart.definiteFunctionType(core.Set, [core.int, core.bool, core.StringBuffer, core.List, core.Set])))();
  let intAndboolAndStringBuffer__ToMap$ = () => (intAndboolAndStringBuffer__ToMap$ = dart.constFn(dart.definiteFunctionType(core.Map, [core.int, core.bool, core.StringBuffer, core.List, core.Map])))();
  let intToint = () => (intToint = dart.constFn(dart.definiteFunctionType(core.int, [core.int])))();
  let VoidTobool = () => (VoidTobool = dart.constFn(dart.definiteFunctionType(core.bool, [])))();
  let intAndintToint = () => (intAndintToint = dart.constFn(dart.definiteFunctionType(core.int, [core.int, core.int])))();
  let StringToString = () => (StringToString = dart.constFn(dart.definiteFunctionType(core.String, [core.String])))();
  collection_to_string_test.NUM_TESTS = 300;
  collection_to_string_test.MAX_COLLECTION_SIZE = 7;
  collection_to_string_test.rand = null;
  collection_to_string_test.main = function() {
    collection_to_string_test.rand = math.Random.new();
    collection_to_string_test.smokeTest();
    collection_to_string_test.exactTest();
    collection_to_string_test.inexactTest();
  };
  dart.fn(collection_to_string_test.main, VoidTodynamic());
  let const$;
  let const$0;
  let const$1;
  let const$2;
  let const$3;
  let const$4;
  let const$5;
  let const$6;
  let const$7;
  let const$8;
  let const$9;
  let const$10;
  let const$11;
  let const$12;
  let const$13;
  let const$14;
  let const$15;
  collection_to_string_test.smokeTest = function() {
    expect$.Expect.equals(dart.toString([]), '[]');
    expect$.Expect.equals(dart.toString(JSArrayOfint().of([1])), '[1]');
    expect$.Expect.equals(dart.toString(JSArrayOfString().of(['Elvis'])), '[Elvis]');
    expect$.Expect.equals(dart.toString([null]), '[null]');
    expect$.Expect.equals(dart.toString(JSArrayOfint().of([1, 2])), '[1, 2]');
    expect$.Expect.equals(dart.toString(JSArrayOfString().of(['I', 'II'])), '[I, II]');
    expect$.Expect.equals(dart.toString(JSArrayOfListOfint().of([JSArrayOfint().of([1, 2]), JSArrayOfint().of([3, 4]), JSArrayOfint().of([5, 6])])), '[[1, 2], [3, 4], [5, 6]]');
    expect$.Expect.equals(dart.toString(const$ || (const$ = dart.constList([], dart.dynamic))), '[]');
    expect$.Expect.equals(dart.toString(const$0 || (const$0 = dart.constList([1], core.int))), '[1]');
    expect$.Expect.equals(dart.toString(const$1 || (const$1 = dart.constList(['Elvis'], core.String))), '[Elvis]');
    expect$.Expect.equals(dart.toString(const$2 || (const$2 = dart.constList([null], dart.dynamic))), '[null]');
    expect$.Expect.equals(dart.toString(const$3 || (const$3 = dart.constList([1, 2], core.int))), '[1, 2]');
    expect$.Expect.equals(dart.toString(const$4 || (const$4 = dart.constList(['I', 'II'], core.String))), '[I, II]');
    expect$.Expect.equals(dart.toString(const$8 || (const$8 = dart.constList([const$5 || (const$5 = dart.constList([1, 2], core.int)), const$6 || (const$6 = dart.constList([3, 4], core.int)), const$7 || (const$7 = dart.constList([5, 6], core.int))], ListOfint()))), '[[1, 2], [3, 4], [5, 6]]');
    expect$.Expect.equals(dart.toString(dart.map()), '{}');
    expect$.Expect.equals(dart.toString(dart.map({Elvis: 'King'}, core.String, core.String)), '{Elvis: King}');
    expect$.Expect.equals(dart.toString(dart.map({Elvis: null}, core.String, dart.dynamic)), '{Elvis: null}');
    expect$.Expect.equals(dart.toString(dart.map({I: 1, II: 2}, core.String, core.int)), '{I: 1, II: 2}');
    expect$.Expect.equals(dart.toString(dart.map({X: dart.map({I: 1, II: 2}, core.String, core.int), Y: dart.map({III: 3, IV: 4}, core.String, core.int), Z: dart.map({V: 5, VI: 6}, core.String, core.int)}, core.String, MapOfString$int())), '{X: {I: 1, II: 2}, Y: {III: 3, IV: 4}, Z: {V: 5, VI: 6}}');
    expect$.Expect.equals(dart.toString(const$9 || (const$9 = dart.const(dart.map()))), '{}');
    expect$.Expect.equals(dart.toString(const$10 || (const$10 = dart.const(dart.map({Elvis: 'King'}, core.String, core.String)))), '{Elvis: King}');
    expect$.Expect.equals(dart.toString(dart.map({Elvis: null}, core.String, dart.dynamic)), '{Elvis: null}');
    expect$.Expect.equals(dart.toString(const$11 || (const$11 = dart.const(dart.map({I: 1, II: 2}, core.String, core.int)))), '{I: 1, II: 2}');
    expect$.Expect.equals(dart.toString(const$15 || (const$15 = dart.const(dart.map({X: const$12 || (const$12 = dart.const(dart.map({I: 1, II: 2}, core.String, core.int))), Y: const$13 || (const$13 = dart.const(dart.map({III: 3, IV: 4}, core.String, core.int))), Z: const$14 || (const$14 = dart.const(dart.map({V: 5, VI: 6}, core.String, core.int)))}, core.String, MapOfString$int())))), '{X: {I: 1, II: 2}, Y: {III: 3, IV: 4}, Z: {V: 5, VI: 6}}');
  };
  dart.fn(collection_to_string_test.smokeTest, VoidTovoid());
  collection_to_string_test.exactTest = function() {
    for (let i = 0; i < collection_to_string_test.NUM_TESTS; i++) {
      let size = math.sqrt(collection_to_string_test.random(collection_to_string_test.MAX_COLLECTION_SIZE * collection_to_string_test.MAX_COLLECTION_SIZE))[dartx.toInt]();
      let stringRep = new core.StringBuffer();
      let o = collection_to_string_test.randomCollection(size, stringRep, {exact: true});
      core.print(stringRep);
      core.print(o);
      expect$.Expect.equals(dart.toString(o), stringRep.toString());
    }
  };
  dart.fn(collection_to_string_test.exactTest, VoidTovoid());
  collection_to_string_test.inexactTest = function() {
    for (let i = 0; i < collection_to_string_test.NUM_TESTS; i++) {
      let size = math.sqrt(collection_to_string_test.random(collection_to_string_test.MAX_COLLECTION_SIZE * collection_to_string_test.MAX_COLLECTION_SIZE))[dartx.toInt]();
      let stringRep = new core.StringBuffer();
      let o = collection_to_string_test.randomCollection(size, stringRep, {exact: false});
      core.print(stringRep);
      core.print(o);
      expect$.Expect.equals(collection_to_string_test.alphagram(dart.toString(o)), collection_to_string_test.alphagram(stringRep.toString()));
    }
  };
  dart.fn(collection_to_string_test.inexactTest, VoidTovoid());
  collection_to_string_test.randomCollection = function(size, stringRep, opts) {
    let exact = opts && 'exact' in opts ? opts.exact : null;
    return collection_to_string_test.randomCollectionHelper(size, exact, stringRep, []);
  };
  dart.fn(collection_to_string_test.randomCollection, intAndStringBuffer__ToObject());
  collection_to_string_test.randomCollectionHelper = function(size, exact, stringRep, beingMade) {
    let interfaceFrac = collection_to_string_test.rand.nextDouble();
    if (dart.test(exact)) {
      if (dart.notNull(interfaceFrac) < 1 / 3) {
        return collection_to_string_test.randomList(size, exact, stringRep, beingMade);
      } else if (dart.notNull(interfaceFrac) < 2 / 3) {
        return collection_to_string_test.randomQueue(size, exact, stringRep, beingMade);
      } else {
        return collection_to_string_test.randomMap(size, exact, stringRep, beingMade);
      }
    } else {
      if (dart.notNull(interfaceFrac) < 1 / 4) {
        return collection_to_string_test.randomList(size, exact, stringRep, beingMade);
      } else if (dart.notNull(interfaceFrac) < 2 / 4) {
        return collection_to_string_test.randomQueue(size, exact, stringRep, beingMade);
      } else if (dart.notNull(interfaceFrac) < 3 / 4) {
        return collection_to_string_test.randomSet(size, exact, stringRep, beingMade);
      } else {
        return collection_to_string_test.randomMap(size, exact, stringRep, beingMade);
      }
    }
  };
  dart.fn(collection_to_string_test.randomCollectionHelper, intAndboolAndStringBuffer__ToObject());
  collection_to_string_test.randomList = function(size, exact, stringRep, beingMade) {
    return core.List._check(collection_to_string_test.populateRandomCollection(size, exact, stringRep, beingMade, [], "[]"));
  };
  dart.fn(collection_to_string_test.randomList, intAndboolAndStringBuffer__ToList());
  collection_to_string_test.randomQueue = function(size, exact, stringRep, beingMade) {
    return collection.Queue._check(collection_to_string_test.populateRandomCollection(size, exact, stringRep, beingMade, collection.Queue.new(), "{}"));
  };
  dart.fn(collection_to_string_test.randomQueue, intAndboolAndStringBuffer__ToQueue());
  collection_to_string_test.randomSet = function(size, exact, stringRep, beingMade) {
    return collection_to_string_test.populateRandomSet(size, exact, stringRep, beingMade, core.Set.new());
  };
  dart.fn(collection_to_string_test.randomSet, intAndboolAndStringBuffer__ToSet());
  collection_to_string_test.randomMap = function(size, exact, stringRep, beingMade) {
    if (dart.test(exact)) {
      return collection_to_string_test.populateRandomMap(size, exact, stringRep, beingMade, collection.LinkedHashMap.new());
    } else {
      return collection_to_string_test.populateRandomMap(size, exact, stringRep, beingMade, dart.test(collection_to_string_test.randomBool()) ? core.Map.new() : collection.LinkedHashMap.new());
    }
  };
  dart.fn(collection_to_string_test.randomMap, intAndboolAndStringBuffer__ToMap());
  collection_to_string_test.populateRandomCollection = function(size, exact, stringRep, beingMade, coll, delimiters) {
    beingMade[dartx.add](coll);
    let start = stringRep.length;
    stringRep.write(delimiters[dartx.get](0));
    let indices = [];
    for (let i = 0; i < dart.notNull(size); i++) {
      indices[dartx.add](stringRep.length);
      if (i != 0) stringRep.write(', ');
      dart.dsend(coll, 'add', collection_to_string_test.randomElement(collection_to_string_test.random(size), exact, stringRep, beingMade));
    }
    if (dart.notNull(size) > 5 && delimiters == "()") {
      let MAX_LENGTH = 80;
      let MIN_COUNT = 3;
      let MAX_COUNT = 100;
      let end = stringRep.length;
      if (dart.notNull(size) > MAX_COUNT) {
        for (let i = MIN_COUNT; i < dart.notNull(size); i++) {
          let startIndex = core.int._check(indices[dartx.get](i));
          if (dart.notNull(startIndex) - dart.notNull(start) > MAX_LENGTH - 6) {
            let prefix = dart.toString(stringRep)[dartx.substring](0, startIndex);
            stringRep.clear();
            stringRep.write(prefix);
            stringRep.write(", ...");
          }
        }
      } else if (dart.notNull(stringRep.length) - dart.notNull(start) > MAX_LENGTH - 1) {
        let lastTwoLength = dart.asInt(dart.notNull(end) - dart.notNull(core.num._check(indices[dartx.get](dart.notNull(indices[dartx.length]) - 2))));
        for (let i = 3; i <= dart.notNull(size) - 3; i++) {
          let elementEnd = core.int._check(indices[dartx.get](i + 1));
          let lengthAfter = dart.notNull(elementEnd) - dart.notNull(start);
          let ellipsisSize = 5;
          if (i == dart.notNull(size) - 3) ellipsisSize = 0;
          if (lengthAfter + ellipsisSize + dart.notNull(lastTwoLength) > MAX_LENGTH - 1) {
            let elementStart = core.int._check(indices[dartx.get](i));
            let buffer = dart.toString(stringRep);
            let prefix = buffer[dartx.substring](0, elementStart);
            let suffix = buffer[dartx.substring](dart.notNull(end) - dart.notNull(lastTwoLength), end);
            stringRep.clear();
            stringRep.write(prefix);
            stringRep.write(", ...");
            stringRep.write(suffix);
            break;
          }
        }
      }
    }
    stringRep.write(delimiters[dartx.get](1));
    beingMade[dartx.removeLast]();
    return coll;
  };
  dart.fn(collection_to_string_test.populateRandomCollection, intAndboolAndStringBuffer__Todynamic());
  collection_to_string_test.populateRandomSet = function(size, exact, stringRep, beingMade, set) {
    stringRep.write('{');
    for (let i = 0; i < dart.notNull(size); i++) {
      if (i != 0) stringRep.write(', ');
      set.add(i);
      stringRep.write(i);
    }
    stringRep.write('}');
    return set;
  };
  dart.fn(collection_to_string_test.populateRandomSet, intAndboolAndStringBuffer__ToSet$());
  collection_to_string_test.populateRandomMap = function(size, exact, stringRep, beingMade, map) {
    beingMade[dartx.add](map);
    stringRep.write('{');
    for (let i = 0; i < dart.notNull(size); i++) {
      if (i != 0) stringRep.write(', ');
      let key = i;
      stringRep.write(key);
      stringRep.write(': ');
      let val = collection_to_string_test.randomElement(collection_to_string_test.random(size), exact, stringRep, beingMade);
      map[dartx.set](key, val);
    }
    stringRep.write('}');
    beingMade[dartx.removeLast]();
    return map;
  };
  dart.fn(collection_to_string_test.populateRandomMap, intAndboolAndStringBuffer__ToMap$());
  collection_to_string_test.randomElement = function(size, exact, stringRep, beingMade) {
    let result = null;
    let elementTypeFrac = collection_to_string_test.rand.nextDouble();
    if (dart.notNull(elementTypeFrac) < 1 / 3) {
      result = collection_to_string_test.random(1000);
      stringRep.write(result);
    } else if (dart.notNull(elementTypeFrac) < 2 / 3) {
      result = collection_to_string_test.randomCollectionHelper(size, exact, stringRep, beingMade);
    } else {
      result = beingMade[dartx.get](collection_to_string_test.random(beingMade[dartx.length]));
      if (core.List.is(result)) {
        stringRep.write('[...]');
      } else if (core.Set.is(result) || core.Map.is(result) || collection.Queue.is(result)) {
        stringRep.write('{...}');
      } else {
        stringRep.write('(...)');
      }
    }
    return result;
  };
  dart.fn(collection_to_string_test.randomElement, intAndboolAndStringBuffer__ToObject());
  collection_to_string_test.random = function(max) {
    return collection_to_string_test.rand.nextInt(max);
  };
  dart.fn(collection_to_string_test.random, intToint());
  collection_to_string_test.randomBool = function() {
    return collection_to_string_test.rand.nextBool();
  };
  dart.fn(collection_to_string_test.randomBool, VoidTobool());
  collection_to_string_test.alphagram = function(s) {
    let chars = s[dartx.codeUnits][dartx.toList]();
    chars[dartx.sort](dart.fn((a, b) => dart.notNull(a) - dart.notNull(b), intAndintToint()));
    return core.String.fromCharCodes(chars);
  };
  dart.fn(collection_to_string_test.alphagram, StringToString());
  // Exports:
  exports.collection_to_string_test = collection_to_string_test;
});
