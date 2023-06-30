// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/file_system/physical_file_system.dart';
import 'package:analyzer/src/dart/element/inheritance_manager3.dart';
import 'package:analyzer_utilities/package_root.dart' as package_root;
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(SelectionCoverageTest);
  });
}

class AstImplData {
  final List<ClassElement> instantiableInterfaces = [];

  AstImplData();
}

class AstInterfaceData {
  /// A table mapping the element for a class to a list of the elements for the
  /// supertypes of that class.
  final Map<ClassElement, List<ClassElement>> supertypes = {};

  /// A table mapping class element to a list of the getters declared directly
  /// in that class that return a `NodeList`.
  final Map<ClassElement, List<ExecutableElement>> declaredLists = {};

  AstInterfaceData();

  List<ExecutableElement> nodeListsFor(ClassElement class_) {
    var lists = <ExecutableElement>[];
    _addListsFor(lists, class_, <ClassElement>{});
    return lists;
  }

  void _addListsFor(List<ExecutableElement> lists, ClassElement class_,
      Set<ClassElement> visited) {
    if (!visited.add(class_)) {
      return;
    }
    lists.addAll(declaredLists[class_] ?? const []);
    var supertypes = this.supertypes[class_];
    if (supertypes != null) {
      for (var supertype in supertypes) {
        _addListsFor(lists, supertype, visited);
      }
    }
  }
}

@reflectiveTest
class SelectionCoverageTest {
  AstImplData processAstImpl(ResolvedUnitResult result) {
    var data = AstImplData();

    for (var declaration in result.unit.declarations) {
      if (declaration is ClassDeclaration &&
          declaration.abstractKeyword == null) {
        var interfaceName = declaration.name.lexeme;
        if (!interfaceName.endsWith('Impl')) {
          continue;
        }
        interfaceName = interfaceName.substring(0, interfaceName.length - 4);
        var implementsClause = declaration.implementsClause;
        if (implementsClause != null) {
          for (var type in implementsClause.interfaces) {
            var element = type.type?.element;
            if (element is ClassElement && element.name == interfaceName) {
              data.instantiableInterfaces.add(element);
            }
          }
        }
      }
    }

    return data;
  }

  AstInterfaceData processAstInterface(ResolvedUnitResult result) {
    var data = AstInterfaceData();

    for (var declaration in result.unit.declarations) {
      if (declaration is ClassDeclaration) {
        // Build the subtype map.
        var subtypeElement = declaration.declaredElement!;
        var implementsClause = declaration.implementsClause;
        if (implementsClause != null) {
          for (var supertype in implementsClause.interfaces) {
            var supertypeElement = supertype.type?.element;
            if (supertypeElement is ClassElement) {
              data.supertypes
                  .putIfAbsent(subtypeElement, () => [])
                  .add(supertypeElement);
            }
          }
        }

        // Build the node list map.
        var nodeLists = <ExecutableElement>[];
        for (var member in declaration.members) {
          if (member is MethodDeclaration && member.isGetter) {
            var returnType = member.returnType;
            if (returnType != null &&
                returnType.toSource().startsWith('NodeList<')) {
              nodeLists.add(member.declaredElement!);
            }
          }
        }
        if (nodeLists.isNotEmpty) {
          data.declaredLists[subtypeElement] = nodeLists;
        }
      }
    }

    return data;
  }

  SelectionData processSelection(ResolvedUnitResult result) {
    var data = SelectionData();

    for (var declaration in result.unit.declarations) {
      if (declaration is ClassDeclaration &&
          declaration.name.lexeme == '_ChildrenFinder') {
        for (var member in declaration.members) {
          if (member is MethodDeclaration &&
              member.name.lexeme.startsWith('visit')) {
            var visitedClass = member
                .parameters?.parameters.first.declaredElement?.type.element;
            if (visitedClass is ClassElement) {
              var visitor = VisitMethodVisitor();
              member.body.accept(visitor);
              data.visitedLists[visitedClass] = visitor.visitedLists;
            }
          }
        }
      }
    }

    return data;
  }

  @TestTimeout(Timeout.factor(4))
  Future<void> test_visitorCoverage() async {
    var provider = PhysicalResourceProvider.INSTANCE;
    var pathContext = provider.pathContext;
    var packageRoot = pathContext.normalize(package_root.packageRoot);
    var pathToAsInterface = pathContext.join(
        packageRoot, 'analyzer', 'lib', 'dart', 'ast', 'ast.dart');
    var pathToAsImpl = pathContext.join(
        packageRoot, 'analyzer', 'lib', 'src', 'dart', 'ast', 'ast.dart');
    var pathToSelection = pathContext.join(packageRoot, 'analysis_server',
        'lib', 'src', 'utilities', 'selection.dart');

    var collection =
        AnalysisContextCollection(includedPaths: [pathToSelection]);
    var context = collection.contexts.first;
    var astInterfaceResult =
        await context.currentSession.getResolvedUnit(pathToAsInterface);
    var astImplResult =
        await context.currentSession.getResolvedUnit(pathToAsImpl);
    var selectionResult =
        await context.currentSession.getResolvedUnit(pathToSelection);

    var astInterfaceData =
        processAstInterface(astInterfaceResult as ResolvedUnitResult);
    var astImplData = processAstImpl(astImplResult as ResolvedUnitResult);
    var selectionData = processSelection(selectionResult as ResolvedUnitResult);
    var visitedLists = selectionData.visitedLists;
    var inheritanceManager = InheritanceManager3();

    var buffer = StringBuffer();
    for (var interface in astImplData.instantiableInterfaces) {
      if (interface.name == 'Comment' ||
          interface.name == 'VariableDeclaration') {
        // The class `Comment` has references, but we don't support selecting a
        // portion of a comment in order to operate on it.
        //
        // The class `VariableDeclaration` has metadata, but the list is never
        // populated, so we don't visit the class, and hence are required to
        // special case it here. If the class hierarchy is ever cleaned up, we
        // can remove this special casing.
        continue;
      }
      var declaredNodeLists = astInterfaceData.nodeListsFor(interface);
      if (declaredNodeLists.isEmpty) {
        continue;
      }
      var visitedNodeLists = visitedLists[interface];
      if (visitedNodeLists == null) {
        var interfaceName = interface.name;
        buffer.writeln('Missing implementation of visit$interfaceName:');
        buffer.writeln();
        buffer.writeln('@override');
        buffer.writeln('void visit$interfaceName($interfaceName node) {');
        for (var nodeList in declaredNodeLists) {
          buffer.writeln('  _fromList(node.${nodeList.name});');
        }
        buffer.writeln('}');
        buffer.writeln();
      } else {
        var unvisitedNodeLists = {...declaredNodeLists};
        for (var visitedNodeList in visitedNodeLists) {
          unvisitedNodeLists.remove(visitedNodeList);
          var overridden = inheritanceManager.getOverridden2(
              visitedNodeList.enclosingElement2 as InterfaceElement,
              Name(visitedNodeList.library.source.uri, visitedNodeList.name));
          if (overridden != null) {
            unvisitedNodeLists.removeAll(overridden);
          }
        }
        if (unvisitedNodeLists.isNotEmpty) {
          buffer.writeln('Missing lines in visit${interface.name}:');
          buffer.writeln();
          for (var nodeList in unvisitedNodeLists) {
            buffer.writeln('  _fromList(node.${nodeList.name});');
          }
          buffer.writeln();
        }
      }
    }
    if (buffer.length > 0) {
      fail(buffer.toString());
    }
  }
}

class SelectionData {
  final Map<ClassElement, List<ExecutableElement>> visitedLists = {};

  SelectionData();
}

class VisitMethodVisitor extends RecursiveAstVisitor<void> {
  List<ExecutableElement> visitedLists = [];

  VisitMethodVisitor();

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (node.methodName.name == '_fromList') {
      var argument = node.argumentList.arguments.first;
      if (argument is PrefixedIdentifier) {
        visitedLists
            .add(argument.identifier.staticElement as ExecutableElement);
      } else if (argument is PropertyAccess) {
        visitedLists
            .add(argument.propertyName.staticElement as ExecutableElement);
      }
    }
  }
}
