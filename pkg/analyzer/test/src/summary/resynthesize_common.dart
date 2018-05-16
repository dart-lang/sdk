// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.src.serialization.elements_test;

import 'dart:async';

import 'package:analyzer/dart/analysis/declared_variables.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/standard_resolution_map.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/handle.dart';
import 'package:analyzer/src/dart/element/member.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/resolver.dart' show Namespace;
import 'package:analyzer/src/generated/sdk.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/generated/testing/ast_test_factory.dart';
import 'package:analyzer/src/summary/idl.dart';
import 'package:analyzer/src/summary/resynthesize.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../generated/test_support.dart';
import '../abstract_single_unit.dart';
import '../context/abstract_context.dart';
import 'element_text.dart';

/**
 * Abstract base class for resynthesizing and comparing elements.
 *
 * The return type separator: →
 */
abstract class AbstractResynthesizeTest extends AbstractSingleUnitTest {
  Set<Source> otherLibrarySources = new Set<Source>();

  /**
   * Names of variables which have initializers that are not valid constants,
   * so they are not resynthesized.
   */
  Set<String> variablesWithNotConstInitializers = new Set<String>();

  /**
   * Names that cannot be resolved, e.g. because of duplicate declaration.
   */
  Set<String> namesThatCannotBeResolved = new Set<String>();

  /**
   * Tests may set this to `true` to indicate that a missing file at the time of
   * summary resynthesis shouldn't trigger an error.
   */
  bool allowMissingFiles = false;

  /**
   * Tests may set this to `false` to indicate that resynthesized elements
   * should not be compare with elements created using AnalysisContext.
   */
  bool shouldCompareLibraryElements = true;

  /**
   * Return `true` if shared front-end is used.
   */
  bool get isSharedFrontEnd => false;

  /**
   * Return `true` if resynthesizing should be done in strong mode.
   */
  bool get isStrongMode;

  void addLibrary(String uri) {
    otherLibrarySources.add(context.sourceFactory.forUri(uri));
  }

  Source addLibrarySource(String filePath, String contents) {
    Source source = addSource(filePath, contents);
    otherLibrarySources.add(source);
    return source;
  }

  void assertNoErrors(Source source) {
    GatheringErrorListener errorListener = new GatheringErrorListener();
    for (AnalysisError error in context.computeErrors(source)) {
      expect(error.source, source);
      ErrorCode errorCode = error.errorCode;
      if (errorCode == HintCode.UNUSED_ELEMENT ||
          errorCode == HintCode.UNUSED_FIELD) {
        continue;
      }
      if (errorCode == HintCode.UNUSED_CATCH_CLAUSE ||
          errorCode == HintCode.UNUSED_CATCH_STACK ||
          errorCode == HintCode.UNUSED_LOCAL_VARIABLE) {
        continue;
      }
      errorListener.onError(error);
    }
    errorListener.assertNoErrors();
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

  void checkLibraryElements(
      LibraryElementImpl original, LibraryElementImpl resynthesized) {
    compareElements(resynthesized, original, '(library)');
    expect(resynthesized.displayName, original.displayName);
    expect(original.enclosingElement, isNull);
    expect(resynthesized.enclosingElement, isNull);
    expect(resynthesized.hasExtUri, original.hasExtUri);
    compareCompilationUnitElements(resynthesized.definingCompilationUnit,
        original.definingCompilationUnit);
    expect(resynthesized.parts.length, original.parts.length, reason: 'parts');
    for (int i = 0; i < resynthesized.parts.length; i++) {
      compareCompilationUnitElements(resynthesized.parts[i], original.parts[i]);
    }
    expect(resynthesized.imports.length, original.imports.length,
        reason: 'imports');
    for (int i = 0; i < resynthesized.imports.length; i++) {
      ImportElement originalImport = original.imports[i];
      compareImportElements(
          resynthesized.imports[i], originalImport, originalImport.toString());
    }
    expect(resynthesized.exports.length, original.exports.length,
        reason: 'exports');
    for (int i = 0; i < resynthesized.exports.length; i++) {
      ExportElement originalExport = original.exports[i];
      compareExportElements(
          resynthesized.exports[i], originalExport, originalExport.toString());
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
      TestSummaryResynthesizer resynthesizer, LibraryElement library) {
    // Check that no other summaries needed to be resynthesized to resynthesize
    // the library element.
    expect(resynthesizer.resynthesisCount, 3);
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

  void compareClassElements(ClassElement r, ClassElement o, String desc) {
    compareElements(r, o, desc);
    expect(r.fields.length, o.fields.length, reason: '$desc fields.length');
    for (int i = 0; i < r.fields.length; i++) {
      String name = o.fields[i].name;
      compareFieldElements(r.fields[i], o.fields[i], '$desc.field $name');
    }
    compareTypes(r.supertype, o.supertype, '$desc supertype');
    expect(r.interfaces.length, o.interfaces.length,
        reason: '$desc interfaces.length');
    for (int i = 0; i < r.interfaces.length; i++) {
      compareTypes(r.interfaces[i], o.interfaces[i],
          '$desc interface ${o.interfaces[i].name}');
    }
    expect(r.mixins.length, o.mixins.length, reason: '$desc mixins.length');
    for (int i = 0; i < r.mixins.length; i++) {
      compareTypes(r.mixins[i], o.mixins[i], '$desc mixin ${o.mixins[i].name}');
    }
    expect(r.typeParameters.length, o.typeParameters.length,
        reason: '$desc typeParameters.length');
    for (int i = 0; i < r.typeParameters.length; i++) {
      compareTypeParameterElements(r.typeParameters[i], o.typeParameters[i],
          '$desc type parameter ${o.typeParameters[i].name}');
    }
    expect(r.constructors.length, o.constructors.length,
        reason: '$desc constructors.length');
    for (int i = 0; i < r.constructors.length; i++) {
      compareConstructorElements(r.constructors[i], o.constructors[i],
          '$desc constructor ${o.constructors[i].name}');
    }
    expect(r.accessors.length, o.accessors.length,
        reason: '$desc accessors.length');
    List<PropertyAccessorElement> rAccessors = _getSortedPropertyAccessors(r);
    List<PropertyAccessorElement> oAccessors = _getSortedPropertyAccessors(o);
    for (int i = 0; i < r.accessors.length; i++) {
      comparePropertyAccessorElements(
          rAccessors[i], oAccessors[i], '$desc accessor ${oAccessors[i].name}');
    }
    expect(r.methods.length, o.methods.length, reason: '$desc methods.length');
    for (int i = 0; i < r.methods.length; i++) {
      compareMethodElements(
          r.methods[i], o.methods[i], '$desc.${o.methods[i].name}');
    }
    compareTypes(r.type, o.type, desc);
    if (r is ClassElementImpl && o is ClassElementImpl) {
      expect(r.hasBeenInferred, o.hasBeenInferred, reason: desc);
    }
  }

  void compareCompilationUnitElements(CompilationUnitElementImpl resynthesized,
      CompilationUnitElementImpl original) {
    String desc = 'Compilation unit ${original.source.uri}';
    expect(resynthesized.source, original.source);
    expect(resynthesized.librarySource, original.librarySource);
    compareLineInfo(resynthesized.lineInfo, original.lineInfo);
    expect(resynthesized.types.length, original.types.length,
        reason: '$desc.types.length');
    for (int i = 0; i < resynthesized.types.length; i++) {
      compareClassElements(
          resynthesized.types[i], original.types[i], original.types[i].name);
    }
    expect(resynthesized.topLevelVariables.length,
        original.topLevelVariables.length,
        reason: '$desc.topLevelVariables.length');
    for (int i = 0; i < resynthesized.topLevelVariables.length; i++) {
      String name = resynthesized.topLevelVariables[i].name;
      compareTopLevelVariableElements(
          resynthesized.topLevelVariables[i],
          original.topLevelVariables
              .singleWhere((TopLevelVariableElement e) => e.name == name),
          '$desc.topLevelVariables[$name]');
    }
    expect(resynthesized.functions.length, original.functions.length,
        reason: '$desc.functions.length');
    for (int i = 0; i < resynthesized.functions.length; i++) {
      compareFunctionElements(resynthesized.functions[i], original.functions[i],
          '$desc.functions[$i] /* ${original.functions[i].name} */');
    }
    expect(resynthesized.functionTypeAliases.length,
        original.functionTypeAliases.length,
        reason: '$desc.functionTypeAliases.length');
    for (int i = 0; i < resynthesized.functionTypeAliases.length; i++) {
      compareFunctionTypeAliasElements(
          resynthesized.functionTypeAliases[i],
          original.functionTypeAliases[i],
          original.functionTypeAliases[i].name);
    }
    expect(resynthesized.enums.length, original.enums.length,
        reason: '$desc.enums.length');
    for (int i = 0; i < resynthesized.enums.length; i++) {
      compareClassElements(
          resynthesized.enums[i], original.enums[i], original.enums[i].name);
    }
    expect(resynthesized.accessors.length, original.accessors.length,
        reason: '$desc.accessors.length');
    for (int i = 0; i < resynthesized.accessors.length; i++) {
      String name = resynthesized.accessors[i].name;
      if (original.accessors[i].isGetter) {
        comparePropertyAccessorElements(
            resynthesized.accessors[i],
            original.accessors
                .singleWhere((PropertyAccessorElement e) => e.name == name),
            '$desc.accessors[$i] /* getter $name */');
      } else {
        comparePropertyAccessorElements(
            resynthesized.accessors[i],
            original.accessors
                .singleWhere((PropertyAccessorElement e) => e.name == name),
            '$desc.accessors[$i] /* setter $name */');
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
        if (variablesWithNotConstInitializers.contains(rItem.fieldName.name)) {
          expect(rItem.expression, isNull, reason: desc);
        } else {
          compareConstAsts(rItem.expression, oItem.expression, desc);
        }
      } else if (oItem is AssertInitializer && rItem is AssertInitializer) {
        compareConstAsts(rItem.condition, oItem.condition, '$desc condition');
        compareConstAsts(rItem.message, oItem.message, '$desc message');
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
        if (namesThatCannotBeResolved.contains(r.name)) {
          expect(r.staticElement, isNull);
        } else {
          compareElements(r.staticElement, o.staticElement, desc);
        }
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
      } else if (o is SimpleIdentifier && r is PrefixedIdentifier) {
        // In 'class C {static const a = 0; static const b = a;}' the reference
        // to 'a' in 'b' is serialized as a fully qualified 'C.a' reference.
        if (r.prefix.staticElement is ClassElement) {
          Element oElement = resolutionMap.staticElementForIdentifier(o);
          compareElements(
              r.prefix.staticElement, oElement?.enclosingElement, desc);
          compareConstAsts(r.identifier, o, desc);
        } else {
          fail('Prefix of type ${r.prefix.staticElement.runtimeType} should not'
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
            r,
            AstTestFactory.identifier(oTarget.identifier, o.propertyName),
            desc);
      } else if (o is PrefixedIdentifier && r is PrefixedIdentifier) {
        compareConstAsts(r.prefix, o.prefix, desc);
        compareConstAsts(r.identifier, o.identifier, desc);
      } else if (o is PropertyAccess && r is PropertyAccess) {
        compareConstAsts(r.target, o.target, desc);
        String oName = o.propertyName.name;
        String rName = r.propertyName.name;
        expect(rName, oName, reason: desc);
        if (oName == 'length') {
          compareElements(
              r.propertyName.staticElement, o.propertyName.staticElement, desc);
        }
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
      } else if (o is SuperExpression && r is SuperExpression) {
        // Nothing to compare.
      } else if (o is ThisExpression && r is ThisExpression) {
        // Nothing to compare.
      } else if (o is NullLiteral) {
        expect(r, new isInstanceOf<NullLiteral>(), reason: desc);
      } else if (o is BooleanLiteral && r is BooleanLiteral) {
        expect(r.value, o.value, reason: desc);
      } else if (o is IntegerLiteral && r is IntegerLiteral) {
        expect(r.value ?? 0, o.value ?? 0, reason: desc);
      } else if (o is IntegerLiteral && r is PrefixExpression) {
        expect(r.operator.type, TokenType.MINUS);
        IntegerLiteral ri = r.operand;
        expect(-ri.value, o.value, reason: desc);
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
      } else if (o is MethodInvocation && r is MethodInvocation) {
        compareConstAsts(r.target, o.target, desc);
        compareConstAsts(r.methodName, o.methodName, desc);
        compareConstAstLists(
            r.typeArguments?.arguments, o.typeArguments?.arguments, desc);
        compareConstAstLists(
            r.argumentList?.arguments, o.argumentList?.arguments, desc);
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
        // In strong mode type inference is performed, so that
        // `C<int> v = new C();` is serialized as `C<int> v = new C<int>();`.
        // So, if there are not type arguments originally, not need to check.
        if (oType.typeArguments?.arguments?.isNotEmpty ?? false) {
          compareConstAstLists(rType.typeArguments?.arguments,
              oType.typeArguments?.arguments, desc);
        }
        compareConstAstLists(
            r.argumentList.arguments, o.argumentList.arguments, desc);
      } else if (o is AnnotationImpl && r is AnnotationImpl) {
        expect(o.atSign.lexeme, r.atSign.lexeme, reason: desc);
        Identifier rName = r.name;
        Identifier oName = o.name;
        if (oName is PrefixedIdentifier &&
            rName is PrefixedIdentifier &&
            o.constructorName != null &&
            o.element != null &&
            r.constructorName == null) {
          // E.g. `@prefix.cls.ctor`.  This sometimes gets resynthesized as
          // `@cls.ctor`, with `cls.ctor` represented as a PrefixedIdentifier.
          compareConstAsts(rName.prefix, oName.identifier, desc);
          expect(rName.period.lexeme, '.', reason: desc);
          compareConstAsts(rName.identifier, o.constructorName, desc);
          expect(r.period, isNull, reason: desc);
          expect(r.constructorName, isNull, reason: desc);
        } else {
          compareConstAsts(r.name, o.name, desc);
          expect(r.period?.lexeme, o.period?.lexeme, reason: desc);
          compareConstAsts(r.constructorName, o.constructorName, desc);
        }
        compareConstAstLists(
            r.arguments?.arguments, o.arguments?.arguments, desc);
        compareElements(r.element, o.element, desc);
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
    if (original.element == null) {
      expect(resynthesized.element, isNull);
    } else {
      expect(resynthesized.element, isNotNull, reason: desc);
      expect(resynthesized.element.kind, original.element.kind, reason: desc);
      expect(resynthesized.element.location, original.element.location,
          reason: desc);
    }
    expect(resynthesized.compilationUnit, isNotNull, reason: desc);
    expect(resynthesized.compilationUnit.location,
        original.compilationUnit.location,
        reason: desc);
    expect(resynthesized.annotationAst, isNotNull, reason: desc);
    compareConstAsts(resynthesized.annotationAst, original.annotationAst, desc);
  }

  void compareElementLocations(
      Element resynthesized, Element original, String desc) {
    bool hasFunctionElementByValue(Element e) {
      if (e == null) {
        return false;
      }
      if (e is FunctionElementImpl_forLUB) {
        return true;
      }
      return hasFunctionElementByValue(e.enclosingElement);
    }

    if (hasFunctionElementByValue(resynthesized)) {
      // We resynthesize elements representing types of local functions
      // without corresponding name offsets, so their locations don't have
      // corresponding valid @offset components. Also, we don't put
      // resynthesized local functions into initializers of variables.
      return;
    }
    expect(resynthesized.location, original.location, reason: desc);
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
    expect(resynthesized, isNotNull, reason: desc);
    if (rImpl is DefaultParameterElementImpl && oImpl is ParameterElementImpl) {
      // This is ok provided the resynthesized parameter element doesn't have
      // any evaluation result.
      expect(rImpl.evaluationResult, isNull);
    } else {
      Type rRuntimeType;
      if (rImpl is ConstFieldElementImpl) {
        rRuntimeType = ConstFieldElementImpl;
      } else if (rImpl is FunctionElementImpl) {
        rRuntimeType = FunctionElementImpl;
      } else {
        rRuntimeType = rImpl.runtimeType;
      }
      expect(rRuntimeType, oImpl.runtimeType);
    }
    expect(resynthesized.kind, original.kind);
    compareElementLocations(resynthesized, original, desc);
    expect(resynthesized.name, original.name);
    expect(resynthesized.nameOffset, original.nameOffset,
        reason: '$desc.nameOffset');
    expect(rImpl.codeOffset, oImpl.codeOffset, reason: desc);
    expect(rImpl.codeLength, oImpl.codeLength, reason: desc);
    expect(resynthesized.documentationComment, original.documentationComment,
        reason: desc);
    compareMetadata(resynthesized.metadata, original.metadata, desc);

    // Validate modifiers.
    for (Modifier modifier in Modifier.values) {
      bool got = _hasModifier(resynthesized, modifier);
      bool want = _hasModifier(original, modifier);
      expect(got, want,
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
    if (!original.hasImplicitReturnType) {
      compareTypes(
          resynthesized.returnType, original.returnType, '$desc return type');
    }
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
  }

  void compareExportElements(ExportElementImpl resynthesized,
      ExportElementImpl original, String desc) {
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

  void compareFunctionTypeAliasElements(FunctionTypeAliasElement resynthesized,
      FunctionTypeAliasElement original, String desc) {
    compareElements(resynthesized, original, desc);
    ElementImpl rImpl = getActualElement(resynthesized, desc);
    ElementImpl oImpl = getActualElement(original, desc);
    if (rImpl is GenericTypeAliasElementImpl) {
      if (oImpl is GenericTypeAliasElementImpl) {
        compareGenericFunctionTypeElements(
            rImpl.function, oImpl.function, '$desc.function');
      } else {
        fail(
            'Resynthesized a GenericTypeAliasElementImpl, but expected a ${oImpl.runtimeType}');
      }
    } else {
      fail('Resynthesized a ${rImpl.runtimeType}');
    }
    compareTypes(resynthesized.type, original.type, desc);
    expect(resynthesized.typeParameters.length, original.typeParameters.length);
    for (int i = 0; i < resynthesized.typeParameters.length; i++) {
      compareTypeParameterElements(
          resynthesized.typeParameters[i],
          original.typeParameters[i],
          '$desc.typeParameters[$i] /* ${original.typeParameters[i].name} */');
    }
  }

  void compareGenericFunctionTypeElements(
      GenericFunctionTypeElement resynthesized,
      GenericFunctionTypeElement original,
      String desc) {
    if (resynthesized == null) {
      if (original != null) {
        fail('Failed to resynthesize generic function type');
      }
    } else if (original == null) {
      fail('Resynthesizes a generic function type when none expected');
    }
    compareTypeParameterElementLists(resynthesized.typeParameters,
        original.typeParameters, '$desc.typeParameters');
    compareParameterElementLists(
        resynthesized.parameters, original.parameters, '$desc.parameters');
    compareTypes(
        resynthesized.returnType, original.returnType, '$desc.returnType');
  }

  void compareImportElements(ImportElementImpl resynthesized,
      ImportElementImpl original, String desc) {
    expect(resynthesized.importedLibrary.location,
        original.importedLibrary.location,
        reason: '$desc importedLibrary location');
    expect(resynthesized.prefixOffset, original.prefixOffset,
        reason: '$desc prefixOffset');
    if (original.prefix == null) {
      expect(resynthesized.prefix, isNull, reason: '$desc prefix');
    } else {
      comparePrefixElements(
          resynthesized.prefix, original.prefix, original.prefix.name);
    }
    expect(resynthesized.combinators.length, original.combinators.length,
        reason: '$desc combinators');
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

  void compareLineInfo(LineInfo resynthesized, LineInfo original) {
    expect(resynthesized.lineCount, original.lineCount);
    expect(resynthesized.lineStarts, original.lineStarts);
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
      expect(resynthesized.shownNames, original.shownNames,
          reason: 'shownNames');
      expect(resynthesized.offset, original.offset, reason: 'offset');
      expect(resynthesized.end, original.end, reason: 'end');
    } else if (original is HideElementCombinatorImpl &&
        resynthesized is HideElementCombinatorImpl) {
      expect(resynthesized.hiddenNames, original.hiddenNames,
          reason: 'hiddenNames');
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
          '$desc.parameters[$i] /* ${originalParameters[i].name} */');
    }
  }

  void compareParameterElements(
      ParameterElement resynthesized, ParameterElement original, String desc) {
    compareVariableElements(resynthesized, original, desc);
    compareParameterElementLists(
        resynthesized.parameters, original.parameters, desc);
    // ignore: deprecated_member_use
    expect(resynthesized.parameterKind, original.parameterKind, reason: desc);
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
    expect(resynthesized.isCovariant, original.isCovariant,
        reason: '$desc isCovariant');
    ParameterElementImpl resynthesizedActual =
        getActualElement(resynthesized, desc);
    ParameterElementImpl originalActual = getActualElement(original, desc);
    expect(resynthesizedActual.isExplicitlyCovariant,
        originalActual.isExplicitlyCovariant,
        reason: desc);
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
    compareElementLocations(
        resynthesized.element, original.element, '$desc.element.location');
    expect(resynthesized.name, original.name, reason: '$desc.name');
  }

  void compareTypeParameterElementLists(
      List<TypeParameterElement> resynthesized,
      List<TypeParameterElement> original,
      String desc) {
    int length = original.length;
    expect(resynthesized.length, length, reason: '$desc.length');
    for (int i = 0; i < length; i++) {
      compareTypeParameterElements(resynthesized[i], original[i], '$desc[$i]');
    }
  }

  void compareTypeParameterElements(TypeParameterElement resynthesized,
      TypeParameterElement original, String desc) {
    compareElements(resynthesized, original, desc);
    compareTypes(resynthesized.type, original.type, '$desc.type');
    compareTypes(resynthesized.bound, original.bound, '$desc.bound');
  }

  void compareTypes(DartType resynthesized, DartType original, String desc) {
    if (original == null) {
      expect(resynthesized, isNull, reason: desc);
    } else if (resynthesized is InterfaceTypeImpl &&
        original is InterfaceTypeImpl) {
      compareTypeImpls(resynthesized, original, desc);
      expect(resynthesized.typeArguments.length, original.typeArguments.length,
          reason: '$desc.typeArguments.length');
      for (int i = 0; i < resynthesized.typeArguments.length; i++) {
        compareTypes(resynthesized.typeArguments[i], original.typeArguments[i],
            '$desc.typeArguments[$i] /* ${original.typeArguments[i].name} */');
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
      if (original.element.enclosingElement == null &&
          original.element is FunctionElement) {
        expect(resynthesized.element, new isInstanceOf<FunctionElement>());
        expect(resynthesized.element.enclosingElement, isNull, reason: desc);
        compareFunctionElements(
            resynthesized.element, original.element, '$desc.element',
            shallow: true);
        expect(resynthesized.element.type, same(resynthesized));
      }
      expect(resynthesized.typeArguments.length, original.typeArguments.length,
          reason: '$desc.typeArguments.length');
      for (int i = 0; i < resynthesized.typeArguments.length; i++) {
        if (resynthesized.typeArguments[i].isDynamic &&
            original.typeArguments[i] is TypeParameterType) {
          // It's ok for type arguments to get converted to `dynamic` if they
          // are not used.
          expect(
              isTypeParameterUsed(
                  original.typeArguments[i], original.element.type),
              isFalse);
        } else {
          compareTypes(
              resynthesized.typeArguments[i],
              original.typeArguments[i],
              '$desc.typeArguments[$i] /* ${original.typeArguments[i].name} */');
        }
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
              original.typeParameters[i], '$desc.typeParameters[$i]');
        }
      }
      expect(resynthesized.typeFormals.length, original.typeFormals.length,
          reason: desc);
      for (int i = 0; i < resynthesized.typeFormals.length; i++) {
        compareTypeParameterElements(resynthesized.typeFormals[i],
            original.typeFormals[i], '$desc.typeFormals[$i]');
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
      fail('Type mismatch: expected $original,'
          ' got $resynthesized ($desc)');
    } else {
      fail('Unimplemented comparison for ${original.runtimeType}');
    }
  }

  void compareVariableElements(
      VariableElement resynthesized, VariableElement original, String desc) {
    compareElements(resynthesized, original, desc);
    if ((resynthesized as VariableElementImpl).typeInferenceError == null) {
      compareTypes(resynthesized.type, original.type, '$desc.type');
    }
    VariableElementImpl resynthesizedActual =
        getActualElement(resynthesized, desc);
    VariableElementImpl originalActual = getActualElement(original, desc);
    compareFunctionElements(resynthesizedActual.initializer,
        originalActual.initializer, '$desc.initializer');
    if (originalActual is ConstVariableElement) {
      Element oEnclosing = original.enclosingElement;
      if (oEnclosing is ClassElement && oEnclosing.isEnum) {
        compareConstValues(resynthesized.constantValue, original.constantValue,
            '$desc.constantValue');
      } else {
        Expression initializer = resynthesizedActual.constantInitializer;
        if (variablesWithNotConstInitializers.contains(resynthesized.name)) {
          expect(initializer, isNull, reason: desc);
        } else {
          compareConstAsts(initializer, originalActual.constantInitializer,
              '$desc.constantInitializer');
        }
      }
    }
    checkPossibleMember(resynthesized, original, desc);
    checkPossibleLocalElements(resynthesized, original);
  }

  DartSdk createDartSdk() => AbstractContextTest.SHARED_MOCK_SDK;

  /**
   * Create the analysis options that should be used for this test.
   */
  AnalysisOptionsImpl createOptions() => new AnalysisOptionsImpl();

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
    }
  }

  /**
   * Determine if [type] makes use of the given [typeParameter].
   */
  bool isTypeParameterUsed(TypeParameterType typeParameter, DartType type) {
    if (type is FunctionType) {
      return isTypeParameterUsed(typeParameter, type.returnType) ||
          type.parameters.any((ParameterElement e) =>
              isTypeParameterUsed(typeParameter, e.type));
    } else if (type is InterfaceType) {
      return type.typeArguments
          .any((DartType t) => isTypeParameterUsed(typeParameter, t));
    } else if (type is TypeParameterType) {
      return type == typeParameter;
    } else {
      expect(type.isDynamic || type.isVoid, isTrue);
      return false;
    }
  }

  @override
  void setUp() {
    super.setUp();
    prepareAnalysisContext(createOptions());
  }

  List<PropertyAccessorElement> _getSortedPropertyAccessors(
      ClassElement classElement) {
    List<PropertyAccessorElement> accessors = classElement.accessors.toList();
    accessors.sort((a, b) => a.displayName.compareTo(b.displayName));
    return accessors;
  }

  bool _hasModifier(Element element, Modifier modifier) {
    if (modifier == Modifier.ABSTRACT) {
      if (element is ClassElement) {
        return element.isAbstract;
      }
      if (element is ExecutableElement) {
        return element.isAbstract;
      }
      return false;
    } else if (modifier == Modifier.ASYNCHRONOUS) {
      if (element is ExecutableElement) {
        return element.isAsynchronous;
      }
      return false;
    } else if (modifier == Modifier.CONST) {
      if (element is VariableElement) {
        return element.isConst;
      }
      return false;
    } else if (modifier == Modifier.COVARIANT) {
      if (element is ParameterElementImpl) {
        return element.isExplicitlyCovariant;
      }
      return false;
    } else if (modifier == Modifier.DEFERRED) {
      if (element is ImportElement) {
        return element.isDeferred;
      }
      return false;
    } else if (modifier == Modifier.ENUM) {
      if (element is ClassElement) {
        return element.isEnum;
      }
      return false;
    } else if (modifier == Modifier.EXTERNAL) {
      if (element is ExecutableElement) {
        return element.isExternal;
      }
      return false;
    } else if (modifier == Modifier.FACTORY) {
      if (element is ConstructorElement) {
        return element.isFactory;
      }
      return false;
    } else if (modifier == Modifier.FINAL) {
      if (element is VariableElement) {
        return element.isFinal;
      }
      return false;
    } else if (modifier == Modifier.GENERATOR) {
      if (element is ExecutableElement) {
        return element.isGenerator;
      }
      return false;
    } else if (modifier == Modifier.GETTER) {
      if (element is PropertyAccessorElement) {
        return element.isGetter;
      }
      return false;
    } else if (modifier == Modifier.HAS_EXT_URI) {
      if (element is LibraryElement) {
        return element.hasExtUri;
      }
      return false;
    } else if (modifier == Modifier.IMPLICIT_TYPE) {
      if (element is ExecutableElement) {
        return element.hasImplicitReturnType;
      }
      return false;
    } else if (modifier == Modifier.MIXIN_APPLICATION) {
      if (element is ClassElement) {
        return element.isMixinApplication;
      }
      return false;
    } else if (modifier == Modifier.REFERENCES_SUPER) {
      if (element is ClassElement) {
        return element.hasReferenceToSuper;
      }
      return false;
    } else if (modifier == Modifier.SETTER) {
      if (element is PropertyAccessorElement) {
        return element.isSetter;
      }
      return false;
    } else if (modifier == Modifier.STATIC) {
      if (element is ExecutableElement) {
        return element.isStatic;
      } else if (element is FieldElement) {
        return element.isStatic;
      }
      return false;
    } else if (modifier == Modifier.SYNTHETIC) {
      return element.isSynthetic;
    }
    throw new UnimplementedError(
        'Modifier $modifier for ${element?.runtimeType}');
  }
}

@reflectiveTest
abstract class ResynthesizeTest extends AbstractResynthesizeTest {
  Future<LibraryElementImpl> checkLibrary(String text,
      {bool allowErrors: false, bool dumpSummaries: false});

  test_class_abstract() async {
    var library = await checkLibrary('abstract class C {}');
    checkElementText(library, r'''
abstract class C {
}
''');
  }

  test_class_alias() async {
    var library = await checkLibrary('''
class C = D with E, F, G;
class D {}
class E {}
class F {}
class G {}
''');
    checkElementText(library, r'''
class alias C extends D with E, F, G {
  synthetic C() = D;
}
class D {
}
class E {
}
class F {
}
class G {
}
''');
  }

  test_class_alias_abstract() async {
    var library = await checkLibrary('''
abstract class C = D with E;
class D {}
class E {}
''');
    checkElementText(library, r'''
abstract class alias C extends D with E {
  synthetic C() = D;
}
class D {
}
class E {
}
''');
  }

  test_class_alias_documented() async {
    var library = await checkLibrary('''
/**
 * Docs
 */
class C = D with E;

class D {}
class E {}
''');
    checkElementText(library, r'''
/**
 * Docs
 */
class alias C extends D with E {
  synthetic C() = D;
}
class D {
}
class E {
}
''');
  }

  test_class_alias_documented_tripleSlash() async {
    var library = await checkLibrary('''
/// aaa
/// b
/// cc
class C = D with E;

class D {}
class E {}
''');
    checkElementText(library, r'''
/// aaa
/// b
/// cc
class alias C extends D with E {
  synthetic C() = D;
}
class D {
}
class E {
}
''');
  }

  test_class_alias_documented_withLeadingNonDocumentation() async {
    var library = await checkLibrary('''
// Extra comment so doc comment offset != 0
/**
 * Docs
 */
class C = D with E;

class D {}
class E {}''');
    checkElementText(library, r'''
/**
 * Docs
 */
class alias C extends D with E {
  synthetic C() = D;
}
class D {
}
class E {
}
''');
  }

  test_class_alias_generic() async {
    var library = await checkLibrary('''
class Z = A with B<int>, C<double>;
class A {}
class B<B1> {}
class C<C1> {}
''');
    checkElementText(library, r'''
class alias Z extends A with B<int>, C<double> {
  synthetic Z() = A;
}
class A {
}
class B<B1> {
}
class C<C1> {
}
''');
  }

  test_class_alias_with_forwarding_constructors() async {
    addLibrarySource('/a.dart', '''
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
    var library = await checkLibrary('''
import "a.dart";
class M {}
class MixinApp = Base with M;
''');
    checkElementText(library, r'''
import 'a.dart';
class M {
}
class alias MixinApp extends Base with M {
  synthetic MixinApp() = Base;
  synthetic MixinApp.noArgs() = Base.noArgs;
  synthetic MixinApp.requiredArg(dynamic x) = Base.requiredArg;
  synthetic MixinApp.fact() = Base.fact;
  synthetic MixinApp.fact2() = Base.fact2;
}
''');
  }

  test_class_alias_with_forwarding_constructors_type_substitution() async {
    var library = await checkLibrary('''
class Base<T> {
  Base.ctor(T t, List<T> l);
}
class M {}
class MixinApp = Base with M;
''');
    checkElementText(library, r'''
class Base<T> {
  Base.ctor(T t, List<T> l);
}
class M {
}
class alias MixinApp extends Base<dynamic> with M {
  synthetic MixinApp.ctor(dynamic t, List<dynamic> l) = Base<T>.ctor;
}
''');
  }

  test_class_alias_with_forwarding_constructors_type_substitution_complex() async {
    var library = await checkLibrary('''
class Base<T> {
  Base.ctor(T t, List<T> l);
}
class M {}
class MixinApp<U> = Base<List<U>> with M;
''');
    checkElementText(library, r'''
class Base<T> {
  Base.ctor(T t, List<T> l);
}
class M {
}
class alias MixinApp<U> extends Base<List<U>> with M {
  synthetic MixinApp.ctor(List<U> t, List<List<U>> l) = Base<T>.ctor;
}
''');
  }

  test_class_alias_with_mixin_members() async {
    var library = await checkLibrary('''
class C = D with E;
class D {}
class E {
  int get a => null;
  void set b(int i) {}
  void f() {}
  int x;
}''');
    checkElementText(library, r'''
class alias C extends D with E {
  synthetic C() = D;
}
class D {
}
class E {
  int x;
  int get a {}
  void set b(int i) {}
  void f() {}
}
''');
  }

  test_class_constructor_const() async {
    var library = await checkLibrary('class C { const C(); }');
    checkElementText(library, r'''
class C {
  const C();
}
''');
  }

  test_class_constructor_const_external() async {
    var library = await checkLibrary('class C { external const C(); }');
    checkElementText(library, r'''
class C {
  external const C();
}
''');
  }

  test_class_constructor_explicit_named() async {
    var library = await checkLibrary('class C { C.foo(); }');
    checkElementText(library, r'''
class C {
  C.foo();
}
''');
  }

  test_class_constructor_explicit_type_params() async {
    var library = await checkLibrary('class C<T, U> { C(); }');
    checkElementText(library, r'''
class C<T, U> {
  C();
}
''');
  }

  test_class_constructor_explicit_unnamed() async {
    var library = await checkLibrary('class C { C(); }');
    checkElementText(library, r'''
class C {
  C();
}
''');
  }

  test_class_constructor_external() async {
    var library = await checkLibrary('class C { external C(); }');
    checkElementText(library, r'''
class C {
  external C();
}
''');
  }

  test_class_constructor_factory() async {
    var library = await checkLibrary('class C { factory C() => null; }');
    checkElementText(library, r'''
class C {
  factory C();
}
''');
  }

  test_class_constructor_field_formal_dynamic_dynamic() async {
    var library =
        await checkLibrary('class C { dynamic x; C(dynamic this.x); }');
    checkElementText(library, r'''
class C {
  dynamic x;
  C(dynamic this.x);
}
''');
  }

  test_class_constructor_field_formal_dynamic_typed() async {
    var library = await checkLibrary('class C { dynamic x; C(int this.x); }');
    checkElementText(library, r'''
class C {
  dynamic x;
  C(int this.x);
}
''');
  }

  test_class_constructor_field_formal_dynamic_untyped() async {
    var library = await checkLibrary('class C { dynamic x; C(this.x); }');
    checkElementText(library, r'''
class C {
  dynamic x;
  C(dynamic this.x);
}
''');
  }

  test_class_constructor_field_formal_multiple_matching_fields() async {
    // This is a compile-time error but it should still analyze consistently.
    var library = await checkLibrary('class C { C(this.x); int x; String x; }',
        allowErrors: true);
    checkElementText(library, r'''
class C {
  int x;
  String x;
  C(int this.x);
}
''');
  }

  test_class_constructor_field_formal_no_matching_field() async {
    // This is a compile-time error but it should still analyze consistently.
    var library =
        await checkLibrary('class C { C(this.x); }', allowErrors: true);
    checkElementText(library, r'''
class C {
  C(dynamic this.x);
}
''');
  }

  test_class_constructor_field_formal_typed_dynamic() async {
    var library = await checkLibrary('class C { num x; C(dynamic this.x); }',
        allowErrors: true);
    checkElementText(library, r'''
class C {
  num x;
  C(dynamic this.x);
}
''');
  }

  test_class_constructor_field_formal_typed_typed() async {
    var library = await checkLibrary('class C { num x; C(int this.x); }');
    checkElementText(library, r'''
class C {
  num x;
  C(int this.x);
}
''');
  }

  test_class_constructor_field_formal_typed_untyped() async {
    var library = await checkLibrary('class C { num x; C(this.x); }');
    checkElementText(library, r'''
class C {
  num x;
  C(num this.x);
}
''');
  }

  test_class_constructor_field_formal_untyped_dynamic() async {
    var library = await checkLibrary('class C { var x; C(dynamic this.x); }');
    checkElementText(library, r'''
class C {
  dynamic x;
  C(dynamic this.x);
}
''');
  }

  test_class_constructor_field_formal_untyped_typed() async {
    var library = await checkLibrary('class C { var x; C(int this.x); }');
    checkElementText(library, r'''
class C {
  dynamic x;
  C(int this.x);
}
''');
  }

  test_class_constructor_field_formal_untyped_untyped() async {
    var library = await checkLibrary('class C { var x; C(this.x); }');
    checkElementText(library, r'''
class C {
  dynamic x;
  C(dynamic this.x);
}
''');
  }

  test_class_constructor_fieldFormal_named_noDefault() async {
    var library = await checkLibrary('class C { int x; C({this.x}); }');
    checkElementText(library, r'''
class C {
  int x;
  C({int this.x});
}
''');
  }

  test_class_constructor_fieldFormal_named_withDefault() async {
    var library = await checkLibrary('class C { int x; C({this.x: 42}); }');
    checkElementText(library, r'''
class C {
  int x;
  C({int this.x: 42});
}
''');
  }

  test_class_constructor_fieldFormal_optional_noDefault() async {
    var library = await checkLibrary('class C { int x; C([this.x]); }');
    checkElementText(library, r'''
class C {
  int x;
  C([int this.x]);
}
''');
  }

  test_class_constructor_fieldFormal_optional_withDefault() async {
    var library = await checkLibrary('class C { int x; C([this.x = 42]); }');
    checkElementText(library, r'''
class C {
  int x;
  C([int this.x = 42]);
}
''');
  }

  test_class_constructor_implicit() async {
    var library = await checkLibrary('class C {}');
    checkElementText(library, r'''
class C {
}
''');
  }

  test_class_constructor_implicit_type_params() async {
    var library = await checkLibrary('class C<T, U> {}');
    checkElementText(library, r'''
class C<T, U> {
}
''');
  }

  test_class_constructor_params() async {
    var library = await checkLibrary('class C { C(x, int y); }');
    checkElementText(library, r'''
class C {
  C(dynamic x, int y);
}
''');
  }

  test_class_constructors() async {
    var library = await checkLibrary('class C { C.foo(); C.bar(); }');
    checkElementText(library, r'''
class C {
  C.foo();
  C.bar();
}
''');
  }

  test_class_documented() async {
    var library = await checkLibrary('''
/**
 * Docs
 */
class C {}''');
    checkElementText(library, r'''
/**
 * Docs
 */
class C {
}
''');
  }

  test_class_documented_mix() async {
    var library = await checkLibrary('''
/**
 * aaa
 */
/**
 * bbb
 */
class A {}

/**
 * aaa
 */
/// bbb
/// ccc
class B {}

/// aaa
/// bbb
/**
 * ccc
 */
class C {}

/// aaa
/// bbb
/**
 * ccc
 */
/// ddd
class D {}

/**
 * aaa
 */
// bbb
class E {}
''');
    checkElementText(library, r'''
/**
 * bbb
 */
class A {
}
/// bbb
/// ccc
class B {
}
/**
 * ccc
 */
class C {
}
/// ddd
class D {
}
/**
 * aaa
 */
class E {
}
''');
  }

  test_class_documented_tripleSlash() async {
    var library = await checkLibrary('''
/// aaa
/// bbbb
/// cc
class C {}''');
    checkElementText(library, r'''
/// aaa
/// bbbb
/// cc
class C {
}
''');
  }

  test_class_documented_with_references() async {
    var library = await checkLibrary('''
/**
 * Docs referring to [D] and [E]
 */
class C {}

class D {}
class E {}''');
    checkElementText(library, r'''
/**
 * Docs referring to [D] and [E]
 */
class C {
}
class D {
}
class E {
}
''');
  }

  test_class_documented_with_windows_line_endings() async {
    var library = await checkLibrary('/**\r\n * Docs\r\n */\r\nclass C {}');
    checkElementText(library, r'''
/**
 * Docs
 */
class C {
}
''');
  }

  test_class_documented_withLeadingNotDocumentation() async {
    var library = await checkLibrary('''
// Extra comment so doc comment offset != 0
/**
 * Docs
 */
class C {}''');
    checkElementText(library, r'''
/**
 * Docs
 */
class C {
}
''');
  }

  test_class_field_const() async {
    var library = await checkLibrary('class C { static const int i = 0; }');
    checkElementText(library, r'''
class C {
  static const int i = 0;
}
''');
  }

  test_class_field_implicit_type() async {
    var library = await checkLibrary('class C { var x; }');
    checkElementText(library, r'''
class C {
  dynamic x;
}
''');
  }

  test_class_field_static() async {
    var library = await checkLibrary('class C { static int i; }');
    checkElementText(library, r'''
class C {
  static int i;
}
''');
  }

  test_class_fields() async {
    var library = await checkLibrary('class C { int i; int j; }');
    checkElementText(library, r'''
class C {
  int i;
  int j;
}
''');
  }

  test_class_getter_abstract() async {
    var library = await checkLibrary('abstract class C { int get x; }');
    checkElementText(library, r'''
abstract class C {
  int get x;
}
''');
  }

  test_class_getter_external() async {
    var library = await checkLibrary('class C { external int get x; }');
    checkElementText(library, r'''
class C {
  external int get x;
}
''');
  }

  test_class_getter_implicit_return_type() async {
    var library = await checkLibrary('class C { get x => null; }');
    checkElementText(library, r'''
class C {
  dynamic get x {}
}
''');
  }

  test_class_getter_static() async {
    var library = await checkLibrary('class C { static int get x => null; }');
    checkElementText(library, r'''
class C {
  static int get x {}
}
''');
  }

  test_class_getters() async {
    var library =
        await checkLibrary('class C { int get x => null; get y => null; }');
    checkElementText(library, r'''
class C {
  int get x {}
  dynamic get y {}
}
''');
  }

  test_class_implicitField_getterFirst() async {
    var library = await checkLibrary('''
class C {
  int get x => 0;
  void set x(int value) {} 
}
''');
    checkElementText(library, r'''
class C {
  int get x {}
  void set x(int value) {}
}
''');
  }

  test_class_implicitField_setterFirst() async {
    var library = await checkLibrary('''
class C {
  void set x(int value) {}
  int get x => 0;
}
''');
    checkElementText(library, r'''
class C {
  void set x(int value) {}
  int get x {}
}
''');
  }

  test_class_interfaces() async {
    var library = await checkLibrary('''
class C implements D, E {}
class D {}
class E {}
''');
    checkElementText(library, r'''
class C implements D, E {
}
class D {
}
class E {
}
''');
  }

  test_class_interfaces_unresolved() async {
    var library = await checkLibrary(
        'class C implements X, Y, Z {} class X {} class Z {}',
        allowErrors: true);
    checkElementText(library, r'''
class C implements X, Z {
}
class X {
}
class Z {
}
''');
  }

  test_class_method_abstract() async {
    var library = await checkLibrary('abstract class C { f(); }');
    checkElementText(library, r'''
abstract class C {
  dynamic f();
}
''');
  }

  test_class_method_external() async {
    var library = await checkLibrary('class C { external f(); }');
    checkElementText(library, r'''
class C {
  external dynamic f() {}
}
''');
  }

  test_class_method_params() async {
    var library = await checkLibrary('class C { f(x, y) {} }');
    checkElementText(library, r'''
class C {
  dynamic f(dynamic x, dynamic y) {}
}
''');
  }

  test_class_method_static() async {
    var library = await checkLibrary('class C { static f() {} }');
    checkElementText(library, r'''
class C {
  static dynamic f() {}
}
''');
  }

  test_class_methods() async {
    var library = await checkLibrary('class C { f() {} g() {} }');
    checkElementText(library, r'''
class C {
  dynamic f() {}
  dynamic g() {}
}
''');
  }

  test_class_mixins() async {
    var library = await checkLibrary('''
class C extends D with E, F, G {}
class D {}
class E {}
class F {}
class G {}
''');
    checkElementText(library, r'''
class C extends D with E, F, G {
  synthetic C();
}
class D {
}
class E {
}
class F {
}
class G {
}
''');
  }

  test_class_mixins_generic() async {
    var library = await checkLibrary('''
class Z extends A with B<int>, C<double> {}
class A {}
class B<B1> {}
class C<C1> {}
''');
    checkElementText(library, r'''
class Z extends A with B<int>, C<double> {
  synthetic Z();
}
class A {
}
class B<B1> {
}
class C<C1> {
}
''');
  }

  test_class_mixins_unresolved() async {
    var library = await checkLibrary(
        'class C extends Object with X, Y, Z {} class X {} class Z {}',
        allowErrors: true);
    checkElementText(library, r'''
class C extends Object with X, Z {
  synthetic C();
}
class X {
}
class Z {
}
''');
  }

  test_class_setter_abstract() async {
    var library =
        await checkLibrary('abstract class C { void set x(int value); }');
    checkElementText(library, r'''
abstract class C {
  void set x(int value);
}
''');
  }

  test_class_setter_external() async {
    var library =
        await checkLibrary('class C { external void set x(int value); }');
    checkElementText(library, r'''
class C {
  external void set x(int value);
}
''');
  }

  test_class_setter_implicit_param_type() async {
    var library = await checkLibrary('class C { void set x(value) {} }');
    checkElementText(library, r'''
class C {
  void set x(dynamic value) {}
}
''');
  }

  test_class_setter_implicit_return_type() async {
    var library = await checkLibrary('class C { set x(int value) {} }');
    if (isStrongMode) {
      checkElementText(library, r'''
class C {
  void set x(int value) {}
}
''');
    } else {
      checkElementText(library, r'''
class C {
  dynamic set x(int value) {}
}
''');
    }
  }

  test_class_setter_invalid_named_parameter() async {
    var library = await checkLibrary('class C { void set x({a}) {} }');
    checkElementText(library, r'''
class C {
  void set x({dynamic a}) {}
}
''');
  }

  test_class_setter_invalid_no_parameter() async {
    var library = await checkLibrary('class C { void set x() {} }');
    checkElementText(library, r'''
class C {
  void set x() {}
}
''');
  }

  test_class_setter_invalid_optional_parameter() async {
    var library = await checkLibrary('class C { void set x([a]) {} }');
    checkElementText(library, r'''
class C {
  void set x([dynamic a]) {}
}
''');
  }

  test_class_setter_invalid_too_many_parameters() async {
    var library = await checkLibrary('class C { void set x(a, b) {} }');
    checkElementText(library, r'''
class C {
  void set x(dynamic a, dynamic b) {}
}
''');
  }

  test_class_setter_static() async {
    var library =
        await checkLibrary('class C { static void set x(int value) {} }');
    checkElementText(library, r'''
class C {
  static void set x(int value) {}
}
''');
  }

  test_class_setters() async {
    var library = await checkLibrary('''
class C {
  void set x(int value) {}
  set y(value) {}
}
''');
    if (isStrongMode) {
      checkElementText(library, r'''
class C {
  void set x(int value) {}
  void set y(dynamic value) {}
}
''');
    } else {
      checkElementText(library, r'''
class C {
  void set x(int value) {}
  dynamic set y(dynamic value) {}
}
''');
    }
  }

  test_class_supertype() async {
    var library = await checkLibrary('''
class C extends D {}
class D {}
''');
    checkElementText(library, r'''
class C extends D {
}
class D {
}
''');
  }

  test_class_supertype_typeArguments() async {
    var library = await checkLibrary('''
class C extends D<int, double> {}
class D<T1, T2> {}
''');
    checkElementText(library, r'''
class C extends D<int, double> {
}
class D<T1, T2> {
}
''');
  }

  test_class_supertype_unresolved() async {
    var library = await checkLibrary('class C extends D {}', allowErrors: true);
    checkElementText(library, r'''
class C {
}
''');
  }

  test_class_type_parameters() async {
    var library = await checkLibrary('class C<T, U> {}');
    checkElementText(library, r'''
class C<T, U> {
}
''');
  }

  test_class_type_parameters_bound() async {
    var library = await checkLibrary('''
class C<T extends Object, U extends D> {}
class D {}
''');
    checkElementText(library, r'''
class C<T extends Object, U extends D> {
}
class D {
}
''');
  }

  test_class_type_parameters_f_bound_complex() async {
    var library = await checkLibrary('class C<T extends List<U>, U> {}');
    checkElementText(library, r'''
class C<T extends List<U>, U> {
}
''');
  }

  test_class_type_parameters_f_bound_simple() async {
    var library = await checkLibrary('class C<T extends U, U> {}');
    checkElementText(library, r'''
class C<T extends U, U> {
}
''');
  }

  test_classes() async {
    var library = await checkLibrary('class C {} class D {}');
    checkElementText(library, r'''
class C {
}
class D {
}
''');
  }

  test_closure_executable_with_return_type_from_closure() async {
    var library = await checkLibrary('''
f() {
  print(() {});
  print(() => () => 0);
}
''');
    checkElementText(library, r'''
dynamic f() {}
''');
  }

  test_closure_generic() async {
    var library = await checkLibrary(r'''
final f = <U, V>(U x, V y) => y;
''');
    if (isStrongMode) {
      checkElementText(library, r'''
final <U,V>(U, V) → V f;
''');
    } else {
      checkElementText(library, r'''
final dynamic f;
''');
    }
  }

  test_closure_in_variable_declaration_in_part() async {
    addSource('/a.dart', 'part of lib; final f = (int i) => i.toDouble();');
    var library = await checkLibrary('''
library lib;
part "a.dart";
''');
    if (isStrongMode) {
      checkElementText(library, r'''
library lib;
part 'a.dart';
--------------------
unit: a.dart

final (int) → double f;
''');
    } else {
      checkElementText(library, r'''
library lib;
part 'a.dart';
--------------------
unit: a.dart

final dynamic f;
''');
    }
  }

  test_const_constructor_inferred_args() async {
    if (!isStrongMode) return;
    var library = await checkLibrary('''
class C<T> {
  final T t;
  const C(this.t);
  const C.named(this.t);
}
const Object x = const C(0);
const Object y = const C.named(0);
''');
    checkElementText(library, '''
class C<T> {
  final T t;
  const C(T this.t);
  const C.named(T this.t);
}
const Object x = const
        C/*location: test.dart;C*/(0);
const Object y = const
        C/*location: test.dart;C*/.
        named/*location: test.dart;C;named*/(0);
''');
    TopLevelVariableElementImpl x =
        library.definingCompilationUnit.topLevelVariables[0];
    InstanceCreationExpression xExpr = x.constantInitializer;
    var xType = xExpr.constructorName.staticElement.returnType;
    expect(xType.toString(), 'C<int>');
    TopLevelVariableElementImpl y =
        library.definingCompilationUnit.topLevelVariables[0];
    InstanceCreationExpression yExpr = y.constantInitializer;
    var yType = yExpr.constructorName.staticElement.returnType;
    expect(yType.toString(), 'C<int>');
  }

  test_const_finalField_hasConstConstructor() async {
    var library = await checkLibrary(r'''
class C {
  final int f = 42;
  const C();
}
''');
    checkElementText(library, r'''
class C {
  final int f = 42;
  const C();
}
''');
  }

  test_const_invalid_field_const() async {
    shouldCompareLibraryElements = false;
    var library = await checkLibrary(r'''
class C {
  static const f = 1 + foo();
}
int foo() => 42;
''', allowErrors: true);
    if (isSharedFrontEnd) {
      // It is OK to keep non-constant initializers.
      checkElementText(library, r'''
class C {
  static const int f = 1 +
        foo/*location: test.dart;foo*/();
}
int foo() {}
''');
    } else if (isStrongMode) {
      checkElementText(library, r'''
class C {
  static const int f = 1 +
        foo/*location: test.dart;foo*/();
}
int foo() {}
''');
    } else {
      checkElementText(library, r'''
class C {
  static const dynamic f = 1 +
        foo/*location: test.dart;foo*/();
}
int foo() {}
''');
    }
  }

  test_const_invalid_field_final() async {
    variablesWithNotConstInitializers.add('f');
    var library = await checkLibrary(r'''
class C {
  final f = 1 + foo();
}
int foo() => 42;
''', allowErrors: true);
    if (isStrongMode) {
      checkElementText(library, r'''
class C {
  final int f;
}
int foo() {}
''');
    } else {
      checkElementText(library, r'''
class C {
  final dynamic f;
}
int foo() {}
''');
    }
  }

  test_const_invalid_intLiteral() async {
    var library = await checkLibrary(r'''
const int x = 0x;
''', allowErrors: true);
    checkElementText(library, r'''
const int x = 0;
''');
  }

  test_const_invalid_topLevel() async {
    shouldCompareLibraryElements = false;
    var library = await checkLibrary(r'''
const v = 1 + foo();
int foo() => 42;
''', allowErrors: true);
    if (isSharedFrontEnd) {
      // It is OK to keep non-constant initializers.
      checkElementText(library, r'''
const int v = 1 +
        foo/*location: test.dart;foo*/();
int foo() {}
''');
    } else if (isStrongMode) {
      checkElementText(library, r'''
const int v = 1 +
        foo/*location: test.dart;foo*/();
int foo() {}
''');
    } else {
      checkElementText(library, r'''
const dynamic v = 1 +
        foo/*location: test.dart;foo*/();
int foo() {}
''');
    }
  }

  test_const_invokeConstructor_generic_named() async {
    var library = await checkLibrary(r'''
class C<K, V> {
  const C.named(K k, V v);
}
const V = const C<int, String>.named(1, '222');
''');
    if (isStrongMode) {
      checkElementText(library, r'''
class C<K, V> {
  const C.named(K k, V v);
}
const C<int, String> V = const
        C/*location: test.dart;C*/<
        int/*location: dart:core;int*/,
        String/*location: dart:core;String*/>.
        named/*location: test.dart;C;named*/(1, '222');
''');
    } else {
      checkElementText(library, r'''
class C<K, V> {
  const C.named(K k, V v);
}
const dynamic V = const
        C/*location: test.dart;C*/<
        int/*location: dart:core;int*/,
        String/*location: dart:core;String*/>.
        named/*location: test.dart;C;named*/(1, '222');
''');
    }
  }

  test_const_invokeConstructor_generic_named_imported() async {
    addLibrarySource('/a.dart', r'''
class C<K, V> {
  const C.named(K k, V v);
}
''');
    var library = await checkLibrary(r'''
import 'a.dart';
const V = const C<int, String>.named(1, '222');
''');
    if (isStrongMode) {
      checkElementText(library, r'''
import 'a.dart';
const C<int, String> V = const
        C/*location: a.dart;C*/<
        int/*location: dart:core;int*/,
        String/*location: dart:core;String*/>.
        named/*location: a.dart;C;named*/(1, '222');
''');
    } else {
      checkElementText(library, r'''
import 'a.dart';
const dynamic V = const
        C/*location: a.dart;C*/<
        int/*location: dart:core;int*/,
        String/*location: dart:core;String*/>.
        named/*location: a.dart;C;named*/(1, '222');
''');
    }
  }

  test_const_invokeConstructor_generic_named_imported_withPrefix() async {
    addLibrarySource('/a.dart', r'''
class C<K, V> {
  const C.named(K k, V v);
}
''');
    var library = await checkLibrary(r'''
import 'a.dart' as p;
const V = const p.C<int, String>.named(1, '222');
''');
    if (isStrongMode) {
      checkElementText(library, r'''
import 'a.dart' as p;
const C<int, String> V = const
        C/*location: a.dart;C*/<
        int/*location: dart:core;int*/,
        String/*location: dart:core;String*/>.
        named/*location: a.dart;C;named*/(1, '222');
''');
    } else {
      checkElementText(library, r'''
import 'a.dart' as p;
const dynamic V = const
        C/*location: a.dart;C*/<
        int/*location: dart:core;int*/,
        String/*location: dart:core;String*/>.
        named/*location: a.dart;C;named*/(1, '222');
''');
    }
  }

  test_const_invokeConstructor_generic_noTypeArguments() async {
    var library = await checkLibrary(r'''
class C<K, V> {
  const C();
}
const V = const C();
''');
    if (isStrongMode) {
      checkElementText(library, r'''
class C<K, V> {
  const C();
}
const C<dynamic, dynamic> V = const
        C/*location: test.dart;C*/();
''');
    } else {
      checkElementText(library, r'''
class C<K, V> {
  const C();
}
const dynamic V = const
        C/*location: test.dart;C*/();
''');
    }
  }

  test_const_invokeConstructor_generic_unnamed() async {
    var library = await checkLibrary(r'''
class C<K, V> {
  const C();
}
const V = const C<int, String>();
''');
    if (isStrongMode) {
      checkElementText(library, r'''
class C<K, V> {
  const C();
}
const C<int, String> V = const
        C/*location: test.dart;C*/<
        int/*location: dart:core;int*/,
        String/*location: dart:core;String*/>();
''');
    } else {
      checkElementText(library, r'''
class C<K, V> {
  const C();
}
const dynamic V = const
        C/*location: test.dart;C*/<
        int/*location: dart:core;int*/,
        String/*location: dart:core;String*/>();
''');
    }
  }

  test_const_invokeConstructor_generic_unnamed_imported() async {
    addLibrarySource('/a.dart', r'''
class C<K, V> {
  const C();
}
''');
    var library = await checkLibrary(r'''
import 'a.dart';
const V = const C<int, String>();
''');
    if (isStrongMode) {
      checkElementText(library, r'''
import 'a.dart';
const C<int, String> V = const
        C/*location: a.dart;C*/<
        int/*location: dart:core;int*/,
        String/*location: dart:core;String*/>();
''');
    } else {
      checkElementText(library, r'''
import 'a.dart';
const dynamic V = const
        C/*location: a.dart;C*/<
        int/*location: dart:core;int*/,
        String/*location: dart:core;String*/>();
''');
    }
  }

  test_const_invokeConstructor_generic_unnamed_imported_withPrefix() async {
    addLibrarySource('/a.dart', r'''
class C<K, V> {
  const C();
}
''');
    var library = await checkLibrary(r'''
import 'a.dart' as p;
const V = const p.C<int, String>();
''');
    if (isStrongMode) {
      checkElementText(library, r'''
import 'a.dart' as p;
const C<int, String> V = const
        C/*location: a.dart;C*/<
        int/*location: dart:core;int*/,
        String/*location: dart:core;String*/>();
''');
    } else {
      checkElementText(library, r'''
import 'a.dart' as p;
const dynamic V = const
        C/*location: a.dart;C*/<
        int/*location: dart:core;int*/,
        String/*location: dart:core;String*/>();
''');
    }
  }

  test_const_invokeConstructor_named() async {
    var library = await checkLibrary(r'''
class C {
  const C.named(bool a, int b, int c, {String d, double e});
}
const V = const C.named(true, 1, 2, d: 'ccc', e: 3.4);
''');
    if (isStrongMode) {
      checkElementText(library, r'''
class C {
  const C.named(bool a, int b, int c, {String d}, {double e});
}
const C V = const
        C/*location: test.dart;C*/.
        named/*location: test.dart;C;named*/(true, 1, 2,
        d/*location: null*/: 'ccc',
        e/*location: null*/: 3.4);
''');
    } else {
      checkElementText(library, r'''
class C {
  const C.named(bool a, int b, int c, {String d}, {double e});
}
const dynamic V = const
        C/*location: test.dart;C*/.
        named/*location: test.dart;C;named*/(true, 1, 2,
        d/*location: null*/: 'ccc',
        e/*location: null*/: 3.4);
''');
    }
  }

  test_const_invokeConstructor_named_imported() async {
    addLibrarySource('/a.dart', r'''
class C {
  const C.named();
}
''');
    var library = await checkLibrary(r'''
import 'a.dart';
const V = const C.named();
''');
    if (isStrongMode) {
      checkElementText(library, r'''
import 'a.dart';
const C V = const
        C/*location: a.dart;C*/.
        named/*location: a.dart;C;named*/();
''');
    } else {
      checkElementText(library, r'''
import 'a.dart';
const dynamic V = const
        C/*location: a.dart;C*/.
        named/*location: a.dart;C;named*/();
''');
    }
  }

  test_const_invokeConstructor_named_imported_withPrefix() async {
    addLibrarySource('/a.dart', r'''
class C {
  const C.named();
}
''');
    var library = await checkLibrary(r'''
import 'a.dart' as p;
const V = const p.C.named();
''');
    if (isStrongMode) {
      checkElementText(library, r'''
import 'a.dart' as p;
const C V = const
        C/*location: a.dart;C*/.
        named/*location: a.dart;C;named*/();
''');
    } else {
      checkElementText(library, r'''
import 'a.dart' as p;
const dynamic V = const
        C/*location: a.dart;C*/.
        named/*location: a.dart;C;named*/();
''');
    }
  }

  test_const_invokeConstructor_named_unresolved() async {
    shouldCompareLibraryElements = false;
    var library = await checkLibrary(r'''
class C {}
const V = const C.named();
''', allowErrors: true);
    checkElementText(library, r'''
class C {
}
const dynamic V = #invalidConst;
''');
  }

  test_const_invokeConstructor_named_unresolved2() async {
    shouldCompareLibraryElements = false;
    var library = await checkLibrary(r'''
const V = const C.named();
''', allowErrors: true);
    checkElementText(library, r'''
const dynamic V = #invalidConst;
''');
  }

  test_const_invokeConstructor_named_unresolved3() async {
    shouldCompareLibraryElements = false;
    addLibrarySource('/a.dart', r'''
class C {
}
''');
    var library = await checkLibrary(r'''
import 'a.dart' as p;
const V = const p.C.named();
''', allowErrors: true);
    checkElementText(library, r'''
import 'a.dart' as p;
const dynamic V = #invalidConst;
''');
  }

  test_const_invokeConstructor_named_unresolved4() async {
    shouldCompareLibraryElements = false;
    addLibrarySource('/a.dart', '');
    var library = await checkLibrary(r'''
import 'a.dart' as p;
const V = const p.C.named();
''', allowErrors: true);
    checkElementText(library, r'''
import 'a.dart' as p;
const dynamic V = #invalidConst;
''');
  }

  test_const_invokeConstructor_named_unresolved5() async {
    shouldCompareLibraryElements = false;
    var library = await checkLibrary(r'''
const V = const p.C.named();
''', allowErrors: true);
    checkElementText(library, r'''
const dynamic V = #invalidConst;
''');
  }

  test_const_invokeConstructor_named_unresolved6() async {
    shouldCompareLibraryElements = false;
    var library = await checkLibrary(r'''
class C<T> {}
const V = const C.named();
''', allowErrors: true);
    checkElementText(library, r'''
class C<T> {
}
const dynamic V = #invalidConst;
''');
  }

  test_const_invokeConstructor_unnamed() async {
    var library = await checkLibrary(r'''
class C {
  const C();
}
const V = const C();
''');
    if (isStrongMode) {
      checkElementText(library, r'''
class C {
  const C();
}
const C V = const
        C/*location: test.dart;C*/();
''');
    } else {
      checkElementText(library, r'''
class C {
  const C();
}
const dynamic V = const
        C/*location: test.dart;C*/();
''');
    }
  }

  test_const_invokeConstructor_unnamed_imported() async {
    addLibrarySource('/a.dart', r'''
class C {
  const C();
}
''');
    var library = await checkLibrary(r'''
import 'a.dart';
const V = const C();
''');
    if (isStrongMode) {
      checkElementText(library, r'''
import 'a.dart';
const C V = const
        C/*location: a.dart;C*/();
''');
    } else {
      checkElementText(library, r'''
import 'a.dart';
const dynamic V = const
        C/*location: a.dart;C*/();
''');
    }
  }

  test_const_invokeConstructor_unnamed_imported_withPrefix() async {
    addLibrarySource('/a.dart', r'''
class C {
  const C();
}
''');
    var library = await checkLibrary(r'''
import 'a.dart' as p;
const V = const p.C();
''');
    if (isStrongMode) {
      checkElementText(library, r'''
import 'a.dart' as p;
const C V = const
        C/*location: a.dart;C*/();
''');
    } else {
      checkElementText(library, r'''
import 'a.dart' as p;
const dynamic V = const
        C/*location: a.dart;C*/();
''');
    }
  }

  test_const_invokeConstructor_unnamed_unresolved() async {
    shouldCompareLibraryElements = false;
    var library = await checkLibrary(r'''
const V = const C();
''', allowErrors: true);
    checkElementText(library, r'''
const dynamic V = #invalidConst;
''');
  }

  test_const_invokeConstructor_unnamed_unresolved2() async {
    shouldCompareLibraryElements = false;
    addLibrarySource('/a.dart', '');
    var library = await checkLibrary(r'''
import 'a.dart' as p;
const V = const p.C();
''', allowErrors: true);
    checkElementText(library, r'''
import 'a.dart' as p;
const dynamic V = #invalidConst;
''');
  }

  test_const_invokeConstructor_unnamed_unresolved3() async {
    shouldCompareLibraryElements = false;
    var library = await checkLibrary(r'''
const V = const p.C();
''', allowErrors: true);
    checkElementText(library, r'''
const dynamic V = #invalidConst;
''');
  }

  test_const_length_ofClassConstField() async {
    var library = await checkLibrary(r'''
class C {
  static const String F = '';
}
const int v = C.F.length;
''');
    checkElementText(library, r'''
class C {
  static const String F = '';
}
const int v =
        C/*location: test.dart;C*/.
        F/*location: test.dart;C;F?*/.
        length/*location: dart:core;String;length?*/;
''');
  }

  test_const_length_ofClassConstField_imported() async {
    addLibrarySource('/a.dart', r'''
class C {
  static const String F = '';
}
''');
    var library = await checkLibrary(r'''
import 'a.dart';
const int v = C.F.length;
''');
    checkElementText(library, r'''
import 'a.dart';
const int v =
        C/*location: a.dart;C*/.
        F/*location: a.dart;C;F?*/.
        length/*location: dart:core;String;length?*/;
''');
  }

  test_const_length_ofClassConstField_imported_withPrefix() async {
    addLibrarySource('/a.dart', r'''
class C {
  static const String F = '';
}
''');
    var library = await checkLibrary(r'''
import 'a.dart' as p;
const int v = p.C.F.length;
''');
    if (isSharedFrontEnd) {
      checkElementText(library, r'''
import 'a.dart' as p;
const int v =
        C/*location: a.dart;C*/.
        F/*location: a.dart;C;F?*/.
        length/*location: dart:core;String;length?*/;
''');
    } else {
      checkElementText(library, r'''
import 'a.dart' as p;
const int v =
        p/*location: test.dart;p*/.
        C/*location: a.dart;C*/.
        F/*location: a.dart;C;F?*/.
        length/*location: dart:core;String;length?*/;
''');
    }
  }

  test_const_length_ofStringLiteral() async {
    var library = await checkLibrary(r'''
const v = 'abc'.length;
''');
    if (isStrongMode) {
      checkElementText(library, r'''
const int v = 'abc'.
        length/*location: dart:core;String;length?*/;
''');
    } else {
      checkElementText(library, r'''
const dynamic v = 'abc'.
        length/*location: dart:core;String;length?*/;
''');
    }
  }

  test_const_length_ofTopLevelVariable() async {
    var library = await checkLibrary(r'''
const String S = 'abc';
const v = S.length;
''');
    if (isStrongMode) {
      checkElementText(library, r'''
const String S = 'abc';
const int v =
        S/*location: test.dart;S?*/.
        length/*location: dart:core;String;length?*/;
''');
    } else {
      checkElementText(library, r'''
const String S = 'abc';
const dynamic v =
        S/*location: test.dart;S?*/.
        length/*location: dart:core;String;length?*/;
''');
    }
  }

  test_const_length_ofTopLevelVariable_imported() async {
    addLibrarySource('/a.dart', r'''
const String S = 'abc';
''');
    var library = await checkLibrary(r'''
import 'a.dart';
const v = S.length;
''');
    if (isStrongMode) {
      checkElementText(library, r'''
import 'a.dart';
const int v =
        S/*location: a.dart;S?*/.
        length/*location: dart:core;String;length?*/;
''');
    } else {
      checkElementText(library, r'''
import 'a.dart';
const dynamic v =
        S/*location: a.dart;S?*/.
        length/*location: dart:core;String;length?*/;
''');
    }
  }

  test_const_length_ofTopLevelVariable_imported_withPrefix() async {
    addLibrarySource('/a.dart', r'''
const String S = 'abc';
''');
    var library = await checkLibrary(r'''
import 'a.dart' as p;
const v = p.S.length;
''');
    if (isStrongMode) {
      if (isSharedFrontEnd) {
        checkElementText(library, r'''
import 'a.dart' as p;
const int v =
        S/*location: a.dart;S?*/.
        length/*location: dart:core;String;length?*/;
''');
      } else {
        checkElementText(library, r'''
import 'a.dart' as p;
const int v =
        p/*location: test.dart;p*/.
        S/*location: a.dart;S?*/.
        length/*location: dart:core;String;length?*/;
''');
      }
    } else {
      checkElementText(library, r'''
import 'a.dart' as p;
const dynamic v =
        p/*location: test.dart;p*/.
        S/*location: a.dart;S?*/.
        length/*location: dart:core;String;length?*/;
''');
    }
  }

  test_const_length_staticMethod() async {
    var library = await checkLibrary(r'''
class C {
  static int length() => 42;
}
const v = C.length;
''');
    if (isStrongMode) {
      checkElementText(library, r'''
class C {
  static int length() {}
}
const () → int v =
        C/*location: test.dart;C*/.
        length/*location: test.dart;C;length*/;
''');
    } else {
      checkElementText(library, r'''
class C {
  static int length() {}
}
const dynamic v =
        C/*location: test.dart;C*/.
        length/*location: test.dart;C;length*/;
''');
    }
  }

  test_const_parameterDefaultValue_initializingFormal_functionTyped() async {
    var library = await checkLibrary(r'''
class C {
  final x;
  const C({this.x: foo});
}
int foo() => 42;
''');
    checkElementText(library, r'''
class C {
  final dynamic x;
  const C({dynamic this.x:
        foo/*location: test.dart;foo*/});
}
int foo() {}
''');
  }

  test_const_parameterDefaultValue_initializingFormal_named() async {
    var library = await checkLibrary(r'''
class C {
  final x;
  const C({this.x: 1 + 2});
}
''');
    checkElementText(library, r'''
class C {
  final dynamic x;
  const C({dynamic this.x: 1 + 2});
}
''');
  }

  test_const_parameterDefaultValue_initializingFormal_positional() async {
    var library = await checkLibrary(r'''
class C {
  final x;
  const C([this.x = 1 + 2]);
}
''');
    checkElementText(library, r'''
class C {
  final dynamic x;
  const C([dynamic this.x = 1 + 2]);
}
''');
  }

  test_const_parameterDefaultValue_normal() async {
    var library = await checkLibrary(r'''
class C {
  const C.positional([p = 1 + 2]);
  const C.named({p: 1 + 2});
  void methodPositional([p = 1 + 2]) {}
  void methodPositionalWithoutDefault([p]) {}
  void methodNamed({p: 1 + 2}) {}
  void methodNamedWithoutDefault({p}) {}
}
''');
    checkElementText(library, r'''
class C {
  const C.positional([dynamic p = 1 + 2]);
  const C.named({dynamic p: 1 + 2});
  void methodPositional([dynamic p = 1 + 2]) {}
  void methodPositionalWithoutDefault([dynamic p]) {}
  void methodNamed({dynamic p: 1 + 2}) {}
  void methodNamedWithoutDefault({dynamic p}) {}
}
''');
  }

  test_const_reference_staticField() async {
    var library = await checkLibrary(r'''
class C {
  static const int F = 42;
}
const V = C.F;
''');
    if (isStrongMode) {
      checkElementText(library, r'''
class C {
  static const int F = 42;
}
const int V =
        C/*location: test.dart;C*/.
        F/*location: test.dart;C;F?*/;
''');
    } else {
      checkElementText(library, r'''
class C {
  static const int F = 42;
}
const dynamic V =
        C/*location: test.dart;C*/.
        F/*location: test.dart;C;F?*/;
''');
    }
  }

  test_const_reference_staticField_imported() async {
    addLibrarySource('/a.dart', r'''
class C {
  static const int F = 42;
}
''');
    var library = await checkLibrary(r'''
import 'a.dart';
const V = C.F;
''');
    if (isStrongMode) {
      checkElementText(library, r'''
import 'a.dart';
const int V =
        C/*location: a.dart;C*/.
        F/*location: a.dart;C;F?*/;
''');
    } else {
      checkElementText(library, r'''
import 'a.dart';
const dynamic V =
        C/*location: a.dart;C*/.
        F/*location: a.dart;C;F?*/;
''');
    }
  }

  test_const_reference_staticField_imported_withPrefix() async {
    addLibrarySource('/a.dart', r'''
class C {
  static const int F = 42;
}
''');
    var library = await checkLibrary(r'''
import 'a.dart' as p;
const V = p.C.F;
''');
    if (isStrongMode) {
      if (isSharedFrontEnd) {
        checkElementText(library, r'''
import 'a.dart' as p;
const int V =
        C/*location: a.dart;C*/.
        F/*location: a.dart;C;F?*/;
''');
      } else {
        checkElementText(library, r'''
import 'a.dart' as p;
const int V =
        p/*location: test.dart;p*/.
        C/*location: a.dart;C*/.
        F/*location: a.dart;C;F?*/;
''');
      }
    } else {
      checkElementText(library, r'''
import 'a.dart' as p;
const dynamic V =
        p/*location: test.dart;p*/.
        C/*location: a.dart;C*/.
        F/*location: a.dart;C;F?*/;
''');
    }
  }

  test_const_reference_staticMethod() async {
    var library = await checkLibrary(r'''
class C {
  static int m(int a, String b) => 42;
}
const V = C.m;
''');
    if (isStrongMode) {
      checkElementText(library, r'''
class C {
  static int m(int a, String b) {}
}
const (int, String) → int V =
        C/*location: test.dart;C*/.
        m/*location: test.dart;C;m*/;
''');
    } else {
      checkElementText(library, r'''
class C {
  static int m(int a, String b) {}
}
const dynamic V =
        C/*location: test.dart;C*/.
        m/*location: test.dart;C;m*/;
''');
    }
  }

  test_const_reference_staticMethod_imported() async {
    addLibrarySource('/a.dart', r'''
class C {
  static int m(int a, String b) => 42;
}
''');
    var library = await checkLibrary(r'''
import 'a.dart';
const V = C.m;
''');
    if (isStrongMode) {
      checkElementText(library, r'''
import 'a.dart';
const (int, String) → int V =
        C/*location: a.dart;C*/.
        m/*location: a.dart;C;m*/;
''');
    } else {
      checkElementText(library, r'''
import 'a.dart';
const dynamic V =
        C/*location: a.dart;C*/.
        m/*location: a.dart;C;m*/;
''');
    }
  }

  test_const_reference_staticMethod_imported_withPrefix() async {
    addLibrarySource('/a.dart', r'''
class C {
  static int m(int a, String b) => 42;
}
''');
    var library = await checkLibrary(r'''
import 'a.dart' as p;
const V = p.C.m;
''');
    if (isStrongMode) {
      if (isSharedFrontEnd) {
        checkElementText(library, r'''
import 'a.dart' as p;
const (int, String) → int V =
        C/*location: a.dart;C*/.
        m/*location: a.dart;C;m*/;
''');
      } else {
        checkElementText(library, r'''
import 'a.dart' as p;
const (int, String) → int V =
        p/*location: test.dart;p*/.
        C/*location: a.dart;C*/.
        m/*location: a.dart;C;m*/;
''');
      }
    } else {
      checkElementText(library, r'''
import 'a.dart' as p;
const dynamic V =
        p/*location: test.dart;p*/.
        C/*location: a.dart;C*/.
        m/*location: a.dart;C;m*/;
''');
    }
  }

  test_const_reference_topLevelFunction() async {
    var library = await checkLibrary(r'''
foo() {}
const V = foo;
''');
    if (isStrongMode) {
      checkElementText(library, r'''
const () → dynamic V =
        foo/*location: test.dart;foo*/;
dynamic foo() {}
''');
    } else {
      checkElementText(library, r'''
const dynamic V =
        foo/*location: test.dart;foo*/;
dynamic foo() {}
''');
    }
  }

  test_const_reference_topLevelFunction_generic() async {
    var library = await checkLibrary(r'''
R foo<P, R>(P p) {}
const V = foo;
''');
    if (isStrongMode) {
      checkElementText(library, r'''
const <P,R>(P) → R V =
        foo/*location: test.dart;foo*/;
R foo<P, R>(P p) {}
''');
    } else {
      checkElementText(library, r'''
const dynamic V =
        foo/*location: test.dart;foo*/;
R foo<P, R>(P p) {}
''');
    }
  }

  test_const_reference_topLevelFunction_imported() async {
    addLibrarySource('/a.dart', r'''
foo() {}
''');
    var library = await checkLibrary(r'''
import 'a.dart';
const V = foo;
''');
    if (isStrongMode) {
      checkElementText(library, r'''
import 'a.dart';
const () → dynamic V =
        foo/*location: a.dart;foo*/;
''');
    } else {
      checkElementText(library, r'''
import 'a.dart';
const dynamic V =
        foo/*location: a.dart;foo*/;
''');
    }
  }

  test_const_reference_topLevelFunction_imported_withPrefix() async {
    addLibrarySource('/a.dart', r'''
foo() {}
''');
    var library = await checkLibrary(r'''
import 'a.dart' as p;
const V = p.foo;
''');
    if (isStrongMode) {
      if (isSharedFrontEnd) {
        checkElementText(library, r'''
import 'a.dart' as p;
const () → dynamic V =
        foo/*location: a.dart;foo*/;
''');
      } else {
        checkElementText(library, r'''
import 'a.dart' as p;
const () → dynamic V =
        p/*location: test.dart;p*/.
        foo/*location: a.dart;foo*/;
''');
      }
    } else {
      checkElementText(library, r'''
import 'a.dart' as p;
const dynamic V =
        p/*location: test.dart;p*/.
        foo/*location: a.dart;foo*/;
''');
    }
  }

  test_const_reference_topLevelVariable() async {
    var library = await checkLibrary(r'''
const A = 1;
const B = A + 2;
''');
    if (isStrongMode) {
      checkElementText(library, r'''
const int A = 1;
const int B =
        A/*location: test.dart;A?*/ + 2;
''');
    } else {
      checkElementText(library, r'''
const dynamic A = 1;
const dynamic B =
        A/*location: test.dart;A?*/ + 2;
''');
    }
  }

  test_const_reference_topLevelVariable_imported() async {
    addLibrarySource('/a.dart', r'''
const A = 1;
''');
    var library = await checkLibrary(r'''
import 'a.dart';
const B = A + 2;
''');
    if (isStrongMode) {
      checkElementText(library, r'''
import 'a.dart';
const int B =
        A/*location: a.dart;A?*/ + 2;
''');
    } else {
      checkElementText(library, r'''
import 'a.dart';
const dynamic B =
        A/*location: a.dart;A?*/ + 2;
''');
    }
  }

  test_const_reference_topLevelVariable_imported_withPrefix() async {
    addLibrarySource('/a.dart', r'''
const A = 1;
''');
    var library = await checkLibrary(r'''
import 'a.dart' as p;
const B = p.A + 2;
''');
    if (isStrongMode) {
      if (isSharedFrontEnd) {
        checkElementText(library, r'''
import 'a.dart' as p;
const int B =
        A/*location: a.dart;A?*/ + 2;
''');
      } else {
        checkElementText(library, r'''
import 'a.dart' as p;
const int B =
        p/*location: test.dart;p*/.
        A/*location: a.dart;A?*/ + 2;
''');
      }
    } else {
      checkElementText(library, r'''
import 'a.dart' as p;
const dynamic B =
        p/*location: test.dart;p*/.
        A/*location: a.dart;A?*/ + 2;
''');
    }
  }

  test_const_reference_type() async {
    var library = await checkLibrary(r'''
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
    if (isStrongMode) {
      checkElementText(library, r'''
typedef F = dynamic Function(int a, String b);
enum E {
  synthetic final int index;
  synthetic static const List<E> values;
  static const E a;
  static const E b;
  static const E c;
  String toString() {}
}
class C {
}
class D<T> {
}
const Type vDynamic =
        dynamic/*location: dynamic*/;
const Type vNull =
        Null/*location: dart:core;Null*/;
const Type vObject =
        Object/*location: dart:core;Object*/;
const Type vClass =
        C/*location: test.dart;C*/;
const Type vGenericClass =
        D/*location: test.dart;D*/;
const Type vEnum =
        E/*location: test.dart;E*/;
const Type vFunctionTypeAlias =
        F/*location: test.dart;F*/;
''');
    } else {
      checkElementText(library, r'''
typedef F = dynamic Function(int a, String b);
enum E {
  synthetic final int index;
  synthetic static const List<E> values;
  static const E a;
  static const E b;
  static const E c;
  String toString() {}
}
class C {
}
class D<T> {
}
const dynamic vDynamic =
        dynamic/*location: dynamic*/;
const dynamic vNull =
        Null/*location: dart:core;Null*/;
const dynamic vObject =
        Object/*location: dart:core;Object*/;
const dynamic vClass =
        C/*location: test.dart;C*/;
const dynamic vGenericClass =
        D/*location: test.dart;D*/;
const dynamic vEnum =
        E/*location: test.dart;E*/;
const dynamic vFunctionTypeAlias =
        F/*location: test.dart;F*/;
''');
    }
  }

  test_const_reference_type_functionType() async {
    var library = await checkLibrary(r'''
typedef F();
class C {
  final f = <F>[];
}
''');
    if (isStrongMode) {
      checkElementText(library, r'''
typedef F = dynamic Function();
class C {
  final List<() → dynamic> f;
}
''');
    } else {
      checkElementText(library, r'''
typedef F = dynamic Function();
class C {
  final dynamic f;
}
''');
    }
  }

  test_const_reference_type_imported() async {
    addLibrarySource('/a.dart', r'''
class C {}
enum E {a, b, c}
typedef F(int a, String b);
''');
    var library = await checkLibrary(r'''
import 'a.dart';
const vClass = C;
const vEnum = E;
const vFunctionTypeAlias = F;
''');
    if (isStrongMode) {
      checkElementText(library, r'''
import 'a.dart';
const Type vClass =
        C/*location: a.dart;C*/;
const Type vEnum =
        E/*location: a.dart;E*/;
const Type vFunctionTypeAlias =
        F/*location: a.dart;F*/;
''');
    } else {
      checkElementText(library, r'''
import 'a.dart';
const dynamic vClass =
        C/*location: a.dart;C*/;
const dynamic vEnum =
        E/*location: a.dart;E*/;
const dynamic vFunctionTypeAlias =
        F/*location: a.dart;F*/;
''');
    }
  }

  test_const_reference_type_imported_withPrefix() async {
    addLibrarySource('/a.dart', r'''
class C {}
enum E {a, b, c}
typedef F(int a, String b);
''');
    var library = await checkLibrary(r'''
import 'a.dart' as p;
const vClass = p.C;
const vEnum = p.E;
const vFunctionTypeAlias = p.F;
''');
    if (isStrongMode) {
      if (isSharedFrontEnd) {
        checkElementText(library, r'''
import 'a.dart' as p;
const Type vClass =
        C/*location: a.dart;C*/;
const Type vEnum =
        E/*location: a.dart;E*/;
const Type vFunctionTypeAlias =
        F/*location: a.dart;F*/;
''');
      } else {
        checkElementText(library, r'''
import 'a.dart' as p;
const Type vClass =
        p/*location: test.dart;p*/.
        C/*location: a.dart;C*/;
const Type vEnum =
        p/*location: test.dart;p*/.
        E/*location: a.dart;E*/;
const Type vFunctionTypeAlias =
        p/*location: test.dart;p*/.
        F/*location: a.dart;F*/;
''');
      }
    } else {
      checkElementText(library, r'''
import 'a.dart' as p;
const dynamic vClass =
        p/*location: test.dart;p*/.
        C/*location: a.dart;C*/;
const dynamic vEnum =
        p/*location: test.dart;p*/.
        E/*location: a.dart;E*/;
const dynamic vFunctionTypeAlias =
        p/*location: test.dart;p*/.
        F/*location: a.dart;F*/;
''');
    }
  }

  test_const_reference_type_typeParameter() async {
    var library = await checkLibrary(r'''
class C<T> {
  final f = <T>[];
}
''');
    if (isStrongMode) {
      checkElementText(library, r'''
class C<T> {
  final List<T> f;
}
''');
    } else {
      checkElementText(library, r'''
class C<T> {
  final dynamic f;
}
''');
    }
  }

  test_const_reference_unresolved_prefix0() async {
    shouldCompareLibraryElements = false;
    var library = await checkLibrary(r'''
const V = foo;
''', allowErrors: true);
    checkElementText(library, r'''
const dynamic V = #invalidConst;
''');
  }

  test_const_reference_unresolved_prefix1() async {
    shouldCompareLibraryElements = false;
    var library = await checkLibrary(r'''
class C {}
const V = C.foo;
''', allowErrors: true);
    checkElementText(library, r'''
class C {
}
const dynamic V = #invalidConst;
''');
  }

  test_const_reference_unresolved_prefix2() async {
    shouldCompareLibraryElements = false;
    addLibrarySource('/foo.dart', '''
class C {}
''');
    var library = await checkLibrary(r'''
import 'foo.dart' as p;
const V = p.C.foo;
''', allowErrors: true);
    checkElementText(library, r'''
import 'foo.dart' as p;
const dynamic V = #invalidConst;
''');
  }

  test_const_topLevel_binary() async {
    var library = await checkLibrary(r'''
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
    if (isStrongMode) {
      checkElementText(library, r'''
const bool vEqual = 1 == 2;
const bool vAnd = true && false;
const bool vOr = false || true;
const int vBitXor = 1 ^ 2;
const int vBitAnd = 1 & 2;
const int vBitOr = 1 | 2;
const int vBitShiftLeft = 1 << 2;
const int vBitShiftRight = 1 >> 2;
const int vAdd = 1 + 2;
const int vSubtract = 1 - 2;
const int vMiltiply = 1 * 2;
const double vDivide = 1 / 2;
const int vFloorDivide = 1 ~/ 2;
const int vModulo = 1 % 2;
const bool vGreater = 1 > 2;
const bool vGreaterEqual = 1 >= 2;
const bool vLess = 1 < 2;
const bool vLessEqual = 1 <= 2;
''');
    } else {
      checkElementText(library, r'''
const dynamic vEqual = 1 == 2;
const dynamic vAnd = true && false;
const dynamic vOr = false || true;
const dynamic vBitXor = 1 ^ 2;
const dynamic vBitAnd = 1 & 2;
const dynamic vBitOr = 1 | 2;
const dynamic vBitShiftLeft = 1 << 2;
const dynamic vBitShiftRight = 1 >> 2;
const dynamic vAdd = 1 + 2;
const dynamic vSubtract = 1 - 2;
const dynamic vMiltiply = 1 * 2;
const dynamic vDivide = 1 / 2;
const dynamic vFloorDivide = 1 ~/ 2;
const dynamic vModulo = 1 % 2;
const dynamic vGreater = 1 > 2;
const dynamic vGreaterEqual = 1 >= 2;
const dynamic vLess = 1 < 2;
const dynamic vLessEqual = 1 <= 2;
''');
    }
  }

  test_const_topLevel_conditional() async {
    var library = await checkLibrary(r'''
const vConditional = (1 == 2) ? 11 : 22;
''');
    if (isStrongMode) {
      checkElementText(library, r'''
const int vConditional = 1 == 2 ? 11 : 22;
''');
    } else {
      checkElementText(library, r'''
const dynamic vConditional = 1 == 2 ? 11 : 22;
''');
    }
  }

  test_const_topLevel_identical() async {
    var library = await checkLibrary(r'''
const vIdentical = (1 == 2) ? 11 : 22;
''');
    if (isStrongMode) {
      checkElementText(library, r'''
const int vIdentical = 1 == 2 ? 11 : 22;
''');
    } else {
      checkElementText(library, r'''
const dynamic vIdentical = 1 == 2 ? 11 : 22;
''');
    }
  }

  test_const_topLevel_ifNull() async {
    var library = await checkLibrary(r'''
const vIfNull = 1 ?? 2.0;
''');
    if (isStrongMode) {
      checkElementText(library, r'''
const num vIfNull = 1 ?? 2.0;
''');
    } else {
      checkElementText(library, r'''
const dynamic vIfNull = 1 ?? 2.0;
''');
    }
  }

  test_const_topLevel_literal() async {
    var library = await checkLibrary(r'''
const vNull = null;
const vBoolFalse = false;
const vBoolTrue = true;
const vInt = 1;
const vIntLong1 = 0x7FFFFFFFFFFFFFFF;
const vIntLong2 = 0xFFFFFFFFFFFFFFFF;
const vDouble = 2.3;
const vString = 'abc';
const vStringConcat = 'aaa' 'bbb';
const vStringInterpolation = 'aaa ${true} ${42} bbb';
const vSymbol = #aaa.bbb.ccc;
''');
    if (isStrongMode) {
      checkElementText(library, r'''
const dynamic vNull = null;
const bool vBoolFalse = false;
const bool vBoolTrue = true;
const int vInt = 1;
const int vIntLong1 = 9223372036854775807;
const int vIntLong2 = -1;
const double vDouble = 2.3;
const String vString = 'abc';
const String vStringConcat = 'aaabbb';
const String vStringInterpolation = 'aaa ${true} ${42} bbb';
const Symbol vSymbol = #aaa.bbb.ccc;
''');
    } else {
      checkElementText(library, r'''
const dynamic vNull = null;
const dynamic vBoolFalse = false;
const dynamic vBoolTrue = true;
const dynamic vInt = 1;
const dynamic vIntLong1 = 9223372036854775807;
const dynamic vIntLong2 = -1;
const dynamic vDouble = 2.3;
const dynamic vString = 'abc';
const dynamic vStringConcat = 'aaabbb';
const dynamic vStringInterpolation = 'aaa ${true} ${42} bbb';
const dynamic vSymbol = #aaa.bbb.ccc;
''');
    }
  }

  test_const_topLevel_parenthesis() async {
    var library = await checkLibrary(r'''
const int v1 = (1 + 2) * 3;
const int v2 = -(1 + 2);
const int v3 = ('aaa' + 'bbb').length;
''');
    checkElementText(library, r'''
const int v1 = (1 + 2) * 3;
const int v2 = -(1 + 2);
const int v3 = ('aaa' + 'bbb').
        length/*location: dart:core;String;length?*/;
''');
  }

  test_const_topLevel_prefix() async {
    var library = await checkLibrary(r'''
const vNotEqual = 1 != 2;
const vNot = !true;
const vNegate = -1;
const vComplement = ~1;
''');
    if (isStrongMode) {
      if (isSharedFrontEnd) {
        checkElementText(library, r'''
const bool vNotEqual = !(1 == 2);
const bool vNot = !true;
const int vNegate = -1;
const int vComplement = ~1;
''');
      } else {
        checkElementText(library, r'''
const bool vNotEqual = 1 != 2;
const bool vNot = !true;
const int vNegate = -1;
const int vComplement = ~1;
''');
      }
    } else {
      checkElementText(library, r'''
const dynamic vNotEqual = 1 != 2;
const dynamic vNot = !true;
const dynamic vNegate = -1;
const dynamic vComplement = ~1;
''');
    }
  }

  test_const_topLevel_super() async {
    shouldCompareLibraryElements = false;
    var library = await checkLibrary(r'''
const vSuper = super;
''');
    checkElementText(library, r'''
const dynamic vSuper = #invalidConst;
''');
  }

  test_const_topLevel_this() async {
    shouldCompareLibraryElements = false;
    var library = await checkLibrary(r'''
const vThis = this;
''');
    checkElementText(library, r'''
const dynamic vThis = #invalidConst;
''');
  }

  test_const_topLevel_typedList() async {
    var library = await checkLibrary(r'''
const vNull = const <Null>[];
const vDynamic = const <dynamic>[1, 2, 3];
const vInterfaceNoTypeParameters = const <int>[1, 2, 3];
const vInterfaceNoTypeArguments = const <List>[];
const vInterfaceWithTypeArguments = const <List<String>>[];
const vInterfaceWithTypeArguments2 = const <Map<int, List<String>>>[];
''');
    if (isStrongMode) {
      checkElementText(library, r'''
const List<Null> vNull = const <
        Null/*location: dart:core;Null*/>[];
const List<dynamic> vDynamic = const <
        dynamic/*location: dynamic*/>[1, 2, 3];
const List<int> vInterfaceNoTypeParameters = const <
        int/*location: dart:core;int*/>[1, 2, 3];
const List<List<dynamic>> vInterfaceNoTypeArguments = const <
        List/*location: dart:core;List*/>[];
const List<List<String>> vInterfaceWithTypeArguments = const <
        List/*location: dart:core;List*/<
        String/*location: dart:core;String*/>>[];
const List<Map<int, List<String>>> vInterfaceWithTypeArguments2 = const <
        Map/*location: dart:core;Map*/<
        int/*location: dart:core;int*/,
        List/*location: dart:core;List*/<
        String/*location: dart:core;String*/>>>[];
''');
    } else {
      checkElementText(library, r'''
const dynamic vNull = const <
        Null/*location: dart:core;Null*/>[];
const dynamic vDynamic = const <
        dynamic/*location: dynamic*/>[1, 2, 3];
const dynamic vInterfaceNoTypeParameters = const <
        int/*location: dart:core;int*/>[1, 2, 3];
const dynamic vInterfaceNoTypeArguments = const <
        List/*location: dart:core;List*/>[];
const dynamic vInterfaceWithTypeArguments = const <
        List/*location: dart:core;List*/<
        String/*location: dart:core;String*/>>[];
const dynamic vInterfaceWithTypeArguments2 = const <
        Map/*location: dart:core;Map*/<
        int/*location: dart:core;int*/,
        List/*location: dart:core;List*/<
        String/*location: dart:core;String*/>>>[];
''');
    }
  }

  test_const_topLevel_typedList_imported() async {
    addLibrarySource('/a.dart', 'class C {}');
    var library = await checkLibrary(r'''
import 'a.dart';
const v = const <C>[];
''');
    if (isStrongMode) {
      checkElementText(library, r'''
import 'a.dart';
const List<C> v = const <
        C/*location: a.dart;C*/>[];
''');
    } else {
      checkElementText(library, r'''
import 'a.dart';
const dynamic v = const <
        C/*location: a.dart;C*/>[];
''');
    }
  }

  test_const_topLevel_typedList_importedWithPrefix() async {
    addLibrarySource('/a.dart', 'class C {}');
    var library = await checkLibrary(r'''
import 'a.dart' as p;
const v = const <p.C>[];
''');
    if (isStrongMode) {
      checkElementText(library, r'''
import 'a.dart' as p;
const List<C> v = const <
        C/*location: a.dart;C*/>[];
''');
    } else {
      checkElementText(library, r'''
import 'a.dart' as p;
const dynamic v = const <
        C/*location: a.dart;C*/>[];
''');
    }
  }

  test_const_topLevel_typedList_typedefArgument() async {
    shouldCompareLibraryElements = false;
    var library = await checkLibrary(r'''
typedef int F(String id);
const v = const <F>[];
''');
    if (isStrongMode) {
      checkElementText(library, r'''
typedef F = int Function(String id);
const List<(String) → int> v = const <
        null/*location: test.dart;F;-*/>[];
''');
    } else {
      checkElementText(library, r'''
typedef F = int Function(String id);
const dynamic v = const <
        null/*location: test.dart;F;-*/>[];
''');
    }
  }

  test_const_topLevel_typedMap() async {
    var library = await checkLibrary(r'''
const vDynamic1 = const <dynamic, int>{};
const vDynamic2 = const <int, dynamic>{};
const vInterface = const <int, String>{};
const vInterfaceWithTypeArguments = const <int, List<String>>{};
''');
    if (isStrongMode) {
      checkElementText(library, r'''
const Map<dynamic, int> vDynamic1 = const <
        dynamic/*location: dynamic*/,
        int/*location: dart:core;int*/>{};
const Map<int, dynamic> vDynamic2 = const <
        int/*location: dart:core;int*/,
        dynamic/*location: dynamic*/>{};
const Map<int, String> vInterface = const <
        int/*location: dart:core;int*/,
        String/*location: dart:core;String*/>{};
const Map<int, List<String>> vInterfaceWithTypeArguments = const <
        int/*location: dart:core;int*/,
        List/*location: dart:core;List*/<
        String/*location: dart:core;String*/>>{};
''');
    } else {
      checkElementText(library, r'''
const dynamic vDynamic1 = const <
        dynamic/*location: dynamic*/,
        int/*location: dart:core;int*/>{};
const dynamic vDynamic2 = const <
        int/*location: dart:core;int*/,
        dynamic/*location: dynamic*/>{};
const dynamic vInterface = const <
        int/*location: dart:core;int*/,
        String/*location: dart:core;String*/>{};
const dynamic vInterfaceWithTypeArguments = const <
        int/*location: dart:core;int*/,
        List/*location: dart:core;List*/<
        String/*location: dart:core;String*/>>{};
''');
    }
  }

  test_const_topLevel_untypedList() async {
    var library = await checkLibrary(r'''
const v = const [1, 2, 3];
''');
    if (isStrongMode) {
      if (isSharedFrontEnd) {
        checkElementText(library, r'''
const List<int> v = const <
        int/*location: dart:core;int*/>[1, 2, 3];
''');
      } else {
        checkElementText(library, r'''
const List<int> v = const [1, 2, 3];
''');
      }
    } else {
      checkElementText(library, r'''
const dynamic v = const [1, 2, 3];
''');
    }
  }

  test_const_topLevel_untypedMap() async {
    var library = await checkLibrary(r'''
const v = const {0: 'aaa', 1: 'bbb', 2: 'ccc'};
''');
    if (isStrongMode) {
      if (isSharedFrontEnd) {
        checkElementText(library, r'''
const Map<int, String> v = const <
        int/*location: dart:core;int*/,
        String/*location: dart:core;String*/>{0: 'aaa', 1: 'bbb', 2: 'ccc'};
''');
      } else {
        checkElementText(library, r'''
const Map<int, String> v = const {0: 'aaa', 1: 'bbb', 2: 'ccc'};
''');
      }
    } else {
      checkElementText(library, r'''
const dynamic v = const {0: 'aaa', 1: 'bbb', 2: 'ccc'};
''');
    }
  }

  test_constExpr_pushReference_enum_field() async {
    var library = await checkLibrary('''
enum E {a, b, c}
final vValue = E.a;
final vValues = E.values;
final vIndex = E.a.index;
''');
    if (isStrongMode) {
      checkElementText(library, r'''
enum E {
  synthetic final int index;
  synthetic static const List<E> values;
  static const E a;
  static const E b;
  static const E c;
  String toString() {}
}
final E vValue;
final List<E> vValues;
final int vIndex;
''');
    } else {
      checkElementText(library, r'''
enum E {
  synthetic final int index;
  synthetic static const List<E> values;
  static const E a;
  static const E b;
  static const E c;
  String toString() {}
}
final dynamic vValue;
final dynamic vValues;
final dynamic vIndex;
''');
    }
  }

  test_constExpr_pushReference_enum_method() async {
    var library = await checkLibrary('''
enum E {a}
final vToString = E.a.toString();
''');
    if (isStrongMode) {
      checkElementText(library, r'''
enum E {
  synthetic final int index;
  synthetic static const List<E> values;
  static const E a;
  String toString() {}
}
final String vToString;
''');
    } else {
      checkElementText(library, r'''
enum E {
  synthetic final int index;
  synthetic static const List<E> values;
  static const E a;
  String toString() {}
}
final dynamic vToString;
''');
    }
  }

  test_constExpr_pushReference_field_simpleIdentifier() async {
    var library = await checkLibrary('''
class C {
  static const a = b;
  static const b = null;
}
''');
    checkElementText(library, r'''
class C {
  static const dynamic a =
        C/*location: test.dart;C*/.
        b/*location: test.dart;C;b?*/;
  static const dynamic b = null;
}
''');
  }

  test_constExpr_pushReference_staticMethod_simpleIdentifier() async {
    var library = await checkLibrary('''
class C {
  static const a = m;
  static m() {}
}
''');
    if (isStrongMode) {
      checkElementText(library, r'''
class C {
  static const () → dynamic a =
        C/*location: test.dart;C*/.
        m/*location: test.dart;C;m*/;
  static dynamic m() {}
}
''');
    } else {
      checkElementText(library, r'''
class C {
  static const dynamic a =
        C/*location: test.dart;C*/.
        m/*location: test.dart;C;m*/;
  static dynamic m() {}
}
''');
    }
  }

  test_constructor_documented() async {
    var library = await checkLibrary('''
class C {
  /**
   * Docs
   */
  C();
}''');
    checkElementText(library, r'''
class C {
  /**
   * Docs
   */
  C();
}
''');
  }

  test_constructor_initializers_assertInvocation() async {
    var library = await checkLibrary('''
class C {
  const C(int x) : assert(x >= 42);
}
''');
    checkElementText(library, r'''
class C {
  const C(int x) : assert(
        x/*location: test.dart;C;;x*/ >= 42);
}
''');
  }

  test_constructor_initializers_assertInvocation_message() async {
    var library = await checkLibrary('''
class C {
  const C(int x) : assert(x >= 42, 'foo');
}
''');
    checkElementText(library, r'''
class C {
  const C(int x) : assert(
        x/*location: test.dart;C;;x*/ >= 42, 'foo');
}
''');
  }

  test_constructor_initializers_field() async {
    var library = await checkLibrary('''
class C {
  final x;
  const C() : x = 42;
}
''');
    checkElementText(library, r'''
class C {
  final dynamic x;
  const C() :
        x/*location: test.dart;C;x*/ = 42;
}
''');
  }

  test_constructor_initializers_field_notConst() async {
    shouldCompareLibraryElements = false;
    var library = await checkLibrary('''
class C {
  final x;
  const C() : x = foo();
}
int foo() => 42;
''', allowErrors: true);
    // It is OK to keep non-constant initializers.
    checkElementText(library, r'''
class C {
  final dynamic x;
  const C() :
        x/*location: test.dart;C;x*/ =
        foo/*location: test.dart;foo*/();
}
int foo() {}
''');
  }

  test_constructor_initializers_field_withParameter() async {
    var library = await checkLibrary('''
class C {
  final x;
  const C(int p) : x = 1 + p;
}
''');
    checkElementText(library, r'''
class C {
  final dynamic x;
  const C(int p) :
        x/*location: test.dart;C;x*/ = 1 +
        p/*location: test.dart;C;;p*/;
}
''');
  }

  test_constructor_initializers_superInvocation_named() async {
    var library = await checkLibrary('''
class A {
  const A.aaa(int p);
}
class C extends A {
  const C() : super.aaa(42);
}
''');
    checkElementText(library, r'''
class A {
  const A.aaa(int p);
}
class C extends A {
  const C() : super.
        aaa/*location: test.dart;A;aaa*/(42);
}
''');
  }

  test_constructor_initializers_superInvocation_named_underscore() async {
    var library = await checkLibrary('''
class A {
  const A._();
}
class B extends A {
  const B() : super._();
}
''');
    checkElementText(library, r'''
class A {
  const A._();
}
class B extends A {
  const B() : super.
        _/*location: test.dart;A;_*/();
}
''');
  }

  test_constructor_initializers_superInvocation_namedExpression() async {
    var library = await checkLibrary('''
class A {
  const A.aaa(a, {int b});
}
class C extends A {
  const C() : super.aaa(1, b: 2);
}
''');
    checkElementText(library, r'''
class A {
  const A.aaa(dynamic a, {int b});
}
class C extends A {
  const C() : super.
        aaa/*location: test.dart;A;aaa*/(1,
        b/*location: null*/: 2);
}
''');
  }

  test_constructor_initializers_superInvocation_unnamed() async {
    var library = await checkLibrary('''
class A {
  const A(int p);
}
class C extends A {
  const C.ccc() : super(42);
}
''');
    checkElementText(library, r'''
class A {
  const A(int p);
}
class C extends A {
  const C.ccc() : super(42);
}
''');
  }

  test_constructor_initializers_thisInvocation_named() async {
    var library = await checkLibrary('''
class C {
  const C() : this.named(1, 'bbb');
  const C.named(int a, String b);
}
''');
    checkElementText(library, r'''
class C {
  const C() = C.named : this.
        named/*location: test.dart;C;named*/(1, 'bbb');
  const C.named(int a, String b);
}
''');
  }

  test_constructor_initializers_thisInvocation_namedExpression() async {
    var library = await checkLibrary('''
class C {
  const C() : this.named(1, b: 2);
  const C.named(a, {int b});
}
''');
    checkElementText(library, r'''
class C {
  const C() = C.named : this.
        named/*location: test.dart;C;named*/(1,
        b/*location: null*/: 2);
  const C.named(dynamic a, {int b});
}
''');
  }

  test_constructor_initializers_thisInvocation_unnamed() async {
    var library = await checkLibrary('''
class C {
  const C.named() : this(1, 'bbb');
  const C(int a, String b);
}
''');
    checkElementText(library, r'''
class C {
  const C.named() = C : this(1, 'bbb');
  const C(int a, String b);
}
''');
  }

  test_constructor_redirected_factory_named() async {
    var library = await checkLibrary('''
class C {
  factory C() = D.named;
  C._();
}
class D extends C {
  D.named() : super._();
}
''');
    checkElementText(library, r'''
class C {
  factory C() = D.named;
  C._();
}
class D extends C {
  D.named();
}
''');
  }

  test_constructor_redirected_factory_named_generic() async {
    var library = await checkLibrary('''
class C<T, U> {
  factory C() = D<U, T>.named;
  C._();
}
class D<T, U> extends C<U, T> {
  D.named() : super._();
}
''');
    checkElementText(library, r'''
class C<T, U> {
  factory C() = D<U, T>.named;
  C._();
}
class D<T, U> extends C<U, T> {
  D.named();
}
''');
  }

  test_constructor_redirected_factory_named_imported() async {
    addLibrarySource('/foo.dart', '''
import 'test.dart';
class D extends C {
  D.named() : super._();
}
''');
    var library = await checkLibrary('''
import 'foo.dart';
class C {
  factory C() = D.named;
  C._();
}
''');
    checkElementText(library, r'''
import 'foo.dart';
class C {
  factory C() = D.named;
  C._();
}
''');
  }

  test_constructor_redirected_factory_named_imported_generic() async {
    addLibrarySource('/foo.dart', '''
import 'test.dart';
class D<T, U> extends C<U, T> {
  D.named() : super._();
}
''');
    var library = await checkLibrary('''
import 'foo.dart';
class C<T, U> {
  factory C() = D<U, T>.named;
  C._();
}
''');
    checkElementText(library, r'''
import 'foo.dart';
class C<T, U> {
  factory C() = D<U, T>.named;
  C._();
}
''');
  }

  test_constructor_redirected_factory_named_prefixed() async {
    addLibrarySource('/foo.dart', '''
import 'test.dart';
class D extends C {
  D.named() : super._();
}
''');
    var library = await checkLibrary('''
import 'foo.dart' as foo;
class C {
  factory C() = foo.D.named;
  C._();
}
''');
    checkElementText(library, r'''
import 'foo.dart' as foo;
class C {
  factory C() = D.named;
  C._();
}
''');
  }

  test_constructor_redirected_factory_named_prefixed_generic() async {
    addLibrarySource('/foo.dart', '''
import 'test.dart';
class D<T, U> extends C<U, T> {
  D.named() : super._();
}
''');
    var library = await checkLibrary('''
import 'foo.dart' as foo;
class C<T, U> {
  factory C() = foo.D<U, T>.named;
  C._();
}
''');
    checkElementText(library, r'''
import 'foo.dart' as foo;
class C<T, U> {
  factory C() = D<U, T>.named;
  C._();
}
''');
  }

  test_constructor_redirected_factory_named_unresolved_class() async {
    var library = await checkLibrary('''
class C<E> {
  factory C() = D.named<E>;
}
''', allowErrors: true);
    checkElementText(library, r'''
class C<E> {
  factory C();
}
''');
  }

  test_constructor_redirected_factory_named_unresolved_constructor() async {
    var library = await checkLibrary('''
class D {}
class C<E> {
  factory C() = D.named<E>;
}
''', allowErrors: true);
    checkElementText(library, r'''
class D {
}
class C<E> {
  factory C();
}
''');
  }

  test_constructor_redirected_factory_unnamed() async {
    var library = await checkLibrary('''
class C {
  factory C() = D;
  C._();
}
class D extends C {
  D() : super._();
}
''');
    checkElementText(library, r'''
class C {
  factory C() = D;
  C._();
}
class D extends C {
  D();
}
''');
  }

  test_constructor_redirected_factory_unnamed_generic() async {
    var library = await checkLibrary('''
class C<T, U> {
  factory C() = D<U, T>;
  C._();
}
class D<T, U> extends C<U, T> {
  D() : super._();
}
''');
    checkElementText(library, r'''
class C<T, U> {
  factory C() = D<U, T>;
  C._();
}
class D<T, U> extends C<U, T> {
  D();
}
''');
  }

  test_constructor_redirected_factory_unnamed_imported() async {
    addLibrarySource('/foo.dart', '''
import 'test.dart';
class D extends C {
  D() : super._();
}
''');
    var library = await checkLibrary('''
import 'foo.dart';
class C {
  factory C() = D;
  C._();
}
''');
    checkElementText(library, r'''
import 'foo.dart';
class C {
  factory C() = D;
  C._();
}
''');
  }

  test_constructor_redirected_factory_unnamed_imported_generic() async {
    addLibrarySource('/foo.dart', '''
import 'test.dart';
class D<T, U> extends C<U, T> {
  D() : super._();
}
''');
    var library = await checkLibrary('''
import 'foo.dart';
class C<T, U> {
  factory C() = D<U, T>;
  C._();
}
''');
    checkElementText(library, r'''
import 'foo.dart';
class C<T, U> {
  factory C() = D<U, T>;
  C._();
}
''');
  }

  test_constructor_redirected_factory_unnamed_prefixed() async {
    addLibrarySource('/foo.dart', '''
import 'test.dart';
class D extends C {
  D() : super._();
}
''');
    var library = await checkLibrary('''
import 'foo.dart' as foo;
class C {
  factory C() = foo.D;
  C._();
}
''');
    checkElementText(library, r'''
import 'foo.dart' as foo;
class C {
  factory C() = D;
  C._();
}
''');
  }

  test_constructor_redirected_factory_unnamed_prefixed_generic() async {
    addLibrarySource('/foo.dart', '''
import 'test.dart';
class D<T, U> extends C<U, T> {
  D() : super._();
}
''');
    var library = await checkLibrary('''
import 'foo.dart' as foo;
class C<T, U> {
  factory C() = foo.D<U, T>;
  C._();
}
''');
    checkElementText(library, r'''
import 'foo.dart' as foo;
class C<T, U> {
  factory C() = D<U, T>;
  C._();
}
''');
  }

  test_constructor_redirected_factory_unnamed_unresolved() async {
    var library = await checkLibrary('''
class C<E> {
  factory C() = D<E>;
}
''', allowErrors: true);
    checkElementText(library, r'''
class C<E> {
  factory C();
}
''');
  }

  test_constructor_redirected_thisInvocation_named() async {
    var library = await checkLibrary('''
class C {
  C.named();
  C() : this.named();
}
''');
    checkElementText(library, r'''
class C {
  C.named();
  C() = C.named;
}
''');
  }

  test_constructor_redirected_thisInvocation_named_generic() async {
    var library = await checkLibrary('''
class C<T> {
  C.named();
  C() : this.named();
}
''');
    checkElementText(library, r'''
class C<T> {
  C.named();
  C() = C<T>.named;
}
''');
  }

  test_constructor_redirected_thisInvocation_unnamed() async {
    var library = await checkLibrary('''
class C {
  C();
  C.named() : this();
}
''');
    checkElementText(library, r'''
class C {
  C();
  C.named() = C;
}
''');
  }

  test_constructor_redirected_thisInvocation_unnamed_generic() async {
    var library = await checkLibrary('''
class C<T> {
  C();
  C.named() : this();
}
''');
    checkElementText(library, r'''
class C<T> {
  C();
  C.named() = C<T>;
}
''');
  }

  test_constructor_withCycles_const() async {
    var library = await checkLibrary('''
class C {
  final x;
  const C() : x = const D();
}
class D {
  final x;
  const D() : x = const C();
}
''');
    checkElementText(library, r'''
class C {
  final dynamic x;
  const C() :
        x/*location: test.dart;C;x*/ = const
        D/*location: test.dart;D*/();
}
class D {
  final dynamic x;
  const D() :
        x/*location: test.dart;D;x*/ = const
        C/*location: test.dart;C*/();
}
''');
  }

  test_constructor_withCycles_nonConst() async {
    var library = await checkLibrary('''
class C {
  final x;
  C() : x = new D();
}
class D {
  final x;
  D() : x = new C();
}
''');
    checkElementText(library, r'''
class C {
  final dynamic x;
  C();
}
class D {
  final dynamic x;
  D();
}
''');
  }

  test_defaultValue_refersToGenericClass_constructor() async {
    var library = await checkLibrary('''
class B<T> {
  const B();
}
class C<T> {
  const C([B<T> b = const B()]);
}
''');
    if (isSharedFrontEnd) {
      // The constant can not depend on a (non-constant) type parameter.
      checkElementText(library, r'''
class B<T> {
  const B();
}
class C<T> {
  const C([B<T> b = const
        B/*location: test.dart;B*/<
        Null/*location: dart:core;Null*/>()]);
}
''');
    } else {
      checkElementText(library, r'''
class B<T> {
  const B();
}
class C<T> {
  const C([B<T> b = const
        B/*location: test.dart;B*/()]);
}
''');
    }
  }

  test_defaultValue_refersToGenericClass_constructor2() async {
    var library = await checkLibrary('''
abstract class A<T> {}
class B<T> implements A<T> {
  const B();
}
class C<T> implements A<Iterable<T>> {
  const C([A<T> a = const B()]);
}
''');
    if (isSharedFrontEnd) {
      // The constant can not depend on a (non-constant) type parameter.
      checkElementText(library, r'''
abstract class A<T> {
}
class B<T> implements A<T> {
  const B();
}
class C<T> implements A<Iterable<T>> {
  const C([A<T> a = const
        B/*location: test.dart;B*/<
        Null/*location: dart:core;Null*/>()]);
}
''');
    } else {
      checkElementText(library, r'''
abstract class A<T> {
}
class B<T> implements A<T> {
  const B();
}
class C<T> implements A<Iterable<T>> {
  const C([A<T> a = const
        B/*location: test.dart;B*/()]);
}
''');
    }
  }

  test_defaultValue_refersToGenericClass_functionG() async {
    var library = await checkLibrary('''
class B<T> {
  const B();
}
void foo<T>([B<T> b = const B()]) {}
''');
    if (isSharedFrontEnd) {
      // The constant can not depend on a (non-constant) type parameter.
      checkElementText(library, r'''
class B<T> {
  const B();
}
void foo<T>([B<T> b = const
        B/*location: test.dart;B*/<
        Null/*location: dart:core;Null*/>()]) {}
''');
    } else {
      checkElementText(library, r'''
class B<T> {
  const B();
}
void foo<T>([B<T> b = const
        B/*location: test.dart;B*/()]) {}
''');
    }
  }

  test_defaultValue_refersToGenericClass_methodG() async {
    var library = await checkLibrary('''
class B<T> {
  const B();
}
class C {
  void foo<T>([B<T> b = const B()]) {}
}
''');
    if (isSharedFrontEnd) {
      // The constant can not depend on a (non-constant) type parameter.
      checkElementText(library, r'''
class B<T> {
  const B();
}
class C {
  void foo<T>([B<T> b = const
        B/*location: test.dart;B*/<
        Null/*location: dart:core;Null*/>()]) {}
}
''');
    } else {
      checkElementText(library, r'''
class B<T> {
  const B();
}
class C {
  void foo<T>([B<T> b = const
        B/*location: test.dart;B*/()]) {}
}
''');
    }
  }

  test_defaultValue_refersToGenericClass_methodG_classG() async {
    var library = await checkLibrary('''
class B<T1, T2> {
  const B();
}
class C<E1> {
  void foo<E2>([B<E1, E2> b = const B()]) {}
}
''');
    if (isSharedFrontEnd) {
      // The constant can not depend on a (non-constant) type parameter.
      checkElementText(library, r'''
class B<T1, T2> {
  const B();
}
class C<E1> {
  void foo<E2>([B<E1, E2> b = const
        B/*location: test.dart;B*/<
        Null/*location: dart:core;Null*/,
        Null/*location: dart:core;Null*/>()]) {}
}
''');
    } else {
      checkElementText(library, r'''
class B<T1, T2> {
  const B();
}
class C<E1> {
  void foo<E2>([B<E1, E2> b = const
        B/*location: test.dart;B*/()]) {}
}
''');
    }
  }

  test_defaultValue_refersToGenericClass_methodNG() async {
    var library = await checkLibrary('''
class B<T> {
  const B();
}
class C<T> {
  void foo([B<T> b = const B()]) {}
}
''');
    if (isSharedFrontEnd) {
      // The constant can not depend on a (non-constant) type parameter.
      checkElementText(library, r'''
class B<T> {
  const B();
}
class C<T> {
  void foo([B<T> b = const
        B/*location: test.dart;B*/<
        Null/*location: dart:core;Null*/>()]) {}
}
''');
    } else {
      checkElementText(library, r'''
class B<T> {
  const B();
}
class C<T> {
  void foo([B<T> b = const
        B/*location: test.dart;B*/()]) {}
}
''');
    }
  }

  test_enum_documented() async {
    var library = await checkLibrary('''
// Extra comment so doc comment offset != 0
/**
 * Docs
 */
enum E { v }''');
    checkElementText(library, r'''
/**
 * Docs
 */
enum E {
  synthetic final int index;
  synthetic static const List<E> values;
  static const E v;
  String toString() {}
}
''');
  }

  test_enum_value_documented() async {
    var library = await checkLibrary('''
enum E {
  /**
   * aaa
   */
  a,
  /// bbb
  b
}''');
    checkElementText(library, r'''
enum E {
  synthetic final int index;
  synthetic static const List<E> values;
  /**
   * aaa
   */
  static const E a;
  /// bbb
  static const E b;
  String toString() {}
}
''');
  }

  test_enum_values() async {
    var library = await checkLibrary('enum E { v1, v2 }');
    checkElementText(library, r'''
enum E {
  synthetic final int index;
  synthetic static const List<E> values;
  static const E v1;
  static const E v2;
  String toString() {}
}
''');
  }

  test_enums() async {
    var library = await checkLibrary('enum E1 { v1 } enum E2 { v2 }');
    checkElementText(library, r'''
enum E1 {
  synthetic final int index;
  synthetic static const List<E1> values;
  static const E1 v1;
  String toString() {}
}
enum E2 {
  synthetic final int index;
  synthetic static const List<E2> values;
  static const E2 v2;
  String toString() {}
}
''');
  }

  test_error_extendsEnum() async {
    var library = await checkLibrary('''
enum E {a, b, c}

class M {}

class A extends E {
  foo() {}
}

class B implements E, M {
  foo() {}
}

class C extends Object with E, M {
  foo() {}
}

class D = Object with M, E;
''');
    checkElementText(library, r'''
enum E {
  synthetic final int index;
  synthetic static const List<E> values;
  static const E a;
  static const E b;
  static const E c;
  String toString() {}
}
class M {
}
class A {
  dynamic foo() {}
}
class B implements M {
  dynamic foo() {}
}
class C extends Object with M {
  synthetic C();
  dynamic foo() {}
}
class alias D extends Object with M {
  synthetic D() = Object;
}
''');
  }

  test_executable_parameter_type_typedef() async {
    var library = await checkLibrary(r'''
typedef F(int p);
main(F f) {}
''');
    checkElementText(library, r'''
typedef F = dynamic Function(int p);
dynamic main((int) → dynamic f) {}
''');
  }

  test_export_class() async {
    addLibrarySource('/a.dart', 'class C {}');
    var library = await checkLibrary('export "a.dart";');
    checkElementText(library, r'''
export 'a.dart';
''');
  }

  test_export_class_type_alias() async {
    addLibrarySource('/a.dart', r'''
class C = _D with _E;
class _D {}
class _E {}
''');
    var library = await checkLibrary('export "a.dart";');
    checkElementText(library, r'''
export 'a.dart';
''');
  }

  test_export_configurations_useDefault() async {
    context.declaredVariables =
        new DeclaredVariables.fromMap({'dart.library.io': 'false'});
    addLibrarySource('/foo.dart', 'class A {}');
    addLibrarySource('/foo_io.dart', 'class A {}');
    addLibrarySource('/foo_html.dart', 'class A {}');
    var library = await checkLibrary(r'''
export 'foo.dart'
  if (dart.library.io) 'foo_io.dart'
  if (dart.library.html) 'foo_html.dart';
''');
    checkElementText(library, r'''
export 'foo.dart';
''');
    expect(library.exports[0].exportedLibrary.source.shortName, 'foo.dart');
  }

  test_export_configurations_useFirst() async {
    context.declaredVariables = new DeclaredVariables.fromMap(
        {'dart.library.io': 'true', 'dart.library.html': 'true'});
    addLibrarySource('/foo.dart', 'class A {}');
    addLibrarySource('/foo_io.dart', 'class A {}');
    addLibrarySource('/foo_html.dart', 'class A {}');
    var library = await checkLibrary(r'''
export 'foo.dart'
  if (dart.library.io) 'foo_io.dart'
  if (dart.library.html) 'foo_html.dart';
''');
    checkElementText(library, r'''
export 'foo_io.dart';
''');
    expect(library.exports[0].exportedLibrary.source.shortName, 'foo_io.dart');
  }

  test_export_configurations_useSecond() async {
    context.declaredVariables = new DeclaredVariables.fromMap(
        {'dart.library.io': 'false', 'dart.library.html': 'true'});
    addLibrarySource('/foo.dart', 'class A {}');
    addLibrarySource('/foo_io.dart', 'class A {}');
    addLibrarySource('/foo_html.dart', 'class A {}');
    var library = await checkLibrary(r'''
export 'foo.dart'
  if (dart.library.io) 'foo_io.dart'
  if (dart.library.html) 'foo_html.dart';
''');
    checkElementText(library, r'''
export 'foo_html.dart';
''');
    ExportElement export = library.exports[0];
    expect(export.exportedLibrary.source.shortName, 'foo_html.dart');
  }

  test_export_function() async {
    addLibrarySource('/a.dart', 'f() {}');
    var library = await checkLibrary('export "a.dart";');
    checkElementText(library, r'''
export 'a.dart';
''');
  }

  test_export_getter() async {
    addLibrarySource('/a.dart', 'get f() => null;');
    var library = await checkLibrary('export "a.dart";');
    checkElementText(library, r'''
export 'a.dart';
''');
  }

  test_export_hide() async {
    addLibrary('dart:async');
    var library =
        await checkLibrary('export "dart:async" hide Stream, Future;');
    checkElementText(library, r'''
export 'dart:async' hide Stream, Future;
''');
  }

  test_export_multiple_combinators() async {
    addLibrary('dart:async');
    var library =
        await checkLibrary('export "dart:async" hide Stream show Future;');
    checkElementText(library, r'''
export 'dart:async' hide Stream show Future;
''');
  }

  test_export_setter() async {
    addLibrarySource('/a.dart', 'void set f(value) {}');
    var library = await checkLibrary('export "a.dart";');
    checkElementText(library, r'''
export 'a.dart';
''');
  }

  test_export_show() async {
    addLibrary('dart:async');
    var library =
        await checkLibrary('export "dart:async" show Future, Stream;');
    checkElementText(library, r'''
export 'dart:async' show Future, Stream;
''');
  }

  test_export_typedef() async {
    addLibrarySource('/a.dart', 'typedef F();');
    var library = await checkLibrary('export "a.dart";');
    checkElementText(library, r'''
export 'a.dart';
''');
  }

  test_export_variable() async {
    addLibrarySource('/a.dart', 'var x;');
    var library = await checkLibrary('export "a.dart";');
    checkElementText(library, r'''
export 'a.dart';
''');
  }

  test_export_variable_const() async {
    addLibrarySource('/a.dart', 'const x = 0;');
    var library = await checkLibrary('export "a.dart";');
    checkElementText(library, r'''
export 'a.dart';
''');
  }

  test_export_variable_final() async {
    addLibrarySource('/a.dart', 'final x = 0;');
    var library = await checkLibrary('export "a.dart";');
    checkElementText(library, r'''
export 'a.dart';
''');
  }

  test_exportImport_configurations_useDefault() async {
    context.declaredVariables =
        new DeclaredVariables.fromMap({'dart.library.io': 'false'});
    addLibrarySource('/foo.dart', 'class A {}');
    addLibrarySource('/foo_io.dart', 'class A {}');
    addLibrarySource('/foo_html.dart', 'class A {}');
    addLibrarySource('/bar.dart', r'''
export 'foo.dart'
  if (dart.library.io) 'foo_io.dart'
  if (dart.library.html) 'foo_html.dart';
''');
    var library = await checkLibrary(r'''
import 'bar.dart';
class B extends A {}
''');
    checkElementText(library, r'''
import 'bar.dart';
class B extends A {
}
''');
    var typeA = library.definingCompilationUnit.getType('B').supertype;
    expect(typeA.element.source.shortName, 'foo.dart');
  }

  test_exportImport_configurations_useFirst() async {
    context.declaredVariables = new DeclaredVariables.fromMap(
        {'dart.library.io': 'true', 'dart.library.html': 'true'});
    addLibrarySource('/foo.dart', 'class A {}');
    addLibrarySource('/foo_io.dart', 'class A {}');
    addLibrarySource('/foo_html.dart', 'class A {}');
    addLibrarySource('/bar.dart', r'''
export 'foo.dart'
  if (dart.library.io) 'foo_io.dart'
  if (dart.library.html) 'foo_html.dart';
''');
    var library = await checkLibrary(r'''
import 'bar.dart';
class B extends A {}
''');
    checkElementText(library, r'''
import 'bar.dart';
class B extends A {
}
''');
    var typeA = library.definingCompilationUnit.getType('B').supertype;
    expect(typeA.element.source.shortName, 'foo_io.dart');
  }

  test_exports() async {
    addLibrarySource('/a.dart', 'library a;');
    addLibrarySource('/b.dart', 'library b;');
    var library = await checkLibrary('export "a.dart"; export "b.dart";');
    checkElementText(library, r'''
export 'a.dart';
export 'b.dart';
''');
  }

  test_expr_invalid_typeParameter_asPrefix() async {
    variablesWithNotConstInitializers.add('f');
    var library = await checkLibrary('''
class C<T> {
  final f = T.k;
}
''');
    checkElementText(library, r'''
class C<T> {
  final dynamic f;
}
''');
  }

  test_field_covariant() async {
    var library = await checkLibrary('''
class C {
  covariant int x;
}''');
    checkElementText(library, r'''
class C {
  covariant int x;
}
''');
  }

  test_field_documented() async {
    var library = await checkLibrary('''
class C {
  /**
   * Docs
   */
  var x;
}''');
    checkElementText(library, r'''
class C {
  /**
   * Docs
   */
  dynamic x;
}
''');
  }

  test_field_formal_param_inferred_type_implicit() async {
    var library = await checkLibrary('class C extends D { var v; C(this.v); }'
        ' abstract class D { int get v; }');
    if (isStrongMode) {
      checkElementText(library, r'''
class C extends D {
  int v;
  C(int this.v);
}
abstract class D {
  int get v;
}
''');
    } else {
      checkElementText(library, r'''
class C extends D {
  dynamic v;
  C(dynamic this.v);
}
abstract class D {
  int get v;
}
''');
    }
  }

  test_field_inferred_type_nonStatic_explicit_initialized() async {
    var library = await checkLibrary('class C { num v = 0; }');
    checkElementText(library, r'''
class C {
  num v;
}
''');
  }

  test_field_inferred_type_nonStatic_implicit_initialized() async {
    var library = await checkLibrary('class C { var v = 0; }');
    if (isStrongMode) {
      checkElementText(library, r'''
class C {
  int v;
}
''');
    } else {
      checkElementText(library, r'''
class C {
  dynamic v;
}
''');
    }
  }

  test_field_inferred_type_nonStatic_implicit_uninitialized() async {
    var library = await checkLibrary(
        'class C extends D { var v; } abstract class D { int get v; }');
    if (isStrongMode) {
      checkElementText(library, r'''
class C extends D {
  int v;
}
abstract class D {
  int get v;
}
''');
    } else {
      checkElementText(library, r'''
class C extends D {
  dynamic v;
}
abstract class D {
  int get v;
}
''');
    }
  }

  test_field_inferred_type_static_implicit_initialized() async {
    var library = await checkLibrary('class C { static var v = 0; }');
    if (isStrongMode) {
      checkElementText(library, r'''
class C {
  static int v;
}
''');
    } else {
      checkElementText(library, r'''
class C {
  static dynamic v;
}
''');
    }
  }

  test_field_propagatedType_const_noDep() async {
    var library = await checkLibrary('''
class C {
  static const x = 0;
}''');
    if (isStrongMode) {
      checkElementText(library, r'''
class C {
  static const int x = 0;
}
''');
    } else {
      checkElementText(library, r'''
class C {
  static const dynamic x = 0;
}
''');
    }
  }

  test_field_propagatedType_final_dep_inLib() async {
    addLibrarySource('/a.dart', 'final a = 1;');
    var library = await checkLibrary('''
import "a.dart";
class C {
  final b = a / 2;
}''');
    if (isStrongMode) {
      checkElementText(library, r'''
import 'a.dart';
class C {
  final double b;
}
''');
    } else {
      checkElementText(library, r'''
import 'a.dart';
class C {
  final dynamic b;
}
''');
    }
  }

  test_field_propagatedType_final_dep_inPart() async {
    addSource('/a.dart', 'part of lib; final a = 1;');
    var library = await checkLibrary('''
library lib;
part "a.dart";
class C {
  final b = a / 2;
}''');
    if (isStrongMode) {
      checkElementText(library, r'''
library lib;
part 'a.dart';
class C {
  final double b;
}
--------------------
unit: a.dart

final int a;
''');
    } else {
      checkElementText(library, r'''
library lib;
part 'a.dart';
class C {
  final dynamic b;
}
--------------------
unit: a.dart

final dynamic a;
''');
    }
  }

  test_field_propagatedType_final_noDep_instance() async {
    var library = await checkLibrary('''
class C {
  final x = 0;
}''');
    if (isStrongMode) {
      checkElementText(library, r'''
class C {
  final int x;
}
''');
    } else {
      checkElementText(library, r'''
class C {
  final dynamic x;
}
''');
    }
  }

  test_field_propagatedType_final_noDep_static() async {
    var library = await checkLibrary('''
class C {
  static final x = 0;
}''');
    if (isStrongMode) {
      checkElementText(library, r'''
class C {
  static final int x;
}
''');
    } else {
      checkElementText(library, r'''
class C {
  static final dynamic x;
}
''');
    }
  }

  test_field_static_final_untyped() async {
    var library = await checkLibrary('class C { static final x = 0; }');
    if (isStrongMode) {
      checkElementText(library, r'''
class C {
  static final int x;
}
''');
    } else {
      checkElementText(library, r'''
class C {
  static final dynamic x;
}
''');
    }
  }

  test_field_untyped() async {
    var library = await checkLibrary('class C { var x = 0; }');
    if (isStrongMode) {
      checkElementText(library, r'''
class C {
  int x;
}
''');
    } else {
      checkElementText(library, r'''
class C {
  dynamic x;
}
''');
    }
  }

  test_function_async() async {
    var library = await checkLibrary(r'''
import 'dart:async';
Future f() async {}
''');
    checkElementText(library, r'''
import 'dart:async';
Future<dynamic> f() async {}
''');
  }

  test_function_asyncStar() async {
    var library = await checkLibrary(r'''
import 'dart:async';
Stream f() async* {}
''');
    checkElementText(library, r'''
import 'dart:async';
Stream<dynamic> f() async* {}
''');
  }

  test_function_documented() async {
    var library = await checkLibrary('''
// Extra comment so doc comment offset != 0
/**
 * Docs
 */
f() {}''');
    checkElementText(library, r'''
/**
 * Docs
 */
dynamic f() {}
''');
  }

  test_function_entry_point() async {
    var library = await checkLibrary('main() {}');
    checkElementText(library, r'''
dynamic main() {}
''');
  }

  test_function_entry_point_in_export() async {
    addLibrarySource('/a.dart', 'library a; main() {}');
    var library = await checkLibrary('export "a.dart";');
    checkElementText(library, r'''
export 'a.dart';
''');
  }

  test_function_entry_point_in_export_hidden() async {
    addLibrarySource('/a.dart', 'library a; main() {}');
    var library = await checkLibrary('export "a.dart" hide main;');
    checkElementText(library, r'''
export 'a.dart' hide main;
''');
  }

  test_function_entry_point_in_part() async {
    addSource('/a.dart', 'part of my.lib; main() {}');
    var library = await checkLibrary('library my.lib; part "a.dart";');
    checkElementText(library, r'''
library my.lib;
part 'a.dart';
--------------------
unit: a.dart

dynamic main() {}
''');
  }

  test_function_external() async {
    var library = await checkLibrary('external f();');
    checkElementText(library, r'''
external dynamic f() {}
''');
  }

  test_function_parameter_final() async {
    var library = await checkLibrary('f(final x) {}');
    checkElementText(library, r'''
dynamic f(final dynamic x) {}
''');
  }

  test_function_parameter_kind_named() async {
    var library = await checkLibrary('f({x}) {}');
    checkElementText(library, r'''
dynamic f({dynamic x}) {}
''');
  }

  test_function_parameter_kind_positional() async {
    var library = await checkLibrary('f([x]) {}');
    checkElementText(library, r'''
dynamic f([dynamic x]) {}
''');
  }

  test_function_parameter_kind_required() async {
    var library = await checkLibrary('f(x) {}');
    checkElementText(library, r'''
dynamic f(dynamic x) {}
''');
  }

  test_function_parameter_parameters() async {
    var library = await checkLibrary('f(g(x, y)) {}');
    checkElementText(library, r'''
dynamic f((dynamic, dynamic) → dynamic g) {}
''');
  }

  test_function_parameter_return_type() async {
    var library = await checkLibrary('f(int g()) {}');
    checkElementText(library, r'''
dynamic f(() → int g) {}
''');
  }

  test_function_parameter_return_type_void() async {
    var library = await checkLibrary('f(void g()) {}');
    checkElementText(library, r'''
dynamic f(() → void g) {}
''');
  }

  test_function_parameter_type() async {
    var library = await checkLibrary('f(int i) {}');
    checkElementText(library, r'''
dynamic f(int i) {}
''');
  }

  test_function_parameters() async {
    var library = await checkLibrary('f(x, y) {}');
    checkElementText(library, r'''
dynamic f(dynamic x, dynamic y) {}
''');
  }

  test_function_return_type() async {
    var library = await checkLibrary('int f() => null;');
    checkElementText(library, r'''
int f() {}
''');
  }

  test_function_return_type_implicit() async {
    var library = await checkLibrary('f() => null;');
    checkElementText(library, r'''
dynamic f() {}
''');
  }

  test_function_return_type_void() async {
    var library = await checkLibrary('void f() {}');
    checkElementText(library, r'''
void f() {}
''');
  }

  test_function_type_parameter() async {
    var library = await checkLibrary('T f<T, U>(U u) => null;');
    checkElementText(library, r'''
T f<T, U>(U u) {}
''');
  }

  test_function_type_parameter_with_function_typed_parameter() async {
    var library = await checkLibrary('void f<T, U>(T x(U u)) {}');
    checkElementText(library, r'''
void f<T, U>((U) → T x) {}
''');
  }

  test_function_typed_parameter_implicit() async {
    var library = await checkLibrary('f(g()) => null;');
    expect(
        library
            .definingCompilationUnit.functions[0].parameters[0].hasImplicitType,
        isFalse);
  }

  test_functions() async {
    var library = await checkLibrary('f() {} g() {}');
    checkElementText(library, r'''
dynamic f() {}
dynamic g() {}
''');
  }

  test_futureOr() async {
    var library = await checkLibrary('import "dart:async"; FutureOr<int> x;');
    if (isStrongMode) {
      checkElementText(library, r'''
import 'dart:async';
FutureOr<int> x;
''');
    } else {
      checkElementText(library, r'''
import 'dart:async';
dynamic x;
''');
    }
    var variables = library.definingCompilationUnit.topLevelVariables;
    expect(variables, hasLength(1));
    if (isStrongMode) {
      expect(variables[0].type.toString(), 'FutureOr<int>');
    } else {
      expect(variables[0].type.toString(), 'dynamic');
    }
  }

  test_futureOr_const() async {
    var library =
        await checkLibrary('import "dart:async"; const x = FutureOr;');
    if (isStrongMode) {
      checkElementText(library, r'''
import 'dart:async';
const Type x =
        FutureOr/*location: dart:async;FutureOr*/;
''');
    } else {
      checkElementText(library, r'''
import 'dart:async';
const dynamic x =
        FutureOr/*location: dart:async;FutureOr*/;
''');
    }
    var variables = library.definingCompilationUnit.topLevelVariables;
    expect(variables, hasLength(1));
    var x = variables[0] as ConstTopLevelVariableElementImpl;
    if (isStrongMode) {
      expect(x.type.toString(), 'Type');
    } else {
      expect(x.type.toString(), 'dynamic');
    }
    expect(x.constantInitializer.toString(), 'FutureOr');
  }

  test_futureOr_inferred() async {
    var library = await checkLibrary('''
import "dart:async";
FutureOr<int> f() => null;
var x = f();
var y = x.then((z) => z.asDouble());
''');
    if (isStrongMode) {
      checkElementText(library, r'''
import 'dart:async';
FutureOr<int> x;
dynamic y;
FutureOr<int> f() {}
''');
    } else {
      checkElementText(library, r'''
import 'dart:async';
dynamic x;
dynamic y;
dynamic f() {}
''');
    }
    var variables = library.definingCompilationUnit.topLevelVariables;
    expect(variables, hasLength(2));
    var x = variables[0];
    expect(x.name, 'x');
    var y = variables[1];
    expect(y.name, 'y');
    if (isStrongMode) {
      expect(x.type.toString(), 'FutureOr<int>');
      expect(y.type.toString(), 'dynamic');
    } else {
      expect(x.type.toString(), 'dynamic');
      expect(y.type.toString(), 'dynamic');
    }
  }

  test_generic_gClass_gMethodStatic() async {
    var library = await checkLibrary('''
class C<T, U> {
  static void m<V, W>(V v, W w) {
    void f<X, Y>(V v, W w, X x, Y y) {
    }
  }
}
''');
    checkElementText(library, r'''
class C<T, U> {
  static void m<V, W>(V v, W w) {}
}
''');
  }

  test_genericFunction_asFunctionReturnType() async {
    shouldCompareLibraryElements = false;
    var library = await checkLibrary(r'''
int Function(int a, String b) f() => null;
''');
    checkElementText(library, r'''
(int, String) → int f() {}
''');
  }

  test_genericFunction_asFunctionTypedParameterReturnType() async {
    shouldCompareLibraryElements = false;
    var library = await checkLibrary(r'''
void f(int Function(int a, String b) p(num c)) => null;
''');
    checkElementText(library, r'''
void f((num) → (int, String) → int p) {}
''');
  }

  test_genericFunction_asGenericFunctionReturnType() async {
    shouldCompareLibraryElements = false;
    var library = await checkLibrary(r'''
typedef F = void Function(String a) Function(int b);
''');
    checkElementText(library, r'''
typedef F = (String) → void Function(int b);
''');
  }

  test_genericFunction_asMethodReturnType() async {
    shouldCompareLibraryElements = false;
    var library = await checkLibrary(r'''
class C {
  int Function(int a, String b) m() => null;
}
''');
    checkElementText(library, r'''
class C {
  (int, String) → int m() {}
}
''');
  }

  test_genericFunction_asParameterType() async {
    shouldCompareLibraryElements = false;
    var library = await checkLibrary(r'''
void f(int Function(int a, String b) p) => null;
''');
    checkElementText(library, r'''
void f((int, String) → int p) {}
''');
  }

  test_genericFunction_asTopLevelVariableType() async {
    shouldCompareLibraryElements = false;
    var library = await checkLibrary(r'''
int Function(int a, String b) v;
''');
    checkElementText(library, r'''
(int, String) → int v;
''');
  }

  test_getter_documented() async {
    var library = await checkLibrary('''
// Extra comment so doc comment offset != 0
/**
 * Docs
 */
get x => null;''');
    checkElementText(library, r'''
/**
 * Docs
 */
dynamic get x {}
''');
  }

  test_getter_external() async {
    var library = await checkLibrary('external int get x;');
    checkElementText(library, r'''
external int get x;
''');
  }

  test_getter_inferred_type_nonStatic_implicit_return() async {
    var library = await checkLibrary(
        'class C extends D { get f => null; } abstract class D { int get f; }');
    if (isStrongMode) {
      checkElementText(library, r'''
class C extends D {
  int get f {}
}
abstract class D {
  int get f;
}
''');
    } else {
      checkElementText(library, r'''
class C extends D {
  dynamic get f {}
}
abstract class D {
  int get f;
}
''');
    }
  }

  test_getters() async {
    var library = await checkLibrary('int get x => null; get y => null;');
    checkElementText(library, r'''
int get x {}
dynamic get y {}
''');
  }

  @failingTest
  test_implicitConstructor_named_const() async {
    // TODO(paulberry, scheglov): get this to pass
    var library = await checkLibrary('''
class C {
  final Object x;
  const C.named(this.x);
}
const x = C.named(42);
''');
    checkElementText(library, 'TODO(paulberry, scheglov)');
  }

  test_implicitTopLevelVariable_getterFirst() async {
    var library =
        await checkLibrary('int get x => 0; void set x(int value) {}');
    checkElementText(library, r'''
int get x {}
void set x(int value) {}
''');
  }

  test_implicitTopLevelVariable_setterFirst() async {
    var library =
        await checkLibrary('void set x(int value) {} int get x => 0;');
    checkElementText(library, r'''
void set x(int value) {}
int get x {}
''');
  }

  test_import_configurations_useDefault() async {
    context.declaredVariables =
        new DeclaredVariables.fromMap({'dart.library.io': 'false'});
    addLibrarySource('/foo.dart', 'class A {}');
    addLibrarySource('/foo_io.dart', 'class A {}');
    addLibrarySource('/foo_html.dart', 'class A {}');
    var library = await checkLibrary(r'''
import 'foo.dart'
  if (dart.library.io) 'foo_io.dart'
  if (dart.library.html) 'foo_html.dart';

class B extends A {}
''');
    checkElementText(library, r'''
import 'foo.dart';
class B extends A {
}
''');
    var typeA = library.definingCompilationUnit.getType('B').supertype;
    expect(typeA.element.source.shortName, 'foo.dart');
  }

  test_import_configurations_useFirst() async {
    context.declaredVariables = new DeclaredVariables.fromMap(
        {'dart.library.io': 'true', 'dart.library.html': 'true'});
    addLibrarySource('/foo.dart', 'class A {}');
    addLibrarySource('/foo_io.dart', 'class A {}');
    addLibrarySource('/foo_html.dart', 'class A {}');
    var library = await checkLibrary(r'''
import 'foo.dart'
  if (dart.library.io) 'foo_io.dart'
  if (dart.library.html) 'foo_html.dart';

class B extends A {}
''');
    checkElementText(library, r'''
import 'foo_io.dart';
class B extends A {
}
''');
    var typeA = library.definingCompilationUnit.getType('B').supertype;
    expect(typeA.element.source.shortName, 'foo_io.dart');
  }

  test_import_deferred() async {
    addLibrarySource('/a.dart', 'f() {}');
    var library = await checkLibrary('''
import 'a.dart' deferred as p;
main() {
  p.f();
  }
''');
    checkElementText(library, r'''
import 'a.dart' deferred as p;
dynamic main() {}
''');
  }

  test_import_hide() async {
    addLibrary('dart:async');
    var library = await checkLibrary('''
import 'dart:async' hide Stream, Completer; Future f;
''');
    checkElementText(library, r'''
import 'dart:async' hide Stream, Completer;
Future<dynamic> f;
''');
  }

  test_import_invalidUri_metadata() async {
    allowMissingFiles = true;
    shouldCompareLibraryElements = false;
    var library = await checkLibrary('''
@foo
import '';
''');
    checkElementText(library, r'''
@#invalidConst
import '<unresolved>';
''');
  }

  test_import_multiple_combinators() async {
    addLibrary('dart:async');
    var library = await checkLibrary('''
import "dart:async" hide Stream show Future;
Future f;
''');
    checkElementText(library, r'''
import 'dart:async' hide Stream show Future;
Future<dynamic> f;
''');
  }

  test_import_prefixed() async {
    addLibrarySource('/a.dart', 'library a; class C {}');
    var library = await checkLibrary('import "a.dart" as a; a.C c;');
    checkElementText(library, r'''
import 'a.dart' as a;
C c;
''');
  }

  test_import_self() async {
    var library = await checkLibrary('''
import 'test.dart' as p;
class C {}
class D extends p.C {} // Prevent "unused import" warning
''');
    expect(library.imports, hasLength(2));
    expect(library.imports[0].importedLibrary.location, library.location);
    expect(library.imports[1].importedLibrary.isDartCore, true);
    checkElementText(library, r'''
import 'test.dart' as p;
class C {
}
class D extends C {
}
''');
  }

  test_import_short_absolute() async {
    testFile = '/my/project/bin/test.dart';
    // Note: "/a.dart" resolves differently on Windows vs. Posix.
    var destinationPath =
        resourceProvider.pathContext.fromUri(Uri.parse('/a.dart'));
    addLibrarySource(destinationPath, 'class C {}');
    var library = await checkLibrary('import "/a.dart"; C c;');
    checkElementText(library, r'''
import 'a.dart';
C c;
''');
  }

  test_import_show() async {
    addLibrary('dart:async');
    var library = await checkLibrary('''
import "dart:async" show Future, Stream;
Future f;
Stream s;
''');
    checkElementText(library, r'''
import 'dart:async' show Future, Stream;
Future<dynamic> f;
Stream<dynamic> s;
''');
  }

  test_imports() async {
    addLibrarySource('/a.dart', 'library a; class C {}');
    addLibrarySource('/b.dart', 'library b; class D {}');
    var library =
        await checkLibrary('import "a.dart"; import "b.dart"; C c; D d;');
    checkElementText(library, r'''
import 'a.dart';
import 'b.dart';
C c;
D d;
''');
  }

  @failingTest
  void test_infer_generic_typedef_complex() async {
    // TODO(paulberry, scheglov): get this test to pass.
    var library = await checkLibrary('''
typedef F<T> = D<T,U> Function<U>();
class C<V> {
  const C(F<V> f);
}
class D<T,U> {}
D<int,U> f<U>() => null;
const x = const C(f);
''');
    checkElementText(library, '''TODO(paulberry, scheglov)''');
  }

  void test_infer_generic_typedef_simple() async {
    var library = await checkLibrary('''
typedef F = D<T> Function<T>();
class C {
  const C(F f);
}
class D<T> {}
D<T> f<T>() => null;
const x = const C(f);
''');
    if (isStrongMode) {
      checkElementText(library, '''
typedef F = D<T> Function<T>();
class C {
  const C(<T>() → D<T> f);
}
class D<T> {
}
const C x = const
        C/*location: test.dart;C*/(
        f/*location: test.dart;f*/);
D<T> f<T>() {}
''');
    } else {
      checkElementText(library, '''
typedef F = D<T> Function<T>();
class C {
  const C(<T>() → D<T> f);
}
class D<T> {
}
const dynamic x = const
        C/*location: test.dart;C*/(
        f/*location: test.dart;f*/);
D<T> f<T>() {}
''');
    }
  }

  test_infer_instanceCreation_fromArguments() async {
    var library = await checkLibrary('''
class A {}

class B extends A {}

class S<T extends A> {
  S(T _);
}

var s = new S(new B());
''');
    if (isStrongMode) {
      checkElementText(library, '''
class A {
}
class B extends A {
}
class S<T extends A> {
  S(T _);
}
S<B> s;
''');
    } else {
      checkElementText(library, '''
class A {
}
class B extends A {
}
class S<T extends A> {
  S(T _);
}
dynamic s;
''');
    }
  }

  test_infer_property_set() async {
    var library = await checkLibrary('''
class A {
  B b;
}
class B {
  C get c => null;
  void set c(C value) {}
}
class C {}
class D extends C {}
var a = new A();
var x = a.b.c ??= new D();
''');
    if (isStrongMode) {
      checkElementText(library, '''
class A {
  B b;
}
class B {
  C get c {}
  void set c(C value) {}
}
class C {
}
class D extends C {
}
A a;
C x;
''');
    } else {
      checkElementText(library, '''
class A {
  B b;
}
class B {
  C get c {}
  void set c(C value) {}
}
class C {
}
class D extends C {
}
dynamic a;
dynamic x;
''');
    }
  }

  test_inference_issue_32394() async {
    // Test the type inference involed in dartbug.com/32394
    var library = await checkLibrary('''
var x = y.map((a) => a.toString());
var y = [3];
var z = x.toList();
''');
    if (isStrongMode) {
      checkElementText(library, '''
Iterable<String> x;
List<int> y;
List<String> z;
''');
    } else {
      checkElementText(library, '''
dynamic x;
dynamic y;
dynamic z;
''');
    }
  }

  test_inference_map() async {
    var library = await checkLibrary('''
class C {
  int p;
}
var x = <C>[];
var y = x.map((c) => c.p);
''');
    if (isStrongMode) {
      checkElementText(library, '''
class C {
  int p;
}
List<C> x;
Iterable<int> y;
''');
    } else {
      checkElementText(library, '''
class C {
  int p;
}
dynamic x;
dynamic y;
''');
    }
  }

  test_inferred_function_type_for_variable_in_generic_function() async {
    // In the code below, `x` has an inferred type of `() => int`, with 2
    // (unused) type parameters from the enclosing top level function.
    var library = await checkLibrary('''
f<U, V>() {
  var x = () => 0;
}
''');
    checkElementText(library, r'''
dynamic f<U, V>() {}
''');
  }

  test_inferred_function_type_in_generic_class_constructor() async {
    // In the code below, `() => () => 0` has an inferred return type of
    // `() => int`, with 2 (unused) type parameters from the enclosing class.
    var library = await checkLibrary('''
class C<U, V> {
  final x;
  C() : x = (() => () => 0);
}
''');
    checkElementText(library, r'''
class C<U, V> {
  final dynamic x;
  C();
}
''');
  }

  test_inferred_function_type_in_generic_class_getter() async {
    // In the code below, `() => () => 0` has an inferred return type of
    // `() => int`, with 2 (unused) type parameters from the enclosing class.
    var library = await checkLibrary('''
class C<U, V> {
  get x => () => () => 0;
}
''');
    checkElementText(library, r'''
class C<U, V> {
  dynamic get x {}
}
''');
  }

  test_inferred_function_type_in_generic_class_in_generic_method() async {
    // In the code below, `() => () => 0` has an inferred return type of
    // `() => int`, with 3 (unused) type parameters from the enclosing class
    // and method.
    var library = await checkLibrary('''
class C<T> {
  f<U, V>() {
    print(() => () => 0);
  }
}
''');
    checkElementText(library, r'''
class C<T> {
  dynamic f<U, V>() {}
}
''');
  }

  test_inferred_function_type_in_generic_class_setter() async {
    // In the code below, `() => () => 0` has an inferred return type of
    // `() => int`, with 2 (unused) type parameters from the enclosing class.
    var library = await checkLibrary('''
class C<U, V> {
  void set x(value) {
    print(() => () => 0);
  }
}
''');
    checkElementText(library, r'''
class C<U, V> {
  void set x(dynamic value) {}
}
''');
  }

  test_inferred_function_type_in_generic_closure() async {
    if (!isStrongMode) {
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
    var library = await checkLibrary('''
f<T>() {
  print(/*<U, V>*/() => () => 0);
}
''');
    if (isStrongMode) {
      checkElementText(library, r'''
dynamic f<T>() {}
''');
    } else {
      checkElementText(library, r'''
''');
    }
  }

  test_inferred_generic_function_type_in_generic_closure() async {
    if (!isStrongMode) {
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
    var library = await checkLibrary('''
f<T>() {
  print(/*<U, V>*/() => /*<W, X, Y, Z>*/() => 0);
}
''');
    if (isStrongMode) {
      checkElementText(library, r'''
dynamic f<T>() {}
''');
    } else {
      checkElementText(library, r'''
''');
    }
  }

  test_inferred_type_is_typedef() async {
    var library = await checkLibrary('typedef int F(String s);'
        ' class C extends D { var v; }'
        ' abstract class D { F get v; }');
    if (isStrongMode) {
      checkElementText(library, r'''
typedef F = int Function(String s);
class C extends D {
  (String) → int v;
}
abstract class D {
  (String) → int get v;
}
''');
    } else {
      checkElementText(library, r'''
typedef F = int Function(String s);
class C extends D {
  dynamic v;
}
abstract class D {
  (String) → int get v;
}
''');
    }
  }

  test_inferred_type_refers_to_bound_type_param() async {
    var library = await checkLibrary('''
class C<T> extends D<int, T> {
  var v;
}
abstract class D<U, V> {
  Map<V, U> get v;
}
''');
    if (isStrongMode) {
      checkElementText(library, r'''
class C<T> extends D<int, T> {
  Map<T, int> v;
}
abstract class D<U, V> {
  Map<V, U> get v;
}
''');
    } else {
      checkElementText(library, r'''
class C<T> extends D<int, T> {
  dynamic v;
}
abstract class D<U, V> {
  Map<V, U> get v;
}
''');
    }
  }

  test_inferred_type_refers_to_function_typed_param_of_typedef() async {
    var library = await checkLibrary('''
typedef void F(int g(String s));
h(F f) => null;
var v = h(/*info:INFERRED_TYPE_CLOSURE*/(y) {});
''');
    checkElementText(library, r'''
typedef F = void Function((String) → int g);
dynamic v;
dynamic h(((String) → int) → void f) {}
''');
  }

  test_inferred_type_refers_to_function_typed_parameter_type_generic_class() async {
    var library = await checkLibrary('''
class C<T, U> extends D<U, int> {
  void f(int x, g) {}
}
abstract class D<V, W> {
  void f(int x, W g(V s));
}''');
    if (isStrongMode) {
      checkElementText(library, r'''
class C<T, U> extends D<U, int> {
  void f(int x, (U) → int g) {}
}
abstract class D<V, W> {
  void f(int x, (V) → W g);
}
''');
    } else {
      checkElementText(library, r'''
class C<T, U> extends D<U, int> {
  void f(int x, dynamic g) {}
}
abstract class D<V, W> {
  void f(int x, (V) → W g);
}
''');
    }
  }

  test_inferred_type_refers_to_function_typed_parameter_type_other_lib() async {
    addLibrarySource('/a.dart', '''
import 'b.dart';
abstract class D extends E {}
''');
    addLibrarySource('/b.dart', '''
abstract class E {
  void f(int x, int g(String s));
}
''');
    var library = await checkLibrary('''
import 'a.dart';
class C extends D {
  void f(int x, g) {}
}
''');
    if (isStrongMode) {
      checkElementText(library, r'''
import 'a.dart';
class C extends D {
  void f(int x, (String) → int g) {}
}
''');
    } else {
      checkElementText(library, r'''
import 'a.dart';
class C extends D {
  void f(int x, dynamic g) {}
}
''');
    }
  }

  test_inferred_type_refers_to_method_function_typed_parameter_type() async {
    var library = await checkLibrary('class C extends D { void f(int x, g) {} }'
        ' abstract class D { void f(int x, int g(String s)); }');
    if (isStrongMode) {
      checkElementText(library, r'''
class C extends D {
  void f(int x, (String) → int g) {}
}
abstract class D {
  void f(int x, (String) → int g);
}
''');
    } else {
      checkElementText(library, r'''
class C extends D {
  void f(int x, dynamic g) {}
}
abstract class D {
  void f(int x, (String) → int g);
}
''');
    }
  }

  test_inferred_type_refers_to_nested_function_typed_param() async {
    var library = await checkLibrary('''
f(void g(int x, void h())) => null;
var v = f((x, y) {});
''');
    checkElementText(library, r'''
dynamic v;
dynamic f((int, () → void) → void g) {}
''');
  }

  test_inferred_type_refers_to_nested_function_typed_param_named() async {
    var library = await checkLibrary('''
f({void g(int x, void h())}) => null;
var v = f(g: (x, y) {});
''');
    checkElementText(library, r'''
dynamic v;
dynamic f({(int, () → void) → void g}) {}
''');
  }

  test_inferred_type_refers_to_setter_function_typed_parameter_type() async {
    var library = await checkLibrary('class C extends D { void set f(g) {} }'
        ' abstract class D { void set f(int g(String s)); }');
    if (isStrongMode) {
      checkElementText(library, r'''
class C extends D {
  void set f((String) → int g) {}
}
abstract class D {
  void set f((String) → int g);
}
''');
    } else {
      checkElementText(library, r'''
class C extends D {
  void set f(dynamic g) {}
}
abstract class D {
  void set f((String) → int g);
}
''');
    }
  }

  test_inferredType_definedInSdkLibraryPart() async {
    addSource('/a.dart', r'''
import 'dart:async';
class A {
  m(Stream p) {}
}
''');
    LibraryElement library = await checkLibrary(r'''
import 'a.dart';
class B extends A {
  m(p) {}
}
  ''');
    if (isStrongMode) {
      checkElementText(library, r'''
import 'a.dart';
class B extends A {
  dynamic m(Stream<dynamic> p) {}
}
''');
    } else {
      checkElementText(library, r'''
import 'a.dart';
class B extends A {
  dynamic m(dynamic p) {}
}
''');
    }
    ClassElement b = library.definingCompilationUnit.types[0];
    ParameterElement p = b.methods[0].parameters[0];
    // This test should verify that we correctly record inferred types,
    // when the type is defined in a part of an SDK library. So, test that
    // the type is actually in a part.
    Element streamElement = p.type.element;
    if (streamElement is ClassElement) {
      expect(streamElement.source, isNot(streamElement.library.source));
    }
  }

  test_inferredType_implicitCreation() async {
    shouldCompareLibraryElements = false;
    var library = await checkLibrary(r'''
class A {
  A();
  A.named();
}
var a1 = A();
var a2 = A.named();
''');
    if (isStrongMode) {
      checkElementText(library, r'''
class A {
  A();
  A.named();
}
A a1;
A a2;
''');
    } else {
      checkElementText(library, r'''
class A {
  A();
  A.named();
}
dynamic a1;
dynamic a2;
''');
    }
  }

  test_inferredType_implicitCreation_prefixed() async {
    shouldCompareLibraryElements = false;
    addLibrarySource('/foo.dart', '''
class A {
  A();
  A.named();
}
''');
    var library = await checkLibrary('''
import 'foo.dart' as foo;
var a1 = foo.A();
var a2 = foo.A.named();
''');
    if (isStrongMode) {
      checkElementText(library, r'''
import 'foo.dart' as foo;
A a1;
A a2;
''');
    } else {
      checkElementText(library, r'''
import 'foo.dart' as foo;
dynamic a1;
dynamic a2;
''');
    }
  }

  test_inferredType_usesSyntheticFunctionType_functionTypedParam() async {
    // AnalysisContext does not set the enclosing element for the synthetic
    // FunctionElement created for the [f, g] type argument.
    shouldCompareLibraryElements = false;
    var library = await checkLibrary('''
int f(int x(String y)) => null;
String g(int x(String y)) => null;
var v = [f, g];
''');
    if (isStrongMode) {
      checkElementText(library, r'''
List<((String) → int) → Object> v;
int f((String) → int x) {}
String g((String) → int x) {}
''');
    } else {
      checkElementText(library, r'''
dynamic v;
int f((String) → int x) {}
String g((String) → int x) {}
''');
    }
  }

  test_inheritance_errors() async {
    var library = await checkLibrary('''
abstract class A {
  int m();
}

abstract class B {
  String m();
}

abstract class C implements A, B {}

abstract class D extends C {
  var f;
}
''');
    checkElementText(library, r'''
abstract class A {
  int m();
}
abstract class B {
  String m();
}
abstract class C implements A, B {
}
abstract class D extends C {
  dynamic f;
}
''');
  }

  test_initializer_executable_with_return_type_from_closure() async {
    var library = await checkLibrary('var v = () => 0;');
    if (isStrongMode) {
      checkElementText(library, r'''
() → int v;
''');
    } else {
      checkElementText(library, r'''
dynamic v;
''');
    }
  }

  test_initializer_executable_with_return_type_from_closure_await_dynamic() async {
    var library = await checkLibrary('var v = (f) async => await f;');
    if (isStrongMode) {
      checkElementText(library, r'''
(dynamic) → Future<dynamic> v;
''');
    } else {
      checkElementText(library, r'''
dynamic v;
''');
    }
  }

  test_initializer_executable_with_return_type_from_closure_await_future3_int() async {
    var library = await checkLibrary(r'''
import 'dart:async';
var v = (Future<Future<Future<int>>> f) async => await f;
''');
    if (isStrongMode) {
      if (isSharedFrontEnd) {
        checkElementText(library, r'''
import 'dart:async';
(Future<Future<Future<int>>>) → Future<Future<int>> v;
''');
      } else {
        // The analyzer type system over-flattens - see dartbug.com/31887
        checkElementText(library, r'''
import 'dart:async';
(Future<Future<Future<int>>>) → Future<int> v;
''');
      }
    } else {
      checkElementText(library, r'''
import 'dart:async';
dynamic v;
''');
    }
  }

  test_initializer_executable_with_return_type_from_closure_await_future_int() async {
    var library = await checkLibrary(r'''
import 'dart:async';
var v = (Future<int> f) async => await f;
''');
    if (isStrongMode) {
      checkElementText(library, r'''
import 'dart:async';
(Future<int>) → Future<int> v;
''');
    } else {
      checkElementText(library, r'''
import 'dart:async';
dynamic v;
''');
    }
  }

  test_initializer_executable_with_return_type_from_closure_await_future_noArg() async {
    var library = await checkLibrary(r'''
import 'dart:async';
var v = (Future f) async => await f;
''');
    if (isStrongMode) {
      checkElementText(library, r'''
import 'dart:async';
(Future<dynamic>) → Future<dynamic> v;
''');
    } else {
      checkElementText(library, r'''
import 'dart:async';
dynamic v;
''');
    }
  }

  test_initializer_executable_with_return_type_from_closure_field() async {
    var library = await checkLibrary('''
class C {
  var v = () => 0;
}
''');
    if (isStrongMode) {
      checkElementText(library, r'''
class C {
  () → int v;
}
''');
    } else {
      checkElementText(library, r'''
class C {
  dynamic v;
}
''');
    }
  }

  test_initializer_executable_with_return_type_from_closure_local() async {
    var library = await checkLibrary('''
void f() {
  int u = 0;
  var v = () => 0;
}
''');
    checkElementText(library, r'''
void f() {}
''');
  }

  test_instantiateToBounds_boundRefersToEarlierTypeArgument() async {
    var library = await checkLibrary('''
class C<S extends num, T extends C<S, T>> {}
C c;
''');
    if (isStrongMode) {
      checkElementText(library, r'''
class C<S extends num, T extends C<S, T>> {
}
C<num, C<num, dynamic>> c;
''');
    } else {
      checkElementText(library, r'''
class C<S extends num, T extends C<S, T>> {
}
C<dynamic, dynamic> c;
''');
    }
  }

  test_instantiateToBounds_boundRefersToItself() async {
    var library = await checkLibrary('''
class C<T extends C<T>> {}
C c;
var c2 = new C();
class B {
  var c3 = new C();
}
''');
    if (isStrongMode) {
      checkElementText(library, r'''
class C<T extends C<T>> {
}
class B {
  C<C<dynamic>> c3;
}
C<C<dynamic>> c;
C<C<dynamic>> c2;
''');
    } else {
      checkElementText(library, r'''
class C<T extends C<T>> {
}
class B {
  dynamic c3;
}
C<dynamic> c;
dynamic c2;
''');
    }
  }

  test_instantiateToBounds_boundRefersToLaterTypeArgument() async {
    var library = await checkLibrary('''
class C<T extends C<T, U>, U extends num> {}
C c;
''');
    if (isStrongMode) {
      checkElementText(library, r'''
class C<T extends C<T, U>, U extends num> {
}
C<C<dynamic, num>, num> c;
''');
    } else {
      checkElementText(library, r'''
class C<T extends C<T, U>, U extends num> {
}
C<dynamic, dynamic> c;
''');
    }
  }

  test_instantiateToBounds_functionTypeAlias_simple() async {
    var library = await checkLibrary('''
typedef F<T extends num>(T p);
F f;
''');
    if (isStrongMode) {
      checkElementText(library, r'''
typedef F<T extends num> = dynamic Function(T p);
(num) → dynamic f;
''');
    } else {
      checkElementText(library, r'''
typedef F<T extends num> = dynamic Function(T p);
(dynamic) → dynamic f;
''');
    }
  }

  test_instantiateToBounds_simple() async {
    var library = await checkLibrary('''
class C<T extends num> {}
C c;
''');
    if (isStrongMode) {
      checkElementText(library, r'''
class C<T extends num> {
}
C<num> c;
''');
    } else {
      checkElementText(library, r'''
class C<T extends num> {
}
C<dynamic> c;
''');
    }
  }

  test_invalid_annotation_prefixed_constructor() async {
    shouldCompareLibraryElements = false;
    addLibrarySource('/a.dart', r'''
class C {
  const C.named();
}
''');
    var library = await checkLibrary('''
import "a.dart" as a;
@a.C.named
class D {}
''');
    checkElementText(library, r'''
import 'a.dart' as a;
@#invalidConst
class D {
}
''');
  }

  test_invalid_annotation_unprefixed_constructor() async {
    shouldCompareLibraryElements = false;
    addLibrarySource('/a.dart', r'''
class C {
  const C.named();
}
''');
    var library = await checkLibrary('''
import "a.dart";
@C.named
class D {}
''');
    checkElementText(library, r'''
import 'a.dart';
@#invalidConst
class D {
}
''');
  }

  test_invalid_importPrefix_asTypeArgument() async {
    var library = await checkLibrary('''
import 'dart:async' as ppp;
class C {
  List<ppp> v;
}
''');
    checkElementText(library, r'''
import 'dart:async' as ppp;
class C {
  List<dynamic> v;
}
''');
  }

  test_invalid_nameConflict_imported() async {
    shouldCompareLibraryElements = false;
    namesThatCannotBeResolved.add('V');
    addLibrarySource('/a.dart', 'V() {}');
    addLibrarySource('/b.dart', 'V() {}');
    var library = await checkLibrary('''
import 'a.dart';
import 'b.dart';
foo([p = V]) {}
''');
    checkElementText(library, r'''
import 'a.dart';
import 'b.dart';
dynamic foo([dynamic p = #invalidConst]) {}
''');
  }

  test_invalid_nameConflict_imported_exported() async {
    shouldCompareLibraryElements = false;
    namesThatCannotBeResolved.add('V');
    addLibrarySource('/a.dart', 'V() {}');
    addLibrarySource('/b.dart', 'V() {}');
    addLibrarySource('/c.dart', r'''
export 'a.dart';
export 'b.dart';
''');
    var library = await checkLibrary('''
import 'c.dart';
foo([p = V]) {}
''');
    checkElementText(library, r'''
import 'c.dart';
dynamic foo([dynamic p = #invalidConst]) {}
''');
  }

  test_invalid_nameConflict_local() async {
    shouldCompareLibraryElements = false;
    namesThatCannotBeResolved.add('V');
    var library = await checkLibrary('''
foo([p = V]) {}
V() {}
var V;
''');
    checkElementText(library, r'''
dynamic V;
dynamic foo([dynamic p = #invalidConst]) {}
dynamic V() {}
''');
  }

  test_invalid_setterParameter_fieldFormalParameter() async {
    var library = await checkLibrary('''
class C {
  int foo;
  void set bar(this.foo) {}
}
''');
    checkElementText(library, r'''
class C {
  int foo;
  void set bar(dynamic this.foo) {}
}
''');
  }

  test_invalid_setterParameter_fieldFormalParameter_self() async {
    var library = await checkLibrary('''
class C {
  set x(this.x) {}
}
''');
    if (isStrongMode) {
      checkElementText(library, r'''
class C {
  void set x(dynamic this.x) {}
}
''');
    } else {
      checkElementText(library, r'''
class C {
  dynamic set x(dynamic this.x) {}
}
''');
    }
  }

  test_invalidUri_part_emptyUri() async {
    allowMissingFiles = true;
    shouldCompareLibraryElements = false;
    var library = await checkLibrary(r'''
part '';
class B extends A {}
''');
    checkElementText(library, r'''
part '<unresolved>';
class B {
}
--------------------
unit: null

''');
  }

  test_invalidUris() async {
    allowMissingFiles = true;
    shouldCompareLibraryElements = false;
    var library = await checkLibrary(r'''
import '[invalid uri]';
import '[invalid uri]:foo.dart';
import 'a1.dart';
import '[invalid uri]';
import '[invalid uri]:foo.dart';

export '[invalid uri]';
export '[invalid uri]:foo.dart';
export 'a2.dart';
export '[invalid uri]';
export '[invalid uri]:foo.dart';

part '[invalid uri]';
part 'a3.dart';
part '[invalid uri]';
''');
    checkElementText(library, r'''
import '<unresolved>';
import '<unresolved>';
import 'a1.dart';
import '<unresolved>';
import '<unresolved>';
export '<unresolved>';
export '<unresolved>';
export 'a2.dart';
export '<unresolved>';
export '<unresolved>';
part '<unresolved>';
part 'a3.dart';
part '<unresolved>';
--------------------
unit: null

--------------------
unit: a3.dart

--------------------
unit: null

''');
  }

  test_library() async {
    var library = await checkLibrary('');
    checkElementText(library, r'''
''');
  }

  test_library_documented_lines() async {
    var library = await checkLibrary('''
/// aaa
/// bbb
library test;
''');
    checkElementText(library, r'''
/// aaa
/// bbb
library test;
''');
  }

  test_library_documented_stars() async {
    var library = await checkLibrary('''
/**
 * aaa
 * bbb
 */
library test;''');
    checkElementText(library, r'''
/**
 * aaa
 * bbb
 */
library test;
''');
  }

  test_library_name_with_spaces() async {
    var library = await checkLibrary('library foo . bar ;');
    checkElementText(library, r'''
library foo.bar;
''');
  }

  test_library_named() async {
    var library = await checkLibrary('library foo.bar;');
    checkElementText(library, r'''
library foo.bar;
''');
  }

  test_localFunctions() async {
    var library = await checkLibrary(r'''
f() {
  f1() {}
  {
    f2() {}
  }
}
''');
    checkElementText(library, r'''
dynamic f() {}
''');
  }

  test_localFunctions_inConstructor() async {
    var library = await checkLibrary(r'''
class C {
  C() {
    f() {}
  }
}
''');
    checkElementText(library, r'''
class C {
  C();
}
''');
  }

  test_localFunctions_inMethod() async {
    var library = await checkLibrary(r'''
class C {
  m() {
    f() {}
  }
}
''');
    checkElementText(library, r'''
class C {
  dynamic m() {}
}
''');
  }

  test_localFunctions_inTopLevelGetter() async {
    var library = await checkLibrary(r'''
get g {
  f() {}
}
''');
    checkElementText(library, r'''
dynamic get g {}
''');
  }

  test_localLabels_inConstructor() async {
    var library = await checkLibrary(r'''
class C {
  C() {
    aaa: while (true) {}
    bbb: switch (42) {
      ccc: case 0:
        break;
    }
  }
}
''', allowErrors: true);
    checkElementText(library, r'''
class C {
  C();
}
''');
  }

  test_localLabels_inMethod() async {
    var library = await checkLibrary(r'''
class C {
  m() {
    aaa: while (true) {}
    bbb: switch (42) {
      ccc: case 0:
        break;
    }
  }
}
''', allowErrors: true);
    checkElementText(library, r'''
class C {
  dynamic m() {}
}
''');
  }

  test_localLabels_inTopLevelFunction() async {
    var library = await checkLibrary(r'''
main() {
  aaa: while (true) {}
  bbb: switch (42) {
    ccc: case 0:
      break;
  }
}
''', allowErrors: true);
    checkElementText(library, r'''
dynamic main() {}
''');
  }

  test_main_class() async {
    var library = await checkLibrary('class main {}');
    checkElementText(library, r'''
class main {
}
''');
  }

  test_main_class_alias() async {
    var library =
        await checkLibrary('class main = C with D; class C {} class D {}');
    checkElementText(library, r'''
class alias main extends C with D {
  synthetic main() = C;
}
class C {
}
class D {
}
''');
  }

  test_main_class_alias_via_export() async {
    addLibrarySource('/a.dart', 'class main = C with D; class C {} class D {}');
    var library = await checkLibrary('export "a.dart";');
    checkElementText(library, r'''
export 'a.dart';
''');
  }

  test_main_class_via_export() async {
    addLibrarySource('/a.dart', 'class main {}');
    var library = await checkLibrary('export "a.dart";');
    checkElementText(library, r'''
export 'a.dart';
''');
  }

  test_main_getter() async {
    var library = await checkLibrary('get main => null;');
    checkElementText(library, r'''
dynamic get main {}
''');
  }

  test_main_getter_via_export() async {
    addLibrarySource('/a.dart', 'get main => null;');
    var library = await checkLibrary('export "a.dart";');
    checkElementText(library, r'''
export 'a.dart';
''');
  }

  test_main_typedef() async {
    var library = await checkLibrary('typedef main();');
    checkElementText(library, r'''
typedef main = dynamic Function();
''');
  }

  test_main_typedef_via_export() async {
    addLibrarySource('/a.dart', 'typedef main();');
    var library = await checkLibrary('export "a.dart";');
    checkElementText(library, r'''
export 'a.dart';
''');
  }

  test_main_variable() async {
    var library = await checkLibrary('var main;');
    checkElementText(library, r'''
dynamic main;
''');
  }

  test_main_variable_via_export() async {
    addLibrarySource('/a.dart', 'var main;');
    var library = await checkLibrary('export "a.dart";');
    checkElementText(library, r'''
export 'a.dart';
''');
  }

  test_member_function_async() async {
    var library = await checkLibrary(r'''
import 'dart:async';
class C {
  Future f() async {}
}
''');
    checkElementText(library, r'''
import 'dart:async';
class C {
  Future<dynamic> f() async {}
}
''');
  }

  test_member_function_asyncStar() async {
    var library = await checkLibrary(r'''
import 'dart:async';
class C {
  Stream f() async* {}
}
''');
    checkElementText(library, r'''
import 'dart:async';
class C {
  Stream<dynamic> f() async* {}
}
''');
  }

  test_member_function_syncStar() async {
    var library = await checkLibrary(r'''
class C {
  Iterable<int> f() sync* {
    yield 42;
  }
}
''');
    checkElementText(library, r'''
class C {
  Iterable<int> f() sync* {}
}
''');
  }

  test_metadata_classDeclaration() async {
    var library = await checkLibrary(r'''
const a = null;
const b = null;
@a
@b
class C {}''');
    checkElementText(library, r'''
@
        a/*location: test.dart;a?*/
@
        b/*location: test.dart;b?*/
class C {
}
const dynamic a = null;
const dynamic b = null;
''');
  }

  test_metadata_classTypeAlias() async {
    var library = await checkLibrary(
        'const a = null; @a class C = D with E; class D {} class E {}');
    checkElementText(library, r'''
@
        a/*location: test.dart;a?*/
class alias C extends D with E {
  synthetic C() = D;
}
class D {
}
class E {
}
const dynamic a = null;
''');
  }

  test_metadata_constructor_call_named() async {
    var library = await checkLibrary('''
class A {
  const A.named();
}
@A.named()
class C {}
''');
    checkElementText(library, r'''
class A {
  const A.named();
}
@
        A/*location: test.dart;A*/.
        named/*location: test.dart;A;named*/()
class C {
}
''');
  }

  test_metadata_constructor_call_named_prefixed() async {
    addLibrarySource('/foo.dart', 'class A { const A.named(); }');
    var library = await checkLibrary('''
import 'foo.dart' as foo;
@foo.A.named()
class C {}
''');
    checkElementText(library, r'''
import 'foo.dart' as foo;
@
        A/*location: foo.dart;A*/.
        named/*location: foo.dart;A;named*/()
class C {
}
''');
  }

  test_metadata_constructor_call_unnamed() async {
    var library = await checkLibrary('class A { const A(); } @A() class C {}');
    checkElementText(library, r'''
class A {
  const A();
}
@
        A/*location: test.dart;A*/()
class C {
}
''');
  }

  test_metadata_constructor_call_unnamed_prefixed() async {
    addLibrarySource('/foo.dart', 'class A { const A(); }');
    var library =
        await checkLibrary('import "foo.dart" as foo; @foo.A() class C {}');
    checkElementText(library, r'''
import 'foo.dart' as foo;
@
        A/*location: foo.dart;A*/()
class C {
}
''');
  }

  test_metadata_constructor_call_with_args() async {
    var library =
        await checkLibrary('class A { const A(x); } @A(null) class C {}');
    checkElementText(library, r'''
class A {
  const A(dynamic x);
}
@
        A/*location: test.dart;A*/(null)
class C {
}
''');
  }

  test_metadata_constructorDeclaration_named() async {
    var library =
        await checkLibrary('const a = null; class C { @a C.named(); }');
    checkElementText(library, r'''
class C {
  @
        a/*location: test.dart;a?*/
  C.named();
}
const dynamic a = null;
''');
  }

  test_metadata_constructorDeclaration_unnamed() async {
    var library = await checkLibrary('const a = null; class C { @a C(); }');
    checkElementText(library, r'''
class C {
  @
        a/*location: test.dart;a?*/
  C();
}
const dynamic a = null;
''');
  }

  test_metadata_enumDeclaration() async {
    var library = await checkLibrary('const a = null; @a enum E { v }');
    checkElementText(library, r'''
@
        a/*location: test.dart;a?*/
enum E {
  synthetic final int index;
  synthetic static const List<E> values;
  static const E v;
  String toString() {}
}
const dynamic a = null;
''');
  }

  test_metadata_exportDirective() async {
    addLibrarySource('/foo.dart', '');
    var library = await checkLibrary('@a export "foo.dart"; const a = null;');
    checkElementText(library, r'''
@
        a/*location: test.dart;a?*/
export 'foo.dart';
const dynamic a = null;
''');
  }

  test_metadata_fieldDeclaration() async {
    var library = await checkLibrary('const a = null; class C { @a int x; }');
    checkElementText(library, r'''
class C {
  @
        a/*location: test.dart;a?*/
  int x;
}
const dynamic a = null;
''');
  }

  test_metadata_fieldFormalParameter() async {
    var library = await checkLibrary('''
const a = null;
class C {
  var x;
  C(@a this.x);
}
''');
    checkElementText(library, r'''
class C {
  dynamic x;
  C(@
        a/*location: test.dart;a?*/ dynamic this.x);
}
const dynamic a = null;
''');
  }

  test_metadata_fieldFormalParameter_withDefault() async {
    var library = await checkLibrary(
        'const a = null; class C { var x; C([@a this.x = null]); }');
    checkElementText(library, r'''
class C {
  dynamic x;
  C([@
        a/*location: test.dart;a?*/ dynamic this.x]);
}
const dynamic a = null;
''');
  }

  test_metadata_functionDeclaration_function() async {
    var library = await checkLibrary('''
const a = null;
@a
f() {}
''');
    checkElementText(library, r'''
const dynamic a = null;
@
        a/*location: test.dart;a?*/
dynamic f() {}
''');
  }

  test_metadata_functionDeclaration_getter() async {
    var library = await checkLibrary('const a = null; @a get f => null;');
    checkElementText(library, r'''
const dynamic a = null;
@
        a/*location: test.dart;a?*/
dynamic get f {}
''');
  }

  test_metadata_functionDeclaration_setter() async {
    var library = await checkLibrary('const a = null; @a set f(value) {}');
    if (isStrongMode) {
      checkElementText(library, r'''
const dynamic a = null;
@
        a/*location: test.dart;a?*/
void set f(dynamic value) {}
''');
    } else {
      checkElementText(library, r'''
const dynamic a = null;
@
        a/*location: test.dart;a?*/
dynamic set f(dynamic value) {}
''');
    }
  }

  test_metadata_functionTypeAlias() async {
    var library = await checkLibrary('const a = null; @a typedef F();');
    checkElementText(library, r'''
@
        a/*location: test.dart;a?*/
typedef F = dynamic Function();
const dynamic a = null;
''');
  }

  test_metadata_functionTypedFormalParameter() async {
    var library = await checkLibrary('const a = null; f(@a g()) {}');
    checkElementText(library, r'''
const dynamic a = null;
dynamic f(@
        a/*location: test.dart;a?*/ () → dynamic g) {}
''');
  }

  test_metadata_functionTypedFormalParameter_withDefault() async {
    var library = await checkLibrary('const a = null; f([@a g() = null]) {}');
    checkElementText(library, r'''
const dynamic a = null;
dynamic f([@
        a/*location: test.dart;a?*/ () → dynamic g]) {}
''');
  }

  test_metadata_importDirective() async {
    addLibrarySource('/foo.dart', 'const b = null;');
    var library = await checkLibrary('@a import "foo.dart"; const a = b;');
    checkElementText(library, r'''
@
        a/*location: test.dart;a?*/
import 'foo.dart';
const dynamic a =
        b/*location: foo.dart;b?*/;
''');
  }

  test_metadata_invalid_classDeclaration() async {
    shouldCompareLibraryElements = false;
    var library = await checkLibrary('f(_) {} @f(42) class C {}');
    checkElementText(library, r'''
@#invalidConst
class C {
}
dynamic f(dynamic _) {}
''');
  }

  test_metadata_libraryDirective() async {
    var library = await checkLibrary('@a library L; const a = null;');
    checkElementText(library, r'''
@
        a/*location: test.dart;a?*/
library L;
const dynamic a = null;
''');
  }

  test_metadata_methodDeclaration_getter() async {
    var library =
        await checkLibrary('const a = null; class C { @a get m => null; }');
    checkElementText(library, r'''
class C {
  @
        a/*location: test.dart;a?*/
  dynamic get m {}
}
const dynamic a = null;
''');
  }

  test_metadata_methodDeclaration_method() async {
    var library = await checkLibrary(r'''
const a = null;
const b = null;
class C {
  @a
  @b
  m() {}
}
''');
    checkElementText(library, r'''
class C {
  @
        a/*location: test.dart;a?*/
  @
        b/*location: test.dart;b?*/
  dynamic m() {}
}
const dynamic a = null;
const dynamic b = null;
''');
  }

  test_metadata_methodDeclaration_setter() async {
    var library = await checkLibrary('''
const a = null;
class C {
  @a
  set m(value) {}
}
''');
    if (isStrongMode) {
      checkElementText(library, r'''
class C {
  @
        a/*location: test.dart;a?*/
  void set m(dynamic value) {}
}
const dynamic a = null;
''');
    } else {
      checkElementText(library, r'''
class C {
  @
        a/*location: test.dart;a?*/
  dynamic set m(dynamic value) {}
}
const dynamic a = null;
''');
    }
  }

  test_metadata_partDirective() async {
    addSource('/foo.dart', 'part of L;');
    var library = await checkLibrary('''
library L;
@a
part 'foo.dart';
const a = null;''');
    checkElementText(library, r'''
library L;
@
        a/*location: test.dart;a?*/
part 'foo.dart';
const dynamic a = null;
--------------------
unit: foo.dart

''');
  }

  test_metadata_prefixed_variable() async {
    addLibrarySource('/a.dart', 'const b = null;');
    var library = await checkLibrary('import "a.dart" as a; @a.b class C {}');
    if (isSharedFrontEnd) {
      checkElementText(library, r'''
import 'a.dart' as a;
@
        b/*location: a.dart;b?*/
class C {
}
''');
    } else {
      checkElementText(library, r'''
import 'a.dart' as a;
@
        a/*location: test.dart;a*/.
        b/*location: a.dart;b?*/
class C {
}
''');
    }
  }

  test_metadata_simpleFormalParameter() async {
    var library = await checkLibrary('const a = null; f(@a x) {}');
    checkElementText(library, r'''
const dynamic a = null;
dynamic f(@
        a/*location: test.dart;a?*/ dynamic x) {}
''');
  }

  test_metadata_simpleFormalParameter_withDefault() async {
    var library = await checkLibrary('const a = null; f([@a x = null]) {}');
    checkElementText(library, r'''
const dynamic a = null;
dynamic f([@
        a/*location: test.dart;a?*/ dynamic x]) {}
''');
  }

  test_metadata_topLevelVariableDeclaration() async {
    var library = await checkLibrary('const a = null; @a int v;');
    checkElementText(library, r'''
const dynamic a = null;
@
        a/*location: test.dart;a?*/
int v;
''');
  }

  test_metadata_typeParameter_ofClass() async {
    var library = await checkLibrary('const a = null; class C<@a T> {}');
    checkElementText(library, r'''
class C<T> {
}
const dynamic a = null;
''');
  }

  test_metadata_typeParameter_ofClassTypeAlias() async {
    var library = await checkLibrary('''
const a = null;
class C<@a T> = D with E;
class D {}
class E {}''');
    checkElementText(library, r'''
class alias C<T> extends D with E {
  synthetic C() = D;
}
class D {
}
class E {
}
const dynamic a = null;
''');
  }

  test_metadata_typeParameter_ofFunction() async {
    var library = await checkLibrary('const a = null; f<@a T>() {}');
    checkElementText(library, r'''
const dynamic a = null;
dynamic f<T>() {}
''');
  }

  test_metadata_typeParameter_ofTypedef() async {
    var library = await checkLibrary('const a = null; typedef F<@a T>();');
    checkElementText(library, r'''
typedef F<T> = dynamic Function();
const dynamic a = null;
''');
  }

  test_method_documented() async {
    var library = await checkLibrary('''
class C {
  /**
   * Docs
   */
  f() {}
}''');
    checkElementText(library, r'''
class C {
  /**
   * Docs
   */
  dynamic f() {}
}
''');
  }

  test_method_inferred_type_nonStatic_implicit_param() async {
    var library = await checkLibrary('class C extends D { void f(value) {} }'
        ' abstract class D { void f(int value); }');
    if (isStrongMode) {
      checkElementText(library, r'''
class C extends D {
  void f(int value) {}
}
abstract class D {
  void f(int value);
}
''');
    } else {
      checkElementText(library, r'''
class C extends D {
  void f(dynamic value) {}
}
abstract class D {
  void f(int value);
}
''');
    }
  }

  test_method_inferred_type_nonStatic_implicit_return() async {
    var library = await checkLibrary('''
class C extends D {
  f() => null;
}
abstract class D {
  int f();
}
''');
    if (isStrongMode) {
      checkElementText(library, r'''
class C extends D {
  int f() {}
}
abstract class D {
  int f();
}
''');
    } else {
      checkElementText(library, r'''
class C extends D {
  dynamic f() {}
}
abstract class D {
  int f();
}
''');
    }
  }

  test_method_type_parameter() async {
    var library = await checkLibrary('class C { T f<T, U>(U u) => null; }');
    checkElementText(library, r'''
class C {
  T f<T, U>(U u) {}
}
''');
  }

  test_method_type_parameter_in_generic_class() async {
    var library = await checkLibrary('''
class C<T, U> {
  V f<V, W>(T t, U u, W w) => null;
}
''');
    checkElementText(library, r'''
class C<T, U> {
  V f<V, W>(T t, U u, W w) {}
}
''');
  }

  test_method_type_parameter_with_function_typed_parameter() async {
    var library = await checkLibrary('class C { void f<T, U>(T x(U u)) {} }');
    checkElementText(library, r'''
class C {
  void f<T, U>((U) → T x) {}
}
''');
  }

  test_methodInvocation_implicitCall() async {
    var library = await checkLibrary(r'''
class A {
  double call() => 0.0;
}
class B {
  A a;
}
var c = new B().a();
''');
    if (isStrongMode) {
      checkElementText(library, r'''
class A {
  double call() {}
}
class B {
  A a;
}
double c;
''');
    } else {
      checkElementText(library, r'''
class A {
  double call() {}
}
class B {
  A a;
}
dynamic c;
''');
    }
  }

  test_nameConflict_exportedAndLocal() async {
    namesThatCannotBeResolved.add('V');
    addLibrarySource('/a.dart', 'class C {}');
    addLibrarySource('/c.dart', '''
export 'a.dart';
class C {}
''');
    var library = await checkLibrary('''
import 'c.dart';
C v = null;
''');
    checkElementText(library, r'''
import 'c.dart';
C v;
''');
  }

  test_nameConflict_exportedAndLocal_exported() async {
    namesThatCannotBeResolved.add('V');
    addLibrarySource('/a.dart', 'class C {}');
    addLibrarySource('/c.dart', '''
export 'a.dart';
class C {}
''');
    addLibrarySource('/d.dart', 'export "c.dart";');
    var library = await checkLibrary('''
import 'd.dart';
C v = null;
''');
    checkElementText(library, r'''
import 'd.dart';
C v;
''');
  }

  test_nameConflict_exportedAndParted() async {
    namesThatCannotBeResolved.add('V');
    addLibrarySource('/a.dart', 'class C {}');
    addLibrarySource('/b.dart', '''
part of lib;
class C {}
''');
    addLibrarySource('/c.dart', '''
library lib;
export 'a.dart';
part 'b.dart';
''');
    var library = await checkLibrary('''
import 'c.dart';
C v = null;
''');
    checkElementText(library, r'''
import 'c.dart';
C v;
''');
  }

  test_nameConflict_importWithRelativeUri_exportWithAbsolute() async {
    if (resourceProvider.pathContext.separator != '/') {
      return;
    }

    addLibrarySource('/a.dart', 'class A {}');
    addLibrarySource('/b.dart', 'export "/a.dart";');
    var library = await checkLibrary('''
import 'a.dart';
import 'b.dart';
A v = null;
''');
    checkElementText(library, r'''
import 'a.dart';
import 'b.dart';
A v;
''');
  }

  test_nested_generic_functions_in_generic_class_with_function_typed_params() async {
    var library = await checkLibrary('''
class C<T, U> {
  void g<V, W>() {
    void h<X, Y>(void p(T t, U u, V v, W w, X x, Y y)) {
    }
  }
}
''');
    checkElementText(library, r'''
class C<T, U> {
  void g<V, W>() {}
}
''');
  }

  test_nested_generic_functions_in_generic_class_with_local_variables() async {
    var library = await checkLibrary('''
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
    checkElementText(library, r'''
class C<T, U> {
  void g<V, W>() {}
}
''');
  }

  test_nested_generic_functions_with_function_typed_param() async {
    var library = await checkLibrary('''
void f<T, U>() {
  void g<V, W>() {
    void h<X, Y>(void p(T t, U u, V v, W w, X x, Y y)) {
    }
  }
}
''');
    checkElementText(library, r'''
void f<T, U>() {}
''');
  }

  test_nested_generic_functions_with_local_variables() async {
    var library = await checkLibrary('''
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
    checkElementText(library, r'''
void f<T, U>() {}
''');
  }

  test_operator() async {
    var library =
        await checkLibrary('class C { C operator+(C other) => null; }');
    checkElementText(library, r'''
class C {
  C +(C other) {}
}
''');
  }

  test_operator_equal() async {
    var library = await checkLibrary('''
class C {
  bool operator==(Object other) => false;
}
''');
    checkElementText(library, r'''
class C {
  bool ==(Object other) {}
}
''');
  }

  test_operator_external() async {
    var library =
        await checkLibrary('class C { external C operator+(C other); }');
    checkElementText(library, r'''
class C {
  external C +(C other) {}
}
''');
  }

  test_operator_greater_equal() async {
    var library = await checkLibrary('''
class C {
  bool operator>=(C other) => false;
}
''');
    checkElementText(library, r'''
class C {
  bool >=(C other) {}
}
''');
  }

  test_operator_index() async {
    var library =
        await checkLibrary('class C { bool operator[](int i) => null; }');
    checkElementText(library, r'''
class C {
  bool [](int i) {}
}
''');
  }

  test_operator_index_set() async {
    var library = await checkLibrary('''
class C {
  void operator[]=(int i, bool v) {}
}
''');
    checkElementText(library, r'''
class C {
  void []=(int i, bool v) {}
}
''');
  }

  test_operator_less_equal() async {
    var library = await checkLibrary('''
class C {
  bool operator<=(C other) => false;
}
''');
    checkElementText(library, r'''
class C {
  bool <=(C other) {}
}
''');
  }

  test_parameter_checked() async {
    // Note: due to dartbug.com/27393, the keyword "checked" is identified by
    // its presence in a library called "meta".  If that bug is fixed, this test
    // my need to be changed.
    var library = await checkLibrary(r'''
library meta;
const checked = null;
class A<T> {
  void f(@checked T t) {}
}
''');
    checkElementText(library, r'''
library meta;
class A<T> {
  void f(@
        checked/*location: test.dart;checked?*/ covariant T t) {}
}
const dynamic checked = null;
''');
  }

  test_parameter_checked_inherited() async {
    // Note: due to dartbug.com/27393, the keyword "checked" is identified by
    // its presence in a library called "meta".  If that bug is fixed, this test
    // my need to be changed.
    var library = await checkLibrary(r'''
library meta;
const checked = null;
class A<T> {
  void f(@checked T t) {}
}
class B<T> extends A<T> {
  void f(T t) {}
}
''');
    if (isStrongMode) {
      checkElementText(library, r'''
library meta;
class A<T> {
  void f(@
        checked/*location: test.dart;checked?*/ covariant T t) {}
}
class B<T> extends A<T> {
  void f(covariant T t) {}
}
const dynamic checked = null;
''');
    } else {
      checkElementText(library, r'''
library meta;
class A<T> {
  void f(@
        checked/*location: test.dart;checked?*/ covariant T t) {}
}
class B<T> extends A<T> {
  void f(T t) {}
}
const dynamic checked = null;
''');
    }
  }

  test_parameter_covariant() async {
    var library = await checkLibrary('class C { void m(covariant C c) {} }');
    checkElementText(library, r'''
class C {
  void m(covariant C c) {}
}
''');
  }

  test_parameter_covariant_inherited() async {
    var library = await checkLibrary(r'''
class A<T> {
  void f(covariant T t) {}
}
class B<T> extends A<T> {
  void f(T t) {}
}
''');
    if (isStrongMode) {
      checkElementText(library, r'''
class A<T> {
  void f(covariant T t) {}
}
class B<T> extends A<T> {
  void f(covariant T t) {}
}
''');
    } else {
      checkElementText(library, r'''
class A<T> {
  void f(covariant T t) {}
}
class B<T> extends A<T> {
  void f(T t) {}
}
''');
    }
  }

  test_parameter_parameters() async {
    var library = await checkLibrary('class C { f(g(x, y)) {} }');
    checkElementText(library, r'''
class C {
  dynamic f((dynamic, dynamic) → dynamic g) {}
}
''');
  }

  test_parameter_parameters_in_generic_class() async {
    var library = await checkLibrary('class C<A, B> { f(A g(B x)) {} }');
    checkElementText(library, r'''
class C<A, B> {
  dynamic f((B) → A g) {}
}
''');
  }

  test_parameter_return_type() async {
    var library = await checkLibrary('class C { f(int g()) {} }');
    checkElementText(library, r'''
class C {
  dynamic f(() → int g) {}
}
''');
  }

  test_parameter_return_type_void() async {
    var library = await checkLibrary('class C { f(void g()) {} }');
    checkElementText(library, r'''
class C {
  dynamic f(() → void g) {}
}
''');
  }

  test_parameterTypeNotInferred_constructor() async {
    // Strong mode doesn't do type inference on constructor parameters, so it's
    // ok that we don't store inferred type info for them in summaries.
    var library = await checkLibrary('''
class C {
  C.positional([x = 1]);
  C.named({x: 1});
}
''');
    checkElementText(library, r'''
class C {
  C.positional([dynamic x = 1]);
  C.named({dynamic x: 1});
}
''');
  }

  test_parameterTypeNotInferred_initializingFormal() async {
    // Strong mode doesn't do type inference on initializing formals, so it's
    // ok that we don't store inferred type info for them in summaries.
    var library = await checkLibrary('''
class C {
  var x;
  C.positional([this.x = 1]);
  C.named({this.x: 1});
}
''');
    checkElementText(library, r'''
class C {
  dynamic x;
  C.positional([dynamic this.x = 1]);
  C.named({dynamic this.x: 1});
}
''');
  }

  test_parameterTypeNotInferred_staticMethod() async {
    // Strong mode doesn't do type inference on parameters of static methods,
    // so it's ok that we don't store inferred type info for them in summaries.
    var library = await checkLibrary('''
class C {
  static void positional([x = 1]) {}
  static void named({x: 1}) {}
}
''');
    checkElementText(library, r'''
class C {
  static void positional([dynamic x = 1]) {}
  static void named({dynamic x: 1}) {}
}
''');
  }

  test_parameterTypeNotInferred_topLevelFunction() async {
    // Strong mode doesn't do type inference on parameters of top level
    // functions, so it's ok that we don't store inferred type info for them in
    // summaries.
    var library = await checkLibrary('''
void positional([x = 1]) {}
void named({x: 1}) {}
''');
    checkElementText(library, r'''
void positional([dynamic x = 1]) {}
void named({dynamic x: 1}) {}
''');
  }

  test_parts() async {
    addSource('/a.dart', 'part of my.lib;');
    addSource('/b.dart', 'part of my.lib;');
    var library =
        await checkLibrary('library my.lib; part "a.dart"; part "b.dart";');
    checkElementText(library, r'''
library my.lib;
part 'a.dart';
part 'b.dart';
--------------------
unit: a.dart

--------------------
unit: b.dart

''');
  }

  test_parts_invalidUri() async {
    allowMissingFiles = true;
    shouldCompareLibraryElements = false;
    addSource('/foo/bar.dart', 'part of my.lib;');
    var library = await checkLibrary('library my.lib; part "foo/";');
    checkElementText(library, r'''
library my.lib;
part '<unresolved>';
--------------------
unit: null

''');
  }

  test_parts_invalidUri_nullStringValue() async {
    allowMissingFiles = true;
    shouldCompareLibraryElements = false;
    addSource('/foo/bar.dart', 'part of my.lib;');
    var library = await checkLibrary(r'''
library my.lib;
part "${foo}/bar.dart";
''');
    checkElementText(library, r'''
library my.lib;
part '<unresolved>';
--------------------
unit: null

''');
  }

  test_propagated_type_refers_to_closure() async {
    var library = await checkLibrary('''
void f() {
  var x = () => 0;
  var y = x;
}
''');
    checkElementText(library, r'''
void f() {}
''');
  }

  test_setter_covariant() async {
    var library =
        await checkLibrary('class C { void set x(covariant int value); }');
    checkElementText(library, r'''
class C {
  void set x(covariant int value);
}
''');
  }

  test_setter_documented() async {
    var library = await checkLibrary('''
// Extra comment so doc comment offset != 0
/**
 * Docs
 */
void set x(value) {}''');
    checkElementText(library, r'''
/**
 * Docs
 */
void set x(dynamic value) {}
''');
  }

  test_setter_external() async {
    var library = await checkLibrary('external void set x(int value);');
    checkElementText(library, r'''
external void set x(int value);
''');
  }

  test_setter_inferred_type_conflictingInheritance() async {
    var library = await checkLibrary('''
class A {
  int t;
}
class B extends A {
  double t;
}
class C extends A implements B {
}
class D extends C {
  void set t(p) {}
}
''');
    checkElementText(library, r'''
class A {
  int t;
}
class B extends A {
  double t;
}
class C extends A implements B {
}
class D extends C {
  void set t(dynamic p) {}
}
''');
  }

  test_setter_inferred_type_nonStatic_implicit_param() async {
    var library =
        await checkLibrary('class C extends D { void set f(value) {} }'
            ' abstract class D { void set f(int value); }');
    if (isStrongMode) {
      checkElementText(library, r'''
class C extends D {
  void set f(int value) {}
}
abstract class D {
  void set f(int value);
}
''');
    } else {
      checkElementText(library, r'''
class C extends D {
  void set f(dynamic value) {}
}
abstract class D {
  void set f(int value);
}
''');
    }
  }

  test_setter_inferred_type_static_implicit_return() async {
    var library = await checkLibrary('''
class C {
  static set f(int value) {}
}
''');
    if (isStrongMode) {
      checkElementText(library, r'''
class C {
  static void set f(int value) {}
}
''');
    } else {
      checkElementText(library, r'''
class C {
  static dynamic set f(int value) {}
}
''');
    }
  }

  test_setter_inferred_type_top_level_implicit_return() async {
    var library = await checkLibrary('set f(int value) {}');
    if (isStrongMode) {
      checkElementText(library, r'''
void set f(int value) {}
''');
    } else {
      checkElementText(library, r'''
dynamic set f(int value) {}
''');
    }
  }

  test_setters() async {
    var library =
        await checkLibrary('void set x(int value) {} set y(value) {}');
    if (isStrongMode) {
      checkElementText(library, r'''
void set x(int value) {}
void set y(dynamic value) {}
''');
    } else {
      checkElementText(library, r'''
void set x(int value) {}
dynamic set y(dynamic value) {}
''');
    }
  }

  test_syntheticFunctionType_genericClosure() async {
    if (!isStrongMode) {
      return;
    }
    var library = await checkLibrary('''
final v = f() ? <T>(T t) => 0 : <T>(T t) => 1;
bool f() => true;
''');
    checkElementText(library, r'''
final (<bottom>) → int v;
bool f() {}
''');
  }

  test_syntheticFunctionType_genericClosure_inGenericFunction() async {
    if (!isStrongMode) {
      return;
    }
    var library = await checkLibrary('''
void f<T, U>(bool b) {
  final v = b ? <V>(T t, U u, V v) => 0 : <V>(T t, U u, V v) => 1;
}
''');
    checkElementText(library, r'''
void f<T, U>(bool b) {}
''');
  }

  test_syntheticFunctionType_inGenericClass() async {
    var library = await checkLibrary('''
class C<T, U> {
  var v = f() ? (T t, U u) => 0 : (T t, U u) => 1;
}
bool f() => false;
''');
    if (isStrongMode) {
      checkElementText(library, r'''
class C<T, U> {
  (T, U) → int v;
}
bool f() {}
''');
    } else {
      checkElementText(library, r'''
class C<T, U> {
  dynamic v;
}
bool f() {}
''');
    }
  }

  test_syntheticFunctionType_inGenericFunction() async {
    var library = await checkLibrary('''
void f<T, U>(bool b) {
  var v = b ? (T t, U u) => 0 : (T t, U u) => 1;
}
''');
    checkElementText(library, r'''
void f<T, U>(bool b) {}
''');
  }

  test_syntheticFunctionType_noArguments() async {
    var library = await checkLibrary('''
final v = f() ? () => 0 : () => 1;
bool f() => true;
''');
    if (isStrongMode) {
      checkElementText(library, r'''
final () → int v;
bool f() {}
''');
    } else {
      checkElementText(library, r'''
final dynamic v;
bool f() {}
''');
    }
  }

  test_syntheticFunctionType_withArguments() async {
    var library = await checkLibrary('''
final v = f() ? (int x, String y) => 0 : (int x, String y) => 1;
bool f() => true;
''');
    if (isStrongMode) {
      checkElementText(library, r'''
final (int, String) → int v;
bool f() {}
''');
    } else {
      checkElementText(library, r'''
final dynamic v;
bool f() {}
''');
    }
  }

  test_type_arguments_explicit_dynamic_dynamic() async {
    var library = await checkLibrary('Map<dynamic, dynamic> m;');
    checkElementText(library, r'''
Map<dynamic, dynamic> m;
''');
  }

  test_type_arguments_explicit_dynamic_int() async {
    var library = await checkLibrary('Map<dynamic, int> m;');
    checkElementText(library, r'''
Map<dynamic, int> m;
''');
  }

  test_type_arguments_explicit_String_dynamic() async {
    var library = await checkLibrary('Map<String, dynamic> m;');
    checkElementText(library, r'''
Map<String, dynamic> m;
''');
  }

  test_type_arguments_explicit_String_int() async {
    var library = await checkLibrary('Map<String, int> m;');
    checkElementText(library, r'''
Map<String, int> m;
''');
  }

  test_type_arguments_implicit() async {
    var library = await checkLibrary('Map m;');
    checkElementText(library, r'''
Map<dynamic, dynamic> m;
''');
  }

  test_type_dynamic() async {
    var library = await checkLibrary('dynamic d;');
    checkElementText(library, r'''
dynamic d;
''');
  }

  test_type_inference_based_on_loadLibrary() async {
    addLibrarySource('/a.dart', '');
    var library = await checkLibrary('''
import 'a.dart' deferred as a;
var x = a.loadLibrary;
''');
    if (isStrongMode) {
      checkElementText(library, '''
import 'a.dart' deferred as a;
() → Future<dynamic> x;
''');
    } else {
      checkElementText(library, '''
import 'a.dart' deferred as a;
dynamic x;
''');
    }
  }

  test_type_inference_closure_with_function_typed_parameter() async {
    var library = await checkLibrary('''
var x = (int f(String x)) => 0;
''');
    if (isStrongMode) {
      checkElementText(library, '''
((String) → int) → int x;
''');
    } else {
      checkElementText(library, '''
dynamic x;
''');
    }
  }

  test_type_inference_closure_with_function_typed_parameter_new() async {
    var library = await checkLibrary('''
var x = (int Function(String) f) => 0;
''');
    if (isStrongMode) {
      checkElementText(library, '''
((String) → int) → int x;
''');
    } else {
      checkElementText(library, '''
dynamic x;
''');
    }
  }

  test_type_inference_depends_on_exported_variable() async {
    addLibrarySource('/a.dart', 'export "b.dart";');
    addLibrarySource('/b.dart', 'var x = 0;');
    var library = await checkLibrary('''
import 'a.dart';
var y = x;
''');
    if (isStrongMode) {
      checkElementText(library, '''
import 'a.dart';
int y;
''');
    } else {
      checkElementText(library, '''
import 'a.dart';
dynamic y;
''');
    }
  }

  test_type_inference_nested_function() async {
    var library = await checkLibrary('''
var x = (t) => (u) => t + u;
''');
    if (isStrongMode) {
      checkElementText(library, '''
(dynamic) → (dynamic) → dynamic x;
''');
    } else {
      checkElementText(library, '''
dynamic x;
''');
    }
  }

  test_type_inference_nested_function_with_parameter_types() async {
    var library = await checkLibrary('''
var x = (int t) => (int u) => t + u;
''');
    if (isStrongMode) {
      checkElementText(library, '''
(int) → (int) → int x;
''');
    } else {
      checkElementText(library, '''
dynamic x;
''');
    }
  }

  test_type_inference_of_closure_with_default_value() async {
    var library = await checkLibrary('''
var x = ([y: 0]) => y;
''');
    if (isStrongMode) {
      checkElementText(library, '''
([dynamic]) → dynamic x;
''');
    } else {
      checkElementText(library, '''
dynamic x;
''');
    }
  }

  test_type_invalid_topLevelVariableElement_asType() async {
    var library = await checkLibrary('''
class C<T extends V> {}
typedef V F(V p);
V f(V p) {}
V V2 = null;
int V = 0;
''', allowErrors: true);
    checkElementText(library, r'''
typedef F = dynamic Function(dynamic p);
class C<T extends dynamic> {
}
dynamic V2;
int V;
dynamic f(dynamic p) {}
''');
  }

  test_type_invalid_topLevelVariableElement_asTypeArgument() async {
    var library = await checkLibrary('''
var V;
static List<V> V2;
''', allowErrors: true);
    checkElementText(library, r'''
dynamic V;
List<dynamic> V2;
''');
  }

  test_type_invalid_typeParameter_asPrefix() async {
    var library = await checkLibrary('''
class C<T> {
  m(T.K p) {}
}
''', allowErrors: true);
    checkElementText(library, r'''
class C<T> {
  dynamic m(dynamic p) {}
}
''');
  }

  test_type_reference_lib_to_lib() async {
    var library = await checkLibrary('''
class C {}
enum E { v }
typedef F();
C c;
E e;
F f;''');
    checkElementText(library, r'''
typedef F = dynamic Function();
enum E {
  synthetic final int index;
  synthetic static const List<E> values;
  static const E v;
  String toString() {}
}
class C {
}
C c;
E e;
() → dynamic f;
''');
  }

  test_type_reference_lib_to_part() async {
    addSource('/a.dart', 'part of l; class C {} enum E { v } typedef F();');
    var library =
        await checkLibrary('library l; part "a.dart"; C c; E e; F f;');
    checkElementText(library, r'''
library l;
part 'a.dart';
C c;
E e;
() → dynamic f;
--------------------
unit: a.dart

typedef F = dynamic Function();
enum E {
  synthetic final int index;
  synthetic static const List<E> values;
  static const E v;
  String toString() {}
}
class C {
}
''');
  }

  test_type_reference_part_to_lib() async {
    addSource('/a.dart', 'part of l; C c; E e; F f;');
    var library = await checkLibrary(
        'library l; part "a.dart"; class C {} enum E { v } typedef F();');
    checkElementText(library, r'''
library l;
part 'a.dart';
typedef F = dynamic Function();
enum E {
  synthetic final int index;
  synthetic static const List<E> values;
  static const E v;
  String toString() {}
}
class C {
}
--------------------
unit: a.dart

C c;
E e;
() → dynamic f;
''');
  }

  test_type_reference_part_to_other_part() async {
    addSource('/a.dart', 'part of l; class C {} enum E { v } typedef F();');
    addSource('/b.dart', 'part of l; C c; E e; F f;');
    var library =
        await checkLibrary('library l; part "a.dart"; part "b.dart";');
    checkElementText(library, r'''
library l;
part 'a.dart';
part 'b.dart';
--------------------
unit: a.dart

typedef F = dynamic Function();
enum E {
  synthetic final int index;
  synthetic static const List<E> values;
  static const E v;
  String toString() {}
}
class C {
}
--------------------
unit: b.dart

C c;
E e;
() → dynamic f;
''');
  }

  test_type_reference_part_to_part() async {
    addSource('/a.dart',
        'part of l; class C {} enum E { v } typedef F(); C c; E e; F f;');
    var library = await checkLibrary('library l; part "a.dart";');
    checkElementText(library, r'''
library l;
part 'a.dart';
--------------------
unit: a.dart

typedef F = dynamic Function();
enum E {
  synthetic final int index;
  synthetic static const List<E> values;
  static const E v;
  String toString() {}
}
class C {
}
C c;
E e;
() → dynamic f;
''');
  }

  test_type_reference_to_class() async {
    var library = await checkLibrary('class C {} C c;');
    checkElementText(library, r'''
class C {
}
C c;
''');
  }

  test_type_reference_to_class_with_type_arguments() async {
    var library = await checkLibrary('class C<T, U> {} C<int, String> c;');
    checkElementText(library, r'''
class C<T, U> {
}
C<int, String> c;
''');
  }

  test_type_reference_to_class_with_type_arguments_implicit() async {
    var library = await checkLibrary('class C<T, U> {} C c;');
    checkElementText(library, r'''
class C<T, U> {
}
C<dynamic, dynamic> c;
''');
  }

  test_type_reference_to_enum() async {
    var library = await checkLibrary('enum E { v } E e;');
    checkElementText(library, r'''
enum E {
  synthetic final int index;
  synthetic static const List<E> values;
  static const E v;
  String toString() {}
}
E e;
''');
  }

  test_type_reference_to_import() async {
    addLibrarySource('/a.dart', 'class C {} enum E { v } typedef F();');
    var library = await checkLibrary('import "a.dart"; C c; E e; F f;');
    checkElementText(library, r'''
import 'a.dart';
C c;
E e;
() → dynamic f;
''');
  }

  test_type_reference_to_import_export() async {
    addLibrarySource('/a.dart', 'export "b.dart";');
    addLibrarySource('/b.dart', 'class C {} enum E { v } typedef F();');
    var library = await checkLibrary('import "a.dart"; C c; E e; F f;');
    checkElementText(library, r'''
import 'a.dart';
C c;
E e;
() → dynamic f;
''');
  }

  test_type_reference_to_import_export_export() async {
    addLibrarySource('/a.dart', 'export "b.dart";');
    addLibrarySource('/b.dart', 'export "c.dart";');
    addLibrarySource('/c.dart', 'class C {} enum E { v } typedef F();');
    var library = await checkLibrary('import "a.dart"; C c; E e; F f;');
    checkElementText(library, r'''
import 'a.dart';
C c;
E e;
() → dynamic f;
''');
  }

  test_type_reference_to_import_export_export_in_subdirs() async {
    addLibrarySource('/a/a.dart', 'export "b/b.dart";');
    addLibrarySource('/a/b/b.dart', 'export "../c/c.dart";');
    addLibrarySource('/a/c/c.dart', 'class C {} enum E { v } typedef F();');
    var library = await checkLibrary('import "a/a.dart"; C c; E e; F f;');
    checkElementText(library, r'''
import 'a.dart';
C c;
E e;
() → dynamic f;
''');
  }

  test_type_reference_to_import_export_in_subdirs() async {
    addLibrarySource('/a/a.dart', 'export "b/b.dart";');
    addLibrarySource('/a/b/b.dart', 'class C {} enum E { v } typedef F();');
    var library = await checkLibrary('import "a/a.dart"; C c; E e; F f;');
    checkElementText(library, r'''
import 'a.dart';
C c;
E e;
() → dynamic f;
''');
  }

  test_type_reference_to_import_part() async {
    addLibrarySource('/a.dart', 'library l; part "b.dart";');
    addSource('/b.dart', 'part of l; class C {} enum E { v } typedef F();');
    var library = await checkLibrary('import "a.dart"; C c; E e; F f;');
    checkElementText(library, r'''
import 'a.dart';
C c;
E e;
() → dynamic f;
''');
  }

  test_type_reference_to_import_part2() async {
    addLibrarySource('/a.dart', 'library l; part "p1.dart"; part "p2.dart";');
    addSource('/p1.dart', 'part of l; class C1 {}');
    addSource('/p2.dart', 'part of l; class C2 {}');
    var library = await checkLibrary('import "a.dart"; C1 c1; C2 c2;');
    checkElementText(library, r'''
import 'a.dart';
C1 c1;
C2 c2;
''');
  }

  test_type_reference_to_import_part_in_subdir() async {
    addLibrarySource('/a/b.dart', 'library l; part "c.dart";');
    addSource('/a/c.dart', 'part of l; class C {} enum E { v } typedef F();');
    var library = await checkLibrary('import "a/b.dart"; C c; E e; F f;');
    checkElementText(library, r'''
import 'b.dart';
C c;
E e;
() → dynamic f;
''');
  }

  test_type_reference_to_import_relative() async {
    addLibrarySource('/a.dart', 'class C {} enum E { v } typedef F();');
    var library = await checkLibrary('import "a.dart"; C c; E e; F f;');
    checkElementText(library, r'''
import 'a.dart';
C c;
E e;
() → dynamic f;
''');
  }

  test_type_reference_to_typedef() async {
    var library = await checkLibrary('typedef F(); F f;');
    checkElementText(library, r'''
typedef F = dynamic Function();
() → dynamic f;
''');
  }

  test_type_reference_to_typedef_with_type_arguments() async {
    var library =
        await checkLibrary('typedef U F<T, U>(T t); F<int, String> f;');
    checkElementText(library, r'''
typedef F<T, U> = U Function(T t);
(int) → String f;
''');
  }

  test_type_reference_to_typedef_with_type_arguments_implicit() async {
    var library = await checkLibrary('typedef U F<T, U>(T t); F f;');
    checkElementText(library, r'''
typedef F<T, U> = U Function(T t);
(dynamic) → dynamic f;
''');
  }

  test_type_unresolved() async {
    var library = await checkLibrary('C c;', allowErrors: true);
    checkElementText(library, r'''
dynamic c;
''');
  }

  test_type_unresolved_prefixed() async {
    var library = await checkLibrary('import "dart:core" as core; core.C c;',
        allowErrors: true);
    checkElementText(library, r'''
import 'dart:core' as core;
dynamic c;
''');
  }

  test_typedef_documented() async {
    var library = await checkLibrary('''
// Extra comment so doc comment offset != 0
/**
 * Docs
 */
typedef F();''');
    checkElementText(library, r'''
/**
 * Docs
 */
typedef F = dynamic Function();
''');
  }

  test_typedef_generic() async {
    var library = await checkLibrary(
        'typedef F<T> = int Function<S>(List<S> list, num Function<A>(A), T);');
    checkElementText(library, r'''
typedef F<T> = int Function<S>(List<S> list, <A>(A) → num , T );
''');
  }

  test_typedef_generic_asFieldType() async {
    shouldCompareLibraryElements = false;
    var library = await checkLibrary(r'''
typedef Foo<S> = S Function<T>(T x);
class A {
  Foo<int> f;
}
''');
    checkElementText(library, r'''
typedef Foo<S> = S Function<T>(T x);
class A {
  <T>(T) → int f;
}
''');
  }

  test_typedef_parameter_parameters() async {
    var library = await checkLibrary('typedef F(g(x, y));');
    checkElementText(library, r'''
typedef F = dynamic Function((dynamic, dynamic) → dynamic g);
''');
  }

  test_typedef_parameter_parameters_in_generic_class() async {
    var library = await checkLibrary('typedef F<A, B>(A g(B x));');
    checkElementText(library, r'''
typedef F<A, B> = dynamic Function((B) → A g);
''');
  }

  test_typedef_parameter_return_type() async {
    var library = await checkLibrary('typedef F(int g());');
    checkElementText(library, r'''
typedef F = dynamic Function(() → int g);
''');
  }

  test_typedef_parameter_type() async {
    var library = await checkLibrary('typedef F(int i);');
    checkElementText(library, r'''
typedef F = dynamic Function(int i);
''');
  }

  test_typedef_parameter_type_generic() async {
    var library = await checkLibrary('typedef F<T>(T t);');
    checkElementText(library, r'''
typedef F<T> = dynamic Function(T t);
''');
  }

  test_typedef_parameters() async {
    var library = await checkLibrary('typedef F(x, y);');
    checkElementText(library, r'''
typedef F = dynamic Function(dynamic x, dynamic y);
''');
  }

  test_typedef_parameters_named() async {
    var library = await checkLibrary('typedef F({y, z, x});');
    if (isSharedFrontEnd) {
      checkElementText(library, r'''
typedef F = dynamic Function({dynamic x}, {dynamic y}, {dynamic z});
''');
    } else {
      checkElementText(library, r'''
typedef F = dynamic Function({dynamic y}, {dynamic z}, {dynamic x});
''');
    }
  }

  test_typedef_return_type() async {
    var library = await checkLibrary('typedef int F();');
    checkElementText(library, r'''
typedef F = int Function();
''');
  }

  test_typedef_return_type_generic() async {
    var library = await checkLibrary('typedef T F<T>();');
    checkElementText(library, r'''
typedef F<T> = T Function();
''');
  }

  test_typedef_return_type_implicit() async {
    var library = await checkLibrary('typedef F();');
    checkElementText(library, r'''
typedef F = dynamic Function();
''');
  }

  test_typedef_return_type_void() async {
    var library = await checkLibrary('typedef void F();');
    checkElementText(library, r'''
typedef F = void Function();
''');
  }

  test_typedef_type_parameters() async {
    var library = await checkLibrary('typedef U F<T, U>(T t);');
    checkElementText(library, r'''
typedef F<T, U> = U Function(T t);
''');
  }

  test_typedef_type_parameters_bound() async {
    var library = await checkLibrary(
        'typedef U F<T extends Object, U extends D>(T t); class D {}');
    checkElementText(library, r'''
typedef F<T extends Object, U extends D> = U Function(T t);
class D {
}
''');
  }

  test_typedef_type_parameters_bound_recursive() async {
    shouldCompareLibraryElements = false;
    var library = await checkLibrary('typedef void F<T extends F>();');
    // Typedefs cannot reference themselves.
    checkElementText(library, r'''
typedef F<T extends () → void> = void Function();
''');
  }

  test_typedef_type_parameters_bound_recursive2() async {
    shouldCompareLibraryElements = false;
    var library = await checkLibrary('typedef void F<T extends List<F>>();');
    // Typedefs cannot reference themselves.
    checkElementText(library, r'''
typedef F<T extends List<() → void>> = void Function();
''');
  }

  test_typedef_type_parameters_f_bound_complex() async {
    var library = await checkLibrary('typedef U F<T extends List<U>, U>(T t);');
    checkElementText(library, r'''
typedef F<T extends List<U>, U> = U Function(T t);
''');
  }

  test_typedef_type_parameters_f_bound_simple() async {
    var library = await checkLibrary('typedef U F<T extends U, U>(T t);');
    checkElementText(library, r'''
typedef F<T extends U, U> = U Function(T t);
''');
  }

  test_typedefs() async {
    var library = await checkLibrary('f() {} g() {}');
    checkElementText(library, r'''
dynamic f() {}
dynamic g() {}
''');
  }

  @failingTest
  test_unresolved_annotation_instanceCreation_argument_super() async {
    // TODO(scheglov) fix https://github.com/dart-lang/sdk/issues/28553
    var library = await checkLibrary('''
class A {
  const A(_);
}

@A(super)
class C {}
''', allowErrors: true);
    checkElementText(library, r'''
class A {
  A(_);
}

class C {
  synthetic C();
}
''');
  }

  test_unresolved_annotation_instanceCreation_argument_this() async {
    shouldCompareLibraryElements = false;
    var library = await checkLibrary('''
class A {
  const A(_);
}

@A(this)
class C {}
''', allowErrors: true);
    checkElementText(library, r'''
class A {
  const A(dynamic _);
}
@#invalidConst
class C {
}
''');
  }

  test_unresolved_annotation_namedConstructorCall_noClass() async {
    shouldCompareLibraryElements = false;
    var library =
        await checkLibrary('@foo.bar() class C {}', allowErrors: true);
    checkElementText(library, r'''
@#invalidConst
class C {
}
''');
  }

  test_unresolved_annotation_namedConstructorCall_noConstructor() async {
    shouldCompareLibraryElements = false;
    var library =
        await checkLibrary('@String.foo() class C {}', allowErrors: true);
    checkElementText(library, r'''
@#invalidConst
class C {
}
''');
  }

  test_unresolved_annotation_prefixedIdentifier_badPrefix() async {
    shouldCompareLibraryElements = false;
    var library = await checkLibrary('@foo.bar class C {}', allowErrors: true);
    checkElementText(library, r'''
@#invalidConst
class C {
}
''');
  }

  test_unresolved_annotation_prefixedIdentifier_noDeclaration() async {
    shouldCompareLibraryElements = false;
    var library = await checkLibrary(
        'import "dart:async" as foo; @foo.bar class C {}',
        allowErrors: true);
    checkElementText(library, r'''
import 'dart:async' as foo;
@#invalidConst
class C {
}
''');
  }

  test_unresolved_annotation_prefixedNamedConstructorCall_badPrefix() async {
    shouldCompareLibraryElements = false;
    var library =
        await checkLibrary('@foo.bar.baz() class C {}', allowErrors: true);
    checkElementText(library, r'''
@#invalidConst
class C {
}
''');
  }

  test_unresolved_annotation_prefixedNamedConstructorCall_noClass() async {
    shouldCompareLibraryElements = false;
    var library = await checkLibrary(
        'import "dart:async" as foo; @foo.bar.baz() class C {}',
        allowErrors: true);
    checkElementText(library, r'''
import 'dart:async' as foo;
@#invalidConst
class C {
}
''');
  }

  test_unresolved_annotation_prefixedNamedConstructorCall_noConstructor() async {
    shouldCompareLibraryElements = false;
    var library = await checkLibrary(
        'import "dart:async" as foo; @foo.Future.bar() class C {}',
        allowErrors: true);
    checkElementText(library, r'''
import 'dart:async' as foo;
@#invalidConst
class C {
}
''');
  }

  test_unresolved_annotation_prefixedUnnamedConstructorCall_badPrefix() async {
    shouldCompareLibraryElements = false;
    var library =
        await checkLibrary('@foo.bar() class C {}', allowErrors: true);
    checkElementText(library, r'''
@#invalidConst
class C {
}
''');
  }

  test_unresolved_annotation_prefixedUnnamedConstructorCall_noClass() async {
    shouldCompareLibraryElements = false;
    var library = await checkLibrary(
        'import "dart:async" as foo; @foo.bar() class C {}',
        allowErrors: true);
    checkElementText(library, r'''
import 'dart:async' as foo;
@#invalidConst
class C {
}
''');
  }

  test_unresolved_annotation_simpleIdentifier() async {
    shouldCompareLibraryElements = false;
    var library = await checkLibrary('@foo class C {}', allowErrors: true);
    checkElementText(library, r'''
@#invalidConst
class C {
}
''');
  }

  test_unresolved_annotation_unnamedConstructorCall_noClass() async {
    shouldCompareLibraryElements = false;
    var library = await checkLibrary('@foo() class C {}', allowErrors: true);
    checkElementText(library, r'''
@#invalidConst
class C {
}
''');
  }

  test_unresolved_export() async {
    allowMissingFiles = true;
    var library = await checkLibrary("export 'foo.dart';", allowErrors: true);
    checkElementText(library, r'''
export 'foo.dart';
''');
  }

  test_unresolved_import() async {
    allowMissingFiles = true;
    var library = await checkLibrary("import 'foo.dart';", allowErrors: true);
    LibraryElement importedLibrary = library.imports[0].importedLibrary;
    expect(importedLibrary.loadLibraryFunction, isNotNull);
    expect(importedLibrary.publicNamespace, isNotNull);
    expect(importedLibrary.exportNamespace, isNotNull);
    checkElementText(library, r'''
import 'foo.dart';
''');
  }

  test_unresolved_part() async {
    allowMissingFiles = true;
    var library = await checkLibrary("part 'foo.dart';", allowErrors: true);
    checkElementText(library, r'''
part 'foo.dart';
--------------------
unit: foo.dart

''');
  }

  test_unused_type_parameter() async {
    shouldCompareLibraryElements = false;
    var library = await checkLibrary('''
class C<T> {
  void f() {}
}
C<int> c;
var v = c.f;
''');
    if (isStrongMode) {
      checkElementText(library, r'''
class C<T> {
  void f() {}
}
C<int> c;
() → void v;
''');
    } else {
      checkElementText(library, r'''
class C<T> {
  void f() {}
}
C<int> c;
dynamic v;
''');
    }
  }

  test_variable_const() async {
    var library = await checkLibrary('const int i = 0;');
    checkElementText(library, r'''
const int i = 0;
''');
  }

  test_variable_documented() async {
    var library = await checkLibrary('''
// Extra comment so doc comment offset != 0
/**
 * Docs
 */
var x;''');
    checkElementText(library, r'''
/**
 * Docs
 */
dynamic x;
''');
  }

  test_variable_final() async {
    var library = await checkLibrary('final int x = 0;');
    checkElementText(library, r'''
final int x;
''');
  }

  test_variable_final_top_level_untyped() async {
    var library = await checkLibrary('final v = 0;');
    if (isStrongMode) {
      checkElementText(library, r'''
final int v;
''');
    } else {
      checkElementText(library, r'''
final dynamic v;
''');
    }
  }

  test_variable_getterInLib_setterInPart() async {
    addSource('/a.dart', '''
part of my.lib;
void set x(int _) {}
''');
    var library = await checkLibrary('''
library my.lib;
part 'a.dart';
int get x => 42;''');
    checkElementText(library, r'''
library my.lib;
part 'a.dart';
int get x {}
--------------------
unit: a.dart

void set x(int _) {}
''');
  }

  test_variable_getterInPart_setterInLib() async {
    addSource('/a.dart', '''
part of my.lib;
int get x => 42;
''');
    var library = await checkLibrary('''
library my.lib;
part 'a.dart';
void set x(int _) {}
''');
    checkElementText(library, r'''
library my.lib;
part 'a.dart';
void set x(int _) {}
--------------------
unit: a.dart

int get x {}
''');
  }

  test_variable_getterInPart_setterInPart() async {
    addSource('/a.dart', 'part of my.lib; int get x => 42;');
    addSource('/b.dart', 'part of my.lib; void set x(int _) {}');
    var library =
        await checkLibrary('library my.lib; part "a.dart"; part "b.dart";');
    checkElementText(library, r'''
library my.lib;
part 'a.dart';
part 'b.dart';
--------------------
unit: a.dart

int get x {}
--------------------
unit: b.dart

void set x(int _) {}
''');
  }

  test_variable_implicit_type() async {
    var library = await checkLibrary('var x;');
    checkElementText(library, r'''
dynamic x;
''');
  }

  test_variable_inferred_type_implicit_initialized() async {
    var library = await checkLibrary('var v = 0;');
    if (isStrongMode) {
      checkElementText(library, r'''
int v;
''');
    } else {
      checkElementText(library, r'''
dynamic v;
''');
    }
  }

  test_variable_propagatedType_const_noDep() async {
    var library = await checkLibrary('const i = 0;');
    if (isStrongMode) {
      checkElementText(library, r'''
const int i = 0;
''');
    } else {
      checkElementText(library, r'''
const dynamic i = 0;
''');
    }
  }

  test_variable_propagatedType_final_dep_inLib() async {
    addLibrarySource('/a.dart', 'final a = 1;');
    var library = await checkLibrary('import "a.dart"; final b = a / 2;');
    if (isStrongMode) {
      checkElementText(library, r'''
import 'a.dart';
final double b;
''');
    } else {
      checkElementText(library, r'''
import 'a.dart';
final dynamic b;
''');
    }
  }

  test_variable_propagatedType_final_dep_inPart() async {
    addSource('/a.dart', 'part of lib; final a = 1;');
    var library =
        await checkLibrary('library lib; part "a.dart"; final b = a / 2;');
    if (isStrongMode) {
      checkElementText(library, r'''
library lib;
part 'a.dart';
final double b;
--------------------
unit: a.dart

final int a;
''');
    } else {
      checkElementText(library, r'''
library lib;
part 'a.dart';
final dynamic b;
--------------------
unit: a.dart

final dynamic a;
''');
    }
  }

  test_variable_propagatedType_final_noDep() async {
    var library = await checkLibrary('final i = 0;');
    if (isStrongMode) {
      checkElementText(library, r'''
final int i;
''');
    } else {
      checkElementText(library, r'''
final dynamic i;
''');
    }
  }

  test_variable_propagatedType_implicit_dep() async {
    // The propagated type is defined in a library that is not imported.
    addLibrarySource('/a.dart', 'class C {}');
    addLibrarySource('/b.dart', 'import "a.dart"; C f() => null;');
    var library = await checkLibrary('import "b.dart"; final x = f();');
    if (isStrongMode) {
      checkElementText(library, r'''
import 'b.dart';
final C x;
''');
    } else {
      checkElementText(library, r'''
import 'b.dart';
final dynamic x;
''');
    }
  }

  test_variable_setterInPart_getterInPart() async {
    addSource('/a.dart', 'part of my.lib; void set x(int _) {}');
    addSource('/b.dart', 'part of my.lib; int get x => 42;');
    var library =
        await checkLibrary('library my.lib; part "a.dart"; part "b.dart";');
    checkElementText(library, r'''
library my.lib;
part 'a.dart';
part 'b.dart';
--------------------
unit: a.dart

void set x(int _) {}
--------------------
unit: b.dart

int get x {}
''');
  }

  test_variables() async {
    var library = await checkLibrary('int i; int j;');
    checkElementText(library, r'''
int i;
int j;
''');
  }
}

class TestSummaryResynthesizer extends SummaryResynthesizer {
  final Map<String, UnlinkedUnit> unlinkedSummaries;
  final Map<String, LinkedLibrary> linkedSummaries;
  final bool allowMissingFiles;

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

  TestSummaryResynthesizer(AnalysisContext context, this.unlinkedSummaries,
      this.linkedSummaries, this.allowMissingFiles)
      : super(context, context.sourceFactory,
            context.analysisOptions.strongMode) {
    // Clear after resynthesizing TypeProvider in super().
    unlinkedSummariesRequested.clear();
    linkedSummariesRequested.clear();
  }

  @override
  LinkedLibrary getLinkedSummary(String uri) {
    linkedSummariesRequested.add(uri);
    LinkedLibrary serializedLibrary = linkedSummaries[uri];
    if (serializedLibrary == null && !allowMissingFiles) {
      fail('Unexpectedly tried to get linked summary for $uri');
    }
    return serializedLibrary;
  }

  @override
  UnlinkedUnit getUnlinkedSummary(String uri) {
    unlinkedSummariesRequested.add(uri);
    UnlinkedUnit serializedUnit = unlinkedSummaries[uri];
    if (serializedUnit == null && !allowMissingFiles) {
      fail('Unexpectedly tried to get unlinked summary for $uri');
    }
    return serializedUnit;
  }

  @override
  bool hasLibrarySummary(String uri) {
    return true;
  }
}
