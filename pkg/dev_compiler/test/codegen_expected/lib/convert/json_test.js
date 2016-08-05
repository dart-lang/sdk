dart_library.library('lib/convert/json_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__json_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const _interceptors = dart_sdk._interceptors;
  const convert = dart_sdk.convert;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const json_test = Object.create(null);
  let dynamicAnddynamicTodynamic = () => (dynamicAnddynamicTodynamic = dart.constFn(dart.functionType(dart.dynamic, [dart.dynamic, dart.dynamic])))();
  let JSArrayOfdynamicAnddynamicTodynamic = () => (JSArrayOfdynamicAnddynamicTodynamic = dart.constFn(_interceptors.JSArray$(dynamicAnddynamicTodynamic())))();
  let JSArrayOfint = () => (JSArrayOfint = dart.constFn(_interceptors.JSArray$(core.int)))();
  let JSArrayOfString = () => (JSArrayOfString = dart.constFn(_interceptors.JSArray$(core.String)))();
  let MapOfString$int = () => (MapOfString$int = dart.constFn(core.Map$(core.String, core.int)))();
  let MapOfString$MapOfString$int = () => (MapOfString$MapOfString$int = dart.constFn(core.Map$(core.String, MapOfString$int())))();
  let JSArrayOfObject = () => (JSArrayOfObject = dart.constFn(_interceptors.JSArray$(core.Object)))();
  let JSArrayOfList = () => (JSArrayOfList = dart.constFn(_interceptors.JSArray$(core.List)))();
  let ListOfList = () => (ListOfList = dart.constFn(core.List$(core.List)))();
  let JSArrayOfListOfList = () => (JSArrayOfListOfList = dart.constFn(_interceptors.JSArray$(ListOfList())))();
  let ListOfListOfList = () => (ListOfListOfList = dart.constFn(core.List$(ListOfList())))();
  let JSArrayOfListOfListOfList = () => (JSArrayOfListOfListOfList = dart.constFn(_interceptors.JSArray$(ListOfListOfList())))();
  let JSArrayOfMap = () => (JSArrayOfMap = dart.constFn(_interceptors.JSArray$(core.Map)))();
  let JSArrayOfbool = () => (JSArrayOfbool = dart.constFn(_interceptors.JSArray$(core.bool)))();
  let dynamicTobool = () => (dynamicTobool = dart.constFn(dart.definiteFunctionType(core.bool, [dart.dynamic])))();
  let dynamicAnddynamicTovoid = () => (dynamicAnddynamicTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [dart.dynamic, dart.dynamic])))();
  let dynamicAnddynamicAnddynamicTodynamic = () => (dynamicAnddynamicAnddynamicTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [dart.dynamic, dart.dynamic, dart.dynamic])))();
  let dynamicAnddynamicTodynamic$ = () => (dynamicAnddynamicTodynamic$ = dart.constFn(dart.definiteFunctionType(dart.dynamic, [dart.dynamic, dart.dynamic])))();
  let ListTovoid = () => (ListTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [core.List])))();
  let StringToString = () => (StringToString = dart.constFn(dart.definiteFunctionType(core.String, [core.String])))();
  let VoidTovoid = () => (VoidTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [])))();
  let dynamicTovoid = () => (dynamicTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [dart.dynamic])))();
  let __Todynamic = () => (__Todynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [], {signs: dart.dynamic, integers: dart.dynamic, fractions: dart.dynamic, exponents: dart.dynamic})))();
  let VoidToString = () => (VoidToString = dart.constFn(dart.definiteFunctionType(core.String, [])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  let StringAndStringTovoid = () => (StringAndStringTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [core.String, core.String])))();
  json_test.badFormat = function(e) {
    return core.FormatException.is(e);
  };
  dart.fn(json_test.badFormat, dynamicTobool());
  json_test.testJson = function(json, expected) {
    function compare(expected, actual, path) {
      if (core.List.is(expected)) {
        expect$.Expect.isTrue(core.List.is(actual));
        expect$.Expect.equals(expected[dartx.length], dart.dload(actual, 'length'), dart.str`${path}: List length`);
        for (let i = 0; i < dart.notNull(expected[dartx.length]); i++) {
          compare(expected[dartx.get](i), dart.dindex(actual, i), dart.str`${path}[${i}]`);
        }
      } else if (core.Map.is(expected)) {
        expect$.Expect.isTrue(core.Map.is(actual));
        expect$.Expect.equals(expected[dartx.length], dart.dload(actual, 'length'), dart.str`${path}: Map size`);
        expected[dartx.forEach](dart.fn((key, value) => {
          expect$.Expect.isTrue(dart.dsend(actual, 'containsKey', key));
          compare(value, dart.dindex(actual, key), dart.str`${path}[${key}]`);
        }, dynamicAnddynamicTovoid()));
      } else if (typeof expected == 'number') {
        expect$.Expect.equals(typeof expected == 'number', typeof actual == 'number', dart.str`${path}: same number type`);
        expect$.Expect.isTrue(expected[dartx.compareTo](core.num._check(actual)) == 0, dart.str`${path}: Expected: ${expected}, was: ${actual}`);
      } else {
        expect$.Expect.equals(expected, actual, core.String._check(path));
      }
    }
    dart.fn(compare, dynamicAnddynamicAnddynamicTodynamic());
    for (let reviver of JSArrayOfdynamicAnddynamicTodynamic().of([null, dart.fn((k, v) => v, dynamicAnddynamicTodynamic$())])) {
      for (let split of JSArrayOfint().of([0, 1, 2, 3])) {
        let name = reviver == null ? "" : "reviver:";
        let sink = convert.ChunkedConversionSink.withCallback(dart.fn(values => {
          let value = values[dartx.get](0);
          compare(expected, value, dart.str`${name}${value}`);
        }, ListTovoid()));
        let decoderSink = convert.JSON.decoder.startChunkedConversion(sink);
        switch (split) {
          case 0:
          {
            decoderSink.add(core.String._check(dart.dsend(json, 'substring', 0, 1)));
            decoderSink.add(core.String._check(dart.dsend(json, 'substring', 1)));
            decoderSink.close();
            break;
          }
          case 1:
          {
            let length = core.int._check(dart.dload(json, 'length'));
            decoderSink.add(core.String._check(dart.dsend(json, 'substring', 0, dart.notNull(length) - 1)));
            decoderSink.add(core.String._check(dart.dsend(json, 'substring', dart.notNull(length) - 1)));
            decoderSink.close();
            break;
          }
          case 2:
          {
            let half = core.int._check(dart.dsend(dart.dload(json, 'length'), '~/', 2));
            decoderSink.add(core.String._check(dart.dsend(json, 'substring', 0, half)));
            decoderSink.add(core.String._check(dart.dsend(json, 'substring', half)));
            decoderSink.close();
            break;
          }
          case 3:
          {
            let length = core.int._check(dart.dload(json, 'length'));
            let third = (dart.notNull(length) / 3)[dartx.truncate]();
            decoderSink.add(core.String._check(dart.dsend(json, 'substring', 0, third)));
            decoderSink.add(core.String._check(dart.dsend(json, 'substring', third, 2 * third)));
            decoderSink.add(core.String._check(dart.dsend(json, 'substring', 2 * third)));
            decoderSink.close();
            break;
          }
        }
      }
    }
  };
  dart.fn(json_test.testJson, dynamicAnddynamicTovoid());
  json_test.escape = function(s) {
    let sb = new core.StringBuffer();
    for (let i = 0; i < dart.notNull(s[dartx.length]); i++) {
      let code = s[dartx.codeUnitAt](i);
      if (code == '\\'[dartx.codeUnitAt](0))
        sb.write('\\\\');
      else if (code == '"'[dartx.codeUnitAt](0))
        sb.write('\\"');
      else if (dart.notNull(code) >= 32 && dart.notNull(code) < 127)
        sb.writeCharCode(code);
      else {
        let hex = dart.str`000${code[dartx.toRadixString](16)}`;
        sb.write('\\u' + dart.str`${hex[dartx.substring](dart.notNull(hex[dartx.length]) - 4)}`);
      }
    }
    return dart.str`${sb}`;
  };
  dart.fn(json_test.escape, StringToString());
  json_test.testThrows = function(json) {
    expect$.Expect.throws(dart.fn(() => convert.JSON.decode(core.String._check(json)), VoidTovoid()), json_test.badFormat, dart.str`json = '${json_test.escape(core.String._check(json))}'`);
  };
  dart.fn(json_test.testThrows, dynamicTovoid());
  json_test.testNumbers = function() {
    let integerList = JSArrayOfString().of(["0", "9", "9999"]);
    let signList = JSArrayOfString().of(["", "-"]);
    let fractionList = JSArrayOfString().of(["", ".0", ".1", ".99999"]);
    let exponentList = JSArrayOfString().of([""]);
    for (let exphead of JSArrayOfString().of(["e", "E", "e-", "E-", "e+", "E+"])) {
      for (let expval of JSArrayOfString().of(["0", "1", "200"])) {
        exponentList[dartx.add](dart.str`${exphead}${expval}`);
      }
    }
    for (let integer of integerList) {
      for (let sign of signList) {
        for (let fraction of fractionList) {
          for (let exp of exponentList) {
            for (let ws of JSArrayOfString().of(["", " ", "\t"])) {
              let literal = dart.str`${ws}${sign}${integer}${fraction}${exp}${ws}`;
              let expectedValue = core.num.parse(literal);
              json_test.testJson(literal, expectedValue);
            }
          }
        }
      }
    }
    function testError(opts) {
      let signs = opts && 'signs' in opts ? opts.signs : null;
      let integers = opts && 'integers' in opts ? opts.integers : null;
      let fractions = opts && 'fractions' in opts ? opts.fractions : null;
      let exponents = opts && 'exponents' in opts ? opts.exponents : null;
      function def(value, defaultValue) {
        if (value == null) return defaultValue;
        if (core.List.is(value)) return value;
        return [value];
      }
      dart.fn(def, dynamicAnddynamicTodynamic$());
      signs = def(signs, signList);
      integers = def(integers, integerList);
      fractions = def(fractions, fractionList);
      exponents = def(exponents, exponentList);
      for (let integer of core.Iterable._check(integers)) {
        for (let sign of core.Iterable._check(signs)) {
          for (let fraction of core.Iterable._check(fractions)) {
            for (let exponent of core.Iterable._check(exponents)) {
              let literal = dart.str`${sign}${integer}${fraction}${exponent}`;
              json_test.testThrows(literal);
            }
          }
        }
      }
    }
    dart.fn(testError, __Todynamic());
    json_test.testJson("1e+400", core.double.INFINITY);
    testError({integers: ""});
    testError({signs: "+"});
    testError({fractions: "."});
    testError({exponents: JSArrayOfString().of(["e", "e+", "e-", "e.0"])});
    json_test.testThrows("-2 .2e+2");
    json_test.testThrows("-2. 2e+2");
    json_test.testThrows("-2.2 e+2");
    json_test.testThrows("-2.2e +2");
    json_test.testThrows("-2.2e+ 2");
    json_test.testThrows("[2.,2]");
    json_test.testThrows("{2.:2}");
    json_test.testThrows("NaN");
    json_test.testThrows("Infinity");
    json_test.testThrows("-Infinity");
    expect$.Expect.throws(dart.fn(() => convert.JSON.encode(core.double.NAN), VoidToString()));
    expect$.Expect.throws(dart.fn(() => convert.JSON.encode(core.double.INFINITY), VoidToString()));
    expect$.Expect.throws(dart.fn(() => convert.JSON.encode(core.double.NEGATIVE_INFINITY), VoidToString()));
  };
  dart.fn(json_test.testNumbers, VoidTodynamic());
  json_test.testStrings = function() {
    let input = '"\\u0000\\uffff\\n\\r\\f\\t\\b\\/\\\\\\"' + ' �￿"';
    let expected = " ￿\n\r\f\t\b/\\\" �￿";
    json_test.testJson(input, expected);
    json_test.testJson('""', "");
    let escapes = dart.map({f: "\f", b: "\b", n: "\n", r: "\r", t: "\t", "\\": "\\", '"': '"', "/": "/"}, core.String, core.String);
    escapes[dartx.forEach](dart.fn((esc, lit) => {
      json_test.testJson(dart.str`"\\${esc}........"`, dart.str`${lit}........`);
      json_test.testJson(dart.str`"........\\${esc}"`, dart.str`........${lit}`);
      json_test.testJson(dart.str`"....\\${esc}...."`, dart.str`....${lit}....`);
    }, StringAndStringTovoid()));
    json_test.testThrows("''");
    json_test.testThrows('"......\\"');
    json_test.testThrows('"\\');
    json_test.testThrows('"\\a"');
    json_test.testThrows('"\\u"');
    json_test.testThrows('"\\u1"');
    json_test.testThrows('"\\u12"');
    json_test.testThrows('"\\u123"');
    json_test.testThrows('"\\ux"');
    json_test.testThrows('"\\u1x"');
    json_test.testThrows('"\\u12x"');
    json_test.testThrows('"\\u123x"');
    json_test.testThrows('"\\a"');
    json_test.testThrows('"\\x00"');
    json_test.testThrows('"\\c2"');
    json_test.testThrows('"\\000"');
    json_test.testThrows('"\\u{0}"');
    json_test.testThrows('"\\%"');
    json_test.testThrows('"\\ "');
    for (let i = 0; i < 32; i++) {
      let string = core.String.fromCharCodes(JSArrayOfint().of([34, i, 34]));
      json_test.testThrows(string);
    }
  };
  dart.fn(json_test.testStrings, VoidTodynamic());
  json_test.testObjects = function() {
    json_test.testJson('{}', dart.map());
    json_test.testJson('{"x":42}', dart.map({x: 42}, core.String, core.int));
    json_test.testJson('{"x":{"x":{"x":42}}}', dart.map({x: dart.map({x: dart.map({x: 42}, core.String, core.int)}, core.String, MapOfString$int())}, core.String, MapOfString$MapOfString$int()));
    json_test.testJson('{"x":10,"x":42}', dart.map({x: 42}, core.String, core.int));
    json_test.testJson('{"":42}', dart.map({"": 42}, core.String, core.int));
    json_test.testThrows('{x:10}');
    json_test.testThrows('{true:10}');
    json_test.testThrows('{false:10}');
    json_test.testThrows('{null:10}');
    json_test.testThrows('{42:10}');
    json_test.testThrows('{42e1:10}');
    json_test.testThrows('{-42:10}');
    json_test.testThrows('{["text"]:10}');
    json_test.testThrows('{:10}');
  };
  dart.fn(json_test.testObjects, VoidTodynamic());
  json_test.testArrays = function() {
    json_test.testJson('[]', []);
    json_test.testJson('[1.1e1,"string",true,false,null,{}]', JSArrayOfObject().of([11.0, "string", true, false, null, dart.map()]));
    json_test.testJson('[[[[[[]]]],[[[]]],[[]]]]', JSArrayOfListOfListOfList().of([JSArrayOfListOfList().of([JSArrayOfListOfListOfList().of([JSArrayOfListOfList().of([JSArrayOfList().of([[]])])]), JSArrayOfListOfList().of([JSArrayOfList().of([[]])]), JSArrayOfList().of([[]])])]));
    json_test.testJson('[{},[{}],{"x":[]}]', JSArrayOfObject().of([dart.map(), JSArrayOfMap().of([dart.map()]), dart.map({x: []}, core.String, core.List)]));
    json_test.testThrows('[1,,2]');
    json_test.testThrows('[1,2,]');
    json_test.testThrows('[,2]');
  };
  dart.fn(json_test.testArrays, VoidTodynamic());
  json_test.testWords = function() {
    json_test.testJson('true', true);
    json_test.testJson('false', false);
    json_test.testJson('null', null);
    json_test.testJson('[true]', JSArrayOfbool().of([true]));
    json_test.testJson('{"true":true}', dart.map({true: true}, core.String, core.bool));
    json_test.testThrows('truefalse');
    json_test.testThrows('trues');
    json_test.testThrows('nulll');
    json_test.testThrows('full');
    json_test.testThrows('nul');
    json_test.testThrows('tru');
    json_test.testThrows('fals');
    json_test.testThrows('\\null');
    json_test.testThrows('t\\rue');
    json_test.testThrows('t\\rue');
  };
  dart.fn(json_test.testWords, VoidTodynamic());
  json_test.testWhitespace = function() {
    let v = '\t\r\n ';
    let invalids = JSArrayOfString().of([' ', '\f', '\b', '\\', ' ', '\u2028', '\u2029']);
    json_test.testJson(dart.str`${v}[${v}-2.2e2${v},${v}{${v}"key"${v}:${v}true${v}}${v},${v}"ab"${v}]${v}`, JSArrayOfObject().of([-220.0, dart.map({key: true}, core.String, core.bool), "ab"]));
    for (let i of invalids) {
      json_test.testThrows(dart.str`${i}"s"`);
      json_test.testThrows(dart.str`42${i}`);
      json_test.testThrows(dart.str`${i}[]`);
      json_test.testThrows(dart.str`[${i}]`);
      json_test.testThrows(dart.str`[${i}"s"]`);
      json_test.testThrows(dart.str`["s"${i}]`);
      json_test.testThrows(dart.str`${i}{"k":"v"}`);
      json_test.testThrows(dart.str`{${i}"k":"v"}`);
      json_test.testThrows(dart.str`{"k"${i}:"v"}`);
      json_test.testThrows(dart.str`{"k":${i}"v"}`);
      json_test.testThrows(dart.str`{"k":"v"${i}}`);
    }
  };
  dart.fn(json_test.testWhitespace, VoidTodynamic());
  json_test.main = function() {
    json_test.testNumbers();
    json_test.testStrings();
    json_test.testWords();
    json_test.testObjects();
    json_test.testArrays();
    json_test.testWhitespace();
  };
  dart.fn(json_test.main, VoidTodynamic());
  // Exports:
  exports.json_test = json_test;
});
