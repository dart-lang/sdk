// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/element/scope.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/type_system.dart';
import 'package:analyzer/src/summary2/ast_resolver.dart';
import 'package:analyzer/src/summary2/library_builder.dart';
import 'package:analyzer/src/summary2/link.dart';
import 'package:analyzer/src/summary2/linking_node_scope.dart';
import 'package:analyzer/src/utilities/extensions/element.dart';

class DefaultValueResolver {
  final Linker _linker;
  final LibraryBuilder _libraryBuilder;
  final TypeSystemImpl _typeSystem;

  DefaultValueResolver(this._linker, this._libraryBuilder)
      : _typeSystem = _libraryBuilder.element.typeSystem;

  void resolve() {
    for (var libraryFragment in _libraryBuilder.element.fragments) {
      _UnitContext(libraryFragment)
        ..forEach(libraryFragment.classes, _interface)
        ..forEach(libraryFragment.enums, _interface)
        ..forEach(libraryFragment.extensions, _extension)
        ..forEach(libraryFragment.extensionTypes, _interface)
        ..forEach(libraryFragment.functions, _executable)
        ..forEach(libraryFragment.mixins, _interface);
    }
  }

  void _constructor(_ClassContext context, ConstructorElementImpl element) {
    if (element.isSynthetic) return;
    _executable(context, element);
  }

  DefaultFormalParameterImpl? _defaultParameter(ParameterElementImpl element) {
    var node = _linker.getLinkingNode(element);
    if (node is DefaultFormalParameterImpl && node.defaultValue != null) {
      return node;
    } else {
      return null;
    }
  }

  void _executable(_Context context, ExecutableElementImpl element) {
    _ExecutableContext(
      enclosingContext: context,
      executableElement: element,
      scope: _scopeFromElement(element),
    ).forEach(element.parameters, _parameter);
  }

  void _extension(_UnitContext context, ExtensionElementImpl element) {
    context.forEach(element.methods, _executable);
  }

  void _interface(_UnitContext context, InterfaceElementImpl element) {
    _ClassContext(context, element)
      ..forEach(element.constructors, _constructor)
      ..forEach(element.methods, _executable);
  }

  void _parameter(_ExecutableContext context, ParameterElementImpl parameter) {
    // If a function typed parameter, process nested parameters.
    context.forEach(parameter.parameters, _parameter);

    var node = _defaultParameter(parameter);
    if (node == null) return;

    var contextType = _typeSystem.eliminateTypeVariables(parameter.type);

    var analysisOptions = _libraryBuilder.kind.file.analysisOptions;
    var astResolver = AstResolver(
      _linker,
      context.libraryFragment,
      context.scope,
      analysisOptions,
      enclosingClassElement: context.classElement?.asElement2,
      enclosingExecutableElement: context.executableElement.asElement2,
    );
    astResolver.resolveExpression(() => node.defaultValue!,
        contextType: contextType);
  }

  Scope _scopeFromElement(ElementImpl element) {
    var node = _linker.getLinkingNode(element)!;
    return LinkingNodeContext.get(node).scope;
  }
}

class _ClassContext extends _Context {
  final _UnitContext unitContext;

  @override
  final InterfaceElementImpl classElement;

  _ClassContext(this.unitContext, this.classElement);

  @override
  CompilationUnitElementImpl get libraryFragment {
    return unitContext.libraryFragment;
  }
}

abstract class _Context {
  InterfaceElementImpl? get classElement => null;

  CompilationUnitElementImpl get libraryFragment;
}

class _ExecutableContext extends _Context {
  final _Context enclosingContext;
  final ExecutableElementImpl executableElement;
  final Scope scope;

  _ExecutableContext({
    required this.enclosingContext,
    required this.executableElement,
    required this.scope,
  });

  @override
  InterfaceElementImpl? get classElement {
    return enclosingContext.classElement;
  }

  @override
  CompilationUnitElementImpl get libraryFragment {
    return enclosingContext.libraryFragment;
  }
}

class _UnitContext extends _Context {
  @override
  final CompilationUnitElementImpl libraryFragment;

  _UnitContext(this.libraryFragment);
}

extension _ContextExtension<C extends _Context> on C {
  void forEach<T>(
    List<T> elements,
    void Function(C context, T element) f,
  ) {
    for (var element in elements) {
      f(this, element);
    }
  }
}
