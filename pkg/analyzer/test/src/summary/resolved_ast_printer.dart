// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/member.dart';
import 'package:analyzer/src/summary2/reference.dart';
import 'package:meta/meta.dart';

/// Prints AST as a tree, with properties and children.
class ResolvedAstPrinter extends ThrowingAstVisitor<void> {
  final String _selfUriStr;
  final StringSink _sink;
  String _indent = '';

  ResolvedAstPrinter({
    @required String selfUriStr,
    @required StringSink sink,
    @required String indent,
  })  : _selfUriStr = selfUriStr,
        _sink = sink,
        _indent = indent;

  @override
  void visitAnnotation(Annotation node) {
    _writeln('Annotation');
    _withIndent(() {
      _writeNode('arguments', node.arguments);
      _writeNode('constructorName', node.constructorName);
      _writeElement('element', node.element);
      _writeNode('name', node.name);
    });
  }

  @override
  void visitArgumentList(ArgumentList node) {
    _writeln('ArgumentList');
    _withIndent(() {
      _writeNodeList('arguments', node.arguments);
    });
  }

  @override
  void visitCompilationUnit(CompilationUnit node) {
    super.visitCompilationUnit(node);
  }

  @override
  void visitConstructorName(ConstructorName node) {
    _writeln('ConstructorName');
    _withIndent(() {
      _writeNode('name', node.name);
      _writeNode('type', node.type);
    });
  }

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    _writeln('InstanceCreationExpression');
    _withIndent(() {
      _writeNode('argumentList', node.argumentList);
      _writeNode('constructorName', node.constructorName);
      _writeElement('staticElement', node.staticElement);
      _writeType('staticType', node.staticType);
    });
  }

  @override
  void visitIntegerLiteral(IntegerLiteral node) {
    _writeln('IntegerLiteral');
    _withIndent(() {
      _writelnWithIndent('literal: ${node.literal}');
      _writeType('staticType', node.staticType);
    });
  }

  @override
  void visitListLiteral(ListLiteral node) {
    _writeln('ListLiteral');
    _withIndent(() {
      _writeNodeList('elements', node.elements);
      _writeType('staticType', node.staticType);
      _writeNode('typeArguments', node.typeArguments);
    });
  }

  @override
  void visitRedirectingConstructorInvocation(
    RedirectingConstructorInvocation node,
  ) {
    _writeln('RedirectingConstructorInvocation');
    _withIndent(() {
      _writeNode('argumentList', node.argumentList);
      _writeNode('constructorName', node.constructorName);
      _writeElement('staticElement', node.staticElement);
    });
  }

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    _writeln('SimpleIdentifier');
    _withIndent(() {
      _writeAuxiliaryElements('auxiliaryElements', node.auxiliaryElements);
      _writeElement('staticElement', node.staticElement);
      _writeType('staticType', node.staticType);
      _writelnWithIndent('token: ${node.token}');
    });
  }

  @override
  void visitSuperConstructorInvocation(SuperConstructorInvocation node) {
    _writeln('SuperConstructorInvocation');
    _withIndent(() {
      _writeNode('argumentList', node.argumentList);
      _writeNode('constructorName', node.constructorName);
      _writeElement('staticElement', node.staticElement);
    });
  }

  @override
  void visitTypeName(TypeName node) {
    _writeln('TypeName');
    _withIndent(() {
      _writeNode('name', node.name);
      _writeType('type', node.type);
      _writeNode('typeArguments', node.typeArguments);
    });
  }

  String _referenceToString(Reference reference) {
    if (reference.parent.name == '@unit') {
      var libraryUriStr = reference.parent.parent.name;
      if (libraryUriStr == _selfUriStr) {
        return 'self';
      }
      return libraryUriStr;
    }

    var name = reference.name;
    if (name.startsWith('@')) {
      return _referenceToString(reference.parent);
    }
    if (name.isEmpty) {
      name = '•';
    }
    return _referenceToString(reference.parent) + '::$name';
  }

  void _withIndent(void Function() f) {
    var indent = _indent;
    _indent = '$_indent  ';
    f();
    _indent = indent;
  }

  void _writeAuxiliaryElements(String name, AuxiliaryElements elements) {
    if (elements != null) {
      throw UnimplementedError();
    }
  }

  void _writeElement(String name, Element element) {
    _sink.write(_indent);
    _sink.write('$name: ');
    if (element == null) {
      _sink.writeln('<null>');
    } else if (element is Member) {
      _sink.writeln(_nameOfMemberClass(element));
      _withIndent(() {
        _writeElement('base', element.baseElement);
        _writelnWithIndent('substitution: ${element.substitution.map}');
      });
    } else {
      var reference = (element as ElementImpl).reference;
      var referenceStr = _referenceToString(reference);
      _sink.writeln(referenceStr);
    }
  }

  void _writeln(String line) {
    _sink.writeln(line);
  }

  void _writelnWithIndent(String line) {
    _sink.write(_indent);
    _sink.writeln(line);
  }

  void _writeNode(String name, AstNode node) {
    if (node != null) {
      _sink.write(_indent);
      _sink.write('$name: ');
      node.accept(this);
    }
  }

  void _writeNodeList(String name, NodeList nodeList) {
    if (nodeList.isNotEmpty) {
      _writelnWithIndent(name);
      _withIndent(() {
        for (var node in nodeList) {
          _sink.write(_indent);
          node.accept(this);
        }
      });
    }
  }

  void _writeType(String name, DartType type) {
    _writelnWithIndent('$name: $type');
  }

  static String _nameOfMemberClass(Member member) {
    return '${member.runtimeType}';
  }
}
