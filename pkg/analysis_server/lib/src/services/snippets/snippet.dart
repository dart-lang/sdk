// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/protocol_server.dart';

class Snippet {
  /// The text the user will type to use this snippet.
  final String prefix;

  /// The label/title of this snippet.
  final String label;

  /// A description of/documentation for the snippet.
  final String? documentation;

  /// The source changes to be made to insert this snippet.
  final SourceChange change;

  Snippet(this.prefix, this.label, this.documentation, this.change);
}
