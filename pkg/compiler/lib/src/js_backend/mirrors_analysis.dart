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

class MirrorsAnalysis {
  final JavaScriptBackend backend;
  final MirrorsHandler resolutionHandler;
  final MirrorsHandler codegenHandler;

  /// List of constants from metadata.  If metadata must be preserved,
  /// these constants must be registered.
  final List<Dependency> metadataConstants = <Dependency>[];

  /// Set of elements for which metadata has been registered as dependencies.
  final Set<Element> _registeredMetadata = new Set<Element>();

  StagedWorldImpactBuilder constantImpactsForResolution =
      new StagedWorldImpactBuilder();

  StagedWorldImpactBuilder constantImpactsForCodegen =
      new StagedWorldImpactBuilder();

  MirrorsAnalysis(this.backend, Resolution resolution)
      : resolutionHandler = new MirrorsHandler(backend, resolution),
        codegenHandler = new MirrorsHandler(backend, resolution);

  DiagnosticReporter get reporter => backend.reporter;
  Compiler get compiler => backend.compiler;
  JavaScriptConstantCompiler get constants => backend.constants;
  MirrorsData get mirrorsData => backend.mirrorsData;

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

    for (Element target in mirrorsData.targetsUsed) {
      if (target == null) continue;
      if (target.isField) {
        staticFields.add(target);
      } else if (target.isLibrary || target.isClass) {
        addFieldsInContainer(target);
      }
    }
    return staticFields;
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

    entities.forEach(processElementMetadata);
  }

  void onQueueEmpty(Enqueuer enqueuer, Iterable<ClassEntity> recentClasses) {
    if (mirrorsData.isTreeShakingDisabled) {
      enqueuer.applyImpact(_computeImpactForReflectiveElements(recentClasses,
          enqueuer.processedClasses, compiler.libraryLoader.libraries,
          forResolution: enqueuer.isResolutionQueue));
    } else if (!mirrorsData.targetsUsed.isEmpty && enqueuer.isResolutionQueue) {
      // Add all static elements (not classes) that have been requested for
      // reflection. If there is no mirror-usage these are probably not
      // necessary, but the backend relies on them being resolved.
      enqueuer.applyImpact(
          _computeImpactForReflectiveStaticFields(_findStaticFieldTargets()));
    }

    if (mirrorsData.mustPreserveNames) reporter.log('Preserving names.');

    if (mirrorsData.mustRetainMetadata) {
      reporter.log('Retaining metadata.');

      compiler.libraryLoader.libraries.forEach(mirrorsData.retainMetadataOf);

      StagedWorldImpactBuilder impactBuilder = enqueuer.isResolutionQueue
          ? constantImpactsForResolution
          : constantImpactsForCodegen;
      if (enqueuer.isResolutionQueue && !enqueuer.queueIsClosed) {
        /// Register the constant value of [metadata] as live in resolution.
        void registerMetadataConstant(MetadataAnnotation metadata) {
          ConstantValue constant =
              constants.getConstantValueForMetadata(metadata);
          Dependency dependency =
              new Dependency(constant, metadata.annotatedElement);
          metadataConstants.add(dependency);
          backend.computeImpactForCompileTimeConstant(
              dependency.constant, impactBuilder,
              forResolution: enqueuer.isResolutionQueue);
        }

        // TODO(johnniwinther): We should have access to all recently processed
        // elements and process these instead.
        processMetadata(compiler.enqueuer.resolution.processedEntities,
            registerMetadataConstant);
      } else {
        for (Dependency dependency in metadataConstants) {
          backend.computeImpactForCompileTimeConstant(
              dependency.constant, impactBuilder,
              forResolution: enqueuer.isResolutionQueue);
        }
        metadataConstants.clear();
      }
      enqueuer.applyImpact(impactBuilder.flush());
    }
  }

  void onResolutionComplete() {
    _registeredMetadata.clear();
  }

  /// Compute the impact for elements that are matched by the mirrors used
  /// annotation or, in lack thereof, all elements.
  WorldImpact _computeImpactForReflectiveElements(
      Iterable<ClassEntity> recents,
      Iterable<ClassEntity> processedClasses,
      Iterable<LibraryElement> loadedLibraries,
      {bool forResolution}) {
    MirrorsHandler handler = forResolution ? resolutionHandler : codegenHandler;
    handler.enqueueReflectiveElements(
        recents, processedClasses, loadedLibraries);
    return handler.flush();
  }

  /// Compute the impact for the static fields that have been marked as used by
  /// reflective usage through `MirrorsUsed`.
  WorldImpact _computeImpactForReflectiveStaticFields(
      Iterable<Element> elements) {
    resolutionHandler.enqueueReflectiveStaticFields(elements);
    return resolutionHandler.flush();
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
    if (_shouldIncludeElementDueToMirrors(constructor,
        includedEnclosing: enclosingWasIncluded)) {
      _logEnqueueReflectiveAction(constructor);
      ClassElement cls = constructor.declaration.enclosingClass;
      impactBuilder
          .registerTypeUse(new TypeUse.mirrorInstantiation(cls.rawType));
      impactBuilder
          .registerStaticUse(new StaticUse.foreignUse(constructor.declaration));
    }
  }

  /// Enqueue the member [element] if it is required for reflection.
  ///
  /// [enclosingWasIncluded] provides a hint whether the enclosing element was
  /// needed for reflection.
  void _enqueueReflectiveMember(Element element, bool enclosingWasIncluded) {
    if (_shouldIncludeElementDueToMirrors(element,
        includedEnclosing: enclosingWasIncluded)) {
      _logEnqueueReflectiveAction(element);
      if (element.isTypedef) {
        TypedefElement typedef = element;
        typedef.ensureResolved(_resolution);
      } else if (Elements.isStaticOrTopLevel(element)) {
        impactBuilder
            .registerStaticUse(new StaticUse.foreignUse(element.declaration));
      } else if (element.isInstanceMember) {
        // We need to enqueue all members matching this one in subclasses, as
        // well.
        // TODO(herhut): Use TypedSelector.subtype for enqueueing
        DynamicUse dynamicUse =
            new DynamicUse(new Selector.fromElement(element), null);
        impactBuilder.registerDynamicUse(dynamicUse);
        if (element.isField) {
          DynamicUse dynamicUse = new DynamicUse(
              new Selector.setter(
                  new Name(element.name, element.library, isSetter: true)),
              null);
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
      cls.constructors.forEach((Element element) {
        _enqueueReflectiveConstructor(element,
            enclosingWasIncluded: includeClass);
      });
      cls.forEachClassMember((Member member) {
        _enqueueReflectiveMember(member.element, includeClass);
      });
    }
  }

  /// Enqueue special classes that might not be visible by normal means or that
  /// would not normally be enqueued:
  ///
  /// [Closure] is treated specially as it is the superclass of all closures.
  /// Although it is in an internal library, we mark it as reflectable. Note
  /// that none of its methods are reflectable, unless reflectable by
  /// inheritance.
  void _enqueueReflectiveSpecialClasses() {
    Iterable<ClassElement> classes = _backend.classesRequiredForReflection;
    for (ClassElement cls in classes) {
      if (_backend.mirrorsData.referencedFromMirrorSystem(cls)) {
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
