// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


// These factory methods could all live in one factory provider class but dartc
// has a bug (5399939) preventing that.

class _FileReaderFactoryProvider {

  factory FileReader() {
    return new dom.FileReader();
  }
}

class _CSSMatrixFactoryProvider {

  factory CSSMatrix([String spec = '']) {
    return new CSSMatrixWrappingImplementation._wrap(
        new dom.WebKitCSSMatrix(spec));
  }
}

class _PointFactoryProvider {

  factory Point(num x, num y) {
    return new PointWrappingImplementation._wrap(new dom.WebKitPoint(x, y));
  }
}
