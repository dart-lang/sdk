// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analyzer.src.dart.sdk.patch;

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/dart/scanner/reader.dart';
import 'package:analyzer/src/dart/scanner/scanner.dart';
import 'package:analyzer/src/dart/sdk/sdk.dart';
import 'package:analyzer/src/generated/parser.dart';
import 'package:analyzer/src/generated/sdk.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:meta/meta.dart';
import 'package:path/src/context.dart';

/**
 * [SdkPatcher] applies patches to SDK [CompilationUnit].
 */
class SdkPatcher {
  String _baseDesc;
  String _patchDesc;
  CompilationUnit _patchUnit;

  /**
   * Patch the given [unit] of a SDK [source] with the patches defined in
   * the [sdk] for the given [platform].  Throw [ArgumentError] if a patch
   * file cannot be read, or the contents violates rules for patch files.
   *
   * If [addNewTopLevelDeclarations] is `true`, then the [unit] is the
   * defining unit of a library, so new top-level declarations should be
   * added to this unit.  For parts new declarations may be added only to the
   * patched classes.
   *
   * TODO(scheglov) auto-detect [addNewTopLevelDeclarations]
   */
  void patch(FolderBasedDartSdk sdk, int platform,
      AnalysisErrorListener errorListener, Source source, CompilationUnit unit,
      {bool addNewTopLevelDeclarations: true}) {
    // Prepare the patch files to apply.
    List<String> patchPaths;
    {
      // TODO(scheglov) add support for patching parts
      String uriStr = source.uri.toString();
      SdkLibrary sdkLibrary = sdk.getSdkLibrary(uriStr);
      if (sdkLibrary == null) {
        throw new ArgumentError(
            'The library $uriStr is not defined in the SDK.');
      }
      patchPaths = sdkLibrary.getPatches(platform);
    }

    bool strongMode = sdk.analysisOptions.strongMode;
    Context pathContext = sdk.resourceProvider.pathContext;
    for (String path in patchPaths) {
      String pathInLib = pathContext.joinAll(path.split('/'));
      File patchFile = sdk.libraryDirectory.getChildAssumingFile(pathInLib);
      if (!patchFile.exists) {
        throw new ArgumentError(
            'The patch file ${patchFile.path} for $source does not exist.');
      }
      Source patchSource = patchFile.createSource();
      CompilationUnit patchUnit = parse(patchSource, strongMode, errorListener);

      // Prepare for reporting errors.
      _baseDesc = source.toString();
      _patchDesc = patchFile.path;
      _patchUnit = patchUnit;

      _patchDirectives(
          source, unit, patchSource, patchUnit, addNewTopLevelDeclarations);
      _patchTopLevelDeclarations(
          source, unit, patchSource, patchUnit, addNewTopLevelDeclarations);
    }
  }

  void _failExternalKeyword(Source source, String name, int offset) {
    throw new ArgumentError(
        'The keyword "external" was expected for "$name" in $source @ $offset.');
  }

  void _failIfPublicName(AstNode node, String name) {
    if (!Identifier.isPrivateName(name)) {
      _failInPatch('contains a public declaration "$name"', node.offset);
    }
  }

  void _failInPatch(String message, int offset) {
    String loc = _getLocationDesc3(_patchUnit, offset);
    throw new ArgumentError(
        'The patch file $_patchDesc for $_baseDesc $message at $loc.');
  }

  String _getLocationDesc3(CompilationUnit unit, int offset) {
    LineInfo_Location location = unit.lineInfo.getLocation(offset);
    return 'the line ${location.lineNumber}';
  }

  void _patchDirectives(
      Source baseSource,
      CompilationUnit baseUnit,
      Source patchSource,
      CompilationUnit patchUnit,
      bool addNewTopLevelDeclarations) {
    for (Directive patchDirective in patchUnit.directives) {
      if (patchDirective is ImportDirective) {
        baseUnit.directives.add(patchDirective);
      } else {
        _failInPatch('contains an unsupported "$patchDirective" directive',
            patchDirective.offset);
      }
    }
  }

  void _patchTopLevelDeclarations(
      Source baseSource,
      CompilationUnit baseUnit,
      Source patchSource,
      CompilationUnit patchUnit,
      bool addNewTopLevelDeclarations) {
    List<CompilationUnitMember> declarationsToAppend = [];
    for (CompilationUnitMember patchDeclaration in patchUnit.declarations) {
      if (patchDeclaration is FunctionDeclaration) {
        String name = patchDeclaration.name.name;
        if (_hasPatchAnnotation(patchDeclaration.metadata)) {
          for (CompilationUnitMember baseDeclaration in baseUnit.declarations) {
            if (patchDeclaration is FunctionDeclaration &&
                baseDeclaration is FunctionDeclaration &&
                baseDeclaration.name.name == name) {
              if (_hasPatchAnnotation(patchDeclaration.metadata)) {
                // Remove the "external" keyword.
                Token externalKeyword = baseDeclaration.externalKeyword;
                if (externalKeyword != null) {
                  baseDeclaration.externalKeyword = null;
                  _removeToken(externalKeyword);
                } else {
                  _failExternalKeyword(
                      baseSource, name, baseDeclaration.offset);
                }
                // Replace the body.
                FunctionExpression oldExpr = baseDeclaration.functionExpression;
                FunctionBody newBody = patchDeclaration.functionExpression.body;
                _replaceNodeTokens(oldExpr.body, newBody);
                oldExpr.body = newBody;
              }
            }
          }
        } else if (addNewTopLevelDeclarations) {
          _failIfPublicName(patchDeclaration, name);
          declarationsToAppend.add(patchDeclaration);
        }
      } else if (patchDeclaration is FunctionTypeAlias) {
        if (patchDeclaration.metadata.isNotEmpty) {
          _failInPatch('contains a function type alias with an annotation',
              patchDeclaration.offset);
        }
        _failIfPublicName(patchDeclaration, patchDeclaration.name.name);
        declarationsToAppend.add(patchDeclaration);
      } else {
        _failInPatch('contains an unsupported top-level declaration',
            patchDeclaration.offset);
      }
    }
    // Append new top-level declarations.
    Token lastToken = baseUnit.endToken.previous;
    for (CompilationUnitMember newDeclaration in declarationsToAppend) {
      newDeclaration.endToken.setNext(lastToken.next);
      lastToken.setNext(newDeclaration.beginToken);
      baseUnit.declarations.add(newDeclaration);
      lastToken = newDeclaration.endToken;
    }
  }

  /**
   * Parse the given [source] into AST.
   */
  @visibleForTesting
  static CompilationUnit parse(
      Source source, bool strong, AnalysisErrorListener errorListener) {
    String code = source.contents.data;

    CharSequenceReader reader = new CharSequenceReader(code);
    Scanner scanner = new Scanner(source, reader, errorListener);
    scanner.scanGenericMethodComments = strong;
    Token token = scanner.tokenize();
    LineInfo lineInfo = new LineInfo(scanner.lineStarts);

    Parser parser = new Parser(source, errorListener);
    parser.parseGenericMethodComments = strong;
    CompilationUnit unit = parser.parseCompilationUnit(token);
    unit.lineInfo = lineInfo;
    return unit;
  }

  /**
   * Return `true` if [metadata] has the `@patch` annotation.
   */
  static bool _hasPatchAnnotation(List<Annotation> metadata) {
    return metadata.any((annotation) {
      Identifier name = annotation.name;
      return annotation.constructorName == null &&
          name is SimpleIdentifier &&
          name.name == 'patch';
    });
  }

  /**
   * Remove the [token] from the stream.
   */
  static void _removeToken(Token token) {
    token.previous.setNext(token.next);
  }

  /**
   * Replace tokens of the [oldNode] with tokens of the [newNode].
   */
  static void _replaceNodeTokens(AstNode oldNode, AstNode newNode) {
    oldNode.beginToken.previous.setNext(newNode.beginToken);
    newNode.endToken.setNext(oldNode.endToken.next);
  }
}
