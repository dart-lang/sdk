// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'ast_model.dart';
import 'visitor_generator.dart';

Uri computeEquivalenceUri(Uri repoDir) {
  return repoDir.resolve('pkg/kernel/lib/src/equivalence.dart');
}

Future<void> main(List<String> args) async {
  Uri output = args.isEmpty
      ? computeEquivalenceUri(Uri.base)
      : new File(args[0]).absolute.uri;
  String result = await generateAstEquivalence(Uri.base);
  new File.fromUri(output).writeAsStringSync(result);
}

Future<String> generateAstEquivalence(Uri repoDir, [AstModel? astModel]) async {
  astModel ??= await deriveAstModel(repoDir);
  return generateVisitor(astModel, new EquivalenceVisitorStrategy());
}

class EquivalenceVisitorStrategy extends Visitor1Strategy {
  Map<AstClass, String> _classStrategyMembers = {};
  Map<AstField, String> _fieldStrategyMembers = {};

  EquivalenceVisitorStrategy();

  @override
  String get generatorCommand =>
      'dart pkg/front_end/tool/generate_ast_equivalence.dart';

  @override
  String get argumentType => 'Node';

  @override
  String get argumentName => 'other';

  @override
  String get returnType => 'bool';

  @override
  String get visitorName => 'EquivalenceVisitor';

  String get strategyName => 'EquivalenceStrategy';

  String get internalCheckValues => '_checkValues';

  String get checkValues => 'checkValues';

  String get matchValues => 'matchValues';

  String get internalCheckNodes => '_checkNodes';

  String get checkNodes => 'checkNodes';

  String get shallowMatchNodes => 'shallowMatchNodes';

  String get deepMatchNodes => 'deepMatchNodes';

  String get internalCheckReferences => '_checkReferences';

  String get checkReferences => 'checkReferences';

  String get matchReferences => 'matchReferences';

  String get deepMatchReferences => 'deeplyMatchReferences';

  String get matchNamedNodes => 'matchNamedNodes';

  String get assumeReferences => 'assumeReferences';

  String get checkAssumedReferences => 'checkAssumedReferences';

  String get checkDeclarations => 'checkDeclarations';

  String get internalCheckDeclarations => '_checkDeclarations';

  String get shallowMatchDeclarations => 'matchDeclarations';

  String get deepMatchDeclarations => 'deepMatchDeclarations';

  String get assumeDeclarations => 'assumeDeclarations';

  String get checkAssumedDeclarations => 'checkAssumedDeclarations';

  String get checkLists => 'checkLists';

  String get matchLists => 'matchLists';

  String get checkSets => 'checkSets';

  String get matchSets => 'matchSets';

  String get checkMaps => 'checkMaps';

  String get matchMaps => 'matchMaps';

  String get checkingState => '_checkingState';

  String get resultOnInequivalence => 'resultOnInequivalence';

  String get registerInequivalence => 'registerInequivalence';

  String classCheckName(AstClass astClass) => 'check${astClass.name}';

  String fieldCheckName(AstField field) =>
      'check${field.astClass.name}_${field.name}';

  /// Compute the expression code for shallow matching two values of type
  /// [fieldType].
  ///
  /// Shallow matching is used to pair value when checking sets and maps. The
  /// checking doesn't traverse the AST deeply and inequivalences are not
  /// registered.
  ///
  /// [prefix] is used as the receiver of the invocation.
  String computeMatchingHelper(FieldType fieldType, [String prefix = '']) {
    String thisName = 'a';
    String otherName = 'b';
    switch (fieldType.kind) {
      case AstFieldKind.value:
        return '$prefix$matchValues';
      case AstFieldKind.node:
        return '$prefix$shallowMatchNodes';
      case AstFieldKind.reference:
        return '$prefix$matchReferences';
      case AstFieldKind.use:
        return '$prefix$shallowMatchDeclarations';
      case AstFieldKind.list:
        ListFieldType listFieldType = fieldType as ListFieldType;
        String elementEquivalence =
            computeMatchingHelper(listFieldType.elementType);
        return '($thisName, $otherName) => $prefix$matchLists('
            '$thisName, $otherName, $elementEquivalence)';
      case AstFieldKind.set:
        SetFieldType setFieldType = fieldType as SetFieldType;
        String elementMatching =
            computeMatchingHelper(setFieldType.elementType);
        String elementEquivalence =
            computeEquivalenceHelper(setFieldType.elementType);
        return '($thisName, $otherName) => $prefix$checkSets('
            '$thisName, $otherName, $elementMatching, $elementEquivalence)';
      case AstFieldKind.map:
        MapFieldType mapFieldType = fieldType as MapFieldType;
        String keyMatching = computeMatchingHelper(mapFieldType.keyType);
        String keyEquivalence = computeEquivalenceHelper(mapFieldType.keyType);
        String valueEquivalence =
            computeEquivalenceHelper(mapFieldType.valueType);
        return '($thisName,  $otherName) => $prefix$checkMaps('
            '$thisName, $otherName, $keyMatching, '
            '$keyEquivalence, $valueEquivalence)';
      case AstFieldKind.utility:
        StringBuffer sb = new StringBuffer();
        UtilityFieldType utilityFieldType = fieldType as UtilityFieldType;
        registerAstClassEquivalence(utilityFieldType.astClass);
        sb.writeln('''($thisName, $otherName, _) {
    if (identical($thisName, $otherName)) return true;
    if ($thisName is! ${utilityFieldType.astClass.name}) return false;
    if ($otherName is! ${utilityFieldType.astClass.name}) return false;
    return ${classCheckName(utilityFieldType.astClass)}(
        visitor,
        $thisName,
        $otherName);
  }''');
        return sb.toString();
    }
  }

  /// Computes the expression code for checking the equivalence of two fields
  /// of type [fieldType].
  ///
  /// Checking is used to check the AST for equivalence and inequivalences are
  /// registered.
  ///
  /// [prefix] is used as the receiver of the invocation.
  String computeEquivalenceHelper(FieldType fieldType, [String prefix = '']) {
    String thisName = 'a';
    String otherName = 'b';
    switch (fieldType.kind) {
      case AstFieldKind.value:
        return '$prefix$checkValues';
      case AstFieldKind.node:
        return '$prefix$checkNodes';
      case AstFieldKind.reference:
        return '$prefix$checkReferences';
      case AstFieldKind.use:
        return '$prefix$checkDeclarations';
      case AstFieldKind.list:
        ListFieldType listFieldType = fieldType as ListFieldType;
        String elementEquivalence =
            computeEquivalenceHelper(listFieldType.elementType);
        return '($thisName, $otherName) => $prefix$checkLists('
            '$thisName, $otherName, $elementEquivalence)';
      case AstFieldKind.set:
        SetFieldType setFieldType = fieldType as SetFieldType;
        String elementMatching =
            computeMatchingHelper(setFieldType.elementType);
        String elementEquivalence =
            computeEquivalenceHelper(setFieldType.elementType);
        return '($thisName, $otherName) => $prefix$checkSets('
            '$thisName, $otherName, $elementMatching, $elementEquivalence)';
      case AstFieldKind.map:
        MapFieldType mapFieldType = fieldType as MapFieldType;
        String keyMatching = computeMatchingHelper(mapFieldType.keyType);
        String keyEquivalence = computeEquivalenceHelper(mapFieldType.keyType);
        String valueEquivalence =
            computeEquivalenceHelper(mapFieldType.valueType);
        return '($thisName, $otherName) => $prefix$checkMaps('
            '$thisName, $otherName, $keyMatching, '
            '$keyEquivalence, $valueEquivalence)';
      case AstFieldKind.utility:
        StringBuffer sb = new StringBuffer();
        UtilityFieldType utilityFieldType = fieldType as UtilityFieldType;
        registerAstClassEquivalence(utilityFieldType.astClass);
        sb.writeln('''($thisName, $otherName, _) {
    if (identical($thisName, $otherName)) return true;
    if ($thisName is! ${utilityFieldType.astClass.name}) return false;
    if ($otherName is! ${utilityFieldType.astClass.name}) return false;
    return ${classCheckName(utilityFieldType.astClass)}(
        visitor,
        $thisName,
        $otherName);
  }''');
        return sb.toString();
    }
  }

  /// Registers that a strategy method is needed for checking [astClass].
  ///
  /// If the method has not already been generated, it is generated and stored
  /// in [_classStrategyMembers].
  void registerAstClassEquivalence(AstClass astClass) {
    if (_classStrategyMembers.containsKey(astClass)) return;

    String thisName = 'node';
    String otherName = 'other';
    StringBuffer classStrategy = new StringBuffer();
    classStrategy.writeln('''
  bool ${classCheckName(astClass)}(
      $visitorName visitor,
      ${astClass.name}? $thisName,
      Object? $otherName) {''');

    classStrategy.writeln('''
    if (identical($thisName, $otherName)) return true;
    if ($thisName is! ${astClass.name}) return false;
    if ($otherName is! ${astClass.name}) return false;''');
    if (astClass.kind == AstClassKind.named) {
      classStrategy.writeln('''
    if (!visitor.$matchNamedNodes($thisName, $otherName)) {
      return false;
    }''');
    } else if (astClass.kind == AstClassKind.declarative) {
      classStrategy.writeln('''
    if (!visitor.$checkDeclarations($thisName, $otherName, '')) {
      return false;
    }''');
    }

    if (astClass.kind != AstClassKind.utilityAsStructure) {
      classStrategy.writeln('''
    visitor.pushNodeState($thisName, $otherName);''');
    }
    classStrategy.writeln('''
    bool result = true;''');
    for (AstField field in astClass.fields.values) {
      registerAstFieldEquivalence(field);
      classStrategy.writeln('''
    if (!${fieldCheckName(field)}(visitor, $thisName, $otherName)) {
      result = visitor.$resultOnInequivalence;
    }''');
    }

    if (astClass.kind != AstClassKind.utilityAsStructure) {
      classStrategy.writeln('''
    visitor.popState();''');
    }

    classStrategy.writeln('''
    return result;
  }''');

    _classStrategyMembers[astClass] = classStrategy.toString();
  }

  /// Registers that a strategy method is needed for checking [field] in
  /// [astClass].
  ///
  /// If the method has not already been generated, it is generated and stored
  /// in [_fieldStrategyMembers].
  void registerAstFieldEquivalence(AstField field) {
    if (_fieldStrategyMembers.containsKey(field)) return;

    AstClass astClass = field.astClass;
    String thisName = 'node';
    String otherName = 'other';
    StringBuffer fieldStrategy = new StringBuffer();
    fieldStrategy.writeln('''
  bool ${fieldCheckName(field)}(
      $visitorName visitor,
      ${astClass.name} $thisName,
      ${astClass.name} $otherName) {''');
    if (field.parentField != null) {
      registerAstFieldEquivalence(field.parentField!);
      fieldStrategy.writeln('''
    return ${fieldCheckName(field.parentField!)}(
        visitor, $thisName, $otherName);''');
    } else {
      switch (field.type.kind) {
        case AstFieldKind.value:
          fieldStrategy.writeln('''
    return visitor.$checkValues(
        $thisName.${field.name},
        $otherName.${field.name},
        '${field.name}');''');
          break;
        case AstFieldKind.node:
          fieldStrategy.writeln('''
    return visitor.$checkNodes(
        $thisName.${field.name},
        $otherName.${field.name},
        '${field.name}');''');
          break;
        case AstFieldKind.reference:
          fieldStrategy.writeln('''
    return visitor.$checkReferences(
        $thisName.${field.name},
        $otherName.${field.name},
        '${field.name}');''');
          break;
        case AstFieldKind.use:
          fieldStrategy.writeln('''
    return visitor.$checkDeclarations(
        $thisName.${field.name},
        $otherName.${field.name},
        '${field.name}');''');
          break;
        case AstFieldKind.list:
          ListFieldType listFieldType = field.type as ListFieldType;
          fieldStrategy.writeln('''
    return visitor.$checkLists(
        $thisName.${field.name},
        $otherName.${field.name},
        ${computeEquivalenceHelper(listFieldType.elementType, 'visitor.')},
        '${field.name}');''');
          break;
        case AstFieldKind.set:
          SetFieldType setFieldType = field.type as SetFieldType;
          fieldStrategy.writeln('''
    return visitor.$checkSets(
        $thisName.${field.name},
        $otherName.${field.name},
        ${computeMatchingHelper(setFieldType.elementType, 'visitor.')},
        ${computeEquivalenceHelper(setFieldType.elementType, 'visitor.')},
        '${field.name}');''');
          break;
        case AstFieldKind.map:
          MapFieldType mapFieldType = field.type as MapFieldType;
          fieldStrategy.writeln('''
    return visitor.$checkMaps(
        $thisName.${field.name},
        $otherName.${field.name},
        ${computeMatchingHelper(mapFieldType.keyType, 'visitor.')},
        ${computeEquivalenceHelper(mapFieldType.keyType, 'visitor.')},
        ${computeEquivalenceHelper(mapFieldType.valueType, 'visitor.')},
        '${field.name}');''');
          break;
        case AstFieldKind.utility:
          UtilityFieldType utilityFieldType = field.type as UtilityFieldType;
          registerAstClassEquivalence(utilityFieldType.astClass);
          fieldStrategy.writeln('''
    '${field.name}';
    return ${classCheckName(utilityFieldType.astClass)}(
        visitor,
        $thisName.${field.name},
        $otherName.${field.name});''');
          break;
      }
    }
    fieldStrategy.writeln('''
  }''');
    _fieldStrategyMembers[field] = fieldStrategy.toString();
  }

  @override
  void handleVisit(AstModel astModel, AstClass astClass, StringBuffer sb) {
    registerAstClassEquivalence(astClass);
    sb.writeln('''
    return strategy.${classCheckName(astClass)}(
        this, node, $argumentName);''');
  }

  @override
  void handleVisitReference(
      AstModel astModel, AstClass astClass, StringBuffer sb) {
    sb.writeln('''
    return false;''');
  }

  @override
  void generateHeader(AstModel astModel, StringBuffer sb) {
    sb.writeln('''
$preamble

import 'package:kernel/ast.dart';
import 'package:kernel/src/printer.dart';
import 'union_find.dart';

part 'equivalence_helpers.dart';

/// Visitor that uses a $strategyName to compute AST node equivalence.
///
/// The visitor hold a current state that collects found inequivalences and
/// current assumptions. The current state has two modes. In the asserting mode,
/// the default, inequivalences are registered when found. In the non-asserting
/// mode, inequivalences are _not_ registered. The latter is used to compute
/// equivalences in sandboxed state, for instance to determine which elements
/// to pair when checking equivalence of two sets.
class $visitorName$visitorTypeParameters
    implements Visitor1<$returnType, $argumentType> {
  final $strategyName strategy;

  $visitorName({
      this.strategy = const $strategyName()});
''');
  }

  @override
  void generateFooter(AstModel astModel, StringBuffer sb) {
    sb.writeln('''
  /// Returns `true` if [a] and [b] are identical or equal.
  bool $internalCheckValues<T>(T? a, T? b) {
    return identical(a, b) || a == b;
  }

  /// Returns `true` if [a] and [b] are identical or equal and registers the
  /// inequivalence otherwise.
  bool $checkValues<T>(T? a, T? b, String propertyName) {
    bool result = $internalCheckValues(a, b);
    if (!result) {
      registerInequivalence(
          propertyName, 'Values \${a} and \${b} are not equivalent');
    }
    return result;
  }

  /// Returns `true` if [a] and [b] are identical or equal. Inequivalence is
  /// _not_ registered.
  bool $matchValues<T>(T? a, T? b) {
    return $internalCheckValues(a, b);
  }

  /// Cache of Constants compares and the results.
  /// This avoids potential exponential blowup when comparing ASTs
  /// that contain Constants.
  Map<Constant, Map<dynamic, bool>>? _constantCache;

  /// Returns `true` if [a] and [b] are equivalent.
  bool $internalCheckNodes<T extends Node>(T? a, T? b) {
    if (identical(a, b)) return true;
    if (a == null || b == null) {
      return false;
    } else {
      if (a is Constant) {
        Map<Constant, Map<dynamic, bool>> cacheFrom = _constantCache ??= {};
        Map<dynamic, bool> cacheTo = cacheFrom[a] ??= {};
        bool? previousResult = cacheTo[b];
        if (previousResult != null) return previousResult;
        bool result = a.accept1(this, b);
        cacheTo[b] = result;
        return result;
      }
      return a.accept1(this, b);
    }
  }

  /// Returns `true` if [a] and [b] are equivalent, as defined by the current
  /// strategy, and registers the inequivalence otherwise.
  bool $checkNodes<T extends Node>(T? a, T? b,
      [String propertyName = '']) {
    $checkingState.pushPropertyState(propertyName);
    bool result = $internalCheckNodes(a, b);
    $checkingState.popState();
    if (!result) {
      $registerInequivalence(
          propertyName, 'Inequivalent nodes\\n1: \${a}\\n2: \${b}');
    }
    return result;
  }

  /// Returns `true` if [a] and [b] are identical or equal. Inequivalence is
  /// _not_ registered.
  bool $shallowMatchNodes<T extends Node>(T? a, T? b) {
    return $internalCheckValues(a, b);
  }

  /// Returns `true` if [a] and [b] are equivalent, as defined by the current
  /// strategy. Inequivalence is _not_ registered.
  bool $deepMatchNodes<T extends Node>(T? a, T? b) {
    CheckingState oldState = $checkingState;
    $checkingState = $checkingState.toMatchingState();
    bool result = $checkNodes(a, b);
    $checkingState = oldState;
    return result;
  }

  /// Returns `true` if [a] and [b] are equivalent, either by existing
  /// assumption or as defined by their corresponding canonical names.
  /// Inequivalence is _not_ registered.
  bool $matchNamedNodes(NamedNode? a, NamedNode? b) {
    return identical(a, b) ||
        a == null ||
        b == null ||
        checkAssumedReferences(a.reference, b.reference) ||
        new ReferenceName.fromNamedNode(a) ==
            new ReferenceName.fromNamedNode(b);
  }

  /// Returns `true` if [a] and [b] are currently assumed to be equivalent.
  bool $checkAssumedReferences(Reference? a, Reference? b) {
    return $checkingState.$checkAssumedReferences(a, b);
  }

  /// Assume that [a] and [b] are equivalent, if possible.
  ///
  /// Returns `true` if [a] and [b] could be assumed to be equivalent. This
  /// would not be the case if [a] xor [b] is `null`.
  bool $assumeReferences(Reference? a, Reference? b) {
    return $checkingState.$assumeReferences(a, b);
  }

  /// Returns `true` if [a] and [b] are equivalent, either by existing
  /// assumption or as defined by their corresponding canonical names.
  /// Inequivalence is _not_ registered.
  bool $matchReferences(Reference? a, Reference? b) {
    return identical(a, b) ||
        checkAssumedReferences(a, b) ||
        ReferenceName.fromReference(a) ==
            ReferenceName.fromReference(b);
  }

  /// Returns `true` if [a] and [b] are equivalent, either by their
  /// corresponding canonical names or by assumption. Inequivalence is _not_
  /// registered.
  bool $internalCheckReferences(Reference? a, Reference? b) {
    if (identical(a, b)) {
      return true;
    } else if (a == null || b == null) {
      return false;
    } else if ($matchReferences(a, b)) {
      return true;
    } else if ($checkAssumedReferences(a, b)) {
      return true;
    } else {
      return false;
    }
  }

  /// Returns `true` if [a] and [b] are equivalent, either by their
  /// corresponding canonical names or by assumption. Inequivalence is _not_
  /// registered.
  bool $deepMatchReferences(Reference? a, Reference? b) {
    CheckingState oldState = $checkingState;
    $checkingState = $checkingState.toMatchingState();
    bool result = $checkReferences(a, b);
    $checkingState = oldState;
    return result;
  }

  /// Returns `true` if [a] and [b] are equivalent, either by their
  /// corresponding canonical names or by assumption, and registers the
  /// inequivalence otherwise.
  bool $checkReferences(
      Reference? a,
      Reference? b,
      [String propertyName = '']) {
    bool result = $internalCheckReferences(a, b);
    if (!result) {
      $registerInequivalence(
          propertyName, 'Inequivalent references:\\n1: \${a}\\n2: \${b}');
    }
    return result;
  }

  /// Returns `true` if declarations [a] and [b] are currently assumed to be
  /// equivalent.
  bool $checkAssumedDeclarations(dynamic a, dynamic b) {
    return $checkingState.$checkAssumedDeclarations(a, b);
  }

  /// Assume that [a] and [b] are equivalent, if possible.
  ///
  /// Returns `true` if [a] and [b] could be assumed to be equivalent. This
  /// would not be the case if [a] is already assumed to be equivalent to
  /// another declaration.
  bool $assumeDeclarations(dynamic a, dynamic b) {
    return $checkingState.$assumeDeclarations(a, b);
  }

  bool $shallowMatchDeclarations(dynamic a, dynamic b) {''');

    for (AstClass cls in astModel.declarativeClasses) {
      if (cls.declarativeName != null) {
        sb.write('''
    if (a is ${cls.name}) {
      return b is ${cls.name} &&
          a.${cls.declarativeName} == b.${cls.declarativeName};
    }
''');
      } else {
        sb.write('''
    if (a is ${cls.name}) {
      return b is ${cls.name};
    }
''');
      }
    }
    try {
      try {
        try {
          sb.writeln('''
          return false;
  }

  bool $internalCheckDeclarations(dynamic a, dynamic b) {
          if (identical(a, b)) {
            return true;
          } else if (a == null || b == null) {
            return false;
          } else if ($checkAssumedDeclarations(a, b)) {
            return true;
          } else if ($shallowMatchDeclarations(a, b)) {
            return $assumeDeclarations(a, b);
          } else {
            return false;
          }
  }

  bool $deepMatchDeclarations(dynamic a, dynamic b) {
          CheckingState oldState = $checkingState;
          $checkingState = $checkingState.toMatchingState();
          bool result = $checkDeclarations(a, b);
          $checkingState = oldState;
          return result;
  }

  bool $checkDeclarations(dynamic a, dynamic b,
            [String propertyName = '']) {
          bool result = $internalCheckDeclarations(a, b);
          if (!result) {
            result = $assumeDeclarations(a, b);
          }
          if (!result) {
            $registerInequivalence(
                propertyName, 'Declarations \${a} and \${b} are not equivalent');
          }
          return result;
  }

  /// Returns `true` if lists [a] and [b] are equivalent, using
  /// [equivalentValues] to determine element-wise equivalence.
  ///
  /// If run in a checking state, the [propertyName] is used for registering
  /// inequivalences.
  bool $checkLists<E>(
            List<E>? a,
            List<E>? b,
            bool Function(E?, E?, String) equivalentValues,
            [String propertyName = '']) {
          if (identical(a, b)) return true;
          if (a == null || b == null) return false;
          if (a.length != b.length) {
            $registerInequivalence(
              '\${propertyName}.length', 'Lists \${a} and \${b} are not equivalent');
            return false;
          }
          for (int i = 0; i < a.length; i++) {
            if (!equivalentValues(a[i], b[i], '\${propertyName}[\${i}]')) {
              return false;
            }
          }
          return true;
  }

  /// Returns `true` if lists [a] and [b] are equivalent, using
  /// [equivalentValues] to determine element-wise equivalence.
  ///
  /// Inequivalence is _not_ registered.
  bool $matchLists<E>(
            List<E>? a,
            List<E>? b,
            bool Function(E?, E?, String) equivalentValues) {
          CheckingState oldState = $checkingState;
          $checkingState = $checkingState.toMatchingState();
          bool result = $checkLists(a, b, equivalentValues);
          $checkingState = oldState;
          return result;
  }

  /// Returns `true` if sets [a] and [b] are equivalent, using
  /// [matchingValues] to determine which elements that should be checked for
  /// element-wise equivalence using [equivalentValues].
  ///
  /// If run in a checking state, the [propertyName] is used for registering
  /// inequivalences.
  bool $checkSets<E>(
            Set<E>? a,
            Set<E>? b,
            bool Function(E?, E?) matchingValues,
            bool Function(E?, E?, String) equivalentValues,
            [String propertyName = '']) {
          if (identical(a, b)) return true;
          if (a == null || b == null) return false;
          if (a.length != b.length) {
            $registerInequivalence(
                '\${propertyName}.length', 'Sets \${a} and \${b} are not equivalent');
            return false;
          }
          b = b.toSet();
          for (E aValue in a) {
            bool hasFoundValue = false;
            E? foundValue;
            for (E bValue in b) {
              if (matchingValues(aValue, bValue)) {
                foundValue = bValue;
                hasFoundValue = true;
                if (!equivalentValues(aValue, bValue,
                    '\${propertyName}[\${aValue}]')) {
                  $registerInequivalence(
                      '\${propertyName}[\${aValue}]',
                      'Elements \${aValue} and \${bValue} are not equivalent');
                  return false;
                }
                break;
              }
            }
            if (hasFoundValue) {
              b.remove(foundValue);
            } else {
              $registerInequivalence(
                  '\${propertyName}[\${aValue}]',
                  'Sets \${a} and \${b} are not equivalent, no equivalent value '
                  'found for \$aValue');
              return false;
            }
          }
          return true;
  }

  /// Returns `true` if sets [a] and [b] are equivalent, using
  /// [matchingValues] to determine which elements that should be checked for
  /// element-wise equivalence using [equivalentValues].
  ///
  /// Inequivalence is _not_registered.
  bool $matchSets<E>(
            Set<E>? a,
            Set<E>? b,
            bool Function(E?, E?) matchingValues,
            bool Function(E?, E?, String) equivalentValues) {
          CheckingState oldState = $checkingState;
          $checkingState = $checkingState.toMatchingState();
          bool result = $checkSets(a, b, matchingValues, equivalentValues);
          $checkingState = oldState;
          return result;
  }

  /// Returns `true` if maps [a] and [b] are equivalent, using
  /// [matchingKeys] to determine which entries that should be checked for
  /// entry-wise equivalence using [equivalentKeys] and [equivalentValues] to
  /// determine key and value equivalences, respectively.
  ///
  /// If run in a checking state, the [propertyName] is used for registering
  /// inequivalences.
  bool $checkMaps<K, V>(
            Map<K, V>? a,
            Map<K, V>? b,
            bool Function(K?, K?) matchingKeys,
            bool Function(K?, K?, String) equivalentKeys,
            bool Function(V?, V?, String) equivalentValues,
            [String propertyName = '']) {
          if (identical(a, b)) return true;
          if (a == null || b == null) return false;
          if (a.length != b.length) {
            $registerInequivalence(
              '\${propertyName}.length',
              'Maps \${a} and \${b} are not equivalent');
            return false;
          }
          Set<K> bKeys = b.keys.toSet();
          for (K aKey in a.keys) {
            bool hasFoundKey = false;
            K? foundKey;
            for (K bKey in bKeys) {
              if (matchingKeys(aKey, bKey)) {
                foundKey = bKey;
                hasFoundKey = true;
                if (!equivalentKeys(aKey, bKey, '\${propertyName}[\${aKey}]')) {
                  $registerInequivalence(
                      '\${propertyName}[\${aKey}]',
                      'Keys \${aKey} and \${bKey} are not equivalent');
                  return false;
                }
                break;
              }
            }
            if (hasFoundKey) {
              bKeys.remove(foundKey);
              if (!equivalentValues(a[aKey], b[foundKey],
                  '\${propertyName}[\${aKey}]')) {
                return false;
              }
            } else {
              $registerInequivalence(
                '\${propertyName}[\${aKey}]',
                'Maps \${a} and \${b} are not equivalent, no equivalent key '
                    'found for \$aKey');
              return false;
            }
          }
          return true;
  }

  /// Returns `true` if maps [a] and [b] are equivalent, using
  /// [matchingKeys] to determine which entries that should be checked for
  /// entry-wise equivalence using [equivalentKeys] and [equivalentValues] to
  /// determine key and value equivalences, respectively.
  ///
  /// Inequivalence is _not_ registered.
  bool $matchMaps<K, V>(
            Map<K, V>? a,
            Map<K, V>? b,
            bool Function(K?, K?) matchingKeys,
            bool Function(K?, K?, String) equivalentKeys,
            bool Function(V?, V?, String) equivalentValues) {
          CheckingState oldState = $checkingState;
          $checkingState = $checkingState.toMatchingState();
          bool result = $checkMaps(a, b, matchingKeys, equivalentKeys,
              equivalentValues);
          $checkingState = oldState;
          return result;
  }

  /// The current state of the visitor.
  ///
  /// This holds the current assumptions, found inequivalences, and whether
  /// inequivalences are currently registered.
  CheckingState $checkingState = new CheckingState();

  /// Runs [f] in a new state that holds all current assumptions. If
  /// [isAsserting] is `true`, inequivalences are registered. Returns the
  /// collected inequivalences.
  ///
  /// If [f] returns `false`, the returned result is marked as having
  /// inequivalences even when non have being registered.
  EquivalenceResult inSubState(bool Function() f, {bool isAsserting = false}) {
    CheckingState _oldState = $checkingState;
    $checkingState = $checkingState.createSubState(isAsserting: isAsserting);
    bool hasInequivalences = f();
    EquivalenceResult result =
        $checkingState.toResult(hasInequivalences: hasInequivalences);
    $checkingState = _oldState;
    return result;
  }

  /// Registers that the visitor enters the property named [propertyName] and
  /// the currently visited node.
  void pushPropertyState(String propertyName) {
    $checkingState.pushPropertyState(propertyName);
  }

  /// Registers that the visitor enters nodes [a] and [b].
  void pushNodeState(Node a, Node b) {
    $checkingState.pushNodeState(a, b);
  }

  /// Register that the visitor leave the current node or property.
  void popState() {
    $checkingState.popState();
  }

  /// Returns the value used as the result for property inequivalences.
  ///
  /// When inequivalences are currently registered, this is `true`, so that the
  /// visitor will continue find inequivalences that are not directly related.
  ///
  /// An example is finding several child inequivalences on otherwise equivalent
  /// nodes, like finding inequivalences deeply in the members of the second
  /// library of a component even when inequivalences deeply in the members of
  /// the first library. Had the return value been `false`, signaling that the
  /// first libraries were inequivalent, which they technically are, given that
  /// the contain inequivalent subnodes, the visitor would have stopped short in
  /// checking the list of libraries, and the inequivalences in the second
  /// library would not have been found.
  ///
  /// When inequivalences are _not_ currently registered, i.e. we are only
  /// interested in the true/false value of the equivalence test, `false` is
  /// used as the result value to stop the equivalence checking short.
  bool get $resultOnInequivalence =>
            $checkingState.$resultOnInequivalence;

  /// Registers an equivalence on the [propertyName] with a detailed description
  /// in [message].
  void $registerInequivalence(String propertyName, String message) {
          $checkingState.registerInequivalence(propertyName, message);
  }

  /// Returns the inequivalences found by the visitor.
  EquivalenceResult toResult() => $checkingState.toResult();

  ''');
        } catch (e, s) {
          print(s);
        }
      } catch (e, s) {
        print(s);
      }
    } catch (e, s) {
      print(s);
    }
    super.generateFooter(astModel, sb);
    sb.writeln('''
/// Checks [a] and [b] be for equivalence using [strategy].
///
/// Returns an [EquivalenceResult] containing the found inequivalences.
EquivalenceResult checkEquivalence(
    Node a,
    Node b,
    {$strategyName strategy = const $strategyName()}) {
  EquivalenceVisitor visitor = new EquivalenceVisitor(
      strategy: strategy);
  visitor.$checkNodes(a, b, 'root');
  return visitor.toResult();
}
''');

    sb.writeln('''
/// Strategy used for determining equivalence of AST nodes.
///
/// The strategy has a method for determining the equivalence of each AST node
/// class, and a method for determining the equivalence of each property on each
/// AST node class.
///
/// The base implementation enforces a full structural equivalence.
///
/// Custom strategies can be made by extending this strategy and override
/// methods where exceptions to the structural equivalence are needed.
class $strategyName {
  const $strategyName();
''');
    _classStrategyMembers.forEach((key, value) {
      sb.write(value);
    });
    _fieldStrategyMembers.forEach((key, value) {
      sb.write(value);
    });
    sb.writeln(r'''
}
''');
  }
}
