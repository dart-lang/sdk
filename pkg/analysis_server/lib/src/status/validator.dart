// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection';

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/src/context/cache.dart';
import 'package:analyzer/src/context/context.dart';
import 'package:analyzer/src/dart/ast/utilities.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/generated/engine.dart'
    show AnalysisEngine, AnalysisResult, CacheState, ChangeSet;
import 'package:analyzer/src/generated/resolver.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/generated/utilities_collection.dart';
import 'package:analyzer/src/task/dart.dart';
import 'package:analyzer/src/task/html.dart';
import 'package:analyzer/task/dart.dart';
import 'package:analyzer/task/model.dart';
import 'package:html/dom.dart' as html;

/**
 * A class used to compare two element models for equality.
 */
class ElementComparator {
  /**
   * The buffer to which any discovered differences will be recorded.
   */
  final StringBuffer _buffer = new StringBuffer();

  /**
   * A flag indicating whether a line break should be added the next time data
   * is written to the [_buffer].
   */
  bool _needsLineBreak = false;

  /**
   * Initialize a newly created comparator.
   */
  ElementComparator();

  /**
   * A textual description of the differences that were found.
   */
  String get description => _buffer.toString();

  /**
   * Return `true` if at least one difference was found between the expected and
   * actual elements.
   */
  bool get hasDifference => _buffer.length > 0;

  /**
   * Compare the [expected] and [actual] elements. The results of the comparison
   * can be accessed via the [hasDifference] and [description] getters.
   */
  void compareElements(Element expected, Element actual) {
    if (expected == null) {
      if (actual != null) {
        _writeMismatch(expected, actual, (Object element) {
          return element == null ? 'null' : 'non null ${element.runtimeType}';
        });
      }
    } else if (actual == null) {
      _writeMismatch(expected, actual, (Object element) {
        return element == null ? 'null' : 'non null ${element.runtimeType}';
      });
    } else if (expected is ClassElement && actual is ClassElement) {
      _compareClassElements(expected, actual);
    } else if (expected is CompilationUnitElement &&
        actual is CompilationUnitElement) {
      _compareCompilationUnitElements(expected, actual);
    } else if (expected is ConstructorElement && actual is ConstructorElement) {
      _compareConstructorElements(expected, actual);
    } else if (expected is ExportElement && actual is ExportElement) {
      _compareExportElements(expected, actual);
    } else if (expected is FieldElement && actual is FieldElement) {
      _compareFieldElements(expected, actual);
    } else if (expected is FieldFormalParameterElement &&
        actual is FieldFormalParameterElement) {
      _compareFieldFormalParameterElements(expected, actual);
    } else if (expected is FunctionElement && actual is FunctionElement) {
      _compareFunctionElements(expected, actual);
    } else if (expected is FunctionTypeAliasElement &&
        actual is FunctionTypeAliasElement) {
      _compareFunctionTypeAliasElements(expected, actual);
    } else if (expected is ImportElement && actual is ImportElement) {
      _compareImportElements(expected, actual);
    } else if (expected is LabelElement && actual is LabelElement) {
      _compareLabelElements(expected, actual);
    } else if (expected is LibraryElement && actual is LibraryElement) {
      _compareLibraryElements(expected, actual);
    } else if (expected is LocalVariableElement &&
        actual is LocalVariableElement) {
      _compareLocalVariableElements(expected, actual);
    } else if (expected is MethodElement && actual is MethodElement) {
      _compareMethodElements(expected, actual);
    } else if (expected is MultiplyDefinedElement &&
        actual is MultiplyDefinedElement) {
      _compareMultiplyDefinedElements(expected, actual);
    } else if (expected is ParameterElement && actual is ParameterElement) {
      _compareParameterElements(expected, actual);
    } else if (expected is PrefixElement && actual is PrefixElement) {
      _comparePrefixElements(expected, actual);
    } else if (expected is PropertyAccessorElement &&
        actual is PropertyAccessorElement) {
      _comparePropertyAccessorElements(expected, actual);
    } else if (expected is TopLevelVariableElement &&
        actual is TopLevelVariableElement) {
      _compareTopLevelVariableElements(expected, actual);
    } else if (expected is TypeParameterElement &&
        actual is TypeParameterElement) {
      _compareTypeParameterElements(expected, actual);
    } else {
      _write('Expected an instance of ');
      _write(expected.runtimeType);
      _write('; found an instance of ');
      _writeln(actual.runtimeType);
    }
  }

  void _compareClassElements(ClassElement expected, ClassElement actual) {
    _compareGenericElements(expected, actual);
    //
    // Compare attributes.
    //
    if (expected.hasReferenceToSuper != actual.hasReferenceToSuper) {
      _writeMismatch(
          expected,
          actual,
          (Object element) => (element as ClassElement).hasReferenceToSuper
              ? 'a class that references super'
              : 'a class that does not reference super');
    }
    if (expected.isAbstract != actual.isAbstract) {
      _writeMismatch(
          expected,
          actual,
          (Object element) => (element as ClassElement).isAbstract
              ? 'an abstract class'
              : 'a concrete class');
    }
    if (expected.isEnum != actual.isEnum ||
        expected.isMixinApplication != actual.isMixinApplication) {
      _writeMismatch(expected, actual, (Object element) {
        ClassElement classElement = element as ClassElement;
        return classElement.isEnum
            ? 'an enum'
            : (classElement.isMixinApplication
                ? 'a mixin application'
                : 'a class');
      });
    }
    if (expected.isOrInheritsProxy != actual.isOrInheritsProxy) {
      _writeMismatch(
          expected,
          actual,
          (Object element) => (element as ClassElement).isOrInheritsProxy
              ? 'a class that is marked as a proxy'
              : 'a class that is not marked as a proxy');
    }
    if (expected.isValidMixin != actual.isValidMixin) {
      _writeMismatch(
          expected,
          actual,
          (Object element) => (element as ClassElement).isValidMixin
              ? 'a valid mixin'
              : 'an invalid mixin');
    }
    _compareTypes('supertype', expected.supertype, actual.supertype);
    _compareTypeLists('mixin', expected.mixins, actual.mixins);
    _compareTypeLists('interface', expected.interfaces, actual.interfaces);
    //
    // Compare children.
    //
    _compareElementLists(expected.accessors, actual.accessors);
    _compareElementLists(expected.constructors, actual.constructors);
    _compareElementLists(expected.fields, actual.fields);
    _compareElementLists(expected.methods, actual.methods);
    _compareElementLists(expected.typeParameters, actual.typeParameters);
  }

  void _compareCompilationUnitElements(
      CompilationUnitElement expected, CompilationUnitElement actual) {
    _compareGenericElements(expected, actual);
    //
    // Compare children.
    //
    _compareElementLists(expected.accessors, actual.accessors);
    _compareElementLists(expected.enums, actual.enums);
    _compareElementLists(expected.functions, actual.functions);
    _compareElementLists(
        expected.functionTypeAliases, actual.functionTypeAliases);
    _compareElementLists(expected.topLevelVariables, actual.topLevelVariables);
    _compareElementLists(expected.types, actual.types);
  }

  void _compareConstructorElements(
      ConstructorElement expected, ConstructorElement actual) {
    _compareExecutableElements(expected, actual, 'constructor');
    //
    // Compare attributes.
    //
    if (expected.isConst != actual.isConst) {
      _writeMismatch(
          expected,
          actual,
          (Object element) => (element as ConstructorElement).isConst
              ? 'a const constructor'
              : 'a non-const constructor');
    }
    if (expected.isFactory != actual.isFactory) {
      _writeMismatch(
          expected,
          actual,
          (Object element) => (element as ConstructorElement).isFactory
              ? 'a factory constructor'
              : 'a non-factory constructor');
    }
    if (expected.periodOffset != actual.periodOffset) {
      _write('Expected a period offset of ');
      _write(expected.periodOffset);
      _write('; found ');
      _writeln(actual.periodOffset);
    }
    if ((expected.redirectedConstructor == null) !=
        (actual.redirectedConstructor == null)) {
      _writeMismatch(
          expected,
          actual,
          (Object element) =>
              (element as ConstructorElement).redirectedConstructor == null
                  ? 'a redirecting constructor'
                  : 'a non-redirecting constructor');
    }
  }

  void _compareElementLists(List expected, List actual) {
    Set<Element> extraElements = new HashSet<Element>();
    Map<Element, Element> commonElements = new HashMap<Element, Element>();

    Map<String, Element> expectedElements = new HashMap<String, Element>();
    for (Element expectedElement in expected) {
      expectedElements[expectedElement.name] = expectedElement;
    }
    for (Element actualElement in actual) {
      String name = actualElement.name;
      Element expectedElement = expectedElements[name];
      if (expectedElement == null) {
        extraElements.add(actualElement);
      } else {
        commonElements[expectedElement] = actualElement;
        expectedElements.remove(name);
      }
    }

    commonElements.forEach((Element expected, Element actual) {
      compareElements(expected, actual);
    });
    void writeElement(Element element) {
      _write('an instance of ');
      _write(element.runtimeType);
      if (element.name == null) {
        _write(' with no name');
      } else {
        _write(' named ');
        _write(element.name);
      }
    }

    expectedElements.forEach((String name, Element element) {
      _write('Expected ');
      writeElement(element);
      _writeln('; found no match');
    });
    extraElements.forEach((Element element) {
      _write('Expected nothing; found ');
      writeElement(element);
    });
  }

  void _compareExecutableElements(
      ExecutableElement expected, ExecutableElement actual, String kind) {
    _compareGenericElements(expected, actual);
    //
    // Compare attributes.
    //
    if (expected.hasImplicitReturnType != actual.hasImplicitReturnType) {
      _writeMismatch(
          expected,
          actual,
          (Object element) =>
              (element as ExecutableElement).hasImplicitReturnType
                  ? 'an implicit return type'
                  : 'an explicit return type');
    }
    if (expected.isAbstract != actual.isAbstract) {
      _writeMismatch(
          expected,
          actual,
          (Object element) => (element as ExecutableElement).isAbstract
              ? 'an abstract $kind'
              : 'a concrete $kind');
    }
    if (expected.isAsynchronous != actual.isAsynchronous) {
      _writeMismatch(
          expected,
          actual,
          (Object element) => (element as ExecutableElement).isAsynchronous
              ? 'an asynchronous $kind'
              : 'a synchronous $kind');
    }
    if (expected.isExternal != actual.isExternal) {
      _writeMismatch(
          expected,
          actual,
          (Object element) => (element as ExecutableElement).isExternal
              ? 'an external $kind'
              : 'a non-external $kind');
    }
    if (expected.isGenerator != actual.isGenerator) {
      _writeMismatch(
          expected,
          actual,
          (Object element) => (element as ExecutableElement).isGenerator
              ? 'a generator $kind'
              : 'a non-generator $kind');
    }
    if (expected.isOperator != actual.isOperator) {
      _writeMismatch(
          expected,
          actual,
          (Object element) => (element as ExecutableElement).isOperator
              ? 'an operator'
              : 'a non-operator $kind');
    }
    if (expected.isStatic != actual.isStatic) {
      _writeMismatch(
          expected,
          actual,
          (Object element) => (element as ExecutableElement).isStatic
              ? 'a static $kind'
              : 'an instance $kind');
    }
    if ((expected.returnType == null) != (actual.returnType == null)) {
      _writeMismatch(
          expected,
          actual,
          (Object element) => (element as ExecutableElement).returnType == null
              ? 'a $kind with no return type'
              : 'a $kind with a return type');
    } else {
      _compareTypes('return type', expected.returnType, actual.returnType);
    }
    //
    // Compare children.
    //
    _compareElementLists(expected.functions, actual.functions);
    _compareElementLists(expected.labels, actual.labels);
    _compareElementLists(expected.localVariables, actual.localVariables);
    _compareElementLists(expected.parameters, actual.parameters);
    _compareElementLists(expected.typeParameters, actual.typeParameters);
  }

  void _compareExportElements(ExportElement expected, ExportElement actual) {
    _compareUriReferencedElements(expected, actual);
    //
    // Compare attributes.
    //
    if ((expected.exportedLibrary == null) !=
        (actual.exportedLibrary == null)) {
      // TODO(brianwilkerson) Check for more than existence?
      _writeMismatch(expected, actual, (Object element) {
        ExportElement exportElement = element as ExportElement;
        return exportElement.exportedLibrary == null
            ? 'unresolved uri'
            : 'uri resolved to ${exportElement.exportedLibrary.source.fullName}';
      });
    }
    //
    // Compare children.
    //
    _compareElementLists(expected.combinators, actual.combinators);
  }

  void _compareFieldElements(FieldElement expected, FieldElement actual) {
    _comparePropertyInducingElements(expected, actual, 'field');
    //
    // Compare attributes.
    //
    if (expected.isEnumConstant != actual.isEnumConstant) {
      _writeMismatch(
          expected,
          actual,
          (Object element) => (element as FieldElement).isEnumConstant
              ? 'an enum constant'
              : 'a normal field');
    }
  }

  void _compareFieldFormalParameterElements(
      FieldFormalParameterElement expected,
      FieldFormalParameterElement actual) {
    // TODO(brianwilkerson) Implement this
    _compareGenericElements(expected, actual);
  }

  void _compareFunctionElements(
      FunctionElement expected, FunctionElement actual) {
    // TODO(brianwilkerson) Implement this
    _compareGenericElements(expected, actual);
  }

  void _compareFunctionTypeAliasElements(
      FunctionTypeAliasElement expected, FunctionTypeAliasElement actual) {
    // TODO(brianwilkerson) Implement this
    _compareGenericElements(expected, actual);
  }

  void _compareGenericElements(Element expected, Element actual) {
    _compareMetadata(expected.metadata, actual.metadata);
    if (expected.nameOffset != actual.nameOffset) {
      _write('Expected name offset of ');
      _write(expected.nameOffset);
      _write('; found ');
      _writeln(actual.nameOffset);
    }
    String expectedComment = expected.documentationComment;
    String actualComment = actual.documentationComment;
    if (expectedComment != actualComment) {
      _write('Expected documentation comment of "');
      _write(expectedComment);
      _write('"; found "');
      _write(actualComment);
      _writeln('"');
    }
  }

  void _compareImportElements(ImportElement expected, ImportElement actual) {
    _compareUriReferencedElements(expected, actual);
    //
    // Compare attributes.
    //
    if (expected.isDeferred != actual.isDeferred) {
      _writeMismatch(
          expected,
          actual,
          (Object element) => (element as ImportElement).isDeferred
              ? 'a deferred import'
              : 'a non-deferred import');
    }
    if ((expected.importedLibrary == null) !=
        (actual.importedLibrary == null)) {
      _writeMismatch(expected, actual, (Object element) {
        ImportElement importElement = element as ImportElement;
        return importElement.importedLibrary == null
            ? 'unresolved uri'
            : 'uri resolved to ${importElement.importedLibrary.source.fullName}';
      });
    }
    if ((expected.prefix == null) != (actual.prefix == null)) {
      _writeMismatch(expected, actual, (Object element) {
        ImportElement importElement = element as ImportElement;
        return importElement.prefix == null
            ? 'no prefix'
            : 'a prefix named ${importElement.prefix.name}';
      });
    }
    if (expected.prefixOffset != actual.prefixOffset) {
      _write('Expected a prefix offset of ');
      _write(expected.prefixOffset);
      _write('; found ');
      _writeln(actual.prefixOffset);
    }
    //
    // Compare children.
    //
    _compareElementLists(expected.combinators, actual.combinators);
  }

  void _compareLabelElements(LabelElement expected, LabelElement actual) {
    // TODO(brianwilkerson) Implement this
    _compareGenericElements(expected, actual);
  }

  void _compareLibraryElements(LibraryElement expected, LibraryElement actual) {
    _compareGenericElements(expected, actual);
    //
    // Compare attributes.
    //
    // TODO(brianwilkerson) Implement this
    expected.hasLoadLibraryFunction;
    expected.name;
    expected.source;
    //
    // Compare children.
    //
    _compareElementLists(expected.imports, actual.imports);
    _compareElementLists(expected.exports, actual.exports);
    _compareElementLists(expected.units, actual.units);
  }

  void _compareLocalVariableElements(
      LocalVariableElement expected, LocalVariableElement actual) {
    // TODO(brianwilkerson) Implement this
    _compareGenericElements(expected, actual);
  }

  void _compareMetadata(
      List<ElementAnnotation> expected, List<ElementAnnotation> actual) {
    // TODO(brianwilkerson) Implement this
  }

  void _compareMethodElements(MethodElement expected, MethodElement actual) {
    // TODO(brianwilkerson) Implement this
    _compareExecutableElements(expected, actual, 'method');
    //
    // Compare attributes.
    //
    if (expected.isStatic != actual.isStatic) {
      _writeMismatch(
          expected,
          actual,
          (Object element) => (element as FieldElement).isStatic
              ? 'a static field'
              : 'an instance field');
    }
  }

  void _compareMultiplyDefinedElements(
      MultiplyDefinedElement expected, MultiplyDefinedElement actual) {
    // TODO(brianwilkerson) Implement this
  }

  void _compareParameterElements(
      ParameterElement expected, ParameterElement actual) {
    // TODO(brianwilkerson) Implement this
    _compareGenericElements(expected, actual);
  }

  void _comparePrefixElements(PrefixElement expected, PrefixElement actual) {
    // TODO(brianwilkerson) Implement this
    _compareGenericElements(expected, actual);
  }

  void _comparePropertyAccessorElements(
      PropertyAccessorElement expected, PropertyAccessorElement actual) {
    // TODO(brianwilkerson) Implement this
    _compareGenericElements(expected, actual);
  }

  void _comparePropertyInducingElements(PropertyInducingElement expected,
      PropertyInducingElement actual, String kind) {
    _compareVariableElements(expected, actual, kind);
  }

  void _compareTopLevelVariableElements(
      TopLevelVariableElement expected, TopLevelVariableElement actual) {
    // TODO(brianwilkerson) Implement this
    _compareGenericElements(expected, actual);
  }

  void _compareTypeLists(String descriptor, List<InterfaceType> expected,
      List<InterfaceType> actual) {
    int expectedLength = expected.length;
    if (expectedLength != actual.length) {
      _write('Expected ');
      _write(expectedLength);
      _write(' ');
      _write(descriptor);
      _write('s; found ');
      _write(actual.length);
    } else {
      for (int i = 0; i < expectedLength; i++) {
        _compareTypes(descriptor, expected[i], actual[i]);
      }
    }
  }

  void _compareTypeParameterElements(
      TypeParameterElement expected, TypeParameterElement actual) {
    // TODO(brianwilkerson) Implement this
    _compareGenericElements(expected, actual);
    expected.bound;
  }

  void _compareTypes(String descriptor, DartType expected, DartType actual) {
    void compareNames() {
      if (expected.name != actual.name) {
        _write('Expected a ');
        _write(descriptor);
        _write(' named ');
        _write(expected.name);
        _write('; found a ');
        _write(descriptor);
        _write(' named ');
        _write(actual.name);
      }
    }

    void compareTypeArguments(
        ParameterizedType expected, ParameterizedType actual) {
      List<DartType> expectedArguments = expected.typeArguments;
      List<DartType> actualArguments = actual.typeArguments;
      int expectedLength = expectedArguments.length;
      if (expectedLength != actualArguments.length) {
        _write('Expected ');
        _write(expectedLength);
        _write(' type arguments; found ');
        _write(actualArguments.length);
      } else {
        for (int i = 0; i < expectedLength; i++) {
          _compareTypes(
              'type argument', expectedArguments[i], actualArguments[i]);
        }
      }
    }

    if (expected == null) {
      if (actual != null) {
        _write('Expected no ');
        _write(descriptor);
        _write('; found a ');
        _write(descriptor);
        _write(' named ');
        _write(actual.name);
      }
    } else if (actual == null) {
      _write('Expected a ');
      _write(descriptor);
      _write(' named ');
      _write(expected.name);
      _write('; found none');
    } else if ((expected.isBottom && actual.isBottom) ||
        (expected.isDynamic && actual.isDynamic) ||
        (expected.isVoid && actual.isVoid)) {
      // The types are the same
    } else if (expected is InterfaceType && actual is InterfaceType) {
      compareNames();
      compareTypeArguments(expected, actual);
    } else if (expected is FunctionType && actual is FunctionType) {
      compareNames();
      compareTypeArguments(expected, actual);
    } else if (expected is TypeParameterType && actual is TypeParameterType) {
      compareNames();
      _compareTypes('bound', expected.element.bound, actual.element.bound);
    } else {
      _write('Expected an instance of ');
      _write(expected.runtimeType);
      _write(' named ');
      _write(expected.name);
      _write('; found an instance of ');
      _writeln(actual.runtimeType);
      _write(' named ');
      _write(actual.name);
    }
  }

  void _compareUriReferencedElements(
      UriReferencedElement expected, UriReferencedElement actual) {
    _compareGenericElements(expected, actual);
    //
    // Compare attributes.
    //
    if (expected.uri != actual.uri) {
      _write('Expected a uri of ');
      _write(expected.uri);
      _write('; found ');
      _writeln(actual.uri);
    }
    if (expected.uriOffset != actual.uriOffset) {
      _write('Expected a uri offset of ');
      _write(expected.uriOffset);
      _write('; found ');
      _writeln(actual.uriOffset);
    }
  }

  void _compareVariableElements(
      VariableElement expected, VariableElement actual, String kind) {
    _compareGenericElements(expected, actual);
    //
    // Compare attributes.
    //
    if ((expected.constantValue == null) != (actual.constantValue == null)) {
      // TODO(brianwilkerson) Check for more than existence.
      _writeMismatch(
          expected,
          actual,
          (Object element) => (element as VariableElement).constantValue == null
              ? 'a $kind with no constant value'
              : 'a $kind with a constant value');
    }
    if (expected.hasImplicitType != actual.hasImplicitType) {
      _writeMismatch(
          expected,
          actual,
          (Object element) => (element as VariableElement).hasImplicitType
              ? 'a $kind with an implicit type'
              : 'a $kind with an explicit type');
    }
    if (expected.isConst != actual.isConst) {
      _writeMismatch(
          expected,
          actual,
          (Object element) => (element as VariableElement).isConst
              ? 'a const $kind'
              : 'a non-const $kind');
    }
    if (expected.isFinal != actual.isFinal) {
      _writeMismatch(
          expected,
          actual,
          (Object element) => (element as VariableElement).isFinal
              ? 'a final $kind'
              : 'a non-final $kind');
    }
    if (expected.isStatic != actual.isStatic) {
      _writeMismatch(
          expected,
          actual,
          (Object element) => (element as VariableElement).isStatic
              ? 'a static $kind'
              : 'an instance $kind');
    }
    //
    // Compare children.
    //
    compareElements(expected.initializer, actual.initializer);
  }

  void _write(Object value) {
    if (_needsLineBreak) {
      _buffer.write('</p><p>');
      _needsLineBreak = false;
    }
    _buffer.write(value);
  }

  void _writeln(Object value) {
    _buffer.write(value);
    _needsLineBreak = true;
  }

  /**
   * Write a simple message explaining that the [expected] and [actual] values
   * were different, using the [describe] function to describe the values.
   */
  void _writeMismatch/*<E>*/(Object/*=E*/ expected, Object/*=E*/ actual,
      String describe(Object/*=E*/ value)) {
    _write('Expected ');
    _write(describe(expected));
    _write('; found ');
    _writeln(describe(actual));
  }
}

/**
 * The comparison of two analyses of the same target.
 */
class EntryComparison {
  /**
   * The target that was analyzed.
   */
  final AnalysisTarget target;

  /**
   * The cache entry from the original context.
   */
  final CacheEntry originalEntry;

  /**
   * The cache entry from the re-analysis in a cloned context.
   */
  final CacheEntry cloneEntry;

  /**
   * A flag indicating whether the target is obsolete. A target is obsolete if
   * it is an element in an element model that was replaced at a some point.
   */
  bool obsoleteTarget = false;

  /**
   * A table mapping the results that were computed for the target to
   * comparisons of the values of those results. The table only contains entries
   * for results for which the comparison produced interesting data.
   */
  Map<ResultDescriptor, ResultComparison> resultMap =
      new HashMap<ResultDescriptor, ResultComparison>();

  /**
   * Initialize a newly created comparison of the given [target]'s analysis,
   * given the [originalEntry] from the original context and the [cloneEntry]
   * from the cloned context.
   */
  EntryComparison(this.target, this.originalEntry, this.cloneEntry) {
    _performComparison();
  }

  /**
   * Return `true` if there is something interesting about the analysis of this
   * target that should be reported.
   */
  bool hasInterestingState() => obsoleteTarget || resultMap.isNotEmpty;

  /**
   * Write an HTML formatted description of the validation results to the given
   * [buffer].
   */
  void writeOn(StringBuffer buffer) {
    buffer.write('<p>');
    buffer.write(target);
    buffer.write('</p>');
    buffer.write('<blockquote>');
    if (obsoleteTarget) {
      buffer.write('<p><b>This target is obsolete.</b></p>');
    }
    List<ResultDescriptor> results = resultMap.keys.toList();
    results.sort((ResultDescriptor first, ResultDescriptor second) =>
        first.toString().compareTo(second.toString()));
    for (ResultDescriptor result in results) {
      resultMap[result].writeOn(buffer);
    }
    buffer.write('</blockquote>');
  }

  /**
   * Compare all of the results that were computed in the two contexts, adding
   * the interesting comparisons to the [resultMap].
   */
  void _compareResults() {
    Set<ResultDescriptor> results = new Set<ResultDescriptor>();
    results.addAll(originalEntry.nonInvalidResults);
    results.addAll(cloneEntry.nonInvalidResults);

    for (ResultDescriptor result in results) {
      ResultComparison difference = new ResultComparison(this, result);
      if (difference.hasInterestingState()) {
        resultMap[result] = difference;
      }
    }
  }

  /**
   * Return `true` if the target of this entry is an obsolete element.
   */
  bool _isTargetObsolete() {
    if (target is Element) {
      LibraryElement library = (target as Element).library;
      AnalysisContextImpl context = library.context;
      CacheEntry entry = context.analysisCache.get(library.source);
      LibraryElement value = entry.getValue(LIBRARY_ELEMENT);
      return value != library;
    }
    return false;
  }

  /**
   * Determine whether or not there is any interesting difference between the
   * original and cloned contexts.
   */
  void _performComparison() {
    obsoleteTarget = _isTargetObsolete();
    _compareResults();
  }
}

/**
 * The comparison of the value of a single result computed for a single target.
 */
class ResultComparison {
  /**
   * The entry for the target for which the result was computed.
   */
  final EntryComparison entry;

  /**
   * The result that was computed for the target.
   */
  final ResultDescriptor result;

  /**
   * A flag indicating whether the state of the result is different.
   */
  bool differentStates = false;

  /**
   * The result of comparing the values of the results, or `null` if the states
   * are different or if the values are the same.
   */
  ValueComparison valueComparison;

  /**
   * Initialize a newly created result comparison.
   */
  ResultComparison(this.entry, this.result) {
    _performComparison();
  }

  /**
   * Return `true` if this object represents a difference between the original
   * and cloned contexts.
   */
  bool hasInterestingState() => differentStates || valueComparison != null;

  /**
   * Write an HTML formatted description of the validation results to the given
   * [buffer].
   */
  void writeOn(StringBuffer buffer) {
    buffer.write('<p>');
    buffer.write(result);
    buffer.write('</p>');
    buffer.write('<blockquote>');
    if (differentStates) {
      CacheState originalState = entry.originalEntry.getState(result);
      CacheState cloneState = entry.cloneEntry.getState(result);
      buffer.write('<p>Original state = ');
      buffer.write(originalState.name);
      buffer.write('; clone state = ');
      buffer.write(cloneState.name);
      buffer.write('</p>');
    }
    if (valueComparison != null) {
      valueComparison.writeOn(buffer);
    }
    buffer.write('</blockquote>');
  }

  /**
   * Determine whether the state of the result is different between the
   * original and cloned contexts.
   */
  bool _areStatesDifferent(CacheState originalState, CacheState cloneState) {
    if (originalState == cloneState) {
      return false;
    } else if (originalState == CacheState.FLUSHED &&
        cloneState == CacheState.VALID) {
      return false;
    } else if (originalState == CacheState.VALID &&
        cloneState == CacheState.FLUSHED) {
      return false;
    }
    return true;
  }

  /**
   * Determine whether the value of the result is different between the
   * original and cloned contexts.
   */
  void _compareValues(CacheState originalState, CacheState cloneState) {
    if (originalState != cloneState || originalState != CacheState.VALID) {
      return null;
    }
    ValueComparison comparison = new ValueComparison(
        entry.originalEntry.getValue(result),
        entry.cloneEntry.getValue(result));
    if (comparison.hasInterestingState()) {
      valueComparison = comparison;
    }
  }

  /**
   * Determine whether or not there is any interesting difference between the
   * original and cloned contexts.
   */
  void _performComparison() {
    CacheState originalState = entry.originalEntry.getState(result);
    CacheState cloneState = entry.cloneEntry.getState(result);
    if (_areStatesDifferent(originalState, cloneState)) {
      differentStates = true;
      _compareValues(originalState, cloneState);
    }
  }
}

/**
 * The results of validating an analysis context.
 *
 * Validation is done by re-analyzing all of the explicitly added source in a
 * new analysis context that is configured to be the same as the original
 * context.
 */
class ValidationResults {
  /**
   * A set of targets that were in the original context that were not included
   * in the re-created context.
   */
  Set<AnalysisTarget> extraTargets;

  /**
   * A set of targets that were in the re-created context that were not included
   * in the original context.
   */
  Set<AnalysisTarget> missingTargets;

  /**
   * A table, keyed by targets, whose values are comparisons of the analysis of
   * those targets. The table only contains entries for targets for which the
   * comparison produced interesting data.
   */
  Map<AnalysisTarget, EntryComparison> targetMap =
      new HashMap<AnalysisTarget, EntryComparison>();

  /**
   * Initialize a newly created validation result by validating the given
   * [context].
   */
  ValidationResults(AnalysisContextImpl context) {
    _validate(context);
  }

  /**
   * Write an HTML formatted description of the validation results to the given
   * [buffer].
   */
  void writeOn(StringBuffer buffer) {
    if (extraTargets.isEmpty && missingTargets.isEmpty && targetMap.isEmpty) {
      buffer.write('<p>No interesting results.</p>');
      return;
    }
    if (extraTargets.isNotEmpty) {
      buffer.write('<h4>Extra Targets</h4>');
      buffer.write('<p style="commentary">');
      buffer.write('Targets that exist in the original context that were not ');
      buffer.write('re-created in the cloned context.');
      buffer.write('</p>');
      _writeTargetList(buffer, extraTargets.toList());
    }
    if (missingTargets.isNotEmpty) {
      buffer.write('<h4>Missing Targets</h4>');
      buffer.write('<p style="commentary">');
      buffer.write('Targets that do <b>not</b> exist in the original context ');
      buffer.write('but do exist in the cloned context.');
      buffer.write('</p>');
      _writeTargetList(buffer, missingTargets.toList());
    }
    if (targetMap.isNotEmpty) {
      buffer.write('<h4>Differing Targets</h4>');
      // TODO(brianwilkerson) Sort the list of targets.
      for (EntryComparison comparison in targetMap.values) {
        comparison.writeOn(buffer);
      }
    }
  }

  /**
   * Analyze all of the explicit sources in the given [context].
   */
  void _analyze(AnalysisContextImpl context) {
    while (true) {
      AnalysisResult result = context.performAnalysisTask();
      if (!result.hasMoreWork) {
        return;
      }
    }
  }

  /**
   * Create and return a new analysis context that will analyze files in the
   * same way as the given [context].
   */
  AnalysisContextImpl _clone(AnalysisContextImpl context) {
    AnalysisContextImpl clone = AnalysisEngine.instance.createAnalysisContext();

    clone.analysisOptions = context.analysisOptions;
    //clone.declaredVariables = context.declaredVariables;
    clone.sourceFactory = context.sourceFactory.clone();
    // TODO(brianwilkerson) Check content cache. We either need to copy the
    // cache into the clone or ensure that the context's cache is empty.

    ChangeSet changeSet = new ChangeSet();
    for (AnalysisTarget target in context.explicitTargets) {
      if (target is Source) {
        changeSet.addedSource(target);
      }
    }
    clone.applyChanges(changeSet);
    return clone;
  }

  /**
   * Compare the results produced in the [original] context to those produced in
   * the [clone].
   */
  void _compareContexts(
      AnalysisContextImpl original, AnalysisContextImpl clone) {
    AnalysisCache originalCache = original.analysisCache;
    AnalysisCache cloneCache = clone.analysisCache;
    List<AnalysisTarget> originalTargets = _getKeys(original, originalCache);
    List<AnalysisTarget> cloneTargets = _getKeys(clone, cloneCache);

    extraTargets =
        new HashSet<AnalysisTarget>(equals: _equal, hashCode: _hashCode);
    extraTargets.addAll(originalTargets);
    extraTargets.removeAll(cloneTargets);

    missingTargets =
        new HashSet<AnalysisTarget>(equals: _equal, hashCode: _hashCode);
    missingTargets.addAll(cloneTargets);
    missingTargets.removeAll(originalTargets);

    for (AnalysisTarget cloneTarget in cloneTargets) {
      if (!missingTargets.contains(cloneTarget)) {
        AnalysisTarget originalTarget = _find(originalTargets, cloneTarget);
        CacheEntry originalEntry = originalCache.get(originalTarget);
        CacheEntry cloneEntry = cloneCache.get(cloneTarget);
        EntryComparison comparison =
            new EntryComparison(cloneTarget, originalEntry, cloneEntry);
        if (comparison.hasInterestingState()) {
          targetMap[cloneTarget] = comparison;
        }
      }
    }
  }

  /**
   * Find the target in the list of [originalTargets] that is equal to the
   * [cloneTarget].
   */
  AnalysisTarget _find(
      List<AnalysisTarget> originalTargets, AnalysisTarget cloneTarget) {
    for (AnalysisTarget originalTarget in originalTargets) {
      if (_equal(originalTarget, cloneTarget)) {
        return originalTarget;
      }
    }
    return null;
  }

  /**
   * Return a list of the analysis targets in the given [cache] that are owned
   * by the given [context].
   */
  List<AnalysisTarget> _getKeys(
      AnalysisContextImpl context, AnalysisCache cache) {
    List<AnalysisTarget> targets = <AnalysisTarget>[];
    MapIterator<AnalysisTarget, CacheEntry> iterator =
        cache.iterator(context: context);
    while (iterator.moveNext()) {
      targets.add(iterator.key);
    }
    return targets;
  }

  /**
   * Validate the given [context].
   */
  void _validate(AnalysisContextImpl context) {
    AnalysisContextImpl clone = _clone(context);
    _analyze(clone);
    _compareContexts(context, clone);
  }

  /**
   * Write the list of [targets] to the [buffer].
   */
  void _writeTargetList(StringBuffer buffer, List<AnalysisTarget> targets) {
    // TODO(brianwilkerson) Sort the list of targets.
    //targets.sort();
    for (AnalysisTarget target in targets) {
      buffer.write('<p>');
      buffer.write(target);
      buffer.write(' (');
      buffer.write(target.runtimeType);
      buffer.write(')');
      buffer.write('</p>');
    }
  }

  /**
   * Return `true` if the [first] and [second] objects are equal.
   */
  static bool _equal(Object first, Object second) {
    //
    // Compare possible null values.
    //
    if (first == null) {
      return second == null;
    } else if (second == null) {
      return false;
    }
    //
    // Handle special cases.
    //
    if (first is ElementAnnotationImpl && second is ElementAnnotationImpl) {
      return _equal(first.source, second.source) &&
          _equal(first.librarySource, second.librarySource) &&
          _equal(first.annotationAst, second.annotationAst);
    } else if (first is AstNode && second is AstNode) {
      return first.runtimeType == second.runtimeType &&
          first.offset == second.offset &&
          first.length == second.length;
    }
    //
    // Handle the general case.
    //
    return first == second;
  }

  /**
   * Return a hash code for the given [object].
   */
  static int _hashCode(Object object) {
    //
    // Handle special cases.
    //
    if (object is ElementAnnotation) {
      return object.source.hashCode;
    } else if (object is AstNode) {
      return object.offset;
    }
    //
    // Handle the general case.
    //
    return object.hashCode;
  }
}

class ValueComparison {
  /**
   * The result value from the original context.
   */
  final Object originalValue;

  /**
   * The result value from the cloned context.
   */
  final Object cloneValue;

  /**
   * A description of the difference between the original and clone values, or
   * `null` if the values are equal.
   */
  String description = null;

  /**
   * Initialize a newly created value comparison to represents the difference,
   * if any, between the [originalValue] and the [cloneValue].
   */
  ValueComparison(this.originalValue, this.cloneValue) {
    _performComparison();
  }

  /**
   * Return `true` if this object represents a difference between the original
   * and cloned values.
   */
  bool hasInterestingState() => description != null;

  /**
   * Write an HTML formatted description of the validation results to the given
   * [buffer].
   */
  void writeOn(StringBuffer buffer) {
    buffer.write('<p>');
    buffer.write(description);
    buffer.write('</p>');
  }

  bool _compareAnalysisErrors(
      AnalysisError expected, AnalysisError actual, StringBuffer buffer) {
    if (actual.errorCode == expected.errorCode &&
        actual.source == expected.source &&
        actual.offset == expected.offset) {
      return true;
    }
    if (buffer != null) {
      void write(AnalysisError originalError) {
        buffer.write('a ');
        buffer.write(originalError.errorCode.uniqueName);
        buffer.write(' in ');
        buffer.write(originalError.source.fullName);
        buffer.write(' at ');
        buffer.write(originalError.offset);
      }

      buffer.write('Expected ');
      write(expected);
      buffer.write('; found ');
      write(actual);
    }
    return false;
  }

  bool _compareAstNodes(AstNode expected, AstNode actual, StringBuffer buffer) {
    if (AstComparator.equalNodes(actual, expected)) {
      return true;
    }
    if (buffer != null) {
      // TODO(brianwilkerson) Compute where the difference is rather than just
      // whether there is a difference.
      buffer.write('Different AST nodes');
    }
    return false;
  }

  bool _compareConstantEvaluationTargets(ConstantEvaluationTarget expected,
      ConstantEvaluationTarget actual, StringBuffer buffer) {
    if (actual is ElementAnnotation) {
      ElementAnnotationImpl expectedAnnotation = expected;
      ElementAnnotationImpl actualAnnotation = actual;
      if (actualAnnotation.source == expectedAnnotation.source &&
          actualAnnotation.librarySource == expectedAnnotation.librarySource &&
          actualAnnotation.annotationAst == expectedAnnotation.annotationAst) {
        return true;
      }
      if (buffer != null) {
        void write(ElementAnnotationImpl target) {
          Annotation annotation = target.annotationAst;
          buffer.write(annotation);
          buffer.write(' at ');
          buffer.write(annotation.offset);
          buffer.write(' in ');
          buffer.write(target.source);
          buffer.write(' in ');
          buffer.write(target.librarySource);
        }

        buffer.write('Expected ');
        write(expectedAnnotation);
        buffer.write('; found ');
        write(actualAnnotation);
      }
      return false;
    }
    if (buffer != null) {
      buffer.write('Unknown class of ConstantEvaluationTarget: ');
      buffer.write(actual.runtimeType);
    }
    return false;
  }

  bool _compareDartScripts(
      DartScript expected, DartScript actual, StringBuffer buffer) {
    // TODO(brianwilkerson) Implement this.
    return true;
  }

  bool _compareDocuments(
      html.Document expected, html.Document actual, StringBuffer buffer) {
    // TODO(brianwilkerson) Implement this.
    return true;
  }

  bool _compareElements(Element expected, Element actual, StringBuffer buffer) {
    ElementComparator comparator = new ElementComparator();
    comparator.compareElements(expected, actual);
    if (comparator.hasDifference) {
      if (buffer != null) {
        buffer.write(comparator.description);
      }
      return false;
    }
    return true;
  }

  bool _compareLibrarySpecificUnits(LibrarySpecificUnit expected,
      LibrarySpecificUnit actual, StringBuffer buffer) {
    if (actual.library.fullName == expected.library.fullName &&
        actual.unit.fullName == expected.unit.fullName) {
      return true;
    }
    if (buffer != null) {
      buffer.write('Expected ');
      buffer.write(expected);
      buffer.write('; found ');
      buffer.write(actual);
    }
    return false;
  }

  bool _compareLineInfos(
      LineInfo expected, LineInfo actual, StringBuffer buffer) {
    // TODO(brianwilkerson) Implement this.
    return true;
  }

  bool _compareLists(List expected, List actual, StringBuffer buffer) {
    int expectedLength = expected.length;
    int actualLength = actual.length;
    int left = 0;
    while (left < expectedLength &&
        left < actualLength &&
        _compareObjects(expected[left], actual[left], null)) {
      left++;
    }
    if (left == actualLength) {
      if (left == expectedLength) {
        // The lists are the same length and the elements are equal.
        return true;
      }
      if (buffer != null) {
        buffer.write('Expected a list of length ');
        buffer.write(expectedLength);
        buffer.write('; found a list of length ');
        buffer.write(actualLength);
        buffer.write(' that was a prefix of the expected list');
      }
      return false;
    } else if (left == expectedLength) {
      if (buffer != null) {
        buffer.write('Expected a list of length ');
        buffer.write(expectedLength);
        buffer.write('; found a list of length ');
        buffer.write(actualLength);
        buffer.write(' that was an extension of the expected list');
      }
      return false;
    }
    int expectedRight = expectedLength - 1;
    int actualRight = actualLength - 1;
    while (expectedRight > left &&
        actualRight > left &&
        _compareObjects(expected[expectedRight], actual[actualRight], null)) {
      actualRight--;
      expectedRight--;
    }
    if (buffer != null) {
      void write(int left, int right, int length) {
        buffer.write('the elements (');
        buffer.write(left);
        buffer.write('..');
        buffer.write(right);
        buffer.write(') in a list of length ');
        buffer.write(length);
      }

      buffer.write('Expected ');
      write(left, expectedRight, expectedLength);
      buffer.write(' to match ');
      write(left, actualRight, actualLength);
      buffer.write(' but they did not');
    }
    return false;
  }

  /**
   * Return `true` if the [expected] and [actual] objects are equal. If they are
   * not equal, and the given [buffer] is not `null`, then a description of the
   * difference will be written to the [buffer].
   */
  bool _compareObjects(Object expected, Object actual, StringBuffer buffer) {
    //
    // Compare possible null values.
    //
    if (actual == null) {
      if (expected == null) {
        return true;
      } else {
        if (buffer != null) {
          buffer.write('Expected an instance of ');
          buffer.write(expected.runtimeType);
          buffer.write('; found null');
        }
        return false;
      }
    }
    Type actualType = actual.runtimeType;
    if (expected == null) {
      if (buffer != null) {
        buffer.write('Expected null; found an instance of ');
        buffer.write(actualType);
      }
      return false;
    }
    Type expectedType = expected.runtimeType;
    //
    // Compare the types.
    //
    if (expectedType != actualType) {
      if (buffer != null) {
        buffer.write('Expected an instance of ');
        buffer.write(expectedType);
        buffer.write('; found an instance of ');
        buffer.write(actualType);
      }
      return false;
    }
    //
    // Compare non-null values of the same type.
    //
    if (actual is bool) {
      return _comparePrimitives(expected, actual, buffer);
    } else if (actual is int) {
      return _comparePrimitives(expected, actual, buffer);
    } else if (actual is String) {
      return _compareStrings(expected, actual, buffer);
    } else if (actual is List) {
      return _compareLists(expected, actual, buffer);
    } else if (actual is AnalysisError) {
      return _compareAnalysisErrors(expected, actual, buffer);
    } else if (actual is AstNode) {
      return _compareAstNodes(expected, actual, buffer);
    } else if (actual is DartScript) {
      return _compareDartScripts(expected, actual, buffer);
    } else if (actual is html.Document) {
      return _compareDocuments(expected, actual, buffer);
    } else if (actual is Element) {
      return _compareElements(expected, actual, buffer);
    } else if (actual is LibrarySpecificUnit) {
      return _compareLibrarySpecificUnits(expected, actual, buffer);
    } else if (actual is LineInfo) {
      return _compareLineInfos(expected, actual, buffer);
    } else if (actual is Source) {
      return _compareSources(expected, actual, buffer);
    } else if (actual is SourceKind) {
      return _comparePrimitives(expected, actual, buffer);
    } else if (actual is Token) {
      return _compareTokenStreams(expected, actual, buffer);
    } else if (actual is TypeProvider) {
      return true;
    } else if (actual is UsedLocalElements) {
      return _compareUsedLocalElements(expected, actual, buffer);
    } else if (actual is UsedImportedElements) {
      return _compareUsedImportedElements(expected, actual, buffer);
    } else if (actual is ConstantEvaluationTarget) {
      return _compareConstantEvaluationTargets(expected, actual, buffer);
    }
    if (buffer != null) {
      buffer.write('Cannot compare values of type ');
      buffer.write(actualType);
    }
    return false;
  }

  bool _comparePrimitives(Object expected, Object actual, StringBuffer buffer) {
    if (actual == expected) {
      return true;
    }
    if (buffer != null) {
      buffer.write('Expected ');
      buffer.write(expected);
      buffer.write('; found ');
      buffer.write(actual);
    }
    return false;
  }

  bool _compareSources(Source expected, Source actual, StringBuffer buffer) {
    if (actual.fullName == expected.fullName) {
      return true;
    }
    if (buffer != null) {
      buffer.write('Expected a source for ');
      buffer.write(expected.fullName);
      buffer.write('; found a source for ');
      buffer.write(actual.fullName);
    }
    return false;
  }

  bool _compareStrings(String expected, String actual, StringBuffer buffer) {
    if (actual == expected) {
      return true;
    }
    int expectedLength = expected.length;
    int actualLength = actual.length;
    int left = 0;
    while (left < actualLength &&
        left < expectedLength &&
        actual.codeUnitAt(left) == expected.codeUnitAt(left)) {
      left++;
    }
    if (left == actualLength) {
      if (buffer != null) {
        buffer.write('Expected ...[');
        buffer.write(expected.substring(left));
        buffer.write(']; found ...[]');
      }
      return false;
    } else if (left == expectedLength) {
      if (buffer != null) {
        buffer.write('Expected ...[]; found ...[');
        buffer.write(actual.substring(left));
        buffer.write(']');
      }
      return false;
    }
    int actualRight = actualLength - 1;
    int expectedRight = expectedLength - 1;
    while (actualRight > left &&
        expectedRight > left &&
        actual.codeUnitAt(actualRight) == expected.codeUnitAt(expectedRight)) {
      actualRight--;
      expectedRight--;
    }
    if (buffer != null) {
      void write(String string, int left, int right) {
        buffer.write('...[');
        buffer.write(string.substring(left, right));
        buffer.write(']... (');
        buffer.write(left);
        buffer.write('..');
        buffer.write(right);
        buffer.write(')');
      }

      buffer.write('Expected ');
      write(expected, left, expectedRight);
      buffer.write('; found ');
      write(actual, left, actualRight);
    }
    return false;
  }

  bool _compareTokenStreams(Token expected, Token actual, StringBuffer buffer) {
    bool equals(Token originalToken, Token cloneToken) {
      return originalToken.type == cloneToken.type &&
          originalToken.offset == cloneToken.offset &&
          originalToken.lexeme == cloneToken.lexeme;
    }

    Token actualLeft = actual;
    Token expectedLeft = expected;
    while (actualLeft.type != TokenType.EOF &&
        expectedLeft.type != TokenType.EOF &&
        equals(actualLeft, expectedLeft)) {
      actualLeft = actualLeft.next;
      expectedLeft = expectedLeft.next;
    }
    if (actualLeft.type == TokenType.EOF &&
        expectedLeft.type == TokenType.EOF) {
      return true;
    }
    if (buffer != null) {
      void write(Token token) {
        buffer.write(token.type);
        buffer.write(' at ');
        buffer.write(token.offset);
        buffer.write(' (');
        buffer.write(token.lexeme);
        buffer.write(')');
      }

      buffer.write('Expected ');
      write(expectedLeft);
      buffer.write('; found ');
      write(actualLeft);
    }
    return false;
  }

  bool _compareUsedImportedElements(UsedImportedElements expected,
      UsedImportedElements actual, StringBuffer buffer) {
    // TODO(brianwilkerson) Implement this.
    return true;
  }

  bool _compareUsedLocalElements(UsedLocalElements expected,
      UsedLocalElements actual, StringBuffer buffer) {
    // TODO(brianwilkerson) Implement this.
    return true;
  }

  /**
   * Determine whether or not there is any interesting difference between the
   * original and cloned values.
   */
  void _performComparison() {
    StringBuffer buffer = new StringBuffer();
    if (!_compareObjects(cloneValue, originalValue, buffer)) {
      description = buffer.toString();
    }
  }
}
