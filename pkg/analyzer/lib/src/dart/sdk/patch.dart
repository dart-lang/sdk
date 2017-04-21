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
import 'package:analyzer/src/generated/parser.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:meta/meta.dart';

/**
 * [SdkPatcher] applies patches to SDK [CompilationUnit].
 */
class SdkPatcher {
  bool _allowNewPublicNames;
  String _baseDesc;
  String _patchDesc;
  CompilationUnit _patchUnit;

  /**
   * Patch the given [unit] of a SDK [source] with the patches defined in
   * [allPatchPaths].  Throw [ArgumentError] if a patch
   * file cannot be read, or the contents violates rules for patch files.
   */
  void patch(
      ResourceProvider resourceProvider,
      bool strongMode,
      Map<String, List<String>> allPatchPaths,
      AnalysisErrorListener errorListener,
      Source source,
      CompilationUnit unit) {
    // Process URI.
    String libraryUriStr;
    bool isLibraryDefiningUnit;
    {
      Uri uri = source.uri;
      if (uri.scheme != 'dart') {
        throw new ArgumentError(
            'The URI of the unit to patch must have the "dart" scheme: $uri');
      }
      List<String> uriSegments = uri.pathSegments;
      String libraryName = uriSegments.first;
      libraryUriStr = 'dart:$libraryName';
      isLibraryDefiningUnit = uriSegments.length == 1;
      _allowNewPublicNames = libraryName == '_internal';
    }
    // Prepare the patch files to apply.
    List<String> patchPaths = allPatchPaths[libraryUriStr] ?? const <String>[];

    for (String path in patchPaths) {
      File patchFile = resourceProvider.getFile(path);
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

      if (isLibraryDefiningUnit) {
        _patchDirectives(source, unit, patchSource, patchUnit);
      }
      _patchTopLevelDeclarations(unit, patchUnit, isLibraryDefiningUnit);
    }
  }

  void _failExternalKeyword(String name, int offset) {
    throw new ArgumentError(
        'The keyword "external" was expected for "$name" in $_baseDesc @ $offset.');
  }

  void _failIfPublicName(AstNode node, String name) {
    if (_allowNewPublicNames) {
      return;
    }
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

  void _matchParameterLists(FormalParameterList baseParameters,
      FormalParameterList patchParameters, String context()) {
    if (baseParameters == null && patchParameters == null) return;
    if (baseParameters == null || patchParameters == null) {
      throw new ArgumentError("${context()}, parameter lists don't match");
    }
    if (baseParameters.parameters.length != patchParameters.parameters.length) {
      throw new ArgumentError(
          '${context()}, parameter lists have different lengths');
    }
    for (var i = 0; i < baseParameters.parameters.length; i++) {
      _matchParameters(baseParameters.parameters[i],
          patchParameters.parameters[i], () => '${context()}, parameter $i');
    }
  }

  void _matchParameters(FormalParameter baseParameter,
      FormalParameter patchParameter, String whichParameter()) {
    if (baseParameter.identifier.name != patchParameter.identifier.name) {
      throw new ArgumentError('${whichParameter()} has different name');
    }
    NormalFormalParameter baseParameterWithoutDefault =
        _withoutDefault(baseParameter);
    NormalFormalParameter patchParameterWithoutDefault =
        _withoutDefault(patchParameter);
    if (baseParameterWithoutDefault is SimpleFormalParameter &&
        patchParameterWithoutDefault is SimpleFormalParameter) {
      _matchTypes(baseParameterWithoutDefault.type,
          patchParameterWithoutDefault.type, () => '${whichParameter()} type');
    } else if (baseParameterWithoutDefault is FunctionTypedFormalParameter &&
        patchParameterWithoutDefault is FunctionTypedFormalParameter) {
      _matchTypes(
          baseParameterWithoutDefault.returnType,
          patchParameterWithoutDefault.returnType,
          () => '${whichParameter()} return type');
      _matchParameterLists(
          baseParameterWithoutDefault.parameters,
          patchParameterWithoutDefault.parameters,
          () => '${whichParameter()} parameters');
    } else if (baseParameterWithoutDefault is FieldFormalParameter &&
        patchParameter is FieldFormalParameter) {
      throw new ArgumentError(
          '${whichParameter()} cannot be patched (field formal parameters are not supported)');
    } else {
      throw new ArgumentError(
          '${whichParameter()} mismatch (different parameter kinds)');
    }
  }

  void _matchTypes(TypeName baseType, TypeName patchType, String whichType()) {
    error() => new ArgumentError("${whichType()} doesn't match");
    if (baseType == null && patchType == null) return;
    if (baseType == null || patchType == null) throw error();
    // Match up the types token by token; this is more restrictive than strictly
    // necessary, but it's easy and sufficient for patching purposes.
    Token baseToken = baseType.beginToken;
    Token patchToken = patchType.beginToken;
    while (true) {
      if (baseToken.lexeme != patchToken.lexeme) throw error();
      if (identical(baseToken, baseType.endToken) &&
          identical(patchToken, patchType.endToken)) {
        break;
      }
      if (identical(baseToken, baseType.endToken) ||
          identical(patchToken, patchType.endToken)) {
        throw error();
      }
      baseToken = baseToken.next;
      patchToken = patchToken.next;
    }
  }

  void _patchClassMembers(
      ClassDeclaration baseClass, ClassDeclaration patchClass) {
    String className = baseClass.name.name;
    List<ClassMember> membersToAppend = [];
    for (ClassMember patchMember in patchClass.members) {
      if (patchMember is FieldDeclaration) {
        if (_hasPatchAnnotation(patchMember.metadata)) {
          _failInPatch('attempts to patch a field', patchMember.offset);
        }
        List<VariableDeclaration> fields = patchMember.fields.variables;
        if (fields.length != 1) {
          _failInPatch('contains a field declaration with more than one field',
              patchMember.offset);
        }
        String name = fields[0].name.name;
        if (!_allowNewPublicNames &&
            !Identifier.isPrivateName(className) &&
            !Identifier.isPrivateName(name)) {
          _failInPatch('contains a public field', patchMember.offset);
        }
        membersToAppend.add(patchMember);
      } else if (patchMember is MethodDeclaration) {
        String name = patchMember.name.name;
        if (_hasPatchAnnotation(patchMember.metadata)) {
          for (ClassMember baseMember in baseClass.members) {
            if (baseMember is MethodDeclaration &&
                baseMember.name.name == name) {
              // Remove the "external" keyword.
              Token externalKeyword = baseMember.externalKeyword;
              if (externalKeyword != null) {
                baseMember.externalKeyword = null;
                _removeToken(externalKeyword);
              } else {
                _failExternalKeyword(name, baseMember.offset);
              }
              _matchParameterLists(
                  baseMember.parameters,
                  patchMember.parameters,
                  () => 'While patching $className.$name');
              _matchTypes(baseMember.returnType, patchMember.returnType,
                  () => 'While patching $className.$name, return type');
              // Replace the body.
              FunctionBody oldBody = baseMember.body;
              FunctionBody newBody = patchMember.body;
              _replaceNodeTokens(oldBody, newBody);
              baseMember.body = newBody;
            }
          }
        } else {
          _failIfPublicName(patchMember, name);
          membersToAppend.add(patchMember);
        }
      } else if (patchMember is ConstructorDeclaration) {
        String name = patchMember.name?.name;
        if (_hasPatchAnnotation(patchMember.metadata)) {
          for (ClassMember baseMember in baseClass.members) {
            if (baseMember is ConstructorDeclaration &&
                baseMember.name?.name == name) {
              // Remove the "external" keyword.
              Token externalKeyword = baseMember.externalKeyword;
              if (externalKeyword != null) {
                baseMember.externalKeyword = null;
                _removeToken(externalKeyword);
              } else {
                _failExternalKeyword(name, baseMember.offset);
              }
              // Factory vs. generative.
              if (baseMember.factoryKeyword == null &&
                  patchMember.factoryKeyword != null) {
                _failInPatch(
                    'attempts to replace generative constructor with a factory one',
                    patchMember.offset);
              } else if (baseMember.factoryKeyword != null &&
                  patchMember.factoryKeyword == null) {
                _failInPatch(
                    'attempts to replace factory constructor with a generative one',
                    patchMember.offset);
              }
              // The base constructor should not have initializers.
              if (baseMember.initializers.isNotEmpty) {
                throw new ArgumentError(
                    'Cannot patch external constructors with initializers '
                    'in $_baseDesc.');
              }
              _matchParameterLists(
                  baseMember.parameters, patchMember.parameters, () {
                String nameSuffix = name == null ? '' : '.$name';
                return 'While patching $className$nameSuffix';
              });
              // Prepare nodes.
              FunctionBody baseBody = baseMember.body;
              FunctionBody patchBody = patchMember.body;
              NodeList<ConstructorInitializer> baseInitializers =
                  baseMember.initializers;
              NodeList<ConstructorInitializer> patchInitializers =
                  patchMember.initializers;
              // Replace initializers and link tokens.
              if (patchInitializers.isNotEmpty) {
                baseMember.parameters.endToken
                    .setNext(patchInitializers.beginToken.previous);
                baseInitializers.addAll(patchInitializers);
                patchBody.endToken.setNext(baseBody.endToken.next);
              } else {
                _replaceNodeTokens(baseBody, patchBody);
              }
              // Replace the body.
              baseMember.body = patchBody;
            }
          }
        } else {
          if (name == null) {
            if (!_allowNewPublicNames && !Identifier.isPrivateName(className)) {
              _failInPatch(
                  'contains an unnamed public constructor', patchMember.offset);
            }
          } else {
            _failIfPublicName(patchMember, name);
          }
          membersToAppend.add(patchMember);
        }
      } else {
        String className = patchClass.name.name;
        _failInPatch('contains an unsupported class member in $className',
            patchMember.offset);
      }
    }
    // Append new class members.
    _appendToNodeList(
        baseClass.members, membersToAppend, baseClass.leftBracket);
  }

  void _patchDirectives(Source baseSource, CompilationUnit baseUnit,
      Source patchSource, CompilationUnit patchUnit) {
    for (Directive patchDirective in patchUnit.directives) {
      if (patchDirective is ImportDirective) {
        baseUnit.directives.add(patchDirective);
      } else {
        _failInPatch('contains an unsupported "$patchDirective" directive',
            patchDirective.offset);
      }
    }
  }

  void _patchTopLevelDeclarations(CompilationUnit baseUnit,
      CompilationUnit patchUnit, bool appendNewTopLevelDeclarations) {
    List<CompilationUnitMember> declarationsToAppend = [];
    for (CompilationUnitMember patchDeclaration in patchUnit.declarations) {
      if (patchDeclaration is FunctionDeclaration) {
        String name = patchDeclaration.name.name;
        if (_hasPatchAnnotation(patchDeclaration.metadata)) {
          for (CompilationUnitMember baseDeclaration in baseUnit.declarations) {
            if (patchDeclaration is FunctionDeclaration &&
                baseDeclaration is FunctionDeclaration &&
                baseDeclaration.name.name == name) {
              // Remove the "external" keyword.
              Token externalKeyword = baseDeclaration.externalKeyword;
              if (externalKeyword != null) {
                baseDeclaration.externalKeyword = null;
                _removeToken(externalKeyword);
              } else {
                _failExternalKeyword(name, baseDeclaration.offset);
              }
              _matchParameterLists(
                  baseDeclaration.functionExpression.parameters,
                  patchDeclaration.functionExpression.parameters,
                  () => 'While patching $name');
              _matchTypes(
                  baseDeclaration.returnType,
                  patchDeclaration.returnType,
                  () => 'While patching $name, return type');
              // Replace the body.
              FunctionExpression oldExpr = baseDeclaration.functionExpression;
              FunctionBody newBody = patchDeclaration.functionExpression.body;
              _replaceNodeTokens(oldExpr.body, newBody);
              oldExpr.body = newBody;
            }
          }
        } else if (appendNewTopLevelDeclarations) {
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
      } else if (patchDeclaration is ClassDeclaration) {
        if (_hasPatchAnnotation(patchDeclaration.metadata)) {
          String name = patchDeclaration.name.name;
          for (CompilationUnitMember baseDeclaration in baseUnit.declarations) {
            if (baseDeclaration is ClassDeclaration &&
                baseDeclaration.name.name == name) {
              _patchClassMembers(baseDeclaration, patchDeclaration);
            }
          }
        } else {
          _failIfPublicName(patchDeclaration, patchDeclaration.name.name);
          declarationsToAppend.add(patchDeclaration);
        }
      } else if (patchDeclaration is TopLevelVariableDeclaration &&
          !_hasPatchAnnotation(patchDeclaration.metadata)) {
        for (VariableDeclaration variable
            in patchDeclaration.variables.variables) {
          _failIfPublicName(patchDeclaration, variable.name.name);
        }
        declarationsToAppend.add(patchDeclaration);
      } else {
        _failInPatch('contains an unsupported top-level declaration',
            patchDeclaration.offset);
      }
    }
    // Append new top-level declarations.
    if (appendNewTopLevelDeclarations) {
      _appendToNodeList(baseUnit.declarations, declarationsToAppend,
          baseUnit.endToken.previous);
    }
  }

  NormalFormalParameter _withoutDefault(FormalParameter parameter) {
    if (parameter is NormalFormalParameter) {
      return parameter;
    } else if (parameter is DefaultFormalParameter) {
      return parameter.parameter;
    } else {
      // Should not happen.
      assert(false);
      return null;
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
   * Append [newNodes] to the given [nodes] and attach new tokens to the end
   * token of the last [nodes] items, or, if it is empty, to [defaultPrevToken].
   */
  static void _appendToNodeList(
      NodeList<AstNode> nodes, List<AstNode> newNodes, Token defaultPrevToken) {
    Token prevToken = nodes.endToken ?? defaultPrevToken;
    for (AstNode newNode in newNodes) {
      newNode.endToken.setNext(prevToken.next);
      prevToken.setNext(newNode.beginToken);
      nodes.add(newNode);
      prevToken = newNode.endToken;
    }
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
