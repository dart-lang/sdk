// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../common.dart';
import '../common_elements.dart';
import '../compiler.dart';
import '../constants/values.dart';
import '../elements/elements.dart' show AbstractFieldElement, Element;
import '../elements/entities.dart';
import '../elements/names.dart';
import '../elements/types.dart';
import '../options.dart';
import '../world.dart';
import '../universe/world_builder.dart';
import '../util/emptyset.dart';

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
  bool isClassReferencedFromMirrorSystem(ClassEntity element);

  /// Returns `true` if the member [element] is covered by a `MirrorsUsed`
  /// annotation.
  ///
  /// Note that it might still be ok to tree shake the element away if no
  /// reflection is used in the program (and thus [isTreeShakingDisabled] is
  /// still false). Therefore _do not_ use this predicate to decide inclusion
  /// in the tree, use [requiredByMirrorSystem] instead.
  bool isMemberReferencedFromMirrorSystem(MemberEntity element);

  /// Returns `true` if the library [element] is covered by a `MirrorsUsed`
  /// annotation.
  bool isLibraryReferencedFromMirrorSystem(LibraryEntity element);

  /// Returns `true` if the typedef [element] needs reflection information at
  /// runtime.
  ///
  /// This property is used to tag emitted elements with a marker which is
  /// checked by the runtime system to throw an exception if an element is
  /// accessed (invoked, get, set) that is not accessible for the reflective
  /// system.
  bool isTypedefAccessibleByReflection(TypedefEntity element);

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

  bool retainMetadataOfLibrary(LibraryEntity element,
      {bool addForEmission: true});
  bool retainMetadataOfTypedef(TypedefEntity element);
  bool retainMetadataOfClass(ClassEntity element);
  bool retainMetadataOfMember(MemberEntity element);

  /// Returns true if this element has to be enqueued due to
  /// mirror usage. Might be a subset of [referencedFromMirrorSystem] if
  /// normal tree shaking is still active ([isTreeShakingDisabled] is false).
  bool isLibraryRequiredByMirrorSystem(LibraryEntity element);
  bool isClassRequiredByMirrorSystem(ClassEntity element);
  bool isMemberRequiredByMirrorSystem(MemberEntity element);
}

abstract class MirrorsDataBuilder {
  void registerUsedMember(MemberEntity member);

  /// Called by [MirrorUsageAnalyzerTask] after it has merged all @MirrorsUsed
  /// annotations. The arguments corresponds to the unions of the corresponding
  /// fields of the annotations.
  void registerMirrorUsage(
      Set<String> symbols, Set<Element> targets, Set<Element> metaTargets);

  /// Called when `const Symbol(name)` is seen.
  void registerConstSymbol(String name);

  void maybeMarkClosureAsNeededForReflection(
      ClassEntity closureClass, FunctionEntity callMethod, Local localFunction);

  void computeMembersNeededForReflection(
      ResolutionWorldBuilder worldBuilder, ClosedWorld closedWorld);
}

abstract class MirrorsDataImpl implements MirrorsData, MirrorsDataBuilder {
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
  final Set<TypedefEntity> _typedefsInMirrorsUsedTargets =
      new Set<TypedefEntity>();

  /// List of annotations provided by user that indicate that the annotated
  /// element must be retained.
  final Set<ClassEntity> metaTargetsUsed = new Set<ClassEntity>();

  // TODO(johnniwinther): Avoid the need for this.
  final Compiler _compiler;

  final CompilerOptions _options;

  final ElementEnvironment _elementEnvironment;
  final CommonElements _commonElements;

  MirrorsDataImpl(this._compiler, this._options, this._elementEnvironment,
      this._commonElements);

  void registerUsedMember(MemberEntity member) {
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
  bool retainMetadataOfMember(MemberEntity element) {
    if (mustRetainMetadata) {
      hasRetainedMetadata = true;
      if (isMemberReferencedFromMirrorSystem(element)) {
        _addConstantsForEmission(
            getMemberMetadata(element, includeParameterMetadata: true));
        return true;
      }
    }
    return false;
  }

  @override
  bool retainMetadataOfClass(ClassEntity element) {
    if (mustRetainMetadata) {
      hasRetainedMetadata = true;
      if (isClassReferencedFromMirrorSystem(element)) {
        _addConstantsForEmission(getClassMetadata(element));
        return true;
      }
    }
    return false;
  }

  @override
  bool retainMetadataOfTypedef(TypedefEntity element) {
    if (mustRetainMetadata) {
      hasRetainedMetadata = true;
      if (_isTypedefReferencedFromMirrorSystem(element)) {
        _addConstantsForEmission(getTypedefMetadata(element));
        return true;
      }
    }
    return false;
  }

  @override
  bool retainMetadataOfLibrary(LibraryEntity element,
      {bool addForEmission: true}) {
    if (mustRetainMetadata) {
      hasRetainedMetadata = true;
      if (isLibraryReferencedFromMirrorSystem(element)) {
        Iterable<ConstantValue> constants = getLibraryMetadata(element);
        if (addForEmission) {
          _addConstantsForEmission(constants);
        }
        return true;
      }
    }
    return false;
  }

  Iterable<ConstantValue> getLibraryMetadata(LibraryEntity element) {
    return _elementEnvironment.getLibraryMetadata(element);
  }

  Iterable<ConstantValue> getClassMetadata(ClassEntity element) {
    return _elementEnvironment.getClassMetadata(element);
  }

  Iterable<ConstantValue> getMemberMetadata(MemberEntity element,
      {bool includeParameterMetadata}) {
    return _elementEnvironment.getMemberMetadata(element,
        includeParameterMetadata: includeParameterMetadata);
  }

  Iterable<ConstantValue> getTypedefMetadata(TypedefEntity element) {
    return _elementEnvironment.getTypedefMetadata(element);
  }

  void _addConstantsForEmission(Iterable<ConstantValue> constants) {
    for (ConstantValue constant in constants) {
      CodegenWorldBuilder worldBuilder = _compiler.codegenWorldBuilder;
      worldBuilder.addCompileTimeConstantForEmission(constant);
    }
  }

  /// Sets of elements that are needed by reflection. Computed using
  /// [computeMembersNeededForReflection] on first use.
  Set<ClassEntity> _classesNeededForReflection;
  Set<TypedefEntity> _typedefsNeededForReflection;
  Set<MemberEntity> _membersNeededForReflection;
  Set<Local> _closuresNeededForReflection;

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
          _typedefsInMirrorsUsedTargets.add(target as TypedefEntity);
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
  bool isTypedefAccessibleByReflection(TypedefEntity element) {
    return _typedefsNeededForReflection.contains(element);
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
  bool isLibraryRequiredByMirrorSystem(LibraryEntity element) {
    return hasInsufficientMirrorsUsed && isTreeShakingDisabled ||
        _libraryMatchesMirrorsMetaTarget(element) ||
        librariesInMirrorsUsedTargets.contains(element);
  }

  bool isClassRequiredByMirrorSystem(ClassEntity element) {
    return hasInsufficientMirrorsUsed && isTreeShakingDisabled ||
        _classMatchesMirrorsMetaTarget(element) ||
        classesInMirrorsUsedTargets.contains(element);
  }

  bool isMemberRequiredByMirrorSystem(MemberEntity element) {
    return hasInsufficientMirrorsUsed && isTreeShakingDisabled ||
        _memberMatchesMirrorsMetaTarget(element) ||
        membersInMirrorsUsedTargets.contains(element);
  }

  @override
  bool isLibraryReferencedFromMirrorSystem(LibraryEntity element) {
    return _libraryReferencedFromMirrorSystem(element);
  }

  @override
  bool isMemberReferencedFromMirrorSystem(MemberEntity element) {
    if (_memberReferencedFromMirrorSystem(element)) return true;
    if (element.enclosingClass != null) {
      return isClassReferencedFromMirrorSystem(element.enclosingClass);
    } else {
      return isLibraryReferencedFromMirrorSystem(element.library);
    }
  }

  @override
  bool isClassReferencedFromMirrorSystem(ClassEntity element) {
    return _classReferencedFromMirrorSystem(element) ||
        isLibraryReferencedFromMirrorSystem(element.library);
  }

  bool _isTypedefReferencedFromMirrorSystem(TypedefEntity element) {
    return _typedefReferencedFromMirrorSystem(element) ||
        isLibraryReferencedFromMirrorSystem(element.library);
  }

  bool _memberReferencedFromMirrorSystem(MemberEntity element) {
    return hasInsufficientMirrorsUsed ||
        _memberMatchesMirrorsMetaTarget(element) ||
        membersInMirrorsUsedTargets.contains(element);
  }

  bool _classReferencedFromMirrorSystem(ClassEntity element) {
    return hasInsufficientMirrorsUsed ||
        _classMatchesMirrorsMetaTarget(element) ||
        classesInMirrorsUsedTargets.contains(element);
  }

  bool _typedefReferencedFromMirrorSystem(TypedefEntity element) {
    return hasInsufficientMirrorsUsed ||
        _typedefMatchesMirrorsMetaTarget(element) ||
        _typedefsInMirrorsUsedTargets.contains(element);
  }

  bool _libraryReferencedFromMirrorSystem(LibraryEntity element) {
    return hasInsufficientMirrorsUsed ||
        _libraryMatchesMirrorsMetaTarget(element) ||
        librariesInMirrorsUsedTargets.contains(element);
  }

  bool _libraryMatchesMirrorsMetaTarget(LibraryEntity element) {
    if (metaTargetsUsed.isEmpty) return false;
    return _matchesMirrorsMetaTarget(getLibraryMetadata(element));
  }

  bool _classMatchesMirrorsMetaTarget(ClassEntity element) {
    if (metaTargetsUsed.isEmpty) return false;
    return _matchesMirrorsMetaTarget(getClassMetadata(element));
  }

  bool _memberMatchesMirrorsMetaTarget(MemberEntity element) {
    if (metaTargetsUsed.isEmpty) return false;
    return _matchesMirrorsMetaTarget(
        getMemberMetadata(element, includeParameterMetadata: false));
  }

  bool _typedefMatchesMirrorsMetaTarget(TypedefEntity element) {
    if (metaTargetsUsed.isEmpty) return false;
    return _matchesMirrorsMetaTarget(getTypedefMetadata(element));
  }

  /**
   * Returns `true` if the element is needed because it has an annotation
   * of a type that is used as a meta target for reflection.
   */
  bool _matchesMirrorsMetaTarget(Iterable<ConstantValue> constants) {
    if (metaTargetsUsed.isEmpty) return false;
    for (ConstantValue constant in constants) {
      DartType type = constant.getType(_commonElements);
      if (type is InterfaceType && metaTargetsUsed.contains(type.element))
        return true;
    }
    return false;
  }

  void createImmutableSets() {
    _classesNeededForReflection = const ImmutableEmptySet<ClassEntity>();
    _typedefsNeededForReflection = const ImmutableEmptySet<TypedefEntity>();
    _membersNeededForReflection = const ImmutableEmptySet<MemberEntity>();
    _closuresNeededForReflection = const ImmutableEmptySet<Local>();
  }

  bool isLibraryInternal(LibraryEntity library) {
    return library.canonicalUri.scheme == 'dart' &&
        library.canonicalUri.path.startsWith('_');
  }

  /// Whether [cls] is 'injected'.
  ///
  /// An injected class is declared in a patch library with no corresponding
  /// class in the origin library.
  // TODO(redemption): Detect injected classes from .dill.
  bool isClassInjected(ClassEntity cls) => false;

  bool isClassResolved(ClassEntity cls) => true;

  void forEachConstructor(
      ClassEntity cls, void f(ConstructorEntity constructor)) {
    _elementEnvironment.forEachConstructor(cls, f);
  }

  void forEachClassMember(
      ClassEntity cls, void f(MemberEntity member, Name memberName)) {
    _elementEnvironment.forEachClassMember(cls,
        (ClassEntity declarer, MemberEntity member) {
      if (member.isSetter) {
        f(member, member.memberName.setter);
      } else {
        f(member, member.memberName.getter);
      }
    });
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
    _classesNeededForReflection = new Set<ClassEntity>();
    _typedefsNeededForReflection = new Set<TypedefEntity>();
    _membersNeededForReflection = new Set<MemberEntity>();
    _closuresNeededForReflection = new Set<Local>();

    // Compute a mapping from class to the closures it contains, so we
    // can include the correct ones when including the class.
    Map<ClassEntity, List<Local>> closureMap =
        new Map<ClassEntity, List<Local>>();
    for (Local closure in worldBuilder.localFunctions) {
      closureMap
          .putIfAbsent(closure.memberContext.enclosingClass, () => [])
          .add(closure);
    }
    bool foundClosure = false;
    for (ClassEntity cls in worldBuilder.directlyInstantiatedClasses) {
      // Do not process internal classes.
      if (isLibraryInternal(cls.library) || isClassInjected(cls)) continue;
      if (isClassReferencedFromMirrorSystem(cls)) {
        Set<Name> memberNames = new Set<Name>();
        // 1) the class (should be resolved)
        assert(isClassResolved(cls), failedAt(cls));
        _classesNeededForReflection.add(cls);
        // 2) its constructors (if resolved)
        forEachConstructor(cls, (ConstructorEntity constructor) {
          if (worldBuilder.isMemberUsed(constructor)) {
            _membersNeededForReflection.add(constructor);
          }
        });
        // 3) all members, including fields via getter/setters (if resolved)
        forEachClassMember(cls, (MemberEntity member, Name memberName) {
          if (worldBuilder.isMemberUsed(member)) {
            memberNames.add(memberName);
            _membersNeededForReflection.add(member);
          }
        });
        // 4) all overriding members of subclasses/subtypes (should be resolved)
        if (closedWorld.hasAnyStrictSubtype(cls)) {
          closedWorld.forEachStrictSubtypeOf(cls, (ClassEntity subcls) {
            forEachClassMember(subcls, (MemberEntity member, Name memberName) {
              if (memberNames.contains(memberName)) {
                // TODO(20993): find out why this assertion fails.
                // assert(worldBuilder.isMemberUsed(member.element),
                //     failedAt(member.element));
                if (worldBuilder.isMemberUsed(member)) {
                  _membersNeededForReflection.add(member);
                }
              }
            });
          });
        }
        // 5) all its closures
        List<Local> closures = closureMap[cls];
        if (closures != null) {
          _closuresNeededForReflection.addAll(closures);
          foundClosure = true;
        }
      } else {
        // check members themselves
        forEachConstructor(cls, (ConstructorEntity element) {
          if (!worldBuilder.isMemberUsed(element)) return;
          if (_memberReferencedFromMirrorSystem(element)) {
            _membersNeededForReflection.add(element);
          }
        });
        forEachClassMember(cls, (MemberEntity member, _) {
          if (!worldBuilder.isMemberUsed(member)) return;
          if (_memberReferencedFromMirrorSystem(member)) {
            _membersNeededForReflection.add(member);
          }
        });
        // Also add in closures. Those might be reflectable is their enclosing
        // member is.
        List<Local> closures = closureMap[cls];
        if (closures != null) {
          for (Local closure in closures) {
            MemberEntity member = closure.memberContext;
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
    for (LibraryEntity lib in _elementEnvironment.libraries) {
      if (isLibraryInternal(lib)) continue;
      _elementEnvironment.forEachLibraryMember(lib, (MemberEntity member) {
        if (worldBuilder.isMemberUsed(member) &&
            isMemberReferencedFromMirrorSystem(member)) {
          _membersNeededForReflection.add(member);
        }
      });
    }
    // And closures inside top-level elements that do not have a surrounding
    // class. These will be in the [:null:] bucket of the [closureMap].
    if (closureMap.containsKey(null)) {
      for (Local closure in closureMap[null]) {
        if (isMemberReferencedFromMirrorSystem(closure.memberContext)) {
          _closuresNeededForReflection.add(closure);
          foundClosure = true;
        }
      }
    }
    // As we do not think about closures as classes, yet, we have to make sure
    // their superclasses are available for reflection manually.
    if (foundClosure) {
      ClassEntity cls = _commonElements.closureClass;
      _classesNeededForReflection.add(cls);
    }
    Set<FunctionEntity> closurizedMembers = worldBuilder.closurizedMembers;
    if (closurizedMembers.any(_membersNeededForReflection.contains)) {
      ClassEntity cls = _commonElements.boundClosureClass;
      _classesNeededForReflection.add(cls);
    }
    // Add typedefs.
    for (TypedefEntity element in closedWorld.allTypedefs) {
      if (_isTypedefReferencedFromMirrorSystem(element)) {
        _typedefsNeededForReflection.add(element);
      }
    }
    // Register all symbols of reflectable elements
    for (ClassEntity element in _classesNeededForReflection) {
      symbolsUsed.add(element.name);
    }
    for (TypedefEntity element in _typedefsNeededForReflection) {
      symbolsUsed.add(element.name);
    }
    for (MemberEntity element in _membersNeededForReflection) {
      symbolsUsed.add(element.name);
    }
    for (Local element in _closuresNeededForReflection) {
      symbolsUsed.add(element.name);
    }
  }

  // TODO(20791): compute closure classes after resolution and move this code to
  // [computeMembersNeededForReflection].
  void maybeMarkClosureAsNeededForReflection(ClassEntity closureClass,
      FunctionEntity callMethod, Local localFunction) {
    if (!_closuresNeededForReflection.contains(localFunction)) return;
    _membersNeededForReflection.add(callMethod);
    _classesNeededForReflection.add(closureClass);
  }

  /// Called when `const Symbol(name)` is seen.
  void registerConstSymbol(String name) {
    symbolsUsed.add(name);
    if (name.endsWith('=')) {
      symbolsUsed.add(name.substring(0, name.length - 1));
    }
  }
}
