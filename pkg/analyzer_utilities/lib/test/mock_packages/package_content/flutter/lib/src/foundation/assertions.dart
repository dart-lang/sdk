// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

class FlutterErrorDetails /* with Diagnosticable */ {
  const FlutterErrorDetails({
    required Object exception,
  });
}

class FlutterError /* extends Error with DiagnosticableTreeMixin implements AssertionError */ {
  static void reportError(FlutterErrorDetails details) {}
}
