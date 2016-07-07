dart_library.library('corelib/string_from_list_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__string_from_list_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const _interceptors = dart_sdk._interceptors;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const string_from_list_test = Object.create(null);
  let ListOfint = () => (ListOfint = dart.constFn(core.List$(core.int)))();
  let JSArrayOfint = () => (JSArrayOfint = dart.constFn(_interceptors.JSArray$(core.int)))();
  let IterableOfint = () => (IterableOfint = dart.constFn(core.Iterable$(core.int)))();
  let intToint = () => (intToint = dart.constFn(dart.definiteFunctionType(core.int, [core.int])))();
  let intTobool = () => (intTobool = dart.constFn(dart.definiteFunctionType(core.bool, [core.int])))();
  let VoidTovoid = () => (VoidTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [])))();
  let const$;
  let const$0;
  let const$1;
  string_from_list_test.main = function() {
    expect$.Expect.equals("", core.String.fromCharCodes(ListOfint().new(0)));
    expect$.Expect.equals("", core.String.fromCharCodes(JSArrayOfint().of([])));
    expect$.Expect.equals("", core.String.fromCharCodes(const$ || (const$ = dart.constList([], core.int))));
    expect$.Expect.equals("AB", core.String.fromCharCodes(JSArrayOfint().of([65, 66])));
    expect$.Expect.equals("AB", core.String.fromCharCodes(const$0 || (const$0 = dart.constList([65, 66], core.int))));
    expect$.Expect.equals("Ærø", core.String.fromCharCodes(const$1 || (const$1 = dart.constList([198, 114, 248], core.int))));
    expect$.Expect.equals("ሴ", core.String.fromCharCodes(JSArrayOfint().of([4660])));
    expect$.Expect.equals("𒍅*", core.String.fromCharCodes(JSArrayOfint().of([74565, 42])));
    expect$.Expect.equals("", core.String.fromCharCodes(ListOfint().new()));
    {
      let a = core.List.new();
      a[dartx.add](65);
      a[dartx.add](66);
      expect$.Expect.equals("AB", core.String.fromCharCodes(IterableOfint()._check(a)));
    }
    for (let len of JSArrayOfint().of([499, 500, 501, 999, 100000])) {
      let list = ListOfint().new(len);
      for (let i = 0; i < dart.notNull(len); i++) {
        list[dartx.set](i, 65 + i[dartx['%']](26));
      }
      for (let i = dart.notNull(len) - 9; i < dart.notNull(len); i++) {
        list[dartx.set](i, 48 + (dart.notNull(len) - i));
      }
      let long = core.String.fromCharCodes(list);
      expect$.Expect.isTrue(long[dartx.startsWith]('ABCDE'));
      expect$.Expect.isTrue(long[dartx.endsWith]('987654321'));
      let middle = (dart.notNull(len) / 2)[dartx.truncate]();
      middle = middle - middle[dartx['%']](26);
      expect$.Expect.equals('XYZABC', long[dartx.substring](middle - 3, middle + 3));
      expect$.Expect.equals(len, long[dartx.length]);
    }
    expect$.Expect.equals("CBA", core.String.fromCharCodes(JSArrayOfint().of([65, 66, 67])[dartx.reversed]));
    expect$.Expect.equals("BCD", core.String.fromCharCodes(JSArrayOfint().of([65, 66, 67])[dartx.map](core.int)(dart.fn(x => dart.notNull(x) + 1, intToint()))));
    expect$.Expect.equals("AC", core.String.fromCharCodes(JSArrayOfint().of([65, 66, 67])[dartx.where](dart.fn(x => x[dartx.isOdd], intTobool()))));
    expect$.Expect.equals("CE", core.String.fromCharCodes(JSArrayOfint().of([65, 66, 67])[dartx.where](dart.fn(x => x[dartx.isOdd], intTobool()))[dartx.map](core.int)(dart.fn(x => dart.notNull(x) + 2, intToint()))));
    expect$.Expect.equals("ABC", core.String.fromCharCodes(IterableOfint().generate(3, dart.fn(x => 65 + dart.notNull(x), intToint()))));
    expect$.Expect.equals("ABC", core.String.fromCharCodes("ABC"[dartx.codeUnits]));
    expect$.Expect.equals("BCD", core.String.fromCharCodes("ABC"[dartx.codeUnits][dartx.map](core.int)(dart.fn(x => dart.notNull(x) + 1, intToint()))));
    expect$.Expect.equals("BCD", core.String.fromCharCodes("ABC"[dartx.runes].map(core.int)(dart.fn(x => dart.notNull(x) + 1, intToint()))));
    let nonBmpCharCodes = JSArrayOfint().of([0, 55314, 56372, 84020, 56372, 55314]);
    let nonBmp = core.String.fromCharCodes(nonBmpCharCodes);
    expect$.Expect.equals(7, nonBmp[dartx.length]);
    expect$.Expect.equals(0, nonBmp[dartx.codeUnitAt](0));
    expect$.Expect.equals(55314, nonBmp[dartx.codeUnitAt](1));
    expect$.Expect.equals(56372, nonBmp[dartx.codeUnitAt](2));
    expect$.Expect.equals(55314, nonBmp[dartx.codeUnitAt](3));
    expect$.Expect.equals(56372, nonBmp[dartx.codeUnitAt](4));
    expect$.Expect.equals(56372, nonBmp[dartx.codeUnitAt](5));
    expect$.Expect.equals(55314, nonBmp[dartx.codeUnitAt](6));
    let reversedNonBmp = core.String.fromCharCodes(nonBmpCharCodes[dartx.reversed]);
    expect$.Expect.equals(7, reversedNonBmp[dartx.length]);
    expect$.Expect.equals(0, reversedNonBmp[dartx.codeUnitAt](6));
    expect$.Expect.equals(55314, reversedNonBmp[dartx.codeUnitAt](5));
    expect$.Expect.equals(56372, reversedNonBmp[dartx.codeUnitAt](4));
    expect$.Expect.equals(56372, reversedNonBmp[dartx.codeUnitAt](3));
    expect$.Expect.equals(55314, reversedNonBmp[dartx.codeUnitAt](2));
    expect$.Expect.equals(56372, reversedNonBmp[dartx.codeUnitAt](1));
    expect$.Expect.equals(55314, reversedNonBmp[dartx.codeUnitAt](0));
    expect$.Expect.equals(nonBmp, core.String.fromCharCodes(nonBmp[dartx.codeUnits]));
    expect$.Expect.equals(nonBmp, core.String.fromCharCodes(nonBmp[dartx.runes]));
  };
  dart.fn(string_from_list_test.main, VoidTovoid());
  // Exports:
  exports.string_from_list_test = string_from_list_test;
});
