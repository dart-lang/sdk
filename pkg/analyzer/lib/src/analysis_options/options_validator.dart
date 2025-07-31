// Copyright (c) 2015, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Support for client code that wants to consume options contributed to the
/// analysis options file.
library;

import 'package:analyzer/error/listener.dart';
import 'package:yaml/yaml.dart';

/// A class that validates options as defined in an analysis options file.
abstract class OptionsValidator {
  /// Validate [options], reporting any errors to the given [reporter].
  void validate(DiagnosticReporter reporter, YamlMap options);
}
