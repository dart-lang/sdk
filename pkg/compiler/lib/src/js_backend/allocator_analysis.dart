// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart' as ir;

import '../constants/values.dart';
import '../js_model/elements.dart' show JsToFrontendMap, JField;
import '../kernel/element_map.dart';
import '../kernel/element_map_impl.dart' show KernelElementEnvironment;
import '../kernel/kelements.dart' show KClass, KField;
import '../options.dart';

abstract class AllocatorAnalysis {}

/// AllocatorAnalysis
///
/// Analysis to determine features of the allocator functions. The allocator
/// function takes parameters for each field initializer and initializes the
/// fields.  Parameters may be omitted if the initializer is always the same
/// constant value.  How the allocator is emitted will determine what kind of
/// constants can be handled.  The initial implementation only permits `null`.

// TODO(sra): Analysis to determine field order. Current field order is
// essentially declaration order, subclass first. We can reorder fields so that
// fields initialized with the same constant are together to allow chained
// initialization. Fields of a class and superclass can be reordered to allow
// chaining, e.g.
//
//     this.x = this.z = null;
//
class KAllocatorAnalysis implements AllocatorAnalysis {
  final KernelElementEnvironment _elementEnvironment;
  KernelToElementMap _elementMap;

  final Map<KField, ConstantValue> _fixedInitializers =
      <KField, ConstantValue>{};

  KAllocatorAnalysis(this._elementEnvironment) {
    _elementMap = _elementEnvironment.elementMap;
  }

  // Register class during resolution. Use simple syntactic analysis to find
  // null-initialized fields.
  void registerInstantiatedClass(KClass class_) {
    ClassDefinition definition = _elementMap.getClassDefinition(class_);
    assert(definition.kind == ClassKind.regular);
    ir.Class classNode = definition.node;

    Set<ir.Field> nulls = new Set<ir.Field>();
    for (ir.Field field in classNode.fields) {
      if (!field.isInstanceMember) continue;
      ir.Expression initializer = field.initializer;
      if (initializer == null || initializer is ir.NullLiteral) {
        nulls.add(field);
      }
    }

    for (ir.Constructor constructor in classNode.constructors) {
      for (ir.Initializer initializer in constructor.initializers) {
        if (initializer is ir.FieldInitializer) {
          // TODO(sra): Check explicit initializer value to see if consistent
          // over all constructors.
          nulls.remove(initializer.field);
        }
      }
    }

    for (var fieldNode in nulls) {
      _fixedInitializers[_elementMap.getField(fieldNode)] =
          const NullConstantValue();
    }
  }
}

class JAllocatorAnalysis implements AllocatorAnalysis {
  // --csp and --fast-startup have different constraints to the generated code.
  final CompilerOptions _options;
  final Map<JField, ConstantValue> _fixedInitializers =
      <JField, ConstantValue>{};

  JAllocatorAnalysis._(this._options);

  static JAllocatorAnalysis from(KAllocatorAnalysis kAnalysis,
      JsToFrontendMap map, CompilerOptions options) {
    var result = new JAllocatorAnalysis._(options);

    kAnalysis._fixedInitializers.forEach((KField kField, ConstantValue value) {
      // TODO(sra): Translate constant, but Null does not need translating.
      if (value.isNull) {
        JField jField = map.toBackendMember(kField);
        if (jField != null) {
          result._fixedInitializers[jField] = value;
        }
      }
    });

    return result;
  }

  bool get _isEnabled {
    if (_options.useContentSecurityPolicy && !_options.useStartupEmitter) {
      // TODO(sra): Refactor csp 'precompiled' constructor generation to allow
      // in-allocator initialization.
      return false;
    }
    if (!_options.strongMode) return false;
    return true;
  }
  // TODO(sra): Add way to let injected fields be initialized to a constant in
  // allocator.

  bool isInitializedInAllocator(JField field) {
    if (!_isEnabled) return false;
    return _fixedInitializers[field] != null;
  }

  /// Return constant for a field initialized in allocator. Returns `null` for
  /// fields not initialized in allocator.
  ConstantValue initializerValue(JField field) {
    assert(_isEnabled);
    return _fixedInitializers[field];
  }
}
