// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// SharedOptions=--enable-experiment=inline-class

@JS()
library external_operator_test;

import 'dart:js_interop';
import 'package:expect/minitest.dart';

@JS()
external void eval(String code);

@JS()
@staticInterop
class Indexable {}

extension IndexableExtension on Indexable {
  external JSAny? operator [](JSNumber index);
  external void operator []=(JSNumber index, JSAny? value);
}

@JS()
external Indexable get indexableArr;

@JS()
external Indexable get indexableObj;

@JS()
extension type Indexable2(JSObject _) {
  external JSAny? operator [](JSNumber index);
  external void operator []=(JSNumber index, JSAny? value);
}

@JS('indexableArr')
external Indexable2 get indexableArr2;

@JS('indexableObj')
external Indexable2 get indexableObj2;

void main() {
  eval('''
    globalThis.indexableArr = [];
    globalThis.indexableObj = {};
  ''');

  // [JSObject] should be indexable.
  {
    final obj = indexableObj;
    obj[3.0.toJS] = 4.0.toJS;
    expect((obj[3.0.toJS] as JSNumber).toDartDouble, 4.0);
  }
  {
    final obj = indexableObj2;
    obj[4.0.toJS] = 5.0.toJS;
    expect((obj[4.0.toJS] as JSNumber).toDartDouble, 5.0);
  }

  // [JSArray] should be indexable.
  {
    final arr = indexableArr;
    arr[5.0.toJS] = 6.0.toJS;
    expect((arr[5.0.toJS] as JSNumber).toDartDouble, 6.0);
  }
  {
    final arr = indexableArr2;
    arr[6.0.toJS] = 7.0.toJS;
    expect((arr[6.0.toJS] as JSNumber).toDartDouble, 7.0);
  }
}
