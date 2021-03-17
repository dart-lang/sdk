// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

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
      Program program, Map<Fragment, FinalizedFragment> fragmentMap) {
    FinalizedFragment finalizedFragment;
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
      fragmentMap[seedFragment] = finalizedFragment;
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
      for (var fragment in fragments) {
        fragmentMap[fragment] = finalizedFragment;
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

  void add(PreFragment that) {
    size += that.size;
    fragments.add(that);
  }
}

class FragmentMerger {
  final CompilerOptions _options;
  int totalSize = 0;

  FragmentMerger(this._options);

  // Converts a map of (loadId, List<fragments>) to a map of
  // (loadId, List<FinalizedFragment>).
  static Map<String, List<FinalizedFragment>> processLoadMap(
      Map<String, List<Fragment>> programLoadMap,
      Map<Fragment, FinalizedFragment> fragmentMap) {
    Map<String, List<FinalizedFragment>> loadMap = {};
    programLoadMap.forEach((loadId, fragments) {
      Set<FinalizedFragment> unique = {};
      List<FinalizedFragment> finalizedFragments = [];
      loadMap[loadId] = finalizedFragments;
      for (var fragment in fragments) {
        var finalizedFragment = fragmentMap[fragment];
        if (unique.add(finalizedFragment)) {
          finalizedFragments.add(finalizedFragment);
        }
      }
    });
    return loadMap;
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
  void attachDependencies(Map<Fragment, PreFragment> fragmentMap,
      List<PreFragment> preDeferredFragments) {
    // Create a map of OutputUnit to Fragment.
    Map<OutputUnit, Fragment> outputUnitMap = {};
    List<OutputUnit> allOutputUnits = [];
    for (var preFragment in preDeferredFragments) {
      var fragment = preFragment.fragments.single;
      var outputUnit = fragment.outputUnit;
      outputUnitMap[outputUnit] = fragment;
      allOutputUnits.add(outputUnit);
      totalSize += preFragment.size;
    }
    allOutputUnits.sort();

    // Get a list of direct edges and then attach them to PreFragments.
    var allEdges = createDirectEdges(allOutputUnits);
    allEdges.forEach((outputUnit, edges) {
      var predecessor = fragmentMap[outputUnitMap[outputUnit]];
      for (var edge in edges) {
        var successor = fragmentMap[outputUnitMap[edge]];
        predecessor.successors.add(successor);
        successor.predecessors.add(predecessor);
      }
    });
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
    // Sort PreFragments by their initial OutputUnit so they are in canonical
    // order.
    preDeferredFragments.sort((a, b) {
      return a.fragments.single.outputUnit
          .compareTo(b.fragments.single.outputUnit);
    });
    int desiredNumberOfFragment = _options.mergeFragmentsThreshold;

    int idealFragmentSize = (totalSize / desiredNumberOfFragment).ceil();
    List<_Partition> partitions = [];
    void add(PreFragment next) {
      // Create a new partition if the current one grows too large, otherwise
      // just add to the most recent partition.
      if (partitions.isEmpty ||
          partitions.last.size + next.size > idealFragmentSize) {
        partitions.add(_Partition());
      }
      partitions.last.add(next);
    }

    // Greedily group fragments into partitions.
    preDeferredFragments.forEach(add);

    // Reduce fragments by merging fragments with fewer imports into fragments
    // with more imports.
    List<PreFragment> merged = [];
    for (var partition in partitions) {
      merged.add(partition.fragments.reduce((a, b) => b.mergeAfter(a)));
    }
    return merged;
  }
}
