// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

import 'package:_fe_analyzer_shared/src/testing/features.dart';
import 'package:compiler/src/closure.dart';
import 'package:compiler/src/common.dart';
import 'package:compiler/src/compiler.dart';
import 'package:compiler/src/deferred_load/output_unit.dart';
import 'package:compiler/src/elements/entities.dart';
import 'package:compiler/src/ir/util.dart';
import 'package:compiler/src/js_model/element_map.dart';
import 'package:compiler/src/js_model/js_world.dart';
import 'package:compiler/src/js_emitter/startup_emitter/fragment_merger.dart';
import 'package:compiler/src/kernel/kernel_strategy.dart';
import 'package:expect/expect.dart';
import '../equivalence/id_equivalence.dart';
import '../equivalence/id_equivalence_helper.dart';
import 'package:compiler/src/constants/values.dart';

import 'package:kernel/ast.dart' as ir;

// For ease of testing and making our tests easier to read, we impose an
// artificial constraint of requiring every deferred import use a different
// named prefix per test. We enforce this constraint here by checking that no
// prefix name responds to two different libraries.
Map<String, Uri> importPrefixes = {};

String importPrefixString(OutputUnit unit) {
  List<String> importNames = [];
  for (ImportEntity import in unit.imports) {
    importNames.add(import.name);
    Expect.isTrue(import.isDeferred);

    if (importPrefixes.containsKey(import.name)) {
      var existing = importPrefixes[import.name];
      var current = import.enclosingLibraryUri;
      Expect.equals(
          existing,
          current,
          '\n    Duplicate prefix \'${import.name}\' used in both:\n'
          '     - $existing and\n'
          '     - $current.\n'
          '    We require using unique prefixes on these tests to make '
          'the expectations more readable.');
    }
    importPrefixes[import.name] = import.enclosingLibraryUri;
  }
  importNames.sort();
  return importNames.join(', ');
}

/// Create a consistent string representation of [OutputUnit]s for both
/// KImportEntities and ImportElements.
String outputUnitString(OutputUnit unit) {
  if (unit == null) return 'none';
  String sb = importPrefixString(unit);
  return '${unit.name}{$sb}';
}

Map<String, List<PreFragment>> buildPreFragmentMap(
    Map<String, List<FinalizedFragment>> fragmentsToLoad,
    List<PreFragment> preDeferredFragments) {
  Map<FinalizedFragment, PreFragment> fragmentMap = {};
  for (var preFragment in preDeferredFragments) {
    fragmentMap[preFragment.finalizedFragment] = preFragment;
  }
  Map<String, List<PreFragment>> preFragmentMap = {};
  fragmentsToLoad.forEach((loadId, fragments) {
    List<PreFragment> preFragments = [];
    for (var fragment in fragments) {
      preFragments.add(fragmentMap[fragment]);
    }
    preFragmentMap[loadId] = preFragments.toList();
  });
  return preFragmentMap;
}

class Tags {
  static const String cls = 'class_unit';
  static const String member = 'member_unit';
  static const String closure = 'closure_unit';
  static const String constants = 'constants';
  static const String type = 'type_unit';
  // The below tags appear in a single block comment in the main file.
  // To keep them appearing in sequential order we prefix characters.
  static const String preFragments = 'a_pre_fragments';
  static const String finalizedFragments = 'b_finalized_fragments';
  static const String steps = 'c_steps';
}

class OutputUnitDataComputer extends DataComputer<Features> {
  const OutputUnitDataComputer();

  /// OutputData for [member] as a kernel based element.
  ///
  /// At this point the compiler has already been run, so it is holding the
  /// relevant OutputUnits, we just need to extract that information from it. We
  /// fill [actualMap] with the data computed about what the resulting OutputUnit
  /// is.
  @override
  void computeMemberData(Compiler compiler, MemberEntity member,
      Map<Id, ActualData<Features>> actualMap,
      {bool verbose: false}) {
    JsClosedWorld closedWorld = compiler.backendClosedWorldForTesting;
    JsToElementMap elementMap = closedWorld.elementMap;
    MemberDefinition definition = elementMap.getMemberDefinition(member);
    OutputUnitIrComputer(compiler.reporter, actualMap, elementMap,
            closedWorld.outputUnitData, closedWorld.closureDataLookup)
        .run(definition.node);
  }

  @override
  void computeClassData(Compiler compiler, ClassEntity cls,
      Map<Id, ActualData<Features>> actualMap,
      {bool verbose: false}) {
    JsClosedWorld closedWorld = compiler.backendClosedWorldForTesting;
    JsToElementMap elementMap = closedWorld.elementMap;
    ClassDefinition definition = elementMap.getClassDefinition(cls);
    OutputUnitIrComputer(compiler.reporter, actualMap, elementMap,
            closedWorld.outputUnitData, closedWorld.closureDataLookup)
        .computeForClass(definition.node);
  }

  @override
  void computeLibraryData(Compiler compiler, LibraryEntity library,
      Map<Id, ActualData<Features>> actualMap,
      {bool verbose}) {
    KernelFrontendStrategy frontendStrategy = compiler.frontendStrategy;
    ir.Library node = frontendStrategy.elementMap.getLibraryNode(library);
    List<PreFragment> preDeferredFragments = compiler
        .backendStrategy.emitterTask.emitter.preDeferredFragmentsForTesting;
    Map<String, List<FinalizedFragment>> fragmentsToLoad =
        compiler.backendStrategy.emitterTask.emitter.finalizedFragmentsToLoad;
    Set<OutputUnit> omittedOutputUnits =
        compiler.backendStrategy.emitterTask.emitter.omittedOutputUnits;
    PreFragmentsIrComputer(compiler.reporter, actualMap, preDeferredFragments,
            fragmentsToLoad, omittedOutputUnits)
        .computeForLibrary(node);
  }

  @override
  DataInterpreter<Features> get dataValidator =>
      const FeaturesDataInterpreter();
}

class PreFragmentsIrComputer extends IrDataExtractor<Features> {
  final List<PreFragment> _preDeferredFragments;
  final Map<String, List<FinalizedFragment>> _fragmentsToLoad;
  final Set<OutputUnit> _omittedOutputUnits;

  PreFragmentsIrComputer(
      DiagnosticReporter reporter,
      Map<Id, ActualData<Features>> actualMap,
      this._preDeferredFragments,
      this._fragmentsToLoad,
      this._omittedOutputUnits)
      : super(reporter, actualMap);

  @override
  Features computeLibraryValue(Id id, ir.Library library) {
    var name = '${library.importUri.pathSegments.last}';
    Features features = new Features();
    if (!name.startsWith('main')) return features;

    // First build a list of pre fragments and their dependencies.
    int index = 1;
    Map<FinalizedFragment, int> finalizedFragmentIndices = {};
    Map<PreFragment, int> preFragmentIndices = {};
    Map<int, PreFragment> reversePreFragmentIndices = {};
    Map<int, FinalizedFragment> reverseFinalizedFragmentIndices = {};
    for (var preFragment in _preDeferredFragments) {
      if (!preFragmentIndices.containsKey(preFragment)) {
        var finalizedFragment = preFragment.finalizedFragment;
        preFragmentIndices[preFragment] = index;
        finalizedFragmentIndices[finalizedFragment] = index;
        reversePreFragmentIndices[index] = preFragment;
        reverseFinalizedFragmentIndices[index] = finalizedFragment;
        index++;
      }
    }

    for (int i = 1; i < index; i++) {
      var preFragment = reversePreFragmentIndices[i];
      List<String> needs = [];
      List<OutputUnit> supplied = [];
      List<String> usedBy = [];
      for (var dependent in preFragment.successors) {
        if (preFragmentIndices.containsKey(dependent)) {
          usedBy.add('p${preFragmentIndices[dependent]}');
        }
      }

      for (var dependency in preFragment.predecessors) {
        if (preFragmentIndices.containsKey(dependency)) {
          needs.add('p${preFragmentIndices[dependency]}');
        }
      }

      for (var emittedOutputUnit in preFragment.emittedOutputUnits) {
        supplied.add(emittedOutputUnit.outputUnit);
      }

      var suppliedString = '[${supplied.map(outputUnitString).join(', ')}]';
      features.addElement(Tags.preFragments,
          'p$i: {units: $suppliedString, usedBy: $usedBy, needs: $needs}');
    }

    // Now dump finalized fragments and load ids.
    for (int i = 1; i < index; i++) {
      var finalizedFragment = reverseFinalizedFragmentIndices[i];
      List<String> supplied = [];

      for (var codeFragment in finalizedFragment.codeFragments) {
        List<String> outputUnitStrings = [];
        for (var outputUnit in codeFragment.outputUnits) {
          if (!_omittedOutputUnits.contains(outputUnit)) {
            outputUnitStrings.add(outputUnitString(outputUnit));
          }
        }
        if (outputUnitStrings.isNotEmpty) {
          supplied.add(outputUnitStrings.join('+'));
        }
      }

      if (supplied.isNotEmpty) {
        var suppliedString = '[${supplied.join(', ')}]';
        features.addElement(Tags.finalizedFragments, 'f$i: $suppliedString');
      }
    }

    _fragmentsToLoad.forEach((loadId, finalizedFragments) {
      List<String> finalizedFragmentNeeds = [];
      for (var finalizedFragment in finalizedFragments) {
        assert(finalizedFragmentIndices.containsKey(finalizedFragment));
        finalizedFragmentNeeds
            .add('f${finalizedFragmentIndices[finalizedFragment]}');
      }
      features.addElement(
          Tags.steps, '$loadId=(${finalizedFragmentNeeds.join(', ')})');
    });

    return features;
  }
}

class OutputUnitIrComputer extends IrDataExtractor<Features> {
  final JsToElementMap _elementMap;
  final OutputUnitData _data;
  final ClosureData _closureDataLookup;

  Set<String> _constants = {};

  OutputUnitIrComputer(
      DiagnosticReporter reporter,
      Map<Id, ActualData<Features>> actualMap,
      this._elementMap,
      this._data,
      this._closureDataLookup)
      : super(reporter, actualMap);

  Features getMemberValue(
      String tag, MemberEntity member, Set<String> constants) {
    Features features = Features();
    features.add(tag,
        value: outputUnitString(_data.outputUnitForMemberForTesting(member)));
    for (var constant in constants) {
      features.addElement(Tags.constants, constant);
    }
    return features;
  }

  @override
  Features computeClassValue(Id id, ir.Class node) {
    var cls = _elementMap.getClass(node);
    Features features = Features();
    features.add(Tags.cls,
        value: outputUnitString(_data.outputUnitForClassForTesting(cls)));
    features.add(Tags.type,
        value: outputUnitString(_data.outputUnitForClassTypeForTesting(cls)));
    return features;
  }

  @override
  Features computeMemberValue(Id id, ir.Member node) {
    if (node is ir.Field && node.isConst) {
      ir.Expression initializer = node.initializer;
      ConstantValue constant = _elementMap.getConstantValue(node, initializer);
      if (!constant.isPrimitive) {
        SourceSpan span = computeSourceSpanFromTreeNode(initializer);
        if (initializer is ir.ConstructorInvocation) {
          // Adjust the source-span to match the AST-based location. The kernel FE
          // skips the "const" keyword for the expression offset and any prefix in
          // front of the constructor. The "-6" is an approximation assuming that
          // there is just a single space after "const" and no prefix.
          // TODO(sigmund): offsets should be fixed in the FE instead.
          span = SourceSpan(span.uri, span.begin - 6, span.end - 6);
        }
        _registerValue(
            NodeId(span.begin, IdKind.node),
            Features.fromMap({
              Tags.member: outputUnitString(
                  _data.outputUnitForConstantForTesting(constant))
            }),
            node,
            span,
            actualMap,
            reporter);
      }
    }

    Features features =
        getMemberValue(Tags.member, _elementMap.getMember(node), _constants);
    _constants = {};
    return features;
  }

  @override
  visitConstantExpression(ir.ConstantExpression node) {
    ConstantValue constant = _elementMap.getConstantValue(null, node);
    if (!constant.isPrimitive) {
      _constants.add('${constant.toStructuredText(_elementMap.types)}='
          '${outputUnitString(_data.outputUnitForConstant(constant))}');
    }
    return super.visitConstantExpression(node);
  }

  @override
  Features computeNodeValue(Id id, ir.TreeNode node) {
    if (node is ir.FunctionExpression || node is ir.FunctionDeclaration) {
      ClosureRepresentationInfo info = _closureDataLookup.getClosureInfo(node);
      return getMemberValue(Tags.closure, info.callMethod, const {});
    }
    return null;
  }
}

/// Set [actualMap] to hold a key of [id] with the computed data [value]
/// corresponding to [object] at location [sourceSpan]. We also perform error
/// checking to ensure that the same [id] isn't added twice.
void _registerValue<T>(Id id, T value, Object object, SourceSpan sourceSpan,
    Map<Id, ActualData<T>> actualMap, CompilerDiagnosticReporter reporter) {
  if (actualMap.containsKey(id)) {
    ActualData<T> existingData = actualMap[id];
    reportHere(reporter, sourceSpan,
        "Duplicate id ${id}, value=$value, object=$object");
    reportHere(
        reporter,
        sourceSpan,
        "Duplicate id ${id}, value=${existingData.value}, "
        "object=${existingData.object}");
    Expect.fail("Duplicate id $id.");
  }
  if (value != null) {
    actualMap[id] =
        ActualData<T>(id, value, sourceSpan.uri, sourceSpan.begin, object);
  }
}
