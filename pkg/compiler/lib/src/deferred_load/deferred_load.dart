// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// *Overview of deferred loading*
///
/// Deferred loading allows developers to specify deferred imports. These
/// imports represent explicit asynchronous splits of the application that
/// allows code to be delivered in pieces.
///
/// The initial download of an application will exclude code used only by
/// deferred imports. As the application reaches a
/// `deferred_import.loadLibrary()` instruction, it will download and initialize
/// any code needed by that deferred import.
///
/// Very often separate deferred imports access common code.  When that happens,
/// the compiler places the shared code in separate files. At runtime, the
/// application will only download shared code once when the first deferred
/// import that needs that code gets loaded. To achieve this, the compiler
/// generates _load lists_: a list of JavaScript files that need to be
/// downloaded for every deferred import in the program.
///
/// Each generated JavaScript file has an initialization within it. The files
/// can be concatenated together in a bundle without affecting the
/// initialization logic. This is used by customers to reduce the download
/// latency when they know that multiple files will be loaded at once.
///
/// *The code splitting algorithm*
///
/// The goal of this library and the [DeferredLoadingTask] is to determine how
/// to best split code in multiple files according to the principles described
/// above.
///
/// We do so by partitioning code into output units ([OutputUnit]s in our
/// implementation). The partitioning reflects how code is shared between
/// different deferred imports. Each output unit is associated a set of deferred
/// imports (an [ImportSet] in our implementation). These are the deferred
/// imports that need the code that is stored in that output unit. Code that is
/// needed by a single deferred import, will be associated with a set containing
/// that deferred import only (a singleton set), but code that is shared by 10
/// deferred imports will be associated with a set containing all of those
/// imports instead.  We determine whether code is shared based on how code is
/// accessed in the program. An element is considered to be accessed by a
/// deferred import if it is either loaded and invoked from that import or
/// transitively accessed by an element that was invoked by that import.
///
/// In theory, there could be an exponential number of output units: one per
/// subset of deferred imports in the program. In practice, large apps do have a
/// large number of output units, but the result is not exponential. This is
/// both because not all deferred imports have code in common and because many
/// deferred imports end up having the same code in common.
///
/// *Main output unit*:
///
/// The main output unit contains any code accessed directly from main. Such
/// code may be accessed by deferred imports too, but because it is accessed
/// from the main entrypoint of the program, possibly synchronously, we do not
/// split out the code or defer it. Our current implementation uses an empty
/// import-set as a sentinel value to represent this output unit.
///
/// *Dependency graph*:
///
/// We use the element model to discover dependencies between elements.
/// We distinguish two kinds of dependencies: deferred or direct (aka.
/// non-deferred):
///
///   * Deferred dependencies are only used to discover root elements. Roots
///   are elements immediately loaded and used from deferred import prefixes in
///   a program.
///
///   * Direct dependencies are used to recursively update which output unit
///   should be associated with an element.
///
/// *Algorithm Principle*:
///
/// Conceptually the algorithm consists of associating an element with an
/// import-set. When we discover a root, we mark it and everything it can reach
/// as being used by that import. Marking elements as used by that import
/// consists of adding the import to the import-set of all those reachable
/// elements.
///
/// An earlier version of this algorithm was implemented with this simple
/// approach: we kept a map from entities to a [Set] of imports and updated the
/// sets iteratively. However, as customer applications grew, we needed a more
/// specialized and efficient implementation.
///
/// *ImportSet representation and related optimizations*:
///
/// The most important change to scale the algorithm was to use an efficient
/// representation of entity to import-set associations. For large apps there
/// are a lot of entities, and the simple representation of having a [Set] per
/// entity was too expensive. We observed that many of such sets had the same
/// imports (which makes sense given that many elements ended up together in the
/// same output units). This led us to design the [ImportSet] abstraction: a
/// representation of import-sets that guarantees that each import-set has a
/// canonical representation. Memory-wise this was a big win: we now bounded
/// the heap utilization to one [ImportSet] instance per unique import-set.
///
/// This representation is not perfect. Simple operations, like adding an import
/// to an import-set, are now worse-case linear. So it was important to add a
/// few optimizations in the algorithm in order to adapt to the new
/// representation.
///
/// The principle of our optimizations is to make bulk updates. Rather than
/// adding an import at a time for all reachable elements, we changed the
/// algorithm to make updates in bulk in two ways:
///
///   * Batch unions: when possible add more than one import at once, and
///
///   * Update elements in segments: when an element and its reachable
///   dependencies would change in the same way, update them all together.
///
/// To achieve these bulk updates, the algorithm uses a two tier algorithm:
///
///   * The top tier uses a worklist to track the start of a bulk update, either
///   from a root (entities that dominate code used by a single deferred import)
///   or from a merge point in the dependency graph (entities that dominate
///   shared code between multiple imports).
///
///   * The second tier is where bulk updates are made, these don't use a
///   worklist, but simply a DFS recursive traversal of the dependency graph.
///   The DFS traversal stops at merge points and makes note of them by
///   updating the top tier worklist.
///
///
/// *Example*:
///
/// Consider this dependency graph (ignoring elements in the main output unit):
///
///   deferred import A: a1 ---> s1 ---> s2  -> s3
///                              ^       ^
///                              |       |
///   deferred import B: b1 -----+       |
///                                      |
///   deferred import C: c1 ---> c2 ---> c3
///
/// Here a1, b1, and c1 are roots, while s1 and s2 are merge points. The
/// algorithm will compute a result with 5 deferred output units:
//
///   * unit {A}:        contains a1
///   * unit {B}:        contains b1
///   * unit {C}:        contains c1, c2, and c3
///   * unit {A, B}:     contains s1
///   * unit {A, B, C}:  contains s2, and s3
///
/// After marking everything reachable from main as part of the main output
/// unit, our algorithm will work as follows:
///
///   * Initially all deferred elements have no mapping.
///   * We make note of work to do, initially to mark the root of each
///     deferred import:
///        * a1 with A, and recurse from there.
///        * b1 with B, and recurse from there.
///        * c1 with C, and recurse from there.
///   * We update a1, s1, s2, s3 in bulk, from no mapping to {A}.
///   * We update b1 from no mapping to {B}, and when we find s1 we notice
///     that s1 is already associated with another import set {A}. This is a
///     merge point that can't be updated in bulk, so we make
///     note of additional work for later to mark s1 with {A, B}
///   * We update in bulk c1, c2, c3 to {C}, and make a note to update s2 with
///     {A, C} (another merge point).
///   * We update s1 to {A, B}, and update the existing note to update s2, now
///     with {A, B, C}
///   * Finally we update s2 and s3 with {A, B, C} in bulk, without ever
///     updating them to the intermediate state {A, C}.
///
/// *How bulk segment updates work?*
///
/// The principle of the bulk segment update is similar to memoizing the result
/// of a union operation. We replace a union operation with a cached result if
/// we can tell that the inputs to the operation are the same.
///
/// Our implementation doesn't use a cache table to memoize arbitrary unions.
/// Instead it only memoizes one union at a time: it tries to reuse the result
/// of a union applied to one entity, when updating the import-sets of its
/// transitive dependencies.
///
/// Consider a modification of the example above where we add s4 and s5 as
/// additional dependencies of s3. Conceptually, we are applying this sequence
/// of union operations:
///
///    importSet[s2] = importSet[s2] UNION {B, C}
///    importSet[s3] = importSet[s3] UNION {B, C}
///    importSet[s4] = importSet[s4] UNION {B, C}
///    importSet[s5] = importSet[s5] UNION {B, C}
///
/// When the algorithm is updating s2, it checks whether any of the entities
/// reachable from s2 also have the same import-set as s2, and if so, we know
/// that the union result is the same.
///
/// Our implementation uses the term `oldSet` to represent the first input of
/// the memoized union operation, and `newSet` to represent the result:
///
///    oldSet = importSet[s2]        // = A
///    newSet = oldSet UNION {B, C}  // = {A, B, C}
///
/// Then the updates are encoded as:
///
///    update(s2, oldSet, newSet);
///    update(s3, oldSet, newSet);
///    update(s4, oldSet, newSet);
///    update(s5, oldSet, newSet);
///
/// where:
///
///    update(s5, oldSet, newSet) {
///      var currentSet = importSet[s];
///      if (currentSet == oldSet) {
///        // Use the memoized result, woohoo!
///        importSet[s] = newSet;
///      } else {
///        // Don't use the memoized result, instead use the worklist to later
///        // update `s` with the appropriate union operation.
///      }
///    }
///
/// As a result of this, the update to the import set for s2, s3, s4 and s5
/// becomes a single if-check and an assignment, but the union operation was
/// only executed once.
///
/// *Constraints*:
///
/// By default our algorithm considers all deferred imports equally and
/// potentially occurring at any time in the application lifetime. In practice,
/// apps use deferred imports to layer the load of their application and, often,
/// developers know how imports will be loaded over time.
///
/// Dart2js accepts a configuration file to specify constraints about deferred
/// imports. There are many kinds of constraints that help developers encode how
/// their applications work.
///
/// To model constraints, the deferred loading algorithm was changed to include
/// _set transitions_: these are changes made to import-sets to effectively
/// encode the constraints.
///
/// Consider, for example, a program with two deferred imports `A` and `B`. Our
/// unconstrained algorithm will split the code in 3 files:
///
///   * code unique to `A` (represented by the import set `{A}`)
///
///   * code unique to `B` (represented by the import set `{B}`)
///
///   * code shared between `A and `B (represented by the import set `{A, B}`)
///
/// When an end-user loads the user journey corresponding to `A`, the code for
/// `{A}` and `{A,B}` gets loaded. When they load the user journey corresponding
/// to `B`, `{B}` and `{A, B}` gets loaded.
///
/// An ordering constraint saying that `B` always loads after `A` tells our
/// algorithm that, even though there exists code that is unique to `A`, we
/// could merge it together with the shared code between `A` and `B`, since the
/// user never intends to load `B` first. The result would be to have two files
/// instead:
///
///   * code unique to `B` (represented by the import set `{B}`)
///
///   * code unique to A and code shared between A and B (represented by the
///   import set `{A, B}`)
///
///
/// In this example, the set transition is to convert any set containing `{A}`
/// into a set containing `{A, B}`.
///
// TODO(joshualitt): update doc above when main is represented by a set
// containing an implicit import corresponding to `main`.
// TODO(sigmund): investigate different heuristics for how to select the next
// work item (e.g. we might converge faster if we pick first the update that
// contains a bigger delta.)
library deferred_load;

import 'dart:convert';

import '../../compiler_api.dart' as api show OutputType;
import '../common.dart';
import '../common/elements.dart' show KElementEnvironment;
import '../common/metrics.dart'
    show Metric, Metrics, CountMetric, DurationMetric;
import '../common/tasks.dart' show CompilerTask;
import '../compiler.dart';
import '../constants/values.dart';
import '../elements/entities.dart';
import '../elements/types.dart';
import '../kernel/element_map.dart';
import '../kernel/kernel_world.dart' show KClosedWorld;
import '../options.dart';
import '../util/util.dart' show makeUnique;
import 'algorithm_state.dart';
import 'entity_data.dart';
import 'import_set.dart';
import 'output_unit.dart';
import 'program_split_constraints/builder.dart' as psc show Builder;

class _DeferredLoadTaskMetrics implements Metrics {
  @override
  String get namespace => 'deferred_load';

  DurationMetric time = DurationMetric('time');
  CountMetric outputUnitElements = CountMetric('outputUnitElements');

  @override
  Iterable<Metric> get primary => [time];

  @override
  Iterable<Metric> get secondary => [outputUnitElements];
}

/// For each deferred import, find elements and constants to be loaded when that
/// import is loaded. Elements that are used by several deferred imports are in
/// shared OutputUnits.
class DeferredLoadTask extends CompilerTask {
  @override
  String get name => 'Deferred Loading';

  /// The OutputUnit that will be loaded when the program starts.
  final OutputUnit _mainOutputUnit;

  /// A sentinel used only by the [ImportSet] corresponding to the
  /// [_mainOutputUnit].
  final ImportEntity _mainImport =
      ImportEntity(true, 'main#main', Uri(), Uri());

  /// A set containing (eventually) all output units that will result from the
  /// program.
  final List<OutputUnit> _allOutputUnits = [];

  /// Will be `true` if the program contains deferred libraries.
  bool isProgramSplit = false;

  /// A cache of the result of calling `computeImportDeferName` on the keys of
  /// this map.
  final Map<ImportEntity, String> importDeferName = {};

  Iterable<ImportEntity> get _allDeferredImports =>
      _deferredImportDescriptions.keys;

  /// Because the token-stream is forgotten later in the program, we cache a
  /// description of each deferred import.
  final Map<ImportEntity, ImportDescription> _deferredImportDescriptions = {};

  /// A lattice to compactly represent multiple subsets of imports.
  ///
  /// This property is nullable only to reclaim memory after this phase is
  /// complete.
  ImportSetLattice? importSets = ImportSetLattice();

  final Compiler compiler;

  final KernelToElementMap _elementMap;

  _DeferredLoadTaskMetrics? _deferredLoadMetrics;
  _DeferredLoadTaskMetrics get deferredLoadMetrics =>
      _deferredLoadMetrics ??= _DeferredLoadTaskMetrics();
  @override
  Metrics get metrics => _deferredLoadMetrics ?? Metrics.none();

  bool get disableProgramSplit => compiler.options.disableProgramSplit;

  AlgorithmState? algorithmState;

  DeferredLoadTask(this.compiler, this._elementMap)
      : _mainOutputUnit = OutputUnit(true, 'main', {}),
        super(compiler.measurer) {
    _allOutputUnits.add(_mainOutputUnit);
  }

  KElementEnvironment get elementEnvironment =>
      compiler.frontendStrategy.elementEnvironment;

  DartTypes get dartTypes => compiler.frontendStrategy.commonElements.dartTypes;

  DiagnosticReporter get reporter => compiler.reporter;

  /// Computes a unique string for the name field for each outputUnit.
  void _createOutputUnits() {
    // Before finalizing [OutputUnit]s, we apply [ImportSetTransition]s.
    measureSubtask('apply set transitions', () {
      algorithmState?.applySetTransitions();
    });

    // Add an [OutputUnit] for each [ImportSet].
    int counter = 1;
    void addUnit(ImportSet importSet) {
      if (importSet.unit != null) return;
      var unit = OutputUnit(false, '$counter', importSet.toSet());
      counter++;
      importSet.unit = unit;
      _allOutputUnits.add(unit);
      deferredLoadMetrics.outputUnitElements.add(1);
    }

    // Generate an output unit for all import sets that are associated with an
    // element or constant.
    algorithmState?.entityToSet.values.forEach(addUnit);

    // Sort output units to make the output of the compiler more stable.
    _allOutputUnits.sort();
  }

  void _setupImportNames() {
    // If useSimpleLoadIds is true then we use a monotonically increasing number
    // to generate loadIds. Otherwise, we will use the user provided names.
    bool useIds = compiler.options.useSimpleLoadIds;
    var allDeferredImports = _allDeferredImports.toList();
    if (useIds) {
      // Sort for a canonical order of [ImportEntity]s.
      allDeferredImports.sort(compareImportEntities);
    }
    int nextDeferId = 0;
    Set<String> usedImportNames = {};
    for (ImportEntity import in allDeferredImports) {
      if (useIds) {
        importDeferName[import] = (++nextDeferId).toString();
      } else {
        String result = computeImportDeferName(import, compiler);
        // Note: tools that process the json file to build multi-part initial load
        // bundles depend on the fact that makeUnique appends only digits, or a
        // period followed by digits.
        importDeferName[import] = makeUnique(result, usedImportNames, '.');
      }
    }
  }

  /// Returns a name for a deferred import.
  String computeImportDeferName(ImportEntity declaration, Compiler compiler) {
    assert(declaration.isDeferred);
    final name = declaration.name;
    if (name != null) return name;

    // This happens when the deferred import isn't declared with a prefix.
    assert(compiler.compilationFailed);
    return '';
  }

  bool get generateDeferredLoadIdMap =>
      compiler.options.stage == Dart2JSStage.deferredLoadIds;

  /// Performs the deferred loading algorithm.
  ///
  /// See the top-level library comment for details.
  OutputUnitData run(FunctionEntity main, KClosedWorld closedWorld) {
    return deferredLoadMetrics.time.measure(() => _run(main, closedWorld));
  }

  OutputUnitData _run(FunctionEntity main, KClosedWorld closedWorld) {
    if (!isProgramSplit || disableProgramSplit) {
      return _buildResult();
    }

    work() {
      algorithmState = AlgorithmState.create(
          main, compiler, _elementMap, closedWorld, importSets!);
    }

    reporter.withCurrentElement(main.library, () => measure(work));
    return _buildResult();
  }

  // Dumps a graph as a list of strings of 0 and 1. There is one 'bit' for each
  // import entity in the graph, and each string in the list represents an
  // output unit.
  void _dumpDeferredGraph(Uri deferredGraphUri) {
    int id = 0;
    Map<ImportEntity, int> importMap = {};
    var entities = _deferredImportDescriptions.keys.toList();
    entities.sort(compareImportEntities);
    entities = entities.reversed.toList();
    for (var key in entities) {
      importMap[key] = id++;
    }
    List<String> graph = [];
    for (var outputUnit in _allOutputUnits) {
      if (!outputUnit.isMainOutput) {
        List<int> representation = List.filled(id, 0);
        for (var entity in outputUnit.imports) {
          representation[importMap[entity]!] = 1;
        }
        graph.add(representation.join());
      }
    }
    compiler.outputProvider
        .createOutputSink(deferredGraphUri.path, '', api.OutputType.debug)
      ..add(graph.join('\n'))
      ..close();
  }

  OutputUnitData _buildResult() {
    _createOutputUnits();
    _setupImportNames();
    var deferredGraphUri = compiler.options.deferredGraphUri;
    if (deferredGraphUri != null) {
      _dumpDeferredGraph(deferredGraphUri);
    }
    bool updateMaps = true;
    if (generateDeferredLoadIdMap) {
      _writeDeferredLoadIdMap();
      updateMaps = false;
    }
    Map<ClassEntity, OutputUnit> classMap = {};
    Map<ClassEntity, OutputUnit> classTypeMap = {};
    Map<MemberEntity, OutputUnit> memberMap = {};
    Map<Local, OutputUnit> localFunctionMap = {};
    Map<ConstantValue, OutputUnit> constantMap = {};
    if (updateMaps) {
      algorithmState?.entityToSet.forEach((d, s) {
        if (d is ClassEntityData) {
          classMap[d.entity] = s.unit!;
        } else if (d is ClassTypeEntityData) {
          classTypeMap[d.entity] = s.unit!;
        } else if (d is MemberEntityData) {
          memberMap[d.entity] = s.unit!;
        } else if (d is LocalFunctionEntityData) {
          localFunctionMap[d.entity] = s.unit!;
        } else if (d is ConstantEntityData) {
          constantMap[d.entity] = s.unit!;
        } else {
          throw 'Unrecognized EntityData $d';
        }
      });
    }
    algorithmState = null;
    importSets = null;
    return OutputUnitData(
        this.isProgramSplit && !disableProgramSplit,
        this._mainOutputUnit,
        classMap,
        classTypeMap,
        memberMap,
        localFunctionMap,
        constantMap,
        _allOutputUnits,
        importDeferName,
        _deferredImportDescriptions);
  }

  void beforeResolution(Uri rootLibraryUri, Iterable<Uri> libraries) {
    measureSubtask('prepare', () {
      for (Uri uri in libraries) {
        LibraryEntity library = elementEnvironment.lookupLibrary(uri)!;
        reporter.withCurrentElement(library, () {
          for (ImportEntity import in elementEnvironment.getImports(library)) {
            if (import.isDeferred) {
              _deferredImportDescriptions[import] =
                  ImportDescription(import, library, rootLibraryUri);
              isProgramSplit = true;
            }
          }
        });
      }

      final importSetsLattice = importSets!;

      // If program split constraints are provided, then parse and interpret
      // them now.
      if (compiler.programSplitConstraintsData != null) {
        var builder = psc.Builder(compiler.programSplitConstraintsData!);
        var transitions = builder.build(_allDeferredImports);
        importSetsLattice.buildInitialSets(transitions.singletonTransitions);
        importSetsLattice.buildSetTransitions(transitions.setTransitions);
      }

      // Build the [ImportSet] representing the [_mainOutputUnit].
      importSetsLattice.buildMainSet(
          _mainImport, _mainOutputUnit, _allDeferredImports);
    });
  }

  /// Creates a textual representation of the output unit content.
  String dump() {
    Map<OutputUnit, List<String>> elementMap = {};
    Map<OutputUnit, List<String>> constantMap = {};
    algorithmState?.entityToSet.forEach((d, importSet) {
      if (d is ClassEntityData) {
        var element = d.entity;
        var elements =
            elementMap.putIfAbsent(importSet.unit!, () => <String>[]);
        var id = element.name;
        id = '$id cls';
        elements.add(id);
      } else if (d is ClassTypeEntityData) {
        var element = d.entity;
        var elements =
            elementMap.putIfAbsent(importSet.unit!, () => <String>[]);
        var id = element.name;
        id = '$id type';
        elements.add(id);
      } else if (d is MemberEntityData) {
        var element = d.entity;
        var elements = elementMap.putIfAbsent(importSet.unit!, () => []);
        var id = element.name ?? '$element';
        var cls = element.enclosingClass?.name;
        if (cls != null) id = '$cls.$id';
        if (element.isSetter) id = '$id=';
        id = '$id member';
        elements.add(id);
      } else if (d is LocalFunctionEntityData) {
        var element = d.entity;
        var elements = elementMap.putIfAbsent(importSet.unit!, () => []);
        var id = element.name ?? '$element';
        // ignore: avoid_dynamic_calls
        var context = (element as dynamic).memberContext.name;
        id = element.name == null || element.name == '' ? '<anonymous>' : id;
        id = '$context.$id';
        id = '$id local';
        elements.add(id);
      } else if (d is ConstantEntityData) {
        var value = d.entity;
        // Skip primitive values: they are not stored in the constant tables and
        // if they are shared, they end up duplicated anyways across output units.
        if (value is PrimitiveConstantValue) return;
        constantMap
            .putIfAbsent(importSet.unit!, () => [])
            .add(value.toStructuredText(dartTypes));
      } else {
        throw 'Unrecognized EntityData $d';
      }
    });

    Map<OutputUnit, String> text = {};
    for (OutputUnit outputUnit in _allOutputUnits) {
      StringBuffer unitText = StringBuffer();
      if (outputUnit.isMainOutput) {
        unitText.write(' <MAIN UNIT>');
      } else {
        unitText.write(' imports:');
        var imports = outputUnit.imports
            .map((i) => '${i.enclosingLibraryUri.resolveUri(i.uri)}')
            .toList();
        for (var i in imports..sort()) {
          unitText.write('\n   $i:');
        }
      }
      List<String>? elements = elementMap[outputUnit];
      if (elements != null) {
        unitText.write('\n elements:');
        for (String element in elements..sort()) {
          unitText.write('\n  $element');
        }
      }
      List<String>? constants = constantMap[outputUnit];
      if (constants != null) {
        unitText.write('\n constants:');
        for (String value in constants..sort()) {
          unitText.write('\n  $value');
        }
      }
      text[outputUnit] = '$unitText';
    }

    StringBuffer sb = StringBuffer();
    for (OutputUnit outputUnit in _allOutputUnits.toList()
      ..sort((a, b) => text[a]!.compareTo(text[b]!))) {
      sb.write('\n\n-------------------------------\n');
      sb.write('Output unit: ${outputUnit.name}');
      sb.write('\n ${text[outputUnit]}');
    }
    return sb.toString();
  }

  void _writeDeferredLoadIdMap() {
    Map<String, dynamic> topLevel = {};
    // Json does not support comments, so we embed the explanation in the
    // data.
    topLevel['_comment'] =
        'This mapping shows the runtime deferred load id for each deferred '
        'import in the program. The mappings are grouped by URI containing the '
        'import.';
    final mapping = <String, Map<String, String>>{};
    topLevel['mapping'] = mapping;
    importDeferName.forEach((import, deferredName) {
      (mapping['${import.uri}'] ??= {})[import.name!] = deferredName;
    });
    compiler.outputProvider.createOutputSink(
        compiler.options
            .dataOutputUriForStage(Dart2JSStage.deferredLoadIds)
            .path,
        '',
        api.OutputType.deferredLoadIds)
      ..add(const JsonEncoder.withIndent("  ").convert(topLevel))
      ..close();
  }
}
