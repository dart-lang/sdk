// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Functions for asserting equivalence across serialization.

library dart2js.serialization.equivalence;

import '../common/resolution.dart';
import '../constants/expressions.dart';
import '../dart_types.dart';
import '../elements/elements.dart';
import '../elements/visitor.dart';
import '../universe/selector.dart';
import '../universe/use.dart';

/// Equality based equivalence function.
bool equality(a, b) => a == b;

/// Returns `true` if the elements in [a] and [b] are pair-wise equivalent
/// according to [elementEquivalence].
bool areListsEquivalent(List a, List b,
    [bool elementEquivalence(a, b) = equality]) {
  if (a.length != b.length) return false;
  for (int i = 0; i < a.length && i < b.length; i++) {
    if (!elementEquivalence(a[i], b[i])) {
      return false;
    }
  }
  return true;
}

/// Returns `true` if the elements in [a] and [b] are equivalent as sets using
/// [elementEquivalence] to determine element equivalence.
bool areSetsEquivalent(Iterable set1, Iterable set2,
    [bool elementEquivalence(a, b) = equality]) {
  Set remaining = set2.toSet();
  for (var element1 in set1) {
    bool found = false;
    for (var element2 in set2) {
      if (elementEquivalence(element1, element2)) {
        found = true;
        remaining.remove(element2);
        break;
      }
    }
    if (!found) {
      return false;
    }
  }
  return remaining.isEmpty;
}

/// Returns `true` if elements [a] and [b] are equivalent.
bool areElementsEquivalent(Element a, Element b) {
  if (identical(a, b)) return true;
  if (a == null || b == null) return false;
  return const ElementIdentityEquivalence().visit(a, b);
}

/// Returns `true` if types [a] and [b] are equivalent.
bool areTypesEquivalent(DartType a, DartType b) {
  if (identical(a, b)) return true;
  if (a == null || b == null) return false;
  return const TypeEquivalence().visit(a, b);
}

/// Returns `true` if constants [a] and [b] are equivalent.
bool areConstantsEquivalent(ConstantExpression exp1, ConstantExpression exp2) {
  if (identical(exp1, exp2)) return true;
  if (exp1 == null || exp2 == null) return false;
  return const ConstantEquivalence().visit(exp1, exp2);
}

/// Returns `true` if the lists of elements, [a] and [b], are equivalent.
bool areElementListsEquivalent(List<Element> a, List<Element> b) {
  return areListsEquivalent(a, b, areElementsEquivalent);
}

/// Returns `true` if the lists of types, [a] and [b], are equivalent.
bool areTypeListsEquivalent(List<DartType> a, List<DartType> b) {
  return areListsEquivalent(a, b, areTypesEquivalent);
}

/// Returns `true` if the lists of constants, [a] and [b], are equivalent.
bool areConstantListsEquivalent(
    List<ConstantExpression> a, List<ConstantExpression> b) {
  return areListsEquivalent(a, b, areConstantsEquivalent);
}

/// Returns `true` if the selectors [a] and [b] are equivalent.
bool areSelectorsEquivalent(Selector a, Selector b) {
  return a.kind == b.kind &&
      a.callStructure == b.callStructure &&
      areNamesEquivalent(a.memberName, b.memberName);
}

/// Returns `true` if the names [a] and [b] are equivalent.
bool areNamesEquivalent(Name a, Name b) {
  return a.text == b.text &&
      a.isSetter == b.isSetter &&
      areElementsEquivalent(a.library, b.library);
}

/// Returns `true` if the dynamic uses [a] and [b] are equivalent.
bool areDynamicUsesEquivalent(DynamicUse a, DynamicUse b) {
  return areSelectorsEquivalent(a.selector, b.selector);
}

/// Returns `true` if the static uses [a] and [b] are equivalent.
bool areStaticUsesEquivalent(StaticUse a, StaticUse b) {
  return a.kind == b.kind && areElementsEquivalent(a.element, b.element);
}

/// Returns `true` if the type uses [a] and [b] are equivalent.
bool areTypeUsesEquivalent(TypeUse a, TypeUse b) {
  return a.kind == b.kind && areTypesEquivalent(a.type, b.type);
}

/// Returns `true` if the list literal uses [a] and [b] are equivalent.
bool areListLiteralUsesEquivalent(ListLiteralUse a, ListLiteralUse b) {
  return areTypesEquivalent(a.type, b.type) &&
      a.isConstant == b.isConstant &&
      a.isEmpty == b.isEmpty;
}

/// Returns `true` if the map literal uses [a] and [b] are equivalent.
bool areMapLiteralUsesEquivalent(MapLiteralUse a, MapLiteralUse b) {
  return areTypesEquivalent(a.type, b.type) &&
      a.isConstant == b.isConstant &&
      a.isEmpty == b.isEmpty;
}

/// Strategy for testing equivalence.
///
/// Use this strategy to determine equivalence without failing on inequivalence.
class TestStrategy {
  const TestStrategy();

  bool test(var object1, var object2, String property, var value1, var value2) {
    return value1 == value2;
  }

  bool testLists(
      Object object1, Object object2, String property, List list1, List list2,
      [bool elementEquivalence(a, b) = equality]) {
    return areListsEquivalent(list1, list2, elementEquivalence);
  }

  bool testSets(
      var object1, var object2, String property, Iterable set1, Iterable set2,
      [bool elementEquivalence(a, b) = equality]) {
    return areSetsEquivalent(set1, set2, elementEquivalence);
  }

  bool testElements(Object object1, Object object2, String property,
      Element element1, Element element2) {
    return areElementsEquivalent(element1, element2);
  }

  bool testTypes(Object object1, Object object2, String property,
      DartType type1, DartType type2) {
    return areTypesEquivalent(type1, type2);
  }

  bool testConstants(Object object1, Object object2, String property,
      ConstantExpression exp1, ConstantExpression exp2) {
    return areConstantsEquivalent(exp1, exp2);
  }

  bool testTypeLists(Object object1, Object object2, String property,
      List<DartType> list1, List<DartType> list2) {
    return areTypeListsEquivalent(list1, list2);
  }

  bool testConstantLists(Object object1, Object object2, String property,
      List<ConstantExpression> list1, List<ConstantExpression> list2) {
    return areConstantListsEquivalent(list1, list2);
  }
}

/// Visitor that checks for equivalence of [Element]s.
class ElementIdentityEquivalence extends BaseElementVisitor<bool, Element> {
  final TestStrategy strategy;

  const ElementIdentityEquivalence([this.strategy = const TestStrategy()]);

  bool visit(Element element1, Element element2) {
    if (element1 == null && element2 == null) {
      return true;
    } else if (element1 == null || element2 == null) {
      return false;
    }
    element1 = element1.declaration;
    element2 = element2.declaration;
    if (element1 == element2) {
      return true;
    }
    return strategy.test(
            element1, element2, 'kind', element1.kind, element2.kind) &&
        element1.accept(this, element2);
  }

  @override
  bool visitElement(Element e, Element arg) {
    throw new UnsupportedError("Unsupported element $e");
  }

  @override
  bool visitLibraryElement(LibraryElement element1, LibraryElement element2) {
    return strategy.test(element1, element2, 'canonicalUri',
        element1.canonicalUri, element2.canonicalUri);
  }

  @override
  bool visitCompilationUnitElement(
      CompilationUnitElement element1, CompilationUnitElement element2) {
    return strategy.test(
            element1, element2, 'name', element1.name, element2.name) &&
        visit(element1.library, element2.library);
  }

  @override
  bool visitClassElement(ClassElement element1, ClassElement element2) {
    return strategy.test(
            element1, element2, 'name', element1.name, element2.name) &&
        visit(element1.library, element2.library);
  }

  bool checkMembers(Element element1, Element element2) {
    if (!strategy.test(
        element1, element2, 'name', element1.name, element2.name)) {
      return false;
    }
    if (element1.enclosingClass != null || element2.enclosingClass != null) {
      return visit(element1.enclosingClass, element2.enclosingClass);
    } else {
      return visit(element1.library, element2.library);
    }
  }

  @override
  bool visitFieldElement(FieldElement element1, FieldElement element2) {
    return checkMembers(element1, element2);
  }

  @override
  bool visitConstructorElement(
      ConstructorElement element1, ConstructorElement element2) {
    return checkMembers(element1, element2);
  }

  @override
  bool visitMethodElement(MethodElement element1, MethodElement element2) {
    return checkMembers(element1, element2);
  }

  @override
  bool visitGetterElement(GetterElement element1, GetterElement element2) {
    return checkMembers(element1, element2);
  }

  @override
  bool visitSetterElement(SetterElement element1, SetterElement element2) {
    return checkMembers(element1, element2);
  }

  @override
  bool visitLocalFunctionElement(
      LocalFunctionElement element1, LocalFunctionElement element2) {
    // TODO(johnniwinther): Define an equivalence on locals.
    return checkMembers(element1.memberContext, element2.memberContext);
  }

  bool visitAbstractFieldElement(
      AbstractFieldElement element1, AbstractFieldElement element2) {
    return checkMembers(element1, element2);
  }

  @override
  bool visitTypeVariableElement(
      TypeVariableElement element1, TypeVariableElement element2) {
    return strategy.test(
            element1, element2, 'name', element1.name, element2.name) &&
        visit(element1.typeDeclaration, element2.typeDeclaration);
  }

  @override
  bool visitTypedefElement(TypedefElement element1, TypedefElement element2) {
    return strategy.test(
            element1, element2, 'name', element1.name, element2.name) &&
        visit(element1.library, element2.library);
  }

  @override
  bool visitParameterElement(
      ParameterElement element1, ParameterElement element2) {
    return strategy.test(
            element1, element2, 'name', element1.name, element2.name) &&
        visit(element1.functionDeclaration, element2.functionDeclaration);
  }

  @override
  bool visitImportElement(ImportElement element1, ImportElement element2) {
    return visit(element1.importedLibrary, element2.importedLibrary) &&
        visit(element1.library, element2.library);
  }

  @override
  bool visitExportElement(ExportElement element1, ExportElement element2) {
    return visit(element1.exportedLibrary, element2.exportedLibrary) &&
        visit(element1.library, element2.library);
  }

  @override
  bool visitPrefixElement(PrefixElement element1, PrefixElement element2) {
    return strategy.test(
            element1, element2, 'name', element1.name, element2.name) &&
        visit(element1.library, element2.library);
  }
}

/// Visitor that checks for equivalence of [DartType]s.
class TypeEquivalence implements DartTypeVisitor<bool, DartType> {
  final TestStrategy strategy;

  const TypeEquivalence([this.strategy = const TestStrategy()]);

  bool visit(DartType type1, DartType type2) {
    return strategy.test(type1, type2, 'kind', type1.kind, type2.kind) &&
        type1.accept(this, type2);
  }

  @override
  bool visitDynamicType(DynamicType type, DynamicType other) => true;

  @override
  bool visitFunctionType(FunctionType type, FunctionType other) {
    return strategy.testTypeLists(type, other, 'parameterTypes',
            type.parameterTypes, other.parameterTypes) &&
        strategy.testTypeLists(type, other, 'optionalParameterTypes',
            type.optionalParameterTypes, other.optionalParameterTypes) &&
        strategy.testTypeLists(type, other, 'namedParameterTypes',
            type.namedParameterTypes, other.namedParameterTypes) &&
        strategy.testLists(type, other, 'namedParameters', type.namedParameters,
            other.namedParameters);
  }

  bool visitGenericType(GenericType type, GenericType other) {
    return strategy.testElements(
            type, other, 'element', type.element, other.element) &&
        strategy.testTypeLists(type, other, 'typeArguments', type.typeArguments,
            other.typeArguments);
  }

  @override
  bool visitMalformedType(MalformedType type, MalformedType other) => true;

  @override
  bool visitStatementType(StatementType type, StatementType other) {
    throw new UnsupportedError("Unsupported type: $type");
  }

  @override
  bool visitTypeVariableType(TypeVariableType type, TypeVariableType other) {
    return strategy.testElements(
        type, other, 'element', type.element, other.element);
  }

  @override
  bool visitVoidType(VoidType type, VoidType argument) => true;

  @override
  bool visitInterfaceType(InterfaceType type, InterfaceType other) {
    return visitGenericType(type, other);
  }

  @override
  bool visitTypedefType(TypedefType type, TypedefType other) {
    return visitGenericType(type, other);
  }
}

/// Visitor that checks for structural equivalence of [ConstantExpression]s.
class ConstantEquivalence
    implements ConstantExpressionVisitor<bool, ConstantExpression> {
  final TestStrategy strategy;

  const ConstantEquivalence([this.strategy = const TestStrategy()]);

  @override
  bool visit(ConstantExpression exp1, ConstantExpression exp2) {
    if (identical(exp1, exp2)) return true;
    return strategy.test(exp1, exp2, 'kind', exp1.kind, exp2.kind) &&
        exp1.accept(this, exp2);
  }

  @override
  bool visitBinary(
      BinaryConstantExpression exp1, BinaryConstantExpression exp2) {
    return strategy.test(
            exp1, exp2, 'operator', exp1.operator, exp2.operator) &&
        strategy.testConstants(exp1, exp2, 'left', exp1.left, exp2.left) &&
        strategy.testConstants(exp1, exp2, 'right', exp1.right, exp2.right);
  }

  @override
  bool visitConcatenate(
      ConcatenateConstantExpression exp1, ConcatenateConstantExpression exp2) {
    return strategy.testConstantLists(
        exp1, exp2, 'expressions', exp1.expressions, exp2.expressions);
  }

  @override
  bool visitConditional(
      ConditionalConstantExpression exp1, ConditionalConstantExpression exp2) {
    return strategy.testConstants(
            exp1, exp2, 'condition', exp1.condition, exp2.condition) &&
        strategy.testConstants(
            exp1, exp2, 'trueExp', exp1.trueExp, exp2.trueExp) &&
        strategy.testConstants(
            exp1, exp2, 'falseExp', exp1.falseExp, exp2.falseExp);
  }

  @override
  bool visitConstructed(
      ConstructedConstantExpression exp1, ConstructedConstantExpression exp2) {
    return strategy.testTypes(exp1, exp2, 'type', exp1.type, exp2.type) &&
        strategy.testElements(exp1, exp2, 'target', exp1.target, exp2.target) &&
        strategy.testConstantLists(
            exp1, exp2, 'arguments', exp1.arguments, exp2.arguments) &&
        strategy.test(exp1, exp2, 'callStructure', exp1.callStructure,
            exp2.callStructure);
  }

  @override
  bool visitFunction(
      FunctionConstantExpression exp1, FunctionConstantExpression exp2) {
    return strategy.testElements(
        exp1, exp2, 'element', exp1.element, exp2.element);
  }

  @override
  bool visitIdentical(
      IdenticalConstantExpression exp1, IdenticalConstantExpression exp2) {
    return strategy.testConstants(exp1, exp2, 'left', exp1.left, exp2.left) &&
        strategy.testConstants(exp1, exp2, 'right', exp1.right, exp2.right);
  }

  @override
  bool visitList(ListConstantExpression exp1, ListConstantExpression exp2) {
    return strategy.testTypes(exp1, exp2, 'type', exp1.type, exp2.type) &&
        strategy.testConstantLists(
            exp1, exp2, 'values', exp1.values, exp2.values);
  }

  @override
  bool visitMap(MapConstantExpression exp1, MapConstantExpression exp2) {
    return strategy.testTypes(exp1, exp2, 'type', exp1.type, exp2.type) &&
        strategy.testConstantLists(exp1, exp2, 'keys', exp1.keys, exp2.keys) &&
        strategy.testConstantLists(
            exp1, exp2, 'values', exp1.values, exp2.values);
  }

  @override
  bool visitNamed(NamedArgumentReference exp1, NamedArgumentReference exp2) {
    return strategy.test(exp1, exp2, 'name', exp1.name, exp2.name);
  }

  @override
  bool visitPositional(
      PositionalArgumentReference exp1, PositionalArgumentReference exp2) {
    return strategy.test(exp1, exp2, 'index', exp1.index, exp2.index);
  }

  @override
  bool visitSymbol(
      SymbolConstantExpression exp1, SymbolConstantExpression exp2) {
    // TODO: implement visitSymbol
    return true;
  }

  @override
  bool visitType(TypeConstantExpression exp1, TypeConstantExpression exp2) {
    return strategy.testTypes(exp1, exp2, 'type', exp1.type, exp2.type);
  }

  @override
  bool visitUnary(UnaryConstantExpression exp1, UnaryConstantExpression exp2) {
    return strategy.test(
            exp1, exp2, 'operator', exp1.operator, exp2.operator) &&
        strategy.testConstants(
            exp1, exp2, 'expression', exp1.expression, exp2.expression);
  }

  @override
  bool visitVariable(
      VariableConstantExpression exp1, VariableConstantExpression exp2) {
    return strategy.testElements(
        exp1, exp2, 'element', exp1.element, exp2.element);
  }

  @override
  bool visitBool(BoolConstantExpression exp1, BoolConstantExpression exp2) {
    return strategy.test(
        exp1, exp2, 'primitiveValue', exp1.primitiveValue, exp2.primitiveValue);
  }

  @override
  bool visitDouble(
      DoubleConstantExpression exp1, DoubleConstantExpression exp2) {
    return strategy.test(
        exp1, exp2, 'primitiveValue', exp1.primitiveValue, exp2.primitiveValue);
  }

  @override
  bool visitInt(IntConstantExpression exp1, IntConstantExpression exp2) {
    return strategy.test(
        exp1, exp2, 'primitiveValue', exp1.primitiveValue, exp2.primitiveValue);
  }

  @override
  bool visitNull(NullConstantExpression exp1, NullConstantExpression exp2) {
    return true;
  }

  @override
  bool visitString(
      StringConstantExpression exp1, StringConstantExpression exp2) {
    return strategy.test(
        exp1, exp2, 'primitiveValue', exp1.primitiveValue, exp2.primitiveValue);
  }

  @override
  bool visitBoolFromEnvironment(BoolFromEnvironmentConstantExpression exp1,
      BoolFromEnvironmentConstantExpression exp2) {
    return strategy.testConstants(exp1, exp2, 'name', exp1.name, exp2.name) &&
        strategy.testConstants(
            exp1, exp2, 'defaultValue', exp1.defaultValue, exp2.defaultValue);
  }

  @override
  bool visitIntFromEnvironment(IntFromEnvironmentConstantExpression exp1,
      IntFromEnvironmentConstantExpression exp2) {
    return strategy.testConstants(exp1, exp2, 'name', exp1.name, exp2.name) &&
        strategy.testConstants(
            exp1, exp2, 'defaultValue', exp1.defaultValue, exp2.defaultValue);
  }

  @override
  bool visitStringFromEnvironment(StringFromEnvironmentConstantExpression exp1,
      StringFromEnvironmentConstantExpression exp2) {
    return strategy.testConstants(exp1, exp2, 'name', exp1.name, exp2.name) &&
        strategy.testConstants(
            exp1, exp2, 'defaultValue', exp1.defaultValue, exp2.defaultValue);
  }

  @override
  bool visitStringLength(StringLengthConstantExpression exp1,
      StringLengthConstantExpression exp2) {
    return strategy.testConstants(
        exp1, exp2, 'expression', exp1.expression, exp2.expression);
  }

  @override
  bool visitDeferred(
      DeferredConstantExpression exp1, DeferredConstantExpression exp2) {
    // TODO: implement visitDeferred
    return true;
  }
}

/// Tests the equivalence of [impact1] and [impact2] using [strategy].
bool testResolutionImpactEquivalence(
    ResolutionImpact impact1, ResolutionImpact impact2,
    [TestStrategy strategy = const TestStrategy()]) {
  return strategy.testSets(impact1, impact2, 'constSymbolNames',
          impact1.constSymbolNames, impact2.constSymbolNames) &&
      strategy.testSets(
          impact1,
          impact2,
          'constantLiterals',
          impact1.constantLiterals,
          impact2.constantLiterals,
          areConstantsEquivalent) &&
      strategy.testSets(impact1, impact2, 'dynamicUses', impact1.dynamicUses,
          impact2.dynamicUses, areDynamicUsesEquivalent) &&
      strategy.testSets(
          impact1, impact2, 'features', impact1.features, impact2.features) &&
      strategy.testSets(impact1, impact2, 'listLiterals', impact1.listLiterals,
          impact2.listLiterals, areListLiteralUsesEquivalent) &&
      strategy.testSets(impact1, impact2, 'mapLiterals', impact1.mapLiterals,
          impact2.mapLiterals, areMapLiteralUsesEquivalent) &&
      strategy.testSets(impact1, impact2, 'staticUses', impact1.staticUses,
          impact2.staticUses, areStaticUsesEquivalent) &&
      strategy.testSets(impact1, impact2, 'typeUses', impact1.typeUses,
          impact2.typeUses, areTypeUsesEquivalent);
}
