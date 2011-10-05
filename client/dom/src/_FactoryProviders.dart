// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


// These factory methods could all live in one factory provider class but dartc
// has a bug (5399939) preventing that.

class _FileReaderFactoryProvider {

  factory FileReader() { return create(); }

  static FileReader create() native;
}

class _WebKitCSSMatrixFactoryProvider {

  factory WebKitCSSMatrix([String spec = '']) { return create(spec); }

  static WebKitCSSMatrix create(spec) native;
}

class _WebKitPointFactoryProvider {

  factory WebKitPoint(num x, num y) { return create(x, y); }

  static WebKitPoint create(x, y) native;
}

class _XMLHttpRequestFactoryProvider {

  factory XMLHttpRequest() { return create(); }

  static XMLHttpRequest create() native;
}
