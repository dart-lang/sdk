// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.test.diagnostic_helper;

import 'dart:collection';

import 'package:compiler/compiler_new.dart'
    show CompilerDiagnostics, Diagnostic;
import 'package:compiler/src/diagnostics/messages.dart'
    show Message, MessageKind;
import 'package:expect/expect.dart';

class CollectedMessage {
  final Message message;
  final Uri uri;
  final int begin;
  final int end;
  final String text;
  final Diagnostic kind;

  CollectedMessage(
      this.message, this.uri, this.begin, this.end, this.text, this.kind);

  MessageKind get messageKind => message?.kind;

  String toString() {
    return '${message != null ? message.kind : ''}'
        ':$uri:$begin:$end:$text:$kind';
  }
}

class DiagnosticCollector implements CompilerDiagnostics {
  List<CollectedMessage> messages = <CollectedMessage>[];

  @override
  void report(covariant Message message, Uri uri, int begin, int end,
      String text, Diagnostic kind) {
    messages.add(new CollectedMessage(message, uri, begin, end, text, kind));
  }

  Iterable<CollectedMessage> filterMessagesByKinds(List<Diagnostic> kinds) {
    return messages
        .where((CollectedMessage message) => kinds.contains(message.kind));
  }

  Iterable<CollectedMessage> get errors {
    return filterMessagesByKinds([Diagnostic.ERROR]);
  }

  Iterable<CollectedMessage> get warnings {
    return filterMessagesByKinds([Diagnostic.WARNING]);
  }

  Iterable<CollectedMessage> get hints {
    return filterMessagesByKinds([Diagnostic.HINT]);
  }

  Iterable<CollectedMessage> get infos {
    return filterMessagesByKinds([Diagnostic.INFO]);
  }

  Iterable<CollectedMessage> get crashes {
    return filterMessagesByKinds([Diagnostic.CRASH]);
  }

  Iterable<CollectedMessage> get verboseInfos {
    return filterMessagesByKinds([Diagnostic.VERBOSE_INFO]);
  }

  /// `true` if non-verbose messages has been collected.
  bool get hasRegularMessages {
    return messages.any((m) => m.kind != Diagnostic.VERBOSE_INFO);
  }

  void clear() {
    messages.clear();
  }

  void checkMessages(List<Expected> expectedMessages) {
    int index = 0;
    Iterable<CollectedMessage> messages = filterMessagesByKinds([
      Diagnostic.ERROR,
      Diagnostic.WARNING,
      Diagnostic.HINT,
      Diagnostic.INFO
    ]);
    for (CollectedMessage message in messages) {
      if (index >= expectedMessages.length) {
        Expect.fail("Unexpected messages:\n "
            "${messages.skip(index).join('\n ')}");
      } else {
        Expected expected = expectedMessages[index];
        Expect.equals(expected.messageKind, message.messageKind,
            "Unexpected message kind in:\n ${messages.join('\n ')}");
        Expect.equals(expected.diagnosticKind, message.kind,
            "Unexpected diagnostic kind in\n ${messages.join('\n ')}");
        index++;
      }
    }
  }
}

class Expected {
  final MessageKind messageKind;
  final Diagnostic diagnosticKind;

  const Expected(this.messageKind, this.diagnosticKind);

  const Expected.error(MessageKind messageKind)
      : this(messageKind, Diagnostic.ERROR);

  const Expected.warning(MessageKind messageKind)
      : this(messageKind, Diagnostic.WARNING);

  const Expected.hint(MessageKind messageKind)
      : this(messageKind, Diagnostic.HINT);

  const Expected.info(MessageKind messageKind)
      : this(messageKind, Diagnostic.INFO);
}

void compareWarningKinds(String text, List expectedWarnings,
    Iterable<CollectedMessage> foundWarnings) {
  compareMessageKinds(text, expectedWarnings, foundWarnings, 'warning');
}

/// [expectedMessages] must be a list of either [MessageKind] or [CheckMessage].
void compareMessageKinds(String text, List expectedMessages,
    Iterable<CollectedMessage> foundMessages, String kind) {
  var fail = (message) => Expect.fail('$text: $message');
  HasNextIterator expectedIterator =
      new HasNextIterator(expectedMessages.iterator);
  HasNextIterator<CollectedMessage> foundIterator =
      new HasNextIterator(foundMessages.iterator);
  while (expectedIterator.hasNext && foundIterator.hasNext) {
    var expected = expectedIterator.next();
    var found = foundIterator.next();
    if (expected is MessageKind) {
      Expect.equals(expected, found.message.kind);
    } else if (expected is CheckMessage) {
      String error = expected(found.message);
      Expect.isNull(error, error);
    } else {
      Expect.fail("Unexpected $kind value: $expected.");
    }
  }
  if (expectedIterator.hasNext) {
    do {
      var expected = expectedIterator.next();
      if (expected is CheckMessage) expected = expected(null);
      print('Expected $kind "${expected}" did not occur');
    } while (expectedIterator.hasNext);
    fail('Too few ${kind}s');
  }
  if (foundIterator.hasNext) {
    do {
      CollectedMessage message = foundIterator.next();
      print('Additional $kind "${message}: ${message.message}"');
    } while (foundIterator.hasNext);
    fail('Too many ${kind}s');
  }
}

/// A function the checks [message]. If the check fails or if [message] is
/// `null`, an error string is returned. Otherwise `null` is returned.
typedef String CheckMessage(Message message);

CheckMessage checkMessage(MessageKind kind, Map arguments) {
  return (Message message) {
    if (message == null) return '$kind';
    if (message.kind != kind) return 'Expected message $kind, found $message.';
    for (var key in arguments.keys) {
      if (!message.arguments.containsKey(key)) {
        return 'Expected argument $key not found in $message.kind.';
      }
      String expectedValue = '${arguments[key]}';
      String foundValue = '${message.arguments[key]}';
      if (expectedValue != foundValue) {
        return 'Expected argument $key with value $expectedValue, '
            'found $foundValue.';
      }
    }
    return null;
  };
}
