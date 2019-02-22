// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:linter/src/analyzer.dart';
import 'package:linter/src/ast.dart';
import 'package:linter/src/util/dart_type_utilities.dart';

const _desc = r'DO reference all public properties in debug methods.';

const _details = r'''
**DO** reference all public properties in `debug` method implementations.

Implementers of `Diagnosticable` should reference all public properties in
a `debugFillProperties(...)` or `debugDescribeChildren(...)` method
implementation to improve debuggability at runtime.

Public properties are defined as fields and getters that are

* not package-private (e.g., prefixed with `_`)
* not `static` or overriding
* not themselves `Widget`s or collections of `Widget`s

In addition, the "debug" prefix is treated specially for properties in Flutter.
For the purposes of diagnostics, a property `foo` and a prefixed property
`debugFoo` are treated as effectively describing the same property and it is
sufficient to refer to one or the other.

**BAD:**
```
class Absorber extends Widget {
  bool get absorbing => _absorbing;
  bool _absorbing;
  bool get ignoringSemantics => _ignoringSemantics;
  bool _ignoringSemantics;
  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<bool>('absorbing', absorbing));
    // Missing reference to ignoringSemantics
  }
}  
```

**GOOD:**
```
class Absorber extends Widget {
  bool get absorbing => _absorbing;
  bool _absorbing;
  bool get ignoringSemantics => _ignoringSemantics;
  bool _ignoringSemantics;
  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<bool>('absorbing', absorbing));
    properties.add(DiagnosticsProperty<bool>('ignoringSemantics', ignoringSemantics));
  }
}  
```
''';

class DiagnosticsDescribeAllProperties extends LintRule
    implements NodeLintRule {
  DiagnosticsDescribeAllProperties()
      : super(
            name: 'diagnostic_describe_all_properties',
            description: _desc,
            details: _details,
            maturity: Maturity.experimental,
            group: Group.errors);

  @override
  void registerNodeProcessors(NodeLintRegistry registry,
      [LinterContext context]) {
    final visitor = new _Visitor(this, context);
    registry.addCompilationUnit(this, visitor);
    registry.addClassDeclaration(this, visitor);
  }
}

// todo (pq): for experiments and book-keeping; remove before landing
int fileCount = 0;
int debugPropertyCount = 0;
int classesWithPropertiesButNoDebugFill = 0;

class _Visitor extends SimpleAstVisitor {
  final LintRule rule;
  final InheritanceManager2 inheritanceManager;

  _Visitor(this.rule, LinterContext context)
      : inheritanceManager = new InheritanceManager2(context.typeSystem);

  // todo (pq): for experiments and book-keeping; remove before landing
  LineInfo lineInfo;

  @override
  visitCompilationUnit(CompilationUnit node) {
    lineInfo = node.lineInfo;
  }

  static int noMethods = 0;
  static int totalClasses = 0;

  bool _isOverridingMember(Element member) {
    if (member == null) {
      return false;
    }

    ClassElement classElement =
        member.getAncestor((element) => element is ClassElement);
    if (classElement == null) {
      return false;
    }
    Uri libraryUri = classElement.library.source.uri;
    return inheritanceManager.getInherited(
            classElement.type, new Name(libraryUri, member.name)) !=
        null;
  }

  @override
  visitClassDeclaration(ClassDeclaration node) {
    ++totalClasses;

    // We only care about Diagnosticables.
    var type = node.declaredElement.type;
    if (!DartTypeUtilities.implementsInterface(type, 'Diagnosticable', '')) {
      return;
    }

    var properties = <SimpleIdentifier>[];
    for (var member in node.members) {
      if (member is MethodDeclaration && member.isGetter) {
        if (isPrivate(member.name)) {
          continue;
        }
        if (member.isStatic) {
          continue;
        }
        if (isWidgetProperty(member.returnType?.type)) {
          continue;
        }
        if (_isOverridingMember(member.declaredElement)) {
          continue;
        }

        properties.add(member.name);
      } else if (member is FieldDeclaration) {
        for (var v in member.fields.variables) {
          if (isPrivate(v.name)) {
            continue;
          }
          if (v.declaredElement.isStatic) {
            continue;
          }
          if (isWidgetProperty(v.declaredElement.type)) {
            continue;
          }
          if (_isOverridingMember(v.declaredElement)) {
            continue;
          }

          properties.add(v.name);
        }
      }
    }

    if (properties.isEmpty) {
      return;
    }

    // todo (pq): move up to top when we're not counting anymore.
    var debugFillProperties = node.getMethod('debugFillProperties');
    if (debugFillProperties == null) {
      ++classesWithPropertiesButNoDebugFill;
    }

    var debugDescribeChildren = node.getMethod('debugDescribeChildren');
    if (debugFillProperties == null && debugDescribeChildren == null) {
      return;
    }

    // Remove any defined in debugFillProperties.
    removeReferences(debugFillProperties, properties);

    // Remove any defined in debugDescribeChildren.
    removeReferences(debugDescribeChildren, properties);

    // Flag the rest.
    properties.forEach(rule.reportLint);

//    // todo (pq): remove before landing
//    for (var prop in properties) {
//      var line = lineInfo.getLocation(prop.offset).lineNumber;
//      var prefix =
//          'https://github.com/flutter/flutter/blob/master/packages/flutter/';
//      var path = node.element.source.fullName.split('packages/flutter/')[1];
//      print('| [$path:$line]($prefix$path#L$line) | ${node.name}.$prop |');
//      ++debugPropertyCount;
//    }
  }

  void removeReferences(
      MethodDeclaration method, List<SimpleIdentifier> properties) {
    if (method == null) {
      return;
    }
    DartTypeUtilities.traverseNodesInDFS(method.body)
        .whereType<SimpleIdentifier>()
        .forEach((p) {
      var debugName;
      var name;
      if (p.name.startsWith('debug') && p.name.length > 5) {
        debugName = p.name;
        name = '${p.name[5].toLowerCase()}${p.name.substring(6)}';
      } else {
        name = p.name;
        debugName = 'debug${p.name[0].toUpperCase()}${p.name.substring(1)}';
      }
      properties.removeWhere(
          (property) => property.name == debugName || property.name == name);
    });
  }

  var collectionInterfaces = <InterfaceTypeDefinition>[
    new InterfaceTypeDefinition('List', 'dart.core'),
    new InterfaceTypeDefinition('Map', 'dart.core'),
    new InterfaceTypeDefinition('LinkedHashMap', 'dart.collection'),
    new InterfaceTypeDefinition('Set', 'dart.core'),
    new InterfaceTypeDefinition('LinkedHashSet', 'dart.collection'),
  ];

  bool isWidgetProperty(DartType type) {
    if (DartTypeUtilities.implementsInterface(type, 'Widget', '')) {
      return true;
    }
    if (type is ParameterizedType &&
        DartTypeUtilities.implementsAnyInterface(type, collectionInterfaces)) {
      // todo (pq): improve....
      return type.typeParameters.length == 1 &&
          isWidgetProperty(type.typeArguments.first);
    }
    return false;
  }
}
