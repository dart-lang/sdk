library TestUtils;

import 'dart:async';
import 'dart:html';
import 'dart:js' as js;
import 'dart:typed_data';
import 'package:test/test.dart';

/**
 * Verifies that [actual] has the same graph structure as [expected].
 * Detects cycles and DAG structure in Maps and Lists.
 */
verifyGraph(expected, actual) {
  var eItems = [];
  var aItems = [];

  message(path, reason) => path == ''
      ? reason
      : reason == null ? "path: $path" : "path: $path, $reason";

  walk(path, expected, actual) {
    if (expected is String || expected is num || expected == null) {
      expect(actual, equals(expected), reason: message(path, 'not equal'));
      return;
    }

    // Cycle or DAG?
    for (int i = 0; i < eItems.length; i++) {
      if (identical(expected, eItems[i])) {
        expect(actual, same(aItems[i]),
            reason: message(path, 'missing back or side edge'));
        return;
      }
    }
    for (int i = 0; i < aItems.length; i++) {
      if (identical(actual, aItems[i])) {
        expect(expected, same(eItems[i]),
            reason: message(path, 'extra back or side edge'));
        return;
      }
    }
    eItems.add(expected);
    aItems.add(actual);

    if (expected is Blob) {
      expect(actual is Blob, isTrue, reason: '$actual is Blob');
      expect(expected.type, equals(actual.type),
          reason: message(path, '.type'));
      expect(expected.size, equals(actual.size),
          reason: message(path, '.size'));
      return;
    }

    if (expected is ByteBuffer) {
      expect(actual is ByteBuffer, isTrue, reason: '$actual is ByteBuffer');
      expect(expected.lengthInBytes, equals(actual.lengthInBytes),
          reason: message(path, '.lengthInBytes'));
      // TODO(antonm): one can create a view on top of those
      // and check if contents identical.  Let's do it later.
      return;
    }

    if (expected is DateTime) {
      expect(actual is DateTime, isTrue, reason: '$actual is DateTime');
      expect(expected.millisecondsSinceEpoch,
          equals(actual.millisecondsSinceEpoch),
          reason: message(path, '.millisecondsSinceEpoch'));
      return;
    }

    if (expected is ImageData) {
      expect(actual is ImageData, isTrue, reason: '$actual is ImageData');
      expect(expected.width, equals(actual.width),
          reason: message(path, '.width'));
      expect(expected.height, equals(actual.height),
          reason: message(path, '.height'));
      walk('$path.data', expected.data, actual.data);
      return;
    }

    if (expected is TypedData) {
      expect(actual is TypedData, isTrue, reason: '$actual is TypedData');
      walk('$path/.buffer', expected.buffer, actual.buffer);
      expect(expected.offsetInBytes, equals(actual.offsetInBytes),
          reason: message(path, '.offsetInBytes'));
      expect(expected.lengthInBytes, equals(actual.lengthInBytes),
          reason: message(path, '.lengthInBytes'));
      // And also fallback to elements check below.
    }

    if (expected is List) {
      expect(actual, isList, reason: message(path, '$actual is List'));
      expect(actual.length, expected.length,
          reason: message(path, 'different list lengths'));
      for (var i = 0; i < expected.length; i++) {
        walk('$path[$i]', expected[i], actual[i]);
      }
      return;
    }

    if (expected is Map) {
      expect(actual, isMap, reason: message(path, '$actual is Map'));
      for (var key in expected.keys) {
        if (!actual.containsKey(key)) {
          expect(false, isTrue, reason: message(path, 'missing key "$key"'));
        }
        walk('$path["$key"]', expected[key], actual[key]);
      }
      for (var key in actual.keys) {
        if (!expected.containsKey(key)) {
          expect(false, isTrue, reason: message(path, 'extra key "$key"'));
        }
      }
      return;
    }

    expect(false, isTrue, reason: 'Unhandled type: $expected');
  }

  walk('', expected, actual);
}

/**
 * Sanitizer which does nothing.
 */
class NullTreeSanitizer implements NodeTreeSanitizer {
  void sanitizeTree(Node node) {}
}

/**
 * Validate that two DOM trees are equivalent.
 */
void validateNodeTree(Node a, Node b, [String path = '']) {
  path = '${path}${a.runtimeType}';
  expect(a.nodeType, b.nodeType, reason: '$path nodeTypes differ');
  expect(a.nodeValue, b.nodeValue, reason: '$path nodeValues differ');
  expect(a.text, b.text, reason: '$path texts differ');
  expect(a.nodes.length, b.nodes.length, reason: '$path nodes.lengths differ');

  if (a is Element) {
    Element bE = b;
    Element aE = a;

    expect(aE.tagName, bE.tagName, reason: '$path tagNames differ');
    expect(aE.attributes.length, bE.attributes.length,
        reason: '$path attributes.lengths differ');
    for (var key in aE.attributes.keys) {
      expect(aE.attributes[key], bE.attributes[key],
          reason: '$path attribute [$key] values differ');
    }
  }
  for (var i = 0; i < a.nodes.length; ++i) {
    validateNodeTree(a.nodes[i], b.nodes[i], '$path[$i].');
  }
}

/**
 * Upgrade all custom elements in the subtree which have not been upgraded.
 *
 * This is needed to cover timing scenarios which the custom element polyfill
 * does not cover.
 */
void upgradeCustomElements(Node node) {
  if (js.context.hasProperty('CustomElements') &&
      js.context['CustomElements'].hasProperty('upgradeAll')) {
    js.context['CustomElements'].callMethod('upgradeAll', [node]);
  }
}

/**
 * A future that completes once all custom elements in the initial HTML page
 * have been upgraded.
 *
 * This is needed because the native implementation can update the elements
 * while parsing the HTML document, but the custom element polyfill cannot,
 * so it completes this future once all elements are upgraded.
 */
// TODO(jmesserly): rename to webComponentsReady to match the event?
Future customElementsReady = () {
  if (_isReady) return new Future.value();

  // Not upgraded. Wait for the polyfill to fire the WebComponentsReady event.
  // Note: we listen on document (not on document.body) to allow this polyfill
  // to be loaded in the HEAD element.
  return document.on['WebComponentsReady'].first;
}();

// Return true if we are using the polyfill and upgrade is complete, or if we
// have native document.register and therefore the browser took care of it.
// Otherwise return false, including the case where we can't find the polyfill.
bool get _isReady {
  // If we don't have dart:js, assume things are ready
  if (js.context == null) return true;

  var customElements = js.context['CustomElements'];
  if (customElements == null) {
    // Return true if native document.register, otherwise false.
    // (Maybe the polyfill isn't loaded yet. Wait for it.)
    return document.supportsRegisterElement;
  }

  return customElements['ready'] == true;
}

/**
 * *Note* this API is primarily intended for tests. In other code it is better
 * to write it in a style that works with or without the polyfill, rather than
 * using this method.
 *
 * Synchronously trigger evaluation of pending lifecycle events, which otherwise
 * need to wait for a [MutationObserver] to signal the changes in the polyfill.
 * This method can be used to resolve differences in timing between native and
 * polyfilled custom elements.
 */
void customElementsTakeRecords([Node node]) {
  var customElements = js.context['CustomElements'];
  if (customElements == null) return;
  customElements.callMethod('takeRecords', [node]);
}
