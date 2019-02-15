// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart' as ir;

import '../constants/values.dart';
import '../js_model/elements.dart' show JField;
import '../js_model/js_world_builder.dart';
import '../kernel/element_map.dart';
import '../kernel/kernel_strategy.dart';
import '../kernel/kelements.dart' show KClass, KField;
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

  final Map<KField, ConstantValue> _fixedInitializers = {};

  KAllocatorAnalysis(KernelFrontEndStrategy kernelStrategy)
      : _elementMap = kernelStrategy.elementMap;

  // Register class during resolution. Use simple syntactic analysis to find
  // null-initialized fields.
  void registerInstantiatedClass(KClass class_) {
    ir.Class classNode = _elementMap.getClassNode(class_);

    Map<ir.Field, ConstantValue> inits = {};
    for (ir.Field field in classNode.fields) {
      if (!field.isInstanceMember) continue;
      ir.Expression initializer = field.initializer;
      // TODO(sra): Should really be using constant evaluator to determine
      // value.
      if (initializer == null || initializer is ir.NullLiteral) {
        inits[field] = const NullConstantValue();
      } else if (initializer is ir.IntLiteral) {
        BigInt intValue = BigInt.from(initializer.value).toUnsigned(64);
        inits[field] = IntConstantValue(intValue);
      } else if (initializer is ir.BoolLiteral) {
        inits[field] = BoolConstantValue(initializer.value);
      } else if (initializer is ir.StringLiteral) {
        if (initializer.value.length <= 20) {
          inits[field] = StringConstantValue(initializer.value);
        }
      }
    }

    for (ir.Constructor constructor in classNode.constructors) {
      for (ir.Initializer initializer in constructor.initializers) {
        if (initializer is ir.FieldInitializer) {
          // TODO(sra): Check explicit initializer value to see if consistent
          // over all constructors.
          inits.remove(initializer.field);
        }
      }
    }

    inits.forEach((ir.Field fieldNode, ConstantValue value) {
      _fixedInitializers[_elementMap.getField(fieldNode)] = value;
    });
  }

  ConstantValue getFixedInitializerForTesting(KField field) =>
      _fixedInitializers[field];
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

    kAnalysis._fixedInitializers.forEach((KField kField, ConstantValue value) {
      // TODO(sra): Translate constant, but Null and these primitives do not
      // need translating.
      if (value.isNull || value.isInt || value.isBool || value.isString) {
        JField jField = map.toBackendMember(kField);
        if (jField != null) {
          result._fixedInitializers[jField] = value;
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
