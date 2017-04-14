// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../common/resolution.dart';
import '../common_elements.dart';
import '../constants/constant_system.dart';
import '../constants/values.dart';
import '../elements/elements.dart';
import '../elements/entities.dart';
import '../elements/resolution_types.dart';
import '../universe/call_structure.dart';
import '../universe/use.dart' show ConstantUse, StaticUse;
import '../universe/world_impact.dart'
    show WorldImpact, StagedWorldImpactBuilder;
import 'backend_usage.dart' show BackendUsageBuilder;
import 'native_data.dart';

/**
 * Support for Custom Elements.
 *
 * The support for custom elements the compiler builds a table that maps the
 * custom element class's [Type] to the interceptor for the class and the
 * constructor(s) for the class.
 *
 * We want the table to contain only the custom element classes used, and we
 * want to avoid resolving and compiling constructors that are not used since
 * that may bring in unused code.  This class controls the resolution and code
 * generation to restrict the impact.
 *
 * The following line of code requires the generation of the generative
 * constructor factory function(s) for FancyButton, and their insertion into the
 * table:
 *
 *     document.register(FancyButton, 'x-fancy-button');
 *
 * We detect this by 'joining' the classes that are referenced as type literals
 * with the classes that are custom elements, enabled by detecting the presence
 * of the table access code used by document.register.
 *
 * We have to be more conservative when the type is unknown, e.g.
 *
 *     document.register(classMirror.reflectedType, tagFromMetadata);
 *
 * and
 *
 *     class Component<T> {
 *       final tag;
 *       Component(this.tag);
 *       void register() => document.register(T, tag);
 *     }
 *     const Component<FancyButton>('x-fancy-button').register();
 *
 * In these cases we conservatively generate all viable entries in the table.
 */
abstract class CustomElementsAnalysisBase {
  final NativeBasicData _nativeData;
  final Resolution _resolution;
  final CommonElements _commonElements;

  CustomElementsAnalysisBase(
      this._resolution, this._commonElements, this._nativeData);

  CustomElementsAnalysisJoin get join;

  void registerInstantiatedClass(ClassElement classElement) {
    classElement.ensureResolved(_resolution);
    if (!_nativeData.isNativeOrExtendsNative(classElement)) return;
    if (classElement.isMixinApplication) return;
    if (classElement.isAbstract) return;
    // JsInterop classes are opaque interfaces without a concrete
    // implementation.
    if (_nativeData.isJsInteropClass(classElement)) return;
    join.instantiatedClasses.add(classElement);
  }

  void registerStaticUse(MemberEntity element) {
    assert(element != null);
    if (element == _commonElements.findIndexForNativeSubclassType) {
      join.demanded = true;
    }
  }

  /// Computes the [WorldImpact] of the classes registered since last flush.
  WorldImpact flush() => join.flush();
}

class CustomElementsResolutionAnalysis extends CustomElementsAnalysisBase {
  final CustomElementsAnalysisJoin join;

  CustomElementsResolutionAnalysis(
      Resolution resolution,
      ConstantSystem constantSystem,
      CommonElements commonElements,
      NativeBasicData nativeData,
      BackendUsageBuilder backendUsageBuilder)
      : join = new CustomElementsAnalysisJoin(
            resolution, constantSystem, commonElements, nativeData,
            backendUsageBuilder: backendUsageBuilder),
        super(resolution, commonElements, nativeData) {
    // TODO(sra): Remove this work-around.  We should mark allClassesSelected in
    // both joins only when we see a construct generating an unknown [Type] but
    // we can't currently recognize all cases.  In particular, the work-around
    // for the unimplemented `ClassMirror.reflectedType` is not recognizable.
    // TODO(12607): Match on [ClassMirror.reflectedType]
    join.allClassesSelected = true;
  }

  void registerTypeLiteral(ResolutionDartType type) {
    if (type.isInterfaceType) {
      // TODO(sra): If we had a flow query from the type literal expression to
      // the Type argument of the metadata lookup, we could tell if this type
      // literal is really a demand for the metadata.
      join.selectedClasses.add(type.element);
    } else if (type.isTypeVariable) {
      // This is a type parameter of a parameterized class.
      // TODO(sra): Is there a way to determine which types are bound to the
      // parameter?
      join.allClassesSelected = true;
    }
  }
}

class CustomElementsCodegenAnalysis extends CustomElementsAnalysisBase {
  final CustomElementsAnalysisJoin join;

  CustomElementsCodegenAnalysis(
      Resolution resolution,
      ConstantSystem constantSystem,
      CommonElements commonElements,
      NativeBasicData nativeData)
      : join = new CustomElementsAnalysisJoin(
            resolution, constantSystem, commonElements, nativeData),
        super(resolution, commonElements, nativeData) {
    // TODO(sra): Remove this work-around.  We should mark allClassesSelected in
    // both joins only when we see a construct generating an unknown [Type] but
    // we can't currently recognize all cases.  In particular, the work-around
    // for the unimplemented `ClassMirror.reflectedType` is not recognizable.
    // TODO(12607): Match on [ClassMirror.reflectedType]
    join.allClassesSelected = true;
  }

  void registerTypeConstant(ClassElement element) {
    assert(element.isClass);
    join.selectedClasses.add(element);
  }

  bool get needsTable => join.demanded;

  bool needsClass(ClassElement classElement) =>
      join.activeClasses.contains(classElement);

  List<ConstructorElement> constructors(ClassElement classElement) =>
      join.computeEscapingConstructors(classElement);
}

class CustomElementsAnalysisJoin {
  final Resolution _resolution;
  final ConstantSystem _constantSystem;
  final CommonElements _commonElements;
  final NativeBasicData _nativeData;
  final BackendUsageBuilder _backendUsageBuilder;

  final bool forResolution;

  final StagedWorldImpactBuilder impactBuilder = new StagedWorldImpactBuilder();

  // Classes that are candidates for needing constructors.  Classes are moved to
  // [activeClasses] when we know they need constructors.
  final instantiatedClasses = new Set<ClassElement>();

  // Classes explicitly named.
  final selectedClasses = new Set<ClassElement>();

  // True if we must conservatively include all extension classes.
  bool allClassesSelected = false;

  // Did we see a demand for the data?
  bool demanded = false;

  // ClassesOutput: classes requiring metadata.
  final activeClasses = new Set<ClassElement>();

  CustomElementsAnalysisJoin(this._resolution, this._constantSystem,
      this._commonElements, this._nativeData,
      {BackendUsageBuilder backendUsageBuilder})
      : this._backendUsageBuilder = backendUsageBuilder,
        this.forResolution = backendUsageBuilder != null;

  WorldImpact flush() {
    if (!demanded) return const WorldImpact();
    var newActiveClasses = new Set<ClassElement>();
    for (ClassElement classElement in instantiatedClasses) {
      bool isNative = _nativeData.isNativeClass(classElement);
      bool isExtension =
          !isNative && _nativeData.isNativeOrExtendsNative(classElement);
      // Generate table entries for native classes that are explicitly named and
      // extensions that fix our criteria.
      if ((isNative && selectedClasses.contains(classElement)) ||
          (isExtension &&
              (allClassesSelected || selectedClasses.contains(classElement)))) {
        newActiveClasses.add(classElement);
        Iterable<ConstructorElement> escapingConstructors =
            computeEscapingConstructors(classElement);
        for (ConstructorElement constructor in escapingConstructors) {
          impactBuilder.registerStaticUse(new StaticUse.constructorInvoke(
              constructor, CallStructure.NO_ARGS));
        }
        if (forResolution) {
          escapingConstructors
              .forEach(_backendUsageBuilder.registerGlobalFunctionDependency);
        }
        // Force the generaton of the type constant that is the key to an entry
        // in the generated table.
        ConstantValue constant = _makeTypeConstant(classElement);
        impactBuilder
            .registerConstantUse(new ConstantUse.customElements(constant));
      }
    }
    activeClasses.addAll(newActiveClasses);
    instantiatedClasses.removeAll(newActiveClasses);
    return impactBuilder.flush();
  }

  TypeConstantValue _makeTypeConstant(ClassElement element) {
    ResolutionDartType elementType = element.rawType;
    return _constantSystem.createType(_commonElements, elementType);
  }

  List<ConstructorElement> computeEscapingConstructors(
      ClassElement classElement) {
    List<ConstructorElement> result = <ConstructorElement>[];
    // Only classes that extend native classes have constructors in the table.
    // We could refine this to classes that extend Element, but that would break
    // the tests and there is no sane reason to subclass other native classes.
    if (_nativeData.isNativeClass(classElement)) return result;

    void selectGenerativeConstructors(ClassElement enclosing, Element member) {
      if (member.isGenerativeConstructor) {
        // Ignore constructors that cannot be called with zero arguments.
        ConstructorElement constructor = member;
        constructor.computeType(_resolution);
        FunctionSignature parameters = constructor.functionSignature;
        if (parameters.requiredParameterCount == 0) {
          result.add(member);
        }
      }
    }

    classElement.forEachMember(selectGenerativeConstructors,
        includeBackendMembers: false, includeSuperAndInjectedMembers: false);
    return result;
  }
}
