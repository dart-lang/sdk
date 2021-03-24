// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection';
import '../../common_elements.dart' show ElementEnvironment;
import '../../deferred_load.dart'
    show ImportDescription, OutputUnit, OutputUnitData, deferredPartFileName;
import '../../elements/entities.dart';
import '../../deferred_load.dart' show OutputUnit;
import '../../js/js.dart' as js;
import '../../js/size_estimator.dart';
import '../../options.dart';
import '../model.dart';

class PreFragment {
  final List<DeferredFragment> fragments = [];
  final List<js.Statement> classPrototypes = [];
  final List<js.Statement> closurePrototypes = [];
  final List<js.Statement> inheritance = [];
  final List<js.Statement> methodAliases = [];
  final List<js.Statement> tearOffs = [];
  final List<js.Statement> constants = [];
  final List<js.Statement> typeRules = [];
  final List<js.Statement> variances = [];
  final List<js.Statement> staticNonFinalFields = [];
  final List<js.Statement> lazyInitializers = [];
  final List<js.Statement> nativeSupport = [];
  final Set<PreFragment> successors = {};
  final Set<PreFragment> predecessors = {};
  FinalizedFragment finalizedFragment;
  int size = 0;

  PreFragment(
      Fragment fragment,
      js.Statement classPrototypes,
      js.Statement closurePrototypes,
      js.Statement inheritance,
      js.Statement methodAliases,
      js.Statement tearOffs,
      js.Statement constants,
      js.Statement typeRules,
      js.Statement variances,
      js.Statement staticNonFinalFields,
      js.Statement lazyInitializers,
      js.Statement nativeSupport,
      bool estimateSize) {
    this.fragments.add(fragment);
    this.classPrototypes.add(classPrototypes);
    this.closurePrototypes.add(closurePrototypes);
    this.inheritance.add(inheritance);
    this.methodAliases.add(methodAliases);
    this.tearOffs.add(tearOffs);
    this.constants.add(constants);
    this.typeRules.add(typeRules);
    this.variances.add(variances);
    this.staticNonFinalFields.add(staticNonFinalFields);
    this.lazyInitializers.add(lazyInitializers);
    this.nativeSupport.add(nativeSupport);
    if (estimateSize) {
      var estimator = SizeEstimator();
      estimator.visit(classPrototypes);
      estimator.visit(closurePrototypes);
      estimator.visit(inheritance);
      estimator.visit(methodAliases);
      estimator.visit(tearOffs);
      estimator.visit(constants);
      estimator.visit(typeRules);
      estimator.visit(variances);
      estimator.visit(staticNonFinalFields);
      estimator.visit(lazyInitializers);
      estimator.visit(nativeSupport);
      size = estimator.charCount;
    }
  }

  PreFragment mergeAfter(PreFragment that) {
    assert(this != that);
    this.fragments.addAll(that.fragments);
    this.classPrototypes.addAll(that.classPrototypes);
    this.closurePrototypes.addAll(that.closurePrototypes);
    this.inheritance.addAll(that.inheritance);
    this.methodAliases.addAll(that.methodAliases);
    this.tearOffs.addAll(that.tearOffs);
    this.constants.addAll(that.constants);
    this.typeRules.addAll(that.typeRules);
    this.variances.addAll(that.variances);
    this.staticNonFinalFields.addAll(that.staticNonFinalFields);
    this.lazyInitializers.addAll(that.lazyInitializers);
    this.nativeSupport.addAll(that.nativeSupport);
    this.successors.remove(that);
    this.predecessors.remove(that);
    that.successors.forEach((fragment) {
      if (fragment == this) return;
      this.successors.add(fragment);
      fragment.predecessors.remove(that);
      fragment.predecessors.add(this);
    });
    that.predecessors.forEach((fragment) {
      if (fragment == this) return;
      this.predecessors.add(fragment);
      fragment.successors.remove(that);
      fragment.successors.add(this);
    });
    that.clearAll();
    this.size += that.size;
    return this;
  }

  FinalizedFragment finalize(
      Program program, Map<OutputUnit, FinalizedFragment> outputUnitMap) {
    assert(finalizedFragment == null);
    var seedFragment = fragments.first;
    var seedOutputUnit = seedFragment.outputUnit;

    // If we only have a single fragment, then wen just finalize it by itself.
    // Otherwise, we finalize an entire group of fragments into a single
    // merged and finalized fragment.
    if (fragments.length == 1) {
      finalizedFragment = FinalizedFragment(
          seedFragment.outputFileName,
          [seedOutputUnit],
          seedFragment.libraries,
          classPrototypes.first,
          closurePrototypes.first,
          inheritance.first,
          methodAliases.first,
          tearOffs.first,
          constants.first,
          typeRules.first,
          variances.first,
          staticNonFinalFields.first,
          lazyInitializers.first,
          nativeSupport.first,
          program.metadataTypesForOutputUnit(seedOutputUnit));
      outputUnitMap[seedOutputUnit] = finalizedFragment;
    } else {
      List<OutputUnit> outputUnits = [seedOutputUnit];
      List<Library> libraries = [];
      for (var fragment in fragments) {
        var fragmentOutputUnit = fragment.outputUnit;
        if (seedOutputUnit != fragmentOutputUnit) {
          program.mergeOutputUnitMetadata(seedOutputUnit, fragmentOutputUnit);
          outputUnits.add(fragmentOutputUnit);
        }
        libraries.addAll(fragment.libraries);
      }
      finalizedFragment = FinalizedFragment(
          seedFragment.outputFileName,
          outputUnits,
          libraries,
          js.Block(classPrototypes),
          js.Block(closurePrototypes),
          js.Block(inheritance),
          js.Block(methodAliases),
          js.Block(tearOffs),
          js.Block(constants),
          js.Block(typeRules),
          js.Block(variances),
          js.Block(staticNonFinalFields),
          js.Block(lazyInitializers),
          js.Block(nativeSupport),
          program.metadataTypesForOutputUnit(seedOutputUnit));
      for (var outputUnit in outputUnits) {
        outputUnitMap[outputUnit] = finalizedFragment;
      }
    }
    return finalizedFragment;
  }

  @override
  String toString() {
    // This is not an efficient operation and should only be used for debugging.
    var successors =
        this.successors.map((fragment) => fragment.debugName()).join(',');
    var predecessors =
        this.predecessors.map((fragment) => fragment.debugName()).join(',');
    var name = debugName();
    return 'PreFragment(fragments=[$name], successors=[$successors], '
        'predecessors=[$predecessors])';
  }

  String debugName() {
    List<String> names = [];
    this.fragments.forEach(
        (fragment) => names.add(fragment.outputUnit.imports.toString()));
    var outputUnitStrings = [];
    for (var fragment in fragments) {
      var importString = [];
      for (var import in fragment.outputUnit.imports) {
        importString.add(import.name);
      }
      outputUnitStrings.add('{${importString.join(', ')}}');
    }
    return "${outputUnitStrings.join('+')}";
  }

  /// Clears all [PreFragment] data structure and zeros out the size. Should be
  /// used only after merging to GC internal data structures.
  void clearAll() {
    fragments.clear();
    classPrototypes.clear();
    closurePrototypes.clear();
    inheritance.clear();
    methodAliases.clear();
    tearOffs.clear();
    constants.clear();
    typeRules.clear();
    variances.clear();
    staticNonFinalFields.clear();
    lazyInitializers.clear();
    nativeSupport.clear();
    successors.clear();
    predecessors.clear();
    size = 0;
  }
}

class FinalizedFragment {
  final String outputFileName;
  final List<OutputUnit> outputUnits;
  final List<Library> libraries;
  final js.Statement classPrototypes;
  final js.Statement closurePrototypes;
  final js.Statement inheritance;
  final js.Statement methodAliases;
  final js.Statement tearOffs;
  final js.Statement constants;
  final js.Statement typeRules;
  final js.Statement variances;
  final js.Statement staticNonFinalFields;
  final js.Statement lazyInitializers;
  final js.Statement nativeSupport;
  final js.Expression deferredTypes;

  FinalizedFragment(
      this.outputFileName,
      this.outputUnits,
      this.libraries,
      this.classPrototypes,
      this.closurePrototypes,
      this.inheritance,
      this.methodAliases,
      this.tearOffs,
      this.constants,
      this.typeRules,
      this.variances,
      this.staticNonFinalFields,
      this.lazyInitializers,
      this.nativeSupport,
      this.deferredTypes);

  bool isEmptyStatement(js.Statement statement) {
    if (statement is js.Block) {
      return statement.statements.isEmpty;
    }
    return statement is js.EmptyStatement;
  }

  bool get isEmpty {
    // TODO(sra): How do we tell if [deferredTypes] is empty? It is filled-in
    // later via the program finalizers. So we should defer the decision on the
    // emptiness of the fragment until the finalizers have run.  For now we seem
    // to get away with the fact that type indexes are either (1) main unit or
    // (2) local to the emitted unit, so there is no such thing as a type in a
    // deferred unit that is referenced from another deferred unit.  If we did
    // not emit any functions, then we probably did not use the signature types
    // in the OutputUnit's types, leaving them unused and tree-shaken.
    // TODO(joshualitt): Currently, we ignore [typeRules] when determining
    // emptiness because the type rules never seem to be empty.
    return isEmptyStatement(classPrototypes) &&
        isEmptyStatement(closurePrototypes) &&
        isEmptyStatement(inheritance) &&
        isEmptyStatement(methodAliases) &&
        isEmptyStatement(tearOffs) &&
        isEmptyStatement(constants) &&
        isEmptyStatement(staticNonFinalFields) &&
        isEmptyStatement(lazyInitializers) &&
        isEmptyStatement(nativeSupport);
  }

  // The 'main' [OutputUnit] for this [FinalizedFragment].
  // TODO(joshualitt): Refactor this to more clearly disambiguate between
  // [OutputUnits](units of deferred merging), fragments(units of emitted code),
  // and files.
  OutputUnit get canonicalOutputUnit => outputUnits.first;
}

class _Partition {
  int size = 0;
  List<PreFragment> fragments = [];
  bool isClosed = false;

  void add(PreFragment that) {
    size += that.size;
    fragments.add(that);
  }
}

class FragmentMerger {
  final CompilerOptions _options;
  final ElementEnvironment _elementEnvironment;
  final OutputUnitData outputUnitData;
  int totalSize = 0;

  FragmentMerger(this._options, this._elementEnvironment, this.outputUnitData);

  // Converts a map of (loadId, List<OutputUnit>) to a map of
  // (loadId, List<FinalizedFragment>).
  Map<String, List<FinalizedFragment>> computeFragmentsToLoad(
      Map<String, List<OutputUnit>> outputUnitsToLoad,
      Map<OutputUnit, FinalizedFragment> outputUnitMap,
      Set<OutputUnit> omittedOutputUnits) {
    Map<String, List<FinalizedFragment>> fragmentsToLoad = {};
    outputUnitsToLoad.forEach((loadId, outputUnits) {
      Set<FinalizedFragment> unique = {};
      List<FinalizedFragment> finalizedFragments = [];
      fragmentsToLoad[loadId] = finalizedFragments;
      for (var outputUnit in outputUnits) {
        if (omittedOutputUnits.contains(outputUnit)) continue;
        var finalizedFragment = outputUnitMap[outputUnit];
        if (unique.add(finalizedFragment)) {
          finalizedFragments.add(finalizedFragment);
        }
      }
    });
    return fragmentsToLoad;
  }

  /// Given a list of OutputUnits sorted by their import entites,
  /// returns a map of all the direct edges between output units.
  Map<OutputUnit, Set<OutputUnit>> createDirectEdges(
      List<OutputUnit> allOutputUnits) {
    Map<OutputUnit, Set<OutputUnit>> backEdges = {};
    for (int i = 0; i < allOutputUnits.length; i++) {
      var a = allOutputUnits[i];
      var aImports = a.imports;
      for (int j = i + 1; j < allOutputUnits.length; j++) {
        var b = allOutputUnits[j];
        if (b.imports.containsAll(aImports)) {
          backEdges[b] ??= {};

          // Remove transitive edges from nodes that will reach 'b' from the
          // edge we just added.
          // Note: Because we add edges in order (starting from the smallest
          // sets) we always add transitive edges before the last direct edge.
          backEdges[b].removeWhere((c) => aImports.containsAll(c.imports));

          // Create an edge to denote that 'b' must be loaded before 'a'.
          backEdges[b].add(a);
        }
      }
    }

    Map<OutputUnit, Set<OutputUnit>> forwardEdges = {};
    backEdges.forEach((b, edges) {
      for (var a in edges) {
        (forwardEdges[a] ??= {}).add(b);
      }
    });
    return forwardEdges;
  }

  /// Attachs predecessors and successors to each PreFragment.
  /// Expects outputUnits to be sorted.
  void attachDependencies(
      List<OutputUnit> outputUnits,
      Map<Fragment, PreFragment> fragmentMap,
      List<PreFragment> preDeferredFragments) {
    // Create a map of OutputUnit to Fragment.
    Map<OutputUnit, Fragment> outputUnitMap = {};
    for (var preFragment in preDeferredFragments) {
      var fragment = preFragment.fragments.single;
      var outputUnit = fragment.outputUnit;
      outputUnitMap[outputUnit] = fragment;
      totalSize += preFragment.size;
    }

    // Get a list of direct edges and then attach them to PreFragments.
    var allEdges = createDirectEdges(outputUnits);
    allEdges.forEach((outputUnit, edges) {
      var predecessor = fragmentMap[outputUnitMap[outputUnit]];
      for (var edge in edges) {
        var successor = fragmentMap[outputUnitMap[edge]];
        predecessor.successors.add(successor);
        successor.predecessors.add(predecessor);
      }
    });
  }

  /// Given a list of [PreFragments], returns a list of lists of [PreFragments]
  /// where each list represents a component in the graph.
  List<List<PreFragment>> separateComponents(
      List<PreFragment> preDeferredFragments) {
    List<List<PreFragment>> components = [];
    Set<PreFragment> visited = {};

    // Starting from each 'root' in the graph, use bfs to find a component.
    for (var preFragment in preDeferredFragments) {
      if (preFragment.predecessors.isEmpty && visited.add(preFragment)) {
        List<PreFragment> component = [];
        var queue = Queue<PreFragment>();
        queue.add(preFragment);
        while (queue.isNotEmpty) {
          var preFragment = queue.removeFirst();
          component.add(preFragment);
          preFragment.predecessors.where(visited.add).forEach(queue.add);
          preFragment.successors.where(visited.add).forEach(queue.add);
        }

        // Sort the fragments in the component so they will be in a canonical
        // order.
        component.sort((a, b) {
          return a.fragments.single.outputUnit
              .compareTo(b.fragments.single.outputUnit);
        });
        components.add(component);
      }
    }
    return components;
  }

  /// A trivial greedy merge that uses the sorted order of the output units to
  /// merge contiguous runs of fragments without creating cycles.
  /// ie, if our sorted output units look like:
  ///   {a}, {b}, {c}, {a, b}, {b, c}, {a, b, c},
  /// Assuming singletons have size 3, doubles have size 2, and triples have
  /// size 1, total size would be 14. If we want 3 fragments, we have an ideal
  /// fragment size of 5. Our final partitions would look like:
  ///   {a}, {b}, {c}+{a, b}, {b, c}+{a, b, c}.
  List<PreFragment> mergeFragments(List<PreFragment> preDeferredFragments) {
    var components = separateComponents(preDeferredFragments);
    int desiredNumberOfFragment = _options.mergeFragmentsThreshold;
    int idealFragmentSize = (totalSize / desiredNumberOfFragment).ceil();
    List<_Partition> partitions = [];
    void add(PreFragment next) {
      // Create a new partition if the current one grows too large, otherwise
      // just add to the most recent partition.
      if (partitions.isEmpty ||
          partitions.last.isClosed ||
          partitions.last.size + next.size > idealFragmentSize) {
        partitions.add(_Partition());
      }
      partitions.last.add(next);
    }

    // Greedily group fragments into partitions, but only within each component.
    for (var component in components) {
      component.forEach(add);
      partitions.last.isClosed = true;
    }

    // Reduce fragments by merging fragments with fewer imports into fragments
    // with more imports.
    List<PreFragment> merged = [];
    for (var partition in partitions) {
      merged.add(partition.fragments.reduce((a, b) => b.mergeAfter(a)));
    }
    return merged;
  }

  /// Computes load lists using a list of sorted OutputUnits.
  Map<String, List<OutputUnit>> computeOutputUnitsToLoad(
      List<OutputUnit> outputUnits) {
    // Sort the output units in descending order of the number of imports they
    // include.

    // The loading of the output units must be ordered because a superclass
    // needs to be initialized before its subclass.
    // But a class can only depend on another class in an output unit shared by
    // a strict superset of the imports:
    // By contradiction: Assume a class C in output unit shared by imports in
    // the set S1 = (lib1,.., lib_n) depends on a class D in an output unit
    // shared by S2 such that S2 not a superset of S1. Let lib_s be a library in
    // S1 not in S2. lib_s must depend on C, and then in turn on D. Therefore D
    // is not in the right output unit.
    List<OutputUnit> sortedOutputUnits = outputUnits.reversed.toList();

    Map<String, List<OutputUnit>> outputUnitsToLoad = {};
    for (var import in outputUnitData.deferredImportDescriptions.keys) {
      var loadId = outputUnitData.importDeferName[import];
      List<OutputUnit> loadList = [];
      for (var outputUnit in sortedOutputUnits) {
        assert(!outputUnit.isMainOutput);
        if (outputUnit.imports.contains(import)) {
          loadList.add(outputUnit);
        }
      }
      outputUnitsToLoad[loadId] = loadList;
    }
    return outputUnitsToLoad;
  }

  /// Returns a json-style map for describing what files that are loaded by a
  /// given deferred import.
  /// The mapping is structured as:
  /// library uri -> {"name": library name, "files": (prefix -> list of files)}
  /// Where
  ///
  /// - <library uri> is the import uri of the library making a deferred
  ///   import.
  /// - <library name> is the name of the library, or "<unnamed>" if it is
  ///   unnamed.
  /// - <prefix> is the `as` prefix used for a given deferred import.
  /// - <list of files> is a list of the filenames the must be loaded when that
  ///   import is loaded.
  /// TODO(joshualitt): the library name is unused and should be removed. This
  /// will be a breaking change.
  Map<String, Map<String, dynamic>> computeDeferredMap(
      Map<String, List<FinalizedFragment>> fragmentsToLoad) {
    Map<String, Map<String, dynamic>> mapping = {};

    outputUnitData.deferredImportDescriptions.keys
        .forEach((ImportEntity import) {
      var importDeferName = outputUnitData.importDeferName[import];
      List<FinalizedFragment> fragments = fragmentsToLoad[importDeferName];
      ImportDescription description =
          outputUnitData.deferredImportDescriptions[import];
      String getName(LibraryEntity library) {
        var name = _elementEnvironment.getLibraryName(library);
        return name == '' ? '<unnamed>' : name;
      }

      Map<String, dynamic> libraryMap = mapping.putIfAbsent(
          description.importingUri,
          () => {"name": getName(description.importingLibrary), "imports": {}});

      List<String> partFileNames = fragments
          .map((fragment) =>
              deferredPartFileName(_options, fragment.canonicalOutputUnit.name))
          .toList();
      libraryMap["imports"][importDeferName] = partFileNames;
    });
    return mapping;
  }
}
