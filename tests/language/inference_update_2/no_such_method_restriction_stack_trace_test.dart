// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests that when a noSuchMethod forwarder throws an exception due to the fact
// that the forwarding stub is for a private member of another library, the
// resulting stack trace points to the class for which the noSuchMethod
// forwarder was created.

import 'package:expect/expect.dart';

import 'no_such_method_restriction_stack_trace_lib1.dart';
import 'no_such_method_restriction_stack_trace_lib2.dart';

main() {
  try {
    callPrivateMethod(Test());
  } on NoSuchMethodError catch (e, st) {
    var stackString = st.toString();
    if (stackString.contains('.js:') || !stackString.contains('.dart')) {
      // Obfuscated stacktrace.  We don't expect to be able to resolve Dart
      // files from this stack trace, so just let the test pass.
      //
      // Note: it's not sufficient to check for the absence of `.dart` in the
      // stacktrace, because obfuscated JavaScript stacktraces often contain
      // `self.dartMainRunner`.
    } else {
      Expect.contains(
          'no_such_method_restriction_stack_trace_lib1.dart', stackString);
    }
  }
}
