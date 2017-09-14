// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Functions for asserting equivalence across serialization.

library dart2js.serialization.equivalence;

import '../closure.dart';
import '../common/resolution.dart';
import '../constants/expressions.dart';
import '../constants/values.dart';
import '../elements/resolution_types.dart';
import '../elements/elements.dart';
import '../elements/entities.dart';
import '../elements/modelx.dart';
import '../elements/jumps.dart';
import '../elements/names.dart';
import '../elements/types.dart';
import '../elements/visitor.dart';
import '../js_backend/backend_serialization.dart'
    show NativeBehaviorSerialization;
import '../native/native.dart' show NativeBehavior;
import '../resolution/access_semantics.dart';
import '../resolution/send_structure.dart';
import '../resolution/tree_elements.dart';
import 'package:front_end/src/fasta/scanner.dart';
import '../tree/nodes.dart';
import '../universe/selector.dart';
import '../universe/feature.dart';
import '../universe/use.dart';
import '../util/util.dart';
import 'resolved_ast_serialization.dart';

typedef bool Equivalence<E>(E a, E b, {TestStrategy strategy});

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
  for (dynamic element1 in set1) {
    bool found = false;
    for (dynamic element2 in set2) {
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

/// Returns `true` if the content of [map1] and [map2] is equivalent using
/// [keyEquivalence] and [valueEquivalence] to determine key/value equivalence.
bool areMapsEquivalent(Map map1, Map map2,
    [bool keyEquivalence(a, b) = equality,
    bool valueEquivalence(a, b) = equality]) {
  Set remaining = map2.keys.toSet();
  for (dynamic key1 in map1.keys) {
    bool found = false;
    for (dynamic key2 in map2.keys) {
      if (keyEquivalence(key1, key2)) {
        found = true;
        remaining.remove(key2);
        if (!valueEquivalence(map1[key1], map2[key2])) {
          return false;
        }
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
bool areElementsEquivalent(Element a, Element b, {TestStrategy strategy}) {
  if (identical(a, b)) return true;
  if (a == null || b == null) return false;
  return new ElementIdentityEquivalence(strategy ?? const TestStrategy())
      .visit(a, b);
}

bool areEntitiesEquivalent(Entity a, Entity b, {TestStrategy strategy}) {
  return areElementsEquivalent(a, b, strategy: strategy);
}

/// Returns `true` if types [a] and [b] are equivalent.
bool areTypesEquivalent(DartType a, DartType b, {TestStrategy strategy}) {
  if (identical(a, b)) return true;
  if (a == null || b == null) return false;
  return new TypeEquivalence(strategy ?? const TestStrategy()).visit(a, b);
}

/// Returns `true` if constants [exp1] and [exp2] are equivalent.
bool areConstantsEquivalent(ConstantExpression exp1, ConstantExpression exp2,
    {TestStrategy strategy}) {
  if (identical(exp1, exp2)) return true;
  if (exp1 == null || exp2 == null) return false;
  return new ConstantEquivalence(strategy ?? const TestStrategy())
      .visit(exp1, exp2);
}

/// Returns `true` if constant values [value1] and [value2] are equivalent.
bool areConstantValuesEquivalent(ConstantValue value1, ConstantValue value2,
    {TestStrategy strategy}) {
  if (identical(value1, value2)) return true;
  if (value1 == null || value2 == null) return false;
  return new ConstantValueEquivalence(strategy ?? const TestStrategy())
      .visit(value1, value2);
}

/// Returns `true` if the lists of elements, [a] and [b], are equivalent.
bool areElementListsEquivalent(List<Element> a, List<Element> b) {
  return areListsEquivalent(a, b, areElementsEquivalent);
}

/// Returns `true` if the lists of types, [a] and [b], are equivalent.
bool areTypeListsEquivalent(
    List<ResolutionDartType> a, List<ResolutionDartType> b) {
  return areListsEquivalent(a, b, areTypesEquivalent);
}

/// Returns `true` if the lists of constants, [a] and [b], are equivalent.
bool areConstantListsEquivalent(
    List<ConstantExpression> a, List<ConstantExpression> b) {
  return areListsEquivalent(a, b, areConstantsEquivalent);
}

/// Returns `true` if the lists of constant values, [a] and [b], are equivalent.
bool areConstantValueListsEquivalent(
    List<ConstantValue> a, List<ConstantValue> b) {
  return areListsEquivalent(a, b, areConstantValuesEquivalent);
}

/// Returns `true` if the selectors [a] and [b] are equivalent.
bool areSelectorsEquivalent(Selector a, Selector b,
    {TestStrategy strategy: const TestStrategy()}) {
  if (identical(a, b)) return true;
  if (a == null || b == null) return false;
  return a.kind == b.kind &&
      a.callStructure == b.callStructure &&
      areNamesEquivalent(a.memberName, b.memberName, strategy: strategy);
}

/// Returns `true` if the names [a] and [b] are equivalent.
bool areNamesEquivalent(Name a, Name b,
    {TestStrategy strategy: const TestStrategy()}) {
  return a.text == b.text &&
      a.isSetter == b.isSetter &&
      strategy.testElements(a, b, 'library', a.library, b.library);
}

/// Returns `true` if the dynamic uses [a] and [b] are equivalent.
bool areDynamicUsesEquivalent(DynamicUse a, DynamicUse b,
    {TestStrategy strategy: const TestStrategy()}) {
  return areSelectorsEquivalent(a.selector, b.selector, strategy: strategy);
}

/// Returns `true` if the static uses [a] and [b] are equivalent.
bool areStaticUsesEquivalent(StaticUse a, StaticUse b,
    {TestStrategy strategy: const TestStrategy()}) {
  return a.kind == b.kind &&
      strategy.testElements(a, b, 'element', a.element, b.element);
}

/// Returns `true` if the type uses [a] and [b] are equivalent.
bool areTypeUsesEquivalent(TypeUse a, TypeUse b,
    {TestStrategy strategy: const TestStrategy()}) {
  return a.kind == b.kind && strategy.testTypes(a, b, 'type', a.type, b.type);
}

/// Returns `true` if the list literal uses [a] and [b] are equivalent.
bool areListLiteralUsesEquivalent(ListLiteralUse a, ListLiteralUse b,
    {TestStrategy strategy: const TestStrategy()}) {
  return strategy.testTypes(a, b, 'type', a.type, b.type) &&
      a.isConstant == b.isConstant &&
      a.isEmpty == b.isEmpty;
}

/// Returns `true` if the map literal uses [a] and [b] are equivalent.
bool areMapLiteralUsesEquivalent(MapLiteralUse a, MapLiteralUse b,
    {TestStrategy strategy: const TestStrategy()}) {
  return strategy.testTypes(a, b, 'type', a.type, b.type) &&
      a.isConstant == b.isConstant &&
      a.isEmpty == b.isEmpty;
}

/// Returns `true` if the access semantics [a] and [b] are equivalent.
bool areAccessSemanticsEquivalent(AccessSemantics a, AccessSemantics b) {
  if (a.kind != b.kind) return false;
  switch (a.kind) {
    case AccessKind.EXPRESSION:
    case AccessKind.THIS:
      // No additional properties.
      return true;
    case AccessKind.THIS_PROPERTY:
    case AccessKind.DYNAMIC_PROPERTY:
    case AccessKind.CONDITIONAL_DYNAMIC_PROPERTY:
      return areNamesEquivalent(a.name, b.name);
    case AccessKind.CLASS_TYPE_LITERAL:
    case AccessKind.TYPEDEF_TYPE_LITERAL:
    case AccessKind.DYNAMIC_TYPE_LITERAL:
      return areConstantsEquivalent(a.constant, b.constant);
    case AccessKind.LOCAL_FUNCTION:
    case AccessKind.LOCAL_VARIABLE:
    case AccessKind.FINAL_LOCAL_VARIABLE:
    case AccessKind.PARAMETER:
    case AccessKind.FINAL_PARAMETER:
    case AccessKind.STATIC_FIELD:
    case AccessKind.FINAL_STATIC_FIELD:
    case AccessKind.STATIC_METHOD:
    case AccessKind.STATIC_GETTER:
    case AccessKind.STATIC_SETTER:
    case AccessKind.TOPLEVEL_FIELD:
    case AccessKind.FINAL_TOPLEVEL_FIELD:
    case AccessKind.TOPLEVEL_METHOD:
    case AccessKind.TOPLEVEL_GETTER:
    case AccessKind.TOPLEVEL_SETTER:
    case AccessKind.SUPER_FIELD:
    case AccessKind.SUPER_FINAL_FIELD:
    case AccessKind.SUPER_METHOD:
    case AccessKind.SUPER_GETTER:
    case AccessKind.SUPER_SETTER:
    case AccessKind.TYPE_PARAMETER_TYPE_LITERAL:
    case AccessKind.UNRESOLVED:
    case AccessKind.UNRESOLVED_SUPER:
    case AccessKind.INVALID:
      return areElementsEquivalent(a.element, b.element);
    case AccessKind.COMPOUND:
      CompoundAccessSemantics compoundAccess1 = a;
      CompoundAccessSemantics compoundAccess2 = b;
      return compoundAccess1.compoundAccessKind ==
              compoundAccess2.compoundAccessKind &&
          areElementsEquivalent(
              compoundAccess1.getter, compoundAccess2.getter) &&
          areElementsEquivalent(compoundAccess1.setter, compoundAccess2.setter);
    case AccessKind.CONSTANT:
    default:
      throw new UnsupportedError('Unsupported access kind: ${a.kind}');
  }
}

/// Returns `true` if the send structures [a] and [b] are equivalent.
bool areSendStructuresEquivalent(SendStructure a, SendStructure b) {
  if (identical(a, b)) return true;
  if (a == null || b == null) return false;
  if (a.kind != b.kind) return false;

  dynamic ad = a;
  dynamic bd = b;
  switch (a.kind) {
    case SendStructureKind.IF_NULL:
    case SendStructureKind.LOGICAL_AND:
    case SendStructureKind.LOGICAL_OR:
    case SendStructureKind.NOT:
    case SendStructureKind.INVALID_UNARY:
    case SendStructureKind.INVALID_BINARY:
      // No additional properties.
      return true;

    case SendStructureKind.IS:
    case SendStructureKind.IS_NOT:
    case SendStructureKind.AS:
      return areTypesEquivalent(ad.type, bd.type);

    case SendStructureKind.INVOKE:
    case SendStructureKind.INCOMPATIBLE_INVOKE:
      if (!areSelectorsEquivalent(ad.selector, bd.selector)) return false;
      continue semantics;

    case SendStructureKind.UNARY:
    case SendStructureKind.BINARY:
    case SendStructureKind.PREFIX:
    case SendStructureKind.POSTFIX:
    case SendStructureKind.INDEX_PREFIX:
    case SendStructureKind.INDEX_POSTFIX:
    case SendStructureKind.COMPOUND:
    case SendStructureKind.COMPOUND_INDEX_SET:
      if (ad.operator != bd.operator) return false;
      continue semantics;

    case SendStructureKind.DEFERRED_PREFIX:
      return areElementsEquivalent(ad.prefix, bd.prefix) &&
          areSendStructuresEquivalent(ad.sendStructure, bd.sendStructure);

    semantics:
    case SendStructureKind.GET:
    case SendStructureKind.SET:
    case SendStructureKind.INDEX:
    case SendStructureKind.INDEX_SET:
    case SendStructureKind.EQUALS:
    case SendStructureKind.NOT_EQUALS:
    case SendStructureKind.SET_IF_NULL:
    case SendStructureKind.INDEX_SET_IF_NULL:
      return areAccessSemanticsEquivalent(ad.semantics, bd.semantics);
  }
  throw new UnsupportedError('Unexpected send structures $a vs $b');
}

/// Returns `true` if the new structures [a] and [b] are equivalent.
bool areNewStructuresEquivalent(NewStructure a, NewStructure b) {
  if (identical(a, b)) return true;
  if (a == null || b == null) return false;
  if (a.kind != b.kind) return false;

  dynamic ad = a;
  dynamic bd = b;
  switch (a.kind) {
    case NewStructureKind.NEW_INVOKE:
      return ad.semantics.kind == bd.semantics.kind &&
          areElementsEquivalent(ad.semantics.element, bd.semantics.element) &&
          areTypesEquivalent(ad.semantics.type, bd.semantics.type) &&
          areSelectorsEquivalent(ad.selector, bd.selector);
    case NewStructureKind.CONST_INVOKE:
      return ad.constantInvokeKind == bd.constantInvokeKind &&
          areConstantsEquivalent(ad.constant, bd.constant);
    case NewStructureKind.LATE_CONST:
    default:
      throw new UnsupportedError('Unsupported NewStructure kind ${a.kind}.');
  }
}

/// Returns `true` if nodes [a] and [b] are equivalent.
bool areNodesEquivalent(Node node1, Node node2) {
  if (identical(node1, node2)) return true;
  if (node1 == null || node2 == null) return false;
  return node1.accept1(const NodeEquivalenceVisitor(), node2);
}

/// Strategy for testing equivalence.
///
/// Use this strategy to determine equivalence without failing on inequivalence.
class TestStrategy {
  final Equivalence<Entity> elementEquivalence;
  final Equivalence<DartType> typeEquivalence;
  final Equivalence<ConstantExpression> constantEquivalence;
  final Equivalence<ConstantValue> constantValueEquivalence;

  const TestStrategy(
      {this.elementEquivalence: areEntitiesEquivalent,
      this.typeEquivalence: areTypesEquivalent,
      this.constantEquivalence: areConstantsEquivalent,
      this.constantValueEquivalence: areConstantValuesEquivalent});

  /// An equivalence [TestStrategy] that doesn't throw on inequivalence.
  TestStrategy get testOnly => this;

  bool test(dynamic object1, dynamic object2, String property, dynamic value1,
      dynamic value2,
      [bool equivalence(a, b) = equality]) {
    return equivalence(value1, value2);
  }

  bool testLists(
      Object object1, Object object2, String property, List list1, List list2,
      [bool elementEquivalence(a, b) = equality]) {
    return areListsEquivalent(list1, list2, elementEquivalence);
  }

  bool testSets(dynamic object1, dynamic object2, String property,
      Iterable set1, Iterable set2,
      [bool elementEquivalence(a, b) = equality]) {
    return areSetsEquivalent(set1, set2, elementEquivalence);
  }

  bool testMaps(
      dynamic object1, dynamic object2, String property, Map map1, Map map2,
      [bool keyEquivalence(a, b) = equality,
      bool valueEquivalence(a, b) = equality]) {
    return areMapsEquivalent(map1, map2, keyEquivalence, valueEquivalence);
  }

  bool testElements(Object object1, Object object2, String property,
      Entity element1, Entity element2) {
    return test(object1, object2, property, element1, element2,
        (a, b) => elementEquivalence(a, b, strategy: this));
  }

  bool testTypes(Object object1, Object object2, String property,
      DartType type1, DartType type2) {
    return test(object1, object2, property, type1, type2,
        (a, b) => typeEquivalence(a, b, strategy: this));
  }

  bool testConstants(Object object1, Object object2, String property,
      ConstantExpression exp1, ConstantExpression exp2) {
    return test(object1, object2, property, exp1, exp2,
        (a, b) => constantEquivalence(a, b, strategy: this));
  }

  bool testConstantValues(Object object1, Object object2, String property,
      ConstantValue value1, ConstantValue value2) {
    return test(object1, object2, property, value1, value2,
        (a, b) => constantValueEquivalence(a, b, strategy: this));
  }

  bool testTypeLists(Object object1, Object object2, String property,
      List<DartType> list1, List<DartType> list2) {
    return testLists(object1, object2, property, list1, list2,
        (a, b) => typeEquivalence(a, b, strategy: this));
  }

  bool testConstantLists(Object object1, Object object2, String property,
      List<ConstantExpression> list1, List<ConstantExpression> list2) {
    return testLists(object1, object2, property, list1, list2,
        (a, b) => constantEquivalence(a, b, strategy: this));
  }

  bool testConstantValueLists(Object object1, Object object2, String property,
      List<ConstantValue> list1, List<ConstantValue> list2) {
    return testLists(object1, object2, property, list1, list2,
        (a, b) => constantValueEquivalence(a, b, strategy: this));
  }

  bool testNodes(
      Object object1, Object object2, String property, Node node1, Node node2) {
    return areNodesEquivalent(node1, node2);
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
  bool visitLibraryElement(
      LibraryElement element1, covariant LibraryElement element2) {
    return strategy.test(element1, element2, 'canonicalUri',
        element1.canonicalUri, element2.canonicalUri);
  }

  @override
  bool visitCompilationUnitElement(CompilationUnitElement element1,
      covariant CompilationUnitElement element2) {
    return strategy.test(element1, element2, 'script.resourceUri',
            element1.script.resourceUri, element2.script.resourceUri) &&
        visit(element1.library, element2.library);
  }

  @override
  bool visitClassElement(
      ClassElement element1, covariant ClassElement element2) {
    if (!strategy.test(
        element1,
        element2,
        'isUnnamedMixinApplication',
        element1.isUnnamedMixinApplication,
        element2.isUnnamedMixinApplication)) {
      return false;
    }
    if (element1.isUnnamedMixinApplication) {
      MixinApplicationElement mixin1 = element1;
      MixinApplicationElement mixin2 = element2;
      return strategy.testElements(
              mixin1, mixin2, 'subclass', mixin1.subclass, mixin2.subclass) &&
          // Using the [mixinType] is more precise but requires the test to
          // handle self references: The identity of a type variable is based on
          // its type declaration and if [mixin1] is generic the [mixinType]
          // will contain the type variables declared by [mixin1], i.e.
          // `abstract class Mixin<T> implements MixinType<T> {}`
          strategy.testElements(
              mixin1, mixin2, 'mixin', mixin1.mixin, mixin2.mixin);
    } else {
      return strategy.test(
              element1, element2, 'name', element1.name, element2.name) &&
          visit(element1.library, element2.library);
    }
  }

  bool checkMembers(Element element1, covariant Element element2) {
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
  bool visitFieldElement(
      FieldElement element1, covariant FieldElement element2) {
    return checkMembers(element1, element2);
  }

  @override
  bool visitBoxFieldElement(
      BoxFieldElement element1, covariant BoxFieldElement element2) {
    return element1.box.name == element2.box.name &&
        visit(element1.box.executableContext, element2.box.executableContext) &&
        visit(element1.variableElement, element2.variableElement);
  }

  @override
  bool visitConstructorElement(
      ConstructorElement element1, covariant ConstructorElement element2) {
    return checkMembers(element1, element2);
  }

  @override
  bool visitMethodElement(
      covariant MethodElement element1, covariant MethodElement element2) {
    return checkMembers(element1, element2);
  }

  @override
  bool visitGetterElement(
      GetterElement element1, covariant GetterElement element2) {
    return checkMembers(element1, element2);
  }

  @override
  bool visitSetterElement(
      SetterElement element1, covariant SetterElement element2) {
    return checkMembers(element1, element2);
  }

  @override
  bool visitLocalFunctionElement(
      LocalFunctionElement element1, covariant LocalFunctionElement element2) {
    // TODO(johnniwinther): Define an equivalence on locals.
    MemberElement member1 = element1.memberContext;
    MemberElement member2 = element2.memberContext;
    return strategy.test(
            element1, element2, 'name', element1.name, element2.name) &&
        checkMembers(member1, member2);
  }

  @override
  bool visitLocalVariableElement(
      LocalVariableElement element1, covariant LocalVariableElement element2) {
    // TODO(johnniwinther): Define an equivalence on locals.
    return strategy.test(
            element1, element2, 'name', element1.name, element2.name) &&
        checkMembers(element1.memberContext, element2.memberContext);
  }

  bool visitAbstractFieldElement(
      AbstractFieldElement element1, covariant AbstractFieldElement element2) {
    return checkMembers(element1, element2);
  }

  @override
  bool visitTypeVariableElement(
      TypeVariableElement element1, covariant TypeVariableElement element2) {
    return strategy.test(
            element1, element2, 'name', element1.name, element2.name) &&
        visit(element1.typeDeclaration, element2.typeDeclaration);
  }

  @override
  bool visitTypedefElement(
      TypedefElement element1, covariant TypedefElement element2) {
    return strategy.test(
            element1, element2, 'name', element1.name, element2.name) &&
        visit(element1.library, element2.library);
  }

  @override
  bool visitParameterElement(
      ParameterElement element1, covariant ParameterElement element2) {
    return strategy.test(
            element1, element2, 'name', element1.name, element2.name) &&
        visit(element1.functionDeclaration, element2.functionDeclaration);
  }

  @override
  bool visitImportElement(
      ImportElement element1, covariant ImportElement element2) {
    return visit(element1.importedLibrary, element2.importedLibrary) &&
        visit(element1.library, element2.library);
  }

  @override
  bool visitExportElement(
      ExportElement element1, covariant ExportElement element2) {
    return visit(element1.exportedLibrary, element2.exportedLibrary) &&
        visit(element1.library, element2.library);
  }

  @override
  bool visitPrefixElement(
      PrefixElement element1, covariant PrefixElement element2) {
    return strategy.test(
            element1, element2, 'name', element1.name, element2.name) &&
        visit(element1.library, element2.library);
  }

  @override
  bool visitErroneousElement(
      ErroneousElement element1, covariant ErroneousElement element2) {
    return strategy.test(element1, element2, 'messageKind',
        element1.messageKind, element2.messageKind);
  }

  @override
  bool visitWarnOnUseElement(
      WarnOnUseElement element1, covariant WarnOnUseElement element2) {
    return strategy.testElements(element1, element2, 'wrappedElement',
        element1.wrappedElement, element2.wrappedElement);
  }
}

/// Visitor that checks for equivalence of [ResolutionDartType]s.
class TypeEquivalence
    implements ResolutionDartTypeVisitor<bool, ResolutionDartType> {
  final TestStrategy strategy;

  const TypeEquivalence([this.strategy = const TestStrategy()]);

  bool visit(
      covariant ResolutionDartType type1, covariant ResolutionDartType type2) {
    return strategy.test(type1, type2, 'kind', type1.kind, type2.kind) &&
        type1.accept(this, type2);
  }

  @override
  bool visitDynamicType(covariant ResolutionDynamicType type,
          covariant ResolutionDynamicType other) =>
      true;

  @override
  bool visitFunctionType(covariant ResolutionFunctionType type,
      covariant ResolutionFunctionType other) {
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
  bool visitMalformedType(MalformedType type, covariant MalformedType other) =>
      true;

  @override
  bool visitTypeVariableType(covariant ResolutionTypeVariableType type,
      covariant ResolutionTypeVariableType other) {
    return strategy.testElements(
            type, other, 'element', type.element, other.element) &&
        strategy.test(type, other, 'is MethodTypeVariableType',
            type is MethodTypeVariableType, other is MethodTypeVariableType);
  }

  @override
  bool visitVoidType(covariant ResolutionVoidType type,
          covariant ResolutionVoidType argument) =>
      true;

  @override
  bool visitInterfaceType(covariant ResolutionInterfaceType type,
      covariant ResolutionInterfaceType other) {
    return visitGenericType(type, other);
  }

  @override
  bool visitTypedefType(covariant ResolutionTypedefType type,
      covariant ResolutionTypedefType other) {
    return visitGenericType(type, other);
  }
}

/// Visitor that checks for structural equivalence of [ConstantExpression]s.
class ConstantEquivalence
    implements ConstantExpressionVisitor<bool, ConstantExpression> {
  final TestStrategy strategy;

  const ConstantEquivalence([this.strategy = const TestStrategy()]);

  @override
  bool visit(ConstantExpression exp1, covariant ConstantExpression exp2) {
    if (identical(exp1, exp2)) return true;
    return strategy.test(exp1, exp2, 'kind', exp1.kind, exp2.kind) &&
        exp1.accept(this, exp2);
  }

  @override
  bool visitBinary(
      BinaryConstantExpression exp1, covariant BinaryConstantExpression exp2) {
    return strategy.test(
            exp1, exp2, 'operator', exp1.operator, exp2.operator) &&
        strategy.testConstants(exp1, exp2, 'left', exp1.left, exp2.left) &&
        strategy.testConstants(exp1, exp2, 'right', exp1.right, exp2.right);
  }

  @override
  bool visitConcatenate(ConcatenateConstantExpression exp1,
      covariant ConcatenateConstantExpression exp2) {
    return strategy.testConstantLists(
        exp1, exp2, 'expressions', exp1.expressions, exp2.expressions);
  }

  @override
  bool visitConditional(ConditionalConstantExpression exp1,
      covariant ConditionalConstantExpression exp2) {
    return strategy.testConstants(
            exp1, exp2, 'condition', exp1.condition, exp2.condition) &&
        strategy.testConstants(
            exp1, exp2, 'trueExp', exp1.trueExp, exp2.trueExp) &&
        strategy.testConstants(
            exp1, exp2, 'falseExp', exp1.falseExp, exp2.falseExp);
  }

  @override
  bool visitConstructed(ConstructedConstantExpression exp1,
      covariant ConstructedConstantExpression exp2) {
    return strategy.testTypes(exp1, exp2, 'type', exp1.type, exp2.type) &&
        strategy.testElements(exp1, exp2, 'target', exp1.target, exp2.target) &&
        strategy.testConstantLists(
            exp1, exp2, 'arguments', exp1.arguments, exp2.arguments) &&
        strategy.test(exp1, exp2, 'callStructure', exp1.callStructure,
            exp2.callStructure);
  }

  @override
  bool visitFunction(FunctionConstantExpression exp1,
      covariant FunctionConstantExpression exp2) {
    return strategy.testElements(
        exp1, exp2, 'element', exp1.element, exp2.element);
  }

  @override
  bool visitIdentical(IdenticalConstantExpression exp1,
      covariant IdenticalConstantExpression exp2) {
    return strategy.testConstants(exp1, exp2, 'left', exp1.left, exp2.left) &&
        strategy.testConstants(exp1, exp2, 'right', exp1.right, exp2.right);
  }

  @override
  bool visitList(
      ListConstantExpression exp1, covariant ListConstantExpression exp2) {
    return strategy.testTypes(exp1, exp2, 'type', exp1.type, exp2.type) &&
        strategy.testConstantLists(
            exp1, exp2, 'values', exp1.values, exp2.values);
  }

  @override
  bool visitMap(
      MapConstantExpression exp1, covariant MapConstantExpression exp2) {
    return strategy.testTypes(exp1, exp2, 'type', exp1.type, exp2.type) &&
        strategy.testConstantLists(exp1, exp2, 'keys', exp1.keys, exp2.keys) &&
        strategy.testConstantLists(
            exp1, exp2, 'values', exp1.values, exp2.values);
  }

  @override
  bool visitNamed(
      NamedArgumentReference exp1, covariant NamedArgumentReference exp2) {
    return strategy.test(exp1, exp2, 'name', exp1.name, exp2.name);
  }

  @override
  bool visitPositional(PositionalArgumentReference exp1,
      covariant PositionalArgumentReference exp2) {
    return strategy.test(exp1, exp2, 'index', exp1.index, exp2.index);
  }

  @override
  bool visitSymbol(
      SymbolConstantExpression exp1, covariant SymbolConstantExpression exp2) {
    // TODO(johnniwinther): Handle private names. Currently not even supported
    // in resolution.
    return strategy.test(exp1, exp2, 'name', exp1.name, exp2.name);
  }

  @override
  bool visitType(
      TypeConstantExpression exp1, covariant TypeConstantExpression exp2) {
    return strategy.testTypes(exp1, exp2, 'type', exp1.type, exp2.type);
  }

  @override
  bool visitUnary(
      UnaryConstantExpression exp1, covariant UnaryConstantExpression exp2) {
    return strategy.test(
            exp1, exp2, 'operator', exp1.operator, exp2.operator) &&
        strategy.testConstants(
            exp1, exp2, 'expression', exp1.expression, exp2.expression);
  }

  @override
  bool visitField(
      FieldConstantExpression exp1, covariant FieldConstantExpression exp2) {
    return strategy.testElements(
        exp1, exp2, 'element', exp1.element, exp2.element);
  }

  @override
  bool visitLocalVariable(LocalVariableConstantExpression exp1,
      covariant LocalVariableConstantExpression exp2) {
    return strategy.testElements(
        exp1, exp2, 'element', exp1.element, exp2.element);
  }

  @override
  bool visitBool(
      BoolConstantExpression exp1, covariant BoolConstantExpression exp2) {
    return strategy.test(
        exp1, exp2, 'primitiveValue', exp1.primitiveValue, exp2.primitiveValue);
  }

  @override
  bool visitDouble(
      DoubleConstantExpression exp1, covariant DoubleConstantExpression exp2) {
    return strategy.test(
        exp1, exp2, 'primitiveValue', exp1.primitiveValue, exp2.primitiveValue);
  }

  @override
  bool visitInt(
      IntConstantExpression exp1, covariant IntConstantExpression exp2) {
    return strategy.test(
        exp1, exp2, 'primitiveValue', exp1.primitiveValue, exp2.primitiveValue);
  }

  @override
  bool visitNull(
      NullConstantExpression exp1, covariant NullConstantExpression exp2) {
    return true;
  }

  @override
  bool visitString(
      StringConstantExpression exp1, covariant StringConstantExpression exp2) {
    return strategy.test(
        exp1, exp2, 'primitiveValue', exp1.primitiveValue, exp2.primitiveValue);
  }

  @override
  bool visitBoolFromEnvironment(BoolFromEnvironmentConstantExpression exp1,
      covariant BoolFromEnvironmentConstantExpression exp2) {
    return strategy.testConstants(exp1, exp2, 'name', exp1.name, exp2.name) &&
        strategy.testConstants(
            exp1, exp2, 'defaultValue', exp1.defaultValue, exp2.defaultValue);
  }

  @override
  bool visitIntFromEnvironment(IntFromEnvironmentConstantExpression exp1,
      covariant IntFromEnvironmentConstantExpression exp2) {
    return strategy.testConstants(exp1, exp2, 'name', exp1.name, exp2.name) &&
        strategy.testConstants(
            exp1, exp2, 'defaultValue', exp1.defaultValue, exp2.defaultValue);
  }

  @override
  bool visitStringFromEnvironment(StringFromEnvironmentConstantExpression exp1,
      covariant StringFromEnvironmentConstantExpression exp2) {
    return strategy.testConstants(exp1, exp2, 'name', exp1.name, exp2.name) &&
        strategy.testConstants(
            exp1, exp2, 'defaultValue', exp1.defaultValue, exp2.defaultValue);
  }

  @override
  bool visitStringLength(StringLengthConstantExpression exp1,
      covariant StringLengthConstantExpression exp2) {
    return strategy.testConstants(
        exp1, exp2, 'expression', exp1.expression, exp2.expression);
  }

  @override
  bool visitDeferred(DeferredConstantExpression exp1,
      covariant DeferredConstantExpression exp2) {
    return strategy.testElements(
            exp1, exp2, 'prefix', exp1.prefix, exp2.prefix) &&
        strategy.testConstants(
            exp1, exp2, 'expression', exp1.expression, exp2.expression);
  }
}

/// Visitor that checks for structural equivalence of [ConstantValue]s.
class ConstantValueEquivalence
    implements ConstantValueVisitor<bool, ConstantValue> {
  final TestStrategy strategy;

  const ConstantValueEquivalence([this.strategy = const TestStrategy()]);

  bool visit(ConstantValue value1, covariant ConstantValue value2) {
    if (identical(value1, value2)) return true;
    return strategy.test(value1, value2, 'kind', value1.kind, value2.kind) &&
        value1.accept(this, value2);
  }

  @override
  bool visitConstructed(ConstructedConstantValue value1,
      covariant ConstructedConstantValue value2) {
    return strategy.testTypes(
            value1, value2, 'type', value1.type, value2.type) &&
        strategy.testMaps(
            value1,
            value2,
            'fields',
            value1.fields,
            value2.fields,
            strategy.elementEquivalence,
            (a, b) => strategy.testConstantValues(
                value1, value2, 'fields.values', a, b));
  }

  @override
  bool visitFunction(
      FunctionConstantValue value1, covariant FunctionConstantValue value2) {
    return strategy.testElements(
        value1, value2, 'element', value1.element, value2.element);
  }

  @override
  bool visitList(ListConstantValue value1, covariant ListConstantValue value2) {
    return strategy.testTypes(
            value1, value2, 'type', value1.type, value2.type) &&
        strategy.testConstantValueLists(
            value1, value2, 'entries', value1.entries, value2.entries);
  }

  @override
  bool visitMap(MapConstantValue value1, covariant MapConstantValue value2) {
    return strategy.testTypes(
            value1, value2, 'type', value1.type, value2.type) &&
        strategy.testConstantValueLists(
            value1, value2, 'keys', value1.keys, value2.keys) &&
        strategy.testConstantValueLists(
            value1, value2, 'values', value1.values, value2.values);
  }

  @override
  bool visitType(TypeConstantValue value1, covariant TypeConstantValue value2) {
    return strategy.testTypes(value1, value2, 'type', value1.type, value2.type);
  }

  @override
  bool visitBool(BoolConstantValue value1, covariant BoolConstantValue value2) {
    return strategy.test(value1, value2, 'primitiveValue',
        value1.primitiveValue, value2.primitiveValue);
  }

  @override
  bool visitDouble(
      DoubleConstantValue value1, covariant DoubleConstantValue value2) {
    return strategy.test(value1, value2, 'primitiveValue',
        value1.primitiveValue, value2.primitiveValue);
  }

  @override
  bool visitInt(IntConstantValue value1, covariant IntConstantValue value2) {
    return strategy.test(value1, value2, 'primitiveValue',
        value1.primitiveValue, value2.primitiveValue);
  }

  @override
  bool visitNull(NullConstantValue value1, covariant NullConstantValue value2) {
    return true;
  }

  @override
  bool visitString(
      StringConstantValue value1, covariant StringConstantValue value2) {
    return strategy.test(value1, value2, 'primitiveValue',
        value1.primitiveValue, value2.primitiveValue);
  }

  @override
  bool visitDeferred(
      DeferredConstantValue value1, covariant DeferredConstantValue value2) {
    return strategy.testElements(
            value1, value2, 'prefix', value1.prefix, value2.prefix) &&
        strategy.testConstantValues(
            value1, value2, 'referenced', value1.referenced, value2.referenced);
  }

  @override
  bool visitNonConstant(
      NonConstantValue value1, covariant NonConstantValue value2) {
    return true;
  }

  @override
  bool visitSynthetic(
      SyntheticConstantValue value1, covariant SyntheticConstantValue value2) {
    return strategy.test(
            value1, value2, 'payload', value1.payload, value2.payload) &&
        strategy.test(
            value1, value2, 'valueKind', value1.valueKind, value2.valueKind);
  }

  @override
  bool visitInterceptor(InterceptorConstantValue value1,
      covariant InterceptorConstantValue value2) {
    return strategy.testElements(value1, value2, 'cls', value1.cls, value2.cls);
  }
}

/// Tests the equivalence of [impact1] and [impact2] using [strategy].
bool testResolutionImpactEquivalence(
    ResolutionImpact impact1, ResolutionImpact impact2,
    {TestStrategy strategy = const TestStrategy()}) {
  return strategy.testSets(impact1, impact2, 'constSymbolNames',
          impact1.constSymbolNames, impact2.constSymbolNames) &&
      strategy.testSets(
          impact1,
          impact2,
          'constantLiterals',
          impact1.constantLiterals,
          impact2.constantLiterals,
          areConstantsEquivalent) &&
      strategy.testSets(
          impact1,
          impact2,
          'dynamicUses',
          impact1.dynamicUses,
          impact2.dynamicUses,
          (a, b) =>
              areDynamicUsesEquivalent(a, b, strategy: strategy.testOnly)) &&
      strategy.testSets(
          impact1, impact2, 'features', impact1.features, impact2.features) &&
      strategy.testSets(
          impact1,
          impact2,
          'listLiterals',
          impact1.listLiterals,
          impact2.listLiterals,
          (a, b) => areListLiteralUsesEquivalent(a, b,
              strategy: strategy.testOnly)) &&
      strategy.testSets(
          impact1,
          impact2,
          'mapLiterals',
          impact1.mapLiterals,
          impact2.mapLiterals,
          (a, b) =>
              areMapLiteralUsesEquivalent(a, b, strategy: strategy.testOnly)) &&
      strategy.testSets(
          impact1,
          impact2,
          'staticUses',
          impact1.staticUses,
          impact2.staticUses,
          (a, b) =>
              areStaticUsesEquivalent(a, b, strategy: strategy.testOnly)) &&
      strategy.testSets(
          impact1,
          impact2,
          'typeUses',
          impact1.typeUses,
          impact2.typeUses,
          (a, b) => areTypeUsesEquivalent(a, b, strategy: strategy.testOnly)) &&
      strategy.testSets(
          impact1,
          impact2,
          'nativeData',
          impact1.nativeData,
          impact2.nativeData,
          (a, b) => testNativeBehavior(a, b, strategy: strategy));
}

/// Tests the equivalence of [resolvedAst1] and [resolvedAst2] using [strategy].
bool testResolvedAstEquivalence(
    ResolvedAst resolvedAst1, ResolvedAst resolvedAst2,
    [TestStrategy strategy = const TestStrategy()]) {
  if (!strategy.test(resolvedAst1, resolvedAst1, 'kind', resolvedAst1.kind,
      resolvedAst2.kind)) {
    return false;
  }
  if (resolvedAst1.kind != ResolvedAstKind.PARSED) {
    // Nothing more to check.
    return true;
  }
  bool result = strategy.testElements(resolvedAst1, resolvedAst2, 'element',
          resolvedAst1.element, resolvedAst2.element) &&
      strategy.testNodes(resolvedAst1, resolvedAst2, 'node', resolvedAst1.node,
          resolvedAst2.node) &&
      strategy.testNodes(resolvedAst1, resolvedAst2, 'body', resolvedAst1.body,
          resolvedAst2.body) &&
      testTreeElementsEquivalence(resolvedAst1, resolvedAst2, strategy) &&
      strategy.test(resolvedAst1, resolvedAst2, 'sourceUri',
          resolvedAst1.sourceUri, resolvedAst2.sourceUri);
  if (resolvedAst1.element is FunctionElement) {
    FunctionElement element1 = resolvedAst1.element;
    FunctionElement element2 = resolvedAst2.element;
    for (int index = 0; index < element1.parameters.length; index++) {
      dynamic parameter1 = element1.parameters[index];
      dynamic parameter2 = element2.parameters[index];
      result = result &&
          strategy.testNodes(parameter1, parameter2, 'node',
              parameter1.implementation.node, parameter2.implementation.node) &&
          strategy.testNodes(
              parameter1,
              parameter2,
              'initializer',
              parameter1.implementation.initializer,
              parameter2.implementation.initializer);
    }
  }
  return result;
}

/// Tests the equivalence of the data stored in the [TreeElements] of
/// [resolvedAst1] and [resolvedAst2] using [strategy].
bool testTreeElementsEquivalence(
    ResolvedAst resolvedAst1, ResolvedAst resolvedAst2,
    [TestStrategy strategy = const TestStrategy()]) {
  AstIndexComputer indices1 = new AstIndexComputer();
  resolvedAst1.node.accept(indices1);
  AstIndexComputer indices2 = new AstIndexComputer();
  resolvedAst2.node.accept(indices2);

  TreeElements elements1 = resolvedAst1.elements;
  TreeElements elements2 = resolvedAst2.elements;

  TreeElementsEquivalenceVisitor visitor = new TreeElementsEquivalenceVisitor(
      indices1, indices2, elements1, elements2, strategy);
  resolvedAst1.node.accept(visitor);
  if (visitor.success) {
    return strategy.test(elements1, elements2, 'containsTryStatement',
        elements1.containsTryStatement, elements2.containsTryStatement);
  }
  return false;
}

bool testNativeBehavior(NativeBehavior a, NativeBehavior b,
    {TestStrategy strategy = const TestStrategy()}) {
  if (identical(a, b)) return true;
  if (a == null || b == null) return false;
  return strategy.test(
          a, b, 'codeTemplateText', a.codeTemplateText, b.codeTemplateText) &&
      strategy.test(a, b, 'isAllocation', a.isAllocation, b.isAllocation) &&
      strategy.test(a, b, 'sideEffects', a.sideEffects, b.sideEffects) &&
      strategy.test(a, b, 'throwBehavior', a.throwBehavior, b.throwBehavior) &&
      strategy.testTypeLists(
          a,
          b,
          'dartTypesReturned',
          NativeBehaviorSerialization.filterDartTypes(a.typesReturned),
          NativeBehaviorSerialization.filterDartTypes(b.typesReturned)) &&
      strategy.testLists(
          a,
          b,
          'specialTypesReturned',
          NativeBehaviorSerialization.filterSpecialTypes(a.typesReturned),
          NativeBehaviorSerialization.filterSpecialTypes(b.typesReturned)) &&
      strategy.testTypeLists(
          a,
          b,
          'dartTypesInstantiated',
          NativeBehaviorSerialization.filterDartTypes(a.typesInstantiated),
          NativeBehaviorSerialization.filterDartTypes(b.typesInstantiated)) &&
      strategy.testLists(
          a,
          b,
          'specialTypesInstantiated',
          NativeBehaviorSerialization.filterSpecialTypes(a.typesInstantiated),
          NativeBehaviorSerialization
              .filterSpecialTypes(b.typesInstantiated)) &&
      strategy.test(a, b, 'useGvn', a.useGvn, b.useGvn);
}

/// Visitor that checks the equivalence of [TreeElements] data.
class TreeElementsEquivalenceVisitor extends Visitor {
  final TestStrategy strategy;
  final AstIndexComputer indices1;
  final AstIndexComputer indices2;
  final TreeElements elements1;
  final TreeElements elements2;
  bool success = true;

  TreeElementsEquivalenceVisitor(
      this.indices1, this.indices2, this.elements1, this.elements2,
      [this.strategy = const TestStrategy()]);

  bool testJumpTargets(
      Node node1, Node node2, String property, JumpTarget a, JumpTarget b) {
    if (identical(a, b)) return true;
    if (a == null || b == null) return false;
    return strategy.test(
            a, b, 'nestingLevel', a.nestingLevel, b.nestingLevel) &&
        strategy.test(a, b, 'statement', indices1.nodeIndices[a.statement],
            indices2.nodeIndices[b.statement]) &&
        strategy.test(
            a, b, 'isBreakTarget', a.isBreakTarget, b.isBreakTarget) &&
        strategy.test(
            a, b, 'isContinueTarget', a.isContinueTarget, b.isContinueTarget) &&
        strategy.testLists(a, b, 'labels', a.labels.toList(), b.labels.toList(),
            (a, b) {
          return indices1.nodeIndices[a.label] == indices2.nodeIndices[b.label];
        });
  }

  bool testLabelDefinitions(Node node1, Node node2, String property,
      LabelDefinitionX a, LabelDefinitionX b) {
    if (identical(a, b)) return true;
    if (a == null || b == null) return false;
    return strategy.test(a, b, 'label', indices1.nodeIndices[a.label],
            indices2.nodeIndices[b.label]) &&
        strategy.test(a, b, 'labelName', a.labelName, b.labelName) &&
        strategy.test(a, b, 'target', indices1.nodeIndices[a.target.statement],
            indices2.nodeIndices[b.target.statement]) &&
        strategy.test(
            a, b, 'isBreakTarget', a.isBreakTarget, b.isBreakTarget) &&
        strategy.test(
            a, b, 'isContinueTarget', a.isContinueTarget, b.isContinueTarget);
  }

  bool testNativeData(Node node1, Node node2, String property, a, b) {
    if (identical(a, b)) return true;
    if (a == null || b == null) return false;
    if (a is NativeBehavior && b is NativeBehavior) {
      return testNativeBehavior(a, b, strategy: strategy);
    }
    return true;
  }

  visitNode(Node node1) {
    if (!success) return;
    int index = indices1.nodeIndices[node1];
    Node node2 = indices2.nodeList[index];
    success = strategy.testElements(
            node1, node2, '[$index]', elements1[node1], elements2[node2]) &&
        strategy.testTypes(node1, node2, 'getType($index)',
            elements1.getType(node1), elements2.getType(node2)) &&
        strategy.test(
            node1,
            node2,
            'getSelector($index)',
            elements1.getSelector(node1),
            elements2.getSelector(node2),
            areSelectorsEquivalent) &&
        strategy.testConstants(node1, node2, 'getConstant($index)',
            elements1.getConstant(node1), elements2.getConstant(node2)) &&
        strategy.testTypes(node1, node2, 'typesCache[$index]',
            elements1.typesCache[node1], elements2.typesCache[node2]) &&
        testJumpTargets(
            node1,
            node2,
            'getTargetDefinition($index)',
            elements1.getTargetDefinition(node1),
            elements2.getTargetDefinition(node2)) &&
        testNativeData(node1, node2, 'getNativeData($index)',
            elements1.getNativeData(node1), elements2.getNativeData(node2));

    node1.visitChildren(this);
  }

  @override
  visitSend(Send node1) {
    visitExpression(node1);
    if (!success) return;
    int index = indices1.nodeIndices[node1];
    Send node2 = indices2.nodeList[index];
    success = strategy.test(node1, node2, 'isTypeLiteral($index)',
            elements1.isTypeLiteral(node1), elements2.isTypeLiteral(node2)) &&
        strategy.testTypes(
            node1,
            node2,
            'getTypeLiteralType($index)',
            elements1.getTypeLiteralType(node1),
            elements2.getTypeLiteralType(node2)) &&
        strategy.test(
            node1,
            node2,
            'getSendStructure($index)',
            elements1.getSendStructure(node1),
            elements2.getSendStructure(node2),
            areSendStructuresEquivalent);
  }

  @override
  visitNewExpression(NewExpression node1) {
    visitExpression(node1);
    if (!success) return;
    int index = indices1.nodeIndices[node1];
    NewExpression node2 = indices2.nodeList[index];
    success = strategy.test(
        node1,
        node2,
        'getNewStructure($index)',
        elements1.getNewStructure(node1),
        elements2.getNewStructure(node2),
        areNewStructuresEquivalent);
  }

  @override
  visitSendSet(SendSet node1) {
    visitSend(node1);
    if (!success) return;
    int index = indices1.nodeIndices[node1];
    SendSet node2 = indices2.nodeList[index];
    success = strategy.test(
            node1,
            node2,
            'getGetterSelectorInComplexSendSet($index)',
            elements1.getGetterSelectorInComplexSendSet(node1),
            elements2.getGetterSelectorInComplexSendSet(node2),
            areSelectorsEquivalent) &&
        strategy.test(
            node1,
            node2,
            'getOperatorSelectorInComplexSendSet($index)',
            elements1.getOperatorSelectorInComplexSendSet(node1),
            elements2.getOperatorSelectorInComplexSendSet(node2),
            areSelectorsEquivalent);
  }

  @override
  visitFunctionExpression(FunctionExpression node1) {
    visitNode(node1);
    if (!success) return;
    int index = indices1.nodeIndices[node1];
    FunctionExpression node2 = indices2.nodeList[index];
    if (elements1[node1] is! FunctionElement) {
      // [getFunctionDefinition] is currently stored in [] which doesn't always
      // contain a [FunctionElement].
      return;
    }
    success = strategy.testElements(
        node1,
        node2,
        'getFunctionDefinition($index)',
        elements1.getFunctionDefinition(node1),
        elements2.getFunctionDefinition(node2));
  }

  @override
  visitForIn(ForIn node1) {
    visitLoop(node1);
    if (!success) return;
    int index = indices1.nodeIndices[node1];
    ForIn node2 = indices2.nodeList[index];
    success = strategy.testElements(node1, node2, 'getForInVariable($index)',
        elements1.getForInVariable(node1), elements2.getForInVariable(node2));
  }

  @override
  visitRedirectingFactoryBody(RedirectingFactoryBody node1) {
    visitStatement(node1);
    if (!success) return;
    int index = indices1.nodeIndices[node1];
    RedirectingFactoryBody node2 = indices2.nodeList[index];
    success = strategy.testElements(
        node1,
        node2,
        'getRedirectingTargetConstructor($index)',
        elements1.getRedirectingTargetConstructor(node1),
        elements2.getRedirectingTargetConstructor(node2));
  }

  @override
  visitGotoStatement(GotoStatement node1) {
    visitStatement(node1);
    if (!success) return;
    int index = indices1.nodeIndices[node1];
    GotoStatement node2 = indices2.nodeList[index];
    success = testJumpTargets(node1, node2, 'getTargetOf($index)',
        elements1.getTargetOf(node1), elements2.getTargetOf(node2));
    if (!success) return;
    if (node1.target == null && node2.target == null) {
      return;
    }
    success = testLabelDefinitions(node1, node2, 'getTarget($index)',
        elements1.getTargetLabel(node1), elements2.getTargetLabel(node2));
  }

  @override
  visitLabel(Label node1) {
    visitNode(node1);
    if (!success) return;
    int index = indices1.nodeIndices[node1];
    Label node2 = indices2.nodeList[index];
    success = testLabelDefinitions(
        node1,
        node2,
        'getLabelDefinition($index)',
        elements1.getLabelDefinition(node1),
        elements2.getLabelDefinition(node2));
  }
}

class NodeEquivalenceVisitor implements Visitor1<bool, Node> {
  final TestStrategy strategy;

  const NodeEquivalenceVisitor([this.strategy = const TestStrategy()]);

  bool testNodes(dynamic object1, dynamic object2, String property, Node node1,
      Node node2) {
    return strategy.test(object1, object2, property, node1, node2,
        (Node n1, Node n2) {
      if (n1 == n2) return true;
      if (n1 == null || n2 == null) return false;
      return n1.accept1(this, n2);
    });
  }

  bool testNodeLists(dynamic object1, dynamic object2, String property,
      Link<Node> list1, Link<Node> list2) {
    return strategy.test(object1, object2, property, list1, list2,
        (Link<Node> l1, Link<Node> l2) {
      if (l1 == l2) return true;
      if (l1 == null || l2 == null) return false;
      while (l1.isNotEmpty && l2.isNotEmpty) {
        if (!l1.head.accept1(this, l2.head)) {
          return false;
        }
        l1 = l1.tail;
        l2 = l2.tail;
      }
      return l1.isEmpty && l2.isEmpty;
    });
  }

  bool testTokens(dynamic object1, dynamic object2, String property,
      Token token1, Token token2) {
    return strategy.test(object1, object2, property, token1, token2,
        (Token t1, Token t2) {
      if (t1 == t2) return true;
      if (t1 == null || t2 == null) return false;
      return strategy.test(
              t1, t2, 'charOffset', t1.charOffset, t2.charOffset) &&
          strategy.test(t1, t2, 'info', t1.type, t2.type) &&
          strategy.test(t1, t2, 'value', t1.lexeme, t2.lexeme);
    });
  }

  @override
  bool visitAssert(Assert node1, covariant Assert node2) {
    return testTokens(node1, node2, 'assertToken', node1.assertToken,
            node2.assertToken) &&
        testNodes(
            node1, node2, 'condition', node1.condition, node2.condition) &&
        testNodes(node1, node2, 'message', node1.message, node2.message);
  }

  @override
  bool visitAsyncForIn(AsyncForIn node1, covariant AsyncForIn node2) {
    return visitForIn(node1, node2) &&
        testTokens(
            node1, node2, 'awaitToken', node1.awaitToken, node2.awaitToken);
  }

  @override
  bool visitAsyncModifier(AsyncModifier node1, covariant AsyncModifier node2) {
    return testTokens(
            node1, node2, 'asyncToken', node1.asyncToken, node2.asyncToken) &&
        testTokens(node1, node2, 'starToken', node1.starToken, node2.starToken);
  }

  @override
  bool visitAwait(Await node1, covariant Await node2) {
    return testTokens(
            node1, node2, 'awaitToken', node1.awaitToken, node2.awaitToken) &&
        testNodes(
            node1, node2, 'expression', node1.expression, node2.expression);
  }

  @override
  bool visitBlock(Block node1, covariant Block node2) {
    return testNodes(
        node1, node2, 'statements', node1.statements, node2.statements);
  }

  @override
  bool visitBreakStatement(
      BreakStatement node1, covariant BreakStatement node2) {
    return testTokens(node1, node2, 'keywordToken', node1.keywordToken,
            node2.keywordToken) &&
        testNodes(node1, node2, 'target', node1.target, node2.target);
  }

  @override
  bool visitCascade(Cascade node1, covariant Cascade node2) {
    return testNodes(
        node1, node2, 'expression', node1.expression, node2.expression);
  }

  @override
  bool visitCascadeReceiver(
      CascadeReceiver node1, covariant CascadeReceiver node2) {
    return testTokens(node1, node2, 'cascadeOperator', node1.cascadeOperator,
            node2.cascadeOperator) &&
        testNodes(
            node1, node2, 'expression', node1.expression, node2.expression);
  }

  @override
  bool visitCaseMatch(CaseMatch node1, covariant CaseMatch node2) {
    return testTokens(node1, node2, 'caseKeyword', node1.caseKeyword,
            node2.caseKeyword) &&
        testNodes(
            node1, node2, 'expression', node1.expression, node2.expression);
  }

  @override
  bool visitCatchBlock(CatchBlock node1, covariant CatchBlock node2) {
    return testTokens(node1, node2, 'catchKeyword', node1.catchKeyword,
            node2.catchKeyword) &&
        testTokens(
            node1, node2, 'onKeyword', node1.onKeyword, node2.onKeyword) &&
        testNodes(node1, node2, 'type', node1.type, node2.type) &&
        testNodes(node1, node2, 'formals', node1.formals, node2.formals) &&
        testNodes(node1, node2, 'block', node1.block, node2.block);
  }

  @override
  bool visitClassNode(ClassNode node1, covariant ClassNode node2) {
    return testTokens(
            node1, node2, 'beginToken', node1.beginToken, node2.beginToken) &&
        testTokens(node1, node2, 'extendsKeyword', node1.extendsKeyword,
            node2.extendsKeyword) &&
        testTokens(node1, node2, 'endToken', node1.endToken, node2.endToken) &&
        testNodes(
            node1, node2, 'modifiers', node1.modifiers, node2.modifiers) &&
        testNodes(node1, node2, 'name', node1.name, node2.name) &&
        testNodes(
            node1, node2, 'superclass', node1.superclass, node2.superclass) &&
        testNodes(
            node1, node2, 'interfaces', node1.interfaces, node2.interfaces) &&
        testNodes(node1, node2, 'typeParameters', node1.typeParameters,
            node2.typeParameters) &&
        testNodes(node1, node2, 'body', node1.body, node2.body);
  }

  @override
  bool visitCombinator(Combinator node1, covariant Combinator node2) {
    return testTokens(node1, node2, 'keywordToken', node1.keywordToken,
            node2.keywordToken) &&
        testNodes(
            node1, node2, 'identifiers', node1.identifiers, node2.identifiers);
  }

  @override
  bool visitConditional(Conditional node1, covariant Conditional node2) {
    return testTokens(node1, node2, 'questionToken', node1.questionToken,
            node2.questionToken) &&
        testTokens(
            node1, node2, 'colonToken', node1.colonToken, node2.colonToken) &&
        testNodes(
            node1, node2, 'condition', node1.condition, node2.condition) &&
        testNodes(node1, node2, 'thenExpression', node1.thenExpression,
            node2.thenExpression) &&
        testNodes(node1, node2, 'elseExpression', node1.elseExpression,
            node2.elseExpression);
  }

  @override
  bool visitConditionalUri(
      ConditionalUri node1, covariant ConditionalUri node2) {
    return testTokens(node1, node2, 'ifToken', node1.ifToken, node2.ifToken) &&
        testNodes(node1, node2, 'key', node1.key, node2.key) &&
        testNodes(node1, node2, 'value', node1.value, node2.value) &&
        testNodes(node1, node2, 'uri', node1.uri, node2.uri);
  }

  @override
  bool visitContinueStatement(
      ContinueStatement node1, covariant ContinueStatement node2) {
    return testTokens(node1, node2, 'keywordToken', node1.keywordToken,
            node2.keywordToken) &&
        testNodes(node1, node2, 'target', node1.target, node2.target);
  }

  @override
  bool visitDoWhile(DoWhile node1, covariant DoWhile node2) {
    return testTokens(
            node1, node2, 'doKeyword', node1.doKeyword, node2.doKeyword) &&
        testTokens(node1, node2, 'whileKeyword', node1.whileKeyword,
            node2.whileKeyword) &&
        testTokens(node1, node2, 'endToken', node1.endToken, node2.endToken) &&
        testNodes(
            node1, node2, 'condition', node1.condition, node2.condition) &&
        testNodes(node1, node2, 'body', node1.body, node2.body);
  }

  @override
  bool visitDottedName(DottedName node1, covariant DottedName node2) {
    return testTokens(node1, node2, 'token', node1.token, node2.token) &&
        testNodes(
            node1, node2, 'identifiers', node1.identifiers, node2.identifiers);
  }

  @override
  bool visitEmptyStatement(
      EmptyStatement node1, covariant EmptyStatement node2) {
    return testTokens(node1, node2, 'semicolonToken', node1.semicolonToken,
        node2.semicolonToken);
  }

  @override
  bool visitEnum(Enum node1, covariant Enum node2) {
    return testTokens(
            node1, node2, 'enumToken', node1.enumToken, node2.enumToken) &&
        testNodes(node1, node2, 'name', node1.name, node2.name) &&
        testNodes(node1, node2, 'names', node1.names, node2.names);
  }

  @override
  bool visitExport(Export node1, covariant Export node2) {
    return visitLibraryDependency(node1, node2) &&
        testTokens(node1, node2, 'exportKeyword', node1.exportKeyword,
            node2.exportKeyword);
  }

  @override
  bool visitExpressionStatement(
      ExpressionStatement node1, covariant ExpressionStatement node2) {
    return testTokens(
            node1, node2, 'endToken', node1.endToken, node2.endToken) &&
        testNodes(
            node1, node2, 'expression', node1.expression, node2.expression);
  }

  @override
  bool visitFor(For node1, covariant For node2) {
    return testTokens(
            node1, node2, 'forToken', node1.forToken, node2.forToken) &&
        testNodes(node1, node2, 'initializer', node1.initializer,
            node2.initializer) &&
        testNodes(node1, node2, 'conditionStatement', node1.conditionStatement,
            node2.conditionStatement) &&
        testNodes(node1, node2, 'update', node1.update, node2.update) &&
        testNodes(node1, node2, 'body', node1.body, node2.body);
  }

  @override
  bool visitForIn(ForIn node1, covariant ForIn node2) {
    return testNodes(
            node1, node2, 'condition', node1.condition, node2.condition) &&
        testNodes(
            node1, node2, 'expression', node1.expression, node2.expression) &&
        testNodes(node1, node2, 'body', node1.body, node2.body) &&
        testNodes(node1, node2, 'declaredIdentifier', node1.declaredIdentifier,
            node2.declaredIdentifier);
  }

  @override
  bool visitFunctionDeclaration(
      FunctionDeclaration node1, covariant FunctionDeclaration node2) {
    return testNodes(node1, node2, 'function', node1.function, node2.function);
  }

  @override
  bool visitFunctionExpression(
      FunctionExpression node1, covariant FunctionExpression node2) {
    return testTokens(
            node1, node2, 'getOrSet', node1.getOrSet, node2.getOrSet) &&
        testNodes(node1, node2, 'name', node1.name, node2.name) &&
        testNodes(
            node1, node2, 'parameters', node1.parameters, node2.parameters) &&
        testNodes(node1, node2, 'body', node1.body, node2.body) &&
        testNodes(
            node1, node2, 'returnType', node1.returnType, node2.returnType) &&
        testNodes(
            node1, node2, 'modifiers', node1.modifiers, node2.modifiers) &&
        testNodes(node1, node2, 'initializers', node1.initializers,
            node2.initializers) &&
        testNodes(node1, node2, 'asyncModifier', node1.asyncModifier,
            node2.asyncModifier);
  }

  @override
  bool visitGotoStatement(GotoStatement node1, covariant GotoStatement node2) {
    return testTokens(node1, node2, 'keywordToken', node1.keywordToken,
            node2.keywordToken) &&
        testTokens(node1, node2, 'semicolonToken', node1.semicolonToken,
            node2.semicolonToken) &&
        testNodes(node1, node2, 'target', node1.target, node2.target);
  }

  @override
  bool visitIdentifier(Identifier node1, covariant Identifier node2) {
    return testTokens(node1, node2, 'token', node1.token, node2.token);
  }

  @override
  bool visitIf(If node1, covariant If node2) {
    return testTokens(node1, node2, 'ifToken', node1.ifToken, node2.ifToken) &&
        testTokens(
            node1, node2, 'elseToken', node1.elseToken, node2.elseToken) &&
        testNodes(
            node1, node2, 'condition', node1.condition, node2.condition) &&
        testNodes(node1, node2, 'thenPart', node1.thenPart, node2.thenPart) &&
        testNodes(node1, node2, 'elsePart', node1.elsePart, node2.elsePart);
  }

  @override
  bool visitImport(Import node1, covariant Import node2) {
    return visitLibraryDependency(node1, node2) &&
        testTokens(node1, node2, 'importKeyword', node1.importKeyword,
            node2.importKeyword) &&
        testNodes(node1, node2, 'prefix', node1.prefix, node2.prefix) &&
        strategy.test(
            node1, node2, 'isDeferred', node1.isDeferred, node2.isDeferred);
  }

  @override
  bool visitLabel(Label node1, covariant Label node2) {
    return testTokens(
            node1, node2, 'colonToken', node1.colonToken, node2.colonToken) &&
        testNodes(
            node1, node2, 'identifier', node1.identifier, node2.identifier);
  }

  @override
  bool visitLabeledStatement(
      LabeledStatement node1, covariant LabeledStatement node2) {
    return testNodes(node1, node2, 'labels', node1.labels, node2.labels) &&
        testNodes(node1, node2, 'statement', node1.statement, node2.statement);
  }

  @override
  bool visitLibraryDependency(
      LibraryDependency node1, covariant LibraryDependency node2) {
    return visitLibraryTag(node1, node2) &&
        testNodes(node1, node2, 'uri', node1.uri, node2.uri) &&
        testNodes(node1, node2, 'conditionalUris', node1.conditionalUris,
            node2.conditionalUris) &&
        testNodes(
            node1, node2, 'combinators', node1.combinators, node2.combinators);
  }

  @override
  bool visitLibraryName(LibraryName node1, covariant LibraryName node2) {
    return visitLibraryTag(node1, node2) &&
        testTokens(node1, node2, 'libraryKeyword', node1.libraryKeyword,
            node2.libraryKeyword) &&
        testNodes(node1, node2, 'name', node1.name, node2.name);
  }

  @override
  bool visitLibraryTag(LibraryTag node1, covariant LibraryTag node2) {
    // TODO(johnniwinther): Check metadata?
    return true;
  }

  @override
  bool visitLiteral(Literal node1, covariant Literal node2) {
    return testTokens(node1, node2, 'token', node1.token, node2.token);
  }

  @override
  bool visitLiteralBool(LiteralBool node1, covariant LiteralBool node2) {
    return visitLiteral(node1, node2);
  }

  @override
  bool visitLiteralDouble(LiteralDouble node1, covariant LiteralDouble node2) {
    return visitLiteral(node1, node2);
  }

  @override
  bool visitLiteralInt(LiteralInt node1, covariant LiteralInt node2) {
    return visitLiteral(node1, node2);
  }

  @override
  bool visitLiteralList(LiteralList node1, covariant LiteralList node2) {
    return testTokens(node1, node2, 'constKeyword', node1.constKeyword,
            node2.constKeyword) &&
        testNodes(node1, node2, 'typeArguments', node1.typeArguments,
            node2.typeArguments) &&
        testNodes(node1, node2, 'elements', node1.elements, node2.elements);
  }

  @override
  bool visitLiteralMap(LiteralMap node1, covariant LiteralMap node2) {
    return testTokens(node1, node2, 'constKeyword', node1.constKeyword,
            node2.constKeyword) &&
        testNodes(node1, node2, 'typeArguments', node1.typeArguments,
            node2.typeArguments) &&
        testNodes(node1, node2, 'entries', node1.entries, node2.entries);
  }

  @override
  bool visitLiteralMapEntry(
      LiteralMapEntry node1, covariant LiteralMapEntry node2) {
    return testTokens(
            node1, node2, 'colonToken', node1.colonToken, node2.colonToken) &&
        testNodes(node1, node2, 'key', node1.key, node2.key) &&
        testNodes(node1, node2, 'value', node1.value, node2.value);
  }

  @override
  bool visitLiteralNull(LiteralNull node1, covariant LiteralNull node2) {
    return visitLiteral(node1, node2);
  }

  @override
  bool visitLiteralString(LiteralString node1, covariant LiteralString node2) {
    return testTokens(node1, node2, 'token', node1.token, node2.token) &&
        strategy.test(
            node1, node2, 'dartString', node1.dartString, node2.dartString);
  }

  @override
  bool visitLiteralSymbol(LiteralSymbol node1, covariant LiteralSymbol node2) {
    return testTokens(
            node1, node2, 'hashToken', node1.hashToken, node2.hashToken) &&
        testNodes(
            node1, node2, 'identifiers', node1.identifiers, node2.identifiers);
  }

  @override
  bool visitLoop(Loop node1, covariant Loop node2) {
    return testNodes(
            node1, node2, 'condition', node1.condition, node2.condition) &&
        testNodes(node1, node2, 'body', node1.body, node2.body);
  }

  @override
  bool visitMetadata(Metadata node1, covariant Metadata node2) {
    return testTokens(node1, node2, 'token', node1.token, node2.token) &&
        testNodes(
            node1, node2, 'expression', node1.expression, node2.expression);
  }

  @override
  bool visitMixinApplication(
      MixinApplication node1, covariant MixinApplication node2) {
    return testNodes(
            node1, node2, 'superclass', node1.superclass, node2.superclass) &&
        testNodes(node1, node2, 'mixins', node1.mixins, node2.mixins);
  }

  @override
  bool visitModifiers(Modifiers node1, covariant Modifiers node2) {
    return strategy.test(node1, node2, 'flags', node1.flags, node2.flags) &&
        testNodes(node1, node2, 'nodes', node1.nodes, node2.nodes);
  }

  @override
  bool visitNamedArgument(NamedArgument node1, covariant NamedArgument node2) {
    return testTokens(
            node1, node2, 'colonToken', node1.colonToken, node2.colonToken) &&
        testNodes(node1, node2, 'name', node1.name, node2.name) &&
        testNodes(
            node1, node2, 'expression', node1.expression, node2.expression);
  }

  @override
  bool visitNamedMixinApplication(
      NamedMixinApplication node1, covariant NamedMixinApplication node2) {
    return testTokens(node1, node2, 'classKeyword', node1.classKeyword,
            node2.classKeyword) &&
        testTokens(node1, node2, 'endToken', node1.endToken, node2.endToken) &&
        testNodes(node1, node2, 'name', node1.name, node2.name) &&
        testNodes(node1, node2, 'typeParameters', node1.typeParameters,
            node2.typeParameters) &&
        testNodes(
            node1, node2, 'modifiers', node1.modifiers, node2.modifiers) &&
        testNodes(node1, node2, 'mixinApplication', node1.mixinApplication,
            node2.mixinApplication) &&
        testNodes(
            node1, node2, 'interfaces', node1.interfaces, node2.interfaces);
  }

  @override
  bool visitNewExpression(NewExpression node1, covariant NewExpression node2) {
    return testTokens(
            node1, node2, 'newToken', node1.newToken, node2.newToken) &&
        testNodes(node1, node2, 'send', node1.send, node2.send);
  }

  @override
  bool visitNodeList(NodeList node1, covariant NodeList node2) {
    return testTokens(
            node1, node2, 'beginToken', node1.beginToken, node2.beginToken) &&
        testTokens(node1, node2, 'endToken', node1.endToken, node2.endToken) &&
        strategy.test(
            node1, node2, 'delimiter', node1.delimiter, node2.delimiter) &&
        testNodeLists(node1, node2, 'nodes', node1.nodes, node2.nodes);
  }

  @override
  bool visitOperator(Operator node1, covariant Operator node2) {
    return visitIdentifier(node1, node2);
  }

  @override
  bool visitParenthesizedExpression(
      ParenthesizedExpression node1, covariant ParenthesizedExpression node2) {
    return testTokens(
            node1, node2, 'beginToken', node1.beginToken, node2.beginToken) &&
        testNodes(
            node1, node2, 'expression', node1.expression, node2.expression);
  }

  @override
  bool visitPart(Part node1, covariant Part node2) {
    return visitLibraryTag(node1, node2) &&
        testTokens(node1, node2, 'partKeyword', node1.partKeyword,
            node2.partKeyword) &&
        testNodes(node1, node2, 'uri', node1.uri, node2.uri);
  }

  @override
  bool visitPartOf(PartOf node1, covariant PartOf node2) {
    // TODO(johnniwinther): Check metadata?
    return testTokens(node1, node2, 'partKeyword', node1.partKeyword,
            node2.partKeyword) &&
        testNodes(node1, node2, 'name', node1.name, node2.name);
  }

  @override
  bool visitPostfix(Postfix node1, covariant Postfix node2) {
    return visitNodeList(node1, node2);
  }

  @override
  bool visitPrefix(Prefix node1, covariant Prefix node2) {
    return visitNodeList(node1, node2);
  }

  @override
  bool visitRedirectingFactoryBody(
      RedirectingFactoryBody node1, covariant RedirectingFactoryBody node2) {
    return testTokens(
            node1, node2, 'beginToken', node1.beginToken, node2.beginToken) &&
        testTokens(node1, node2, 'endToken', node1.endToken, node2.endToken) &&
        testNodes(node1, node2, 'constructorReference',
            node1.constructorReference, node2.constructorReference);
  }

  @override
  bool visitRethrow(Rethrow node1, covariant Rethrow node2) {
    return testTokens(
            node1, node2, 'throwToken', node1.throwToken, node2.throwToken) &&
        testTokens(node1, node2, 'endToken', node1.endToken, node2.endToken);
  }

  @override
  bool visitReturn(Return node1, covariant Return node2) {
    return testTokens(
            node1, node2, 'beginToken', node1.beginToken, node2.beginToken) &&
        testTokens(node1, node2, 'endToken', node1.endToken, node2.endToken) &&
        testNodes(
            node1, node2, 'expression', node1.expression, node2.expression);
  }

  @override
  bool visitSend(Send node1, covariant Send node2) {
    return strategy.test(node1, node2, 'isConditional', node1.isConditional,
            node2.isConditional) &&
        testNodes(node1, node2, 'receiver', node1.receiver, node2.receiver) &&
        testNodes(node1, node2, 'selector', node1.selector, node2.selector) &&
        testNodes(node1, node2, 'argumentsNode', node1.argumentsNode,
            node2.argumentsNode);
  }

  @override
  bool visitSendSet(SendSet node1, covariant SendSet node2) {
    return visitSend(node1, node2) &&
        testNodes(node1, node2, 'assignmentOperator', node1.assignmentOperator,
            node2.assignmentOperator);
  }

  @override
  bool visitStringInterpolation(
      StringInterpolation node1, covariant StringInterpolation node2) {
    return testNodes(node1, node2, 'string', node1.string, node2.string) &&
        testNodes(node1, node2, 'parts', node1.parts, node2.parts);
  }

  @override
  bool visitStringInterpolationPart(
      StringInterpolationPart node1, covariant StringInterpolationPart node2) {
    return testNodes(
        node1, node2, 'expression', node1.expression, node2.expression);
  }

  @override
  bool visitStringJuxtaposition(
      StringJuxtaposition node1, covariant StringJuxtaposition node2) {
    return testNodes(node1, node2, 'first', node1.first, node2.first) &&
        testNodes(node1, node2, 'second', node1.second, node2.second);
  }

  @override
  bool visitSwitchCase(SwitchCase node1, covariant SwitchCase node2) {
    return testTokens(node1, node2, 'defaultKeyword', node1.defaultKeyword,
            node2.defaultKeyword) &&
        testTokens(
            node1, node2, 'startToken', node1.startToken, node2.startToken) &&
        testNodes(node1, node2, 'labelsAndCases', node1.labelsAndCases,
            node2.labelsAndCases) &&
        testNodes(
            node1, node2, 'statements', node1.statements, node2.statements);
  }

  @override
  bool visitSwitchStatement(
      SwitchStatement node1, covariant SwitchStatement node2) {
    return testTokens(node1, node2, 'switchKeyword', node1.switchKeyword,
            node2.switchKeyword) &&
        testNodes(node1, node2, 'parenthesizedExpression',
            node1.parenthesizedExpression, node2.parenthesizedExpression) &&
        testNodes(node1, node2, 'cases', node1.cases, node2.cases);
  }

  @override
  bool visitSyncForIn(SyncForIn node1, covariant SyncForIn node2) {
    return visitForIn(node1, node2);
  }

  @override
  bool visitThrow(Throw node1, covariant Throw node2) {
    return testTokens(
            node1, node2, 'throwToken', node1.throwToken, node2.throwToken) &&
        testTokens(node1, node2, 'endToken', node1.endToken, node2.endToken) &&
        testNodes(
            node1, node2, 'expression', node1.expression, node2.expression);
  }

  @override
  bool visitTryStatement(TryStatement node1, covariant TryStatement node2) {
    return testTokens(
            node1, node2, 'tryKeyword', node1.tryKeyword, node2.tryKeyword) &&
        testTokens(node1, node2, 'finallyKeyword', node1.finallyKeyword,
            node2.finallyKeyword) &&
        testNodes(node1, node2, 'tryBlock', node1.tryBlock, node2.tryBlock) &&
        testNodes(node1, node2, 'catchBlocks', node1.catchBlocks,
            node2.catchBlocks) &&
        testNodes(node1, node2, 'finallyBlock', node1.finallyBlock,
            node2.finallyBlock);
  }

  @override
  bool visitNominalTypeAnnotation(
      NominalTypeAnnotation node1, covariant NominalTypeAnnotation node2) {
    return testNodes(
            node1, node2, 'typeName', node1.typeName, node2.typeName) &&
        testNodes(node1, node2, 'typeArguments', node1.typeArguments,
            node2.typeArguments);
  }

  @override
  bool visitFunctionTypeAnnotation(
      FunctionTypeAnnotation node1, covariant FunctionTypeAnnotation node2) {
    return testNodes(
            node1, node2, 'returnType', node1.returnType, node2.returnType) &&
        testNodes(node1, node2, 'formals', node1.formals, node2.formals) &&
        testNodes(node1, node2, 'typeParameters', node1.typeParameters,
            node2.typeParameters);
  }

  @override
  bool visitTypeVariable(TypeVariable node1, covariant TypeVariable node2) {
    return testNodes(node1, node2, 'name', node1.name, node2.name) &&
        testNodes(node1, node2, 'bound', node1.bound, node2.bound);
  }

  @override
  bool visitTypedef(Typedef node1, covariant Typedef node2) {
    return testTokens(node1, node2, 'typedefKeyword', node1.typedefKeyword,
            node2.typedefKeyword) &&
        testTokens(node1, node2, 'endToken', node1.endToken, node2.endToken) &&
        testNodes(
            node1, node2, 'returnType', node1.returnType, node2.returnType) &&
        testNodes(node1, node2, 'name', node1.name, node2.name) &&
        testNodes(node1, node2, 'typeParameters', node1.templateParameters,
            node2.templateParameters) &&
        testNodes(node1, node2, 'formals', node1.formals, node2.formals);
  }

  @override
  bool visitVariableDefinitions(
      VariableDefinitions node1, covariant VariableDefinitions node2) {
    return testNodes(
            node1, node2, 'metadata', node1.metadata, node2.metadata) &&
        testNodes(node1, node2, 'type', node1.type, node2.type) &&
        testNodes(
            node1, node2, 'modifiers', node1.modifiers, node2.modifiers) &&
        testNodes(
            node1, node2, 'definitions', node1.definitions, node2.definitions);
  }

  @override
  bool visitWhile(While node1, covariant While node2) {
    return testTokens(node1, node2, 'whileKeyword', node1.whileKeyword,
            node2.whileKeyword) &&
        testNodes(
            node1, node2, 'condition', node1.condition, node2.condition) &&
        testNodes(node1, node2, 'body', node1.body, node2.body);
  }

  @override
  bool visitYield(Yield node1, covariant Yield node2) {
    return testTokens(
            node1, node2, 'yieldToken', node1.yieldToken, node2.yieldToken) &&
        testTokens(
            node1, node2, 'starToken', node1.starToken, node2.starToken) &&
        testTokens(node1, node2, 'endToken', node1.endToken, node2.endToken) &&
        testNodes(
            node1, node2, 'expression', node1.expression, node2.expression);
  }

  @override
  bool visitNode(Node node1, covariant Node node2) {
    throw new UnsupportedError('Unexpected nodes: $node1 <> $node2');
  }

  @override
  bool visitExpression(Expression node1, covariant Expression node2) {
    throw new UnsupportedError('Unexpected nodes: $node1 <> $node2');
  }

  @override
  bool visitStatement(Statement node1, covariant Statement node2) {
    throw new UnsupportedError('Unexpected nodes: $node1 <> $node2');
  }

  @override
  bool visitStringNode(StringNode node1, covariant StringNode node2) {
    throw new UnsupportedError('Unexpected nodes: $node1 <> $node2');
  }

  @override
  bool visitTypeAnnotation(
      TypeAnnotation node1, covariant TypeAnnotation node2) {
    throw new UnsupportedError('Unexpected nodes: $node1 <> $node2');
  }
}

bool areMetadataAnnotationsEquivalent(
    MetadataAnnotation metadata1, MetadataAnnotation metadata2) {
  if (metadata1 == metadata2) return true;
  if (metadata1 == null || metadata2 == null) return false;
  return areElementsEquivalent(
          metadata1.annotatedElement, metadata2.annotatedElement) &&
      areConstantsEquivalent(metadata1.constant, metadata2.constant);
}
