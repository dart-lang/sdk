// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

// Test that closures have a useful string that identifies the function by name
// in error messages.

import "package:expect/expect.dart";

@pragma('dart2js:noInline')
@pragma('dart2js:assumeDynamic')
confuse(x) => x;

class CCCC {
  instanceMethod([a, b]) => '[$a, $b]';
  static staticMethod() => 'hi';
  // Default `toString` method returns "Instance of 'CCCC'" or similar with a
  // shorter name if minified.
}

main() {
  var c = confuse(new CCCC());

  var instanceString = confuse(c).toString();
  bool isMinified =
      instanceString.contains(new RegExp("Instance of '..?.?'")) ||
          instanceString.contains('minified:');
  if (!isMinified) {
    Expect.equals("Instance of 'CCCC'", instanceString);
  }

  checkContains(String message, String tag) {
    if (!message.contains(tag)) {
      if (!isMinified) {
        Expect.fail('"$message" should contain "$tag"');
      }
      // When minified we will accept quoted names up to 3 characters.
      Expect.isTrue(
          message.contains(new RegExp("'..?.?'")) ||
              message.contains("'minified:"),
          '"$message" should contain minified name');
    }
  }

  // We use ArgumentError.value since it prints the value using
  // Error.safeToString.
  var e1 = new ArgumentError.value(c);
  var s1 = '$e1';
  Expect.isTrue(s1.contains(instanceString),
      'Error message "$s1" should contain "$instanceString"');

  // Instance method tear-off.
  var e2 = new ArgumentError.value(confuse(c).instanceMethod);
  var s2 = '$e2';
  // Instance method tear-off should contain instance string.
  Expect.isTrue(s2.contains(instanceString),
      'Error message "$s2" should contain "$instanceString"');
  // Instance method tear-off should also name the method.
  checkContains(s2.replaceAll(instanceString, '*'), "instanceMethod");

  // Top level tear-off.
  var e3 = new ArgumentError.value(confuse);
  var s3 = '$e3';
  checkContains(s3, "confuse");
  checkContains('$confuse', "confuse");

  // Static method tear-off.
  var e4 = new ArgumentError.value(CCCC.staticMethod);
  var s4 = '$e4';
  checkContains(s4, "staticMethod");
  checkContains('${CCCC.staticMethod}', "staticMethod");

  // Local anonymous closure.
  var anon = () => c;
  var e5 = new ArgumentError.value(anon);
  var s5 = '$e5';
  checkContains(s5, "main_closure");
  checkContains('$anon', "main_closure");

  // Local named closure.
  localFunction() => c;
  var e6 = new ArgumentError.value(localFunction);
  var s6 = '$e6';
  checkContains(s6, "localFunction");
  checkContains('$localFunction', "localFunction");
}
