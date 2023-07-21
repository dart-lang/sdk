// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection';

import 'package:_fe_analyzer_shared/src/scanner/string_canonicalizer.dart';
import 'package:_fe_analyzer_shared/src/type_inference/type_analyzer.dart'
    as shared;
import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/analysis/session.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/scope.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/dart/element/type_provider.dart';
import 'package:analyzer/dart/element/type_system.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/src/dart/analysis/experiments.dart';
import 'package:analyzer/src/dart/analysis/session.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/dart/ast/token.dart';
import 'package:analyzer/src/dart/constant/compute.dart';
import 'package:analyzer/src/dart/constant/evaluation.dart';
import 'package:analyzer/src/dart/element/display_string_builder.dart';
import 'package:analyzer/src/dart/element/member.dart';
import 'package:analyzer/src/dart/element/name_union.dart';
import 'package:analyzer/src/dart/element/nullability_eliminator.dart';
import 'package:analyzer/src/dart/element/scope.dart';
import 'package:analyzer/src/dart/element/since_sdk_version.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/dart/element/type_algebra.dart';
import 'package:analyzer/src/dart/element/type_provider.dart';
import 'package:analyzer/src/dart/element/type_system.dart';
import 'package:analyzer/src/dart/resolver/scope.dart'
    show Namespace, NamespaceBuilder;
import 'package:analyzer/src/dart/resolver/variance.dart';
import 'package:analyzer/src/generated/element_type_provider.dart';
import 'package:analyzer/src/generated/engine.dart' show AnalysisContext;
import 'package:analyzer/src/generated/sdk.dart' show DartSdk;
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/generated/utilities_collection.dart';
import 'package:analyzer/src/generated/utilities_dart.dart';
import 'package:analyzer/src/summary2/ast_binary_tokens.dart';
import 'package:analyzer/src/summary2/bundle_reader.dart';
import 'package:analyzer/src/summary2/export.dart';
import 'package:analyzer/src/summary2/macro.dart';
import 'package:analyzer/src/summary2/macro_application_error.dart';
import 'package:analyzer/src/summary2/reference.dart';
import 'package:analyzer/src/task/api/model.dart' show AnalysisTarget;
import 'package:analyzer/src/task/inference_error.dart';
import 'package:analyzer/src/util/file_paths.dart' as file_paths;
import 'package:analyzer/src/utilities/extensions/collection.dart';
import 'package:analyzer/src/utilities/extensions/string.dart';
import 'package:collection/collection.dart';
import 'package:meta/meta.dart';
import 'package:pub_semver/pub_semver.dart';

/// A library augmentation import directive within a library.
///
/// Clients may not extend, implement or mix-in this class.
@experimental
abstract class AugmentationImportElement implements _ExistingElement {
  @Deprecated('Use enclosingElement2 instead')
  @override
  LibraryOrAugmentationElement get enclosingElement;

  @override
  LibraryOrAugmentationElement get enclosingElement2;

  /// The [LibraryAugmentationElement], if [uri] is a
  /// [DirectiveUriWithAugmentation].
  LibraryAugmentationElement? get importedAugmentation;

  /// The offset of the `import` keyword.
  int get importKeywordOffset;

  /// The interpretation of the URI specified in the directive.
  DirectiveUri get uri;
}

class AugmentationImportElementImpl extends _ExistingElementImpl
    implements AugmentationImportElement {
  @override
  final int importKeywordOffset;

  @override
  final DirectiveUri uri;

  AugmentationImportElementImpl({
    required this.importKeywordOffset,
    required this.uri,
  }) : super(null, importKeywordOffset);

  @Deprecated('Use enclosingElement2 instead')
  @override
  LibraryOrAugmentationElementImpl get enclosingElement {
    return super.enclosingElement2 as LibraryOrAugmentationElementImpl;
  }

  @override
  LibraryOrAugmentationElementImpl get enclosingElement2 {
    return super.enclosingElement2 as LibraryOrAugmentationElementImpl;
  }

  @override
  LibraryAugmentationElementImpl? get importedAugmentation {
    final uri = this.uri;
    if (uri is DirectiveUriWithAugmentationImpl) {
      return uri.augmentation;
    }
    return null;
  }

  @override
  ElementKind get kind => ElementKind.AUGMENTATION_IMPORT;

  @override
  T? accept<T>(ElementVisitor<T> visitor) =>
      visitor.visitAugmentationImportElement(this);
}

/// The result of applying augmentations to a [ClassElement].
///
/// Clients may not extend, implement or mix-in this class.
abstract class AugmentedClassElement implements AugmentedInterfaceElement {
  @override
  ClassElement get declaration;
}

class AugmentedClassElementImpl extends AugmentedInterfaceElementImpl
    implements AugmentedClassElement {
  @override
  final ClassElementImpl declaration;

  AugmentedClassElementImpl(this.declaration);
}

/// The result of applying augmentations to an [EnumElement].
///
/// Clients may not extend, implement or mix-in this class.
abstract class AugmentedEnumElement implements AugmentedInterfaceElement {}

class AugmentedEnumElementImpl extends AugmentedInterfaceElementImpl
    implements AugmentedEnumElement {}

/// The result of applying augmentations to an [ExtensionElement].
///
/// Clients may not extend, implement or mix-in this class.
abstract class AugmentedExtensionElement implements AugmentedInstanceElement {}

class AugmentedExtensionElementImpl extends AugmentedInstanceElementImpl
    implements AugmentedExtensionElement {}

/// The result of applying augmentations to an [InlineClassElement].
///
/// Clients may not extend, implement or mix-in this class.
abstract class AugmentedInlineClassElement
    implements AugmentedNamedInstanceElement {}

class AugmentedInlineClassElementImpl extends AugmentedNamedInstanceElementImpl
    implements AugmentedInlineClassElement {}

/// The result of applying augmentations to a [InstanceElement].
///
/// Clients may not extend, implement or mix-in this class.
abstract class AugmentedInstanceElement {
  /// The accessors (getters and setters) declared in this element.
  ///
  /// Declarations are appended, augmentations replace declarations.
  List<PropertyAccessorElement> get accessors;

  /// The declaration (not augmentation) that owns this result.
  InstanceElement get declaration;

  /// The fields declared in this element.
  ///
  /// Declarations are appended, augmentations replace declarations.
  List<FieldElement> get fields;

  /// The metadata associated with this element.
  ///
  /// This is a union of annotations associated with the class declaration and
  /// all its augmentations.
  List<ElementAnnotation> get metadata;

  /// The methods declared in this element.
  ///
  /// Declarations are appended, augmentations replace declarations.
  List<MethodElement> get methods;

  /// Returns the field from [fields] that has the given [name].
  FieldElement? getField(String name);

  /// Returns the getter from [accessors] that has the given [name].
  PropertyAccessorElement? getGetter(String name);

  /// Returns the method from [methods] that has the given [name].
  MethodElement? getMethod(String name);

  /// Returns the setter from [accessors] that has the given [name].
  PropertyAccessorElement? getSetter(String name);
}

abstract class AugmentedInstanceElementImpl
    implements AugmentedInstanceElement {
  @override
  List<FieldElement> fields = [];

  @override
  List<PropertyAccessorElement> accessors = [];

  @override
  List<MethodElement> methods = [];

  @override
  // TODO: implement declaration
  InstanceElement get declaration => throw UnimplementedError();

  @override
  // TODO: implement metadata
  List<ElementAnnotation> get metadata => throw UnimplementedError();

  @override
  FieldElement? getField(String name) {
    final length = fields.length;
    for (var i = 0; i < length; i++) {
      final field = fields[i];
      if (field.name == name) {
        return field;
      }
    }
    return null;
  }

  @override
  PropertyAccessorElement? getGetter(String name) {
    final length = accessors.length;
    for (var i = 0; i < length; i++) {
      final accessor = accessors[i];
      if (accessor.isGetter && accessor.name == name) {
        return accessor;
      }
    }
    return null;
  }

  @override
  MethodElement? getMethod(String name) {
    final length = methods.length;
    for (var i = 0; i < length; i++) {
      final method = methods[i];
      if (method.name == name) {
        return method;
      }
    }
    return null;
  }

  @override
  PropertyAccessorElement? getSetter(String name) {
    final nameLength = name.length;
    final length = accessors.length;
    for (var i = 0; i < length; i++) {
      final accessor = accessors[i];
      if (accessor.isSetter) {
        final accessorName = accessor.name;
        if (accessorName.length == nameLength + 1) {
          if (accessorName.startsWith(name)) {
            return accessor;
          }
        }
      }
    }
    return null;
  }
}

/// The result of applying augmentations to a [InterfaceElement].
///
/// Clients may not extend, implement or mix-in this class.
abstract class AugmentedInterfaceElement
    implements AugmentedNamedInstanceElement {
  @override
  InterfaceElement get declaration;

  /// The interfaces implemented by this element.
  ///
  /// This is a union of interfaces declared by the class declaration and
  /// all its augmentations.
  List<InterfaceType> get interfaces;

  /// The mixins applied by this class or in its augmentations.
  ///
  /// This is a union of mixins applied by the class declaration and all its
  /// augmentations.
  List<InterfaceType> get mixins;
}

abstract class AugmentedInterfaceElementImpl
    extends AugmentedNamedInstanceElementImpl
    implements AugmentedInterfaceElement {
  @override
  List<InterfaceType> interfaces = [];

  @override
  List<InterfaceType> mixins = [];

  @override
  // TODO: implement declaration
  InterfaceElement get declaration => throw UnimplementedError();
}

/// The result of applying augmentations to a [MixinElement].
///
/// Clients may not extend, implement or mix-in this class.
abstract class AugmentedMixinElement extends AugmentedInterfaceElement {
  /// The superclass constraints of this element.
  ///
  /// This is a union of constraints declared by the class declaration and
  /// all its augmentations.
  List<InterfaceType> get superclassConstraints;
}

class AugmentedMixinElementImpl extends AugmentedInterfaceElementImpl
    implements AugmentedMixinElement {
  @override
  final MixinElementImpl declaration;

  @override
  List<InterfaceType> superclassConstraints = [];

  AugmentedMixinElementImpl(this.declaration);
}

/// The result of applying augmentations to a [NamedInstanceElement].
///
/// Clients may not extend, implement or mix-in this class.
abstract class AugmentedNamedInstanceElement
    implements AugmentedInstanceElement {
  /// The constructors declared in this element.
  ///
  /// Declarations are appended, augmentations replace declarations.
  List<ConstructorElement> get constructors;

  @override
  NamedInstanceElement get declaration;

  /// The unnamed constructor from [constructors].
  ConstructorElement? get unnamedConstructor;

  /// Returns the constructor from [constructors] that has the given [name].
  ConstructorElement? getNamedConstructor(String name);
}

abstract class AugmentedNamedInstanceElementImpl
    extends AugmentedInstanceElementImpl
    implements AugmentedNamedInstanceElement {
  @override
  // TODO: implement constructors
  List<ConstructorElement> get constructors => throw UnimplementedError();

  @override
  // TODO: implement declaration
  NamedInstanceElement get declaration => throw UnimplementedError();

  @override
  // TODO: implement unnamedConstructor
  ConstructorElement? get unnamedConstructor => throw UnimplementedError();

  @override
  ConstructorElement? getNamedConstructor(String name) {
    // TODO: implement getNamedConstructor
    throw UnimplementedError();
  }
}

/// A pattern variable that is explicitly declared.
///
/// Clients may not extend, implement or mix-in this class.
abstract class BindPatternVariableElement implements PatternVariableElement {}

class BindPatternVariableElementImpl extends PatternVariableElementImpl
    implements BindPatternVariableElement {
  final DeclaredVariablePatternImpl node;

  /// This flag is set to `true` if this variable clashes with another
  /// pattern variable with the same name within the same pattern.
  bool isDuplicate = false;

  BindPatternVariableElementImpl(this.node, super.name, super.offset);
}

/// An element that represents a class. The class can be defined by either a
/// class declaration (with a class body), a mixin application (without
/// a class body).
///
/// Clients may not extend, implement or mix-in this class.
abstract class ClassElement implements InterfaceElement {
  @experimental
  @override
  ClassElement? get augmentation;

  @experimental
  @override
  ClassElement? get augmentationTarget;

  @experimental
  @override
  AugmentedClassElement? get augmented;

  /// Whether the class or its superclass declares a non-final instance field.
  bool get hasNonFinalField;

  /// Whether the class is abstract. A class is abstract if it has an
  /// explicit `abstract` modifier. Note, that this definition of
  /// <i>abstract</i> is different from <i>has unimplemented members</i>.
  bool get isAbstract;

  /// Whether this class is a base class.
  ///
  /// A class is a base class if it has an explicit `base` modifier, or the
  /// class has a `base` induced modifier and [isSealed] is `true` as well.
  /// The base modifier allows the class to be extended but not implemented.
  bool get isBase;

  /// Whether the class can be instantiated.
  bool get isConstructable;

  /// Whether the class represents the class 'Enum' defined in `dart:core`.
  bool get isDartCoreEnum;

  /// Whether the class represents the class 'Object' defined in `dart:core`.
  bool get isDartCoreObject;

  /// Whether the class has the property where, in a switch, if you cover all
  /// of the subtypes of this element, then the compiler knows that you have
  /// covered all possible instances of the type.
  bool get isExhaustive;

  /// Whether the class is a final class.
  ///
  /// A class is a final class if it has an explicit `final` modifier, or the
  /// class has a `final` induced modifier and [isSealed] is `true` as well.
  /// The final modifier prohibits this class from being extended, implemented,
  /// or mixed in.
  bool get isFinal;

  /// Whether the class is an inline class.
  ///
  /// A class is an inline class if it has an explicit `inline` modifier.
  @experimental
  bool get isInline;

  /// Whether the class is an interface class.
  ///
  /// A class is an interface class if it has an explicit `interface` modifier,
  /// or the class has an `interface` induced modifier and [isSealed] is `true`
  /// as well. The interface modifier allows the class to be implemented, but
  /// not extended or mixed in.
  bool get isInterface;

  /// Whether the class is a mixin application.
  ///
  /// A class is a mixin application if it was declared using the syntax
  /// `class A = B with C;`.
  bool get isMixinApplication;

  /// Whether the class is a mixin class.
  ///
  /// A class is a mixin class if it has an explicit `mixin` modifier.
  bool get isMixinClass;

  /// Whether the class is a sealed class.
  ///
  /// A class is a sealed class if it has an explicit `sealed` modifier.
  bool get isSealed;

  /// Whether the class can validly be used as a mixin when defining
  /// another class.
  ///
  /// For classes defined by a class declaration or a mixin application, the
  /// behavior of this method is defined by the Dart Language Specification
  /// in section 9:
  /// <blockquote>
  /// It is a compile-time error if a declared or derived mixin refers to super.
  /// It is a compile-time error if a declared or derived mixin explicitly
  /// declares a constructor. It is a compile-time error if a mixin is derived
  /// from a class whose superclass is not Object.
  /// </blockquote>
  bool get isValidMixin;

  /// Whether the class, assuming that it is within scope, is extendable to
  /// classes in the given [library].
  bool isExtendableIn(LibraryElement library);

  /// Whether the class, assuming that it is within scope, is
  /// implementable to classes, mixins, and enums in the given [library].
  bool isImplementableIn(LibraryElement library);

  /// Whether the class, assuming that it is within scope, is able to be
  /// mixed-in by classes and enums in the given [library].
  bool isMixableIn(LibraryElement library);
}

/// An [InterfaceElementImpl] which is a class.
class ClassElementImpl extends ClassOrMixinElementImpl
    with _HasAugmentation<ClassElementImpl>
    implements ClassElement {
  late AugmentedClassElement augmentedInternal =
      NotAugmentedClassElementImpl(this);

  /// Initialize a newly created class element to have the given [name] at the
  /// given [offset] in the file that contains the declaration of this element.
  ClassElementImpl(super.name, super.offset);

  @override
  set accessors(List<PropertyAccessorElementImpl> accessors) {
    assert(!isMixinApplication);
    super.accessors = accessors;
  }

  /// If we can find all possible subtypes of this class, return them.
  ///
  /// If the class is final, all its subtypes are declared in this library.
  ///
  /// If the class is sealed, and all its subtypes are either final or sealed,
  /// then these subtypes are all subtypes that are possible.
  List<InterfaceType>? get allSubtypes {
    if (isFinal) {
      final result = <InterfaceType>[];
      for (final element in library.topLevelElements) {
        if (element is InterfaceElement && element != this) {
          final elementThis = element.thisType;
          if (elementThis.asInstanceOf(this) != null) {
            result.add(elementThis);
          }
        }
      }
      return result;
    }

    if (isSealed) {
      final result = <InterfaceType>[];
      for (final element in library.topLevelElements) {
        if (element is ClassElement && element != this) {
          final elementThis = element.thisType;
          if (elementThis.asInstanceOf(this) != null) {
            if (element.isFinal || element.isSealed) {
              result.add(elementThis);
            } else {
              return null;
            }
          }
        }
      }
      return result;
    }

    return null;
  }

  @override
  AugmentedClassElement? get augmented {
    if (isAugmentation) {
      return augmentationTarget?.augmented;
    } else {
      linkedData?.read(this);
      return augmentedInternal;
    }
  }

  @override
  set constructors(List<ConstructorElementImpl> constructors) {
    assert(!isMixinApplication);
    super.constructors = constructors;
  }

  @override
  set fields(List<FieldElementImpl> fields) {
    assert(!isMixinApplication);
    super.fields = fields;
  }

  bool get hasGenerativeConstConstructor {
    return constructors.any((c) => !c.isFactory && c.isConst);
  }

  @override
  bool get hasNonFinalField {
    final classesToVisit = <InterfaceElement>[];
    final visitedClasses = <InterfaceElement>{};
    classesToVisit.add(this);
    while (classesToVisit.isNotEmpty) {
      final currentElement = classesToVisit.removeAt(0);
      if (visitedClasses.add(currentElement)) {
        // check fields
        for (FieldElement field in currentElement.fields) {
          if (!field.isFinal &&
              !field.isConst &&
              !field.isStatic &&
              !field.isSynthetic) {
            return true;
          }
        }
        // check mixins
        for (InterfaceType mixinType in currentElement.mixins) {
          classesToVisit.add(mixinType.element);
        }
        // check super
        final supertype = currentElement.supertype;
        if (supertype != null) {
          classesToVisit.add(supertype.element);
        }
      }
    }
    // not found
    return false;
  }

  /// Return `true` if the class has a concrete `noSuchMethod()` method distinct
  /// from the one declared in class `Object`, as per the Dart Language
  /// Specification (section 10.4).
  bool get hasNoSuchMethod {
    MethodElement? method = lookUpConcreteMethod(
        FunctionElement.NO_SUCH_METHOD_METHOD_NAME, library);
    var definingClass = method?.enclosingElement2 as ClassElement?;
    return definingClass != null && !definingClass.isDartCoreObject;
  }

  @override
  bool get isAbstract {
    return hasModifier(Modifier.ABSTRACT);
  }

  set isAbstract(bool isAbstract) {
    setModifier(Modifier.ABSTRACT, isAbstract);
  }

  @override
  bool get isBase {
    return hasModifier(Modifier.BASE);
  }

  @override
  bool get isConstructable => !isSealed && !isAbstract;

  @override
  bool get isDartCoreEnum {
    return name == 'Enum' && library.isDartCore;
  }

  @override
  bool get isDartCoreObject {
    return name == 'Object' && library.isDartCore;
  }

  bool get isDartCoreRecord {
    return name == 'Record' && library.isDartCore;
  }

  bool get isEnumLike {
    // Must be a concrete class.
    if (isAbstract) {
      return false;
    }

    // With only private non-factory constructors.
    for (var constructor in constructors) {
      if (constructor.isPublic || constructor.isFactory) {
        return false;
      }
    }

    // With 2+ static const fields with the type of this class.
    var numberOfElements = 0;
    for (var field in fields) {
      if (field.isStatic && field.isConst && field.type == thisType) {
        numberOfElements++;
      }
    }
    if (numberOfElements < 2) {
      return false;
    }

    // No subclasses in the library.
    for (var unit in library.units) {
      for (var class_ in unit.classes) {
        if (class_.supertype?.element == this) {
          return false;
        }
      }
    }

    return true;
  }

  @override
  bool get isExhaustive => isSealed;

  @override
  bool get isFinal {
    return hasModifier(Modifier.FINAL);
  }

  set isFinal(bool isFinal) {
    setModifier(Modifier.FINAL, isFinal);
  }

  @override
  bool get isInline {
    return hasModifier(Modifier.INLINE);
  }

  set isInline(bool isInline) {
    setModifier(Modifier.INLINE, isInline);
  }

  @override
  bool get isInterface {
    return hasModifier(Modifier.INTERFACE);
  }

  set isInterface(bool isInterface) {
    setModifier(Modifier.INTERFACE, isInterface);
  }

  bool get isMacro {
    return hasModifier(Modifier.MACRO);
  }

  set isMacro(bool isMacro) {
    setModifier(Modifier.MACRO, isMacro);
  }

  @override
  bool get isMixinApplication {
    return hasModifier(Modifier.MIXIN_APPLICATION);
  }

  /// Set whether this class is a mixin application.
  set isMixinApplication(bool isMixinApplication) {
    setModifier(Modifier.MIXIN_APPLICATION, isMixinApplication);
  }

  @override
  bool get isMixinClass {
    return hasModifier(Modifier.MIXIN_CLASS);
  }

  set isMixinClass(bool isMixinClass) {
    setModifier(Modifier.MIXIN_CLASS, isMixinClass);
  }

  @override
  bool get isSealed {
    return hasModifier(Modifier.SEALED);
  }

  set isSealed(bool isSealed) {
    setModifier(Modifier.SEALED, isSealed);
  }

  @override
  bool get isValidMixin {
    final supertype = this.supertype;
    if (supertype != null && !supertype.isDartCoreObject) {
      return false;
    }
    for (ConstructorElement constructor in constructors) {
      if (!constructor.isSynthetic && !constructor.isFactory) {
        return false;
      }
    }
    return true;
  }

  @override
  set methods(List<MethodElementImpl> methods) {
    assert(!isMixinApplication);
    super.methods = methods;
  }

  @override
  T? accept<T>(ElementVisitor<T> visitor) {
    return visitor.visitClassElement(this);
  }

  @override
  void appendTo(ElementDisplayStringBuilder builder) {
    builder.writeClassElement(this);
  }

  @override
  bool isExtendableIn(LibraryElement library) {
    if (library == this.library) {
      return true;
    }
    return !isInterface && !isFinal && !isSealed;
  }

  @override
  bool isImplementableIn(LibraryElement library) {
    if (library == this.library) {
      return true;
    }
    return !isBase && !isFinal && !isSealed;
  }

  @override
  bool isMixableIn(LibraryElement library) {
    if (library == this.library) {
      return true;
    } else if (this.library.featureSet.isEnabled(Feature.class_modifiers)) {
      return isMixinClass && !isInterface && !isFinal && !isSealed;
    }
    return true;
  }

  @override
  void _buildMixinAppConstructors() {
    // Do nothing if not a mixin application.
    if (!isMixinApplication) {
      return;
    }

    // Assign to break a possible infinite recursion during computing.
    _constructors = const <ConstructorElementImpl>[];

    final superType = supertype;
    if (superType == null) {
      // Shouldn't ever happen, since the only classes with no supertype are
      // Object and mixins, and they aren't a mixin application. But for
      // safety's sake just assume an empty list.
      assert(false);
      _constructors = <ConstructorElementImpl>[];
      return;
    }

    final superElement = superType.element as ClassElementImpl;

    final constructorsToForward = superElement.constructors
        .where((constructor) => constructor.isAccessibleIn(library))
        .where((constructor) => !constructor.isFactory);

    // Figure out the type parameter substitution we need to perform in order
    // to produce constructors for this class.  We want to be robust in the
    // face of errors, so drop any extra type arguments and fill in any missing
    // ones with `dynamic`.
    var superClassParameters = superElement.typeParameters;
    List<DartType> argumentTypes = List<DartType>.filled(
        superClassParameters.length, DynamicTypeImpl.instance);
    for (int i = 0; i < superType.typeArguments.length; i++) {
      if (i >= argumentTypes.length) {
        break;
      }
      argumentTypes[i] = superType.typeArguments[i];
    }
    var substitution =
        Substitution.fromPairs(superClassParameters, argumentTypes);

    bool typeHasInstanceVariables(InterfaceType type) =>
        type.element.fields.any((e) => !e.isSynthetic);

    // Now create an implicit constructor for every constructor found above,
    // substituting type parameters as appropriate.
    _constructors = constructorsToForward.map((superclassConstructor) {
      var name = superclassConstructor.name;
      var implicitConstructor = ConstructorElementImpl(name, -1);
      implicitConstructor.isSynthetic = true;
      implicitConstructor.name = name;
      implicitConstructor.nameOffset = -1;

      var containerRef = reference!.getChild('@constructor');
      var referenceName = name.ifNotEmptyOrElse('new');
      var implicitReference = containerRef.getChild(referenceName);
      implicitConstructor.reference = implicitReference;
      implicitReference.element = implicitConstructor;

      var hasMixinWithInstanceVariables = mixins.any(typeHasInstanceVariables);
      implicitConstructor.isConst =
          superclassConstructor.isConst && !hasMixinWithInstanceVariables;
      List<ParameterElement> superParameters = superclassConstructor.parameters;
      int count = superParameters.length;
      var argumentsForSuperInvocation = <ExpressionImpl>[];
      if (count > 0) {
        var implicitParameters = <ParameterElement>[];
        for (int i = 0; i < count; i++) {
          ParameterElement superParameter = superParameters[i];
          ParameterElementImpl implicitParameter;
          if (superParameter is ConstVariableElement) {
            var constVariable = superParameter as ConstVariableElement;
            implicitParameter = DefaultParameterElementImpl(
              name: superParameter.name,
              nameOffset: -1,
              // ignore: deprecated_member_use_from_same_package
              parameterKind: superParameter.parameterKind,
            )..constantInitializer = constVariable.constantInitializer;
          } else {
            implicitParameter = ParameterElementImpl(
              name: superParameter.name,
              nameOffset: -1,
              // ignore: deprecated_member_use_from_same_package
              parameterKind: superParameter.parameterKind,
            );
          }
          implicitParameter.isConst = superParameter.isConst;
          implicitParameter.isFinal = superParameter.isFinal;
          implicitParameter.isSynthetic = true;
          implicitParameter.type =
              substitution.substituteType(superParameter.type);
          implicitParameters.add(implicitParameter);
          argumentsForSuperInvocation.add(
            SimpleIdentifierImpl(
              StringToken(TokenType.STRING, implicitParameter.name, -1),
            )
              ..staticElement = implicitParameter
              ..staticType = implicitParameter.type,
          );
        }
        implicitConstructor.parameters = implicitParameters.toFixedList();
      }
      implicitConstructor.enclosingElement = this;
      // TODO(scheglov) Why do we manually map parameters types above?
      implicitConstructor.superConstructor =
          ConstructorMember.from(superclassConstructor, superType);

      var isNamed = superclassConstructor.name.isNotEmpty;
      implicitConstructor.constantInitializers = [
        SuperConstructorInvocationImpl(
          superKeyword: Tokens.super_(),
          period: isNamed ? Tokens.period() : null,
          constructorName: isNamed
              ? (SimpleIdentifierImpl(
                  StringToken(TokenType.STRING, superclassConstructor.name, -1),
                )..staticElement = superclassConstructor)
              : null,
          argumentList: ArgumentListImpl(
            leftParenthesis: Tokens.openParenthesis(),
            arguments: argumentsForSuperInvocation,
            rightParenthesis: Tokens.closeParenthesis(),
          ),
        )..staticElement = superclassConstructor,
      ];

      return implicitConstructor;
    }).toList(growable: false);
  }
}

/// An element that is contained within a [ClassElement].
///
/// Clients may not extend, implement or mix-in this class.
abstract class ClassMemberElement implements Element {
  // TODO(brianwilkerson) Either remove this class or rename it to something
  //  more correct.

  @Deprecated('Use enclosingElement2 instead')
  @override
  Element get enclosingElement;

  @override
  Element get enclosingElement2;

  /// Whether the element is a static element.
  ///
  /// A static element is an element that is not associated with a particular
  /// instance, but rather with an entire library or class.
  bool get isStatic;
}

abstract class ClassOrMixinElementImpl extends InterfaceElementImpl {
  /// Initialize a newly created class element to have the given [name] at the
  /// given [offset] in the file that contains the declaration of this element.
  ClassOrMixinElementImpl(super.name, super.offset);

  bool get isBase {
    return hasModifier(Modifier.BASE);
  }

  set isBase(bool isBase) {
    setModifier(Modifier.BASE, isBase);
  }

  /// TODO(scheglov) Do we need a separate kind for `MixinElement`?
  @override
  ElementKind get kind => ElementKind.CLASS;
}

/// An element representing a compilation unit.
///
/// Clients may not extend, implement or mix-in this class.
abstract class CompilationUnitElement implements UriReferencedElement {
  /// The top-level accessors (getters and setters) declared in this
  /// compilation unit.
  List<PropertyAccessorElement> get accessors;

  /// The classes declared in this compilation unit.
  List<ClassElement> get classes;

  /// The library, or library augmentation that encloses this unit.
  @Deprecated('Use enclosingElement2 instead')
  @override
  LibraryOrAugmentationElement get enclosingElement;

  /// The library, or library augmentation that encloses this unit.
  @override
  LibraryOrAugmentationElement get enclosingElement2;

  /// The enums declared in this compilation unit.
  List<EnumElement> get enums;

  /// The extensions declared in this compilation unit.
  List<ExtensionElement> get extensions;

  /// The top-level functions declared in this compilation unit.
  List<FunctionElement> get functions;

  /// The [LineInfo] for the [source].
  LineInfo get lineInfo;

  /// The mixins declared in this compilation unit.
  List<MixinElement> get mixins;

  @override
  AnalysisSession get session;

  /// The top-level variables declared in this compilation unit.
  List<TopLevelVariableElement> get topLevelVariables;

  /// The type aliases declared in this compilation unit.
  List<TypeAliasElement> get typeAliases;

  /// Returns the class defined in this compilation unit that has the given
  /// [name], or `null` if this compilation unit does not define a class with
  /// the given name.
  ClassElement? getClass(String name);

  /// Returns the enum defined in this compilation unit that has the given
  /// [name], or `null` if this compilation unit does not define an enum with
  /// the given name.
  EnumElement? getEnum(String name);
}

/// A concrete implementation of a [CompilationUnitElement].
class CompilationUnitElementImpl extends UriReferencedElementImpl
    implements CompilationUnitElement, MacroTargetElementContainer {
  /// The source that corresponds to this compilation unit.
  @override
  final Source source;

  @override
  LineInfo lineInfo;

  /// The source of the library containing this compilation unit.
  ///
  /// This is the same as the source of the containing [LibraryElement],
  /// except that it does not require the containing [LibraryElement] to be
  /// computed.
  @override
  final Source librarySource;

  /// A list containing all of the top-level accessors (getters and setters)
  /// contained in this compilation unit.
  List<PropertyAccessorElementImpl> _accessors = const [];

  List<ClassElementImpl> _classes = const [];

  /// A list containing all of the enums contained in this compilation unit.
  List<EnumElementImpl> _enums = const [];

  /// A list containing all of the extensions contained in this compilation
  /// unit.
  List<ExtensionElementImpl> _extensions = const [];

  /// A list containing all of the top-level functions contained in this
  /// compilation unit.
  List<FunctionElementImpl> _functions = const [];

  List<MixinElementImpl> _mixins = const [];

  /// A list containing all of the type aliases contained in this compilation
  /// unit.
  List<TypeAliasElementImpl> _typeAliases = const [];

  /// A list containing all of the variables contained in this compilation unit.
  List<TopLevelVariableElementImpl> _variables = const [];

  ElementLinkedData? linkedData;

  /// Initialize a newly created compilation unit element to have the given
  /// [name].
  CompilationUnitElementImpl({
    required this.source,
    required this.librarySource,
    required this.lineInfo,
  }) : super(null, -1);

  @override
  List<PropertyAccessorElementImpl> get accessors {
    return _accessors;
  }

  /// Set the top-level accessors (getters and setters) contained in this
  /// compilation unit to the given [accessors].
  set accessors(List<PropertyAccessorElementImpl> accessors) {
    for (var accessor in accessors) {
      accessor.enclosingElement = this;
    }
    _accessors = accessors;
  }

  @override
  List<Element> get children => [
        ...super.children,
        ...accessors,
        ...classes,
        ...enums,
        ...extensions,
        ...functions,
        ...mixins,
        ...typeAliases,
        ...topLevelVariables,
      ];

  @override
  List<ClassElementImpl> get classes {
    return _classes;
  }

  /// Set the classes contained in this compilation unit to [classes].
  set classes(List<ClassElementImpl> classes) {
    for (var class_ in classes) {
      class_.enclosingElement = this;
    }
    _classes = classes;
  }

  @Deprecated('Use enclosingElement2 instead')
  @override
  LibraryOrAugmentationElement get enclosingElement =>
      super.enclosingElement2 as LibraryOrAugmentationElement;

  @override
  LibraryOrAugmentationElement get enclosingElement2 =>
      super.enclosingElement2 as LibraryOrAugmentationElement;

  @override
  CompilationUnitElementImpl get enclosingUnit {
    return this;
  }

  @override
  List<EnumElementImpl> get enums {
    return _enums;
  }

  /// Set the enums contained in this compilation unit to the given [enums].
  set enums(List<EnumElementImpl> enums) {
    for (final element in enums) {
      element.enclosingElement = this;
    }
    _enums = enums;
  }

  @override
  List<ExtensionElementImpl> get extensions {
    return _extensions;
  }

  /// Set the extensions contained in this compilation unit to the given
  /// [extensions].
  set extensions(List<ExtensionElementImpl> extensions) {
    for (var extension in extensions) {
      extension.enclosingElement = this;
    }
    _extensions = extensions;
  }

  @override
  List<FunctionElementImpl> get functions {
    return _functions;
  }

  /// Set the top-level functions contained in this compilation unit to the
  ///  given[functions].
  set functions(List<FunctionElementImpl> functions) {
    for (var function in functions) {
      function.enclosingElement = this;
    }
    _functions = functions;
  }

  @override
  int get hashCode => source.hashCode;

  @override
  String get identifier => '${source.uri}';

  @override
  ElementKind get kind => ElementKind.COMPILATION_UNIT;

  @override
  List<ElementAnnotation> get metadata {
    linkedData?.read(this);
    return super.metadata;
  }

  @override
  List<MixinElementImpl> get mixins {
    return _mixins;
  }

  /// Set the mixins contained in this compilation unit to the given [mixins].
  set mixins(List<MixinElementImpl> mixins) {
    for (var mixin_ in mixins) {
      mixin_.enclosingElement = this;
    }
    _mixins = mixins;
  }

  @override
  AnalysisSession get session => enclosingElement2.session;

  @override
  List<TopLevelVariableElementImpl> get topLevelVariables {
    return _variables;
  }

  /// Set the top-level variables contained in this compilation unit to the
  ///  given[variables].
  set topLevelVariables(List<TopLevelVariableElementImpl> variables) {
    for (var variable in variables) {
      variable.enclosingElement = this;
    }
    _variables = variables;
  }

  @override
  List<TypeAliasElementImpl> get typeAliases {
    return _typeAliases;
  }

  /// Set the type aliases contained in this compilation unit to [typeAliases].
  set typeAliases(List<TypeAliasElementImpl> typeAliases) {
    for (var typeAlias in typeAliases) {
      typeAlias.enclosingElement = this;
    }
    _typeAliases = typeAliases;
  }

  @override
  TypeParameterizedElementMixin? get typeParameterContext => null;

  @override
  bool operator ==(Object other) =>
      other is CompilationUnitElementImpl && source == other.source;

  @override
  T? accept<T>(ElementVisitor<T> visitor) =>
      visitor.visitCompilationUnitElement(this);

  @override
  void appendTo(ElementDisplayStringBuilder builder) {
    builder.writeCompilationUnitElement(this);
  }

  @override
  ClassElement? getClass(String className) {
    for (final class_ in classes) {
      if (class_.name == className) {
        return class_;
      }
    }
    return null;
  }

  @override
  EnumElement? getEnum(String name) {
    for (final element in enums) {
      if (element.name == name) {
        return element;
      }
    }
    return null;
  }

  void setLinkedData(Reference reference, ElementLinkedData linkedData) {
    this.reference = reference;
    reference.element = this;

    this.linkedData = linkedData;
  }
}

/// A [FieldElement] for a 'const' or 'final' field that has an initializer.
///
/// TODO(paulberry): we should rename this class to reflect the fact that it's
/// used for both const and final fields.  However, we shouldn't do so until
/// we've created an API for reading the values of constants; until that API is
/// available, clients are likely to read constant values by casting to
/// ConstFieldElementImpl, so it would be a breaking change to rename this
/// class.
class ConstFieldElementImpl extends FieldElementImpl with ConstVariableElement {
  /// Initialize a newly created synthetic field element to have the given
  /// [name] and [offset].
  ConstFieldElementImpl(super.name, super.offset);

  @override
  Expression? get constantInitializer {
    linkedData?.read(this);
    return super.constantInitializer;
  }
}

/// A [LocalVariableElement] for a local 'const' variable that has an
/// initializer.
class ConstLocalVariableElementImpl extends LocalVariableElementImpl
    with ConstVariableElement {
  /// Initialize a newly created local variable element to have the given [name]
  /// and [offset].
  ConstLocalVariableElementImpl(super.name, super.offset);
}

/// An element representing a constructor or a factory method defined within a
/// class.
///
/// Clients may not extend, implement or mix-in this class.
abstract class ConstructorElement
    implements ClassMemberElement, ExecutableElement, ConstantEvaluationTarget {
  @experimental
  @override
  ConstructorElement? get augmentation;

  @experimental
  @override
  ConstructorElement? get augmentationTarget;

  @override
  ConstructorElement get declaration;

  @override
  String get displayName;

  @Deprecated('Use enclosingElement2 instead')
  @override
  InterfaceElement get enclosingElement;

  @override
  NamedInstanceElement get enclosingElement2;

  /// Whether the constructor is a const constructor.
  bool get isConst;

  /// Whether the constructor can be used as a default constructor - unnamed,
  /// and has no required parameters.
  bool get isDefaultConstructor;

  /// Whether the constructor represents a factory constructor.
  bool get isFactory;

  /// Whether the constructor represents a generative constructor.
  bool get isGenerative;

  @override
  String get name;

  /// The offset of the character immediately following the last character of
  /// this constructor's name, or `null` if not named.
  ///
  /// TODO(migration): encapsulate [nameEnd] and [periodOffset]?
  int? get nameEnd;

  /// The offset of the `.` before this constructor name, or `null` if not
  /// named.
  int? get periodOffset;

  /// The constructor to which this constructor is redirecting, or `null` if
  /// this constructor does not redirect to another constructor or if the
  /// library containing this constructor has not yet been resolved.
  ConstructorElement? get redirectedConstructor;

  @Deprecated('Use returnType2 instead')
  @override
  InterfaceType get returnType;

  @override
  DartType get returnType2;
}

/// A concrete implementation of a [ConstructorElement].
class ConstructorElementImpl extends ExecutableElementImpl
    with ConstructorElementMixin
    implements ConstructorElement {
  /// The super-constructor which this constructor is invoking, or `null` if
  /// this constructor is not generative, or is redirecting, or the
  /// super-constructor is not resolved, or the enclosing class is `Object`.
  ///
  /// TODO(scheglov) We cannot have both super and redirecting constructors.
  /// So, ideally we should have some kind of "either" or "variant" here.
  ConstructorElement? _superConstructor;

  /// The constructor to which this constructor is redirecting.
  ConstructorElement? _redirectedConstructor;

  /// The initializers for this constructor (used for evaluating constant
  /// instance creation expressions).
  List<ConstructorInitializer> _constantInitializers = const [];

  @override
  int? periodOffset;

  @override
  int? nameEnd;

  /// For every constructor we initially set this flag to `true`, and then
  /// set it to `false` during computing constant values if we detect that it
  /// is a part of a cycle.
  bool isCycleFree = true;

  @override
  bool isConstantEvaluated = false;

  @override
  ConstructorElementImpl? augmentation;

  @override
  ConstructorElementImpl? augmentationTarget;

  /// Initialize a newly created constructor element to have the given [name]
  /// and [offset].
  ConstructorElementImpl(super.name, super.offset);

  /// Return the constant initializers for this element, which will be empty if
  /// there are no initializers, or `null` if there was an error in the source.
  List<ConstructorInitializer> get constantInitializers {
    linkedData?.read(this);
    return _constantInitializers;
  }

  set constantInitializers(List<ConstructorInitializer> constantInitializers) {
    _constantInitializers = constantInitializers;
  }

  @override
  ConstructorElement get declaration => this;

  @override
  String get displayName {
    var className = enclosingElement2.name;
    var name = this.name;
    if (name.isNotEmpty) {
      return '$className.$name';
    } else {
      return className;
    }
  }

  @Deprecated('Use enclosingElement2 instead')
  @override
  InterfaceElement get enclosingElement =>
      super.enclosingElement2 as InterfaceElementImpl;

  @override
  NamedInstanceElement get enclosingElement2 =>
      super.enclosingElement2 as NamedInstanceElement;

  @override
  bool get isConst {
    return hasModifier(Modifier.CONST);
  }

  /// Set whether this constructor represents a 'const' constructor.
  set isConst(bool isConst) {
    setModifier(Modifier.CONST, isConst);
  }

  @override
  bool get isFactory {
    return hasModifier(Modifier.FACTORY);
  }

  /// Set whether this constructor represents a factory method.
  set isFactory(bool isFactory) {
    setModifier(Modifier.FACTORY, isFactory);
  }

  @override
  ElementKind get kind => ElementKind.CONSTRUCTOR;

  @override
  int get nameLength {
    final nameEnd = this.nameEnd;
    if (nameEnd == null) {
      return 0;
    } else {
      return nameEnd - nameOffset;
    }
  }

  @override
  Element get nonSynthetic {
    return isSynthetic ? enclosingElement2 : this;
  }

  @override
  ConstructorElement? get redirectedConstructor {
    linkedData?.read(this);
    return _redirectedConstructor;
  }

  set redirectedConstructor(ConstructorElement? redirectedConstructor) {
    _redirectedConstructor = redirectedConstructor;
  }

  @Deprecated('Use returnType2 instead')
  @override
  InterfaceType get returnType =>
      ElementTypeProvider.current.getExecutableReturnType(this)
          as InterfaceType;

  @override
  set returnType(DartType returnType) {
    assert(false);
  }

  @override
  DartType get returnType2 =>
      ElementTypeProvider.current.getExecutableReturnType(this);

  @override
  DartType get returnTypeInternal {
    var result = _returnType;
    if (result != null) {
      return result;
    }

    final augmentedDeclaration = enclosingElement2.augmented?.declaration;
    result = augmentedDeclaration?.thisType;
    result ??= InvalidTypeImpl.instance;
    return _returnType = result;
  }

  ConstructorElement? get superConstructor {
    linkedData?.read(this);
    return _superConstructor;
  }

  set superConstructor(ConstructorElement? superConstructor) {
    _superConstructor = superConstructor;
  }

  @override
  FunctionType get type => ElementTypeProvider.current.getExecutableType(this);

  @override
  set type(FunctionType type) {
    assert(false);
  }

  @override
  FunctionType get typeInternal {
    // TODO(scheglov) Remove "element" in the breaking changes branch.
    return _type ??= FunctionTypeImpl(
      typeFormals: typeParameters,
      parameters: parameters,
      returnType: returnType2,
      nullabilitySuffix: _noneOrStarSuffix,
    );
  }

  @override
  T? accept<T>(ElementVisitor<T> visitor) =>
      visitor.visitConstructorElement(this);

  @override
  void appendTo(ElementDisplayStringBuilder builder) {
    builder.writeConstructorElement(this);
  }

  /// Ensures that dependencies of this constructor, such as default values
  /// of formal parameters, are evaluated.
  void computeConstantDependencies() {
    if (!isConstantEvaluated) {
      computeConstants(
        declaredVariables: context.declaredVariables,
        constants: [this],
        featureSet: library.featureSet,
        configuration: ConstantEvaluationConfiguration(),
      );
    }
  }
}

/// Common implementation for methods defined in [ConstructorElement].
mixin ConstructorElementMixin implements ConstructorElement {
  @override
  bool get isDefaultConstructor {
    // unnamed
    if (name.isNotEmpty) {
      return false;
    }
    // no required parameters
    for (ParameterElement parameter in parameters) {
      if (parameter.isRequired) {
        return false;
      }
    }
    // OK, can be used as default constructor
    return true;
  }

  @override
  bool get isGenerative {
    return !isFactory;
  }
}

/// A [TopLevelVariableElement] for a top-level 'const' variable that has an
/// initializer.
class ConstTopLevelVariableElementImpl extends TopLevelVariableElementImpl
    with ConstVariableElement {
  /// Initialize a newly created synthetic top-level variable element to have
  /// the given [name] and [offset].
  ConstTopLevelVariableElementImpl(super.name, super.offset);

  @override
  Expression? get constantInitializer {
    linkedData?.read(this);
    return super.constantInitializer;
  }
}

/// Mixin used by elements that represent constant variables and have
/// initializers.
///
/// Note that in correct Dart code, all constant variables must have
/// initializers.  However, analyzer also needs to handle incorrect Dart code,
/// in which case there might be some constant variables that lack initializers.
/// This interface is only used for constant variables that have initializers.
///
/// This class is not intended to be part of the public API for analyzer.
mixin ConstVariableElement implements ElementImpl, ConstantEvaluationTarget {
  /// If this element represents a constant variable, and it has an initializer,
  /// a copy of the initializer for the constant.  Otherwise `null`.
  ///
  /// Note that in correct Dart code, all constant variables must have
  /// initializers.  However, analyzer also needs to handle incorrect Dart code,
  /// in which case there might be some constant variables that lack
  /// initializers.
  Expression? constantInitializer;

  EvaluationResultImpl? _evaluationResult;

  EvaluationResultImpl? get evaluationResult => _evaluationResult;

  set evaluationResult(EvaluationResultImpl? evaluationResult) {
    _evaluationResult = evaluationResult;
  }

  @override
  bool get isConstantEvaluated => _evaluationResult != null;

  /// Return a representation of the value of this variable, forcing the value
  /// to be computed if it had not previously been computed, or `null` if either
  /// this variable was not declared with the 'const' modifier or if the value
  /// of this variable could not be computed because of errors.
  DartObject? computeConstantValue() {
    if (evaluationResult == null) {
      final library = this.library;
      // TODO(scheglov) https://github.com/dart-lang/sdk/issues/47915
      if (library == null) {
        throw StateError(
          '[library: null][this: ($runtimeType) $this]'
          '[enclosingElement: $enclosingElement2]'
          '[reference: $reference]',
        );
      }
      computeConstants(
        declaredVariables: context.declaredVariables,
        constants: [this],
        featureSet: library.featureSet,
        configuration: ConstantEvaluationConfiguration(),
      );
    }
    return evaluationResult?.value;
  }
}

/// A [FieldFormalParameterElementImpl] for parameters that have an initializer.
class DefaultFieldFormalParameterElementImpl
    extends FieldFormalParameterElementImpl with ConstVariableElement {
  /// Initialize a newly created parameter element to have the given [name] and
  /// [nameOffset].
  DefaultFieldFormalParameterElementImpl({
    required super.name,
    required super.nameOffset,
    required super.parameterKind,
  });

  @override
  String? get defaultValueCode {
    return constantInitializer?.toSource();
  }
}

/// A [ParameterElement] for parameters that have an initializer.
class DefaultParameterElementImpl extends ParameterElementImpl
    with ConstVariableElement {
  /// Initialize a newly created parameter element to have the given [name] and
  /// [nameOffset].
  DefaultParameterElementImpl({
    required super.name,
    required super.nameOffset,
    required super.parameterKind,
  });

  @override
  String? get defaultValueCode {
    return constantInitializer?.toSource();
  }
}

class DefaultSuperFormalParameterElementImpl
    extends SuperFormalParameterElementImpl with ConstVariableElement {
  /// Initialize a newly created parameter element to have the given [name] and
  /// [nameOffset].
  DefaultSuperFormalParameterElementImpl({
    required super.name,
    required super.nameOffset,
    required super.parameterKind,
  });

  @override
  String? get defaultValueCode {
    final constantInitializer = this.constantInitializer;
    if (constantInitializer != null) {
      return constantInitializer.toSource();
    }

    if (_superConstructorParameterDefaultValue != null) {
      return superConstructorParameter?.defaultValueCode;
    }

    return null;
  }

  @override
  EvaluationResultImpl? get evaluationResult {
    if (constantInitializer != null) {
      return super.evaluationResult;
    }

    var superConstructorParameter = this.superConstructorParameter?.declaration;
    if (superConstructorParameter is ParameterElementImpl) {
      return superConstructorParameter.evaluationResult;
    }

    return null;
  }

  DartObject? get _superConstructorParameterDefaultValue {
    var superDefault = superConstructorParameter?.computeConstantValue();
    var superDefaultType = superDefault?.type;
    var libraryElement = library;
    if (superDefaultType != null &&
        libraryElement != null &&
        libraryElement.typeSystem.isSubtypeOf(superDefaultType, type)) {
      return superDefault;
    }

    return null;
  }

  @override
  DartObject? computeConstantValue() {
    if (constantInitializer != null) {
      return super.computeConstantValue();
    }

    return _superConstructorParameterDefaultValue;
  }
}

/// [ImportElementPrefix] that is used together with `deferred`.
///
/// Clients may not extend, implement or mix-in this class.
abstract class DeferredImportElementPrefix implements ImportElementPrefix {}

class DeferredImportElementPrefixImpl extends ImportElementPrefixImpl
    implements DeferredImportElementPrefix {
  DeferredImportElementPrefixImpl({
    required super.element,
  });
}

/// Meaning of a URI referenced in a directive.
///
/// Clients may not extend, implement or mix-in this class.
abstract class DirectiveUri {}

class DirectiveUriImpl implements DirectiveUri {}

/// [DirectiveUriWithSource] that references a [LibraryAugmentationElement].
///
/// Clients may not extend, implement or mix-in this class.
abstract class DirectiveUriWithAugmentation extends DirectiveUriWithSource {
  /// The library augmentation referenced by the [source].
  LibraryAugmentationElement get augmentation;
}

class DirectiveUriWithAugmentationImpl extends DirectiveUriWithSourceImpl
    implements DirectiveUriWithAugmentation {
  @override
  late LibraryAugmentationElementImpl augmentation;

  DirectiveUriWithAugmentationImpl({
    required super.relativeUriString,
    required super.relativeUri,
    required super.source,
    required this.augmentation,
  });
}

/// [DirectiveUriWithSource] that references a [LibraryElement].
///
/// Clients may not extend, implement or mix-in this class.
abstract class DirectiveUriWithLibrary extends DirectiveUriWithSource {
  /// The library referenced by the [source].
  LibraryElement get library;
}

class DirectiveUriWithLibraryImpl extends DirectiveUriWithSourceImpl
    implements DirectiveUriWithLibrary {
  @override
  late LibraryElementImpl library;

  DirectiveUriWithLibraryImpl({
    required super.relativeUriString,
    required super.relativeUri,
    required super.source,
    required this.library,
  });

  DirectiveUriWithLibraryImpl.read({
    required super.relativeUriString,
    required super.relativeUri,
    required super.source,
  });
}

/// [DirectiveUriWithRelativeUriString] that can be parsed into a relative URI.
///
/// Clients may not extend, implement or mix-in this class.
abstract class DirectiveUriWithRelativeUri
    extends DirectiveUriWithRelativeUriString {
  /// The relative URI, parsed from [relativeUriString].
  Uri get relativeUri;
}

class DirectiveUriWithRelativeUriImpl
    extends DirectiveUriWithRelativeUriStringImpl
    implements DirectiveUriWithRelativeUri {
  @override
  final Uri relativeUri;

  DirectiveUriWithRelativeUriImpl({
    required super.relativeUriString,
    required this.relativeUri,
  });
}

/// [DirectiveUri] for which we can get its relative URI string.
///
/// Clients may not extend, implement or mix-in this class.
abstract class DirectiveUriWithRelativeUriString extends DirectiveUri {
  /// The relative URI string specified in code.
  String get relativeUriString;
}

class DirectiveUriWithRelativeUriStringImpl extends DirectiveUriImpl
    implements DirectiveUriWithRelativeUriString {
  @override
  final String relativeUriString;

  DirectiveUriWithRelativeUriStringImpl({
    required this.relativeUriString,
  });
}

/// [DirectiveUriWithRelativeUri] that resolves to a [Source].
///
/// Clients may not extend, implement or mix-in this class.
abstract class DirectiveUriWithSource extends DirectiveUriWithRelativeUri {
  /// The result of resolving [relativeUri] against the enclosing URI.
  Source get source;
}

class DirectiveUriWithSourceImpl extends DirectiveUriWithRelativeUriImpl
    implements DirectiveUriWithSource {
  @override
  final Source source;

  DirectiveUriWithSourceImpl({
    required super.relativeUriString,
    required super.relativeUri,
    required this.source,
  });
}

/// [DirectiveUriWithSource] that references a [CompilationUnitElement].
///
/// Clients may not extend, implement or mix-in this class.
abstract class DirectiveUriWithUnit extends DirectiveUriWithSource {
  /// The unit referenced by the [source].
  CompilationUnitElement get unit;
}

class DirectiveUriWithUnitImpl extends DirectiveUriWithRelativeUriImpl
    implements DirectiveUriWithUnit {
  @override
  final CompilationUnitElementImpl unit;

  DirectiveUriWithUnitImpl({
    required super.relativeUriString,
    required super.relativeUri,
    required this.unit,
  });

  @override
  Source get source => unit.source;
}

/// The synthetic element representing the declaration of the type `dynamic`.
class DynamicElementImpl extends ElementImpl implements TypeDefiningElement {
  /// Return the unique instance of this class.
  static DynamicElementImpl get instance => DynamicTypeImpl.instance.element;

  /// Initialize a newly created instance of this class. Instances of this class
  /// should <b>not</b> be created except as part of creating the type
  /// associated with this element. The single instance of this class should be
  /// accessed through the method [instance].
  DynamicElementImpl() : super(Keyword.DYNAMIC.lexeme, -1) {
    setModifier(Modifier.SYNTHETIC, true);
  }

  @override
  ElementKind get kind => ElementKind.DYNAMIC;

  @override
  T? accept<T>(ElementVisitor<T> visitor) => null;
}

/// The base class for all of the elements in the element model. Generally
/// speaking, the element model is a semantic model of the program that
/// represents things that are declared with a name and hence can be referenced
/// elsewhere in the code.
///
/// There are two exceptions to the general case. First, there are elements in
/// the element model that are created for the convenience of various kinds of
/// analysis but that do not have any corresponding declaration within the
/// source code. Such elements are marked as being <i>synthetic</i>. Examples of
/// synthetic elements include
/// * default constructors in classes that do not define any explicit
///   constructors,
/// * getters and setters that are induced by explicit field declarations,
/// * fields that are induced by explicit declarations of getters and setters,
///   and
/// * functions representing the initialization expression for a variable.
///
/// Second, there are elements in the element model that do not have a name.
/// These correspond to unnamed functions and exist in order to more accurately
/// represent the semantic structure of the program.
///
/// Clients may not extend, implement or mix-in this class.
abstract class Element implements AnalysisTarget {
  /// A list of this element's children.
  ///
  /// There is no guarantee of the order in which the children will be included.
  List<Element> get children;

  /// The analysis context in which this element is defined.
  AnalysisContext get context;

  /// The declaration of this element.
  ///
  /// If the element is a view on an element, e.g. a method from an interface
  /// type, with substituted type parameters, return the corresponding element
  /// from the class, without any substitutions. If this element is already a
  /// declaration (or a synthetic element, e.g. a synthetic property accessor),
  /// return itself.
  Element? get declaration;

  /// The display name of this element, possibly the empty string if the
  /// element does not have a name.
  ///
  /// In most cases the name and the display name are the same. Differences
  /// though are cases such as setters where the name of some setter `set f(x)`
  /// is `f=`, instead of `f`.
  String get displayName;

  /// The content of the documentation comment (including delimiters) for this
  /// element, or `null` if this element does not or cannot have documentation.
  String? get documentationComment;

  /// The element that either physically or logically encloses this element.
  ///
  /// This will be `null` if this element is a library because libraries are
  /// the top-level elements in the model.
  @Deprecated('Use enclosingElement2 instead')
  Element? get enclosingElement;

  /// The element that either physically or logically encloses this element.
  ///
  /// This will be `null` if this element is a library because libraries are
  /// the top-level elements in the model.
  Element? get enclosingElement2;

  /// Whether the element has an annotation of the form `@alwaysThrows`.
  bool get hasAlwaysThrows;

  /// Whether the element has an annotation of the form `@deprecated`
  /// or `@Deprecated('..')`.
  bool get hasDeprecated;

  /// Whether the element has an annotation of the form `@doNotStore`.
  bool get hasDoNotStore;

  /// Whether the element has an annotation of the form `@factory`.
  bool get hasFactory;

  /// Whether the element has an annotation of the form `@internal`.
  bool get hasInternal;

  /// Whether the element has an annotation of the form `@isTest`.
  bool get hasIsTest;

  /// Whether the element has an annotation of the form `@isTestGroup`.
  bool get hasIsTestGroup;

  /// Whether the element has an annotation of the form `@JS(..)`.
  bool get hasJS;

  /// Whether the element has an annotation of the form `@literal`.
  bool get hasLiteral;

  /// Whether the element has an annotation of the form `@mustBeOverridden`.
  bool get hasMustBeOverridden;

  /// Whether the element has an annotation of the form `@mustCallSuper`.
  bool get hasMustCallSuper;

  /// Whether the element has an annotation of the form `@nonVirtual`.
  bool get hasNonVirtual;

  /// Whether the element has an annotation of the form `@optionalTypeArgs`.
  bool get hasOptionalTypeArgs;

  /// Whether the element has an annotation of the form `@override`.
  bool get hasOverride;

  /// Whether the element has an annotation of the form `@protected`.
  bool get hasProtected;

  /// Whether the element has an annotation of the form `@reopen`.
  bool get hasReopen;

  /// Whether the element has an annotation of the form `@required`.
  bool get hasRequired;

  /// Whether the element has an annotation of the form `@sealed`.
  bool get hasSealed;

  /// Whether the element has an annotation of the form `@useResult`
  /// or `@UseResult('..')`.
  bool get hasUseResult;

  /// Whether the element has an annotation of the form `@visibleForOverriding`.
  bool get hasVisibleForOverriding;

  /// Whether the element has an annotation of the form `@visibleForTemplate`.
  bool get hasVisibleForTemplate;

  /// Whether the element has an annotation of the form `@visibleForTesting`.
  bool get hasVisibleForTesting;

  /// Whether the element has an annotation of the form
  /// `@visibleOutsideTemplate`.
  bool get hasVisibleOutsideTemplate;

  /// The unique integer identifier of this element.
  int get id;

  /// Whether the element is private.
  ///
  /// Private elements are visible only within the library in which they are
  /// declared.
  bool get isPrivate;

  /// Whether the element is public.
  ///
  /// Public elements are visible within any library that imports the library
  /// in which they are declared.
  bool get isPublic;

  /// Whether the element is synthetic.
  ///
  /// A synthetic element is an element that is not represented in the source
  /// code explicitly, but is implied by the source code, such as the default
  /// constructor for a class that does not explicitly define any constructors.
  bool get isSynthetic;

  /// The kind of element that this is.
  ElementKind get kind;

  /// Tibrary that contains this element.
  ///
  /// This will be the element itself if it is a library element. This will be
  /// `null` if this element is [MultiplyDefinedElement] that is not contained
  /// in a library.
  LibraryElement? get library;

  /// The location of this element in the element model.
  ///
  /// The object can be used to locate this element at a later time.
  ElementLocation? get location;

  /// All of the metadata associated with this element.
  ///
  /// The array will be empty if the element does not have any metadata or if
  /// the library containing this element has not yet been resolved.
  List<ElementAnnotation> get metadata;

  /// The name of this element, or `null` if this element does not have a name.
  String? get name;

  /// The length of the name of this element in the file that contains the
  /// declaration of this element, or `0` if this element does not have a name.
  int get nameLength;

  /// The offset of the name of this element in the file that contains the
  /// declaration of this element, or `-1` if this element is synthetic, does
  /// not have a name, or otherwise does not have an offset.
  int get nameOffset;

  /// The non-synthetic element that caused this element to be created.
  ///
  /// If this element is not synthetic, then the element itself is returned.
  ///
  /// If this element is synthetic, then the corresponding non-synthetic
  /// element is returned. For example, for a synthetic getter of a
  /// non-synthetic field the field is returned; for a synthetic constructor
  /// the enclosing class is returned.
  Element get nonSynthetic;

  /// The analysis session in which this element is defined.
  AnalysisSession? get session;

  /// The version where this SDK API was added.
  ///
  /// A `@Since()` annotation can be applied to a library declaration,
  /// any public declaration in a library, or in a class, or to an optional
  /// parameter, etc.
  ///
  /// The returned version is "effective", so that if a library is annotated
  /// then all elements of the library inherit it; or if a class is annotated
  /// then all members and constructors of the class inherit it.
  ///
  /// If multiple `@Since()` annotations apply to the same element, the latest
  /// version takes precedence.
  ///
  /// Returns `null` if the element is not declared in SDK, or does not have
  /// a `@Since()` annotation applicable to it.
  Version? get sinceSdkVersion;

  @override
  Source? get source;

  /// Uses the given [visitor] to visit this element.
  ///
  /// Returns the value returned by the visitor as a result of visiting this
  /// element.
  T? accept<T>(ElementVisitor<T> visitor);

  /// Returns the presentation of this element as it should appear when
  /// presented to users.
  ///
  /// If [withNullability] is `true`, then [NullabilitySuffix.question] and
  /// [NullabilitySuffix.star] in types will be represented as `?` and `*`.
  /// [NullabilitySuffix.none] does not have any explicit presentation.
  ///
  /// If [withNullability] is `false`, nullability suffixes will not be
  /// included into the presentation.
  ///
  /// If [multiline] is `true`, the string may be wrapped over multiple lines
  /// with newlines to improve formatting. For example function signatures may
  /// be formatted as if they had trailing commas.
  ///
  /// Clients should not depend on the content of the returned value as it will
  /// be changed if doing so would improve the UX.
  String getDisplayString({
    required bool withNullability,
    bool multiline = false,
  });

  /// Returns a display name for the given element that includes the path to the
  /// compilation unit in which the type is defined. If [shortName] is `null`
  /// then [displayName] will be used as the name of this element. Otherwise
  /// the provided name will be used.
  // TODO(brianwilkerson) Make the parameter optional.
  String getExtendedDisplayName(String? shortName);

  /// Whether the element, assuming that it is within scope, is accessible to
  /// code in the given [library].
  ///
  /// This is defined by the Dart Language Specification in section 6.2:
  /// <blockquote>
  /// A declaration <i>m</i> is accessible to a library <i>L</i> if <i>m</i> is
  /// declared in <i>L</i> or if <i>m</i> is public.
  /// </blockquote>
  bool isAccessibleIn(LibraryElement library);

  /// Returns either this element or the most immediate ancestor of this element
  /// for which the [predicate] returns `true`, or `null` if there is no such
  /// element.
  E? thisOrAncestorMatching<E extends Element>(
    bool Function(Element) predicate,
  );

  /// Returns either this element or the most immediate ancestor of this element
  /// that has the given type, or `null` if there is no such element.
  E? thisOrAncestorOfType<E extends Element>();

  /// Uses the given [visitor] to visit all of the children of this element.
  /// There is no guarantee of the order in which the children will be visited.
  void visitChildren(ElementVisitor visitor);
}

/// A single annotation associated with an element.
///
/// Clients may not extend, implement or mix-in this class.
abstract class ElementAnnotation implements ConstantEvaluationTarget {
  /// The errors that were produced while computing a value for this
  /// annotation, or `null` if no value has been computed.
  ///
  /// If a value has been produced but no errors were generated, then the
  /// list will be empty.
  List<AnalysisError>? get constantEvaluationErrors;

  /// Returns the element referenced by this annotation.
  ///
  /// In valid code this element can be a [PropertyAccessorElement] getter
  /// of a constant top-level variable, or a constant static field of a
  /// class; or a constant [ConstructorElement].
  ///
  /// In invalid code this element can be `null`, or a reference to any
  /// other element.
  Element? get element;

  /// Whether the annotation marks the associated function as always throwing.
  bool get isAlwaysThrows;

  /// Whether the annotation marks the associated element as being deprecated.
  bool get isDeprecated;

  /// Whether the annotation marks the associated element as not to be stored.
  bool get isDoNotStore;

  /// Whether the annotation marks the associated member as a factory.
  bool get isFactory;

  /// Whether the annotation marks the associated class and its subclasses as
  /// being immutable.
  bool get isImmutable;

  /// Whether the annotation marks the associated element as being internal to
  /// its package.
  bool get isInternal;

  /// Whether the annotation marks the associated member as running a single
  /// test.
  bool get isIsTest;

  /// Whether the annotation marks the associated member as running a test
  /// group.
  bool get isIsTestGroup;

  /// Whether the annotation marks the associated element with the `JS`
  /// annotation.
  bool get isJS;

  /// Whether the annotation marks the associated constructor as being literal.
  bool get isLiteral;

  /// Whether the annotation marks the associated member as requiring
  /// subclasses to override this member.
  bool get isMustBeOverridden;

  /// Whether the annotation marks the associated member as requiring
  /// overriding methods to call super.
  bool get isMustCallSuper;

  /// Whether the annotation marks the associated member as being non-virtual.
  bool get isNonVirtual;

  /// Whether the annotation marks the associated type as having "optional"
  /// type arguments.
  bool get isOptionalTypeArgs;

  /// Whether the annotation marks the associated method as being expected to
  /// override an inherited method.
  bool get isOverride;

  /// Whether the annotation marks the associated member as being protected.
  bool get isProtected;

  /// Whether the annotation marks the associated class as implementing a proxy
  /// object.
  bool get isProxy;

  /// Whether the marks the associated member as being reopened.
  bool get isReopen;

  /// Whether the annotation marks the associated member as being required.
  bool get isRequired;

  /// Whether the annotation marks the associated class as being sealed.
  bool get isSealed;

  /// Whether the annotation marks the associated class as being intended to
  /// be used as an annotation.
  bool get isTarget;

  /// Whether the annotation marks the associated returned element as
  /// requiring use.
  bool get isUseResult;

  /// Whether the annotation marks the associated member as being visible for
  /// overriding only.
  bool get isVisibleForOverriding;

  /// Whether the annotation marks the associated member as being visible for
  /// template files.
  bool get isVisibleForTemplate;

  /// Whether the annotation marks the associated member as being visible for
  /// testing.
  bool get isVisibleForTesting;

  /// Whether the annotation marks the associated member as being visible
  /// outside of template files.
  bool get isVisibleOutsideTemplate;

  /// Returns a representation of the value of this annotation, forcing the
  /// value to be computed if it had not previously been computed, or `null`
  /// if the value of this annotation could not be computed because of errors.
  DartObject? computeConstantValue();

  /// Returns a textual description of this annotation in a form approximating
  /// valid source.
  ///
  /// The returned string will not be valid source primarily in the case where
  /// the annotation itself is not well-formed.
  String toSource();
}

/// A concrete implementation of an [ElementAnnotation].
class ElementAnnotationImpl implements ElementAnnotation {
  /// The name of the top-level variable used to mark that a function always
  /// throws, for dead code purposes.
  static const String _alwaysThrowsVariableName = 'alwaysThrows';

  /// The name of the class used to mark an element as being deprecated.
  static const String _deprecatedClassName = 'Deprecated';

  /// The name of the top-level variable used to mark an element as being
  /// deprecated.
  static const String _deprecatedVariableName = 'deprecated';

  /// The name of the top-level variable used to mark an element as not to be
  /// stored.
  static const String _doNotStoreVariableName = 'doNotStore';

  /// The name of the top-level variable used to mark a method as being a
  /// factory.
  static const String _factoryVariableName = 'factory';

  /// The name of the top-level variable used to mark a class and its subclasses
  /// as being immutable.
  static const String _immutableVariableName = 'immutable';

  /// The name of the top-level variable used to mark an element as being
  /// internal to its package.
  static const String _internalVariableName = 'internal';

  /// The name of the top-level variable used to mark a constructor as being
  /// literal.
  static const String _literalVariableName = 'literal';

  /// The name of the top-level variable used to mark a type as having
  /// "optional" type arguments.
  static const String _optionalTypeArgsVariableName = 'optionalTypeArgs';

  /// The name of the top-level variable used to mark a function as running
  /// a single test.
  static const String _isTestVariableName = 'isTest';

  /// The name of the top-level variable used to mark a function as running
  /// a test group.
  static const String _isTestGroupVariableName = 'isTestGroup';

  /// The name of the class used to JS annotate an element.
  static const String _jsClassName = 'JS';

  /// The name of `_js_annotations` library, used to define JS annotations.
  static const String _jsLibName = '_js_annotations';

  /// The name of `meta` library, used to define analysis annotations.
  static const String _metaLibName = 'meta';

  /// The name of `meta_meta` library, used to define annotations for other
  /// annotations.
  static const String _metaMetaLibName = 'meta_meta';

  /// The name of the top-level variable used to mark a method as requiring
  /// subclasses to override this method.
  static const String _mustBeOverridden = 'mustBeOverridden';

  /// The name of the top-level variable used to mark a method as requiring
  /// overriders to call super.
  static const String _mustCallSuperVariableName = 'mustCallSuper';

  /// The name of `angular.meta` library, used to define angular analysis
  /// annotations.
  static const String _angularMetaLibName = 'angular.meta';

  /// The name of the top-level variable used to mark a member as being nonVirtual.
  static const String _nonVirtualVariableName = 'nonVirtual';

  /// The name of the top-level variable used to mark a method as being expected
  /// to override an inherited method.
  static const String _overrideVariableName = 'override';

  /// The name of the top-level variable used to mark a method as being
  /// protected.
  static const String _protectedVariableName = 'protected';

  /// The name of the top-level variable used to mark a class or mixin as being
  /// reopened.
  static const String _reopenVariableName = 'reopen';

  /// The name of the class used to mark a parameter as being required.
  static const String _requiredClassName = 'Required';

  /// The name of the top-level variable used to mark a parameter as being
  /// required.
  static const String _requiredVariableName = 'required';

  /// The name of the top-level variable used to mark a class as being sealed.
  static const String _sealedVariableName = 'sealed';

  /// The name of the class used to annotate a class as an annotation with a
  /// specific set of target element kinds.
  static const String _targetClassName = 'Target';

  /// The name of the class used to mark a returned element as requiring use.
  static const String _useResultClassName = 'UseResult';

  /// The name of the top-level variable used to mark a returned element as
  /// requiring use.
  static const String _useResultVariableName = 'useResult';

  /// The name of the top-level variable used to mark a member as being visible
  /// for overriding only.
  static const String _visibleForOverridingName = 'visibleForOverriding';

  /// The name of the top-level variable used to mark a method as being
  /// visible for templates.
  static const String _visibleForTemplateVariableName = 'visibleForTemplate';

  /// The name of the top-level variable used to mark a method as being
  /// visible for testing.
  static const String _visibleForTestingVariableName = 'visibleForTesting';

  /// The name of the top-level variable used to mark a method as being
  /// visible outside of template files.
  static const String _visibleOutsideTemplateVariableName =
      'visibleOutsideTemplate';

  @override
  Element? element;

  /// The compilation unit in which this annotation appears.
  CompilationUnitElementImpl compilationUnit;

  /// The AST of the annotation itself, cloned from the resolved AST for the
  /// source code.
  late AnnotationImpl annotationAst;

  /// The result of evaluating this annotation as a compile-time constant
  /// expression, or `null` if the compilation unit containing the variable has
  /// not been resolved.
  EvaluationResultImpl? evaluationResult;

  /// Initialize a newly created annotation. The given [compilationUnit] is the
  /// compilation unit in which the annotation appears.
  ElementAnnotationImpl(this.compilationUnit);

  @override
  List<AnalysisError> get constantEvaluationErrors =>
      evaluationResult?.errors ?? const <AnalysisError>[];

  @override
  AnalysisContext get context => compilationUnit.library.context;

  @override
  bool get isAlwaysThrows => _isPackageMetaGetter(_alwaysThrowsVariableName);

  @override
  bool get isConstantEvaluated => evaluationResult != null;

  bool get isDartInternalSince {
    final element = this.element;
    if (element is ConstructorElement) {
      return element.enclosingElement2.name == 'Since' &&
          element.library.source.uri.toString() == 'dart:_internal';
    }
    return false;
  }

  @override
  bool get isDeprecated {
    final element = this.element;
    if (element is ConstructorElement) {
      return element.library.isDartCore &&
          element.enclosingElement2.name == _deprecatedClassName;
    } else if (element is PropertyAccessorElement) {
      return element.library.isDartCore &&
          element.name == _deprecatedVariableName;
    }
    return false;
  }

  @override
  bool get isDoNotStore => _isPackageMetaGetter(_doNotStoreVariableName);

  @override
  bool get isFactory => _isPackageMetaGetter(_factoryVariableName);

  @override
  bool get isImmutable => _isPackageMetaGetter(_immutableVariableName);

  @override
  bool get isInternal => _isPackageMetaGetter(_internalVariableName);

  @override
  bool get isIsTest => _isPackageMetaGetter(_isTestVariableName);

  @override
  bool get isIsTestGroup => _isPackageMetaGetter(_isTestGroupVariableName);

  @override
  bool get isJS =>
      _isConstructor(libraryName: _jsLibName, className: _jsClassName);

  @override
  bool get isLiteral => _isPackageMetaGetter(_literalVariableName);

  @override
  bool get isMustBeOverridden => _isPackageMetaGetter(_mustBeOverridden);

  @override
  bool get isMustCallSuper => _isPackageMetaGetter(_mustCallSuperVariableName);

  @override
  bool get isNonVirtual => _isPackageMetaGetter(_nonVirtualVariableName);

  @override
  bool get isOptionalTypeArgs =>
      _isPackageMetaGetter(_optionalTypeArgsVariableName);

  @override
  bool get isOverride => _isDartCoreGetter(_overrideVariableName);

  /// Return `true` if this is an annotation of the form
  /// `@pragma("vm:entry-point")`.
  bool get isPragmaVmEntryPoint {
    if (_isConstructor(libraryName: 'dart.core', className: 'pragma')) {
      var value = computeConstantValue();
      var nameValue = value?.getField('name');
      return nameValue?.toStringValue() == 'vm:entry-point';
    }
    return false;
  }

  @override
  bool get isProtected => _isPackageMetaGetter(_protectedVariableName);

  @override
  bool get isProxy => false;

  @override
  bool get isReopen => _isPackageMetaGetter(_reopenVariableName);

  @override
  bool get isRequired =>
      _isConstructor(
          libraryName: _metaLibName, className: _requiredClassName) ||
      _isPackageMetaGetter(_requiredVariableName);

  @override
  bool get isSealed => _isPackageMetaGetter(_sealedVariableName);

  @override
  bool get isTarget => _isConstructor(
      libraryName: _metaMetaLibName, className: _targetClassName);

  @override
  bool get isUseResult =>
      _isConstructor(
          libraryName: _metaLibName, className: _useResultClassName) ||
      _isPackageMetaGetter(_useResultVariableName);

  @override
  bool get isVisibleForOverriding =>
      _isPackageMetaGetter(_visibleForOverridingName);

  @override
  bool get isVisibleForTemplate => _isTopGetter(
      libraryName: _angularMetaLibName, name: _visibleForTemplateVariableName);

  @override
  bool get isVisibleForTesting =>
      _isPackageMetaGetter(_visibleForTestingVariableName);

  @override
  bool get isVisibleOutsideTemplate => _isTopGetter(
      libraryName: _angularMetaLibName,
      name: _visibleOutsideTemplateVariableName);

  @override
  LibraryElement get library => compilationUnit.library;

  /// Get the library containing this annotation.
  @override
  Source get librarySource => compilationUnit.librarySource;

  @override
  Source get source => compilationUnit.source;

  @override
  DartObject? computeConstantValue() {
    if (evaluationResult == null) {
      computeConstants(
        declaredVariables: context.declaredVariables,
        constants: [this],
        featureSet: compilationUnit.library.featureSet,
        configuration: ConstantEvaluationConfiguration(),
      );
    }
    return evaluationResult?.value;
  }

  @override
  String toSource() => annotationAst.toSource();

  @override
  String toString() => '@$element';

  bool _isConstructor({
    required String libraryName,
    required String className,
  }) {
    final element = this.element;
    return element is ConstructorElement &&
        element.enclosingElement2.name == className &&
        element.library.name == libraryName;
  }

  bool _isDartCoreGetter(String name) {
    return _isTopGetter(
      libraryName: 'dart.core',
      name: name,
    );
  }

  bool _isPackageMetaGetter(String name) {
    return _isTopGetter(
      libraryName: _metaLibName,
      name: name,
    );
  }

  bool _isTopGetter({
    required String libraryName,
    required String name,
  }) {
    final element = this.element;
    return element is PropertyAccessorElement &&
        element.name == name &&
        element.library.name == libraryName;
  }
}

/// A base class for concrete implementations of an [Element].
abstract class ElementImpl implements Element {
  static const _metadataFlag_isReady = 1 << 0;
  static const _metadataFlag_hasDeprecated = 1 << 1;
  static const _metadataFlag_hasOverride = 1 << 2;

  /// Cached values for [sinceSdkVersion].
  ///
  /// Only very few elements have `@Since()` annotations, so instead of adding
  /// an instance field to [ElementImpl], we attach this information this way.
  /// We ask it only when [Modifier.HAS_SINCE_SDK_VERSION_VALUE] is `true`, so
  /// don't pay for a hash lookup when we know that the result is `null`.
  static final Expando<Version> _sinceSdkVersion = Expando<Version>();

  static int _NEXT_ID = 0;

  @override
  final int id = _NEXT_ID++;

  /// The enclosing element of this element, or `null` if this element is at the
  /// root of the element structure.
  ElementImpl? _enclosingElement;

  Reference? reference;

  /// The name of this element.
  String? _name;

  /// The offset of the name of this element in the file that contains the
  /// declaration of this element.
  int _nameOffset = 0;

  /// A bit-encoded form of the modifiers associated with this element.
  int _modifiers = 0;

  /// A list containing all of the metadata associated with this element.
  List<ElementAnnotation> _metadata = const [];

  /// Cached flags denoting presence of specific annotations in [_metadata].
  int _metadataFlags = 0;

  /// A cached copy of the calculated hashCode for this element.
  int? _cachedHashCode;

  /// A cached copy of the calculated location for this element.
  ElementLocation? _cachedLocation;

  /// The documentation comment for this element.
  String? _docComment;

  /// The offset of the beginning of the element's code in the file that
  /// contains the element, or `null` if the element is synthetic.
  int? _codeOffset;

  /// The length of the element's code, or `null` if the element is synthetic.
  int? _codeLength;

  /// Initialize a newly created element to have the given [name] at the given
  /// [_nameOffset].
  ElementImpl(this._name, this._nameOffset, {this.reference}) {
    reference?.element = this;
  }

  @override
  List<Element> get children => const [];

  /// The length of the element's code, or `null` if the element is synthetic.
  int? get codeLength => _codeLength;

  /// The offset of the beginning of the element's code in the file that
  /// contains the element, or `null` if the element is synthetic.
  int? get codeOffset => _codeOffset;

  @override
  AnalysisContext get context {
    return _enclosingElement!.context;
  }

  @override
  Element get declaration => this;

  @override
  String get displayName => _name ?? '';

  @override
  String? get documentationComment => _docComment;

  /// The documentation comment source for this element.
  set documentationComment(String? doc) {
    _docComment = doc;
  }

  @Deprecated('Use enclosingElement2 instead')
  @override
  Element? get enclosingElement => _enclosingElement;

  /// Set the enclosing element of this element to the given [element].
  set enclosingElement(Element? element) {
    _enclosingElement = element as ElementImpl?;
  }

  @override
  Element? get enclosingElement2 => _enclosingElement;

  /// Return the enclosing unit element (which might be the same as `this`), or
  /// `null` if this element is not contained in any compilation unit.
  CompilationUnitElementImpl get enclosingUnit {
    return _enclosingElement!.enclosingUnit;
  }

  @override
  bool get hasAlwaysThrows {
    final metadata = this.metadata;
    for (var i = 0; i < metadata.length; i++) {
      var annotation = metadata[i];
      if (annotation.isAlwaysThrows) {
        return true;
      }
    }
    return false;
  }

  @override
  bool get hasDeprecated {
    return (_getMetadataFlags() & _metadataFlag_hasDeprecated) != 0;
  }

  @override
  bool get hasDoNotStore {
    final metadata = this.metadata;
    for (var i = 0; i < metadata.length; i++) {
      var annotation = metadata[i];
      if (annotation.isDoNotStore) {
        return true;
      }
    }
    return false;
  }

  @override
  bool get hasFactory {
    final metadata = this.metadata;
    for (var i = 0; i < metadata.length; i++) {
      var annotation = metadata[i];
      if (annotation.isFactory) {
        return true;
      }
    }
    return false;
  }

  @override
  int get hashCode {
    // TODO: We might want to re-visit this optimization in the future.
    // We cache the hash code value as this is a very frequently called method.
    return _cachedHashCode ??= location.hashCode;
  }

  @override
  bool get hasInternal {
    final metadata = this.metadata;
    for (var i = 0; i < metadata.length; i++) {
      var annotation = metadata[i];
      if (annotation.isInternal) {
        return true;
      }
    }
    return false;
  }

  @override
  bool get hasIsTest {
    final metadata = this.metadata;
    for (var i = 0; i < metadata.length; i++) {
      var annotation = metadata[i];
      if (annotation.isIsTest) {
        return true;
      }
    }
    return false;
  }

  @override
  bool get hasIsTestGroup {
    final metadata = this.metadata;
    for (var i = 0; i < metadata.length; i++) {
      var annotation = metadata[i];
      if (annotation.isIsTestGroup) {
        return true;
      }
    }
    return false;
  }

  @override
  bool get hasJS {
    final metadata = this.metadata;
    for (var i = 0; i < metadata.length; i++) {
      var annotation = metadata[i];
      if (annotation.isJS) {
        return true;
      }
    }
    return false;
  }

  @override
  bool get hasLiteral {
    final metadata = this.metadata;
    for (var i = 0; i < metadata.length; i++) {
      var annotation = metadata[i];
      if (annotation.isLiteral) {
        return true;
      }
    }
    return false;
  }

  @override
  bool get hasMustBeOverridden {
    final metadata = this.metadata;
    for (var i = 0; i < metadata.length; i++) {
      var annotation = metadata[i];
      if (annotation.isMustBeOverridden) {
        return true;
      }
    }
    return false;
  }

  @override
  bool get hasMustCallSuper {
    final metadata = this.metadata;
    for (var i = 0; i < metadata.length; i++) {
      var annotation = metadata[i];
      if (annotation.isMustCallSuper) {
        return true;
      }
    }
    return false;
  }

  @override
  bool get hasNonVirtual {
    final metadata = this.metadata;
    for (var i = 0; i < metadata.length; i++) {
      var annotation = metadata[i];
      if (annotation.isNonVirtual) {
        return true;
      }
    }
    return false;
  }

  @override
  bool get hasOptionalTypeArgs {
    final metadata = this.metadata;
    for (var i = 0; i < metadata.length; i++) {
      var annotation = metadata[i];
      if (annotation.isOptionalTypeArgs) {
        return true;
      }
    }
    return false;
  }

  @override
  bool get hasOverride {
    return (_getMetadataFlags() & _metadataFlag_hasOverride) != 0;
  }

  /// Return `true` if this element has an annotation of the form
  /// `@pragma("vm:entry-point")`.
  bool get hasPragmaVmEntryPoint {
    final metadata = this.metadata;
    for (var i = 0; i < metadata.length; i++) {
      var annotation = metadata[i];
      if (annotation is ElementAnnotationImpl &&
          annotation.isPragmaVmEntryPoint) {
        return true;
      }
    }
    return false;
  }

  @override
  bool get hasProtected {
    final metadata = this.metadata;
    for (var i = 0; i < metadata.length; i++) {
      var annotation = metadata[i];
      if (annotation.isProtected) {
        return true;
      }
    }
    return false;
  }

  @override
  bool get hasReopen {
    final metadata = this.metadata;
    for (var i = 0; i < metadata.length; i++) {
      var annotation = metadata[i];
      if (annotation.isReopen) {
        return true;
      }
    }
    return false;
  }

  @override
  bool get hasRequired {
    final metadata = this.metadata;
    for (var i = 0; i < metadata.length; i++) {
      var annotation = metadata[i];
      if (annotation.isRequired) {
        return true;
      }
    }
    return false;
  }

  @override
  bool get hasSealed {
    final metadata = this.metadata;
    for (var i = 0; i < metadata.length; i++) {
      var annotation = metadata[i];
      if (annotation.isSealed) {
        return true;
      }
    }
    return false;
  }

  @override
  bool get hasUseResult {
    final metadata = this.metadata;
    for (var i = 0; i < metadata.length; i++) {
      var annotation = metadata[i];
      if (annotation.isUseResult) {
        return true;
      }
    }
    return false;
  }

  @override
  bool get hasVisibleForOverriding {
    final metadata = this.metadata;
    for (var i = 0; i < metadata.length; i++) {
      var annotation = metadata[i];
      if (annotation.isVisibleForOverriding) {
        return true;
      }
    }
    return false;
  }

  @override
  bool get hasVisibleForTemplate {
    final metadata = this.metadata;
    for (var i = 0; i < metadata.length; i++) {
      var annotation = metadata[i];
      if (annotation.isVisibleForTemplate) {
        return true;
      }
    }
    return false;
  }

  @override
  bool get hasVisibleForTesting {
    final metadata = this.metadata;
    for (var i = 0; i < metadata.length; i++) {
      var annotation = metadata[i];
      if (annotation.isVisibleForTesting) {
        return true;
      }
    }
    return false;
  }

  @override
  bool get hasVisibleOutsideTemplate {
    final metadata = this.metadata;
    for (var i = 0; i < metadata.length; i++) {
      var annotation = metadata[i];
      if (annotation.isVisibleOutsideTemplate) {
        return true;
      }
    }
    return false;
  }

  /// Return an identifier that uniquely identifies this element among the
  /// children of this element's parent.
  String get identifier => name!;

  bool get isNonFunctionTypeAliasesEnabled {
    return library!.featureSet.isEnabled(Feature.nonfunction_type_aliases);
  }

  @override
  bool get isPrivate {
    final name = this.name;
    if (name == null) {
      return true;
    }
    return Identifier.isPrivateName(name);
  }

  @override
  bool get isPublic => !isPrivate;

  @override
  bool get isSynthetic {
    return hasModifier(Modifier.SYNTHETIC);
  }

  /// Set whether this element is synthetic.
  set isSynthetic(bool isSynthetic) {
    setModifier(Modifier.SYNTHETIC, isSynthetic);
  }

  bool get isTempAugmentation {
    return hasModifier(Modifier.TEMP_AUGMENTATION);
  }

  set isTempAugmentation(bool value) {
    setModifier(Modifier.TEMP_AUGMENTATION, value);
  }

  @override
  LibraryElementImpl? get library => thisOrAncestorOfType();

  @override
  Source? get librarySource => library?.source;

  @override
  ElementLocation get location {
    return _cachedLocation ??= ElementLocationImpl.con1(this);
  }

  @override
  List<ElementAnnotation> get metadata {
    return _metadata;
  }

  set metadata(List<ElementAnnotation> metadata) {
    _metadata = metadata;
  }

  @override
  String? get name => _name;

  /// Changes the name of this element.
  set name(String? name) {
    _name = name;
  }

  @override
  int get nameLength => displayName.length;

  @override
  int get nameOffset => _nameOffset;

  /// Sets the offset of the name of this element in the file that contains the
  /// declaration of this element.
  set nameOffset(int offset) {
    _nameOffset = offset;
  }

  @override
  Element get nonSynthetic => this;

  @override
  AnalysisSession? get session {
    return enclosingElement2?.session;
  }

  @override
  Version? get sinceSdkVersion {
    if (!hasModifier(Modifier.HAS_SINCE_SDK_VERSION_COMPUTED)) {
      setModifier(Modifier.HAS_SINCE_SDK_VERSION_COMPUTED, true);
      final result = SinceSdkVersionComputer().compute(this);
      if (result != null) {
        _sinceSdkVersion[this] = result;
        setModifier(Modifier.HAS_SINCE_SDK_VERSION_VALUE, true);
      }
    }
    if (hasModifier(Modifier.HAS_SINCE_SDK_VERSION_VALUE)) {
      return _sinceSdkVersion[this];
    }
    return null;
  }

  @override
  Source? get source {
    return enclosingElement2?.source;
  }

  /// Return the context to resolve type parameters in, or `null` if neither
  /// this element nor any of its ancestors is of a kind that can declare type
  /// parameters.
  TypeParameterizedElementMixin? get typeParameterContext {
    return _enclosingElement?.typeParameterContext;
  }

  NullabilitySuffix get _noneOrStarSuffix {
    return library!.isNonNullableByDefault == true
        ? NullabilitySuffix.none
        : NullabilitySuffix.star;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is ElementImpl &&
        other.kind == kind &&
        other.location == location;
  }

  /// Append a textual representation of this element to the given [builder].
  void appendTo(ElementDisplayStringBuilder builder) {
    builder.writeAbstractElement(this);
  }

  /// Set this element as the enclosing element for given [element].
  void encloseElement(ElementImpl element) {
    element.enclosingElement = this;
  }

  /// Set this element as the enclosing element for given [elements].
  void encloseElements(List<Element> elements) {
    for (Element element in elements) {
      (element as ElementImpl)._enclosingElement = this;
    }
  }

  @override
  String getDisplayString({
    required bool withNullability,
    bool multiline = false,
  }) {
    var builder = ElementDisplayStringBuilder(
      skipAllDynamicArguments: false,
      withNullability: withNullability,
      multiline: multiline,
    );
    appendTo(builder);
    return builder.toString();
  }

  @override
  String getExtendedDisplayName(String? shortName) {
    shortName ??= displayName;
    final source = this.source;
    return "$shortName (${source?.fullName})";
  }

  /// Return `true` if this element has the given [modifier] associated with it.
  bool hasModifier(Modifier modifier) =>
      BooleanArray.get(_modifiers, modifier.ordinal);

  @override
  bool isAccessibleIn(LibraryElement library) {
    if (Identifier.isPrivateName(name!)) {
      return library == this.library;
    }
    return true;
  }

  void resetMetadataFlags() {
    _metadataFlags = 0;
  }

  /// Set the code range for this element.
  void setCodeRange(int offset, int length) {
    _codeOffset = offset;
    _codeLength = length;
  }

  /// Set whether the given [modifier] is associated with this element to
  /// correspond to the given [value].
  void setModifier(Modifier modifier, bool value) {
    _modifiers = BooleanArray.set(_modifiers, modifier.ordinal, value);
  }

  @override
  E? thisOrAncestorMatching<E extends Element>(
    bool Function(Element) predicate,
  ) {
    Element? element = this;
    while (element != null && !predicate(element)) {
      element = element.enclosingElement2;
    }
    return element as E?;
  }

  @override
  E? thisOrAncestorOfType<E extends Element>() {
    Element? element = this;
    while (element != null && element is! E) {
      if (element is CompilationUnitElement) {
        element = element.enclosingElement2;
      } else {
        element = element.enclosingElement2;
      }
    }
    return element as E?;
  }

  @override
  String toString() {
    return getDisplayString(withNullability: true);
  }

  /// Use the given [visitor] to visit all of the children of this element.
  /// There is no guarantee of the order in which the children will be visited.
  @override
  void visitChildren(ElementVisitor visitor) {
    for (Element child in children) {
      child.accept(visitor);
    }
  }

  /// Return flags that denote presence of a few specific annotations.
  int _getMetadataFlags() {
    var result = _metadataFlags;

    // Has at least `_metadataFlag_isReady`.
    if (result != 0) {
      return result;
    }

    final metadata = this.metadata;
    for (var i = 0; i < metadata.length; i++) {
      var annotation = metadata[i];
      if (annotation.isDeprecated) {
        result |= _metadataFlag_hasDeprecated;
      } else if (annotation.isOverride) {
        result |= _metadataFlag_hasOverride;
      }
    }

    result |= _metadataFlag_isReady;
    return _metadataFlags = result;
  }
}

/// Abstract base class for elements whose type is guaranteed to be a function
/// type.
abstract class ElementImplWithFunctionType implements Element {
  /// Gets the element's return type, without going through the indirection of
  /// [ElementTypeProvider].
  ///
  /// In most cases, the element's `returnType` getter should be used instead.
  DartType get returnTypeInternal;

  /// Gets the element's type, without going through the indirection of
  /// [ElementTypeProvider].
  ///
  /// In most cases, the element's `type` getter should be used instead.
  FunctionType get typeInternal;
}

/// A concrete implementation of an [ElementLocation].
class ElementLocationImpl implements ElementLocation {
  /// The character used to separate components in the encoded form.
  static const int _separatorChar = 0x3B;

  /// The path to the element whose location is represented by this object.
  late final List<String> _components;

  /// Initialize a newly created location to represent the given [element].
  ElementLocationImpl.con1(Element element) {
    List<String> components = <String>[];
    Element? ancestor = element;
    while (ancestor != null) {
      components.insert(0, (ancestor as ElementImpl).identifier);
      ancestor = ancestor.enclosingElement2;
    }
    _components = components.toFixedList();
  }

  /// Initialize a newly created location from the given [encoding].
  ElementLocationImpl.con2(String encoding) {
    _components = _decode(encoding);
  }

  /// Initialize a newly created location from the given [components].
  ElementLocationImpl.con3(List<String> components) {
    _components = components;
  }

  @override
  List<String> get components => _components;

  @override
  String get encoding {
    StringBuffer buffer = StringBuffer();
    int length = _components.length;
    for (int i = 0; i < length; i++) {
      if (i > 0) {
        buffer.writeCharCode(_separatorChar);
      }
      _encode(buffer, _components[i]);
    }
    return buffer.toString();
  }

  @override
  int get hashCode => Object.hashAll(_components);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other is ElementLocationImpl) {
      List<String> otherComponents = other._components;
      int length = _components.length;
      if (otherComponents.length != length) {
        return false;
      }
      for (int i = 0; i < length; i++) {
        if (_components[i] != otherComponents[i]) {
          return false;
        }
      }
      return true;
    }
    return false;
  }

  @override
  String toString() => encoding;

  /// Decode the [encoding] of a location into a list of components and return
  /// the components.
  List<String> _decode(String encoding) {
    List<String> components = <String>[];
    StringBuffer buffer = StringBuffer();
    int index = 0;
    int length = encoding.length;
    while (index < length) {
      int currentChar = encoding.codeUnitAt(index);
      if (currentChar == _separatorChar) {
        if (index + 1 < length &&
            encoding.codeUnitAt(index + 1) == _separatorChar) {
          buffer.writeCharCode(_separatorChar);
          index += 2;
        } else {
          components.add(buffer.toString());
          buffer = StringBuffer();
          index++;
        }
      } else {
        buffer.writeCharCode(currentChar);
        index++;
      }
    }
    components.add(buffer.toString());
    return components;
  }

  /// Append an encoded form of the given [component] to the given [buffer].
  void _encode(StringBuffer buffer, String component) {
    int length = component.length;
    for (int i = 0; i < length; i++) {
      int currentChar = component.codeUnitAt(i);
      if (currentChar == _separatorChar) {
        buffer.writeCharCode(_separatorChar);
      }
      buffer.writeCharCode(currentChar);
    }
  }
}

/// An element that represents an enum.
///
/// Clients may not extend, implement or mix-in this class.
abstract class EnumElement implements InterfaceElement {
  @experimental
  @override
  EnumElement? get augmentation;

  @experimental
  @override
  EnumElement? get augmentationTarget;

  @experimental
  @override
  AugmentedEnumElement? get augmented;
}

/// An [InterfaceElementImpl] which is an enum.
class EnumElementImpl extends InterfaceElementImpl implements EnumElement {
  late AugmentedEnumElement augmentedInternal =
      NotAugmentedEnumElementImpl(this);

  /// Initialize a newly created class element to have the given [name] at the
  /// given [offset] in the file that contains the declaration of this element.
  EnumElementImpl(super.name, super.offset);

  @override
  EnumElementImpl? get augmentation {
    // TODO(scheglov) implement
    return null;
  }

  @override
  // TODO: implement augmentationTarget
  EnumElementImpl? get augmentationTarget => throw UnimplementedError();

  @override
  AugmentedEnumElement? get augmented {
    linkedData?.read(this);
    return augmentedInternal;
  }

  List<FieldElementImpl> get constants {
    return fields.where((field) => field.isEnumConstant).toList();
  }

  @override
  ElementKind get kind => ElementKind.ENUM;

  ConstFieldElementImpl? get valuesField {
    for (var field in fields) {
      if (field is ConstFieldElementImpl &&
          field.name == 'values' &&
          field.isSyntheticEnumField) {
        return field;
      }
    }
    return null;
  }

  @override
  T? accept<T>(ElementVisitor<T> visitor) {
    return visitor.visitEnumElement(this);
  }

  @override
  void appendTo(ElementDisplayStringBuilder builder) {
    builder.writeEnumElement(this);
  }
}

/// An element representing an executable object, including functions, methods,
/// constructors, getters, and setters.
///
/// Clients may not extend, implement or mix-in this class.
abstract class ExecutableElement implements FunctionTypedElement {
  /// The immediate augmentation of this element, or `null` if there are no
  /// augmentations.
  ///
  /// [ExecutableElement.augmentationTarget] will point back at this element.
  @experimental
  ExecutableElement? get augmentation;

  /// The element that is augmented by this augmentation.
  ///
  /// The chain of augmentations normally ends with a [ExecutableElement] that
  /// is not an augmentation, but might end with `null` immediately or after a
  /// few intermediate [ExecutableElement]s in case of invalid code when an
  /// augmentation is declared without the corresponding declaration.
  @experimental
  ExecutableElement? get augmentationTarget;

  @override
  ExecutableElement get declaration;

  @override
  String get displayName;

  @Deprecated('Use enclosingElement2 instead')
  @override
  Element get enclosingElement;

  @override
  Element get enclosingElement2;

  /// Whether the executable element did not have an explicit return type
  /// specified for it in the original source.
  bool get hasImplicitReturnType;

  /// Whether the executable element is abstract.
  ///
  /// Executable elements are abstract if they are not external, and have no
  /// body.
  bool get isAbstract;

  /// Whether the executable element has body marked as being asynchronous.
  bool get isAsynchronous;

  /// Whether the element is an augmentation.
  ///
  /// If `true`, declaration has the explicit `augment` modifier.
  bool get isAugmentation;

  /// Whether the executable element is external.
  ///
  /// Executable elements are external if they are explicitly marked as such
  /// using the 'external' keyword.
  bool get isExternal;

  /// Whether the executable element has a body marked as being a generator.
  bool get isGenerator;

  /// Whether the executable element is an operator.
  ///
  /// The test may be based on the name of the executable element, in which
  /// case the result will be correct when the name is legal.
  bool get isOperator;

  /// Whether the element is a static element.
  ///
  /// A static element is an element that is not associated with a particular
  /// instance, but rather with an entire library or class.
  bool get isStatic;

  /// Whether the executable element has a body marked as being synchronous.
  bool get isSynchronous;

  @override
  String get name;
}

/// A base class for concrete implementations of an [ExecutableElement].
abstract class ExecutableElementImpl extends _ExistingElementImpl
    with TypeParameterizedElementMixin, HasCompletionData
    implements ExecutableElement, ElementImplWithFunctionType {
  /// A list containing all of the parameters defined by this executable
  /// element.
  List<ParameterElement> _parameters = const [];

  /// The inferred return type of this executable element.
  DartType? _returnType;

  /// The type of function defined by this executable element.
  FunctionType? _type;

  ElementLinkedData? linkedData;

  /// Initialize a newly created executable element to have the given [name] and
  /// [offset].
  ExecutableElementImpl(String super.name, super.offset, {super.reference});

  @override
  List<Element> get children => [
        ...super.children,
        ...typeParameters,
        ...parameters,
      ];

  @Deprecated('Use enclosingElement2 instead')
  @override
  Element get enclosingElement => super.enclosingElement!;

  @override
  Element get enclosingElement2 => super.enclosingElement2!;

  @override
  bool get hasImplicitReturnType {
    return hasModifier(Modifier.IMPLICIT_TYPE);
  }

  /// Set whether this executable element has an implicit return type.
  set hasImplicitReturnType(bool hasImplicitReturnType) {
    setModifier(Modifier.IMPLICIT_TYPE, hasImplicitReturnType);
  }

  bool get invokesSuperSelf {
    return hasModifier(Modifier.INVOKES_SUPER_SELF);
  }

  set invokesSuperSelf(bool value) {
    setModifier(Modifier.INVOKES_SUPER_SELF, value);
  }

  @override
  bool get isAbstract {
    return hasModifier(Modifier.ABSTRACT);
  }

  @override
  bool get isAsynchronous {
    return hasModifier(Modifier.ASYNCHRONOUS);
  }

  /// Set whether this executable element's body is asynchronous.
  set isAsynchronous(bool isAsynchronous) {
    setModifier(Modifier.ASYNCHRONOUS, isAsynchronous);
  }

  @override
  bool get isAugmentation {
    return hasModifier(Modifier.AUGMENTATION);
  }

  set isAugmentation(bool value) {
    setModifier(Modifier.AUGMENTATION, value);
  }

  @override
  bool get isExternal {
    return hasModifier(Modifier.EXTERNAL);
  }

  /// Set whether this executable element is external.
  set isExternal(bool isExternal) {
    setModifier(Modifier.EXTERNAL, isExternal);
  }

  @override
  bool get isGenerator {
    return hasModifier(Modifier.GENERATOR);
  }

  /// Set whether this method's body is a generator.
  set isGenerator(bool isGenerator) {
    setModifier(Modifier.GENERATOR, isGenerator);
  }

  @override
  bool get isOperator => false;

  @override
  bool get isStatic {
    return hasModifier(Modifier.STATIC);
  }

  set isStatic(bool isStatic) {
    setModifier(Modifier.STATIC, isStatic);
  }

  @override
  bool get isSynchronous => !isAsynchronous;

  @override
  List<ElementAnnotation> get metadata {
    linkedData?.read(this);
    return super.metadata;
  }

  @override
  String get name {
    return super.name!;
  }

  @override
  List<ParameterElement> get parameters =>
      ElementTypeProvider.current.getExecutableParameters(this);

  /// Set the parameters defined by this executable element to the given
  /// [parameters].
  set parameters(List<ParameterElement> parameters) {
    for (ParameterElement parameter in parameters) {
      (parameter as ParameterElementImpl).enclosingElement = this;
    }
    _parameters = parameters;
  }

  List<ParameterElement> get parameters_unresolved {
    return _parameters;
  }

  /// Gets the element's parameters, without going through the indirection of
  /// [ElementTypeProvider].
  ///
  /// In most cases, the [parameters] getter should be used instead.
  List<ParameterElement> get parametersInternal {
    linkedData?.read(this);
    return _parameters;
  }

  @Deprecated('Use returnType2 instead')
  @override
  DartType get returnType =>
      ElementTypeProvider.current.getExecutableReturnType(this);

  set returnType(DartType returnType) {
    _returnType = returnType;
    // We do this because of return type inference. At the moment when we
    // create a local function element we don't know yet its return type,
    // because we have not done static type analysis yet.
    // It somewhere it between we access the type of this element, so it gets
    // cached in the element. When we are done static type analysis, we then
    // should clear this cached type to make it right.
    // TODO(scheglov) Remove when type analysis is done in the single pass.
    _type = null;
  }

  @override
  DartType get returnType2 =>
      ElementTypeProvider.current.getExecutableReturnType(this);

  @override
  DartType get returnTypeInternal {
    linkedData?.read(this);
    return _returnType!;
  }

  @override
  FunctionType get type => ElementTypeProvider.current.getExecutableType(this);

  set type(FunctionType type) {
    _type = type;
  }

  @override
  FunctionType get typeInternal {
    if (_type != null) return _type!;

    return _type = FunctionTypeImpl(
      typeFormals: typeParameters,
      parameters: parameters,
      returnType: returnType2,
      nullabilitySuffix: _noneOrStarSuffix,
    );
  }

  /// Set the type parameters defined by this executable element to the given
  /// [typeParameters].
  set typeParameters(List<TypeParameterElement> typeParameters) {
    for (TypeParameterElement parameter in typeParameters) {
      (parameter as TypeParameterElementImpl).enclosingElement = this;
    }
    _typeParameterElements = typeParameters;
  }

  @override
  void appendTo(ElementDisplayStringBuilder builder) {
    builder.writeExecutableElement(this, displayName);
  }

  void setLinkedData(Reference reference, ElementLinkedData linkedData) {
    this.reference = reference;
    reference.element = this;

    this.linkedData = linkedData;
  }
}

/// An element that represents an extension.
///
/// Clients may not extend, implement or mix-in this class.
abstract class ExtensionElement implements InstanceElement {
  @experimental
  @override
  ExtensionElement? get augmentation;

  @experimental
  @override
  ExtensionElement? get augmentationTarget;

  @experimental
  @override
  AugmentedExtensionElement? get augmented;

  /// The type that is extended by this extension.
  DartType get extendedType;

  /// Returns the element representing the field with the given [name] that is
  /// declared in this extension, or `null` if this extension does not declare a
  /// field with the given name.
  FieldElement? getField(String name);

  /// Returns the element representing the getter with the given [name] that is
  /// declared in this extension, or `null` if this extension does not declare a
  /// getter with the given name.
  PropertyAccessorElement? getGetter(String name);

  /// Returns the element representing the method with the given [name] that is
  /// declared in this extension, or `null` if this extension does not declare a
  /// method with the given name.
  MethodElement? getMethod(String name);

  /// Returns the element representing the setter with the given [name] that is
  /// declared in this extension, or `null` if this extension does not declare a
  /// setter with the given name.
  PropertyAccessorElement? getSetter(String name);
}

/// A concrete implementation of an [ExtensionElement].
class ExtensionElementImpl extends InstanceElementImpl
    with HasCompletionData
    implements ExtensionElement {
  /// The type being extended.
  DartType? _extendedType;

  /// Initialize a newly created extension element to have the given [name] at
  /// the given [offset] in the file that contains the declaration of this
  /// element.
  ExtensionElementImpl(super.name, super.nameOffset);

  @override
  ExtensionElementImpl? get augmentation {
    // TODO(scheglov) implement
    throw UnimplementedError();
  }

  @override
  // TODO: implement augmentationTarget
  ExtensionElementImpl? get augmentationTarget => throw UnimplementedError();

  @override
  AugmentedExtensionElement? get augmented {
    // TODO(scheglov) implement
    throw UnimplementedError();
  }

  @override
  List<Element> get children => [
        ...super.children,
        ...accessors,
        ...fields,
        ...methods,
        ...typeParameters,
      ];

  @override
  String get displayName => name ?? '';

  @override
  DartType get extendedType =>
      ElementTypeProvider.current.getExtendedType(this);

  set extendedType(DartType extendedType) {
    _extendedType = extendedType;
  }

  DartType get extendedTypeInternal {
    linkedData?.read(this);
    return _extendedType!;
  }

  @override
  String get identifier {
    if (reference != null) {
      return reference!.name;
    }
    return super.identifier;
  }

  @override
  bool get isSimplyBounded => true;

  @override
  ElementKind get kind => ElementKind.EXTENSION;

  @override
  List<ElementAnnotation> get metadata {
    linkedData?.read(this);
    return super.metadata;
  }

  @override
  DartType get thisType => extendedType;

  @override
  List<TypeParameterElement> get typeParameters {
    linkedData?.read(this);
    return super.typeParameters;
  }

  /// Set the type parameters defined by this extension to the given
  /// [typeParameters].
  set typeParameters(List<TypeParameterElement> typeParameters) {
    for (TypeParameterElement typeParameter in typeParameters) {
      (typeParameter as TypeParameterElementImpl).enclosingElement = this;
    }
    _typeParameterElements = typeParameters;
  }

  @override
  T? accept<T>(ElementVisitor<T> visitor) {
    return visitor.visitExtensionElement(this);
  }

  @override
  void appendTo(ElementDisplayStringBuilder builder) {
    builder.writeExtensionElement(this);
  }

  @override
  FieldElement? getField(String name) {
    for (FieldElement fieldElement in fields) {
      if (name == fieldElement.name) {
        return fieldElement;
      }
    }
    return null;
  }

  @override
  PropertyAccessorElement? getGetter(String getterName) {
    int length = accessors.length;
    for (int i = 0; i < length; i++) {
      PropertyAccessorElement accessor = accessors[i];
      if (accessor.isGetter && accessor.name == getterName) {
        return accessor;
      }
    }
    return null;
  }

  @override
  MethodElement? getMethod(String methodName) {
    int length = methods.length;
    for (int i = 0; i < length; i++) {
      MethodElement method = methods[i];
      if (method.name == methodName) {
        return method;
      }
    }
    return null;
  }

  @override
  PropertyAccessorElement? getSetter(String setterName) {
    return InterfaceElementImpl.getSetterFromAccessors(setterName, accessors);
  }
}

/// A field defined within a class.
///
/// Clients may not extend, implement or mix-in this class.
abstract class FieldElement
    implements ClassMemberElement, PropertyInducingElement {
  @override
  FieldElement get declaration;

  /// Whether the field is abstract.
  ///
  /// Executable fields are abstract if they are declared with the `abstract`
  /// keyword.
  bool get isAbstract;

  /// Whether the field was explicitly marked as being covariant.
  bool get isCovariant;

  /// Whether the element is an enum constant.
  bool get isEnumConstant;

  /// Whether the field was explicitly marked as being external.
  bool get isExternal;

  /// Whether the field can be type promoted.
  bool get isPromotable;

  /// Whether the element is a static element.
  ///
  /// A static element is an element that is not associated with a particular
  /// instance, but rather with an entire library or class.
  @override
  bool get isStatic;
}

/// A concrete implementation of a [FieldElement].
class FieldElementImpl extends PropertyInducingElementImpl
    with HasCompletionData
    implements FieldElement {
  /// True if this field inherits from a covariant parameter. This happens
  /// when it overrides a field in a supertype that is covariant.
  bool inheritsCovariant = false;

  /// Initialize a newly created synthetic field element to have the given
  /// [name] at the given [offset].
  FieldElementImpl(super.name, super.offset);

  @override
  FieldElement get declaration => this;

  @override
  bool get isAbstract {
    return hasModifier(Modifier.ABSTRACT);
  }

  @override
  bool get isCovariant {
    return hasModifier(Modifier.COVARIANT);
  }

  /// Set whether this field is explicitly marked as being covariant.
  set isCovariant(bool isCovariant) {
    setModifier(Modifier.COVARIANT, isCovariant);
  }

  @override
  bool get isEnumConstant {
    return hasModifier(Modifier.ENUM_CONSTANT);
  }

  set isEnumConstant(bool isEnumConstant) {
    setModifier(Modifier.ENUM_CONSTANT, isEnumConstant);
  }

  @override
  bool get isExternal {
    return hasModifier(Modifier.EXTERNAL);
  }

  @override
  bool get isPromotable {
    return hasModifier(Modifier.PROMOTABLE);
  }

  set isPromotable(bool value) {
    setModifier(Modifier.PROMOTABLE, value);
  }

  /// Return `true` if this element is a synthetic enum field.
  ///
  /// It is synthetic because it is not written explicitly in code, but it
  /// is different from other synthetic fields, because its getter is also
  /// synthetic.
  ///
  /// Such fields are `index`, `_name`, and `values`.
  bool get isSyntheticEnumField {
    return enclosingElement2 is EnumElementImpl &&
        isSynthetic &&
        getter?.isSynthetic == true &&
        setter == null;
  }

  @override
  ElementKind get kind => ElementKind.FIELD;

  @override
  List<ElementAnnotation> get metadata {
    linkedData?.read(this);
    return super.metadata;
  }

  @override
  T? accept<T>(ElementVisitor<T> visitor) => visitor.visitFieldElement(this);
}

/// A field formal parameter defined within a constructor element.
///
/// Clients may not extend, implement or mix-in this class.
abstract class FieldFormalParameterElement implements ParameterElement {
  /// The field element associated with this field formal parameter, or `null`
  /// if the parameter references a field that doesn't exist.
  FieldElement? get field;
}

/// A [ParameterElementImpl] that has the additional information of the
/// [FieldElement] associated with the parameter.
class FieldFormalParameterElementImpl extends ParameterElementImpl
    implements FieldFormalParameterElement {
  @override
  FieldElement? field;

  /// Initialize a newly created parameter element to have the given [name] and
  /// [nameOffset].
  FieldFormalParameterElementImpl({
    required String super.name,
    required super.nameOffset,
    required super.parameterKind,
  });

  /// Initializing formals are visible only in the "formal parameter
  /// initializer scope", which is the current scope of the initializer list
  /// of the constructor, and which is enclosed in the scope where the
  /// constructor is declared. And according to the specification, they
  /// introduce final local variables, always, regardless whether the field
  /// is final.
  @override
  bool get isFinal => true;

  @override
  bool get isInitializingFormal => true;

  @override
  T? accept<T>(ElementVisitor<T> visitor) =>
      visitor.visitFieldFormalParameterElement(this);
}

/// A (non-method) function. This can be either a top-level function, a local
/// function, a closure, or the initialization expression for a field or
/// variable.
///
/// Clients may not extend, implement or mix-in this class.
abstract class FunctionElement implements ExecutableElement, LocalElement {
  /// The name of the method that can be implemented by a class to allow its
  /// instances to be invoked as if they were a function.
  static final String CALL_METHOD_NAME = "call";

  /// The name of the synthetic function defined for libraries that are
  /// deferred.
  static final String LOAD_LIBRARY_NAME = "loadLibrary";

  /// The name of the function used as an entry point.
  static const String MAIN_FUNCTION_NAME = "main";

  /// The name of the method that will be invoked if an attempt is made to
  /// invoke an undefined method on an object.
  static final String NO_SUCH_METHOD_METHOD_NAME = "noSuchMethod";

  @experimental
  @override
  FunctionElement? get augmentation;

  @experimental
  @override
  FunctionElement? get augmentationTarget;

  /// Whether the function represents `identical` from the `dart:core` library.
  bool get isDartCoreIdentical;

  /// Whether the function is an entry point, i.e. a top-level function and
  /// has the name `main`.
  bool get isEntryPoint;
}

/// A concrete implementation of a [FunctionElement].
class FunctionElementImpl extends ExecutableElementImpl
    implements FunctionElement, FunctionTypedElementImpl {
  @override
  FunctionElementImpl? augmentation;

  @override
  FunctionElementImpl? augmentationTarget;

  /// Initialize a newly created function element to have the given [name] and
  /// [offset].
  FunctionElementImpl(super.name, super.offset);

  /// Initialize a newly created function element to have no name and the given
  /// [nameOffset]. This is used for function expressions, that have no name.
  FunctionElementImpl.forOffset(int nameOffset) : super("", nameOffset);

  @override
  ExecutableElement get declaration => this;

  @override
  String get identifier {
    String identifier = super.identifier;
    Element? enclosing = enclosingElement2;
    if (enclosing is ExecutableElement || enclosing is VariableElement) {
      identifier += "@$nameOffset";
    }
    return considerCanonicalizeString(identifier);
  }

  @override
  bool get isDartCoreIdentical {
    return isStatic && name == 'identical' && library.isDartCore;
  }

  @override
  bool get isEntryPoint {
    return isStatic && displayName == FunctionElement.MAIN_FUNCTION_NAME;
  }

  @override
  ElementKind get kind => ElementKind.FUNCTION;

  @override
  T? accept<T>(ElementVisitor<T> visitor) => visitor.visitFunctionElement(this);
}

/// An element that has a [FunctionType] as its [type].
///
/// This also provides convenient access to the parameters and return type.
///
/// Clients may not extend, implement or mix-in this class.
abstract class FunctionTypedElement implements TypeParameterizedElement {
  /// The parameters defined by this executable element.
  List<ParameterElement> get parameters;

  /// The return type defined by this element.
  @Deprecated('Use returnType2 instead')
  DartType get returnType;

  /// The return type defined by this element.
  DartType get returnType2;

  /// The type defined by this element.
  FunctionType get type;
}

/// Common internal interface shared by elements whose type is a function type.
///
/// Clients may not extend, implement or mix-in this class.
abstract class FunctionTypedElementImpl
    implements _ExistingElementImpl, FunctionTypedElement {
  set returnType(DartType returnType);
}

/// The pseudo-declaration that defines a generic function type.
///
/// Clients may not extend, implement, or mix-in this class.
abstract class GenericFunctionTypeElement implements FunctionTypedElement {}

/// The element used for a generic function type.
///
/// Clients may not extend, implement or mix-in this class.
class GenericFunctionTypeElementImpl extends _ExistingElementImpl
    with TypeParameterizedElementMixin
    implements
        GenericFunctionTypeElement,
        FunctionTypedElementImpl,
        ElementImplWithFunctionType {
  /// The declared return type of the function.
  DartType? _returnType;

  /// The elements representing the parameters of the function.
  List<ParameterElement> _parameters = const [];

  /// Is `true` if the type has the question mark, so is nullable.
  bool isNullable = false;

  /// The type defined by this element.
  FunctionType? _type;

  /// Initialize a newly created function element to have no name and the given
  /// [nameOffset]. This is used for function expressions, that have no name.
  GenericFunctionTypeElementImpl.forOffset(int nameOffset)
      : super("", nameOffset);

  @override
  List<Element> get children => [
        ...super.children,
        ...typeParameters,
        ...parameters,
      ];

  @override
  String get identifier => '-';

  @override
  ElementKind get kind => ElementKind.GENERIC_FUNCTION_TYPE;

  @override
  List<ParameterElement> get parameters {
    return _parameters;
  }

  /// Set the parameters defined by this function type element to the given
  /// [parameters].
  set parameters(List<ParameterElement> parameters) {
    for (ParameterElement parameter in parameters) {
      (parameter as ParameterElementImpl).enclosingElement = this;
    }
    _parameters = parameters;
  }

  @Deprecated('Use returnType2 instead')
  @override
  DartType get returnType =>
      ElementTypeProvider.current.getExecutableReturnType(this);

  /// Set the return type defined by this function type element to the given
  /// [returnType].
  @override
  set returnType(DartType returnType) {
    _returnType = returnType;
  }

  @override
  DartType get returnType2 =>
      ElementTypeProvider.current.getExecutableReturnType(this);

  @override
  DartType get returnTypeInternal {
    return _returnType!;
  }

  @override
  FunctionType get type => ElementTypeProvider.current.getExecutableType(this);

  /// Set the function type defined by this function type element to the given
  /// [type].
  set type(FunctionType type) {
    _type = type;
  }

  @override
  FunctionType get typeInternal {
    if (_type != null) return _type!;

    return _type = FunctionTypeImpl(
      typeFormals: typeParameters,
      parameters: parameters,
      returnType: returnType2,
      nullabilitySuffix:
          isNullable ? NullabilitySuffix.question : _noneOrStarSuffix,
    );
  }

  /// Set the type parameters defined by this function type element to the given
  /// [typeParameters].
  set typeParameters(List<TypeParameterElement> typeParameters) {
    for (TypeParameterElement parameter in typeParameters) {
      (parameter as TypeParameterElementImpl).enclosingElement = this;
    }
    _typeParameterElements = typeParameters;
  }

  @override
  T? accept<T>(ElementVisitor<T> visitor) {
    return visitor.visitGenericFunctionTypeElement(this);
  }

  @override
  void appendTo(ElementDisplayStringBuilder builder) {
    builder.writeGenericFunctionTypeElement(this);
  }
}

/// This mixins is added to elements that can have cache completion data.
mixin HasCompletionData {
  Object? completionData;
}

/// A combinator that causes some of the names in a namespace to be hidden when
/// being imported.
///
/// Clients may not extend, implement or mix-in this class.
abstract class HideElementCombinator implements NamespaceCombinator {
  /// The names that are not to be made visible in the importing library even
  /// if they are defined in the imported library.
  List<String> get hiddenNames;
}

/// A concrete implementation of a [HideElementCombinator].
class HideElementCombinatorImpl implements HideElementCombinator {
  @override
  List<String> hiddenNames = const [];

  @override
  String toString() {
    StringBuffer buffer = StringBuffer();
    buffer.write("hide ");
    int count = hiddenNames.length;
    for (int i = 0; i < count; i++) {
      if (i > 0) {
        buffer.write(", ");
      }
      buffer.write(hiddenNames[i]);
    }
    return buffer.toString();
  }
}

/// Usage of a [PrefixElement] in an `import` directive.
///
/// Clients may not extend, implement or mix-in this class.
abstract class ImportElementPrefix {
  /// The prefix that was specified as part of the import directive, or `null`
  /// if there was no prefix specified.
  PrefixElement get element;
}

class ImportElementPrefixImpl implements ImportElementPrefix {
  @override
  final PrefixElementImpl element;

  ImportElementPrefixImpl({
    required this.element,
  });
}

/// An element that represents an inline class.
///
/// Clients may not extend, implement or mix-in this class.
@experimental
abstract class InlineClassElement implements NamedInstanceElement {
  @experimental
  @override
  InlineClassElement? get augmentation;

  @experimental
  @override
  InlineClassElement? get augmentationTarget;

  @experimental
  @override
  AugmentedInlineClassElement? get augmented;

  /// The direct [InlineClassType]s that are implemented by this inline class.
  List<InlineClassType> get implemented;
}

class InlineClassElementImpl extends NamedInstanceElementImpl
    implements InlineClassElement {
  InlineClassElementImpl(super.name, super.nameOffset);

  @override
  Never get augmentation {
    // TODO: implement augmentation
    throw UnimplementedError();
  }

  @override
  // TODO: implement augmentationTarget
  InlineClassElementImpl? get augmentationTarget => throw UnimplementedError();

  @override
  AugmentedInlineClassElement? get augmented {
    // TODO(scheglov) implement
    throw UnimplementedError();
  }

  @override
  List<InlineClassType> get implemented {
    // TODO(scheglov) implement
    throw UnimplementedError();
  }

  @override
  ElementKind get kind {
    return ElementKind.INLINE_CLASS;
  }

  @override
  InlineClassType get thisType {
    // TODO(scheglov) implement
    throw UnimplementedError();
  }

  @override
  T? accept<T>(ElementVisitor<T> visitor) {
    // TODO(scheglov) implement
    throw UnimplementedError();
  }

  @override
  DartType instantiate({
    required List<DartType> typeArguments,
    required NullabilitySuffix nullabilitySuffix,
  }) {
    // TODO(scheglov) implement
    throw UnimplementedError();
  }
}

/// An element that has `this`.
///
/// Clients may not extend, implement or mix-in this class.
abstract class InstanceElement
    implements TypeDefiningElement, TypeParameterizedElement {
  /// The declared accessors (getters and setters).
  List<PropertyAccessorElement> get accessors;

  /// The immediate augmentation of this element, or `null` if there are no
  /// augmentations.
  ///
  /// [InstanceElement.augmentationTarget] will point back at this element.
  @experimental
  InstanceElement? get augmentation;

  /// The element that is augmented by this augmentation; or `null` if
  /// [isAugmentation] is `false`, or there is no corresponding element to be
  /// augmented.
  ///
  /// The chain of augmentations should normally end with a not augmentation
  /// [InstanceElement], but might end with `null` immediately or after a few
  /// intermediate elements in case of invalid code when an augmentation is
  /// declared without the corresponding declaration.
  @experimental
  InstanceElement? get augmentationTarget;

  /// The result of applying augmentations.
  @experimental
  AugmentedInstanceElement? get augmented;

  @Deprecated('Use enclosingElement2 instead')
  @override
  CompilationUnitElement get enclosingElement;

  @override
  CompilationUnitElement get enclosingElement2;

  /// The declared fields.
  List<FieldElement> get fields;

  /// Whether the element is an augmentation.
  ///
  /// If `true`, declaration has the explicit `augment` modifier.
  bool get isAugmentation;

  /// The declared methods.
  List<MethodElement> get methods;

  /// The type of `this` expression.
  ///
  /// For a class like `class MyClass<T, U> {}` the returned type is equivalent
  /// to the type `MyClass<T, U>`. So, the type arguments are the types of the
  /// type parameters, and either `none` or `star` is used for the nullability
  /// suffix is used, depending on the nullability status of the declaring
  /// library.
  DartType get thisType;
}

abstract class InstanceElementImpl extends _ExistingElementImpl
    with TypeParameterizedElementMixin
    implements InstanceElement {
  ElementLinkedData? linkedData;

  List<FieldElementImpl> _fields = _Sentinel.fieldElement;
  List<PropertyAccessorElementImpl> _accessors =
      _Sentinel.propertyAccessorElement;
  List<MethodElementImpl> _methods = _Sentinel.methodElement;

  InstanceElementImpl(super.name, super.nameOffset);

  @override
  List<PropertyAccessorElementImpl> get accessors {
    if (!identical(_accessors, _Sentinel.propertyAccessorElement)) {
      return _accessors;
    }

    linkedData?.readMembers(this);
    return _accessors;
  }

  set accessors(List<PropertyAccessorElementImpl> accessors) {
    for (var accessor in accessors) {
      accessor.enclosingElement = this;
    }
    _accessors = accessors;
  }

  @override
  InstanceElementImpl? get augmentation;

  @override
  InstanceElementImpl? get augmentationTarget;

  @Deprecated('Use enclosingElement2 instead')
  @override
  CompilationUnitElementImpl get enclosingElement {
    return super.enclosingElement2 as CompilationUnitElementImpl;
  }

  @override
  CompilationUnitElementImpl get enclosingElement2 {
    return super.enclosingElement2 as CompilationUnitElementImpl;
  }

  @override
  List<FieldElementImpl> get fields {
    if (!identical(_fields, _Sentinel.fieldElement)) {
      return _fields;
    }

    linkedData?.readMembers(this);
    return _fields;
  }

  set fields(List<FieldElementImpl> fields) {
    for (var field in fields) {
      field.enclosingElement = this;
    }
    _fields = fields;
  }

  @override
  bool get isAugmentation {
    return hasModifier(Modifier.AUGMENTATION);
  }

  set isAugmentation(bool value) {
    setModifier(Modifier.AUGMENTATION, value);
  }

  @override
  List<ElementAnnotation> get metadata {
    linkedData?.read(this);
    return super.metadata;
  }

  @override
  List<MethodElementImpl> get methods {
    if (!identical(_methods, _Sentinel.methodElement)) {
      return _methods;
    }

    linkedData?.readMembers(this);
    return _methods;
  }

  set methods(List<MethodElementImpl> methods) {
    for (var method in methods) {
      method.enclosingElement = this;
    }
    _methods = methods;
  }

  void setLinkedData(Reference reference, ElementLinkedData linkedData) {
    this.reference = reference;
    reference.element = this;

    this.linkedData = linkedData;
  }
}

/// An element that defines an [InterfaceType].
///
/// Clients may not extend, implement or mix-in this class.
abstract class InterfaceElement implements NamedInstanceElement {
  /// All the supertypes defined for this element and its supertypes.
  ///
  /// This includes superclasses, mixins, interfaces, and superclass constraints.
  List<InterfaceType> get allSupertypes;

  @override
  InterfaceElement? get augmentationTarget;

  @experimental
  @override
  AugmentedInterfaceElement? get augmented;

  /// The interfaces that are implemented by this class.
  ///
  /// <b>Note:</b> Because the element model represents the state of the code,
  /// it is possible for it to be semantically invalid. In particular, it is not
  /// safe to assume that the inheritance structure of a class does not contain
  /// a cycle. Clients that traverse the inheritance structure must explicitly
  /// guard against infinite loops.
  List<InterfaceType> get interfaces;

  /// The mixins that are applied to the class being extended in order to
  /// derive the superclass of this class.
  ///
  /// [ClassElement] and [EnumElement] can have mixins.
  ///
  /// [MixinElement] cannot have mixins, so the empty list is returned.
  ///
  /// <b>Note:</b> Because the element model represents the state of the code,
  /// it is possible for it to be semantically invalid. In particular, it is not
  /// safe to assume that the inheritance structure of a class does not contain
  /// a cycle. Clients that traverse the inheritance structure must explicitly
  /// guard against infinite loops.
  List<InterfaceType> get mixins;

  /// The superclass of this element.
  ///
  /// For [ClassElement] returns `null` only if this class is `Object`. If the
  /// superclass is not explicitly specified, or the superclass cannot be
  /// resolved, then the implicit superclass `Object` is returned.
  ///
  /// For [EnumElement] returns `Enum` from `dart:core`.
  ///
  /// For [MixinElement] always returns `null`.
  ///
  /// <b>Note:</b> Because the element model represents the state of the code,
  /// it is possible for it to be semantically invalid. In particular, it is not
  /// safe to assume that the inheritance structure of a class does not contain
  /// a cycle. Clients that traverse the inheritance structure must explicitly
  /// guard against infinite loops.
  InterfaceType? get supertype;

  @override
  InterfaceType get thisType;

  /// The field (synthetic or explicit) defined directly in this class or
  /// augmentation that has the given [name].
  /// TODO(scheglov) Deprecate and remove it.
  FieldElement? getField(String name);

  /// The getter (synthetic or explicit) defined directly in this class or
  /// augmentation that has the given [name].
  /// TODO(scheglov) Deprecate and remove it.
  PropertyAccessorElement? getGetter(String name);

  /// The method defined directly in this class or augmentation that has the
  /// given [name].
  /// TODO(scheglov) Deprecate and remove it.
  MethodElement? getMethod(String name);

  /// The setter (synthetic or explicit) defined directly in this class or
  /// augmentation that has the given [name].
  /// TODO(scheglov) Deprecate and remove it.
  PropertyAccessorElement? getSetter(String name);

  @override
  InterfaceType instantiate({
    required List<DartType> typeArguments,
    required NullabilitySuffix nullabilitySuffix,
  });

  /// Returns the element representing the method that results from looking up
  /// the given [methodName] in this class with respect to the given [library],
  /// ignoring abstract methods, or `null` if the look up fails.
  ///
  /// The behavior of this method is defined by the Dart Language Specification
  /// in section 16.15.1:
  /// <blockquote>
  /// The result of looking up method <i>m</i> in class <i>C</i> with respect to
  /// library <i>L</i> is: If <i>C</i> declares an instance method named
  /// <i>m</i> that is accessible to <i>L</i>, then that method is the result of
  /// the lookup. Otherwise, if <i>C</i> has a superclass <i>S</i>, then the
  /// result of the lookup is the result of looking up method <i>m</i> in
  /// <i>S</i> with respect to <i>L</i>. Otherwise, we say that the lookup has
  /// failed.
  /// </blockquote>
  /// TODO(scheglov) Deprecate and remove it.
  MethodElement? lookUpConcreteMethod(
      String methodName, LibraryElement library);

  /// Returns the element representing the getter that results from looking up
  /// the given [getterName] in this class with respect to the given [library],
  /// or `null` if the look up fails.
  ///
  /// The behavior of this method is defined by the Dart Language Specification
  /// in section 16.15.2:
  /// <blockquote>
  /// The result of looking up getter (respectively setter) <i>m</i> in class
  /// <i>C</i> with respect to library <i>L</i> is: If <i>C</i> declares an
  /// instance getter (respectively setter) named <i>m</i> that is accessible to
  /// <i>L</i>, then that getter (respectively setter) is the result of the
  /// lookup. Otherwise, if <i>C</i> has a superclass <i>S</i>, then the result
  /// of the lookup is the result of looking up getter (respectively setter)
  /// <i>m</i> in <i>S</i> with respect to <i>L</i>. Otherwise, we say that the
  /// lookup has failed.
  /// </blockquote>
  /// TODO(scheglov) Deprecate and remove it.
  PropertyAccessorElement? lookUpGetter(
      String getterName, LibraryElement library);

  /// Returns the element representing the getter that results from looking up
  /// the given [getterName] in the superclass of this class with respect to the
  /// given [library], ignoring abstract getters, or `null` if the look up
  /// fails.
  ///
  /// The behavior of this method is defined by the Dart Language Specification
  /// in section 16.15.2:
  /// <blockquote>
  /// The result of looking up getter (respectively setter) <i>m</i> in class
  /// <i>C</i> with respect to library <i>L</i> is: If <i>C</i> declares an
  /// instance getter (respectively setter) named <i>m</i> that is accessible to
  /// <i>L</i>, then that getter (respectively setter) is the result of the
  /// lookup. Otherwise, if <i>C</i> has a superclass <i>S</i>, then the result
  /// of the lookup is the result of looking up getter (respectively setter)
  /// <i>m</i> in <i>S</i> with respect to <i>L</i>. Otherwise, we say that the
  /// lookup has failed.
  /// </blockquote>
  /// TODO(scheglov) Deprecate and remove it.
  PropertyAccessorElement? lookUpInheritedConcreteGetter(
      String getterName, LibraryElement library);

  /// Returns the element representing the method that results from looking up
  /// the given [methodName] in the superclass of this class with respect to the
  /// given [library], ignoring abstract methods, or `null` if the look up
  /// fails.
  ///
  /// The behavior of this method is defined by the Dart Language Specification
  /// in section 16.15.1:
  /// <blockquote>
  /// The result of looking up method <i>m</i> in class <i>C</i> with respect to
  /// library <i>L</i> is:  If <i>C</i> declares an instance method named
  /// <i>m</i> that is accessible to <i>L</i>, then that method is the result of
  /// the lookup. Otherwise, if <i>C</i> has a superclass <i>S</i>, then the
  /// result of the lookup is the result of looking up method <i>m</i> in
  /// <i>S</i> with respect to <i>L</i>. Otherwise, we say that the lookup has
  /// failed.
  /// </blockquote>
  /// TODO(scheglov) Deprecate and remove it.
  MethodElement? lookUpInheritedConcreteMethod(
      String methodName, LibraryElement library);

  /// Returns the element representing the setter that results from looking up
  /// the given [setterName] in the superclass of this class with respect to the
  /// given [library], ignoring abstract setters, or `null` if the look up
  /// fails.
  ///
  /// The behavior of this method is defined by the Dart Language Specification
  /// in section 16.15.2:
  /// <blockquote>
  /// The result of looking up getter (respectively setter) <i>m</i> in class
  /// <i>C</i> with respect to library <i>L</i> is:  If <i>C</i> declares an
  /// instance getter (respectively setter) named <i>m</i> that is accessible to
  /// <i>L</i>, then that getter (respectively setter) is the result of the
  /// lookup. Otherwise, if <i>C</i> has a superclass <i>S</i>, then the result
  /// of the lookup is the result of looking up getter (respectively setter)
  /// <i>m</i> in <i>S</i> with respect to <i>L</i>. Otherwise, we say that the
  /// lookup has failed.
  /// </blockquote>
  /// TODO(scheglov) Deprecate and remove it.
  PropertyAccessorElement? lookUpInheritedConcreteSetter(
      String setterName, LibraryElement library);

  /// Returns the element representing the method that results from looking up
  /// the given [methodName] in the superclass of this class with respect to the
  /// given [library], or `null` if the look up fails.
  ///
  /// The behavior of this method is defined by the Dart Language Specification
  /// in section 16.15.1:
  /// <blockquote>
  /// The result of looking up method <i>m</i> in class <i>C</i> with respect to
  /// library <i>L</i> is:  If <i>C</i> declares an instance method named
  /// <i>m</i> that is accessible to <i>L</i>, then that method is the result of
  /// the lookup. Otherwise, if <i>C</i> has a superclass <i>S</i>, then the
  /// result of the lookup is the result of looking up method <i>m</i> in
  /// <i>S</i> with respect to <i>L</i>. Otherwise, we say that the lookup has
  /// failed.
  /// </blockquote>
  /// TODO(scheglov) Deprecate and remove it.
  MethodElement? lookUpInheritedMethod(
      String methodName, LibraryElement library);

  /// Returns the element representing the method that results from looking up
  /// the given [methodName] in this class with respect to the given [library],
  /// or `null` if the look up fails.
  ///
  /// The behavior of this method is defined by the Dart Language Specification
  /// in section 16.15.1:
  /// <blockquote>
  /// The result of looking up method <i>m</i> in class <i>C</i> with respect to
  /// library <i>L</i> is:  If <i>C</i> declares an instance method named
  /// <i>m</i> that is accessible to <i>L</i>, then that method is the result of
  /// the lookup. Otherwise, if <i>C</i> has a superclass <i>S</i>, then the
  /// result of the lookup is the result of looking up method <i>m</i> in
  /// <i>S</i> with respect to <i>L</i>. Otherwise, we say that the lookup has
  /// failed.
  /// </blockquote>
  /// TODO(scheglov) Deprecate and remove it.
  MethodElement? lookUpMethod(String methodName, LibraryElement library);

  /// Returns the element representing the setter that results from looking up
  /// the given [setterName] in this class with respect to the given [library],
  /// or `null` if the look up fails.
  ///
  /// The behavior of this method is defined by the Dart Language Specification
  /// in section 16.15.2:
  /// <blockquote>
  /// The result of looking up getter (respectively setter) <i>m</i> in class
  /// <i>C</i> with respect to library <i>L</i> is: If <i>C</i> declares an
  /// instance getter (respectively setter) named <i>m</i> that is accessible to
  /// <i>L</i>, then that getter (respectively setter) is the result of the
  /// lookup. Otherwise, if <i>C</i> has a superclass <i>S</i>, then the result
  /// of the lookup is the result of looking up getter (respectively setter)
  /// <i>m</i> in <i>S</i> with respect to <i>L</i>. Otherwise, we say that the
  /// lookup has failed.
  /// </blockquote>
  /// TODO(scheglov) Deprecate and remove it.
  PropertyAccessorElement? lookUpSetter(
      String setterName, LibraryElement library);
}

abstract class InterfaceElementImpl extends NamedInstanceElementImpl
    with HasCompletionData, MacroTargetElement
    implements InterfaceElement {
  /// A list containing all of the mixins that are applied to the class being
  /// extended in order to derive the superclass of this class.
  List<InterfaceType> _mixins = const [];

  /// A list containing all of the interfaces that are implemented by this
  /// class.
  List<InterfaceType> _interfaces = const [];

  /// This callback is set during mixins inference to handle reentrant calls.
  List<InterfaceType>? Function(InterfaceElementImpl)? mixinInferenceCallback;

  InterfaceType? _supertype;

  /// The type defined by the class.
  InterfaceType? _thisType;

  /// A flag indicating whether the types associated with the instance members
  /// of this class have been inferred.
  bool hasBeenInferred = false;

  /// Initialize a newly created class element to have the given [name] at the
  /// given [offset] in the file that contains the declaration of this element.
  InterfaceElementImpl(super.name, super.offset);

  @override
  List<InterfaceType> get allSupertypes {
    return library.session.classHierarchy.implementedInterfaces(this);
  }

  @override
  InterfaceElementImpl? get augmentation;

  @override
  InterfaceElementImpl? get augmentationTarget;

  @override
  AugmentedInterfaceElement? get augmented {
    throw UnimplementedError();
  }

  @override
  List<Element> get children => [
        ...super.children,
        ...accessors,
        ...fields,
        ...constructors,
        ...methods,
        ...typeParameters,
      ];

  @override
  List<InterfaceType> get interfaces {
    return ElementTypeProvider.current.getClassInterfaces(this);
  }

  set interfaces(List<InterfaceType> interfaces) {
    _interfaces = interfaces;
  }

  List<InterfaceType> get interfacesInternal {
    linkedData?.read(this);
    return _interfaces;
  }

  /// Return `true` if this class represents the class '_Enum' defined in the
  /// dart:core library.
  bool get isDartCoreEnumImpl {
    return name == '_Enum' && library.isDartCore;
  }

  /// Return `true` if this class represents the class 'Function' defined in the
  /// dart:core library.
  bool get isDartCoreFunctionImpl {
    return name == 'Function' && library.isDartCore;
  }

  @override
  bool get isSimplyBounded {
    return hasModifier(Modifier.SIMPLY_BOUNDED);
  }

  set isSimplyBounded(bool isSimplyBounded) {
    setModifier(Modifier.SIMPLY_BOUNDED, isSimplyBounded);
  }

  @override
  List<InterfaceType> get mixins {
    if (mixinInferenceCallback != null) {
      var mixins = mixinInferenceCallback!(this);
      if (mixins != null) {
        return _mixins = mixins;
      }
    }

    linkedData?.read(this);
    return _mixins;
  }

  set mixins(List<InterfaceType> mixins) {
    _mixins = mixins;
  }

  @override
  InterfaceType? get supertype {
    linkedData?.read(this);
    return _supertype;
  }

  set supertype(InterfaceType? value) {
    _supertype = value;
  }

  @override
  InterfaceType get thisType {
    if (_thisType == null) {
      List<DartType> typeArguments;
      if (typeParameters.isNotEmpty) {
        typeArguments = typeParameters.map<DartType>((t) {
          return t.instantiate(nullabilitySuffix: _noneOrStarSuffix);
        }).toFixedList();
      } else {
        typeArguments = const <DartType>[];
      }
      return _thisType = instantiate(
        typeArguments: typeArguments,
        nullabilitySuffix: _noneOrStarSuffix,
      );
    }
    return _thisType!;
  }

  @override
  List<TypeParameterElement> get typeParameters {
    linkedData?.read(this);
    return super.typeParameters;
  }

  set typeParameters(List<TypeParameterElement> typeParameters) {
    for (TypeParameterElement typeParameter in typeParameters) {
      (typeParameter as TypeParameterElementImpl).enclosingElement = this;
    }
    _typeParameterElements = typeParameters;
  }

  /// This element and all its augmentations, in order.
  Iterable<InterfaceElementImpl> get withAugmentations sync* {
    InterfaceElementImpl? current = this;
    while (current != null) {
      yield current;
      current = current.augmentation;
    }
  }

  @override
  FieldElement? getField(String name) {
    return fields.firstWhereOrNull((fieldElement) => name == fieldElement.name);
  }

  @override
  PropertyAccessorElement? getGetter(String getterName) {
    return accessors.firstWhereOrNull(
        (accessor) => accessor.isGetter && accessor.name == getterName);
  }

  @override
  MethodElement? getMethod(String methodName) {
    return methods.firstWhereOrNull((method) => method.name == methodName);
  }

  @override
  PropertyAccessorElement? getSetter(String setterName) {
    return getSetterFromAccessors(setterName, accessors);
  }

  @override
  InterfaceType instantiate({
    required List<DartType> typeArguments,
    required NullabilitySuffix nullabilitySuffix,
  }) {
    return InterfaceTypeImpl(
      element: this,
      typeArguments: typeArguments,
      nullabilitySuffix: nullabilitySuffix,
    );
  }

  @override
  MethodElement? lookUpConcreteMethod(
      String methodName, LibraryElement library) {
    return _implementationsOfMethod(methodName).firstWhereOrNull(
        (method) => !method.isAbstract && method.isAccessibleIn(library));
  }

  @override
  PropertyAccessorElement? lookUpGetter(
      String getterName, LibraryElement library) {
    return _implementationsOfGetter(getterName)
        .firstWhereOrNull((getter) => getter.isAccessibleIn(library));
  }

  @override
  PropertyAccessorElement? lookUpInheritedConcreteGetter(
      String getterName, LibraryElement library) {
    return _implementationsOfGetter(getterName).firstWhereOrNull((getter) =>
        !getter.isAbstract &&
        !getter.isStatic &&
        getter.isAccessibleIn(library) &&
        getter.enclosingElement2 != this);
  }

  ExecutableElement? lookUpInheritedConcreteMember(
      String name, LibraryElement library) {
    if (name.endsWith('=')) {
      return lookUpInheritedConcreteSetter(name, library);
    } else {
      return lookUpInheritedConcreteMethod(name, library) ??
          lookUpInheritedConcreteGetter(name, library);
    }
  }

  @override
  MethodElement? lookUpInheritedConcreteMethod(
      String methodName, LibraryElement library) {
    return _implementationsOfMethod(methodName).firstWhereOrNull((method) =>
        !method.isAbstract &&
        !method.isStatic &&
        method.isAccessibleIn(library) &&
        method.enclosingElement2 != this);
  }

  @override
  PropertyAccessorElement? lookUpInheritedConcreteSetter(
      String setterName, LibraryElement library) {
    return _implementationsOfSetter(setterName).firstWhereOrNull((setter) =>
        !setter.isAbstract &&
        !setter.isStatic &&
        setter.isAccessibleIn(library) &&
        setter.enclosingElement2 != this);
  }

  @override
  MethodElement? lookUpInheritedMethod(
      String methodName, LibraryElement library) {
    return _implementationsOfMethod(methodName).firstWhereOrNull((method) =>
        !method.isStatic &&
        method.isAccessibleIn(library) &&
        method.enclosingElement2 != this);
  }

  @override
  MethodElement? lookUpMethod(String methodName, LibraryElement library) {
    return _implementationsOfMethod(methodName).firstWhereOrNull(
        (MethodElement method) => method.isAccessibleIn(library));
  }

  @override
  PropertyAccessorElement? lookUpSetter(
      String setterName, LibraryElement library) {
    return _implementationsOfSetter(setterName).firstWhereOrNull(
        (PropertyAccessorElement setter) => setter.isAccessibleIn(library));
  }

  /// Return the static getter with the [name], accessible to the [library].
  ///
  /// This method should be used only for error recovery during analysis,
  /// when instance access to a static class member, defined in this class,
  /// or a superclass.
  PropertyAccessorElement? lookupStaticGetter(
      String name, LibraryElement library) {
    return _implementationsOfGetter(name).firstWhereOrNull(
        (element) => element.isStatic && element.isAccessibleIn(library));
  }

  /// Return the static method with the [name], accessible to the [library].
  ///
  /// This method should be used only for error recovery during analysis,
  /// when instance access to a static class member, defined in this class,
  /// or a superclass.
  MethodElement? lookupStaticMethod(String name, LibraryElement library) {
    return _implementationsOfMethod(name).firstWhereOrNull(
        (element) => element.isStatic && element.isAccessibleIn(library));
  }

  /// Return the static setter with the [name], accessible to the [library].
  ///
  /// This method should be used only for error recovery during analysis,
  /// when instance access to a static class member, defined in this class,
  /// or a superclass.
  PropertyAccessorElement? lookupStaticSetter(
      String name, LibraryElement library) {
    return _implementationsOfSetter(name).firstWhereOrNull(
        (element) => element.isStatic && element.isAccessibleIn(library));
  }

  /// Return an iterable containing all of the implementations of a getter with
  /// the given [getterName] that are defined in this class and any superclass
  /// of this class (but not in interfaces).
  ///
  /// The getters that are returned are not filtered in any way. In particular,
  /// they can include getters that are not visible in some context. Clients
  /// must perform any necessary filtering.
  ///
  /// The getters are returned based on the depth of their defining class; if
  /// this class contains a definition of the getter it will occur first, if
  /// Object contains a definition of the getter it will occur last.
  Iterable<PropertyAccessorElement> _implementationsOfGetter(
      String getterName) sync* {
    final visitedClasses = <InterfaceElement>{};
    InterfaceElement? classElement = this;
    while (classElement != null && visitedClasses.add(classElement)) {
      var getter = classElement.getGetter(getterName);
      if (getter != null) {
        yield getter;
      }
      for (InterfaceType mixin in classElement.mixins.reversed) {
        getter = mixin.element.getGetter(getterName);
        if (getter != null) {
          yield getter;
        }
      }
      classElement = classElement.supertype?.element;
    }
  }

  /// Return an iterable containing all of the implementations of a method with
  /// the given [methodName] that are defined in this class and any superclass
  /// of this class (but not in interfaces).
  ///
  /// The methods that are returned are not filtered in any way. In particular,
  /// they can include methods that are not visible in some context. Clients
  /// must perform any necessary filtering.
  ///
  /// The methods are returned based on the depth of their defining class; if
  /// this class contains a definition of the method it will occur first, if
  /// Object contains a definition of the method it will occur last.
  Iterable<MethodElement> _implementationsOfMethod(String methodName) sync* {
    final visitedClasses = <InterfaceElement>{};
    InterfaceElement? classElement = this;
    while (classElement != null && visitedClasses.add(classElement)) {
      var method = classElement.getMethod(methodName);
      if (method != null) {
        yield method;
      }
      for (InterfaceType mixin in classElement.mixins.reversed) {
        method = mixin.element.getMethod(methodName);
        if (method != null) {
          yield method;
        }
      }
      classElement = classElement.supertype?.element;
    }
  }

  /// Return an iterable containing all of the implementations of a setter with
  /// the given [setterName] that are defined in this class and any superclass
  /// of this class (but not in interfaces).
  ///
  /// The setters that are returned are not filtered in any way. In particular,
  /// they can include setters that are not visible in some context. Clients
  /// must perform any necessary filtering.
  ///
  /// The setters are returned based on the depth of their defining class; if
  /// this class contains a definition of the setter it will occur first, if
  /// Object contains a definition of the setter it will occur last.
  Iterable<PropertyAccessorElement> _implementationsOfSetter(
      String setterName) sync* {
    final visitedClasses = <InterfaceElement>{};
    InterfaceElement? classElement = this;
    while (classElement != null && visitedClasses.add(classElement)) {
      var setter = classElement.getSetter(setterName);
      if (setter != null) {
        yield setter;
      }
      for (InterfaceType mixin in classElement.mixins.reversed) {
        setter = mixin.element.getSetter(setterName);
        if (setter != null) {
          yield setter;
        }
      }
      classElement = classElement.supertype?.element;
    }
  }

  static PropertyAccessorElement? getSetterFromAccessors(
      String setterName, List<PropertyAccessorElement> accessors) {
    // TODO (jwren) revisit- should we append '=' here or require clients to
    // include it?
    // Do we need the check for isSetter below?
    if (!setterName.endsWith('=')) {
      setterName += '=';
    }
    return accessors.firstWhereOrNull(
        (accessor) => accessor.isSetter && accessor.name == setterName);
  }
}

/// A pattern variable that is a join of other pattern variables, created
/// for a logical-or patterns, or shared `case` bodies in `switch` statements.
///
/// Clients may not extend, implement or mix-in this class.
abstract class JoinPatternVariableElement implements PatternVariableElement {
  /// Whether the [variables] are consistent, present in all branches,
  /// and have the same type and finality.
  bool get isConsistent;

  /// The variables that join into this variable.
  List<PatternVariableElement> get variables;
}

class JoinPatternVariableElementImpl extends PatternVariableElementImpl
    implements JoinPatternVariableElement {
  @override
  final List<PatternVariableElementImpl> variables;

  shared.JoinedPatternVariableInconsistency inconsistency;

  /// The identifiers that reference this element.
  final List<SimpleIdentifier> references = [];

  JoinPatternVariableElementImpl(
    super.name,
    super.offset,
    this.variables,
    this.inconsistency,
  ) {
    for (var component in variables) {
      component.join = this;
    }
  }

  @override
  int get hashCode => identityHashCode(this);

  @override
  bool get isConsistent {
    return inconsistency == shared.JoinedPatternVariableInconsistency.none;
  }

  /// Returns this variable, and variables that join into it.
  List<PatternVariableElementImpl> get transitiveVariables {
    var result = <PatternVariableElementImpl>[];

    void append(PatternVariableElementImpl variable) {
      result.add(variable);
      if (variable is JoinPatternVariableElementImpl) {
        for (var variable in variable.variables) {
          append(variable);
        }
      }
    }

    append(this);
    return result;
  }

  @override
  bool operator ==(Object other) => identical(other, this);
}

/// A label associated with a statement.
///
/// Clients may not extend, implement or mix-in this class.
abstract class LabelElement implements Element {
  @Deprecated('Use enclosingElement2 instead')
  @override
  ExecutableElement get enclosingElement;

  @override
  ExecutableElement get enclosingElement2;

  @override
  String get name;
}

/// A concrete implementation of a [LabelElement].
class LabelElementImpl extends ElementImpl implements LabelElement {
  /// A flag indicating whether this label is associated with a `switch` member
  /// (`case` or `default`).
  // TODO(brianwilkerson) Make this a modifier.
  final bool _onSwitchMember;

  /// Initialize a newly created label element to have the given [name].
  /// [onSwitchMember] should be `true` if this label is associated with a
  /// `switch` member.
  LabelElementImpl(String super.name, super.nameOffset, this._onSwitchMember);

  @override
  String get displayName => name;

  @Deprecated('Use enclosingElement2 instead')
  @override
  ExecutableElement get enclosingElement =>
      super.enclosingElement2 as ExecutableElement;

  @override
  ExecutableElement get enclosingElement2 =>
      super.enclosingElement2 as ExecutableElement;

  /// Return `true` if this label is associated with a `switch` member (`case
  /// ` or`default`).
  bool get isOnSwitchMember => _onSwitchMember;

  @override
  ElementKind get kind => ElementKind.LABEL;

  @override
  String get name => super.name!;

  @override
  T? accept<T>(ElementVisitor<T> visitor) => visitor.visitLabelElement(this);
}

/// A library augmentation.
///
/// Clients may not extend, implement or mix-in this class.
@experimental
abstract class LibraryAugmentationElement
    implements LibraryOrAugmentationElement, _ExistingElement {
  /// The library that is augmented by this augmentation.
  LibraryOrAugmentationElement get augmentationTarget;
}

class LibraryAugmentationElementImpl extends LibraryOrAugmentationElementImpl
    implements LibraryAugmentationElement {
  @override
  final LibraryOrAugmentationElementImpl augmentationTarget;

  LibraryAugmentationElementLinkedData? linkedData;

  LibraryAugmentationElementImpl({
    required this.augmentationTarget,
    required super.nameOffset,
  }) : super(name: null);

  @override
  // TODO: implement accessibleExtensions
  List<ExtensionElement> get accessibleExtensions => throw UnimplementedError();

  @override
  List<AugmentationImportElementImpl> get augmentationImports {
    _readLinkedData();
    return super.augmentationImports;
  }

  @override
  FeatureSet get featureSet => augmentationTarget.featureSet;

  @override
  bool get isNonNullableByDefault => augmentationTarget.isNonNullableByDefault;

  @override
  ElementKind get kind => ElementKind.LIBRARY_AUGMENTATION;

  @override
  LibraryLanguageVersion get languageVersion {
    return augmentationTarget.languageVersion;
  }

  @override
  LibraryElementImpl get library => augmentationTarget.library;

  @override
  List<LibraryExportElementImpl> get libraryExports {
    return _libraryExports;
  }

  @override
  List<LibraryImportElementImpl> get libraryImports {
    _readLinkedData();
    return _libraryImports;
  }

  @override
  Source get librarySource => library.source;

  @override
  AnalysisSessionImpl get session => augmentationTarget.session;

  @override
  TypeProvider get typeProvider => augmentationTarget.typeProvider;

  @override
  TypeSystem get typeSystem => augmentationTarget.typeSystem;

  @override
  T? accept<T>(ElementVisitor<T> visitor) {
    return visitor.visitLibraryAugmentationElement(this);
  }

  @override
  void _readLinkedData() {
    augmentationTarget._readLinkedData();
  }
}

/// A library.
///
/// Clients may not extend, implement or mix-in this class.
abstract class LibraryElement
    implements LibraryOrAugmentationElement, _ExistingElement {
  /// The entry point for this library, or `null` if this library does
  /// not have an entry point.
  ///
  /// The entry point is defined to be a zero argument top-level function
  /// whose name is `main`.
  FunctionElement? get entryPoint;

  /// The libraries that are exported from this library.
  List<LibraryElement> get exportedLibraries;

  /// The export [Namespace] of this library.
  Namespace get exportNamespace;

  /// The identifier that uniquely identifies this element among the children
  /// of this element's parent.
  String get identifier;

  /// The libraries that are imported into this library.
  ///
  /// This includes all of the libraries that are imported using a prefix, and
  /// those that are imported without a prefix.
  List<LibraryElement> get importedLibraries;

  /// Whether the library is an application that can be run in the browser.
  bool get isBrowserApplication;

  /// Whether the library is the `dart:async` library.
  bool get isDartAsync;

  /// Whether the library is the `dart:core` library.
  bool get isDartCore;

  /// Whether the library is part of the SDK.
  bool get isInSdk;

  /// The element representing the synthetic function `loadLibrary` that is
  /// implicitly defined for this library if the library is imported using a
  /// deferred import.
  FunctionElement get loadLibraryFunction;

  /// The name of this library, possibly the empty string if this library does
  /// not have an explicit name.
  @override
  String get name;

  /// The list of `part` directives of this library.
  List<PartElement> get parts;

  /// The public [Namespace] of this library.
  Namespace get publicNamespace;

  /// The top-level elements defined in each of the compilation units that are
  /// included in this library. This includes both public and private elements,
  /// but does not include imports, exports, or synthetic elements.
  Iterable<Element> get topLevelElements;

  /// The compilation units this library consists of.
  ///
  /// This includes the defining compilation unit and units included using the
  /// `part` directive.
  List<CompilationUnitElement> get units;

  /// The class defined in this library that has the given [name], or
  /// `null` if this library does not define a class with the given name.
  ClassElement? getClass(String name);

  /// If a legacy library, returns the legacy view on the [element].
  ///
  /// Otherwise, return the original element.
  T toLegacyElementIfOptOut<T extends Element>(T element);

  /// If a legacy library, return the legacy version of the [type].
  /// Otherwise, return the original type.
  DartType toLegacyTypeIfOptOut(DartType type);
}

/// A concrete implementation of a [LibraryElement].
class LibraryElementImpl extends LibraryOrAugmentationElementImpl
    with _HasLibraryMixin
    implements LibraryElement {
  /// The analysis context in which this library is defined.
  @override
  final AnalysisContext context;

  @override
  AnalysisSessionImpl session;

  /// The language version for the library.
  LibraryLanguageVersion? _languageVersion;

  bool hasTypeProviderSystemSet = false;

  @override
  late TypeProviderImpl typeProvider;

  @override
  late TypeSystemImpl typeSystem;

  late final List<ExportedReference> exportedReferences;

  LibraryElementLinkedData? linkedData;

  /// The union of names for all searchable elements in this library.
  ElementNameUnion nameUnion = ElementNameUnion.empty();

  @override
  final FeatureSet featureSet;

  /// The entry point for this library, or `null` if this library does not have
  /// an entry point.
  FunctionElement? _entryPoint;

  /// The list of `part` directives of this library.
  List<PartElementImpl> _parts = const <PartElementImpl>[];

  /// The element representing the synthetic function `loadLibrary` that is
  /// defined for this library, or `null` if the element has not yet been
  /// created.
  late FunctionElement _loadLibraryFunction;

  @override
  int nameLength;

  /// The export [Namespace] of this library, `null` if it has not been
  /// computed yet.
  Namespace? _exportNamespace;

  /// The public [Namespace] of this library, `null` if it has not been
  /// computed yet.
  Namespace? _publicNamespace;

  /// The macro executor for the bundle to which this library belongs.
  BundleMacroExecutor? bundleMacroExecutor;

  /// All augmentations of this library, in the depth-first pre-order order.
  late final List<LibraryAugmentationElementImpl> augmentations =
      _computeAugmentations();

  /// Initialize a newly created library element in the given [context] to have
  /// the given [name] and [offset].
  LibraryElementImpl(this.context, this.session, String name, int offset,
      this.nameLength, this.featureSet)
      : linkedData = null,
        super(name: name, nameOffset: offset);

  @override
  List<ExtensionElement> get accessibleExtensions => scope.extensions;

  @override
  List<AugmentationImportElementImpl> get augmentationImports {
    _readLinkedData();
    return super.augmentationImports;
  }

  @override
  List<Element> get children => [
        ...super.children,
        ...parts,
        ..._partUnits,
      ];

  @override
  CompilationUnitElementImpl get enclosingUnit {
    return _definingCompilationUnit;
  }

  @override
  FunctionElement? get entryPoint {
    _readLinkedData();
    return _entryPoint;
  }

  set entryPoint(FunctionElement? entryPoint) {
    _entryPoint = entryPoint;
  }

  @override
  List<LibraryElementImpl> get exportedLibraries {
    return libraryExports
        .map((import) => import.exportedLibrary)
        .whereNotNull()
        .toSet()
        .toList();
  }

  @override
  Namespace get exportNamespace {
    if (_exportNamespace != null) return _exportNamespace!;

    final linkedData = this.linkedData;
    if (linkedData != null) {
      var elements = linkedData.elementFactory;
      return _exportNamespace = elements.buildExportNamespace(
        source.uri,
        exportedReferences,
      );
    }

    return _exportNamespace!;
  }

  set exportNamespace(Namespace exportNamespace) {
    _exportNamespace = exportNamespace;
  }

  bool get hasPartOfDirective {
    return hasModifier(Modifier.HAS_PART_OF_DIRECTIVE);
  }

  set hasPartOfDirective(bool hasPartOfDirective) {
    setModifier(Modifier.HAS_PART_OF_DIRECTIVE, hasPartOfDirective);
  }

  @override
  String get identifier => '${_definingCompilationUnit.source.uri}';

  @override
  List<LibraryElementImpl> get importedLibraries {
    return libraryImports
        .map((import) => import.importedLibrary)
        .whereNotNull()
        .toSet()
        .toList();
  }

  @override
  bool get isBrowserApplication =>
      entryPoint != null && isOrImportsBrowserLibrary;

  @override
  bool get isDartAsync => name == "dart.async";

  @override
  bool get isDartCore => name == "dart.core";

  @override
  bool get isInSdk {
    var uri = definingCompilationUnit.source.uri;
    return DartUriResolver.isDartUri(uri);
  }

  @override
  bool get isNonNullableByDefault =>
      ElementTypeProvider.current.isLibraryNonNullableByDefault(this);

  bool get isNonNullableByDefaultInternal {
    return featureSet.isEnabled(Feature.non_nullable);
  }

  /// Return `true` if the receiver directly or indirectly imports the
  /// 'dart:html' libraries.
  bool get isOrImportsBrowserLibrary {
    List<LibraryElement> visited = <LibraryElement>[];
    var htmlLibSource = context.sourceFactory.forUri(DartSdk.DART_HTML);
    visited.add(this);
    for (int index = 0; index < visited.length; index++) {
      LibraryElement library = visited[index];
      var source = library.definingCompilationUnit.source;
      if (source == htmlLibSource) {
        return true;
      }
      for (LibraryElement importedLibrary in library.importedLibraries) {
        if (!visited.contains(importedLibrary)) {
          visited.add(importedLibrary);
        }
      }
      for (LibraryElement exportedLibrary in library.exportedLibraries) {
        if (!visited.contains(exportedLibrary)) {
          visited.add(exportedLibrary);
        }
      }
    }
    return false;
  }

  @override
  ElementKind get kind => ElementKind.LIBRARY;

  @override
  LibraryLanguageVersion get languageVersion {
    return _languageVersion ??= LibraryLanguageVersion(
      package: ExperimentStatus.currentVersion,
      override: null,
    );
  }

  set languageVersion(LibraryLanguageVersion languageVersion) {
    _languageVersion = languageVersion;
  }

  @override
  LibraryElementImpl get library => this;

  @override
  List<LibraryExportElementImpl> get libraryExports {
    _readLinkedData();
    return _libraryExports;
  }

  @override
  List<LibraryImportElementImpl> get libraryImports {
    _readLinkedData();
    return _libraryImports;
  }

  @override
  FunctionElement get loadLibraryFunction {
    return _loadLibraryFunction;
  }

  @override
  List<ElementAnnotation> get metadata {
    _readLinkedData();
    return super.metadata;
  }

  @override
  String get name => super.name!;

  @override
  List<PartElementImpl> get parts => _parts;

  set parts(List<PartElementImpl> parts) {
    for (final part in parts) {
      part.enclosingElement = this;
      final uri = part.uri;
      if (uri is DirectiveUriWithUnitImpl) {
        uri.unit.enclosingElement = this;
      }
    }
    _parts = parts;
  }

  @override
  List<PrefixElementImpl> get prefixes =>
      _prefixes ??= buildPrefixesFromImports(libraryImports);

  @override
  Namespace get publicNamespace {
    return _publicNamespace ??=
        NamespaceBuilder().createPublicNamespaceForLibrary(this);
  }

  set publicNamespace(Namespace publicNamespace) {
    _publicNamespace = publicNamespace;
  }

  @override
  Source get source {
    return _definingCompilationUnit.source;
  }

  @override
  Iterable<Element> get topLevelElements sync* {
    for (var unit in units) {
      yield* unit.accessors;
      yield* unit.classes;
      yield* unit.enums;
      yield* unit.extensions;
      yield* unit.functions;
      yield* unit.mixins;
      yield* unit.topLevelVariables;
      yield* unit.typeAliases;
    }
  }

  @override
  List<CompilationUnitElementImpl> get units {
    return [
      _definingCompilationUnit,
      ..._partUnits,
      ...augmentations.map((e) => e.definingCompilationUnit),
    ];
  }

  List<CompilationUnitElementImpl> get _partUnits {
    return parts
        .map((e) => e.uri)
        .whereType<DirectiveUriWithUnitImpl>()
        .map((e) => e.unit)
        .toList();
  }

  @override
  T? accept<T>(ElementVisitor<T> visitor) => visitor.visitLibraryElement(this);

  @override
  void appendTo(ElementDisplayStringBuilder builder) {
    builder.writeLibraryElement(this);
  }

  /// Create the [FunctionElement] to be returned by [loadLibraryFunction].
  /// The [typeProvider] must be already set.
  void createLoadLibraryFunction() {
    _loadLibraryFunction =
        FunctionElementImpl(FunctionElement.LOAD_LIBRARY_NAME, -1)
          ..enclosingElement = library
          ..isSynthetic = true
          ..returnType = typeProvider.futureDynamicType;
  }

  @override
  ClassElement? getClass(String name) {
    for (final unitElement in units) {
      final element = unitElement.getClass(name);
      if (element != null) {
        return element;
      }
    }
    return null;
  }

  EnumElement? getEnum(String name) {
    for (final unitElement in units) {
      final element = unitElement.getEnum(name);
      if (element != null) {
        return element;
      }
    }
    return null;
  }

  /// Return `true` if [reference] comes only from deprecated exports.
  bool isFromDeprecatedExport(ExportedReference reference) {
    if (reference is ExportedReferenceExported) {
      for (final location in reference.locations) {
        final export = location.exportOf(this);
        if (!export.hasDeprecated) {
          return false;
        }
      }
      return true;
    }
    return false;
  }

  /// Indicates whether it is unnecessary to report an undefined identifier
  /// error for an identifier reference with the given [name] and optional
  /// [prefix].
  ///
  /// This method is intended to reduce spurious errors in circumstances where
  /// an undefined identifier occurs as the result of a missing (most likely
  /// code generated) file.  It will only return `true` in a circumstance where
  /// the current library is guaranteed to have at least one other error (due to
  /// a missing part or import), so there is no risk that ignoring the undefined
  /// identifier would cause an invalid program to be treated as valid.
  bool shouldIgnoreUndefined({
    required String? prefix,
    required String name,
  }) {
    for (var importElement in libraryImports) {
      if (importElement.prefix?.element.name == prefix &&
          importElement.importedLibrary?.isSynthetic != false) {
        var showCombinators = importElement.combinators
            .whereType<ShowElementCombinator>()
            .toList();
        if (prefix != null && showCombinators.isEmpty) {
          return true;
        }
        for (var combinator in showCombinators) {
          if (combinator.shownNames.contains(name)) {
            return true;
          }
        }
      }
    }

    if (prefix == null && name.startsWith(r'_$')) {
      for (final augmentation in augmentationImports) {
        final uri = augmentation.uri;
        if (uri is DirectiveUriWithSource &&
            uri is! DirectiveUriWithAugmentation &&
            file_paths.isGenerated(uri.relativeUriString)) {
          return true;
        }
      }
      for (var partElement in parts) {
        final uri = partElement.uri;
        if (uri is DirectiveUriWithSource &&
            uri is! DirectiveUriWithUnit &&
            file_paths.isGenerated(uri.relativeUriString)) {
          return true;
        }
      }
    }

    return false;
  }

  /// Convenience wrapper around [shouldIgnoreUndefined] that calls it for a
  /// given (possibly prefixed) identifier [node].
  bool shouldIgnoreUndefinedIdentifier(Identifier node) {
    if (node is PrefixedIdentifier) {
      return shouldIgnoreUndefined(
        prefix: node.prefix.name,
        name: node.identifier.name,
      );
    }

    return shouldIgnoreUndefined(
      prefix: null,
      name: (node as SimpleIdentifier).name,
    );
  }

  /// Convenience wrapper around [shouldIgnoreUndefined] that calls it for a
  /// given (possibly prefixed) named type [node].
  bool shouldIgnoreUndefinedNamedType(NamedType node) {
    return shouldIgnoreUndefined(
      prefix: node.importPrefix?.name.lexeme,
      name: node.name2.lexeme,
    );
  }

  @override
  T toLegacyElementIfOptOut<T extends Element>(T element) {
    if (isNonNullableByDefault) return element;
    return Member.legacy(element) as T;
  }

  @override
  DartType toLegacyTypeIfOptOut(DartType type) {
    if (isNonNullableByDefault) return type;
    return NullabilityEliminator.perform(typeProvider, type);
  }

  List<LibraryAugmentationElementImpl> _computeAugmentations() {
    final result = <LibraryAugmentationElementImpl>[];

    void visitAugmentations(LibraryOrAugmentationElementImpl container) {
      if (container is LibraryAugmentationElementImpl) {
        result.add(container);
      }
      for (final import in container.augmentationImports) {
        final augmentation = import.importedAugmentation;
        if (augmentation != null) {
          visitAugmentations(augmentation);
        }
      }
    }

    visitAugmentations(this);
    return result.toFixedList();
  }

  @override
  void _readLinkedData() {
    linkedData?.read(this);
  }

  static List<PrefixElementImpl> buildPrefixesFromImports(
      List<LibraryImportElementImpl> imports) {
    var prefixes = HashSet<PrefixElementImpl>();
    for (var element in imports) {
      var prefix = element.prefix?.element;
      if (prefix != null) {
        prefixes.add(prefix);
      }
    }
    return prefixes.toList(growable: false);
  }
}

/// A single export directive within a library.
///
/// Clients may not extend, implement or mix-in this class.
abstract class LibraryExportElement implements _ExistingElement {
  /// The combinators that were specified as part of the `export` directive in
  /// the order in which they were specified.
  List<NamespaceCombinator> get combinators;

  /// The [LibraryElement], if [uri] is a [DirectiveUriWithLibrary].
  LibraryElement? get exportedLibrary;

  /// The offset of the `export` keyword.
  int get exportKeywordOffset;

  /// The interpretation of the URI specified in the directive.
  DirectiveUri get uri;
}

class LibraryExportElementImpl extends _ExistingElementImpl
    implements LibraryExportElement {
  @override
  final List<NamespaceCombinator> combinators;

  @override
  final int exportKeywordOffset;

  @override
  final DirectiveUri uri;

  LibraryExportElementImpl({
    required this.combinators,
    required this.exportKeywordOffset,
    required this.uri,
  }) : super(null, exportKeywordOffset);

  @override
  LibraryElementImpl? get exportedLibrary {
    final uri = this.uri;
    if (uri is DirectiveUriWithLibraryImpl) {
      return uri.library;
    }
    return null;
  }

  @override
  int get hashCode => identityHashCode(this);

  @override
  String get identifier => 'export@$nameOffset';

  @override
  ElementKind get kind => ElementKind.EXPORT;

  @override
  bool operator ==(Object other) {
    return identical(this, other);
  }

  @override
  T? accept<T>(ElementVisitor<T> visitor) {
    return visitor.visitLibraryExportElement(this);
  }

  @override
  void appendTo(ElementDisplayStringBuilder builder) {
    builder.writeExportElement(this);
  }
}

/// A single import directive within a library.
///
/// Clients may not extend, implement or mix-in this class.
abstract class LibraryImportElement implements _ExistingElement {
  /// The combinators that were specified as part of the `import` directive in
  /// the order in which they were specified.
  List<NamespaceCombinator> get combinators;

  /// The [LibraryElement], if [uri] is a [DirectiveUriWithLibrary].
  LibraryElement? get importedLibrary;

  /// The offset of the `import` keyword.
  int get importKeywordOffset;

  /// The [Namespace] that this directive contributes to the containing library.
  Namespace get namespace;

  /// The prefix that was specified as part of the import directive, or `null`
  /// if there was no prefix specified.
  ImportElementPrefix? get prefix;

  /// The interpretation of the URI specified in the directive.
  DirectiveUri get uri;
}

class LibraryImportElementImpl extends _ExistingElementImpl
    implements LibraryImportElement {
  @override
  final List<NamespaceCombinator> combinators;

  @override
  final int importKeywordOffset;

  @override
  final ImportElementPrefixImpl? prefix;

  @override
  final DirectiveUri uri;

  Namespace? _namespace;

  LibraryImportElementImpl({
    required this.combinators,
    required this.importKeywordOffset,
    required this.prefix,
    required this.uri,
  }) : super(null, importKeywordOffset);

  @override
  int get hashCode => identityHashCode(this);

  @override
  String get identifier => 'import@$nameOffset';

  @override
  LibraryElementImpl? get importedLibrary {
    final uri = this.uri;
    if (uri is DirectiveUriWithLibraryImpl) {
      return uri.library;
    }
    return null;
  }

  @override
  ElementKind get kind => ElementKind.IMPORT;

  @override
  Namespace get namespace {
    final uri = this.uri;
    if (uri is DirectiveUriWithLibrary) {
      return _namespace ??=
          NamespaceBuilder().createImportNamespaceForDirective(
        importedLibrary: uri.library,
        combinators: combinators,
        prefix: prefix?.element,
      );
    }
    return Namespace.EMPTY;
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other);
  }

  @override
  T? accept<T>(ElementVisitor<T> visitor) {
    return visitor.visitLibraryImportElement(this);
  }

  @override
  void appendTo(ElementDisplayStringBuilder builder) {
    builder.writeImportElement(this);
  }
}

/// Shared interface between [LibraryElement] and [LibraryAugmentationElement].
///
/// Clients may not extend, implement or mix-in this class.
@experimental
abstract class LibraryOrAugmentationElement implements Element {
  /// The extension elements accessible within this library.
  List<ExtensionElement> get accessibleExtensions;

  /// The augmentation imports specified in this library.
  @experimental
  List<AugmentationImportElement> get augmentationImports;

  /// The compilation unit that defines this library.
  CompilationUnitElement get definingCompilationUnit;

  /// The set of features available to this library.
  ///
  /// Determined by the combination of the language version for the enclosing
  /// package, enabled experiments, and the presence of a `// @dart` language
  /// version override comment at the top of the file.
  FeatureSet get featureSet;

  bool get isNonNullableByDefault;

  /// The language version for this library.
  LibraryLanguageVersion get languageVersion;

  @override
  LibraryElement get library;

  /// The exports defined in this library.
  List<LibraryExportElement> get libraryExports;

  /// The imports defined in this library.
  List<LibraryImportElement> get libraryImports;

  /// The prefixes used to `import` libraries into this library.
  ///
  /// Each prefix can be used in more than one `import` directive.
  List<PrefixElement> get prefixes;

  /// The name lookup scope for this library.
  ///
  /// It consists of elements that are either declared in the library, or
  /// imported into it.
  Scope get scope;

  @override
  AnalysisSession get session;

  /// The [TypeProvider] that is used in this library.
  TypeProvider get typeProvider;

  /// The [TypeSystem] that is used in this library.
  TypeSystem get typeSystem;
}

/// A concrete implementation of a [LibraryOrAugmentationElement].
abstract class LibraryOrAugmentationElementImpl extends ElementImpl
    implements LibraryOrAugmentationElement, MacroTargetElementContainer {
  /// The compilation unit that defines this library.
  late CompilationUnitElementImpl _definingCompilationUnit;

  List<AugmentationImportElementImpl> _augmentationImports =
      _Sentinel.augmentationImportElement;

  /// A list containing specifications of all of the imports defined in this
  /// library.
  List<LibraryExportElementImpl> _libraryExports =
      _Sentinel.libraryExportElement;

  /// A list containing specifications of all of the imports defined in this
  /// library.
  List<LibraryImportElementImpl> _libraryImports =
      _Sentinel.libraryImportElement;

  /// The cached list of prefixes.
  List<PrefixElementImpl>? _prefixes;

  /// The scope of this library, `null` if it has not been created yet.
  LibraryOrAugmentationScope? _scope;

  LibraryOrAugmentationElementImpl({
    required String? name,
    required int nameOffset,
  }) : super(name, nameOffset);

  @override
  List<AugmentationImportElementImpl> get augmentationImports {
    return _augmentationImports;
  }

  set augmentationImports(List<AugmentationImportElementImpl> imports) {
    for (final importElement in imports) {
      importElement.enclosingElement = this;
      importElement.importedAugmentation?.enclosingElement = this;
    }
    _augmentationImports = imports;
  }

  @override
  List<Element> get children => [
        ...super.children,
        definingCompilationUnit,
        ...libraryExports,
        ...libraryImports,
        ...augmentationImports,
      ];

  @override
  CompilationUnitElementImpl get definingCompilationUnit =>
      _definingCompilationUnit;

  /// Set the compilation unit that defines this library to the given
  ///  compilation[unit].
  set definingCompilationUnit(CompilationUnitElement unit) {
    assert((unit as CompilationUnitElementImpl).librarySource == unit.source);
    (unit as CompilationUnitElementImpl).enclosingElement = this;
    _definingCompilationUnit = unit;
  }

  @override
  CompilationUnitElementImpl get enclosingUnit {
    return _definingCompilationUnit;
  }

  List<LibraryExportElementImpl> get exports_unresolved {
    return _libraryExports;
  }

  @override
  String get identifier => '${_definingCompilationUnit.source.uri}';

  List<LibraryImportElementImpl> get imports_unresolved {
    return _libraryImports;
  }

  @override
  LibraryElementImpl get library;

  @override
  List<LibraryExportElementImpl> get libraryExports {
    _readLinkedData();
    return _libraryExports;
  }

  /// Set the specifications of all of the exports defined in this library to
  /// the given list of [exports].
  set libraryExports(List<LibraryExportElementImpl> exports) {
    for (final exportElement in exports) {
      exportElement.enclosingElement = this;
    }
    _libraryExports = exports;
  }

  @override
  List<LibraryImportElementImpl> get libraryImports;

  /// Set the specifications of all of the imports defined in this library to
  /// the given list of [imports].
  set libraryImports(List<LibraryImportElementImpl> imports) {
    for (final importElement in imports) {
      importElement.enclosingElement = this;
    }
    _libraryImports = imports;
    _prefixes = null;
  }

  @override
  List<PrefixElementImpl> get prefixes =>
      _prefixes ??= buildPrefixesFromImports(libraryImports);

  @override
  LibraryOrAugmentationScope get scope {
    return _scope ??= LibraryOrAugmentationScope(this);
  }

  @override
  AnalysisSessionImpl get session;

  @override
  Source get source {
    return _definingCompilationUnit.source;
  }

  void _readLinkedData();

  static List<PrefixElementImpl> buildPrefixesFromImports(
      List<LibraryImportElementImpl> imports) {
    var prefixes = HashSet<PrefixElementImpl>();
    for (final import in imports) {
      var prefix = import.prefix;
      if (prefix != null) {
        prefixes.add(prefix.element);
      }
    }
    return prefixes.toList(growable: false);
  }
}

/// An element that can be (but is not required to be) defined within a method
/// or function (an [ExecutableElement]).
///
/// Clients may not extend, implement or mix-in this class.
abstract class LocalElement implements Element {}

/// A local variable.
///
/// Clients may not extend, implement or mix-in this class.
abstract class LocalVariableElement implements PromotableElement {
  /// Whether the variable has an initializer at declaration.
  bool get hasInitializer;

  @override
  String get name;
}

/// A concrete implementation of a [LocalVariableElement].
class LocalVariableElementImpl extends NonParameterVariableElementImpl
    implements LocalVariableElement {
  @override
  late bool hasInitializer;

  /// Initialize a newly created method element to have the given [name] and
  /// [offset].
  LocalVariableElementImpl(super.name, super.offset);

  @override
  String get identifier {
    return '$name$nameOffset';
  }

  @override
  bool get isLate {
    return hasModifier(Modifier.LATE);
  }

  @override
  ElementKind get kind => ElementKind.LOCAL_VARIABLE;

  @override
  T? accept<T>(ElementVisitor<T> visitor) =>
      visitor.visitLocalVariableElement(this);
}

mixin MacroTargetElement {
  /// Errors registered while applying macros to this element.
  List<MacroApplicationError> macroApplicationErrors = const [];

  void addMacroApplicationError(MacroApplicationError error) {
    macroApplicationErrors = [...macroApplicationErrors, error];
  }
}

/// Marker interface for elements that may have [MacroTargetElement]s.
class MacroTargetElementContainer {}

/// An element that represents a method defined within a class.
///
/// Clients may not extend, implement or mix-in this class.
abstract class MethodElement implements ClassMemberElement, ExecutableElement {
  @experimental
  @override
  MethodElement? get augmentation;

  @experimental
  @override
  MethodElement? get augmentationTarget;

  @override
  MethodElement get declaration;
}

/// A concrete implementation of a [MethodElement].
class MethodElementImpl extends ExecutableElementImpl
    with _HasAugmentation<MethodElementImpl>
    implements MethodElement {
  /// Is `true` if this method is `operator==`, and there is no explicit
  /// type specified for its formal parameter, in this method or in any
  /// overridden methods other than the one declared in `Object`.
  bool isOperatorEqualWithParameterTypeFromObject = false;

  /// The error reported during type inference for this variable, or `null` if
  /// this variable is not a subject of type inference, or there was no error.
  TopLevelInferenceError? typeInferenceError;

  /// If this method is a synthetic element which is based on another method
  /// with some modifications (such as making some parameters covariant),
  /// this field contains the base method.
  MethodElement? prototype;

  /// Initialize a newly created method element to have the given [name] at the
  /// given [offset].
  MethodElementImpl(super.name, super.offset);

  @override
  MethodElement get declaration => prototype ?? this;

  @override
  String get displayName {
    String displayName = super.displayName;
    if ("unary-" == displayName) {
      return "-";
    }
    return displayName;
  }

  /// Set whether this class is abstract.
  set isAbstract(bool isAbstract) {
    setModifier(Modifier.ABSTRACT, isAbstract);
  }

  @override
  bool get isOperator {
    String name = displayName;
    if (name.isEmpty) {
      return false;
    }
    int first = name.codeUnitAt(0);
    return !((0x61 <= first && first <= 0x7A) ||
        (0x41 <= first && first <= 0x5A) ||
        first == 0x5F ||
        first == 0x24);
  }

  @override
  ElementKind get kind => ElementKind.METHOD;

  @override
  String get name {
    String name = super.name;
    if (name == '-' && parametersInternal.isEmpty) {
      return 'unary-';
    }
    return name;
  }

  @override
  Element get nonSynthetic {
    if (isSynthetic && enclosingElement2 is EnumElementImpl) {
      return enclosingElement2;
    }
    return this;
  }

  @override
  T? accept<T>(ElementVisitor<T> visitor) => visitor.visitMethodElement(this);
}

/// An element that represents a mixin.
///
/// Clients may not extend, implement or mix-in this class.
abstract class MixinElement implements InterfaceElement {
  @experimental
  @override
  MixinElement? get augmentation;

  @experimental
  @override
  MixinElement? get augmentationTarget;

  @experimental
  @override
  AugmentedMixinElement? get augmented;

  /// Whether the mixin is a base mixin.
  ///
  /// A mixin is a base mixin if it has an explicit `base` modifier.
  /// The base modifier allows a mixin to be mixed in, but not implemented.
  bool get isBase;

  /// The superclass constraints defined for this mixin.
  ///
  /// If the declaration does not have an `on` clause, then the list will
  /// contain the type for the class `Object`.
  ///
  /// <b>Note:</b> Because the element model represents the state of the code,
  /// it is possible for it to be semantically invalid. In particular, it is not
  /// safe to assume that the inheritance structure of a class does not contain
  /// a cycle. Clients that traverse the inheritance structure must explicitly
  /// guard against infinite loops.
  List<InterfaceType> get superclassConstraints;

  /// Whether the element, assuming that it is within scope, is
  /// implementable to classes, mixins, and enums in the given [library].
  bool isImplementableIn(LibraryElement library);
}

/// A [ClassElementImpl] representing a mixin declaration.
class MixinElementImpl extends ClassOrMixinElementImpl
    with _HasAugmentation<MixinElementImpl>
    implements MixinElement {
  List<InterfaceType> _superclassConstraints = const [];

  /// Names of methods, getters, setters, and operators that this mixin
  /// declaration super-invokes.  For setters this includes the trailing "=".
  /// The list will be empty if this class is not a mixin declaration.
  late List<String> superInvokedNames;

  late AugmentedMixinElement augmentedInternal =
      NotAugmentedMixinElementImpl(this);

  /// Initialize a newly created class element to have the given [name] at the
  /// given [offset] in the file that contains the declaration of this element.
  MixinElementImpl(super.name, super.offset);

  @override
  AugmentedMixinElement? get augmented {
    if (isAugmentation) {
      return augmentationTarget?.augmented;
    } else {
      linkedData?.read(this);
      return augmentedInternal;
    }
  }

  @override
  bool get isBase {
    return hasModifier(Modifier.BASE);
  }

  @override
  List<InterfaceType> get mixins => const [];

  @override
  set mixins(List<InterfaceType> mixins) {
    throw StateError('Attempt to set mixins for a mixin declaration.');
  }

  @override
  List<InterfaceType> get superclassConstraints {
    linkedData?.read(this);
    return _superclassConstraints;
  }

  set superclassConstraints(List<InterfaceType> superclassConstraints) {
    _superclassConstraints = superclassConstraints;
  }

  @override
  InterfaceType? get supertype => null;

  @override
  set supertype(InterfaceType? supertype) {
    throw StateError('Attempt to set a supertype for a mixin declaration.');
  }

  @override
  T? accept<T>(ElementVisitor<T> visitor) {
    return visitor.visitMixinElement(this);
  }

  @override
  void appendTo(ElementDisplayStringBuilder builder) {
    builder.writeMixinElement(this);
  }

  @override
  bool isImplementableIn(LibraryElement library) {
    if (library == this.library) {
      return true;
    }
    return !isBase;
  }
}

/// The constants for all of the modifiers defined by the Dart language and for
/// a few additional flags that are useful.
///
/// Clients may not extend, implement or mix-in this class.
class Modifier implements Comparable<Modifier> {
  /// Indicates that the modifier 'abstract' was applied to the element.
  static const Modifier ABSTRACT = Modifier('ABSTRACT', 0);

  /// Indicates that an executable element has a body marked as being
  /// asynchronous.
  static const Modifier ASYNCHRONOUS = Modifier('ASYNCHRONOUS', 1);

  /// Indicates that the modifier 'augment' was applied to the element.
  static const Modifier AUGMENTATION = Modifier('AUGMENTATION', 2);

  /// Indicates that the modifier 'base' was applied to the element.
  static const Modifier BASE = Modifier('BASE', 3);

  /// Indicates that the modifier 'const' was applied to the element.
  static const Modifier CONST = Modifier('CONST', 4);

  /// Indicates that the modifier 'covariant' was applied to the element.
  static const Modifier COVARIANT = Modifier('COVARIANT', 5);

  /// Indicates that the class is `Object` from `dart:core`.
  static const Modifier DART_CORE_OBJECT = Modifier('DART_CORE_OBJECT', 6);

  /// Indicates that the import element represents a deferred library.
  static const Modifier DEFERRED = Modifier('DEFERRED', 7);

  /// Indicates that a class element was defined by an enum declaration.
  static const Modifier ENUM = Modifier('ENUM', 8);

  /// Indicates that the element is an enum constant field.
  static const Modifier ENUM_CONSTANT = Modifier('ENUM_CONSTANT', 9);

  /// Indicates that a class element was defined by an enum declaration.
  static const Modifier EXTERNAL = Modifier('EXTERNAL', 10);

  /// Indicates that the modifier 'factory' was applied to the element.
  static const Modifier FACTORY = Modifier('FACTORY', 11);

  /// Indicates that the modifier 'final' was applied to the element.
  static const Modifier FINAL = Modifier('FINAL', 12);

  /// Indicates that an executable element has a body marked as being a
  /// generator.
  static const Modifier GENERATOR = Modifier('GENERATOR', 13);

  /// Indicates that the pseudo-modifier 'get' was applied to the element.
  static const Modifier GETTER = Modifier('GETTER', 14);

  /// A flag used for libraries indicating that the variable has an explicit
  /// initializer.
  static const Modifier HAS_INITIALIZER = Modifier('HAS_INITIALIZER', 15);

  /// A flag used for libraries indicating that the defining compilation unit
  /// has a `part of` directive, meaning that this unit should be a part,
  /// but is used as a library.
  static const Modifier HAS_PART_OF_DIRECTIVE =
      Modifier('HAS_PART_OF_DIRECTIVE', 16);

  /// Indicates that the value of [Element.sinceSdkVersion] was computed.
  static const Modifier HAS_SINCE_SDK_VERSION_COMPUTED =
      Modifier('HAS_SINCE_SDK_VERSION_COMPUTED', 17);

  /// [HAS_SINCE_SDK_VERSION_COMPUTED] and the value was not `null`.
  static const Modifier HAS_SINCE_SDK_VERSION_VALUE =
      Modifier('HAS_SINCE_SDK_VERSION_VALUE', 18);

  /// Indicates that the associated element did not have an explicit type
  /// associated with it. If the element is an [ExecutableElement], then the
  /// type being referred to is the return type.
  static const Modifier IMPLICIT_TYPE = Modifier('IMPLICIT_TYPE', 19);

  /// Indicates that the modifier 'inline' was applied to the element.
  static const Modifier INLINE = Modifier('INLINE', 20);

  /// Indicates that the modifier 'interface' was applied to the element.
  static const Modifier INTERFACE = Modifier('INTERFACE', 21);

  /// Indicates that the method invokes the super method with the same name.
  static const Modifier INVOKES_SUPER_SELF = Modifier('INVOKES_SUPER_SELF', 22);

  /// Indicates that modifier 'lazy' was applied to the element.
  static const Modifier LATE = Modifier('LATE', 23);

  /// Indicates that a class is a macro builder.
  static const Modifier MACRO = Modifier('MACRO', 24);

  /// Indicates that a class is a mixin application.
  static const Modifier MIXIN_APPLICATION = Modifier('MIXIN_APPLICATION', 25);

  /// Indicates that a class is a mixin class.
  static const Modifier MIXIN_CLASS = Modifier('MIXIN_CLASS', 26);

  static const Modifier PROMOTABLE = Modifier('IS_PROMOTABLE', 27);

  /// Indicates whether the type of a [PropertyInducingElementImpl] should be
  /// used to infer the initializer. We set it to `false` if the type was
  /// inferred from the initializer itself.
  static const Modifier SHOULD_USE_TYPE_FOR_INITIALIZER_INFERENCE =
      Modifier('SHOULD_USE_TYPE_FOR_INITIALIZER_INFERENCE', 28);

  /// Indicates that the modifier 'sealed' was applied to the element.
  static const Modifier SEALED = Modifier('SEALED', 29);

  /// Indicates that the pseudo-modifier 'set' was applied to the element.
  static const Modifier SETTER = Modifier('SETTER', 30);

  /// See [TypeParameterizedElement.isSimplyBounded].
  static const Modifier SIMPLY_BOUNDED = Modifier('SIMPLY_BOUNDED', 31);

  /// Indicates that the modifier 'static' was applied to the element.
  static const Modifier STATIC = Modifier('STATIC', 32);

  /// Indicates that the element does not appear in the source code but was
  /// implicitly created. For example, if a class does not define any
  /// constructors, an implicit zero-argument constructor will be created and it
  /// will be marked as being synthetic.
  static const Modifier SYNTHETIC = Modifier('SYNTHETIC', 33);

  /// Indicates that the element was appended to this enclosing element to
  /// simulate temporary the effect of applying augmentation.
  static const Modifier TEMP_AUGMENTATION = Modifier('TEMP_AUGMENTATION', 34);

  static const List<Modifier> values = [
    ABSTRACT,
    ASYNCHRONOUS,
    BASE,
    CONST,
    COVARIANT,
    DART_CORE_OBJECT,
    DEFERRED,
    ENUM,
    ENUM_CONSTANT,
    EXTERNAL,
    FACTORY,
    FINAL,
    GENERATOR,
    GETTER,
    HAS_INITIALIZER,
    HAS_PART_OF_DIRECTIVE,
    HAS_SINCE_SDK_VERSION_COMPUTED,
    HAS_SINCE_SDK_VERSION_VALUE,
    IMPLICIT_TYPE,
    INLINE,
    INTERFACE,
    INVOKES_SUPER_SELF,
    LATE,
    MACRO,
    MIXIN_APPLICATION,
    MIXIN_CLASS,
    PROMOTABLE,
    SEALED,
    SETTER,
    STATIC,
    SIMPLY_BOUNDED,
    SYNTHETIC,
    TEMP_AUGMENTATION,
  ];

  /// The name of this modifier.
  final String name;

  /// The ordinal value of the modifier.
  final int ordinal;

  const Modifier(this.name, this.ordinal);

  @override
  int get hashCode => ordinal;

  @override
  int compareTo(Modifier other) => ordinal - other.ordinal;

  @override
  String toString() => name;
}

/// A pseudo-element that represents multiple elements defined within a single
/// scope that have the same name. This situation is not allowed by the
/// language, so objects implementing this interface always represent an error.
/// As a result, most of the normal operations on elements do not make sense
/// and will return useless results.
///
/// Clients may not extend, implement or mix-in this class.
abstract class MultiplyDefinedElement implements Element {
  /// The elements that were defined within the scope to have the same name.
  List<Element> get conflictingElements;
}

/// A concrete implementation of a [MultiplyDefinedElement].
class MultiplyDefinedElementImpl implements MultiplyDefinedElement {
  /// The unique integer identifier of this element.
  @override
  final int id = ElementImpl._NEXT_ID++;

  /// The analysis context in which the multiply defined elements are defined.
  @override
  final AnalysisContext context;

  @override
  final AnalysisSession session;

  /// The name of the conflicting elements.
  @override
  final String name;

  @override
  final List<Element> conflictingElements;

  /// Initialize a newly created element in the given [context] to represent
  /// the given non-empty [conflictingElements].
  MultiplyDefinedElementImpl(
      this.context, this.session, this.name, this.conflictingElements);

  @override
  List<Element> get children => const [];

  @override
  Element? get declaration => null;

  @override
  String get displayName => name;

  @override
  String? get documentationComment => null;

  @Deprecated('Use enclosingElement2 instead')
  @override
  Element? get enclosingElement => null;

  @override
  Element? get enclosingElement2 => null;

  @override
  bool get hasAlwaysThrows => false;

  @override
  bool get hasDeprecated => false;

  @override
  bool get hasDoNotStore => false;

  @override
  bool get hasFactory => false;

  @override
  bool get hasInternal => false;

  @override
  bool get hasIsTest => false;

  @override
  bool get hasIsTestGroup => false;

  @override
  bool get hasJS => false;

  @override
  bool get hasLiteral => false;

  @override
  bool get hasMustBeOverridden => false;

  @override
  bool get hasMustCallSuper => false;

  @override
  bool get hasNonVirtual => false;

  @override
  bool get hasOptionalTypeArgs => false;

  @override
  bool get hasOverride => false;

  @override
  bool get hasProtected => false;

  @override
  bool get hasReopen => false;

  @override
  bool get hasRequired => false;

  @override
  bool get hasSealed => false;

  @override
  bool get hasUseResult => false;

  @override
  bool get hasVisibleForOverriding => false;

  @override
  bool get hasVisibleForTemplate => false;

  @override
  bool get hasVisibleForTesting => false;

  @override
  bool get hasVisibleOutsideTemplate => false;

  @override
  bool get isPrivate {
    throw UnimplementedError();
  }

  @override
  bool get isPublic => !isPrivate;

  @override
  bool get isSynthetic => true;

  bool get isVisibleForTemplate => false;

  bool get isVisibleOutsideTemplate => false;

  @override
  ElementKind get kind => ElementKind.ERROR;

  @override
  LibraryElement? get library => null;

  @override
  Source? get librarySource => null;

  @override
  ElementLocation? get location => null;

  @override
  List<ElementAnnotation> get metadata => const <ElementAnnotation>[];

  @override
  int get nameLength => 0;

  @override
  int get nameOffset => -1;

  @override
  Element get nonSynthetic => this;

  @override
  Version? get sinceSdkVersion => null;

  @override
  Source? get source => null;

  @override
  T? accept<T>(ElementVisitor<T> visitor) =>
      visitor.visitMultiplyDefinedElement(this);

  @override
  String getDisplayString({
    required bool withNullability,
    bool multiline = false,
  }) {
    var elementsStr = conflictingElements.map((e) {
      return e.getDisplayString(
        withNullability: withNullability,
      );
    }).join(', ');
    return '[$elementsStr]';
  }

  @override
  String getExtendedDisplayName(String? shortName) {
    if (shortName != null) {
      return shortName;
    }
    return displayName;
  }

  @override
  bool isAccessibleIn(LibraryElement library) {
    for (Element element in conflictingElements) {
      if (element.isAccessibleIn(library)) {
        return true;
      }
    }
    return false;
  }

  @override
  E? thisOrAncestorMatching<E extends Element>(
    bool Function(Element) predicate,
  ) {
    return null;
  }

  @override
  E? thisOrAncestorOfType<E extends Element>() => null;

  @override
  String toString() {
    StringBuffer buffer = StringBuffer();
    bool needsSeparator = false;
    void writeList(List<Element> elements) {
      for (Element element in elements) {
        if (needsSeparator) {
          buffer.write(", ");
        } else {
          needsSeparator = true;
        }
        buffer.write(
          element.getDisplayString(withNullability: true),
        );
      }
    }

    buffer.write("[");
    writeList(conflictingElements);
    buffer.write("]");
    return buffer.toString();
  }

  /// Use the given [visitor] to visit all of the children of this element.
  /// There is no guarantee of the order in which the children will be visited.
  @override
  void visitChildren(ElementVisitor visitor) {
    for (Element child in children) {
      child.accept(visitor);
    }
  }
}

/// An [ExecutableElement], with the additional information of a list of
/// [ExecutableElement]s from which this element was composed.
///
/// Clients may not extend, implement or mix-in this class.
abstract class MultiplyInheritedExecutableElement implements ExecutableElement {
  /// The executable elements defined within this executable element.
  List<ExecutableElement> get inheritedElements;
}

/// An element that represents a named [InstanceElement].
///
/// Clients may not extend, implement or mix-in this class.
@experimental
abstract class NamedInstanceElement implements InstanceElement {
  @override
  NamedInstanceElement? get augmentationTarget;

  @experimental
  @override
  AugmentedNamedInstanceElement? get augmented;

  /// The declared constructors.
  ///
  /// The list is empty for [MixinElement].
  List<ConstructorElement> get constructors;

  @override
  String get name;

  /// The unnamed constructor declared directly in this class.
  ///
  /// If the class does not declare any constructors, a synthetic default
  /// constructor will be returned.
  /// TODO(scheglov) Deprecate and remove it.
  ConstructorElement? get unnamedConstructor;

  /// The constructor defined directly in this class or augmentation
  /// that has the given [name].
  /// TODO(scheglov) Deprecate and remove it.
  ConstructorElement? getNamedConstructor(String name);

  /// Create the [DartType] for this element with the given [typeArguments]
  /// and [nullabilitySuffix].
  DartType instantiate({
    required List<DartType> typeArguments,
    required NullabilitySuffix nullabilitySuffix,
  });
}

abstract class NamedInstanceElementImpl extends InstanceElementImpl
    implements NamedInstanceElement {
  List<ConstructorElementImpl> _constructors = _Sentinel.constructorElement;

  NamedInstanceElementImpl(super.name, super.nameOffset);

  @override
  NamedInstanceElementImpl? get augmentationTarget;

  @override
  List<ConstructorElementImpl> get constructors {
    if (!identical(_constructors, _Sentinel.constructorElement)) {
      return _constructors;
    }

    _buildMixinAppConstructors();
    linkedData?.readMembers(this);
    return _constructors;
  }

  set constructors(List<ConstructorElementImpl> constructors) {
    for (var constructor in constructors) {
      constructor.enclosingElement = this;
    }
    _constructors = constructors;
  }

  @override
  String get displayName => name;

  @override
  String get name {
    return super.name!;
  }

  @override
  ConstructorElement? get unnamedConstructor {
    return constructors.firstWhereOrNull((element) => element.name.isEmpty);
  }

  @override
  ConstructorElement? getNamedConstructor(String name) {
    if (name == 'new') {
      // A constructor declared as `C.new` is unnamed, and is modeled as such.
      name = '';
    }
    return constructors.firstWhereOrNull((element) => element.name == name);
  }

  /// Builds constructors for this mixin application.
  void _buildMixinAppConstructors() {}
}

/// An object that controls how namespaces are combined.
///
/// Clients may not extend, implement or mix-in this class.
abstract class NamespaceCombinator {}

/// The synthetic element representing the declaration of the type `Never`.
class NeverElementImpl extends ElementImpl implements TypeDefiningElement {
  /// The unique instance of this class.
  static final instance = NeverElementImpl._();

  /// Initialize a newly created instance of this class. Instances of this class
  /// should <b>not</b> be created except as part of creating the type
  /// associated with this element. The single instance of this class should be
  /// accessed through the method [instance].
  NeverElementImpl._() : super('Never', -1) {
    setModifier(Modifier.SYNTHETIC, true);
  }

  @override
  ElementKind get kind => ElementKind.NEVER;

  @override
  T? accept<T>(ElementVisitor<T> visitor) => null;

  DartType instantiate({
    required NullabilitySuffix nullabilitySuffix,
  }) {
    switch (nullabilitySuffix) {
      case NullabilitySuffix.question:
        return NeverTypeImpl.instanceNullable;
      case NullabilitySuffix.star:
        return NeverTypeImpl.instanceLegacy;
      case NullabilitySuffix.none:
        return NeverTypeImpl.instance;
    }
  }
}

/// A [VariableElementImpl], which is not a parameter.
abstract class NonParameterVariableElementImpl extends VariableElementImpl
    with _HasLibraryMixin {
  /// Initialize a newly created variable element to have the given [name] and
  /// [offset].
  NonParameterVariableElementImpl(String super.name, super.offset);

  @Deprecated('Use enclosingElement2 instead')
  @override
  Element get enclosingElement => super.enclosingElement!;

  @override
  Element get enclosingElement2 => super.enclosingElement2!;

  bool get hasInitializer {
    return hasModifier(Modifier.HAS_INITIALIZER);
  }

  /// Set whether this variable has an initializer.
  set hasInitializer(bool hasInitializer) {
    setModifier(Modifier.HAS_INITIALIZER, hasInitializer);
  }
}

class NotAugmentedClassElementImpl extends NotAugmentedInterfaceElementImpl
    implements AugmentedClassElement {
  @override
  final ClassElementImpl element;

  NotAugmentedClassElementImpl(this.element);

  @override
  ClassElementImpl get declaration => element;
}

class NotAugmentedEnumElementImpl extends NotAugmentedInterfaceElementImpl
    implements AugmentedEnumElement {
  @override
  final EnumElementImpl element;

  NotAugmentedEnumElementImpl(this.element);

  @override
  EnumElementImpl get declaration => element;
}

class NotAugmentedExtensionElementImpl extends AugmentedInstanceElementImpl
    implements AugmentedExtensionElement {
  final ExtensionElementImpl element;

  NotAugmentedExtensionElementImpl(this.element);
}

class NotAugmentedInlineClassElementImpl
    extends NotAugmentedNamedInstanceElementImpl
    implements AugmentedInlineClassElement {
  @override
  final InlineClassElementImpl element;

  NotAugmentedInlineClassElementImpl(this.element);

  @override
  InlineClassElementImpl get declaration => element;
}

abstract class NotAugmentedInstanceElementImpl
    implements AugmentedInstanceElement {
  @override
  List<PropertyAccessorElement> get accessors {
    return element.accessors;
  }

  InstanceElementImpl get element;

  @override
  List<FieldElement> get fields {
    return element.fields;
  }

  @override
  List<ElementAnnotation> get metadata {
    return element.metadata;
  }

  @override
  List<MethodElement> get methods {
    return element.methods;
  }

  @override
  FieldElement? getField(String name) {
    final length = fields.length;
    for (var i = 0; i < length; i++) {
      final field = fields[i];
      if (field.name == name) {
        return field;
      }
    }
    return null;
  }

  @override
  PropertyAccessorElement? getGetter(String name) {
    final length = accessors.length;
    for (var i = 0; i < length; i++) {
      final accessor = accessors[i];
      if (accessor.isGetter && accessor.name == name) {
        return accessor;
      }
    }
    return null;
  }

  @override
  MethodElement? getMethod(String name) {
    final length = methods.length;
    for (var i = 0; i < length; i++) {
      final method = methods[i];
      if (method.name == name) {
        return method;
      }
    }
    return null;
  }

  @override
  PropertyAccessorElement? getSetter(String name) {
    final nameLength = name.length;
    final length = accessors.length;
    for (var i = 0; i < length; i++) {
      final accessor = accessors[i];
      if (accessor.isSetter) {
        final accessorName = accessor.name;
        if (accessorName.length == nameLength + 1) {
          if (accessorName.startsWith(name)) {
            return accessor;
          }
        }
      }
    }
    return null;
  }
}

abstract class NotAugmentedInterfaceElementImpl
    extends NotAugmentedNamedInstanceElementImpl
    implements AugmentedInterfaceElement {
  @override
  InterfaceElementImpl get element;

  @override
  List<InterfaceType> get interfaces {
    return element.interfaces;
  }

  @override
  List<InterfaceType> get mixins {
    return element.mixins;
  }
}

class NotAugmentedMixinElementImpl extends NotAugmentedInterfaceElementImpl
    implements AugmentedMixinElement {
  @override
  final MixinElementImpl element;

  NotAugmentedMixinElementImpl(this.element);

  @override
  MixinElementImpl get declaration => element;

  @override
  List<InterfaceType> get superclassConstraints {
    return element.superclassConstraints;
  }
}

abstract class NotAugmentedNamedInstanceElementImpl
    extends NotAugmentedInstanceElementImpl
    implements AugmentedNamedInstanceElement {
  @override
  List<ConstructorElement> get constructors {
    return element.constructors;
  }

  @override
  NamedInstanceElementImpl get element;

  @override
  ConstructorElement? get unnamedConstructor {
    return element.unnamedConstructor;
  }

  @override
  ConstructorElement? getNamedConstructor(String name) {
    return element.getNamedConstructor(name);
  }
}

/// A parameter defined within an executable element.
///
/// Clients may not extend, implement or mix-in this class.
abstract class ParameterElement
    implements PromotableElement, ConstantEvaluationTarget {
  @override
  ParameterElement get declaration;

  /// The code of the default value, or `null` if no default value.
  String? get defaultValueCode;

  /// Whether the parameter has a default value.
  bool get hasDefaultValue;

  /// Whether the parameter is covariant, meaning it is allowed to have a
  /// narrower type in an override.
  bool get isCovariant;

  /// Whether the parameter is an initializing formal parameter.
  bool get isInitializingFormal;

  /// Whether the parameter is a named parameter.
  ///
  /// Named parameters that are annotated with the `@required` annotation are
  /// considered optional. Named parameters that are annotated with the
  /// `required` syntax are considered required.
  bool get isNamed;

  /// Whether the parameter is an optional parameter.
  ///
  /// Optional parameters can either be positional or named. Named parameters
  /// that are annotated with the `@required` annotation are considered
  /// optional. Named parameters that are annotated with the `required` syntax
  /// are considered required.
  bool get isOptional;

  /// Whether the parameter is both an optional and named parameter.
  ///
  /// Named parameters that are annotated with the `@required` annotation are
  /// considered optional. Named parameters that are annotated with the
  /// `required` syntax are considered required.
  bool get isOptionalNamed;

  /// Whether the parameter is both an optional and positional parameter.
  bool get isOptionalPositional;

  /// Whether the parameter is a positional parameter.
  ///
  /// Positional parameters can either be required or optional.
  bool get isPositional;

  /// Whether the parameter is either a required positional parameter, or a
  /// named parameter with the `required` keyword.
  ///
  /// Note: the presence or absence of the `@required` annotation does not
  /// change the meaning of this getter. The parameter `{@required int x}`
  /// will return `false` and the parameter `{@required required int x}`
  /// will return `true`.
  bool get isRequired;

  /// Whether the parameter is both a required and named parameter.
  ///
  /// Named parameters that are annotated with the `@required` annotation are
  /// considered optional. Named parameters that are annotated with the
  /// `required` syntax are considered required.
  bool get isRequiredNamed;

  /// Whether the parameter is both a required and positional parameter.
  bool get isRequiredPositional;

  /// Whether the parameter is a super formal parameter.
  bool get isSuperFormal;

  @override
  String get name;

  /// The kind of this parameter.
  @Deprecated('Use the getters isOptionalNamed, isOptionalPositional, '
      'isRequiredNamed, and isRequiredPositional')
  ParameterKind get parameterKind;

  /// The parameters defined by this parameter.
  ///
  /// A parameter will only define other parameters if it is a function typed
  /// parameter.
  List<ParameterElement> get parameters;

  /// The type parameters defined by this parameter.
  ///
  /// A parameter will only define type parameters if it is a function typed
  /// parameter.
  List<TypeParameterElement> get typeParameters;

  /// Appends the type, name and possibly the default value of this parameter
  /// to the given [buffer].
  void appendToWithoutDelimiters(
    StringBuffer buffer, {
    bool withNullability = false,
  });
}

/// A concrete implementation of a [ParameterElement].
class ParameterElementImpl extends VariableElementImpl
    with ParameterElementMixin
    implements ParameterElement {
  /// A list containing all of the parameters defined by this parameter element.
  /// There will only be parameters if this parameter is a function typed
  /// parameter.
  List<ParameterElement> _parameters = const [];

  /// A list containing all of the type parameters defined for this parameter
  /// element. There will only be parameters if this parameter is a function
  /// typed parameter.
  List<TypeParameterElement> _typeParameters = const [];

  @override
  final ParameterKind parameterKind;

  @override
  String? defaultValueCode;

  /// True if this parameter inherits from a covariant parameter. This happens
  /// when it overrides a method in a supertype that has a corresponding
  /// covariant parameter.
  bool inheritsCovariant = false;

  /// Initialize a newly created parameter element to have the given [name] and
  /// [nameOffset].
  ParameterElementImpl({
    required String? name,
    required int nameOffset,
    required this.parameterKind,
  }) : super(name, nameOffset);

  /// Creates a synthetic parameter with [name], [type] and [parameterKind].
  factory ParameterElementImpl.synthetic(
      String? name, DartType type, ParameterKind parameterKind) {
    var element = ParameterElementImpl(
      name: name,
      nameOffset: -1,
      parameterKind: parameterKind,
    );
    element.type = type;
    element.isSynthetic = true;
    return element;
  }

  @override
  List<Element> get children => parameters;

  @override
  ParameterElement get declaration => this;

  @override
  bool get hasDefaultValue {
    return defaultValueCode != null;
  }

  @override
  bool get isCovariant {
    if (isExplicitlyCovariant || inheritsCovariant) {
      return true;
    }
    return false;
  }

  /// Return true if this parameter is explicitly marked as being covariant.
  bool get isExplicitlyCovariant {
    return hasModifier(Modifier.COVARIANT);
  }

  /// Set whether this variable parameter is explicitly marked as being
  /// covariant.
  set isExplicitlyCovariant(bool isCovariant) {
    setModifier(Modifier.COVARIANT, isCovariant);
  }

  @override
  bool get isInitializingFormal => false;

  @override
  bool get isLate => false;

  @override
  bool get isSuperFormal => false;

  @override
  ElementKind get kind => ElementKind.PARAMETER;

  @override
  List<ParameterElement> get parameters {
    return _parameters;
  }

  /// Set the parameters defined by this executable element to the given
  /// [parameters].
  set parameters(List<ParameterElement> parameters) {
    for (ParameterElement parameter in parameters) {
      (parameter as ParameterElementImpl).enclosingElement = this;
    }
    _parameters = parameters;
  }

  @override
  List<TypeParameterElement> get typeParameters {
    return _typeParameters;
  }

  /// Set the type parameters defined by this parameter element to the given
  /// [typeParameters].
  set typeParameters(List<TypeParameterElement> typeParameters) {
    for (TypeParameterElement parameter in typeParameters) {
      (parameter as TypeParameterElementImpl).enclosingElement = this;
    }
    _typeParameters = typeParameters;
  }

  @override
  T? accept<T>(ElementVisitor<T> visitor) =>
      visitor.visitParameterElement(this);

  @override
  void appendTo(ElementDisplayStringBuilder builder) {
    builder.writeFormalParameter(this);
  }
}

/// The parameter of an implicit setter.
class ParameterElementImpl_ofImplicitSetter extends ParameterElementImpl {
  final PropertyAccessorElementImpl_ImplicitSetter setter;

  ParameterElementImpl_ofImplicitSetter(this.setter)
      : super(
          name: considerCanonicalizeString('_${setter.variable.name}'),
          nameOffset: -1,
          parameterKind: ParameterKind.REQUIRED,
        ) {
    enclosingElement = setter;
    isSynthetic = true;
  }

  @override
  bool get inheritsCovariant {
    var variable = setter.variable;
    if (variable is FieldElementImpl) {
      return variable.inheritsCovariant;
    }
    return false;
  }

  @override
  set inheritsCovariant(bool value) {
    var variable = setter.variable;
    if (variable is FieldElementImpl) {
      variable.inheritsCovariant = value;
    }
  }

  @override
  bool get isCovariant {
    if (isExplicitlyCovariant || inheritsCovariant) {
      return true;
    }
    return false;
  }

  @override
  bool get isExplicitlyCovariant {
    var variable = setter.variable;
    if (variable is FieldElementImpl) {
      return variable.isCovariant;
    }
    return false;
  }

  @override
  Element get nonSynthetic {
    return setter.variable;
  }

  @override
  DartType get type => ElementTypeProvider.current.getVariableType(this);

  @override
  set type(DartType type) {
    assert(false); // Should never be called.
  }

  @override
  DartType get typeInternal => setter.variable.type;
}

/// A mixin that provides a common implementation for methods defined in
/// [ParameterElement].
mixin ParameterElementMixin implements ParameterElement {
  @override
  bool get isNamed => parameterKind.isNamed;

  @override
  bool get isOptional => parameterKind.isOptional;

  @override
  bool get isOptionalNamed => parameterKind.isOptionalNamed;

  @override
  bool get isOptionalPositional => parameterKind.isOptionalPositional;

  @override
  bool get isPositional => parameterKind.isPositional;

  @override
  bool get isRequired => parameterKind.isRequired;

  @override
  bool get isRequiredNamed => parameterKind.isRequiredNamed;

  @override
  bool get isRequiredPositional => parameterKind.isRequiredPositional;

  @override
  // Overridden to remove the 'deprecated' annotation.
  ParameterKind get parameterKind;

  @override
  void appendToWithoutDelimiters(
    StringBuffer buffer, {
    bool withNullability = false,
  }) {
    buffer.write(
      type.getDisplayString(
        withNullability: withNullability,
      ),
    );
    buffer.write(' ');
    buffer.write(displayName);
    if (defaultValueCode != null) {
      buffer.write(' = ');
      buffer.write(defaultValueCode);
    }
  }
}

/// A 'part' directive within a library.
///
/// Clients may not extend, implement or mix-in this class.
abstract class PartElement implements _ExistingElement {
  /// The interpretation of the URI specified in the directive.
  DirectiveUri get uri;
}

class PartElementImpl extends _ExistingElementImpl implements PartElement {
  @override
  final DirectiveUri uri;

  PartElementImpl({
    required this.uri,
  }) : super(null, -1);

  @override
  CompilationUnitElementImpl get enclosingUnit {
    var enclosingLibrary = enclosingElement2 as LibraryElementImpl;
    return enclosingLibrary._definingCompilationUnit;
  }

  @override
  String get identifier => 'part';

  @override
  ElementKind get kind => ElementKind.PART;

  @override
  T? accept<T>(ElementVisitor<T> visitor) => visitor.visitPartElement(this);

  @override
  void appendTo(ElementDisplayStringBuilder builder) {
    builder.writePartElement(this);
  }
}

/// A pattern variable.
///
/// Clients may not extend, implement or mix-in this class.
abstract class PatternVariableElement implements LocalVariableElement {
  /// The variable in which this variable joins with other pattern variables
  /// with the same name, in a logical-or pattern, or shared case scope.
  JoinPatternVariableElement? get join;
}

class PatternVariableElementImpl extends LocalVariableElementImpl
    implements PatternVariableElement {
  @override
  JoinPatternVariableElementImpl? join;

  /// This flag is set to `true` while we are visiting the [WhenClause] of
  /// the [GuardedPattern] that declares this variable.
  bool isVisitingWhenClause = false;

  PatternVariableElementImpl(super.name, super.offset);

  /// Return the root [join], or self.
  PatternVariableElementImpl get rootVariable {
    return join?.rootVariable ?? this;
  }
}

/// A prefix used to import one or more libraries into another library.
///
/// Clients may not extend, implement or mix-in this class.
abstract class PrefixElement implements _ExistingElement {
  /// The library, or library augmentation that encloses this element.
  @Deprecated('Use enclosingElement2 instead')
  @override
  LibraryOrAugmentationElement get enclosingElement;

  /// The library, or library augmentation that encloses this element.
  @override
  LibraryOrAugmentationElement get enclosingElement2;

  /// The imports that share this prefix.
  List<LibraryImportElement> get imports;

  @override
  String get name;

  /// The name lookup scope for this import prefix.
  ///
  /// It consists of elements imported into the enclosing library with this
  /// prefix. The namespace combinators of the import directives are taken
  /// into account.
  Scope get scope;
}

/// A concrete implementation of a [PrefixElement].
class PrefixElementImpl extends _ExistingElementImpl implements PrefixElement {
  /// The scope of this prefix, `null` if it has not been created yet.
  PrefixScope? _scope;

  /// Initialize a newly created method element to have the given [name] and
  /// [nameOffset].
  PrefixElementImpl(String super.name, super.nameOffset, {super.reference});

  @override
  String get displayName => name;

  @Deprecated('Use enclosingElement2 instead')
  @override
  LibraryOrAugmentationElementImpl get enclosingElement =>
      super.enclosingElement2 as LibraryOrAugmentationElementImpl;

  @override
  LibraryOrAugmentationElementImpl get enclosingElement2 =>
      super.enclosingElement2 as LibraryOrAugmentationElementImpl;

  @override
  List<LibraryImportElementImpl> get imports {
    return enclosingElement2.libraryImports
        .where((import) => import.prefix?.element == this)
        .toList();
  }

  @override
  ElementKind get kind => ElementKind.PREFIX;

  @override
  String get name {
    return super.name!;
  }

  @override
  Scope get scope => _scope ??= PrefixScope(enclosingElement2, this);

  @override
  T? accept<T>(ElementVisitor<T> visitor) => visitor.visitPrefixElement(this);

  @override
  void appendTo(ElementDisplayStringBuilder builder) {
    builder.writePrefixElement(this);
  }
}

/// A variable that might be subject to type promotion.  This might be a local
/// variable or a parameter.
///
/// Clients may not extend, implement or mix-in this class.
abstract class PromotableElement implements LocalElement, VariableElement {
  // Promotable elements are guaranteed to have a name.
  @override
  String get name;
}

/// A getter or a setter. Note that explicitly defined property accessors
/// implicitly define a synthetic field. Symmetrically, synthetic accessors are
/// implicitly created for explicitly defined fields. The following rules apply:
///
/// * Every explicit field is represented by a non-synthetic [FieldElement].
/// * Every explicit field induces a getter and possibly a setter, both of which
///   are represented by synthetic [PropertyAccessorElement]s.
/// * Every explicit getter or setter is represented by a non-synthetic
///   [PropertyAccessorElement].
/// * Every explicit getter or setter (or pair thereof if they have the same
///   name) induces a field that is represented by a synthetic [FieldElement].
///
/// Clients may not extend, implement or mix-in this class.
abstract class PropertyAccessorElement implements ExecutableElement {
  @experimental
  @override
  PropertyAccessorElement? get augmentation;

  @experimental
  @override
  PropertyAccessorElement? get augmentationTarget;

  /// The accessor representing the getter that corresponds to (has the same
  /// name as) this setter, or `null` if this accessor is not a setter or
  /// if there is no corresponding getter.
  PropertyAccessorElement? get correspondingGetter;

  /// The accessor representing the setter that corresponds to (has the same
  /// name as) this getter, or `null` if this accessor is not a getter or
  /// if there is no corresponding setter.
  PropertyAccessorElement? get correspondingSetter;

  @override
  PropertyAccessorElement get declaration;

  @Deprecated('Use enclosingElement2 instead')
  @override
  Element get enclosingElement;

  @override
  Element get enclosingElement2;

  /// Whether the accessor represents a getter.
  bool get isGetter;

  /// Whether the accessor represents a setter.
  bool get isSetter;

  /// The field or top-level variable associated with this accessor.
  ///
  /// If this accessor was explicitly defined (is not synthetic) then the
  /// variable associated with it will be synthetic.
  PropertyInducingElement get variable;
}

/// A concrete implementation of a [PropertyAccessorElement].
class PropertyAccessorElementImpl extends ExecutableElementImpl
    with _HasAugmentation<PropertyAccessorElementImpl>
    implements PropertyAccessorElement {
  late PropertyInducingElementImpl _variable;

  /// If this method is a synthetic element which is based on another method
  /// with some modifications (such as making some parameters covariant),
  /// this field contains the base method.
  PropertyAccessorElement? prototype;

  /// Initialize a newly created property accessor element to have the given
  /// [name] and [offset].
  PropertyAccessorElementImpl(super.name, super.offset);

  /// Initialize a newly created synthetic property accessor element to be
  /// associated with the given [variable].
  PropertyAccessorElementImpl.forVariable(this._variable,
      {Reference? reference})
      : super(_variable.name, -1, reference: reference) {
    isAbstract = variable is FieldElementImpl &&
        (variable as FieldElementImpl).isAbstract;
    isStatic = variable.isStatic;
    isSynthetic = true;
  }

  @override
  PropertyAccessorElement? get correspondingGetter {
    if (isGetter) {
      return null;
    }
    return variable.getter;
  }

  @override
  PropertyAccessorElement? get correspondingSetter {
    if (isSetter) {
      return null;
    }
    return variable.setter;
  }

  @override
  PropertyAccessorElement get declaration => prototype ?? this;

  @override
  String get identifier {
    String name = displayName;
    String suffix = isGetter ? "?" : "=";
    return considerCanonicalizeString("$name$suffix");
  }

  /// Set whether this class is abstract.
  set isAbstract(bool isAbstract) {
    setModifier(Modifier.ABSTRACT, isAbstract);
  }

  @override
  bool get isGetter {
    return hasModifier(Modifier.GETTER);
  }

  /// Set whether this accessor is a getter.
  set isGetter(bool isGetter) {
    setModifier(Modifier.GETTER, isGetter);
  }

  @override
  bool get isSetter {
    return hasModifier(Modifier.SETTER);
  }

  /// Set whether this accessor is a setter.
  set isSetter(bool isSetter) {
    setModifier(Modifier.SETTER, isSetter);
  }

  @override
  ElementKind get kind {
    if (isGetter) {
      return ElementKind.GETTER;
    }
    return ElementKind.SETTER;
  }

  @override
  List<ElementAnnotation> get metadata {
    linkedData?.read(this);
    return super.metadata;
  }

  @override
  String get name {
    if (isSetter) {
      return considerCanonicalizeString("${super.name}=");
    }
    return super.name;
  }

  @override
  PropertyInducingElementImpl get variable {
    linkedData?.read(this);
    return _variable;
  }

  set variable(PropertyInducingElementImpl value) {
    _variable = value;
  }

  @override
  T? accept<T>(ElementVisitor<T> visitor) =>
      visitor.visitPropertyAccessorElement(this);

  @override
  void appendTo(ElementDisplayStringBuilder builder) {
    builder.writeExecutableElement(
      this,
      (isGetter ? 'get ' : 'set ') + variable.displayName,
    );
  }
}

/// Implicit getter for a [PropertyInducingElementImpl].
class PropertyAccessorElementImpl_ImplicitGetter
    extends PropertyAccessorElementImpl {
  /// Create the implicit getter and bind it to the [property].
  PropertyAccessorElementImpl_ImplicitGetter(
      PropertyInducingElementImpl property,
      {Reference? reference})
      : super.forVariable(property, reference: reference) {
    property.getter = this;
    reference?.element = this;
  }

  @Deprecated('Use enclosingElement2 instead')
  @override
  Element get enclosingElement => variable.enclosingElement2;

  @override
  Element get enclosingElement2 => variable.enclosingElement2;

  @override
  bool get hasImplicitReturnType => variable.hasImplicitType;

  @override
  bool get isGetter => true;

  @override
  Element get nonSynthetic {
    final variable = this.variable;
    if (!variable.isSynthetic) {
      return variable;
    }
    assert(enclosingElement2 is EnumElementImpl);
    return enclosingElement2;
  }

  @Deprecated('Use returnType2 instead')
  @override
  DartType get returnType =>
      ElementTypeProvider.current.getExecutableReturnType(this);

  @override
  set returnType(DartType returnType) {
    assert(false); // Should never be called.
  }

  @override
  DartType get returnType2 =>
      ElementTypeProvider.current.getExecutableReturnType(this);

  @override
  DartType get returnTypeInternal => variable.type;

  @override
  Version? get sinceSdkVersion => variable.sinceSdkVersion;

  @override
  FunctionType get type => ElementTypeProvider.current.getExecutableType(this);

  @override
  set type(FunctionType type) {
    assert(false); // Should never be called.
  }

  @override
  FunctionType get typeInternal {
    return _type ??= FunctionTypeImpl(
      typeFormals: const <TypeParameterElement>[],
      parameters: const <ParameterElement>[],
      returnType: returnType2,
      nullabilitySuffix: _noneOrStarSuffix,
    );
  }
}

/// Implicit setter for a [PropertyInducingElementImpl].
class PropertyAccessorElementImpl_ImplicitSetter
    extends PropertyAccessorElementImpl {
  /// Create the implicit setter and bind it to the [property].
  PropertyAccessorElementImpl_ImplicitSetter(
      PropertyInducingElementImpl property,
      {Reference? reference})
      : super.forVariable(property, reference: reference) {
    property.setter = this;
  }

  @Deprecated('Use enclosingElement2 instead')
  @override
  Element get enclosingElement => variable.enclosingElement2;

  @override
  Element get enclosingElement2 => variable.enclosingElement2;

  @override
  bool get isSetter => true;

  @override
  Element get nonSynthetic => variable;

  @override
  List<ParameterElement> get parameters =>
      ElementTypeProvider.current.getExecutableParameters(this);

  @override
  List<ParameterElement> get parametersInternal {
    if (_parameters.isNotEmpty) {
      return _parameters;
    }

    return _parameters = List.generate(
        1, (_) => ParameterElementImpl_ofImplicitSetter(this),
        growable: false);
  }

  @Deprecated('Use returnType2 instead')
  @override
  DartType get returnType =>
      ElementTypeProvider.current.getExecutableReturnType(this);

  @override
  set returnType(DartType returnType) {
    assert(false); // Should never be called.
  }

  @override
  DartType get returnType2 =>
      ElementTypeProvider.current.getExecutableReturnType(this);

  @override
  DartType get returnTypeInternal => VoidTypeImpl.instance;

  @override
  Version? get sinceSdkVersion => variable.sinceSdkVersion;

  @override
  FunctionType get type => ElementTypeProvider.current.getExecutableType(this);

  @override
  set type(FunctionType type) {
    assert(false); // Should never be called.
  }

  @override
  FunctionType get typeInternal {
    return _type ??= FunctionTypeImpl(
      typeFormals: const <TypeParameterElement>[],
      parameters: parameters,
      returnType: returnType2,
      nullabilitySuffix: _noneOrStarSuffix,
    );
  }
}

/// A variable that has an associated getter and possibly a setter. Note that
/// explicitly defined variables implicitly define a synthetic getter and that
/// non-`final` explicitly defined variables implicitly define a synthetic
/// setter. Symmetrically, synthetic fields are implicitly created for
/// explicitly defined getters and setters. The following rules apply:
///
/// * Every explicit variable is represented by a non-synthetic
///   [PropertyInducingElement].
/// * Every explicit variable induces a getter and possibly a setter, both of
///   which are represented by synthetic [PropertyAccessorElement]s.
/// * Every explicit getter or setter is represented by a non-synthetic
///   [PropertyAccessorElement].
/// * Every explicit getter or setter (or pair thereof if they have the same
///   name) induces a variable that is represented by a synthetic
///   [PropertyInducingElement].
///
/// Clients may not extend, implement or mix-in this class.
abstract class PropertyInducingElement implements VariableElement {
  @override
  String get displayName;

  /// The getter associated with this variable.
  ///
  /// If this variable was explicitly defined (is not synthetic) then the
  /// getter associated with it will be synthetic.
  PropertyAccessorElement? get getter;

  /// Whether the variable has an initializer at declaration.
  bool get hasInitializer;

  @override
  LibraryElement get library;

  @override
  String get name;

  /// The setter associated with this variable, or `null` if the variable
  /// is effectively `final` and therefore does not have a setter associated
  /// with it.
  ///
  /// This can happen either because the variable is explicitly defined as
  /// being `final` or because the variable is induced by an explicit getter
  /// that does not have a corresponding setter. If this variable was
  /// explicitly defined (is not synthetic) then the setter associated with
  /// it will be synthetic.
  PropertyAccessorElement? get setter;
}

/// A concrete implementation of a [PropertyInducingElement].
abstract class PropertyInducingElementImpl
    extends NonParameterVariableElementImpl implements PropertyInducingElement {
  /// The getter associated with this element.
  @override
  PropertyAccessorElementImpl? getter;

  /// The setter associated with this element, or `null` if the element is
  /// effectively `final` and therefore does not have a setter associated with
  /// it.
  @override
  PropertyAccessorElementImpl? setter;

  /// This field is set during linking, and performs type inference for
  /// this property. After linking this field is always `null`.
  PropertyInducingElementTypeInference? typeInference;

  /// The error reported during type inference for this variable, or `null` if
  /// this variable is not a subject of type inference, or there was no error.
  TopLevelInferenceError? typeInferenceError;

  ElementLinkedData? linkedData;

  /// Initialize a newly created synthetic element to have the given [name] and
  /// [offset].
  PropertyInducingElementImpl(super.name, super.offset) {
    setModifier(Modifier.SHOULD_USE_TYPE_FOR_INITIALIZER_INFERENCE, true);
  }

  @override
  bool get isConstantEvaluated => true;

  @override
  bool get isLate {
    return hasModifier(Modifier.LATE);
  }

  @override
  Element get nonSynthetic {
    if (isSynthetic) {
      if (enclosingElement2 is EnumElementImpl) {
        // TODO(scheglov) remove 'index'?
        if (name == 'index' || name == 'values') {
          return enclosingElement2;
        }
      }
      return (getter ?? setter)!;
    } else {
      return this;
    }
  }

  bool get shouldUseTypeForInitializerInference {
    return hasModifier(Modifier.SHOULD_USE_TYPE_FOR_INITIALIZER_INFERENCE);
  }

  set shouldUseTypeForInitializerInference(bool value) {
    setModifier(Modifier.SHOULD_USE_TYPE_FOR_INITIALIZER_INFERENCE, value);
  }

  @override
  DartType get type => ElementTypeProvider.current.getFieldType(this);

  @override
  set type(DartType type) {
    super.type = type;
    // Reset cached types of synthetic getters and setters.
    // TODO(scheglov) Consider not caching these types.
    if (!isSynthetic) {
      var getter = this.getter;
      if (getter is PropertyAccessorElementImpl_ImplicitGetter) {
        getter._type = null;
      }
      var setter = this.setter;
      if (setter is PropertyAccessorElementImpl_ImplicitSetter) {
        setter._type = null;
      }
    }
  }

  @override
  DartType get typeInternal {
    linkedData?.read(this);
    if (_type != null) return _type!;

    if (isSynthetic) {
      if (getter != null) {
        return _type = getter!.returnType2;
      } else if (setter != null) {
        List<ParameterElement> parameters = setter!.parameters;
        return _type = parameters.isNotEmpty
            ? parameters[0].type
            : DynamicTypeImpl.instance;
      } else {
        return _type = DynamicTypeImpl.instance;
      }
    }

    // We must be linking, and the type has not been set yet.
    _type = typeInference!.perform();
    shouldUseTypeForInitializerInference = false;
    return _type!;
  }

  /// Return `true` if this variable needs the setter.
  bool get _hasSetter {
    if (isConst) {
      return false;
    }

    if (isLate) {
      return !isFinal || !hasInitializer;
    }

    return !isFinal;
  }

  void bindReference(Reference reference) {
    this.reference = reference;
    reference.element = this;
  }

  void createImplicitAccessors(Reference enclosingRef, String name) {
    getter = PropertyAccessorElementImpl_ImplicitGetter(
      this,
      reference: enclosingRef.getChild('@getter').getChild(name),
    );

    if (_hasSetter) {
      setter = PropertyAccessorElementImpl_ImplicitSetter(
        this,
        reference: enclosingRef.getChild('@setter').getChild(name),
      );
    }
  }

  void setLinkedData(Reference reference, ElementLinkedData linkedData) {
    this.reference = reference;
    reference.element = this;

    this.linkedData = linkedData;
  }
}

/// Instances of this class are set for fields and top-level variables
/// to perform top-level type inference during linking.
abstract class PropertyInducingElementTypeInference {
  DartType perform();
}

/// A combinator that cause some of the names in a namespace to be visible (and
/// the rest hidden) when being imported.
///
/// Clients may not extend, implement or mix-in this class.
abstract class ShowElementCombinator implements NamespaceCombinator {
  /// The offset of the character immediately following the last character of
  /// this node.
  int get end;

  /// The offset of the 'show' keyword of this element.
  int get offset;

  /// The names that are to be made visible in the importing library if they
  /// are defined in the imported library.
  List<String> get shownNames;
}

/// A concrete implementation of a [ShowElementCombinator].
class ShowElementCombinatorImpl implements ShowElementCombinator {
  @override
  List<String> shownNames = const [];

  @override
  int offset = 0;

  @override
  int end = -1;

  @override
  String toString() {
    StringBuffer buffer = StringBuffer();
    buffer.write("show ");
    int count = shownNames.length;
    for (int i = 0; i < count; i++) {
      if (i > 0) {
        buffer.write(", ");
      }
      buffer.write(shownNames[i]);
    }
    return buffer.toString();
  }
}

/// A super formal parameter defined within a constructor element.
///
/// Clients may not extend, implement or mix-in this class.
abstract class SuperFormalParameterElement implements ParameterElement {
  /// The associated super-constructor parameter, from the super-constructor
  /// that is referenced by the implicit or explicit super-constructor
  /// invocation.
  ///
  /// Can be `null` for erroneous code - not existing super-constructor,
  /// no corresponding parameter in the super-constructor.
  ParameterElement? get superConstructorParameter;
}

class SuperFormalParameterElementImpl extends ParameterElementImpl
    implements SuperFormalParameterElement {
  /// Initialize a newly created parameter element to have the given [name] and
  /// [nameOffset].
  SuperFormalParameterElementImpl({
    required String super.name,
    required super.nameOffset,
    required super.parameterKind,
  });

  /// Super parameters are visible only in the initializer list scope,
  /// and introduce final variables.
  @override
  bool get isFinal => true;

  @override
  bool get isSuperFormal => true;

  @override
  ParameterElement? get superConstructorParameter {
    final enclosingElement2 = this.enclosingElement2;
    if (enclosingElement2 is ConstructorElementImpl) {
      var superConstructor = enclosingElement2.superConstructor;
      if (superConstructor != null) {
        var superParameters = superConstructor.parameters;
        if (isNamed) {
          return superParameters
              .firstWhereOrNull((e) => e.isNamed && e.name == name);
        } else {
          var index = indexIn(enclosingElement2);
          var positionalSuperParameters =
              superParameters.where((e) => e.isPositional).toList();
          if (index >= 0 && index < positionalSuperParameters.length) {
            return positionalSuperParameters[index];
          }
        }
      }
    }
    return null;
  }

  @override
  T? accept<T>(ElementVisitor<T> visitor) =>
      visitor.visitSuperFormalParameterElement(this);

  /// Return the index of this super-formal parameter among other super-formals.
  int indexIn(ConstructorElementImpl enclosingElement) {
    return enclosingElement.parameters
        .whereType<SuperFormalParameterElementImpl>()
        .toList()
        .indexOf(this);
  }
}

/// A top-level variable.
///
/// Clients may not extend, implement or mix-in this class.
abstract class TopLevelVariableElement implements PropertyInducingElement {
  @override
  TopLevelVariableElement get declaration;

  /// Whether the field was explicitly marked as being external.
  bool get isExternal;
}

/// A concrete implementation of a [TopLevelVariableElement].
class TopLevelVariableElementImpl extends PropertyInducingElementImpl
    with HasCompletionData
    implements TopLevelVariableElement {
  /// Initialize a newly created synthetic top-level variable element to have
  /// the given [name] and [offset].
  TopLevelVariableElementImpl(super.name, super.offset);

  @override
  TopLevelVariableElement get declaration => this;

  @override
  bool get isExternal {
    return hasModifier(Modifier.EXTERNAL);
  }

  @override
  bool get isStatic => true;

  @override
  ElementKind get kind => ElementKind.TOP_LEVEL_VARIABLE;

  @override
  List<ElementAnnotation> get metadata {
    linkedData?.read(this);
    return super.metadata;
  }

  @override
  T? accept<T>(ElementVisitor<T> visitor) =>
      visitor.visitTopLevelVariableElement(this);
}

/// A type alias (`typedef`).
///
/// Clients may not extend, implement or mix-in this class.
abstract class TypeAliasElement
    implements TypeParameterizedElement, TypeDefiningElement {
  /// If the aliased type has structure, return the corresponding element.
  /// For example it could be [GenericFunctionTypeElement].
  ///
  /// If there is no structure, return `null`.
  Element? get aliasedElement;

  /// The aliased type.
  ///
  /// If non-function type aliases feature is enabled for the enclosing library,
  /// this type might be just anything. If the feature is disabled, return
  /// a [FunctionType].
  DartType get aliasedType;

  @Deprecated('Use enclosingElement2 instead')
  @override
  CompilationUnitElement get enclosingElement;

  @override
  CompilationUnitElement get enclosingElement2;

  @override
  String get name;

  /// Produces the type resulting from instantiating this typedef with the given
  /// [typeArguments] and [nullabilitySuffix].
  ///
  /// Note that this always instantiates the typedef itself, so for a
  /// [TypeAliasElement] the returned [DartType] might still be a generic
  /// type, with type formals. For example, if the typedef is:
  ///     typedef F<T> = void Function<U>(T, U);
  /// then `F<int>` will produce `void Function<U>(int, U)`.
  DartType instantiate({
    required List<DartType> typeArguments,
    required NullabilitySuffix nullabilitySuffix,
  });
}

/// An element that represents [GenericTypeAlias].
///
/// Clients may not extend, implement or mix-in this class.
class TypeAliasElementImpl extends _ExistingElementImpl
    with TypeParameterizedElementMixin, HasCompletionData
    implements TypeAliasElement {
  /// Is `true` if the element has direct or indirect reference to itself
  /// from anywhere except a class element or type parameter bounds.
  bool hasSelfReference = false;

  bool isFunctionTypeAliasBased = false;

  ElementLinkedData? linkedData;

  ElementImpl? _aliasedElement;
  DartType? _aliasedType;

  TypeAliasElementImpl(String super.name, super.nameOffset);

  @override
  ElementImpl? get aliasedElement {
    linkedData?.read(this);
    return _aliasedElement;
  }

  set aliasedElement(ElementImpl? aliasedElement) {
    _aliasedElement = aliasedElement;
    aliasedElement?.enclosingElement = this;
  }

  @override
  DartType get aliasedType {
    linkedData?.read(this);
    return _aliasedType!;
  }

  set aliasedType(DartType rawType) {
    _aliasedType = rawType;
  }

  @override
  String get displayName => name;

  @Deprecated('Use enclosingElement2 instead')
  @override
  CompilationUnitElement get enclosingElement =>
      super.enclosingElement2 as CompilationUnitElement;

  @override
  CompilationUnitElement get enclosingElement2 =>
      super.enclosingElement2 as CompilationUnitElement;

  /// Returns whether this alias is a "proper rename" of [aliasedClass], as
  /// defined in the constructor-tearoffs specification.
  bool get isProperRename {
    var aliasedType_ = aliasedType;
    if (aliasedType_ is! InterfaceType) {
      return false;
    }
    var aliasedClass = aliasedType_.element;
    var typeArguments = aliasedType_.typeArguments;
    var typeParameterCount = typeParameters.length;
    if (typeParameterCount != aliasedClass.typeParameters.length) {
      return false;
    }
    for (var i = 0; i < typeParameterCount; i++) {
      var bound = typeParameters[i].bound ?? library.typeProvider.dynamicType;
      var aliasedBound = aliasedClass.typeParameters[i].bound ??
          library.typeProvider.dynamicType;
      if (!library.typeSystem.isSubtypeOf(bound, aliasedBound) ||
          !library.typeSystem.isSubtypeOf(aliasedBound, bound)) {
        return false;
      }
      final typeArgument = typeArguments[i];
      if (typeArgument is TypeParameterType &&
          typeParameters[i] != typeArgument.element) {
        return false;
      }
    }
    return true;
  }

  @override
  bool get isSimplyBounded {
    return hasModifier(Modifier.SIMPLY_BOUNDED);
  }

  set isSimplyBounded(bool isSimplyBounded) {
    setModifier(Modifier.SIMPLY_BOUNDED, isSimplyBounded);
  }

  @override
  ElementKind get kind {
    if (isNonFunctionTypeAliasesEnabled) {
      return ElementKind.TYPE_ALIAS;
    } else {
      return ElementKind.FUNCTION_TYPE_ALIAS;
    }
  }

  @override
  List<ElementAnnotation> get metadata {
    linkedData?.read(this);
    return super.metadata;
  }

  @override
  String get name {
    return super.name!;
  }

  /// Instantiates this type alias with its type parameters as arguments.
  DartType get rawType {
    final List<DartType> typeArguments;
    if (typeParameters.isNotEmpty) {
      typeArguments = typeParameters.map<DartType>((t) {
        return t.instantiate(nullabilitySuffix: _noneOrStarSuffix);
      }).toList();
    } else {
      typeArguments = const <DartType>[];
    }
    return instantiate(
      typeArguments: typeArguments,
      nullabilitySuffix: _noneOrStarSuffix,
    );
  }

  @override
  List<TypeParameterElement> get typeParameters {
    linkedData?.read(this);
    return super.typeParameters;
  }

  /// Set the type parameters defined for this type to the given
  /// [typeParameters].
  set typeParameters(List<TypeParameterElement> typeParameters) {
    for (TypeParameterElement typeParameter in typeParameters) {
      (typeParameter as TypeParameterElementImpl).enclosingElement = this;
    }
    _typeParameterElements = typeParameters;
  }

  @override
  T? accept<T>(ElementVisitor<T> visitor) {
    return visitor.visitTypeAliasElement(this);
  }

  @override
  void appendTo(ElementDisplayStringBuilder builder) {
    builder.writeTypeAliasElement(this);
  }

  @override
  DartType instantiate({
    required List<DartType> typeArguments,
    required NullabilitySuffix nullabilitySuffix,
  }) {
    if (hasSelfReference) {
      if (isNonFunctionTypeAliasesEnabled) {
        return DynamicTypeImpl.instance;
      } else {
        return _errorFunctionType(nullabilitySuffix);
      }
    }

    var substitution = Substitution.fromPairs(typeParameters, typeArguments);
    var type = substitution.substituteType(aliasedType);

    var resultNullability = type.nullabilitySuffix == NullabilitySuffix.question
        ? NullabilitySuffix.question
        : nullabilitySuffix;

    if (type is FunctionType) {
      return FunctionTypeImpl(
        typeFormals: type.typeFormals,
        parameters: type.parameters,
        returnType: type.returnType,
        nullabilitySuffix: resultNullability,
        alias: InstantiatedTypeAliasElementImpl(
          element: this,
          typeArguments: typeArguments,
        ),
      );
    } else if (type is InterfaceType) {
      return InterfaceTypeImpl(
        element: type.element,
        typeArguments: type.typeArguments,
        nullabilitySuffix: resultNullability,
        alias: InstantiatedTypeAliasElementImpl(
          element: this,
          typeArguments: typeArguments,
        ),
      );
    } else if (type is RecordTypeImpl) {
      return RecordTypeImpl(
        positionalFields: type.positionalFields,
        namedFields: type.namedFields,
        nullabilitySuffix: resultNullability,
        alias: InstantiatedTypeAliasElementImpl(
          element: this,
          typeArguments: typeArguments,
        ),
      );
    } else if (type is TypeParameterType) {
      return TypeParameterTypeImpl(
        element: type.element,
        nullabilitySuffix: resultNullability,
        alias: InstantiatedTypeAliasElementImpl(
          element: this,
          typeArguments: typeArguments,
        ),
      );
    } else {
      return (type as TypeImpl).withNullability(resultNullability);
    }
  }

  void setLinkedData(Reference reference, ElementLinkedData linkedData) {
    this.reference = reference;
    reference.element = this;

    this.linkedData = linkedData;
  }

  FunctionTypeImpl _errorFunctionType(NullabilitySuffix nullabilitySuffix) {
    return FunctionTypeImpl(
      typeFormals: const [],
      parameters: const [],
      returnType: DynamicTypeImpl.instance,
      nullabilitySuffix: nullabilitySuffix,
    );
  }
}

/// An element that defines a type.
///
/// Clients may not extend, implement or mix-in this class.
abstract class TypeDefiningElement implements Element {}

/// A type parameter.
///
/// Clients may not extend, implement or mix-in this class.
abstract class TypeParameterElement implements TypeDefiningElement {
  /// The type representing the bound associated with this parameter, or `null`
  /// if this parameter does not have an explicit bound. Being able to
  /// distinguish between an implicit and explicit bound is needed by the
  /// instantiate to bounds algorithm.
  DartType? get bound;

  @override
  TypeParameterElement get declaration;

  @override
  String get displayName;

  @override
  String get name;

  /// Creates the [TypeParameterType] with the given [nullabilitySuffix] for
  /// this type parameter.
  TypeParameterType instantiate({
    required NullabilitySuffix nullabilitySuffix,
  });
}

/// A concrete implementation of a [TypeParameterElement].
class TypeParameterElementImpl extends ElementImpl
    implements TypeParameterElement {
  /// The default value of the type parameter. It is used to provide the
  /// corresponding missing type argument in type annotations and as the
  /// fall-back type value in type inference.
  DartType? defaultType;

  /// The type representing the bound associated with this parameter, or `null`
  /// if this parameter does not have an explicit bound.
  DartType? _bound;

  /// The value representing the variance modifier keyword, or `null` if
  /// there is no explicit variance modifier, meaning legacy covariance.
  Variance? _variance;

  /// Initialize a newly created method element to have the given [name] and
  /// [offset].
  TypeParameterElementImpl(String super.name, super.offset);

  /// Initialize a newly created synthetic type parameter element to have the
  /// given [name], and with [synthetic] set to true.
  TypeParameterElementImpl.synthetic(String name) : super(name, -1) {
    isSynthetic = true;
  }

  @override
  DartType? get bound =>
      ElementTypeProvider.current.getTypeParameterBound(this);

  set bound(DartType? bound) {
    _bound = bound;
  }

  DartType? get boundInternal {
    return _bound;
  }

  @override
  TypeParameterElement get declaration => this;

  @override
  String get displayName => name;

  bool get isLegacyCovariant {
    return _variance == null;
  }

  @override
  ElementKind get kind => ElementKind.TYPE_PARAMETER;

  @override
  String get name {
    return super.name!;
  }

  Variance get variance {
    return _variance ?? Variance.covariant;
  }

  set variance(Variance? newVariance) => _variance = newVariance;

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) {
      return true;
    }
    if (other is TypeParameterElement) {
      if (other.enclosingElement2 == null || enclosingElement2 == null) {
        return identical(other, this);
      }
      return other.location == location;
    }
    return false;
  }

  @override
  T? accept<T>(ElementVisitor<T> visitor) =>
      visitor.visitTypeParameterElement(this);

  @override
  void appendTo(ElementDisplayStringBuilder builder) {
    builder.writeTypeParameter(this);
  }

  @override
  TypeParameterType instantiate({
    required NullabilitySuffix nullabilitySuffix,
  }) {
    return TypeParameterTypeImpl(
      element: this,
      nullabilitySuffix: nullabilitySuffix,
    );
  }
}

/// An element that has type parameters, such as a class or a typedef. This also
/// includes functions and methods if support for generic methods is enabled.
///
/// Clients may not extend, implement or mix-in this class.
abstract class TypeParameterizedElement implements _ExistingElement {
  /// If the element defines a type, indicates whether the type may safely
  /// appear without explicit type parameters as the bounds of a type parameter
  /// declaration.
  ///
  /// If the element does not define a type, returns `true`.
  bool get isSimplyBounded;

  /// The type parameters declared by this element directly.
  ///
  /// This does not include type parameters that are declared by any enclosing
  /// elements.
  List<TypeParameterElement> get typeParameters;
}

/// Mixin representing an element which can have type parameters.
mixin TypeParameterizedElementMixin
    implements _ExistingElementImpl, TypeParameterizedElement {
  /// The type parameters declared by this element directly. This does not
  /// include type parameters that are declared by any enclosing elements.
  List<TypeParameterElement> _typeParameterElements = const [];

  @override
  bool get isSimplyBounded => true;

  @override
  List<TypeParameterElement> get typeParameters {
    return _typeParameterElements;
  }

  List<TypeParameterElement> get typeParameters_unresolved {
    return _typeParameterElements;
  }
}

/// A pseudo-elements that represents names that are undefined. This situation
/// is not allowed by the language, so objects implementing this interface
/// always represent an error. As a result, most of the normal operations on
/// elements do not make sense and will return useless results.
///
/// Clients may not extend, implement or mix-in this class.
abstract class UndefinedElement implements Element {}

/// An element included into a library using some URI.
///
/// Clients may not extend, implement or mix-in this class.
abstract class UriReferencedElement implements _ExistingElement {
  /// The URI that is used to include this element into the enclosing library,
  /// or `null` if this is the defining compilation unit of a library.
  String? get uri;

  /// The offset of the character immediately following the last character of
  /// this node's URI, or `-1` for synthetic import.
  int get uriEnd;

  /// The offset of the URI in the file, or `-1` if this element is synthetic.
  int get uriOffset;
}

/// A concrete implementation of a [UriReferencedElement].
abstract class UriReferencedElementImpl extends _ExistingElementImpl
    implements UriReferencedElement {
  /// The offset of the URI in the file, or `-1` if this node is synthetic.
  int _uriOffset = -1;

  /// The offset of the character immediately following the last character of
  /// this node's URI, or `-1` if this node is synthetic.
  int _uriEnd = -1;

  /// The URI that is specified by this directive.
  String? _uri;

  /// Initialize a newly created import element to have the given [name] and
  /// [offset]. The offset may be `-1` if the element is synthetic.
  UriReferencedElementImpl(super.name, super.offset);

  /// Return the URI that is specified by this directive.
  @override
  String? get uri => _uri;

  /// Set the URI that is specified by this directive to be the given [uri].
  set uri(String? uri) {
    _uri = uri;
  }

  /// Return the offset of the character immediately following the last
  /// character of this node's URI, or `-1` if this node is synthetic.
  @override
  int get uriEnd => _uriEnd;

  /// Set the offset of the character immediately following the last character
  /// of this node's URI to the given [offset].
  set uriEnd(int offset) {
    _uriEnd = offset;
  }

  /// Return the offset of the URI in the file, or `-1` if this node is
  /// synthetic.
  @override
  int get uriOffset => _uriOffset;

  /// Set the offset of the URI in the file to the given [offset].
  set uriOffset(int offset) {
    _uriOffset = offset;
  }
}

/// A variable. There are more specific subclasses for more specific kinds of
/// variables.
///
/// Clients may not extend, implement or mix-in this class.
abstract class VariableElement implements Element, ConstantEvaluationTarget {
  @override
  VariableElement get declaration;

  /// Whether the variable element did not have an explicit type specified
  /// for it.
  bool get hasImplicitType;

  /// Whether the variable was declared with the 'const' modifier.
  bool get isConst;

  /// Whether the variable was declared with the 'final' modifier.
  ///
  /// Variables that are declared with the 'const' modifier will return `false`
  /// even though they are implicitly final.
  bool get isFinal;

  /// Whether the variable uses late evaluation semantics.
  ///
  /// This will always return `false` unless the experiment 'non-nullable' is
  /// enabled.
  bool get isLate;

  /// Whether the element is a static variable, as per section 8 of the Dart
  /// Language Specification:
  ///
  /// > A static variable is a variable that is not associated with a particular
  /// > instance, but rather with an entire library or class. Static variables
  /// > include library variables and class variables. Class variables are
  /// > variables whose declaration is immediately nested inside a class
  /// > declaration and includes the modifier static. A library variable is
  /// > implicitly static.
  bool get isStatic;

  @override
  String get name;

  /// The declared type of this variable.
  DartType get type;

  /// Returns a representation of the value of this variable, forcing the value
  /// to be computed if it had not previously been computed, or `null` if either
  /// this variable was not declared with the 'const' modifier or if the value
  /// of this variable could not be computed because of errors.
  DartObject? computeConstantValue();
}

/// A concrete implementation of a [VariableElement].
abstract class VariableElementImpl extends ElementImpl
    implements VariableElement {
  /// The type of this variable.
  DartType? _type;

  /// Initialize a newly created variable element to have the given [name] and
  /// [offset].
  VariableElementImpl(super.name, super.offset);

  /// If this element represents a constant variable, and it has an initializer,
  /// a copy of the initializer for the constant.  Otherwise `null`.
  ///
  /// Note that in correct Dart code, all constant variables must have
  /// initializers.  However, analyzer also needs to handle incorrect Dart code,
  /// in which case there might be some constant variables that lack
  /// initializers.
  Expression? get constantInitializer => null;

  @override
  VariableElement get declaration => this;

  @override
  String get displayName => name;

  /// Return the result of evaluating this variable's initializer as a
  /// compile-time constant expression, or `null` if this variable is not a
  /// 'const' variable, if it does not have an initializer, or if the
  /// compilation unit containing the variable has not been resolved.
  EvaluationResultImpl? get evaluationResult => null;

  /// Set the result of evaluating this variable's initializer as a compile-time
  /// constant expression to the given [result].
  set evaluationResult(EvaluationResultImpl? result) {
    throw StateError("Invalid attempt to set a compile-time constant result");
  }

  @override
  bool get hasImplicitType {
    return hasModifier(Modifier.IMPLICIT_TYPE);
  }

  /// Set whether this variable element has an implicit type.
  set hasImplicitType(bool hasImplicitType) {
    setModifier(Modifier.IMPLICIT_TYPE, hasImplicitType);
  }

  /// Set whether this variable is abstract.
  set isAbstract(bool isAbstract) {
    setModifier(Modifier.ABSTRACT, isAbstract);
  }

  @override
  bool get isConst {
    return hasModifier(Modifier.CONST);
  }

  /// Set whether this variable is const.
  set isConst(bool isConst) {
    setModifier(Modifier.CONST, isConst);
  }

  @override
  bool get isConstantEvaluated => true;

  /// Set whether this variable is external.
  set isExternal(bool isExternal) {
    setModifier(Modifier.EXTERNAL, isExternal);
  }

  @override
  bool get isFinal {
    return hasModifier(Modifier.FINAL);
  }

  /// Set whether this variable is final.
  set isFinal(bool isFinal) {
    setModifier(Modifier.FINAL, isFinal);
  }

  /// Set whether this variable is late.
  set isLate(bool isLate) {
    setModifier(Modifier.LATE, isLate);
  }

  @override
  bool get isStatic => hasModifier(Modifier.STATIC);

  set isStatic(bool isStatic) {
    setModifier(Modifier.STATIC, isStatic);
  }

  @override
  String get name => super.name!;

  @override
  DartType get type => ElementTypeProvider.current.getVariableType(this);

  set type(DartType type) {
    _type = type;
  }

  /// Gets the element's type, without going through the indirection of
  /// [ElementTypeProvider].
  ///
  /// In most cases, the element's `returnType` getter should be used instead.
  DartType get typeInternal => _type!;

  @override
  void appendTo(ElementDisplayStringBuilder builder) {
    builder.writeVariableElement(this);
  }

  @override
  DartObject? computeConstantValue() => null;
}

/// This class exists to provide non-nullable overrides for existing elements,
/// as opposite to artificial "multiply defined" element.
abstract class _ExistingElement implements Element {
  @override
  Element get declaration;

  @override
  LibraryElement get library;

  @override
  Source get librarySource;

  @override
  Source get source;
}

abstract class _ExistingElementImpl extends ElementImpl with _HasLibraryMixin {
  _ExistingElementImpl(super.name, super.offset, {super.reference});
}

/// Shared implementation of `augmentation` and `augmentationTarget`.
mixin _HasAugmentation<T> on ElementImpl {
  T? _augmentation;
  T? _augmentationTarget;

  T? get augmentation {
    linkedData?.read(this);
    return _augmentation;
  }

  set augmentation(T? value) {
    _augmentation = value;
  }

  T? get augmentationTarget {
    linkedData?.read(this);
    return _augmentationTarget;
  }

  set augmentationTarget(T? value) {
    _augmentationTarget = value;
  }

  ElementLinkedData? get linkedData;
}

mixin _HasLibraryMixin on ElementImpl {
  @override
  LibraryElementImpl get library => thisOrAncestorOfType()!;

  @override
  Source get librarySource => library.source;

  @override
  Source get source => enclosingElement2!.source!;
}

/// Instances of [List]s that are used as "not yet computed" values, they
/// must be not `null`, and not identical to `const <T>[]`.
class _Sentinel {
  static final List<AugmentationImportElementImpl> augmentationImportElement =
      List.unmodifiable([]);
  static final List<ConstructorElementImpl> constructorElement =
      List.unmodifiable([]);
  static final List<FieldElementImpl> fieldElement = List.unmodifiable([]);
  static final List<LibraryExportElementImpl> libraryExportElement =
      List.unmodifiable([]);
  static final List<LibraryImportElementImpl> libraryImportElement =
      List.unmodifiable([]);
  static final List<MethodElementImpl> methodElement = List.unmodifiable([]);
  static final List<PropertyAccessorElementImpl> propertyAccessorElement =
      List.unmodifiable([]);
}
