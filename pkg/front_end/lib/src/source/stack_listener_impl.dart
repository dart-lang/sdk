// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.stack_listener_impl;

import 'package:_fe_analyzer_shared/src/experiments/flags.dart' as shared
    show ExperimentalFlag;
import 'package:_fe_analyzer_shared/src/parser/stack_listener.dart';
import 'package:_fe_analyzer_shared/src/scanner/scanner.dart' show Token;
import 'package:kernel/ast.dart';

import '../api_prototype/experimental_flags.dart';
import '../base/problems.dart' as problems show internalProblem, unhandled;
import '../codes/cfe_codes.dart';

abstract class StackListenerImpl extends StackListener {
  LibraryFeatures get libraryFeatures;

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

  /// Used to report an internal error encountered in the stack listener.
  @override
  // Coverage-ignore(suite): Not run.
  Never internalProblem(Message message, int charOffset, Uri uri) {
    return problems.internalProblem(message, charOffset, uri);
  }

  // Coverage-ignore(suite): Not run.
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
      reportFeatureNotEnabled(feature, charOffset, length);
      return true;
    }
    return false;
  }

  /// Reports that [feature] is not enabled, using [charOffset] and
  /// [length] for the location of the message.
  ///
  /// Returns the primary message.
  Message reportFeatureNotEnabled(
      LibraryFeature feature, int charOffset, int length);

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
