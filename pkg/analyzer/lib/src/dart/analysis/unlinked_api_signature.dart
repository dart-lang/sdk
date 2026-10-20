// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:typed_data';

import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/dart/ast/invokes_super_self.dart';
import 'package:analyzer/src/dart/ast/mixin_super_invoked_names.dart';
import 'package:analyzer/src/summary/api_signature.dart';

/// Return the bytes of the unlinked API signature of the given [unit].
///
/// If API signatures of two units are different, they may have different APIs.
Uint8List computeUnlinkedApiSignature(CompilationUnitImpl unit) {
  var computer = _UnitApiSignatureComputer();
  computer.compute(unit);
  return computer.signature.toByteList();
}

class _UnitApiSignatureComputer {
  static const int _kindConstructorDeclaration = 1;
  static const int _kindFieldsDeclaration = 2;
  static const int _kindMethodDeclaration = 3;
  static const int _kindPrimaryConstructorBody = 4;
  static const int _nullNode = 0;
  static const int _notNullNode = 1;
  static const int _nullToken = 0;
  static const int _notNullToken = 1;

  final ApiSignature signature = ApiSignature();

  void compute(CompilationUnitImpl unit) {
    signature.addFeatureSet(unit.featureSet);

    signature.addInt(unit.directives.length);
    unit.directives.forEach(_addNode);

    signature.addInt(unit.declarations2.length);
    for (var declaration in unit.declarations2) {
      switch (declaration) {
        case ClassDeclarationImpl():
          _addClass(declaration);
        case EnumDeclarationImpl():
          _addEnum(declaration);
        case ExtensionDeclarationImpl():
          _addExtension(declaration);
        case ExtensionTypeDeclarationImpl():
          _addNode(declaration);
        case MixinDeclarationImpl():
          _addMixin(declaration);
        case TopLevelFunctionDeclarationImpl():
          _addTokens(
            declaration.beginToken,
            declaration.formalParameters.endToken,
          );
          signature.addBool(declaration.isComplete);
          _addFunctionBodyModifiers(declaration.body);
        case TopLevelGetterDeclarationImpl():
          _addTokens(
            declaration.beginToken,
            declaration.recoveryFormalParameters?.endToken ?? declaration.name,
          );
          signature.addBool(declaration.isComplete);
          _addFunctionBodyModifiers(declaration.body);
        case TopLevelSetterDeclarationImpl():
          _addTokens(
            declaration.beginToken,
            declaration.formalParameters.endToken,
          );
          signature.addBool(declaration.isComplete);
          _addFunctionBodyModifiers(declaration.body);
        case TopLevelVariablesDeclarationImpl():
          _topLevelVariablesDeclaration(declaration);
        case ClassTypeAliasImpl() ||
            FunctionTypeAlias2Impl() ||
            GenericTypeAlias2Impl():
          _addNode(declaration);
      }
    }
  }

  void _addClass(ClassDeclarationImpl node) {
    _addTokens(node.beginToken, node.body.beginToken);
    bool hasConstConstructor = node.body.members2.any(
      (m) => m is ConstructorDeclaration2Impl && m.constKeyword != null,
    );
    _addClassMembers(node.body.members2, hasConstConstructor);
  }

  void _addClassMembers(List<AnnotatedNode> members, bool hasConstConstructor) {
    signature.addInt(members.length);
    for (var member in members) {
      if (member is ConstructorDeclaration2Impl) {
        _addConstructorDeclaration(member);
      } else if (member is FieldsDeclaration) {
        _addFieldsDeclaration(member, hasConstConstructor);
      } else if (member is MethodDeclarationV1OriginImpl) {
        _addMethodDeclaration(member);
      } else if (member is PrimaryConstructorBody) {
        _addPrimaryConstructorBody(member);
      } else {
        throw UnimplementedError('(${member.runtimeType}) $member');
      }
    }
  }

  void _addConstructorDeclaration(ConstructorDeclaration2Impl node) {
    signature.addInt(_kindConstructorDeclaration);
    _addTokens(node.beginToken, node.formalParameters.endToken);
    _addNodeList(node.initializers);
    _addNode(node.factoryRedirectionTarget);
    signature.addBool(node.isComplete);
  }

  void _addEnum(EnumDeclarationImpl node) {
    var members = node.body.members2;

    // If not enhanced, include the whole node.
    var firstMember = members.firstOrNull;
    if (firstMember == null) {
      _addNode(node);
      return;
    }

    _addTokens(node.beginToken, firstMember.beginToken);
    _addClassMembers(members, true);
  }

  void _addExtension(ExtensionDeclarationImpl node) {
    _addTokens(node.beginToken, node.body.beginToken);
    _addClassMembers(node.body.members2, false);
  }

  void _addFieldsDeclaration(FieldsDeclaration node, bool hasConstConstructor) {
    signature.addInt(_kindFieldsDeclaration);

    _addToken(node.abstractKeyword);
    _addToken(node.augmentKeyword);
    _addToken(node.covariantKeyword);
    _addToken(node.externalKeyword);
    _addToken(node.staticKeyword);
    _addNodeList(node.metadata);

    _addToken(node.constFinalOrVarKeyword);
    _addToken(node.lateKeyword);
    _addNode(node.type);

    var includeInitializers =
        node.type == null ||
        node.constKeyword != null ||
        hasConstConstructor &&
            node.staticKeyword == null &&
            node.finalKeyword != null;
    var fields = node.fields;
    signature.addInt(fields.length);

    for (var field in fields) {
      _addToken(field.name);
      signature.addBool(field.initializer != null);
      if (includeInitializers) {
        _addNode(field.initializer);
      }
    }
  }

  void _addFunctionBodyModifiers(FunctionBody? node) {
    if (node != null) {
      signature.addBool(node.isSynchronous);
      signature.addBool(node.isGenerator);
      signature.addBool(node is NativeFunctionBody);
    }
  }

  void _addMethodDeclaration(MethodDeclarationV1OriginImpl node) {
    signature.addInt(_kindMethodDeclaration);
    _addTokens(
      node.beginToken,
      node.writtenFormalParameters?.endToken ?? node.nameToken,
    );
    signature.addBool(node.isComplete);
    _addFunctionBodyModifiers(node.body);
    signature.addBool(node.invokesSuperSelf);
  }

  void _addMixin(MixinDeclarationImpl node) {
    _addTokens(node.beginToken, node.body.beginToken);
    _addClassMembers(node.body.members2, false);
    signature.addStringList(node.superInvokedNames);
  }

  void _addNode(AstNode? node) {
    if (node != null) {
      signature.addInt(_notNullNode);
      _addTokens(node.beginToken, node.endToken);
    } else {
      signature.addInt(_nullNode);
    }
  }

  void _addNodeList(List<AstNode> nodes) {
    for (var node in nodes) {
      _addNode(node);
    }
  }

  void _addPrimaryConstructorBody(PrimaryConstructorBody node) {
    signature.addInt(_kindPrimaryConstructorBody);
    _addTokens(node.beginToken, node.body.beginToken);
  }

  void _addToken(Token? token) {
    if (token != null) {
      signature.addInt(_notNullToken);
      signature.addString(token.lexeme);
    } else {
      signature.addInt(_nullToken);
    }
  }

  /// Appends tokens from [begin] (including), to [end] (also including).
  void _addTokens(Token begin, Token end) {
    if (begin is CommentToken) {
      begin = begin.parent!;
    }

    Token? token = begin;
    while (token != null) {
      _addToken(token);

      if (token == end) {
        break;
      }

      var nextToken = token.next;

      // Stop if EOF.
      if (nextToken == token) {
        break;
      }

      token = nextToken;
    }
  }

  void _topLevelVariablesDeclaration(TopLevelVariablesDeclaration node) {
    _addToken(node.abstractKeyword);
    _addToken(node.augmentKeyword);
    _addToken(node.externalKeyword);
    _addNodeList(node.metadata);

    _addToken(node.constFinalOrVarKeyword);
    _addToken(node.lateKeyword);
    _addNode(node.type);

    var includeInitializers = node.type == null || node.constKeyword != null;
    var variables = node.variables;
    signature.addInt(variables.length);

    for (var variable in variables) {
      _addToken(variable.name);
      signature.addBool(variable.initializer != null);
      if (includeInitializers) {
        _addNode(variable.initializer);
      }
    }
  }
}

extension on MixinDeclaration {
  List<String> get superInvokedNames {
    var names = <String>{};
    var collector = MixinSuperInvokedNamesCollector(names);
    accept2(collector);
    return names.toList(growable: false);
  }
}
