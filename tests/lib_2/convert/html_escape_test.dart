// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";
import 'dart:async';
import 'dart:convert';

const _NOOP = 'Nothing_to_escape';

const _TEST_INPUT = """<A </test> of \xA0 "double" & 'single' values>""";

const _OUTPUT_UNKNOWN = '&lt;A &lt;&#47;test&gt; of \xA0 &quot;double&quot; '
    '&amp; &#39;single&#39; values&gt;';

const _OUTPUT_ATTRIBUTE =
    "&lt;A &lt;/test&gt; of \xA0 &quot;double&quot; &amp; 'single' values&gt;";

const _OUTPUT_SQ_ATTRIBUTE =
    '&lt;A &lt;/test&gt; of \xA0 "double" &amp; &#39;single&#39; values&gt;';

const _OUTPUT_ELEMENT =
    """&lt;A &lt;/test&gt; of \xA0 "double" &amp; 'single' values&gt;""";

void _testMode(HtmlEscape escape, String input, String expected) {
  _testConvert(escape, input, expected);
  _testTransform(escape, input, expected);
  _testChunked(escape, input, expected);
}

void _testChunked(HtmlEscape escape, String input, String expected) {
  var buffer = new StringBuffer();

  var rootSink = new StringConversionSink.fromStringSink(buffer);
  var sink = escape.startChunkedConversion(rootSink);

  sink.addSlice("1" + input + "2", 1, input.length + 1, false);
  sink.close();

  Expect.equals(expected, buffer.toString());
}

void _testConvert(HtmlEscape escape, String input, String expected) {
  var output = escape.convert(input);
  Expect.equals(expected, output);
}

void _testTransform(HtmlEscape escape, String input, String expected) {
  var controller = new StreamController<String>(sync: true);

  var stream = controller.stream.transform(escape);

  var done = false;
  int count = 0;

  void stringData(value) {
    Expect.equals(expected, value);
    count++;
  }

  void streamClosed() {
    done = true;
  }

  stream.listen(stringData, onDone: streamClosed);

  for (var i = 0; i < _COUNT; i++) {
    controller.add(input);
  }
  controller.close();
  Expect.isTrue(done);
  Expect.equals(_COUNT, count);
}

const _COUNT = 3;

void main() {
  _testMode(HTML_ESCAPE, _TEST_INPUT, _OUTPUT_UNKNOWN);
  _testMode(const HtmlEscape(), _TEST_INPUT, _OUTPUT_UNKNOWN);
  _testMode(
      const HtmlEscape(HtmlEscapeMode.unknown), _TEST_INPUT, _OUTPUT_UNKNOWN);
  _testMode(const HtmlEscape(HtmlEscapeMode.attribute), _TEST_INPUT,
      _OUTPUT_ATTRIBUTE);
  _testMode(const HtmlEscape(HtmlEscapeMode.sqAttribute), _TEST_INPUT,
      _OUTPUT_SQ_ATTRIBUTE);
  _testMode(
      const HtmlEscape(HtmlEscapeMode.element), _TEST_INPUT, _OUTPUT_ELEMENT);
  _testMode(HTML_ESCAPE, _NOOP, _NOOP);
}
