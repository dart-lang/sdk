library safe_dom_test;

import 'dart:async';
import 'dart:html';
import '../../pkg/unittest/lib/unittest.dart';
import '../../pkg/unittest/lib/html_config.dart';

main() {
  useHtmlConfiguration();

  // Checks to see if any illegal properties were set via script.
  var checkerScript = '''
  window.addEventListener('message', function(e) {
    if (e.data == 'check_unsafe') {
      if (window.unsafe_value) {
        window.postMessage('unsafe_check_failed', '*');
      } else {
        window.postMessage('unsafe_check_passed', '*');
      }
      //window.alert('checking!');
    }
  }, false);
  ''';

  var script = new ScriptElement();
  script.text = checkerScript;
  document.body.append(script);

  var unsafeString =
      '<img src="_.png" onerror="javascript:window.unsafe_value=1;" crap="1"/>';

  test('Safe DOM', () {
    var fragment = createContextualFragment(unsafeString);

    expect(isSafe(), completion(true),
        reason: 'Expected no unsafe code executed.');
  });

  // Make sure that scripts did get executed, so we know our detection works.
  test('Unsafe Execution', () {
    var div = new DivElement();
    div.unsafeInnerHtml = unsafeString;
    // Crashing DRT ??
    // var fragment = createContextualFragment(unsafeString);
    // div.append(fragment);
    // document.body.append(div)

    expect(isSafe(), completion(false),
        reason: 'Expected unsafe code was executed.');
  });

  test('Validity', () {
    var fragment = createContextualFragment('<span>content</span>');
    var div = new DivElement();
    div.append(fragment);

    expect(div.nodes.length, 1);
    expect(div.nodes[0] is SpanElement, isTrue);
  });
}

DocumentFragment createContextualFragment(String html, [String contextTag]) {
  var doc = document.implementation.createHtmlDocument('');

  var contextElement;
  if (contextTag != null) {
    contextElement = doc.$dom_createElement(contextTag);
  } else {
    contextElement = doc.body;
  }

  if (Range.supportsCreateContextualFragment) {
    var range = doc.createRange();
    range.selectNode(contextElement);
    return range.createContextualFragment(html);
  } else {
    contextElement.unsafeInnerHtml = html;
    var fragment = new DocumentFragment();;
    while (contextElement.firstChild != null) {
      fragment.append(contextElement.firstChild);
    }
    return fragment;
  }
}

// Delay to wait for the image load to fail.
const Duration imageLoadDelay = const Duration(milliseconds: 500);

Future<bool> isSafe() {
  return new Future.delayed(imageLoadDelay).then((_) {
    window.postMessage('check_unsafe', '*');
  }).then((_) {
    return window.onMessage.where(
        (e) => e.data.startsWith('unsafe_check')).first;
  }).then((e) {
    return e.data == 'unsafe_check_passed';
  });
}
