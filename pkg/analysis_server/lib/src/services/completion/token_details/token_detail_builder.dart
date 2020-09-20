// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/protocol/protocol_generated.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';

/// An object used to build the details for each token in the code being
/// analyzed.
class TokenDetailBuilder {
  /// The list of details that were built.
  List<TokenDetails> details = [];

  /// Initialize a newly created builder.
  TokenDetailBuilder();

  /// Visit a [node] in the AST structure to build details for all of the tokens
  /// contained by that node.
  void visitNode(AstNode node) {
    for (var entity in node.childEntities) {
      if (entity is Token) {
        _createDetails(entity, null, null);
      } else if (entity is SimpleIdentifier) {
        String type;
        var typeNameNode = _getTypeName(entity);
        if (typeNameNode != null) {
          var typeStr = _typeStr(typeNameNode.type);
          type = 'dart:core;Type<$typeStr>';
        } else if (entity.staticElement is ClassElement) {
          type = 'Type';
        } else if (entity.inDeclarationContext()) {
          var element = entity.staticElement;
          if (element is FunctionElement) {
            type = _typeStr(element.type);
          } else if (element is MethodElement) {
            type = _typeStr(element.type);
          } else if (element is VariableElement) {
            type = _typeStr(element.type);
          }
        } else {
          type = _typeStr(entity.staticType);
        }
        var kinds = <String>[];
        if (entity.inDeclarationContext()) {
          kinds.add('declaration');
        } else {
          kinds.add('reference');
        }
        _createDetails(entity.token, type, kinds);
      } else if (entity is BooleanLiteral) {
        _createDetails(entity.literal, _typeStr(entity.staticType), null);
      } else if (entity is DoubleLiteral) {
        _createDetails(entity.literal, _typeStr(entity.staticType), null);
      } else if (entity is IntegerLiteral) {
        _createDetails(entity.literal, _typeStr(entity.staticType), null);
      } else if (entity is SimpleStringLiteral) {
        _createDetails(entity.literal, _typeStr(entity.staticType), null);
      } else if (entity is Comment) {
        // Ignore comments and the references within them.
      } else if (entity is AstNode) {
        visitNode(entity);
      }
    }
  }

  /// Create the details for a single [token], using the given list of [kinds].
  void _createDetails(Token token, String type, List<String> kinds) {
    details.add(TokenDetails(token.lexeme, token.offset,
        type: type, validElementKinds: kinds));
  }

  /// Return the [TypeName] with the [identifier].
  TypeName _getTypeName(SimpleIdentifier identifier) {
    var parent = identifier.parent;
    if (parent is TypeName && identifier == parent.name) {
      return parent;
    } else if (parent is PrefixedIdentifier &&
        parent.identifier == identifier) {
      var parent2 = parent.parent;
      if (parent2 is TypeName && parent == parent2.name) {
        return parent2;
      }
    }
    return null;
  }

  /// Return a unique identifier for the [type].
  String _typeStr(DartType type) {
    var buffer = StringBuffer();
    _writeType(buffer, type);
    return buffer.toString();
  }

  /// Return a unique identifier for the type of the given [expression].
  void _writeType(StringBuffer buffer, DartType type) {
    if (type == null) {
      // This should never happen if the AST has been resolved.
      buffer.write('dynamic');
    } else if (type is FunctionType) {
      _writeType(buffer, type.returnType);
      buffer.write(' Function(');
      var first = true;
      for (var parameter in type.parameters) {
        if (first) {
          first = false;
        } else {
          buffer.write(', ');
        }
        _writeType(buffer, parameter.type);
      }
      buffer.write(')');
    } else if (type is InterfaceType) {
      Element element = type.element;
      if (element == null || element.isSynthetic) {
        assert(false, 'untested branch may print nullable types wrong');
        // TODO: test this, use the the library's nullability (not tracked yet).
        buffer.write(type.getDisplayString(withNullability: false));
      } else {
//        String uri = element.library.source.uri.toString();
        var name = element.name;
        if (element is ClassMemberElement) {
          var className = element.enclosingElement.name;
          // TODO(brianwilkerson) Figure out why the uri is a file: URI when it
          //  ought to be a package: URI and restore the code below to include
          //  the URI in the string.
//          buffer.write('$uri;$className;$name');
          buffer.write('$className;$name');
        } else {
//          buffer.write('$uri;$name');
          buffer.write('$name');
        }
      }
    } else {
      // Handle `void` and `dynamic`. Nullability doesn't affect this.
      assert(type.getDisplayString(withNullability: false) ==
          type.getDisplayString(withNullability: true));
      buffer.write(type.getDisplayString(withNullability: false));
    }
  }
}
