// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/analysis/analysis_options.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/dart/ast/extensions.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/error/inference_error.dart';
import 'package:analyzer/src/summary2/ast_resolver.dart';
import 'package:analyzer/src/summary2/instance_member_inferrer.dart';
import 'package:analyzer/src/summary2/library_builder.dart';
import 'package:analyzer/src/summary2/link.dart';
import 'package:analyzer/src/summary2/linking_node_scope.dart';
import 'package:analyzer/src/utilities/extensions/object.dart';
import 'package:collection/collection.dart';

/// Resolver for typed constant top-level variables and fields initializers.
///
/// Initializers of untyped variables are resolved during [TopLevelInference].
class ConstantInitializersResolver {
  final Linker linker;

  ConstantInitializersResolver(this.linker);

  void perform() {
    for (var builder in linker.builders.values) {
      var analysisOptions = builder.kind.file.analysisOptions;
      var libraryElement = builder.element;

      var instanceElementListList = [
        libraryElement.classes,
        libraryElement.enums,
        libraryElement.extensions,
        libraryElement.extensionTypes,
        libraryElement.mixins,
      ];
      for (var instanceElementList in instanceElementListList) {
        for (var instanceElement in instanceElementList) {
          for (var field in instanceElement.fields) {
            _resolveVariable(analysisOptions, field);
          }
        }
      }

      for (var variable in libraryElement.topLevelVariables) {
        _resolveVariable(analysisOptions, variable);
      }
    }
  }

  void _resolveVariable(
    AnalysisOptionsImpl analysisOptions,
    PropertyInducingElementImpl element,
  ) {
    if (element is FieldElementImpl && element.isEnumConstant) {
      return;
    }

    var constantInitializer = element.constantInitializer2;
    if (constantInitializer == null) {
      return;
    }

    var fragment = constantInitializer.fragment;
    var node = linker.elementNodes[fragment] as VariableDeclarationImpl;
    var scope = LinkingNodeContext.get(node).scope;

    var astResolver = AstResolver(
      linker,
      fragment.libraryFragment as LibraryFragmentImpl,
      scope,
      analysisOptions,
    );
    astResolver.resolveExpression(
      () => node.initializer!,
      contextType: element.type,
    );

    // We could have rewritten the initializer.
    fragment.constantInitializer = node.initializer;
  }
}

class TopLevelInference {
  final Linker linker;

  TopLevelInference(this.linker);

  void infer() {
    var initializerInference = _InitializerInference(linker);
    initializerInference.createNodes();

    _performOverrideInference();

    initializerInference.perform();
  }

  void _performOverrideInference() {
    var interfacesToInfer = linker.builders.values.expand((builder) {
      return builder.element.children.whereType<InterfaceElementImpl>();
    }).toList();

    var inferrer = InstanceMemberInferrer(linker.inheritance);
    inferrer.perform(interfacesToInfer);
  }
}

enum _InferenceStatus { notInferred, beingInferred, inferred }

class _InitializerInference {
  final Linker _linker;
  final List<PropertyInducingElementImpl> _toInfer = [];
  final List<_PropertyInducingElementTypeInference> _inferring = [];

  late LibraryBuilder _libraryBuilder;

  _InitializerInference(this._linker);

  void createNodes() {
    for (var builder in _linker.builders.values) {
      _libraryBuilder = builder;
      var libraryElement = builder.element;

      var instanceElementListList = [
        libraryElement.classes,
        libraryElement.enums,
        libraryElement.extensions,
        libraryElement.extensionTypes,
        libraryElement.mixins,
      ];
      for (var instanceElementList in instanceElementListList) {
        for (var instanceElement in instanceElementList) {
          for (var field in instanceElement.fields) {
            _addVariableNode(field);
          }
        }
      }

      for (var variable in libraryElement.topLevelVariables) {
        _addVariableNode(variable);
      }
    }
  }

  /// Perform type inference for variables for which it was not done yet.
  void perform() {
    for (var element in _toInfer) {
      // Will perform inference, if not done yet.
      element.type;
    }
  }

  void _addVariableNode(PropertyInducingElementImpl element) {
    if (element.isSynthetic &&
        !(element is FieldElementImpl && element.isSyntheticEnumField)) {
      return;
    }

    if (!element.hasImplicitType) return;

    _toInfer.add(element);

    element.firstFragment.typeInference = _PropertyInducingElementTypeInference(
      _linker,
      _inferring,
      element,
      _libraryBuilder,
    );
  }
}

class _PropertyInducingElementTypeInference
    implements PropertyInducingElementTypeInference {
  final Linker _linker;

  /// The stack of objects performing inference now. A new object is pushed
  /// when we start resolving the initializer, and popped when we are done.
  final List<_PropertyInducingElementTypeInference> _inferring;

  /// The status is used to identify a cycle, when we are asked to infer the
  /// type, but the status is already [_InferenceStatus.beingInferred].
  _InferenceStatus _status = _InferenceStatus.notInferred;

  final LibraryBuilder _libraryBuilder;
  final PropertyInducingElementImpl _element;

  _PropertyInducingElementTypeInference(
    this._linker,
    this._inferring,
    this._element,
    this._libraryBuilder,
  );

  @override
  TypeImpl perform() {
    PropertyInducingFragmentImpl? initializerFragment;
    VariableDeclarationImpl? variableDeclaration;
    for (var fragment in _element.fragments) {
      var node = _linker.elementNodes[fragment] as VariableDeclarationImpl;
      if (node.initializer != null) {
        initializerFragment = fragment;
        variableDeclaration = node;
      }
    }

    if (initializerFragment == null || variableDeclaration == null) {
      _status = _InferenceStatus.inferred;
      return DynamicTypeImpl.instance;
    }

    // With this status the type must be already set.
    // So, the element knows the type, ans should not call the inferrer.
    if (_status == _InferenceStatus.inferred) {
      assert(false, 'Should not happen: $_element');
      return DynamicTypeImpl.instance;
    }

    // If we are already inferring this element, we found a cycle.
    if (_status == _InferenceStatus.beingInferred) {
      var startIndex = _inferring.indexOf(this);
      var cycle = _inferring.slice(startIndex);
      var inferenceError = TopLevelInferenceError(
        kind: TopLevelInferenceErrorKind.dependencyCycle,
        arguments: cycle.map((e) => e._element.name ?? '').sorted(),
      );
      for (var inference in cycle) {
        if (inference._status == _InferenceStatus.beingInferred) {
          var element = inference._element;
          element.firstFragment.typeInferenceError = inferenceError;
          element.type = DynamicTypeImpl.instance;
          inference._status = _InferenceStatus.inferred;
        }
      }
      return DynamicTypeImpl.instance;
    }

    assert(_status == _InferenceStatus.notInferred);

    // Push self into the stack, and mark.
    _inferring.add(this);
    _status = _InferenceStatus.beingInferred;

    var enclosingElement = _element.enclosingElement;
    var enclosingInterfaceElement = enclosingElement
        .ifTypeOrNull<InterfaceElementImpl>();

    var scope = LinkingNodeContext.get(variableDeclaration).scope;

    var analysisOptions = _libraryBuilder.kind.file.analysisOptions;
    var astResolver = AstResolver(
      _linker,
      initializerFragment.libraryFragment,
      scope,
      analysisOptions,
      enclosingClassElement: enclosingInterfaceElement,
    );
    astResolver.resolveExpression(() => variableDeclaration!.initializer!);

    // Pop self from the stack.
    var self = _inferring.removeLast();
    assert(identical(self, this));

    // We might have found a cycle, and already set the type.
    // Anyway, we are done.
    if (_status == _InferenceStatus.inferred) {
      return _element.type;
    } else {
      _status = _InferenceStatus.inferred;
    }

    var initializerType = variableDeclaration.initializer!.typeOrThrow;
    return _refineType(initializerType);
  }

  TypeImpl _refineType(TypeImpl type) {
    if (type.isDartCoreNull) {
      return DynamicTypeImpl.instance;
    }

    return type;
  }
}
