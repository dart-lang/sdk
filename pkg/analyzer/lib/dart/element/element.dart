// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Defines the element model. The element model describes the semantic (as
/// opposed to syntactic) structure of Dart code. The syntactic structure of the
/// code is modeled by the [AST
/// structure](../dart_ast_ast/dart_ast_ast-library.html).
///
/// The element model consists of two closely related kinds of objects: elements
/// (instances of a subclass of [Element]) and types. This library defines the
/// elements, the types are defined in
/// [type.dart](../dart_element_type/dart_element_type-library.html).
///
/// Generally speaking, an element represents something that is declared in the
/// code, such as a class, method, or variable. Elements are organized in a tree
/// structure in which the children of an element are the elements that are
/// logically (and often syntactically) part of the declaration of the parent.
/// For example, the elements representing the methods and fields in a class are
/// children of the element representing the class.
///
/// Every complete element structure is rooted by an instance of the class
/// [LibraryElement]. A library element represents a single Dart library. Every
/// library is defined by one or more compilation units (the library and all of
/// its parts). The compilation units are represented by the class
/// [CompilationUnitElement] and are children of the library that is defined by
/// them. Each compilation unit can contain zero or more top-level declarations,
/// such as classes, functions, and variables. Each of these is in turn
/// represented as an element that is a child of the compilation unit. Classes
/// contain methods and fields, methods can contain local variables, etc.
///
/// The element model does not contain everything in the code, only those things
/// that are declared by the code. For example, it does not include any
/// representation of the statements in a method body, but if one of those
/// statements declares a local variable then the local variable will be
/// represented by an element.
library;

import 'package:analyzer/src/dart/element/element.dart';
import 'package:pub_semver/pub_semver.dart';

export 'package:analyzer/src/dart/element/element.dart'
    show
        AugmentationImportElement,
        AugmentedClassElement,
        AugmentedEnumElement,
        AugmentedExtensionElement,
        AugmentedInlineClassElement,
        AugmentedInstanceElement,
        AugmentedInterfaceElement,
        AugmentedMixinElement,
        AugmentedNamedInstanceElement,
        BindPatternVariableElement,
        ClassElement,
        ClassMemberElement,
        CompilationUnitElement,
        ConstructorElement,
        DeferredImportElementPrefix,
        DirectiveUri,
        DirectiveUriWithAugmentation,
        DirectiveUriWithLibrary,
        DirectiveUriWithRelativeUri,
        DirectiveUriWithRelativeUriString,
        DirectiveUriWithSource,
        DirectiveUriWithUnit,
        Element,
        ElementAnnotation,
        EnumElement,
        ExecutableElement,
        ExtensionElement,
        FieldElement,
        FieldFormalParameterElement,
        FunctionElement,
        FunctionTypedElement,
        GenericFunctionTypeElement,
        HideElementCombinator,
        ImportElementPrefix,
        InlineClassElement,
        InstanceElement,
        InterfaceElement,
        JoinPatternVariableElement,
        LabelElement,
        LibraryAugmentationElement,
        LibraryElement,
        LibraryExportElement,
        LibraryImportElement,
        LibraryOrAugmentationElement,
        LocalElement,
        LocalVariableElement,
        MethodElement,
        MixinElement,
        MultiplyDefinedElement,
        MultiplyInheritedExecutableElement,
        NamedInstanceElement,
        NamespaceCombinator,
        ParameterElement,
        PartElement,
        PatternVariableElement,
        PrefixElement,
        PromotableElement,
        PropertyAccessorElement,
        PropertyInducingElement,
        ShowElementCombinator,
        SuperFormalParameterElement,
        TopLevelVariableElement,
        TypeAliasElement,
        TypeDefiningElement,
        TypeParameterElement,
        TypeParameterizedElement,
        UndefinedElement,
        UriReferencedElement,
        VariableElement;

/// The kind of elements in the element model.
///
/// Clients may not extend, implement or mix-in this class.
class ElementKind implements Comparable<ElementKind> {
  static const ElementKind AUGMENTATION_IMPORT =
      ElementKind('AUGMENTATION_IMPORT', 0, "augmentation import");

  static const ElementKind CLASS = ElementKind('CLASS', 1, "class");

  static const ElementKind CLASS_AUGMENTATION =
      ElementKind('CLASS_AUGMENTATION', 2, "class augmentation");

  static const ElementKind COMPILATION_UNIT =
      ElementKind('COMPILATION_UNIT', 3, "compilation unit");

  static const ElementKind CONSTRUCTOR =
      ElementKind('CONSTRUCTOR', 4, "constructor");

  static const ElementKind DYNAMIC = ElementKind('DYNAMIC', 5, "<dynamic>");

  static const ElementKind ENUM = ElementKind('ENUM', 6, "enum");

  static const ElementKind ERROR = ElementKind('ERROR', 7, "<error>");

  static const ElementKind EXPORT =
      ElementKind('EXPORT', 8, "export directive");

  static const ElementKind EXTENSION = ElementKind('EXTENSION', 9, "extension");

  static const ElementKind FIELD = ElementKind('FIELD', 10, "field");

  static const ElementKind FUNCTION = ElementKind('FUNCTION', 11, "function");

  static const ElementKind GENERIC_FUNCTION_TYPE =
      ElementKind('GENERIC_FUNCTION_TYPE', 12, 'generic function type');

  static const ElementKind GETTER = ElementKind('GETTER', 13, "getter");

  static const ElementKind IMPORT =
      ElementKind('IMPORT', 14, "import directive");

  static const ElementKind INLINE_CLASS =
      ElementKind('INLINE_CLASS', 15, "inline class");

  static const ElementKind LABEL = ElementKind('LABEL', 16, "label");

  static const ElementKind LIBRARY = ElementKind('LIBRARY', 17, "library");

  static const ElementKind LIBRARY_AUGMENTATION =
      ElementKind('LIBRARY_AUGMENTATION', 18, "library augmentation");

  static const ElementKind LOCAL_VARIABLE =
      ElementKind('LOCAL_VARIABLE', 19, "local variable");

  static const ElementKind METHOD = ElementKind('METHOD', 20, "method");

  static const ElementKind NAME = ElementKind('NAME', 21, "<name>");

  static const ElementKind NEVER = ElementKind('NEVER', 22, "<never>");

  static const ElementKind PARAMETER =
      ElementKind('PARAMETER', 23, "parameter");

  static const ElementKind PART = ElementKind('PART', 24, "part");

  static const ElementKind PREFIX = ElementKind('PREFIX', 25, "import prefix");

  static const ElementKind RECORD = ElementKind('RECORD', 26, "record");

  static const ElementKind SETTER = ElementKind('SETTER', 27, "setter");

  static const ElementKind TOP_LEVEL_VARIABLE =
      ElementKind('TOP_LEVEL_VARIABLE', 28, "top level variable");

  static const ElementKind FUNCTION_TYPE_ALIAS =
      ElementKind('FUNCTION_TYPE_ALIAS', 29, "function type alias");

  static const ElementKind TYPE_PARAMETER =
      ElementKind('TYPE_PARAMETER', 30, "type parameter");

  static const ElementKind TYPE_ALIAS =
      ElementKind('TYPE_ALIAS', 31, "type alias");

  static const ElementKind UNIVERSE = ElementKind('UNIVERSE', 32, "<universe>");

  static const List<ElementKind> values = [
    CLASS,
    CLASS_AUGMENTATION,
    COMPILATION_UNIT,
    CONSTRUCTOR,
    DYNAMIC,
    ENUM,
    ERROR,
    EXPORT,
    FIELD,
    FUNCTION,
    GENERIC_FUNCTION_TYPE,
    GETTER,
    IMPORT,
    INLINE_CLASS,
    LABEL,
    LIBRARY,
    LOCAL_VARIABLE,
    METHOD,
    NAME,
    NEVER,
    PARAMETER,
    PART,
    PREFIX,
    RECORD,
    SETTER,
    TOP_LEVEL_VARIABLE,
    FUNCTION_TYPE_ALIAS,
    TYPE_PARAMETER,
    UNIVERSE
  ];

  /// The name of this element kind.
  final String name;

  /// The ordinal value of the element kind.
  final int ordinal;

  /// The name displayed in the UI for this kind of element.
  final String displayName;

  /// Initialize a newly created element kind to have the given [displayName].
  const ElementKind(this.name, this.ordinal, this.displayName);

  @override
  int compareTo(ElementKind other) => ordinal - other.ordinal;

  @override
  String toString() => name;

  /// Returns the kind of the given [element], or [ERROR] if the element is
  /// `null`.
  ///
  /// This is a utility method that can reduce the need for null checks in
  /// other places.
  static ElementKind of(Element? element) {
    if (element == null) {
      return ERROR;
    }
    return element.kind;
  }
}

/// The location of an element within the element model.
///
/// Clients may not extend, implement or mix-in this class.
abstract class ElementLocation {
  /// The path to the element whose location is represented by this object.
  ///
  /// Clients must not modify the returned array.
  List<String> get components;

  /// The encoded representation of this location that can be used to create a
  /// location that is equal to this location.
  String get encoding;
}

/// An object that can be used to visit an element structure.
///
/// Clients may not extend, implement or mix-in this class. There are classes
/// that implement this interface that provide useful default behaviors in
/// `package:analyzer/dart/element/visitor.dart`. A couple of the most useful
/// include
/// * SimpleElementVisitor which implements every visit method by doing nothing,
/// * RecursiveElementVisitor which will cause every node in a structure to be
///   visited, and
/// * ThrowingElementVisitor which implements every visit method by throwing an
///   exception.
abstract class ElementVisitor<R> {
  R? visitAugmentationImportElement(AugmentationImportElement element);

  R? visitClassElement(ClassElement element);

  R? visitCompilationUnitElement(CompilationUnitElement element);

  R? visitConstructorElement(ConstructorElement element);

  R? visitEnumElement(EnumElement element);

  R? visitExtensionElement(ExtensionElement element);

  R? visitFieldElement(FieldElement element);

  R? visitFieldFormalParameterElement(FieldFormalParameterElement element);

  R? visitFunctionElement(FunctionElement element);

  R? visitGenericFunctionTypeElement(GenericFunctionTypeElement element);

  R? visitLabelElement(LabelElement element);

  R? visitLibraryAugmentationElement(LibraryAugmentationElement element);

  R? visitLibraryElement(LibraryElement element);

  R? visitLibraryExportElement(LibraryExportElement element);

  R? visitLibraryImportElement(LibraryImportElement element);

  R? visitLocalVariableElement(LocalVariableElement element);

  R? visitMethodElement(MethodElement element);

  R? visitMixinElement(MixinElement element);

  R? visitMultiplyDefinedElement(MultiplyDefinedElement element);

  R? visitParameterElement(ParameterElement element);

  R? visitPartElement(PartElement element);

  R? visitPrefixElement(PrefixElement element);

  R? visitPropertyAccessorElement(PropertyAccessorElement element);

  R? visitSuperFormalParameterElement(SuperFormalParameterElement element);

  R? visitTopLevelVariableElement(TopLevelVariableElement element);

  R? visitTypeAliasElement(TypeAliasElement element);

  R? visitTypeParameterElement(TypeParameterElement element);
}

class LibraryLanguageVersion {
  /// The version for the whole package that contains this library.
  final Version package;

  /// The version specified using `@dart` override, `null` if absent or invalid.
  final Version? override;

  LibraryLanguageVersion({
    required this.package,
    required this.override,
  });

  /// The effective language version for the library.
  Version get effective {
    return override ?? package;
  }
}
