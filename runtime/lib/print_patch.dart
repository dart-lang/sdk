// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

typedef void _PrintClosure(Object obj);

patch void print(Object obj) {
  _printClosure(obj.toString());
}

void _unsupportedPrint(Object obj) {
  throw const UnsupportedOperationException("'print' is not supported");
}

// _printClosure can be overwritten by the embedder to supply a different
// print implementation.
_PrintClosure _printClosure = _unsupportedPrint;
