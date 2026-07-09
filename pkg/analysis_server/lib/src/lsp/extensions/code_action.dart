// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/lsp_protocol/protocol.dart';

extension CodeActionExtensions on CodeAction {
  /// The [Command] for this [CodeAction], whether it's a [CodeActionLiteral]
  /// or a [Command].
  Command? get command {
    return map((literal) => literal.command, (command) => command);
  }

  /// The title for this [CodeAction], whether it's a [CodeActionLiteral]
  /// or a [Command].
  String get title {
    return map((literal) => literal.title, (command) => command.title);
  }
}
