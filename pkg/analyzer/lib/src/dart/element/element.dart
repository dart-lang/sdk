// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection';

import 'package:_fe_analyzer_shared/src/type_inference/type_analyzer.dart'
    as shared;
import 'package:_fe_analyzer_shared/src/type_inference/type_analyzer_operations.dart'
    as shared;
import 'package:_fe_analyzer_shared/src/types/shared_type.dart';
import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/analysis/session.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/diagnostic/diagnostic.dart';
import 'package:analyzer/source/line_info.dart';
import 'package:analyzer/source/source.dart';
import 'package:analyzer/src/dart/analysis/experiments.dart';
import 'package:analyzer/src/dart/analysis/session.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/dart/ast/token.dart';
import 'package:analyzer/src/dart/constant/compute.dart';
import 'package:analyzer/src/dart/constant/evaluation.dart';
import 'package:analyzer/src/dart/constant/value.dart';
import 'package:analyzer/src/dart/element/display_string_builder.dart';
import 'package:analyzer/src/dart/element/field_name_non_promotability_info.dart';
import 'package:analyzer/src/dart/element/inheritance_manager3.dart';
import 'package:analyzer/src/dart/element/name_union.dart';
import 'package:analyzer/src/dart/element/scope.dart';
import 'package:analyzer/src/dart/element/since_sdk_version.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/dart/element/type_algebra.dart';
import 'package:analyzer/src/dart/element/type_provider.dart';
import 'package:analyzer/src/dart/element/type_system.dart';
import 'package:analyzer/src/dart/resolver/scope.dart'
    show Namespace, NamespaceBuilder;
import 'package:analyzer/src/error/inference_error.dart';
import 'package:analyzer/src/fine/annotations.dart';
import 'package:analyzer/src/fine/library_manifest.dart';
import 'package:analyzer/src/fine/requirements.dart';
import 'package:analyzer/src/generated/engine.dart' show AnalysisContext;
import 'package:analyzer/src/generated/source.dart' show DartUriResolver;
import 'package:analyzer/src/generated/utilities_collection.dart';
import 'package:analyzer/src/generated/utilities_dart.dart';
import 'package:analyzer/src/summary2/ast_binary_tokens.dart';
import 'package:analyzer/src/summary2/data_reader.dart';
import 'package:analyzer/src/summary2/data_writer.dart';
import 'package:analyzer/src/summary2/export.dart';
import 'package:analyzer/src/summary2/reference.dart';
import 'package:analyzer/src/util/file_paths.dart' as file_paths;
import 'package:analyzer/src/utilities/extensions/collection.dart';
import 'package:analyzer/src/utilities/extensions/element.dart';
import 'package:analyzer/src/utilities/extensions/object.dart';
import 'package:collection/collection.dart';
import 'package:pub_semver/pub_semver.dart';

part 'element.g.dart';

// TODO(fshcheglov): Remove after third_party/pkg/dartdoc stops using it.
// https://github.com/dart-lang/dartdoc/issues/4066
@Deprecated('Use VariableFragmentImpl instead')
typedef ConstVariableElement = VariableFragmentImpl;

class BindPatternVariableElementImpl extends PatternVariableElementImpl
    implements BindPatternVariableElement {
  BindPatternVariableElementImpl(super._wrappedElement);

  @override
  BindPatternVariableFragmentImpl get firstFragment =>
      super.firstFragment as BindPatternVariableFragmentImpl;

  @override
  List<BindPatternVariableFragmentImpl> get fragments {
    return [
      for (
        BindPatternVariableFragmentImpl? fragment = firstFragment;
        fragment != null;
        fragment = fragment.nextFragment
      )
        fragment,
    ];
  }

  /// Whether this variable clashes with another pattern variable with the same
  /// name within the same pattern.
  bool get isDuplicate => _wrappedElement.isDuplicate;

  /// Set whether this variable clashes with another pattern variable with the
  /// same name within the same pattern.
  set isDuplicate(bool value) => _wrappedElement.isDuplicate = value;

  DeclaredVariablePatternImpl get node => _wrappedElement.node;

  @override
  BindPatternVariableFragmentImpl get _wrappedElement =>
      super._wrappedElement as BindPatternVariableFragmentImpl;
}

class BindPatternVariableFragmentImpl extends PatternVariableFragmentImpl
    implements BindPatternVariableFragment {
  final DeclaredVariablePatternImpl node;

  /// This flag is set to `true` if this variable clashes with another
  /// pattern variable with the same name within the same pattern.
  bool isDuplicate = false;

  BindPatternVariableFragmentImpl({
    required this.node,
    required super.name,
    required super.firstTokenOffset,
  }) {
    _element2 = BindPatternVariableElementImpl(this);
  }

  @override
  BindPatternVariableElementImpl get element =>
      super.element as BindPatternVariableElementImpl;

  @override
  BindPatternVariableFragmentImpl? get nextFragment =>
      super.nextFragment as BindPatternVariableFragmentImpl?;

  @override
  BindPatternVariableFragmentImpl? get previousFragment =>
      super.previousFragment as BindPatternVariableFragmentImpl?;
}

@elementClass
class ClassElementImpl extends InterfaceElementImpl implements ClassElement {
  @override
  @trackedIncludedInId
  final Reference reference;

  final ClassFragmentImpl _firstFragment;

  ClassElementImpl(this.reference, this._firstFragment) {
    reference.element = this;
    firstFragment.element = this;

    isAbstract = firstFragment.isAbstract;
    isBase = firstFragment.isBase;
    isFinal = firstFragment.isFinal;
    isInterface = firstFragment.isInterface;
    isMixinClass = firstFragment.isMixinClass;
    isSealed = firstFragment.isSealed;
  }

  /// If we can find all possible subtypes of this class, return them.
  ///
  /// If the class is final, all its subtypes are declared in this library.
  ///
  /// If the class is sealed, and all its subtypes are either final or sealed,
  /// then these subtypes are all subtypes that are possible.
  @trackedDirectlyExpensive
  List<InterfaceTypeImpl>? get allSubtypes {
    globalResultRequirements?.record_classElement_allSubtypes(element: this);

    if (isFinal) {
      var result = <InterfaceTypeImpl>[];
      for (var element in library.children) {
        if (element is InterfaceElementImpl && element != this) {
          var elementThis = element.thisType;
          if (elementThis.asInstanceOf(this) != null) {
            result.add(elementThis);
          }
        }
      }
      return result;
    }

    if (isSealed) {
      var result = <InterfaceTypeImpl>[];
      for (var element in library.children) {
        if (element is! InterfaceElementImpl || identical(element, this)) {
          continue;
        }

        var elementThis = element.thisType;
        if (elementThis.asInstanceOf(this) == null) {
          continue;
        }

        switch (element) {
          case ClassElementImpl _:
            if (element.isFinal || element.isSealed) {
              result.add(elementThis);
            } else {
              return null;
            }
          case EnumElement _:
            result.add(elementThis);
          case MixinElement _:
            return null;
        }
      }
      return result;
    }

    return null;
  }

  @override
  @trackedDirectlyOpaque
  ClassFragmentImpl get firstFragment {
    globalResultRequirements?.recordOpaqueApiUse(this, 'firstFragment');
    return _firstFragment;
  }

  @override
  @trackedDirectlyOpaque
  List<ClassFragmentImpl> get fragments {
    globalResultRequirements?.recordOpaqueApiUse(this, 'fragments');
    return [
      for (
        ClassFragmentImpl? fragment = firstFragment;
        fragment != null;
        fragment = fragment.nextFragment
      )
        fragment,
    ];
  }

  bool get hasGenerativeConstConstructor {
    return constructors.any((c) => !c.isFactory && c.isConst);
  }

  @override
  @trackedDirectlyExpensive
  bool get hasNonFinalField {
    globalResultRequirements?.record_classElement_hasNonFinalField(
      element: this,
    );

    var classesToVisit = <InterfaceElementImpl>[];
    var visitedClasses = <InterfaceElementImpl>{};
    classesToVisit.add(this);
    while (classesToVisit.isNotEmpty) {
      var currentElement = classesToVisit.removeAt(0);
      if (visitedClasses.add(currentElement)) {
        // check fields
        for (var field in currentElement.fields) {
          if (!field.isFinal &&
              !field.isConst &&
              !field.isStatic &&
              !field.isSynthetic) {
            return true;
          }
        }
        // check mixins
        for (var mixinType in currentElement.mixins) {
          classesToVisit.add(mixinType.element);
        }
        // check super
        var supertype = currentElement.supertype;
        if (supertype != null) {
          classesToVisit.add(supertype.element);
        }
      }
    }
    // not found
    return false;
  }

  @override
  @trackedIncludedInId
  bool get isAbstract {
    return hasModifier(Modifier.ABSTRACT);
  }

  set isAbstract(bool isAbstract) {
    setModifier(Modifier.ABSTRACT, isAbstract);
  }

  @override
  @trackedIncludedInId
  bool get isBase {
    return hasModifier(Modifier.BASE);
  }

  set isBase(bool isBase) {
    setModifier(Modifier.BASE, isBase);
  }

  @override
  @trackedIncludedInId
  bool get isConstructable => firstFragment.isConstructable;

  @override
  @trackedIncludedInId
  bool get isDartCoreEnum {
    return name == 'Enum' && library.isDartCore;
  }

  /// Return `true` if this class represents the class 'Function' defined in the
  /// dart:core library.
  bool get isDartCoreFunctionImpl {
    return name == 'Function' && library.isDartCore;
  }

  @override
  @trackedIncludedInId
  bool get isDartCoreObject {
    return name == 'Object' && library.isDartCore;
  }

  @trackedIncludedInId
  bool get isDartCoreRecord {
    return name == 'Record' && library.isDartCore;
  }

  @trackedDirectlyExpensive
  bool get isEnumLike {
    globalResultRequirements?.record_classElement_isEnumLike(element: this);

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
    for (var class_ in library.classes) {
      if (class_.supertype?.element == this) {
        return false;
      }
    }

    return true;
  }

  @override
  @trackedIncludedInId
  bool get isExhaustive => firstFragment.isExhaustive;

  @override
  bool get isExtendableOutside => !isInterface && !isFinal && !isSealed;

  @override
  @trackedIncludedInId
  bool get isFinal {
    return hasModifier(Modifier.FINAL);
  }

  set isFinal(bool isFinal) {
    setModifier(Modifier.FINAL, isFinal);
  }

  @override
  bool get isImplementableOutside => !isBase && !isFinal && !isSealed;

  @override
  @trackedIncludedInId
  bool get isInterface {
    return hasModifier(Modifier.INTERFACE);
  }

  set isInterface(bool isInterface) {
    setModifier(Modifier.INTERFACE, isInterface);
  }

  @override
  bool get isMixableOutside {
    if (library.featureSet.isEnabled(Feature.class_modifiers)) {
      return isMixinClass && !isInterface && !isFinal && !isSealed;
    }
    return true;
  }

  @override
  @trackedIncludedInId
  bool get isMixinApplication {
    return globalResultRequirements.includedInId(() {
      return firstFragment.isMixinApplication;
    });
  }

  @override
  @trackedIncludedInId
  bool get isMixinClass {
    return hasModifier(Modifier.MIXIN_CLASS);
  }

  set isMixinClass(bool isMixinClass) {
    setModifier(Modifier.MIXIN_CLASS, isMixinClass);
  }

  @override
  @trackedIncludedInId
  bool get isSealed {
    return hasModifier(Modifier.SEALED);
  }

  set isSealed(bool isSealed) {
    setModifier(Modifier.SEALED, isSealed);
  }

  @override
  @trackedIncludedInId
  bool get isValidMixin => firstFragment.isValidMixin;

  @override
  ElementKind get kind => ElementKind.CLASS;

  @override
  @trackedDirectlyOpaque
  T? accept<T>(ElementVisitor2<T> visitor) {
    globalResultRequirements?.recordOpaqueApiUse(this, 'accept2');
    return visitor.visitClassElement(this);
  }

  @Deprecated('Use accept instead')
  @override
  @trackedDirectlyOpaque
  T? accept2<T>(ElementVisitor2<T> visitor) {
    return accept(visitor);
  }

  @override
  void appendTo(ElementDisplayStringBuilder builder) {
    builder.writeClassElement(this);
  }

  @Deprecated('Use isExtendableOutside instead')
  @override
  @trackedIndirectly
  bool isExtendableIn(LibraryElement library) {
    return library == this.library || isExtendableOutside;
  }

  @Deprecated('Use isExtendableOutside instead')
  @override
  bool isExtendableIn2(LibraryElement library) {
    return isExtendableIn(library);
  }

  @Deprecated('Use isImplementableOutside instead')
  @override
  @trackedIndirectly
  bool isImplementableIn(LibraryElement library) {
    return library == this.library || isImplementableOutside;
  }

  @Deprecated('Use isImplementableOutside instead')
  @override
  bool isImplementableIn2(LibraryElement library) {
    return isImplementableIn(library);
  }

  @Deprecated('Use isMixableOutside instead')
  @override
  @trackedIndirectly
  bool isMixableIn(LibraryElement library) {
    return (library == this.library) || isMixableOutside;
  }

  @Deprecated('Use isMixableOutside instead')
  @override
  bool isMixableIn2(LibraryElement library) {
    return isMixableIn(library);
  }

  void linkFragments(List<ClassFragmentImpl> fragments) {
    assert(identical(fragments[0], firstFragment));
    fragments.reduce((previous, current) {
      previous.addFragment(current);
      return current;
    });
  }

  @override
  void _buildMixinAppConstructors() {
    // Do nothing if not a mixin application.
    if (!isMixinApplication) {
      return;
    }

    var superType = supertype;
    if (superType == null) {
      // Shouldn't ever happen, since the only classes with no supertype are
      // Object and mixins, and they aren't a mixin application. But for
      // safety's sake just assume an empty list.
      assert(false);
      _constructors = <ConstructorElementImpl>[];
      return;
    }

    // Assign to break a possible infinite recursion during computing.
    _constructors = const <ConstructorElementImpl>[];

    var superConstructors = superType.constructors
        .where((constructor) => constructor.isAccessibleIn(library))
        .where((constructor) => constructor.isGenerative)
        .toList(growable: false);

    bool typeHasInstanceVariables(InterfaceTypeImpl type) =>
        type.element.fields.any((e) => !e.isSynthetic);

    _constructors =
        superConstructors.map((superConstructor) {
          var constructorFragment = ConstructorFragmentImpl(
            name: superConstructor.name ?? 'new',
          );
          constructorFragment.isSynthetic = true;
          constructorFragment.typeName = name;
          constructorFragment.isConst =
              superConstructor.isConst && !mixins.any(typeHasInstanceVariables);
          constructorFragment.enclosingFragment = firstFragment;

          var constructorElement = ConstructorElementImpl(
            name: constructorFragment.name,
            reference: reference
                .getChild('@constructor')
                .getChild(constructorFragment.name),
            firstFragment: constructorFragment,
          );
          constructorElement.superConstructor = superConstructor;
          // TODO(scheglov): make it explicit
          // constructorElement.enclosingElement = this;

          var formalParameterFragments = <FormalParameterFragmentImpl>[];
          var formalParameterElements = <FormalParameterElementImpl>[];
          var superInvocationArguments = <ExpressionImpl>[];
          for (var superFormalParameter in superConstructor.formalParameters) {
            var formalParameterFragment = FormalParameterFragmentImpl(
                name: superFormalParameter.name,
                nameOffset: null,
                parameterKind: superFormalParameter.parameterKind,
              )
              ..constantInitializer =
                  superFormalParameter
                      .baseElement
                      .firstFragment
                      .constantInitializer;

            formalParameterFragment.isConst = superFormalParameter.isConst;
            formalParameterFragment.isFinal = superFormalParameter.isFinal;
            formalParameterFragment.isSynthetic = true;
            formalParameterFragments.add(formalParameterFragment);

            var formalParameterElement = FormalParameterElementImpl(
              formalParameterFragment,
            );
            formalParameterElements.add(formalParameterElement);
            formalParameterElement.type = superFormalParameter.type;

            superInvocationArguments.add(
              SimpleIdentifierImpl(
                  token: StringToken(
                    TokenType.STRING,
                    formalParameterFragment.name ?? '',
                    -1,
                  ),
                )
                ..element = formalParameterElement
                ..setPseudoExpressionStaticType(formalParameterElement.type),
            );
          }

          constructorFragment.formalParameters =
              formalParameterFragments.toFixedList();

          var isNamed = superConstructor.name != 'new';
          var superInvocation = SuperConstructorInvocationImpl(
            superKeyword: Tokens.super_(),
            period: isNamed ? Tokens.period() : null,
            constructorName:
                isNamed
                    ? (SimpleIdentifierImpl(
                      token: StringToken(
                        TokenType.STRING,
                        superConstructor.name ?? 'new',
                        -1,
                      ),
                    )..element = superConstructor.baseElement)
                    : null,
            argumentList: ArgumentListImpl(
              leftParenthesis: Tokens.openParenthesis(),
              arguments: superInvocationArguments,
              rightParenthesis: Tokens.closeParenthesis(),
            ),
          );
          AstNodeImpl.linkNodeTokens(superInvocation);
          superInvocation.element = superConstructor.baseElement;
          constructorFragment.constantInitializers = [superInvocation];

          return constructorElement;
        }).toFixedList();

    firstFragment.constructors =
        _constructors.map((e) => e.firstFragment).toFixedList();
  }
}

/// An [InterfaceFragmentImpl] which is a class.
@GenerateFragmentImpl(modifiers: _ClassFragmentImplModifiers.values)
class ClassFragmentImpl extends InterfaceFragmentImpl
    with _ClassFragmentImplMixin
    implements ClassFragment {
  @override
  late final ClassElementImpl element;

  /// Initialize a newly created class element to have the given [name] at the
  /// given [offset] in the file that contains the declaration of this element.
  ClassFragmentImpl({required super.name});

  bool get hasGenerativeConstConstructor {
    _ClassFragmentImplModifiers.hasExtendsClause;
    return constructors.any((c) => !c.isFactory && c.isConst);
  }

  bool get isConstructable => !isSealed && !isAbstract;

  bool get isExhaustive => isSealed;

  bool get isValidMixin {
    var supertype = this.supertype;
    if (supertype != null && !supertype.isDartCoreObject) {
      return false;
    }
    for (var constructor in constructors) {
      if (!constructor.isSynthetic && !constructor.isFactory) {
        return false;
      }
    }
    return true;
  }

  @override
  ClassFragmentImpl? get nextFragment {
    return super.nextFragment as ClassFragmentImpl?;
  }

  @override
  ClassFragmentImpl? get previousFragment {
    return super.previousFragment as ClassFragmentImpl?;
  }

  void addFragment(ClassFragmentImpl fragment) {
    fragment.element = element;
    fragment.previousFragment = this;
    nextFragment = fragment;
  }
}

// TODO(scheglov): remove this
class ConstantInitializerImpl {
  final VariableFragmentImpl fragment;
  final ExpressionImpl expression;

  ConstantInitializerImpl({required this.fragment, required this.expression});
}

class ConstructorElementImpl extends ExecutableElementImpl
    with InternalConstructorElement
    implements ConstantEvaluationTarget {
  @override
  final Reference reference;

  @override
  final String? name;

  @override
  final ConstructorFragmentImpl firstFragment;

  /// The constructor to which this constructor is redirecting.
  InternalConstructorElement? _redirectedConstructor;

  /// The super-constructor which this constructor is invoking, or `null` if
  /// this constructor is not generative, or is redirecting, or the
  /// super-constructor is not resolved, or the enclosing class is `Object`.
  ///
  // TODO(scheglov): We cannot have both super and redirecting constructors.
  // So, ideally we should have some kind of "either" or "variant" here.
  InternalConstructorElement? _superConstructor;

  ConstructorElementImpl({
    required this.name,
    required this.reference,
    required this.firstFragment,
  }) {
    reference.element = this;
    firstFragment.element = this;
  }

  @override
  ConstructorElementImpl get baseElement => this;

  /// The constant initializers for this element, from all fragments.
  List<ConstructorInitializer> get constantInitializers {
    return fragments
        .expand((fragment) => fragment.constantInitializers)
        .toList(growable: false);
  }

  @override
  String get displayName {
    var className = enclosingElement.name ?? '<null>';
    var name = this.name ?? '<null>';
    if (name != 'new') {
      return '$className.$name';
    } else {
      return className;
    }
  }

  @override
  InterfaceElementImpl get enclosingElement =>
      firstFragment.enclosingFragment.element;

  @Deprecated('Use enclosingElement instead')
  @override
  InterfaceElementImpl get enclosingElement2 => enclosingElement;

  @override
  List<ConstructorFragmentImpl> get fragments {
    return [
      for (
        ConstructorFragmentImpl? fragment = firstFragment;
        fragment != null;
        fragment = fragment.nextFragment
      )
        fragment,
    ];
  }

  @override
  bool get isConst => firstFragment.isConst;

  @override
  bool get isConstantEvaluated => firstFragment.isConstantEvaluated;

  @override
  bool get isDefaultConstructor => firstFragment.isDefaultConstructor;

  @override
  bool get isFactory => firstFragment.isFactory;

  @override
  bool get isGenerative => firstFragment.isGenerative;

  @override
  ElementKind get kind => ElementKind.CONSTRUCTOR;

  @override
  ConstructorFragmentImpl get lastFragment {
    return super.lastFragment as ConstructorFragmentImpl;
  }

  @override
  LibraryFragmentImpl get libraryFragment => firstFragment.libraryFragment;

  @Deprecated('Use name instead')
  @override
  String? get name3 => name;

  @override
  Element get nonSynthetic {
    if (isSynthetic) {
      return enclosingElement;
    } else {
      return this;
    }
  }

  @override
  InternalConstructorElement? get redirectedConstructor {
    _ensureReadResolution();
    return _redirectedConstructor;
  }

  set redirectedConstructor(InternalConstructorElement? value) {
    _redirectedConstructor = value;
  }

  @Deprecated('Use redirectedConstructor instead')
  @override
  InternalConstructorElement? get redirectedConstructor2 {
    return redirectedConstructor;
  }

  @override
  InterfaceTypeImpl get returnType {
    var result = _returnType;
    if (result != null) {
      return result as InterfaceTypeImpl;
    }

    return _returnType = enclosingElement.thisType;
  }

  @override
  InternalConstructorElement? get superConstructor {
    _ensureReadResolution();
    return _superConstructor;
  }

  set superConstructor(InternalConstructorElement? superConstructor) {
    _superConstructor = superConstructor;
  }

  @Deprecated('Use superConstructor instead')
  @override
  InternalConstructorElement? get superConstructor2 {
    return superConstructor;
  }

  @override
  T? accept<T>(ElementVisitor2<T> visitor) {
    return visitor.visitConstructorElement(this);
  }

  @Deprecated('Use accept instead')
  @override
  T? accept2<T>(ElementVisitor2<T> visitor) => accept(visitor);

  @override
  void appendTo(ElementDisplayStringBuilder builder) {
    builder.writeConstructorElement(this);
  }

  /// Ensures that dependencies of this constructor, such as default values
  /// of formal parameters, are evaluated.
  void computeConstantDependencies() {
    if (!isConstantEvaluated) {
      computeConstants(
        declaredVariables: library.context.declaredVariables,
        constants: [this],
        featureSet: library.featureSet,
        configuration: ConstantEvaluationConfiguration(),
      );
    }
  }

  void linkFragments(List<ConstructorFragmentImpl> fragments) {
    assert(identical(fragments[0], firstFragment));
    fragments.reduce((previous, current) {
      previous.addFragment(current);
      return current;
    });
  }

  @override
  void visitChildren<T>(ElementVisitor2<T> visitor) {
    for (var child in children) {
      child.accept(visitor);
    }
  }
}

/// A concrete implementation of a [ConstructorFragment].
@GenerateFragmentImpl(modifiers: _ConstructorFragmentImplModifiers.values)
class ConstructorFragmentImpl extends ExecutableFragmentImpl
    with _ConstructorFragmentImplMixin
    implements ConstructorFragment {
  late final ConstructorElementImpl element;

  /// The initializers for this constructor (used for evaluating constant
  /// instance creation expressions).
  List<ConstructorInitializer> _constantInitializers = const [];

  @override
  String? typeName;

  @override
  int? typeNameOffset;

  @override
  int? periodOffset;

  @override
  int? nameEnd;

  @override
  final String name;

  @override
  int? nameOffset;

  @override
  ConstructorFragmentImpl? previousFragment;

  @override
  ConstructorFragmentImpl? nextFragment;

  /// For every constructor we initially set this flag to `true`, and then
  /// set it to `false` during computing constant values if we detect that it
  /// is a part of a cycle.
  bool isCycleFree = true;

  /// Return whether this constant is evaluated.
  bool isConstantEvaluated = false;

  /// Initialize a newly created constructor element to have the given [name]
  /// and [offset].
  ConstructorFragmentImpl({required this.name});

  /// Return the constant initializers for this element, which will be empty if
  /// there are no initializers, or `null` if there was an error in the source.
  List<ConstructorInitializer> get constantInitializers {
    _ensureReadResolution();
    return _constantInitializers;
  }

  set constantInitializers(List<ConstructorInitializer> constantInitializers) {
    _constantInitializers = constantInitializers;
  }

  @override
  ConstructorFragmentImpl get declaration => this;

  @override
  String get displayName {
    var className = enclosingFragment.name;
    var name = this.name;
    if (name != 'new') {
      return '$className.$name';
    } else {
      return className ?? '<null>';
    }
  }

  @override
  InterfaceFragmentImpl get enclosingFragment =>
      super.enclosingFragment as InterfaceFragmentImpl;

  /// Whether the constructor can be used as a default constructor - unnamed,
  /// and has no required parameters.
  bool get isDefaultConstructor {
    // unnamed
    if (name != 'new') {
      return false;
    }
    // no required parameters
    for (var formalParameters in formalParameters) {
      if (formalParameters.isRequired) {
        return false;
      }
    }
    // OK, can be used as default constructor
    return true;
  }

  /// Whether the constructor represents a generative constructor.
  bool get isGenerative {
    return !isFactory;
  }

  @Deprecated('Use name instead')
  @override
  String get name2 => name;

  @override
  int get offset =>
      nameOffset ??
      typeNameOffset ??
      firstTokenOffset ??
      enclosingFragment.offset;

  void addFragment(ConstructorFragmentImpl fragment) {
    fragment.element = element;
    fragment.previousFragment = this;
    nextFragment = fragment;
  }
}

/// This mixin is used to set up loading class members from summaries only when
/// they are requested. The summary reader uses [deferReadMembers], and
/// getters invoke [ensureReadMembers].
///
/// We defer reading of both class elements, and class fragments. However
/// getters on class fragments ensure that the whole class element members are
/// read. The reason is that we want to have `nextFragment`, `previousFragment`,
/// and `element` properties return correct value, and reading the whole
/// element is the simplest way to do this.
mixin DeferredMembersReadingMixin {
  void Function()? _readMembersCallback;
  void Function()? _applyMembersOffsets;

  void deferApplyMembersOffsets(void Function() callback) {
    assert(_applyMembersOffsets == null);
    _applyMembersOffsets = callback;
  }

  void deferReadMembers(void Function()? callback) {
    assert(_readMembersCallback == null);
    _readMembersCallback = callback;
  }

  void ensureReadMembers() {
    if (_readMembersCallback case var callback?) {
      _readMembersCallback = null;
      callback();
    }

    if (_applyMembersOffsets case var callback?) {
      _applyMembersOffsets = null;
      callback();
    }
  }
}

/// This mixin is used to set up loading resolution information from summaries
/// on demand, and after all elements are loaded, so for example types can
/// reference them. The summary reader uses [deferReadResolution], and getters
/// invoke [_ensureReadResolution].
mixin DeferredResolutionReadingMixin {
  // TODO(scheglov): review whether we need this
  int _lockResolutionLoading = 0;
  void Function()? _readResolutionCallback;
  void Function()? _applyResolutionConstantOffsets;

  void deferReadResolution(void Function()? callback) {
    assert(_readResolutionCallback == null);
    _readResolutionCallback = callback;
  }

  void deferResolutionConstantOffsets(void Function() callback) {
    assert(_applyResolutionConstantOffsets == null);
    _applyResolutionConstantOffsets = callback;
  }

  void withoutLoadingResolution(void Function() operation) {
    _lockResolutionLoading++;
    operation();
    _lockResolutionLoading--;
  }

  void _ensureReadResolution() {
    if (_lockResolutionLoading > 0) {
      return;
    }

    if (_readResolutionCallback case var callback?) {
      _readResolutionCallback = null;
      callback();

      // The callback read all AST nodes, apply offsets.
      if (_applyResolutionConstantOffsets case var callback?) {
        _applyResolutionConstantOffsets = null;
        callback();
      }
    }
  }
}

class DirectiveUriImpl implements DirectiveUri {}

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

  @override
  @Deprecated('Use library instead')
  LibraryElement get library2 => library;
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

class DirectiveUriWithRelativeUriStringImpl extends DirectiveUriImpl
    implements DirectiveUriWithRelativeUriString {
  @override
  final String relativeUriString;

  DirectiveUriWithRelativeUriStringImpl({required this.relativeUriString});
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

class DirectiveUriWithUnitImpl extends DirectiveUriWithRelativeUriImpl
    implements DirectiveUriWithUnit {
  @override
  final LibraryFragmentImpl libraryFragment;

  DirectiveUriWithUnitImpl({
    required super.relativeUriString,
    required super.relativeUri,
    required this.libraryFragment,
  });

  @override
  Source get source => libraryFragment.source;
}

/// The synthetic element representing the declaration of the type `dynamic`.
class DynamicElementImpl extends ElementImpl implements TypeDefiningElement {
  /// The unique instance of this class.
  static final DynamicElementImpl instance = DynamicElementImpl._();

  DynamicElementImpl._();

  @override
  Null get documentationComment => null;

  @override
  Element? get enclosingElement => null;

  @Deprecated('Use enclosingElement instead')
  @override
  Element? get enclosingElement2 => enclosingElement;

  @override
  DynamicFragmentImpl get firstFragment => DynamicFragmentImpl.instance;

  @override
  List<DynamicFragmentImpl> get fragments {
    return [
      for (
        DynamicFragmentImpl? fragment = firstFragment;
        fragment != null;
        fragment = fragment.nextFragment
      )
        fragment,
    ];
  }

  @override
  bool get isSynthetic => true;

  @override
  ElementKind get kind => ElementKind.DYNAMIC;

  @override
  Null get library => null;

  @Deprecated('Use library instead')
  @override
  Null get library2 => library;

  @override
  MetadataImpl get metadata {
    return MetadataImpl(const []);
  }

  @Deprecated('Use metadata instead')
  @override
  MetadataImpl get metadata2 => metadata;

  @override
  String get name => 'dynamic';

  @Deprecated('Use name instead')
  @override
  String get name3 => name;

  @override
  T? accept<T>(ElementVisitor2<T> visitor) => null;

  @Deprecated('Use accept instead')
  @override
  T? accept2<T>(ElementVisitor2<T> visitor) => accept(visitor);

  @override
  void appendTo(ElementDisplayStringBuilder builder) {
    builder.writeDynamicElement(this);
  }
}

/// The synthetic element representing the declaration of the type `dynamic`.
class DynamicFragmentImpl extends FragmentImpl implements TypeDefiningFragment {
  /// The unique instance of this class.
  static final DynamicFragmentImpl instance = DynamicFragmentImpl._();

  /// Initialize a newly created instance of this class. Instances of this class
  /// should <b>not</b> be created except as part of creating the type
  /// associated with this element. The single instance of this class should be
  /// accessed through the method [instance].
  DynamicFragmentImpl._() : super(firstTokenOffset: null) {
    isSynthetic = true;
  }

  @override
  List<Fragment> get children => const [];

  @Deprecated('Use children instead')
  @override
  List<Fragment> get children3 => const [];

  @override
  DynamicElementImpl get element => DynamicElementImpl.instance;

  @override
  Null get enclosingFragment => null;

  @override
  Null get libraryFragment => null;

  @Deprecated('Use metadata instead')
  @override
  MetadataImpl get metadata2 => metadata;

  @override
  String get name => 'dynamic';

  @Deprecated('Use name instead')
  @override
  String get name2 => name;

  @override
  Null get nameOffset => null;

  @override
  Null get nextFragment => null;

  @override
  int get offset => 0;

  @override
  Null get previousFragment => null;
}

/// A concrete implementation of an [ElementAnnotation].
class ElementAnnotationImpl
    implements ElementAnnotation, ConstantEvaluationTarget {
  /// The name of the top-level variable used to mark that a function always
  /// throws, for dead code purposes.
  static const String _alwaysThrowsVariableName = 'alwaysThrows';

  /// The name of the top-level variable used to mark an element as not needing
  /// to be awaited.
  static const String _awaitNotRequiredVariableName = 'awaitNotRequired';

  /// The name of the class used to mark an element as being deprecated.
  static const String _deprecatedClassName = 'Deprecated';

  /// The name of the top-level variable used to mark an element as being
  /// deprecated.
  static const String _deprecatedVariableName = 'deprecated';

  /// The name of the top-level variable used to mark an element as not to be
  /// stored.
  static const String _doNotStoreVariableName = 'doNotStore';

  /// The name of the top-level variable used to mark a declaration as not to be
  /// used (for ephemeral testing and debugging only).
  static const String _doNotSubmitVariableName = 'doNotSubmit';

  /// The name of the top-level variable used to mark a declaration as experimental.
  static const String _experimentalVariableName = 'experimental';

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

  /// The name of the top-level variable used to mark a returned element as
  /// requiring use.
  static const String _mustBeConstVariableName = 'mustBeConst';

  /// The name of the top-level variable used to mark a type as having
  /// "optional" type arguments.
  static const String _optionalTypeArgsVariableName = 'optionalTypeArgs';

  /// The name of the top-level variable used to mark a function as running
  /// a single test.
  static const String _isTestVariableName = 'isTest';

  /// The name of the top-level variable used to mark a function as a Flutter
  /// widget factory.
  static const String _widgetFactoryName = 'widgetFactory';

  /// The URI of the Flutter widget inspector library.
  static final Uri _flutterWidgetInspectorLibraryUri = Uri.parse(
    'package:flutter/src/widgets/widget_inspector.dart',
  );

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

  /// The name of the top-level variable used to mark a member as redeclaring.
  static const String _redeclareVariableName = 'redeclare';

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
  LibraryFragmentImpl libraryFragment;

  /// The AST of the annotation itself, cloned from the resolved AST for the
  /// source code.
  late AnnotationImpl annotationAst;

  /// The result of evaluating this annotation as a compile-time constant
  /// expression, or `null` if the compilation unit containing the variable has
  /// not been resolved.
  Constant? evaluationResult;

  /// Any additional errors, other than [evaluationResult] being an
  /// [InvalidConstant], that came from evaluating the constant expression,
  /// or `null` if the compilation unit containing the variable has
  /// not been resolved.
  ///
  // TODO(kallentu): Remove this field once we fix up g3's dependency on
  // annotations having a valid result as well as unresolved errors.
  List<Diagnostic>? additionalErrors;

  /// Initialize a newly created annotation. The given [libraryFragment] is the
  /// compilation unit in which the annotation appears.
  ElementAnnotationImpl(this.libraryFragment, this.annotationAst) {
    annotationAst.elementAnnotation = this;
  }

  @override
  List<Diagnostic> get constantEvaluationErrors {
    var evaluationResult = this.evaluationResult;
    var additionalErrors = this.additionalErrors;
    if (evaluationResult is InvalidConstant) {
      // When we have an [InvalidConstant], we don't report the additional
      // errors because this result contains the most relevant error.
      return [
        Diagnostic.tmp(
          source: libraryFragment.source,
          offset: evaluationResult.offset,
          length: evaluationResult.length,
          diagnosticCode: evaluationResult.diagnosticCode,
          arguments: evaluationResult.arguments,
          contextMessages: evaluationResult.contextMessages,
        ),
      ];
    }
    return additionalErrors ?? const <Diagnostic>[];
  }

  @override
  Element? get element => annotationAst.element;

  @override
  @Deprecated('Use element instead')
  Element? get element2 => element;

  @override
  bool get isAlwaysThrows => _isPackageMetaGetter(_alwaysThrowsVariableName);

  @override
  bool get isAwaitNotRequired =>
      _isPackageMetaGetter(_awaitNotRequiredVariableName);

  @override
  bool get isConstantEvaluated => evaluationResult != null;

  bool get isDartInternalSince {
    var element = this.element;
    if (element is ConstructorElement) {
      return element.enclosingElement.name == 'Since' &&
          element.library.uri.toString() == 'dart:_internal';
    }
    return false;
  }

  @override
  bool get isDeprecated {
    var element = this.element;
    if (element is ConstructorElement) {
      return element.library.isDartCore &&
          element.enclosingElement.name == _deprecatedClassName;
    } else if (element is PropertyAccessorElement) {
      return element.library.isDartCore &&
          element.name == _deprecatedVariableName;
    }
    return false;
  }

  @override
  bool get isDoNotStore => _isPackageMetaGetter(_doNotStoreVariableName);

  @override
  bool get isDoNotSubmit => _isPackageMetaGetter(_doNotSubmitVariableName);

  @override
  bool get isExperimental => _isPackageMetaGetter(_experimentalVariableName);

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
  bool get isMustBeConst => _isPackageMetaGetter(_mustBeConstVariableName);

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
  bool get isRedeclare => _isPackageMetaGetter(_redeclareVariableName);

  @override
  bool get isReopen => _isPackageMetaGetter(_reopenVariableName);

  @override
  bool get isRequired =>
      _isConstructor(
        libraryName: _metaLibName,
        className: _requiredClassName,
      ) ||
      _isPackageMetaGetter(_requiredVariableName);

  @override
  bool get isSealed => _isPackageMetaGetter(_sealedVariableName);

  @override
  bool get isTarget => _isConstructor(
    libraryName: _metaMetaLibName,
    className: _targetClassName,
  );

  @override
  bool get isUseResult =>
      _isConstructor(
        libraryName: _metaLibName,
        className: _useResultClassName,
      ) ||
      _isPackageMetaGetter(_useResultVariableName);

  @override
  bool get isVisibleForOverriding =>
      _isPackageMetaGetter(_visibleForOverridingName);

  @override
  bool get isVisibleForTemplate => _isTopGetter(
    libraryName: _angularMetaLibName,
    name: _visibleForTemplateVariableName,
  );

  @override
  bool get isVisibleForTesting =>
      _isPackageMetaGetter(_visibleForTestingVariableName);

  @override
  bool get isVisibleOutsideTemplate => _isTopGetter(
    libraryName: _angularMetaLibName,
    name: _visibleOutsideTemplateVariableName,
  );

  @override
  bool get isWidgetFactory => _isTopGetter(
    libraryUri: _flutterWidgetInspectorLibraryUri,
    name: _widgetFactoryName,
  );

  @override
  DartObject? computeConstantValue() {
    if (evaluationResult == null) {
      var library = libraryFragment.element;
      computeConstants(
        declaredVariables: library.context.declaredVariables,
        constants: [this],
        featureSet: library.featureSet,
        configuration: ConstantEvaluationConfiguration(),
      );
    }

    if (evaluationResult case DartObjectImpl result) {
      return result;
    }
    return null;
  }

  @override
  String toSource() => annotationAst.toSource();

  @override
  String toString() => '@$element';

  bool _isConstructor({
    required String libraryName,
    required String className,
  }) {
    var element = this.element;
    return element is ConstructorElement &&
        element.enclosingElement.name == className &&
        element.library.name == libraryName;
  }

  bool _isDartCoreGetter(String name) {
    return _isTopGetter(libraryName: 'dart.core', name: name);
  }

  bool _isPackageMetaGetter(String name) {
    return _isTopGetter(libraryName: _metaLibName, name: name);
  }

  bool _isTopGetter({
    String? libraryName,
    Uri? libraryUri,
    required String name,
  }) {
    assert(
      (libraryName != null) != (libraryUri != null),
      'Exactly one of libraryName/libraryUri should be provided',
    );
    var element = this.element;
    return element is PropertyAccessorElement &&
        element.name == name &&
        (libraryName == null || element.library.name == libraryName) &&
        (libraryUri == null || element.library.uri == libraryUri);
  }
}

sealed class ElementDirectiveImpl implements ElementDirective {
  @override
  late LibraryFragmentImpl libraryFragment;

  @override
  final DirectiveUri uri;

  @override
  MetadataImpl metadata = MetadataImpl(const []);

  ElementDirectiveImpl({required this.uri});

  @override
  Null get documentationComment => null;

  @Deprecated('Use metadata instead')
  @override
  MetadataImpl get metadata2 => metadata;

  /// Append a textual representation to the given [builder].
  void appendTo(ElementDisplayStringBuilder builder);

  String displayString() {
    var builder = ElementDisplayStringBuilder(preferTypeAlias: false);
    appendTo(builder);
    return builder.toString();
  }

  @override
  String toString() {
    return displayString();
  }
}

abstract class ElementImpl implements Element {
  /// Cached values for [sinceSdkVersion].
  ///
  /// Only very few elements have `@Since()` annotations, so instead of adding
  /// an instance field to [ElementImpl], we attach this information this way.
  /// We ask it only when [Modifier.HAS_SINCE_SDK_VERSION_VALUE] is `true`, so
  /// don't pay for a hash lookup when we know that the result is `null`.
  static final Expando<Version> _sinceSdkVersion = Expando<Version>();

  @override
  final int id = FragmentImpl._NEXT_ID++;

  /// The modifiers associated with this element.
  EnumSet<Modifier> _modifiers = EnumSet.empty();

  @override
  Element get baseElement => this;

  @override
  List<Element> get children => const [];

  @Deprecated('Use children instead')
  @override
  List<Element> get children2 => children;

  @override
  String get displayName => name ?? '<unnamed>';

  @override
  String? get documentationComment {
    var buffer = StringBuffer();
    for (var fragment in fragments) {
      var comment = fragment.documentationComment;
      if (comment != null) {
        if (buffer.isNotEmpty) {
          buffer.writeln();
          buffer.writeln();
        }
        buffer.write(comment);
      }
    }
    if (buffer.isEmpty) {
      return null;
    }
    return buffer.toString();
  }

  @override
  List<Fragment> get fragments {
    return [
      for (
        Fragment? fragment = firstFragment;
        fragment != null;
        fragment = fragment.nextFragment
      )
        fragment,
    ];
  }

  @override
  bool get isPrivate {
    var name = this.name;
    if (name == null) {
      return true;
    }
    return Identifier.isPrivateName(name);
  }

  @override
  bool get isPublic => !isPrivate;

  @override
  @trackedIncludedInId
  LibraryElementImpl? get library {
    return globalResultRequirements.includedInId(() {
      return firstFragment.libraryFragment?.element as LibraryElementImpl?;
    });
  }

  @override
  String? get lookupName {
    return name;
  }

  @override
  MetadataImpl get metadata => MetadataImpl.empty;

  @override
  Element get nonSynthetic => this;

  @Deprecated('Use nonSynthetic instead')
  @override
  Element get nonSynthetic2 => nonSynthetic;

  /// The reference of this element, used during reading summaries.
  ///
  /// Can be `null` if this element cannot be referenced from outside,
  /// for example a [LocalFunctionElement], a [TypeParameterElement],
  /// a positional [FormalParameterElement], etc.
  Reference? get reference => null;

  @override
  AnalysisSession? get session {
    return enclosingElement?.session;
  }

  @override
  Version? get sinceSdkVersion {
    if (!hasModifier(Modifier.HAS_SINCE_SDK_VERSION_COMPUTED)) {
      setModifier(Modifier.HAS_SINCE_SDK_VERSION_COMPUTED, true);
      var result = SinceSdkVersionComputer().compute(this);
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
  bool operator ==(Object other) {
    return identical(this, other);
  }

  /// Append a textual representation of this element to the given [builder].
  void appendTo(ElementDisplayStringBuilder builder) {
    builder.writeAbstractElement(this);
  }

  @override
  String displayString({bool multiline = false, bool preferTypeAlias = false}) {
    var builder = ElementDisplayStringBuilder(
      multiline: multiline,
      preferTypeAlias: preferTypeAlias,
    );
    appendTo(builder);
    return builder.toString();
  }

  @Deprecated('Use displayString instead')
  @override
  String displayString2({
    bool multiline = false,
    bool preferTypeAlias = false,
  }) {
    return displayString(
      multiline: multiline,
      preferTypeAlias: preferTypeAlias,
    );
  }

  @override
  String getExtendedDisplayName({String? shortName}) {
    shortName ??= displayName;
    var source = firstFragment.libraryFragment?.source;
    return "$shortName (${source?.fullName})";
  }

  @Deprecated('Use getExtendedDisplayName instead')
  @override
  String getExtendedDisplayName2({String? shortName}) {
    return getExtendedDisplayName(shortName: shortName);
  }

  /// Whether this element has the [modifier].
  bool hasModifier(Modifier modifier) => _modifiers[modifier];

  @override
  bool isAccessibleIn(LibraryElement library) {
    var name = this.name;
    if (name == null || Identifier.isPrivateName(name)) {
      return library == this.library;
    }
    return true;
  }

  @Deprecated('Use isAccessibleIn instead')
  @override
  bool isAccessibleIn2(LibraryElement library) {
    return isAccessibleIn(library);
  }

  void readModifiers(SummaryDataReader reader) {
    _modifiers = EnumSet.read(reader);
  }

  /// Update [modifier] of this element to [value].
  void setModifier(Modifier modifier, bool value) {
    _modifiers = _modifiers.updated(modifier, value);
  }

  @override
  Element? thisOrAncestorMatching(bool Function(Element p1) predicate) {
    Element? element = this;
    while (element != null && !predicate(element)) {
      element = element.enclosingElement;
    }
    return element;
  }

  @Deprecated('Use thisOrAncestorMatching instead')
  @override
  Element? thisOrAncestorMatching2(bool Function(Element p1) predicate) {
    return thisOrAncestorMatching(predicate);
  }

  @override
  E? thisOrAncestorOfType<E extends Element>() {
    Element element = this;
    while (element is! E) {
      var ancestor = element.enclosingElement;
      if (ancestor == null) return null;
      element = ancestor;
    }
    return element;
  }

  @Deprecated('Use thisOrAncestorOfType instead')
  @override
  E? thisOrAncestorOfType2<E extends Element>() {
    return thisOrAncestorOfType();
  }

  @override
  String toString() {
    return displayString();
  }

  /// Use the given [visitor] to visit all of the children of this element.
  /// There is no guarantee of the order in which the children will be visited.
  @override
  void visitChildren<T>(ElementVisitor2<T> visitor) {
    for (var child in children) {
      child.accept(visitor);
    }
  }

  /// Use the given [visitor] to visit all of the children of this element.
  /// There is no guarantee of the order in which the children will be visited.
  @Deprecated('Use visitChildren instead')
  @override
  void visitChildren2<T>(ElementVisitor2<T> visitor) {
    visitChildren(visitor);
  }

  void writeModifiers(BufferedSink writer) {
    _modifiers.write(writer);
  }
}

class EnumElementImpl extends InterfaceElementImpl implements EnumElement {
  @override
  final Reference reference;

  @override
  final EnumFragmentImpl firstFragment;

  EnumElementImpl(this.reference, this.firstFragment) {
    reference.element = this;
    firstFragment.element = this;
  }

  @override
  List<FieldElementImpl> get constants {
    return fields.where((field) => field.isEnumConstant).toList();
  }

  @Deprecated('Use constants instead')
  @override
  List<FieldElementImpl> get constants2 {
    return constants;
  }

  @override
  List<EnumFragmentImpl> get fragments {
    return [
      for (
        EnumFragmentImpl? fragment = firstFragment;
        fragment != null;
        fragment = fragment.nextFragment
      )
        fragment,
    ];
  }

  @override
  ElementKind get kind => ElementKind.ENUM;

  FieldElementImpl? get valuesField {
    for (var field in fields) {
      if (field.name == 'values' && field.isSyntheticEnumField) {
        return field;
      }
    }
    return null;
  }

  @override
  T? accept<T>(ElementVisitor2<T> visitor) => visitor.visitEnumElement(this);

  @Deprecated('Use accept instead')
  @override
  T? accept2<T>(ElementVisitor2<T> visitor) => accept(visitor);

  @override
  void appendTo(ElementDisplayStringBuilder builder) {
    builder.writeEnumElement(this);
  }

  void linkFragments(List<EnumFragmentImpl> fragments) {
    assert(identical(fragments[0], firstFragment));
    fragments.reduce((previous, current) {
      previous.addFragment(current);
      return current;
    });
  }
}

/// An [InterfaceFragmentImpl] which is an enum.
class EnumFragmentImpl extends InterfaceFragmentImpl implements EnumFragment {
  @override
  late final EnumElementImpl element;

  /// Initialize a newly created class element to have the given [name] at the
  /// given [offset] in the file that contains the declaration of this element.
  EnumFragmentImpl({required super.name});

  @override
  List<FieldElement> get constants {
    var constants = fields.where((field) => field.isEnumConstant).toList();
    return constants.map((e) => e.asElement2).toList();
  }

  @Deprecated('Use constants instead')
  @override
  List<FieldElement> get constants2 {
    return constants;
  }

  @override
  EnumFragmentImpl? get nextFragment => super.nextFragment as EnumFragmentImpl?;

  @override
  EnumFragmentImpl? get previousFragment =>
      super.previousFragment as EnumFragmentImpl?;

  void addFragment(EnumFragmentImpl fragment) {
    fragment.element = element;
    fragment.previousFragment = this;
    nextFragment = fragment;
  }
}

abstract class ExecutableElementImpl extends FunctionTypedElementImpl
    with InternalExecutableElement, DeferredResolutionReadingMixin {
  TypeImpl? _returnType;
  FunctionTypeImpl? _type;

  @override
  ExecutableElementImpl get baseElement => this;

  @override
  List<Element> get children => [
    ...super.children,
    ...typeParameters,
    ...formalParameters,
  ];

  @Deprecated('Use children instead')
  @override
  List<Element> get children2 => children;

  @override
  ExecutableFragmentImpl get firstFragment;

  @override
  List<FormalParameterElementImpl> get formalParameters {
    _ensureReadResolution();
    return firstFragment.formalParameters
        .map((fragment) => fragment.asElement2)
        .toList();
  }

  @override
  List<ExecutableFragmentImpl> get fragments;

  /// Whether the type of this element references a type parameter of the
  /// enclosing element. This includes not only explicitly specified type
  /// annotations, but also inferred types.
  ///
  /// Top-level declarations don't have enclosing element type parameters,
  /// so for them this flag is always `false`.
  bool get hasEnclosingTypeParameterReference {
    var firstFragment = this.firstFragment;
    return firstFragment.hasEnclosingTypeParameterReference;
  }

  @override
  bool get hasImplicitReturnType {
    for (var fragment in fragments) {
      if (!fragment.hasImplicitReturnType) {
        return false;
      }
    }
    return true;
  }

  bool get invokesSuperSelf {
    var firstFragment = this.firstFragment;
    return firstFragment.hasModifier(Modifier.INVOKES_SUPER_SELF);
  }

  @override
  bool get isAbstract {
    for (var fragment in fragments) {
      if (!fragment.isAbstract) {
        return false;
      }
    }
    return true;
  }

  @override
  bool get isExtensionTypeMember {
    return hasModifier(Modifier.EXTENSION_TYPE_MEMBER);
  }

  set isExtensionTypeMember(bool value) {
    setModifier(Modifier.EXTENSION_TYPE_MEMBER, value);
  }

  @override
  bool get isExternal {
    return firstFragment.isExternal;
  }

  @override
  bool get isSimplyBounded {
    return firstFragment.isSimplyBounded;
  }

  @override
  bool get isStatic {
    return firstFragment.isStatic;
  }

  @override
  bool get isSynthetic {
    return firstFragment.isSynthetic;
  }

  ExecutableFragmentImpl get lastFragment {
    var result = firstFragment;
    while (true) {
      if (result.nextFragment case ExecutableFragmentImpl nextFragment) {
        result = nextFragment;
      } else {
        return result;
      }
    }
  }

  @Deprecated('Use library instead')
  @override
  LibraryElement get library2 => library;

  @override
  MetadataImpl get metadata {
    var annotations = <ElementAnnotationImpl>[];
    for (var fragment in fragments) {
      annotations.addAll(fragment.metadata.annotations);
    }
    return MetadataImpl(annotations);
  }

  @Deprecated('Use metadata instead')
  @override
  MetadataImpl get metadata2 => metadata;

  @override
  TypeImpl get returnType {
    _ensureReadResolution();

    // If a synthetic getter, we might need to infer the type.
    if (_returnType == null && isSynthetic) {
      if (this case GetterElementImpl thisGetter) {
        thisGetter.variable.type;
      } else if (this case SetterElementImpl thisSetter) {
        thisSetter.variable.type;
      }
    }

    return _returnType!;
  }

  set returnType(TypeImpl value) {
    _returnType = value;
    // We do this because of return type inference. At the moment when we
    // create a local function element we don't know yet its return type,
    // because we have not done static type analysis yet.
    // It somewhere it between we access the type of this element, so it gets
    // cached in the element. When we are done static type analysis, we then
    // should clear this cached type to make it right.
    // TODO(scheglov): Remove when type analysis is done in the single pass.
    _type = null;
  }

  @override
  FunctionTypeImpl get type {
    return _type ??= FunctionTypeImpl(
      typeParameters: typeParameters,
      parameters: formalParameters,
      returnType: returnType,
      nullabilitySuffix: NullabilitySuffix.none,
    );
  }

  @override
  List<TypeParameterElementImpl> get typeParameters {
    return firstFragment.typeParameters
        .map((fragment) => fragment.element)
        .toList();
  }

  @Deprecated('Use typeParameters instead')
  @override
  List<TypeParameterElementImpl> get typeParameters2 {
    return typeParameters;
  }

  @override
  void appendTo(ElementDisplayStringBuilder builder) {
    builder.writeExecutableElement(this, name!);
  }
}

@GenerateFragmentImpl(modifiers: _ExecutableFragmentImplModifiers.values)
abstract class ExecutableFragmentImpl extends FragmentImpl
    with
        DeferredResolutionReadingMixin,
        TypeParameterizedFragmentMixin,
        _ExecutableFragmentImplMixin
    implements ExecutableFragment {
  /// A list containing all of the parameters defined by this executable
  /// element.
  List<FormalParameterFragmentImpl> _formalParameters = const [];

  /// Initialize a newly created executable element to have the given [name] and
  /// [offset].
  ExecutableFragmentImpl({super.firstTokenOffset});

  @override
  List<Fragment> get children => [...typeParameters, ...formalParameters];

  @Deprecated('Use children instead')
  @override
  List<Fragment> get children3 => children;

  @override
  ExecutableFragmentImpl get declaration => this;

  @override
  ExecutableElementImpl get element;

  @override
  FragmentImpl get enclosingFragment {
    return super.enclosingFragment!;
  }

  @override
  List<FormalParameterFragmentImpl> get formalParameters {
    _ensureReadResolution();
    return _formalParameters;
  }

  set formalParameters(List<FormalParameterFragmentImpl> formalParameters) {
    for (var formalParameter in formalParameters) {
      formalParameter.enclosingFragment = this;
    }
    _formalParameters = formalParameters;
  }

  /// Whether the type of this fragment references a type parameter of the
  /// enclosing element. This includes not only explicitly specified type
  /// annotations, but also inferred types.
  bool get hasEnclosingTypeParameterReference {
    return !hasModifier(Modifier.NO_ENCLOSING_TYPE_PARAMETER_REFERENCE);
  }

  set hasEnclosingTypeParameterReference(bool value) {
    setModifier(Modifier.NO_ENCLOSING_TYPE_PARAMETER_REFERENCE, !value);
  }

  /// Whether the executable element is an operator.
  ///
  /// The test may be based on the name of the executable element, in which
  /// case the result will be correct when the name is legal.
  bool get isOperator => false;

  @override
  bool get isSynchronous => !isAsynchronous;

  @override
  MetadataImpl get metadata {
    _ensureReadResolution();
    return super.metadata;
  }

  @override
  int get offset => nameOffset ?? firstTokenOffset!;
}

class ExtensionElementImpl extends InstanceElementImpl
    implements ExtensionElement {
  @override
  final Reference reference;

  @override
  final ExtensionFragmentImpl firstFragment;

  TypeImpl _extendedType = InvalidTypeImpl.instance;

  ExtensionElementImpl(this.reference, this.firstFragment) {
    reference.element = this;
    firstFragment.element = this;
  }

  @override
  TypeImpl get extendedType {
    _ensureReadResolution();
    return _extendedType;
  }

  set extendedType(TypeImpl value) {
    _extendedType = value;
  }

  @override
  List<ExtensionFragmentImpl> get fragments {
    return [
      for (
        ExtensionFragmentImpl? fragment = firstFragment;
        fragment != null;
        fragment = fragment.nextFragment
      )
        fragment,
    ];
  }

  @override
  ElementKind get kind => ElementKind.EXTENSION;

  @override
  DartType get thisType => extendedType;

  @override
  T? accept<T>(ElementVisitor2<T> visitor) {
    return visitor.visitExtensionElement(this);
  }

  @Deprecated('Use accept instead')
  @override
  T? accept2<T>(ElementVisitor2<T> visitor) => accept(visitor);

  @override
  void appendTo(ElementDisplayStringBuilder builder) {
    builder.writeExtensionElement(this);
  }

  void linkFragments(List<ExtensionFragmentImpl> fragments) {
    assert(identical(fragments[0], firstFragment));
    fragments.reduce((previous, current) {
      previous.addFragment(current);
      return current;
    });
  }
}

class ExtensionFragmentImpl extends InstanceFragmentImpl
    implements ExtensionFragment {
  @override
  late final ExtensionElementImpl element;

  /// Initialize a newly created extension element to have the given [name] at
  /// the given [nameOffset] in the file that contains the declaration of this
  /// element.
  ExtensionFragmentImpl({required super.name});

  @override
  List<Fragment> get children => [
    ...fields,
    ...getters,
    ...methods,
    ...setters,
    ...typeParameters,
  ];

  @Deprecated('Use children instead')
  @override
  List<Fragment> get children3 => children;

  @override
  String get displayName => name ?? '';

  TypeImpl get extendedType {
    return element.extendedType;
  }

  @override
  bool get isPrivate {
    var name = this.name;
    return name == null || Identifier.isPrivateName(name);
  }

  @override
  bool get isSimplyBounded => true;

  @override
  MetadataImpl get metadata {
    _ensureReadResolution();
    return super.metadata;
  }

  @override
  ExtensionFragmentImpl? get nextFragment =>
      super.nextFragment as ExtensionFragmentImpl?;

  @override
  ExtensionFragmentImpl? get previousFragment =>
      super.previousFragment as ExtensionFragmentImpl?;

  void addFragment(ExtensionFragmentImpl fragment) {
    fragment.element = element;
    fragment.previousFragment = this;
    nextFragment = fragment;
  }
}

class ExtensionTypeElementImpl extends InterfaceElementImpl
    implements ExtensionTypeElement {
  @override
  final Reference reference;

  @override
  final ExtensionTypeFragmentImpl firstFragment;

  ExtensionTypeElementImpl(this.reference, this.firstFragment) {
    reference.element = this;
    firstFragment.element = this;
  }

  @override
  List<ExtensionTypeFragmentImpl> get fragments {
    return [
      for (
        ExtensionTypeFragmentImpl? fragment = firstFragment;
        fragment != null;
        fragment = fragment.nextFragment
      )
        fragment,
    ];
  }

  /// Whether the element has direct or indirect reference to itself,
  /// in implemented superinterfaces.
  bool get hasImplementsSelfReference {
    return firstFragment.hasImplementsSelfReference;
  }

  /// Whether the element has direct or indirect reference to itself,
  /// in implemented superinterfaces.
  set hasImplementsSelfReference(bool value) {
    firstFragment.hasImplementsSelfReference = value;
  }

  /// Whether the element has direct or indirect reference to itself,
  /// in representation.
  bool get hasRepresentationSelfReference {
    return firstFragment.hasRepresentationSelfReference;
  }

  /// Whether the element has direct or indirect reference to itself,
  /// in representation.
  set hasRepresentationSelfReference(bool value) {
    firstFragment.hasRepresentationSelfReference = value;
  }

  @override
  ElementKind get kind => ElementKind.EXTENSION_TYPE;

  @override
  ConstructorElement get primaryConstructor {
    return firstFragment.primaryConstructor.element;
  }

  @Deprecated('Use primaryConstructor instead')
  @override
  ConstructorElement get primaryConstructor2 {
    return primaryConstructor;
  }

  @override
  FieldElementImpl get representation {
    return firstFragment.representation.element;
  }

  @Deprecated('Use representation instead')
  @override
  FieldElementImpl get representation2 {
    return representation;
  }

  @override
  DartType get typeErasure => firstFragment.typeErasure;

  @override
  T? accept<T>(ElementVisitor2<T> visitor) {
    return visitor.visitExtensionTypeElement(this);
  }

  @Deprecated('Use accept instead')
  @override
  T? accept2<T>(ElementVisitor2<T> visitor) => accept(visitor);

  @override
  void appendTo(ElementDisplayStringBuilder builder) {
    builder.writeExtensionTypeElement(this);
  }

  void linkFragments(List<ExtensionTypeFragmentImpl> fragments) {
    assert(identical(fragments[0], firstFragment));
    fragments.reduce((previous, current) {
      previous.addFragment(current);
      return current;
    });
  }
}

class ExtensionTypeFragmentImpl extends InterfaceFragmentImpl
    implements ExtensionTypeFragment {
  @override
  late final ExtensionTypeElementImpl element;

  late DartType typeErasure;

  /// Whether the element has direct or indirect reference to itself,
  /// in representation.
  bool hasRepresentationSelfReference = false;

  /// Whether the element has direct or indirect reference to itself,
  /// in implemented superinterfaces.
  bool hasImplementsSelfReference = false;

  ExtensionTypeFragmentImpl({required super.name});

  @override
  ExtensionTypeFragmentImpl? get nextFragment =>
      super.nextFragment as ExtensionTypeFragmentImpl?;

  @override
  ExtensionTypeFragmentImpl? get previousFragment =>
      super.previousFragment as ExtensionTypeFragmentImpl?;

  @override
  ConstructorFragmentImpl get primaryConstructor {
    return constructors.first;
  }

  @Deprecated('Use primaryConstructor instead')
  @override
  ConstructorFragmentImpl get primaryConstructor2 => primaryConstructor;

  @override
  FieldFragmentImpl get representation {
    return fields.first;
  }

  @Deprecated('Use representation instead')
  @override
  FieldFragmentImpl get representation2 => representation;

  void addFragment(ExtensionTypeFragmentImpl fragment) {
    fragment.element = element;
    fragment.previousFragment = this;
    nextFragment = fragment;
  }
}

class FieldElementImpl extends PropertyInducingElementImpl
    with InternalFieldElement {
  @override
  final Reference reference;

  @override
  final FieldFragmentImpl firstFragment;

  FieldElementImpl({required this.reference, required this.firstFragment}) {
    reference.element = this;
    firstFragment.element = this;
  }

  @override
  FieldElementImpl get baseElement => this;

  @override
  InstanceElementImpl get enclosingElement {
    return firstFragment.enclosingFragment.element;
  }

  @Deprecated('Use enclosingElement instead')
  @override
  InstanceElement get enclosingElement2 => enclosingElement;

  @override
  List<FieldFragmentImpl> get fragments {
    return [
      for (
        FieldFragmentImpl? fragment = firstFragment;
        fragment != null;
        fragment = fragment.nextFragment
      )
        fragment,
    ];
  }

  @override
  GetterElementImpl? get getter {
    globalResultRequirements?.record_fieldElement_getter(
      element: this,
      name: name,
    );

    return super.getter;
  }

  /// Whether the type of this fragment references a type parameter of the
  /// enclosing element. This includes not only explicitly specified type
  /// annotations, but also inferred types.
  bool get hasEnclosingTypeParameterReference {
    return firstFragment.hasEnclosingTypeParameterReference;
  }

  @override
  bool get hasImplicitType => firstFragment.hasImplicitType;

  @override
  bool get isAbstract => firstFragment.isAbstract;

  @override
  bool get isConst => firstFragment.isConst;

  @override
  bool get isCovariant => firstFragment.isExplicitlyCovariant;

  @override
  bool get isEnumConstant => firstFragment.isEnumConstant;

  bool get isEnumValues {
    return enclosingElement is EnumElementImpl && name == 'values';
  }

  @override
  bool get isExternal => firstFragment.isExternal;

  @override
  bool get isFinal => firstFragment.isFinal;

  @override
  bool get isLate => firstFragment.isLate;

  @override
  bool get isPromotable => firstFragment.isPromotable;

  @override
  bool get isStatic => firstFragment.isStatic;

  @override
  bool get isSynthetic => firstFragment.isSynthetic;

  /// Return `true` if this element is a synthetic enum field.
  ///
  /// It is synthetic because it is not written explicitly in code, but it
  /// is different from other synthetic fields, because its getter is also
  /// synthetic.
  ///
  /// Such fields are `index`, `_name`, and `values`.
  bool get isSyntheticEnumField {
    return enclosingElement is EnumElementImpl &&
        isSynthetic &&
        getter?.isSynthetic == true &&
        setter == null;
  }

  @override
  ElementKind get kind => ElementKind.FIELD;

  @Deprecated('Use library instead')
  @override
  LibraryElementImpl get library2 => library;

  @override
  MetadataImpl get metadata {
    var annotations = <ElementAnnotationImpl>[];
    for (var fragment in fragments) {
      annotations.addAll(fragment.metadata.annotations);
    }
    return MetadataImpl(annotations);
  }

  @Deprecated('Use metadata instead')
  @override
  MetadataImpl get metadata2 => metadata;

  @override
  String? get name => firstFragment.name;

  @Deprecated('Use name instead')
  @override
  String? get name3 => name;

  @override
  SetterElementImpl? get setter {
    globalResultRequirements?.record_fieldElement_setter(
      element: this,
      name: name,
    );

    return super.setter;
  }

  @override
  List<FieldFragmentImpl> get _fragments => fragments;

  @override
  T? accept<T>(ElementVisitor2<T> visitor) {
    return visitor.visitFieldElement(this);
  }

  @Deprecated('Use accept instead')
  @override
  T? accept2<T>(ElementVisitor2<T> visitor) => accept(visitor);

  void linkFragments(List<FieldFragmentImpl> fragments) {
    assert(identical(fragments[0], firstFragment));
    fragments.reduce((previous, current) {
      previous.addFragment(current);
      return current;
    });
  }
}

class FieldFormalParameterElementImpl extends FormalParameterElementImpl
    implements FieldFormalParameterElement {
  FieldFormalParameterElementImpl(super.firstFragment);

  @override
  FieldElementImpl? get field => switch (firstFragment) {
    FieldFormalParameterFragmentImpl(:FieldFragmentImpl field) => field.element,
    _ => null,
  };

  @Deprecated('Use field instead')
  @override
  FieldElementImpl? get field2 => field;

  @override
  FieldFormalParameterFragmentImpl get firstFragment =>
      super.firstFragment as FieldFormalParameterFragmentImpl;

  @override
  List<FieldFormalParameterFragmentImpl> get fragments {
    return [
      for (
        FieldFormalParameterFragmentImpl? fragment = firstFragment;
        fragment != null;
        fragment = fragment.nextFragment
      )
        fragment,
    ];
  }
}

class FieldFormalParameterFragmentImpl extends FormalParameterFragmentImpl
    implements FieldFormalParameterFragment {
  /// The field element associated with this field formal parameter, or `null`
  /// if the parameter references a field that doesn't exist.
  // TODO(scheglov): move to element
  FieldFragmentImpl? field;

  /// Initialize a newly created parameter element to have the given [name] and
  /// [nameOffset].
  FieldFormalParameterFragmentImpl({
    super.firstTokenOffset,
    required super.name,
    required super.nameOffset,
    required super.parameterKind,
  });

  @override
  FieldFormalParameterElementImpl get element =>
      super.element as FieldFormalParameterElementImpl;

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
  FieldFormalParameterFragmentImpl? get nextFragment =>
      super.nextFragment as FieldFormalParameterFragmentImpl?;

  @override
  FieldFormalParameterFragmentImpl? get previousFragment =>
      super.previousFragment as FieldFormalParameterFragmentImpl?;

  @override
  FieldFormalParameterElementImpl _createElement(
    FormalParameterFragment firstFragment,
  ) => FieldFormalParameterElementImpl(
    firstFragment as FormalParameterFragmentImpl,
  );
}

@GenerateFragmentImpl(modifiers: _FieldFragmentImplModifiers.values)
class FieldFragmentImpl extends PropertyInducingFragmentImpl
    with _FieldFragmentImplMixin
    implements FieldFragment {
  /// True if this field inherits from a covariant parameter. This happens
  /// when it overrides a field in a supertype that is covariant.
  bool inheritsCovariant = false;

  @override
  late final FieldElementImpl element;

  /// Initialize a newly created synthetic field element to have the given
  /// [name] at the given [offset].
  FieldFragmentImpl({required super.name});

  @override
  ExpressionImpl? get constantInitializer {
    _ensureReadResolution();
    return super.constantInitializer;
  }

  @override
  FieldFragmentImpl get declaration => this;

  @override
  InstanceFragmentImpl get enclosingFragment {
    return super.enclosingFragment as InstanceFragmentImpl;
  }

  /// Whether the type of this fragment references a type parameter of the
  /// enclosing element. This includes not only explicitly specified type
  /// annotations, but also inferred types.
  bool get hasEnclosingTypeParameterReference {
    return !hasModifier(Modifier.NO_ENCLOSING_TYPE_PARAMETER_REFERENCE);
  }

  set hasEnclosingTypeParameterReference(bool value) {
    setModifier(Modifier.NO_ENCLOSING_TYPE_PARAMETER_REFERENCE, !value);
  }

  @override
  MetadataImpl get metadata {
    _ensureReadResolution();
    return super.metadata;
  }

  @override
  FieldFragmentImpl? get nextFragment =>
      super.nextFragment as FieldFragmentImpl?;

  @override
  int get offset => nameOffset ?? firstTokenOffset ?? enclosingFragment.offset;

  @override
  FieldFragmentImpl? get previousFragment =>
      super.previousFragment as FieldFragmentImpl?;

  void addFragment(FieldFragmentImpl fragment) {
    fragment.element = element;
    fragment.previousFragment = this;
    nextFragment = fragment;
  }
}

class FormalParameterElementImpl extends PromotableElementImpl
    with InternalFormalParameterElement {
  final FormalParameterFragmentImpl wrappedElement;

  @override
  TypeImpl type = InvalidTypeImpl.instance;

  /// Whether this formal parameter inherits from a covariant formal parameter.
  /// This happens when it overrides a method in a supertype that has a
  /// corresponding covariant formal parameter.
  bool inheritsCovariant = false;

  FormalParameterElementImpl(this.wrappedElement) {
    FormalParameterFragmentImpl? fragment = wrappedElement;
    while (fragment != null) {
      fragment.element = this;
      fragment = fragment.nextFragment;
    }
  }

  /// Creates a synthetic parameter with [name], [type] and [parameterKind].
  factory FormalParameterElementImpl.synthetic(
    String? name,
    TypeImpl type,
    ParameterKind parameterKind,
  ) {
    var fragment = FormalParameterFragmentImpl.synthetic(name, parameterKind);
    return FormalParameterElementImpl(fragment)..type = type;
  }

  @override
  FormalParameterElementImpl get baseElement => this;

  @override
  // TODO(augmentations): Implement the merge of formal parameters.
  String? get defaultValueCode {
    return constantInitializer2?.expression.toSource();
  }

  @override
  Element? get enclosingElement {
    return wrappedElement.enclosingFragment?.element;
  }

  @Deprecated('Use enclosingElement instead')
  @override
  Element? get enclosingElement2 => enclosingElement;

  @override
  FormalParameterFragmentImpl get firstFragment => wrappedElement;

  @override
  // TODO(augmentations): Implement the merge of formal parameters.
  List<FormalParameterElementImpl> get formalParameters =>
      wrappedElement.formalParameters
          .map((fragment) => fragment.element)
          .toList();

  @override
  List<FormalParameterFragmentImpl> get fragments {
    return [
      for (
        FormalParameterFragmentImpl? fragment = firstFragment;
        fragment != null;
        fragment = fragment.nextFragment
      )
        fragment,
    ];
  }

  @override
  // TODO(augmentations): Implement the merge of formal parameters.
  bool get hasDefaultValue => defaultValueCode != null;

  @override
  // TODO(augmentations): Implement the merge of formal parameters.
  bool get hasImplicitType => wrappedElement.hasImplicitType;

  @override
  // TODO(augmentations): Implement the merge of formal parameters.
  bool get isConst => wrappedElement.isConst;

  @override
  bool get isCovariant {
    if (firstFragment.isExplicitlyCovariant || inheritsCovariant) {
      return true;
    }
    return false;
  }

  @override
  // TODO(augmentations): Implement the merge of formal parameters.
  bool get isFinal => wrappedElement.isFinal;

  @override
  bool get isInitializingFormal => wrappedElement.isInitializingFormal;

  @override
  // TODO(augmentations): Implement the merge of formal parameters.
  bool get isLate => wrappedElement.isLate;

  @override
  bool get isNamed => wrappedElement.isNamed;

  @override
  bool get isOptional => wrappedElement.isOptional;

  @override
  bool get isOptionalNamed => wrappedElement.isOptionalNamed;

  @override
  bool get isOptionalPositional => wrappedElement.isOptionalPositional;

  @override
  bool get isPositional => wrappedElement.isPositional;

  @override
  bool get isRequired => wrappedElement.isRequired;

  @override
  bool get isRequiredNamed => wrappedElement.isRequiredNamed;

  @override
  bool get isRequiredPositional => wrappedElement.isRequiredPositional;

  @override
  // TODO(augmentations): Implement the merge of formal parameters.
  bool get isStatic => wrappedElement.isStatic;

  @override
  // TODO(augmentations): Implement the merge of formal parameters.
  bool get isSuperFormal => wrappedElement.isSuperFormal;

  @override
  bool get isSynthetic {
    return firstFragment.isSynthetic;
  }

  @override
  ElementKind get kind => ElementKind.PARAMETER;

  @Deprecated('Use library instead')
  @override
  LibraryElementImpl? get library2 => library;

  @override
  MetadataImpl get metadata {
    var annotations = <ElementAnnotationImpl>[];
    for (var fragment in fragments) {
      annotations.addAll(fragment.metadata.annotations);
    }
    return MetadataImpl(annotations);
  }

  @Deprecated('Use metadata instead')
  @override
  MetadataImpl get metadata2 => metadata;

  @override
  String? get name {
    return wrappedElement.name;
  }

  @Deprecated('Use name instead')
  @override
  String? get name3 {
    return name;
  }

  @override
  String get nameShared => wrappedElement.name ?? '';

  @override
  ParameterKind get parameterKind {
    return firstFragment.parameterKind;
  }

  @override
  // TODO(augmentations): Implement the merge of formal parameters.
  List<TypeParameterElementImpl> get typeParameters =>
      firstFragment.typeParameters.map((fragment) => fragment.element).toList();

  @Deprecated('Use typeParameters instead')
  @override
  // TODO(augmentations): Implement the merge of formal parameters.
  List<TypeParameterElementImpl> get typeParameters2 => typeParameters;

  @override
  TypeImpl get typeShared => type;

  @override
  T? accept<T>(ElementVisitor2<T> visitor) {
    return visitor.visitFormalParameterElement(this);
  }

  @Deprecated('Use accept instead')
  @override
  T? accept2<T>(ElementVisitor2<T> visitor) => accept(visitor);

  @override
  void appendTo(ElementDisplayStringBuilder builder) {
    builder.writeFormalParameterElement(this);
  }

  @override
  void visitChildren<T>(ElementVisitor2<T> visitor) {
    for (var child in children) {
      child.accept(visitor);
    }
  }

  // firstFragment.typeParameters
  //     .map((fragment) => (fragment as TypeParameterElementImpl).element)
  //     .toList();
}

@GenerateFragmentImpl(modifiers: _FormalParameterFragmentImplModifiers.values)
class FormalParameterFragmentImpl extends VariableFragmentImpl
    with _FormalParameterFragmentImplMixin
    implements FormalParameterFragment {
  @override
  final String? name;

  @override
  int? nameOffset;

  /// A list containing all of the parameters defined by this parameter element.
  /// There will only be parameters if this parameter is a function typed
  /// parameter.
  List<FormalParameterFragmentImpl> _formalParameters = const [];

  /// A list containing all of the type parameters defined for this parameter
  /// element. There will only be parameters if this parameter is a function
  /// typed parameter.
  List<TypeParameterFragmentImpl> _typeParameters = const [];

  /// The kind of a parameter. A parameter can be either positional or named, and
  /// can be either required or optional.
  ///
  /// Prefer using `isXyz` instead, e.g. [isRequiredNamed].
  final ParameterKind parameterKind;

  /// The element corresponding to this fragment.
  FormalParameterElementImpl? _element;

  /// Initialize a newly created parameter element to have the given [name] and
  /// [nameOffset].
  FormalParameterFragmentImpl({
    super.firstTokenOffset,
    required this.name,
    required this.nameOffset,
    required this.parameterKind,
  }) : assert(nameOffset == null || nameOffset >= 0),
       assert(name == null || name.isNotEmpty);

  /// Creates a synthetic parameter with [name2], [type] and [parameterKind].
  factory FormalParameterFragmentImpl.synthetic(
    String? name2,
    ParameterKind parameterKind,
  ) {
    // TODO(dantup): This does not keep any reference to the non-synthetic
    //  parameter which prevents navigation/references from working. See
    //  https://github.com/dart-lang/sdk/issues/60200
    var element = FormalParameterFragmentImpl(
      name: name2,
      nameOffset: null,
      parameterKind: parameterKind,
    );
    element.isSynthetic = true;
    return element;
  }

  @override
  List<Fragment> get children => const [];

  @Deprecated('Use children instead')
  @override
  List<Fragment> get children3 => children;

  @override
  FormalParameterFragmentImpl get declaration => this;

  @override
  FormalParameterElementImpl get element {
    if (_element != null) {
      return _element!;
    }
    FormalParameterFragment firstFragment = this;
    var previousFragment = firstFragment.previousFragment;
    while (previousFragment != null) {
      firstFragment = previousFragment;
      previousFragment = firstFragment.previousFragment;
    }
    // As a side-effect of creating the element, all of the fragments in the
    // chain will have their `_element` set to the newly created element.
    return _createElement(firstFragment);
  }

  set element(FormalParameterElementImpl element) => _element = element;

  /// The parameters defined by this parameter.
  ///
  /// A parameter will only define other parameters if it is a function typed
  /// parameter.
  List<FormalParameterFragmentImpl> get formalParameters {
    return _formalParameters;
  }

  /// Set the parameters defined by this executable element to the given
  /// [value].
  set formalParameters(List<FormalParameterFragmentImpl> value) {
    for (var formalParameter in value) {
      formalParameter.enclosingFragment = this;
    }
    _formalParameters = value;
  }

  /// Whether the parameter is an initializing formal parameter.
  bool get isInitializingFormal => false;

  /// Whether the parameter is a named parameter.
  ///
  /// Named parameters that are annotated with the `@required` annotation are
  /// considered optional. Named parameters that are annotated with the
  /// `required` syntax are considered required.
  bool get isNamed => parameterKind.isNamed;

  /// Whether the parameter is an optional parameter.
  ///
  /// Optional parameters can either be positional or named. Named parameters
  /// that are annotated with the `@required` annotation are considered
  /// optional. Named parameters that are annotated with the `required` syntax
  /// are considered required.
  bool get isOptional => parameterKind.isOptional;

  /// Whether the parameter is both an optional and named parameter.
  ///
  /// Named parameters that are annotated with the `@required` annotation are
  /// considered optional. Named parameters that are annotated with the
  /// `required` syntax are considered required.
  bool get isOptionalNamed => parameterKind.isOptionalNamed;

  /// Whether the parameter is both an optional and positional parameter.
  bool get isOptionalPositional => parameterKind.isOptionalPositional;

  /// Whether the parameter is a positional parameter.
  ///
  /// Positional parameters can either be required or optional.
  bool get isPositional => parameterKind.isPositional;

  /// Whether the parameter is either a required positional parameter, or a
  /// named parameter with the `required` keyword.
  ///
  /// Note: the presence or absence of the `@required` annotation does not
  /// change the meaning of this getter. The parameter `{@required int x}`
  /// will return `false` and the parameter `{@required required int x}`
  /// will return `true`.
  bool get isRequired => parameterKind.isRequired;

  /// Whether the parameter is both a required and named parameter.
  ///
  /// Named parameters that are annotated with the `@required` annotation are
  /// considered optional. Named parameters that are annotated with the
  /// `required` syntax are considered required.
  bool get isRequiredNamed => parameterKind.isRequiredNamed;

  /// Whether the parameter is both a required and positional parameter.
  bool get isRequiredPositional => parameterKind.isRequiredPositional;

  /// Whether the parameter is a super formal parameter.
  bool get isSuperFormal => false;

  @override
  LibraryFragment? get libraryFragment {
    return enclosingFragment?.libraryFragment;
  }

  @Deprecated('Use metadata instead')
  @override
  MetadataImpl get metadata2 => metadata;

  @Deprecated('Use name instead')
  @override
  String? get name2 => name;

  @override
  // TODO(augmentations): Support chaining between the fragments.
  FormalParameterFragmentImpl? get nextFragment => null;

  @override
  // TODO(augmentations): Support chaining between the fragments.
  FormalParameterFragmentImpl? get previousFragment => null;

  /// The type parameters defined by this parameter.
  ///
  /// A parameter will only define type parameters if it is a function typed
  /// parameter.
  List<TypeParameterFragmentImpl> get typeParameters {
    return _typeParameters;
  }

  /// Set the type parameters defined by this parameter element to the given
  /// [typeParameters].
  set typeParameters(List<TypeParameterFragmentImpl> typeParameters) {
    for (var parameter in typeParameters) {
      parameter.enclosingFragment = this;
    }
    _typeParameters = typeParameters;
  }

  FormalParameterElementImpl _createElement(
    FormalParameterFragment firstFragment,
  ) => FormalParameterElementImpl(firstFragment as FormalParameterFragmentImpl);
}

@GenerateFragmentImpl(modifiers: _FragmentImplModifiers.values)
abstract class FragmentImpl with _FragmentImplMixin implements Fragment {
  static int _NEXT_ID = 0;

  /// The unique integer identifier of this fragment.
  final int id = _NEXT_ID++;

  /// The element that either physically or logically encloses this element.
  ///
  /// For [LibraryElement] returns `null`, because libraries are the top-level
  /// elements in the model.
  ///
  /// For [CompilationUnitElement] returns the [CompilationUnitElement] that
  /// uses `part` directive to include this element, or `null` if this element
  /// is the defining unit of the library.
  @override
  FragmentImpl? enclosingFragment;

  /// The offset of the first token of the declaration of this fragment,
  /// or `null` if this fragment is synthetic.
  int? firstTokenOffset;

  /// The modifiers associated with this element.
  EnumSet<Modifier> _modifiers = EnumSet.empty();

  @override
  String? documentationComment;

  @override
  MetadataImpl metadata = MetadataImpl.empty;

  /// The offset of the beginning of the element's code in the file that
  /// contains the element, or `null` if the element is synthetic.
  int? _codeOffset;

  /// The length of the element's code, or `null` if the element is synthetic.
  int? _codeLength;

  /// Initialize a newly created element to have the given [name] at the given
  /// [_nameOffset].
  FragmentImpl({this.firstTokenOffset});

  /// The length of the element's code, or `null` if the element is synthetic.
  int? get codeLength => _codeLength;

  /// The offset of the beginning of the element's code in the file that
  /// contains the element, or `null` if the element is synthetic.
  int? get codeOffset => _codeOffset;

  /// The declaration of this element.
  ///
  /// If the element is a view on an element, e.g. a method from an interface
  /// type, with substituted type parameters, return the corresponding element
  /// from the class, without any substitutions. If this element is already a
  /// declaration (or a synthetic element, e.g. a synthetic property accessor),
  /// return itself.
  FragmentImpl get declaration => this;

  /// The display name of this element, possibly the empty string if the
  /// element does not have a name.
  ///
  /// In most cases the name and the display name are the same. Differences
  /// though are cases such as setters where the name of some setter `set f(x)`
  /// is `f=`, instead of `f`.
  String get displayName => name ?? '';

  /// Return the enclosing unit element (which might be the same as `this`), or
  /// `null` if this element is not contained in any compilation unit.
  LibraryFragmentImpl get enclosingUnit {
    return enclosingFragment!.enclosingUnit;
  }

  /// Whether the element is private.
  ///
  /// Private elements are visible only within the library in which they are
  /// declared.
  bool get isPrivate {
    var name = this.name;
    if (name == null) {
      return false;
    }
    return Identifier.isPrivateName(name);
  }

  /// Whether the element is public.
  ///
  /// Public elements are visible within any library that imports the library
  /// in which they are declared.
  bool get isPublic => !isPrivate;

  String? get lookupName {
    return name;
  }

  @Deprecated('Use name instead')
  @override
  String? get name2 => name;

  /// The offset after the last character of the name, or `null` if there is
  /// no declaration in code for this fragment, or the name is absent.
  int? get nameEnd {
    if (nameOffset case var nameOffset?) {
      if (name case var name?) {
        return nameOffset + name.length;
      }
    }
    return null;
  }

  @override
  @Deprecated('Use nameOffset instead')
  int? get nameOffset2 => nameOffset;

  /// The analysis session in which this element is defined.
  AnalysisSession? get session {
    return enclosingFragment?.session;
  }

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
  Version? get sinceSdkVersion {
    return asElement2?.sinceSdkVersion;
  }

  /// Whether to include the [nameOffset] in [identifier] to disambiguate
  /// elements that might otherwise have the same identifier.
  bool get _includeNameOffsetInIdentifier {
    return false;
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other);
  }

  /// Set this element as the enclosing element for given [element].
  void encloseElement(FragmentImpl element) {
    element.enclosingFragment = this;
  }

  /// Set this element as the enclosing element for given [elements].
  void encloseElements(List<FragmentImpl> elements) {
    for (var element in elements) {
      element.enclosingFragment = this;
    }
  }

  /// Return `true` if this element has the given [modifier] associated with it.
  @override
  bool hasModifier(Modifier modifier) => _modifiers[modifier];

  void readModifiers(SummaryDataReader reader) {
    _modifiers = EnumSet.read(reader);
  }

  /// Set the code range for this element.
  void setCodeRange(int offset, int length) {
    _codeOffset = offset;
    _codeLength = length;
  }

  /// Set whether the given [modifier] is associated with this element to
  /// correspond to the given [value].
  @override
  void setModifier(Modifier modifier, bool value) {
    _modifiers = _modifiers.updated(modifier, value);
  }

  @override
  String toString() {
    return "fragmentOf: $element";
  }

  void writeModifiers(BufferedSink writer) {
    _modifiers.write(writer);
  }
}

sealed class FunctionFragmentImpl extends ExecutableFragmentImpl
    implements FunctionTypedFragmentImpl {
  @override
  final String? name;

  @override
  int? nameOffset;

  /// Initialize a newly created function element to have the given [name] and
  /// [offset].
  FunctionFragmentImpl({required this.name, super.firstTokenOffset});

  @override
  ExecutableFragmentImpl get declaration => this;
}

abstract class FunctionTypedElementImpl extends ElementImpl
    implements FunctionTypedElement {
  @override
  LibraryElementImpl get library => super.library!;

  @override
  void visitChildren<T>(ElementVisitor2<T> visitor) {
    for (var child in children) {
      child.accept(visitor);
    }
  }
}

/// Common internal interface shared by elements whose type is a function type.
///
/// Clients may not extend, implement or mix-in this class.
abstract class FunctionTypedFragmentImpl implements FragmentImpl {
  /// The parameters defined by this executable element.
  List<FormalParameterFragmentImpl> get formalParameters;

  /// The type parameters declared by this element directly.
  ///
  /// This does not include type parameters that are declared by any enclosing
  /// elements.
  List<TypeParameterFragmentImpl> get typeParameters;
}

class GenerateFragmentImpl {
  /// Modifiers to generate in the annotated class.
  ///
  /// Should be a companion enum to reuse Dart syntax, and allow attaching
  /// optional documentation comments. Theoretically it could be a type
  /// literal, but then each enum constant is marked as unused, so we
  /// use `_MyModifiersEnum.values` instead.
  final List<Enum> modifiers;

  const GenerateFragmentImpl({required this.modifiers});
}

/// The element used for a generic function type.
///
/// Clients may not extend, implement or mix-in this class.
class GenericFunctionTypeElementImpl extends FunctionTypedElementImpl
    implements GenericFunctionTypeElement {
  final GenericFunctionTypeFragmentImpl _wrappedElement;

  GenericFunctionTypeElementImpl(this._wrappedElement);

  @override
  String? get documentationComment => _wrappedElement.documentationComment;

  @override
  Element? get enclosingElement => firstFragment.enclosingFragment?.element;

  @Deprecated('Use enclosingElement instead')
  @override
  Element? get enclosingElement2 => enclosingElement;

  @override
  GenericFunctionTypeFragmentImpl get firstFragment => _wrappedElement;

  @override
  List<FormalParameterElementImpl> get formalParameters =>
      _wrappedElement.formalParameters
          .map((fragment) => fragment.element)
          .toList();

  @override
  List<GenericFunctionTypeFragmentImpl> get fragments {
    return [
      for (
        GenericFunctionTypeFragmentImpl? fragment = firstFragment;
        fragment != null;
        fragment = fragment.nextFragment
      )
        fragment,
    ];
  }

  @override
  bool get isSimplyBounded => _wrappedElement.isSimplyBounded;

  @override
  bool get isSynthetic => _wrappedElement.isSynthetic;

  @override
  ElementKind get kind => ElementKind.GENERIC_FUNCTION_TYPE;

  @Deprecated('Use library instead')
  @override
  LibraryElementImpl get library2 => library;

  @override
  MetadataImpl get metadata => _wrappedElement.metadata;

  @Deprecated('Use metadata instead')
  @override
  MetadataImpl get metadata2 => metadata;

  @override
  String? get name => _wrappedElement.name;

  @Deprecated('Use name instead')
  @override
  String? get name3 => name;

  @override
  TypeImpl get returnType => _wrappedElement.returnType;

  @override
  FunctionType get type => _wrappedElement.type;

  @override
  List<TypeParameterElement> get typeParameters =>
      _wrappedElement.typeParameters
          .map((fragment) => fragment.element)
          .toList();

  @Deprecated('Use typeParameters2 instead')
  @override
  List<TypeParameterElement> get typeParameters2 => typeParameters;

  @override
  T? accept<T>(ElementVisitor2<T> visitor) {
    return visitor.visitGenericFunctionTypeElement(this);
  }

  @Deprecated('Use accept instead')
  @override
  T? accept2<T>(ElementVisitor2<T> visitor) => accept(visitor);

  @override
  void appendTo(ElementDisplayStringBuilder builder) {
    builder.writeGenericFunctionTypeElement(this);
  }
}

/// The element used for a generic function type.
///
/// Clients may not extend, implement or mix-in this class.
class GenericFunctionTypeFragmentImpl extends FragmentImpl
    with DeferredResolutionReadingMixin, TypeParameterizedFragmentMixin
    implements FunctionTypedFragmentImpl, GenericFunctionTypeFragment {
  /// The declared return type of the function.
  TypeImpl? _returnType;

  /// The elements representing the parameters of the function.
  List<FormalParameterFragmentImpl> _formalParameters = const [];

  /// Is `true` if the type has the question mark, so is nullable.
  bool isNullable = false;

  /// The type defined by this element.
  FunctionTypeImpl? _type;

  late final GenericFunctionTypeElementImpl _element2 =
      GenericFunctionTypeElementImpl(this);

  /// Initialize a newly created function element to have no name and the given
  /// [nameOffset]. This is used for function expressions, that have no name.
  GenericFunctionTypeFragmentImpl({super.firstTokenOffset});

  @override
  List<Fragment> get children => [...typeParameters, ...formalParameters];

  @Deprecated('Use children instead')
  @override
  List<Fragment> get children3 => children;

  @override
  GenericFunctionTypeElementImpl get element => _element2;

  @override
  List<FormalParameterFragmentImpl> get formalParameters {
    return _formalParameters;
  }

  /// Set the parameters defined by this function type element to the given
  /// [formalParameters].
  set formalParameters(List<FormalParameterFragmentImpl> formalParameters) {
    for (var formalParameter in formalParameters) {
      formalParameter.enclosingFragment = this;
    }
    _formalParameters = formalParameters;
  }

  @override
  String? get name => null;

  @Deprecated('Use name instead')
  @override
  String? get name2 => name;

  @override
  int? get nameOffset => null;

  @override
  GenericFunctionTypeFragmentImpl? get nextFragment => null;

  @override
  int get offset => firstTokenOffset!;

  @override
  GenericFunctionTypeFragmentImpl? get previousFragment => null;

  /// The return type defined by this element.
  TypeImpl get returnType {
    return _returnType!;
  }

  /// Set the return type defined by this function type element to the given
  /// [returnType].
  set returnType(DartType returnType) {
    // TODO(paulberry): eliminate this cast by changing the setter parameter
    // type to `TypeImpl`.
    _returnType = returnType as TypeImpl;
  }

  FunctionTypeImpl get type {
    if (_type != null) return _type!;

    return _type = FunctionTypeImpl(
      typeParameters: typeParameters.map((f) => f.asElement2).toList(),
      parameters: formalParameters.map((f) => f.asElement2).toList(),
      returnType: returnType,
      nullabilitySuffix:
          isNullable ? NullabilitySuffix.question : NullabilitySuffix.none,
    );
  }

  /// Set the function type defined by this function type element to the given
  /// [type].
  set type(FunctionTypeImpl type) {
    _type = type;
  }
}

class GetterElementImpl extends PropertyAccessorElementImpl
    with InternalGetterElement {
  @override
  Reference reference;

  @override
  final GetterFragmentImpl firstFragment;

  GetterElementImpl(this.reference, this.firstFragment) {
    reference.element = this;
    GetterFragmentImpl? fragment = firstFragment;
    while (fragment != null) {
      fragment.element = this;
      fragment = fragment.nextFragment;
    }
  }

  @override
  GetterElementImpl get baseElement => this;

  @override
  SetterElement? get correspondingSetter {
    return variable.setter;
  }

  @Deprecated('Use correspondingSetter instead')
  @override
  SetterElement? get correspondingSetter2 {
    return correspondingSetter;
  }

  @override
  List<GetterFragmentImpl> get fragments {
    return [
      for (
        GetterFragmentImpl? fragment = firstFragment;
        fragment != null;
        fragment = fragment.nextFragment
      )
        fragment,
    ];
  }

  @override
  ElementKind get kind => ElementKind.GETTER;

  @override
  GetterFragmentImpl get lastFragment {
    return super.lastFragment as GetterFragmentImpl;
  }

  @override
  Element get nonSynthetic {
    if (isSynthetic) {
      return variable.nonSynthetic;
    } else {
      return this;
    }
  }

  @override
  Version? get sinceSdkVersion {
    if (isSynthetic) {
      return variable.sinceSdkVersion;
    }
    return super.sinceSdkVersion;
  }

  @override
  T? accept<T>(ElementVisitor2<T> visitor) {
    return visitor.visitGetterElement(this);
  }

  @Deprecated('Use accept instead')
  @override
  T? accept2<T>(ElementVisitor2<T> visitor) => accept(visitor);

  @override
  void appendTo(ElementDisplayStringBuilder builder) {
    builder.writeGetterElement(this);
  }

  void linkFragments(List<GetterFragmentImpl> fragments) {
    assert(identical(fragments[0], firstFragment));
    fragments.reduce((previous, current) {
      previous.addFragment(current);
      return current;
    });
  }
}

class GetterFragmentImpl extends PropertyAccessorFragmentImpl
    implements GetterFragment {
  @override
  late GetterElementImpl element;

  @override
  GetterFragmentImpl? previousFragment;

  @override
  GetterFragmentImpl? nextFragment;

  GetterFragmentImpl({required super.name});

  GetterFragmentImpl.forVariable(super.variable) : super.forVariable();

  void addFragment(GetterFragmentImpl fragment) {
    fragment.element = element;
    fragment.previousFragment = this;
    nextFragment = fragment;
  }
}

/// A concrete implementation of a [HideElementCombinator].
class HideElementCombinatorImpl implements HideElementCombinator {
  @override
  List<String> hiddenNames = const [];

  @override
  int offset = 0;

  @override
  int end = -1;

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

@elementClass
abstract class InstanceElementImpl extends ElementImpl
    with DeferredMembersReadingMixin, DeferredResolutionReadingMixin
    implements InstanceElement, TypeParameterizedElement {
  List<FieldElementImpl> _fields = [];
  List<GetterElementImpl> _getters = [];
  List<SetterElementImpl> _setters = [];
  List<MethodElementImpl> _methods = [];

  @override
  InstanceElement get baseElement => this;

  @override
  List<Element> get children {
    return [...fields, ...getters, ...setters, ...methods];
  }

  @Deprecated('Use children instead')
  @override
  List<Element> get children2 {
    return children;
  }

  @override
  @trackedIncludedInId
  String get displayName {
    return globalResultRequirements.includedInId(() {
      return firstFragment.displayName;
    });
  }

  @override
  String? get documentationComment => firstFragment.documentationComment;

  @override
  LibraryElementImpl get enclosingElement => library;

  @Deprecated('Use enclosingElement instead')
  @override
  LibraryElement get enclosingElement2 => enclosingElement;

  @override
  List<FieldElementImpl> get fields {
    globalResultRequirements?.record_instanceElement_fields(element: this);
    ensureReadMembers();
    return _fields;
  }

  set fields(List<FieldElementImpl> value) {
    _fields = value;
  }

  @Deprecated('Use fields instead')
  @override
  List<FieldElementImpl> get fields2 => fields;

  @override
  InstanceFragmentImpl get firstFragment;

  @override
  List<GetterElementImpl> get getters {
    globalResultRequirements?.record_instanceElement_getters(element: this);
    ensureReadMembers();
    return _getters;
  }

  set getters(List<GetterElementImpl> value) {
    _getters = value;
  }

  @Deprecated('Use getters instead')
  @override
  List<GetterElementImpl> get getters2 => getters;

  @override
  bool get isPrivate => firstFragment.isPrivate;

  @override
  bool get isPublic => firstFragment.isPublic;

  @override
  @trackedIncludedInId
  bool get isSimplyBounded {
    return globalResultRequirements.includedInId(() {
      return firstFragment.isSimplyBounded;
    });
  }

  @override
  @trackedIncludedInId
  bool get isSynthetic {
    return globalResultRequirements.includedInId(() {
      return firstFragment.isSynthetic;
    });
  }

  @override
  LibraryElementImpl get library => super.library!;

  @Deprecated('Use library instead')
  @override
  LibraryElementImpl get library2 => library;

  @override
  @trackedIncludedInId
  MetadataImpl get metadata {
    return globalResultRequirements.includedInId(() {
      return firstFragment.metadata;
    });
  }

  @Deprecated('Use metadata instead')
  @override
  MetadataImpl get metadata2 => metadata;

  @override
  @trackedDirectlyExpensive
  List<MethodElementImpl> get methods {
    globalResultRequirements?.record_instanceElement_methods(element: this);
    ensureReadMembers();
    return _methods;
  }

  set methods(List<MethodElementImpl> value) {
    _methods = value;
  }

  @Deprecated('Use methods instead')
  @override
  List<MethodElementImpl> get methods2 => methods;

  @override
  @trackedIncludedInId
  String? get name {
    return globalResultRequirements.includedInId(() {
      return firstFragment.name;
    });
  }

  @Deprecated('Use name instead')
  @override
  String? get name3 => name;

  @override
  Element get nonSynthetic => isSynthetic ? enclosingElement : this as Element;

  @override
  AnalysisSession? get session => firstFragment.session;

  @override
  List<SetterElementImpl> get setters {
    globalResultRequirements?.record_instanceElement_setters(element: this);
    ensureReadMembers();
    return _setters;
  }

  set setters(List<SetterElementImpl> value) {
    _setters = value;
  }

  @Deprecated('Use setters instead')
  @override
  List<SetterElementImpl> get setters2 => setters;

  @override
  @trackedIncludedInId
  List<TypeParameterElementImpl> get typeParameters {
    return globalResultRequirements.includedInId(() {
      return firstFragment.typeParameters
          .map((fragment) => fragment.element)
          .toList();
    });
  }

  @Deprecated('Use typeParameters instead')
  @override
  List<TypeParameterElementImpl> get typeParameters2 => typeParameters;

  void addField(FieldElementImpl element) {
    _fields.add(element);
  }

  void addGetter(GetterElementImpl element) {
    _getters.add(element);
  }

  void addMethod(MethodElementImpl element) {
    _methods.add(element);
  }

  void addSetter(SetterElementImpl element) {
    _setters.add(element);
  }

  @Deprecated('Use displayString instead')
  @override
  String displayString2({
    bool multiline = false,
    bool preferTypeAlias = false,
  }) => displayString(multiline: multiline, preferTypeAlias: preferTypeAlias);

  @override
  @trackedDirectly
  FieldElementImpl? getField(String name) {
    globalResultRequirements?.record_instanceElement_getField(
      element: this,
      name: name,
    );

    return globalResultRequirements.alreadyRecorded(() {
      return fields.firstWhereOrNull((e) => e.name == name);
    });
  }

  @Deprecated('Use getField instead')
  @override
  FieldElementImpl? getField2(String name) => getField(name);

  @override
  @trackedDirectly
  GetterElementImpl? getGetter(String name) {
    globalResultRequirements?.record_instanceElement_getGetter(
      element: this,
      name: name,
    );

    return globalResultRequirements.alreadyRecorded(() {
      return getters.firstWhereOrNull((e) => e.name == name);
    });
  }

  @Deprecated('Use getGetter instead')
  @override
  GetterElementImpl? getGetter2(String name) => getGetter(name);

  @override
  @trackedDirectly
  MethodElementImpl? getMethod(String name) {
    globalResultRequirements?.record_instanceElement_getMethod(
      element: this,
      name: name,
    );

    return globalResultRequirements.alreadyRecorded(() {
      return methods.firstWhereOrNull((e) => e.lookupName == name);
    });
  }

  @Deprecated('Use getMethod instead')
  @override
  MethodElementImpl? getMethod2(String name) => getMethod(name);

  @override
  @trackedDirectly
  SetterElementImpl? getSetter(String name) {
    globalResultRequirements?.record_instanceElement_getSetter(
      element: this,
      name: name,
    );

    return globalResultRequirements.alreadyRecorded(() {
      return setters.firstWhereOrNull((e) => e.name == name);
    });
  }

  @Deprecated('Use getSetter instead')
  @override
  SetterElementImpl? getSetter2(String name) => getSetter(name);

  @override
  bool isAccessibleIn(LibraryElement library) {
    var name = this.name;
    if (name != null && Identifier.isPrivateName(name)) {
      return library == this.library;
    }
    return true;
  }

  @Deprecated('Use isAccessibleIn instead')
  @override
  bool isAccessibleIn2(LibraryElement library) {
    return isAccessibleIn(library);
  }

  @override
  GetterElement? lookUpGetter({
    required String name,
    required LibraryElement library,
  }) {
    return _implementationsOfGetter(
          name,
        ).firstWhereOrNull((getter) => getter.isAccessibleIn(library))
        as GetterElement?;
  }

  @Deprecated('Use lookUpGetter instead')
  @override
  GetterElement? lookUpGetter2({
    required String name,
    required LibraryElement library,
  }) {
    return lookUpGetter(name: name, library: library);
  }

  @override
  MethodElement? lookUpMethod({
    required String name,
    required LibraryElement library,
  }) {
    return _implementationsOfMethod(
      name,
    ).firstWhereOrNull((method) => method.isAccessibleIn(library));
  }

  @Deprecated('Use lookUpMethod instead')
  @override
  MethodElement? lookUpMethod2({
    required String name,
    required LibraryElement library,
  }) {
    return lookUpMethod(name: name, library: library);
  }

  @override
  SetterElement? lookUpSetter({
    required String name,
    required LibraryElement library,
  }) {
    return _implementationsOfSetter(
          name,
        ).firstWhereOrNull((setter) => setter.isAccessibleIn(library))
        as SetterElement?;
  }

  @Deprecated('Use lookUpSetter instead')
  @override
  SetterElement? lookUpSetter2({
    required String name,
    required LibraryElement library,
  }) {
    return lookUpSetter(name: name, library: library);
  }

  @override
  Element? thisOrAncestorMatching(bool Function(Element) predicate) {
    if (predicate(this)) {
      return this;
    }
    return library.thisOrAncestorMatching(predicate);
  }

  @Deprecated('Use thisOrAncestorMatching instead')
  @override
  Element? thisOrAncestorMatching2(bool Function(Element) predicate) {
    return thisOrAncestorMatching(predicate);
  }

  @override
  E? thisOrAncestorOfType<E extends Element>() {
    if (this case E result) {
      return result;
    }
    return library.thisOrAncestorOfType<E>();
  }

  @Deprecated('Use thisOrAncestorOfType instead')
  @override
  E? thisOrAncestorOfType2<E extends Element>() {
    return thisOrAncestorOfType();
  }

  @override
  void visitChildren<T>(ElementVisitor2<T> visitor) {
    for (var child in children) {
      child.accept(visitor);
    }
  }

  Iterable<InternalPropertyAccessorElement> _implementationsOfGetter(
    String name,
  ) sync* {
    var visitedElements = <InstanceElement>{};
    InstanceElement? element = this;
    while (element != null && visitedElements.add(element)) {
      var getter = element.getGetter(name);
      if (getter != null) {
        yield getter as InternalPropertyAccessorElement;
      }
      if (element is! InterfaceElement) {
        return;
      }
      for (var mixin in element.mixins.reversed) {
        mixin as InterfaceTypeImpl;
        getter = mixin.element.getGetter(name);
        if (getter != null) {
          yield getter as InternalPropertyAccessorElement;
        }
      }
      var supertype = element.supertype;
      supertype as InterfaceTypeImpl?;
      element = supertype?.element;
    }
  }

  Iterable<InternalMethodElement> _implementationsOfMethod(String name) sync* {
    var visitedElements = <InstanceElement>{};
    InstanceElement? element = this;
    while (element != null && visitedElements.add(element)) {
      var method = element.getMethod(name);
      if (method != null) {
        yield method as InternalMethodElement;
      }
      if (element is! InterfaceElement) {
        return;
      }
      for (var mixin in element.mixins.reversed) {
        mixin as InterfaceTypeImpl;
        method = mixin.element.getMethod(name);
        if (method != null) {
          yield method as InternalMethodElement;
        }
      }
      var supertype = element.supertype;
      supertype as InterfaceTypeImpl?;
      element = supertype?.element;
    }
  }

  Iterable<InternalPropertyAccessorElement> _implementationsOfSetter(
    String name,
  ) sync* {
    var visitedElements = <InstanceElement>{};
    InstanceElement? element = this;
    while (element != null && visitedElements.add(element)) {
      var setter = element.getSetter(name);
      if (setter != null) {
        yield setter as InternalPropertyAccessorElement;
      }
      if (element is! InterfaceElement) {
        return;
      }
      for (var mixin in element.mixins.reversed) {
        mixin as InterfaceTypeImpl;
        setter = mixin.element.getSetter(name);
        if (setter != null) {
          yield setter as InternalPropertyAccessorElement;
        }
      }
      var supertype = element.supertype;
      supertype as InterfaceTypeImpl?;
      element = supertype?.element;
    }
  }
}

abstract class InstanceFragmentImpl extends FragmentImpl
    with
        DeferredMembersReadingMixin,
        DeferredResolutionReadingMixin,
        TypeParameterizedFragmentMixin
    implements InstanceFragment {
  @override
  final String? name;

  @override
  int? nameOffset;

  @override
  InstanceFragmentImpl? previousFragment;

  @override
  InstanceFragmentImpl? nextFragment;

  List<FieldFragmentImpl> _fields = _Sentinel.fieldFragment;
  List<GetterFragmentImpl> _getters = _Sentinel.getterFragment;
  List<SetterFragmentImpl> _setters = _Sentinel.setterFragment;
  List<MethodFragmentImpl> _methods = _Sentinel.methodFragment;

  InstanceFragmentImpl({required this.name});

  List<PropertyAccessorFragmentImpl> get accessors {
    return [...getters, ...setters];
  }

  @override
  InstanceElementImpl get element;

  @override
  LibraryFragmentImpl get enclosingFragment =>
      super.enclosingFragment as LibraryFragmentImpl;

  @override
  List<FieldFragmentImpl> get fields {
    if (!identical(_fields, _Sentinel.fieldFragment)) {
      return _fields;
    }

    element.ensureReadMembers();
    _ensureReadResolution();
    return _fields;
  }

  set fields(List<FieldFragmentImpl> fields) {
    for (var field in fields) {
      field.enclosingFragment = this;
    }
    _fields = fields;
  }

  @Deprecated('Use fields instead')
  @override
  List<FieldFragment> get fields2 => fields.cast<FieldFragment>();

  @override
  List<GetterFragmentImpl> get getters {
    if (!identical(_getters, _Sentinel.getterFragment)) {
      return _getters;
    }

    element.ensureReadMembers();
    _ensureReadResolution();
    return _getters;
  }

  set getters(List<GetterFragmentImpl> getters) {
    for (var getter in getters) {
      getter.enclosingFragment = this;
    }
    _getters = getters;
  }

  @override
  MetadataImpl get metadata {
    _ensureReadResolution();
    return super.metadata;
  }

  @override
  List<MethodFragmentImpl> get methods {
    if (!identical(_methods, _Sentinel.methodFragment)) {
      return _methods;
    }

    element.ensureReadMembers();
    _ensureReadResolution();
    return _methods;
  }

  set methods(List<MethodFragmentImpl> methods) {
    for (var method in methods) {
      method.enclosingFragment = this;
    }
    _methods = methods;
  }

  @Deprecated('Use methods instead')
  @override
  List<MethodFragment> get methods2 => methods.cast<MethodFragment>();

  @override
  int get offset => nameOffset ?? firstTokenOffset!;

  @override
  List<SetterFragmentImpl> get setters {
    if (!identical(_setters, _Sentinel.setterFragment)) {
      return _setters;
    }

    element.ensureReadMembers();
    _ensureReadResolution();
    return _setters;
  }

  set setters(List<SetterFragmentImpl> setters) {
    for (var setter in setters) {
      setter.enclosingFragment = this;
    }
    _setters = setters;
  }

  void addField(FieldFragmentImpl fragment) {
    if (identical(_fields, _Sentinel.fieldFragment)) {
      _fields = [];
    }
    _fields.add(fragment);
    fragment.enclosingFragment = this;
  }

  void addGetter(GetterFragmentImpl fragment) {
    if (identical(_getters, _Sentinel.getterFragment)) {
      _getters = [];
    }
    _getters.add(fragment);
    fragment.enclosingFragment = this;
  }

  void addMethod(MethodFragmentImpl fragment) {
    if (identical(_methods, _Sentinel.methodFragment)) {
      _methods = [];
    }
    _methods.add(fragment);
    fragment.enclosingFragment = this;
  }

  void addSetter(SetterFragmentImpl fragment) {
    if (identical(_setters, _Sentinel.setterFragment)) {
      _setters = [];
    }
    _setters.add(fragment);
    fragment.enclosingFragment = this;
  }
}

abstract class InterfaceElementImpl extends InstanceElementImpl
    implements InterfaceElement {
  /// The non-nullable instance of this element, without alias.
  /// Should be used only when the element has no type parameters.
  InterfaceTypeImpl? _nonNullableInstance;

  /// The nullable instance of this element, without alias.
  /// Should be used only when the element has no type parameters.
  InterfaceTypeImpl? _nullableInstance;

  InterfaceTypeImpl? _supertype;
  List<InterfaceTypeImpl> _mixins = const [];
  List<InterfaceTypeImpl> _interfaces = const [];

  InterfaceTypeImpl? _thisType;

  /// The cached result of [allSupertypes].
  List<InterfaceTypeImpl>? _allSupertypes;

  List<ConstructorElementImpl> _constructors = _Sentinel.constructorElement;

  /// This callback is set during mixins inference to handle reentrant calls.
  List<InterfaceTypeImpl>? Function(InterfaceElementImpl)?
  mixinInferenceCallback;

  /// A flag indicating whether the types associated with the instance members
  /// of this class have been inferred.
  bool hasBeenInferred = false;

  @override
  List<InterfaceTypeImpl> get allSupertypes {
    return _allSupertypes ??= library.session.classHierarchy
        .implementedInterfaces(this);
  }

  @override
  List<Element> get children {
    return [...super.children, ...constructors];
  }

  @Deprecated('Use children instead')
  @override
  List<Element> get children2 {
    return children;
  }

  @override
  List<ConstructorElementImpl> get constructors {
    globalResultRequirements?.record_instanceElement_constructors(
      element: this,
    );
    ensureReadMembers();
    if (!identical(_constructors, _Sentinel.constructorElement)) {
      return _constructors;
    }

    _buildMixinAppConstructors();
    return _constructors;
  }

  set constructors(List<ConstructorElementImpl> value) {
    _constructors = value;
  }

  @Deprecated('Use constructors instead')
  @override
  List<ConstructorElementImpl> get constructors2 {
    return constructors;
  }

  @override
  InterfaceFragmentImpl get firstFragment;

  @override
  List<InterfaceFragmentImpl> get fragments {
    return [
      for (
        InterfaceFragmentImpl? fragment = firstFragment;
        fragment != null;
        fragment = fragment.nextFragment
      )
        fragment,
    ];
  }

  InheritanceManager3 get inheritanceManager {
    return library.session.inheritanceManager;
  }

  @override
  Map<Name, ExecutableElement> get inheritedConcreteMembers =>
      (session as AnalysisSessionImpl).inheritanceManager
          .getInheritedConcreteMap(this);

  @override
  Map<Name, ExecutableElement> get inheritedMembers =>
      (session as AnalysisSessionImpl).inheritanceManager.getInheritedMap(this);

  @override
  Map<Name, ExecutableElement> get interfaceMembers =>
      (session as AnalysisSessionImpl).inheritanceManager
          .getInterface(this)
          .map;

  @override
  @trackedIncludedInId
  List<InterfaceTypeImpl> get interfaces {
    _ensureReadResolution();
    return _interfaces;
  }

  set interfaces(List<InterfaceType> interfaces) {
    // TODO(paulberry): eliminate this cast by changing the type of the
    // `interfaces` parameter.
    _interfaces = interfaces.cast();
  }

  /// Return `true` if this class represents the class '_Enum' defined in the
  /// dart:core library.
  bool get isDartCoreEnumImpl {
    return name == '_Enum' && library.isDartCore;
  }

  set isSimplyBounded(bool value) {
    for (var fragment in fragments) {
      fragment.isSimplyBounded = value;
    }
  }

  @override
  @trackedIncludedInId
  List<InterfaceTypeImpl> get mixins {
    if (mixinInferenceCallback case var mixinInferenceCallback?) {
      var mixins = mixinInferenceCallback(this);
      if (mixins != null) {
        return _mixins = mixins;
      }
    }

    _ensureReadResolution();
    return _mixins;
  }

  set mixins(List<InterfaceType> mixins) {
    // TODO(paulberry): eliminate this cast by changing the type of the `mixins`
    // parameter.
    _mixins = mixins.cast();
  }

  @override
  @trackedIncludedInId
  InterfaceTypeImpl? get supertype {
    _ensureReadResolution();
    return _supertype;
  }

  set supertype(InterfaceTypeImpl? value) {
    _supertype = value;
  }

  @override
  InterfaceTypeImpl get thisType {
    if (_thisType == null) {
      List<TypeImpl> typeArguments;
      if (typeParameters.isNotEmpty) {
        typeArguments =
            typeParameters.map<TypeImpl>((t) {
              return t.instantiate(nullabilitySuffix: NullabilitySuffix.none);
            }).toFixedList();
      } else {
        typeArguments = const [];
      }
      return _thisType = instantiateImpl(
        typeArguments: typeArguments,
        nullabilitySuffix: NullabilitySuffix.none,
      );
    }
    return _thisType!;
  }

  @override
  ConstructorElementImpl? get unnamedConstructor {
    return getNamedConstructor('new');
  }

  @Deprecated('Use unnamedConstructor instead')
  @override
  ConstructorElementImpl? get unnamedConstructor2 {
    return unnamedConstructor;
  }

  void addConstructor(ConstructorElementImpl element) {
    if (identical(_constructors, _Sentinel.constructorElement)) {
      _constructors = [];
    }
    _constructors.add(element);
  }

  @override
  ExecutableElement? getInheritedConcreteMember(Name name) =>
      inheritedConcreteMembers[name];

  @override
  ExecutableElement? getInheritedMember(Name name) =>
      (session as AnalysisSessionImpl).inheritanceManager.getInherited(
        this,
        name,
      );

  @override
  ExecutableElement? getInterfaceMember(Name name) =>
      (session as AnalysisSessionImpl).inheritanceManager.getMember(this, name);

  @override
  ConstructorElementImpl? getNamedConstructor(String name) {
    globalResultRequirements?.record_interfaceElement_getNamedConstructor(
      element: this,
      name: name,
    );

    return globalResultRequirements.alreadyRecorded(() {
      return constructors.firstWhereOrNull((e) => e.name == name);
    });
  }

  @Deprecated('Use getNamedConstructor instead')
  @override
  ConstructorElementImpl? getNamedConstructor2(String name) {
    return getNamedConstructor(name);
  }

  @override
  List<ExecutableElement>? getOverridden(Name name) =>
      (session as AnalysisSessionImpl).inheritanceManager.getOverridden(
        this,
        name,
      );

  @override
  InterfaceTypeImpl instantiate({
    required List<DartType> typeArguments,
    required NullabilitySuffix nullabilitySuffix,
  }) {
    return instantiateImpl(
      typeArguments: typeArguments.cast<TypeImpl>(),
      nullabilitySuffix: nullabilitySuffix,
    );
  }

  InterfaceTypeImpl instantiateImpl({
    required List<TypeImpl> typeArguments,
    required NullabilitySuffix nullabilitySuffix,
  }) {
    assert(typeArguments.length == typeParameters.length);

    if (typeArguments.isEmpty) {
      switch (nullabilitySuffix) {
        case NullabilitySuffix.none:
          if (_nonNullableInstance case var instance?) {
            return instance;
          }
        case NullabilitySuffix.question:
          if (_nullableInstance case var instance?) {
            return instance;
          }
        case NullabilitySuffix.star:
          // TODO(scheglov): remove together with `star`
          break;
      }
    }

    var result = InterfaceTypeImpl(
      element: this,
      typeArguments: typeArguments,
      nullabilitySuffix: nullabilitySuffix,
    );

    if (typeArguments.isEmpty) {
      switch (nullabilitySuffix) {
        case NullabilitySuffix.none:
          _nonNullableInstance = result;
        case NullabilitySuffix.question:
          _nullableInstance = result;
        case NullabilitySuffix.star:
          // TODO(scheglov): remove together with `star`
          break;
      }
    }

    return result;
  }

  @override
  MethodElement? lookUpConcreteMethod(
    String methodName,
    LibraryElement library,
  ) {
    return _implementationsOfMethod(methodName).firstWhereOrNull(
      (method) => !method.isAbstract && method.isAccessibleIn(library),
    );
  }

  PropertyAccessorElement? lookUpInheritedConcreteGetter(
    String getterName,
    LibraryElement library,
  ) {
    return _implementationsOfGetter(getterName).firstWhereOrNull(
      (getter) =>
          !getter.isAbstract &&
          !getter.isStatic &&
          getter.isAccessibleIn(library) &&
          getter.enclosingElement != this,
    );
  }

  MethodElement? lookUpInheritedConcreteMethod(
    String methodName,
    LibraryElement library,
  ) {
    return _implementationsOfMethod(methodName).firstWhereOrNull(
      (method) =>
          !method.isAbstract &&
          !method.isStatic &&
          method.isAccessibleIn(library) &&
          method.enclosingElement != this,
    );
  }

  PropertyAccessorElement? lookUpInheritedConcreteSetter(
    String setterName,
    LibraryElement library,
  ) {
    return _implementationsOfSetter(setterName).firstWhereOrNull(
      (setter) =>
          !setter.isAbstract &&
          !setter.isStatic &&
          setter.isAccessibleIn(library) &&
          setter.enclosingElement != this,
    );
  }

  @override
  MethodElement? lookUpInheritedMethod({
    required String methodName,
    required LibraryElement library,
  }) {
    return inheritanceManager
        .getInherited(this, Name.forLibrary(library, methodName))
        .ifTypeOrNull();
  }

  @override
  @Deprecated('Use lookUpInheritedMethod instead')
  MethodElement? lookUpInheritedMethod2({
    required String methodName,
    required LibraryElement library,
  }) {
    return lookUpInheritedMethod(methodName: methodName, library: library);
  }

  /// Return the static getter with the [name], accessible to the [library].
  ///
  /// This method should be used only for error recovery during analysis,
  /// when instance access to a static class member, defined in this class,
  /// or a superclass.
  @trackedIndirectly
  InternalGetterElement? lookupStaticGetter(
    String name,
    LibraryElement library,
  ) {
    return _implementationsOfGetter(name)
        .firstWhereOrNull(
          (element) => element.isStatic && element.isAccessibleIn(library),
        )
        .ifTypeOrNull();
  }

  /// Return the static method with the [name], accessible to the [library].
  ///
  /// This method should be used only for error recovery during analysis,
  /// when instance access to a static class member, defined in this class,
  /// or a superclass.
  @trackedIndirectly
  InternalMethodElement? lookupStaticMethod(
    String name,
    LibraryElement library,
  ) {
    return _implementationsOfMethod(name).firstWhereOrNull(
      (element) => element.isStatic && element.isAccessibleIn(library),
    );
  }

  /// Return the static setter with the [name], accessible to the [library].
  ///
  /// This method should be used only for error recovery during analysis,
  /// when instance access to a static class member, defined in this class,
  /// or a superclass.
  @trackedIndirectly
  InternalSetterElement? lookupStaticSetter(
    String name,
    LibraryElement library,
  ) {
    return _implementationsOfSetter(name)
        .firstWhereOrNull(
          (element) => element.isStatic && element.isAccessibleIn(library),
        )
        .ifTypeOrNull();
  }

  void resetCachedAllSupertypes() {
    _allSupertypes = null;
  }

  /// Builds constructors for this mixin application.
  void _buildMixinAppConstructors() {}
}

@GenerateFragmentImpl(modifiers: _InterfaceFragmentImplModifiers.values)
abstract class InterfaceFragmentImpl extends InstanceFragmentImpl
    with _InterfaceFragmentImplMixin
    implements InterfaceFragment {
  List<ConstructorFragmentImpl> _constructors = _Sentinel.constructorFragment;

  /// Initialize a newly created class element to have the given [name] at the
  /// given [offset] in the file that contains the declaration of this element.
  InterfaceFragmentImpl({required super.name});

  @override
  List<Fragment> get children => [
    ...constructors,
    ...fields,
    ...getters,
    ...methods,
    ...setters,
    ...typeParameters,
  ];

  @Deprecated('Use children instead')
  @override
  List<Fragment> get children3 => children;

  @override
  List<ConstructorFragmentImpl> get constructors {
    element.ensureReadMembers();
    if (!identical(_constructors, _Sentinel.constructorFragment)) {
      return _constructors;
    }

    // This will also create constructor fragments.
    element._buildMixinAppConstructors();
    return _constructors;
  }

  set constructors(List<ConstructorFragmentImpl> constructors) {
    for (var constructor in constructors) {
      constructor.enclosingFragment = this;
    }
    _constructors = constructors;
  }

  @Deprecated('Use constructors instead')
  @override
  List<ConstructorFragmentImpl> get constructors2 {
    return constructors;
  }

  @override
  String get displayName => name ?? '';

  @override
  InterfaceElementImpl get element;

  @override
  List<InterfaceTypeImpl> get interfaces => element.interfaces;


  @override
  List<InterfaceTypeImpl> get mixins => element.mixins;

  @override
  InterfaceFragmentImpl? get nextFragment {
    return super.nextFragment as InterfaceFragmentImpl?;
  }

  @override
  InterfaceFragmentImpl? get previousFragment {
    return super.previousFragment as InterfaceFragmentImpl?;
  }

  @override
  InterfaceTypeImpl? get supertype => element.supertype;

  void addConstructor(ConstructorFragmentImpl fragment) {
    if (identical(_constructors, _Sentinel.constructorFragment)) {
      _constructors = [];
    }
    _constructors.add(fragment);
    fragment.enclosingFragment = this;
  }
}

mixin InternalConstructorElement on InternalExecutableElement
    implements ConstructorElement {
  @override
  ConstructorElementImpl get baseElement;

  @override
  InterfaceElementImpl get enclosingElement;

  @override
  ConstructorFragmentImpl get firstFragment;

  @override
  List<ConstructorFragmentImpl> get fragments;

  @override
  LibraryElementImpl get library;

  @override
  InternalConstructorElement? get redirectedConstructor;

  @Deprecated('Use redirectedConstructor instead')
  @override
  InternalConstructorElement? get redirectedConstructor2;

  @override
  InterfaceTypeImpl get returnType;

  @override
  InternalConstructorElement? get superConstructor;

  @Deprecated('Use superConstructor instead')
  @override
  InternalConstructorElement? get superConstructor2;
}

mixin InternalExecutableElement implements ExecutableElement {
  @override
  ExecutableElementImpl get baseElement;

  @override
  List<InternalFormalParameterElement> get formalParameters;

  @override
  MetadataImpl get metadata;

  @override
  TypeImpl get returnType;

  @override
  FunctionTypeImpl get type;

  @override
  List<TypeParameterElementImpl> get typeParameters;
}

mixin InternalFieldElement on InternalPropertyInducingElement
    implements FieldElement {
  @override
  FieldElementImpl get baseElement;

  @override
  FieldFragmentImpl get firstFragment;

  @override
  List<FieldFragmentImpl> get fragments;
}

mixin InternalFormalParameterElement on InternalVariableElement
    implements FormalParameterElement, SharedNamedFunctionParameter {
  @override
  FormalParameterElementImpl get baseElement;

  ParameterKind get parameterKind;

  @override
  TypeImpl get type;

  @override
  List<TypeParameterElementImpl> get typeParameters;

  @override
  void appendToWithoutDelimiters(StringBuffer buffer) {
    buffer.write(type.getDisplayString());
    buffer.write(' ');
    buffer.write(displayName);
    if (defaultValueCode != null) {
      buffer.write(' = ');
      buffer.write(defaultValueCode);
    }
  }

  @Deprecated('Use appendToWithoutDelimiters instead')
  @override
  void appendToWithoutDelimiters2(StringBuffer buffer) {
    appendToWithoutDelimiters(buffer);
  }
}

mixin InternalGetterElement on InternalPropertyAccessorElement
    implements GetterElement {
  @override
  GetterElementImpl get baseElement;

  @override
  GetterFragmentImpl get firstFragment;

  @override
  List<GetterFragmentImpl> get fragments;
}

mixin InternalMethodElement on InternalExecutableElement
    implements MethodElement {
  @override
  MethodElementImpl get baseElement;

  @override
  MethodFragmentImpl get firstFragment;

  @override
  List<MethodFragmentImpl> get fragments;
}

mixin InternalPropertyAccessorElement on InternalExecutableElement
    implements PropertyAccessorElement {
  @override
  PropertyAccessorElementImpl get baseElement;

  @override
  PropertyAccessorFragmentImpl get firstFragment;

  @override
  List<PropertyAccessorFragmentImpl> get fragments;

  @override
  InternalPropertyInducingElement get variable;

  @Deprecated('Use variable instead')
  @override
  InternalPropertyInducingElement? get variable3;
}

mixin InternalPropertyInducingElement on InternalVariableElement
    implements PropertyInducingElement {
  @override
  PropertyInducingElementImpl get baseElement;

  @override
  InternalGetterElement? get getter;

  @Deprecated('Use getter instead')
  @override
  InternalGetterElement? get getter2;

  @override
  LibraryElementImpl get library;

  @override
  MetadataImpl get metadata;

  @override
  InternalSetterElement? get setter;

  @Deprecated('Use setter instead')
  @override
  InternalSetterElement? get setter2;
}

mixin InternalSetterElement on InternalPropertyAccessorElement
    implements SetterElement {
  @override
  SetterElementImpl get baseElement;

  @override
  SetterFragmentImpl get firstFragment;

  @override
  List<SetterFragmentImpl> get fragments;
}

mixin InternalVariableElement implements VariableElement {
  @override
  TypeImpl get type;
}

class JoinPatternVariableElementImpl extends PatternVariableElementImpl
    implements JoinPatternVariableElement {
  JoinPatternVariableElementImpl(super._wrappedElement);

  @override
  JoinPatternVariableFragmentImpl get firstFragment =>
      super.firstFragment as JoinPatternVariableFragmentImpl;

  @override
  List<JoinPatternVariableFragmentImpl> get fragments {
    return [
      for (
        JoinPatternVariableFragmentImpl? fragment = firstFragment;
        fragment != null;
        fragment = fragment.nextFragment
      )
        fragment,
    ];
  }

  shared.JoinedPatternVariableInconsistency get inconsistency =>
      _wrappedElement.inconsistency;

  set inconsistency(shared.JoinedPatternVariableInconsistency value) =>
      _wrappedElement.inconsistency = value;

  @override
  bool get isConsistent {
    return _wrappedElement.inconsistency ==
        shared.JoinedPatternVariableInconsistency.none;
  }

  set isFinal(bool value) => _wrappedElement.isFinal = value;

  /// The identifiers that reference this element.
  List<SimpleIdentifier> get references => _wrappedElement.references;

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
  List<PatternVariableElementImpl> get variables =>
      _wrappedElement.variables.map((fragment) => fragment.element).toList();

  /// The variables that join into this variable.
  @Deprecated('Use variables instead')
  @override
  List<PatternVariableElementImpl> get variables2 {
    return variables;
  }

  @override
  JoinPatternVariableFragmentImpl get _wrappedElement =>
      super._wrappedElement as JoinPatternVariableFragmentImpl;
}

class JoinPatternVariableFragmentImpl extends PatternVariableFragmentImpl
    implements JoinPatternVariableFragment {
  /// The variables that join into this variable.
  final List<PatternVariableFragmentImpl> variables;

  shared.JoinedPatternVariableInconsistency inconsistency;

  /// The identifiers that reference this element.
  final List<SimpleIdentifier> references = [];

  JoinPatternVariableFragmentImpl({
    required super.name,
    required super.firstTokenOffset,
    required this.variables,
    required this.inconsistency,
  }) {
    for (var component in variables) {
      component.join = this;
    }
  }

  @override
  JoinPatternVariableElementImpl get element =>
      super.element as JoinPatternVariableElementImpl;

  @override
  JoinPatternVariableFragmentImpl? get nextFragment =>
      super.nextFragment as JoinPatternVariableFragmentImpl?;

  @override
  int get offset => variables[0].offset;

  @override
  JoinPatternVariableFragmentImpl? get previousFragment =>
      super.previousFragment as JoinPatternVariableFragmentImpl?;

  /// Returns this variable, and variables that join into it.
  List<PatternVariableFragmentImpl> get transitiveVariables {
    var result = <PatternVariableFragmentImpl>[];

    void append(PatternVariableFragmentImpl variable) {
      result.add(variable);
      if (variable is JoinPatternVariableFragmentImpl) {
        for (var variable in variable.variables) {
          append(variable);
        }
      }
    }

    append(this);
    return result;
  }
}

class LabelElementImpl extends ElementImpl implements LabelElement {
  final LabelFragmentImpl _wrappedFragment;

  LabelElementImpl(this._wrappedFragment);

  @override
  LabelElement get baseElement => this;

  @override
  ExecutableElement? get enclosingElement => null;

  @Deprecated('Use enclosingElement instead')
  @override
  ExecutableElement? get enclosingElement2 => enclosingElement;

  @override
  LabelFragmentImpl get firstFragment => _wrappedFragment;

  @override
  List<LabelFragmentImpl> get fragments {
    return [firstFragment];
  }

  /// Return `true` if this label is associated with a `switch` member (`case`
  /// or `default`).
  bool get isOnSwitchMember => _wrappedFragment.isOnSwitchMember;

  @override
  bool get isSynthetic => _wrappedFragment.isSynthetic;

  @override
  ElementKind get kind => ElementKind.LABEL;

  @override
  LibraryElementImpl get library => super.library!;

  @Deprecated('Use library instead')
  @override
  LibraryElement get library2 => library;

  @override
  String? get name => _wrappedFragment.name;

  @Deprecated('Use name instead')
  @override
  String? get name3 => name;

  @override
  T? accept<T>(ElementVisitor2<T> visitor) {
    return visitor.visitLabelElement(this);
  }

  @Deprecated('Use accept instead')
  @override
  T? accept2<T>(ElementVisitor2<T> visitor) => accept(visitor);

  @override
  void appendTo(ElementDisplayStringBuilder builder) {
    builder.writeLabelElement(this);
  }

  @Deprecated('Use displayString instead')
  @override
  String displayString2({
    bool multiline = false,
    bool preferTypeAlias = false,
  }) => displayString(multiline: multiline, preferTypeAlias: preferTypeAlias);

  @override
  void visitChildren<T>(ElementVisitor2<T> visitor) {}
}

class LabelFragmentImpl extends FragmentImpl implements LabelFragment {
  late final LabelElementImpl element2 = LabelElementImpl(this);

  @override
  final String? name;

  /// A flag indicating whether this label is associated with a `switch` member
  /// (`case` or `default`).
  // TODO(brianwilkerson): Make this a modifier.
  final bool _onSwitchMember;

  /// Initialize a newly created label element to have the given [name].
  /// [_onSwitchMember] should be `true` if this label is associated with a
  /// `switch` member.
  LabelFragmentImpl({
    required this.name,
    required super.firstTokenOffset,
    required bool onSwitchMember,
  }) : _onSwitchMember = onSwitchMember;

  @override
  List<Fragment> get children => const [];

  @Deprecated('Use children instead')
  @override
  List<Fragment> get children3 => children;

  @override
  String get displayName => name ?? '';

  @override
  LabelElement get element => element2;

  @override
  ExecutableFragmentImpl get enclosingFragment =>
      super.enclosingFragment as ExecutableFragmentImpl;

  @override
  int get firstTokenOffset => super.firstTokenOffset!;

  /// Return `true` if this label is associated with a `switch` member (`case`
  /// or `default`).
  bool get isOnSwitchMember => _onSwitchMember;

  @override
  LibraryFragmentImpl get libraryFragment => enclosingUnit;

  @override
  // TODO(scheglov): make it a nullable field
  int? get nameOffset => firstTokenOffset;

  @override
  LabelFragmentImpl? get nextFragment => null;

  @override
  int get offset => firstTokenOffset;

  @override
  LabelFragmentImpl? get previousFragment => null;
}

/// A concrete implementation of [LibraryElement].
class LibraryElementImpl extends ElementImpl
    with DeferredResolutionReadingMixin
    implements LibraryElement {
  final AnalysisContext context;

  @override
  Reference? reference;

  MetadataImpl _metadata = MetadataImpl(const []);

  @override
  String? documentationComment;

  @override
  AnalysisSessionImpl session;

  /// The compilation unit that defines this library.
  late LibraryFragmentImpl definingCompilationUnit;

  /// The language version for the library.
  LibraryLanguageVersion? _languageVersion;

  bool hasTypeProviderSystemSet = false;

  @override
  late TypeProviderImpl typeProvider;

  @override
  late TypeSystemImpl typeSystem;

  late List<ExportedReference> exportedReferences;

  /// The union of names for all searchable elements in this library.
  ElementNameUnion nameUnion = ElementNameUnion.empty();

  @override
  final FeatureSet featureSet;

  /// The entry point for this library, or `null` if this library does not have
  /// an entry point.
  TopLevelFunctionElementImpl? _entryPoint;

  /// The provider for the synthetic function `loadLibrary` that is defined
  /// for this library.
  late final LoadLibraryFunctionProvider loadLibraryProvider;

  // TODO(scheglov): replace with `LibraryName` or something.
  @override
  String name;

  // TODO(scheglov): replace with `LibraryName` or something.
  int nameOffset;

  // TODO(scheglov): replace with `LibraryName` or something.
  int nameLength;

  @override
  List<ClassElementImpl> classes = [];

  @override
  List<EnumElementImpl> enums = [];

  @override
  List<ExtensionElementImpl> extensions = [];

  @override
  List<ExtensionTypeElementImpl> extensionTypes = [];

  @override
  List<GetterElementImpl> getters = [];

  @override
  List<SetterElementImpl> setters = [];

  @override
  List<MixinElementImpl> mixins = [];

  @override
  List<TopLevelFunctionElementImpl> topLevelFunctions = [];

  @override
  List<TopLevelVariableElementImpl> topLevelVariables = [];

  @override
  List<TypeAliasElementImpl> typeAliases = [];

  /// The export [Namespace] of this library, `null` if it has not been
  /// computed yet.
  Namespace? _exportNamespace;

  /// The public [Namespace] of this library, `null` if it has not been
  /// computed yet.
  Namespace? _publicNamespace;

  /// Information about why non-promotable private fields in the library are not
  /// promotable.
  ///
  /// See [fieldNameNonPromotabilityInfo].
  Map<String, FieldNameNonPromotabilityInfo>? _fieldNameNonPromotabilityInfo;

  /// The map of top-level declarations, from all units.
  LibraryDeclarations? _libraryDeclarations;

  /// With fine-grained dependencies, the manifest of the library.
  LibraryManifest? manifest;

  /// Initialize a newly created library element in the given [context] to have
  /// the given [name] and [offset].
  LibraryElementImpl(
    this.context,
    this.session,
    this.name,
    this.nameOffset,
    this.nameLength,
    this.featureSet,
  );

  @override
  LibraryElementImpl get baseElement => this;

  @override
  List<Element> get children {
    return [
      ...classes,
      ...enums,
      ...extensions,
      ...extensionTypes,
      ...getters,
      ...mixins,
      ...setters,
      ...topLevelFunctions,
      ...topLevelVariables,
      ...typeAliases,
    ];
  }

  @Deprecated('Use children instead')
  @override
  List<Element> get children2 {
    return children;
  }

  @override
  Null get enclosingElement => null;

  @Deprecated('Use enclosingElement instead')
  @override
  Null get enclosingElement2 => enclosingElement;

  @override
  TopLevelFunctionElementImpl? get entryPoint {
    _ensureReadResolution();
    return _entryPoint;
  }

  set entryPoint(TopLevelFunctionElementImpl? value) {
    _entryPoint = value;
  }

  @Deprecated('Use entryPoint instead')
  @override
  TopLevelFunctionElementImpl? get entryPoint2 {
    return entryPoint;
  }

  @override
  List<LibraryElementImpl> get exportedLibraries {
    return fragments
        .expand((fragment) => fragment.libraryExports)
        .map((export) => export.exportedLibrary)
        .nonNulls
        .toSet()
        .toList();
  }

  @Deprecated('Use exportedLibraries instead')
  @override
  List<LibraryElementImpl> get exportedLibraries2 {
    return exportedLibraries;
  }

  @override
  Namespace get exportNamespace {
    _ensureReadResolution();
    return _exportNamespace ??= Namespace({});
  }

  set exportNamespace(Namespace exportNamespace) {
    _exportNamespace = exportNamespace;
  }

  /// Information about why non-promotable private fields in the library are not
  /// promotable.
  ///
  /// If field promotion is not enabled in this library, this field is still
  /// populated, so that the analyzer can figure out whether enabling field
  /// promotion would cause a field to be promotable.
  ///
  /// There are two ways an access to a private property name might not be
  /// promotable: the property might be non-promotable for a reason inherent to
  /// itself (e.g. it's declared as a concrete getter rather than a field, or
  /// it's a non-final field), or the property might have the same name as an
  /// inherently non-promotable property elsewhere in the same library (in which
  /// case the inherently non-promotable property is said to be "conflicting").
  ///
  /// When a compile-time error occurs because a property is non-promotable due
  /// conflicting properties elsewhere in the library, the analyzer needs to be
  /// able to find the conflicting properties in order to generate context
  /// messages. This data structure allows that, by mapping each non-promotable
  /// private name to the set of conflicting declarations.
  ///
  /// If a field in the library has a private name and that name does not appear
  /// as a key in this map, the field is promotable.
  Map<String, FieldNameNonPromotabilityInfo> get fieldNameNonPromotabilityInfo {
    _ensureReadResolution();
    return _fieldNameNonPromotabilityInfo!;
  }

  set fieldNameNonPromotabilityInfo(
    Map<String, FieldNameNonPromotabilityInfo>? value,
  ) {
    _fieldNameNonPromotabilityInfo = value;
  }

  @override
  LibraryFragmentImpl get firstFragment => definingCompilationUnit;

  @override
  List<LibraryFragmentImpl> get fragments {
    return [definingCompilationUnit, ..._partUnits];
  }

  bool get hasPartOfDirective {
    return hasModifier(Modifier.HAS_PART_OF_DIRECTIVE);
  }

  set hasPartOfDirective(bool hasPartOfDirective) {
    setModifier(Modifier.HAS_PART_OF_DIRECTIVE, hasPartOfDirective);
  }

  @override
  String get identifier => '$uri';

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
  bool get isSynthetic {
    return hasModifier(Modifier.SYNTHETIC);
  }

  set isSynthetic(bool isSynthetic) {
    setModifier(Modifier.SYNTHETIC, isSynthetic);
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

  @Deprecated('Use library instead')
  @override
  LibraryElementImpl get library2 => library;

  LibraryDeclarations get libraryDeclarations {
    return _libraryDeclarations ??= LibraryDeclarations(this);
  }

  @override
  TopLevelFunctionElementImpl get loadLibraryFunction {
    return loadLibraryProvider.getElement(this);
  }

  @Deprecated('Use loadLibraryFunction instead')
  @override
  TopLevelFunctionElementImpl get loadLibraryFunction2 {
    return loadLibraryFunction;
  }

  @override
  String? get lookupName => null;

  @override
  MetadataImpl get metadata {
    _ensureReadResolution();
    return _metadata;
  }

  set metadata(MetadataImpl value) {
    _metadata = value;
  }

  @Deprecated('Use metadata instead')
  @override
  MetadataImpl get metadata2 => metadata;

  @Deprecated('Use name instead')
  @override
  String? get name3 => name;

  @override
  LibraryElementImpl get nonSynthetic => this;

  @override
  Namespace get publicNamespace {
    return _publicNamespace ??= NamespaceBuilder()
        .createPublicNamespaceForLibrary(this);
  }

  set publicNamespace(Namespace publicNamespace) {
    _publicNamespace = publicNamespace;
  }

  // TODO(scheglov): replace with `firstFragment.source`
  Source get source {
    return definingCompilationUnit.source;
  }

  Iterable<FragmentImpl> get topLevelElements sync* {
    for (var unit in units) {
      yield* unit.accessors;
      yield* unit.classes;
      yield* unit.enums;
      yield* unit.extensions;
      yield* unit.extensionTypes;
      yield* unit.functions;
      yield* unit.mixins;
      yield* unit.topLevelVariables;
      yield* unit.typeAliases;
    }
  }

  /// The compilation units this library consists of.
  ///
  /// This includes the defining compilation unit and units included using the
  /// `part` directive.
  List<LibraryFragmentImpl> get units {
    return [definingCompilationUnit, ..._partUnits];
  }

  @override
  Uri get uri => firstFragment.source.uri;

  List<LibraryFragmentImpl> get _partUnits {
    var result = <LibraryFragmentImpl>[];

    void visitParts(LibraryFragmentImpl unit) {
      for (var part in unit.parts) {
        if (part.uri case DirectiveUriWithUnitImpl uri) {
          var unit = uri.libraryFragment;
          result.add(unit);
          visitParts(unit);
        }
      }
    }

    visitParts(definingCompilationUnit);
    return result;
  }

  @override
  T? accept<T>(ElementVisitor2<T> visitor) {
    return visitor.visitLibraryElement(this);
  }

  @Deprecated('Use accept instead')
  @override
  T? accept2<T>(ElementVisitor2<T> visitor) => accept(visitor);

  void addClass(ClassElementImpl element) {
    classes.add(element);
  }

  void addEnum(EnumElementImpl element) {
    enums.add(element);
  }

  void addExtension(ExtensionElementImpl element) {
    extensions.add(element);
  }

  void addExtensionType(ExtensionTypeElementImpl element) {
    extensionTypes.add(element);
  }

  void addGetter(GetterElementImpl element) {
    getters.add(element);
  }

  void addMixin(MixinElementImpl element) {
    mixins.add(element);
  }

  void addSetter(SetterElementImpl element) {
    setters.add(element);
  }

  void addTopLevelFunction(TopLevelFunctionElementImpl element) {
    topLevelFunctions.add(element);
  }

  void addTopLevelVariable(TopLevelVariableElementImpl element) {
    topLevelVariables.add(element);
  }

  @override
  void appendTo(ElementDisplayStringBuilder builder) {
    builder.writeLibraryElement(this);
  }

  @Deprecated('Use displayString instead')
  @override
  String displayString2({
    bool multiline = false,
    bool preferTypeAlias = false,
  }) {
    return displayString(
      multiline: multiline,
      preferTypeAlias: preferTypeAlias,
    );
  }

  @override
  ClassElementImpl? getClass(String name) {
    return _getElementByName(classes, name);
  }

  @Deprecated('Use getClass instead')
  @override
  ClassElementImpl? getClass2(String name) {
    return getClass(name);
  }

  @override
  EnumElement? getEnum(String name) {
    return _getElementByName(enums, name);
  }

  @Deprecated('Use getEnum instead')
  @override
  EnumElement? getEnum2(String name) {
    return getEnum(name);
  }

  @override
  String getExtendedDisplayName({String? shortName}) {
    shortName ??= displayName;
    var source = this.source;
    return "$shortName (${source.fullName})";
  }

  @Deprecated('Use getExtendedDisplayName instead')
  @override
  String getExtendedDisplayName2({String? shortName}) {
    return getExtendedDisplayName(shortName: shortName);
  }

  @override
  ExtensionElement? getExtension(String name) {
    return _getElementByName(extensions, name);
  }

  @override
  ExtensionTypeElementImpl? getExtensionType(String name) {
    return _getElementByName(extensionTypes, name);
  }

  @override
  GetterElement? getGetter(String name) {
    return _getElementByName(getters, name);
  }

  @override
  MixinElement? getMixin(String name) {
    return _getElementByName(mixins, name);
  }

  @Deprecated('Use getMixin instead')
  @override
  MixinElement? getMixin2(String name) {
    return getMixin(name);
  }

  @override
  SetterElement? getSetter(String name) {
    return _getElementByName(setters, name);
  }

  @override
  TopLevelFunctionElement? getTopLevelFunction(String name) {
    return _getElementByName(topLevelFunctions, name);
  }

  @override
  TopLevelVariableElement? getTopLevelVariable(String name) {
    return _getElementByName(topLevelVariables, name);
  }

  @override
  TypeAliasElement? getTypeAlias(String name) {
    return _getElementByName(typeAliases, name);
  }

  @override
  bool isAccessibleIn(LibraryElement library) {
    return true;
  }

  @Deprecated('Use isAccessibleIn instead')
  @override
  bool isAccessibleIn2(LibraryElement library) {
    return isAccessibleIn(library);
  }

  /// Return `true` if [reference] comes only from deprecated exports.
  bool isFromDeprecatedExport(ExportedReference reference) {
    if (reference is ExportedReferenceExported) {
      for (var location in reference.locations) {
        var export = location.exportOf(this);
        if (!export.metadata.hasDeprecated) {
          return false;
        }
      }
      return true;
    }
    return false;
  }

  void resetScope() {
    _libraryDeclarations = null;
    for (var fragment in units) {
      fragment._scope = null;
    }
  }

  @override
  LibraryElementImpl? thisOrAncestorMatching(bool Function(Element) predicate) {
    return predicate(this) ? this : null;
  }

  @Deprecated('Use thisOrAncestorMatching instead')
  @override
  LibraryElementImpl? thisOrAncestorMatching2(
    bool Function(Element) predicate,
  ) {
    return thisOrAncestorMatching(predicate);
  }

  @override
  E? thisOrAncestorOfType<E extends Element>() {
    return E is LibraryElement ? this as E : null;
  }

  @Deprecated('Use thisOrAncestorOfType instead')
  @override
  E? thisOrAncestorOfType2<E extends Element>() {
    return thisOrAncestorOfType();
  }

  @override
  void visitChildren<T>(ElementVisitor2<T> visitor) {
    for (var child in children) {
      child.accept(visitor);
    }
  }

  static T? _getElementByName<T extends Element>(
    List<T> elements,
    String name,
  ) {
    return elements.firstWhereOrNull((e) => e.name == name);
  }
}

class LibraryExportImpl extends ElementDirectiveImpl implements LibraryExport {
  @override
  final List<NamespaceCombinator> combinators;

  @override
  int exportKeywordOffset;

  LibraryExportImpl({
    required super.uri,
    required this.combinators,
    required this.exportKeywordOffset,
  });

  @override
  LibraryElementImpl? get exportedLibrary {
    if (uri case DirectiveUriWithLibraryImpl uri) {
      return uri.library;
    }
    return null;
  }

  @Deprecated('Use exportedLibrary instead')
  @override
  LibraryElementImpl? get exportedLibrary2 {
    return exportedLibrary;
  }

  @override
  void appendTo(ElementDisplayStringBuilder builder) {
    builder.writeLibraryExport(this);
  }
}

/// A concrete implementation of [LibraryFragment].
class LibraryFragmentImpl extends FragmentImpl
    with DeferredResolutionReadingMixin
    implements LibraryFragment {
  @override
  final Source source;

  @override
  LineInfo lineInfo;

  final LibraryElementImpl library;

  /// The libraries exported by this unit.
  List<LibraryExportImpl> _libraryExports = _Sentinel.libraryExport;

  /// The libraries imported by this unit.
  List<LibraryImportImpl> _libraryImports = _Sentinel.libraryImport;

  /// The cached list of prefixes from [prefixes].
  List<PrefixElementImpl>? _libraryImportPrefixes2;

  /// The parts included by this unit.
  List<PartIncludeImpl> _parts = const <PartIncludeImpl>[];

  /// All top-level getters in this compilation unit.
  List<GetterFragmentImpl> _getters = _Sentinel.getterFragment;

  /// All top-level setters in this compilation unit.
  List<SetterFragmentImpl> _setters = _Sentinel.setterFragment;

  List<ClassFragmentImpl> _classes = _Sentinel.classFragment;

  /// A list containing all of the enums contained in this compilation unit.
  List<EnumFragmentImpl> _enums = _Sentinel.enumFragment;

  /// A list containing all of the extensions contained in this compilation
  /// unit.
  List<ExtensionFragmentImpl> _extensions = _Sentinel.extensionFragment;

  List<ExtensionTypeFragmentImpl> _extensionTypes =
      _Sentinel.extensionTypeFragment;

  /// A list containing all of the top-level functions contained in this
  /// compilation unit.
  List<TopLevelFunctionFragmentImpl> _functions =
      _Sentinel.topLevelFunctionFragment;

  List<MixinFragmentImpl> _mixins = _Sentinel.mixinFragment;

  /// A list containing all of the type aliases contained in this compilation
  /// unit.
  List<TypeAliasFragmentImpl> _typeAliases = _Sentinel.typeAliasFragment;

  /// A list containing all of the variables contained in this compilation unit.
  List<TopLevelVariableFragmentImpl> _variables =
      _Sentinel.topLevelVariableFragment;

  /// The scope of this fragment, `null` if it has not been created yet.
  LibraryFragmentScope? _scope;

  LibraryFragmentImpl({
    required this.library,
    required this.source,
    required this.lineInfo,
  }) : super(firstTokenOffset: 0);

  @override
  List<ExtensionElement> get accessibleExtensions {
    return scope.accessibleExtensions;
  }

  @Deprecated('Use accessibleExtensions instead')
  @override
  List<ExtensionElement> get accessibleExtensions2 {
    return accessibleExtensions;
  }

  List<PropertyAccessorFragmentImpl> get accessors {
    return [...getters, ...setters];
  }

  @override
  List<Fragment> get children {
    return [
      ...classes,
      ...enums,
      ...extensions,
      ...extensionTypes,
      ...functions,
      ...getters,
      ...mixins,
      ...setters,
      ...typeAliases,
      ...topLevelVariables,
    ];
  }

  @Deprecated('Use children instead')
  @override
  List<Fragment> get children3 {
    return children;
  }

  @override
  List<ClassFragmentImpl> get classes => _classes;

  /// Set the classes contained in this compilation unit to [classes].
  set classes(List<ClassFragmentImpl> classes) {
    for (var class_ in classes) {
      class_.enclosingFragment = this;
    }
    _classes = classes;
  }

  @Deprecated('Use classes instead')
  @override
  List<ClassFragment> get classes2 => classes;

  @override
  LibraryElementImpl get element => library;

  @override
  LibraryFragmentImpl? get enclosingFragment =>
      super.enclosingFragment as LibraryFragmentImpl?;

  @override
  LibraryFragmentImpl get enclosingUnit {
    return this;
  }

  @override
  List<EnumFragmentImpl> get enums => _enums;

  /// Set the enums contained in this compilation unit to the given [enums].
  set enums(List<EnumFragmentImpl> enums) {
    for (var element in enums) {
      element.enclosingFragment = this;
    }
    _enums = enums;
  }

  @Deprecated('Use enums instead')
  @override
  List<EnumFragment> get enums2 => enums;

  @override
  List<ExtensionFragmentImpl> get extensions => _extensions;

  /// Set the extensions contained in this compilation unit to the given
  /// [extensions].
  set extensions(List<ExtensionFragmentImpl> extensions) {
    for (var extension in extensions) {
      extension.enclosingFragment = this;
    }
    _extensions = extensions;
  }

  @Deprecated('Use extensions instead')
  @override
  List<ExtensionFragment> get extensions2 => extensions;

  @override
  List<ExtensionTypeFragmentImpl> get extensionTypes => _extensionTypes;

  set extensionTypes(List<ExtensionTypeFragmentImpl> elements) {
    for (var element in elements) {
      element.enclosingFragment = this;
    }
    _extensionTypes = elements;
  }

  @Deprecated('Use extensionTypes instead')
  @override
  List<ExtensionTypeFragment> get extensionTypes2 => extensionTypes;

  @override
  List<TopLevelFunctionFragmentImpl> get functions {
    return _functions;
  }

  /// Set the top-level functions contained in this compilation unit to the
  ///  given[functions].
  set functions(List<TopLevelFunctionFragmentImpl> functions) {
    for (var function in functions) {
      function.enclosingFragment = this;
    }
    _functions = functions;
  }

  @Deprecated('Use functions instead')
  @override
  List<TopLevelFunctionFragment> get functions2 => functions;

  @override
  List<GetterFragmentImpl> get getters => _getters;

  set getters(List<GetterFragmentImpl> getters) {
    for (var getter in getters) {
      getter.enclosingFragment = this;
    }
    _getters = getters;
  }

  @override
  int get hashCode => source.hashCode;

  @override
  List<LibraryElement> get importedLibraries {
    return libraryImports
        .map((import) => import.importedLibrary)
        .nonNulls
        .toSet()
        .toList();
  }

  @Deprecated('Use importedLibraries instead')
  @override
  List<LibraryElement> get importedLibraries2 {
    return importedLibraries;
  }

  @override
  List<LibraryExportImpl> get libraryExports {
    _ensureReadResolution();
    return _libraryExports;
  }

  set libraryExports(List<LibraryExportImpl> exports) {
    for (var exportElement in exports) {
      exportElement.libraryFragment = this;
    }
    _libraryExports = exports;
  }

  @Deprecated('Use libraryExports instead')
  @override
  List<LibraryExport> get libraryExports2 => libraryExports;

  @override
  LibraryFragment get libraryFragment => this;

  @override
  List<LibraryImportImpl> get libraryImports {
    _ensureReadResolution();
    return _libraryImports;
  }

  set libraryImports(List<LibraryImportImpl> imports) {
    for (var importElement in imports) {
      importElement.libraryFragment = this;
    }
    _libraryImports = imports;
  }

  @Deprecated('Use libraryImports instead')
  @override
  List<LibraryImport> get libraryImports2 => libraryImports;

  @override
  List<MixinFragmentImpl> get mixins => _mixins;

  /// Set the mixins contained in this compilation unit to the given [mixins].
  set mixins(List<MixinFragmentImpl> mixins) {
    for (var mixin_ in mixins) {
      mixin_.enclosingFragment = this;
    }
    _mixins = mixins;
  }

  @Deprecated('Use mixins instead')
  @override
  List<MixinFragment> get mixins2 => mixins;

  @override
  String? get name => null;

  @Deprecated('Use name instead')
  @override
  String? get name2 => name;

  @override
  int? get nameOffset => null;

  @override
  LibraryFragment? get nextFragment {
    var units = library.units;
    var index = units.indexOf(this);
    return units.elementAtOrNull(index + 1);
  }

  @override
  int get offset {
    if (!identical(this, library.definingCompilationUnit)) {
      // Not the first fragment, so there is no name; return an offset of 0
      return 0;
    }
    if (library.nameOffset < 0) {
      // There is no name, so return an offset of 0
      return 0;
    }
    return library.nameOffset;
  }

  @override
  List<PartInclude> get partIncludes => parts.cast<PartInclude>();

  /// The parts included by this unit.
  List<PartIncludeImpl> get parts => _parts;

  set parts(List<PartIncludeImpl> parts) {
    for (var part in parts) {
      part.libraryFragment = this;
      if (part.uri case DirectiveUriWithUnitImpl uri) {
        uri.libraryFragment.enclosingFragment = this;
      }
    }
    _parts = parts;
  }

  @override
  List<PrefixElementImpl> get prefixes {
    return _libraryImportPrefixes2 ??= _buildLibraryImportPrefixes();
  }

  @override
  LibraryFragment? get previousFragment {
    var units = library.units;
    var index = units.indexOf(this);
    if (index >= 1) {
      return units[index - 1];
    }
    return null;
  }

  @override
  LibraryFragmentScope get scope {
    return _scope ??= LibraryFragmentScope(this);
  }

  @override
  AnalysisSession get session => library.session;

  @override
  List<SetterFragmentImpl> get setters => _setters;

  set setters(List<SetterFragmentImpl> setters) {
    for (var setter in setters) {
      setter.enclosingFragment = this;
    }
    _setters = setters;
  }

  @override
  List<TopLevelVariableFragmentImpl> get topLevelVariables => _variables;

  /// Set the top-level variables contained in this compilation unit to the
  ///  given[variables].
  set topLevelVariables(List<TopLevelVariableFragmentImpl> variables) {
    for (var variable in variables) {
      variable.enclosingFragment = this;
    }
    _variables = variables;
  }

  @Deprecated('Use topLevelVariables instead')
  @override
  List<TopLevelVariableFragment> get topLevelVariables2 => topLevelVariables;

  @override
  List<TypeAliasFragmentImpl> get typeAliases {
    return _typeAliases;
  }

  /// Set the type aliases contained in this compilation unit to [typeAliases].
  set typeAliases(List<TypeAliasFragmentImpl> typeAliases) {
    for (var typeAlias in typeAliases) {
      typeAlias.enclosingFragment = this;
    }
    _typeAliases = typeAliases;
  }

  @Deprecated('Use typeAliases instead')
  @override
  List<TypeAliasFragment> get typeAliases2 => typeAliases;

  void addClass(ClassFragmentImpl fragment) {
    if (identical(_classes, _Sentinel.classFragment)) {
      _classes = [];
    }
    _classes.add(fragment);
    fragment.enclosingFragment = this;
  }

  void addEnum(EnumFragmentImpl fragment) {
    if (identical(_enums, _Sentinel.enumFragment)) {
      _enums = [];
    }
    _enums.add(fragment);
    fragment.enclosingFragment = this;
  }

  void addExtension(ExtensionFragmentImpl fragment) {
    if (identical(_extensions, _Sentinel.extensionFragment)) {
      _extensions = [];
    }
    _extensions.add(fragment);
    fragment.enclosingFragment = this;
  }

  void addExtensionType(ExtensionTypeFragmentImpl fragment) {
    if (identical(_extensionTypes, _Sentinel.extensionTypeFragment)) {
      _extensionTypes = [];
    }
    _extensionTypes.add(fragment);
    fragment.enclosingFragment = this;
  }

  void addFunction(TopLevelFunctionFragmentImpl fragment) {
    if (identical(_functions, _Sentinel.topLevelFunctionFragment)) {
      _functions = [];
    }
    _functions.add(fragment);
    fragment.enclosingFragment = this;
  }

  void addGetter(GetterFragmentImpl fragment) {
    if (identical(_getters, _Sentinel.getterFragment)) {
      _getters = [];
    }
    _getters.add(fragment);
    fragment.enclosingFragment = this;
  }

  void addMixin(MixinFragmentImpl fragment) {
    if (identical(_mixins, _Sentinel.mixinFragment)) {
      _mixins = [];
    }
    _mixins.add(fragment);
    fragment.enclosingFragment = this;
  }

  void addSetter(SetterFragmentImpl fragment) {
    if (identical(_setters, _Sentinel.setterFragment)) {
      _setters = [];
    }
    _setters.add(fragment);
    fragment.enclosingFragment = this;
  }

  void addTopLevelVariable(TopLevelVariableFragmentImpl fragment) {
    if (identical(_variables, _Sentinel.topLevelVariableFragment)) {
      _variables = [];
    }
    _variables.add(fragment);
    fragment.enclosingFragment = this;
  }

  void addTypeAlias(TypeAliasFragmentImpl fragment) {
    if (identical(_typeAliases, _Sentinel.typeAliasFragment)) {
      _typeAliases = [];
    }
    _typeAliases.add(fragment);
    fragment.enclosingFragment = this;
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
  bool shouldIgnoreUndefined({required String? prefix, required String name}) {
    for (var libraryFragment in withEnclosing) {
      for (var importElement in libraryFragment.libraryImports) {
        if (importElement.prefix?.element.name == prefix &&
            importElement.importedLibrary?.isSynthetic != false) {
          var showCombinators =
              importElement.combinators
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
    }

    if (prefix == null && name.startsWith(r'_$')) {
      for (var partElement in parts) {
        var uri = partElement.uri;
        if (uri is DirectiveUriWithSourceImpl &&
            uri is! DirectiveUriWithUnitImpl &&
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
      name: node.name.lexeme,
    );
  }

  List<PrefixElementImpl> _buildLibraryImportPrefixes() {
    var prefixes = <PrefixElementImpl>{};
    for (var import in libraryImports) {
      var prefix = import.prefix?.element;
      if (prefix != null) {
        prefixes.add(prefix);
      }
    }
    return prefixes.toFixedList();
  }
}

class LibraryImportImpl extends ElementDirectiveImpl implements LibraryImport {
  @override
  final bool isSynthetic;

  @override
  final List<NamespaceCombinator> combinators;

  @override
  int importKeywordOffset;

  @override
  final PrefixFragmentImpl? prefix;

  Namespace? _namespace;

  LibraryImportImpl({
    required super.uri,
    required this.isSynthetic,
    required this.combinators,
    required this.importKeywordOffset,
    required this.prefix,
  });

  @override
  LibraryElementImpl? get importedLibrary {
    if (uri case DirectiveUriWithLibraryImpl uri) {
      return uri.library;
    }
    return null;
  }

  @Deprecated('Use importedLibrary instead')
  @override
  LibraryElementImpl? get importedLibrary2 {
    return importedLibrary;
  }

  @override
  Namespace get namespace {
    var uri = this.uri;
    if (uri is DirectiveUriWithLibraryImpl) {
      return _namespace ??= NamespaceBuilder()
          .createImportNamespaceForDirective(
            importedLibrary: uri.library,
            combinators: combinators,
            prefix: prefix,
          );
    }
    return Namespace.EMPTY;
  }

  @Deprecated('Use prefix instead')
  @override
  PrefixFragment? get prefix2 => prefix;

  @override
  void appendTo(ElementDisplayStringBuilder builder) {
    builder.writeLibraryImport(this);
  }
}

/// The provider for the lazily created `loadLibrary` function.
final class LoadLibraryFunctionProvider {
  final Reference elementReference;
  TopLevelFunctionElementImpl? _element;

  LoadLibraryFunctionProvider({required this.elementReference});

  TopLevelFunctionElementImpl getElement(LibraryElementImpl library) {
    return _element ??= _create(library);
  }

  TopLevelFunctionElementImpl _create(LibraryElementImpl library) {
    var name = TopLevelFunctionElement.LOAD_LIBRARY_NAME;

    var fragment = TopLevelFunctionFragmentImpl(name: name);
    fragment.isSynthetic = true;
    fragment.isStatic = true;
    fragment.enclosingFragment = library.definingCompilationUnit;

    return TopLevelFunctionElementImpl(elementReference, fragment)
      ..returnType = library.typeProvider.futureDynamicType;
  }
}

class LocalFunctionElementImpl extends ExecutableElementImpl
    implements LocalFunctionElement {
  final LocalFunctionFragmentImpl _wrappedFragment;

  LocalFunctionElementImpl(this._wrappedFragment);

  @override
  // Local functions belong to Fragments, not Elements.
  Element? get enclosingElement => null;

  @Deprecated('Use enclosingElement instead')
  @override
  Element? get enclosingElement2 => enclosingElement;

  @override
  LocalFunctionFragmentImpl get firstFragment => _wrappedFragment;

  @override
  List<LocalFunctionFragmentImpl> get fragments {
    return [
      for (
        LocalFunctionFragmentImpl? fragment = firstFragment;
        fragment != null;
        fragment = fragment.nextFragment
      )
        fragment,
    ];
  }

  @override
  ElementKind get kind => ElementKind.FUNCTION;

  @override
  String? get name => _wrappedFragment.name;

  @Deprecated('Use name instead')
  @override
  String? get name3 => name;

  FunctionFragmentImpl get wrappedElement {
    return _wrappedFragment;
  }

  @override
  T? accept<T>(ElementVisitor2<T> visitor) {
    return visitor.visitLocalFunctionElement(this);
  }

  @Deprecated('Use accept instead')
  @override
  T? accept2<T>(ElementVisitor2<T> visitor) => accept(visitor);

  @override
  void appendTo(ElementDisplayStringBuilder builder) {
    builder.writeLocalFunctionElement(this);
  }

  @Deprecated('Use displayString instead')
  @override
  String displayString2({
    bool multiline = false,
    bool preferTypeAlias = false,
  }) => displayString(multiline: multiline, preferTypeAlias: preferTypeAlias);
}

/// A concrete implementation of a [LocalFunctionFragment].
class LocalFunctionFragmentImpl extends FunctionFragmentImpl
    implements LocalFunctionFragment {
  /// The element corresponding to this fragment.
  @override
  late final LocalFunctionElementImpl element = LocalFunctionElementImpl(this);

  @override
  LocalFunctionFragmentImpl? previousFragment;

  @override
  LocalFunctionFragmentImpl? nextFragment;

  LocalFunctionFragmentImpl({
    required super.name,
    required super.firstTokenOffset,
  });

  @override
  bool get _includeNameOffsetInIdentifier {
    return super._includeNameOffsetInIdentifier ||
        enclosingFragment is ExecutableFragment ||
        enclosingFragment is VariableFragment;
  }
}

class LocalVariableElementImpl extends PromotableElementImpl
    implements LocalVariableElement {
  final LocalVariableFragmentImpl _wrappedElement;

  @override
  TypeImpl type = InvalidTypeImpl.instance;

  LocalVariableElementImpl(this._wrappedElement);

  @override
  LocalVariableElement get baseElement => this;

  @override
  String? get documentationComment => null;

  @override
  Element? get enclosingElement {
    return _wrappedElement.enclosingFragment.element;
  }

  @Deprecated('Use enclosingElement instead')
  @override
  Element? get enclosingElement2 => enclosingElement;

  @override
  LocalVariableFragmentImpl get firstFragment => _wrappedElement;

  @override
  List<LocalVariableFragmentImpl> get fragments {
    return [firstFragment];
  }

  @override
  bool get hasImplicitType => _wrappedElement.hasImplicitType;

  @override
  bool get isConst => _wrappedElement.isConst;

  @override
  bool get isFinal => _wrappedElement.isFinal;

  @override
  bool get isLate => _wrappedElement.isLate;

  @override
  bool get isStatic => _wrappedElement.isStatic;

  @override
  bool get isSynthetic => _wrappedElement.isSynthetic;

  @override
  ElementKind get kind => ElementKind.LOCAL_VARIABLE;

  @override
  LibraryElementImpl get library => super.library!;

  @Deprecated('Use library instead')
  @override
  LibraryElementImpl get library2 => library;

  @override
  MetadataImpl get metadata => _wrappedElement.metadata;

  @Deprecated('Use metadata instead')
  @override
  MetadataImpl get metadata2 => metadata;

  @override
  String? get name => _wrappedElement.name;

  @Deprecated('Use name instead')
  @override
  String? get name3 => name;

  @override
  T? accept<T>(ElementVisitor2<T> visitor) {
    return visitor.visitLocalVariableElement(this);
  }

  @Deprecated('Use accept instead')
  @override
  T? accept2<T>(ElementVisitor2<T> visitor) => accept(visitor);

  @Deprecated('Use displayString instead')
  @override
  String displayString2({
    bool multiline = false,
    bool preferTypeAlias = false,
  }) {
    return displayString(
      multiline: multiline,
      preferTypeAlias: preferTypeAlias,
    );
  }
}

class LocalVariableFragmentImpl extends NonParameterVariableFragmentImpl
    implements LocalVariableFragment {
  late LocalVariableElementImpl _element2 = switch (this) {
    BindPatternVariableFragmentImpl() => BindPatternVariableElementImpl(this),
    JoinPatternVariableFragmentImpl() => JoinPatternVariableElementImpl(this),
    PatternVariableFragmentImpl() => PatternVariableElementImpl(this),
    _ => LocalVariableElementImpl(this),
  };

  @override
  final String? name;

  @override
  int? nameOffset;

  /// Initialize a newly created method element to have the given [name] and
  /// [offset].
  LocalVariableFragmentImpl({
    required this.name,
    required super.firstTokenOffset,
  });

  @override
  List<Fragment> get children => const [];

  @Deprecated('Use children instead')
  @override
  List<Fragment> get children3 => children;

  @override
  LocalVariableElementImpl get element => _element2;

  @override
  LibraryFragmentImpl get libraryFragment => enclosingUnit;

  @override
  LocalVariableFragmentImpl? get nextFragment => null;

  @override
  LocalVariableFragmentImpl? get previousFragment => null;
}

final class MetadataImpl implements Metadata {
  static final MetadataImpl empty = MetadataImpl(const []);

  static const _isReady = 1 << 0;
  static const _hasDeprecated = 1 << 1;
  static const _hasOverride = 1 << 2;

  /// Cached flags denoting presence of specific annotations.
  int _metadataFlags2 = 0;

  @override
  final List<ElementAnnotationImpl> annotations;

  MetadataImpl(this.annotations);

  @override
  bool get hasAlwaysThrows {
    var annotations = this.annotations;
    for (var i = 0; i < annotations.length; i++) {
      var annotation = annotations[i];
      if (annotation.isAlwaysThrows) {
        return true;
      }
    }
    return false;
  }

  @override
  bool get hasAwaitNotRequired {
    var annotations = this.annotations;
    for (var i = 0; i < annotations.length; i++) {
      var annotation = annotations[i];
      if (annotation.isAwaitNotRequired) {
        return true;
      }
    }
    return false;
  }

  @override
  bool get hasDeprecated {
    return (_getMetadataFlags() & _hasDeprecated) != 0;
  }

  @override
  bool get hasDoNotStore {
    var annotations = this.annotations;
    for (var i = 0; i < annotations.length; i++) {
      var annotation = annotations[i];
      if (annotation.isDoNotStore) {
        return true;
      }
    }
    return false;
  }

  @override
  bool get hasDoNotSubmit {
    var annotations = this.annotations;
    for (var i = 0; i < annotations.length; i++) {
      var annotation = annotations[i];
      if (annotation.isDoNotSubmit) {
        return true;
      }
    }
    return false;
  }

  @override
  bool get hasExperimental {
    var annotations = this.annotations;
    for (var i = 0; i < annotations.length; i++) {
      var annotation = annotations[i];
      if (annotation.isExperimental) {
        return true;
      }
    }
    return false;
  }

  @override
  bool get hasFactory {
    var annotations = this.annotations;
    for (var i = 0; i < annotations.length; i++) {
      var annotation = annotations[i];
      if (annotation.isFactory) {
        return true;
      }
    }
    return false;
  }

  @override
  bool get hasImmutable {
    var annotations = this.annotations;
    for (var i = 0; i < annotations.length; i++) {
      var annotation = annotations[i];
      if (annotation.isImmutable) {
        return true;
      }
    }
    return false;
  }

  @override
  bool get hasInternal {
    var annotations = this.annotations;
    for (var i = 0; i < annotations.length; i++) {
      var annotation = annotations[i];
      if (annotation.isInternal) {
        return true;
      }
    }
    return false;
  }

  @override
  bool get hasIsTest {
    var annotations = this.annotations;
    for (var i = 0; i < annotations.length; i++) {
      var annotation = annotations[i];
      if (annotation.isIsTest) {
        return true;
      }
    }
    return false;
  }

  @override
  bool get hasIsTestGroup {
    var annotations = this.annotations;
    for (var i = 0; i < annotations.length; i++) {
      var annotation = annotations[i];
      if (annotation.isIsTestGroup) {
        return true;
      }
    }
    return false;
  }

  @override
  bool get hasJS {
    var annotations = this.annotations;
    for (var i = 0; i < annotations.length; i++) {
      var annotation = annotations[i];
      if (annotation.isJS) {
        return true;
      }
    }
    return false;
  }

  @override
  bool get hasLiteral {
    var annotations = this.annotations;
    for (var i = 0; i < annotations.length; i++) {
      var annotation = annotations[i];
      if (annotation.isLiteral) {
        return true;
      }
    }
    return false;
  }

  @override
  bool get hasMustBeConst {
    var annotations = this.annotations;
    for (var i = 0; i < annotations.length; i++) {
      var annotation = annotations[i];
      if (annotation.isMustBeConst) {
        return true;
      }
    }
    return false;
  }

  @override
  bool get hasMustBeOverridden {
    var annotations = this.annotations;
    for (var i = 0; i < annotations.length; i++) {
      var annotation = annotations[i];
      if (annotation.isMustBeOverridden) {
        return true;
      }
    }
    return false;
  }

  @override
  bool get hasMustCallSuper {
    var annotations = this.annotations;
    for (var i = 0; i < annotations.length; i++) {
      var annotation = annotations[i];
      if (annotation.isMustCallSuper) {
        return true;
      }
    }
    return false;
  }

  @override
  bool get hasNonVirtual {
    var annotations = this.annotations;
    for (var i = 0; i < annotations.length; i++) {
      var annotation = annotations[i];
      if (annotation.isNonVirtual) {
        return true;
      }
    }
    return false;
  }

  @override
  bool get hasOptionalTypeArgs {
    var annotations = this.annotations;
    for (var i = 0; i < annotations.length; i++) {
      var annotation = annotations[i];
      if (annotation.isOptionalTypeArgs) {
        return true;
      }
    }
    return false;
  }

  @override
  bool get hasOverride {
    return (_getMetadataFlags() & _hasOverride) != 0;
  }

  /// Return `true` if this element has an annotation of the form
  /// `@pragma("vm:entry-point")`.
  bool get hasPragmaVmEntryPoint {
    var annotations = this.annotations;
    for (var i = 0; i < annotations.length; i++) {
      var annotation = annotations[i];
      if (annotation.isPragmaVmEntryPoint) {
        return true;
      }
    }
    return false;
  }

  @override
  bool get hasProtected {
    var annotations = this.annotations;
    for (var i = 0; i < annotations.length; i++) {
      var annotation = annotations[i];
      if (annotation.isProtected) {
        return true;
      }
    }
    return false;
  }

  @override
  bool get hasRedeclare {
    var annotations = this.annotations;
    for (var i = 0; i < annotations.length; i++) {
      var annotation = annotations[i];
      if (annotation.isRedeclare) {
        return true;
      }
    }
    return false;
  }

  @override
  bool get hasReopen {
    var annotations = this.annotations;
    for (var i = 0; i < annotations.length; i++) {
      var annotation = annotations[i];
      if (annotation.isReopen) {
        return true;
      }
    }
    return false;
  }

  @override
  bool get hasRequired {
    var annotations = this.annotations;
    for (var i = 0; i < annotations.length; i++) {
      var annotation = annotations[i];
      if (annotation.isRequired) {
        return true;
      }
    }
    return false;
  }

  @override
  bool get hasSealed {
    var annotations = this.annotations;
    for (var i = 0; i < annotations.length; i++) {
      var annotation = annotations[i];
      if (annotation.isSealed) {
        return true;
      }
    }
    return false;
  }

  @override
  bool get hasUseResult {
    var annotations = this.annotations;
    for (var i = 0; i < annotations.length; i++) {
      var annotation = annotations[i];
      if (annotation.isUseResult) {
        return true;
      }
    }
    return false;
  }

  @override
  bool get hasVisibleForOverriding {
    var annotations = this.annotations;
    for (var i = 0; i < annotations.length; i++) {
      var annotation = annotations[i];
      if (annotation.isVisibleForOverriding) {
        return true;
      }
    }
    return false;
  }

  @override
  bool get hasVisibleForTemplate {
    var annotations = this.annotations;
    for (var i = 0; i < annotations.length; i++) {
      var annotation = annotations[i];
      if (annotation.isVisibleForTemplate) {
        return true;
      }
    }
    return false;
  }

  @override
  bool get hasVisibleForTesting {
    var annotations = this.annotations;
    for (var i = 0; i < annotations.length; i++) {
      var annotation = annotations[i];
      if (annotation.isVisibleForTesting) {
        return true;
      }
    }
    return false;
  }

  @override
  bool get hasVisibleOutsideTemplate {
    var annotations = this.annotations;
    for (var i = 0; i < annotations.length; i++) {
      var annotation = annotations[i];
      if (annotation.isVisibleOutsideTemplate) {
        return true;
      }
    }
    return false;
  }

  @override
  bool get hasWidgetFactory {
    var annotations = this.annotations;
    for (var i = 0; i < annotations.length; i++) {
      var annotation = annotations[i];
      if (annotation.isWidgetFactory) {
        return true;
      }
    }
    return false;
  }

  void resetCache() {
    _metadataFlags2 = 0;
  }

  /// Return flags that denote presence of a few specific annotations.
  int _getMetadataFlags() {
    var result = _metadataFlags2;

    // Has at least `_metadataFlag_isReady`.
    if (result != 0) {
      return result;
    }

    for (var i = 0; i < annotations.length; i++) {
      var annotation = annotations[i];
      if (annotation.isDeprecated) {
        result |= _hasDeprecated;
      } else if (annotation.isOverride) {
        result |= _hasOverride;
      }
    }

    result |= _isReady;
    return _metadataFlags2 = result;
  }
}

class MethodElementImpl extends ExecutableElementImpl
    with InternalMethodElement {
  @override
  final Reference reference;

  @override
  final String? name;

  @override
  final MethodFragmentImpl firstFragment;

  /// Is `true` if this method is `operator==`, and there is no explicit
  /// type specified for its formal parameter, in this method or in any
  /// overridden methods other than the one declared in `Object`.
  bool isOperatorEqualWithParameterTypeFromObject = false;

  /// The error reported during type inference for this variable, or `null` if
  /// this variable is not a subject of type inference, or there was no error.
  TopLevelInferenceError? typeInferenceError;

  MethodElementImpl({
    required this.name,
    required this.reference,
    required this.firstFragment,
  }) {
    reference.element = this;
    firstFragment.element = this;
  }

  @override
  MethodElementImpl get baseElement => this;

  @override
  String get displayName {
    return lookupName ?? '<unnamed>';
  }

  @override
  InstanceElementImpl get enclosingElement {
    return firstFragment.enclosingFragment.element;
  }

  @Deprecated('Use enclosingElement instead')
  @override
  Element? get enclosingElement2 => enclosingElement;

  @override
  List<MethodFragmentImpl> get fragments {
    return [
      for (
        MethodFragmentImpl? fragment = firstFragment;
        fragment != null;
        fragment = fragment.nextFragment
      )
        fragment,
    ];
  }

  @override
  bool get isOperator => firstFragment.isOperator;

  @override
  ElementKind get kind => ElementKind.METHOD;

  @override
  MethodFragmentImpl get lastFragment {
    return super.lastFragment as MethodFragmentImpl;
  }

  @override
  String? get lookupName {
    if (name == '-' && formalParameters.isEmpty) {
      return 'unary-';
    }
    return name;
  }

  @Deprecated('Use name instead')
  @override
  String? get name3 => name;

  @override
  T? accept<T>(ElementVisitor2<T> visitor) {
    return visitor.visitMethodElement(this);
  }

  @Deprecated('Use accept instead')
  @override
  T? accept2<T>(ElementVisitor2<T> visitor) => accept(visitor);

  @override
  void appendTo(ElementDisplayStringBuilder builder) {
    builder.writeMethodElement(this);
  }

  void linkFragments(List<MethodFragmentImpl> fragments) {
    assert(identical(fragments[0], firstFragment));
    fragments.reduce((previous, current) {
      previous.addFragment(current);
      return current;
    });
  }
}

class MethodFragmentImpl extends ExecutableFragmentImpl
    implements MethodFragment {
  @override
  late final MethodElementImpl element;

  @override
  final String? name;

  @override
  int? nameOffset;

  @override
  MethodFragmentImpl? previousFragment;

  @override
  MethodFragmentImpl? nextFragment;

  /// Initialize a newly created method element to have the given [name] at the
  /// given [offset].
  MethodFragmentImpl({required this.name});

  @override
  MethodFragmentImpl get declaration => this;

  @override
  String get displayName {
    String displayName = super.displayName;
    if ("unary-" == displayName) {
      return "-";
    }
    return displayName;
  }

  @override
  InstanceFragmentImpl get enclosingFragment =>
      super.enclosingFragment as InstanceFragmentImpl;

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
  String? get lookupName {
    if (name == '-' && formalParameters.isEmpty) {
      return 'unary-';
    }
    return name;
  }

  void addFragment(MethodFragmentImpl fragment) {
    fragment.element = element;
    fragment.previousFragment = this;
    nextFragment = fragment;
  }
}

class MixinElementImpl extends InterfaceElementImpl implements MixinElement {
  @override
  final Reference reference;

  @override
  final MixinFragmentImpl firstFragment;

  List<InterfaceTypeImpl> _superclassConstraints = const [];

  MixinElementImpl(this.reference, this.firstFragment) {
    reference.element = this;
    firstFragment.element = this;

    isBase = firstFragment.isBase;
  }

  @override
  List<MixinFragmentImpl> get fragments {
    return [
      for (
        MixinFragmentImpl? fragment = firstFragment;
        fragment != null;
        fragment = fragment.nextFragment
      )
        fragment,
    ];
  }

  @override
  bool get isBase {
    return hasModifier(Modifier.BASE);
  }

  set isBase(bool isBase) {
    setModifier(Modifier.BASE, isBase);
  }

  @override
  bool get isImplementableOutside => !isBase;

  @override
  ElementKind get kind => ElementKind.MIXIN;

  @override
  set mixins(List<InterfaceType> mixins) {
    throw StateError('Attempt to set mixins for a mixin declaration.');
  }

  @override
  List<InterfaceTypeImpl> get superclassConstraints {
    _ensureReadResolution();
    return _superclassConstraints;
  }

  set superclassConstraints(List<InterfaceTypeImpl> value) {
    _superclassConstraints = value;
  }

  /// Names of methods, getters, setters, and operators that this mixin
  /// declaration super-invokes.  For setters this includes the trailing "=".
  /// The list will be empty if this class is not a mixin declaration.
  List<String> get superInvokedNames => firstFragment.superInvokedNames;

  @override
  set supertype(InterfaceType? supertype) {
    throw StateError('Attempt to set a supertype for a mixin declaration.');
  }

  @override
  T? accept<T>(ElementVisitor2<T> visitor) {
    return visitor.visitMixinElement(this);
  }

  @Deprecated('Use accept instead')
  @override
  T? accept2<T>(ElementVisitor2<T> visitor) => accept(visitor);

  @override
  void appendTo(ElementDisplayStringBuilder builder) {
    builder.writeMixinElement(this);
  }

  @Deprecated('Use isImplementableOutside instead')
  @override
  bool isImplementableIn(LibraryElement library) {
    if (library == this.library) {
      return true;
    }
    return !isBase;
  }

  @Deprecated('Use isImplementableOutside instead')
  @override
  bool isImplementableIn2(LibraryElement library) {
    return isImplementableIn(library);
  }

  void linkFragments(List<MixinFragmentImpl> fragments) {
    assert(identical(fragments[0], firstFragment));
    fragments.reduce((previous, current) {
      previous.addFragment(current);
      return current;
    });
  }
}

/// A [ClassFragmentImpl] representing a mixin declaration.
@GenerateFragmentImpl(modifiers: _MixinFragmentImplModifiers.values)
class MixinFragmentImpl extends InterfaceFragmentImpl
    with _MixinFragmentImplMixin
    implements MixinFragment {
  @override
  late final MixinElementImpl element;

  /// Names of methods, getters, setters, and operators that this mixin
  /// declaration super-invokes.  For setters this includes the trailing "=".
  /// The list will be empty if this class is not a mixin declaration.
  late List<String> superInvokedNames;

  /// Initialize a newly created class element to have the given [name] at the
  /// given [offset] in the file that contains the declaration of this element.
  MixinFragmentImpl({required super.name});

  @override
  List<InterfaceTypeImpl> get mixins => const [];

  @override
  MixinFragmentImpl? get nextFragment =>
      super.nextFragment as MixinFragmentImpl?;

  @override
  MixinFragmentImpl? get previousFragment =>
      super.previousFragment as MixinFragmentImpl?;

  @override
  List<InterfaceTypeImpl> get superclassConstraints {
    return element.superclassConstraints;
  }

  @override
  InterfaceTypeImpl? get supertype => null;

  void addFragment(MixinFragmentImpl fragment) {
    fragment.element = element;
    fragment.previousFragment = this;
    nextFragment = fragment;
  }
}

/// The constants for all of the modifiers defined by the Dart language and for
/// a few additional flags that are useful.
///
/// Clients may not extend, implement or mix-in this class.
enum Modifier {
  /// Indicates that the modifier 'abstract' was applied to the element.
  ABSTRACT,

  /// Indicates that an executable element has a body marked as being
  /// asynchronous.
  ASYNCHRONOUS,

  /// Indicates that the modifier 'augment' was applied to the element.
  AUGMENTATION,

  /// Indicates that the element is the start of the augmentation chain,
  /// in the simplest case - the declaration. But could be an augmentation
  /// that has no augmented declaration (which is a compile-time error).
  AUGMENTATION_CHAIN_START,

  /// Indicates that the modifier 'base' was applied to the element.
  BASE,

  /// Indicates that the modifier 'const' was applied to the element.
  CONST,

  /// Indicates that the modifier 'covariant' was applied to the element.
  EXPLICITLY_COVARIANT,

  /// Indicates that the class is `Object` from `dart:core`.
  DART_CORE_OBJECT,

  /// Indicates that the import element represents a deferred library.
  DEFERRED,

  /// Indicates that a class element was defined by an enum declaration.
  ENUM,

  /// Indicates that the element is an enum constant field.
  ENUM_CONSTANT,

  /// Indicates that the element is an extension type member.
  EXTENSION_TYPE_MEMBER,

  /// Indicates that a class element was defined by an enum declaration.
  EXTERNAL,

  /// Indicates that the modifier 'factory' was applied to the element.
  FACTORY,

  /// Indicates that the modifier 'final' was applied to the element.
  FINAL,

  /// Indicates that an executable element has a body marked as being a
  /// generator.
  GENERATOR,

  /// Indicates that the pseudo-modifier 'get' was applied to the element.
  GETTER,

  /// Indicates that this class has an explicit `extends` clause.
  HAS_EXTENDS_CLAUSE,

  /// A flag used for libraries indicating that the variable has an explicit
  /// initializer.
  HAS_INITIALIZER,

  /// A flag used for libraries indicating that the defining compilation unit
  /// has a `part of` directive, meaning that this unit should be a part,
  /// but is used as a library.
  HAS_PART_OF_DIRECTIVE,

  /// Indicates that the value of [FragmentImpl.sinceSdkVersion] was computed.
  HAS_SINCE_SDK_VERSION_COMPUTED,

  /// [HAS_SINCE_SDK_VERSION_COMPUTED] and the value was not `null`.
  HAS_SINCE_SDK_VERSION_VALUE,

  /// Indicates that the associated element did not have an explicit type
  /// associated with it.
  HAS_IMPLICIT_TYPE,

  /// Indicates that the associated [ExecutableElement] did
  /// not have an explicit return type associated with it.
  HAS_IMPLICIT_RETURN_TYPE,

  /// Indicates that the modifier 'interface' was applied to the element.
  INTERFACE,

  /// Indicates that the method invokes the super method with the same name.
  INVOKES_SUPER_SELF,

  /// Indicates that modifier 'lazy' was applied to the element.
  LATE,

  /// Indicates that a class is a mixin application.
  MIXIN_APPLICATION,

  /// Indicates that a class is a mixin class.
  MIXIN_CLASS,

  /// Whether the type of this fragment references a type parameter of the
  /// enclosing element. This includes not only explicitly specified type
  /// annotations, but also inferred types.
  NO_ENCLOSING_TYPE_PARAMETER_REFERENCE,
  PROMOTABLE,

  /// Indicates whether the type of a [PropertyInducingFragmentImpl] should be
  /// used to infer the initializer. We set it to `false` if the type was
  /// inferred from the initializer itself.
  SHOULD_USE_TYPE_FOR_INITIALIZER_INFERENCE,

  /// Indicates that the modifier 'sealed' was applied to the element.
  SEALED,

  /// Indicates that the pseudo-modifier 'set' was applied to the element.
  SETTER,

  /// See [TypeParameterizedElement.isSimplyBounded].
  SIMPLY_BOUNDED,

  /// Indicates that the modifier 'static' was applied to the element.
  STATIC,

  /// Indicates that the element does not appear in the source code but was
  /// implicitly created. For example, if a class does not define any
  /// constructors, an implicit zero-argument constructor will be created and it
  /// will be marked as being synthetic.
  SYNTHETIC,
}

class MultiplyDefinedElementImpl extends ElementImpl
    implements MultiplyDefinedElement {
  final LibraryFragmentImpl libraryFragment;

  @override
  final String name;

  @override
  final List<Element> conflictingElements;

  @override
  late final MultiplyDefinedFragmentImpl firstFragment =
      MultiplyDefinedFragmentImpl(this);

  MultiplyDefinedElementImpl(
    this.libraryFragment,
    this.name,
    this.conflictingElements,
  );

  @override
  MultiplyDefinedElementImpl get baseElement => this;

  @override
  List<Element> get children => const [];

  @Deprecated('Use children instead')
  @override
  List<Element> get children2 => children;

  @Deprecated('Use conflictingElements instead')
  @override
  List<Element> get conflictingElements2 => conflictingElements;

  @override
  String get displayName => name;

  @override
  Null get enclosingElement => null;

  @Deprecated('Use enclosingElement instead')
  @override
  Null get enclosingElement2 => enclosingElement;

  @override
  List<MultiplyDefinedFragmentImpl> get fragments {
    return [firstFragment];
  }

  @override
  bool get isPrivate => false;

  @override
  bool get isPublic => true;

  @override
  bool get isSynthetic => true;

  bool get isVisibleForTemplate => false;

  bool get isVisibleOutsideTemplate => false;

  @override
  ElementKind get kind => ElementKind.ERROR;

  @override
  LibraryElementImpl get library => libraryFragment.element;

  @Deprecated('Use library instead')
  @override
  LibraryElement get library2 => library;

  @Deprecated('Use name instead')
  @override
  String get name3 => name;

  @override
  Element get nonSynthetic => this;

  @override
  AnalysisSession get session => libraryFragment.session;

  @override
  T? accept<T>(ElementVisitor2<T> visitor) {
    return visitor.visitMultiplyDefinedElement(this);
  }

  @Deprecated('Use accept instead')
  @override
  T? accept2<T>(ElementVisitor2<T> visitor) => accept(visitor);

  @override
  String displayString({bool multiline = false, bool preferTypeAlias = false}) {
    var elementsStr = conflictingElements
        .map((e) {
          return e.displayString();
        })
        .join(', ');
    return '[$elementsStr]';
  }

  @Deprecated('Use displayString instead')
  @override
  String displayString2({
    bool multiline = false,
    bool preferTypeAlias = false,
  }) {
    return displayString(
      multiline: multiline,
      preferTypeAlias: preferTypeAlias,
    );
  }

  @override
  bool isAccessibleIn(LibraryElement library) {
    for (var element in conflictingElements) {
      if (element.isAccessibleIn(library)) {
        return true;
      }
    }
    return false;
  }

  @Deprecated('Use isAccessibleIn instead')
  @override
  bool isAccessibleIn2(LibraryElement library) {
    return isAccessibleIn(library);
  }

  @override
  Element? thisOrAncestorMatching(bool Function(Element p1) predicate) {
    return null;
  }

  @Deprecated('Use thisOrAncestorMatching instead')
  @override
  Element? thisOrAncestorMatching2(bool Function(Element p1) predicate) {
    return thisOrAncestorMatching(predicate);
  }

  @override
  E? thisOrAncestorOfType<E extends Element>() {
    return null;
  }

  @Deprecated('Use thisOrAncestorOfType instead')
  @override
  E? thisOrAncestorOfType2<E extends Element>() {
    return thisOrAncestorOfType();
  }

  @override
  String toString() {
    StringBuffer buffer = StringBuffer();
    bool needsSeparator = false;
    void writeList(List<Element> elements) {
      for (var element in elements) {
        if (needsSeparator) {
          buffer.write(", ");
        } else {
          needsSeparator = true;
        }
        buffer.write(element.displayString());
      }
    }

    buffer.write("[");
    writeList(conflictingElements);
    buffer.write("]");
    return buffer.toString();
  }

  @override
  void visitChildren<T>(ElementVisitor2<T> visitor) {
    for (var child in children) {
      child.accept(visitor);
    }
  }
}

class MultiplyDefinedFragmentImpl implements MultiplyDefinedFragment {
  @override
  final MultiplyDefinedElementImpl element;

  MultiplyDefinedFragmentImpl(this.element);

  @override
  List<Fragment> get children => [];

  @Deprecated('Use children instead')
  @override
  List<Fragment> get children3 => children;

  @override
  String? get documentationComment => null;

  @override
  LibraryFragment get enclosingFragment => element.libraryFragment;

  @override
  LibraryFragment get libraryFragment => enclosingFragment;

  @override
  MetadataImpl get metadata => MetadataImpl.empty;

  @override
  String? get name => element.name;

  @Deprecated('Use name instead')
  @override
  String? get name2 => name;

  @override
  Null get nameOffset => null;

  @Deprecated('Use nameOffset instead')
  @override
  int? get nameOffset2 => nameOffset;

  @override
  Null get nextFragment => null;

  @override
  int get offset => 0;

  @override
  Null get previousFragment => null;
}

/// The synthetic element representing the declaration of the type `Never`.
class NeverElementImpl extends ElementImpl implements TypeDefiningElement {
  /// The unique instance of this class.
  static final instance = NeverElementImpl._();

  NeverElementImpl._();

  @override
  Null get documentationComment => null;

  @override
  Element? get enclosingElement => null;

  @Deprecated('Use enclosingElement instead')
  @override
  Element? get enclosingElement2 => enclosingElement;

  @override
  NeverFragmentImpl get firstFragment => NeverFragmentImpl.instance;

  @override
  List<NeverFragmentImpl> get fragments {
    return [firstFragment];
  }

  @override
  bool get isSynthetic => true;

  @override
  ElementKind get kind => ElementKind.NEVER;

  @override
  Null get library => null;

  @Deprecated('Use library instead')
  @override
  Null get library2 => library;

  @override
  MetadataImpl get metadata {
    return MetadataImpl(const []);
  }

  @Deprecated('Use metadata instead')
  @override
  MetadataImpl get metadata2 => metadata;

  @override
  String get name => 'Never';

  @Deprecated('Use name instead')
  @override
  String get name3 => name;

  @override
  T? accept<T>(ElementVisitor2<T> visitor) {
    return null;
  }

  @Deprecated('Use accept instead')
  @override
  T? accept2<T>(ElementVisitor2<T> visitor) => accept(visitor);

  @override
  void appendTo(ElementDisplayStringBuilder builder) {
    builder.writeNeverElement(this);
  }

  DartType instantiate({required NullabilitySuffix nullabilitySuffix}) {
    switch (nullabilitySuffix) {
      case NullabilitySuffix.question:
        return NeverTypeImpl.instanceNullable;
      case NullabilitySuffix.star:
        // TODO(scheglov): remove together with `star`
        return NeverTypeImpl.instanceNullable;
      case NullabilitySuffix.none:
        return NeverTypeImpl.instance;
    }
  }
}

/// The synthetic element representing the declaration of the type `Never`.
class NeverFragmentImpl extends FragmentImpl implements TypeDefiningFragment {
  /// The unique instance of this class.
  static final instance = NeverFragmentImpl._();

  /// Initialize a newly created instance of this class. Instances of this class
  /// should <b>not</b> be created except as part of creating the type
  /// associated with this element. The single instance of this class should be
  /// accessed through the method [instance].
  NeverFragmentImpl._() : super(firstTokenOffset: null) {
    isSynthetic = true;
  }

  @override
  List<Fragment> get children => const [];

  @Deprecated('Use children instead')
  @override
  List<Fragment> get children3 => children;

  @override
  NeverElementImpl get element => NeverElementImpl.instance;

  @override
  Null get enclosingFragment => null;

  @override
  Null get libraryFragment => null;

  @Deprecated('Use metadata instead')
  @override
  MetadataImpl get metadata2 => metadata;

  @override
  String get name => 'Never';

  @Deprecated('Use name instead')
  @override
  String get name2 => name;

  @override
  Null get nameOffset => null;

  @override
  Null get nextFragment => null;

  @override
  int get offset => 0;

  @override
  Null get previousFragment => null;

  DartType instantiate({required NullabilitySuffix nullabilitySuffix}) {
    switch (nullabilitySuffix) {
      case NullabilitySuffix.question:
        return NeverTypeImpl.instanceNullable;
      case NullabilitySuffix.star:
        // TODO(scheglov): remove together with `star`
        return NeverTypeImpl.instanceNullable;
      case NullabilitySuffix.none:
        return NeverTypeImpl.instance;
    }
  }
}

/// A [VariableFragmentImpl], which is not a parameter.
@GenerateFragmentImpl(
  modifiers: _NonParameterVariableFragmentImplModifiers.values,
)
abstract class NonParameterVariableFragmentImpl extends VariableFragmentImpl
    with _NonParameterVariableFragmentImplMixin {
  /// Initialize a newly created variable element to have the given [name] and
  /// [offset].
  NonParameterVariableFragmentImpl({super.firstTokenOffset});

  @override
  FragmentImpl get enclosingFragment {
    return super.enclosingFragment as FragmentImpl;
  }
}

class PartIncludeImpl extends ElementDirectiveImpl implements PartInclude {
  @override
  int partKeywordOffset;

  PartIncludeImpl({required super.uri, required this.partKeywordOffset});

  @override
  LibraryFragmentImpl? get includedFragment {
    if (uri case DirectiveUriWithUnitImpl uri) {
      return uri.libraryFragment;
    }
    return null;
  }

  @override
  void appendTo(ElementDisplayStringBuilder builder) {
    builder.writePartInclude(this);
  }
}

class PatternVariableElementImpl extends LocalVariableElementImpl
    implements PatternVariableElement {
  PatternVariableElementImpl(super._wrappedElement);

  @override
  PatternVariableFragmentImpl get firstFragment =>
      super.firstFragment as PatternVariableFragmentImpl;

  @override
  List<PatternVariableFragmentImpl> get fragments {
    return [
      for (
        PatternVariableFragmentImpl? fragment = firstFragment;
        fragment != null;
        fragment = fragment.nextFragment
      )
        fragment,
    ];
  }

  /// This flag is set to `true` while we are visiting the [WhenClause] of
  /// the [GuardedPattern] that declares this variable.
  bool get isVisitingWhenClause => _wrappedElement.isVisitingWhenClause;

  /// This flag is set to `true` while we are visiting the [WhenClause] of
  /// the [GuardedPattern] that declares this variable.
  set isVisitingWhenClause(bool value) =>
      _wrappedElement.isVisitingWhenClause = value;

  @override
  JoinPatternVariableElementImpl? get join {
    return _wrappedElement.join?.asElement2;
  }

  @Deprecated('Use join instead')
  @override
  JoinPatternVariableElementImpl? get join2 {
    return join;
  }

  /// Return the root [join], or self.
  PatternVariableElementImpl get rootVariable {
    return join?.rootVariable ?? this;
  }

  @override
  PatternVariableFragmentImpl get _wrappedElement =>
      super._wrappedElement as PatternVariableFragmentImpl;

  static PatternVariableElement fromElement(
    PatternVariableFragmentImpl element,
  ) {
    if (element is JoinPatternVariableFragmentImpl) {
      return JoinPatternVariableElementImpl(element);
    } else if (element is BindPatternVariableFragmentImpl) {
      return BindPatternVariableElementImpl(element);
    }
    return PatternVariableElementImpl(element);
  }
}

class PatternVariableFragmentImpl extends LocalVariableFragmentImpl
    implements PatternVariableFragment {
  @override
  JoinPatternVariableFragmentImpl? join;

  /// This flag is set to `true` while we are visiting the [WhenClause] of
  /// the [GuardedPattern] that declares this variable.
  bool isVisitingWhenClause = false;

  PatternVariableFragmentImpl({
    required super.name,
    required super.firstTokenOffset,
  });

  @override
  PatternVariableElementImpl get element =>
      super.element as PatternVariableElementImpl;

  @Deprecated('Use join instead')
  @override
  JoinPatternVariableFragment? get join2 => join;

  @override
  PatternVariableFragmentImpl? get nextFragment =>
      super.nextFragment as PatternVariableFragmentImpl?;

  @override
  PatternVariableFragmentImpl? get previousFragment =>
      super.previousFragment as PatternVariableFragmentImpl?;

  /// Return the root [join], or self.
  PatternVariableFragmentImpl get rootVariable {
    return join?.rootVariable ?? this;
  }
}

class PrefixElementImpl extends ElementImpl implements PrefixElement {
  @override
  final Reference reference;

  @override
  final PrefixFragmentImpl firstFragment;

  PrefixFragmentImpl lastFragment;

  /// The scope of this prefix, `null` if not set yet.
  PrefixScope? _scope;

  PrefixElementImpl({required this.reference, required this.firstFragment})
    : lastFragment = firstFragment {
    reference.element = this;
  }

  @override
  Null get enclosingElement => null;

  @Deprecated('Use enclosingElement instead')
  @override
  Null get enclosingElement2 => enclosingElement;

  @override
  List<PrefixFragmentImpl> get fragments {
    return [
      for (
        PrefixFragmentImpl? fragment = firstFragment;
        fragment != null;
        fragment = fragment.nextFragment
      )
        fragment,
    ];
  }

  @override
  List<LibraryImportImpl> get imports {
    return firstFragment.enclosingFragment.libraryImports
        .where((import) => import.prefix?.element == this)
        .toList();
  }

  @override
  bool get isSynthetic => false;

  @override
  ElementKind get kind => ElementKind.PREFIX;

  @override
  LibraryElementImpl get library => super.library!;

  @Deprecated('Use library instead')
  @override
  LibraryElementImpl get library2 => library;

  @override
  String? get name => firstFragment.name;

  @Deprecated('Use name instead')
  @override
  String? get name3 => name;

  @override
  PrefixScope get scope {
    firstFragment.enclosingFragment.scope;
    // SAFETY: The previous statement initializes this field.
    return _scope!;
  }

  set scope(PrefixScope value) {
    _scope = value;
  }

  @override
  T? accept<T>(ElementVisitor2<T> visitor) {
    return visitor.visitPrefixElement(this);
  }

  @Deprecated('Use accept instead')
  @override
  T? accept2<T>(ElementVisitor2<T> visitor) => accept(visitor);

  void addFragment(PrefixFragmentImpl fragment) {
    lastFragment.nextFragment = fragment;
    fragment.previousFragment = lastFragment;
    lastFragment = fragment;
  }

  @override
  void appendTo(ElementDisplayStringBuilder builder) {
    builder.writePrefixElement(this);
  }

  @Deprecated('Use displayString instead')
  @override
  String displayString2({
    bool multiline = false,
    bool preferTypeAlias = false,
  }) {
    return displayString(
      multiline: multiline,
      preferTypeAlias: preferTypeAlias,
    );
  }

  @override
  void visitChildren<T>(ElementVisitor2<T> visitor) {}
}

class PrefixFragmentImpl extends FragmentImpl implements PrefixFragment {
  @override
  final String? name;

  @override
  int? nameOffset;

  @override
  int offset = 0;

  @override
  final bool isDeferred;

  @override
  late final PrefixElementImpl element;

  @override
  PrefixFragmentImpl? previousFragment;

  @override
  PrefixFragmentImpl? nextFragment;

  PrefixFragmentImpl({
    required this.name,
    required this.nameOffset,
    required super.firstTokenOffset,
    required this.isDeferred,
  });

  @override
  List<Fragment> get children => const [];

  @Deprecated('Use children instead')
  @override
  List<Fragment> get children3 => children;

  @override
  LibraryFragmentImpl get enclosingFragment =>
      super.enclosingFragment as LibraryFragmentImpl;

  @override
  LibraryFragmentImpl get libraryFragment => enclosingFragment;
}

abstract class PromotableElementImpl extends VariableElementImpl {}

abstract class PropertyAccessorElementImpl extends ExecutableElementImpl
    with InternalPropertyAccessorElement {
  PropertyInducingElementImpl? _variable3;

  @override
  PropertyAccessorElementImpl get baseElement => this;

  @override
  Element get enclosingElement => firstFragment.enclosingFragment.element;

  @Deprecated('Use enclosingElement instead')
  @override
  Element get enclosingElement2 => enclosingElement;

  @override
  PropertyAccessorFragmentImpl get firstFragment;

  @override
  List<PropertyAccessorFragmentImpl> get fragments;

  @override
  PropertyAccessorFragmentImpl get lastFragment {
    return super.lastFragment as PropertyAccessorFragmentImpl;
  }

  @override
  String? get name => firstFragment.name;

  @Deprecated('Use name instead')
  @override
  String? get name3 => name;

  @override
  List<TypeParameterElementImpl> get typeParameters;

  @override
  @trackedDirectly
  PropertyInducingElementImpl get variable {
    globalResultRequirements?.record_propertyAccessorElement_variable(
      element: this,
      name: name,
    );

    return _variable3!;
  }

  set variable(PropertyInducingElementImpl? value) {
    _variable3 = value;
  }

  @Deprecated('Use variable instead')
  @override
  @trackedDirectly
  PropertyInducingElementImpl? get variable3 {
    return variable;
  }
}

sealed class PropertyAccessorFragmentImpl extends ExecutableFragmentImpl
    implements PropertyAccessorFragment {
  @override
  final String? name;

  @override
  int? nameOffset;

  /// Initialize a newly created property accessor element to have the given
  /// [name] and [offset].
  PropertyAccessorFragmentImpl({required this.name, super.firstTokenOffset});

  /// Initialize a newly created synthetic property accessor element to be
  /// associated with the given [variable].
  PropertyAccessorFragmentImpl.forVariable(
    PropertyInducingFragmentImpl variable,
  ) : name = variable.name,
      super(firstTokenOffset: null) {
    isAbstract = variable is FieldFragmentImpl && variable.isAbstract;
    isStatic = variable.isStatic;
    isSynthetic = true;
  }

  @override
  PropertyAccessorFragmentImpl get declaration => this;

  @override
  PropertyAccessorElementImpl get element;

  @override
  MetadataImpl get metadata {
    _ensureReadResolution();
    return super.metadata;
  }

  @override
  int get offset {
    if (nameOffset case var nameOffset?) {
      return nameOffset;
    }
    if (isSynthetic) {
      var variable = element.variable;
      if (variable.isSynthetic) {
        return enclosingFragment.offset;
      }
      return variable.firstFragment.offset;
    }
    return firstTokenOffset!;
  }
}

abstract class PropertyInducingElementImpl extends VariableElementImpl
    with InternalPropertyInducingElement, DeferredResolutionReadingMixin {
  @override
  GetterElementImpl? getter;

  @override
  SetterElementImpl? setter;

  TypeImpl? _type;

  PropertyInducingElementImpl() {
    shouldUseTypeForInitializerInference = true;
  }

  @override
  PropertyInducingFragmentImpl get firstFragment;

  @override
  List<PropertyInducingFragmentImpl> get fragments {
    return [
      for (
        PropertyInducingFragmentImpl? fragment = firstFragment;
        fragment != null;
        fragment = fragment.nextFragment
      )
        fragment,
    ];
  }

  @Deprecated('Use getter instead')
  @override
  GetterElementImpl? get getter2 => getter;

  @override
  bool get hasInitializer {
    return _fragments.any((f) => f.hasInitializer);
  }

  @override
  LibraryElementImpl get library => super.library!;

  @override
  Element get nonSynthetic {
    if (isSynthetic) {
      if (enclosingElement case EnumElementImpl enclosingElement) {
        // TODO(scheglov): remove 'index'?
        if (name == 'index' || name == 'values') {
          return enclosingElement;
        }
      }
      return (getter ?? setter)!;
    } else {
      return this;
    }
  }

  @override
  Reference get reference;

  @Deprecated('Use setter instead')
  @override
  SetterElementImpl? get setter2 => setter;

  bool get shouldUseTypeForInitializerInference {
    return hasModifier(Modifier.SHOULD_USE_TYPE_FOR_INITIALIZER_INFERENCE);
  }

  set shouldUseTypeForInitializerInference(bool value) {
    setModifier(Modifier.SHOULD_USE_TYPE_FOR_INITIALIZER_INFERENCE, value);
  }

  @override
  TypeImpl get type {
    _ensureReadResolution();
    if (_type case var type?) {
      return type;
    }

    // We must be linking, and the type has not been set yet.
    var type = firstFragment.typeInference?.perform();
    type ??= InvalidTypeImpl.instance;
    this.type = type;
    shouldUseTypeForInitializerInference = false;

    return type;
  }

  @override
  set type(TypeImpl value) {
    _type = value;

    if (getter case var getter?) {
      if (getter.isSynthetic) {
        getter.returnType = type;
      }
    }

    if (setter case var setter?) {
      if (setter.isSynthetic) {
        setter.returnType = VoidTypeImpl.instance;
        setter.valueFormalParameter.type = type;
      }
    }
  }

  List<PropertyInducingFragmentImpl> get _fragments;

  @override
  void appendTo(ElementDisplayStringBuilder builder) {
    builder.writeVariableElement(this);
  }
}

/// Instances of this class are set for fields and top-level variables
/// to perform top-level type inference during linking.
abstract class PropertyInducingElementTypeInference {
  TypeImpl perform();
}

abstract class PropertyInducingFragmentImpl
    extends NonParameterVariableFragmentImpl
    with DeferredResolutionReadingMixin
    implements PropertyInducingFragment {
  @override
  final String? name;

  @override
  int? nameOffset;

  @override
  PropertyInducingFragmentImpl? previousFragment;

  @override
  PropertyInducingFragmentImpl? nextFragment;

  /// This field is set during linking, and performs type inference for
  /// this property. After linking this field is always `null`.
  PropertyInducingElementTypeInference? typeInference;

  /// The error reported during type inference for this variable, or `null` if
  /// this variable is not a subject of type inference, or there was no error.
  TopLevelInferenceError? typeInferenceError;

  /// Initialize a newly created synthetic element to have the given [name] and
  /// [offset].
  PropertyInducingFragmentImpl({required this.name});

  @override
  List<Fragment> get children => const [];

  @Deprecated('Use children instead')
  @override
  List<Fragment> get children3 => children;

  @override
  PropertyInducingElementImpl get element;

  /// Return `true` if this variable needs the setter.
  bool get hasSetter {
    if (isConst) {
      return false;
    }

    if (isLate) {
      return !isFinal || !hasInitializer;
    }

    return !isFinal;
  }

  @override
  LibraryFragment get libraryFragment {
    return enclosingFragment.libraryFragment!;
  }

  @Deprecated('Use metadata instead')
  @override
  MetadataImpl get metadata2 => metadata;
}

class SetterElementImpl extends PropertyAccessorElementImpl
    with InternalSetterElement {
  @override
  Reference reference;

  @override
  final SetterFragmentImpl firstFragment;

  SetterElementImpl(this.reference, this.firstFragment) {
    reference.element = this;
    SetterFragmentImpl? fragment = firstFragment;
    while (fragment != null) {
      fragment.element = this;
      fragment = fragment.nextFragment;
    }
  }

  @override
  SetterElementImpl get baseElement => this;

  @override
  GetterElement? get correspondingGetter {
    return variable.getter;
  }

  @Deprecated('Use correspondingGetter instead')
  @override
  GetterElement? get correspondingGetter2 {
    return correspondingGetter;
  }

  @override
  Element get enclosingElement => firstFragment.enclosingFragment.element;

  @Deprecated('Use enclosingElement instead')
  @override
  Element get enclosingElement2 => enclosingElement;

  @override
  List<SetterFragmentImpl> get fragments {
    return [
      for (
        SetterFragmentImpl? fragment = firstFragment;
        fragment != null;
        fragment = fragment.nextFragment
      )
        fragment,
    ];
  }

  @override
  ElementKind get kind => ElementKind.SETTER;

  @override
  SetterFragmentImpl get lastFragment {
    return super.lastFragment as SetterFragmentImpl;
  }

  @override
  String? get lookupName {
    if (name case var name?) {
      return '$name=';
    }
    return null;
  }

  @override
  Element get nonSynthetic {
    if (isSynthetic) {
      return variable.nonSynthetic;
    } else {
      return this;
    }
  }

  @override
  Version? get sinceSdkVersion {
    if (isSynthetic) {
      return variable.sinceSdkVersion;
    }
    return super.sinceSdkVersion;
  }

  FormalParameterElementImpl get valueFormalParameter {
    return formalParameters.single;
  }

  @override
  T? accept<T>(ElementVisitor2<T> visitor) {
    return visitor.visitSetterElement(this);
  }

  @Deprecated('Use accept instead')
  @override
  T? accept2<T>(ElementVisitor2<T> visitor) => accept(visitor);

  @override
  void appendTo(ElementDisplayStringBuilder builder) {
    builder.writeSetterElement(this);
  }

  void linkFragments(List<SetterFragmentImpl> fragments) {
    assert(identical(fragments[0], firstFragment));
    fragments.reduce((previous, current) {
      previous.addFragment(current);
      return current;
    });
  }
}

class SetterFragmentImpl extends PropertyAccessorFragmentImpl
    implements SetterFragment {
  @override
  late SetterElementImpl element;

  @override
  SetterFragmentImpl? previousFragment;

  @override
  SetterFragmentImpl? nextFragment;

  SetterFragmentImpl({required super.name});

  SetterFragmentImpl.forVariable(super.variable) : super.forVariable();

  @override
  String? get lookupName {
    if (name case var name?) {
      return '$name=';
    }
    return null;
  }

  FormalParameterFragmentImpl get valueFormalParameter {
    return formalParameters.single;
  }

  void addFragment(SetterFragmentImpl fragment) {
    fragment.element = element;
    fragment.previousFragment = this;
    nextFragment = fragment;
  }
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

class SuperFormalParameterElementImpl extends FormalParameterElementImpl
    implements SuperFormalParameterElement {
  SuperFormalParameterElementImpl(super.firstFragment);

  @override
  String? get defaultValueCode {
    if (isRequired) {
      return null;
    }

    var constantInitializer = constantInitializer2?.expression;
    if (constantInitializer != null) {
      return constantInitializer.toSource();
    }

    if (_superConstructorParameterDefaultValue != null) {
      return superConstructorParameter?.defaultValueCode;
    }

    return null;
  }

  @override
  Constant? get evaluationResult {
    if (constantInitializer2 != null) {
      return super.evaluationResult;
    }

    var superConstructorParameter = this.superConstructorParameter?.baseElement;
    if (superConstructorParameter != null) {
      return superConstructorParameter.evaluationResult;
    }

    return null;
  }

  @override
  SuperFormalParameterFragmentImpl get firstFragment =>
      super.firstFragment as SuperFormalParameterFragmentImpl;

  @override
  List<SuperFormalParameterFragmentImpl> get fragments {
    return [
      for (
        SuperFormalParameterFragmentImpl? fragment = firstFragment;
        fragment != null;
        fragment = fragment.nextFragment
      )
        fragment,
    ];
  }

  @override
  InternalFormalParameterElement? get superConstructorParameter {
    var enclosingElement = this.enclosingElement;
    if (enclosingElement is ConstructorElementImpl) {
      var superConstructor = enclosingElement.superConstructor;
      if (superConstructor != null) {
        var superParameters = superConstructor.formalParameters;
        if (isNamed) {
          return superParameters.firstWhereOrNull(
            (e) => e.isNamed && e.name == name,
          );
        } else {
          var index = indexIn(enclosingElement);
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

  @Deprecated('Use superConstructorParameter instead')
  @override
  InternalFormalParameterElement? get superConstructorParameter2 {
    return superConstructorParameter;
  }

  DartObject? get _superConstructorParameterDefaultValue {
    var superDefault = superConstructorParameter?.computeConstantValue();
    if (superDefault == null) {
      return null;
    }

    // TODO(scheglov): eliminate this cast
    superDefault as DartObjectImpl;
    var superDefaultType = superDefault.type;

    var typeSystem = library?.typeSystem;
    if (typeSystem == null) {
      return null;
    }

    var requiredType = type.extensionTypeErasure;
    if (typeSystem.isSubtypeOf(superDefaultType, requiredType)) {
      return superDefault;
    }

    return null;
  }

  @override
  DartObject? computeConstantValue() {
    if (constantInitializer2 != null) {
      return super.computeConstantValue();
    }

    return _superConstructorParameterDefaultValue;
  }

  /// Return the index of this super-formal parameter among other super-formals.
  int indexIn(ConstructorElementImpl enclosingElement) {
    return enclosingElement.formalParameters
        .whereType<SuperFormalParameterElementImpl>()
        .toList()
        .indexOf(this);
  }
}

class SuperFormalParameterFragmentImpl extends FormalParameterFragmentImpl
    implements SuperFormalParameterFragment {
  /// Initialize a newly created parameter element to have the given [name] and
  /// [nameOffset].
  SuperFormalParameterFragmentImpl({
    super.firstTokenOffset,
    required super.name,
    required super.nameOffset,
    required super.parameterKind,
  });

  @override
  SuperFormalParameterElementImpl get element =>
      super.element as SuperFormalParameterElementImpl;

  /// Super parameters are visible only in the initializer list scope,
  /// and introduce final variables.
  @override
  bool get isFinal => true;

  @override
  bool get isSuperFormal => true;

  @override
  SuperFormalParameterFragmentImpl? get nextFragment =>
      super.nextFragment as SuperFormalParameterFragmentImpl?;

  @override
  SuperFormalParameterFragmentImpl? get previousFragment =>
      super.previousFragment as SuperFormalParameterFragmentImpl?;

  /// Return the index of this super-formal parameter among other super-formals.
  int indexIn(ConstructorFragmentImpl enclosingElement) {
    return enclosingElement.formalParameters
        .whereType<SuperFormalParameterFragmentImpl>()
        .toList()
        .indexOf(this);
  }

  @override
  FormalParameterElementImpl _createElement(
    FormalParameterFragment firstFragment,
  ) => SuperFormalParameterElementImpl(
    firstFragment as FormalParameterFragmentImpl,
  );
}

class TopLevelFunctionElementImpl extends ExecutableElementImpl
    implements TopLevelFunctionElement {
  @override
  final Reference reference;

  @override
  final TopLevelFunctionFragmentImpl firstFragment;

  TopLevelFunctionElementImpl(this.reference, this.firstFragment) {
    reference.element = this;
    firstFragment.element = this;
  }

  @override
  TopLevelFunctionElementImpl get baseElement => this;

  @override
  LibraryElementImpl get enclosingElement => library;

  @Deprecated('Use enclosingElement instead')
  @override
  LibraryElementImpl get enclosingElement2 => enclosingElement;

  @override
  List<TopLevelFunctionFragmentImpl> get fragments {
    return [
      for (
        TopLevelFunctionFragmentImpl? fragment = firstFragment;
        fragment != null;
        fragment = fragment.nextFragment
      )
        fragment,
    ];
  }

  @override
  bool get isDartCoreIdentical {
    return name == 'identical' && library.isDartCore;
  }

  @override
  bool get isEntryPoint {
    return displayName == TopLevelFunctionElement.MAIN_FUNCTION_NAME;
  }

  @override
  ElementKind get kind => ElementKind.FUNCTION;

  @override
  TopLevelFunctionFragmentImpl get lastFragment {
    return super.lastFragment as TopLevelFunctionFragmentImpl;
  }

  @Deprecated('Use library instead')
  @override
  LibraryElementImpl get library2 => library;

  @override
  String? get name => firstFragment.name;

  @Deprecated('Use name instead')
  @override
  String? get name3 => name;

  @override
  T? accept<T>(ElementVisitor2<T> visitor) {
    return visitor.visitTopLevelFunctionElement(this);
  }

  @Deprecated('Use accept instead')
  @override
  T? accept2<T>(ElementVisitor2<T> visitor) => accept(visitor);

  @override
  void appendTo(ElementDisplayStringBuilder builder) {
    builder.writeTopLevelFunctionElement(this);
  }

  void linkFragments(List<TopLevelFunctionFragmentImpl> fragments) {
    assert(identical(fragments[0], firstFragment));
    fragments.reduce((previous, current) {
      previous.addFragment(current);
      return current;
    });
  }
}

/// A concrete implementation of a [TopLevelFunctionFragment].
class TopLevelFunctionFragmentImpl extends FunctionFragmentImpl
    implements TopLevelFunctionFragment {
  /// The element corresponding to this fragment.
  @override
  late TopLevelFunctionElementImpl element;

  @override
  TopLevelFunctionFragmentImpl? previousFragment;

  @override
  TopLevelFunctionFragmentImpl? nextFragment;

  TopLevelFunctionFragmentImpl({required super.name});

  @override
  LibraryFragmentImpl get enclosingFragment =>
      super.enclosingFragment as LibraryFragmentImpl;

  @override
  set enclosingFragment(covariant LibraryFragmentImpl element);

  void addFragment(TopLevelFunctionFragmentImpl fragment) {
    fragment.element = element;
    fragment.previousFragment = this;
    nextFragment = fragment;
  }
}

class TopLevelVariableElementImpl extends PropertyInducingElementImpl
    implements TopLevelVariableElement {
  @override
  final Reference reference;

  @override
  final TopLevelVariableFragmentImpl firstFragment;

  TopLevelVariableElementImpl(this.reference, this.firstFragment) {
    reference.element = this;
    firstFragment.element = this;
  }

  @override
  TopLevelVariableElementImpl get baseElement => this;

  @override
  LibraryElementImpl get enclosingElement => library;

  @Deprecated('Use enclosingElement instead')
  @override
  LibraryElement get enclosingElement2 => enclosingElement;

  @override
  List<TopLevelVariableFragmentImpl> get fragments {
    return [
      for (
        TopLevelVariableFragmentImpl? fragment = firstFragment;
        fragment != null;
        fragment = fragment.nextFragment
      )
        fragment,
    ];
  }

  @override
  bool get hasImplicitType => firstFragment.hasImplicitType;

  @override
  bool get isConst => firstFragment.isConst;

  @override
  bool get isExternal => firstFragment.isExternal;

  @override
  bool get isFinal => firstFragment.isFinal;

  @override
  bool get isLate => firstFragment.isLate;

  @override
  bool get isStatic => firstFragment.isStatic;

  @override
  bool get isSynthetic {
    return firstFragment.isSynthetic;
  }

  @override
  ElementKind get kind => ElementKind.TOP_LEVEL_VARIABLE;

  @Deprecated('Use library instead')
  @override
  LibraryElement get library2 => library;

  @override
  MetadataImpl get metadata {
    var annotations = <ElementAnnotationImpl>[];
    for (var fragment in _fragments) {
      annotations.addAll(fragment.metadata.annotations);
    }
    return MetadataImpl(annotations);
  }

  @Deprecated('Use metadata instead')
  @override
  MetadataImpl get metadata2 => metadata;

  @override
  String? get name => firstFragment.name;

  @Deprecated('Use name instead')
  @override
  String? get name3 => name;

  @override
  List<TopLevelVariableFragmentImpl> get _fragments {
    var result = <TopLevelVariableFragmentImpl>[];
    TopLevelVariableFragmentImpl? current = firstFragment;
    while (current != null) {
      result.add(current);
      current = current.nextFragment;
    }
    return result;
  }

  @override
  T? accept<T>(ElementVisitor2<T> visitor) {
    return visitor.visitTopLevelVariableElement(this);
  }

  @Deprecated('Use accept instead')
  @override
  T? accept2<T>(ElementVisitor2<T> visitor) => accept(visitor);

  void linkFragments(List<TopLevelVariableFragmentImpl> fragments) {
    assert(identical(fragments[0], firstFragment));
    fragments.reduce((previous, current) {
      previous.addFragment(current);
      return current;
    });
  }
}

class TopLevelVariableFragmentImpl extends PropertyInducingFragmentImpl
    implements TopLevelVariableFragment {
  @override
  late TopLevelVariableElementImpl element;

  /// Initialize a newly created synthetic top-level variable element to have
  /// the given [name] and [offset].
  TopLevelVariableFragmentImpl({required super.name});

  @override
  ExpressionImpl? get constantInitializer {
    _ensureReadResolution();
    return super.constantInitializer;
  }

  @override
  TopLevelVariableFragmentImpl get declaration => this;

  @override
  bool get isStatic => true;

  @override
  LibraryFragmentImpl get libraryFragment => enclosingUnit;

  @override
  MetadataImpl get metadata {
    _ensureReadResolution();
    return super.metadata;
  }

  @override
  TopLevelVariableFragmentImpl? get nextFragment =>
      super.nextFragment as TopLevelVariableFragmentImpl?;

  @override
  TopLevelVariableFragmentImpl? get previousFragment =>
      super.previousFragment as TopLevelVariableFragmentImpl?;

  void addFragment(TopLevelVariableFragmentImpl fragment) {
    fragment.element = element;
    fragment.previousFragment = this;
    nextFragment = fragment;
  }
}

class TypeAliasElementImpl extends ElementImpl
    with DeferredResolutionReadingMixin
    implements TypeAliasElement {
  @override
  final Reference reference;

  @override
  final TypeAliasFragmentImpl firstFragment;

  TypeImpl? _aliasedType;

  TypeAliasElementImpl(this.reference, this.firstFragment) {
    reference.element = this;
    firstFragment.element = this;
  }

  @override
  ElementImpl? get aliasedElement {
    switch (firstFragment.aliasedElement) {
      case InstanceFragmentImpl instance:
        return instance.element;
      case GenericFunctionTypeFragmentImpl instance:
        return instance.element;
    }
    return null;
  }

  @Deprecated('Use aliasedElement instead')
  @override
  Element? get aliasedElement2 {
    return aliasedElement;
  }

  @override
  TypeImpl get aliasedType {
    _ensureReadResolution();
    return _aliasedType!;
  }

  set aliasedType(DartType rawType) {
    // TODO(paulberry): eliminate this cast by changing the type of the
    // `rawType` parameter.
    _aliasedType = rawType as TypeImpl;
  }

  /// The aliased type, might be `null` if not yet linked.
  TypeImpl? get aliasedTypeRaw => _aliasedType;

  @override
  TypeAliasElementImpl get baseElement => this;

  @override
  LibraryElementImpl get enclosingElement => library;

  @Deprecated('Use enclosingElement instead')
  @override
  LibraryElement get enclosingElement2 => enclosingElement;

  @override
  List<TypeAliasFragmentImpl> get fragments {
    return [
      for (
        TypeAliasFragmentImpl? fragment = firstFragment;
        fragment != null;
        fragment = fragment.nextFragment
      )
        fragment,
    ];
  }

  bool get isNonFunctionTypeAliasesEnabled {
    return library.featureSet.isEnabled(Feature.nonfunction_type_aliases);
  }

  /// Whether this alias is a "proper rename" of [aliasedType], as defined in
  /// the constructor-tearoffs specification.
  bool get isProperRename {
    var aliasedType_ = aliasedType;
    if (aliasedType_ is! InterfaceTypeImpl) {
      return false;
    }
    var typeParameters = this.typeParameters;
    var aliasedClass = aliasedType_.element;
    var typeArguments = aliasedType_.typeArguments;
    var typeParameterCount = typeParameters.length;
    if (typeParameterCount != aliasedClass.typeParameters.length) {
      return false;
    }
    for (var i = 0; i < typeParameterCount; i++) {
      var bound = typeParameters[i].bound ?? DynamicTypeImpl.instance;
      var aliasedBound =
          aliasedClass.typeParameters[i].bound ??
          library.typeProvider.dynamicType;
      if (!library.typeSystem.isSubtypeOf(bound, aliasedBound) ||
          !library.typeSystem.isSubtypeOf(aliasedBound, bound)) {
        return false;
      }
      var typeArgument = typeArguments[i];
      if (typeArgument is TypeParameterType &&
          typeParameters[i] != typeArgument.element) {
        return false;
      }
    }
    return true;
  }

  @override
  bool get isSimplyBounded => firstFragment.isSimplyBounded;

  set isSimplyBounded(bool value) {
    for (var fragment in fragments) {
      fragment.isSimplyBounded = value;
    }
  }

  @override
  bool get isSynthetic {
    return firstFragment.isSynthetic;
  }

  @override
  ElementKind get kind => ElementKind.TYPE_ALIAS;

  @override
  LibraryElementImpl get library => super.library!;

  @Deprecated('Use library instead')
  @override
  LibraryElementImpl get library2 => library;

  @override
  MetadataImpl get metadata {
    var annotations = <ElementAnnotationImpl>[];
    for (var fragment in _fragments) {
      annotations.addAll(fragment.metadata.annotations);
    }
    return MetadataImpl(annotations);
  }

  @Deprecated('Use metadata instead')
  @override
  MetadataImpl get metadata2 => metadata;

  @override
  String? get name => firstFragment.name;

  @Deprecated('Use name instead')
  @override
  String? get name3 => name;

  @override
  List<TypeParameterElementImpl> get typeParameters =>
      firstFragment.typeParameters.map((fragment) => fragment.element).toList();

  @Deprecated('Use typeParameters instead')
  @override
  List<TypeParameterElementImpl> get typeParameters2 => typeParameters;

  /// A list of all of the fragments from which this element is composed.
  List<TypeAliasFragmentImpl> get _fragments {
    var result = <TypeAliasFragmentImpl>[];
    TypeAliasFragmentImpl? current = firstFragment;
    while (current != null) {
      result.add(current);
      current = current.nextFragment;
    }
    return result;
  }

  @override
  T? accept<T>(ElementVisitor2<T> visitor) {
    return visitor.visitTypeAliasElement(this);
  }

  @Deprecated('Use accept instead')
  @override
  T? accept2<T>(ElementVisitor2<T> visitor) => accept(visitor);

  @override
  void appendTo(ElementDisplayStringBuilder builder) {
    builder.writeTypeAliasElement(this);
  }

  @override
  TypeImpl instantiate({
    required List<DartType> typeArguments,
    required NullabilitySuffix nullabilitySuffix,
  }) {
    return instantiateImpl(
      typeArguments: typeArguments.cast<TypeImpl>(),
      nullabilitySuffix: nullabilitySuffix,
    );
  }

  TypeImpl instantiateImpl({
    required List<TypeImpl> typeArguments,
    required NullabilitySuffix nullabilitySuffix,
  }) {
    if (firstFragment.hasSelfReference) {
      if (isNonFunctionTypeAliasesEnabled) {
        return DynamicTypeImpl.instance;
      } else {
        return _errorFunctionType(nullabilitySuffix);
      }
    }

    var substitution = Substitution.fromPairs2(typeParameters, typeArguments);
    var type = substitution.substituteType(aliasedType);

    var resultNullability =
        type.nullabilitySuffix == NullabilitySuffix.question
            ? NullabilitySuffix.question
            : nullabilitySuffix;

    if (type is FunctionTypeImpl) {
      return FunctionTypeImpl.v2(
        typeParameters: type.typeParameters,
        formalParameters: type.parameters,
        returnType: type.returnType,
        nullabilitySuffix: resultNullability,
        alias: InstantiatedTypeAliasElementImpl(
          element: this,
          typeArguments: typeArguments,
        ),
      );
    } else if (type is InterfaceTypeImpl) {
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
    } else if (type is TypeParameterTypeImpl) {
      return TypeParameterTypeImpl(
        element: type.element,
        nullabilitySuffix: resultNullability,
        alias: InstantiatedTypeAliasElementImpl(
          element: this,
          typeArguments: typeArguments,
        ),
      );
    } else {
      return type.withNullability(resultNullability);
    }
  }

  FunctionTypeImpl _errorFunctionType(NullabilitySuffix nullabilitySuffix) {
    return FunctionTypeImpl(
      typeParameters: const [],
      parameters: const [],
      returnType: DynamicTypeImpl.instance,
      nullabilitySuffix: nullabilitySuffix,
    );
  }
}

/// An element that represents [GenericTypeAlias].
///
/// Clients may not extend, implement or mix-in this class.
@GenerateFragmentImpl(modifiers: _TypeAliasFragmentImplModifiers.values)
class TypeAliasFragmentImpl extends FragmentImpl
    with
        DeferredResolutionReadingMixin,
        TypeParameterizedFragmentMixin,
        _TypeAliasFragmentImplMixin
    implements TypeAliasFragment {
  @override
  final String? name;

  @override
  int? nameOffset;

  @override
  TypeAliasFragmentImpl? previousFragment;

  @override
  TypeAliasFragmentImpl? nextFragment;

  /// Is `true` if the element has direct or indirect reference to itself
  /// from anywhere except a class element or type parameter bounds.
  bool hasSelfReference = false;

  bool isFunctionTypeAliasBased = false;

  FragmentImpl? _aliasedElement;

  @override
  late TypeAliasElementImpl element;

  TypeAliasFragmentImpl({required this.name, required super.firstTokenOffset});

  /// If the aliased type has structure, return the corresponding element.
  /// For example it could be [GenericFunctionTypeElement].
  ///
  /// If there is no structure, return `null`.
  FragmentImpl? get aliasedElement {
    _ensureReadResolution();
    return _aliasedElement;
  }

  set aliasedElement(FragmentImpl? aliasedElement) {
    _aliasedElement = aliasedElement;
    aliasedElement?.enclosingFragment = this;
  }

  @override
  List<Fragment> get children => const [];

  @Deprecated('Use children instead')
  @override
  List<Fragment> get children3 => children;

  @override
  String get displayName => name ?? '';

  @override
  LibraryFragmentImpl get enclosingFragment =>
      super.enclosingFragment as LibraryFragmentImpl;

  @override
  MetadataImpl get metadata {
    _ensureReadResolution();
    return super.metadata;
  }

  @override
  int get offset => nameOffset ?? firstTokenOffset!;

  void addFragment(TypeAliasFragmentImpl fragment) {
    fragment.element = element;
    fragment.previousFragment = this;
    nextFragment = fragment;
  }
}

class TypeParameterElementImpl extends ElementImpl
    implements TypeParameterElement, SharedTypeParameter {
  @override
  final TypeParameterFragmentImpl firstFragment;

  @override
  final String? name;

  /// The value representing the variance modifier keyword, or `null` if
  /// there is no explicit variance modifier, meaning legacy covariance.
  shared.Variance? _variance;

  /// The type representing the bound associated with this type parameter,
  /// or `null` if this type parameter does not have an explicit bound.
  ///
  /// Being able to distinguish between an implicit and explicit bound is
  /// needed by the instantiate to bounds algorithm.
  @override
  TypeImpl? bound;

  /// The default value of the type parameter. It is used to provide the
  /// corresponding missing type argument in type annotations and as the
  /// fall-back type value in type inference.
  TypeImpl? defaultType;

  TypeParameterElementImpl({required this.firstFragment})
    : name = firstFragment.name {
    firstFragment.element = this;
  }

  factory TypeParameterElementImpl.synthetic({required String name}) {
    var fragment = TypeParameterFragmentImpl.synthetic(name: name);
    return TypeParameterElementImpl(firstFragment: fragment);
  }

  @override
  TypeParameterElementImpl get baseElement => this;

  @override
  TypeImpl? get boundShared => bound;

  @override
  Element? get enclosingElement {
    return firstFragment.enclosingFragment?.element;
  }

  @Deprecated('Use enclosingElement instead')
  @override
  Element? get enclosingElement2 => enclosingElement;

  @override
  List<TypeParameterFragmentImpl> get fragments {
    return [
      for (
        TypeParameterFragmentImpl? fragment = firstFragment;
        fragment != null;
        fragment = fragment.nextFragment
      )
        fragment,
    ];
  }

  bool get isLegacyCovariant {
    return _variance == null;
  }

  @override
  bool get isSynthetic {
    return firstFragment.isSynthetic;
  }

  @override
  ElementKind get kind => ElementKind.TYPE_PARAMETER;

  @Deprecated('Use library instead')
  @override
  LibraryElementImpl? get library2 => library;

  @override
  MetadataImpl get metadata {
    var annotations = <ElementAnnotationImpl>[];
    for (var fragment in fragments) {
      annotations.addAll(fragment.metadata.annotations);
    }
    return MetadataImpl(annotations);
  }

  @Deprecated('Use metadata instead')
  @override
  MetadataImpl get metadata2 => metadata;

  @Deprecated('Use name instead')
  @override
  String? get name3 => name;

  shared.Variance get variance {
    return _variance ?? shared.Variance.covariant;
  }

  set variance(shared.Variance? newVariance) => _variance = newVariance;

  @override
  T? accept<T>(ElementVisitor2<T> visitor) {
    return visitor.visitTypeParameterElement(this);
  }

  @Deprecated('Use accept instead')
  @override
  T? accept2<T>(ElementVisitor2<T> visitor) => accept(visitor);

  @override
  void appendTo(ElementDisplayStringBuilder builder) {
    builder.writeTypeParameterElement(this);
  }

  /// Computes the variance of the type parameters in the [type].
  shared.Variance computeVarianceInType(DartType type) {
    if (type is TypeParameterTypeImpl) {
      if (type.element == this) {
        return shared.Variance.covariant;
      } else {
        return shared.Variance.unrelated;
      }
    } else if (type is InterfaceTypeImpl) {
      var result = shared.Variance.unrelated;
      for (int i = 0; i < type.typeArguments.length; ++i) {
        var argument = type.typeArguments[i];
        var parameter = type.element.typeParameters[i];

        var parameterVariance = parameter.variance;
        result = result.meet(
          parameterVariance.combine(computeVarianceInType(argument)),
        );
      }
      return result;
    } else if (type is FunctionType) {
      var result = computeVarianceInType(type.returnType);

      for (var parameter in type.typeParameters) {
        // If [parameter] is referenced in the bound at all, it makes the
        // variance of [parameter] in the entire type invariant.  The invocation
        // of [computeVariance] below is made to simply figure out if [variable]
        // occurs in the bound.
        var bound = parameter.bound;
        if (bound != null && !computeVarianceInType(bound).isUnrelated) {
          result = shared.Variance.invariant;
        }
      }

      for (var formalParameter in type.formalParameters) {
        result = result.meet(
          shared.Variance.contravariant.combine(
            computeVarianceInType(formalParameter.type),
          ),
        );
      }
      return result;
    }
    return shared.Variance.unrelated;
  }

  @override
  TypeParameterTypeImpl instantiate({
    required NullabilitySuffix nullabilitySuffix,
  }) {
    return TypeParameterTypeImpl(
      element: this,
      nullabilitySuffix: nullabilitySuffix,
    );
  }

  @override
  void visitChildren<T>(ElementVisitor2<T> visitor) {
    for (var child in children) {
      child.accept(visitor);
    }
  }
}

class TypeParameterFragmentImpl extends FragmentImpl
    implements TypeParameterFragment {
  @override
  final String? name;

  @override
  int? nameOffset;

  /// The element corresponding to this fragment.
  TypeParameterElementImpl? _element;

  /// Initialize a newly created method element to have the given [name] and
  /// [offset].
  TypeParameterFragmentImpl({required this.name, super.firstTokenOffset});

  /// Initialize a newly created synthetic type parameter element to have the
  /// given [name], and with [isSynthetic] set to `true`.
  TypeParameterFragmentImpl.synthetic({required this.name})
    : super(firstTokenOffset: null) {
    isSynthetic = true;
  }

  @override
  List<Fragment> get children => const [];

  @Deprecated('Use children instead')
  @override
  List<Fragment> get children3 => children;

  @override
  TypeParameterFragmentImpl get declaration => this;

  @override
  String get displayName => name ?? '';

  @override
  TypeParameterElementImpl get element {
    if (_element != null) {
      return _element!;
    }
    var firstFragment = this;
    var previousFragment = firstFragment.previousFragment;
    while (previousFragment != null) {
      firstFragment = previousFragment;
      previousFragment = firstFragment.previousFragment;
    }
    // As a side-effect of creating the element, all of the fragments in the
    // chain will have their `_element` set to the newly created element.
    return TypeParameterElementImpl(firstFragment: firstFragment);
  }

  set element(TypeParameterElementImpl element) {
    _element = element;
  }

  @override
  LibraryFragment? get libraryFragment {
    return enclosingFragment?.libraryFragment;
  }

  @Deprecated('Use metadata instead')
  @override
  MetadataImpl get metadata2 => metadata;

  @override
  // TODO(augmentations): Support chaining between the fragments.
  TypeParameterFragmentImpl? get nextFragment => null;

  @override
  int get offset => nameOffset ?? firstTokenOffset!;

  @override
  // TODO(augmentations): Support chaining between the fragments.
  TypeParameterFragmentImpl? get previousFragment => null;
}

/// Mixin representing an element which can have type parameters.
mixin TypeParameterizedFragmentMixin on FragmentImpl
    implements TypeParameterizedFragment {
  List<TypeParameterFragmentImpl> _typeParameters = const [];

  /// If the element defines a type, indicates whether the type may safely
  /// appear without explicit type parameters as the bounds of a type parameter
  /// declaration.
  ///
  /// If the element does not define a type, returns `true`.
  bool get isSimplyBounded => true;

  @override
  LibraryFragmentImpl get libraryFragment => enclosingUnit;

  @Deprecated('Use metadata instead')
  @override
  MetadataImpl get metadata2 => metadata;

  @override
  List<TypeParameterFragmentImpl> get typeParameters {
    _ensureReadResolution();
    return _typeParameters;
  }

  set typeParameters(List<TypeParameterFragmentImpl> typeParameters) {
    for (var typeParameter in typeParameters) {
      typeParameter.enclosingFragment = this;
    }
    _typeParameters = typeParameters;
  }

  @Deprecated('Use typeParameters instead')
  @override
  List<TypeParameterFragmentImpl> get typeParameters2 => typeParameters;

  void _ensureReadResolution();
}

abstract class VariableElementImpl extends ElementImpl
    with InternalVariableElement
    implements ConstantEvaluationTarget {
  ConstantInitializerImpl? _constantInitializer;

  /// The result of evaluating [constantInitializer2].
  ///
  /// Is `null` if [constantInitializer2] is `null`, or if the value could not
  /// be computed because of errors.
  Constant? evaluationResult;

  @override
  ExpressionImpl? get constantInitializer {
    return constantInitializer2?.expression;
  }

  // TODO(scheglov): remove this
  ConstantInitializerImpl? get constantInitializer2 {
    if (_constantInitializer case var result?) {
      return result;
    }

    for (var fragment in fragments.reversed) {
      fragment as VariableFragmentImpl;
      if (fragment.initializer case ExpressionImpl expression) {
        return _constantInitializer = ConstantInitializerImpl(
          fragment: fragment,
          expression: expression,
        );
      }
    }

    return null;
  }

  @override
  bool get isConstantEvaluated => evaluationResult != null;

  @override
  LibraryFragmentImpl? get libraryFragment =>
      firstFragment.libraryFragment as LibraryFragmentImpl?;

  set type(TypeImpl type) {
    // TODO(scheglov): eventually move logic from PropertyInducingElementImpl
  }

  @override
  void appendTo(ElementDisplayStringBuilder builder) {
    builder.writeVariableElement(this);
  }

  /// Return a representation of the value of this variable, forcing the value
  /// to be computed if it had not previously been computed, or `null` if either
  /// this variable was not declared with the 'const' modifier or if the value
  /// of this variable could not be computed because of errors.
  @override
  DartObject? computeConstantValue() {
    if (evaluationResult == null) {
      var library = libraryFragment?.element;
      // TODO(scheglov): https://github.com/dart-lang/sdk/issues/47915
      if (library == null) {
        return null;
      }
      computeConstants(
        declaredVariables: library.context.declaredVariables,
        constants: [this],
        featureSet: library.featureSet,
        configuration: ConstantEvaluationConfiguration(),
      );
    }

    if (evaluationResult case DartObjectImpl result) {
      return result;
    }
    return null;
  }

  void resetConstantInitializer() {
    _constantInitializer = null;
  }

  @override
  void visitChildren<T>(ElementVisitor2<T> visitor) {
    for (var child in children) {
      child.accept(visitor);
    }
  }
}

@GenerateFragmentImpl(modifiers: _VariableFragmentImplModifiers.values)
abstract class VariableFragmentImpl extends FragmentImpl
    with _VariableFragmentImplMixin
    implements VariableFragment {
  /// If this element represents a constant variable, and it has an initializer,
  /// a copy of the initializer for the constant.  Otherwise `null`.
  ///
  /// Note that in correct Dart code, all constant variables must have
  /// initializers.  However, analyzer also needs to handle incorrect Dart code,
  /// in which case there might be some constant variables that lack
  /// initializers.
  ExpressionImpl? constantInitializer;

  /// Initialize a newly created variable element to have the given [name] and
  /// [offset].
  VariableFragmentImpl({required super.firstTokenOffset});

  @override
  VariableFragmentImpl get declaration => this;

  @override
  String get displayName => name ?? '';

  @override
  VariableElementImpl get element;

  // TODO(scheglov): remove this
  ExpressionImpl? get initializer {
    return constantInitializer;
  }

  @override
  int get offset {
    if (nameOffset ?? firstTokenOffset case var result?) {
      return result;
    }
    if (this case PropertyInducingFragmentImpl property) {
      var getter = property.element.getter?.firstFragment;
      var setter = property.element.setter?.firstFragment;
      return (getter ?? setter)!.offset;
    }
    if (this case FormalParameterFragmentImpl()) {
      return enclosingFragment!.offset;
    }
    throw StateError('($runtimeType) $this');
  }
}

enum _ClassFragmentImplModifiers {
  hasExtendsClause,

  /// Whether the executable element is abstract.
  ///
  /// Executable elements are abstract if they are not external, and have no
  /// body.
  isAbstract,
  isBase,
  isFinal,
  isInterface,
  isMixinApplication,
  isMixinClass,
  isSealed,
}

enum _ConstructorFragmentImplModifiers { isConst, isFactory }

enum _ExecutableFragmentImplModifiers {
  hasImplicitReturnType,
  invokesSuperSelf,

  /// Whether the executable element is abstract.
  ///
  /// Executable elements are abstract if they are not external, and have no
  /// body.
  isAbstract,
  isAsynchronous,

  /// Executable elements are external if they are explicitly marked as such
  /// using the 'external' keyword.
  isExternal,
  isGenerator,
  isStatic,
}

enum _FieldFragmentImplModifiers {
  /// Whether the field was explicitly marked as being covariant.
  isExplicitlyCovariant,
  isEnumConstant,
  isPromotable,
}

enum _FormalParameterFragmentImplModifiers {
  /// Whether the field was explicitly marked as being covariant.
  isExplicitlyCovariant,
}

enum _FragmentImplModifiers {
  isAugmentation,

  /// A synthetic element is an element that is not represented in the source
  /// code explicitly, but is implied by the source code, such as the default
  /// constructor for a class that does not explicitly define any constructors.
  isSynthetic,
}

enum _InterfaceFragmentImplModifiers { isSimplyBounded }

enum _MixinFragmentImplModifiers { isBase }

enum _NonParameterVariableFragmentImplModifiers { hasInitializer }

/// Instances of [List]s that are used as "not yet computed" values, they
/// must be not `null`, and not identical to `const <T>[]`.
class _Sentinel {
  static final List<ClassFragmentImpl> classFragment = List.unmodifiable([]);
  static final List<ConstructorFragmentImpl> constructorFragment =
      List.unmodifiable([]);
  static final List<EnumFragmentImpl> enumFragment = List.unmodifiable([]);
  static final List<ExtensionFragmentImpl> extensionFragment =
      List.unmodifiable([]);
  static final List<ExtensionTypeFragmentImpl> extensionTypeFragment =
      List.unmodifiable([]);
  static final List<FieldFragmentImpl> fieldFragment = List.unmodifiable([]);
  static final List<GetterFragmentImpl> getterFragment = List.unmodifiable([]);
  static final List<MethodFragmentImpl> methodFragment = List.unmodifiable([]);
  static final List<MixinFragmentImpl> mixinFragment = List.unmodifiable([]);
  static final List<SetterFragmentImpl> setterFragment = List.unmodifiable([]);
  static final List<TypeAliasFragmentImpl> typeAliasFragment =
      List.unmodifiable([]);
  static final List<TopLevelFunctionFragmentImpl> topLevelFunctionFragment =
      List.unmodifiable([]);
  static final List<TopLevelVariableFragmentImpl> topLevelVariableFragment =
      List.unmodifiable([]);

  static final List<ConstructorElementImpl> constructorElement =
      List.unmodifiable([]);

  static final List<LibraryExportImpl> libraryExport = List.unmodifiable([]);
  static final List<LibraryImportImpl> libraryImport = List.unmodifiable([]);
}

enum _TypeAliasFragmentImplModifiers { isSimplyBounded }

enum _VariableFragmentImplModifiers {
  /// Whether the variable element did not have an explicit type specified
  /// for it.
  hasImplicitType,

  /// Whether the executable element is abstract.
  ///
  /// Executable elements are abstract if they are not external, and have no
  /// body.
  isAbstract,
  isConst,

  /// Executable elements are external if they are explicitly marked as such
  /// using the 'external' keyword.
  isExternal,

  /// Whether the variable was declared with the 'final' modifier.
  ///
  /// Variables that are declared with the 'const' modifier will return `false`
  /// even though they are implicitly final.
  isFinal,
  isLate,

  /// Whether the element is a static variable, as per section 8 of the Dart
  /// Language Specification:
  ///
  /// > A static variable is a variable that is not associated with a particular
  /// > instance, but rather with an entire library or class. Static variables
  /// > include library variables and class variables. Class variables are
  /// > variables whose declaration is immediately nested inside a class
  /// > declaration and includes the modifier static. A library variable is
  /// > implicitly static.
  isStatic,
}
