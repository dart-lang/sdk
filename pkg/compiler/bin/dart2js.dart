// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Entrypoint to run the compiler. This entrypoint is currently only used by
/// dart2js developers. To run the compiler you now can:
///   * call `pub get` in the pkg/compiler folder.
///   * simply call `dart path-to-pkg/compiler/bin/dart2js.dart foo.dart`
// TODO(sigmund): move `main` here, and change our sdk build tools to just use
// this entrypoint instead.
library compiler.bin.dart2js;

export 'package:compiler/src/dart2js.dart';
