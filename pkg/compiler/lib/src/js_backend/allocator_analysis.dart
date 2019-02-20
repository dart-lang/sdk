// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart' as ir;

import '../constants/values.dart';
import '../js_model/elements.dart' show JField;
import '../js_model/js_world_builder.dart';
import '../kernel/element_map.dart';
import '../kernel/kernel_strategy.dart';
import '../kernel/kelements.dart' show KClass, KField, KConstructor;
import '../options.dart';
import '../serialization/serialization.dart';

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
  final KernelToElementMap _elementMap;

  final Map<KField, AllocatorData> _fixedInitializers = {};

  KAllocatorAnalysis(KernelFrontEndStrategy kernelStrategy)
      : _elementMap = kernelStrategy.elementMap;

  // Register class during resolution. Use simple syntactic analysis to find
  // null-initialized fields.
  void registerInstantiatedClass(KClass class_) {
    ir.Class classNode = _elementMap.getClassNode(class_);

    Map<ir.Field, AllocatorData> fieldData = {};
    for (ir.Field field in classNode.fields) {
      if (!field.isInstanceMember) continue;
      ir.Expression expression = field.initializer;
      ConstantValue value = _elementMap.getConstantValue(expression,
          requireConstant: false, implicitNull: true);
      if (value != null && value.isConstant) {
        fieldData[field] = new AllocatorData(value);
      }
    }

    for (ir.Constructor constructor in classNode.constructors) {
      KConstructor constructorElement = _elementMap.getConstructor(constructor);
      for (ir.Initializer initializer in constructor.initializers) {
        if (initializer is ir.FieldInitializer) {
          AllocatorData data = fieldData[initializer.field];
          if (data == null) {
            // TODO(johnniwinther): Support initializers with side-effects?

            // The field has a non-constant initializer.
            continue;
          }

          Initializer initializerValue = const Initializer.complex();
          ir.Expression value = initializer.value;
          ConstantValue constantValue = _elementMap.getConstantValue(value,
              requireConstant: false, implicitNull: true);
          if (constantValue != null && constantValue.isConstant) {
            initializerValue = new Initializer.direct(constantValue);
          } else if (value is ir.VariableGet) {
            ir.VariableDeclaration parameter = value.variable;
            int position =
                constructor.function.positionalParameters.indexOf(parameter);
            if (position != -1) {
              if (position >= constructor.function.requiredParameterCount) {
                constantValue = _elementMap.getConstantValue(
                    parameter.initializer,
                    requireConstant: false,
                    implicitNull: true);
                if (constantValue != null && constantValue.isConstant) {
                  initializerValue =
                      new Initializer.positional(position, constantValue);
                }
              }
            } else {
              position =
                  constructor.function.namedParameters.indexOf(parameter);
              if (position != -1) {
                constantValue = _elementMap.getConstantValue(
                    parameter.initializer,
                    requireConstant: false,
                    implicitNull: true);
                if (constantValue != null && constantValue.isConstant) {
                  initializerValue =
                      new Initializer.named(parameter.name, constantValue);
                }
              }
            }
          }
          data.initializers[constructorElement] = initializerValue;
        }
      }
    }

    fieldData.forEach((ir.Field fieldNode, AllocatorData data) {
      _fixedInitializers[_elementMap.getField(fieldNode)] = data;
    });
  }

  AllocatorData getFixedInitializerForTesting(KField field) =>
      _fixedInitializers[field];
}

class AllocatorData {
  final ConstantValue initialValue;
  final Map<KConstructor, Initializer> initializers = {};

  AllocatorData(this.initialValue);
}

enum InitializerKind {
  direct,
  positional,
  named,
  complex,
}

class Initializer {
  final InitializerKind kind;
  final int index;
  final String name;
  final ConstantValue value;

  Initializer.direct(this.value)
      : kind = InitializerKind.direct,
        index = null,
        name = null;

  Initializer.positional(this.index, this.value)
      : kind = InitializerKind.positional,
        name = null;

  Initializer.named(this.name, this.value)
      : kind = InitializerKind.named,
        index = null;

  const Initializer.complex()
      : kind = InitializerKind.complex,
        index = null,
        name = null,
        value = null;

  String shortText() {
    switch (kind) {
      case InitializerKind.direct:
        return value.toStructuredText();
      case InitializerKind.positional:
        return '$index:${value.toStructuredText()}';
      case InitializerKind.named:
        return '$name:${value.toStructuredText()}';
      case InitializerKind.complex:
        return '?';
    }
    throw new UnsupportedError('Unexpected kind $kind');
  }
}

class JAllocatorAnalysis implements AllocatorAnalysis {
  /// Tag used for identifying serialized [JAllocatorAnalysis] objects in a
  /// debugging data stream.
  static const String tag = 'allocator-analysis';

  // --csp and --fast-startup have different constraints to the generated code.
  final Map<JField, ConstantValue> _fixedInitializers = {};

  JAllocatorAnalysis._();

  /// Deserializes a [JAllocatorAnalysis] object from [source].
  factory JAllocatorAnalysis.readFromDataSource(
      DataSource source, CompilerOptions options) {
    source.begin(tag);
    JAllocatorAnalysis analysis = new JAllocatorAnalysis._();
    int fieldCount = source.readInt();
    for (int i = 0; i < fieldCount; i++) {
      JField field = source.readMember();
      ConstantValue value = source.readConstant();
      analysis._fixedInitializers[field] = value;
    }
    source.end(tag);
    return analysis;
  }

  /// Serializes this [JAllocatorAnalysis] to [sink].
  void writeToDataSink(DataSink sink) {
    sink.begin(tag);
    sink.writeInt(_fixedInitializers.length);
    _fixedInitializers.forEach((JField field, ConstantValue value) {
      sink.writeMember(field);
      sink.writeConstant(value);
    });
    sink.end(tag);
  }

  static JAllocatorAnalysis from(KAllocatorAnalysis kAnalysis,
      JsToFrontendMap map, CompilerOptions options) {
    var result = JAllocatorAnalysis._();

    kAnalysis._fixedInitializers.forEach((KField kField, AllocatorData data) {
      // TODO(johnniwinther): Use liveness of constructors and elided optional
      // parameters to recognize more constant initializers.
      if (data.initialValue != null && data.initializers.isEmpty) {
        ConstantValue value = data.initialValue;
        if (value.isNull || value.isInt || value.isBool || value.isString) {
          // TODO(johnniwinther,sra): Support non-primitive constants in
          // allocators when it does cause allocators to deoptimized because
          // of deferred loading.

          JField jField = map.toBackendMember(kField);
          if (jField != null) {
            result._fixedInitializers[jField] = map.toBackendConstant(value);
          }
        }
      }
    });

    return result;
  }

  bool get _isEnabled {
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
