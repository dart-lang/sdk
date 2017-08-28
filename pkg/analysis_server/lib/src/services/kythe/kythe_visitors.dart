// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/standard_resolution_map.dart';
import 'package:analyzer/dart/ast/syntactic_entity.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/dart/element/visitor.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/dart/resolver/inheritance_manager.dart';
import 'package:analyzer/src/generated/bazel.dart';
import 'package:analyzer/src/generated/gn.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart'
    show KytheEntry, KytheVName;

import 'schema.dart' as schema;

const int _notFound = -1;

/// Given some [ConstructorElement], this method returns '<class-name>' as the
/// name of the constructor, unless the constructor is a named constructor in
/// which '<class-name>.<constructor-name>' is returned.
String _computeConstructorElementName(ConstructorElement element) {
  assert(element != null);
  var name = element.enclosingElement.name;
  var constructorName = element.name;
  if (!constructorName.isEmpty) {
    name = name + '.' + constructorName;
  }
  return name;
}

/// Create an anchor signature of the form '<start>-<end>'.
String _getAnchorSignature(int start, int end) {
  return '$start-$end';
}

String _getPath(ResourceProvider provider, Element e) {
  // TODO(jwren) This method simply serves to provide the WORKSPACE relative
  // path for sources in Elements, it needs to be written in a more robust way.
  // TODO(jwren) figure out what source generates a e != null, but
  // e.source == null to ensure that it is not a bug somewhere in the stack.
  if (e == null || e.source == null) {
    // null sometimes when the element is used to generate the node type
    // "dynamic"
    return '';
  }
  String path = e.source.fullName;
  BazelWorkspace bazelWorkspace = BazelWorkspace.find(provider, path);
  if (bazelWorkspace != null) {
    return provider.pathContext.relative(path, from: bazelWorkspace.root);
  }
  GnWorkspace gnWorkspace = GnWorkspace.find(provider, path);
  if (gnWorkspace != null) {
    return provider.pathContext.relative(path, from: gnWorkspace.root);
  }
  if (path.lastIndexOf('CORPUS_NAME') != -1) {
    return path.substring(path.lastIndexOf('CORPUS_NAME') + 12);
  }
  return path;
}

/// If a non-null element is passed, the [SignatureElementVisitor] is used to
/// generate and return a [String] signature, otherwise [schema.DYNAMIC_KIND] is
/// returned.
String _getSignature(ResourceProvider provider, Element element,
    String nodeKind, String corpus) {
  assert(nodeKind != schema.ANCHOR_KIND); // Call _getAnchorSignature instead
  if (element == null) {
    return schema.DYNAMIC_KIND;
  }
  if (element is CompilationUnitElement) {
    return _getPath(provider, element);
  }
  return '$nodeKind:${element.accept(SignatureElementVisitor.instance)}';
}

class CodedBufferWriter {
  CodedBufferWriter(var v);
  toBuffer() {}
}

/// This visitor writes out Kythe facts and edges as specified by the Kythe
/// Schema here https://kythe.io/docs/schema/.  This visitor handles all nodes,
/// facts and edges.
class KytheDartVisitor extends GeneralizingAstVisitor with OutputUtils {
  final ResourceProvider resourceProvider;
  final List<KytheEntry> entries;
  final String corpus;
  final InheritanceManager _inheritanceManager;
  final String _contents;

  String _enclosingFilePath = '';
  Element _enclosingElement;
  ClassElement _enclosingClassElement;
  KytheVName _enclosingVName;
  KytheVName _enclosingFileVName;
  KytheVName _enclosingClassVName;

  KytheDartVisitor(this.resourceProvider, this.entries, this.corpus,
      this._inheritanceManager, this._contents);

  @override
  String get enclosingFilePath => _enclosingFilePath;

  @override
  visitAnnotation(Annotation node) {
    // TODO(jwren) To get the full set of cross refs correct, additional ref
    // edges are needed, example: from "A" in "A.namedConstructor()"

    var start = node.name.offset;
    var end = node.name.end;
    if (node.constructorName != null) {
      end = node.constructorName.end;
    }
    var refVName = _handleRefEdge(
      node.element,
      const <String>[schema.REF_EDGE],
      start: start,
      end: end,
    );
    if (refVName != null) {
      var parentNode = node.parent;
      if (parentNode is Declaration) {
        Element parentElement = parentNode.element;
        if (parentNode is TopLevelVariableDeclaration) {
          _handleVariableDeclarationListAnnotations(
              parentNode.variables, refVName);
        } else if (parentNode is FieldDeclaration) {
          _handleVariableDeclarationListAnnotations(
              parentNode.fields, refVName);
        } else if (parentElement != null) {
          var parentVName =
              _vNameFromElement(parentElement, _getNodeKind(parentElement));
          addEdge(parentVName, schema.ANNOTATED_BY_EDGE, refVName);
        } else {
          // parentAstNode is not a variable declaration node and
          // parentElement == null
          assert(false);
        }
      } else {
        // parentAstNode is not a Declaration
        // TODO(jwren) investigate
//      throw new Exception('parentAstNode.runtimeType = ${parentAstNode.runtimeType}');
//        assert(false);
      }
    }

    // visit children
    _safelyVisit(node.arguments);
  }

  @override
  visitAssignmentExpression(AssignmentExpression node) {
    //
    // operator
    // NOTE: usage node only written out if assignment is not the '=' operator,
    // we are looking for an operator such as +=, -=, *=, /=
    //
    Token operator = node.operator;
    MethodElement element = node.bestElement;
    if (operator.type != TokenType.EQ && element != null) {
      // method
      _vNameFromElement(element, schema.FUNCTION_KIND);

      // anchor- ref/call
      _handleRefCallEdge(element,
          syntacticEntity: node.operator, enclosingTarget: _enclosingVName);

      // TODO (jwren) Add function type information
    }
    // visit children
    _safelyVisit(node.leftHandSide);
    _safelyVisit(node.rightHandSide);
  }

  @override
  visitBinaryExpression(BinaryExpression node) {
    //
    // operators such as +, -, *, /
    //
    MethodElement element = node.bestElement;
    if (element != null) {
      // method
      _vNameFromElement(element, schema.FUNCTION_KIND);

      // anchor- ref/call
      _handleRefCallEdge(element,
          syntacticEntity: node.operator, enclosingTarget: _enclosingVName);

      // TODO (jwren) Add function type information
    }
    // visit children
    _safelyVisit(node.leftOperand);
    _safelyVisit(node.rightOperand);
  }

  @override
  visitClassDeclaration(ClassDeclaration node) {
    return _withEnclosingElement(node.element, () {
      // record/ class node
      addNodeAndFacts(schema.RECORD_KIND,
          nodeVName: _enclosingClassVName,
          subKind: schema.CLASS_SUBKIND,
          completeFact: schema.DEFINITION);

      // anchor- defines/binding
      addAnchorEdgesContainingEdge(
          syntacticEntity: node.name,
          edges: [
            schema.DEFINES_BINDING_EDGE,
          ],
          target: _enclosingClassVName,
          enclosingTarget: _enclosingFileVName);

      // anchor- defines
      addAnchorEdgesContainingEdge(
          syntacticEntity: node,
          edges: [
            schema.DEFINES_EDGE,
          ],
          target: _enclosingClassVName);

      // extends
      var supertype = _enclosingClassElement.supertype;
      if (supertype?.element != null) {
        var recordSupertypeVName =
            _vNameFromElement(supertype.element, schema.RECORD_KIND);
        addEdge(
            _enclosingClassVName, schema.EXTENDS_EDGE, recordSupertypeVName);
      }

      // implements
      var interfaces = _enclosingClassElement.interfaces;
      for (var interface in interfaces) {
        if (interface.element != null) {
          var recordInterfaceVName =
              _vNameFromElement(interface.element, schema.RECORD_KIND);
          addEdge(
              _enclosingClassVName, schema.EXTENDS_EDGE, recordInterfaceVName);
        }
      }

      // mixins
      var mixins = _enclosingClassElement.mixins;
      for (var mixin in mixins) {
        if (mixin.element != null) {
          var recordMixinVName =
              _vNameFromElement(mixin.element, schema.RECORD_KIND);
          addEdge(_enclosingClassVName, schema.EXTENDS_EDGE, recordMixinVName);
        }
      }

      // TODO (jwren) type parameters

      // visit children
      _safelyVisit(node.documentationComment);
      _safelyVisitList(node.metadata);
      _safelyVisit(node.extendsClause);
      _safelyVisit(node.implementsClause);
      _safelyVisit(node.withClause);
      _safelyVisit(node.nativeClause);
      _safelyVisitList(node.members);
      _safelyVisit(node.typeParameters);
    });
  }

  @override
  visitClassTypeAlias(ClassTypeAlias node) {
    return _withEnclosingElement(node.element, () {
      // record/ class node
      addNodeAndFacts(schema.RECORD_KIND,
          nodeVName: _enclosingClassVName,
          subKind: schema.CLASS_SUBKIND,
          completeFact: schema.DEFINITION);

      // anchor
      addAnchorEdgesContainingEdge(
          syntacticEntity: node.name,
          edges: [
            schema.DEFINES_BINDING_EDGE,
          ],
          target: _enclosingClassVName,
          enclosingTarget: _enclosingFileVName);

      //
      // superclass
      // The super type is not in an ExtendsClause (as is the case with
      // ClassDeclarations) and super.visitClassTypeAlias is not sufficient.
      //
      _handleRefEdge(
        node.superclass.name.bestElement,
        const <String>[schema.REF_EDGE],
        syntacticEntity: node.superclass,
      );
      // TODO(jwren) refactor the following lines into a method that can be used
      // by visitClassDeclaration()
      // extends
      var recordSupertypeVName = _vNameFromElement(
          node.superclass.name.bestElement, schema.RECORD_KIND);
      addEdge(_enclosingClassVName, schema.EXTENDS_EDGE, recordSupertypeVName);

      // implements
      var interfaces = _enclosingClassElement.interfaces;
      for (var interface in interfaces) {
        if (interface.element != null) {
          var recordInterfaceVName =
              _vNameFromElement(interface.element, schema.RECORD_KIND);
          addEdge(
              _enclosingClassVName, schema.EXTENDS_EDGE, recordInterfaceVName);
        }
      }

      // mixins
      var mixins = _enclosingClassElement.mixins;
      for (var mixin in mixins) {
        if (mixin.element != null) {
          var recordMixinVName =
              _vNameFromElement(mixin.element, schema.RECORD_KIND);
          addEdge(_enclosingClassVName, schema.EXTENDS_EDGE, recordMixinVName);
        }
      }

      // visit children
      _safelyVisit(node.documentationComment);
      _safelyVisitList(node.metadata);
      _safelyVisit(node.typeParameters);
      _safelyVisit(node.withClause);
      _safelyVisit(node.implementsClause);
    });
  }

  @override
  visitCompilationUnit(CompilationUnit node) {
    _enclosingFilePath = _getPath(resourceProvider, node.element);
    return _withEnclosingElement(node.element, () {
      addFact(_enclosingFileVName, schema.NODE_KIND_FACT,
          _encode(schema.FILE_KIND));
      addFact(_enclosingFileVName, schema.TEXT_FACT, _encode(_contents));
      addFact(_enclosingFileVName, schema.TEXT_ENCODING_FACT,
          _encode(schema.DEFAULT_TEXT_ENCODING));

      // handle LibraryDirective:

      // A "package" VName in Kythe, schema.PACKAGE_KIND, is a Dart "library".

      // Don't use visitLibraryDirective as this won't generate a package
      // VName for libraries that don't have a library directive.
      var libraryElement =
          resolutionMap.elementDeclaredByCompilationUnit(node).library;
      if (libraryElement.definingCompilationUnit == node.element) {
        LibraryDirective libraryDirective;
        for (var directive in node.directives) {
          if (directive is LibraryDirective) {
            libraryDirective = directive;
            break;
          }
        }

        var start = 0;
        var end = 0;
        if (libraryDirective != null) {
          start = libraryDirective.name.offset;
          end = libraryDirective.name.end;
        }

        // package node
        var packageVName = addNodeAndFacts(schema.PACKAGE_KIND,
            element: libraryElement, completeFact: schema.DEFINITION);

        // anchor
        addAnchorEdgesContainingEdge(
            start: start,
            end: end,
            edges: [
              schema.DEFINES_BINDING_EDGE,
            ],
            target: packageVName,
            enclosingTarget: _enclosingFileVName);
      }

      super.visitCompilationUnit(node);
    });
  }

  @override
  visitConstructorDeclaration(ConstructorDeclaration node) {
    return _withEnclosingElement(node.element, () {
      // function/ constructor node
      var constructorVName = addNodeAndFacts(schema.FUNCTION_KIND,
          element: node.element,
          subKind: schema.CONSTRUCTOR_SUBKIND,
          completeFact: schema.DEFINITION);

      // anchor
      var start = node.returnType.offset;
      var end = node.returnType.end;
      if (node.name != null) {
        end = node.name.end;
      }
      addAnchorEdgesContainingEdge(
          start: start,
          end: end,
          edges: [
            schema.DEFINES_BINDING_EDGE,
          ],
          target: constructorVName,
          enclosingTarget: _enclosingClassVName);

      // function type
      addFunctionType(node.element, node.parameters, constructorVName,
          returnNode: node.returnType);

      // TODO(jwren) handle implicit constructor case
      // TODO(jwren) handle redirected constructor case

      // visit children
      _safelyVisit(node.documentationComment);
      _safelyVisitList(node.metadata);
      _safelyVisit(node.parameters);
      _safelyVisitList(node.initializers);
      _safelyVisit(node.body);
    });
  }

  @override
  visitDeclaredIdentifier(DeclaredIdentifier node) {
    // variable
    var variableVName = addNodeAndFacts(schema.VARIABLE_KIND,
        element: node.element,
        subKind: schema.LOCAL_SUBKIND,
        completeFact: schema.DEFINITION);

    // anchor
    addAnchorEdgesContainingEdge(
        syntacticEntity: node.identifier,
        edges: [
          schema.DEFINES_BINDING_EDGE,
        ],
        target: variableVName,
        enclosingTarget: _enclosingVName);

    // type
    addEdge(
        variableVName,
        schema.TYPED_EDGE,
        _vNameFromType(
            resolutionMap.elementDeclaredByDeclaredIdentifier(node).type));

    // no children
  }

  @override
  visitEnumConstantDeclaration(EnumConstantDeclaration node) {
    // constant node
    var constDeclVName =
        addNodeAndFacts(schema.CONSTANT_KIND, element: node.element);

    // anchor- defines/binding, defines
    addAnchorEdgesContainingEdge(
        syntacticEntity: node.name,
        edges: [
          schema.DEFINES_BINDING_EDGE,
          schema.DEFINES_EDGE,
        ],
        target: constDeclVName,
        enclosingTarget: _enclosingClassVName);

    // no children
  }

  @override
  visitEnumDeclaration(EnumDeclaration node) {
    return _withEnclosingElement(node.element, () {
      // record/ enum node
      addNodeAndFacts(schema.RECORD_KIND,
          nodeVName: _enclosingClassVName,
          subKind: schema.ENUM_CLASS_SUBKIND,
          completeFact: schema.DEFINITION);

      // anchor- defines/binding
      addAnchorEdgesContainingEdge(
          syntacticEntity: node.name,
          edges: [
            schema.DEFINES_BINDING_EDGE,
          ],
          target: _enclosingClassVName,
          enclosingTarget: _enclosingFileVName);

      // anchor- defines
      addAnchorEdgesContainingEdge(
          syntacticEntity: node,
          edges: [
            schema.DEFINES_EDGE,
          ],
          target: _enclosingClassVName);

      // visit children
      _safelyVisitList(node.constants);
    });
  }

  @override
  visitFieldFormalParameter(FieldFormalParameter node) {
    // identifier
    // Specified as Element, not var, so that the type can be changed in the
    // if-block.
    Element element = node.element;
    if (element is FieldFormalParameterElement) {
      element = (element as FieldFormalParameterElement).field;
    }
    _handleRefEdge(
      element,
      const <String>[schema.REF_EDGE],
      syntacticEntity: node.identifier,
    );

    // visit children
    _safelyVisit(node.documentationComment);
    _safelyVisitList(node.metadata);
    _safelyVisit(node.type);
    _safelyVisit(node.typeParameters);
    _safelyVisit(node.parameters);
  }

  @override
  visitFunctionDeclaration(FunctionDeclaration node) {
    return _withEnclosingElement(node.element, () {
      // function node
      var functionVName = addNodeAndFacts(schema.FUNCTION_KIND,
          element: node.element, completeFact: schema.DEFINITION);

      // anchor- defines/binding
      addAnchorEdgesContainingEdge(
          syntacticEntity: node.name,
          edges: [
            schema.DEFINES_BINDING_EDGE,
          ],
          target: functionVName,
          enclosingTarget: _enclosingFileVName);

      // anchor- defines
      addAnchorEdgesContainingEdge(
          syntacticEntity: node,
          edges: [
            schema.DEFINES_EDGE,
          ],
          target: functionVName);

      // function type
      addFunctionType(
          node.element, node.functionExpression.parameters, functionVName,
          returnNode: node.returnType);

      _safelyVisit(node.documentationComment);
      _safelyVisitList(node.metadata);
      _safelyVisit(node.returnType);
      _safelyVisit(node.functionExpression);
    });
  }

  @override
  visitFunctionExpression(FunctionExpression node) {
    return _withEnclosingElement(
        node.element, () => super.visitFunctionExpression(node));
  }

  @override
  visitFunctionTypeAlias(FunctionTypeAlias node) {
    //
    // return type
    //
    var returnType = node.returnType;
    if (returnType is TypeName) {
      _handleRefEdge(
        returnType.name?.bestElement,
        const <String>[schema.REF_EDGE],
        syntacticEntity: returnType.name,
      );
    } else if (returnType is GenericFunctionType) {
      // TODO(jwren): add support for generic function types.
      throw new UnimplementedError();
    } else if (returnType != null) {
      throw new StateError(
          'Unexpected TypeAnnotation subtype: ${returnType.runtimeType}');
    }

    // visit children
    _safelyVisit(node.documentationComment);
    _safelyVisitList(node.metadata);
    _safelyVisit(node.typeParameters);
    _safelyVisit(node.parameters);
  }

  @override
  visitFunctionTypedFormalParameter(FunctionTypedFormalParameter node) {
    // TODO(jwren) Missing graph coverage on FunctionTypedFormalParameters
    // visit children
    _safelyVisit(node.documentationComment);
    _safelyVisitList(node.metadata);
    _safelyVisit(node.identifier);
    _safelyVisit(node.typeParameters);
    _safelyVisit(node.parameters);
  }

  @override
  visitImportDirective(ImportDirective node) {
    // uri
    _handleUriReference(node.uri, node.uriElement);

    // prefix
    var prefixIdentifier = node.prefix;

    if (prefixIdentifier != null) {
      // variable
      var variableVName = addNodeAndFacts(schema.VARIABLE_KIND,
          element: prefixIdentifier.staticElement,
          completeFact: schema.DEFINITION);

      // anchor
      addAnchorEdgesContainingEdge(
          syntacticEntity: prefixIdentifier,
          edges: [schema.DEFINES_BINDING_EDGE],
          target: variableVName,
          enclosingTarget: _enclosingVName);
    }

    // visit children
    _safelyVisit(node.documentationComment);
    _safelyVisitList(node.metadata);
    _safelyVisitList(node.combinators);
    _safelyVisitList(node.configurations);
    _safelyVisit(node.uri);
  }

  @override
  visitIndexExpression(IndexExpression node) {
    //
    // index method ref/call
    //
    var element = node.bestElement;
    var start = node.leftBracket.offset;
    var end = node.rightBracket.end;

    // anchor- ref/call
    _handleRefCallEdge(element,
        start: start, end: end, enclosingTarget: _enclosingVName);

    // visit children
    _safelyVisit(node.target);
    _safelyVisit(node.index);
  }

  @override
  visitInstanceCreationExpression(InstanceCreationExpression node) {
    //
    // constructorName
    //
    var constructorName = node.constructorName;
    var constructorElement =
        resolutionMap.staticElementForConstructorReference(constructorName);
    if (constructorElement != null) {
      // anchor- ref/call
      _handleRefCallEdge(constructorElement,
          syntacticEntity: constructorName, enclosingTarget: _enclosingVName);

      // Now write out a ref edge from the same anchor (constructorName) to the
      // enclosing class of the called constructor, this will make the
      // invocation of a constructor discoverable when someone inquires about
      // references to the class.
      //
      // We can't call _handleRefEdge as the anchor node has already been
      // written out.
      var enclosingEltVName = _vNameFromElement(
          constructorElement.enclosingElement, schema.RECORD_KIND);
      var anchorVName =
          _vNameAnchor(constructorName.offset, constructorName.end);
      addEdge(anchorVName, schema.REF_EDGE, enclosingEltVName);

      // TODO(jwren): investigate
      //   assert (element.enclosingElement != null);
    }
    // visit children
    _safelyVisitList(constructorName.type.typeArguments?.arguments);
    _safelyVisit(node.argumentList);
  }

  @override
  visitMethodDeclaration(MethodDeclaration node) {
    return _withEnclosingElement(node.element, () {
      // function node
      var methodVName = addNodeAndFacts(schema.FUNCTION_KIND,
          element: node.element, completeFact: schema.DEFINITION);

      // anchor- defines/binding
      addAnchorEdgesContainingEdge(
          syntacticEntity: node.name,
          edges: [
            schema.DEFINES_BINDING_EDGE,
          ],
          target: methodVName,
          enclosingTarget: _enclosingClassVName);

      // anchor- defines
      addAnchorEdgesContainingEdge(
          syntacticEntity: node,
          edges: [
            schema.DEFINES_EDGE,
          ],
          target: methodVName);

      // function type
      addFunctionType(node.element, node.parameters, methodVName,
          returnNode: node.returnType);

      // override edges
      List<ExecutableElement> overriddenList =
          _inheritanceManager.lookupOverrides(_enclosingClassElement,
              resolutionMap.elementDeclaredByMethodDeclaration(node).name);
      for (ExecutableElement overridden in overriddenList) {
        if (overridden is MultiplyInheritedExecutableElement) {
          for (ExecutableElement elt in overridden.inheritedElements) {
            addEdge(methodVName, schema.OVERRIDES_EDGE,
                _vNameFromElement(elt, schema.FUNCTION_KIND));
          }
        } else {
          addEdge(methodVName, schema.OVERRIDES_EDGE,
              _vNameFromElement(overridden, schema.FUNCTION_KIND));
        }
      }

      // visit children
      _safelyVisit(node.documentationComment);
      _safelyVisitList(node.metadata);
      _safelyVisit(node.returnType);
      _safelyVisit(node.typeParameters);
      _safelyVisit(node.parameters);
      _safelyVisit(node.body);
    });
  }

  @override
  visitMethodInvocation(MethodInvocation node) {
    var element = node.methodName?.bestElement;

    // anchor- ref/call
    _handleRefCallEdge(element, syntacticEntity: node.methodName);

    // visit children
    _safelyVisit(node.target);
    _safelyVisit(node.typeArguments);
    _safelyVisit(node.argumentList);
  }

  @override
  visitSimpleFormalParameter(SimpleFormalParameter node) {
    // parameter node
    var paramVName = addNodeAndFacts(schema.VARIABLE_KIND,
        element: node.element,
        subKind: schema.LOCAL_PARAMETER_SUBKIND,
        completeFact: schema.DEFINITION);

    // The anchor and anchor edges generation are broken into two cases, the
    // first case is "method(parameter_name) ...", where the the parameter
    // character range only includes a parameter name.  The second case is for
    // parameter declarations which are prefixed with a type, 'var', or
    // 'dynamic', as in "method(var parameter_name) ...".
    //
    // With the first case a single anchor range is created, for the second
    // case an anchor is created on parameter_name, as well as the range
    // including any prefixes.
    if (node.offset == node.identifier.offset &&
        node.length == node.identifier.length) {
      // anchor- defines/binding, defines
      addAnchorEdgesContainingEdge(
          syntacticEntity: node.identifier,
          edges: [
            schema.DEFINES_BINDING_EDGE,
            schema.DEFINES_EDGE,
          ],
          target: paramVName,
          enclosingTarget: _enclosingVName);
    } else {
      // anchor- defines/binding
      addAnchorEdgesContainingEdge(
          syntacticEntity: node.identifier,
          edges: [
            schema.DEFINES_BINDING_EDGE,
          ],
          target: paramVName,
          enclosingTarget: _enclosingVName);

      // anchor- defines
      addAnchorEdgesContainingEdge(
          syntacticEntity: node,
          edges: [
            schema.DEFINES_EDGE,
          ],
          target: paramVName);
    }

    // type
    addEdge(
        paramVName,
        schema.TYPED_EDGE,
        _vNameFromType(
            resolutionMap.elementDeclaredByFormalParameter(node).type));

    // visit children
    _safelyVisit(node.documentationComment);
    _safelyVisitList(node.metadata);
    _safelyVisit(node.type);
  }

  @override
  visitSimpleIdentifier(SimpleIdentifier node) {
    // Most simple identifiers are "ref" edges.  In cases some cases, there may
    // be other ref/* edges.

    if (node.getAncestor((node) => node is CommentReference) != null) {
      // The identifier is in a comment, add just the "ref" edge.
      _handleRefEdge(
        node.bestElement,
        const <String>[schema.REF_EDGE],
        syntacticEntity: node,
      );
    } else if (node.inDeclarationContext()) {
      // The node is in a declaration context, and should have
      // "ref/defines/binding" edge as well as the default "ref" edge.
      _handleRefEdge(
        node.bestElement,
        const <String>[schema.DEFINES_BINDING_EDGE, schema.REF_EDGE],
        syntacticEntity: node,
      );
    } else {
      _handleRefCallEdge(node.bestElement, syntacticEntity: node);
    }

    // no children to visit
  }

  @override
  visitSuperExpression(SuperExpression node) {
    _handleThisOrSuper(node);
  }

  @override
  visitThisExpression(ThisExpression node) {
    _handleThisOrSuper(node);
  }

  @override
  visitUriBasedDirective(UriBasedDirective node) {
    _handleUriReference(node.uri, node.uriElement);

    // visit children
    super.visitUriBasedDirective(node);
  }

  @override
  visitVariableDeclaration(VariableDeclaration node) {
    // level variable
    var isLocal = _enclosingVName != _enclosingClassVName &&
        _enclosingVName != _enclosingFileVName;

    // variable
    var variableVName = addNodeAndFacts(schema.VARIABLE_KIND,
        element: node.element,
        subKind: isLocal ? schema.LOCAL_SUBKIND : schema.FIELD_SUBKIND,
        completeFact: schema.DEFINITION);

    // anchor
    addAnchorEdgesContainingEdge(
        syntacticEntity: node.name,
        edges: [
          schema.DEFINES_BINDING_EDGE,
        ],
        target: variableVName,
        enclosingTarget: _enclosingVName);

    // type
    addEdge(
        variableVName,
        schema.TYPED_EDGE,
        _vNameFromType(
            resolutionMap.elementDeclaredByVariableDeclaration(node).type));

    // visit children
    _safelyVisit(node.initializer);
  }

  Element _findNonSyntheticElement(Element element) {
    if (element == null || !element.isSynthetic) {
      return element;
    }
    if (element is PropertyAccessorElement) {
      if (!element.variable.isSynthetic) {
        return element.variable;
      } else if (element.correspondingGetter != null &&
          !element.correspondingGetter.isSynthetic) {
        return element.correspondingGetter;
      } else if (element.correspondingSetter != null &&
          !element.correspondingSetter.isSynthetic) {
        return element.correspondingSetter;
      }
    }
    return null;
  }

  String _getNodeKind(Element e) {
    if (e is FieldElement && e.isEnumConstant) {
      // FieldElement is a kind of VariableElement, so this test case must be
      // before the e is VariableElement check.
      return schema.CONSTANT_KIND;
    } else if (e is VariableElement || e is PrefixElement) {
      return schema.VARIABLE_KIND;
    } else if (e is ExecutableElement) {
      return schema.FUNCTION_KIND;
    } else if (e is ClassElement || e is TypeParameterElement) {
      // TODO(jwren): this should be using absvar instead, see
      // https://kythe.io/docs/schema/#absvar
      return schema.RECORD_KIND;
    }
    return null;
  }

  _handleRefCallEdge(
    Element element, {
    SyntacticEntity syntacticEntity: null,
    start: _notFound,
    end: _notFound,
    KytheVName enclosingTarget: null,
  }) {
    if (element is ExecutableElement &&
        _enclosingVName != _enclosingFileVName) {
      _handleRefEdge(
        element,
        const <String>[schema.REF_CALL_EDGE, schema.REF_EDGE],
        syntacticEntity: syntacticEntity,
        start: start,
        end: end,
        enclosingTarget: enclosingTarget,
        enclosingAnchor: _enclosingVName,
      );
    } else {
      _handleRefEdge(
        element,
        const <String>[schema.REF_EDGE],
        syntacticEntity: syntacticEntity,
        start: start,
        end: end,
        enclosingTarget: enclosingTarget,
      );
    }
  }

  /// This is a convenience method for adding ref edges. If the [start] and
  /// [end] offsets are provided, they are used, otherwise the offsets are
  /// computed by using the [syntacticEntity]. The list of edges is assumed to
  /// be non-empty, and are added from the anchor to the target generated using
  /// the passed [Element]. The created [KytheVName] is returned, if not `null`
  /// is returned.
  KytheVName _handleRefEdge(
    Element element,
    List<String> refEdgeTypes, {
    SyntacticEntity syntacticEntity: null,
    start: _notFound,
    end: _notFound,
    KytheVName enclosingTarget: null,
    KytheVName enclosingAnchor: null,
  }) {
    assert(refEdgeTypes.isNotEmpty);
    element = _findNonSyntheticElement(element);
    if (element == null) {
      return null;
    }

    // vname
    var nodeKind = _getNodeKind(element);
    if (nodeKind == null || nodeKind.isEmpty) {
      return null;
    }
    var vName = _vNameFromElement(element, nodeKind);
    assert(vName != null);

    // anchor
    addAnchorEdgesContainingEdge(
      start: start,
      end: end,
      syntacticEntity: syntacticEntity,
      edges: refEdgeTypes,
      target: vName,
      enclosingTarget: enclosingTarget,
      enclosingAnchor: enclosingAnchor,
    );

    return vName;
  }

  void _handleThisOrSuper(Expression thisOrSuperNode) {
    DartType type = thisOrSuperNode.staticType;
    if (type != null && type.element != null) {
      // Expected SuperExpression.staticType to return the type of the
      // supertype, but it returns the type of the enclosing class (same as
      // ThisExpression), do some additional work to correct assumption:
      if (thisOrSuperNode is SuperExpression && type.element is ClassElement) {
        DartType supertype = (type.element as ClassElement).supertype;
        if (supertype != null) {
          type = supertype;
        }
      }
      // vname
      var vName = _vNameFromElement(type.element, schema.RECORD_KIND);

      // anchor
      var anchorVName = addAnchorEdgesContainingEdge(
          syntacticEntity: thisOrSuperNode,
          edges: [schema.REF_EDGE],
          target: vName);

      // childof from the anchor
      addEdge(anchorVName, schema.CHILD_OF_EDGE, _enclosingVName);
    }

    // no children to visit
  }

  /// Add a "ref/imports" edge from the passed [uriNode] location to the
  /// [referencedElement] [Element].  If the passed element is null, the edge is
  /// not written out.
  void _handleUriReference(StringLiteral uriNode, Element referencedElement) {
    if (referencedElement != null) {
      var start = uriNode.offset;
      var end = uriNode.end;

      // The following is the expected and common case.
      // The contents between the quotes is used as the location to work well
      // with CodeSearch.
      if (uriNode is SimpleStringLiteral) {
        start = uriNode.contentsOffset;
        end = uriNode.contentsEnd;
      }

      // package node
      var packageVName =
          _vNameFromElement(referencedElement, schema.PACKAGE_KIND);

      // anchor
      addAnchorEdgesContainingEdge(
          start: start,
          end: end,
          edges: [schema.REF_IMPORTS_EDGE],
          target: packageVName,
          enclosingTarget: _enclosingFileVName);
    }
  }

  _handleVariableDeclarationListAnnotations(
      VariableDeclarationList variableDeclarationList, KytheVName refVName) {
    assert(refVName != null);
    for (var varDecl in variableDeclarationList.variables) {
      if (varDecl.element != null) {
        var parentVName =
            _vNameFromElement(varDecl.element, schema.VARIABLE_KIND);
        addEdge(parentVName, schema.ANNOTATED_BY_EDGE, refVName);
      } else {
        // The element out of the VarDeclarationList is null
        assert(false);
      }
    }
  }

  /// If the given [node] is not `null`, accept this visitor.
  void _safelyVisit(AstNode node) {
    if (node != null) {
      node.accept(this);
    }
  }

  /// If the given [nodeList] is not `null`, accept this visitor.
  void _safelyVisitList(NodeList nodeList) {
    if (nodeList != null) {
      nodeList.accept(this);
    }
  }

  _withEnclosingElement(Element element, f()) {
    Element outerEnclosingElement = _enclosingElement;
    Element outerEnclosingClassElement = _enclosingClassElement;
    var outerEnclosingVName = _enclosingVName;
    var outerEnclosingClassVName = _enclosingClassVName;
    try {
      _enclosingElement = element;
      if (element is CompilationUnitElement) {
        _enclosingFileVName = _enclosingVName = _vNameFile();
      } else if (element is ClassElement) {
        _enclosingClassElement = element;
        _enclosingClassVName = _enclosingVName =
            _vNameFromElement(_enclosingClassElement, schema.RECORD_KIND);
      } else if (element is MethodElement ||
          element is FunctionElement ||
          element is ConstructorElement) {
        _enclosingVName =
            _vNameFromElement(_enclosingElement, schema.FUNCTION_KIND);
      }
      return f();
    } finally {
      _enclosingElement = outerEnclosingElement;
      _enclosingClassElement = outerEnclosingClassElement;
      _enclosingClassVName = outerEnclosingClassVName;
      _enclosingVName = outerEnclosingVName;
    }
  }
}

/// This class is meant to be a mixin to concrete visitor methods to walk the
/// [Element] or [AstNode]s produced by the Dart Analyzer to output Kythe
/// [KytheEntry] protos.
abstract class OutputUtils {
  /// A set of [String]s which have already had a name [KytheVName] created.
  final Set<String> nameNodes = new Set<String>();

  String get corpus;

  KytheVName get dynamicBuiltin => _vName(schema.DYNAMIC_KIND, '', '', '');

  String get enclosingFilePath;

  List<KytheEntry> get entries;

  KytheVName get fnBuiltin => _vName(schema.FN_BUILTIN, '', '', '');

  ResourceProvider get resourceProvider;

  KytheVName get voidBuiltin => _vName(schema.VOID_BUILTIN, '', '', '');

  /// This is a convenience method for adding anchors. If the [start] and [end]
  /// offsets are provided, they are used, otherwise the offsets are computed by
  /// using the [syntacticEntity]. If a non-empty list of edges is provided, as
  /// well as a target, then this method also adds the edges from the anchor to
  /// target. The anchor [KytheVName] is returned.
  ///
  /// If a [target] and [enclosingTarget] are provided, a childof edge is
  /// written out from the target to the enclosing target.
  ///
  /// If an [enclosingAnchor] is provided a childof edge is written out from the
  /// anchor to the enclosing anchor. In cases where ref/call is an edge, this
  /// is required to generate the callgraph.
  ///
  /// Finally, for all anchors, a childof edge with a target of the enclosing
  /// file is written out.
  KytheVName addAnchorEdgesContainingEdge({
    SyntacticEntity syntacticEntity: null,
    int start: _notFound,
    int end: _notFound,
    List<String> edges: const [],
    KytheVName target: null,
    KytheVName enclosingTarget: null,
    KytheVName enclosingAnchor: null,
  }) {
    if (start == _notFound && end == _notFound) {
      if (syntacticEntity != null) {
        start = syntacticEntity.offset;
        end = syntacticEntity.end;
      } else {
        throw new Exception('Offset positions were not provided when calling '
            'addAnchorEdgesContainingEdge');
      }
    }
    // TODO(jwren) investigate
//    assert(start < end);
    var anchorVName = _vNameAnchor(start, end);
    addFact(anchorVName, schema.NODE_KIND_FACT, _encode(schema.ANCHOR_KIND));
    addFact(anchorVName, schema.ANCHOR_START_FACT, _encodeInt(start));
    addFact(anchorVName, schema.ANCHOR_END_FACT, _encodeInt(end));
    if (target != null) {
      for (String edge in edges) {
        addEdge(anchorVName, edge, target);
      }
      if (enclosingTarget != null) {
        addEdge(target, schema.CHILD_OF_EDGE, enclosingTarget);
      }
    }
    // If provided, write out the childof edge to the enclosing anchor
    if (enclosingAnchor != null) {
      addEdge(anchorVName, schema.CHILD_OF_EDGE, enclosingAnchor);
    }

    // Assert that if ref/call is one of the edges, that and enclosing anchor
    // was provided for the callgraph.
    // Documentation at http://kythe.io/docs/schema/callgraph.html
    if (edges.contains(schema.REF_CALL_EDGE)) {
      assert(enclosingAnchor != null);
    }

    // Finally add the childof edge to the enclosing file VName.
    addEdge(anchorVName, schema.CHILD_OF_EDGE, _vNameFile());
    return anchorVName;
  }

  /// TODO(jwren): for cases where the target is a name, we need the same kind
  /// of logic as [addNameFact] to prevent the edge from being written out.
  /// This is a convenience method for visitors to add an edge Entry.
  KytheEntry addEdge(KytheVName source, String edgeKind, KytheVName target,
      {int ordinalIntValue: _notFound}) {
    if (ordinalIntValue == _notFound) {
      return addEntry(source, edgeKind, target, "/", new List<int>());
    } else {
      return addEntry(source, edgeKind, target, schema.ORDINAL,
          _encodeInt(ordinalIntValue));
    }
  }

  KytheEntry addEntry(KytheVName source, String edgeKind, KytheVName target,
      String factName, List<int> factValue) {
    assert(source != null);
    assert(factName != null);
    assert(factValue != null);
    // factValue may be an empty array, the fact may be that a file text or
    // document text is empty
    if (edgeKind == null || edgeKind.isEmpty) {
      edgeKind = null;
      target = null;
    }
    var entry = new KytheEntry(source, factName,
        kind: edgeKind, target: target, value: factValue);
    entries.add(entry);
    return entry;
  }

  /// This is a convenience method for visitors to add a fact [KytheEntry].
  KytheEntry addFact(KytheVName source, String factName, List<int> factValue) {
    return addEntry(source, null, null, factName, factValue);
  }

  /// This is a convenience method for adding function types.
  KytheVName addFunctionType(
    Element functionElement,
    FormalParameterList paramNodes,
    KytheVName functionVName, {
    AstNode returnNode: null,
  }) {
    var i = 0;
    var funcTypeVName =
        addNodeAndFacts(schema.TAPP_KIND, element: functionElement);
    addEdge(funcTypeVName, schema.PARAM_EDGE, fnBuiltin, ordinalIntValue: i++);

    var returnTypeVName;
    if (returnNode is TypeName) {
      // MethodDeclaration and FunctionDeclaration both return a TypeName from
      // returnType
      if (resolutionMap.typeForTypeName(returnNode).isVoid) {
        returnTypeVName = voidBuiltin;
      } else {
        returnTypeVName =
            _vNameFromElement(returnNode.name.bestElement, schema.TAPP_KIND);
      }
    } else if (returnNode is Identifier) {
      // ConstructorDeclaration returns an Identifier from returnType
      if (resolutionMap.bestTypeForExpression(returnNode).isVoid) {
        returnTypeVName = voidBuiltin;
      } else {
        returnTypeVName =
            _vNameFromElement(returnNode.bestElement, schema.TAPP_KIND);
      }
    }
    // else: return type is null, void, unresolved.

    if (returnTypeVName != null) {
      addEdge(funcTypeVName, schema.PARAM_EDGE, returnTypeVName,
          ordinalIntValue: i++);
    }

    if (paramNodes != null) {
      for (FormalParameter paramNode in paramNodes.parameters) {
        var paramTypeVName = dynamicBuiltin;
        if (!resolutionMap
            .elementDeclaredByFormalParameter(paramNode)
            .type
            .isDynamic) {
          paramTypeVName = _vNameFromElement(
              resolutionMap
                  .elementDeclaredByFormalParameter(paramNode)
                  .type
                  .element,
              schema.TAPP_KIND);
        }
        addEdge(funcTypeVName, schema.PARAM_EDGE, paramTypeVName,
            ordinalIntValue: i++);
      }
    }
    addEdge(functionVName, schema.TYPED_EDGE, funcTypeVName);
    return funcTypeVName;
  }

  /// This is a convenience method for adding nodes with facts.
  /// If an [KytheVName] is passed, it is used, otherwise an element is required
  /// which is used to create a [KytheVName].  Either [nodeVName] must be non-null or
  /// [element] must be non-null. Other optional parameters if passed are then
  /// used to set the associated facts on the [KytheVName]. This method does not
  /// currently guarantee that the inputs to these fact kinds are valid for the
  /// associated nodeKind- if a non-null, then it will set.
  KytheVName addNodeAndFacts(String nodeKind,
      {Element element: null,
      KytheVName nodeVName: null,
      String subKind: null,
      String completeFact: null}) {
    if (nodeVName == null) {
      nodeVName = _vNameFromElement(element, nodeKind);
    }
    addFact(nodeVName, schema.NODE_KIND_FACT, _encode(nodeKind));
    if (subKind != null) {
      addFact(nodeVName, schema.SUBKIND_FACT, _encode(subKind));
    }
    if (completeFact != null) {
      addFact(nodeVName, schema.COMPLETE_FACT, _encode(completeFact));
    }
    return nodeVName;
  }

  List<int> _encode(String str) {
    return UTF8.encode(str);
  }

  List<int> _encodeInt(int i) {
    return UTF8.encode(i.toString());
  }

  /// Given all parameters for a [KytheVName] this method creates and returns a
  /// [KytheVName].
  KytheVName _vName(String signature, String corpus, String root, String path,
      [String language = schema.DART_LANG]) {
    return new KytheVName(signature, corpus, root, path, language);
  }

  /// Returns an anchor [KytheVName] corresponding to the given start and end
  /// offsets.
  KytheVName _vNameAnchor(int start, int end) {
    return _vName(
        _getAnchorSignature(start, end), corpus, '', enclosingFilePath);
  }

  /// Return the [KytheVName] for this file.
  KytheVName _vNameFile() {
    // file vnames, the signature and language are not set
    return _vName('', corpus, '', enclosingFilePath, '');
  }

  /// Given some [Element] and Kythe node kind, this method generates and
  /// returns the [KytheVName].
  KytheVName _vNameFromElement(Element e, String nodeKind) {
    assert(nodeKind != schema.FILE_KIND);
    // general case
    return _vName(_getSignature(resourceProvider, e, nodeKind, corpus), corpus,
        '', _getPath(resourceProvider, e));
  }

  /// Returns a [KytheVName] corresponding to the given [DartType].
  KytheVName _vNameFromType(DartType type) {
    if (type == null || type.isDynamic) {
      return dynamicBuiltin;
    } else if (type.isVoid) {
      return voidBuiltin;
    } else if (type.element is ClassElement) {
      return _vNameFromElement(type.element, schema.RECORD_KIND);
    } else {
      return dynamicBuiltin;
    }
  }
}

/// This visitor class should be used by [_getSignature].
///
/// This visitor is an [GeneralizingElementVisitor] which builds up a [String]
/// signature for a given [Element], uniqueness is guaranteed within the
/// enclosing file.
class SignatureElementVisitor extends GeneralizingElementVisitor<StringBuffer> {
  static SignatureElementVisitor instance = new SignatureElementVisitor();

  @override
  StringBuffer visitCompilationUnitElement(CompilationUnitElement e) {
    return new StringBuffer();
  }

  @override
  StringBuffer visitElement(Element e) {
    assert(e is! MultiplyInheritedExecutableElement);
    var enclosingElt = e.enclosingElement;
    var buffer = enclosingElt.accept(this);
    if (buffer.isNotEmpty) {
      buffer.write('#');
    }
    if (e is MethodElement && e.name == '-' && e.parameters.length == 1) {
      buffer.write('unary-');
    } else if (e is ConstructorElement) {
      buffer.write(_computeConstructorElementName(e));
    } else {
      buffer.write(e.name);
    }
    if (enclosingElt is ExecutableElement) {
      buffer..write('@')..write(e.nameOffset - enclosingElt.nameOffset);
    }
    return buffer;
  }

  @override
  StringBuffer visitLibraryElement(LibraryElement e) {
    return new StringBuffer('library:${e.displayName}');
  }

  @override
  StringBuffer visitTypeParameterElement(TypeParameterElement e) {
    // It is legal to have a named constructor with the same name as a type
    // parameter.  So we distinguish them by using '.' between the class (or
    // typedef) name and the type parameter name.
    return e.enclosingElement.accept(this)..write('.')..write(e.name);
  }
}
