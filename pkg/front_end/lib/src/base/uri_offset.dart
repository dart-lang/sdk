// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'messages.dart';

/// Source location pointer used for messaging.
class UriOffset(
  /// The file URI of the location.
  @override final Uri fileUri,

  /// The character offset for the location with [fileUri].
  @override final int fileOffset,
) implements UriOffsetLength {
  @override
  int get length => noLength;
}

/// Source location pointer used for messaging.
class UriOffsetLength(
  /// The file URI of the location.
  final Uri fileUri,

  /// The character offset for the location with [fileUri].
  final int fileOffset,

  /// The length of the location.
  ///
  /// This is used to emitted the correct number of `^` characters in the
  /// message output for the source location.
  final int length,
);

/// Source location based on the offset of a name.
class UriOffsetName(
  @override final Uri fileUri,
  final String name,
  final int nameOffset,
) implements UriOffsetLength {
  @override
  int get fileOffset => nameOffset;

  @override
  int get length => name.length;
}

extension ProblemReportingExtension on ProblemReporting {
  /// Helper method for calling [ProblemReporting.addProblem] with a
  /// [UriOffsetLength].
  void addProblem2(
    Message message,
    UriOffsetLength uriOffset, {
    bool wasHandled = false,
    List<LocatedMessage>? context,
    CfeSeverity? severity,
  }) {
    addProblem(
      message,
      uriOffset.fileOffset,
      uriOffset.length,
      uriOffset.fileUri,
      wasHandled: wasHandled,
      context: context,
      severity: severity,
    );
  }
}

extension MessageExtension on Message {
  /// Helper method for calling [Message.withLocation] with a [UriOffsetLength].
  LocatedMessage withLocation2(UriOffsetLength uriOffset) {
    return withLocation(
      uriOffset.fileUri,
      uriOffset.fileOffset,
      uriOffset.length,
    );
  }
}
