// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library deferred_load;

import 'dart:uri'
       show Uri;

import 'dart:collection'
       show LinkedHashMap,
            LinkedHashSet;

import 'dart2jslib.dart'
       show Compiler,
            CompilerTask,
            ConstructedConstant,
            MessageKind,
            SourceString,
            StringConstant;

import 'elements/elements.dart'
       show ClassElement,
            Element,
            Elements,
            FunctionElement,
            LibraryElement,
            MetadataAnnotation,
            ScopeContainerElement;

import 'util/util.dart'
       show Link;

import 'tree/tree.dart'
       show LibraryTag,
            Node,
            Visitor;

import 'resolution/resolution.dart'
       show TreeElements;

class DeferredLoadTask extends CompilerTask {
  final Set<LibraryElement> deferredLibraries =
      new LinkedHashSet<LibraryElement>();

  /// Records all elements that are deferred.
  ///
  /// Long term, we want to split deferred element into more than one
  /// file (one for each library that is deferred), and this field
  /// should become obsolete.
  final Set<Element> allDeferredElements = new LinkedHashSet<Element>();

  ClassElement cachedDeferredLibraryClass;

  DeferredLoadTask(Compiler compiler) : super(compiler);

  String get name => 'Deferred Loading';

  /// DeferredLibrary from dart:async
  ClassElement get deferredLibraryClass {
    if (cachedDeferredLibraryClass == null) {
      cachedDeferredLibraryClass = findDeferredLibraryClass();
    }
    return cachedDeferredLibraryClass;
  }

  ClassElement findDeferredLibraryClass() {
    var uri = new Uri.fromComponents(scheme: 'dart', path: 'async');
    LibraryElement asyncLibrary =
        compiler.libraryLoader.loadLibrary(uri, null, uri);
    var element = asyncLibrary.find(const SourceString('DeferredLibrary'));
    if (element == null) {
      compiler.internalErrorOnElement(
          asyncLibrary,
          'dart:async library does not contain required class: '
          'DeferredLibrary');
    }
    return element;
  }

  bool isDeferred(Element element) {
    element = element.implementation;
    return allDeferredElements.contains(element);
  }

  bool isExplicitlyDeferred(Element element) {
    element = element.implementation;
    return deferredLibraries.contains(element.getLibrary());
  }

  void onResolutionComplete(FunctionElement main) {
    if (main == null) return;
    LibraryElement mainApp = main.getLibrary();
    measureElement(mainApp, () {
      deferredLibraries.addAll(findDeferredLibraries(mainApp).toList());
      if (deferredLibraries.isEmpty) return;

      // TODO(ahe): Enforce the following invariants on
      // [deferredElements] and [eagerElements]:
      // 1. Only static or top-level elements are recorded.
      // 2. Only implementation is stored.
      Map<LibraryElement, Set<Element>> deferredElements =
          new LinkedHashMap<LibraryElement, Set<Element>>();
      Set<Element> eagerElements = new LinkedHashSet<Element>();

      // Iterate through the local members of the main script.  Create
      // a root-set of elements that must be loaded eagerly
      // (everything that is directly referred to from the main
      // script, but not imported from a deferred library), as well as
      // root-sets for deferred libraries.
      mainApp.forEachLocalMember((Element e) {
        for (Element dependency in allElementsResolvedFrom(e)) {
          if (isExplicitlyDeferred(dependency)) {
            Set<Element> deferredElementsFromLibrary =
                deferredElements.putIfAbsent(
                    dependency.getLibrary(),
                    () => new LinkedHashSet<Element>());
            deferredElementsFromLibrary.add(dependency);
          } else if (dependency.getLibrary() != mainApp) {
            eagerElements.add(dependency.implementation);
          }
        }
      });

      // Also add "global" dependencies to the eager root-set.  These
      // are things that the backend need but cannot associate with a
      // particular element, for example, startRootIsolate.  This set
      // also contains elements for which we lack precise information.
      eagerElements.addAll(compiler.globalDependencies.otherDependencies);

      addTransitiveClosureTo(eagerElements);

      for (Set<Element> e in deferredElements.values) {
        addTransitiveClosureTo(e);
        e.removeAll(eagerElements);
        for (Element element in e) {
          allDeferredElements.add(element);
        }
      }

      // TODO(ahe): The following code has no effect yet.  I'm
      // including it as a comment for how to extend this to support
      // multiple deferred files.
      Map<Element, List<LibraryElement>> reverseMap =
          new LinkedHashMap<Element, List<LibraryElement>>();

      deferredElements.forEach((LibraryElement library, Set<Element> map) {
        for (Element element in map) {
          List<LibraryElement> libraries =
              reverseMap.putIfAbsent(element, () => <LibraryElement>[]);
          libraries.add(library);
        }
      });

      // Now compute the output files based on the lists in reverseMap.
      // TODO(ahe): Do that.
    });
  }

  /// Returns all elements in the tree map of [element], but not the
  /// transitive closure.
  Set<Element> allElementsResolvedFrom(Element element) {
    element = element.implementation;
    Set<Element> result = new LinkedHashSet<Element>();
    if (element.isGenerativeConstructor()) {
      // When instantiating a class, we record a reference to the
      // constructor, not the class itself.
      element = element.getEnclosingClass().implementation;
    }
    if (element.isClass()) {
      // If we see a class, add everything its instance members refer
      // to.  Static members are not relevant.
      ClassElement cls = element.declaration;
      cls.forEachLocalMember((Element e) {
        if (!e.isInstanceMember()) return;
        result.addAll(DependencyCollector.collect(e.implementation, compiler));
      });
      if (cls.implementation != cls) {
        // TODO(ahe): Why doesn't ClassElement.forEachLocalMember do this?
        cls.implementation.forEachLocalMember((Element e) {
          if (!e.isInstanceMember()) return;
          result.addAll(DependencyCollector.collect(e.implementation,
                                                    compiler));
        });
      }
      for (var type in cls.allSupertypes) {
        result.add(type.element.implementation);
      }
      result.add(cls.implementation);
    } else if (Elements.isStaticOrTopLevel(element)) {
      result.addAll(DependencyCollector.collect(element, compiler));
    }
    // Other elements, in particular instance members, are ignored as
    // they are processed as part of the class.
    return result;
  }

  void addTransitiveClosureTo(Set<Element> elements) {
    Set<Element> workSet = new LinkedHashSet.from(elements);
    Set<Element> closure = new LinkedHashSet<Element>();
    while (!workSet.isEmpty) {
      Element current = workSet.first;
      workSet.remove(current);
      if (closure.contains(current)) continue;
      workSet.addAll(allElementsResolvedFrom(current));
      closure.add(current);
    }
    elements.addAll(closure);
  }

  Link<LibraryElement> findDeferredLibraries(LibraryElement library) {
    Link<LibraryElement> link = const Link<LibraryElement>();
    for (LibraryTag tag in library.tags) {
      Link<MetadataAnnotation> metadata = tag.metadata;
      if (metadata == null) continue;
      for (MetadataAnnotation metadata in tag.metadata) {
        metadata.ensureResolved(compiler);
        Element element = metadata.value.computeType(compiler).element;
        if (element == deferredLibraryClass) {
          ConstructedConstant value = metadata.value;
          StringConstant nameField = value.fields[0];
          SourceString expectedName = nameField.toDartString().source;
          LibraryElement deferredLibrary = library.getLibraryFromTag(tag);
          link = link.prepend(deferredLibrary);
          SourceString actualName =
              new SourceString(deferredLibrary.getLibraryOrScriptName());
          if (expectedName != actualName) {
            compiler.reportErrorCode(
                metadata,
                MessageKind.DEFERRED_LIBRARY_NAME_MISMATCH,
                { 'expectedName': expectedName.slowToString(),
                  'actualName': actualName.slowToString()});
          }
        }
      }
    }
    return link;
  }
}

class DependencyCollector extends Visitor {
  final Set<Element> dependencies = new LinkedHashSet<Element>();
  final TreeElements elements;
  final Compiler compiler;

  DependencyCollector(this.elements, this.compiler);

  visitNode(Node node) {
    node.visitChildren(this);
    Element dependency = elements[node];
    if (dependency == null) return;
    dependencies.add(dependency.implementation);
  }

  static Set<Element> collect(Element element, Compiler compiler) {
    TreeElements elements =
        compiler.enqueuer.resolution.getCachedElements(element);
    if (elements == null) return new LinkedHashSet<Element>();
    Node node = element.parseNode(compiler);
    var collector = new DependencyCollector(elements, compiler);
    node.accept(collector);
    collector.dependencies.addAll(elements.otherDependencies);
    return collector.dependencies;
  }
}
