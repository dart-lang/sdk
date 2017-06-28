// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../closure.dart';
import '../common.dart';
import '../common_elements.dart';
import '../compiler.dart';
import '../constants/values.dart';
import '../elements/elements.dart';
import '../elements/entities.dart';
import '../elements/names.dart';
import '../elements/types.dart';
import '../options.dart';
import '../world.dart';
import '../universe/world_builder.dart';
import '../util/emptyset.dart';
import 'constant_handler_javascript.dart';

abstract class MirrorsData {
  /// True if a call to preserveMetadataMarker has been seen.  This means that
  /// metadata must be retained for dart:mirrors to work correctly.
  // resolution-empty-queue
  bool get mustRetainMetadata;

  /// True if any metadata has been retained.  This is slightly different from
  /// [mustRetainMetadata] and tells us if any metadata was retained.  For
  /// example, if [mustRetainMetadata] is true but there is no metadata in the
  /// program, this variable will stil be false.
  // emitter
  bool get hasRetainedMetadata;

  /// True if a call to preserveLibraryNames has been seen.
  // emitter
  bool get mustRetainLibraryNames;

  /// True if a call to preserveNames has been seen.
  // resolution-empty-queue
  bool get mustPreserveNames;

  /// True if a call to disableTreeShaking has been seen.
  bool get isTreeShakingDisabled;

  /// True if a call to preserveUris has been seen and the preserve-uris flag
  /// is set.
  bool get mustPreserveUris;

  /// Set of symbols that the user has requested for reflection.
  Iterable<String> get symbolsUsed;

  /// The members that the user has requested for reflection through the
  /// 'targets' property of a `MirrorsUsed` annotation.
  Iterable<MemberEntity> get membersInMirrorsUsedTargets;

  /// The classes that the user has requested for reflection through the
  /// 'targets' property of a `MirrorsUsed` annotation.
  Iterable<ClassEntity> get classesInMirrorsUsedTargets;

  /// The libraries that the user has requested for reflection through the
  /// 'targets' property of a `MirrorsUsed` annotation.
  Iterable<LibraryEntity> get librariesInMirrorsUsedTargets;

  /// Should the getter for [element] that would normally not be generated due
  /// to tree-shaking be retained for reflection?
  bool shouldRetainGetter(FieldEntity element);

  /// Should the setter for [element] that would normally not be generated due
  /// to tree-shaking be retained for reflection?
  bool shouldRetainSetter(FieldEntity element);

  /// Should [name] be retained for reflection?
  bool shouldRetainName(String name);

  /// Returns `true` if the class [element] is covered by a `MirrorsUsed`
  /// annotation.
  ///
  /// Note that it might still be ok to tree shake the element away if no
  /// reflection is used in the program (and thus [isTreeShakingDisabled] is
  /// still false). Therefore _do not_ use this predicate to decide inclusion
  /// in the tree, use [requiredByMirrorSystem] instead.
  bool isClassReferencedFromMirrorSystem(covariant ClassEntity element);

  /// Returns `true` if the member [element] is covered by a `MirrorsUsed`
  /// annotation.
  ///
  /// Note that it might still be ok to tree shake the element away if no
  /// reflection is used in the program (and thus [isTreeShakingDisabled] is
  /// still false). Therefore _do not_ use this predicate to decide inclusion
  /// in the tree, use [requiredByMirrorSystem] instead.
  bool isMemberReferencedFromMirrorSystem(covariant MemberEntity element);

  /// Returns `true` if the library [element] is covered by a `MirrorsUsed`
  /// annotation.
  bool isLibraryReferencedFromMirrorSystem(covariant LibraryEntity element);

  /// Returns `true` if the typedef [element] needs reflection information at
  /// runtime.
  ///
  /// This property is used to tag emitted elements with a marker which is
  /// checked by the runtime system to throw an exception if an element is
  /// accessed (invoked, get, set) that is not accessible for the reflective
  /// system.
  bool isTypedefAccessibleByReflection(TypedefElement element);

  /// Returns `true` if the class [element] needs reflection information at
  /// runtime.
  ///
  /// This property is used to tag emitted elements with a marker which is
  /// checked by the runtime system to throw an exception if an element is
  /// accessed (invoked, get, set) that is not accessible for the reflective
  /// system.
  bool isClassAccessibleByReflection(ClassEntity element);

  /// Returns `true` if the member [element] needs reflection information at
  /// runtime.
  ///
  /// This property is used to tag emitted elements with a marker which is
  /// checked by the runtime system to throw an exception if an element is
  /// accessed (invoked, get, set) that is not accessible for the reflective
  /// system.
  bool isMemberAccessibleByReflection(MemberEntity element);

  // TODO(johnniwinther): Remove this.
  @deprecated
  bool isAccessibleByReflection(Element element);

  bool retainMetadataOfLibrary(covariant LibraryEntity element,
      {bool addForEmission: true});
  bool retainMetadataOfTypedef(TypedefElement element);
  bool retainMetadataOfClass(covariant ClassEntity element);
  bool retainMetadataOfMember(covariant MemberEntity element);
  bool retainMetadataOfParameter(ParameterElement element);

  bool invokedReflectively(Element element);

  /// Returns true if this element has to be enqueued due to
  /// mirror usage. Might be a subset of [referencedFromMirrorSystem] if
  /// normal tree shaking is still active ([isTreeShakingDisabled] is false).
  bool requiredByMirrorSystem(Element element);
}

abstract class MirrorsDataBuilder {
  void registerUsedMember(MemberElement member);

  /// Called by [MirrorUsageAnalyzerTask] after it has merged all @MirrorsUsed
  /// annotations. The arguments corresponds to the unions of the corresponding
  /// fields of the annotations.
  void registerMirrorUsage(
      Set<String> symbols, Set<Element> targets, Set<Element> metaTargets);

  /// Called when `const Symbol(name)` is seen.
  void registerConstSymbol(String name);

  void maybeMarkClosureAsNeededForReflection(
      ClosureClassElement globalizedElement,
      MethodElement callFunction,
      LocalFunctionElement function);

  void computeMembersNeededForReflection(
      ResolutionWorldBuilder worldBuilder, ClosedWorld closedWorld);
}

class MirrorsDataImpl implements MirrorsData, MirrorsDataBuilder {
  /// True if a call to preserveMetadataMarker has been seen.  This means that
  /// metadata must be retained for dart:mirrors to work correctly.
  bool mustRetainMetadata = false;

  /// True if any metadata has been retained.  This is slightly different from
  /// [mustRetainMetadata] and tells us if any metadata was retained.  For
  /// example, if [mustRetainMetadata] is true but there is no metadata in the
  /// program, this variable will stil be false.
  bool hasRetainedMetadata = false;

  /// True if a call to preserveLibraryNames has been seen.
  bool mustRetainLibraryNames = false;

  /// True if a call to preserveNames has been seen.
  bool mustPreserveNames = false;

  /// True if a call to disableTreeShaking has been seen.
  bool isTreeShakingDisabled = false;

  /// True if there isn't sufficient @MirrorsUsed data.
  bool hasInsufficientMirrorsUsed = false;

  /// True if a call to preserveUris has been seen and the preserve-uris flag
  /// is set.
  bool mustPreserveUris = false;

  /// Set of symbols that the user has requested for reflection.
  final Set<String> symbolsUsed = new Set<String>();

  /// Set of elements that the user has requested for reflection.
  final Set<MemberEntity> membersInMirrorsUsedTargets = new Set<MemberEntity>();
  final Set<ClassEntity> classesInMirrorsUsedTargets = new Set<ClassEntity>();
  final Set<LibraryEntity> librariesInMirrorsUsedTargets =
      new Set<LibraryEntity>();
  final Set<TypedefElement> _typedefsInMirrorsUsedTargets =
      new Set<TypedefElement>();

  /// List of annotations provided by user that indicate that the annotated
  /// element must be retained.
  final Set<ClassEntity> metaTargetsUsed = new Set<ClassEntity>();

  // TODO(johnniwinther): Avoid the need for this.
  final Compiler _compiler;

  final CompilerOptions _options;

  final CommonElements _commonElements;

  MirrorsDataImpl(this._compiler, this._options, this._commonElements);

  JavaScriptConstantCompiler get _constants => _compiler.backend.constants;

  void registerUsedMember(MemberElement member) {
    if (member == _commonElements.disableTreeShakingMarker) {
      isTreeShakingDisabled = true;
    } else if (member == _commonElements.preserveNamesMarker) {
      mustPreserveNames = true;
    } else if (member == _commonElements.preserveMetadataMarker) {
      mustRetainMetadata = true;
    } else if (member == _commonElements.preserveUrisMarker) {
      if (_options.preserveUris) mustPreserveUris = true;
    } else if (member == _commonElements.preserveLibraryNamesMarker) {
      mustRetainLibraryNames = true;
    }
  }

  bool shouldRetainGetter(FieldEntity element) {
    return isTreeShakingDisabled && isMemberAccessibleByReflection(element);
  }

  bool shouldRetainSetter(FieldEntity element) {
    return isTreeShakingDisabled && isMemberAccessibleByReflection(element);
  }

  /// Should [name] be retained for reflection?
  bool shouldRetainName(String name) {
    if (hasInsufficientMirrorsUsed) return mustPreserveNames;
    if (name == '') return false;
    return symbolsUsed.contains(name);
  }

  @override
  bool retainMetadataOfParameter(ParameterElement element) {
    if (mustRetainMetadata) {
      hasRetainedMetadata = true;
      if (isParameterReferencedFromMirrorSystem(element)) {
        _retainMetadataOf(element);
        return true;
      }
    }
    return false;
  }

  @override
  bool retainMetadataOfMember(MemberElement element) {
    if (mustRetainMetadata) {
      hasRetainedMetadata = true;
      if (isMemberReferencedFromMirrorSystem(element)) {
        _retainMetadataOf(element);
        return true;
      }
    }
    return false;
  }

  @override
  bool retainMetadataOfClass(ClassElement element) {
    if (mustRetainMetadata) {
      hasRetainedMetadata = true;
      if (isClassReferencedFromMirrorSystem(element)) {
        _retainMetadataOf(element);
        return true;
      }
    }
    return false;
  }

  @override
  bool retainMetadataOfTypedef(TypedefElement element) {
    if (mustRetainMetadata) {
      hasRetainedMetadata = true;
      if (isTypedefReferencedFromMirrorSystem(element)) {
        _retainMetadataOf(element);
        return true;
      }
    }
    return false;
  }

  @override
  bool retainMetadataOfLibrary(LibraryElement element,
      {bool addForEmission: true}) {
    if (mustRetainMetadata) {
      hasRetainedMetadata = true;
      if (isLibraryReferencedFromMirrorSystem(element)) {
        _retainMetadataOf(element, addForEmission: addForEmission);
        return true;
      }
    }
    return false;
  }

  void _retainMetadataOf(Element element, {bool addForEmission: true}) {
    for (MetadataAnnotation metadata in element.metadata) {
      metadata.ensureResolved(_compiler.resolution);
      ConstantValue constant = _constants.getConstantValueForMetadata(metadata);
      if (addForEmission) {
        CodegenWorldBuilder worldBuilder = _compiler.codegenWorldBuilder;
        worldBuilder.addCompileTimeConstantForEmission(constant);
      }
    }
  }

  bool invokedReflectively(Element element) {
    if (element.isParameter) {
      ParameterElement parameter = element;
      if (invokedReflectively(parameter.functionDeclaration)) return true;
    }

    if (element.isField) {
      if (Elements.isStaticOrTopLevel(element) &&
          (element.isFinal || element.isConst)) {
        return false;
      }
    }

    return isAccessibleByReflection(element.declaration);
  }

  /// Sets of elements that are needed by reflection. Computed using
  /// [computeMembersNeededForReflection] on first use.
  Set<ClassElement> _classesNeededForReflection;
  Set<TypedefElement> _typedefsNeededForReflection;
  Set<MemberElement> _membersNeededForReflection;
  Set<LocalFunctionElement> _closuresNeededForReflection;

  /// Called by [MirrorUsageAnalyzerTask] after it has merged all @MirrorsUsed
  /// annotations. The arguments corresponds to the unions of the corresponding
  /// fields of the annotations.
  // TODO(redemption): Change type of [metaTargets] to `Set<ClassEntity>`.
  void registerMirrorUsage(
      Set<String> symbols, Set<Element> targets, Set<Element> metaTargets) {
    if (symbols == null && targets == null && metaTargets == null) {
      // The user didn't specify anything, or there are imports of
      // 'dart:mirrors' without @MirrorsUsed.
      hasInsufficientMirrorsUsed = true;
      return;
    }
    if (symbols != null) symbolsUsed.addAll(symbols);
    if (targets != null) {
      for (Element target in targets) {
        if (target.isAbstractField) {
          AbstractFieldElement field = target;
          if (field.getter != null) {
            membersInMirrorsUsedTargets.add(field.getter);
          }
          if (field.setter != null) {
            membersInMirrorsUsedTargets.add(field.setter);
          }
        } else if (target.isClass) {
          classesInMirrorsUsedTargets.add(target as ClassEntity);
        } else if (target.isTypedef) {
          _typedefsInMirrorsUsedTargets.add(target);
        } else if (target.isLibrary) {
          librariesInMirrorsUsedTargets.add(target as LibraryEntity);
        } else if (target != null) {
          membersInMirrorsUsedTargets.add(target as MemberEntity);
        }
      }
    }
    if (metaTargets != null) {
      for (dynamic element in metaTargets) {
        if (element is ClassEntity) {
          metaTargetsUsed.add(element);
        }
      }
    }
  }

  @override
  bool isClassAccessibleByReflection(ClassEntity element) {
    return _classesNeededForReflection.contains(_getDartClass(element));
  }

  @override
  bool isTypedefAccessibleByReflection(TypedefElement element) {
    return _typedefsNeededForReflection.contains(element);
  }

  bool isAccessibleByReflection(Element element) {
    if (element.isLibrary) {
      return false;
    } else if (element.isClass) {
      ClassElement cls = element;
      return isClassAccessibleByReflection(cls);
    } else if (element.isTypedef) {
      return isTypedefAccessibleByReflection(element);
    } else {
      MemberElement member = element;
      return isMemberAccessibleByReflection(member);
    }
  }

  ClassEntity _getDartClass(ClassEntity cls) {
    if (cls == _commonElements.jsIntClass) {
      return _commonElements.intClass;
    } else if (cls == _commonElements.jsBoolClass) {
      return _commonElements.boolClass;
    } else if (cls == _commonElements.jsNumberClass) {
      return _commonElements.numClass;
    } else if (cls == _commonElements.jsDoubleClass) {
      return _commonElements.doubleClass;
    } else if (cls == _commonElements.jsStringClass) {
      return _commonElements.stringClass;
    } else if (cls == _commonElements.jsArrayClass) {
      return _commonElements.listClass;
    } else if (cls == _commonElements.jsNullClass) {
      return _commonElements.nullClass;
    } else {
      return cls;
    }
  }

  bool isMemberAccessibleByReflection(MemberEntity element) {
    return _membersNeededForReflection.contains(element);
  }

  /// Returns true if this element has to be enqueued due to
  /// mirror usage. Might be a subset of [referencedFromMirrorSystem] if
  /// normal tree shaking is still active ([isTreeShakingDisabled] is false).
  bool requiredByMirrorSystem(Element element) {
    return hasInsufficientMirrorsUsed && isTreeShakingDisabled ||
        matchesMirrorsMetaTarget(element) ||
        classesInMirrorsUsedTargets.contains(element) ||
        membersInMirrorsUsedTargets.contains(element) ||
        librariesInMirrorsUsedTargets.contains(element) ||
        _typedefsInMirrorsUsedTargets.contains(element);
  }

  @override
  bool isLibraryReferencedFromMirrorSystem(LibraryElement element) {
    return _libraryReferencedFromMirrorSystem(element);
  }

  @override
  bool isMemberReferencedFromMirrorSystem(MemberElement element) {
    if (_memberReferencedFromMirrorSystem(element)) return true;
    if (element.enclosingClass != null) {
      return isClassReferencedFromMirrorSystem(element.enclosingClass);
    } else {
      return isLibraryReferencedFromMirrorSystem(element.library);
    }
  }

  @override
  bool isClassReferencedFromMirrorSystem(ClassElement element) {
    return _classReferencedFromMirrorSystem(element) ||
        isLibraryReferencedFromMirrorSystem(element.library);
  }

  bool isParameterReferencedFromMirrorSystem(ParameterElement element) {
    return _parameterReferencedFromMirrorSystem(element) ||
        isMemberReferencedFromMirrorSystem(element.memberContext);
  }

  bool isTypedefReferencedFromMirrorSystem(TypedefElement element) {
    return _typedefReferencedFromMirrorSystem(element) ||
        isLibraryReferencedFromMirrorSystem(element.library);
  }

  bool _memberReferencedFromMirrorSystem(MemberElement element) {
    return hasInsufficientMirrorsUsed ||
        matchesMirrorsMetaTarget(element) ||
        membersInMirrorsUsedTargets.contains(element);
  }

  bool _parameterReferencedFromMirrorSystem(ParameterElement element) {
    return hasInsufficientMirrorsUsed || matchesMirrorsMetaTarget(element);
  }

  bool _classReferencedFromMirrorSystem(ClassElement element) {
    return hasInsufficientMirrorsUsed ||
        matchesMirrorsMetaTarget(element) ||
        classesInMirrorsUsedTargets.contains(element);
  }

  bool _typedefReferencedFromMirrorSystem(TypedefElement element) {
    return hasInsufficientMirrorsUsed ||
        matchesMirrorsMetaTarget(element) ||
        _typedefsInMirrorsUsedTargets.contains(element);
  }

  bool _libraryReferencedFromMirrorSystem(LibraryElement element) {
    return hasInsufficientMirrorsUsed ||
        matchesMirrorsMetaTarget(element) ||
        librariesInMirrorsUsedTargets.contains(element);
  }

  /**
   * Returns `true` if the element is needed because it has an annotation
   * of a type that is used as a meta target for reflection.
   */
  bool matchesMirrorsMetaTarget(Element element) {
    if (metaTargetsUsed.isEmpty) return false;
    for (MetadataAnnotation metadata in element.metadata) {
      // TODO(kasperl): It would be nice if we didn't have to resolve
      // all metadata but only stuff that potentially would match one
      // of the used meta targets.
      metadata.ensureResolved(_compiler.resolution);
      ConstantValue value =
          _compiler.constants.getConstantValue(metadata.constant);
      if (value == null) continue;
      DartType type = value.getType(_commonElements);
      if (type is InterfaceType && metaTargetsUsed.contains(type.element))
        return true;
    }
    return false;
  }

  void createImmutableSets() {
    _classesNeededForReflection = const ImmutableEmptySet<ClassElement>();
    _typedefsNeededForReflection = const ImmutableEmptySet<TypedefElement>();
    _membersNeededForReflection = const ImmutableEmptySet<MemberElement>();
    _closuresNeededForReflection =
        const ImmutableEmptySet<LocalFunctionElement>();
  }

  /**
   * Visits all classes and computes whether its members are needed for
   * reflection.
   *
   * We have to precompute this set as we cannot easily answer the need for
   * reflection locally when looking at the member: We lack the information by
   * which classes a member is inherited. Called after resolution is complete.
   *
   * We filter out private libraries here, as their elements should not
   * be visible by reflection unless some other interfaces makes them
   * accessible.
   */
  void computeMembersNeededForReflection(
      ResolutionWorldBuilder worldBuilder, ClosedWorld closedWorld) {
    if (_membersNeededForReflection != null) return;
    if (!closedWorld.backendUsage.isMirrorsUsed) {
      createImmutableSets();
      return;
    }
    _classesNeededForReflection = new Set<ClassElement>();
    _typedefsNeededForReflection = new Set<TypedefElement>();
    _membersNeededForReflection = new Set<MemberElement>();
    _closuresNeededForReflection = new Set<LocalFunctionElement>();

    // Compute a mapping from class to the closures it contains, so we
    // can include the correct ones when including the class.
    Map<ClassElement, List<LocalFunctionElement>> closureMap =
        new Map<ClassElement, List<LocalFunctionElement>>();
    for (LocalFunctionElement closure in worldBuilder.localFunctions) {
      closureMap.putIfAbsent(closure.enclosingClass, () => []).add(closure);
    }
    bool foundClosure = false;
    for (ClassElement cls in worldBuilder.directlyInstantiatedClasses) {
      // Do not process internal classes.
      if (cls.library.isInternalLibrary || cls.isInjected) continue;
      if (isClassReferencedFromMirrorSystem(cls)) {
        Set<Name> memberNames = new Set<Name>();
        // 1) the class (should be resolved)
        assert(cls.isResolved, failedAt(cls));
        _classesNeededForReflection.add(cls);
        // 2) its constructors (if resolved)
        cls.constructors.forEach((Element _constructor) {
          ConstructorElement constructor = _constructor;
          if (worldBuilder.isMemberUsed(constructor)) {
            _membersNeededForReflection.add(constructor);
          }
        });
        // 3) all members, including fields via getter/setters (if resolved)
        cls.forEachClassMember((Member member) {
          MemberElement element = member.element;
          if (worldBuilder.isMemberUsed(element)) {
            memberNames.add(member.name);
            _membersNeededForReflection.add(element);
            element.nestedClosures.forEach((FunctionElement _callFunction) {
              SynthesizedCallMethodElementX callFunction = _callFunction;
              _membersNeededForReflection.add(callFunction);
              _classesNeededForReflection.add(callFunction.closureClass);
            });
          }
        });
        // 4) all overriding members of subclasses/subtypes (should be resolved)
        if (closedWorld.hasAnyStrictSubtype(cls)) {
          closedWorld.forEachStrictSubtypeOf(cls, (ClassEntity _subcls) {
            ClassElement subcls = _subcls;
            subcls.forEachClassMember((Member member) {
              if (memberNames.contains(member.name)) {
                // TODO(20993): find out why this assertion fails.
                // assert(worldBuilder.isMemberUsed(member.element),
                //     failedAt(member.element));
                if (worldBuilder.isMemberUsed(member.element)) {
                  _membersNeededForReflection.add(member.element);
                }
              }
            });
          });
        }
        // 5) all its closures
        List<LocalFunctionElement> closures = closureMap[cls];
        if (closures != null) {
          _closuresNeededForReflection.addAll(closures);
          foundClosure = true;
        }
      } else {
        // check members themselves
        cls.constructors.forEach((Element _element) {
          ConstructorElement element = _element;
          if (!worldBuilder.isMemberUsed(element)) return;
          if (_memberReferencedFromMirrorSystem(element)) {
            _membersNeededForReflection.add(element);
          }
        });
        cls.forEachClassMember((Member member) {
          if (!worldBuilder.isMemberUsed(member.element)) return;
          if (_memberReferencedFromMirrorSystem(member.element)) {
            _membersNeededForReflection.add(member.element);
          }
        });
        // Also add in closures. Those might be reflectable is their enclosing
        // member is.
        List<LocalFunctionElement> closures = closureMap[cls];
        if (closures != null) {
          for (LocalFunctionElement closure in closures) {
            MemberElement member = closure.memberContext;
            if (_memberReferencedFromMirrorSystem(member)) {
              _closuresNeededForReflection.add(closure);
              foundClosure = true;
            }
          }
        }
      }
    }
    // We also need top-level non-class elements like static functions and
    // global fields. We use the resolution queue to decide which elements are
    // part of the live world.
    for (LibraryElement lib in _compiler.libraryLoader.libraries) {
      if (lib.isInternalLibrary) continue;
      lib.forEachLocalMember((Element element) {
        if (element.isClass || element.isTypedef) return;
        MemberElement member = element;
        if (worldBuilder.isMemberUsed(member) &&
            isMemberReferencedFromMirrorSystem(member)) {
          _membersNeededForReflection.add(member);
        }
      });
    }
    // And closures inside top-level elements that do not have a surrounding
    // class. These will be in the [:null:] bucket of the [closureMap].
    if (closureMap.containsKey(null)) {
      for (LocalFunctionElement closure in closureMap[null]) {
        if (isMemberReferencedFromMirrorSystem(closure.memberContext)) {
          _closuresNeededForReflection.add(closure);
          foundClosure = true;
        }
      }
    }
    // As we do not think about closures as classes, yet, we have to make sure
    // their superclasses are available for reflection manually.
    if (foundClosure) {
      ClassElement cls = _commonElements.closureClass;
      _classesNeededForReflection.add(cls);
    }
    Set<FunctionEntity> closurizedMembers = worldBuilder.closurizedMembers;
    if (closurizedMembers.any(_membersNeededForReflection.contains)) {
      ClassElement cls = _commonElements.boundClosureClass;
      _classesNeededForReflection.add(cls);
    }
    // Add typedefs.
    _typedefsNeededForReflection.addAll(
        closedWorld.allTypedefs.where(isTypedefReferencedFromMirrorSystem));
    // Register all symbols of reflectable elements
    for (ClassElement element in _classesNeededForReflection) {
      symbolsUsed.add(element.name);
    }
    for (TypedefElement element in _typedefsNeededForReflection) {
      symbolsUsed.add(element.name);
    }
    for (MemberElement element in _membersNeededForReflection) {
      symbolsUsed.add(element.name);
    }
    for (LocalFunctionElement element in _closuresNeededForReflection) {
      symbolsUsed.add(element.name);
    }
  }

  // TODO(20791): compute closure classes after resolution and move this code to
  // [computeMembersNeededForReflection].
  void maybeMarkClosureAsNeededForReflection(
      ClosureClassElement globalizedElement,
      MethodElement callFunction,
      LocalFunctionElement function) {
    if (!_closuresNeededForReflection.contains(function)) return;
    _membersNeededForReflection.add(callFunction);
    _classesNeededForReflection.add(globalizedElement);
  }

  /// Called when `const Symbol(name)` is seen.
  void registerConstSymbol(String name) {
    symbolsUsed.add(name);
    if (name.endsWith('=')) {
      symbolsUsed.add(name.substring(0, name.length - 1));
    }
  }
}
