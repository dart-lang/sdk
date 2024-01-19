// Copyright (c) 2015, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Operations to be performed during the simulation.
library;

import '../utilities/server.dart';

/// An operation that will send an 'analysis.updateContent' request.
class Analysis_UpdateContent extends ServerOperation {
  /// The path of the file whose content is being updated.
  final String filePath;

  /// The overlay used to update the content.
  final Object overlay;

  /// Initialize an operation to send an 'analysis.updateContent' request with
  /// the given [filePath] and [overlay] as parameters.
  Analysis_UpdateContent(this.filePath, this.overlay);

  @override
  void perform(Server server) {
    server.sendAnalysisUpdateContent({filePath: overlay});
//    if (overlay is ChangeContentOverlay) {
//      List<SourceEdit> edits = (overlay as ChangeContentOverlay).edits;
//      if (edits.length == 1) {
//        SourceEdit edit = edits[0];
//        if (edit.replacement.endsWith('.')) {
//          int offset = edit.offset + edit.replacement.length - 1;
//          server.sendCompletionGetSuggestions(filePath, offset);
//        }
//      }
//    }
  }
}

/// An operation to be performed during the simulation.
abstract class ServerOperation {
  /// Perform this operation by communicating with the given [server].
  void perform(Server server);
}
