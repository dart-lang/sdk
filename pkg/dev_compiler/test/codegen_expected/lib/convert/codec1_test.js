dart_library.library('lib/convert/codec1_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__codec1_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const convert = dart_sdk.convert;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const codec1_test = Object.create(null);
  let CodecOfString$dynamic = () => (CodecOfString$dynamic = dart.constFn(convert.Codec$(core.String, dart.dynamic)))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  codec1_test.IntStringConverter = class IntStringConverter extends convert.Converter$(core.int, core.String) {
    new() {
      super.new();
    }
    convert(i) {
      return dart.toString(i);
    }
  };
  dart.addSimpleTypeTests(codec1_test.IntStringConverter);
  dart.setSignature(codec1_test.IntStringConverter, {
    constructors: () => ({new: dart.definiteFunctionType(codec1_test.IntStringConverter, [])}),
    methods: () => ({convert: dart.definiteFunctionType(core.String, [core.int])})
  });
  let const$;
  codec1_test.StringIntConverter = class StringIntConverter extends convert.Converter$(core.String, core.int) {
    new() {
      super.new();
    }
    convert(str) {
      return core.int.parse(str);
    }
  };
  dart.addSimpleTypeTests(codec1_test.StringIntConverter);
  dart.setSignature(codec1_test.StringIntConverter, {
    constructors: () => ({new: dart.definiteFunctionType(codec1_test.StringIntConverter, [])}),
    methods: () => ({convert: dart.definiteFunctionType(core.int, [core.String])})
  });
  let const$0;
  codec1_test.MyCodec = class MyCodec extends convert.Codec$(core.int, core.String) {
    new() {
      this.encoder = const$ || (const$ = dart.const(new codec1_test.IntStringConverter()));
      this.decoder = const$0 || (const$0 = dart.const(new codec1_test.StringIntConverter()));
      super.new();
    }
  };
  dart.addSimpleTypeTests(codec1_test.MyCodec);
  dart.setSignature(codec1_test.MyCodec, {
    constructors: () => ({new: dart.definiteFunctionType(codec1_test.MyCodec, [])})
  });
  codec1_test.MyCodec2 = class MyCodec2 extends convert.Codec$(core.int, core.String) {
    new() {
      super.new();
    }
    get encoder() {
      return new codec1_test.IntStringConverter2();
    }
    get decoder() {
      return new codec1_test.StringIntConverter2();
    }
  };
  dart.addSimpleTypeTests(codec1_test.MyCodec2);
  dart.setSignature(codec1_test.MyCodec2, {
    constructors: () => ({new: dart.definiteFunctionType(codec1_test.MyCodec2, [])})
  });
  codec1_test.IntStringConverter2 = class IntStringConverter2 extends convert.Converter$(core.int, core.String) {
    new() {
      super.new();
    }
    convert(i) {
      return dart.toString(dart.notNull(i) + 99);
    }
  };
  dart.addSimpleTypeTests(codec1_test.IntStringConverter2);
  dart.setSignature(codec1_test.IntStringConverter2, {
    methods: () => ({convert: dart.definiteFunctionType(core.String, [core.int])})
  });
  codec1_test.StringIntConverter2 = class StringIntConverter2 extends convert.Converter$(core.String, core.int) {
    new() {
      super.new();
    }
    convert(str) {
      return dart.notNull(core.int.parse(str)) + 400;
    }
  };
  dart.addSimpleTypeTests(codec1_test.StringIntConverter2);
  dart.setSignature(codec1_test.StringIntConverter2, {
    methods: () => ({convert: dart.definiteFunctionType(core.int, [core.String])})
  });
  codec1_test.TEST_CODEC = dart.const(new codec1_test.MyCodec());
  codec1_test.TEST_CODEC2 = dart.const(new codec1_test.MyCodec2());
  codec1_test.main = function() {
    expect$.Expect.equals("0", codec1_test.TEST_CODEC.encode(0));
    expect$.Expect.equals(5, codec1_test.TEST_CODEC.decode("5"));
    expect$.Expect.equals(3, codec1_test.TEST_CODEC.decode(codec1_test.TEST_CODEC.encode(3)));
    expect$.Expect.equals("99", codec1_test.TEST_CODEC2.encode(0));
    expect$.Expect.equals(405, codec1_test.TEST_CODEC2.decode("5"));
    expect$.Expect.equals(499, codec1_test.TEST_CODEC2.decode(codec1_test.TEST_CODEC2.encode(0)));
    let inverted = null, fused = null;
    inverted = codec1_test.TEST_CODEC.inverted;
    fused = codec1_test.TEST_CODEC.fuse(CodecOfString$dynamic()._check(inverted));
    expect$.Expect.equals(499, dart.dsend(fused, 'encode', 499));
    expect$.Expect.equals(499, dart.dsend(fused, 'decode', 499));
    fused = dart.dsend(inverted, 'fuse', codec1_test.TEST_CODEC);
    expect$.Expect.equals("499", dart.dsend(fused, 'encode', "499"));
    expect$.Expect.equals("499", dart.dsend(fused, 'decode', "499"));
    inverted = codec1_test.TEST_CODEC2.inverted;
    fused = codec1_test.TEST_CODEC2.fuse(CodecOfString$dynamic()._check(inverted));
    expect$.Expect.equals(499, dart.dsend(fused, 'encode', 0));
    expect$.Expect.equals(499, dart.dsend(fused, 'decode', 0));
    fused = codec1_test.TEST_CODEC.fuse(CodecOfString$dynamic()._check(inverted));
    expect$.Expect.equals(405, dart.dsend(fused, 'encode', 5));
    expect$.Expect.equals(101, dart.dsend(fused, 'decode', 2));
  };
  dart.fn(codec1_test.main, VoidTodynamic());
  // Exports:
  exports.codec1_test = codec1_test;
});
