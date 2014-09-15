// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Library that defines a main which calls build() from builder.dart. For
/// polymer projects the build.dart file can simply export this to make the
/// linter run on all of the entry points defined in your pubspec.yaml.
library polymer.default_build;

import 'builder.dart';

main(args) { lint(options: parseOptions(args)); }
