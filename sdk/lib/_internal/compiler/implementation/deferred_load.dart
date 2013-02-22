// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library deferred_load;

import 'dart:uri';

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
            LibraryElement,
            MetadataAnnotation;

import 'util/util.dart'
       show Link;

import 'tree/tree.dart'
       show LibraryTag;

class DeferredLoadTask extends CompilerTask {
  final Set<LibraryElement> deferredLibraries = new Set<LibraryElement>();

  ClassElement cachedDeferredLibraryClass;

  DeferredLoadTask(Compiler compiler) : super(compiler);

  String get name => 'Lazy';

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
    // TODO(ahe): This is really a graph coloring problem. We should
    // make sure that libraries and elements only used by a deferred
    // library are also deferred.
    // Also, if something is deferred depends on your
    // perspective. Inside a deferred library, other elements of the
    // same library are not deferred. We should add an extra parameter
    // to this method to indicate "from where".
    return deferredLibraries.contains(element.getLibrary());
  }

  void registerMainApp(LibraryElement mainApp) {
    if (mainApp == null) return;
    measureElement(mainApp, () {
      deferredLibraries.addAll(findDeferredLibraries(mainApp));
    });
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
