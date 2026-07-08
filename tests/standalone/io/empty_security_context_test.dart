// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Regression test for https://buganizer.corp.google.com/issues/524667903.
// Verifies that an empty SecurityContext(withTrustedRoots: false) does not silently
// trust OS root certificates on macOS/iOS when custom anchor certificates are not set.

import 'dart:io';

import 'package:expect/expect.dart';

void main() async {
  // Empty security context that trusts no root certificates.
  final untrustedContext = SecurityContext(withTrustedRoots: false);
  final client = HttpClient(context: untrustedContext);

  try {
    final request = await client.getUrl(Uri.parse('https://www.google.com'));
    final response = await request.close();
    await response.drain();
    Expect.fail(
      'SecurityContext(withTrustedRoots: false) unexpectedly accepted a publicly trusted certificate chain.',
    );
  } on HandshakeException {
    // Correct behavior: untrusted context rejected the publicly trusted chain.
  } finally {
    client.close(force: true);
  }
}
