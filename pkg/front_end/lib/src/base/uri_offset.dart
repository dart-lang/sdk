// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'messages.dart';

/// Source location pointer used for messaging.
class UriOffset implements UriOffsetLength {
  /// The file URI of the location.
  @override
  final Uri fileUri;

  /// The character offset for the location with [fileUri].
  @override
  final int fileOffset;

  UriOffset(this.fileUri, this.fileOffset);

  @override
  int get length => noLength;
}

/// Source location pointer used for messaging.
class UriOffsetLength {
  /// The file URI of the location.
  final Uri fileUri;

  /// The character offset for the location with [fileUri].
  final int fileOffset;

  /// The length of the location.
  ///
  /// This is used to emitted the correct number of `^` characters in the
  /// message output for the source location.
  final int length;

  UriOffsetLength(this.fileUri, this.fileOffset, this.length);
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
    bool problemOnLibrary = false,
  }) {
    addProblem(
      message,
      uriOffset.fileOffset,
      uriOffset.length,
      uriOffset.fileUri,
      wasHandled: wasHandled,
      context: context,
      severity: severity,
      problemOnLibrary: problemOnLibrary,
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
