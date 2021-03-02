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
    that.successors.forEach((fragment) {
      fragment.predecessors.remove(that);
      fragment.predecessors.add(this);
    });
    this.successors.addAll(that.successors);
    that.predecessors.remove(this);
    that.predecessors.forEach((fragment) {
      fragment.successors.remove(that);
      fragment.successors.add(this);
    });
    this.predecessors.addAll(that.predecessors);
    this.size += that.size;
    return this;
  }

  FinalizedFragment finalize(
      Program program, Map<Fragment, FinalizedFragment> fragmentMap) {
    FinalizedFragment finalizedFragment;
    var seedFragment = fragments.first;

    // If we only have a single fragment, then wen just finalize it by itself.
    // Otherwise, we finalize an entire group of fragments into a single
    // merged and finalized fragment.
    if (fragments.length == 1) {
      finalizedFragment = FinalizedFragment(
          seedFragment.outputFileName,
          seedFragment.outputUnit,
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
          program.metadataTypesForOutputUnit(seedFragment.outputUnit));
      fragmentMap[seedFragment] = finalizedFragment;
    } else {
      List<Library> libraries = [];
      for (var fragment in fragments) {
        if (seedFragment.outputUnit != fragment.outputUnit) {
          program.mergeOutputUnitMetadata(
              seedFragment.outputUnit, fragment.outputUnit);
          seedFragment.outputUnit.merge(fragment.outputUnit);
        }
        libraries.addAll(fragment.libraries);
      }
      finalizedFragment = FinalizedFragment(
          seedFragment.outputFileName,
          seedFragment.outputUnit,
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
          program.metadataTypesForOutputUnit(seedFragment.outputUnit));
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
}

class FinalizedFragment {
  final String outputFileName;
  final OutputUnit outputUnit;
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
      this.outputUnit,
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

  // Attaches predecessors to each PreFragment. We only care about
  // direct predecessors.
  static void attachDependencies(Map<String, List<Fragment>> programLoadMap,
      Map<Fragment, PreFragment> fragmentMap) {
    programLoadMap.forEach((loadId, fragments) {
      for (int i = 0; i < fragments.length - 1; i++) {
        var fragment = fragmentMap[fragments[i]];
        var nextFragment = fragmentMap[fragments[i + 1]];
        fragment.successors.add(nextFragment);
        nextFragment.predecessors.add(fragment);
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

    // TODO(joshualitt): Precalculate totalSize when computing dependencies.
    int totalSize = 0;
    for (var preFragment in preDeferredFragments) {
      totalSize += preFragment.size;
    }

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
