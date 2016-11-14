// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.mirrors_handler;

import '../common/resolution.dart';
import '../diagnostics/diagnostic_listener.dart';
import '../elements/elements.dart';
import '../enqueue.dart';
import '../universe/selector.dart';
import '../universe/use.dart';
import 'backend.dart';

class MirrorsAnalysis {
  final MirrorsHandler resolutionHandler;
  final MirrorsHandler codegenHandler;

  MirrorsAnalysis(JavaScriptBackend backend, Resolution resolution)
      : resolutionHandler = new MirrorsHandler(backend, resolution),
        codegenHandler = new MirrorsHandler(backend, resolution);

  /// Enqueue all elements that are matched by the mirrors used
  /// annotation or, in lack thereof, all elements.
  // TODO(johnniwinther): Compute [WorldImpact] instead of enqueuing directly.
  void enqueueReflectiveElements(
      Enqueuer enqueuer,
      Iterable<ClassElement> recents,
      Iterable<LibraryElement> loadedLibraries) {
    MirrorsHandler handler =
        enqueuer.isResolutionQueue ? resolutionHandler : codegenHandler;
    handler.enqueueReflectiveElements(enqueuer, recents, loadedLibraries);
  }

  /// Enqueue the static fields that have been marked as used by reflective
  /// usage through `MirrorsUsed`.
  // TODO(johnniwinther): Compute [WorldImpact] instead of enqueuing directly.
  void enqueueReflectiveStaticFields(
      Enqueuer enqueuer, Iterable<Element> elements) {
    MirrorsHandler handler =
        enqueuer.isResolutionQueue ? resolutionHandler : codegenHandler;
    handler.enqueueReflectiveStaticFields(enqueuer, elements);
  }
}

class MirrorsHandler {
  static final TRACE_MIRROR_ENQUEUING =
      const bool.fromEnvironment("TRACE_MIRROR_ENQUEUING");

  final JavaScriptBackend _backend;
  final Resolution _resolution;

  bool hasEnqueuedReflectiveElements = false;
  bool hasEnqueuedReflectiveStaticFields = false;

  MirrorsHandler(this._backend, this._resolution);

  DiagnosticReporter get _reporter => _resolution.reporter;

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
    return includedEnclosing || _backend.requiredByMirrorSystem(element);
  }

  /// Enqeue the constructor [ctor] if it is required for reflection.
  ///
  /// [enclosingWasIncluded] provides a hint whether the enclosing element was
  /// needed for reflection.
  void _enqueueReflectiveConstructor(
      Enqueuer enqueuer, ConstructorElement constructor,
      {bool enclosingWasIncluded}) {
    if (_shouldIncludeElementDueToMirrors(constructor,
        includedEnclosing: enclosingWasIncluded)) {
      _logEnqueueReflectiveAction(constructor);
      ClassElement cls = constructor.declaration.enclosingClass;
      enqueuer.registerTypeUse(new TypeUse.mirrorInstantiation(cls.rawType));
      enqueuer
          .registerStaticUse(new StaticUse.foreignUse(constructor.declaration));
    }
  }

  /// Enqeue the member [element] if it is required for reflection.
  ///
  /// [enclosingWasIncluded] provides a hint whether the enclosing element was
  /// needed for reflection.
  void _enqueueReflectiveMember(
      Enqueuer enqueuer, Element element, bool enclosingWasIncluded) {
    if (_shouldIncludeElementDueToMirrors(element,
        includedEnclosing: enclosingWasIncluded)) {
      _logEnqueueReflectiveAction(element);
      if (element.isTypedef) {
        TypedefElement typedef = element;
        typedef.ensureResolved(_resolution);
      } else if (Elements.isStaticOrTopLevel(element)) {
        enqueuer
            .registerStaticUse(new StaticUse.foreignUse(element.declaration));
      } else if (element.isInstanceMember) {
        // We need to enqueue all members matching this one in subclasses, as
        // well.
        // TODO(herhut): Use TypedSelector.subtype for enqueueing
        DynamicUse dynamicUse =
            new DynamicUse(new Selector.fromElement(element), null);
        enqueuer.registerDynamicUse(dynamicUse);
        if (element.isField) {
          DynamicUse dynamicUse = new DynamicUse(
              new Selector.setter(
                  new Name(element.name, element.library, isSetter: true)),
              null);
          enqueuer.registerDynamicUse(dynamicUse);
        }
      }
    }
  }

  /// Enqeue the member [element] if it is required for reflection.
  ///
  /// [enclosingWasIncluded] provides a hint whether the enclosing element was
  /// needed for reflection.
  void _enqueueReflectiveElementsInClass(
      Enqueuer enqueuer, ClassElement cls, Iterable<ClassElement> recents,
      {bool enclosingWasIncluded}) {
    if (cls.library.isInternalLibrary || cls.isInjected) return;
    bool includeClass = _shouldIncludeElementDueToMirrors(cls,
        includedEnclosing: enclosingWasIncluded);
    if (includeClass) {
      _logEnqueueReflectiveAction(cls, "register");
      ClassElement declaration = cls.declaration;
      declaration.ensureResolved(_resolution);
      enqueuer.registerTypeUse(
          new TypeUse.mirrorInstantiation(declaration.rawType));
    }
    // If the class is never instantiated, we know nothing of it can possibly
    // be reflected upon.
    // TODO(herhut): Add a warning if a mirrors annotation cannot hit.
    if (recents.contains(cls.declaration)) {
      _logEnqueueReflectiveAction(cls, "members");
      cls.constructors.forEach((Element element) {
        _enqueueReflectiveConstructor(enqueuer, element,
            enclosingWasIncluded: includeClass);
      });
      cls.forEachClassMember((Member member) {
        _enqueueReflectiveMember(enqueuer, member.element, includeClass);
      });
    }
  }

  /// Enqeue special classes that might not be visible by normal means or that
  /// would not normally be enqueued:
  ///
  /// [Closure] is treated specially as it is the superclass of all closures.
  /// Although it is in an internal library, we mark it as reflectable. Note
  /// that none of its methods are reflectable, unless reflectable by
  /// inheritance.
  void _enqueueReflectiveSpecialClasses(Enqueuer enqueuer) {
    Iterable<ClassElement> classes = _backend.classesRequiredForReflection;
    for (ClassElement cls in classes) {
      if (_backend.referencedFromMirrorSystem(cls)) {
        _logEnqueueReflectiveAction(cls);
        cls.ensureResolved(_resolution);
        enqueuer.registerTypeUse(new TypeUse.mirrorInstantiation(cls.rawType));
      }
    }
  }

  /// Enqeue all local members of the library [lib] if they are required for
  /// reflection.
  void _enqueueReflectiveElementsInLibrary(
      Enqueuer enqueuer, LibraryElement lib, Iterable<ClassElement> recents) {
    bool includeLibrary =
        _shouldIncludeElementDueToMirrors(lib, includedEnclosing: false);
    lib.forEachLocalMember((Element member) {
      if (member.isInjected) return;
      if (member.isClass) {
        _enqueueReflectiveElementsInClass(enqueuer, member, recents,
            enclosingWasIncluded: includeLibrary);
      } else {
        _enqueueReflectiveMember(enqueuer, member, includeLibrary);
      }
    });
  }

  /// Enqueue all elements that are matched by the mirrors used
  /// annotation or, in lack thereof, all elements.
  // TODO(johnniwinther): Compute [WorldImpact] instead of enqueuing directly.
  void enqueueReflectiveElements(
      Enqueuer enqueuer,
      Iterable<ClassElement> recents,
      Iterable<LibraryElement> loadedLibraries) {
    if (!hasEnqueuedReflectiveElements) {
      _logEnqueueReflectiveAction("!START enqueueAll");
      // First round of enqueuing, visit everything that is visible to
      // also pick up static top levels, etc.
      // Also, during the first round, consider all classes that have been seen
      // as recently seen, as we do not know how many rounds of resolution might
      // have run before tree shaking is disabled and thus everything is
      // enqueued.
      recents = enqueuer.processedClasses.toSet();
      _reporter.log('Enqueuing everything');
      for (LibraryElement lib in loadedLibraries) {
        _enqueueReflectiveElementsInLibrary(enqueuer, lib, recents);
      }
      _enqueueReflectiveSpecialClasses(enqueuer);
      hasEnqueuedReflectiveElements = true;
      hasEnqueuedReflectiveStaticFields = true;
      _logEnqueueReflectiveAction("!DONE enqueueAll");
    } else if (recents.isNotEmpty) {
      // Keep looking at new classes until fixpoint is reached.
      _logEnqueueReflectiveAction("!START enqueueRecents");
      recents.forEach((ClassElement cls) {
        _enqueueReflectiveElementsInClass(enqueuer, cls, recents,
            enclosingWasIncluded: _shouldIncludeElementDueToMirrors(cls.library,
                includedEnclosing: false));
      });
      _logEnqueueReflectiveAction("!DONE enqueueRecents");
    }
  }

  /// Enqueue the static fields that have been marked as used by reflective
  /// usage through `MirrorsUsed`.
  // TODO(johnniwinther): Compute [WorldImpact] instead of enqueuing directly.
  void enqueueReflectiveStaticFields(
      Enqueuer enqueuer, Iterable<Element> elements) {
    if (hasEnqueuedReflectiveStaticFields) return;
    hasEnqueuedReflectiveStaticFields = true;
    for (Element element in elements) {
      _enqueueReflectiveMember(enqueuer, element, true);
    }
  }
}
