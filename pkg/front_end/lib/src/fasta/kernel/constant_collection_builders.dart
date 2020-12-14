// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of 'constant_evaluator.dart';

abstract class _ListOrSetConstantBuilder<L extends Expression> {
  final ConstantEvaluator evaluator;
  final Expression original;
  final DartType elementType;

  // Each element of [parts] is either a `List<Constant>` (containing fully
  // evaluated constants) or a `Constant` (potentially unevaluated).
  List<Object> parts = <Object>[<Constant>[]];

  _ListOrSetConstantBuilder(this.original, this.elementType, this.evaluator);

  L makeLiteral(List<Expression> elements);

  /// Add an element to the constant list being built by this builder.
  ///
  /// Returns [null] on success and an error-"constant" on failure, as such the
  /// return value should be checked.
  AbortConstant add(Expression element) {
    Constant constant = evaluator._evaluateSubexpression(element);
    if (constant is AbortConstant) return constant;
    if (evaluator.shouldBeUnevaluated) {
      parts.add(evaluator.unevaluated(
          element, makeLiteral([evaluator.extract(constant)])));
      return null;
    } else {
      return addConstant(constant, element);
    }
  }

  /// Returns [null] on success and an error-"constant" on failure, as such the
  /// return value should be checked.
  AbortConstant addSpread(Expression spreadExpression) {
    Constant constant = evaluator._evaluateSubexpression(spreadExpression);
    if (constant is AbortConstant) return constant;
    Constant spread = evaluator.unlower(constant);
    if (evaluator.shouldBeUnevaluated) {
      // Unevaluated spread
      parts.add(spread);
    } else if (spread == evaluator.nullConstant) {
      // Null spread
      return evaluator.createErrorConstant(
          spreadExpression, messageConstEvalNullValue);
    } else {
      // Fully evaluated spread
      List<Constant> entries;
      if (spread is ListConstant) {
        entries = spread.entries;
      } else if (spread is SetConstant) {
        entries = spread.entries;
      } else if (evaluator.backend.isLoweredListConstant(spread)) {
        entries = <Constant>[];
        evaluator.backend.forEachLoweredListConstantElement(spread,
            (Constant element) {
          entries.add(element);
        });
      } else if (evaluator.backend.isLoweredSetConstant(constant)) {
        entries = <Constant>[];
        evaluator.backend.forEachLoweredSetConstantElement(spread,
            (Constant element) {
          entries.add(element);
        });
      } else {
        // Not list or set in spread
        return evaluator.createErrorConstant(
            spreadExpression, messageConstEvalNotListOrSetInSpread);
      }
      for (Constant entry in entries) {
        AbortConstant error = addConstant(entry, spreadExpression);
        if (error != null) return error;
      }
    }
    return null;
  }

  /// Returns [null] on success and an error-"constant" on failure, as such the
  /// return value should be checked.
  AbortConstant addConstant(Constant constant, TreeNode context);

  Constant build();
}

class ListConstantBuilder extends _ListOrSetConstantBuilder<ListLiteral> {
  ListConstantBuilder(
      Expression original, DartType elementType, ConstantEvaluator evaluator)
      : super(original, elementType, evaluator);

  @override
  ListLiteral makeLiteral(List<Expression> elements) =>
      new ListLiteral(elements, isConst: true);

  @override
  AbortConstant addConstant(Constant constant, TreeNode context) {
    List<Constant> lastPart;
    if (parts.last is List<Constant>) {
      lastPart = parts.last;
    } else {
      // Probably unreachable.
      parts.add(lastPart = <Constant>[]);
    }
    Constant value = evaluator.ensureIsSubtype(constant, elementType, context);
    if (value is AbortConstant) return value;
    lastPart.add(value);
    return null;
  }

  @override
  Constant build() {
    if (parts.length == 1) {
      // Fully evaluated
      return evaluator
          .lowerListConstant(new ListConstant(elementType, parts.single));
    }
    List<Expression> lists = <Expression>[];
    for (Object part in parts) {
      if (part is List<Constant>) {
        if (part.isEmpty) continue;
        lists.add(new ConstantExpression(new ListConstant(elementType, part)));
      } else if (part is Constant) {
        lists.add(evaluator.extract(part));
      } else {
        throw 'Non-constant in constant list';
      }
    }
    return evaluator.unevaluated(
        original, new ListConcatenation(lists, typeArgument: elementType));
  }
}

class SetConstantBuilder extends _ListOrSetConstantBuilder<SetLiteral> {
  final Set<Constant> seen = new Set<Constant>.identity();
  final Set<Constant> weakSeen = new Set<Constant>.identity();

  SetConstantBuilder(
      Expression original, DartType elementType, ConstantEvaluator evaluator)
      : super(original, elementType, evaluator);

  @override
  SetLiteral makeLiteral(List<Expression> elements) =>
      new SetLiteral(elements, isConst: true);

  @override
  AbortConstant addConstant(Constant constant, TreeNode context) {
    if (!evaluator.hasPrimitiveEqual(constant)) {
      return evaluator.createErrorConstant(
          context,
          templateConstEvalElementImplementsEqual.withArguments(
              constant, evaluator.isNonNullableByDefault));
    }
    bool unseen = seen.add(constant);
    if (!unseen) {
      return evaluator.createErrorConstant(
          context,
          templateConstEvalDuplicateElement.withArguments(
              constant, evaluator.isNonNullableByDefault));
    }
    if (evaluator.evaluationMode == EvaluationMode.agnostic) {
      Constant weakConstant =
          evaluator._weakener.visitConstant(constant) ?? constant;
      bool weakUnseen = weakSeen.add(weakConstant);
      if (unseen != weakUnseen) {
        return evaluator.createErrorConstant(
            context, messageNonAgnosticConstant);
      }
    }

    List<Constant> lastPart;
    if (parts.last is List<Constant>) {
      lastPart = parts.last;
    } else {
      // Probably unreachable.
      parts.add(lastPart = <Constant>[]);
    }
    Constant value = evaluator.ensureIsSubtype(constant, elementType, context);
    if (value is AbortConstant) return value;
    lastPart.add(value);
    return null;
  }

  @override
  Constant build() {
    if (parts.length == 1) {
      // Fully evaluated
      List<Constant> entries = parts.single;
      SetConstant result = new SetConstant(elementType, entries);
      return evaluator.lowerSetConstant(result);
    }
    List<Expression> sets = <Expression>[];
    for (Object part in parts) {
      if (part is List<Constant>) {
        if (part.isEmpty) continue;
        sets.add(new ConstantExpression(new SetConstant(elementType, part)));
      } else if (part is Constant) {
        sets.add(evaluator.extract(part));
      } else {
        throw 'Non-constant in constant set';
      }
    }
    return evaluator.unevaluated(
        original, new SetConcatenation(sets, typeArgument: elementType));
  }
}

class MapConstantBuilder {
  final ConstantEvaluator evaluator;
  final Expression original;
  final DartType keyType;
  final DartType valueType;

  /// Each element of [parts] is either a `List<ConstantMapEntry>` (containing
  /// fully evaluated map entries) or a `Constant` (potentially unevaluated).
  List<Object> parts = <Object>[<ConstantMapEntry>[]];

  final Set<Constant> seenKeys = new Set<Constant>.identity();
  final Set<Constant> weakSeenKeys = new Set<Constant>.identity();

  MapConstantBuilder(
      this.original, this.keyType, this.valueType, this.evaluator);

  /// Add a map entry to the constant map being built by this builder
  ///
  /// Returns [null] on success and an error-"constant" on failure, as such the
  /// return value should be checked.
  AbortConstant add(MapEntry element) {
    Constant key = evaluator._evaluateSubexpression(element.key);
    if (key is AbortConstant) return key;
    Constant value = evaluator._evaluateSubexpression(element.value);
    if (value is AbortConstant) return value;
    if (evaluator.shouldBeUnevaluated) {
      parts.add(evaluator.unevaluated(
          element.key,
          new MapLiteral(
              [new MapEntry(evaluator.extract(key), evaluator.extract(value))],
              isConst: true)));
      return null;
    } else {
      return addConstant(key, value, element.key, element.value);
    }
  }

  /// Returns [null] on success and an error-"constant" on failure, as such the
  /// return value should be checked.
  AbortConstant addSpread(Expression spreadExpression) {
    Constant constant = evaluator._evaluateSubexpression(spreadExpression);
    if (constant is AbortConstant) return constant;
    Constant spread = evaluator.unlower(constant);
    if (evaluator.shouldBeUnevaluated) {
      // Unevaluated spread
      parts.add(spread);
    } else if (spread == evaluator.nullConstant) {
      // Null spread
      return evaluator.createErrorConstant(
          spreadExpression, messageConstEvalNullValue);
    } else {
      // Fully evaluated spread
      if (spread is MapConstant) {
        for (ConstantMapEntry entry in spread.entries) {
          AbortConstant error = addConstant(
              entry.key, entry.value, spreadExpression, spreadExpression);
          if (error != null) return error;
        }
      } else if (evaluator.backend.isLoweredMapConstant(spread)) {
        AbortConstant error;
        evaluator.backend.forEachLoweredMapConstantEntry(spread,
            (Constant key, Constant value) {
          error ??= addConstant(key, value, spreadExpression, spreadExpression);
        });
        if (error != null) return error;
      } else {
        // Not map in spread
        return evaluator.createErrorConstant(
            spreadExpression, messageConstEvalNotMapInSpread);
      }
    }
    return null;
  }

  /// Returns [null] on success and an error-"constant" on failure, as such the
  /// return value should be checked.
  AbortConstant addConstant(Constant key, Constant value, TreeNode keyContext,
      TreeNode valueContext) {
    List<ConstantMapEntry> lastPart;
    if (parts.last is List<ConstantMapEntry>) {
      lastPart = parts.last;
    } else {
      // Probably unreachable.
      parts.add(lastPart = <ConstantMapEntry>[]);
    }
    if (!evaluator.hasPrimitiveEqual(key)) {
      return evaluator.createErrorConstant(
          keyContext,
          templateConstEvalKeyImplementsEqual.withArguments(
              key, evaluator.isNonNullableByDefault));
    }
    bool unseenKey = seenKeys.add(key);
    if (!unseenKey) {
      return evaluator.createErrorConstant(
          keyContext,
          templateConstEvalDuplicateKey.withArguments(
              key, evaluator.isNonNullableByDefault));
    }
    if (evaluator.evaluationMode == EvaluationMode.agnostic) {
      Constant weakKey = evaluator._weakener.visitConstant(key) ?? key;
      bool weakUnseenKey = weakSeenKeys.add(weakKey);
      if (unseenKey != weakUnseenKey) {
        return evaluator.createErrorConstant(
            keyContext, messageNonAgnosticConstant);
      }
    }
    Constant key2 = evaluator.ensureIsSubtype(key, keyType, keyContext);
    if (key2 is AbortConstant) return key2;
    Constant value2 = evaluator.ensureIsSubtype(value, valueType, valueContext);
    if (value2 is AbortConstant) return value2;
    lastPart.add(new ConstantMapEntry(key2, value2));
    return null;
  }

  Constant build() {
    if (parts.length == 1) {
      // Fully evaluated
      return evaluator
          .lowerMapConstant(new MapConstant(keyType, valueType, parts.single));
    }
    List<Expression> maps = <Expression>[];
    for (Object part in parts) {
      if (part is List<ConstantMapEntry>) {
        if (part.isEmpty) continue;
        maps.add(
            new ConstantExpression(new MapConstant(keyType, valueType, part)));
      } else if (part is Constant) {
        maps.add(evaluator.extract(part));
      } else {
        throw 'Non-constant in constant map';
      }
    }
    return evaluator.unevaluated(original,
        new MapConcatenation(maps, keyType: keyType, valueType: valueType));
  }
}
