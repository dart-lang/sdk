// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:_fe_analyzer_shared/src/messages/diagnostic_message.dart'
    show DiagnosticMessage, DiagnosticMessageHandler, getMessageHeaderText;
import 'package:analyzer_fe_comparison/src/comparison_node.dart';
import 'package:front_end/src/api_prototype/compiler_options.dart'
    show CompilerOptions;
import 'package:front_end/src/api_prototype/kernel_generator.dart';
import 'package:front_end/src/api_prototype/standard_file_system.dart';
import 'package:kernel/ast.dart';
import 'package:kernel/target/targets.dart';

/// Compiles the given [inputs] to kernel using the front_end, and returns a
/// [ComparisonNode] representing them.
Future<ComparisonNode> analyzePackage(
    List<Uri> inputs, Uri packagesFileUri, Uri platformUri) async {
  var messages = <DiagnosticMessage>[];
  var component = (await kernelForModule(inputs,
          _makeCompilerOptions(packagesFileUri, platformUri, messages.add)))
      .component;
  if (messages.isNotEmpty) {
    return ComparisonNode(
        'Error occurred', messages.map(_diagnosticMessageToNode).toList());
  }
  var libraryNodes = <ComparisonNode>[];
  var visitor = _KernelVisitor(libraryNodes);
  for (var library in component.libraries) {
    if (inputs.contains(library.importUri)) {
      library.accept(visitor);
    }
  }
  return ComparisonNode.sorted('Component', libraryNodes);
}

/// Compiles the given [input] to kernel using the front_end, and returns a
/// [ComparisonNode] representing it.
///
/// Only libraries whose URI passes the [uriFilter] are included in the results.
Future<ComparisonNode> analyzeProgram(Uri input, Uri packagesFileUri,
    Uri platformUri, bool uriFilter(Uri uri)) async {
  var messages = <DiagnosticMessage>[];
  var component = (await kernelForProgram(input,
          _makeCompilerOptions(packagesFileUri, platformUri, messages.add)))
      .component;
  if (messages.isNotEmpty) {
    return ComparisonNode(
        'Error occurred', messages.map(_diagnosticMessageToNode).toList());
  }
  var libraryNodes = <ComparisonNode>[];
  var visitor = _KernelVisitor(libraryNodes);
  for (var library in component.libraries) {
    if (uriFilter(library.importUri)) {
      library.accept(visitor);
    }
  }
  return ComparisonNode.sorted('Component', libraryNodes);
}

ComparisonNode _diagnosticMessageToNode(DiagnosticMessage message) {
  return ComparisonNode(getMessageHeaderText(message));
}

CompilerOptions _makeCompilerOptions(Uri packagesFileUri, Uri platformUri,
    DiagnosticMessageHandler onDiagnostic) {
  var targetFlags = TargetFlags();
  var target = NoneTarget(targetFlags);
  var fileSystem = StandardFileSystem.instance;

  return CompilerOptions()
    ..fileSystem = fileSystem
    ..packagesFileUri = packagesFileUri
    ..sdkSummary = platformUri
    ..target = target
    ..throwOnErrorsForDebugging = false
    ..embedSourceText = false
    ..onDiagnostic = onDiagnostic;
}

/// Visitor for serializing a kernel representation of a program into
/// ComparisonNodes.
///
/// Results are accumulated into [_resultNodes].
class _KernelVisitor extends TreeVisitor<void> {
  final List<ComparisonNode> _resultNodes;

  _KernelVisitor(this._resultNodes);

  @override
  void defaultTreeNode(TreeNode node) {
    throw new UnimplementedError('KernelVisitor: ${node.runtimeType}');
  }

  @override
  void visitClass(Class class_) {
    if (class_.isAnonymousMixin) return null;
    var kind = class_.isEnum
        ? 'Enum'
        : class_.isMixinApplication
            ? 'MixinApplication'
            : class_.isMixinDeclaration ? 'Mixin' : 'Class';
    var children = <ComparisonNode>[];
    var visitor = _KernelVisitor(children);
    if (class_.isEnum) {
      for (var field in class_.fields) {
        if (!field.isStatic) continue;
        if (field.name.name == 'values') continue;
        // TODO(paulberry): handle index
        children.add(ComparisonNode('EnumValue ${field.name.name}'));
      }
    } else {
      visitor._visitTypeParameters(class_.typeParameters);
      if (class_.supertype != null) {
        var declaredSupertype = class_.supertype.asInterfaceType;
        if (class_.isMixinDeclaration) {
          var constraints = <DartType>[];
          // Kernel represents a mixin declaration such as:
          //   mixin M on S0, S1, S2 {...}
          // By desugaring it to:
          //   abstract class _M&S0&S1 implements S0, S1 {}
          //   abstract class _M&S0&S1&S2 implements _M&S0&S1 {}
          //   abstract class M extends M&S0&S1&S2 {...}
          // (See dartbug.com/34783)
          while (declaredSupertype.classNode.isAnonymousMixin) {
            // Since we're walking up the class hierarchy, we encounter the
            // mixins in the reverse order that they were declared, so we have
            // to use [List.insert] to add them to [constraints].
            constraints.insert(
                0,
                declaredSupertype
                    .classNode.implementedTypes[1].asInterfaceType);
            declaredSupertype =
                declaredSupertype.classNode.implementedTypes[0].asInterfaceType;
          }
          constraints.insert(0, declaredSupertype);
          for (int i = 0; i < constraints.length; i++) {
            children.add(_TypeVisitor.translate('On $i: ', constraints[i]));
          }
        } else {
          var mixedInTypes = <DartType>[];
          if (class_.isMixinApplication) {
            mixedInTypes.add(class_.mixedInType.asInterfaceType);
          }
          while (declaredSupertype.classNode.isAnonymousMixin) {
            // Since we're walking from the class to its declared supertype, we
            // encounter the mixins in the reverse order that they were declared,
            // so we have to use [List.insert] to add them to [mixedInTypes].
            mixedInTypes.insert(
                0, declaredSupertype.classNode.mixedInType.asInterfaceType);
            declaredSupertype =
                declaredSupertype.classNode.supertype.asInterfaceType;
          }
          children.add(_TypeVisitor.translate('Extends: ', declaredSupertype));
          for (int i = 0; i < mixedInTypes.length; i++) {
            children.add(_TypeVisitor.translate('Mixin $i: ', mixedInTypes[i]));
          }
        }
      }
      for (int i = 0; i < class_.implementedTypes.length; i++) {
        children.add(_TypeVisitor.translate(
            'Implements $i: ', class_.implementedTypes[i].asInterfaceType));
      }
      visitor._visitList(class_.fields);
      visitor._visitList(class_.constructors);
      visitor._visitList(class_.procedures);
    }
    // TODO(paulberry): handle more fields from Class
    _resultNodes.add(ComparisonNode.sorted('$kind ${class_.name}', children));
  }

  @override
  void visitConstructor(Constructor constructor) {
    if (constructor.isSynthetic) return null;
    var name = constructor.name.name;
    if (name.isEmpty) {
      name = '(unnamed)';
    }
    var children = <ComparisonNode>[];
    var visitor = _KernelVisitor(children);
    constructor.function.accept(visitor);
    // TODO(paulberry): handle more fields from Constructor
    _resultNodes.add(ComparisonNode.sorted('Constructor $name', children));
  }

  @override
  void visitField(Field field) {
    if (field.name.name == '_redirecting#') return null;
    if (field.name.name == '_exports#') return null;
    var children = <ComparisonNode>[];
    children.add(_TypeVisitor.translate('Type: ', field.type));
    // TODO(paulberry): handle more fields from Field
    _resultNodes
        .add(ComparisonNode.sorted('Field ${field.name.name}', children));
  }

  @override
  void visitFunctionNode(FunctionNode node) {
    var parent = node.parent;
    if (!(parent is Constructor || parent is Procedure && parent.isFactory)) {
      _visitTypeParameters(node.typeParameters);
      _resultNodes
          .add(_TypeVisitor.translate('Return type: ', node.returnType));
    }
    var parameterChildren = <ComparisonNode>[];
    var parameterVisitor = _KernelVisitor(parameterChildren);
    for (int i = 0; i < node.positionalParameters.length; i++) {
      parameterVisitor._visitParameter(node.positionalParameters[i],
          i < node.requiredParameterCount ? 'Required' : 'Optional');
    }
    for (int i = 0; i < node.namedParameters.length; i++) {
      parameterVisitor._visitParameter(node.namedParameters[i], 'Named');
    }
    _resultNodes.add(ComparisonNode('Parameters', parameterChildren));
    // TODO(paulberry): handle more fields from FunctionNode
  }

  @override
  void visitLibrary(Library library) {
    var children = <ComparisonNode>[];
    if (library.name != null) {
      children.add(ComparisonNode('name=${library.name}'));
    }
    var visitor = _KernelVisitor(children);
    visitor._visitList(library.typedefs);
    visitor._visitList(library.classes);
    visitor._visitList(library.procedures);
    visitor._visitList(library.fields);
    // TODO(paulberry): handle more fields from Library
    _resultNodes
        .add(ComparisonNode.sorted(library.importUri.toString(), children));
  }

  @override
  void visitProcedure(Procedure procedure) {
    if (procedure.isSyntheticForwarder) {
      return null;
    }
    if (procedure.name.name.startsWith('__loadLibrary_')) {
      // Sometimes the front end generates procedures with this name that don't
      // correspond to anything in the source file.  Ignore them.
      return null;
    }
    // TODO(paulberry): add an annotation to the ComparisonNode when the
    // procedure is a factory.
    var kind = procedure.isFactory
        ? 'Constructor'
        : procedure.kind.toString().replaceAll('ProcedureKind.', '');
    var name = procedure.name.name;
    if (name.isEmpty) {
      name = '(unnamed)';
    }
    var children = <ComparisonNode>[];
    var visitor = _KernelVisitor(children);
    procedure.function.accept(visitor);
    // TODO(paulberry): handle more fields from Procedure
    _resultNodes.add(ComparisonNode.sorted('$kind $name', children));
  }

  @override
  void visitTypedef(Typedef typedef) {
    var children = <ComparisonNode>[];
    var visitor = _KernelVisitor(children);
    visitor._visitTypeParameters(typedef.typeParameters);
    children.add(_TypeVisitor.translate('Type: ', typedef.type));
    // TODO(paulberry): handle more fields from Typedef
    _resultNodes
        .add(ComparisonNode.sorted('Typedef ${typedef.name}', children));
  }

  /// Visits all the nodes in [nodes].
  void _visitList(List<TreeNode> nodes) {
    for (var node in nodes) {
      node.accept(this);
    }
  }

  void _visitParameter(VariableDeclaration parameter, String kind) {
    var children = <ComparisonNode>[];
    children.add(_TypeVisitor.translate('Type: ', parameter.type));
    // TODO(paulberry): handle more fields from VariableDeclaration
    _resultNodes
        .add(ComparisonNode.sorted('$kind: ${parameter.name}', children));
  }

  void _visitTypeParameters(List<TypeParameter> typeParameters) {
    for (int i = 0; i < typeParameters.length; i++) {
      _resultNodes.add(ComparisonNode(
          'Type parameter $i: ${typeParameters[i].name}',
          [_TypeVisitor.translate('Bound: ', typeParameters[i].bound)]));
    }
  }
}

/// Visitor for serializing a kernel representation of a type into
/// ComparisonNodes.
class _TypeVisitor extends DartTypeVisitor<ComparisonNode> {
  /// Text to prepend to the node text.
  String _prefix;

  _TypeVisitor(this._prefix);

  @override
  ComparisonNode defaultDartType(DartType node) {
    throw new UnimplementedError('_TypeVisitor: ${node.runtimeType}');
  }

  @override
  ComparisonNode visitDynamicType(DynamicType node) {
    return ComparisonNode('${_prefix}Dynamic');
  }

  @override
  ComparisonNode visitFunctionType(FunctionType node) {
    var children = <ComparisonNode>[];
    var visitor = _KernelVisitor(children);
    visitor._visitTypeParameters(node.typeParameters);
    children.add(translate('Return type: ', node.returnType));
    for (int i = 0; i < node.positionalParameters.length; i++) {
      var kind = i < node.requiredParameterCount ? 'Required' : 'Optional';
      children
          .add(translate('$kind parameter $i: ', node.positionalParameters[i]));
    }
    for (var namedType in node.namedParameters) {
      children.add(
          translate('Named parameter ${namedType.name}: ', namedType.type));
    }
    return ComparisonNode.sorted('${_prefix}FunctionType', children);
  }

  @override
  ComparisonNode visitInterfaceType(InterfaceType node) {
    var children = <ComparisonNode>[];
    children.add(ComparisonNode(
        'Library: ${node.classNode.enclosingLibrary.importUri}'));
    for (int i = 0; i < node.typeArguments.length; i++) {
      children.add(translate('Type arg $i: ', node.typeArguments[i]));
    }
    return ComparisonNode(
        '${_prefix}InterfaceType ${node.classNode.name}', children);
  }

  @override
  ComparisonNode visitTypeParameterType(TypeParameterType node) {
    // TODO(paulberry): disambiguate if needed.
    return ComparisonNode(
        '${_prefix}TypeParameterType: ${node.parameter.name}');
  }

  @override
  ComparisonNode visitVoidType(VoidType node) {
    return ComparisonNode('${_prefix}Void');
  }

  static ComparisonNode translate(String prefix, DartType type) {
    return type.accept(new _TypeVisitor(prefix));
  }
}
