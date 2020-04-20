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
  void add(Expression element) {
    Constant constant = evaluator._evaluateSubexpression(element);
    if (evaluator.shouldBeUnevaluated) {
      parts.add(evaluator.unevaluated(
          element, makeLiteral([evaluator.extract(constant)])));
    } else {
      addConstant(constant, element);
    }
  }

  void addSpread(Expression spreadExpression) {
    Constant spread =
        evaluator.unlower(evaluator._evaluateSubexpression(spreadExpression));
    if (evaluator.shouldBeUnevaluated) {
      // Unevaluated spread
      parts.add(spread);
    } else if (spread == evaluator.nullConstant) {
      // Null spread
      evaluator.report(spreadExpression, messageConstEvalNullValue);
    } else {
      // Fully evaluated spread
      List<Constant> entries;
      if (spread is ListConstant) {
        entries = spread.entries;
      } else if (spread is SetConstant) {
        entries = spread.entries;
      } else {
        // Not list or set in spread
        return evaluator.report(
            spreadExpression, messageConstEvalNotListOrSetInSpread);
      }
      for (Constant entry in entries) {
        addConstant(entry, spreadExpression);
      }
    }
  }

  void addConstant(Constant constant, TreeNode context);

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
  void addConstant(Constant constant, TreeNode context) {
    List<Constant> lastPart;
    if (parts.last is List<Constant>) {
      lastPart = parts.last;
    } else {
      parts.add(lastPart = <Constant>[]);
    }
    lastPart.add(evaluator.ensureIsSubtype(constant, elementType, context));
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
  void addConstant(Constant constant, TreeNode context) {
    if (!evaluator.hasPrimitiveEqual(constant)) {
      evaluator.report(
          context,
          templateConstEvalElementImplementsEqual.withArguments(
              constant, evaluator.isNonNullableByDefault));
    }
    bool unseen = seen.add(constant);
    if (!unseen) {
      evaluator.report(
          context,
          templateConstEvalDuplicateElement.withArguments(
              constant, evaluator.isNonNullableByDefault));
    }
    if (evaluator.evaluationMode == EvaluationMode.agnostic) {
      Constant weakConstant =
          evaluator._weakener.visitConstant(constant) ?? constant;
      bool weakUnseen = weakSeen.add(weakConstant);
      if (unseen != weakUnseen) {
        evaluator.report(context, messageNonAgnosticConstant);
      }
    }

    List<Constant> lastPart;
    if (parts.last is List<Constant>) {
      lastPart = parts.last;
    } else {
      parts.add(lastPart = <Constant>[]);
    }
    lastPart.add(evaluator.ensureIsSubtype(constant, elementType, context));
  }

  @override
  Constant build() {
    if (parts.length == 1) {
      // Fully evaluated
      List<Constant> entries = parts.single;
      SetConstant result = new SetConstant(elementType, entries);
      if (evaluator.desugarSets) {
        final List<ConstantMapEntry> mapEntries =
            new List<ConstantMapEntry>(entries.length);
        for (int i = 0; i < entries.length; ++i) {
          mapEntries[i] =
              new ConstantMapEntry(entries[i], evaluator.nullConstant);
        }
        Constant map = evaluator.lowerMapConstant(new MapConstant(
            elementType, evaluator.typeEnvironment.nullType, mapEntries));
        return evaluator.lower(
            result,
            new InstanceConstant(
                evaluator.unmodifiableSetMap.enclosingClass.reference, [
              elementType
            ], <Reference, Constant>{
              evaluator.unmodifiableSetMap.reference: map
            }));
      } else {
        return evaluator.lowerSetConstant(result);
      }
    }
    List<Expression> sets = <Expression>[];
    for (Object part in parts) {
      if (part is List<Constant>) {
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
  void add(MapEntry element) {
    Constant key = evaluator._evaluateSubexpression(element.key);
    Constant value = evaluator._evaluateSubexpression(element.value);
    if (evaluator.shouldBeUnevaluated) {
      parts.add(evaluator.unevaluated(
          element.key,
          new MapLiteral(
              [new MapEntry(evaluator.extract(key), evaluator.extract(value))],
              isConst: true)));
    } else {
      addConstant(key, value, element.key, element.value);
    }
  }

  void addSpread(Expression spreadExpression) {
    Constant spread =
        evaluator.unlower(evaluator._evaluateSubexpression(spreadExpression));
    if (evaluator.shouldBeUnevaluated) {
      // Unevaluated spread
      parts.add(spread);
    } else if (spread == evaluator.nullConstant) {
      // Null spread
      evaluator.report(spreadExpression, messageConstEvalNullValue);
    } else {
      // Fully evaluated spread
      if (spread is MapConstant) {
        for (ConstantMapEntry entry in spread.entries) {
          addConstant(
              entry.key, entry.value, spreadExpression, spreadExpression);
        }
      } else {
        // Not map in spread
        return evaluator.report(
            spreadExpression, messageConstEvalNotMapInSpread);
      }
    }
  }

  void addConstant(Constant key, Constant value, TreeNode keyContext,
      TreeNode valueContext) {
    List<ConstantMapEntry> lastPart;
    if (parts.last is List<ConstantMapEntry>) {
      lastPart = parts.last;
    } else {
      parts.add(lastPart = <ConstantMapEntry>[]);
    }
    if (!evaluator.hasPrimitiveEqual(key)) {
      evaluator.report(
          keyContext,
          templateConstEvalKeyImplementsEqual.withArguments(
              key, evaluator.isNonNullableByDefault));
    }
    bool unseenKey = seenKeys.add(key);
    if (!unseenKey) {
      evaluator.report(
          keyContext,
          templateConstEvalDuplicateKey.withArguments(
              key, evaluator.isNonNullableByDefault));
    }
    if (evaluator.evaluationMode == EvaluationMode.agnostic) {
      Constant weakKey = evaluator._weakener.visitConstant(key) ?? key;
      bool weakUnseenKey = weakSeenKeys.add(weakKey);
      if (unseenKey != weakUnseenKey) {
        evaluator.report(keyContext, messageNonAgnosticConstant);
      }
    }
    lastPart.add(new ConstantMapEntry(
        evaluator.ensureIsSubtype(key, keyType, keyContext),
        evaluator.ensureIsSubtype(value, valueType, valueContext)));
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
