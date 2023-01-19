// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../messages/codes.dart';
import 'value_kind.dart';

mixin StackChecker {
  /// Used to report an internal error encountered in the stack listener.
  Never internalProblem(Message message, int charOffset, Uri uri);

  /// Checks that [value] matches the expected [kind].
  ///
  /// Use this in assert statements like
  ///
  ///     assert(checkStackValue(uri, fileOffset, ValueKind.Token, value));
  ///
  /// to document and validate the expected value kind.
  bool checkStackValue(
      Uri uri, int? fileOffset, ValueKind kind, Object? value) {
    if (!kind.check(value)) {
      String message = 'Unexpected value `${value}` (${value.runtimeType}). '
          'Expected ${kind}.';
      if (fileOffset != null) {
        // If offset is available report and internal problem to show the
        // parsed code in the output.
        throw internalProblem(
            new Message(const Code<String>('Internal error'),
                problemMessage: message),
            fileOffset,
            uri);
      } else {
        throw message;
      }
    }
    return true;
  }

  int get stackLength;

  Object? lookupStack(int index);

  /// Checks the top of the current stack against [kinds]. If a mismatch is
  /// found, a top of the current stack is print along with the expected [kinds]
  /// marking the frames that don't match, and throws an exception.
  ///
  /// Use this in assert statements like
  ///
  ///     assert(checkStackState(
  ///         uri, fileOffset, [ValueKind.Integer, ValueKind.StringOrNull]))
  ///
  /// to document the expected stack and get earlier errors on unexpected stack
  /// content.
  bool checkStackState(Uri uri, int? fileOffset, List<ValueKind> kinds) {
    bool success = true;
    for (int kindIndex = 0; kindIndex < kinds.length; kindIndex++) {
      ValueKind kind = kinds[kindIndex];
      if (kindIndex < stackLength) {
        Object? value = lookupStack(kindIndex);
        if (!kind.check(value)) {
          success = false;
        }
      } else {
        success = false;
      }
    }
    if (!success) {
      StringBuffer sb = new StringBuffer();

      String safeToString(Object? object) {
        try {
          return '$object';
        } catch (e) {
          // Judgments fail on toString.
          return object.runtimeType.toString();
        }
      }

      String padLeft(Object object, int length) {
        String text = safeToString(object);
        if (text.length < length) {
          return ' ' * (length - text.length) + text;
        }
        return text;
      }

      String padRight(Object object, int length) {
        String text = safeToString(object);
        if (text.length < length) {
          return text + ' ' * (length - text.length);
        }
        return text;
      }

      // Compute kind/stack frame information for all expected values plus 3 more
      // stack elements if available.
      for (int kindIndex = 0; kindIndex < kinds.length + 3; kindIndex++) {
        if (kindIndex >= stackLength && kindIndex >= kinds.length) {
          // No more stack elements nor kinds to display.
          break;
        }
        sb.write(padLeft(kindIndex, 4));
        sb.write(': ');
        ValueKind? kind;
        if (kindIndex < kinds.length) {
          kind = kinds[kindIndex];
          sb.write(padRight(kind, 60));
        } else {
          sb.write(padRight('---', 60));
        }
        if (kindIndex < stackLength) {
          Object? value = lookupStack(kindIndex);
          if (kind == null || kind.check(value)) {
            sb.write(' ');
          } else {
            sb.write('*');
          }
          sb.write(safeToString(value));
          sb.write(' (${value.runtimeType})');
        } else {
          if (kind == null) {
            sb.write(' ');
          } else {
            sb.write('*');
          }
          sb.write('---');
        }
        sb.writeln();
      }

      String message = '$runtimeType failure\n$sb';
      if (fileOffset != null) {
        // If offset is available report and internal problem to show the
        // parsed code in the output.
        throw internalProblem(
            new Message(const Code<String>('Internal error'),
                problemMessage: message),
            fileOffset,
            uri);
      } else {
        throw message;
      }
    }
    return success;
  }
}
