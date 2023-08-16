// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection';
import '../../common/elements.dart' show ElementEnvironment;
import '../../deferred_load/output_unit.dart'
    show OutputUnit, OutputUnitData, deferredPartFileName;
import '../../elements/entities.dart';
import '../../js/js.dart' as js;
import '../../options.dart';
import '../model.dart';

/// This file contains a number of abstractions used by dart2js for emitting and
/// merging deferred fragments.
///
/// The initial deferred loading algorithm breaks a program up into multiple
/// [OutputUnits] where each [OutputUnit] represents part of the user's
/// program. [OutputUnits] are represented by a unique intersection of imports
/// known as an import set. Thus, each [OutputUnit] is a node in a deferred
/// graph. Edges in this graph are dependencies between [OutputUnits].
///
/// [OutputUnits] have a notion of successors and predecessors, that is a
/// successor to an [OutputUnit] is an [OutputUnit] that must be loaded first. A
/// predecessor to an [OutputUnit] is an [OutputUnit] that must be loaded later.
///
/// To load some given deferred library, a list of [OutputUnits] must be loaded
/// in the correct order, with their successors loaded first, then the given
/// [OutputUnit], then the [OutputUnits] predecessors.
///
/// To give a concrete example, say our graph looks like:
///    {a}   {b}   {c}
///
///     {a, b} {b, c}
///
///       {a, b, c}
///
/// Where each set above is the import set of an [OutputUnit]. We say that
/// {a}, {b}, and {c} are root [OutputUnits], i.e. [OutputUnits] with no
/// predecessors, and {a, b, c} is a leaf [OutputUnit], i.e. [OutputUnits]
/// with no successors.
///
/// We then have three load lists:
///   a: {a, b, c}, {a, b}, {a}
///   b: {a, b, c}, {a, b}, {b, c}, {b}
///   c: {a, b, c}, {b, c}, {c}
///
/// In all 3 load lists, {a, b, c} must be loaded first. All of the other
/// [OutputUnits] are predecessors of {a, b, c}. {a, b, c} is a successor to all
/// other [OutputUnits].
///
/// However, the dart2js deferred loading algorithm generates a very granular
/// sparse graph of [OutputUnits] and in many cases it is desireable to coalesce
/// smaller [OutputUnits] together into larger chunks of code to reduce the
/// number of files which have to be sent to the client. To do this
/// cleanly, we use various abstractions to merge [OutputUnits].
///
/// First, we emit the code for each [OutputUnit] into an [EmittedOutputUnit].
/// An [EmittedOutputUnit] is the JavaScript representation of an [OutputUnit].
/// [EmittedOutputUnits] map 1:1 to [OutputUnits].
///
/// We wrap each [EmittedOutputUnit] in a [PreFragment], which is just a wrapper
/// to facilitate merging of [EmittedOutputUnits]. Then, we run a merge
/// algorithm on these [PreFragments], merging them together until some
/// threshold.
///
/// Once we are finished merging [PreFragments], we must now decide on their
/// final representation in JavaScript.
///
/// Depending on the results of the merge, we chose one of two representations.
/// For example, say we merge {a, b} and {a} into {a, b}+{a}. In this case our
/// new load lists look like:
///
///   a: {a, b, c}, {a, b}+{a}
///   b: {a, b, c}, {a, b}+{a}, {b, c}, {b}
///   c: {a, b, c}, {b, c}, {c}
///
/// This adds a bit of extra code to the 'b' load list, but otherwise there are
/// no problems. In this case, we will interleave [EmittedOutputUnits] into a
/// single [CodeFragment], with a single top level initialization function. This
/// approach results in lower overhead, because the runtime can initialize the
/// {a, b}+{a} [CodeFragment] with a single invocation of a top level function.
///
/// Ideally we would interleave all [EmittedOutputUnits] in each [PreFragment]
/// into a single [CodeFragment]. We would then write this single
/// [CodeFragment] into a single [FinalizedFragment], where a
/// [FinalizedFragment] is just an abstraction representing a single file on
/// disk. Unfortunately this is not always possible to do efficiently.
///
/// Specifically, lets say we decide to merge {a} and {c} into {a}+{c}
/// In this case, our load lists now look like:
///
///   a: {a, b, c}, {a, b}, {a}+{c}
///   b: {a, b, c}, {a, b}, {b, c}, {b}
///   c: {a, b, c}, {b, c}, {a}+{c}
///
/// Now, load lists 'a' and 'c' are invalid. Specifically, load list 'a' is
/// missing {c}'s dependency {b, c} and load list 'c' is missing {a}'s
/// dependency {a, b}. We could bloat both load lists with the necessary
/// dependencies, but this would negate any performance benefit from
/// interleaving.
///
/// Instead, when this happens we emit {a} and {c} into separate
/// [CodeFragments], with separate top level initialization functions that are
/// only called when the necessary dependencies for initialization are
/// present. These [CodeFragments] end up in a single [FinalizedFragment].
/// While this approach doesn't have the performance benefits of
/// interleaving, it at least reduces the total number of files which need to be
/// sent to the client.

class EmittedOutputUnit {
  final Fragment fragment;
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

  EmittedOutputUnit(
      this.fragment,
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
      this.nativeSupport);

  CodeFragment toCodeFragment(Program program) {
    return CodeFragment(
        [fragment],
        [outputUnit],
        libraries,
        classPrototypes,
        closurePrototypes,
        inheritance,
        methodAliases,
        tearOffs,
        constants,
        typeRules,
        variances,
        staticNonFinalFields,
        lazyInitializers,
        nativeSupport,
        program.metadataTypesForOutputUnit(outputUnit));
  }
}

class PreFragment {
  final String outputFileName;
  final List<EmittedOutputUnit> emittedOutputUnits = [];
  final Set<PreFragment> successors = {};
  final Set<PreFragment> predecessors = {};
  late final FinalizedFragment finalizedFragment;
  int size = 0;

  // TODO(joshualitt): interleave dynamically when it makes sense.
  bool shouldInterleave = false;

  PreFragment(
      this.outputFileName, EmittedOutputUnit emittedOutputUnit, this.size) {
    emittedOutputUnits.add(emittedOutputUnit);
  }

  PreFragment mergeAfter(PreFragment that) {
    assert(this != that);
    this.emittedOutputUnits.addAll(that.emittedOutputUnits);
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

  /// Interleaves the [EmittedOutputUnits] into a single [CodeFragment].
  CodeFragment interleaveEmittedOutputUnits(Program program) {
    var seedEmittedOutputUnit = emittedOutputUnits.first;
    if (emittedOutputUnits.length == 1) {
      return seedEmittedOutputUnit.toCodeFragment(program);
    } else {
      var seedOutputUnit = seedEmittedOutputUnit.outputUnit;
      List<Fragment> fragments = [];
      List<Library> libraries = [];
      List<OutputUnit> outputUnits = [seedOutputUnit];
      List<js.Statement> classPrototypes = [];
      List<js.Statement> closurePrototypes = [];
      List<js.Statement> inheritance = [];
      List<js.Statement> methodAliases = [];
      List<js.Statement> tearOffs = [];
      List<js.Statement> constants = [];
      List<js.Statement> typeRules = [];
      List<js.Statement> variances = [];
      List<js.Statement> staticNonFinalFields = [];
      List<js.Statement> lazyInitializers = [];
      List<js.Statement> nativeSupport = [];
      for (var emittedOutputUnit in emittedOutputUnits) {
        var thatOutputUnit = emittedOutputUnit.outputUnit;
        if (seedOutputUnit != thatOutputUnit) {
          program.mergeOutputUnitMetadata(seedOutputUnit, thatOutputUnit);
          outputUnits.add(thatOutputUnit);
          fragments.add(emittedOutputUnit.fragment);
        }
        libraries.addAll(emittedOutputUnit.libraries);
        classPrototypes.add(emittedOutputUnit.classPrototypes);
        closurePrototypes.add(emittedOutputUnit.closurePrototypes);
        inheritance.add(emittedOutputUnit.inheritance);
        methodAliases.add(emittedOutputUnit.methodAliases);
        tearOffs.add(emittedOutputUnit.tearOffs);
        constants.add(emittedOutputUnit.constants);
        typeRules.add(emittedOutputUnit.typeRules);
        variances.add(emittedOutputUnit.variances);
        staticNonFinalFields.add(emittedOutputUnit.staticNonFinalFields);
        lazyInitializers.add(emittedOutputUnit.lazyInitializers);
        nativeSupport.add(emittedOutputUnit.nativeSupport);
      }
      return CodeFragment(
          fragments,
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
    }
  }

  /// Bundles [EmittedOutputUnits] into multiple [CodeFragments].
  List<CodeFragment> bundleEmittedOutputUnits(Program program) {
    List<CodeFragment> codeFragments = [];
    for (var emittedOutputUnit in emittedOutputUnits) {
      codeFragments.add(emittedOutputUnit.toCodeFragment(program));
    }
    return codeFragments;
  }

  /// Finalizes this [PreFragment] into a single [FinalizedFragment] by either
  /// interleaving [EmittedOutputUnits] into a single [CodeFragment] or by
  /// bundling [EmittedOutputUnits] into multiple [CodeFragments].
  FinalizedFragment finalize(
      Program program,
      Map<OutputUnit, CodeFragment> outputUnitMap,
      Map<CodeFragment, FinalizedFragment> codeFragmentMap) {
    List<CodeFragment> codeFragments = shouldInterleave
        ? [interleaveEmittedOutputUnits(program)]
        : bundleEmittedOutputUnits(program);
    finalizedFragment = FinalizedFragment(outputFileName, codeFragments);
    codeFragments.forEach((codeFragment) {
      codeFragmentMap[codeFragment] = finalizedFragment;
      codeFragment.outputUnits.forEach((outputUnit) {
        outputUnitMap[outputUnit] = codeFragment;
      });
    });
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
    var outputUnitStrings = [];
    for (var emittedOutputUnit in emittedOutputUnits) {
      var importString = [];
      for (var import in emittedOutputUnit.outputUnit.imports) {
        importString.add(import.name);
      }
      outputUnitStrings.add('{${importString.join(', ')}}');
    }
    return "${outputUnitStrings.join('+')}";
  }

  /// Clears all [PreFragment] data structure and zeros out the size. Should be
  /// used only after merging to GC internal data structures.
  void clearAll() {
    emittedOutputUnits.clear();
    successors.clear();
    predecessors.clear();
    size = 0;
  }
}

class CodeFragment {
  final List<Fragment> fragments;
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

  CodeFragment(
      this.fragments,
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

  @override
  String toString() {
    List<String> outputUnitStrings = [];
    for (var outputUnit in outputUnits) {
      List<String?> importStrings = [];
      for (var import in outputUnit.imports) {
        importStrings.add(import.name);
      }
      outputUnitStrings.add('{${importStrings.join(', ')}}');
    }
    return outputUnitStrings.join('+');
  }

  OutputUnit get canonicalOutputUnit => outputUnits.first;
}

class FinalizedFragment {
  final String outputFileName;
  final List<CodeFragment> codeFragments;

  FinalizedFragment(this.outputFileName, this.codeFragments);

  // The 'main' [OutputUnit] for this [FinalizedFragment].
  // TODO(joshualitt): Refactor this to more clearly disambiguate between
  // [OutputUnits](units of deferred merging), fragments(units of emitted code),
  // and files.
  OutputUnit get canonicalOutputUnit => codeFragments.first.canonicalOutputUnit;

  @override
  String toString() {
    List<String> strings = [];
    for (var codeFragment in codeFragments) {
      strings.add(codeFragment.toString());
    }
    return 'FinalizedFragment([${strings.join(', ')}])';
  }
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

  // Converts a map of (loadId, List<OutputUnit>) to two maps.
  // The first is a map of (loadId, List<FinalizedFragment>), which is used to
  // compute which files need to be loaded for a given loadId.
  // The second is a map of (loadId, List<CodeFragment>) which is used to
  // compute which CodeFragments need to be loaded for a given loadId.
  void computeFragmentsToLoad(
      Map<String, List<OutputUnit>> outputUnitsToLoad,
      Map<OutputUnit, CodeFragment> outputUnitMap,
      Map<CodeFragment, FinalizedFragment> codeFragmentMap,
      Set<OutputUnit> omittedOutputUnits,
      Map<String, List<CodeFragment>> codeFragmentsToLoad,
      Map<String, List<FinalizedFragment>> finalizedFragmentsToLoad) {
    outputUnitsToLoad.forEach((loadId, outputUnits) {
      Set<CodeFragment> uniqueCodeFragments = {};
      Set<FinalizedFragment> uniqueFinalizedFragments = {};
      List<FinalizedFragment> finalizedFragments = [];
      List<CodeFragment> codeFragments = [];
      for (var outputUnit in outputUnits) {
        if (omittedOutputUnits.contains(outputUnit)) continue;
        final codeFragment = outputUnitMap[outputUnit]!;
        if (uniqueCodeFragments.add(codeFragment)) {
          codeFragments.add(codeFragment);
        }
        final finalizedFragment = codeFragmentMap[codeFragment]!;
        if (uniqueFinalizedFragments.add(finalizedFragment)) {
          finalizedFragments.add(finalizedFragment);
        }
      }
      codeFragmentsToLoad[loadId] = codeFragments;
      finalizedFragmentsToLoad[loadId] = finalizedFragments;
    });
  }

  /// Given a list of OutputUnits sorted by their import entities,
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
          final backEdge = backEdges[b] ??= {};

          // Remove transitive edges from nodes that will reach 'b' from the
          // edge we just added.
          // Note: Because we add edges in order (starting from the smallest
          // sets) we always add transitive edges before the last direct edge.
          backEdge.removeWhere((c) => aImports.containsAll(c.imports));

          // Create an edge to denote that 'b' must be loaded before 'a'.
          backEdge.add(a);
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
      List<OutputUnit> outputUnits, List<PreFragment> preDeferredFragments) {
    // Create a map of OutputUnit to Fragment.
    Map<OutputUnit, PreFragment> outputUnitMap = {};
    for (var preFragment in preDeferredFragments) {
      var outputUnit = preFragment.emittedOutputUnits.single.outputUnit;
      outputUnitMap[outputUnit] = preFragment;
      totalSize += preFragment.size;
    }

    // Get a list of direct edges and then attach them to PreFragments.
    var allEdges = createDirectEdges(outputUnits);
    allEdges.forEach((outputUnit, edges) {
      final predecessor = outputUnitMap[outputUnit]!;
      for (var edge in edges) {
        final successor = outputUnitMap[edge]!;
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
          return a.emittedOutputUnits.single.outputUnit
              .compareTo(b.emittedOutputUnits.single.outputUnit);
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
    final desiredNumberOfFragment = _options.mergeFragmentsThreshold!;
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
      final loadId = outputUnitData.importDeferName[import]!;
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
  /// library uri -> {
  ///   "name": library name,
  ///   "imports": (loadId -> list of files),
  ///   "importPrefixToLoadId": (prefix -> loadId)
  /// }
  ///
  /// Where
  ///
  /// - <library uri> is the import uri of the library making a deferred
  ///   import.
  /// - <library name> is the name of the library, or "<unnamed>" if it is
  ///   unnamed.
  /// - <prefix> is the `as` prefix used for a given deferred import.
  /// - <loadId> is the unique ID assigned by the compiler for each
  ///   <library uri>/<prefix> pair.
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
      final fragments = fragmentsToLoad[importDeferName]!;
      final description = outputUnitData.deferredImportDescriptions[import]!;
      String getName(LibraryEntity library) {
        var name = _elementEnvironment.getLibraryName(library);
        return name == '' ? '<unnamed>' : name;
      }

      Map<String, dynamic> libraryMap = mapping.putIfAbsent(
          description.importingUri,
          () => {
                'name': getName(description.importingLibrary),
                'imports': {},
                'importPrefixToLoadId': {},
              });

      List<String> partFileNames = fragments
          .map((fragment) =>
              deferredPartFileName(_options, fragment.canonicalOutputUnit.name))
          .toList();
      (libraryMap['imports'] as Map)[importDeferName] = partFileNames;
      (libraryMap['importPrefixToLoadId'] as Map)[import.name] =
          importDeferName;
    });
    return mapping;
  }
}
