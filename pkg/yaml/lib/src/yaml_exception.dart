// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library yaml.exception;

import 'package:source_span/source_span.dart';

/// An error thrown by the YAML processor.
class YamlException extends SourceSpanFormatException {
  YamlException(String message, SourceSpan span)
      : super(message, span);
}

