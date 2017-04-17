library wrapping_collection_test;

import 'dart:html';
import 'dart:html_common';
import 'dart:js' as js;
import 'package:unittest/unittest.dart';
import 'package:unittest/html_config.dart';

/// Test that if we access objects through JS-interop we get the
/// appropriate objects, even if dart:html maps them.
main() {
  test("Access through JS-interop", () {
    var performance = js.context['performance'];
    var entries = performance.callMethod('getEntries', const []);
    entries.forEach((x) {
      expect(x is js.JsObject, isTrue);
    });
  });

  test("Access through dart:html", () {
    var dartPerformance = js.JsNative.toTypedObject(js.context['performance']);
    var dartEntries = dartPerformance.getEntries();
    dartEntries.forEach((x) {
      expect(x is PerformanceEntry, isTrue);
    });
  });
}
