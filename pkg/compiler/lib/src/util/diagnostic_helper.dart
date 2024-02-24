// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.test.diagnostic_helper;

import 'package:compiler/compiler_api.dart' as api
    show CompilerDiagnostics, Diagnostic;
import 'package:compiler/src/diagnostics/messages.dart'
    show Message, MessageKind;

class CollectedMessage {
  final Message? message;
  final Uri? uri;
  final int? begin;
  final int? end;
  final String text;
  final api.Diagnostic kind;

  CollectedMessage(
      this.message, this.uri, this.begin, this.end, this.text, this.kind);

  MessageKind? get messageKind => message?.kind;

  @override
  String toString() {
    return '${message != null ? message!.kind : ''}'
        ':$uri:$begin:$end:$text:$kind';
  }
}

class DiagnosticCollector implements api.CompilerDiagnostics {
  List<CollectedMessage> messages = <CollectedMessage>[];

  @override
  void report(covariant Message? message, Uri? uri, int? begin, int? end,
      String text, api.Diagnostic kind) {
    messages.add(CollectedMessage(message, uri, begin, end, text, kind));
  }

  Iterable<CollectedMessage> filterMessagesByKinds(List<api.Diagnostic> kinds) {
    return messages
        .where((CollectedMessage message) => kinds.contains(message.kind));
  }

  Iterable<CollectedMessage> get errors {
    return filterMessagesByKinds([api.Diagnostic.error]);
  }

  Iterable<CollectedMessage> get warnings {
    return filterMessagesByKinds([api.Diagnostic.warning]);
  }

  Iterable<CollectedMessage> get hints {
    return filterMessagesByKinds([api.Diagnostic.hint]);
  }

  Iterable<CollectedMessage> get infos {
    return filterMessagesByKinds([api.Diagnostic.info]);
  }

  Iterable<CollectedMessage> get crashes {
    return filterMessagesByKinds([api.Diagnostic.crash]);
  }

  Iterable<CollectedMessage> get contexts {
    return filterMessagesByKinds([api.Diagnostic.context]);
  }

  Iterable<CollectedMessage> get verboseInfos {
    return filterMessagesByKinds([api.Diagnostic.verboseInfo]);
  }

  /// `true` if non-verbose messages has been collected.
  bool get hasRegularMessages {
    return messages.any((m) => m.kind != api.Diagnostic.verboseInfo);
  }

  void clear() {
    messages.clear();
  }
}
