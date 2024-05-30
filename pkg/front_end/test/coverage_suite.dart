// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert' show jsonEncode;
import 'dart:io'
    show Directory, File, Platform, Process, ProcessResult, exitCode;

import 'package:args/args.dart' show ArgParser;
import 'package:args/src/arg_results.dart';

import '../tool/coverage_merger.dart' as coverageMerger;

bool debug = false;

// This is the state as of 8b8ec2aa3d91a7dc9e61bd7b9e576f82bf2b52c3,
// using out/ReleaseX64/dart-sdk/bin/dart (which for instance makes a
// difference for compute_platform_binaries_location.dart).
const Map<String, double> _expect = {
  "package:front_end/src/api_prototype/compiler_options.dart":
      18.53448275862069,
  "package:front_end/src/api_prototype/experimental_flags.dart":
      81.08108108108108,
  "package:front_end/src/api_prototype/experimental_flags_generated.dart":
      53.605769230769226,
  "package:front_end/src/api_prototype/file_system.dart": 33.33333333333333,
  "package:front_end/src/api_prototype/incremental_kernel_generator.dart":
      6.666666666666667,
  "package:front_end/src/api_prototype/kernel_generator.dart": 0.0,
  "package:front_end/src/api_prototype/language_version.dart": 0.0,
  "package:front_end/src/api_prototype/lowering_predicates.dart":
      3.6036036036036037,
  "package:front_end/src/api_prototype/memory_file_system.dart": 25.0,
  "package:front_end/src/api_prototype/standard_file_system.dart":
      38.46153846153847,
  "package:front_end/src/api_prototype/summary_generator.dart": 0.0,
  "package:front_end/src/api_prototype/terminal_color_support.dart": 0.0,
  "package:front_end/src/api_unstable/compiler_state.dart": 0.0,
  "package:front_end/src/api_unstable/dart2js.dart": 0.0,
  "package:front_end/src/api_unstable/util.dart": 37.03703703703704,
  "package:front_end/src/base/instrumentation.dart": 100.0,
  "package:front_end/src/base/processed_options.dart": 39.0,
  "package:front_end/src/compute_platform_binaries_location.dart":
      64.1025641025641,
  "package:front_end/src/fasta/builder/builder.dart": 63.63636363636363,
  "package:front_end/src/fasta/builder/builder_mixins.dart": 100.0,
  "package:front_end/src/fasta/builder/builtin_type_declaration_builder.dart":
      70.0,
  "package:front_end/src/fasta/builder/class_builder.dart": 71.14427860696517,
  "package:front_end/src/fasta/builder/constructor_reference_builder.dart":
      100.0,
  "package:front_end/src/fasta/builder/declaration_builder.dart": 100.0,
  "package:front_end/src/fasta/builder/dynamic_type_declaration_builder.dart":
      100.0,
  "package:front_end/src/fasta/builder/extension_builder.dart": 50.0,
  "package:front_end/src/fasta/builder/extension_type_declaration_builder.dart":
      100.0,
  "package:front_end/src/fasta/builder/fixed_type_builder.dart":
      22.727272727272727,
  "package:front_end/src/fasta/builder/formal_parameter_builder.dart":
      95.85492227979275,
  "package:front_end/src/fasta/builder/function_type_builder.dart":
      77.95275590551181,
  "package:front_end/src/fasta/builder/future_or_type_declaration_builder.dart":
      0.0,
  "package:front_end/src/fasta/builder/inferable_type_builder.dart": 100.0,
  "package:front_end/src/fasta/builder/invalid_type_builder.dart":
      33.33333333333333,
  "package:front_end/src/fasta/builder/invalid_type_declaration_builder.dart":
      85.0,
  "package:front_end/src/fasta/builder/library_builder.dart": 81.63265306122449,
  "package:front_end/src/fasta/builder/member_builder.dart": 96.75324675324676,
  "package:front_end/src/fasta/builder/metadata_builder.dart":
      86.04651162790698,
  "package:front_end/src/fasta/builder/mixin_application_builder.dart": 100.0,
  "package:front_end/src/fasta/builder/modifier_builder.dart":
      76.47058823529412,
  "package:front_end/src/fasta/builder/named_type_builder.dart":
      74.94949494949495,
  "package:front_end/src/fasta/builder/never_type_declaration_builder.dart":
      76.92307692307693,
  "package:front_end/src/fasta/builder/null_type_declaration_builder.dart":
      33.33333333333333,
  "package:front_end/src/fasta/builder/nullability_builder.dart": 100.0,
  "package:front_end/src/fasta/builder/omitted_type_builder.dart":
      34.146341463414636,
  "package:front_end/src/fasta/builder/omitted_type_declaration_builder.dart":
      0.0,
  "package:front_end/src/fasta/builder/prefix_builder.dart": 89.1891891891892,
  "package:front_end/src/fasta/builder/record_type_builder.dart":
      74.35897435897436,
  "package:front_end/src/fasta/builder/type_alias_builder.dart":
      78.99159663865547,
  "package:front_end/src/fasta/builder/type_builder.dart": 77.77777777777779,
  "package:front_end/src/fasta/builder/type_declaration_builder.dart": 90.0,
  "package:front_end/src/fasta/builder/type_variable_builder.dart":
      78.42227378190255,
  "package:front_end/src/fasta/builder/void_type_declaration_builder.dart":
      100.0,
  "package:front_end/src/fasta/builder_graph.dart": 54.0,
  "package:front_end/src/fasta/codes/fasta_codes_cfe_generated.dart":
      73.0892742453436,
  "package:front_end/src/fasta/codes/type_labeler.dart": 83.68336025848141,
  "package:front_end/src/fasta/combinator.dart": 100.0,
  "package:front_end/src/fasta/command_line_reporting.dart": 68.68686868686868,
  "package:front_end/src/fasta/compiler_context.dart": 90.1639344262295,
  "package:front_end/src/fasta/configuration.dart": 100.0,
  "package:front_end/src/fasta/crash.dart": 57.95454545454546,
  "package:front_end/src/fasta/dill/dill_builder_mixins.dart": 100.0,
  "package:front_end/src/fasta/dill/dill_class_builder.dart": 92.34972677595628,
  "package:front_end/src/fasta/dill/dill_extension_builder.dart":
      86.74698795180723,
  "package:front_end/src/fasta/dill/dill_extension_member_builder.dart":
      70.29702970297029,
  "package:front_end/src/fasta/dill/dill_extension_type_declaration_builder.dart":
      95.42483660130719,
  "package:front_end/src/fasta/dill/dill_extension_type_member_builder.dart":
      83.76623376623377,
  "package:front_end/src/fasta/dill/dill_library_builder.dart": 78.134110787172,
  "package:front_end/src/fasta/dill/dill_loader.dart": 80.0,
  "package:front_end/src/fasta/dill/dill_member_builder.dart":
      86.52173913043478,
  "package:front_end/src/fasta/dill/dill_target.dart": 74.35897435897436,
  "package:front_end/src/fasta/dill/dill_type_alias_builder.dart":
      95.83333333333334,
  "package:front_end/src/fasta/export.dart": 72.22222222222221,
  "package:front_end/src/fasta/hybrid_file_system.dart": 50.0,
  "package:front_end/src/fasta/identifiers.dart": 84.78260869565217,
  "package:front_end/src/fasta/ignored_parser_errors.dart": 100.0,
  "package:front_end/src/fasta/import.dart": 100.0,
  "package:front_end/src/fasta/import_chains.dart": 96.96969696969697,
  "package:front_end/src/fasta/incremental_compiler.dart": 47.0,
  "package:front_end/src/fasta/incremental_serializer.dart": 0.0,
  "package:front_end/src/fasta/kernel/augmentation_lowering.dart": 100.0,
  "package:front_end/src/fasta/kernel/benchmarker.dart": 0.0,
  "package:front_end/src/fasta/kernel/body_builder.dart": 90.0,
  "package:front_end/src/fasta/kernel/body_builder_context.dart":
      68.31501831501832,
  "package:front_end/src/fasta/kernel/collections.dart": 36.44736842105264,
  "package:front_end/src/fasta/kernel/combined_member_signature.dart":
      91.29411764705883,
  "package:front_end/src/fasta/kernel/const_conditional_simplifier.dart": 50.0,
  "package:front_end/src/fasta/kernel/constant_collection_builders.dart": 64.0,
  "package:front_end/src/fasta/kernel/constant_evaluator.dart": 78.0,
  "package:front_end/src/fasta/kernel/constant_int_folder.dart":
      92.04545454545455,
  "package:front_end/src/fasta/kernel/constructor_tearoff_lowering.dart":
      95.11278195488721,
  "package:front_end/src/fasta/kernel/exhaustiveness.dart": 74.57098283931357,
  "package:front_end/src/fasta/kernel/expression_generator.dart": 79.0,
  "package:front_end/src/fasta/kernel/expression_generator_helper.dart": 100.0,
  "package:front_end/src/fasta/kernel/forest.dart": 90.27777777777779,
  "package:front_end/src/fasta/kernel/forwarding_node.dart": 94.4927536231884,
  "package:front_end/src/fasta/kernel/hierarchy/class_member.dart":
      83.1896551724138,
  "package:front_end/src/fasta/kernel/hierarchy/delayed.dart": 100.0,
  "package:front_end/src/fasta/kernel/hierarchy/extension_type_members.dart":
      87.52834467120182,
  "package:front_end/src/fasta/kernel/hierarchy/hierarchy_builder.dart":
      50.256410256410255,
  "package:front_end/src/fasta/kernel/hierarchy/hierarchy_node.dart":
      93.33333333333333,
  "package:front_end/src/fasta/kernel/hierarchy/members_builder.dart":
      98.51851851851852,
  "package:front_end/src/fasta/kernel/hierarchy/members_node.dart":
      91.44427001569859,
  "package:front_end/src/fasta/kernel/hierarchy/mixin_inferrer.dart":
      61.53846153846154,
  "package:front_end/src/fasta/kernel/implicit_field_type.dart":
      52.24719101123596,
  "package:front_end/src/fasta/kernel/implicit_type_argument.dart":
      2.941176470588235,
  "package:front_end/src/fasta/kernel/internal_ast.dart": 46.40625,
  "package:front_end/src/fasta/kernel/invalid_type.dart": 74.13793103448276,
  "package:front_end/src/fasta/kernel/kernel_constants.dart": 45.45454545454545,
  "package:front_end/src/fasta/kernel/kernel_helper.dart": 98.95833333333334,
  "package:front_end/src/fasta/kernel/kernel_target.dart": 78.0,
  "package:front_end/src/fasta/kernel/kernel_variable_builder.dart":
      61.111111111111114,
  "package:front_end/src/fasta/kernel/late_lowering.dart": 100.0,
  "package:front_end/src/fasta/kernel/load_library_builder.dart":
      87.17948717948718,
  "package:front_end/src/fasta/kernel/macro/annotation_parser.dart":
      0.1984126984126984,
  "package:front_end/src/fasta/kernel/macro/identifiers.dart": 0.0,
  "package:front_end/src/fasta/kernel/macro/introspectors.dart": 0.0,
  "package:front_end/src/fasta/kernel/macro/macro.dart": 0.22675736961451248,
  "package:front_end/src/fasta/kernel/macro/offsets.dart": 0.0,
  "package:front_end/src/fasta/kernel/macro/types.dart": 0.0,
  "package:front_end/src/fasta/kernel/member_covariance.dart":
      89.23611111111111,
  "package:front_end/src/fasta/kernel/resource_identifier.dart":
      39.473684210526315,
  "package:front_end/src/fasta/kernel/static_weak_references.dart":
      15.238095238095239,
  "package:front_end/src/fasta/kernel/try_constant_evaluator.dart":
      19.753086419753085,
  "package:front_end/src/fasta/kernel/type_algorithms.dart": 93.4560327198364,
  "package:front_end/src/fasta/kernel/type_builder_computer.dart":
      90.20618556701031,
  "package:front_end/src/fasta/kernel/utils.dart": 37.93103448275862,
  "package:front_end/src/fasta/kernel/verifier.dart": 56.25,
  "package:front_end/src/fasta/library_graph.dart": 79.3103448275862,
  "package:front_end/src/fasta/messages.dart": 30.0,
  "package:front_end/src/fasta/modifier.dart": 100.0,
  "package:front_end/src/fasta/operator.dart": 100.0,
  "package:front_end/src/fasta/problems.dart": 0.0,
  "package:front_end/src/fasta/scope.dart": 79.0,
  "package:front_end/src/fasta/source/class_declaration.dart":
      80.29556650246306,
  "package:front_end/src/fasta/source/diet_listener.dart": 89.0,
  "package:front_end/src/fasta/source/diet_parser.dart": 100.0,
  "package:front_end/src/fasta/source/name_scheme.dart": 93.19148936170212,
  "package:front_end/src/fasta/source/outline_builder.dart": 91.54411764705883,
  "package:front_end/src/fasta/source/redirecting_factory_body.dart":
      94.44444444444444,
  "package:front_end/src/fasta/source/source_builder_mixins.dart":
      88.8268156424581,
  "package:front_end/src/fasta/source/source_class_builder.dart": 85.9375,
  "package:front_end/src/fasta/source/source_constructor_builder.dart":
      92.65658747300216,
  "package:front_end/src/fasta/source/source_enum_builder.dart":
      95.73560767590618,
  "package:front_end/src/fasta/source/source_extension_builder.dart":
      61.261261261261254,
  "package:front_end/src/fasta/source/source_extension_type_declaration_builder.dart":
      85.34136546184739,
  "package:front_end/src/fasta/source/source_factory_builder.dart":
      92.22222222222223,
  "package:front_end/src/fasta/source/source_field_builder.dart":
      89.18507235338919,
  "package:front_end/src/fasta/source/source_function_builder.dart":
      89.29663608562691,
  "package:front_end/src/fasta/source/source_library_builder.dart":
      82.6852338413032,
  "package:front_end/src/fasta/source/source_loader.dart": 79.0,
  "package:front_end/src/fasta/source/source_member_builder.dart":
      40.32258064516129,
  "package:front_end/src/fasta/source/source_procedure_builder.dart":
      96.11829944547135,
  "package:front_end/src/fasta/source/source_type_alias_builder.dart":
      97.63313609467455,
  "package:front_end/src/fasta/source/stack_listener_impl.dart":
      64.44444444444444,
  "package:front_end/src/fasta/ticker.dart": 73.0,
  "package:front_end/src/fasta/type_inference/closure_context.dart":
      84.23236514522821,
  "package:front_end/src/fasta/type_inference/delayed_expressions.dart":
      77.55474452554745,
  "package:front_end/src/fasta/type_inference/external_ast_helper.dart":
      97.88732394366197,
  "package:front_end/src/fasta/type_inference/factor_type.dart":
      76.19047619047619,
  "package:front_end/src/fasta/type_inference/for_in.dart": 75.47169811320755,
  "package:front_end/src/fasta/type_inference/inference_results.dart":
      85.12820512820512,
  "package:front_end/src/fasta/type_inference/inference_visitor.dart":
      90.10645683869475,
  "package:front_end/src/fasta/type_inference/inference_visitor_base.dart":
      83.98997134670488,
  "package:front_end/src/fasta/type_inference/matching_cache.dart":
      80.26509572901325,
  "package:front_end/src/fasta/type_inference/matching_expressions.dart":
      98.10964083175804,
  "package:front_end/src/fasta/type_inference/object_access_target.dart":
      77.19298245614034,
  "package:front_end/src/fasta/type_inference/shared_type_analyzer.dart": 98.0,
  "package:front_end/src/fasta/type_inference/standard_bounds.dart":
      71.42857142857143,
  "package:front_end/src/fasta/type_inference/type_constraint_gatherer.dart":
      60,
  "package:front_end/src/fasta/type_inference/type_demotion.dart":
      77.77777777777779,
  "package:front_end/src/fasta/type_inference/type_inference_engine.dart":
      86.76975945017182,
  "package:front_end/src/fasta/type_inference/type_inferrer.dart":
      51.17647058823529,
  "package:front_end/src/fasta/type_inference/type_schema.dart":
      36.666666666666664,
  "package:front_end/src/fasta/type_inference/type_schema_elimination.dart":
      88.88888888888889,
  "package:front_end/src/fasta/type_inference/type_schema_environment.dart":
      79.50530035335689,
  "package:front_end/src/fasta/uri_offset.dart": 100.0,
  "package:front_end/src/fasta/uri_translator.dart": 75.92592592592592,
  "package:front_end/src/fasta/uris.dart": 100.0,
  "package:front_end/src/fasta/util/error_reporter_file_copier.dart": 0.0,
  "package:front_end/src/fasta/util/experiment_environment_getter.dart":
      85.71428571428571,
  "package:front_end/src/fasta/util/helpers.dart": 52.63157894736842,
  "package:front_end/src/fasta/util/parser_ast.dart": 5.567451820128479,
  "package:front_end/src/fasta/util/parser_ast_helper.dart": 20.424013434089,
  "package:front_end/src/fasta/util/textual_outline.dart": 86.54205607476636,
  "package:front_end/src/kernel_generator_impl.dart": 0.5376344086021506,
  "package:front_end/src/macros/isolate_macro_serializer.dart": 0.0,
  "package:front_end/src/macros/macro_serializer.dart": 0.0,
  "package:front_end/src/macros/macro_target.dart": 0.0,
  "package:front_end/src/macros/macro_target_io.dart": 0.0,
  "package:front_end/src/macros/temp_dir_macro_serializer.dart": 0.0,
};

Future<void> main([List<String> arguments = const <String>[]]) async {
  Directory coverageTmpDir =
      Directory.systemTemp.createTempSync("cfe_coverage");
  try {
    await _run(coverageTmpDir, arguments);
  } finally {
    if (debug) {
      print("Data available in $coverageTmpDir");
    } else {
      coverageTmpDir.deleteSync(recursive: true);
    }
  }
}

Future<void> _run(Directory coverageTmpDir, List<String> arguments) async {
  Stopwatch totalRuntime = new Stopwatch()..start();

  List<String> results = [];
  List<String> logs = [];
  Options options = Options.parse(arguments);
  debug = options.debug;
  List<Future<ProcessResult>> futures = [];

  if (options.verbose) {
    print("NOTE: Will run with ${options.numberOfWorkers} shards.");
    print("");
  }

  print("Note: Has ${Platform.numberOfProcessors} cores.");

  for (int i = 0; i < options.numberOfWorkers; i++) {
    print("Starting shard ${i + 1} of ${options.numberOfWorkers}");
    futures.add(Process.run(Platform.resolvedExecutable, [
      "--enable-asserts",
      "pkg/front_end/test/fasta/strong_suite.dart",
      "-DskipVm=true",
      "--shards=${options.numberOfWorkers}",
      "--shard=${i + 1}",
      "--coverage=${coverageTmpDir.path}/",
    ]));
  }

  // Wait for isolates to terminate and clean up.
  Iterable<ProcessResult> runResults = await Future.wait(futures);

  print("Run finished.");

  Map<Uri, coverageMerger.CoverageInfo>? coverageData =
      coverageMerger.mergeFromDirUri(
    Uri.base.resolve(".dart_tool/package_config.json"),
    coverageTmpDir.uri,
    silent: true,
  );
  if (coverageData == null) throw "Failure in coverage.";

  void addResult(String testName, bool pass, {String? log}) {
    results.add(jsonEncode({
      "name": "coverage/$testName",
      "configuration": options.configurationName,
      "suite": "coverage",
      "test_name": testName,
      "expected": "Pass",
      "result": pass ? "Pass" : "Fail",
      "matches": pass,
    }));

    if (log != null) {
      logs.add(jsonEncode({
        "name": "coverage/$testName",
        "configuration": options.configurationName,
        "suite": "coverage",
        "test_name": testName,
        "result": pass ? "Pass" : "Fail",
        "log": log,
      }));
    }

    if (options.verbose) {
      String result = pass ? "PASS" : "FAIL";
      print("${testName}: ${result}");
    }
  }

  for (MapEntry<Uri, coverageMerger.CoverageInfo> coverageEntry
      in coverageData.entries) {
    if (coverageEntry.value.error) {
      // TODO(jensj): More info here would be good.
      addResult(coverageEntry.key.toString(), false, log: "Error");
    } else {
      int hitCount = coverageEntry.value.hitCount;
      int missCount = coverageEntry.value.missCount;
      double percent = (hitCount / (hitCount + missCount) * 100);
      if (debug) {
        print("\"${coverageEntry.key}\": $percent,");
      }
      int requireAtLeast =
          (_expect[coverageEntry.key.toString()] ?? 0.0).floor();
      bool pass = percent >= requireAtLeast;
      String? log;
      if (!pass) {
        log = "${coverageEntry.value.visualization}\n\n"
            "Expected at least $requireAtLeast%, got $percent% "
            "($hitCount hits and $missCount misses).";
      }
      addResult(coverageEntry.key.toString(), pass, log: log);
    }
  }

  // Write results.json and logs.json.
  Uri resultJsonUri = options.outputDirectory.resolve("results.json");
  Uri logsJsonUri = options.outputDirectory.resolve("logs.json");
  await writeLinesToFile(resultJsonUri, results);
  await writeLinesToFile(logsJsonUri, logs);
  print("Log files written to ${resultJsonUri.toFilePath()} and"
      " ${logsJsonUri.toFilePath()}");
  print("Entire run took ${totalRuntime.elapsed}.");

  bool timedOutOrCrashed = runResults.any((p) => p.exitCode != 0);
  if (timedOutOrCrashed) {
    print("Warning: At least one processes exited with a non-0 exit code.");
  }

  // Always return 0 or the try bot will become purple.
  exitCode = 0;
}

int getDefaultThreads() {
  int numberOfWorkers = 1;
  if (Platform.numberOfProcessors > 2) {
    numberOfWorkers = Platform.numberOfProcessors - 1;
  }
  if (numberOfWorkers > 5) numberOfWorkers = 5;
  return numberOfWorkers;
}

Future<void> writeLinesToFile(Uri uri, List<String> lines) async {
  await File.fromUri(uri).writeAsString(lines.map((line) => "$line\n").join());
}

class Options {
  final String? configurationName;
  final bool verbose;
  final bool debug;
  final Uri outputDirectory;
  final int numberOfWorkers;

  Options(
    this.configurationName,
    this.verbose,
    this.debug,
    this.outputDirectory, {
    required this.numberOfWorkers,
  });

  static Options parse(List<String> args) {
    var parser = new ArgParser()
      ..addOption("named-configuration",
          abbr: "n",
          help: "configuration name to use for emitting json result files")
      ..addOption("output-directory",
          help: "directory to which results.json and logs.json are written")
      ..addFlag("verbose",
          abbr: "v", help: "print additional information", defaultsTo: false)
      ..addFlag("debug", help: "debug mode", defaultsTo: false)
      ..addOption("tasks",
          abbr: "j",
          help: "The number of parallel tasks to run.",
          defaultsTo: "${getDefaultThreads()}")
      // These are not used but are here for compatibility with the test system.
      ..addOption("shards", help: "(Ignored) Number of shards", defaultsTo: "1")
      ..addOption("shard",
          help: "(Ignored) Which shard to run", defaultsTo: "1");
    ArgResults parsedOptions = parser.parse(args);
    String outputPath = parsedOptions["output-directory"] ?? ".";
    Uri outputDirectory = Uri.base.resolveUri(Uri.directory(outputPath));

    bool verbose = parsedOptions["verbose"];
    bool debug = parsedOptions["debug"];

    String tasksString = parsedOptions["tasks"];
    int? tasks = int.tryParse(tasksString);
    if (tasks == null || tasks < 1) {
      throw "--tasks (-j) has to be an integer >= 1";
    }

    if (verbose) {
      print("NOTE: Created with options\n  "
          "named config = ${parsedOptions["named-configuration"]},\n  "
          "verbose = ${verbose},\n  "
          "debug = ${debug},\n  "
          "${outputDirectory},\n  "
          "numberOfWorkers: ${tasks}");
    }

    return Options(
      parsedOptions["named-configuration"],
      verbose,
      debug,
      outputDirectory,
      numberOfWorkers: tasks,
    );
  }
}
