// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Dart core library.

// VM implementation of double.

patch class double {
  static double _parse(String string) native "Double_parse";

  /* patch */ static double parse(String str,
                                  [double handleError(String str)]) {
    if (handleError == null) return _parse(str);
    try {
      return _parse(str);
    } on FormatException {
      return handleError(str);
    }
  }
}
