// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.stack_listener_impl;

import 'package:_fe_analyzer_shared/src/messages/codes.dart' show Message;

import 'package:_fe_analyzer_shared/src/parser/parser.dart' show Parser;

import 'package:_fe_analyzer_shared/src/parser/stack_listener.dart';

import 'package:_fe_analyzer_shared/src/scanner/scanner.dart' show Token;
import 'package:front_end/src/api_prototype/experimental_flags.dart';

import 'package:kernel/ast.dart'
    show AsyncMarker, Expression, FunctionNode, TreeNode;

import '../fasta_codes.dart';

import '../problems.dart' as problems
    show internalProblem, unhandled, unsupported;

import 'source_library_builder.dart';

abstract class StackListenerImpl extends StackListener {
  SourceLibraryBuilder get libraryBuilder;

  AsyncMarker asyncMarkerFromTokens(Token asyncToken, Token starToken) {
    if (asyncToken == null || identical(asyncToken.stringValue, "sync")) {
      if (starToken == null) {
        return AsyncMarker.Sync;
      } else {
        assert(identical(starToken.stringValue, "*"));
        return AsyncMarker.SyncStar;
      }
    } else if (identical(asyncToken.stringValue, "async")) {
      if (starToken == null) {
        return AsyncMarker.Async;
      } else {
        assert(identical(starToken.stringValue, "*"));
        return AsyncMarker.AsyncStar;
      }
    } else {
      return unhandled(asyncToken.lexeme, "asyncMarkerFromTokens",
          asyncToken.charOffset, null);
    }
  }

  // TODO(ahe): This doesn't belong here. Only implemented by body_builder.dart
  // and ast_builder.dart.
  void finishFunction(
      covariant formals, AsyncMarker asyncModifier, covariant body) {
    return problems.unsupported("finishFunction", -1, uri);
  }

  // TODO(ahe): This doesn't belong here. Only implemented by body_builder.dart
  // and ast_builder.dart.
  dynamic finishFields() {
    return problems.unsupported("finishFields", -1, uri);
  }

  // TODO(ahe): This doesn't belong here. Only implemented by body_builder.dart
  // and ast_builder.dart.
  List<Expression> finishMetadata(TreeNode parent) {
    return problems.unsupported("finishMetadata", -1, uri);
  }

  // TODO(ahe): This doesn't belong here. Only implemented by body_builder.dart
  // and ast_builder.dart.
  void exitLocalScope() => problems.unsupported("exitLocalScope", -1, uri);

  // TODO(ahe): This doesn't belong here. Only implemented by body_builder.dart.
  dynamic parseSingleExpression(
      Parser parser, Token token, FunctionNode parameters) {
    return problems.unsupported("finishSingleExpression", -1, uri);
  }

  /// Used to report an internal error encountered in the stack listener.
  internalProblem(Message message, int charOffset, Uri uri) {
    return problems.internalProblem(message, charOffset, uri);
  }

  /// Used to report an unexpected situation encountered in the stack
  /// listener.
  dynamic unhandled(String what, String where, int charOffset, Uri uri) {
    return problems.unhandled(what, where, charOffset, uri);
  }

  void reportMissingNonNullableSupport(Token token) {
    assert(!libraryBuilder.isNonNullableByDefault);
    assert(token != null);
    if (libraryBuilder.enableNonNullableInLibrary) {
      if (libraryBuilder.languageVersion.isExplicit) {
        addProblem(
            templateNonNullableOptOutExplicit.withArguments(
                libraryBuilder.enableNonNullableVersionInLibrary.toText()),
            token.charOffset,
            token.charCount,
            context: <LocatedMessage>[
              messageNonNullableOptOutComment.withLocation(
                  libraryBuilder.languageVersion.fileUri,
                  libraryBuilder.languageVersion.charOffset,
                  libraryBuilder.languageVersion.charCount)
            ]);
      } else {
        addProblem(
            templateNonNullableOptOutImplicit.withArguments(
                libraryBuilder.enableNonNullableVersionInLibrary.toText()),
            token.charOffset,
            token.charCount);
      }
    } else if (libraryBuilder.loader.target
        .isExperimentEnabledByDefault(ExperimentalFlag.nonNullable)) {
      if (libraryBuilder.languageVersion.version <
          libraryBuilder.enableNonNullableVersionInLibrary) {
        addProblem(
            templateExperimentDisabledInvalidLanguageVersion.withArguments(
                libraryBuilder.enableNonNullableVersionInLibrary.toText()),
            token.offset,
            noLength);
      } else {
        addProblem(templateExperimentDisabled.withArguments('non-nullable'),
            token.offset, noLength);
      }
    } else if (!libraryBuilder.loader.target
        .isExperimentEnabledGlobally(ExperimentalFlag.nonNullable)) {
      if (libraryBuilder.languageVersion.version <
          libraryBuilder.enableNonNullableVersionInLibrary) {
        addProblem(
            templateExperimentNotEnabledNoFlagInvalidLanguageVersion
                .withArguments(
                    libraryBuilder.enableNonNullableVersionInLibrary.toText()),
            token.offset,
            noLength);
      } else {
        addProblem(messageExperimentNotEnabledNoFlag, token.offset, noLength);
      }
    } else {
      addProblem(
          templateExperimentNotEnabled.withArguments('non-nullable',
              libraryBuilder.enableNonNullableVersionInLibrary.toText()),
          token.offset,
          noLength);
    }
  }

  void reportErrorIfNullableType(Token questionMark) {
    if (questionMark != null) {
      reportMissingNonNullableSupport(questionMark);
    }
  }

  void reportNonNullableModifierError(Token modifierToken) {
    assert(!libraryBuilder.isNonNullableByDefault);
    if (modifierToken != null) {
      reportMissingNonNullableSupport(modifierToken);
    }
  }

  void reportNonNullAssertExpressionNotEnabled(Token bang) {
    reportMissingNonNullableSupport(bang);
  }
}

/// A null-aware alternative to `token.offset`.  If [token] is `null`, returns
/// `TreeNode.noOffset`.
int offsetForToken(Token token) {
  return token == null ? TreeNode.noOffset : token.offset;
}
