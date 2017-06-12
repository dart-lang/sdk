// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.mirrors_handler;

import '../common.dart';
import '../common/resolution.dart';
import '../compiler.dart';
import '../constants/values.dart';
import '../diagnostics/diagnostic_listener.dart';
import '../elements/elements.dart';
import '../elements/entities.dart';
import '../enqueue.dart';
import '../universe/selector.dart';
import '../universe/use.dart';
import '../universe/world_impact.dart';
import 'backend.dart';
import 'constant_handler_javascript.dart';
import 'mirrors_data.dart';

abstract class MirrorsResolutionAnalysis {
  void onQueueEmpty(Enqueuer enqueuer, Iterable<ClassEntity> recentClasses);

  void onResolutionComplete();

  /// Close this analysis and create the [MirrorsCodegenAnalysis] for the
  /// collected data.
  MirrorsCodegenAnalysis close();
}

abstract class MirrorsCodegenAnalysis {
  void onQueueEmpty(Enqueuer enqueuer, Iterable<ClassEntity> recentClasses);

  /// Number of methods compiled before considering reflection.
  int get preMirrorsMethodCount;
}

class MirrorsResolutionAnalysisImpl implements MirrorsResolutionAnalysis {
  final JavaScriptBackend _backend;
  final MirrorsHandler handler;

  /// Set of elements for which metadata has been registered as dependencies.
  final Set<Element> _registeredMetadata = new Set<Element>();

  /// List of constants from metadata.  If metadata must be preserved,
  /// these constants must be registered.
  final List<Dependency> _metadataConstants = <Dependency>[];

  StagedWorldImpactBuilder _impactBuilder = new StagedWorldImpactBuilder();

  MirrorsResolutionAnalysisImpl(this._backend, Resolution resolution)
      : handler = new MirrorsHandler(_backend, resolution);

  DiagnosticReporter get _reporter => _backend.reporter;
  Compiler get _compiler => _backend.compiler;
  JavaScriptConstantCompiler get _constants => _backend.constants;
  MirrorsData get _mirrorsData => _backend.mirrorsData;

  /// Returns all static fields that are referenced through
  /// `mirrorsData.targetsUsed`. If the target is a library or class all nested
  /// static fields are included too.
  Iterable<Element> _findStaticFieldTargets() {
    List staticFields = [];

    void addFieldsInContainer(ScopeContainerElement container) {
      container.forEachLocalMember((Element member) {
        if (!member.isInstanceMember && member.isField) {
          staticFields.add(member);
        } else if (member.isClass) {
          addFieldsInContainer(member);
        }
      });
    }

    for (MemberElement target in _mirrorsData.membersInMirrorsUsedTargets) {
      if (target.isField) {
        staticFields.add(target);
      }
    }
    for (ClassElement target in _mirrorsData.classesInMirrorsUsedTargets) {
      addFieldsInContainer(target);
    }
    for (LibraryElement target in _mirrorsData.librariesInMirrorsUsedTargets) {
      addFieldsInContainer(target);
    }
    return staticFields;
  }

  /// Compute the impact for elements that are matched by the mirrors used
  /// annotation or, in lack thereof, all elements.
  WorldImpact _computeImpactForReflectiveElements(
      Iterable<ClassEntity> recents,
      Iterable<ClassEntity> processedClasses,
      Iterable<LibraryElement> loadedLibraries) {
    handler.enqueueReflectiveElements(
        recents, processedClasses, loadedLibraries);
    return handler.flush();
  }

  /// Compute the impact for the static fields that have been marked as used by
  /// reflective usage through `MirrorsUsed`.
  WorldImpact _computeImpactForReflectiveStaticFields(
      Iterable<Element> elements) {
    handler.enqueueReflectiveStaticFields(elements);
    return handler.flush();
  }

  void onQueueEmpty(Enqueuer enqueuer, Iterable<ClassEntity> recentClasses) {
    if (_mirrorsData.isTreeShakingDisabled) {
      enqueuer.applyImpact(_computeImpactForReflectiveElements(recentClasses,
          enqueuer.processedClasses, _compiler.libraryLoader.libraries));
    } else if (_mirrorsData.membersInMirrorsUsedTargets.isNotEmpty ||
        _mirrorsData.classesInMirrorsUsedTargets.isNotEmpty ||
        _mirrorsData.librariesInMirrorsUsedTargets.isNotEmpty) {
      // Add all static elements (not classes) that have been requested for
      // reflection. If there is no mirror-usage these are probably not
      // necessary, but the backend relies on them being resolved.
      enqueuer.applyImpact(
          _computeImpactForReflectiveStaticFields(_findStaticFieldTargets()));
    }

    if (_mirrorsData.mustPreserveNames) _reporter.log('Preserving names.');

    if (_mirrorsData.mustRetainMetadata) {
      _reporter.log('Retaining metadata.');

      for (LibraryEntity library in _compiler.libraryLoader.libraries) {
        _mirrorsData.retainMetadataOfLibrary(library,
            addForEmission: !enqueuer.isResolutionQueue);
      }

      if (!enqueuer.queueIsClosed) {
        /// Register the constant value of [metadata] as live in resolution.
        void registerMetadataConstant(MetadataAnnotation metadata) {
          ConstantValue constant =
              _constants.getConstantValueForMetadata(metadata);
          Dependency dependency =
              new Dependency(constant, metadata.annotatedElement);
          _metadataConstants.add(dependency);
          _impactBuilder.registerConstantUse(new ConstantUse.mirrors(constant));
        }

        // TODO(johnniwinther): We should have access to all recently processed
        // elements and process these instead.
        processMetadata(enqueuer.processedEntities, registerMetadataConstant);
      } else {
        for (Dependency dependency in _metadataConstants) {
          _impactBuilder.registerConstantUse(
              new ConstantUse.mirrors(dependency.constant));
        }
        _metadataConstants.clear();
      }
      enqueuer.applyImpact(_impactBuilder.flush());
    }
  }

  /// Call [registerMetadataConstant] on all metadata from [entities].
  void processMetadata(
      Iterable<Entity> entities, void onMetadata(MetadataAnnotation metadata)) {
    void processLibraryMetadata(LibraryElement library) {
      if (_registeredMetadata.add(library)) {
        library.metadata.forEach(onMetadata);
        library.entryCompilationUnit.metadata.forEach(onMetadata);
        for (ImportElement import in library.imports) {
          import.metadata.forEach(onMetadata);
        }
      }
    }

    void processElementMetadata(Element element) {
      if (_registeredMetadata.add(element)) {
        element.metadata.forEach(onMetadata);
        if (element.isFunction) {
          FunctionElement function = element;
          for (ParameterElement parameter in function.parameters) {
            parameter.metadata.forEach(onMetadata);
          }
        }
        if (element.enclosingClass != null) {
          // Only process library of top level fields/methods
          // (and not for classes).
          // TODO(johnniwinther): Fix this: We are missing some metadata on
          // libraries (example: in co19/Language/Metadata/before_export_t01).
          if (element.enclosingElement is ClassElement) {
            // Use [enclosingElement] instead of [enclosingClass] to ensure that
            // we process patch class metadata for patch and injected members.
            processElementMetadata(element.enclosingElement);
          }
        } else {
          processLibraryMetadata(element.library);
        }
      }
    }

    entities.forEach((MemberElement member) => processElementMetadata(member));
  }

  void onResolutionComplete() {
    _registeredMetadata.clear();
  }

  MirrorsCodegenAnalysis close() => new MirrorsCodegenAnalysisImpl(
      _backend, handler._resolution, _metadataConstants);
}

class MirrorsCodegenAnalysisImpl implements MirrorsCodegenAnalysis {
  final JavaScriptBackend _backend;
  final MirrorsHandler handler;

  StagedWorldImpactBuilder _impactBuilder = new StagedWorldImpactBuilder();

  /// List of constants from metadata.  If metadata must be preserved,
  /// these constants must be registered.
  final List<Dependency> _metadataConstants;

  /// Number of methods compiled before considering reflection.
  int preMirrorsMethodCount = 0;

  MirrorsCodegenAnalysisImpl(
      this._backend, Resolution resolution, this._metadataConstants)
      : handler = new MirrorsHandler(_backend, resolution);

  DiagnosticReporter get _reporter => _backend.reporter;
  Compiler get _compiler => _backend.compiler;
  JavaScriptConstantCompiler get _constants => _backend.constants;
  MirrorsData get _mirrorsData => _backend.mirrorsData;

  /// Compute the impact for elements that are matched by the mirrors used
  /// annotation or, in lack thereof, all elements.
  WorldImpact _computeImpactForReflectiveElements(
      Iterable<ClassEntity> recents,
      Iterable<ClassEntity> processedClasses,
      Iterable<LibraryElement> loadedLibraries) {
    handler.enqueueReflectiveElements(
        recents, processedClasses, loadedLibraries);
    return handler.flush();
  }

  void onQueueEmpty(Enqueuer enqueuer, Iterable<ClassEntity> recentClasses) {
    if (preMirrorsMethodCount == 0) {
      preMirrorsMethodCount = _backend.generatedCode.length;
    }
    if (_mirrorsData.isTreeShakingDisabled) {
      enqueuer.applyImpact(_computeImpactForReflectiveElements(recentClasses,
          enqueuer.processedClasses, _compiler.libraryLoader.libraries));
    }

    if (_mirrorsData.mustPreserveNames) _reporter.log('Preserving names.');

    if (_mirrorsData.mustRetainMetadata) {
      _reporter.log('Retaining metadata.');

      (_compiler.libraryLoader.libraries as Iterable<LibraryElement>)
          .forEach(_mirrorsData.retainMetadataOfLibrary);

      for (Dependency dependency in _metadataConstants) {
        _impactBuilder
            .registerConstantUse(new ConstantUse.mirrors(dependency.constant));
      }
      _metadataConstants.clear();
      enqueuer.applyImpact(_impactBuilder.flush());
    }
  }
}

class MirrorsHandler {
  static final TRACE_MIRROR_ENQUEUING =
      const bool.fromEnvironment("TRACE_MIRROR_ENQUEUING");

  final JavaScriptBackend _backend;
  final Resolution _resolution;

  bool hasEnqueuedReflectiveElements = false;
  bool hasEnqueuedReflectiveStaticFields = false;

  StagedWorldImpactBuilder impactBuilder = new StagedWorldImpactBuilder();

  MirrorsHandler(this._backend, this._resolution);

  DiagnosticReporter get _reporter => _resolution.reporter;

  WorldImpact flush() => impactBuilder.flush();

  void _logEnqueueReflectiveAction(action, [msg = ""]) {
    if (TRACE_MIRROR_ENQUEUING) {
      print("MIRROR_ENQUEUE (R): $action $msg");
    }
  }

  /**
   * Decides whether an element should be included to satisfy requirements
   * of the mirror system.
   *
   * During resolution, we have to resort to matching elements against the
   * [MirrorsUsed] pattern, as we do not have a complete picture of the world,
   * yet.
   */
  bool _shouldIncludeElementDueToMirrors(Element element,
      {bool includedEnclosing}) {
    return includedEnclosing ||
        _backend.mirrorsData.requiredByMirrorSystem(element);
  }

  /// Enqueue the constructor [ctor] if it is required for reflection.
  ///
  /// [enclosingWasIncluded] provides a hint whether the enclosing element was
  /// needed for reflection.
  void _enqueueReflectiveConstructor(ConstructorElement constructor,
      {bool enclosingWasIncluded}) {
    assert(constructor.isDeclaration);
    if (_shouldIncludeElementDueToMirrors(constructor,
        includedEnclosing: enclosingWasIncluded)) {
      if (constructor.isFromEnvironmentConstructor) return;
      _logEnqueueReflectiveAction(constructor);
      ClassElement cls = constructor.enclosingClass;
      impactBuilder
          .registerTypeUse(new TypeUse.mirrorInstantiation(cls.rawType));
      impactBuilder.registerStaticUse(new StaticUse.mirrorUse(constructor));
    }
  }

  /// Enqueue the member [element] if it is required for reflection.
  ///
  /// [enclosingWasIncluded] provides a hint whether the enclosing element was
  /// needed for reflection.
  void _enqueueReflectiveMember(
      MemberElement element, bool enclosingWasIncluded) {
    assert(element.isDeclaration);
    if (_shouldIncludeElementDueToMirrors(element,
        includedEnclosing: enclosingWasIncluded)) {
      _logEnqueueReflectiveAction(element);
      if (Elements.isStaticOrTopLevel(element)) {
        impactBuilder.registerStaticUse(new StaticUse.mirrorUse(element));
      } else if (element.isInstanceMember) {
        // We need to enqueue all members matching this one in subclasses, as
        // well.
        // TODO(herhut): Use TypedSelector.subtype for enqueueing
        DynamicUse dynamicUse =
            new DynamicUse(new Selector.fromElement(element), null);
        impactBuilder.registerDynamicUse(dynamicUse);
        if (element.isField) {
          DynamicUse dynamicUse = new DynamicUse(
              new Selector.setter(element.memberName.setter), null);
          impactBuilder.registerDynamicUse(dynamicUse);
        }
      }
    }
  }

  /// Enqueue the member [element] if it is required for reflection.
  ///
  /// [enclosingWasIncluded] provides a hint whether the enclosing element was
  /// needed for reflection.
  void _enqueueReflectiveElementsInClass(
      ClassElement cls, Iterable<ClassEntity> recents,
      {bool enclosingWasIncluded}) {
    assert(cls.isDeclaration);
    if (cls.library.isInternalLibrary || cls.isInjected) return;
    bool includeClass = _shouldIncludeElementDueToMirrors(cls,
        includedEnclosing: enclosingWasIncluded);
    if (includeClass) {
      _logEnqueueReflectiveAction(cls, "register");
      ClassElement declaration = cls.declaration;
      declaration.ensureResolved(_resolution);
      impactBuilder.registerTypeUse(
          new TypeUse.mirrorInstantiation(declaration.rawType));
    }
    // If the class is never instantiated, we know nothing of it can possibly
    // be reflected upon.
    // TODO(herhut): Add a warning if a mirrors annotation cannot hit.
    if (recents.contains(cls.declaration)) {
      _logEnqueueReflectiveAction(cls, "members");
      cls.constructors.forEach((ConstructorElement element) {
        _enqueueReflectiveConstructor(element.declaration,
            enclosingWasIncluded: includeClass);
      });
      cls.forEachClassMember((Member member) {
        _enqueueReflectiveMember(member.element, includeClass);
      });
    }
  }

  /// Set of classes that need to be considered for reflection although not
  /// otherwise visible during resolution.
  Iterable<ClassEntity> get _classesRequiredForReflection {
    // TODO(herhut): Clean this up when classes needed for rti are tracked.
    return [
      _backend.compiler.commonElements.closureClass,
      _backend.compiler.commonElements.jsIndexableClass
    ];
  }

  /// Enqueue special classes that might not be visible by normal means or that
  /// would not normally be enqueued:
  ///
  /// [Closure] is treated specially as it is the superclass of all closures.
  /// Although it is in an internal library, we mark it as reflectable. Note
  /// that none of its methods are reflectable, unless reflectable by
  /// inheritance.
  void _enqueueReflectiveSpecialClasses() {
    Iterable<ClassElement> classes = _classesRequiredForReflection;
    for (ClassElement cls in classes) {
      if (_backend.mirrorsData.isClassReferencedFromMirrorSystem(cls)) {
        _logEnqueueReflectiveAction(cls);
        cls.ensureResolved(_resolution);
        impactBuilder
            .registerTypeUse(new TypeUse.mirrorInstantiation(cls.rawType));
      }
    }
  }

  /// Enqueue all local members of the library [lib] if they are required for
  /// reflection.
  void _enqueueReflectiveElementsInLibrary(
      LibraryElement lib, Iterable<ClassEntity> recents) {
    assert(lib.isDeclaration);
    bool includeLibrary =
        _shouldIncludeElementDueToMirrors(lib, includedEnclosing: false);
    lib.forEachLocalMember((Element member) {
      if (member.isInjected) return;
      if (member.isClass) {
        ClassElement cls = member;
        cls.ensureResolved(_resolution);
        do {
          _enqueueReflectiveElementsInClass(cls, recents,
              enclosingWasIncluded: includeLibrary);
          cls = cls.superclass;
        } while (cls != null && cls.isUnnamedMixinApplication);
      } else if (member.isTypedef) {
        TypedefElement typedef = member;
        typedef.ensureResolved(_resolution);
      } else {
        _enqueueReflectiveMember(member, includeLibrary);
      }
    });
  }

  /// Enqueue all elements that are matched by the mirrors used
  /// annotation or, in lack thereof, all elements.
  // TODO(johnniwinther): Compute [WorldImpact] instead of enqueuing directly.
  void enqueueReflectiveElements(
      Iterable<ClassEntity> recents,
      Iterable<ClassEntity> processedClasses,
      Iterable<LibraryElement> loadedLibraries) {
    if (!hasEnqueuedReflectiveElements) {
      _logEnqueueReflectiveAction("!START enqueueAll");
      // First round of enqueuing, visit everything that is visible to
      // also pick up static top levels, etc.
      // Also, during the first round, consider all classes that have been seen
      // as recently seen, as we do not know how many rounds of resolution might
      // have run before tree shaking is disabled and thus everything is
      // enqueued.
      recents = processedClasses.toSet();
      _reporter.log('Enqueuing everything');
      for (LibraryElement lib in loadedLibraries) {
        _enqueueReflectiveElementsInLibrary(lib, recents);
      }
      _enqueueReflectiveSpecialClasses();
      hasEnqueuedReflectiveElements = true;
      hasEnqueuedReflectiveStaticFields = true;
      _logEnqueueReflectiveAction("!DONE enqueueAll");
    } else if (recents.isNotEmpty) {
      // Keep looking at new classes until fixpoint is reached.
      _logEnqueueReflectiveAction("!START enqueueRecents");
      recents.forEach((ClassElement cls) {
        _enqueueReflectiveElementsInClass(cls, recents,
            enclosingWasIncluded: _shouldIncludeElementDueToMirrors(cls.library,
                includedEnclosing: false));
      });
      _logEnqueueReflectiveAction("!DONE enqueueRecents");
    }
  }

  /// Enqueue the static fields that have been marked as used by reflective
  /// usage through `MirrorsUsed`.
  // TODO(johnniwinther): Compute [WorldImpact] instead of enqueuing directly.
  void enqueueReflectiveStaticFields(Iterable<Element> elements) {
    if (hasEnqueuedReflectiveStaticFields) return;
    hasEnqueuedReflectiveStaticFields = true;
    for (Element element in elements) {
      _enqueueReflectiveMember(element, true);
    }
  }
}

/// Records that [constant] is used by the element behind [registry].
class Dependency {
  final ConstantValue constant;
  final Element annotatedElement;

  const Dependency(this.constant, this.annotatedElement);

  String toString() => '$annotatedElement:${constant.toStructuredText()}';
}
