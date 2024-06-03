// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.stack_listener_impl;

import 'package:_fe_analyzer_shared/src/experiments/flags.dart' as shared
    show ExperimentalFlag;
import 'package:_fe_analyzer_shared/src/parser/stack_listener.dart';
import 'package:_fe_analyzer_shared/src/scanner/scanner.dart' show Token;
import 'package:kernel/ast.dart';

import '../../api_prototype/experimental_flags.dart';
import '../codes/fasta_codes.dart';
import '../problems.dart' as problems
    show internalProblem, unhandled, unsupported;
import 'source_library_builder.dart';

abstract class StackListenerImpl extends StackListener {
  SourceLibraryBuilder get libraryBuilder;

  LibraryFeatures get libraryFeatures => libraryBuilder.libraryFeatures;

  @override
  Uri get importUri => libraryBuilder.origin.importUri;

  AsyncMarker asyncMarkerFromTokens(Token? asyncToken, Token? starToken) {
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
  List<Expression> finishMetadata(Annotatable? parent) {
    return problems.unsupported("finishMetadata", -1, uri);
  }

  /// Used to report an internal error encountered in the stack listener.
  @override
  Never internalProblem(Message message, int charOffset, Uri uri) {
    return problems.internalProblem(message, charOffset, uri);
  }

  /// Used to report an unexpected situation encountered in the stack
  /// listener.
  Never unhandled(String what, String where, int charOffset, Uri? uri) {
    return problems.unhandled(what, where, charOffset, uri);
  }

  /// Reports an error if [feature] is not enabled, using [charOffset] and
  /// [length] for the location of the message.
  ///
  /// Return `true` if the [feature] is not enabled.
  bool reportIfNotEnabled(LibraryFeature feature, int charOffset, int length) {
    if (!feature.isEnabled) {
      libraryBuilder.reportFeatureNotEnabled(feature, uri, charOffset, length);
      return true;
    }
    return false;
  }

  @override
  void handleExperimentNotEnabled(shared.ExperimentalFlag experimentalFlag,
      Token startToken, Token endToken) {
    reportIfNotEnabled(
        libraryFeatures.fromSharedExperimentalFlags(experimentalFlag),
        startToken.charOffset,
        endToken.charEnd - startToken.charOffset);
  }
}

/// A null-aware alternative to `token.offset`.  If [token] is `null`, returns
/// `TreeNode.noOffset`.
int offsetForToken(Token? token) {
  return token == null ? TreeNode.noOffset : token.offset;
}
