// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection';

import 'kernel.dart';

class _ConstVisitor extends RecursiveVisitor<void> {
  _ConstVisitor(
    this.classLibraryUri,
    this.className,
    this.annotationClassLibraryUri,
    this.annotationClassName,
  )   : _visitedInstances = <String>{},
        constantInstances = <Map<String, dynamic>>[],
        nonConstantLocations = <Map<String, dynamic>>[];

  /// The library URI for the class to find.
  final String classLibraryUri;

  /// The name of the class to find.
  final String className;

  final Set<String> _visitedInstances;
  // TODO(johnniwinther): Use extension types to type these.
  final List<Map<String, dynamic>> constantInstances;
  final List<Map<String, dynamic>> nonConstantLocations;

  bool inIgnoredClass = false;

  /// Whether or not we are currently within the declaration of the target
  /// class.
  ///
  /// We use this to determine when to skip tracking non-constant
  /// [ConstructorInvocation]s. This is because, in web builds, a static
  /// method is always created called _#new#tearOff() which returns the result
  /// of a non-constant invocation of the unnamed constructor.
  ///
  /// For the following Dart class "FooBar":
  ///
  /// class FooBar {
  ///   const FooBar();
  /// }
  ///
  /// The following kernel structure is generated:
  ///
  /// class FooBar extends core::Object /*hasConstConstructor*/  {
  ///   const constructor •() → min::FooBar
  ///     : super core::Object::•()
  ///     ;
  ///   static method _#new#tearOff() → min::FooBar
  ///     /* this is a non-const constructor invocation */
  ///     return new min::FooBar::•();
  ///   method noOp() → void {}
  /// }
  bool inTargetClass = false;

  bool inTargetTearOff = false;

  /// The name of the name of the class of the annotation marking classes
  /// whose constant references should be ignored.
  final String? annotationClassName;

  /// The library URI of the class of the annotation marking classes whose
  /// constant references should be ignored.
  final String? annotationClassLibraryUri;

  // A cache of previously evaluated classes.
  static final Map<Class, bool> _classHierarchyCache = <Class, bool>{};
  bool _matches(Class node) {
    final bool? result = _classHierarchyCache[node];
    if (result != null) {
      return result;
    }
    final bool exactMatch = node.name == className &&
        node.enclosingLibrary.importUri.toString() == classLibraryUri;
    final bool match = exactMatch ||
        node.supers.any((Supertype supertype) => _matches(supertype.classNode));
    _classHierarchyCache[node] = match;
    return match;
  }

  // Avoid visiting the same constant more than once.
  // TODO(johnniwinther): Use [VisitOnceConstantVisitor] instead.
  final Set<Constant> _cache = LinkedHashSet<Constant>.identity();

  @override
  void visitProcedure(Procedure node) {
    // TODO(johnniwinther): Use lowering predicates.
    final bool isTearOff = node.isStatic &&
        node.kind == ProcedureKind.Method &&
        node.name.text == '_#new#tearOff';
    if (inTargetClass && isTearOff) {
      inTargetTearOff = true;
    }
    super.visitProcedure(node);
    inTargetTearOff = false;
  }

  @override
  void defaultConstant(Constant node) {
    if (_cache.add(node)) {
      super.defaultConstant(node);
    }
  }

  @override
  void defaultConstantReference(Constant node) {
    defaultConstant(node);
  }

  @override
  void visitConstructorInvocation(ConstructorInvocation node) {
    final Class parentClass = node.target.parent! as Class;
    if (!inTargetTearOff && _matches(parentClass)) {
      final Location location = node.location!;
      nonConstantLocations.add(<String, dynamic>{
        'file': location.file.toString(),
        'line': location.line,
        'column': location.column,
      });
    }
    super.visitConstructorInvocation(node);
  }

  @override
  void visitClass(Class node) {
    inTargetClass = _matches(node);
    // check if this is a class that we should ignore
    inIgnoredClass = _classShouldBeIgnored(node);
    super.visitClass(node);
    inTargetClass = false;
    inIgnoredClass = false;
  }

  // If any annotations on the class match annotationClassName AND
  // annotationClassLibraryUri.
  bool _classShouldBeIgnored(Class node) {
    if (annotationClassName == null || annotationClassLibraryUri == null) {
      return false;
    }
    return node.annotations.any((Expression expression) {
      if (expression is! ConstantExpression) {
        return false;
      }

      final Constant constant = expression.constant;
      return constant is InstanceConstant &&
          constant.classNode.name == annotationClassName &&
          constant.classNode.enclosingLibrary.importUri.toString() ==
              annotationClassLibraryUri;
    });
  }

  @override
  void visitInstanceConstantReference(InstanceConstant node) {
    super.visitInstanceConstantReference(node);
    if (!_matches(node.classNode) || inIgnoredClass) {
      return;
    }

    final Map<String, dynamic> instance = <String, dynamic>{};
    for (final MapEntry<Reference, Constant> entry
        in node.fieldValues.entries) {
      if (entry.value is! PrimitiveConstant<dynamic>) {
        continue;
      }
      final PrimitiveConstant<dynamic> value =
          entry.value as PrimitiveConstant<dynamic>;
      instance[entry.key.asField.name.text] = value.value;
    }
    if (_visitedInstances.add(instance.toString())) {
      constantInstances.add(instance);
    }
  }
}

/// A kernel AST visitor that finds const references.
class ConstFinder {
  /// The path to the file to open.
  final String kernelFilePath;

  /// Creates a new ConstFinder class.
  ///
  /// The `kernelFilePath` is the path to a dill (kernel) file to process.
  ConstFinder({
    required this.kernelFilePath,
    required String classLibraryUri,
    required String className,
    String? annotationClassLibraryUri,
    String? annotationClassName,
  }) : _visitor = _ConstVisitor(
          classLibraryUri,
          className,
          annotationClassLibraryUri,
          annotationClassName,
        );

  final _ConstVisitor _visitor;

  /// Finds all instances
  // TODO(johnniwinther): Use extension types to type the result.
  Map<String, dynamic> findInstances() {
    _visitor._visitedInstances.clear();
    for (final Library library
        in loadComponentFromBinary(kernelFilePath).libraries) {
      library.visitChildren(_visitor);
    }
    return <String, dynamic>{
      'constantInstances': _visitor.constantInstances,
      'nonConstantLocations': _visitor.nonConstantLocations,
    };
  }
}
