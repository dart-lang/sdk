// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:js_runtime/synced/invocation_mirror_constants.dart'
    as constants;

enum InvocationMirrorKind {
  method._(constants.method),
  getter._(constants.getter),
  setter._(constants.setter),
  ;

  // This is preferred over [index] to avoid coupling the enum ordering to
  // codegen.
  final int value;

  const InvocationMirrorKind._(this.value);
}
