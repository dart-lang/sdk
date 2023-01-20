// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@JS('library')
library static_interop_library;

import 'package:js/js.dart';

@JS()
@staticInterop
class NamespacedClass {
  external factory NamespacedClass();
}

extension NamespacedClassExtension on NamespacedClass {
  external String member();
}

@JS()
external String get libraryTopLevelGetter;

@JS('jsedLibraryTopLevelGetter')
external String get libraryOtherTopLevelGetter;
