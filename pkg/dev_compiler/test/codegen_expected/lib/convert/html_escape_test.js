dart_library.library('lib/convert/html_escape_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__html_escape_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const convert = dart_sdk.convert;
  const async = dart_sdk.async;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const html_escape_test = Object.create(null);
  let StreamControllerOfString = () => (StreamControllerOfString = dart.constFn(async.StreamController$(core.String)))();
  let HtmlEscapeAndStringAndStringTovoid = () => (HtmlEscapeAndStringAndStringTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [convert.HtmlEscape, core.String, core.String])))();
  let dynamicTovoid = () => (dynamicTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [dart.dynamic])))();
  let VoidTovoid = () => (VoidTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [])))();
  html_escape_test._NOOP = 'Nothing_to_escape';
  html_escape_test._TEST_INPUT = "<A </test> of   \"double\" & 'single' values>";
  html_escape_test._OUTPUT_UNKNOWN = '&lt;A &lt;&#47;test&gt; of   &quot;double&quot; ' + '&amp; &#39;single&#39; values&gt;';
  html_escape_test._OUTPUT_ATTRIBUTE = "&lt;A &lt;/test&gt; of   &quot;double&quot; &amp; 'single' values&gt;";
  html_escape_test._OUTPUT_SQ_ATTRIBUTE = '&lt;A &lt;/test&gt; of   "double" &amp; &#39;single&#39; values&gt;';
  html_escape_test._OUTPUT_ELEMENT = "&lt;A &lt;/test&gt; of   \"double\" &amp; 'single' values&gt;";
  html_escape_test._testMode = function(escape, input, expected) {
    html_escape_test._testConvert(escape, input, expected);
    html_escape_test._testTransform(escape, input, expected);
    html_escape_test._testChunked(escape, input, expected);
  };
  dart.fn(html_escape_test._testMode, HtmlEscapeAndStringAndStringTovoid());
  html_escape_test._testChunked = function(escape, input, expected) {
    let buffer = new core.StringBuffer();
    let rootSink = convert.StringConversionSink.fromStringSink(buffer);
    let sink = escape.startChunkedConversion(rootSink);
    sink.addSlice("1" + dart.notNull(input) + "2", 1, dart.notNull(input[dartx.length]) + 1, false);
    sink.close();
    expect$.Expect.equals(expected, buffer.toString());
  };
  dart.fn(html_escape_test._testChunked, HtmlEscapeAndStringAndStringTovoid());
  html_escape_test._testConvert = function(escape, input, expected) {
    let output = escape.convert(input);
    expect$.Expect.equals(expected, output);
  };
  dart.fn(html_escape_test._testConvert, HtmlEscapeAndStringAndStringTovoid());
  html_escape_test._testTransform = function(escape, input, expected) {
    let controller = StreamControllerOfString().new({sync: true});
    let stream = controller.stream.transform(core.String)(escape);
    let done = false;
    let count = 0;
    function stringData(value) {
      expect$.Expect.equals(expected, value);
      count++;
    }
    dart.fn(stringData, dynamicTovoid());
    function streamClosed() {
      done = true;
    }
    dart.fn(streamClosed, VoidTovoid());
    stream.listen(stringData, {onDone: streamClosed});
    for (let i = 0; i < html_escape_test._COUNT; i++) {
      controller.add(input);
    }
    controller.close();
    expect$.Expect.isTrue(done);
    expect$.Expect.equals(html_escape_test._COUNT, count);
  };
  dart.fn(html_escape_test._testTransform, HtmlEscapeAndStringAndStringTovoid());
  html_escape_test._COUNT = 3;
  let const$;
  let const$0;
  let const$1;
  let const$2;
  let const$3;
  html_escape_test.main = function() {
    html_escape_test._testMode(convert.HTML_ESCAPE, html_escape_test._TEST_INPUT, html_escape_test._OUTPUT_UNKNOWN);
    html_escape_test._testMode(const$ || (const$ = dart.const(new convert.HtmlEscape())), html_escape_test._TEST_INPUT, html_escape_test._OUTPUT_UNKNOWN);
    html_escape_test._testMode(const$0 || (const$0 = dart.const(new convert.HtmlEscape(convert.HtmlEscapeMode.UNKNOWN))), html_escape_test._TEST_INPUT, html_escape_test._OUTPUT_UNKNOWN);
    html_escape_test._testMode(const$1 || (const$1 = dart.const(new convert.HtmlEscape(convert.HtmlEscapeMode.ATTRIBUTE))), html_escape_test._TEST_INPUT, html_escape_test._OUTPUT_ATTRIBUTE);
    html_escape_test._testMode(const$2 || (const$2 = dart.const(new convert.HtmlEscape(convert.HtmlEscapeMode.SQ_ATTRIBUTE))), html_escape_test._TEST_INPUT, html_escape_test._OUTPUT_SQ_ATTRIBUTE);
    html_escape_test._testMode(const$3 || (const$3 = dart.const(new convert.HtmlEscape(convert.HtmlEscapeMode.ELEMENT))), html_escape_test._TEST_INPUT, html_escape_test._OUTPUT_ELEMENT);
    html_escape_test._testMode(convert.HTML_ESCAPE, html_escape_test._NOOP, html_escape_test._NOOP);
  };
  dart.fn(html_escape_test.main, VoidTovoid());
  // Exports:
  exports.html_escape_test = html_escape_test;
});
