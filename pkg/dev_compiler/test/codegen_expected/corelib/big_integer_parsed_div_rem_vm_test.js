dart_library.library('corelib/big_integer_parsed_div_rem_vm_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__big_integer_parsed_div_rem_vm_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const big_integer_parsed_div_rem_vm_test = Object.create(null);
  let StringAndStringAndString__Todynamic = () => (StringAndStringAndString__Todynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [core.String, core.String, core.String, core.String])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  big_integer_parsed_div_rem_vm_test.divRemParsed = function(a, b, quotient, remainder) {
    let int_a = core.int.parse(a);
    let int_b = core.int.parse(b);
    let int_quotient = core.int.parse(quotient);
    let int_remainder = core.int.parse(remainder);
    let computed_quotient = (dart.notNull(int_a) / dart.notNull(int_b))[dartx.truncate]();
    expect$.Expect.equals(int_quotient, computed_quotient);
    let str_quotient = computed_quotient >= 0 ? dart.str`0x${computed_quotient[dartx.toRadixString](16)}` : dart.str`-0x${(-computed_quotient)[dartx.toRadixString](16)}`;
    expect$.Expect.equals(quotient[dartx.toLowerCase](), str_quotient);
    let computed_remainder = dart.asInt(int_a[dartx.remainder](int_b));
    expect$.Expect.equals(int_remainder, computed_remainder);
    let str_remainder = dart.notNull(computed_remainder) >= 0 ? dart.str`0x${computed_remainder[dartx.toRadixString](16)}` : dart.str`-0x${(-dart.notNull(computed_remainder))[dartx.toRadixString](16)}`;
    expect$.Expect.equals(remainder[dartx.toLowerCase](), str_remainder);
  };
  dart.fn(big_integer_parsed_div_rem_vm_test.divRemParsed, StringAndStringAndString__Todynamic());
  big_integer_parsed_div_rem_vm_test.testBigintDivideRemainder = function() {
    let zero = "0x0";
    let one = "0x1";
    let minus_one = "-0x1";
    big_integer_parsed_div_rem_vm_test.divRemParsed(one, one, one, zero);
    big_integer_parsed_div_rem_vm_test.divRemParsed(zero, one, zero, zero);
    big_integer_parsed_div_rem_vm_test.divRemParsed(minus_one, one, minus_one, zero);
    big_integer_parsed_div_rem_vm_test.divRemParsed(one, "0x2", zero, one);
    big_integer_parsed_div_rem_vm_test.divRemParsed(minus_one, "0x7", zero, minus_one);
    big_integer_parsed_div_rem_vm_test.divRemParsed("0xB", "0x7", one, "0x4");
    big_integer_parsed_div_rem_vm_test.divRemParsed("0x12345678", "0x7", "0x299C335", "0x5");
    big_integer_parsed_div_rem_vm_test.divRemParsed("-0x12345678", "0x7", "-0x299C335", "-0x5");
    big_integer_parsed_div_rem_vm_test.divRemParsed("0x12345678", "-0x7", "-0x299C335", "0x5");
    big_integer_parsed_div_rem_vm_test.divRemParsed("-0x12345678", "-0x7", "0x299C335", "-0x5");
    big_integer_parsed_div_rem_vm_test.divRemParsed("0x7", "0x12345678", zero, "0x7");
    big_integer_parsed_div_rem_vm_test.divRemParsed("-0x7", "0x12345678", zero, "-0x7");
    big_integer_parsed_div_rem_vm_test.divRemParsed("-0x7", "-0x12345678", zero, "-0x7");
    big_integer_parsed_div_rem_vm_test.divRemParsed("0x7", "-0x12345678", zero, "0x7");
    big_integer_parsed_div_rem_vm_test.divRemParsed("0x12345678", "0x7", "0x299C335", "0x5");
    big_integer_parsed_div_rem_vm_test.divRemParsed("-0x12345678", "0x7", "-0x299C335", "-0x5");
    big_integer_parsed_div_rem_vm_test.divRemParsed("0x12345678", "-0x7", "-0x299C335", "0x5");
    big_integer_parsed_div_rem_vm_test.divRemParsed("-0x12345678", "-0x7", "0x299C335", "-0x5");
    big_integer_parsed_div_rem_vm_test.divRemParsed("0x14B66DC327D3C88D7EAA988BBFFA9BBA877826E7EDAF373907A931FBFC3A25231DF7F2" + "516F511FB1638F0B570F4A8F0B570F4A8F0B570F4A8F0B570F4A8F0B570F4A8F0B570F4A" + "8F0B570F4A8F0B570F4A8F0B570F4A8F0B570F4A8F0B570F4A8F0B570F4A8F0B570F4A8F" + "0B570F4A8F0B570F4A8F0B570F4A8F0B570F4A8F0B570F4A8F0B570F4A8F0B570F4A8F0B" + "570F4A8F0B570F4A8F0B570F4A8F0B570F4A8F0B570F4A8F0B570F4A8F0B570F4A8F0B57" + "0F4A8F0B570F4A8F0B570F4A8F0B570F35D89D93E776C67DD864B2034B5C739007933027" + "5CDFD41E07A15D0F5AD5256BED5F1CF91FBA375DE70", "0x1234567890ABCDEF01234567890ABCDEF01234567890ABCDEF01234567890ABCDEF" + "01234567890ABCDEF", "0x1234567890123456789012345678901234567890123456789012345678901234567890" + "123456789012345678901234567890123456789012345678901234567890123456789012" + "345678901234567890123456789012345678901234567890123456789012345678901234" + "567890123456789012345678901234567890123456789012345678901234567890123456" + "789012345678901234567890123456789012345678901234567890123456789012345678" + "90123456789012345678901234567890", zero);
    big_integer_parsed_div_rem_vm_test.divRemParsed("0x14B66DC327D3C88D7EAA988BBFFA9BBA877826E7EDAF373907A931FBFC3A25231DF7F2" + "516F511FB1638F0B570F4A8F0B570F4A8F0B570F4A8F0B570F4A8F0B570F4A8F0B570F4A" + "8F0B570F4A8F0B570F4A8F0B570F4A8F0B570F4A8F0B570F4A8F0B570F4A8F0B570F4A8F" + "0B570F4A8F0B570F4A8F0B570F4A8F0B570F4A8F0B570F4A8F0B570F4A8F0B570F4A8F0B" + "570F4A8F0B570F4A8F0B570F4A8F0B570F4A8F0B570F4A8F0B570F4A8F0B570F4A8F0B57" + "0F4A8F0B570F4A8F0B570F4A8F0B570F35D89D93E776C67DD864B2034B5C739007933027" + "5CDFD41E07A15D0F5AD5256BED5F1CF91FBA375DE71", "0x1234567890ABCDEF01234567890ABCDEF01234567890ABCDEF01234567890ABCDEF" + "01234567890ABCDEF", "0x1234567890123456789012345678901234567890123456789012345678901234567890" + "123456789012345678901234567890123456789012345678901234567890123456789012" + "345678901234567890123456789012345678901234567890123456789012345678901234" + "567890123456789012345678901234567890123456789012345678901234567890123456" + "789012345678901234567890123456789012345678901234567890123456789012345678" + "90123456789012345678901234567890", one);
    big_integer_parsed_div_rem_vm_test.divRemParsed("0x14B66DC327D3C88D7EAA988BBFFA9BBA877826E7EDAF373907A931FBFC3A25231DF7F2" + "516F511FB1638F0B570F4A8F0B570F4A8F0B570F4A8F0B570F4A8F0B570F4A8F0B570F4A" + "8F0B570F4A8F0B570F4A8F0B570F4A8F0B570F4A8F0B570F4A8F0B570F4A8F0B570F4A8F" + "0B570F4A8F0B570F4A8F0B570F4A8F0B570F4A8F0B570F4A8F0B570F4A8F0B570F4A8F0B" + "570F4A8F0B570F4A8F0B570F4A8F0B570F4A8F0B570F4A8F0B570F4A8F0B570F4A8F0B57" + "0F4A8F0B570F4A8F0B570F4A8F0B5710591E051CF233A56DEA99087BDC08417F08B6758E" + "E5EA90FCF7B39165D365D139DC60403E8743421AC5E", "0x1234567890ABCDEF01234567890ABCDEF01234567890ABCDEF01234567890ABCDEF" + "01234567890ABCDEF", "0x1234567890123456789012345678901234567890123456789012345678901234567890" + "123456789012345678901234567890123456789012345678901234567890123456789012" + "345678901234567890123456789012345678901234567890123456789012345678901234" + "567890123456789012345678901234567890123456789012345678901234567890123456" + "789012345678901234567890123456789012345678901234567890123456789012345678" + "90123456789012345678901234567890", "0x1234567890ABCDEF01234567890ABCDEF01234567890ABCDEF01234567890ABCDEF" + "01234567890ABCDEE");
  };
  dart.fn(big_integer_parsed_div_rem_vm_test.testBigintDivideRemainder, VoidTodynamic());
  big_integer_parsed_div_rem_vm_test.main = function() {
    big_integer_parsed_div_rem_vm_test.testBigintDivideRemainder();
  };
  dart.fn(big_integer_parsed_div_rem_vm_test.main, VoidTodynamic());
  // Exports:
  exports.big_integer_parsed_div_rem_vm_test = big_integer_parsed_div_rem_vm_test;
});
