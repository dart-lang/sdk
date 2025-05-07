// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/element/element.dart';

extension LibraryElement2Extension on LibraryElement {
  /// All extensions exported from this library.
  Iterable<ExtensionElement> get exportedExtensions {
    return exportNamespace.definedNames2.values.whereType();
  }
}
