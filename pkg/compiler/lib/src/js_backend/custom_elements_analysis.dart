// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../common/elements.dart';
import '../constants/constant_system.dart' as constant_system;
import '../constants/values.dart';
import '../elements/entities.dart';
import '../elements/types.dart';
import '../universe/call_structure.dart';
import '../universe/use.dart' show ConstantUse, StaticUse;
import '../universe/world_impact.dart' show WorldImpact, WorldImpactBuilderImpl;
import 'backend_usage.dart' show BackendUsageBuilder;
import 'native_data.dart';

/// Support for Custom Elements.
///
/// The support for custom elements the compiler builds a table that maps the
/// custom element class's [Type] to the interceptor for the class and the
/// constructor(s) for the class.
///
/// We want the table to contain only the custom element classes used, and we
/// want to avoid resolving and compiling constructors that are not used since
/// that may bring in unused code.  This class controls the resolution and code
/// generation to restrict the impact.
///
/// The following line of code requires the generation of the generative
/// constructor factory function(s) for FancyButton, and their insertion into
/// the table:
///
///     document.register(FancyButton, 'x-fancy-button');
///
/// We detect this by 'joining' the classes that are referenced as type literals
/// with the classes that are custom elements, enabled by detecting the presence
/// of the table access code used by document.register.
///
/// We have to be more conservative when the type is unknown, e.g.
///
///     document.register(classMirror.reflectedType, tagFromMetadata);
///
/// and
///
///     class Component<T> {
///       final tag;
///       Component(this.tag);
///       void register() => document.register(T, tag);
///     }
///     const Component<FancyButton>('x-fancy-button').register();
///
/// In these cases we conservatively generate all viable entries in the table.
abstract class CustomElementsAnalysisBase {
  final NativeBasicData _nativeData;
  final ElementEnvironment _elementEnvironment;
  final CommonElements _commonElements;

  CustomElementsAnalysisBase(
      this._elementEnvironment, this._commonElements, this._nativeData);

  CustomElementsAnalysisJoin get join;

  void registerInstantiatedClass(ClassEntity cls) {
    if (!_nativeData.isNativeOrExtendsNative(cls)) return;
    if (_elementEnvironment.isUnnamedMixinApplication(cls)) return;
    if (cls.isAbstract) return;
    // JsInterop classes are opaque interfaces without a concrete
    // implementation.
    if (_nativeData.isJsInteropClass(cls)) return;
    join.instantiatedClasses.add(cls);
  }

  void registerStaticUse(MemberEntity element) {
    if (_commonElements.isFindIndexForNativeSubclassType(element)) {
      join.demanded = true;
    }
  }

  /// Computes the [WorldImpact] of the classes registered since last flush.
  WorldImpact flush() => join.flush();
}

class CustomElementsResolutionAnalysis extends CustomElementsAnalysisBase {
  @override
  final CustomElementsAnalysisJoin join;

  CustomElementsResolutionAnalysis(
      super.elementEnvironment,
      super.commonElements,
      super.nativeData,
      BackendUsageBuilder backendUsageBuilder)
      : join = CustomElementsAnalysisJoin(
            elementEnvironment, commonElements, nativeData,
            backendUsageBuilder: backendUsageBuilder) {
    // TODO(sra): Remove this workaround.  We should mark allClassesSelected in
    // both joins only when we see a construct generating an unknown [Type] but
    // we can't currently recognize all cases.  In particular, the workaround
    // for the unimplemented `ClassMirror.reflectedType` is not recognizable.
    // TODO(12607): Match on [ClassMirror.reflectedType]
    join.allClassesSelected = true;
  }

  void registerTypeLiteral(DartType type) {
    if (type is InterfaceType) {
      // TODO(sra): If we had a flow query from the type literal expression to
      // the Type argument of the metadata lookup, we could tell if this type
      // literal is really a demand for the metadata.
      InterfaceType interfaceType = type;
      join.selectedClasses.add(interfaceType.element);
    } else if (type is TypeVariableType) {
      // This is a type parameter of a parameterized class.
      // TODO(sra): Is there a way to determine which types are bound to the
      // parameter?
      join.allClassesSelected = true;
    }
  }
}

class CustomElementsCodegenAnalysis extends CustomElementsAnalysisBase {
  @override
  final CustomElementsAnalysisJoin join;

  CustomElementsCodegenAnalysis(CommonElements commonElements,
      ElementEnvironment elementEnvironment, NativeBasicData nativeData)
      : join = CustomElementsAnalysisJoin(
            elementEnvironment, commonElements, nativeData),
        super(elementEnvironment, commonElements, nativeData) {
    // TODO(sra): Remove this workaround.  We should mark allClassesSelected in
    // both joins only when we see a construct generating an unknown [Type] but
    // we can't currently recognize all cases.  In particular, the workaround
    // for the unimplemented `ClassMirror.reflectedType` is not recognizable.
    // TODO(12607): Match on [ClassMirror.reflectedType]
    join.allClassesSelected = true;
  }

  void registerTypeConstant(ClassEntity cls) {
    join.selectedClasses.add(cls);
  }

  bool get needsTable => join.demanded;

  bool needsClass(ClassEntity cls) => join.activeClasses.contains(cls);

  List<ConstructorEntity> constructors(ClassEntity cls) =>
      join.computeEscapingConstructors(cls);
}

class CustomElementsAnalysisJoin {
  final ElementEnvironment _elementEnvironment;
  final CommonElements _commonElements;
  final NativeBasicData _nativeData;
  final BackendUsageBuilder? _backendUsageBuilder;

  // Classes that are candidates for needing constructors.  Classes are moved to
  // [activeClasses] when we know they need constructors.
  final Set<ClassEntity> instantiatedClasses = {};

  // Classes explicitly named.
  final Set<ClassEntity> selectedClasses = {};

  // True if we must conservatively include all extension classes.
  bool allClassesSelected = false;

  // Did we see a demand for the data?
  bool demanded = false;

  // ClassesOutput: classes requiring metadata.
  final Set<ClassEntity> activeClasses = {};

  CustomElementsAnalysisJoin(
      this._elementEnvironment, this._commonElements, this._nativeData,
      {BackendUsageBuilder? backendUsageBuilder})
      : this._backendUsageBuilder = backendUsageBuilder;

  WorldImpact flush() {
    if (!demanded) return const WorldImpact();
    final impactBuilder = WorldImpactBuilderImpl();
    var newActiveClasses = Set<ClassEntity>();
    for (ClassEntity cls in instantiatedClasses) {
      bool isNative = _nativeData.isNativeClass(cls);
      bool isExtension = !isNative && _nativeData.isNativeOrExtendsNative(cls);
      // Generate table entries for native classes that are explicitly named and
      // extensions that fix our criteria.
      if ((isNative && selectedClasses.contains(cls)) ||
          (isExtension &&
              (allClassesSelected || selectedClasses.contains(cls)))) {
        newActiveClasses.add(cls);
        Iterable<ConstructorEntity> escapingConstructors =
            computeEscapingConstructors(cls);
        for (ConstructorEntity constructor in escapingConstructors) {
          impactBuilder.registerStaticUse(
              StaticUse.constructorInvoke(constructor, CallStructure.NO_ARGS));
        }
        if (_backendUsageBuilder != null) {
          escapingConstructors
              .forEach(_backendUsageBuilder!.registerGlobalFunctionDependency);
        }
        // Force the generation of the type constant that is the key to an entry
        // in the generated table.
        final constant = _makeTypeConstant(cls);
        impactBuilder.registerConstantUse(ConstantUse.customElements(constant));
      }
    }
    activeClasses.addAll(newActiveClasses);
    instantiatedClasses.removeAll(newActiveClasses);
    return impactBuilder;
  }

  TypeConstantValue _makeTypeConstant(ClassEntity cls) {
    DartType type = _elementEnvironment.getRawType(cls);
    return constant_system.createType(_commonElements, type);
  }

  List<ConstructorEntity> computeEscapingConstructors(ClassEntity cls) {
    List<ConstructorEntity> result = [];
    // Only classes that extend native classes have constructors in the table.
    // We could refine this to classes that extend Element, but that would break
    // the tests and there is no sane reason to subclass other native classes.
    if (_nativeData.isNativeClass(cls)) return result;

    _elementEnvironment.forEachConstructor(cls,
        (ConstructorEntity constructor) {
      if (constructor.isGenerativeConstructor) {
        // Ensure that parameter structure has been computed by querying the
        // function type.
        _elementEnvironment.getFunctionType(constructor);
        // Ignore constructors that cannot be called with zero arguments.
        if (constructor.parameterStructure.requiredPositionalParameters == 0) {
          result.add(constructor);
        }
      }
    });
    return result;
  }
}
