define(['dart_sdk'], function(dart_sdk) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect = Object.create(null);
  let VoidTovoid = () => (VoidTovoid = dart.constFn(dart.functionType(dart.void, [])))();
  let dynamicAnddynamicTobool = () => (dynamicAnddynamicTobool = dart.constFn(dart.definiteFunctionType(core.bool, [dart.dynamic, dart.dynamic])))();
  expect.Expect = class Expect extends core.Object {
    static _truncateString(string, start, end, length) {
      if (dart.notNull(end) - dart.notNull(start) > dart.notNull(length)) {
        end = dart.notNull(start) + dart.notNull(length);
      } else if (dart.notNull(end) - dart.notNull(start) < dart.notNull(length)) {
        let overflow = dart.notNull(length) - (dart.notNull(end) - dart.notNull(start));
        if (overflow > 10) overflow = 10;
        start = dart.notNull(start) - ((overflow + 1) / 2)[dartx.truncate]();
        end = dart.notNull(end) + (overflow / 2)[dartx.truncate]();
        if (dart.notNull(start) < 0) start = 0;
        if (dart.notNull(end) > dart.notNull(string[dartx.length])) end = string[dartx.length];
      }
      if (start == 0 && end == string[dartx.length]) return string;
      let buf = new core.StringBuffer();
      if (dart.notNull(start) > 0) buf.write("...");
      for (let i = start; dart.notNull(i) < dart.notNull(end); i = dart.notNull(i) + 1) {
        let code = string[dartx.codeUnitAt](i);
        if (dart.notNull(code) < 32) {
          buf.write("\\x");
          buf.write("0123456789abcdef"[dartx.get]((dart.notNull(code) / 16)[dartx.truncate]()));
          buf.write("0123456789abcdef"[dartx.get](code[dartx['%']](16)));
        } else {
          buf.writeCharCode(string[dartx.codeUnitAt](i));
        }
      }
      if (dart.notNull(end) < dart.notNull(string[dartx.length])) buf.write("...");
      return buf.toString();
    }
    static _stringDifference(expected, actual) {
      if (dart.notNull(expected[dartx.length]) < 20 && dart.notNull(actual[dartx.length]) < 20) return null;
      for (let i = 0; i < dart.notNull(expected[dartx.length]) && i < dart.notNull(actual[dartx.length]); i++) {
        if (expected[dartx.codeUnitAt](i) != actual[dartx.codeUnitAt](i)) {
          let start = i;
          i++;
          while (i < dart.notNull(expected[dartx.length]) && i < dart.notNull(actual[dartx.length])) {
            if (expected[dartx.codeUnitAt](i) == actual[dartx.codeUnitAt](i)) break;
            i++;
          }
          let end = i;
          let truncExpected = expect.Expect._truncateString(expected, start, end, 20);
          let truncActual = expect.Expect._truncateString(actual, start, end, 20);
          return dart.str`at index ${start}: Expected <${truncExpected}>, ` + dart.str`Found: <${truncActual}>`;
        }
      }
      return null;
    }
    static equals(expected, actual, reason) {
      if (reason === void 0) reason = null;
      if (dart.equals(expected, actual)) return;
      let msg = expect.Expect._getMessage(reason);
      if (typeof expected == 'string' && typeof actual == 'string') {
        let stringDifference = expect.Expect._stringDifference(expected, actual);
        if (stringDifference != null) {
          expect.Expect._fail(dart.str`Expect.equals(${stringDifference}${msg}) fails.`);
        }
      }
      expect.Expect._fail(dart.str`Expect.equals(expected: <${expected}>, actual: <${actual}>${msg}) fails.`);
    }
    static isTrue(actual, reason) {
      if (reason === void 0) reason = null;
      if (dart.test(expect._identical(actual, true))) return;
      let msg = expect.Expect._getMessage(reason);
      expect.Expect._fail(dart.str`Expect.isTrue(${actual}${msg}) fails.`);
    }
    static isFalse(actual, reason) {
      if (reason === void 0) reason = null;
      if (dart.test(expect._identical(actual, false))) return;
      let msg = expect.Expect._getMessage(reason);
      expect.Expect._fail(dart.str`Expect.isFalse(${actual}${msg}) fails.`);
    }
    static isNull(actual, reason) {
      if (reason === void 0) reason = null;
      if (null == actual) return;
      let msg = expect.Expect._getMessage(reason);
      expect.Expect._fail(dart.str`Expect.isNull(actual: <${actual}>${msg}) fails.`);
    }
    static isNotNull(actual, reason) {
      if (reason === void 0) reason = null;
      if (null != actual) return;
      let msg = expect.Expect._getMessage(reason);
      expect.Expect._fail(dart.str`Expect.isNotNull(actual: <${actual}>${msg}) fails.`);
    }
    static identical(expected, actual, reason) {
      if (reason === void 0) reason = null;
      if (dart.test(expect._identical(expected, actual))) return;
      let msg = expect.Expect._getMessage(reason);
      expect.Expect._fail(dart.str`Expect.identical(expected: <${expected}>, actual: <${actual}>${msg}) ` + "fails.");
    }
    static fail(msg) {
      expect.Expect._fail(dart.str`Expect.fail('${msg}')`);
    }
    static approxEquals(expected, actual, tolerance, reason) {
      if (tolerance === void 0) tolerance = null;
      if (reason === void 0) reason = null;
      if (tolerance == null) {
        tolerance = (dart.notNull(expected) / 10000.0)[dartx.abs]();
      }
      if (dart.notNull((dart.notNull(expected) - dart.notNull(actual))[dartx.abs]()) <= dart.notNull(tolerance)) return;
      let msg = expect.Expect._getMessage(reason);
      expect.Expect._fail(dart.str`Expect.approxEquals(expected:<${expected}>, actual:<${actual}>, ` + dart.str`tolerance:<${tolerance}>${msg}) fails`);
    }
    static notEquals(unexpected, actual, reason) {
      if (reason === void 0) reason = null;
      if (!dart.equals(unexpected, actual)) return;
      let msg = expect.Expect._getMessage(reason);
      expect.Expect._fail(dart.str`Expect.notEquals(unexpected: <${unexpected}>, actual:<${actual}>${msg}) ` + "fails.");
    }
    static listEquals(expected, actual, reason) {
      if (reason === void 0) reason = null;
      let msg = expect.Expect._getMessage(reason);
      let n = dart.notNull(expected[dartx.length]) < dart.notNull(actual[dartx.length]) ? expected[dartx.length] : actual[dartx.length];
      for (let i = 0; i < dart.notNull(n); i++) {
        if (!dart.equals(expected[dartx.get](i), actual[dartx.get](i))) {
          expect.Expect._fail(dart.str`Expect.listEquals(at index ${i}, ` + dart.str`expected: <${expected[dartx.get](i)}>, actual: <${actual[dartx.get](i)}>${msg}) fails`);
        }
      }
      if (expected[dartx.length] != actual[dartx.length]) {
        expect.Expect._fail('Expect.listEquals(list length, ' + dart.str`expected: <${expected[dartx.length]}>, actual: <${actual[dartx.length]}>${msg}) ` + 'fails: Next element <' + dart.str`${dart.notNull(expected[dartx.length]) > dart.notNull(n) ? expected[dartx.get](n) : actual[dartx.get](n)}>`);
      }
    }
    static mapEquals(expected, actual, reason) {
      if (reason === void 0) reason = null;
      let msg = expect.Expect._getMessage(reason);
      for (let key of expected[dartx.keys]) {
        if (!dart.test(actual[dartx.containsKey](key))) {
          expect.Expect._fail(dart.str`Expect.mapEquals(missing expected key: <${key}>${msg}) fails`);
        }
        expect.Expect.equals(expected[dartx.get](key), actual[dartx.get](key));
      }
      for (let key of actual[dartx.keys]) {
        if (!dart.test(expected[dartx.containsKey](key))) {
          expect.Expect._fail(dart.str`Expect.mapEquals(unexpected key: <${key}>${msg}) fails`);
        }
      }
    }
    static stringEquals(expected, actual, reason) {
      if (reason === void 0) reason = null;
      if (expected == actual) return;
      let msg = expect.Expect._getMessage(reason);
      let defaultMessage = dart.str`Expect.stringEquals(expected: <${expected}>", <${actual}>${msg}) fails`;
      if (expected == null || actual == null) {
        expect.Expect._fail(dart.str`${defaultMessage}`);
      }
      let left = 0;
      let right = 0;
      let eLen = expected[dartx.length];
      let aLen = actual[dartx.length];
      while (true) {
        if (left == eLen || left == aLen || expected[dartx.get](left) != actual[dartx.get](left)) {
          break;
        }
        left++;
      }
      let eRem = dart.notNull(eLen) - left;
      let aRem = dart.notNull(aLen) - left;
      while (true) {
        if (right == eRem || right == aRem || expected[dartx.get](dart.notNull(eLen) - right - 1) != actual[dartx.get](dart.notNull(aLen) - right - 1)) {
          break;
        }
        right++;
      }
      let leftSnippet = expected[dartx.substring](left < 10 ? 0 : left - 10, left);
      let rightSnippetLength = right < 10 ? right : 10;
      let rightSnippet = expected[dartx.substring](dart.notNull(eLen) - right, dart.notNull(eLen) - right + rightSnippetLength);
      let eSnippet = expected[dartx.substring](left, dart.notNull(eLen) - right);
      let aSnippet = actual[dartx.substring](left, dart.notNull(aLen) - right);
      if (dart.notNull(eSnippet[dartx.length]) > 43) {
        eSnippet = dart.notNull(eSnippet[dartx.substring](0, 20)) + "..." + dart.notNull(eSnippet[dartx.substring](dart.notNull(eSnippet[dartx.length]) - 20));
      }
      if (dart.notNull(aSnippet[dartx.length]) > 43) {
        aSnippet = dart.notNull(aSnippet[dartx.substring](0, 20)) + "..." + dart.notNull(aSnippet[dartx.substring](dart.notNull(aSnippet[dartx.length]) - 20));
      }
      let leftLead = "...";
      let rightTail = "...";
      if (left <= 10) leftLead = "";
      if (right <= 10) rightTail = "";
      let diff = dart.str`\nDiff (${left}..${dart.notNull(eLen) - right}/${dart.notNull(aLen) - right}):\n` + dart.str`${leftLead}${leftSnippet}[ ${eSnippet} ]${rightSnippet}${rightTail}\n` + dart.str`${leftLead}${leftSnippet}[ ${aSnippet} ]${rightSnippet}${rightTail}`;
      expect.Expect._fail(dart.str`${defaultMessage}${diff}`);
    }
    static setEquals(expected, actual, reason) {
      if (reason === void 0) reason = null;
      let missingSet = core.Set.from(expected);
      missingSet.removeAll(actual);
      let extraSet = core.Set.from(actual);
      extraSet.removeAll(expected);
      if (dart.test(extraSet.isEmpty) && dart.test(missingSet.isEmpty)) return;
      let msg = expect.Expect._getMessage(reason);
      let sb = new core.StringBuffer(dart.str`Expect.setEquals(${msg}) fails`);
      if (!dart.test(missingSet.isEmpty)) {
        sb.write('\nExpected collection does not contain: ');
      }
      for (let val of missingSet) {
        sb.write(dart.str`${val} `);
      }
      if (!dart.test(extraSet.isEmpty)) {
        sb.write('\nExpected collection should not contain: ');
      }
      for (let val of extraSet) {
        sb.write(dart.str`${val} `);
      }
      expect.Expect._fail(sb.toString());
    }
    static deepEquals(expected, actual) {
      if (dart.equals(expected, actual)) return;
      if (typeof expected == 'string' && typeof actual == 'string') {
        expect.Expect.stringEquals(expected, actual);
      } else if (core.Iterable.is(expected) && core.Iterable.is(actual)) {
        let expectedLength = expected[dartx.length];
        let actualLength = actual[dartx.length];
        let length = dart.notNull(expectedLength) < dart.notNull(actualLength) ? expectedLength : actualLength;
        for (let i = 0; i < dart.notNull(length); i++) {
          expect.Expect.deepEquals(expected[dartx.elementAt](i), actual[dartx.elementAt](i));
        }
        if (expectedLength != actualLength) {
          let nextElement = (dart.notNull(expectedLength) > dart.notNull(length) ? expected : actual)[dartx.elementAt](length);
          expect.Expect._fail('Expect.deepEquals(list length, ' + dart.str`expected: <${expectedLength}>, actual: <${actualLength}>) ` + dart.str`fails: Next element <${nextElement}>`);
        }
      } else if (core.Map.is(expected) && core.Map.is(actual)) {
        for (let key of expected[dartx.keys]) {
          if (!dart.test(actual[dartx.containsKey](key))) {
            expect.Expect._fail(dart.str`Expect.deepEquals(missing expected key: <${key}>) fails`);
          }
          expect.Expect.deepEquals(expected[dartx.get](key), actual[dartx.get](key));
        }
        for (let key of actual[dartx.keys]) {
          if (!dart.test(expected[dartx.containsKey](key))) {
            expect.Expect._fail(dart.str`Expect.deepEquals(unexpected key: <${key}>) fails`);
          }
        }
      } else {
        expect.Expect._fail(dart.str`Expect.deepEquals(expected: <${expected}>, actual: <${actual}>) ` + "fails.");
      }
    }
    static throws(f, check, reason) {
      if (check === void 0) check = null;
      if (reason === void 0) reason = null;
      let msg = reason == null ? "" : dart.str`(${reason})`;
      if (!expect._Nullary.is(f)) {
        expect.Expect._fail(dart.str`Expect.throws${msg}: Function f not callable with zero arguments`);
      }
      try {
        f();
      } catch (e) {
        let s = dart.stackTrace(e);
        if (check != null) {
          if (!dart.test(dart.dcall(check, e))) {
            expect.Expect._fail(dart.str`Expect.throws${msg}: Unexpected '${e}'\n${s}`);
          }
        }
        return;
      }

      expect.Expect._fail(dart.str`Expect.throws${msg} fails: Did not throw`);
    }
    static _getMessage(reason) {
      return reason == null ? "" : dart.str`, '${reason}'`;
    }
    static _fail(message) {
      dart.throw(new expect.ExpectException(message));
    }
  };
  dart.setSignature(expect.Expect, {
    statics: () => ({
      _truncateString: dart.definiteFunctionType(core.String, [core.String, core.int, core.int, core.int]),
      _stringDifference: dart.definiteFunctionType(core.String, [core.String, core.String]),
      equals: dart.definiteFunctionType(dart.void, [dart.dynamic, dart.dynamic], [core.String]),
      isTrue: dart.definiteFunctionType(dart.void, [dart.dynamic], [core.String]),
      isFalse: dart.definiteFunctionType(dart.void, [dart.dynamic], [core.String]),
      isNull: dart.definiteFunctionType(dart.void, [dart.dynamic], [core.String]),
      isNotNull: dart.definiteFunctionType(dart.void, [dart.dynamic], [core.String]),
      identical: dart.definiteFunctionType(dart.void, [dart.dynamic, dart.dynamic], [core.String]),
      fail: dart.definiteFunctionType(dart.void, [core.String]),
      approxEquals: dart.definiteFunctionType(dart.void, [core.num, core.num], [core.num, core.String]),
      notEquals: dart.definiteFunctionType(dart.void, [dart.dynamic, dart.dynamic], [core.String]),
      listEquals: dart.definiteFunctionType(dart.void, [core.List, core.List], [core.String]),
      mapEquals: dart.definiteFunctionType(dart.void, [core.Map, core.Map], [core.String]),
      stringEquals: dart.definiteFunctionType(dart.void, [core.String, core.String], [core.String]),
      setEquals: dart.definiteFunctionType(dart.void, [core.Iterable, core.Iterable], [core.String]),
      deepEquals: dart.definiteFunctionType(dart.void, [core.Object, core.Object]),
      throws: dart.definiteFunctionType(dart.void, [VoidTovoid()], [expect._CheckExceptionFn, core.String]),
      _getMessage: dart.definiteFunctionType(core.String, [core.String]),
      _fail: dart.definiteFunctionType(dart.void, [core.String])
    }),
    names: ['_truncateString', '_stringDifference', 'equals', 'isTrue', 'isFalse', 'isNull', 'isNotNull', 'identical', 'fail', 'approxEquals', 'notEquals', 'listEquals', 'mapEquals', 'stringEquals', 'setEquals', 'deepEquals', 'throws', '_getMessage', '_fail']
  });
  expect._identical = function(a, b) {
    return core.identical(a, b);
  };
  dart.fn(expect._identical, dynamicAnddynamicTobool());
  expect._CheckExceptionFn = dart.typedef('_CheckExceptionFn', () => dart.functionType(core.bool, [dart.dynamic]));
  expect._Nullary = dart.typedef('_Nullary', () => dart.functionType(dart.dynamic, []));
  expect.ExpectException = class ExpectException extends core.Object {
    new(message) {
      this.message = message;
    }
    toString() {
      return this.message;
    }
  };
  expect.ExpectException[dart.implements] = () => [core.Exception];
  dart.setSignature(expect.ExpectException, {
    constructors: () => ({new: dart.definiteFunctionType(expect.ExpectException, [core.String])}),
    fields: () => ({message: core.String})
  });
  expect.NoInline = class NoInline extends core.Object {
    new() {
    }
  };
  dart.setSignature(expect.NoInline, {
    constructors: () => ({new: dart.definiteFunctionType(expect.NoInline, [])})
  });
  expect.TrustTypeAnnotations = class TrustTypeAnnotations extends core.Object {
    new() {
    }
  };
  dart.setSignature(expect.TrustTypeAnnotations, {
    constructors: () => ({new: dart.definiteFunctionType(expect.TrustTypeAnnotations, [])})
  });
  expect.AssumeDynamic = class AssumeDynamic extends core.Object {
    new() {
    }
  };
  dart.setSignature(expect.AssumeDynamic, {
    constructors: () => ({new: dart.definiteFunctionType(expect.AssumeDynamic, [])})
  });
  // Exports:
  return {
    expect: expect
  };
});
