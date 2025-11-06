// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../messages/codes.dart';
import '../scanner/token.dart';
import 'parser_impl.dart';

class DirectiveContext {
  /// Whether the `enhanced-parts` feature is enabled.
  final bool enableFeatureEnhancedParts;

  DirectiveState state = DirectiveState.Unknown;

  DirectiveContext({required this.enableFeatureEnhancedParts});

  void checkScriptTag(Parser parser, Token token) {
    if (state == DirectiveState.Unknown) {
      state = DirectiveState.Script;
      return;
    }
    // The scanner only produces the SCRIPT_TAG
    // when it is the first token in the file.
    throw "Internal error: Unexpected script tag.";
  }

  void checkDeclaration() {
    if (state != DirectiveState.PartOf) {
      state = DirectiveState.Declarations;
    }
  }

  void checkExport(Parser parser, Token token) {
    switch (state) {
      case DirectiveState.Unknown:
      case DirectiveState.Script:
      case DirectiveState.Library:
      case DirectiveState.ImportAndExport:
        state = DirectiveState.ImportAndExport;
      case DirectiveState.Part:
        parser.reportRecoverableError(token, codeExportAfterPart);
      case DirectiveState.PartOf:
        if (enableFeatureEnhancedParts) {
          state = DirectiveState.ImportAndExport;
        } else {
          parser.reportRecoverableError(token, codeNonPartOfDirectiveInPart);
        }
      case DirectiveState.Declarations:
        parser.reportRecoverableError(token, codeDirectiveAfterDeclaration);
    }
  }

  void checkImport(Parser parser, Token token) {
    switch (state) {
      case DirectiveState.Unknown:
      case DirectiveState.Script:
      case DirectiveState.Library:
      case DirectiveState.ImportAndExport:
        state = DirectiveState.ImportAndExport;
      case DirectiveState.Part:
        parser.reportRecoverableError(token, codeImportAfterPart);
      case DirectiveState.PartOf:
        if (enableFeatureEnhancedParts) {
          state = DirectiveState.ImportAndExport;
        } else {
          parser.reportRecoverableError(token, codeNonPartOfDirectiveInPart);
        }
      case DirectiveState.Declarations:
        parser.reportRecoverableError(token, codeDirectiveAfterDeclaration);
    }
  }

  void checkLibrary(Parser parser, Token token) {
    if (state.index < DirectiveState.Library.index) {
      state = DirectiveState.Library;
      return;
    }
    // Recovery
    if (state == DirectiveState.Library) {
      parser.reportRecoverableError(token, codeMultipleLibraryDirectives);
    } else if (state == DirectiveState.PartOf) {
      parser.reportRecoverableError(token, codeNonPartOfDirectiveInPart);
    } else {
      parser.reportRecoverableError(token, codeLibraryDirectiveNotFirst);
    }
  }

  void checkPart(Parser parser, Token token) {
    switch (state) {
      case DirectiveState.Unknown:
      case DirectiveState.Script:
      case DirectiveState.Library:
      case DirectiveState.ImportAndExport:
      case DirectiveState.Part:
        state = DirectiveState.Part;
      case DirectiveState.PartOf:
        if (enableFeatureEnhancedParts) {
          state = DirectiveState.ImportAndExport;
        } else {
          parser.reportRecoverableError(token, codeNonPartOfDirectiveInPart);
        }
      case DirectiveState.Declarations:
        parser.reportRecoverableError(token, codeDirectiveAfterDeclaration);
    }
  }

  void checkPartOf(Parser parser, Token token) {
    if (state == DirectiveState.Unknown) {
      state = DirectiveState.PartOf;
      return;
    }
    // Recovery
    if (state == DirectiveState.PartOf) {
      parser.reportRecoverableError(token, codePartOfTwice);
    } else {
      parser.reportRecoverableError(token, codeNonPartOfDirectiveInPart);
    }
  }

  @override
  String toString() => 'DirectiveContext(${state})';
}

enum DirectiveState {
  Unknown,
  Script,
  Library,
  ImportAndExport,
  Part,
  PartOf,
  Declarations,
}
