dart_library.library('lib/convert/line_splitter_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__line_splitter_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const convert = dart_sdk.convert;
  const math = dart_sdk.math;
  const _interceptors = dart_sdk._interceptors;
  const async = dart_sdk.async;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const line_splitter_test = Object.create(null);
  let JSArrayOfString = () => (JSArrayOfString = dart.constFn(_interceptors.JSArray$(core.String)))();
  let SinkOfString = () => (SinkOfString = dart.constFn(core.Sink$(core.String)))();
  let VoidTovoid = () => (VoidTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [])))();
  let dynamicAndStringTodynamic = () => (dynamicAndStringTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [dart.dynamic, core.String])))();
  let StringToString = () => (StringToString = dart.constFn(dart.definiteFunctionType(core.String, [core.String])))();
  let dynamicTovoid = () => (dynamicTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [dart.dynamic])))();
  let StringTovoid = () => (StringTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [core.String])))();
  line_splitter_test.lineTerminators = dart.constList(['\n', '\r', '\r\n'], core.String);
  line_splitter_test.main = function() {
    line_splitter_test.testSimpleConvert();
    line_splitter_test.testSplit();
    line_splitter_test.testSplitWithOffsets();
    line_splitter_test.testManyLines();
    line_splitter_test.testReadLine1();
    line_splitter_test.testReadLine2();
    line_splitter_test.testChunkedConversion();
  };
  dart.fn(line_splitter_test.main, VoidTovoid());
  let const$;
  line_splitter_test.testManyLines = function() {
    let breakIndex = 0;
    let inputs = const$ || (const$ = dart.constList(['line1', 'line2', 'long line 3', ' line 4 ', 'l5'], core.String));
    let buffer = inputs[dartx.fold](dart.dynamic)(new core.StringBuffer(), dart.fn((buff, e) => {
      dart.dsend(buff, 'write', e);
      dart.dsend(buff, 'write', line_splitter_test.lineTerminators[dartx.get](breakIndex));
      breakIndex++;
      breakIndex = breakIndex[dartx['%']](line_splitter_test.lineTerminators[dartx.length]);
      return buff;
    }, dynamicAndStringTodynamic()));
    let foo = line_splitter_test._getLinesSliced(dart.toString(buffer));
    expect$.Expect.equals(inputs[dartx.join](), foo);
  };
  dart.fn(line_splitter_test.testManyLines, VoidTovoid());
  line_splitter_test._getLinesSliced = function(str) {
    let lines = null;
    let stringSink = convert.StringConversionSink.withCallback(dart.fn(result => lines = result, StringToString()));
    let sink = new convert.LineSplitter().startChunkedConversion(stringSink);
    let chunkSize = 3;
    let index = 0;
    while (index < dart.notNull(str[dartx.length])) {
      let end = math.min(core.int)(str[dartx.length], index + chunkSize);
      sink.addSlice(str, index, end, false);
      index = index + chunkSize;
    }
    sink.close();
    return lines;
  };
  dart.fn(line_splitter_test._getLinesSliced, StringToString());
  line_splitter_test.testSimpleConvert = function() {
    let decoder = new convert.LineSplitter();
    for (let lf of line_splitter_test.lineTerminators) {
      let test = dart.str`line1${lf}line2${lf}line3`;
      let result = decoder.convert(test);
      expect$.Expect.listEquals(JSArrayOfString().of(['line1', 'line2', 'line3']), result);
    }
    let test = "Line1\nLine2\r\nLine3\rLine4\n\n\n\r\n\r\n\r\r";
    let result = decoder.convert(test);
    expect$.Expect.listEquals(JSArrayOfString().of(['Line1', 'Line2', 'Line3', 'Line4', '', '', '', '', '', '']), result);
  };
  dart.fn(line_splitter_test.testSimpleConvert, VoidTovoid());
  let const$0;
  line_splitter_test.testReadLine1 = function() {
    let controller = async.StreamController.new({sync: true});
    let stream = controller.stream.transform(core.String)(convert.UTF8.decoder).transform(core.String)(const$0 || (const$0 = dart.const(new convert.LineSplitter())));
    let stage = 0;
    let done = false;
    function stringData(line) {
      expect$.Expect.equals(stage, 0);
      expect$.Expect.equals("Line", line);
      stage++;
    }
    dart.fn(stringData, dynamicTovoid());
    function streamClosed() {
      expect$.Expect.equals(1, stage);
      done = true;
    }
    dart.fn(streamClosed, VoidTovoid());
    stream.listen(stringData, {onDone: streamClosed});
    controller.add("Line"[dartx.codeUnits]);
    controller.close();
    expect$.Expect.isTrue(done, 'should be done by now');
  };
  dart.fn(line_splitter_test.testReadLine1, VoidTovoid());
  let const$1;
  line_splitter_test.testReadLine2 = function() {
    let controller = async.StreamController.new({sync: true});
    let stream = controller.stream.transform(core.String)(convert.UTF8.decoder).transform(core.String)(const$1 || (const$1 = dart.const(new convert.LineSplitter())));
    let expectedLines = JSArrayOfString().of(['Line1', 'Line2', 'Line3', 'Line4', '', '', '', '', '', '', 'Line5', 'Line6']);
    let index = 0;
    stream.listen(dart.fn(line => {
      expect$.Expect.equals(expectedLines[dartx.get](index++), line);
    }, StringTovoid()));
    controller.add("Line1\nLine2\r\nLine3\rLi"[dartx.codeUnits]);
    controller.add("ne4\n"[dartx.codeUnits]);
    controller.add("\n\n\r\n\r\n\r\r"[dartx.codeUnits]);
    controller.add("Line5\r"[dartx.codeUnits]);
    controller.add("\nLine6\n"[dartx.codeUnits]);
    controller.close();
    expect$.Expect.equals(expectedLines[dartx.length], index);
  };
  dart.fn(line_splitter_test.testReadLine2, VoidTovoid());
  line_splitter_test.testSplit = function() {
    for (let lf of line_splitter_test.lineTerminators) {
      let test = dart.str`line1${lf}line2${lf}line3`;
      let result = convert.LineSplitter.split(test)[dartx.toList]();
      expect$.Expect.listEquals(JSArrayOfString().of(['line1', 'line2', 'line3']), result);
    }
    let test = "Line1\nLine2\r\nLine3\rLine4\n\n\n\r\n\r\n\r\r";
    let result = convert.LineSplitter.split(test)[dartx.toList]();
    expect$.Expect.listEquals(JSArrayOfString().of(['Line1', 'Line2', 'Line3', 'Line4', '', '', '', '', '', '']), result);
  };
  dart.fn(line_splitter_test.testSplit, VoidTovoid());
  line_splitter_test.testSplitWithOffsets = function() {
    for (let lf of line_splitter_test.lineTerminators) {
      let test = dart.str`line1${lf}line2${lf}line3`;
      let i2 = 5 + dart.notNull(lf[dartx.length]);
      expect$.Expect.equals(5 + dart.notNull(lf[dartx.length]), i2);
      let result = convert.LineSplitter.split(test, 4)[dartx.toList]();
      expect$.Expect.listEquals(JSArrayOfString().of(['1', 'line2', 'line3']), result);
      result = convert.LineSplitter.split(test, 5)[dartx.toList]();
      expect$.Expect.listEquals(JSArrayOfString().of(['', 'line2', 'line3']), result);
      result = convert.LineSplitter.split(test, i2)[dartx.toList]();
      expect$.Expect.listEquals(JSArrayOfString().of(['line2', 'line3']), result);
      result = convert.LineSplitter.split(test, 0, i2 + 2)[dartx.toList]();
      expect$.Expect.listEquals(JSArrayOfString().of(['line1', 'li']), result);
      result = convert.LineSplitter.split(test, i2, i2 + 5)[dartx.toList]();
      expect$.Expect.listEquals(JSArrayOfString().of(['line2']), result);
    }
    let test = "Line1\nLine2\r\nLine3\rLine4\n\n\n\r\n\r\n\r\r";
    let result = convert.LineSplitter.split(test)[dartx.toList]();
    expect$.Expect.listEquals(JSArrayOfString().of(['Line1', 'Line2', 'Line3', 'Line4', '', '', '', '', '', '']), result);
    test = "a\n\nb\r\nc\n\rd\r\re\r\n\nf\r\n";
    result = convert.LineSplitter.split(test)[dartx.toList]();
    expect$.Expect.listEquals(JSArrayOfString().of(["a", "", "b", "c", "", "d", "", "e", "", "f"]), result);
  };
  dart.fn(line_splitter_test.testSplitWithOffsets, VoidTovoid());
  line_splitter_test.testChunkedConversion = function() {
    let test = "a\n\nb\r\nc\n\rd\r\re\r\n\nf\rg\nh\r\n";
    let result = JSArrayOfString().of(["a", "", "b", "c", "", "d", "", "e", "", "f", "g", "h"]);
    for (let i = 0; i < dart.notNull(test[dartx.length]); i++) {
      let output = [];
      let splitter = new convert.LineSplitter();
      let outSink = convert.ChunkedConversionSink.withCallback(dart.bind(output, dartx.addAll));
      let sink = splitter.startChunkedConversion(SinkOfString()._check(outSink));
      sink.addSlice(test, 0, i, false);
      sink.addSlice(test, i, test[dartx.length], false);
      sink.close();
      expect$.Expect.listEquals(result, output);
    }
    for (let i = 0; i < dart.notNull(test[dartx.length]); i++) {
      for (let j = i; j < dart.notNull(test[dartx.length]); j++) {
        let output = [];
        let splitter = new convert.LineSplitter();
        let outSink = convert.ChunkedConversionSink.withCallback(dart.bind(output, dartx.addAll));
        let sink = splitter.startChunkedConversion(SinkOfString()._check(outSink));
        sink.addSlice(test, 0, i, false);
        sink.addSlice(test, i, j, false);
        sink.addSlice(test, j, test[dartx.length], true);
        expect$.Expect.listEquals(result, output);
      }
    }
  };
  dart.fn(line_splitter_test.testChunkedConversion, VoidTovoid());
  // Exports:
  exports.line_splitter_test = line_splitter_test;
});
