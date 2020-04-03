// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server_client/protocol.dart';

import '../util.dart';

/// Perform the indicated source edits to the given source, returning the
/// resulting transformed text.
String applyEdits(SourceFileEdit sourceFileEdit, String source) {
  List<SourceEdit> edits = sortEdits(sourceFileEdit);
  return SourceEdit.applySequence(source, edits);
}
