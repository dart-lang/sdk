// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:language_server_protocol/protocol_generated.dart';

extension TextDocumentFilterSchemeExtension on TextDocumentFilterScheme {
  /// The string pattern for this selector, regardless of whether it is a
  /// [String] or a [RelativePattern].
  String? get patternString {
    return pattern?.map(
      (patternString) => patternString,
      (relativePattern) => relativePattern.pattern,
    );
  }
}
