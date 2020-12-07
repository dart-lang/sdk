// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.incremental_serializer;

import 'dart:typed_data' show Uint8List;

import 'package:kernel/binary/ast_from_binary.dart' show SubComponentView;

import 'package:kernel/binary/ast_to_binary.dart' show BinaryPrinter;

import 'package:kernel/kernel.dart' show Component, Library, LibraryDependency;

import 'kernel/utils.dart' show ByteSink;

class IncrementalSerializer {
  final Map<Uri, SerializationGroup> uriToGroup =
      new Map<Uri, SerializationGroup>();
  final Set<Uri> invalidatedUris = new Set<Uri>();

  /// Invalidate the uri: Will remove cache associated with it, depending on it
  /// etc. Called by the incremental compiler.
  void invalidate(Uri uri) {
    invalidatedUris.add(uri);
  }

  /// Initializes the cache via a already serialized list of bytes based on the
  /// view of those bytes. Called by the incremental compiler.
  bool initialize(List<int> bytes, List<SubComponentView> views) {
    if (uriToGroup.isNotEmpty) {
      throw "Cannot initialize when already in use.";
    }

    // Find the sub-components that are packaged correctly.
    List<SubComponentView> goodViews = [];
    Set<Uri> uris = new Set<Uri>();
    for (int i = 0; i < views.length; i++) {
      SubComponentView view = views[i];
      bool good = true;
      String packageName;
      for (Library lib in view.libraries) {
        Uri uri = lib.importUri;
        // Uris need to be unique.
        if (!uris.add(lib.fileUri)) return false;
        if (uri.scheme == "package") {
          String thisPackageName = uri.pathSegments.first;
          if (packageName == null) {
            packageName = thisPackageName;
          } else if (packageName != thisPackageName) {
            good = false;
          }
        } else {
          good = false;
        }
      }
      if (good) {
        goodViews.add(view);
      }
    }

    // Add groups. Wrap in try because an exception will be thrown if a group
    // has a dependency that isn't being met.
    try {
      List<SerializationGroup> newGroups = <SerializationGroup>[];
      for (int i = 0; i < goodViews.length; i++) {
        SubComponentView view = goodViews[i];
        List<int> data = new Uint8List(view.componentFileSize);
        data.setRange(0, data.length, bytes, view.componentStartOffset);
        SerializationGroup newGroup = createGroupFor(view.libraries, data);
        newGroups.add(newGroup);
      }

      // Setup dependency tracking for the new groups.
      for (int i = 0; i < goodViews.length; i++) {
        SubComponentView view = goodViews[i];
        List<Library> libraries = view.libraries;
        SerializationGroup packageGroup = newGroups[i];
        setupDependencyTracking(libraries, packageGroup);
      }
    } catch (e) {
      uriToGroup.clear();
      return false;
    }
    return true;
  }

  /// Write packages to sink, cache new package data, trim input component.
  void writePackagesToSinkAndTrimComponent(
      Component component, Sink<List<int>> sink) {
    if (component == null) return;
    if (component.libraries.isEmpty) return;

    // If we're given a partial component (i.e. an actual delta component)
    // incremental serialization (at least currently) doesn't work.
    // The reason is that it might contain a new partial thing of what we
    // already have cached while still depending on something from the same
    // group that is currently cached. We would throw away the cache, but
    // actually depend on something we just threw away --- we would try to
    // include it and crash because we no longer have it.
    // Alternative ways to fix this could be:
    // * to group into smaller groups so this wouldn't happen.
    // * cache the actual Libraries too, so we could re-serialize when needed
    //   (though maybe not eagerly).
    if (!isSelfContained(component)) return;

    // Remove cache pertaining to invalidated uris.
    if (invalidatedUris.isNotEmpty) {
      removeInvalidated();
    }

    // Make sure we can serialize individual libraries.
    component.computeCanonicalNames();

    // Split into package and non-package libraries.
    List<Library> packageLibraries = <Library>[];
    List<Library> nonPackageLibraries = <Library>[];
    for (Library lib in component.libraries) {
      Uri uri = lib.importUri;
      if (uri.scheme == "package") {
        packageLibraries.add(lib);
      } else {
        nonPackageLibraries.add(lib);
      }
    }

    // Output already serialized packages and group needed non-serialized
    // packages.
    Map<String, List<Library>> newPackages = new Map<String, List<Library>>();
    Set<SerializationGroup> cachedPackagesInOutput =
        new Set<SerializationGroup>.identity();
    for (Library lib in packageLibraries) {
      SerializationGroup group = uriToGroup[lib.fileUri];
      if (group != null) {
        addDataButNotDependentData(group, cachedPackagesInOutput, sink);
      } else {
        String package = lib.importUri.pathSegments.first;
        newPackages[package] ??= <Library>[];
        newPackages[package].add(lib);
      }
    }

    // Add any dependencies that wasn't added already.
    List<SerializationGroup> upFrontGroups = cachedPackagesInOutput.toList();
    for (SerializationGroup group in upFrontGroups) {
      if (group.dependencies != null) {
        // Now also add all dependencies.
        for (SerializationGroup dep in group.dependencies) {
          addDataAndDependentData(dep, cachedPackagesInOutput, sink);
        }
      }
    }

    // Serialize all new packages, create groups and add to sink.
    Map<String, SerializationGroup> newPackageGroups =
        new Map<String, SerializationGroup>();
    for (String package in newPackages.keys) {
      List<Library> libraries = newPackages[package];
      List<int> data = serialize(component, libraries);
      sink.add(data);
      SerializationGroup newGroup = createGroupFor(libraries, data);
      newPackageGroups[package] = newGroup;
    }

    // Setup dependency tracking for the new groups.
    for (String package in newPackages.keys) {
      List<Library> libraries = newPackages[package];
      SerializationGroup packageGroup = newPackageGroups[package];
      setupDependencyTracking(libraries, packageGroup);
    }

    // All packages have been added to the sink already.
    component.libraries
      ..clear()
      ..addAll(nonPackageLibraries);
  }

  bool isSelfContained(Component component) {
    Set<Library> got = new Set<Library>.from(component.libraries);
    for (Library lib in component.libraries) {
      for (LibraryDependency dependency in lib.dependencies) {
        if (!got.contains(dependency.targetLibrary)) {
          if (dependency.targetLibrary.importUri.scheme == "dart") {
            continue;
          }
          return false;
        }
      }
    }
    return true;
  }

  /// Remove cached data based on what has been invalidated.
  /// Note that invalidating a single file can remove many cached things because
  /// of dependencies.
  void removeInvalidated() {
    // Remove all directly invalidated entries.
    Set<SerializationGroup> removed = new Set<SerializationGroup>();
    List<SerializationGroup> workList = <SerializationGroup>[];
    for (Uri uri in invalidatedUris) {
      removeUriFromMap(uri, removed, workList);
    }

    // Continuously remove all that depend on the removed groups.
    //
    // Note that with the current invalidating strategy in the incremental
    // compiler this is not strictly necessary (assuming the incremental
    // compiler is used via the incremental compiler) - but it is included for
    // completeness.
    //
    // The reason we have to do this (assuming a different incremental
    // compiler invalidation strategy), is that we group things into packages,
    // meaning that a group as a whole might depend on another group containing
    // libraries that is not in the input component. Not removing these groups
    // could lead to including a group in an output where we cannot re-create
    // the dependencies. Example:
    // Group #1: [lib1]
    // Group #2: [lib2, lib3]. Note that lib3 depends on lib1, but lib2 is
    //                         standalone.
    // Lib1 is invalidated and we thus remove group #1.
    // We then serialize something that needs lib2. We thus output group #2.
    // We should now also output group #1, but we don't have it so we can't.
    // We can't re-create it either, because the input component only contains
    // lib2 as it is standalone. Had we removed group #2 too everything would
    // have been fine as we would then just serialize and cached lib2 by itself.
    while (workList.isNotEmpty) {
      SerializationGroup group = workList.removeLast();
      if (group.othersDependingOnMe == null) continue;
      for (SerializationGroup dependsOnGroup in group.othersDependingOnMe) {
        removeUriFromMap(dependsOnGroup.uris.first, removed, workList);
      }
    }

    invalidatedUris.clear();
  }

  /// Setup dependency tracking for a single group having the specified
  /// libraries. Note that all groups this depend on has to be created prior
  /// to calling this.
  void setupDependencyTracking(
      List<Library> libraries, SerializationGroup packageGroup) {
    for (Library lib in libraries) {
      for (LibraryDependency dep in lib.dependencies) {
        Library dependencyLibrary = dep.importedLibraryReference.asLibrary;
        if (dependencyLibrary.importUri.scheme != "package") continue;
        Uri dependencyLibraryUri =
            dep.importedLibraryReference.asLibrary.fileUri;
        SerializationGroup depGroup = uriToGroup[dependencyLibraryUri];
        if (depGroup == null) {
          throw "Didn't contain group for $dependencyLibraryUri";
        }
        if (depGroup == packageGroup) continue;
        packageGroup.registerDependency(depGroup);
      }
    }
  }

  /// Add the group but not its dependencies to the output if they weren't added
  /// already.
  addDataButNotDependentData(SerializationGroup group,
      Set<SerializationGroup> cachedPackagesInOutput, Sink<List<int>> sink) {
    if (cachedPackagesInOutput.add(group)) {
      sink.add(group.serializedData);
    }
  }

  /// Add the group and its dependencies to the output if they weren't added
  /// already.
  addDataAndDependentData(SerializationGroup group,
      Set<SerializationGroup> cachedPackagesInOutput, Sink<List<int>> sink) {
    if (cachedPackagesInOutput.add(group)) {
      sink.add(group.serializedData);
      if (group.dependencies != null) {
        // Now also add all dependencies.
        for (SerializationGroup dep in group.dependencies) {
          addDataAndDependentData(dep, cachedPackagesInOutput, sink);
        }
      }
    }
  }

  /// Create a [SerializationGroup] for the input, setting up [uriToGroup].
  SerializationGroup createGroupFor(List<Library> libraries, List<int> data) {
    Set<Uri> libraryUris = new Set<Uri>();
    for (Library lib in libraries) {
      libraryUris.add(lib.fileUri);
    }

    SerializationGroup newGroup = new SerializationGroup(data, libraryUris);

    for (Uri uri in libraryUris) {
      assert(!uriToGroup.containsKey(uri));
      uriToGroup[uri] = newGroup;
    }
    return newGroup;
  }

  /// Serialize the specified libraries using other needed data from the
  /// component.
  List<int> serialize(Component component, List<Library> libraries) {
    Component singlePackageLibraries = new Component(
        libraries: libraries,
        uriToSource: component.uriToSource,
        nameRoot: component.root);
    singlePackageLibraries.setMainMethodAndMode(null, false, component.mode);

    ByteSink byteSink = new ByteSink();
    final BinaryPrinter printer = new BinaryPrinter(byteSink);
    printer.writeComponentFile(singlePackageLibraries);
    return byteSink.builder.takeBytes();
  }

  /// Remove the specified uri from the [uriToGroup] map.
  ///
  /// Also remove all uris in the group the uri belongs to, and add the group to
  /// the worklist.
  void removeUriFromMap(Uri uri, Set<SerializationGroup> removed,
      List<SerializationGroup> workList) {
    SerializationGroup group = uriToGroup.remove(uri);
    if (group == null) return;
    bool added = removed.add(group);
    assert(added);
    workList.add(group);
    for (Uri groupUri in group.uris) {
      SerializationGroup sameGroup = uriToGroup.remove(groupUri);
      assert((groupUri == uri && sameGroup == null) ||
          (groupUri != uri && sameGroup != null));
    }
  }
}

class SerializationGroup {
  final List<int> serializedData;
  final Set<Uri> uris;
  Set<SerializationGroup> dependencies;
  Set<SerializationGroup> othersDependingOnMe;

  SerializationGroup(this.serializedData, this.uris);

  /// Register the dependency that this group depends on the [other] one.
  /// The registration is bilateral so that [other] is added as a dependency for
  /// this, and this is added as a "others depend on me" for [other].
  void registerDependency(SerializationGroup other) {
    dependencies ??= new Set<SerializationGroup>.identity();
    if (dependencies.add(other)) {
      other.othersDependingOnMe ??= new Set<SerializationGroup>.identity();
      other.othersDependingOnMe.add(this);
    }
  }
}
