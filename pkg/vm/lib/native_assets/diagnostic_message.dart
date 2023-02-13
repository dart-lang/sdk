// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:front_end/src/api_unstable/vm.dart';

class NativeAssetsDiagnosticMessage implements DiagnosticMessage {
  final String message;

  @override
  final Severity severity;

  NativeAssetsDiagnosticMessage({
    required this.message,
    this.severity = Severity.error,
    this.involvedFiles,
  });

  @override
  Iterable<String> get ansiFormatted => [message];

  @override
  String? get codeName => null;

  @override
  final List<Uri>? involvedFiles;

  @override
  Iterable<String> get plainTextFormatted => [message];

  @override
  String toString() => 'NativeAssetsDiagnosticMessage($message)';
}
