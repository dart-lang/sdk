// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../closure.dart';
import '../common.dart';
import '../common_elements.dart';
import '../compiler.dart';
import '../constants/values.dart';
import '../elements/elements.dart';
import '../elements/resolution_types.dart';
import '../options.dart';
import '../world.dart';
import '../universe/world_builder.dart';
import '../util/emptyset.dart';
import 'backend_helpers.dart';
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

  /// Set of elements that the user has requested for reflection.
  Iterable<Element> get targetsUsed;

  /// Should [element] (a getter) that would normally not be generated due to
  /// treeshaking be retained for reflection?
  bool shouldRetainGetter(Element element);

  /// Should [element] (a setter) hat would normally not be generated due to
  /// treeshaking be retained for reflection?
  bool shouldRetainSetter(Element element);

  /// Should [name] be retained for reflection?
  bool shouldRetainName(String name);

  /// Returns true if this element is covered by a mirrorsUsed annotation.
  ///
  /// Note that it might still be ok to tree shake the element away if no
  /// reflection is used in the program (and thus [isTreeShakingDisabled] is
  /// still false). Therefore _do not_ use this predicate to decide inclusion
  /// in the tree, use [requiredByMirrorSystem] instead.
  bool referencedFromMirrorSystem(Element element, [recursive = true]);

  /// Returns `true` if [element] can be accessed through reflection, that is,
  /// is in the set of elements covered by a `MirrorsUsed` annotation.
  ///
  /// This property is used to tag emitted elements with a marker which is
  /// checked by the runtime system to throw an exception if an element is
  /// accessed (invoked, get, set) that is not accessible for the reflective
  /// system.
  bool isAccessibleByReflection(Element element);

  bool retainMetadataOf(Element element);

  bool invokedReflectively(Element element);

  /// Returns `true` if this member element needs reflection information at
  /// runtime.
  bool isMemberAccessibleByReflection(MemberElement element);

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
      FunctionElement callFunction,
      FunctionElement function);

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
  final Set<Element> targetsUsed = new Set<Element>();

  /// List of annotations provided by user that indicate that the annotated
  /// element must be retained.
  final Set<Element> metaTargetsUsed = new Set<Element>();

  // TODO(johnniwinther): Avoid the need for this.
  final Compiler _compiler;

  final CompilerOptions _options;

  final CommonElements _commonElements;

  final BackendHelpers _helpers;

  final JavaScriptConstantCompiler _constants;

  MirrorsDataImpl(this._compiler, this._options, this._commonElements,
      this._helpers, this._constants);

  void registerUsedMember(MemberElement member) {
    if (member == _helpers.disableTreeShakingMarker) {
      isTreeShakingDisabled = true;
    } else if (member == _helpers.preserveNamesMarker) {
      mustPreserveNames = true;
    } else if (member == _helpers.preserveMetadataMarker) {
      mustRetainMetadata = true;
    } else if (member == _helpers.preserveUrisMarker) {
      if (_options.preserveUris) mustPreserveUris = true;
    } else if (member == _helpers.preserveLibraryNamesMarker) {
      mustRetainLibraryNames = true;
    }
  }

  /// Should [element] (a getter) that would normally not be generated due to
  /// treeshaking be retained for reflection?
  bool shouldRetainGetter(Element element) {
    return isTreeShakingDisabled && isAccessibleByReflection(element);
  }

  /// Should [element] (a setter) hat would normally not be generated due to
  /// treeshaking be retained for reflection?
  bool shouldRetainSetter(Element element) {
    return isTreeShakingDisabled && isAccessibleByReflection(element);
  }

  /// Should [name] be retained for reflection?
  bool shouldRetainName(String name) {
    if (hasInsufficientMirrorsUsed) return mustPreserveNames;
    if (name == '') return false;
    return symbolsUsed.contains(name);
  }

  bool retainMetadataOf(Element element) {
    if (mustRetainMetadata) hasRetainedMetadata = true;
    if (mustRetainMetadata && referencedFromMirrorSystem(element)) {
      for (MetadataAnnotation metadata in element.metadata) {
        metadata.ensureResolved(_compiler.resolution);
        ConstantValue constant =
            _constants.getConstantValueForMetadata(metadata);
        _constants.addCompileTimeConstantForEmission(constant);
      }
      return true;
    }
    return false;
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

  /// Set of methods that are needed by reflection. Computed using
  /// [computeMembersNeededForReflection] on first use.
  Set<Element> _membersNeededForReflection = null;
  Iterable<Element> get membersNeededForReflection {
    assert(_membersNeededForReflection != null);
    return _membersNeededForReflection;
  }

  /// Called by [MirrorUsageAnalyzerTask] after it has merged all @MirrorsUsed
  /// annotations. The arguments corresponds to the unions of the corresponding
  /// fields of the annotations.
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
          targetsUsed.add(field.getter);
          targetsUsed.add(field.setter);
        } else {
          targetsUsed.add(target);
        }
      }
    }
    if (metaTargets != null) metaTargetsUsed.addAll(metaTargets);
  }

  /// Returns `true` if [element] can be accessed through reflection, that is,
  /// is in the set of elements covered by a `MirrorsUsed` annotation.
  ///
  /// This property is used to tag emitted elements with a marker which is
  /// checked by the runtime system to throw an exception if an element is
  /// accessed (invoked, get, set) that is not accessible for the reflective
  /// system.
  bool isAccessibleByReflection(Element element) {
    if (element.isClass) {
      element = _getDartClass(element);
    }
    return membersNeededForReflection.contains(element);
  }

  ClassElement _getDartClass(ClassElement cls) {
    if (cls == _helpers.jsIntClass) {
      return _commonElements.intClass;
    } else if (cls == _helpers.jsBoolClass) {
      return _commonElements.boolClass;
    } else if (cls == _helpers.jsNumberClass) {
      return _commonElements.numClass;
    } else if (cls == _helpers.jsDoubleClass) {
      return _commonElements.doubleClass;
    } else if (cls == _helpers.jsStringClass) {
      return _commonElements.stringClass;
    } else if (cls == _helpers.jsArrayClass) {
      return _commonElements.listClass;
    } else if (cls == _helpers.jsNullClass) {
      return _commonElements.nullClass;
    } else {
      return cls;
    }
  }

  /// Returns `true` if this member element needs reflection information at
  /// runtime.
  bool isMemberAccessibleByReflection(MemberElement element) {
    return membersNeededForReflection.contains(element);
  }

  /// Returns true if this element has to be enqueued due to
  /// mirror usage. Might be a subset of [referencedFromMirrorSystem] if
  /// normal tree shaking is still active ([isTreeShakingDisabled] is false).
  bool requiredByMirrorSystem(Element element) {
    return hasInsufficientMirrorsUsed && isTreeShakingDisabled ||
        matchesMirrorsMetaTarget(element) ||
        targetsUsed.contains(element);
  }

  /// Returns true if this element is covered by a mirrorsUsed annotation.
  ///
  /// Note that it might still be ok to tree shake the element away if no
  /// reflection is used in the program (and thus [isTreeShakingDisabled] is
  /// still false). Therefore _do not_ use this predicate to decide inclusion
  /// in the tree, use [requiredByMirrorSystem] instead.
  bool referencedFromMirrorSystem(Element element, [recursive = true]) {
    Element enclosing = recursive ? element.enclosingElement : null;

    return hasInsufficientMirrorsUsed ||
        matchesMirrorsMetaTarget(element) ||
        targetsUsed.contains(element) ||
        (enclosing != null && referencedFromMirrorSystem(enclosing));
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
      ResolutionDartType type = value.getType(_commonElements);
      if (metaTargetsUsed.contains(type.element)) return true;
    }
    return false;
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
    if (closedWorld.commonElements.mirrorsLibrary == null) {
      _membersNeededForReflection = const ImmutableEmptySet<Element>();
      return;
    }
    // Compute a mapping from class to the closures it contains, so we
    // can include the correct ones when including the class.
    Map<ClassElement, List<LocalFunctionElement>> closureMap =
        new Map<ClassElement, List<LocalFunctionElement>>();
    for (LocalFunctionElement closure in worldBuilder.localFunctions) {
      closureMap.putIfAbsent(closure.enclosingClass, () => []).add(closure);
    }
    bool foundClosure = false;
    Set<Element> reflectableMembers = new Set<Element>();
    for (ClassElement cls in worldBuilder.directlyInstantiatedClasses) {
      // Do not process internal classes.
      if (cls.library.isInternalLibrary || cls.isInjected) continue;
      if (referencedFromMirrorSystem(cls)) {
        Set<Name> memberNames = new Set<Name>();
        // 1) the class (should be resolved)
        assert(invariant(cls, cls.isResolved));
        reflectableMembers.add(cls);
        // 2) its constructors (if resolved)
        cls.constructors.forEach((ConstructorElement constructor) {
          if (worldBuilder.isMemberUsed(constructor)) {
            reflectableMembers.add(constructor);
          }
        });
        // 3) all members, including fields via getter/setters (if resolved)
        cls.forEachClassMember((Member member) {
          MemberElement element = member.element;
          if (worldBuilder.isMemberUsed(element)) {
            memberNames.add(member.name);
            reflectableMembers.add(element);
            element.nestedClosures
                .forEach((SynthesizedCallMethodElementX callFunction) {
              reflectableMembers.add(callFunction);
              reflectableMembers.add(callFunction.closureClass);
            });
          }
        });
        // 4) all overriding members of subclasses/subtypes (should be resolved)
        if (closedWorld.hasAnyStrictSubtype(cls)) {
          closedWorld.forEachStrictSubtypeOf(cls, (ClassElement subcls) {
            subcls.forEachClassMember((Member member) {
              if (memberNames.contains(member.name)) {
                // TODO(20993): find out why this assertion fails.
                // assert(invariant(member.element,
                //    worldBuilder.isMemberUsed(member.element)));
                if (worldBuilder.isMemberUsed(member.element)) {
                  reflectableMembers.add(member.element);
                }
              }
            });
          });
        }
        // 5) all its closures
        List<LocalFunctionElement> closures = closureMap[cls];
        if (closures != null) {
          reflectableMembers.addAll(closures);
          foundClosure = true;
        }
      } else {
        // check members themselves
        cls.constructors.forEach((ConstructorElement element) {
          if (!worldBuilder.isMemberUsed(element)) return;
          if (referencedFromMirrorSystem(element, false)) {
            reflectableMembers.add(element);
          }
        });
        cls.forEachClassMember((Member member) {
          if (!worldBuilder.isMemberUsed(member.element)) return;
          if (referencedFromMirrorSystem(member.element, false)) {
            reflectableMembers.add(member.element);
          }
        });
        // Also add in closures. Those might be reflectable is their enclosing
        // member is.
        List<LocalFunctionElement> closures = closureMap[cls];
        if (closures != null) {
          for (LocalFunctionElement closure in closures) {
            MemberElement member = closure.memberContext;
            if (referencedFromMirrorSystem(member, false)) {
              reflectableMembers.add(closure);
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
            referencedFromMirrorSystem(member)) {
          reflectableMembers.add(member);
        }
      });
    }
    // And closures inside top-level elements that do not have a surrounding
    // class. These will be in the [:null:] bucket of the [closureMap].
    if (closureMap.containsKey(null)) {
      for (Element closure in closureMap[null]) {
        if (referencedFromMirrorSystem(closure)) {
          reflectableMembers.add(closure);
          foundClosure = true;
        }
      }
    }
    // As we do not think about closures as classes, yet, we have to make sure
    // their superclasses are available for reflection manually.
    if (foundClosure) {
      ClassElement cls = _helpers.closureClass;
      reflectableMembers.add(cls);
    }
    Set<MethodElement> closurizedMembers = worldBuilder.closurizedMembers;
    if (closurizedMembers.any(reflectableMembers.contains)) {
      ClassElement cls = _helpers.boundClosureClass;
      reflectableMembers.add(cls);
    }
    // Add typedefs.
    reflectableMembers
        .addAll(closedWorld.allTypedefs.where(referencedFromMirrorSystem));
    // Register all symbols of reflectable elements
    for (Element element in reflectableMembers) {
      symbolsUsed.add(element.name);
    }
    _membersNeededForReflection = reflectableMembers;
  }

  // TODO(20791): compute closure classes after resolution and move this code to
  // [computeMembersNeededForReflection].
  void maybeMarkClosureAsNeededForReflection(
      ClosureClassElement globalizedElement,
      FunctionElement callFunction,
      FunctionElement function) {
    if (!_membersNeededForReflection.contains(function)) return;
    _membersNeededForReflection.add(callFunction);
    _membersNeededForReflection.add(globalizedElement);
  }

  /// Called when `const Symbol(name)` is seen.
  void registerConstSymbol(String name) {
    symbolsUsed.add(name);
    if (name.endsWith('=')) {
      symbolsUsed.add(name.substring(0, name.length - 1));
    }
  }
}
