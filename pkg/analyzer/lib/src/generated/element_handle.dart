// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@deprecated
library analyzer.src.generated.element_handle;

export 'package:analyzer/src/dart/element/handle.dart';

/**
 * TODO(scheglov) invalid implementation
 */
class WeakReference<T> {
  final T value;
  WeakReference(this.value);
  T get() => value;
}
