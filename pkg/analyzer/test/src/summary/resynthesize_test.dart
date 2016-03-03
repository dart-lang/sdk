// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.src.serialization.elements_test;

import 'dart:convert';

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/member.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/generated/constant.dart' show DartObject;
import 'package:analyzer/src/generated/element_handle.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/resolver.dart'
    show Namespace, TypeProvider;
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/generated/testing/ast_factory.dart';
import 'package:analyzer/src/summary/idl.dart';
import 'package:analyzer/src/summary/resynthesize.dart';
import 'package:analyzer/src/summary/summarize_elements.dart';
import 'package:unittest/unittest.dart';

import '../../generated/resolver_test.dart';
import '../../reflective_tests.dart';
import 'summary_common.dart' show canonicalize;

main() {
  groupSep = ' | ';
  runReflectiveTests(ResynthTest);
}

@reflectiveTest
class ResynthTest extends ResolverTestCase {
  Set<Source> otherLibrarySources = new Set<Source>();
  bool constantInitializersAreInvalid = false;

  void addLibrary(String uri) {
    otherLibrarySources.add(analysisContext2.sourceFactory.forUri(uri));
  }

  void addLibrarySource(String filePath, String contents) {
    otherLibrarySources.add(addNamedSource(filePath, contents));
  }

  /**
   * Verify that the given prefix is safe to elide from a resynthesized AST.
   */
  void checkElidablePrefix(SimpleIdentifier prefix) {
    if (prefix.staticElement is! PrefixElement &&
        prefix.staticElement is! ClassElement) {
      fail('Prefix of type ${prefix.staticElement.runtimeType}'
          ' should not have been elided');
    }
  }

  void checkLibrary(String text,
      {bool allowErrors: false, bool dumpSummaries: false}) {
    Source source = addSource(text);
    LibraryElementImpl original = resolve2(source);
    LibraryElementImpl resynthesized = resynthesizeLibraryElement(
        encodeLibrary(original,
            allowErrors: allowErrors, dumpSummaries: dumpSummaries),
        source.uri.toString(),
        original);
    checkLibraryElements(original, resynthesized);
  }

  void checkLibraryElements(
      LibraryElementImpl original, LibraryElementImpl resynthesized) {
    compareElements(resynthesized, original, '(library)');
    expect(resynthesized.displayName, original.displayName);
    expect(original.enclosingElement, isNull);
    expect(resynthesized.enclosingElement, isNull);
    expect(resynthesized.hasExtUri, original.hasExtUri);
    compareCompilationUnitElements(resynthesized.definingCompilationUnit,
        original.definingCompilationUnit);
    expect(resynthesized.parts.length, original.parts.length);
    for (int i = 0; i < resynthesized.parts.length; i++) {
      compareCompilationUnitElements(resynthesized.parts[i], original.parts[i]);
    }
    expect(resynthesized.imports.length, original.imports.length);
    for (int i = 0; i < resynthesized.imports.length; i++) {
      compareImportElements(resynthesized.imports[i], original.imports[i],
          'import ${original.imports[i].uri}');
    }
    expect(resynthesized.exports.length, original.exports.length);
    for (int i = 0; i < resynthesized.exports.length; i++) {
      compareExportElements(resynthesized.exports[i], original.exports[i],
          'export ${original.exports[i].uri}');
    }
    expect(resynthesized.nameLength, original.nameLength);
    compareNamespaces(resynthesized.publicNamespace, original.publicNamespace,
        '(public namespace)');
    compareNamespaces(resynthesized.exportNamespace, original.exportNamespace,
        '(export namespace)');
    if (original.entryPoint == null) {
      expect(resynthesized.entryPoint, isNull);
    } else {
      expect(resynthesized.entryPoint, isNotNull);
      compareFunctionElements(
          resynthesized.entryPoint, original.entryPoint, '(entry point)');
    }
    // The libraries `dart:core` and `dart:async` cannot create their
    // `loadLibrary` functions until after both are created.
    if (original.name != 'dart.core' && original.name != 'dart.async') {
      compareExecutableElements(
          resynthesized.loadLibraryFunction as ExecutableElementImpl,
          original.loadLibraryFunction as ExecutableElementImpl,
          '(loadLibraryFunction)');
    }
    expect(resynthesized.libraryCycle.toSet(), original.libraryCycle.toSet());
  }

  /**
   * Verify that the [resynthesizer] didn't do any unnecessary work when
   * resynthesizing [library].
   */
  void checkMinimalResynthesisWork(
      _TestSummaryResynthesizer resynthesizer, LibraryElement library) {
    // Check that no other summaries needed to be resynthesized to resynthesize
    // the library element.
    expect(resynthesizer.resynthesisCount, 1);
    // Check that the only linked summary consulted was that for [uri].
    expect(resynthesizer.linkedSummariesRequested, hasLength(1));
    expect(resynthesizer.linkedSummariesRequested.first,
        library.source.uri.toString());
    // Check that the only unlinked summaries consulted were those for the
    // library in question.
    Set<String> expectedCompilationUnitUris = library.units
        .map((CompilationUnitElement unit) => unit.source.uri.toString())
        .toSet();
    for (String requestedUri in resynthesizer.unlinkedSummariesRequested) {
      expect(expectedCompilationUnitUris, contains(requestedUri));
    }
  }

  void checkPossibleLocalElements(Element resynthesized, Element original) {
    if (original is! LocalElement && resynthesized is! LocalElement) {
      return;
    }
    if (original is LocalElement && resynthesized is LocalElement) {
      expect(resynthesized.visibleRange, original.visibleRange);
    } else {
      fail('Incompatible local elements '
          '${resynthesized.runtimeType} vs. ${original.runtimeType}');
    }
  }

  void checkPossibleMember(
      Element resynthesized, Element original, String desc) {
    Element resynthesizedNonHandle = resynthesized is ElementHandle
        ? resynthesized.actualElement
        : resynthesized;
    if (original is Member) {
      expect(resynthesizedNonHandle, new isInstanceOf<Member>(), reason: desc);
      if (resynthesizedNonHandle is Member) {
        List<DartType> resynthesizedTypeArguments =
            resynthesizedNonHandle.definingType.typeArguments;
        List<DartType> originalTypeArguments =
            original.definingType.typeArguments;
        expect(
            resynthesizedTypeArguments, hasLength(originalTypeArguments.length),
            reason: desc);
        for (int i = 0; i < originalTypeArguments.length; i++) {
          compareTypeImpls(resynthesizedTypeArguments[i],
              originalTypeArguments[i], '$desc type argument $i');
        }
      }
    } else {
      expect(
          resynthesizedNonHandle, isNot(new isInstanceOf<ConstructorMember>()),
          reason: desc);
    }
  }

  void compareClassElements(
      ClassElementImpl resynthesized, ClassElementImpl original, String desc) {
    compareElements(resynthesized, original, desc);
    expect(resynthesized.fields.length, original.fields.length,
        reason: '$desc fields.length');
    for (int i = 0; i < resynthesized.fields.length; i++) {
      String name = original.fields[i].name;
      compareFieldElements(
          resynthesized.fields[i], original.fields[i], '$desc.field $name');
    }
    compareTypes(
        resynthesized.supertype, original.supertype, '$desc supertype');
    expect(resynthesized.interfaces.length, original.interfaces.length);
    for (int i = 0; i < resynthesized.interfaces.length; i++) {
      compareTypes(resynthesized.interfaces[i], original.interfaces[i],
          '$desc interface ${original.interfaces[i].name}');
    }
    expect(resynthesized.mixins.length, original.mixins.length);
    for (int i = 0; i < resynthesized.mixins.length; i++) {
      compareTypes(resynthesized.mixins[i], original.mixins[i],
          '$desc mixin ${original.mixins[i].name}');
    }
    expect(resynthesized.typeParameters.length, original.typeParameters.length);
    for (int i = 0; i < resynthesized.typeParameters.length; i++) {
      compareTypeParameterElements(
          resynthesized.typeParameters[i],
          original.typeParameters[i],
          '$desc type parameter ${original.typeParameters[i].name}');
    }
    expect(resynthesized.constructors.length, original.constructors.length,
        reason: '$desc constructors.length');
    for (int i = 0; i < resynthesized.constructors.length; i++) {
      compareConstructorElements(
          resynthesized.constructors[i],
          original.constructors[i],
          '$desc constructor ${original.constructors[i].name}');
    }
    expect(resynthesized.accessors.length, original.accessors.length);
    for (int i = 0; i < resynthesized.accessors.length; i++) {
      comparePropertyAccessorElements(
          resynthesized.accessors[i],
          original.accessors[i],
          '$desc accessor ${original.accessors[i].name}');
    }
    expect(resynthesized.methods.length, original.methods.length);
    for (int i = 0; i < resynthesized.methods.length; i++) {
      compareMethodElements(resynthesized.methods[i], original.methods[i],
          '$desc.${original.methods[i].name}');
    }
    compareTypes(resynthesized.type, original.type, desc);
    expect(resynthesized.hasBeenInferred, original.hasBeenInferred,
        reason: desc);
  }

  void compareCompilationUnitElements(CompilationUnitElementImpl resynthesized,
      CompilationUnitElementImpl original) {
    String desc = 'Compilation unit ${original.source.uri}';
    compareUriReferencedElements(resynthesized, original, desc);
    expect(resynthesized.source, original.source);
    expect(resynthesized.librarySource, original.librarySource);
    expect(resynthesized.types.length, original.types.length);
    for (int i = 0; i < resynthesized.types.length; i++) {
      compareClassElements(
          resynthesized.types[i], original.types[i], original.types[i].name);
    }
    expect(resynthesized.topLevelVariables.length,
        original.topLevelVariables.length);
    for (int i = 0; i < resynthesized.topLevelVariables.length; i++) {
      String name = resynthesized.topLevelVariables[i].name;
      compareTopLevelVariableElements(
          resynthesized.topLevelVariables[i],
          original.topLevelVariables
              .singleWhere((TopLevelVariableElement e) => e.name == name),
          'variable $name');
    }
    expect(resynthesized.functions.length, original.functions.length);
    for (int i = 0; i < resynthesized.functions.length; i++) {
      compareFunctionElements(resynthesized.functions[i], original.functions[i],
          'function ${original.functions[i].name}');
    }
    expect(resynthesized.functionTypeAliases.length,
        original.functionTypeAliases.length);
    for (int i = 0; i < resynthesized.functionTypeAliases.length; i++) {
      compareFunctionTypeAliasElements(
          resynthesized.functionTypeAliases[i],
          original.functionTypeAliases[i],
          original.functionTypeAliases[i].name);
    }
    expect(resynthesized.enums.length, original.enums.length);
    for (int i = 0; i < resynthesized.enums.length; i++) {
      compareClassElements(
          resynthesized.enums[i], original.enums[i], original.enums[i].name);
    }
    expect(resynthesized.accessors.length, original.accessors.length);
    for (int i = 0; i < resynthesized.accessors.length; i++) {
      String name = resynthesized.accessors[i].name;
      if (original.accessors[i].isGetter) {
        comparePropertyAccessorElements(
            resynthesized.accessors[i],
            original.accessors
                .singleWhere((PropertyAccessorElement e) => e.name == name),
            'getter $name');
      } else {
        comparePropertyAccessorElements(
            resynthesized.accessors[i],
            original.accessors
                .singleWhere((PropertyAccessorElement e) => e.name == name),
            'setter $name');
      }
    }
    // Note: no need to test CompilationUnitElementImpl._offsetToElementMap
    // since it is built on demand when needed (see
    // CompilationUnitElementImpl.getElementAt])
  }

  void compareConstAstLists(
      List<Object> rItems, List<Object> oItems, String desc) {
    if (rItems == null && oItems == null) {
      return;
    }
    expect(rItems != null && oItems != null, isTrue);
    expect(rItems, hasLength(oItems.length));
    for (int i = 0; i < oItems.length; i++) {
      Object rItem = rItems[i];
      Object oItem = oItems[i];
      if (rItem is Expression && oItem is Expression) {
        compareConstAsts(rItem, oItem, desc);
      } else if (rItem is TypeName && oItem is TypeName) {
        compareConstAsts(rItem.name, oItem.name, desc);
      } else if (rItem is InterpolationString && oItem is InterpolationString) {
        expect(rItem.value, oItem.value);
      } else if (rItem is InterpolationExpression &&
          oItem is InterpolationExpression) {
        compareConstAsts(rItem.expression, oItem.expression, desc);
      } else if (rItem is MapLiteralEntry && oItem is MapLiteralEntry) {
        compareConstAsts(rItem.key, oItem.key, desc);
        compareConstAsts(rItem.value, oItem.value, desc);
      } else if (oItem is ConstructorFieldInitializer &&
          rItem is ConstructorFieldInitializer) {
        compareConstAsts(rItem.fieldName, oItem.fieldName, desc);
        if (constantInitializersAreInvalid) {
          _assertUnresolvedIdentifier(rItem.expression, desc);
        } else {
          compareConstAsts(rItem.expression, oItem.expression, desc);
        }
      } else if (oItem is SuperConstructorInvocation &&
          rItem is SuperConstructorInvocation) {
        compareElements(rItem.staticElement, oItem.staticElement, desc);
        compareConstAsts(rItem.constructorName, oItem.constructorName, desc);
        compareConstAstLists(
            rItem.argumentList.arguments, oItem.argumentList.arguments, desc);
      } else if (oItem is RedirectingConstructorInvocation &&
          rItem is RedirectingConstructorInvocation) {
        compareElements(rItem.staticElement, oItem.staticElement, desc);
        compareConstAsts(rItem.constructorName, oItem.constructorName, desc);
        compareConstAstLists(
            rItem.argumentList.arguments, oItem.argumentList.arguments, desc);
      } else {
        fail('$desc Incompatible item types: '
            '${rItem.runtimeType} vs. ${oItem.runtimeType}');
      }
    }
  }

  void compareConstAsts(AstNode r, AstNode o, String desc) {
    if (o == null) {
      expect(r, isNull, reason: desc);
    } else {
      expect(r, isNotNull, reason: desc);
      // ConstantAstCloner does not copy static types, and constant values
      // computer does not use static types. So, we don't set them during
      // resynthesis and should not check them here.
      if (o is ParenthesizedExpression) {
        // We don't resynthesize parenthesis, so just ignore it.
        compareConstAsts(r, o.expression, desc);
      } else if (o is SimpleIdentifier && r is SimpleIdentifier) {
        expect(r.name, o.name, reason: desc);
        compareElements(r.staticElement, o.staticElement, desc);
      } else if (o is PrefixedIdentifier && r is SimpleIdentifier) {
        // We don't resynthesize prefixed identifiers when the prefix refers to
        // a PrefixElement or a ClassElement.  We use simple identifiers with
        // correct elements.
        if (o.prefix.staticElement is PrefixElement ||
            o.prefix.staticElement is ClassElement) {
          compareConstAsts(r, o.identifier, desc);
        } else {
          fail('Prefix of type ${o.prefix.staticElement.runtimeType} should not'
              ' have been elided');
        }
      } else if (o is PropertyAccess &&
          o.target is PrefixedIdentifier &&
          r is PrefixedIdentifier) {
        // We don't resynthesize prefixed identifiers when the prefix refers to
        // a PrefixElement or a ClassElement.  Which means that if the original
        // expression was e.g. `prefix.topLevelVariableName.length`, it will get
        // resynthesized as `topLevelVariableName.length`
        PrefixedIdentifier oTarget = o.target;
        checkElidablePrefix(oTarget.prefix);
        compareConstAsts(
            r, AstFactory.identifier(oTarget.identifier, o.propertyName), desc);
      } else if (o is PrefixedIdentifier && r is PrefixedIdentifier) {
        compareConstAsts(r.prefix, o.prefix, desc);
        compareConstAsts(r.identifier, o.identifier, desc);
      } else if (o is PropertyAccess && r is PropertyAccess) {
        compareConstAsts(r.target, o.target, desc);
        expect(r.propertyName.name, o.propertyName.name, reason: desc);
        compareElements(
            r.propertyName.staticElement, o.propertyName.staticElement, desc);
      } else if (o is PropertyAccess &&
          o.target is PrefixedIdentifier &&
          r is SimpleIdentifier) {
        // We don't resynthesize property access when it takes the form
        // `prefixName.className.staticMember`.  We just resynthesize a
        // SimpleIdentifier correctly resolved to the static member.
        PrefixedIdentifier oTarget = o.target;
        checkElidablePrefix(oTarget.prefix);
        checkElidablePrefix(oTarget.identifier);
        compareConstAsts(r, o.propertyName, desc);
      } else if (o is NullLiteral) {
        expect(r, new isInstanceOf<NullLiteral>(), reason: desc);
      } else if (o is BooleanLiteral && r is BooleanLiteral) {
        expect(r.value, o.value, reason: desc);
      } else if (o is IntegerLiteral && r is IntegerLiteral) {
        expect(r.value, o.value, reason: desc);
      } else if (o is DoubleLiteral && r is DoubleLiteral) {
        if (r.value != null &&
            r.value.isNaN &&
            o.value != null &&
            o.value.isNaN) {
          // NaN is not comparable.
        } else {
          expect(r.value, o.value, reason: desc);
        }
      } else if (o is StringInterpolation && r is StringInterpolation) {
        compareConstAstLists(r.elements, o.elements, desc);
      } else if (o is StringLiteral && r is StringLiteral) {
        // We don't keep all the tokens of AdjacentStrings.
        // So, we can compare only their values.
        expect(r.stringValue, o.stringValue, reason: desc);
      } else if (o is SymbolLiteral && r is SymbolLiteral) {
        // We don't keep all the tokens of symbol literals.
        // So, we can compare only their values.
        expect(r.components.map((t) => t.lexeme).join('.'),
            o.components.map((t) => t.lexeme).join('.'),
            reason: desc);
      } else if (o is NamedExpression && r is NamedExpression) {
        expect(r.name.label.name, o.name.label.name, reason: desc);
        compareConstAsts(r.expression, o.expression, desc);
      } else if (o is BinaryExpression && r is BinaryExpression) {
        expect(r.operator.lexeme, o.operator.lexeme, reason: desc);
        compareConstAsts(r.leftOperand, o.leftOperand, desc);
        compareConstAsts(r.rightOperand, o.rightOperand, desc);
      } else if (o is PrefixExpression && r is PrefixExpression) {
        expect(r.operator.lexeme, o.operator.lexeme, reason: desc);
        compareConstAsts(r.operand, o.operand, desc);
      } else if (o is ConditionalExpression && r is ConditionalExpression) {
        compareConstAsts(r.condition, o.condition, desc);
        compareConstAsts(r.thenExpression, o.thenExpression, desc);
        compareConstAsts(r.elseExpression, o.elseExpression, desc);
      } else if (o is ListLiteral && r is ListLiteral) {
        compareConstAstLists(
            r.typeArguments?.arguments, o.typeArguments?.arguments, desc);
        compareConstAstLists(r.elements, o.elements, desc);
      } else if (o is MapLiteral && r is MapLiteral) {
        compareConstAstLists(
            r.typeArguments?.arguments, o.typeArguments?.arguments, desc);
        compareConstAstLists(r.entries, o.entries, desc);
      } else if (o is InstanceCreationExpression &&
          r is InstanceCreationExpression) {
        compareElements(r.staticElement, o.staticElement, desc);
        ConstructorName oConstructor = o.constructorName;
        ConstructorName rConstructor = r.constructorName;
        expect(oConstructor, isNotNull, reason: desc);
        expect(rConstructor, isNotNull, reason: desc);
        // Note: just compare rConstructor.staticElement and
        // oConstructor.staticElement as elements, because we just want to
        // check that they're pointing to the correct elements; we don't want
        // to check that their constructor initializers match, because that
        // could lead to infinite regress.
        compareElements(
            rConstructor.staticElement, oConstructor.staticElement, desc);
        TypeName oType = oConstructor.type;
        TypeName rType = rConstructor.type;
        expect(oType, isNotNull, reason: desc);
        expect(rType, isNotNull, reason: desc);
        compareConstAsts(rType.name, oType.name, desc);
        compareConstAsts(rConstructor.name, oConstructor.name, desc);
        compareConstAstLists(rType.typeArguments?.arguments,
            oType.typeArguments?.arguments, desc);
        compareConstAstLists(
            r.argumentList.arguments, o.argumentList.arguments, desc);
      } else if (o is AnnotationImpl && r is AnnotationImpl) {
        expect(o.atSign.lexeme, r.atSign.lexeme, reason: desc);
        Identifier rName = r.name;
        Identifier oName = o.name;
        if (oName is PrefixedIdentifier && o.constructorName != null) {
          // E.g. `@prefix.cls.ctor`.  This gets resynthesized as `@cls.ctor`,
          // with `cls.ctor` represented as a PrefixedIdentifier.
          expect(rName, new isInstanceOf<PrefixedIdentifier>(), reason: desc);
          if (rName is PrefixedIdentifier) {
            compareConstAsts(rName.prefix, oName.identifier, desc);
            expect(rName.period.lexeme, '.', reason: desc);
            compareConstAsts(rName.identifier, o.constructorName, desc);
            expect(r.period, isNull, reason: desc);
            expect(r.constructorName, isNull, reason: desc);
          }
        } else {
          compareConstAsts(r.name, o.name, desc);
          expect(r.period?.lexeme, o.period?.lexeme, reason: desc);
          compareConstAsts(r.constructorName, o.constructorName, desc);
        }
        compareConstAstLists(
            r.arguments?.arguments, o.arguments?.arguments, desc);
        Element expectedElement = o.element;
        if (oName is PrefixedIdentifier && o.constructorName != null) {
          // Due to dartbug.com/25706, [o.element] incorrectly points to the
          // class rather than the named constructor.  Hack around this.
          // TODO(paulberry): when dartbug.com/25706 is fixed, remove this.
          expectedElement = (expectedElement as ClassElement)
              .getNamedConstructor(o.constructorName.name);
          expect(expectedElement, isNotNull, reason: desc);
        }
        compareElements(r.element, expectedElement, desc);
        // elementAnnotation should be null; it is only used in the full AST.
        expect(o.elementAnnotation, isNull);
        expect(r.elementAnnotation, isNull);
      } else {
        fail('Not implemented for ${r.runtimeType} vs. ${o.runtimeType}');
      }
    }
  }

  void compareConstructorElements(ConstructorElement resynthesized,
      ConstructorElement original, String desc) {
    if (original == null && resynthesized == null) {
      return;
    }
    compareExecutableElements(resynthesized, original, desc);
    ConstructorElementImpl resynthesizedImpl =
        getActualElement(resynthesized, desc);
    ConstructorElementImpl originalImpl = getActualElement(original, desc);
    if (original.isConst) {
      compareConstAstLists(resynthesizedImpl.constantInitializers,
          originalImpl.constantInitializers, desc);
    }
    if (original.redirectedConstructor == null) {
      expect(resynthesized.redirectedConstructor, isNull, reason: desc);
    } else {
      compareConstructorElements(resynthesized.redirectedConstructor,
          original.redirectedConstructor, '$desc redirectedConstructor');
    }
    checkPossibleMember(resynthesized, original, desc);
    expect(resynthesized.nameEnd, original.nameEnd, reason: desc);
    expect(resynthesized.periodOffset, original.periodOffset, reason: desc);
    expect(resynthesizedImpl.isCycleFree, originalImpl.isCycleFree,
        reason: desc);
  }

  void compareConstValues(
      DartObject resynthesized, DartObject original, String desc) {
    if (original == null) {
      expect(resynthesized, isNull, reason: desc);
    } else {
      expect(resynthesized, isNotNull, reason: desc);
      compareTypes(resynthesized.type, original.type, desc);
      expect(resynthesized.hasKnownValue, original.hasKnownValue, reason: desc);
      if (original.isNull) {
        expect(resynthesized.isNull, isTrue, reason: desc);
      } else if (original.toBoolValue() != null) {
        expect(resynthesized.toBoolValue(), original.toBoolValue(),
            reason: desc);
      } else if (original.toIntValue() != null) {
        expect(resynthesized.toIntValue(), original.toIntValue(), reason: desc);
      } else if (original.toDoubleValue() != null) {
        expect(resynthesized.toDoubleValue(), original.toDoubleValue(),
            reason: desc);
      } else if (original.toListValue() != null) {
        List<DartObject> resynthesizedList = resynthesized.toListValue();
        List<DartObject> originalList = original.toListValue();
        expect(resynthesizedList, hasLength(originalList.length));
        for (int i = 0; i < originalList.length; i++) {
          compareConstValues(resynthesizedList[i], originalList[i], desc);
        }
      } else if (original.toMapValue() != null) {
        Map<DartObject, DartObject> resynthesizedMap =
            resynthesized.toMapValue();
        Map<DartObject, DartObject> originalMap = original.toMapValue();
        expect(resynthesizedMap, hasLength(originalMap.length));
        List<DartObject> resynthesizedKeys = resynthesizedMap.keys.toList();
        List<DartObject> originalKeys = originalMap.keys.toList();
        for (int i = 0; i < originalKeys.length; i++) {
          DartObject resynthesizedKey = resynthesizedKeys[i];
          DartObject originalKey = originalKeys[i];
          compareConstValues(resynthesizedKey, originalKey, desc);
          DartObject resynthesizedValue = resynthesizedMap[resynthesizedKey];
          DartObject originalValue = originalMap[originalKey];
          compareConstValues(resynthesizedValue, originalValue, desc);
        }
      } else if (original.toStringValue() != null) {
        expect(resynthesized.toStringValue(), original.toStringValue(),
            reason: desc);
      } else if (original.toSymbolValue() != null) {
        expect(resynthesized.toSymbolValue(), original.toSymbolValue(),
            reason: desc);
      } else if (original.toTypeValue() != null) {
        fail('Not implemented');
      }
    }
  }

  void compareElementAnnotations(ElementAnnotationImpl resynthesized,
      ElementAnnotationImpl original, String desc) {
    expect(resynthesized.element, isNotNull, reason: desc);
    expect(resynthesized.element.kind, original.element.kind, reason: desc);
    expect(resynthesized.element.location, original.element.location,
        reason: desc);
    expect(resynthesized.compilationUnit, isNotNull, reason: desc);
    expect(resynthesized.compilationUnit.location,
        original.compilationUnit.location,
        reason: desc);
    expect(resynthesized.annotationAst, isNotNull, reason: desc);
    compareConstAsts(resynthesized.annotationAst, original.annotationAst, desc);
  }

  void compareElements(Element resynthesized, Element original, String desc) {
    ElementImpl rImpl = getActualElement(resynthesized, desc);
    ElementImpl oImpl = getActualElement(original, desc);
    if (oImpl == null && rImpl == null) {
      return;
    }
    if (oImpl is PrefixElement) {
      // TODO(scheglov) prefixes cannot be resynthesized
      return;
    }
    expect(original, isNotNull);
    expect(resynthesized, isNotNull);
    expect(rImpl.runtimeType, oImpl.runtimeType);
    expect(resynthesized.kind, original.kind);
    expect(resynthesized.location, original.location, reason: desc);
    expect(resynthesized.name, original.name);
    expect(resynthesized.nameOffset, original.nameOffset, reason: desc);
    expect(resynthesized.documentationComment, original.documentationComment,
        reason: desc);
    expect(resynthesized.docRange, original.docRange, reason: desc);
    compareMetadata(resynthesized.metadata, original.metadata, desc);
    // Modifiers are a pain to test via handles.  So just test them via the
    // actual element.
    for (Modifier modifier in Modifier.persistedValues) {
      bool got = rImpl.hasModifier(modifier);
      bool want = oImpl.hasModifier(modifier);
      expect(got, want,
          reason: 'Mismatch in $desc.$modifier: got $got, want $want');
    }
    for (Modifier modifier in Modifier.transientValues) {
      bool got = rImpl.hasModifier(modifier);
      bool want = false;
      expect(got, false,
          reason: 'Mismatch in $desc.$modifier: got $got, want $want');
    }

    // Validate members.
    if (oImpl is Member) {
      expect(rImpl, new isInstanceOf<Member>(), reason: desc);
    } else {
      expect(rImpl, isNot(new isInstanceOf<Member>()), reason: desc);
    }
  }

  void compareExecutableElements(
      ExecutableElement resynthesized, ExecutableElement original, String desc,
      {bool shallow: false}) {
    compareElements(resynthesized, original, desc);
    compareParameterElementLists(
        resynthesized.parameters, original.parameters, desc);
    compareTypes(
        resynthesized.returnType, original.returnType, '$desc return type');
    if (!shallow) {
      compareTypes(resynthesized.type, original.type, desc);
    }
    expect(resynthesized.typeParameters.length, original.typeParameters.length);
    for (int i = 0; i < resynthesized.typeParameters.length; i++) {
      compareTypeParameterElements(
          resynthesized.typeParameters[i],
          original.typeParameters[i],
          '$desc type parameter ${original.typeParameters[i].name}');
    }
    if (original is! Member) {
      List<FunctionElement> rFunctions = resynthesized.functions;
      List<FunctionElement> oFunctions = original.functions;
      expect(rFunctions, hasLength(oFunctions.length));
      for (int i = 0; i < oFunctions.length; i++) {
        compareFunctionElements(rFunctions[i], oFunctions[i],
            '$desc local function ${oFunctions[i].name}');
      }
    }
    if (original is! Member) {
      List<LabelElement> rLabels = resynthesized.labels;
      List<LabelElement> oLabels = original.labels;
      expect(rLabels, hasLength(oLabels.length));
      for (int i = 0; i < oLabels.length; i++) {
        compareLabelElements(
            rLabels[i], oLabels[i], '$desc label ${oLabels[i].name}');
      }
    }
    if (original is! Member) {
      List<LocalVariableElement> rVariables = resynthesized.localVariables;
      List<LocalVariableElement> oVariables = original.localVariables;
      expect(rVariables, hasLength(oVariables.length));
      for (int i = 0; i < oVariables.length; i++) {
        compareVariableElements(rVariables[i], oVariables[i],
            '$desc local variable ${oVariables[i].name}');
      }
    }
  }

  void compareExportElements(ExportElementImpl resynthesized,
      ExportElementImpl original, String desc) {
    compareUriReferencedElements(resynthesized, original, desc);
    expect(resynthesized.exportedLibrary.location,
        original.exportedLibrary.location);
    expect(resynthesized.combinators.length, original.combinators.length);
    for (int i = 0; i < resynthesized.combinators.length; i++) {
      compareNamespaceCombinators(
          resynthesized.combinators[i], original.combinators[i]);
    }
  }

  void compareFieldElements(
      FieldElementImpl resynthesized, FieldElementImpl original, String desc) {
    comparePropertyInducingElements(resynthesized, original, desc);
  }

  void compareFunctionElements(
      FunctionElement resynthesized, FunctionElement original, String desc,
      {bool shallow: false}) {
    if (original == null && resynthesized == null) {
      return;
    }
    expect(resynthesized, isNotNull, reason: desc);
    compareExecutableElements(resynthesized, original, desc, shallow: shallow);
    checkPossibleLocalElements(resynthesized, original);
  }

  void compareFunctionTypeAliasElements(
      FunctionTypeAliasElementImpl resynthesized,
      FunctionTypeAliasElementImpl original,
      String desc) {
    compareElements(resynthesized, original, desc);
    compareParameterElementLists(
        resynthesized.parameters, original.parameters, desc);
    compareTypes(
        resynthesized.returnType, original.returnType, '$desc return type');
    compareTypes(resynthesized.type, original.type, desc);
    expect(resynthesized.typeParameters.length, original.typeParameters.length);
    for (int i = 0; i < resynthesized.typeParameters.length; i++) {
      compareTypeParameterElements(
          resynthesized.typeParameters[i],
          original.typeParameters[i],
          '$desc type parameter ${original.typeParameters[i].name}');
    }
  }

  void compareImportElements(ImportElementImpl resynthesized,
      ImportElementImpl original, String desc) {
    compareUriReferencedElements(resynthesized, original, desc);
    expect(resynthesized.importedLibrary.location,
        original.importedLibrary.location);
    expect(resynthesized.prefixOffset, original.prefixOffset);
    if (original.prefix == null) {
      expect(resynthesized.prefix, isNull);
    } else {
      comparePrefixElements(
          resynthesized.prefix, original.prefix, original.prefix.name);
    }
    expect(resynthesized.combinators.length, original.combinators.length);
    for (int i = 0; i < resynthesized.combinators.length; i++) {
      compareNamespaceCombinators(
          resynthesized.combinators[i], original.combinators[i]);
    }
  }

  void compareLabelElements(
      LabelElementImpl resynthesized, LabelElementImpl original, String desc) {
    expect(resynthesized.isOnSwitchMember, original.isOnSwitchMember,
        reason: desc);
    expect(resynthesized.isOnSwitchStatement, original.isOnSwitchStatement,
        reason: desc);
    compareElements(resynthesized, original, desc);
  }

  void compareMetadata(List<ElementAnnotation> resynthesized,
      List<ElementAnnotation> original, String desc) {
    expect(resynthesized, hasLength(original.length), reason: desc);
    for (int i = 0; i < original.length; i++) {
      compareElementAnnotations(
          resynthesized[i], original[i], '$desc annotation $i');
    }
  }

  void compareMethodElements(MethodElementImpl resynthesized,
      MethodElementImpl original, String desc) {
    // TODO(paulberry): do we need to deal with
    // MultiplyInheritedMethodElementImpl?
    compareExecutableElements(resynthesized, original, desc);
  }

  void compareNamespaceCombinators(
      NamespaceCombinator resynthesized, NamespaceCombinator original) {
    if (original is ShowElementCombinatorImpl &&
        resynthesized is ShowElementCombinatorImpl) {
      expect(resynthesized.shownNames, original.shownNames);
      expect(resynthesized.offset, original.offset);
      expect(resynthesized.end, original.end);
    } else if (original is HideElementCombinatorImpl &&
        resynthesized is HideElementCombinatorImpl) {
      expect(resynthesized.hiddenNames, original.hiddenNames);
    } else if (resynthesized.runtimeType != original.runtimeType) {
      fail(
          'Type mismatch: expected ${original.runtimeType}, got ${resynthesized.runtimeType}');
    } else {
      fail('Unimplemented comparison for ${original.runtimeType}');
    }
  }

  void compareNamespaces(
      Namespace resynthesized, Namespace original, String desc) {
    Map<String, Element> resynthesizedMap = resynthesized.definedNames;
    Map<String, Element> originalMap = original.definedNames;
    expect(resynthesizedMap.keys.toSet(), originalMap.keys.toSet(),
        reason: desc);
    for (String key in originalMap.keys) {
      Element resynthesizedElement = resynthesizedMap[key];
      Element originalElement = originalMap[key];
      compareElements(resynthesizedElement, originalElement, key);
    }
  }

  void compareParameterElementLists(
      List<ParameterElement> resynthesizedParameters,
      List<ParameterElement> originalParameters,
      String desc) {
    expect(resynthesizedParameters.length, originalParameters.length);
    for (int i = 0; i < resynthesizedParameters.length; i++) {
      compareParameterElements(
          resynthesizedParameters[i],
          originalParameters[i],
          '$desc parameter ${originalParameters[i].name}');
    }
  }

  void compareParameterElements(
      ParameterElement resynthesized, ParameterElement original, String desc) {
    compareVariableElements(resynthesized, original, desc);
    compareParameterElementLists(
        resynthesized.parameters, original.parameters, desc);
    expect(resynthesized.parameterKind, original.parameterKind);
    expect(resynthesized.isInitializingFormal, original.isInitializingFormal,
        reason: desc);
    expect(resynthesized is FieldFormalParameterElementImpl,
        original is FieldFormalParameterElementImpl);
    if (resynthesized is FieldFormalParameterElementImpl &&
        original is FieldFormalParameterElementImpl) {
      if (original.field == null) {
        expect(resynthesized.field, isNull, reason: '$desc field');
      } else {
        expect(resynthesized.field, isNotNull, reason: '$desc field');
        compareFieldElements(
            resynthesized.field, original.field, '$desc field');
      }
    }
    expect(resynthesized.defaultValueCode, original.defaultValueCode,
        reason: desc);
    ParameterElementImpl resynthesizedActual =
        getActualElement(resynthesized, desc);
    ParameterElementImpl originalActual = getActualElement(original, desc);
    compareFunctionElements(
        resynthesizedActual.initializer, originalActual.initializer, desc);
  }

  void comparePrefixElements(PrefixElementImpl resynthesized,
      PrefixElementImpl original, String desc) {
    compareElements(resynthesized, original, desc);
  }

  void comparePropertyAccessorElements(
      PropertyAccessorElementImpl resynthesized,
      PropertyAccessorElementImpl original,
      String desc) {
    // TODO(paulberry): do I need to worry about
    // MultiplyInheritedPropertyAccessorElementImpl?
    compareExecutableElements(resynthesized, original, desc);
    expect(resynthesized.variable, isNotNull);
    expect(resynthesized.variable.location, original.variable.location);
  }

  void comparePropertyInducingElements(
      PropertyInducingElementImpl resynthesized,
      PropertyInducingElementImpl original,
      String desc) {
    compareVariableElements(resynthesized, original, desc);
    compareTypes(resynthesized.propagatedType, original.propagatedType, desc);
    if (original.getter == null) {
      expect(resynthesized.getter, isNull);
    } else {
      expect(resynthesized.getter, isNotNull);
      expect(resynthesized.getter.location, original.getter.location);
    }
    if (original.setter == null) {
      expect(resynthesized.setter, isNull);
    } else {
      expect(resynthesized.setter, isNotNull);
      expect(resynthesized.setter.location, original.setter.location);
    }
  }

  void compareTopLevelVariableElements(
      TopLevelVariableElementImpl resynthesized,
      TopLevelVariableElementImpl original,
      String desc) {
    comparePropertyInducingElements(resynthesized, original, desc);
  }

  void compareTypeImpls(
      TypeImpl resynthesized, TypeImpl original, String desc) {
    expect(resynthesized.element.location, original.element.location,
        reason: desc);
    expect(resynthesized.name, original.name, reason: desc);
  }

  void compareTypeParameterElements(TypeParameterElementImpl resynthesized,
      TypeParameterElementImpl original, String desc) {
    compareElements(resynthesized, original, desc);
    compareTypes(resynthesized.type, original.type, desc);
    compareTypes(resynthesized.bound, original.bound, '$desc bound');
  }

  void compareTypes(DartType resynthesized, DartType original, String desc) {
    if (original == null) {
      expect(resynthesized, isNull, reason: desc);
    } else if (resynthesized is InterfaceTypeImpl &&
        original is InterfaceTypeImpl) {
      compareTypeImpls(resynthesized, original, desc);
      expect(resynthesized.typeArguments.length, original.typeArguments.length);
      for (int i = 0; i < resynthesized.typeArguments.length; i++) {
        compareTypes(resynthesized.typeArguments[i], original.typeArguments[i],
            '$desc type argument ${original.typeArguments[i].name}');
      }
    } else if (resynthesized is TypeParameterTypeImpl &&
        original is TypeParameterTypeImpl) {
      compareTypeImpls(resynthesized, original, desc);
    } else if (resynthesized is DynamicTypeImpl &&
        original is DynamicTypeImpl) {
      expect(resynthesized, same(original));
    } else if (resynthesized is UndefinedTypeImpl &&
        original is UndefinedTypeImpl) {
      expect(resynthesized, same(original));
    } else if (resynthesized is FunctionTypeImpl &&
        original is FunctionTypeImpl) {
      compareTypeImpls(resynthesized, original, desc);
      expect(resynthesized.isInstantiated, original.isInstantiated,
          reason: desc);
      if (original.element.isSynthetic &&
          original.element is FunctionTypeAliasElementImpl &&
          resynthesized.element is FunctionTypeAliasElementImpl) {
        compareFunctionTypeAliasElements(
            resynthesized.element, original.element, desc);
      }
      if (original.element.enclosingElement == null &&
          original.element is FunctionElement) {
        expect(resynthesized.element, new isInstanceOf<FunctionElement>());
        expect(resynthesized.element.enclosingElement, isNull, reason: desc);
        compareFunctionElements(
            resynthesized.element, original.element, '$desc element',
            shallow: true);
        expect(resynthesized.element.type, same(resynthesized));
      }
      expect(resynthesized.typeArguments.length, original.typeArguments.length,
          reason: desc);
      for (int i = 0; i < resynthesized.typeArguments.length; i++) {
        compareTypes(resynthesized.typeArguments[i], original.typeArguments[i],
            '$desc type argument ${original.typeArguments[i].name}');
      }
      if (original.typeParameters == null) {
        expect(resynthesized.typeParameters, isNull, reason: desc);
      } else {
        expect(resynthesized.typeParameters, isNotNull, reason: desc);
        expect(
            resynthesized.typeParameters.length, original.typeParameters.length,
            reason: desc);
        for (int i = 0; i < resynthesized.typeParameters.length; i++) {
          compareTypeParameterElements(resynthesized.typeParameters[i],
              original.typeParameters[i], '$desc type parameter $i');
        }
      }
      expect(resynthesized.typeFormals.length, original.typeFormals.length,
          reason: desc);
      for (int i = 0; i < resynthesized.typeFormals.length; i++) {
        compareTypeParameterElements(resynthesized.typeFormals[i],
            original.typeFormals[i], '$desc bound type parameter $i');
      }
    } else if (resynthesized is VoidTypeImpl && original is VoidTypeImpl) {
      expect(resynthesized, same(original));
    } else if (resynthesized is DynamicTypeImpl &&
        original is UndefinedTypeImpl) {
      // TODO(scheglov) In the strong mode constant variable like
      //  `var V = new Unresolved()` gets `UndefinedTypeImpl`, and it gets
      // `DynamicTypeImpl` in the spec mode.
    } else if (resynthesized is BottomTypeImpl && original is BottomTypeImpl) {
      expect(resynthesized, same(original));
    } else if (resynthesized.runtimeType != original.runtimeType) {
      fail('Type mismatch: expected ${original.runtimeType},'
          ' got ${resynthesized.runtimeType} ($desc)');
    } else {
      fail('Unimplemented comparison for ${original.runtimeType}');
    }
  }

  void compareUriReferencedElements(UriReferencedElementImpl resynthesized,
      UriReferencedElementImpl original, String desc) {
    compareElements(resynthesized, original, desc);
    expect(resynthesized.uri, original.uri);
    expect(resynthesized.uriOffset, original.uriOffset, reason: desc);
    expect(resynthesized.uriEnd, original.uriEnd, reason: desc);
  }

  void compareVariableElements(
      VariableElement resynthesized, VariableElement original, String desc) {
    compareElements(resynthesized, original, desc);
    compareTypes(resynthesized.type, original.type, desc);
    VariableElementImpl resynthesizedActual =
        getActualElement(resynthesized, desc);
    VariableElementImpl originalActual = getActualElement(original, desc);
    compareFunctionElements(resynthesizedActual.initializer,
        originalActual.initializer, '$desc initializer');
    if (originalActual is ConstVariableElement) {
      Element oEnclosing = original.enclosingElement;
      if (oEnclosing is ClassElement && oEnclosing.isEnum) {
        compareConstValues(
            resynthesized.constantValue, original.constantValue, desc);
      } else {
        Expression initializer = resynthesizedActual.constantInitializer;
        if (constantInitializersAreInvalid) {
          _assertUnresolvedIdentifier(initializer, desc);
        } else {
          compareConstAsts(initializer, originalActual.constantInitializer,
              '$desc initializer');
        }
      }
    }
    checkPossibleMember(resynthesized, original, desc);
    checkPossibleLocalElements(resynthesized, original);
  }

  /**
   * Determine the analysis options that should be used for this test.
   */
  AnalysisOptionsImpl createOptions() =>
      new AnalysisOptionsImpl()..enableGenericMethods = true;

  /**
   * Serialize the given [library] into a summary.  Then create a
   * [_TestSummaryResynthesizer] which can deserialize it, along with any
   * references it makes to `dart:core`.
   *
   * Errors will lead to a test failure unless [allowErrors] is `true`.
   */
  _TestSummaryResynthesizer encodeLibrary(LibraryElementImpl library,
      {bool allowErrors: false, bool dumpSummaries: false}) {
    if (!allowErrors) {
      assertNoErrors(library.source);
    }
    addLibrary('dart:core');
    return encodeLibraryElement(library, dumpSummaries: dumpSummaries);
  }

  /**
   * Convert the library element [library] into a summary, and then create a
   * [_TestSummaryResynthesizer] which can deserialize it.
   *
   * Caller is responsible for checking the library for errors, and adding any
   * dependent libraries using [addLibrary].
   */
  _TestSummaryResynthesizer encodeLibraryElement(LibraryElementImpl library,
      {bool dumpSummaries: false}) {
    Map<String, UnlinkedUnit> unlinkedSummaries = <String, UnlinkedUnit>{};
    LinkedLibrary getLinkedSummaryFor(LibraryElement lib) {
      LibrarySerializationResult serialized = serializeLibrary(
          lib, typeProvider, analysisContext.analysisOptions.strongMode);
      for (int i = 0; i < serialized.unlinkedUnits.length; i++) {
        unlinkedSummaries[serialized.unitUris[i]] =
            new UnlinkedUnit.fromBuffer(serialized.unlinkedUnits[i].toBuffer());
      }
      return new LinkedLibrary.fromBuffer(serialized.linked.toBuffer());
    }
    Map<String, LinkedLibrary> linkedSummaries = <String, LinkedLibrary>{
      library.source.uri.toString(): getLinkedSummaryFor(library)
    };
    for (Source source in otherLibrarySources) {
      LibraryElement original = resolve2(source);
      String uri = source.uri.toString();
      linkedSummaries[uri] = getLinkedSummaryFor(original);
    }
    if (dumpSummaries) {
      unlinkedSummaries.forEach((String path, UnlinkedUnit unit) {
        print('Unlinked $path: ${JSON.encode(canonicalize(unit))}');
      });
      linkedSummaries.forEach((String path, LinkedLibrary lib) {
        print('Linked $path: ${JSON.encode(canonicalize(lib))}');
      });
    }
    return new _TestSummaryResynthesizer(
        null,
        analysisContext,
        analysisContext.typeProvider,
        analysisContext.sourceFactory,
        unlinkedSummaries,
        linkedSummaries,
        createOptions().strongMode);
  }

  fail_library_hasExtUri() {
    checkLibrary('import "dart-ext:doesNotExist.dart";');
  }

  ElementImpl getActualElement(Element element, String desc) {
    if (element == null) {
      return null;
    } else if (element is ElementImpl) {
      return element;
    } else if (element is ElementHandle) {
      Element actualElement = element.actualElement;
      // A handle should never point to a member, because if it did, then
      // "is Member" checks on the handle would produce the wrong result.
      expect(actualElement, isNot(new isInstanceOf<Member>()), reason: desc);
      return getActualElement(actualElement, desc);
    } else if (element is Member) {
      return getActualElement(element.baseElement, desc);
    } else {
      fail('Unexpected type for resynthesized ($desc):'
          ' ${element.runtimeType}');
      return null;
    }
  }

  /**
   * Resynthesize the library element associated with [uri] using
   * [resynthesizer], and verify that it only had to consult one summary in
   * order to do so.  [original] is consulted merely to verify that no
   * unnecessary resynthesis work was performed.
   */
  LibraryElementImpl resynthesizeLibraryElement(
      _TestSummaryResynthesizer resynthesizer,
      String uri,
      LibraryElement original) {
    LibraryElementImpl resynthesized = resynthesizer.getLibraryElement(uri);
    checkMinimalResynthesisWork(resynthesizer, original);
    return resynthesized;
  }

  @override
  void setUp() {
    super.setUp();
    resetWithOptions(createOptions());
  }

  test_class_abstract() {
    checkLibrary('abstract class C {}');
  }

  test_class_alias() {
    checkLibrary('class C = D with E, F; class D {} class E {} class F {}');
  }

  test_class_alias_abstract() {
    checkLibrary('abstract class C = D with E; class D {} class E {}');
  }

  test_class_alias_documented() {
    checkLibrary('''
// Extra comment so doc comment offset != 0
/**
 * Docs
 */
class C = D with E;

class D {}
class E {}''');
  }

  test_class_alias_with_forwarding_constructors() {
    addLibrarySource(
        '/a.dart',
        '''
class Base {
  Base._priv();
  Base();
  Base.noArgs();
  Base.requiredArg(x);
  Base.positionalArg([x]);
  Base.namedArg({x});
  factory Base.fact() => null;
  factory Base.fact2() = Base.noArgs;
}
''');
    checkLibrary('''
import "a.dart";
class M {}
class MixinApp = Base with M;
''');
  }

  test_class_alias_with_forwarding_constructors_type_substitution() {
    checkLibrary('''
class Base<T> {
  Base.ctor(T t, List<T> l);
}
class M {}
class MixinApp = Base with M;
''');
  }

  test_class_alias_with_forwarding_constructors_type_substitution_complex() {
    checkLibrary('''
class Base<T> {
  Base.ctor(T t, List<T> l);
}
class M {}
class MixinApp<U> = Base<List<U>> with M;
''');
  }

  test_class_alias_with_mixin_members() {
    checkLibrary('''
class C = D with E;
class D {}
class E {
  int get a => null;
  void set b(int i) {}
  void f() {}
  int x;
}''');
  }

  test_class_constructor_const() {
    checkLibrary('class C { const C(); }');
  }

  test_class_constructor_const_external() {
    checkLibrary('class C { external const C(); }');
  }

  test_class_constructor_explicit_named() {
    checkLibrary('class C { C.foo(); }');
  }

  test_class_constructor_explicit_type_params() {
    checkLibrary('class C<T, U> { C(); }');
  }

  test_class_constructor_explicit_unnamed() {
    checkLibrary('class C { C(); }');
  }

  test_class_constructor_external() {
    checkLibrary('class C { external C(); }');
  }

  test_class_constructor_factory() {
    checkLibrary('class C { factory C() => null; }');
  }

  test_class_constructor_field_formal_dynamic_dynamic() {
    checkLibrary('class C { dynamic x; C(dynamic this.x); }');
  }

  test_class_constructor_field_formal_dynamic_typed() {
    checkLibrary('class C { dynamic x; C(int this.x); }');
  }

  test_class_constructor_field_formal_dynamic_untyped() {
    checkLibrary('class C { dynamic x; C(this.x); }');
  }

  test_class_constructor_field_formal_multiple_matching_fields() {
    // This is a compile-time error but it should still analyze consistently.
    checkLibrary('class C { C(this.x); int x; String x; }', allowErrors: true);
  }

  test_class_constructor_field_formal_no_matching_field() {
    // This is a compile-time error but it should still analyze consistently.
    checkLibrary('class C { C(this.x); }', allowErrors: true);
  }

  test_class_constructor_field_formal_typed_dynamic() {
    checkLibrary('class C { num x; C(dynamic this.x); }', allowErrors: true);
  }

  test_class_constructor_field_formal_typed_typed() {
    checkLibrary('class C { num x; C(int this.x); }');
  }

  test_class_constructor_field_formal_typed_untyped() {
    checkLibrary('class C { num x; C(this.x); }');
  }

  test_class_constructor_field_formal_untyped_dynamic() {
    checkLibrary('class C { var x; C(dynamic this.x); }');
  }

  test_class_constructor_field_formal_untyped_typed() {
    checkLibrary('class C { var x; C(int this.x); }');
  }

  test_class_constructor_field_formal_untyped_untyped() {
    checkLibrary('class C { var x; C(this.x); }');
  }

  test_class_constructor_fieldFormal_named_noDefault() {
    checkLibrary('class C { int x; C({this.x}); }');
  }

  test_class_constructor_fieldFormal_named_withDefault() {
    checkLibrary('class C { int x; C({this.x: 42}); }');
  }

  test_class_constructor_fieldFormal_optional_noDefault() {
    checkLibrary('class C { int x; C([this.x]); }');
  }

  test_class_constructor_fieldFormal_optional_withDefault() {
    checkLibrary('class C { int x; C([this.x = 42]); }');
  }

  test_class_constructor_implicit() {
    checkLibrary('class C {}');
  }

  test_class_constructor_implicit_type_params() {
    checkLibrary('class C<T, U> {}');
  }

  test_class_constructor_params() {
    checkLibrary('class C { C(x, y); }');
  }

  test_class_constructors() {
    checkLibrary('class C { C.foo(); C.bar(); }');
  }

  test_class_documented() {
    checkLibrary('''
// Extra comment so doc comment offset != 0
/**
 * Docs
 */
class C {}''');
  }

  test_class_documented_with_references() {
    checkLibrary('''
/**
 * Docs referring to [D] and [E]
 */
class C {}

class D {}
class E {}''');
  }

  test_class_documented_with_windows_line_endings() {
    checkLibrary('/**\r\n * Docs\r\n */\r\nclass C {}');
  }

  test_class_field_const() {
    checkLibrary('class C { static const int i = 0; }');
  }

  test_class_field_implicit_type() {
    checkLibrary('class C { var x; }');
  }

  test_class_field_static() {
    checkLibrary('class C { static int i; }');
  }

  test_class_fields() {
    checkLibrary('class C { int i; int j; }');
  }

  test_class_getter_abstract() {
    checkLibrary('abstract class C { int get x; }');
  }

  test_class_getter_external() {
    checkLibrary('class C { external int get x; }');
  }

  test_class_getter_implicit_return_type() {
    checkLibrary('class C { get x => null; }');
  }

  test_class_getter_static() {
    checkLibrary('class C { static int get x => null; }');
  }

  test_class_getters() {
    checkLibrary('class C { int get x => null; get y => null; }');
  }

  test_class_implicitField_getterFirst() {
    checkLibrary('class C { int get x => 0; void set x(int value) {} }');
  }

  test_class_implicitField_setterFirst() {
    checkLibrary('class C { void set x(int value) {} int get x => 0; }');
  }

  test_class_interfaces() {
    checkLibrary('class C implements D, E {} class D {} class E {}');
  }

  test_class_method_abstract() {
    checkLibrary('abstract class C { f(); }');
  }

  test_class_method_external() {
    checkLibrary('class C { external f(); }');
  }

  test_class_method_params() {
    checkLibrary('class C { f(x, y) {} }');
  }

  test_class_method_static() {
    checkLibrary('class C { static f() {} }');
  }

  test_class_methods() {
    checkLibrary('class C { f() {} g() {} }');
  }

  test_class_mixins() {
    checkLibrary('class C extends Object with D, E {} class D {} class E {}');
  }

  test_class_setter_abstract() {
    checkLibrary('abstract class C { void set x(int value); }');
  }

  test_class_setter_external() {
    checkLibrary('class C { external void set x(int value); }');
  }

  test_class_setter_implicit_param_type() {
    checkLibrary('class C { void set x(value) {} }');
  }

  test_class_setter_implicit_return_type() {
    checkLibrary('class C { set x(int value) {} }');
  }

  test_class_setter_static() {
    checkLibrary('class C { static void set x(int value) {} }');
  }

  test_class_setters() {
    checkLibrary('class C { void set x(int value) {} set y(value) {} }');
  }

  test_class_supertype() {
    checkLibrary('class C extends D {} class D {}');
  }

  test_class_type_parameters() {
    checkLibrary('class C<T, U> {}');
  }

  test_class_type_parameters_bound() {
    checkLibrary('class C<T extends Object, U extends D> {} class D {}');
  }

  test_class_type_parameters_f_bound_complex() {
    checkLibrary('class C<T extends List<U>, U> {}');
  }

  test_class_type_parameters_f_bound_simple() {
    checkLibrary('class C<T extends U, U> {}');
  }

  test_classes() {
    checkLibrary('class C {} class D {}');
  }

  test_closure_executable_with_return_type_from_closure() {
    checkLibrary('''
f() {
  print(() {});
  print(() => () => 0);
}
''');
  }

  test_const_invalid_field_const() {
    constantInitializersAreInvalid = true;
    checkLibrary(
        r'''
class C {
  static const f = 1 + foo();
}
int foo() => 42;
''',
        allowErrors: true);
  }

  test_const_invalid_field_final() {
    constantInitializersAreInvalid = true;
    checkLibrary(
        r'''
class C {
  final f = 1 + foo();
}
int foo() => 42;
''',
        allowErrors: true);
  }

  test_const_invalid_topLevel() {
    constantInitializersAreInvalid = true;
    checkLibrary(
        r'''
const v = 1 + foo();
int foo() => 42;
''',
        allowErrors: true);
  }

  test_const_invokeConstructor_generic_named() {
    checkLibrary(r'''
class C<K, V> {
  const C.named(K k, V v);
}
const V = const C<int, String>.named(1, '222');
''');
  }

  test_const_invokeConstructor_generic_named_imported() {
    addLibrarySource(
        '/a.dart',
        r'''
class C<K, V> {
  const C.named(K k, V v);
}
''');
    checkLibrary(r'''
import 'a.dart';
const V = const C<int, String>.named(1, '222');
''');
  }

  test_const_invokeConstructor_generic_named_imported_withPrefix() {
    addLibrarySource(
        '/a.dart',
        r'''
class C<K, V> {
  const C.named(K k, V v);
}
''');
    checkLibrary(r'''
import 'a.dart' as p;
const V = const p.C<int, String>.named(1, '222');
''');
  }

  test_const_invokeConstructor_generic_noTypeArguments() {
    checkLibrary(r'''
class C<K, V> {
  const C();
}
const V = const C();
''');
  }

  test_const_invokeConstructor_generic_unnamed() {
    checkLibrary(r'''
class C<K, V> {
  const C();
}
const V = const C<int, String>();
''');
  }

  test_const_invokeConstructor_generic_unnamed_imported() {
    addLibrarySource(
        '/a.dart',
        r'''
class C<K, V> {
  const C();
}
''');
    checkLibrary(r'''
import 'a.dart';
const V = const C<int, String>();
''');
  }

  test_const_invokeConstructor_generic_unnamed_imported_withPrefix() {
    addLibrarySource(
        '/a.dart',
        r'''
class C<K, V> {
  const C();
}
''');
    checkLibrary(r'''
import 'a.dart' as p;
const V = const p.C<int, String>();
''');
  }

  test_const_invokeConstructor_named() {
    checkLibrary(r'''
class C {
  const C.named(bool a, int b, int c, {String d, double e});
}
const V = const C.named(true, 1, 2, d: 'ccc', e: 3.4);
''');
  }

  test_const_invokeConstructor_named_imported() {
    addLibrarySource(
        '/a.dart',
        r'''
class C {
  const C.named();
}
''');
    checkLibrary(r'''
import 'a.dart';
const V = const C.named();
''');
  }

  test_const_invokeConstructor_named_imported_withPrefix() {
    addLibrarySource(
        '/a.dart',
        r'''
class C {
  const C.named();
}
''');
    checkLibrary(r'''
import 'a.dart' as p;
const V = const p.C.named();
''');
  }

  test_const_invokeConstructor_named_unresolved() {
    checkLibrary(
        r'''
class C {}
const V = const C.named();
''',
        allowErrors: true);
  }

  test_const_invokeConstructor_named_unresolved2() {
    checkLibrary(
        r'''
const V = const C.named();
''',
        allowErrors: true);
  }

  test_const_invokeConstructor_named_unresolved3() {
    addLibrarySource(
        '/a.dart',
        r'''
class C {
}
''');
    checkLibrary(
        r'''
import 'a.dart' as p;
const V = const p.C.named();
''',
        allowErrors: true);
  }

  test_const_invokeConstructor_named_unresolved4() {
    addLibrarySource('/a.dart', '');
    checkLibrary(
        r'''
import 'a.dart' as p;
const V = const p.C.named();
''',
        allowErrors: true);
  }

  test_const_invokeConstructor_named_unresolved5() {
    checkLibrary(
        r'''
const V = const p.C.named();
''',
        allowErrors: true);
  }

  test_const_invokeConstructor_unnamed() {
    checkLibrary(r'''
class C {
  const C();
}
const V = const C();
''');
  }

  test_const_invokeConstructor_unnamed_imported() {
    addLibrarySource(
        '/a.dart',
        r'''
class C {
  const C();
}
''');
    checkLibrary(r'''
import 'a.dart';
const V = const C();
''');
  }

  test_const_invokeConstructor_unnamed_imported_withPrefix() {
    addLibrarySource(
        '/a.dart',
        r'''
class C {
  const C();
}
''');
    checkLibrary(r'''
import 'a.dart' as p;
const V = const p.C();
''');
  }

  test_const_invokeConstructor_unnamed_unresolved() {
    checkLibrary(
        r'''
const V = const C();
''',
        allowErrors: true);
  }

  test_const_invokeConstructor_unnamed_unresolved2() {
    addLibrarySource('/a.dart', '');
    checkLibrary(
        r'''
import 'a.dart' as p;
const V = const p.C();
''',
        allowErrors: true);
  }

  test_const_invokeConstructor_unnamed_unresolved3() {
    checkLibrary(
        r'''
const V = const p.C();
''',
        allowErrors: true);
  }

  test_const_length_ofClassConstField() {
    checkLibrary(r'''
class C {
  static const String F = '';
}
const int v = C.F.length;
''');
  }

  test_const_length_ofClassConstField_imported() {
    addLibrarySource(
        '/a.dart',
        r'''
class C {
  static const String F = '';
}
''');
    checkLibrary(r'''
import 'a.dart';
const int v = C.F.length;
''');
  }

  test_const_length_ofClassConstField_imported_withPrefix() {
    addLibrarySource(
        '/a.dart',
        r'''
class C {
  static const String F = '';
}
''');
    checkLibrary(r'''
import 'a.dart' as p;
const int v = p.C.F.length;
''');
  }

  test_const_length_ofStringLiteral() {
    checkLibrary(r'''
const v = 'abc'.length;
''');
  }

  test_const_length_ofTopLevelVariable() {
    checkLibrary(r'''
const String S = 'abc';
const v = S.length;
''');
  }

  test_const_length_ofTopLevelVariable_imported() {
    addLibrarySource(
        '/a.dart',
        r'''
const String S = 'abc';
''');
    checkLibrary(r'''
import 'a.dart';
const v = S.length;
''');
  }

  test_const_length_ofTopLevelVariable_imported_withPrefix() {
    addLibrarySource(
        '/a.dart',
        r'''
const String S = 'abc';
''');
    checkLibrary(r'''
import 'a.dart' as p;
const v = p.S.length;
''');
  }

  test_const_length_staticMethod() {
    checkLibrary(r'''
class C {
  static int length() => 42;
}
const v = C.length;
''');
  }

  test_const_parameterDefaultValue_initializingFormal_functionTyped() {
    checkLibrary(r'''
class C {
  final x;
  const C({this.x: foo});
}
int foo() => 42;
''');
  }

  test_const_parameterDefaultValue_initializingFormal_named() {
    checkLibrary(r'''
class C {
  final x;
  const C({this.x: 1 + 2});
}
''');
  }

  test_const_parameterDefaultValue_initializingFormal_positional() {
    checkLibrary(r'''
class C {
  final x;
  const C([this.x = 1 + 2]);
}
''');
  }

  test_const_parameterDefaultValue_normal() {
    checkLibrary(r'''
class C {
  const C.positional([p = 1 + 2]);
  const C.named({p: 1 + 2});
  void methodPositional([p = 1 + 2]) {}
  void methodPositionalWithoutDefault([p]) {}
  void methodNamed({p: 1 + 2}) {}
  void methodNamedWithoutDefault({p}) {}
}
''');
  }

  test_const_reference_staticField() {
    checkLibrary(r'''
class C {
  static const int F = 42;
}
const V = C.F;
''');
  }

  test_const_reference_staticField_imported() {
    addLibrarySource(
        '/a.dart',
        r'''
class C {
  static const int F = 42;
}
''');
    checkLibrary(r'''
import 'a.dart';
const V = C.F;
''');
  }

  test_const_reference_staticField_imported_withPrefix() {
    addLibrarySource(
        '/a.dart',
        r'''
class C {
  static const int F = 42;
}
''');
    checkLibrary(r'''
import 'a.dart' as p;
const V = p.C.F;
''');
  }

  test_const_reference_staticMethod() {
    checkLibrary(r'''
class C {
  static int m(int a, String b) => 42;
}
const V = C.m;
''');
  }

  test_const_reference_staticMethod_imported() {
    addLibrarySource(
        '/a.dart',
        r'''
class C {
  static int m(int a, String b) => 42;
}
''');
    checkLibrary(r'''
import 'a.dart';
const V = C.m;
''');
  }

  test_const_reference_staticMethod_imported_withPrefix() {
    addLibrarySource(
        '/a.dart',
        r'''
class C {
  static int m(int a, String b) => 42;
}
''');
    checkLibrary(r'''
import 'a.dart' as p;
const V = p.C.m;
''');
  }

  test_const_reference_topLevelFunction() {
    checkLibrary(r'''
foo() {}
const V = foo;
''');
  }

  test_const_reference_topLevelFunction_imported() {
    addLibrarySource(
        '/a.dart',
        r'''
foo() {}
''');
    checkLibrary(r'''
import 'a.dart';
const V = foo;
''');
  }

  test_const_reference_topLevelFunction_imported_withPrefix() {
    addLibrarySource(
        '/a.dart',
        r'''
foo() {}
''');
    checkLibrary(r'''
import 'a.dart' as p;
const V = p.foo;
''');
  }

  test_const_reference_topLevelVariable() {
    checkLibrary(r'''
const A = 1;
const B = A + 2;
''');
  }

  test_const_reference_topLevelVariable_imported() {
    addLibrarySource(
        '/a.dart',
        r'''
const A = 1;
''');
    checkLibrary(r'''
import 'a.dart';
const B = A + 2;
''');
  }

  test_const_reference_topLevelVariable_imported_withPrefix() {
    addLibrarySource(
        '/a.dart',
        r'''
const A = 1;
''');
    checkLibrary(r'''
import 'a.dart' as p;
const B = p.A + 2;
''');
  }

  test_const_reference_type() {
    checkLibrary(r'''
class C {}
class D<T> {}
enum E {a, b, c}
typedef F(int a, String b);
const vDynamic = dynamic;
const vNull = Null;
const vObject = Object;
const vClass = C;
const vGenericClass = D;
const vEnum = E;
const vFunctionTypeAlias = F;
''');
  }

  test_const_reference_type_imported() {
    addLibrarySource(
        '/a.dart',
        r'''
class C {}
enum E {a, b, c}
typedef F(int a, String b);
''');
    checkLibrary(r'''
import 'a.dart';
const vClass = C;
const vEnum = E;
const vFunctionTypeAlias = F;
''');
  }

  test_const_reference_type_imported_withPrefix() {
    addLibrarySource(
        '/a.dart',
        r'''
class C {}
enum E {a, b, c}
typedef F(int a, String b);
''');
    checkLibrary(r'''
import 'a.dart' as p;
const vClass = p.C;
const vEnum = p.E;
const vFunctionTypeAlias = p.F;
''');
  }

  test_const_reference_unresolved_prefix0() {
    checkLibrary(
        r'''
const V = foo;
''',
        allowErrors: true);
  }

  test_const_reference_unresolved_prefix1() {
    checkLibrary(
        r'''
class C {}
const v = C.foo;
''',
        allowErrors: true);
  }

  test_const_reference_unresolved_prefix2() {
    addLibrarySource(
        '/foo.dart',
        '''
class C {}
''');
    checkLibrary(
        r'''
import 'foo.dart' as p;
const v = p.C.foo;
''',
        allowErrors: true);
  }

  test_const_topLevel_binary() {
    checkLibrary(r'''
const vEqual = 1 == 2;
const vAnd = true && false;
const vOr = false || true;
const vBitXor = 1 ^ 2;
const vBitAnd = 1 & 2;
const vBitOr = 1 | 2;
const vBitShiftLeft = 1 << 2;
const vBitShiftRight = 1 >> 2;
const vAdd = 1 + 2;
const vSubtract = 1 - 2;
const vMiltiply = 1 * 2;
const vDivide = 1 / 2;
const vFloorDivide = 1 ~/ 2;
const vModulo = 1 % 2;
const vGreater = 1 > 2;
const vGreaterEqual = 1 >= 2;
const vLess = 1 < 2;
const vLessEqual = 1 <= 2;
''');
  }

  test_const_topLevel_conditional() {
    checkLibrary(r'''
const vConditional = (1 == 2) ? 11 : 22;
''');
  }

  test_const_topLevel_identical() {
    checkLibrary(r'''
const vIdentical = (1 == 2) ? 11 : 22;
''');
  }

  test_const_topLevel_literal() {
    checkLibrary(r'''
const vNull = null;
const vBoolFalse = false;
const vBoolTrue = true;
const vInt = 1;
const vIntLong = 0x9876543210987654321;
const vDouble = 2.3;
const vString = 'abc';
const vStringConcat = 'aaa' 'bbb';
const vStringInterpolation = 'aaa ${true} ${42} bbb';
const vSymbol = #aaa.bbb.ccc;
''');
  }

  test_const_topLevel_prefix() {
    checkLibrary(r'''
const vNotEqual = 1 != 2;
const vNot = !true;
const vNegate = -1;
const vComplement = ~1;
''');
  }

  test_const_topLevel_typedList() {
    checkLibrary(r'''
const vNull = const <Null>[];
const vDynamic = const <dynamic>[1, 2, 3];
const vInterfaceNoTypeParameters = const <int>[1, 2, 3];
const vInterfaceNoTypeArguments = const <List>[];
const vInterfaceWithTypeArguments = const <List<String>>[];
const vInterfaceWithTypeArguments2 = const <Map<int, List<String>>>[];
''');
  }

  test_const_topLevel_typedList_imported() {
    addLibrarySource('/a.dart', 'class C {}');
    checkLibrary(r'''
import 'a.dart';
const v = const <C>[];
''');
  }

  test_const_topLevel_typedList_importedWithPrefix() {
    addLibrarySource('/a.dart', 'class C {}');
    checkLibrary(r'''
import 'a.dart' as p;
const v = const <p.C>[];
''');
  }

  test_const_topLevel_typedMap() {
    checkLibrary(r'''
const vDynamic1 = const <dynamic, int>{};
const vDynamic2 = const <int, dynamic>{};
const vInterface = const <int, String>{};
const vInterfaceWithTypeArguments = const <int, List<String>>{};
''');
  }

  test_const_topLevel_untypedList() {
    checkLibrary(r'''
const v = const [1, 2, 3];
''');
  }

  test_const_topLevel_untypedMap() {
    checkLibrary(r'''
const v = const {0: 'aaa', 1: 'bbb', 2: 'ccc'};
''');
  }

  test_constExpr_pushReference_field_simpleIdentifier() {
    checkLibrary('''
class C {
  static const a = b;
  static const b = null;
}
''');
  }

  test_constExpr_pushReference_staticMethod_simpleIdentifier() {
    checkLibrary('''
class C {
  static const a = m;
  static m() {}
}
''');
  }

  test_constructor_documented() {
    checkLibrary('''
class C {
  /**
   * Docs
   */
  C();
}''');
  }

  test_constructor_initializers_field() {
    checkLibrary('''
class C {
  final x;
  const C() : x = 42;
}
''');
  }

  test_constructor_initializers_field_notConst() {
    constantInitializersAreInvalid = true;
    checkLibrary(
        '''
class C {
  final x;
  const A() : x = foo();
}
int foo() => 42;
''',
        allowErrors: true);
  }

  test_constructor_initializers_field_withParameter() {
    checkLibrary('''
class C {
  final x;
  const C(int p) : x = 1 + p;
}
''');
  }

  test_constructor_initializers_superInvocation_named() {
    checkLibrary('''
class A {
  const A.aaa(int p);
}
class C extends A {
  const C() : super.aaa(42);
}
''');
  }

  test_constructor_initializers_superInvocation_unnamed() {
    checkLibrary('''
class A {
  const A(int p);
}
class C extends A {
  const C.ccc() : super(42);
}
''');
  }

  test_constructor_initializers_thisInvocation_named() {
    checkLibrary('''
class C {
  const C() : this.named(1, 'bbb');
  const C.named(int a, String b);
}
''');
  }

  test_constructor_initializers_thisInvocation_unnamed() {
    checkLibrary('''
class C {
  const C.named() : this(1, 'bbb');
  const C(int a, String b);
}
''');
  }

  test_constructor_redirected_factory_named() {
    checkLibrary('''
class C {
  factory C() = D.named;
  C._();
}
class D extends C {
  D.named() : super._();
}
''');
  }

  test_constructor_redirected_factory_named_generic() {
    checkLibrary('''
class C<T, U> {
  factory C() = D<U, T>.named;
  C._();
}
class D<T, U> extends C<U, T> {
  D.named() : super._();
}
''');
  }

  test_constructor_redirected_factory_named_imported() {
    addLibrarySource(
        '/foo.dart',
        '''
import 'test.dart';
class D extends C {
  D.named() : super._();
}
''');
    checkLibrary('''
import 'foo.dart';
class C {
  factory C() = D.named;
  C._();
}
''');
  }

  test_constructor_redirected_factory_named_imported_generic() {
    addLibrarySource(
        '/foo.dart',
        '''
import 'test.dart';
class D<T, U> extends C<U, T> {
  D.named() : super._();
}
''');
    checkLibrary('''
import 'foo.dart';
class C<T, U> {
  factory C() = D<U, T>.named;
  C._();
}
''');
  }

  test_constructor_redirected_factory_named_prefixed() {
    addLibrarySource(
        '/foo.dart',
        '''
import 'test.dart';
class D extends C {
  D.named() : super._();
}
''');
    checkLibrary('''
import 'foo.dart' as foo;
class C {
  factory C() = foo.D.named;
  C._();
}
''');
  }

  test_constructor_redirected_factory_named_prefixed_generic() {
    addLibrarySource(
        '/foo.dart',
        '''
import 'test.dart';
class D<T, U> extends C<U, T> {
  D.named() : super._();
}
''');
    checkLibrary('''
import 'foo.dart' as foo;
class C<T, U> {
  factory C() = foo.D<U, T>.named;
  C._();
}
''');
  }

  test_constructor_redirected_factory_unnamed() {
    checkLibrary('''
class C {
  factory C() = D;
  C._();
}
class D extends C {
  D() : super._();
}
''');
  }

  test_constructor_redirected_factory_unnamed_generic() {
    checkLibrary('''
class C<T, U> {
  factory C() = D<U, T>;
  C._();
}
class D<T, U> extends C<U, T> {
  D() : super._();
}
''');
  }

  test_constructor_redirected_factory_unnamed_imported() {
    addLibrarySource(
        '/foo.dart',
        '''
import 'test.dart';
class D extends C {
  D() : super._();
}
''');
    checkLibrary('''
import 'foo.dart';
class C {
  factory C() = D;
  C._();
}
''');
  }

  test_constructor_redirected_factory_unnamed_imported_generic() {
    addLibrarySource(
        '/foo.dart',
        '''
import 'test.dart';
class D<T, U> extends C<U, T> {
  D() : super._();
}
''');
    checkLibrary('''
import 'foo.dart';
class C<T, U> {
  factory C() = D<U, T>;
  C._();
}
''');
  }

  test_constructor_redirected_factory_unnamed_prefixed() {
    addLibrarySource(
        '/foo.dart',
        '''
import 'test.dart';
class D extends C {
  D() : super._();
}
''');
    checkLibrary('''
import 'foo.dart' as foo;
class C {
  factory C() = foo.D;
  C._();
}
''');
  }

  test_constructor_redirected_factory_unnamed_prefixed_generic() {
    addLibrarySource(
        '/foo.dart',
        '''
import 'test.dart';
class D<T, U> extends C<U, T> {
  D() : super._();
}
''');
    checkLibrary('''
import 'foo.dart' as foo;
class C<T, U> {
  factory C() = foo.D<U, T>;
  C._();
}
''');
  }

  test_constructor_redirected_thisInvocation_named() {
    checkLibrary('''
class C {
  C.named();
  C() : this.named();
}
''');
  }

  test_constructor_redirected_thisInvocation_named_generic() {
    checkLibrary('''
class C<T> {
  C.named();
  C() : this.named();
}
''');
  }

  test_constructor_redirected_thisInvocation_unnamed() {
    checkLibrary('''
class C {
  C();
  C.named() : this();
}
''');
  }

  test_constructor_redirected_thisInvocation_unnamed_generic() {
    checkLibrary('''
class C<T> {
  C();
  C.named() : this();
}
''');
  }

  test_constructor_withCycles_const() {
    checkLibrary('''
class C {
  final x;
  const C() : x = const D();
}
class D {
  final x;
  const D() : x = const C();
}
''');
  }

  test_constructor_withCycles_nonConst() {
    checkLibrary('''
class C {
  final x;
  C() : x = new D();
}
class D {
  final x;
  D() : x = new C();
}
''');
  }

  test_core() {
    if (createOptions().strongMode) {
      // The fake `dart:core` library is always in spec mode, so don't bother
      // trying to check that it resynthesizes properly; it won't.
      return;
    }
    String uri = 'dart:core';
    LibraryElementImpl original =
        resolve2(analysisContext2.sourceFactory.forUri(uri));
    LibraryElementImpl resynthesized = resynthesizeLibraryElement(
        encodeLibraryElement(original), uri, original);
    checkLibraryElements(original, resynthesized);
  }

  test_enum_documented() {
    checkLibrary('''
// Extra comment so doc comment offset != 0
/**
 * Docs
 */
enum E { v }''');
  }

  test_enum_value_documented() {
    checkLibrary('''
enum E {
  /**
   * Docs
   */
  v
}''');
  }

  test_enum_values() {
    checkLibrary('enum E { v1, v2 }');
  }

  test_enums() {
    checkLibrary('enum E1 { v1 } enum E2 { v2 }');
  }

  test_executable_parameter_type_typedef() {
    checkLibrary(r'''
typedef F(int p);
main(F f) {}
''');
  }

  test_export_class() {
    addLibrarySource('/a.dart', 'class C {}');
    checkLibrary('export "a.dart";');
  }

  test_export_class_type_alias() {
    addLibrarySource(
        '/a.dart', 'class C {} exends _D with _E; class _D {} class _E {}');
    checkLibrary('export "a.dart";');
  }

  test_export_function() {
    addLibrarySource('/a.dart', 'f() {}');
    checkLibrary('export "a.dart";');
  }

  test_export_getter() {
    addLibrarySource('/a.dart', 'get f() => null;');
    checkLibrary('export "a.dart";');
  }

  test_export_hide() {
    addLibrary('dart:async');
    checkLibrary('export "dart:async" hide Stream, Future;');
  }

  test_export_multiple_combinators() {
    addLibrary('dart:async');
    checkLibrary('export "dart:async" hide Stream show Future;');
  }

  test_export_setter() {
    addLibrarySource('/a.dart', 'void set f(value) {}');
    checkLibrary('export "a.dart";');
  }

  test_export_show() {
    addLibrary('dart:async');
    checkLibrary('export "dart:async" show Future, Stream;');
  }

  test_export_typedef() {
    addLibrarySource('/a.dart', 'typedef F();');
    checkLibrary('export "a.dart";');
  }

  test_export_variable() {
    addLibrarySource('/a.dart', 'var x;');
    checkLibrary('export "a.dart";');
  }

  test_export_variable_const() {
    addLibrarySource('/a.dart', 'const x = 0;');
    checkLibrary('export "a.dart";');
  }

  test_export_variable_final() {
    addLibrarySource('/a.dart', 'final x = 0;');
    checkLibrary('export "a.dart";');
  }

  test_exports() {
    addLibrarySource('/a.dart', 'library a;');
    addLibrarySource('/b.dart', 'library b;');
    checkLibrary('export "a.dart"; export "b.dart";');
  }

  test_field_documented() {
    checkLibrary('''
class C {
  /**
   * Docs
   */
  var x;
}''');
  }

  test_field_formal_param_inferred_type_implicit() {
    checkLibrary('class C extends D { var v; C(this.v); }'
        ' abstract class D { int get v; }');
  }

  test_field_inferred_type_nonStatic_explicit_initialized() {
    checkLibrary('class C { num v = 0; }');
  }

  test_field_inferred_type_nonStatic_implicit_initialized() {
    checkLibrary('class C { var v = 0; }');
  }

  test_field_inferred_type_nonStatic_implicit_uninitialized() {
    checkLibrary(
        'class C extends D { var v; } abstract class D { int get v; }');
  }

  test_field_inferred_type_static_implicit_initialized() {
    checkLibrary('class C { static var v = 0; }');
  }

  test_field_propagatedType_const_noDep() {
    checkLibrary('''
class C {
  static const x = 0;
}''');
  }

  test_field_propagatedType_final_dep_inLib() {
    addLibrarySource('/a.dart', 'final a = 1;');
    checkLibrary('''
import "a.dart";
class C {
  final b = a / 2;
}''');
  }

  test_field_propagatedType_final_dep_inPart() {
    addNamedSource('/a.dart', 'part of lib; final a = 1;');
    checkLibrary('''
library lib;
part "a.dart";
class C {
  final b = a / 2;
}''');
  }

  test_field_propagatedType_final_noDep_instance() {
    checkLibrary('''
class C {
  final x = 0;
}''');
  }

  test_field_propagatedType_final_noDep_static() {
    checkLibrary('''
class C {
  static final x = 0;
}''');
  }

  test_function_documented() {
    checkLibrary('''
// Extra comment so doc comment offset != 0
/**
 * Docs
 */
f() {}''');
  }

  test_function_entry_point() {
    checkLibrary('main() {}');
  }

  test_function_entry_point_in_export() {
    addLibrarySource('/a.dart', 'library a; main() {}');
    checkLibrary('export "a.dart";');
  }

  test_function_entry_point_in_export_hidden() {
    addLibrarySource('/a.dart', 'library a; main() {}');
    checkLibrary('export "a.dart" hide main;');
  }

  test_function_entry_point_in_part() {
    addNamedSource('/a.dart', 'part of my.lib; main() {}');
    checkLibrary('library my.lib; part "a.dart";');
  }

  test_function_external() {
    checkLibrary('external f();');
  }

  test_function_parameter_kind_named() {
    checkLibrary('f({x}) {}');
  }

  test_function_parameter_kind_positional() {
    checkLibrary('f([x]) {}');
  }

  test_function_parameter_kind_required() {
    checkLibrary('f(x) {}');
  }

  test_function_parameter_parameters() {
    checkLibrary('f(g(x, y)) {}');
  }

  test_function_parameter_return_type() {
    checkLibrary('f(int g()) {}');
  }

  test_function_parameter_return_type_void() {
    checkLibrary('f(void g()) {}');
  }

  test_function_parameter_type() {
    checkLibrary('f(int i) {}');
  }

  test_function_parameters() {
    checkLibrary('f(x, y) {}');
  }

  test_function_return_type() {
    checkLibrary('int f() => null;');
  }

  test_function_return_type_implicit() {
    checkLibrary('f() => null;');
  }

  test_function_return_type_void() {
    checkLibrary('void f() {}');
  }

  test_function_type_parameter() {
    resetWithOptions(createOptions()..enableGenericMethods = true);
    checkLibrary('T f<T, U>(U u) => null;');
  }

  test_function_type_parameter_with_function_typed_parameter() {
    resetWithOptions(createOptions()..enableGenericMethods = true);
    checkLibrary('void f<T, U>(T x(U u)) {}');
  }

  test_functions() {
    checkLibrary('f() {} g() {}');
  }

  test_generic_gClass_gMethodStatic() {
    resetWithOptions(createOptions()..enableGenericMethods = true);
    checkLibrary('''
class C<T, U> {
  static void m<V, W>(V v, W w) {
    void f<X, Y>(V v, W w, X x, Y y) {
    }
  }
}
''');
  }

  test_getElement_constructor_named() {
    ConstructorElement original = resolve2(addSource('class C { C.named(); }'))
        .getType('C')
        .getNamedConstructor('named');
    expect(original, isNotNull);
    ConstructorElement resynthesized = validateGetElement(original);
    compareConstructorElements(resynthesized, original, 'C.constructor named');
  }

  test_getElement_constructor_unnamed() {
    ConstructorElement original =
        resolve2(addSource('class C { C(); }')).getType('C').unnamedConstructor;
    expect(original, isNotNull);
    ConstructorElement resynthesized = validateGetElement(original);
    compareConstructorElements(resynthesized, original, 'C.constructor');
  }

  test_getElement_field() {
    FieldElement original =
        resolve2(addSource('class C { var f; }')).getType('C').getField('f');
    expect(original, isNotNull);
    FieldElement resynthesized = validateGetElement(original);
    compareFieldElements(resynthesized, original, 'C.field f');
  }

  test_getElement_getter() {
    PropertyAccessorElement original =
        resolve2(addSource('class C { get f => null; }'))
            .getType('C')
            .getGetter('f');
    expect(original, isNotNull);
    PropertyAccessorElement resynthesized = validateGetElement(original);
    comparePropertyAccessorElements(resynthesized, original, 'C.getter f');
  }

  test_getElement_method() {
    MethodElement original =
        resolve2(addSource('class C { f() {} }')).getType('C').getMethod('f');
    expect(original, isNotNull);
    MethodElement resynthesized = validateGetElement(original);
    compareMethodElements(resynthesized, original, 'C.method f');
  }

  test_getElement_operator() {
    MethodElement original =
        resolve2(addSource('class C { operator+(x) => null; }'))
            .getType('C')
            .getMethod('+');
    expect(original, isNotNull);
    MethodElement resynthesized = validateGetElement(original);
    compareMethodElements(resynthesized, original, 'C.operator+');
  }

  test_getElement_setter() {
    PropertyAccessorElement original =
        resolve2(addSource('class C { void set f(value) {} }'))
            .getType('C')
            .getSetter('f');
    expect(original, isNotNull);
    PropertyAccessorElement resynthesized = validateGetElement(original);
    comparePropertyAccessorElements(resynthesized, original, 'C.setter f');
  }

  test_getElement_unit() {
    Source source = addSource('class C { f() {} }');
    CompilationUnitElement original = resolve2(source).definingCompilationUnit;
    expect(original, isNotNull);
    CompilationUnitElement resynthesized = validateGetElement(original);
    compareCompilationUnitElements(resynthesized, original);
  }

  test_getter_documented() {
    checkLibrary('''
// Extra comment so doc comment offset != 0
/**
 * Docs
 */
get x => null;''');
  }

  test_getter_external() {
    checkLibrary('external int get x;');
  }

  test_getter_inferred_type_nonStatic_implicit_return() {
    checkLibrary(
        'class C extends D { get f => null; } abstract class D { int get f; }');
  }

  test_getters() {
    checkLibrary('int get x => null; get y => null;');
  }

  test_implicitTopLevelVariable_getterFirst() {
    checkLibrary('int get x => 0; void set x(int value) {}');
  }

  test_implicitTopLevelVariable_setterFirst() {
    checkLibrary('void set x(int value) {} int get x => 0;');
  }

  test_import_deferred() {
    addLibrarySource('/a.dart', 'f() {}');
    checkLibrary('import "a.dart" deferred as p; main() { p.f(); }');
  }

  test_import_hide() {
    addLibrary('dart:async');
    checkLibrary('import "dart:async" hide Stream, Completer; Future f;');
  }

  test_import_multiple_combinators() {
    addLibrary('dart:async');
    checkLibrary('import "dart:async" hide Stream show Future; Future f;');
  }

  test_import_prefixed() {
    addLibrarySource('/a.dart', 'library a; class C {}');
    checkLibrary('import "a.dart" as a; a.C c;');
  }

  test_import_show() {
    addLibrary('dart:async');
    checkLibrary('import "dart:async" show Future, Stream; Future f;');
  }

  test_imports() {
    addLibrarySource('/a.dart', 'library a; class C {}');
    addLibrarySource('/b.dart', 'library b; class D {}');
    checkLibrary('import "a.dart"; import "b.dart"; C c; D d;');
  }

  test_inferred_function_type_for_variable_in_generic_function() {
    // In the code below, `x` has an inferred type of `() => int`, with 2
    // (unused) type parameters from the enclosing top level function.
    checkLibrary('''
f<U, V>() {
  var x = () => 0;
}
''');
  }

  test_inferred_function_type_in_generic_class_constructor() {
    // In the code below, `() => () => 0` has an inferred return type of
    // `() => int`, with 2 (unused) type parameters from the enclosing class.
    checkLibrary('''
class C<U, V> {
  final x;
  C() : x = (() => () => 0);
}
''');
  }

  test_inferred_function_type_in_generic_class_getter() {
    // In the code below, `() => () => 0` has an inferred return type of
    // `() => int`, with 2 (unused) type parameters from the enclosing class.
    checkLibrary('''
class C<U, V> {
  get x => () => () => 0;
}
''');
  }

  test_inferred_function_type_in_generic_class_in_generic_method() {
    // In the code below, `() => () => 0` has an inferred return type of
    // `() => int`, with 3 (unused) type parameters from the enclosing class
    // and method.
    checkLibrary('''
class C<T> {
  f<U, V>() {
    print(() => () => 0);
  }
}
''');
  }

  test_inferred_function_type_in_generic_class_setter() {
    // In the code below, `() => () => 0` has an inferred return type of
    // `() => int`, with 2 (unused) type parameters from the enclosing class.
    checkLibrary('''
class C<U, V> {
  void set x(value) {
    print(() => () => 0);
  }
}
''');
  }

  test_inferred_function_type_in_generic_closure() {
    if (!createOptions().strongMode) {
      // The test below uses generic comment syntax because proper generic
      // method syntax doesn't support generic closures.  So it can only run in
      // strong mode.
      // TODO(paulberry): once proper generic method syntax supports generic
      // closures, rewrite the test below without using generic comment syntax,
      // and remove this hack.  See dartbug.com/25819
      return;
    }
    // In the code below, `<U, V>() => () => 0` has an inferred return type of
    // `() => int`, with 3 (unused) type parameters.
    checkLibrary('''
f<T>() {
  print(/*<U, V>*/() => () => 0);
}
''');
  }

  test_inferred_generic_function_type_in_generic_closure() {
    if (!createOptions().strongMode) {
      // The test below uses generic comment syntax because proper generic
      // method syntax doesn't support generic closures.  So it can only run in
      // strong mode.
      // TODO(paulberry): once proper generic method syntax supports generic
      // closures, rewrite the test below without using generic comment syntax,
      // and remove this hack.  See dartbug.com/25819
      return;
    }
    // In the code below, `<U, V>() => <W, X, Y, Z>() => 0` has an inferred
    // return type of `() => int`, with 7 (unused) type parameters.
    checkLibrary('''
f<T>() {
  print(/*<U, V>*/() => /*<W, X, Y, Z>*/() => 0);
}
''');
  }

  test_inferred_type_is_typedef() {
    checkLibrary('typedef int F(String s);'
        ' class C extends D { var v; }'
        ' abstract class D { F get v; }');
  }

  test_inferred_type_refers_to_bound_type_param() {
    checkLibrary('class C<T> extends D<int, T> { var v; }'
        ' abstract class D<U, V> { Map<V, U> get v; }');
  }

  test_inferred_type_refers_to_function_typed_parameter_type_generic_class() {
    checkLibrary('class C<T, U> extends D<U, int> { void f(int x, g) {} }'
        ' abstract class D<V, W> { void f(int x, W g(V s)); }');
  }

  test_inferred_type_refers_to_function_typed_parameter_type_other_lib() {
    addLibrarySource(
        '/a.dart', 'import "b.dart"; abstract class D extends E {}');
    addLibrarySource(
        '/b.dart', 'abstract class E { void f(int x, int g(String s)); }');
    checkLibrary('import "a.dart"; class C extends D { void f(int x, g) {} }');
  }

  test_inferred_type_refers_to_method_function_typed_parameter_type() {
    checkLibrary('class C extends D { void f(int x, g) {} }'
        ' abstract class D { void f(int x, int g(String s)); }');
  }

  test_inferred_type_refers_to_setter_function_typed_parameter_type() {
    checkLibrary('class C extends D { void set f(g) {} }'
        ' abstract class D { void set f(int g(String s)); }');
  }

  test_initializer_executable_with_return_type_from_closure() {
    checkLibrary('var v = () => 0;');
  }

  test_initializer_executable_with_return_type_from_closure_field() {
    checkLibrary('''
class C {
  var v = () => 0;
}
''');
  }

  test_initializer_executable_with_return_type_from_closure_local() {
    checkLibrary('''
void f() {
  int u = 0;
  var v = () => 0;
}
''');
  }

  test_library() {
    checkLibrary('');
  }

  test_library_documented() {
    checkLibrary('''
// Extra comment so doc comment offset != 0
/**
 * Docs
 */
library foo;''');
  }

  test_library_name_with_spaces() {
    checkLibrary('library foo . bar ;');
  }

  test_library_named() {
    checkLibrary('library foo.bar;');
  }

  test_localFunctions() {
    checkLibrary(r'''
f() {
  f1() {}
  {
    f2() {}
  }
}
''');
  }

  test_localFunctions_inConstructor() {
    checkLibrary(r'''
class C {
  C() {
    f() {}
  }
}
''');
  }

  test_localFunctions_inMethod() {
    checkLibrary(r'''
class C {
  m() {
    f() {}
  }
}
''');
  }

  test_localFunctions_inTopLevelGetter() {
    checkLibrary(r'''
get g {
  f() {}
}
''');
  }

  test_localLabels_inConstructor() {
    checkLibrary(r'''
class C {
  C() {
    aaa: while (true) {}
    bbb: switch (42) {
      ccc: case 0:
        break;
    }
  }
}
''');
  }

  test_localLabels_inMethod() {
    checkLibrary(r'''
class C {
  m() {
    aaa: while (true) {}
    bbb: switch (42) {
      ccc: case 0:
        break;
    }
  }
}
''');
  }

  test_localLabels_inTopLevelFunction() {
    checkLibrary(r'''
main() {
  aaa: while (true) {}
  bbb: switch (42) {
    ccc: case 0:
      break;
  }
}
''');
  }

  test_localVariables_inConstructor() {
    checkLibrary(r'''
class C {
  C() {
    int v;
    f() {}
  }
}
''');
  }

  test_localVariables_inLocalFunction() {
    checkLibrary(r'''
f() {
  f1() {
    int v1 = 1;
  } // 2
  f2() {
    int v1 = 1;
    f3() {
      int v2 = 1;
    }
  }
}
''');
  }

  test_localVariables_inMethod() {
    checkLibrary(r'''
class C {
  m() {
    int v;
  }
}
''');
  }

  test_localVariables_inTopLevelFunction() {
    checkLibrary(r'''
main() {
  int v1 = 1;
  {
    const String v2 = 'bbb';
  }
  Map<int, List<double>> v3;
}
''');
  }

  test_localVariables_inTopLevelGetter() {
    checkLibrary(r'''
get g {
  int v;
}
''');
  }

  test_main_class() {
    checkLibrary('class main {}');
  }

  test_main_class_alias() {
    checkLibrary('class main = C with D; class C {} class D {}');
  }

  test_main_class_alias_via_export() {
    addLibrarySource('/a.dart', 'class main = C with D; class C {} class D {}');
    checkLibrary('export "a.dart";');
  }

  test_main_class_via_export() {
    addLibrarySource('/a.dart', 'class main {}');
    checkLibrary('export "a.dart";');
  }

  test_main_getter() {
    checkLibrary('get main => null;');
  }

  test_main_getter_via_export() {
    addLibrarySource('/a.dart', 'get main => null;');
    checkLibrary('export "a.dart";');
  }

  test_main_typedef() {
    checkLibrary('typedef main();');
  }

  test_main_typedef_via_export() {
    addLibrarySource('/a.dart', 'typedef main();');
    checkLibrary('export "a.dart";');
  }

  test_main_variable() {
    checkLibrary('var main;');
  }

  test_main_variable_via_export() {
    addLibrarySource('/a.dart', 'var main;');
    checkLibrary('export "a.dart";');
  }

  test_metadata_classDeclaration() {
    checkLibrary('const a = null; @a class C {}');
  }

  test_metadata_classTypeAlias() {
    checkLibrary(
        'const a = null; @a class C = D with E; class D {} class E {}');
  }

  test_metadata_constructor_call_named() {
    checkLibrary('class A { const A.named(); } @A.named() class C {}');
  }

  test_metadata_constructor_call_named_prefixed() {
    addLibrarySource('/foo.dart', 'class A { const A.named(); }');
    checkLibrary('import "foo.dart" as foo; @foo.A.named() class C {}');
  }

  test_metadata_constructor_call_unnamed() {
    checkLibrary('class A { const A(); } @A() class C {}');
  }

  test_metadata_constructor_call_unnamed_prefixed() {
    addLibrarySource('/foo.dart', 'class A { const A(); }');
    checkLibrary('import "foo.dart" as foo; @foo.A() class C {}');
  }

  test_metadata_constructor_call_with_args() {
    checkLibrary('class A { const A(x); } @A(null) class C {}');
  }

  test_metadata_constructorDeclaration_named() {
    checkLibrary('const a = null; class C { @a C.named(); }');
  }

  test_metadata_constructorDeclaration_unnamed() {
    checkLibrary('const a = null; class C { @a C(); }');
  }

  test_metadata_enumDeclaration() {
    checkLibrary('const a = null; @a enum E { v }');
  }

  test_metadata_exportDirective() {
    addLibrarySource('/foo.dart', '');
    checkLibrary('@a export "foo.dart"; const a = null;');
  }

  test_metadata_fieldDeclaration() {
    checkLibrary('const a = null; class C { @a int x; }');
  }

  test_metadata_fieldFormalParameter() {
    checkLibrary('const a = null; class C { var x; C(@a this.x); }');
  }

  test_metadata_fieldFormalParameter_withDefault() {
    checkLibrary('const a = null; class C { var x; C([@a this.x = null]); }');
  }

  test_metadata_functionDeclaration_function() {
    checkLibrary('const a = null; @a f() {}');
  }

  test_metadata_functionDeclaration_getter() {
    checkLibrary('const a = null; @a get f => null;');
  }

  test_metadata_functionDeclaration_setter() {
    checkLibrary('const a = null; @a set f(value) {}');
  }

  test_metadata_functionTypeAlias() {
    checkLibrary('const a = null; @a typedef F();');
  }

  test_metadata_functionTypedFormalParameter() {
    checkLibrary('const a = null; f(@a g()) {}');
  }

  test_metadata_functionTypedFormalParameter_withDefault() {
    checkLibrary('const a = null; f([@a g() = null]) {}');
  }

  test_metadata_importDirective() {
    addLibrarySource('/foo.dart', 'const b = null;');
    checkLibrary('@a import "foo.dart"; const a = b;');
  }

  test_metadata_libraryDirective() {
    checkLibrary('@a library L; const a = null;');
  }

  test_metadata_methodDeclaration_getter() {
    checkLibrary('const a = null; class C { @a get m => null; }');
  }

  test_metadata_methodDeclaration_method() {
    checkLibrary('const a = null; class C { @a m() {} }');
  }

  test_metadata_methodDeclaration_setter() {
    checkLibrary('const a = null; class C { @a set m(value) {} }');
  }

  test_metadata_partDirective() {
    addNamedSource('/foo.dart', 'part of L;');
    checkLibrary('library L; @a part "foo.dart"; const a = null;');
  }

  test_metadata_prefixed_variable() {
    addLibrarySource('/a.dart', 'const b = null;');
    checkLibrary('import "a.dart" as a; @a.b class C {}');
  }

  test_metadata_simpleFormalParameter() {
    checkLibrary('const a = null; f(@a x) {}');
  }

  test_metadata_simpleFormalParameter_withDefault() {
    checkLibrary('const a = null; f([@a x = null]) {}');
  }

  test_metadata_topLevelVariableDeclaration() {
    checkLibrary('const a = null; @a int v;');
  }

  test_metadata_typeParameter_ofClass() {
    checkLibrary('const a = null; class C<@a T> {}');
  }

  test_metadata_typeParameter_ofClassTypeAlias() {
    checkLibrary(
        'const a = null; class C<@a T> = D with E; class D {} class E {}');
  }

  test_metadata_typeParameter_ofFunction() {
    checkLibrary('const a = null; f<@a T>() {}');
  }

  test_metadata_typeParameter_ofTypedef() {
    checkLibrary('const a = null; typedef F<@a T>();');
  }

  test_method_documented() {
    checkLibrary('''
class C {
  /**
   * Docs
   */
  f() {}
}''');
  }

  test_method_inferred_type_nonStatic_implicit_param() {
    checkLibrary('class C extends D { void f(value) {} }'
        ' abstract class D { void f(int value); }');
  }

  test_method_inferred_type_nonStatic_implicit_return() {
    checkLibrary(
        'class C extends D { f() => null; } abstract class D { int f(); }');
  }

  test_method_parameter_parameters() {
    checkLibrary('class C { f(g(x, y)) {} }');
  }

  test_method_parameter_parameters_in_generic_class() {
    checkLibrary('class C<A, B> { f(A g(B x)) {} }');
  }

  test_method_parameter_return_type() {
    checkLibrary('class C { f(int g()) {} }');
  }

  test_method_parameter_return_type_void() {
    checkLibrary('class C { f(void g()) {} }');
  }

  test_method_type_parameter() {
    resetWithOptions(createOptions()..enableGenericMethods = true);
    checkLibrary('class C { T f<T, U>(U u) => null; }');
  }

  test_method_type_parameter_in_generic_class() {
    resetWithOptions(createOptions()..enableGenericMethods = true);
    checkLibrary('class C<T, U> { V f<V, W>(T t, U u, W w) => null; }');
  }

  test_method_type_parameter_with_function_typed_parameter() {
    resetWithOptions(createOptions()..enableGenericMethods = true);
    checkLibrary('class C { void f<T, U>(T x(U u)) {} }');
  }

  test_nested_generic_functions_in_generic_class_with_function_typed_params() {
    checkLibrary('''
class C<T, U> {
  void g<V, W>() {
    void h<X, Y>(void p(T t, U u, V v, W w, X x, Y y)) {
    }
  }
}
''');
  }

  test_nested_generic_functions_in_generic_class_with_local_variables() {
    checkLibrary('''
class C<T, U> {
  void g<V, W>() {
    void h<X, Y>() {
      T t;
      U u;
      V v;
      W w;
      X x;
      Y y;
    }
  }
}
''');
  }

  test_nested_generic_functions_with_function_typed_param() {
    checkLibrary('''
void f<T, U>() {
  void g<V, W>() {
    void h<X, Y>(void p(T t, U u, V v, W w, X x, Y y)) {
    }
  }
}
''');
  }

  test_nested_generic_functions_with_local_variables() {
    checkLibrary('''
void f<T, U>() {
  void g<V, W>() {
    void h<X, Y>() {
      T t;
      U u;
      V v;
      W w;
      X x;
      Y y;
    }
  }
}
''');
  }

  test_operator() {
    checkLibrary('class C { C operator+(C other) => null; }');
  }

  test_operator_equal() {
    checkLibrary('class C { bool operator==(Object other) => false; }');
  }

  test_operator_external() {
    checkLibrary('class C { external C operator+(C other); }');
  }

  test_operator_greater_equal() {
    checkLibrary('class C { bool operator>=(C other) => false; }');
  }

  test_operator_index() {
    checkLibrary('class C { bool operator[](int i) => null; }');
  }

  test_operator_index_set() {
    checkLibrary('class C { void operator[]=(int i, bool v) {} }');
  }

  test_operator_less_equal() {
    checkLibrary('class C { bool operator<=(C other) => false; }');
  }

  test_parameterTypeNotInferred_constructor() {
    // Strong mode doesn't do type inference on constructor parameters, so it's
    // ok that we don't store inferred type info for them in summaries.
    checkLibrary('''
class C {
  C.positional([x = 1]);
  C.named({x: 1});
}
''');
  }

  test_parameterTypeNotInferred_initializingFormal() {
    // Strong mode doesn't do type inference on initializing formals, so it's
    // ok that we don't store inferred type info for them in summaries.
    checkLibrary('''
class C {
  var x;
  C.positional([this.x = 1]);
  C.named({this.x: 1});
}
''');
  }

  test_parameterTypeNotInferred_staticMethod() {
    // Strong mode doesn't do type inference on parameters of static methods,
    // so it's ok that we don't store inferred type info for them in summaries.
    checkLibrary('''
class C {
  static void positional([x = 1]) {}
  static void named({x: 1}) {}
}
''');
  }

  test_parameterTypeNotInferred_topLevelFunction() {
    // Strong mode doesn't do type inference on parameters of top level
    // functions, so it's ok that we don't store inferred type info for them in
    // summaries.
    checkLibrary('''
void positional([x = 1]) {}
void named({x: 1}) {}
''');
  }

  test_parts() {
    addNamedSource('/a.dart', 'part of my.lib;');
    addNamedSource('/b.dart', 'part of my.lib;');
    checkLibrary('library my.lib; part "a.dart"; part "b.dart";');
  }

  test_propagated_type_refers_to_closure() {
    checkLibrary('''
void f() {
  var x = () => 0;
  var y = x;
}
''');
  }

  test_setter_documented() {
    checkLibrary('''
// Extra comment so doc comment offset != 0
/**
 * Docs
 */
void set x(value) {}''');
  }

  test_setter_external() {
    checkLibrary('external void set x(int value);');
  }

  test_setter_inferred_type_nonStatic_implicit_param() {
    checkLibrary('class C extends D { void set f(value) {} }'
        ' abstract class D { void set f(int value); }');
  }

  test_setter_inferred_type_static_implicit_return() {
    checkLibrary('class C { static set f(int value) {} }');
  }

  test_setter_inferred_type_top_level_implicit_return() {
    checkLibrary('set f(int value) {}');
  }

  test_setters() {
    checkLibrary('void set x(int value) {} set y(value) {}');
  }

  test_syntheticFunctionType_genericClosure() {
    if (!createOptions().strongMode) {
      // The test below uses generic comment syntax because proper generic
      // method syntax doesn't support generic closures.  So it can only run in
      // strong mode.
      // TODO(paulberry): once proper generic method syntax supports generic
      // closures, rewrite the test below without using generic comment syntax,
      // and remove this hack.  See dartbug.com/25819
      return;
    }
    checkLibrary('''
final v = f() ? /*<T>*/(T t) => 0 : /*<T>*/(T t) => 1;
bool f() => true;
''');
  }

  test_syntheticFunctionType_genericClosure_inGenericFunction() {
    if (!createOptions().strongMode) {
      // The test below uses generic comment syntax because proper generic
      // method syntax doesn't support generic closures.  So it can only run in
      // strong mode.
      // TODO(paulberry): once proper generic method syntax supports generic
      // closures, rewrite the test below without using generic comment syntax,
      // and remove this hack.  See dartbug.com/25819
      return;
    }
    checkLibrary('''
void f<T, U>(bool b) {
  final v = b ? /*<V>*/(T t, U u, V v) => 0 : /*<V>*/(T t, U u, V v) => 1;
}
''');
  }

  test_syntheticFunctionType_inGenericClass() {
    checkLibrary('''
class C<T, U> {
  var v = f() ? (T t, U u) => 0 : (T t, U u) => 1;
}
bool f() => false;
''');
  }

  test_syntheticFunctionType_inGenericFunction() {
    checkLibrary('''
void f<T, U>(bool b) {
  var v = b ? (T t, U u) => 0 : (T t, U u) => 1;
}
''');
  }

  test_syntheticFunctionType_noArguments() {
    checkLibrary('''
final v = f() ? () => 0 : () => 1;
bool f() => true;
''');
  }

  test_syntheticFunctionType_withArguments() {
    checkLibrary('''
final v = f() ? (int x, String y) => 0 : (int x, String y) => 1;
bool f() => true;
''');
  }

  test_type_arguments_explicit_dynamic_dynamic() {
    checkLibrary('Map<dynamic, dynamic> m;');
  }

  test_type_arguments_explicit_dynamic_int() {
    checkLibrary('Map<dynamic, int> m;');
  }

  test_type_arguments_explicit_String_dynamic() {
    checkLibrary('Map<String, dynamic> m;');
  }

  test_type_arguments_explicit_String_int() {
    checkLibrary('Map<String, int> m;');
  }

  test_type_arguments_implicit() {
    checkLibrary('Map m;');
  }

  test_type_dynamic() {
    checkLibrary('dynamic d;');
  }

  test_type_reference_lib_to_lib() {
    checkLibrary('class C {} enum E { v } typedef F(); C c; E e; F f;');
  }

  test_type_reference_lib_to_part() {
    addNamedSource(
        '/a.dart', 'part of l; class C {} enum E { v } typedef F();');
    checkLibrary('library l; part "a.dart"; C c; E e; F f;');
  }

  test_type_reference_part_to_lib() {
    addNamedSource('/a.dart', 'part of l; C c; E e; F f;');
    checkLibrary(
        'library l; part "a.dart"; class C {} enum E { v } typedef F();');
  }

  test_type_reference_part_to_other_part() {
    addNamedSource(
        '/a.dart', 'part of l; class C {} enum E { v } typedef F();');
    addNamedSource('/b.dart', 'part of l; C c; E e; F f;');
    checkLibrary('library l; part "a.dart"; part "b.dart";');
  }

  test_type_reference_part_to_part() {
    addNamedSource('/a.dart',
        'part of l; class C {} enum E { v } typedef F(); C c; E e; F f;');
    checkLibrary('library l; part "a.dart";');
  }

  test_type_reference_to_class() {
    checkLibrary('class C {} C c;');
  }

  test_type_reference_to_class_with_type_arguments() {
    checkLibrary('class C<T, U> {} C<int, String> c;');
  }

  test_type_reference_to_class_with_type_arguments_implicit() {
    checkLibrary('class C<T, U> {} C c;');
  }

  test_type_reference_to_enum() {
    checkLibrary('enum E { v } E e;');
  }

  test_type_reference_to_import() {
    addLibrarySource('/a.dart', 'class C {} enum E { v }; typedef F();');
    checkLibrary('import "a.dart"; C c; E e; F f;');
  }

  test_type_reference_to_import_export() {
    addLibrarySource('/a.dart', 'export "b.dart";');
    addLibrarySource('/b.dart', 'class C {} enum E { v } typedef F();');
    checkLibrary('import "a.dart"; C c; E e; F f;');
  }

  test_type_reference_to_import_export_export() {
    addLibrarySource('/a.dart', 'export "b.dart";');
    addLibrarySource('/b.dart', 'export "c.dart";');
    addLibrarySource('/c.dart', 'class C {} enum E { v } typedef F();');
    checkLibrary('import "a.dart"; C c; E e; F f;');
  }

  test_type_reference_to_import_export_export_in_subdirs() {
    addLibrarySource('/a/a.dart', 'export "b/b.dart";');
    addLibrarySource('/a/b/b.dart', 'export "../c/c.dart";');
    addLibrarySource('/a/c/c.dart', 'class C {} enum E { v } typedef F();');
    checkLibrary('import "a/a.dart"; C c; E e; F f;');
  }

  test_type_reference_to_import_export_in_subdirs() {
    addLibrarySource('/a/a.dart', 'export "b/b.dart";');
    addLibrarySource('/a/b/b.dart', 'class C {} enum E { v } typedef F();');
    checkLibrary('import "a/a.dart"; C c; E e; F f;');
  }

  test_type_reference_to_import_part() {
    addLibrarySource('/a.dart', 'library l; part "b.dart";');
    addNamedSource(
        '/b.dart', 'part of l; class C {} enum E { v } typedef F();');
    checkLibrary('import "a.dart"; C c; E e; F f;');
  }

  test_type_reference_to_import_part2() {
    addLibrarySource('/a.dart', 'library l; part "p1.dart"; part "p2.dart";');
    addNamedSource('/p1.dart', 'part of l; class C1 {}');
    addNamedSource('/p2.dart', 'part of l; class C2 {}');
    checkLibrary('import "a.dart"; C1 c1; C2 c2;');
  }

  test_type_reference_to_import_part_in_subdir() {
    addLibrarySource('/a/b.dart', 'library l; part "c.dart";');
    addNamedSource(
        '/a/c.dart', 'part of l; class C {} enum E { v } typedef F();');
    checkLibrary('import "a/b.dart"; C c; E e; F f;');
  }

  test_type_reference_to_import_relative() {
    addLibrarySource('/a.dart', 'class C {} enum E { v } typedef F();');
    checkLibrary('import "a.dart"; C c; E e; F f;');
  }

  test_type_reference_to_typedef() {
    checkLibrary('typedef F(); F f;');
  }

  test_type_reference_to_typedef_with_type_arguments() {
    checkLibrary('typedef U F<T, U>(T t); F<int, String> f;');
  }

  test_type_reference_to_typedef_with_type_arguments_implicit() {
    checkLibrary('typedef U F<T, U>(T t); F f;');
  }

  test_type_unresolved() {
    checkLibrary('C c;', allowErrors: true);
  }

  test_type_unresolved_prefixed() {
    checkLibrary('import "dart:core" as core; core.C c;', allowErrors: true);
  }

  test_typedef_documented() {
    checkLibrary('''
// Extra comment so doc comment offset != 0
/**
 * Docs
 */
typedef F();''');
  }

  test_typedef_parameter_parameters() {
    checkLibrary('typedef F(g(x, y));');
  }

  test_typedef_parameter_parameters_in_generic_class() {
    checkLibrary('typedef F<A, B>(A g(B x));');
  }

  test_typedef_parameter_return_type() {
    checkLibrary('typedef F(int g());');
  }

  test_typedef_parameter_type() {
    checkLibrary('typedef F(int i);');
  }

  test_typedef_parameter_type_generic() {
    checkLibrary('typedef F<T>(T t);');
  }

  test_typedef_parameters() {
    checkLibrary('typedef F(x, y);');
  }

  test_typedef_return_type() {
    checkLibrary('typedef int F();');
  }

  test_typedef_return_type_generic() {
    checkLibrary('typedef T F<T>();');
  }

  test_typedef_return_type_implicit() {
    checkLibrary('typedef F();');
  }

  test_typedef_return_type_void() {
    checkLibrary('typedef void F();');
  }

  test_typedef_type_parameters() {
    checkLibrary('typedef U F<T, U>(T t);');
  }

  test_typedef_type_parameters_bound() {
    checkLibrary('typedef U F<T extends Object, U extends D>(T t); class D {}');
  }

  test_typedef_type_parameters_f_bound_complex() {
    checkLibrary('typedef U F<T extends List<U>, U>(T t);');
  }

  test_typedef_type_parameters_f_bound_simple() {
    checkLibrary('typedef U F<T extends U, U>(T t);');
  }

  test_typedefs() {
    checkLibrary('f() {} g() {}');
  }

  test_variable_const() {
    checkLibrary('const int i = 0;');
  }

  test_variable_documented() {
    checkLibrary('''
// Extra comment so doc comment offset != 0
/**
 * Docs
 */
var x;''');
  }

  test_variable_final() {
    checkLibrary('final int x = 0;');
  }

  test_variable_getterInLib_setterInPart() {
    addNamedSource('/a.dart', 'part of my.lib; void set x(int _) {}');
    checkLibrary('library my.lib; part "a.dart"; int get x => 42;');
  }

  test_variable_getterInPart_setterInLib() {
    addNamedSource('/a.dart', 'part of my.lib; int get x => 42;');
    checkLibrary('library my.lib; part "a.dart"; void set x(int _) {}');
  }

  test_variable_getterInPart_setterInPart() {
    addNamedSource('/a.dart', 'part of my.lib; int get x => 42;');
    addNamedSource('/b.dart', 'part of my.lib; void set x(int _) {}');
    checkLibrary('library my.lib; part "a.dart"; part "b.dart";');
  }

  test_variable_implicit_type() {
    checkLibrary('var x;');
  }

  test_variable_inferred_type_implicit_initialized() {
    checkLibrary('var v = 0;');
  }

  test_variable_propagatedType_const_noDep() {
    checkLibrary('const i = 0;');
  }

  test_variable_propagatedType_final_dep_inLib() {
    addLibrarySource('/a.dart', 'final a = 1;');
    checkLibrary('import "a.dart"; final b = a / 2;');
  }

  test_variable_propagatedType_final_dep_inPart() {
    addNamedSource('/a.dart', 'part of lib; final a = 1;');
    checkLibrary('library lib; part "a.dart"; final b = a / 2;');
  }

  test_variable_propagatedType_final_noDep() {
    checkLibrary('final i = 0;');
  }

  test_variable_propagatedType_implicit_dep() {
    // The propagated type is defined in a library that is not imported.
    addLibrarySource('/a.dart', 'class C {}');
    addLibrarySource('/b.dart', 'import "a.dart"; C f() => null;');
    checkLibrary('import "b.dart"; final x = f();');
  }

  test_variable_setterInPart_getterInPart() {
    addNamedSource('/a.dart', 'part of my.lib; void set x(int _) {}');
    addNamedSource('/b.dart', 'part of my.lib; int get x => 42;');
    checkLibrary('library my.lib; part "a.dart"; part "b.dart";');
  }

  test_variables() {
    checkLibrary('int i; int j;');
  }

  /**
   * Encode the library containing [original] into a summary and then use
   * [_TestSummaryResynthesizer.getElement] to retrieve just the original
   * element from the resynthesized summary.
   */
  Element validateGetElement(Element original) {
    _TestSummaryResynthesizer resynthesizer = encodeLibrary(original.library);
    ElementLocationImpl location = original.location;
    Element result = resynthesizer.getElement(location);
    checkMinimalResynthesisWork(resynthesizer, original.library);
    // Check that no other summaries needed to be resynthesized to resynthesize
    // the library element.
    expect(resynthesizer.resynthesisCount, 1);
    expect(result.location, location);
    return result;
  }

  void _assertUnresolvedIdentifier(Expression initializer, String desc) {
    expect(initializer, new isInstanceOf<SimpleIdentifier>(), reason: desc);
    SimpleIdentifier identifier = initializer;
    expect(identifier.staticElement, isNull, reason: desc);
  }
}

class _TestSummaryResynthesizer extends SummaryResynthesizer {
  final Map<String, UnlinkedUnit> unlinkedSummaries;
  final Map<String, LinkedLibrary> linkedSummaries;

  /**
   * The set of uris for which unlinked summaries have been requested using
   * [getUnlinkedSummary].
   */
  final Set<String> unlinkedSummariesRequested = new Set<String>();

  /**
   * The set of uris for which linked summaries have been requested using
   * [getLinkedSummary].
   */
  final Set<String> linkedSummariesRequested = new Set<String>();

  _TestSummaryResynthesizer(
      SummaryResynthesizer parent,
      AnalysisContext context,
      TypeProvider typeProvider,
      SourceFactory sourceFactory,
      this.unlinkedSummaries,
      this.linkedSummaries,
      bool strongMode)
      : super(parent, context, typeProvider, sourceFactory, strongMode);

  @override
  LinkedLibrary getLinkedSummary(String uri) {
    linkedSummariesRequested.add(uri);
    LinkedLibrary serializedLibrary = linkedSummaries[uri];
    if (serializedLibrary == null) {
      fail('Unexpectedly tried to get linked summary for $uri');
    }
    return serializedLibrary;
  }

  @override
  UnlinkedUnit getUnlinkedSummary(String uri) {
    unlinkedSummariesRequested.add(uri);
    UnlinkedUnit serializedUnit = unlinkedSummaries[uri];
    if (serializedUnit == null) {
      fail('Unexpectedly tried to get unlinked summary for $uri');
    }
    return serializedUnit;
  }

  @override
  bool hasLibrarySummary(String uri) {
    return true;
  }
}
