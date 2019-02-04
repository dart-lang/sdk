// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../util/features.dart';
import 'nodes.dart';

/// Log used for unit testing optimizations.
class OptimizationTestLog {
  List<OptimizationLogEntry> entries = [];

  Map<String, Set<HInstruction>> _unconverted;

  Features _register(String tag, HInstruction original, HInstruction converted,
      void f(Features features)) {
    if (converted == null) {
      _unconverted ??= {};
      Set<HInstruction> set = _unconverted[tag] ??= new Set<HInstruction>();
      if (!set.add(original)) {
        return null;
      }
    }
    Features features = new Features();
    f(features);
    entries.add(new OptimizationLogEntry(tag, features));
    return features;
  }

  void registerFieldGet(HInvokeDynamicGetter original, HFieldGet converted) {
    Features features = new Features();
    features['name'] =
        '${converted.element.enclosingClass.name}.${converted.element.name}';
    entries.add(new OptimizationLogEntry('FieldGet', features));
  }

  void registerFieldSet(HInvokeDynamicSetter original, HFieldSet converted) {
    Features features = new Features();
    features['name'] =
        '${converted.element.enclosingClass.name}.${converted.element.name}';
    entries.add(new OptimizationLogEntry('FieldSet', features));
  }

  Features _registerSpecializer(
      HInvokeDynamic original, HInstruction converted, String name,
      [String unconvertedName]) {
    assert(!(converted == null && unconvertedName == null));
    return _register('Specializer', original, converted, (Features features) {
      if (converted != null) {
        features.add(name);
      } else {
        features.add(unconvertedName);
      }
    });
  }

  void registerIndexAssign(HInvokeDynamic original, HIndexAssign converted) {
    _registerSpecializer(original, converted, 'IndexAssign');
  }

  void registerIndex(HInvokeDynamic original, HIndex converted) {
    _registerSpecializer(original, converted, 'Index');
  }

  void registerBitNot(HInvokeDynamic original, HBitNot converted) {
    _registerSpecializer(original, converted, 'BitNot');
  }

  void registerUnaryNegate(HInvokeDynamic original, HNegate converted) {
    _registerSpecializer(original, converted, 'Negate');
  }

  void registerAbs(HInvokeDynamic original, HAbs converted) {
    _registerSpecializer(original, converted, 'Abs');
  }

  void registerAdd(HInvokeDynamic original, HAdd converted) {
    _registerSpecializer(original, converted, 'Add');
  }

  void registerDivide(HInvokeDynamic original, HDivide converted) {
    _registerSpecializer(original, converted, 'Divide');
  }

  void registerModulo(HInvokeDynamic original, [HRemainder converted]) {
    _registerSpecializer(original, converted, 'Modulo', 'DynamicModulo');
  }

  void registerRemainder(HInvokeDynamic original, HRemainder converted) {
    _registerSpecializer(original, converted, 'Remainder');
  }

  void registerMultiply(HInvokeDynamic original, HMultiply converted) {
    _registerSpecializer(original, converted, 'Multiply');
  }

  void registerSubtract(HInvokeDynamic original, HSubtract converted) {
    _registerSpecializer(original, converted, 'Subtract');
  }

  void registerTruncatingDivide(
      HInvokeDynamic original, HTruncatingDivide converted) {
    _registerSpecializer(original, converted, 'TruncatingDivide',
        'TruncatingDivide.${original.selector.name}');
  }

  void registerShiftLeft(HInvokeDynamic original, HShiftLeft converted) {
    _registerSpecializer(original, converted, 'ShiftLeft',
        'ShiftLeft.${original.selector.name}');
  }

  void registerShiftRight(HInvokeDynamic original, HShiftRight converted) {
    _registerSpecializer(original, converted, 'ShiftRight',
        'ShiftRight.${original.selector.name}');
  }

  void registerBitOr(HInvokeDynamic original, HBitOr converted) {
    _registerSpecializer(original, converted, 'BitOr');
  }

  void registerBitAnd(HInvokeDynamic original, HBitAnd converted) {
    _registerSpecializer(original, converted, 'BitAnd');
  }

  void registerBitXor(HInvokeDynamic original, HBitXor converted) {
    _registerSpecializer(original, converted, 'BitXor');
  }

  void registerEquals(HInvokeDynamic original, HIdentity converted) {
    _registerSpecializer(original, converted, 'Equals');
  }

  void registerLess(HInvokeDynamic original, HLess converted) {
    _registerSpecializer(original, converted, 'Less');
  }

  void registerGreater(HInvokeDynamic original, HGreater converted) {
    _registerSpecializer(original, converted, 'Greater');
  }

  void registerLessEqual(HInvokeDynamic original, HLessEqual converted) {
    _registerSpecializer(original, converted, 'LessEquals');
  }

  void registerGreaterEqual(HInvokeDynamic original, HGreaterEqual converted) {
    _registerSpecializer(original, converted, 'GreaterEquals');
  }

  void registerCodeUnitAt(HInvokeDynamic original) {
    Features features = new Features();
    features['name'] = original.selector.name;
    entries.add(new OptimizationLogEntry('CodeUnitAt', features));
  }

  void registerCompareTo(HInvokeDynamic original, [HConstant converted]) {
    Features features = new Features();
    if (converted != null) {
      features['constant'] = converted.constant.toDartText();
    }
    entries.add(new OptimizationLogEntry('CompareTo', features));
  }

  void registerSubstring(HInvokeDynamic original) {
    Features features = new Features();
    entries.add(new OptimizationLogEntry('Substring', features));
  }

  void registerTrim(HInvokeDynamic original) {
    Features features = new Features();
    entries.add(new OptimizationLogEntry('Trim', features));
  }

  void registerPatternMatch(HInvokeDynamic original) {
    Features features = new Features();
    entries.add(new OptimizationLogEntry('PatternMatch', features));
  }

  void registerRound(HInvokeDynamic original) {
    _registerSpecializer(original, null, null, 'Round');
  }

  void registerTypeConversion(
      HInstruction original, HTypeConversion converted) {
    Features features = new Features();
    switch (converted.kind) {
      case HTypeConversion.CHECKED_MODE_CHECK:
        features['kind'] = 'checked';
        break;
      case HTypeConversion.ARGUMENT_TYPE_CHECK:
        features['kind'] = 'argument';
        break;
      case HTypeConversion.CAST_TYPE_CHECK:
        features['kind'] = 'cast';
        break;
      case HTypeConversion.BOOLEAN_CONVERSION_CHECK:
        features['kind'] = 'boolean';
        break;
      case HTypeConversion.RECEIVER_TYPE_CHECK:
        features['kind'] = 'receiver';
        break;
    }
    if (converted.typeExpression != null) {
      features['type'] = '${converted.typeExpression}';
    }
    entries.add(new OptimizationLogEntry('TypeConversion', features));
  }

  String getText() {
    return entries.join(',\n');
  }

  String toString() => 'OptimizationLog(${getText()})';
}

/// A registered optimization.
class OptimizationLogEntry {
  /// String that uniquely identifies the optimization kind.
  final String tag;

  /// Additional data for this optimization.
  final Features features;

  OptimizationLogEntry(this.tag, this.features);

  String toString() => '$tag(${features.getText()})';
}
