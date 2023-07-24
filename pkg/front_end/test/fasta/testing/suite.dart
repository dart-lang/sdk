// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE.md file.

library fasta.testing.suite;

import 'dart:convert' show jsonDecode, utf8;
import 'dart:io' show Directory, File, Platform;
import 'dart:typed_data' show Uint8List;

import 'package:_fe_analyzer_shared/src/scanner/token.dart'
    show LanguageVersionToken, Token;
import 'package:_fe_analyzer_shared/src/util/colors.dart' as colors;
import 'package:_fe_analyzer_shared/src/util/libraries_specification.dart'
    show LibraryInfo;
import 'package:_fe_analyzer_shared/src/util/options.dart';
import 'package:compiler/src/kernel/dart2js_target.dart';
import 'package:compiler/src/options.dart' as dart2jsOptions
    show CompilerOptions;
import 'package:dart2wasm/target.dart';
import 'package:dev_compiler/src/kernel/target.dart';
import 'package:front_end/src/api_prototype/compiler_options.dart'
    show
        CompilerOptions,
        DiagnosticMessage,
        parseExperimentalArguments,
        parseExperimentalFlags;
import 'package:front_end/src/api_prototype/constant_evaluator.dart'
    show ConstantEvaluator, ErrorReporter, EvaluationMode;
import 'package:front_end/src/api_prototype/experimental_flags.dart'
    show
        AllowedExperimentalFlags,
        ExperimentalFlag,
        defaultAllowedExperimentalFlags,
        isExperimentEnabled;
import 'package:front_end/src/api_prototype/file_system.dart'
    show FileSystem, FileSystemEntity, FileSystemException;
import 'package:front_end/src/api_prototype/incremental_kernel_generator.dart'
    show IncrementalCompilerResult;
import 'package:front_end/src/api_prototype/standard_file_system.dart'
    show StandardFileSystem;
import 'package:front_end/src/base/command_line_options.dart';
import 'package:front_end/src/base/nnbd_mode.dart' show NnbdMode;
import 'package:front_end/src/base/processed_options.dart'
    show ProcessedOptions;
import 'package:front_end/src/compute_platform_binaries_location.dart'
    show computePlatformBinariesLocation, computePlatformDillName;
import 'package:front_end/src/fasta/builder/library_builder.dart'
    show LibraryBuilder;
import 'package:front_end/src/fasta/compiler_context.dart' show CompilerContext;
import 'package:front_end/src/fasta/crash.dart';
import 'package:front_end/src/fasta/dill/dill_target.dart' show DillTarget;
import 'package:front_end/src/fasta/incremental_compiler.dart'
    show IncrementalCompiler;
import 'package:front_end/src/fasta/kernel/hierarchy/hierarchy_builder.dart'
    show ClassHierarchyBuilder;
import 'package:front_end/src/fasta/kernel/hierarchy/hierarchy_node.dart'
    show ClassHierarchyNode;
import 'package:front_end/src/fasta/kernel/kernel_target.dart'
    show BuildResult, KernelTarget;
import 'package:front_end/src/fasta/kernel/utils.dart' show ByteSink;
import 'package:front_end/src/fasta/kernel/verifier.dart' show verifyComponent;
import 'package:front_end/src/fasta/messages.dart' show LocatedMessage;
import 'package:front_end/src/fasta/ticker.dart' show Ticker;
import 'package:front_end/src/fasta/uri_translator.dart' show UriTranslator;
import 'package:front_end/src/fasta/util/parser_ast.dart'
    show ParserAstVisitor, getAST;
import 'package:front_end/src/fasta/util/parser_ast_helper.dart';
import 'package:kernel/ast.dart'
    show
        BasicLiteral,
        Class,
        Component,
        Constant,
        ConstantExpression,
        Expression,
        FileUriExpression,
        FileUriNode,
        InstanceInvocation,
        InstanceSet,
        InvalidExpression,
        Library,
        LibraryPart,
        Member,
        Node,
        NonNullableByDefaultCompiledMode,
        Reference,
        TreeNode,
        UnevaluatedConstant,
        VariableDeclaration,
        Version;
import 'package:kernel/binary/ast_to_binary.dart' show BinaryPrinter;
import 'package:kernel/class_hierarchy.dart' show ClassHierarchy;
import 'package:kernel/core_types.dart' show CoreTypes;
import 'package:kernel/kernel.dart'
    show RecursiveResultVisitor, loadComponentFromBytes;
import 'package:kernel/reference_from_index.dart' show ReferenceFromIndex;

import 'package:kernel/src/equivalence.dart'
    show
        EquivalenceResult,
        EquivalenceStrategy,
        EquivalenceVisitor,
        ReferenceName,
        checkEquivalence;

import 'package:kernel/target/changed_structure_notifier.dart'
    show ChangedStructureNotifier;
import 'package:kernel/target/targets.dart'
    show
        DiagnosticReporter,
        NoneConstantsBackend,
        NoneTarget,
        NumberSemantics,
        Target,
        TestTargetFlags,
        TestTargetMixin,
        TestTargetWrapper;

import 'package:kernel/type_environment.dart'
    show StaticTypeContext, TypeEnvironment;
import 'package:kernel/verifier.dart' show VerificationStage;
import 'package:testing/testing.dart'
    show
        Chain,
        ChainContext,
        Expectation,
        ExpectationSet,
        Result,
        Step,
        TestDescription,
        StdioProcess;
import 'package:vm/target/vm.dart' show VmTarget;

import '../../incremental_suite.dart' show TestRecorderForTesting;

import '../../testing_utils.dart' show checkEnvironment;
import '../../utils/kernel_chain.dart'
    show
        ComponentResult,
        MatchContext,
        MatchExpectation,
        Print,
        TypeCheck,
        WriteDill;
import '../../utils/validating_instrumentation.dart'
    show ValidatingInstrumentation;

export 'package:testing/testing.dart' show Chain, runMe;

const String COMPILATION_MODE = " compilation mode ";

const String UPDATE_EXPECTATIONS = "updateExpectations";
const String UPDATE_COMMENTS = "updateComments";

const String EXPECTATIONS = '''
[
  {
    "name": "ExpectationFileMismatch",
    "group": "Fail"
  },
  {
    "name": "ExpectationFileMismatchSerialized",
    "group": "Fail"
  },
  {
    "name": "ExpectationFileMissing",
    "group": "Fail"
  },
  {
    "name": "InstrumentationMismatch",
    "group": "Fail"
  },
  {
    "name": "TypeCheckError",
    "group": "Fail"
  },
  {
    "name": "VerificationError",
    "group": "Fail"
  },
  {
    "name": "TransformVerificationError",
    "group": "Fail"
  },
  {
    "name": "TextSerializationFailure",
    "group": "Fail"
  },
  {
    "name": "SemiFuzzFailure",
    "group": "Fail"
  },
  {
    "name": "semiFuzzFailureOnForceRebuildBodies",
    "group": "Fail"
  },
  {
    "name": "SemiFuzzCrash",
    "group": "Fail"
  }
]
''';

final Expectation runtimeError =
    ExpectationSet.defaultExpectations["RuntimeError"];

const String experimentalFlagOptions = '--enable-experiment=';
const Option<String?> overwriteCurrentSdkVersion =
    const Option('--overwrite-current-sdk-version', const StringValue());
const Option<bool> noVerifyCmd =
    const Option('--no-verify', const BoolValue(false));

const List<Option> folderOptionsSpecification = [
  Options.enableExperiment,
  Options.enableUnscheduledExperiments,
  Options.forceLateLoweringSentinel,
  overwriteCurrentSdkVersion,
  Options.forceLateLowering,
  Options.forceStaticFieldLowering,
  Options.forceNoExplicitGetterCalls,
  Options.forceConstructorTearOffLowering,
  Options.nnbdAgnosticMode,
  Options.noDefines,
  noVerifyCmd,
  Options.target,
  Options.defines,
  Options.showOffsets,
];

const Option<bool> fixNnbdReleaseVersion =
    const Option('--fix-nnbd-release-version', const BoolValue(false));

const List<Option> testOptionsSpecification = [
  Options.nnbdAgnosticMode,
  Options.nnbdStrongMode,
  Options.nnbdWeakMode,
  fixNnbdReleaseVersion,
];

final ExpectationSet staticExpectationSet =
    new ExpectationSet.fromJsonList(jsonDecode(EXPECTATIONS));
final Expectation semiFuzzFailure = staticExpectationSet["SemiFuzzFailure"];
final Expectation semiFuzzFailureOnForceRebuildBodies =
    staticExpectationSet["semiFuzzFailureOnForceRebuildBodies"];
final Expectation semiFuzzCrash = staticExpectationSet["SemiFuzzCrash"];

/// Options used for all tests within a given folder.
///
/// This is used for instance for defining target, mode, and experiment specific
/// test folders.
class FolderOptions {
  final Map<ExperimentalFlag, bool> _explicitExperimentalFlags;
  final bool? enableUnscheduledExperiments;
  final int? forceLateLowerings;
  final bool? forceLateLoweringSentinel;
  final bool? forceStaticFieldLowering;
  final bool? forceNoExplicitGetterCalls;
  final int? forceConstructorTearOffLowering;
  final bool nnbdAgnosticMode;
  final Map<String, String>? defines;
  final bool noVerify;
  final String target;
  final String? overwriteCurrentSdkVersion;
  final bool showOffsets;

  FolderOptions(this._explicitExperimentalFlags,
      {this.enableUnscheduledExperiments,
      this.forceLateLowerings,
      this.forceLateLoweringSentinel,
      this.forceStaticFieldLowering,
      this.forceNoExplicitGetterCalls,
      this.forceConstructorTearOffLowering,
      this.nnbdAgnosticMode = false,
      this.defines = const {},
      this.noVerify = false,
      this.target = "vm",
      // can be null
      this.overwriteCurrentSdkVersion,
      this.showOffsets = false})
      : assert(
            // no this doesn't make any sense but left to underline
            // that this is allowed to be null!
            defines != null || defines == null);

  Map<ExperimentalFlag, bool> computeExplicitExperimentalFlags(
      Map<ExperimentalFlag, bool> forcedExperimentalFlags) {
    Map<ExperimentalFlag, bool> flags = {};
    flags.addAll(_explicitExperimentalFlags);
    flags.addAll(forcedExperimentalFlags);
    return flags;
  }
}

/// Options for a single test located within its own subfolder.
///
/// This is used for instance for defining custom link dependencies and
/// setting up custom experimental flag defaults for a single test.
class TestOptions {
  final Set<Uri> linkDependencies;
  final NnbdMode? nnbdMode;
  final AllowedExperimentalFlags? allowedExperimentalFlags;
  final Map<ExperimentalFlag, Version>? experimentEnabledVersion;
  final Map<ExperimentalFlag, Version>? experimentReleasedVersion;
  Component? component;
  List<Iterable<String>>? errors;

  TestOptions(this.linkDependencies,
      {required this.nnbdMode,
      required this.allowedExperimentalFlags,
      required this.experimentEnabledVersion,
      required this.experimentReleasedVersion});
}

class FastaContext extends ChainContext with MatchContext {
  final Uri baseUri;
  @override
  final List<Step> steps;
  final Uri vm;
  final bool onlyCrashes;
  final Map<ExperimentalFlag, bool> explicitExperimentalFlags;
  final bool skipVm;
  final bool semiFuzz;
  final bool verify;
  final bool soundNullSafety;
  final Uri platformBinaries;
  final Map<UriConfiguration, UriTranslator> _uriTranslators = {};
  final Map<Uri, FolderOptions> _folderOptions = {};
  final Map<Uri, TestOptions> _testOptions = {};
  final Map<Uri, Uri?> _librariesJson = {};

  @override
  final bool updateExpectations;

  @override
  String get updateExpectationsOption => '${UPDATE_EXPECTATIONS}=true';

  @override
  bool get canBeFixWithUpdateExpectations => true;

  @override
  final ExpectationSet expectationSet = staticExpectationSet;

  Map<Uri, Component> _platforms = {};

  FastaContext(
      this.baseUri,
      this.vm,
      this.platformBinaries,
      this.onlyCrashes,
      this.explicitExperimentalFlags,
      bool ignoreExpectations,
      this.updateExpectations,
      bool updateComments,
      this.skipVm,
      this.semiFuzz,
      CompileMode compileMode,
      this.verify,
      this.soundNullSafety)
      : steps = <Step>[
          new Outline(compileMode, updateComments: updateComments),
          const Print(),
          new Verify(compileMode == CompileMode.full
              ? VerificationStage.afterConstantEvaluation
              : VerificationStage.outline)
        ] {
    String prefix;
    String infix;
    if (soundNullSafety) {
      prefix = '.strong';
    } else {
      prefix = '.weak';
    }
    switch (compileMode) {
      case CompileMode.outline:
        infix = '.outline';
        break;
      case CompileMode.modular:
        infix = '.modular';
        break;
      case CompileMode.full:
        infix = '';
        break;
    }

    if (compileMode == CompileMode.outline) {
      // If doing an outline compile, this is the only expect file so we run the
      // extra constant evaluation now. If we do a full or modular compilation,
      // we'll do if after the transformation. That also ensures we don't get
      // the same 'extra constant evaluation' output twice (in .transformed and
      // not).
      steps.add(const StressConstantEvaluatorStep());
    }
    if (!ignoreExpectations) {
      steps.add(new MatchExpectation("$prefix$infix.expect",
          serializeFirst: false, isLastMatchStep: false));
      steps.add(new MatchExpectation("$prefix$infix.expect",
          serializeFirst: true, isLastMatchStep: true));
    }
    steps.add(const TypeCheck());
    steps.add(const EnsureNoErrors());
    switch (compileMode) {
      case CompileMode.full:
        steps.add(const Transform());
        steps.add(const Verify(VerificationStage.afterModularTransformations));
        steps.add(const StressConstantEvaluatorStep());
        if (!ignoreExpectations) {
          steps.add(new MatchExpectation("$prefix$infix.transformed.expect",
              serializeFirst: false, isLastMatchStep: updateExpectations));
          if (!updateExpectations) {
            steps.add(new MatchExpectation("$prefix$infix.transformed.expect",
                serializeFirst: true, isLastMatchStep: true));
          }
        }
        steps.add(const EnsureNoErrors());
        steps.add(new WriteDill(skipVm: skipVm));
        if (semiFuzz) {
          steps.add(const FuzzCompiles());
        }

        // Notice: The below steps will run async, i.e. the next test will run
        // intertwined with this/these step(s). That for instance means that they
        // should not touch any ASTs!
        if (!skipVm) {
          steps.add(const Run());
        }
        break;
      case CompileMode.modular:
      case CompileMode.outline:
        steps.add(new WriteDill(skipVm: true));
        break;
    }
  }

  FolderOptions _computeFolderOptions(Directory directory) {
    FolderOptions? folderOptions = _folderOptions[directory.uri];
    if (folderOptions == null) {
      bool? enableUnscheduledExperiments;
      int? forceLateLowering;
      bool? forceLateLoweringSentinel;
      bool? forceStaticFieldLowering;
      bool? forceNoExplicitGetterCalls;
      int? forceConstructorTearOffLowering;
      bool nnbdAgnosticMode = false;
      bool noVerify = false;
      Map<String, String>? defines = {};
      String target = "vm";
      bool showOffsets = false;
      if (directory.uri == baseUri) {
        folderOptions = new FolderOptions({},
            enableUnscheduledExperiments: enableUnscheduledExperiments,
            forceLateLowerings: forceLateLowering,
            forceLateLoweringSentinel: forceLateLoweringSentinel,
            forceStaticFieldLowering: forceStaticFieldLowering,
            forceNoExplicitGetterCalls: forceNoExplicitGetterCalls,
            forceConstructorTearOffLowering: forceConstructorTearOffLowering,
            nnbdAgnosticMode: nnbdAgnosticMode,
            defines: defines,
            noVerify: noVerify,
            target: target,
            showOffsets: showOffsets);
      } else {
        File optionsFile =
            new File.fromUri(directory.uri.resolve('folder.options'));
        if (optionsFile.existsSync()) {
          List<String> arguments =
              ParsedOptions.readOptionsFile(optionsFile.readAsStringSync());
          ParsedOptions parsedOptions =
              ParsedOptions.parse(arguments, folderOptionsSpecification);
          List<String> experimentalFlagsArguments =
              Options.enableExperiment.read(parsedOptions) ?? <String>[];
          String? overwriteCurrentSdkVersionArgument =
              overwriteCurrentSdkVersion.read(parsedOptions);
          enableUnscheduledExperiments =
              Options.enableUnscheduledExperiments.read(parsedOptions);
          forceLateLoweringSentinel =
              Options.forceLateLoweringSentinel.read(parsedOptions);
          forceLateLowering = Options.forceLateLowering.read(parsedOptions);
          forceStaticFieldLowering =
              Options.forceStaticFieldLowering.read(parsedOptions);
          forceNoExplicitGetterCalls =
              Options.forceNoExplicitGetterCalls.read(parsedOptions);
          forceConstructorTearOffLowering =
              Options.forceConstructorTearOffLowering.read(parsedOptions);
          nnbdAgnosticMode = Options.nnbdAgnosticMode.read(parsedOptions);
          defines = parsedOptions.defines;
          showOffsets = Options.showOffsets.read(parsedOptions);
          if (Options.noDefines.read(parsedOptions)) {
            if (defines.isNotEmpty) {
              throw "Can't have no defines and specific defines "
                  "at the same time.";
            }
            defines = null;
          }
          noVerify = noVerifyCmd.read(parsedOptions);
          target = Options.target.read(parsedOptions);
          folderOptions = new FolderOptions(
              parseExperimentalFlags(
                  parseExperimentalArguments(experimentalFlagsArguments),
                  onError: (String message) => throw new ArgumentError(message),
                  onWarning: (String message) =>
                      throw new ArgumentError(message)),
              enableUnscheduledExperiments: enableUnscheduledExperiments,
              forceLateLowerings: forceLateLowering,
              forceLateLoweringSentinel: forceLateLoweringSentinel,
              forceStaticFieldLowering: forceStaticFieldLowering,
              forceNoExplicitGetterCalls: forceNoExplicitGetterCalls,
              forceConstructorTearOffLowering: forceConstructorTearOffLowering,
              nnbdAgnosticMode: nnbdAgnosticMode,
              defines: defines,
              noVerify: noVerify,
              target: target,
              overwriteCurrentSdkVersion: overwriteCurrentSdkVersionArgument,
              showOffsets: showOffsets);
        } else {
          folderOptions = _computeFolderOptions(directory.parent);
        }
      }
      _folderOptions[directory.uri] = folderOptions;
    }
    return folderOptions;
  }

  /// Computes the experimental flag for [description].
  ///
  /// [forcedExperimentalFlags] is used to override the default flags for
  /// [description].
  FolderOptions computeFolderOptions(TestDescription description) {
    Directory directory = new File.fromUri(description.uri).parent;
    return _computeFolderOptions(directory);
  }

  Future<UriTranslator> computeUriTranslator(
      TestDescription description) async {
    UriConfiguration uriConfiguration = computeUriConfiguration(description);
    UriTranslator? uriTranslator = _uriTranslators[uriConfiguration];
    if (uriTranslator == null) {
      Uri sdk = Uri.base.resolve("sdk/");
      Uri packages = Uri.base.resolve(".dart_tool/package_config.json");
      FolderOptions folderOptions = computeFolderOptions(description);
      CompilerOptions compilerOptions = new CompilerOptions()
        ..onDiagnostic = (DiagnosticMessage message) {
          throw message.plainTextFormatted.join("\n");
        }
        ..sdkRoot = sdk
        ..packagesFileUri = uriConfiguration.packageConfigUri ?? packages
        ..enableUnscheduledExperiments =
            folderOptions.enableUnscheduledExperiments ?? false
        ..environmentDefines = folderOptions.defines
        ..explicitExperimentalFlags = folderOptions
            .computeExplicitExperimentalFlags(explicitExperimentalFlags)
        ..nnbdMode = soundNullSafety
            ? (folderOptions.nnbdAgnosticMode
                ? NnbdMode.Agnostic
                : NnbdMode.Strong)
            : NnbdMode.Weak
        ..librariesSpecificationUri =
            uriConfiguration.librariesSpecificationUri;
      if (folderOptions.overwriteCurrentSdkVersion != null) {
        compilerOptions.currentSdkVersion =
            folderOptions.overwriteCurrentSdkVersion!;
      }
      ProcessedOptions options = new ProcessedOptions(options: compilerOptions);
      uriTranslator = await options.getUriTranslator();
      _uriTranslators[uriConfiguration] = uriTranslator;
    }
    return uriTranslator;
  }

  /// Computes the test for [description].
  TestOptions computeTestOptions(TestDescription description) {
    Directory directory = new File.fromUri(description.uri).parent;
    TestOptions? testOptions = _testOptions[directory.uri];
    if (testOptions == null) {
      File optionsFile =
          new File.fromUri(directory.uri.resolve('test.options'));
      Set<Uri> linkDependencies = new Set<Uri>();
      NnbdMode? nnbdMode;
      AllowedExperimentalFlags? allowedExperimentalFlags;
      Map<ExperimentalFlag, Version>? experimentEnabledVersion;
      Map<ExperimentalFlag, Version>? experimentReleasedVersion;
      if (optionsFile.existsSync()) {
        List<String> arguments =
            ParsedOptions.readOptionsFile(optionsFile.readAsStringSync());
        ParsedOptions parsedOptions =
            ParsedOptions.parse(arguments, testOptionsSpecification);
        if (Options.nnbdAgnosticMode.read(parsedOptions)) {
          nnbdMode = NnbdMode.Agnostic;
        }
        if (Options.nnbdStrongMode.read(parsedOptions)) {
          if (nnbdMode != null) {
            throw new UnsupportedError(
                'Nnbd mode $nnbdMode already specified.');
          }
          nnbdMode = NnbdMode.Strong;
        }
        if (Options.nnbdWeakMode.read(parsedOptions)) {
          if (nnbdMode != null) {
            throw new UnsupportedError(
                'Nnbd mode $nnbdMode already specified.');
          }
          nnbdMode = NnbdMode.Weak;
        }
        if (fixNnbdReleaseVersion.read(parsedOptions)) {
          // Allow package:allowed_package to use nnbd features from version
          // 2.9.
          allowedExperimentalFlags = new AllowedExperimentalFlags(
              sdkDefaultExperiments:
                  defaultAllowedExperimentalFlags.sdkDefaultExperiments,
              sdkLibraryExperiments:
                  defaultAllowedExperimentalFlags.sdkLibraryExperiments,
              packageExperiments: {
                ...defaultAllowedExperimentalFlags.packageExperiments,
                'allowed_package': {ExperimentalFlag.nonNullable}
              });
          experimentEnabledVersion = const {
            ExperimentalFlag.nonNullable: const Version(2, 10)
          };
          experimentReleasedVersion = const {
            ExperimentalFlag.nonNullable: const Version(2, 9)
          };
        }
        for (String argument in parsedOptions.arguments) {
          Uri uri = description.uri.resolve(argument);
          if (!uri.isScheme('package')) {
            File f = new File.fromUri(uri);
            if (!f.existsSync()) {
              throw new UnsupportedError("No file found: $f ($argument)");
            }
            uri = f.uri;
          }
          linkDependencies.add(uri);
        }
      }
      testOptions = new TestOptions(linkDependencies,
          nnbdMode: nnbdMode,
          allowedExperimentalFlags: allowedExperimentalFlags,
          experimentEnabledVersion: experimentEnabledVersion,
          experimentReleasedVersion: experimentReleasedVersion);
      _testOptions[directory.uri] = testOptions;
    }
    return testOptions;
  }

  /// Libraries json for [description].
  Uri? computeLibrariesSpecificationUri(TestDescription description) {
    Directory directory = new File.fromUri(description.uri).parent;
    if (_librariesJson.containsKey(directory.uri)) {
      return _librariesJson[directory.uri];
    } else {
      Uri? librariesJson;
      File jsonFile = new File.fromUri(directory.uri.resolve('libraries.json'));
      if (jsonFile.existsSync()) {
        librariesJson = jsonFile.uri;
      }
      return _librariesJson[directory.uri] = librariesJson;
    }
  }

  /// Custom package config used for [description].
  Uri? computePackageConfigUri(TestDescription description) {
    Uri packageConfig =
        description.uri.resolve(".dart_tool/package_config.json");
    return new File.fromUri(packageConfig).existsSync() ? packageConfig : null;
  }

  UriConfiguration computeUriConfiguration(TestDescription description) {
    Uri? librariesSpecificationUri =
        computeLibrariesSpecificationUri(description);
    Uri? packageConfigUri = computePackageConfigUri(description);
    return new UriConfiguration(librariesSpecificationUri, packageConfigUri);
  }

  Expectation get verificationError => expectationSet["VerificationError"];

  Uri _getPlatformUri(Target target, NnbdMode nnbdMode) {
    String fileName = computePlatformDillName(
        target,
        nnbdMode,
        () => throw new UnsupportedError(
            "No platform dill for target '${target.name}' with $nnbdMode."))!;
    return platformBinaries.resolve(fileName);
  }

  Component loadPlatform(Target target, NnbdMode nnbdMode) {
    Uri uri = _getPlatformUri(target, nnbdMode);
    return _platforms.putIfAbsent(uri, () {
      return loadComponentFromBytes(new File.fromUri(uri).readAsBytesSync());
    });
  }

  void clearPlatformCache(Target target, NnbdMode nnbdMode) {
    Uri uri = _getPlatformUri(target, nnbdMode);
    _platforms.remove(uri);
  }

  @override
  Result processTestResult(
      TestDescription description, Result result, bool last) {
    if (onlyCrashes) {
      Expectation outcome = result.outcome;
      if (outcome == Expectation.crash || outcome == verificationError) {
        return result;
      }
      return result.copyWithOutcome(Expectation.pass);
    }
    return super.processTestResult(description, result, last);
  }

  @override
  Set<Expectation> processExpectedOutcomes(
      Set<Expectation> outcomes, TestDescription description) {
    // Remove outcomes related to phases not currently in effect.

    Set<Expectation>? result;

    // If skipping VM we can't get a runtime error.
    if (skipVm && outcomes.contains(runtimeError)) {
      result ??= new Set.from(outcomes);
      result.remove(runtimeError);
    }

    // If not semi-fuzzing we can't get semi-fuzz errors.
    if (!semiFuzz &&
        (outcomes.contains(semiFuzzFailure) ||
            outcomes.contains(semiFuzzFailureOnForceRebuildBodies) ||
            outcomes.contains(semiFuzzCrash))) {
      result ??= new Set.from(outcomes);
      result.remove(semiFuzzFailure);
      result.remove(semiFuzzFailureOnForceRebuildBodies);
      result.remove(semiFuzzCrash);
    }

    // Fast-path: no changes made.
    if (result == null) return outcomes;

    // Changes made: No expectations left. This happens when all expected
    // outcomes are removed above.
    // We have to put in the implicit assumption that it will pass then.
    if (result.isEmpty) return {Expectation.pass};

    // Changes made with at least one expectation left. That's out result!
    return result;
  }

  static Future<FastaContext> create(
      Chain suite, Map<String, String> environment) {
    const Set<String> knownEnvironmentKeys = {
      "enableExtensionMethods",
      "enableNonNullable",
      "soundNullSafety",
      "onlyCrashes",
      "ignoreExpectations",
      UPDATE_EXPECTATIONS,
      UPDATE_COMMENTS,
      "skipVm",
      "semiFuzz",
      "verify",
      "platformBinaries",
      COMPILATION_MODE,
    };
    checkEnvironment(environment, knownEnvironmentKeys);

    String resolvedExecutable = Platform.environment['resolvedExecutable'] ??
        Platform.resolvedExecutable;
    Uri vm = Uri.base.resolveUri(new Uri.file(resolvedExecutable));
    Map<ExperimentalFlag, bool> experimentalFlags = <ExperimentalFlag, bool>{
      // Force enable features in development.
      ExperimentalFlag.records: true,
      ExperimentalFlag.patterns: true,
      ExperimentalFlag.sealedClass: true,
    };

    void addForcedExperimentalFlag(String name, ExperimentalFlag flag) {
      if (environment.containsKey(name)) {
        experimentalFlags[flag] = environment[name] == "true";
      }
    }

    addForcedExperimentalFlag(
        "enableExtensionMethods", ExperimentalFlag.extensionMethods);
    addForcedExperimentalFlag(
        "enableNonNullable", ExperimentalFlag.nonNullable);

    bool soundNullSafety = environment["soundNullSafety"] == "true";
    bool onlyCrashes = environment["onlyCrashes"] == "true";
    bool ignoreExpectations = environment["ignoreExpectations"] == "true";
    bool updateExpectations = environment[UPDATE_EXPECTATIONS] == "true";
    bool updateComments = environment[UPDATE_COMMENTS] == "true";
    bool skipVm = environment["skipVm"] == "true";
    bool semiFuzz = environment["semiFuzz"] == "true";
    bool verify = environment["verify"] != "false";
    String? platformBinaries = environment["platformBinaries"];
    if (platformBinaries != null && !platformBinaries.endsWith('/')) {
      platformBinaries = '$platformBinaries/';
    }
    return new Future.value(new FastaContext(
        suite.uri,
        vm,
        platformBinaries == null
            ? computePlatformBinariesLocation(forceBuildDir: true)
            : Uri.base.resolve(platformBinaries),
        onlyCrashes,
        experimentalFlags,
        ignoreExpectations,
        updateExpectations,
        updateComments,
        skipVm,
        semiFuzz,
        compileModeFromName(environment[COMPILATION_MODE]),
        verify,
        soundNullSafety));
  }
}

class Run extends Step<ComponentResult, ComponentResult, FastaContext> {
  const Run();

  @override
  String get name => "run";

  /// WARNING: Every subsequent step in this test will run async as well!
  @override
  bool get isAsync => true;

  @override
  Future<Result<ComponentResult>> run(
      ComponentResult result, FastaContext context) async {
    Uri? outputUri = result.outputUri;
    if (outputUri == null) {
      return pass(result);
    }

    File generated = new File.fromUri(result.outputUri!);
    try {
      FolderOptions folderOptions =
          context.computeFolderOptions(result.description);
      switch (folderOptions.target) {
        case "vm":
          if (context._platforms.isEmpty) {
            throw "Executed `Run` step before initializing the context.";
          }
          List<String> args = <String>[];
          if (context.soundNullSafety) {
            args.add("--sound-null-safety");
          } else {
            args.add("--no-sound-null-safety");
          }
          args.add(generated.path);
          StdioProcess process =
              await StdioProcess.run(context.vm.toFilePath(), args);
          print(process.output);
          Result<int> runResult = process.toResult();
          if (result.component.mode ==
              NonNullableByDefaultCompiledMode.Invalid) {
            // In this case we expect and want a runtime error.
            if (runResult.outcome ==
                ExpectationSet.defaultExpectations["RuntimeError"]) {
              // We convert this to pass because that's exactly what we'd
              // expect.
              return pass(result);
            } else {
              // Different outcome - that's a failure!
              return new Result<ComponentResult>(
                  result,
                  ExpectationSet.defaultExpectations["MissingRuntimeError"],
                  runResult.error);
            }
          }
          return new Result<ComponentResult>(
              result, runResult.outcome, runResult.error);
        case "none":
        case "dart2js":
        case "dartdevc":
        case "wasm":
          // TODO(johnniwinther): Support running dart2js, dartdevc and/or wasm.
          return pass(result);
        default:
          throw new ArgumentError(
              "Unsupported run target '${folderOptions.target}'.");
      }
    } finally {
      await generated.parent.delete(recursive: true);
    }
  }
}

class StressConstantEvaluatorStep
    extends Step<ComponentResult, ComponentResult, FastaContext> {
  const StressConstantEvaluatorStep();

  @override
  String get name => "stress constant evaluator";

  @override
  Future<Result<ComponentResult>> run(
      ComponentResult result, FastaContext context) {
    KernelTarget target = result.sourceTarget;
    TypeEnvironment environment =
        new TypeEnvironment(target.loader.coreTypes, target.loader.hierarchy);
    StressConstantEvaluatorVisitor stressConstantEvaluatorVisitor =
        new StressConstantEvaluatorVisitor(
      target.backendTarget,
      result.component,
      result.options.environmentDefines,
      target.globalFeatures.tripleShift.isEnabled,
      environment,
      !target.backendTarget.supportsSetLiterals,
      result.options.errorOnUnevaluatedConstant,
      target.getConstantEvaluationModeForTesting(),
    );
    for (Library lib in result.component.libraries) {
      if (!result.isUserLibrary(lib)) continue;
      lib.accept(stressConstantEvaluatorVisitor);
    }
    if (stressConstantEvaluatorVisitor.success > 0) {
      result.extraConstantStrings.addAll(stressConstantEvaluatorVisitor.output);
      result.extraConstantStrings.add("Extra constant evaluation: "
          "evaluated: ${stressConstantEvaluatorVisitor.tries}, "
          "effectively constant: ${stressConstantEvaluatorVisitor.success}");
    }
    return new Future.value(pass(result));
  }
}

class StressConstantEvaluatorVisitor extends RecursiveResultVisitor<Node>
    implements ErrorReporter {
  late ConstantEvaluator constantEvaluator;
  late ConstantEvaluator constantEvaluatorWithEmptyEnvironment;
  int tries = 0;
  int success = 0;
  List<String> output = [];

  StressConstantEvaluatorVisitor(
      Target target,
      Component component,
      Map<String, String>? environmentDefines,
      bool enableTripleShift,
      TypeEnvironment typeEnvironment,
      bool desugarSets,
      bool errorOnUnevaluatedConstant,
      EvaluationMode evaluationMode) {
    constantEvaluator = new ConstantEvaluator(
        target.dartLibrarySupport,
        target.constantsBackend,
        component,
        environmentDefines,
        typeEnvironment,
        this,
        enableTripleShift: enableTripleShift,
        errorOnUnevaluatedConstant: errorOnUnevaluatedConstant,
        evaluationMode: evaluationMode);
    constantEvaluatorWithEmptyEnvironment = new ConstantEvaluator(
        target.dartLibrarySupport,
        target.constantsBackend,
        component,
        {},
        typeEnvironment,
        this,
        enableTripleShift: enableTripleShift,
        errorOnUnevaluatedConstant: errorOnUnevaluatedConstant,
        evaluationMode: evaluationMode);
  }

  Library? currentLibrary;

  @override
  Library visitLibrary(Library node) {
    currentLibrary = node;
    node.visitChildren(this);
    currentLibrary = null;
    return node;
  }

  Member? currentMember;

  @override
  Node defaultMember(Member node) {
    Member? prevCurrentMember = currentMember;
    currentMember = node;
    node.visitChildren(this);
    currentMember = prevCurrentMember;
    return node;
  }

  @override
  Node defaultExpression(Expression node) {
    if (node is BasicLiteral) return node;
    if (node is InvalidExpression) return node;
    if (node is ConstantExpression) {
      bool evaluate = false;
      Constant constant = node.constant;
      if (constant is UnevaluatedConstant) {
        if (constant.expression is! InvalidExpression) {
          evaluate = true;
        }
      }
      if (!evaluate) return node;
      if (constantEvaluator.hasEnvironment) {
        throw "Unexpected UnevaluatedConstant "
            "when the environment is not null.";
      }
    }

    // Try to evaluate it as a constant.
    tries++;
    StaticTypeContext staticTypeContext;
    if (currentMember == null) {
      staticTypeContext = new StaticTypeContext.forAnnotations(
          currentLibrary!, constantEvaluator.typeEnvironment);
    } else {
      staticTypeContext = new StaticTypeContext(
          currentMember!, constantEvaluator.typeEnvironment);
    }
    Constant x = constantEvaluator.evaluate(staticTypeContext, node);
    bool evaluatedWithEmptyEnvironment = false;
    if (x is UnevaluatedConstant && x.expression is! InvalidExpression) {
      // try with an environment
      if (constantEvaluator.hasEnvironment) {
        throw "Unexpected UnevaluatedConstant (with an InvalidExpression in "
            "it) when the environment is not null.";
      }
      x = constantEvaluatorWithEmptyEnvironment.evaluate(
          new StaticTypeContext(
              currentMember!, constantEvaluator.typeEnvironment),
          new ConstantExpression(x));
      evaluatedWithEmptyEnvironment = true;
    }
    if (x is UnevaluatedConstant) {
      if (x.expression is! InvalidExpression &&
          x.expression is! FileUriExpression) {
        throw "Unexpected ${x.runtimeType} with "
            "${x.expression.runtimeType} inside.";
      }
      node.visitChildren(this);
    } else {
      success++;
      if (!evaluatedWithEmptyEnvironment) {
        output
            .add("Evaluated: ${node.runtimeType} @ ${getLocation(node)} -> $x");
        // Don't recurse into children - theoretically we could replace this
        // node with a constant expression.
      } else {
        output.add("Evaluated with empty environment: "
            "${node.runtimeType} @ ${getLocation(node)} -> $x");
        // Here we (for now) recurse into children.
        node.visitChildren(this);
      }
    }
    return node;
  }

  String getLocation(TreeNode node) {
    try {
      return node.location.toString();
    } catch (e) {
      TreeNode? n = node;
      while (n != null && n is! FileUriNode) {
        n = n.parent;
      }
      if (n == null) return "(unknown location)";
      FileUriNode fileUriNode = n as FileUriNode;
      return ("(unknown position in ${fileUriNode.fileUri})");
    }
  }

  @override
  void report(LocatedMessage message, [List<LocatedMessage>? context]) {
    // ignored.
  }
}

class CompilationSetup {
  final TestOptions testOptions;
  final FolderOptions folderOptions;
  final CompilerOptions compilerOptions;
  final ProcessedOptions options;
  final List<Iterable<String>> errors;
  final CompilerOptions Function(
          NnbdMode nnbdMode,
          AllowedExperimentalFlags? allowedExperimentalFlags,
          Map<ExperimentalFlag, Version>? experimentEnabledVersion,
          Map<ExperimentalFlag, Version>? experimentReleasedVersion)
      createCompilerOptions;

  final ProcessedOptions Function(CompilerOptions compilerOptions)
      createProcessedOptions;

  CompilationSetup(
      this.testOptions,
      this.folderOptions,
      this.compilerOptions,
      this.options,
      this.errors,
      this.createCompilerOptions,
      this.createProcessedOptions);
}

CompilationSetup createCompilationSetup(
    TestDescription description, FastaContext context) {
  List<Iterable<String>> errors = <Iterable<String>>[];

  Uri? librariesSpecificationUri =
      context.computeLibrariesSpecificationUri(description);
  TestOptions testOptions = context.computeTestOptions(description);
  FolderOptions folderOptions = context.computeFolderOptions(description);
  Map<ExperimentalFlag, bool> experimentalFlags = folderOptions
      .computeExplicitExperimentalFlags(context.explicitExperimentalFlags);
  NnbdMode nnbdMode = !context.soundNullSafety ||
          !isExperimentEnabled(ExperimentalFlag.nonNullable,
              explicitExperimentalFlags: experimentalFlags)
      ? NnbdMode.Weak
      : (folderOptions.nnbdAgnosticMode ? NnbdMode.Agnostic : NnbdMode.Strong);
  List<Uri> inputs = <Uri>[description.uri];

  CompilerOptions createCompilerOptions(
      NnbdMode nnbdMode,
      AllowedExperimentalFlags? allowedExperimentalFlags,
      Map<ExperimentalFlag, Version>? experimentEnabledVersion,
      Map<ExperimentalFlag, Version>? experimentReleasedVersion) {
    CompilerOptions compilerOptions = new CompilerOptions()
      ..onDiagnostic = (DiagnosticMessage message) {
        errors.add(message.plainTextFormatted);
      }
      ..enableUnscheduledExperiments =
          folderOptions.enableUnscheduledExperiments ?? false
      ..environmentDefines = folderOptions.defines
      ..explicitExperimentalFlags = experimentalFlags
      ..nnbdMode = nnbdMode
      ..librariesSpecificationUri = librariesSpecificationUri
      ..allowedExperimentalFlagsForTesting = allowedExperimentalFlags
      ..experimentEnabledVersionForTesting = experimentEnabledVersion
      ..experimentReleasedVersionForTesting = experimentReleasedVersion
      ..skipPlatformVerification = true
      ..omitPlatform = true
      ..omitOsMessageForTesting = true
      ..target = createTarget(folderOptions, context);
    if (folderOptions.overwriteCurrentSdkVersion != null) {
      compilerOptions.currentSdkVersion =
          folderOptions.overwriteCurrentSdkVersion!;
    }
    return compilerOptions;
  }

  ProcessedOptions createProcessedOptions(CompilerOptions compilerOptions) {
    return new ProcessedOptions(options: compilerOptions, inputs: inputs);
  }

  // Disable colors to ensure that expectation files are the same across
  // platforms and independent of stdin/stderr.
  colors.enableColors = false;

  CompilerOptions compilerOptions = createCompilerOptions(
      nnbdMode,
      testOptions.allowedExperimentalFlags,
      testOptions.experimentEnabledVersion,
      testOptions.experimentReleasedVersion);
  ProcessedOptions options = createProcessedOptions(compilerOptions);
  return new CompilationSetup(testOptions, folderOptions, compilerOptions,
      options, errors, createCompilerOptions, createProcessedOptions);
}

class FuzzCompiles
    extends Step<ComponentResult, ComponentResult, FastaContext> {
  const FuzzCompiles();

  @override
  String get name {
    return "semifuzz";
  }

  @override
  Future<Result<ComponentResult>> run(
      ComponentResult result, FastaContext context) async {
    bool? originalFlag = context.explicitExperimentalFlags[
        ExperimentalFlag.alternativeInvalidationStrategy];
    context.explicitExperimentalFlags[
        ExperimentalFlag.alternativeInvalidationStrategy] = true;

    CompilationSetup compilationSetup =
        createCompilationSetup(result.description, context);

    Target backendTarget = compilationSetup.options.target;
    if (backendTarget is TestTarget) {
      // For the fuzzing we want to run the VM transformations, i.e. have the
      // incremental compiler behave as normal.
      backendTarget.performModularTransformations = true;
    }

    UriTranslator uriTranslator =
        await context.computeUriTranslator(result.description);

    Component platform =
        context.loadPlatform(backendTarget, compilationSetup.options.nnbdMode);

    final bool hasErrors;
    {
      bool foundErrors = false;
      if ((result.component.problemsAsJson?.length ?? 0) > 0) {
        foundErrors = true;
      } else {
        for (Library library in result.component.libraries) {
          if ((library.problemsAsJson?.length ?? 0) > 0) {
            foundErrors = true;
            break;
          }
        }
      }
      hasErrors = foundErrors;
    }

    try {
      Result<ComponentResult>? passResult = await performFileInvalidation(
        compilationSetup,
        platform,
        uriTranslator,
        context,
        originalCompilationResult: result,
        forceAndCheckRebuildBodiesOnly: false,
      );
      if (passResult != null) return passResult;

      passResult = await performChunkReordering(
        compilationSetup,
        platform,
        uriTranslator,
        result,
        context,
      );
      if (passResult != null) return passResult;

      if (!hasErrors) {
        // To get proper splitting (between dill and not dill builders) we need
        // experimental invalidation - it doesn't work when there's errors
        // though, so skip those up front.
        // Note also that because of splitting and privacy this might fail with
        // an error --- so it should probably be the last one. At some point we
        // might swallow that so we can continue, but for now it will be good
        // to know when it's not run because of that.
        passResult = await performFileSplitting(
          compilationSetup,
          platform,
          uriTranslator,
          result,
          context,
        );
        if (passResult != null) return passResult;
      }

      return pass(result);
    } catch (e, st) {
      return new Result<ComponentResult>(result, semiFuzzCrash,
          "Crashed with '$e' when fuzz compiling.\n\n$st");
    } finally {
      if (originalFlag != null) {
        context.explicitExperimentalFlags[
            ExperimentalFlag.alternativeInvalidationStrategy] = originalFlag;
      } else {
        context.explicitExperimentalFlags
            .remove(ExperimentalFlag.alternativeInvalidationStrategy);
      }
    }
  }

  /// Perform a number of compilations where each user-file is invalidated
  /// one at a time, and the code recompiled after each invalidation.
  /// Verifies that either it's an error in all cases or in no cases.
  /// Verifies that the same libraries comes out as a result.
  Future<Result<ComponentResult>?> performFileInvalidation(
      CompilationSetup compilationSetup,
      Component platform,
      UriTranslator uriTranslator,
      FastaContext context,
      {ComponentResult? originalCompilationResult,
      required bool forceAndCheckRebuildBodiesOnly}) async {
    compilationSetup.errors.clear();
    SemiForceExperimentalInvalidationIncrementalCompiler incrementalCompiler =
        new SemiForceExperimentalInvalidationIncrementalCompiler.fromComponent(
            new CompilerContext(compilationSetup.options), platform);
    incrementalCompiler.skipExperimentalInvalidationChecksForTesting =
        forceAndCheckRebuildBodiesOnly;
    IncrementalCompilerResult incrementalCompilerResult =
        await incrementalCompiler.computeDelta();
    final Component component = incrementalCompilerResult.component;
    print("Compiled and got ${component.libraries.length} libs");
    if (!canSerialize(component)) {
      return new Result<ComponentResult>(originalCompilationResult,
          semiFuzzFailure, "Couldn't serialize initial component for fuzzing");
    }

    final Set<Uri> userLibraries =
        createUserLibrariesImportUriSet(component, uriTranslator);
    final bool expectErrors = compilationSetup.errors.isNotEmpty;

    if (expectErrors && forceAndCheckRebuildBodiesOnly) {
      return new Result<ComponentResult>(
          originalCompilationResult,
          semiFuzzFailureOnForceRebuildBodies,
          "Errors upon compilation not compatible "
          "with forcing rebuild bodies. Got ${compilationSetup.errors}");
    }

    List<Iterable<String>> originalErrors =
        new List<Iterable<String>>.from(compilationSetup.errors);

    if (originalCompilationResult != null) {
      Set<Uri> intersectionUserLibraries =
          originalCompilationResult.userLibraries.intersection(userLibraries);
      if (intersectionUserLibraries.length != userLibraries.length ||
          userLibraries.length !=
              originalCompilationResult.userLibraries.length) {
        String originalCompileString = originalCompilationResult.userLibraries
            .map((e) => e.toString())
            .join("\n");
        return new Result<ComponentResult>(
            originalCompilationResult,
            semiFuzzFailure,
            "Got a different amount of user libraries on first compile "
            "compared to 'original' compilation:\n\n"
            "This compile:\n"
            "${userLibraries.map((e) => e.toString()).join("\n")}\n\n"
            "Original compile:\n"
            "$originalCompileString");
      }
    }

    compilationSetup.errors.clear();
    for (Uri importUri in userLibraries) {
      print(" -> invalidating $importUri");
      incrementalCompiler.invalidate(importUri);
      final IncrementalCompilerResult newResult;
      try {
        newResult = await incrementalCompiler.computeDelta(fullComponent: true);
      } catch (e, st) {
        return new Result<ComponentResult>(
            originalCompilationResult,
            semiFuzzCrash,
            "Crashed with '$e' on recompilation after invalidating "
            "'$importUri'.\n\n$st");
      }
      if (forceAndCheckRebuildBodiesOnly) {
        bool didRebuildBodiesOnly =
            incrementalCompiler.recorderForTesting.rebuildBodiesCount! > 0;
        if (!didRebuildBodiesOnly) {
          return new Result<ComponentResult>(originalCompilationResult,
              semiFuzzFailure, "Didn't rebuild bodies only!");
        }
      }
      final Component newComponent = newResult.component;
      print(" -> and got ${newComponent.libraries.length} libs");
      if (!canSerialize(newComponent)) {
        return new Result<ComponentResult>(originalCompilationResult,
            semiFuzzFailure, "Couldn't serialize fuzzed component");
      }

      final Set<Uri> newUserLibraries =
          createUserLibrariesImportUriSet(newComponent, uriTranslator);
      final bool gotErrors = compilationSetup.errors.isNotEmpty;

      if (expectErrors != gotErrors) {
        if (expectErrors) {
          String errorsString =
              originalErrors.map((error) => error.join('\n')).join('\n\n');
          return new Result<ComponentResult>(
              originalCompilationResult,
              semiFuzzFailure,
              "Expected these errors:\n${errorsString}\n\n"
              "but didn't get any after invalidating $importUri");
        } else {
          String errorsString = compilationSetup.errors
              .map((error) => error.join('\n'))
              .join('\n\n');
          return new Result<ComponentResult>(
              originalCompilationResult,
              semiFuzzFailure,
              "Unexpected errors:\n${errorsString}\n\n"
              "after invalidating $importUri");
        }
      }

      Set<Uri> intersectionUserLibraries =
          userLibraries.intersection(newUserLibraries);
      if (intersectionUserLibraries.length != newUserLibraries.length ||
          newUserLibraries.length != userLibraries.length) {
        String originalCompileString = "";
        if (originalCompilationResult != null) {
          originalCompileString = "Original compile:\n" +
              originalCompilationResult.userLibraries
                  .map((e) => e.toString())
                  .join("\n");
        }
        return new Result<ComponentResult>(
            originalCompilationResult,
            semiFuzzFailure,
            "Got a different amount of user libraries on recompile "
            "compared to 'original' compilation after having invalidated "
            "$importUri.\n\n"
            "This compile:\n"
            "${newUserLibraries.map((e) => e.toString()).join("\n")}\n\n"
            "${originalCompileString}");
      }

      if (!compareComponents(component, newComponent)) {
        return new Result<ComponentResult>(originalCompilationResult,
            semiFuzzFailure, "Fuzzed component changed in an unexpected way.");
      }
    }

    return null;
  }

  bool compareComponents(Component a, Component b) {
    if (a.libraries.length != b.libraries.length) {
      print("Not the same number of libraries.");
      return false;
    }
    a.libraries.sort((l1, l2) {
      return "${l1.importUri}".compareTo("${l2.importUri}");
    });
    b.libraries.sort((l1, l2) {
      return "${l1.importUri}".compareTo("${l2.importUri}");
    });
    for (int i = 0; i < a.libraries.length; i++) {
      EquivalenceResult result = checkEquivalence(
          a.libraries[i], b.libraries[i],
          strategy: const Strategy());
      if (!result.isEquivalent) {
        print(result.toString());
        return false;
      }
    }
    return true;
  }

  bool canSerialize(Component component) {
    ByteSink byteSink = new ByteSink();
    try {
      new BinaryPrinter(byteSink).writeComponentFile(component);
      return true;
    } catch (e, st) {
      print("Can't serialize, got '$e' from $st");
      return false;
    }
  }

  /// Perform a number of compilations where each user-file is in turn sorted
  /// in both ascending and descending order (i.e. the procedures and classes
  /// etc are sorted).
  /// Verifies that either it's an error in all cases or in no cases.
  /// Verifies that the same libraries comes out as a result.
  Future<Result<ComponentResult>?> performChunkReordering(
      CompilationSetup compilationSetup,
      Component platform,
      UriTranslator uriTranslator,
      ComponentResult result,
      FastaContext context) async {
    compilationSetup.errors.clear();

    FileSystem orgFileSystem = compilationSetup.options.fileSystem;
    compilationSetup.options.clearFileSystemCache();
    _FakeFileSystem fs = new _FakeFileSystem(orgFileSystem);
    compilationSetup.compilerOptions.fileSystem = fs;
    IncrementalCompiler incrementalCompiler =
        new IncrementalCompiler.fromComponent(
            new CompilerContext(compilationSetup.options), platform);
    IncrementalCompilerResult initialResult =
        await incrementalCompiler.computeDelta();
    Component initialComponent = initialResult.component;
    if (!canSerialize(initialComponent)) {
      return new Result<ComponentResult>(result, semiFuzzFailure,
          "Couldn't serialize initial component for fuzzing");
    }

    final bool expectErrors = compilationSetup.errors.isNotEmpty;
    List<Iterable<String>> originalErrors =
        new List<Iterable<String>>.from(compilationSetup.errors);
    compilationSetup.errors.clear();

    // Create lookup-table from file uri to whatever.
    Map<Uri, LibraryBuilder> builders = {};
    for (LibraryBuilder builder
        in incrementalCompiler.kernelTargetForTesting!.loader.libraryBuilders) {
      if (builder.importUri.isScheme("dart") && !builder.isSynthetic) continue;
      builders[builder.fileUri] = builder;
      for (LibraryPart part in builder.library.parts) {
        Uri thisPartUri = builder.importUri.resolve(part.partUri);
        if (thisPartUri.isScheme("package")) {
          thisPartUri = incrementalCompiler
              .kernelTargetForTesting!.uriTranslator
              .translate(thisPartUri)!;
        }
        builders[thisPartUri] = builder;
      }
    }

    for (Uri uri in fs.data.keys) {
      print("Work on $uri");
      LibraryBuilder? builder = builders[uri];
      if (builder == null) {
        print("Skipping $uri -- couldn't find builder for it.");
        continue;
      }
      Uint8List? orgData = fs.data[uri];
      if (orgData == null) {
        print("Skipping $uri -- couldn't find source for it.");
        continue;
      }
      FuzzAstVisitorSorter fuzzAstVisitorSorter;
      try {
        fuzzAstVisitorSorter =
            new FuzzAstVisitorSorter(orgData, builder.isNonNullableByDefault);
      } on FormatException catch (e, st) {
        // UTF-16-LE formatted test crashes `utf8.decode(bytes)` --- catch that
        return new Result<ComponentResult>(
            result,
            semiFuzzCrash,
            "$e\n\n"
            "$st");
      }

      // Sort ascending and then compile. Then sort descending and try again.
      for (void Function() sorter in [
        () => fuzzAstVisitorSorter.sortAscending(),
        () => fuzzAstVisitorSorter.sortDescending(),
      ]) {
        sorter();
        StringBuffer sb = new StringBuffer();
        for (FuzzAstVisitorSorterChunk chunk in fuzzAstVisitorSorter.chunks) {
          sb.writeln(chunk.getSource());
        }
        Uint8List sortedData = utf8.encode(sb.toString());
        fs.data[uri] = sortedData;
        incrementalCompiler = new IncrementalCompiler.fromComponent(
            new CompilerContext(compilationSetup.options), platform);
        try {
          IncrementalCompilerResult incrementalCompilerResult =
              await incrementalCompiler.computeDelta();
          Component component = incrementalCompilerResult.component;
          if (!canSerialize(component)) {
            return new Result<ComponentResult>(
                result, semiFuzzFailure, "Couldn't serialize fuzzed component");
          }
        } catch (e, st) {
          return new Result<ComponentResult>(
              result,
              semiFuzzCrash,
              "Crashed with '$e' after reordering '$uri' to\n\n"
              "$sb\n\n"
              "$st");
        }
        final bool gotErrors = compilationSetup.errors.isNotEmpty;
        String errorsString = compilationSetup.errors
            .map((error) => error.join('\n'))
            .join('\n\n');
        compilationSetup.errors.clear();

        // TODO(jensj): When we get errors we should try to verify it's
        // "the same" errors (note, though, that they will naturally be at a
        // changed location --- some will likely have different wording).
        if (expectErrors != gotErrors) {
          if (expectErrors) {
            String errorsString =
                originalErrors.map((error) => error.join('\n')).join('\n\n');
            return new Result<ComponentResult>(
                result,
                semiFuzzFailure,
                "Expected these errors:\n${errorsString}\n\n"
                "but didn't get any after reordering $uri "
                "to have this content:\n\n"
                "$sb");
          } else {
            return new Result<ComponentResult>(
                result,
                semiFuzzFailure,
                "Unexpected errors:\n${errorsString}\n\n"
                "after reordering $uri to have this content:\n\n"
                "$sb");
          }
        }
      }
    }

    compilationSetup.options.clearFileSystemCache();
    compilationSetup.compilerOptions.fileSystem = orgFileSystem;
    return null;
  }

  /// Splits all files into "sub files" that all import and export each other
  /// so everything should still work (except for privacy).
  /// Then invalidate one file at a time with forced experimental invalidation.
  ///
  /// Prerequisite: No errors should be present, as that doesn't work with
  /// experimental invalidation.
  Future<Result<ComponentResult>?> performFileSplitting(
      CompilationSetup compilationSetup,
      Component platform,
      UriTranslator uriTranslator,
      ComponentResult result,
      FastaContext context) async {
    FileSystem orgFileSystem = compilationSetup.options.fileSystem;
    compilationSetup.options.clearFileSystemCache();
    _FakeFileSystem fs = new _FakeFileSystem(orgFileSystem);
    compilationSetup.compilerOptions.fileSystem = fs;
    IncrementalCompiler incrementalCompiler =
        new IncrementalCompiler.fromComponent(
            new CompilerContext(compilationSetup.options), platform);
    IncrementalCompilerResult initialResult =
        await incrementalCompiler.computeDelta();
    Component initialComponent = initialResult.component;
    if (!canSerialize(initialComponent)) {
      return new Result<ComponentResult>(result, semiFuzzFailure,
          "Couldn't serialize initial component for fuzzing");
    }

    // Create lookup-table from file uri to whatever.
    Map<Uri, LibraryBuilder> builders = {};
    for (LibraryBuilder builder
        in incrementalCompiler.kernelTargetForTesting!.loader.libraryBuilders) {
      if (builder.importUri.isScheme("dart") && !builder.isSynthetic) continue;
      if (builder.importUri.isScheme("package") &&
          !builder.fileUri.toString().contains("/pkg/front_end/testcases/")) {
        // A package uri where the file uri is *not* inside out testcases.
        // This for instance ignores "package:expect/expect.dart" etc.
        continue;
      }
      builders[builder.fileUri] = builder;
      for (LibraryPart part in builder.library.parts) {
        Uri thisPartUri = builder.importUri.resolve(part.partUri);
        if (thisPartUri.isScheme("package")) {
          thisPartUri = incrementalCompiler
              .kernelTargetForTesting!.uriTranslator
              .translate(thisPartUri)!;
        }
        builders[thisPartUri] = builder;
      }
    }

    List<Uri> originalUris = List<Uri>.of(fs.data.keys);
    uriLoop:
    for (Uri uri in originalUris) {
      print("Work on $uri");
      LibraryBuilder? builder = builders[uri];
      if (builder == null) {
        print("Skipping $uri -- couldn't find builder for it.");
        continue;
      }
      Uint8List orgData = fs.data[uri]!;
      FuzzAstVisitorSorter fuzzAstVisitorSorter;
      try {
        fuzzAstVisitorSorter =
            new FuzzAstVisitorSorter(orgData, builder.isNonNullableByDefault);
      } on FormatException catch (e, st) {
        // UTF-16-LE formatted test crashes `utf8.decode(bytes)` --- catch that
        return new Result<ComponentResult>(
            result,
            semiFuzzCrash,
            "$e\n\n"
            "$st");
      }

      // Put each chunk into its own file.
      StringBuffer headerSb = new StringBuffer();
      StringBuffer orgFileOnlyHeaderSb = new StringBuffer();
      List<FuzzAstVisitorSorterChunk> nonHeaderChunks = [];

      print("Found ${fuzzAstVisitorSorter.chunks.length} chunks...");

      for (FuzzAstVisitorSorterChunk chunk in fuzzAstVisitorSorter.chunks) {
        if (chunk.originalType == FuzzOriginalType.PartOf) {
          print("Skipping part...");
          continue uriLoop;
        } else if (chunk.originalType == FuzzOriginalType.Part) {
          // The part declaration should only be in the "main" file.
          orgFileOnlyHeaderSb.writeln(chunk.getSource());
        } else if (chunk.originalType == FuzzOriginalType.Import ||
            chunk.originalType == FuzzOriginalType.Export ||
            chunk.originalType == FuzzOriginalType.LibraryName ||
            chunk.originalType == FuzzOriginalType.LanguageVersion) {
          headerSb.writeln(chunk.getSource());
        } else {
          nonHeaderChunks.add(chunk);
        }
      }

      Uri getUriForChunk(int chunkNum) {
        return uri.resolve(uri.pathSegments.last + ".split.$chunkNum.dart");
      }

      int totalSubFiles = nonHeaderChunks.length;
      int currentSubFile = 0;
      for (FuzzAstVisitorSorterChunk chunk in nonHeaderChunks) {
        // We need to have special handling for dart versions, imports,
        // exports, etc.
        StringBuffer sb = new StringBuffer();
        sb.writeln(headerSb.toString());
        sb.writeln("import '${uri.pathSegments.last}';");
        sb.writeln(chunk.getSource());
        fs.data[getUriForChunk(currentSubFile)] = utf8.encode(sb.toString());
        print(" => Split into ${getUriForChunk(currentSubFile)}:\n"
            "${sb.toString()}\n-------------\n");
        currentSubFile++;
      }

      // Rewrite main file.
      StringBuffer sb = new StringBuffer();
      sb.writeln(headerSb.toString());
      for (int i = 0; i < totalSubFiles; i++) {
        sb.writeln("import '${getUriForChunk(i).pathSegments.last}';");
        sb.writeln("export '${getUriForChunk(i).pathSegments.last}';");
      }
      sb.writeln(orgFileOnlyHeaderSb.toString());
      print(" => Main file becomes:\n${sb.toString()}\n-------------\n");
      fs.data[uri] = utf8.encode(sb.toString());
    }

    Result<ComponentResult>? passResult = await performFileInvalidation(
      compilationSetup,
      platform,
      uriTranslator,
      context,
      originalCompilationResult: null,
      forceAndCheckRebuildBodiesOnly: true,
    );
    if (passResult != null) return passResult;

    compilationSetup.options.clearFileSystemCache();
    compilationSetup.compilerOptions.fileSystem = orgFileSystem;
    return null;
  }
}

class Strategy extends EquivalenceStrategy {
  const Strategy();

  @override
  bool checkLibrary_procedures(
      EquivalenceVisitor visitor, Library node, Library other) {
    return visitor.checkSets(node.procedures.toSet(), other.procedures.toSet(),
        visitor.matchNamedNodes, visitor.checkNodes, 'procedures');
  }

  @override
  bool checkClass_procedures(
      EquivalenceVisitor visitor, Class node, Class other) {
    return visitor.checkSets(node.procedures.toSet(), other.procedures.toSet(),
        visitor.matchNamedNodes, visitor.checkNodes, 'procedures');
  }

  @override
  bool checkLibrary_additionalExports(
      EquivalenceVisitor visitor, Library node, Library other) {
    return visitor.checkSets(
        node.additionalExports.toSet(),
        other.additionalExports.toSet(),
        visitor.matchReferences,
        visitor.checkReferences,
        'additionalExports');
  }

  @override
  bool checkVariableDeclaration_binaryOffsetNoTag(EquivalenceVisitor visitor,
      VariableDeclaration node, VariableDeclaration other) {
    return true;
  }

  /// Allow assuming references like
  /// "_Class&Superclass&Mixin::@methods::method4" and
  /// "Mixin::@methods::method4" are equal (an interfaceTargetReference change
  /// that often occur on recompile in regards to mixins).
  ///
  /// Copied from incremental_dart2js_load_from_dill_test.dart
  bool _isMixinOrCloneReference(EquivalenceVisitor visitor, Reference? a,
      Reference? b, String propertyName) {
    if (a != null && b != null) {
      ReferenceName thisName = ReferenceName.fromReference(a)!;
      ReferenceName otherName = ReferenceName.fromReference(b)!;
      if (thisName.isMember &&
          otherName.isMember &&
          thisName.memberName == otherName.memberName) {
        String? thisClassName = thisName.declarationName;
        String? otherClassName = otherName.declarationName;
        if (thisClassName != null &&
            otherClassName != null &&
            thisClassName.contains('&${otherClassName}')) {
          visitor.assumeReferences(a, b);
        }
      }
    }
    return visitor.checkReferences(a, b, propertyName);
  }

  @override
  bool checkInstanceInvocation_interfaceTargetReference(
      EquivalenceVisitor visitor,
      InstanceInvocation node,
      InstanceInvocation other) {
    return _isMixinOrCloneReference(visitor, node.interfaceTargetReference,
        other.interfaceTargetReference, 'interfaceTargetReference');
  }

  @override
  bool checkInstanceSet_interfaceTargetReference(
      EquivalenceVisitor visitor, InstanceSet node, InstanceSet other) {
    return _isMixinOrCloneReference(visitor, node.interfaceTargetReference,
        other.interfaceTargetReference, 'interfaceTargetReference');
  }

  @override
  bool checkLibrary_problemsAsJson(
      EquivalenceVisitor visitor, Library node, Library other) {
    List<String>? a = node.problemsAsJson;
    if (a != null) {
      a = a.map(_rewriteJsonMap).toList();
    }
    List<String>? b = other.problemsAsJson;
    if (b != null) {
      b = b.map(_rewriteJsonMap).toList();
    }
    return visitor.checkLists(a, b, visitor.checkValues, 'problemsAsJson');
  }

  String _rewriteJsonMap(String s) {
    // Several things can change, e.g.
    // * unserializableExports (when from dill) causes the message code to
    //   become "unspecified" from usage of `templateUnspecified`)
    // * Order of things (and for instance which line it's reported on) can
    //   change depending on order, e.g. duplicate names in exports upon
    //   recompile of one of the exported libraries.
    Map<String, dynamic> decoded = jsonDecode(s);
    return decoded["uri"];
  }
}

class FuzzAstVisitorSorterChunk {
  final FuzzOriginalType originalType;
  final String data;
  final String? metadataAndComments;
  final int layer;

  FuzzAstVisitorSorterChunk(
      this.originalType, this.data, this.metadataAndComments, this.layer);

  @override
  String toString() {
    return "FuzzAstVisitorSorterChunk[${getSource()}]";
  }

  String getSource() {
    if (metadataAndComments != null) {
      return "$metadataAndComments\n$data";
    }
    return "$data";
  }
}

enum FuzzSorterState { nonSortable, importExportSortable, sortableRest }

enum FuzzOriginalType {
  Import,
  Export,
  LanguageVersion,
  AdditionalMetadata,
  Class,
  Mixin,
  Enum,
  Extension,
  LibraryName,
  Part,
  PartOf,
  TopLevelFields,
  TopLevelMethod,
  TypeDef,
}

class FuzzAstVisitorSorter extends ParserAstVisitor {
  final Uint8List bytes;
  final String asString;
  final bool nnbd;

  FuzzAstVisitorSorter(this.bytes, this.nnbd) : asString = utf8.decode(bytes) {
    CompilationUnitEnd ast = getAST(bytes,
        includeBody: false,
        includeComments: true,
        enableExtensionMethods: true,
        enableNonNullable: nnbd);
    accept(ast);

    if (metadataStart == null &&
        ast.token.precedingComments != null &&
        chunks.isEmpty) {
      _chunkOutLanguageVersionComment(ast.token);
    }

    if (metadataStart != null) {
      String metadata = asString.substring(
          metadataStart!.charOffset, metadataEndInclusive!.charEnd);
      layer++;
      chunks.add(new FuzzAstVisitorSorterChunk(
        FuzzOriginalType.AdditionalMetadata,
        "",
        metadata,
        layer,
      ));
    }
  }

  void sortAscending() {
    chunks.sort(_ascendingSorter);
  }

  void sortDescending() {
    chunks.sort(_descendingSorter);
  }

  int _ascendingSorter(
      FuzzAstVisitorSorterChunk a, FuzzAstVisitorSorterChunk b) {
    if (a.layer < b.layer) return -1;
    if (a.layer > b.layer) return 1;
    return a.data.compareTo(b.data);
  }

  int _descendingSorter(
      FuzzAstVisitorSorterChunk a, FuzzAstVisitorSorterChunk b) {
    // Only sort layers differently internally.
    if (a.layer < b.layer) return -1;
    if (a.layer > b.layer) return 1;
    return b.data.compareTo(a.data);
  }

  List<FuzzAstVisitorSorterChunk> chunks = [];
  Token? metadataStart;
  Token? metadataEndInclusive;
  int layer = 0;
  FuzzSorterState? state = null;

  /// If there's any LanguageVersionToken in the comment preceding the given
  /// token add it as a separate chunk to keep it in place.
  void _chunkOutLanguageVersionComment(Token fromToken) {
    Token comment = fromToken.precedingComments!;
    bool hasLanguageVersion = comment is LanguageVersionToken;
    while (comment.next != null) {
      comment = comment.next!;
      hasLanguageVersion |= comment is LanguageVersionToken;
    }
    if (hasLanguageVersion) {
      layer++;
      chunks.add(new FuzzAstVisitorSorterChunk(
        FuzzOriginalType.LanguageVersion,
        asString.substring(
            fromToken.precedingComments!.charOffset, comment.charEnd),
        null,
        layer,
      ));
      layer++;
    }
  }

  void handleData(FuzzOriginalType originalType, FuzzSorterState thisState,
      Token startInclusive, Token endInclusive) {
    // Non-sortable things always gets a new layer.
    if (state != thisState || thisState == FuzzSorterState.nonSortable) {
      state = thisState;
      layer++;
    }

    // "Chunk out" any language version at the top, i.e. if there are no other
    // chunks and there is a metadata, any language version chunk on the
    // metadata will be "chunked out". If there is no metadata, any language
    // version on the non-metadata will be "chunked out".
    // Note that if there is metadata and there is a language version on the
    // non-metadata it will not be chunked out as it's in an illegal place
    // anyway, so possibly allowing it to be sorted (and put in another place)
    // won't make it more or less illegal.
    if (metadataStart != null &&
        metadataStart!.precedingComments != null &&
        chunks.isEmpty) {
      _chunkOutLanguageVersionComment(metadataStart!);
    } else if (metadataStart == null &&
        startInclusive.precedingComments != null &&
        chunks.isEmpty) {
      _chunkOutLanguageVersionComment(startInclusive);
    }

    String? metadata;
    if (metadataStart != null || metadataEndInclusive != null) {
      metadata = asString.substring(
          metadataStart!.charOffset, metadataEndInclusive!.charEnd);
    }
    chunks.add(new FuzzAstVisitorSorterChunk(
      originalType,
      asString.substring(startInclusive.charOffset, endInclusive.charEnd),
      metadata,
      layer,
    ));
    metadataStart = null;
    metadataEndInclusive = null;
  }

  @override
  void visitExport(ExportEnd node, Token startInclusive, Token endInclusive) {
    handleData(FuzzOriginalType.Export, FuzzSorterState.importExportSortable,
        startInclusive, endInclusive);
  }

  @override
  void visitImport(ImportEnd node, Token startInclusive, Token? endInclusive) {
    handleData(FuzzOriginalType.Import, FuzzSorterState.importExportSortable,
        startInclusive, endInclusive!);
  }

  @override
  void visitClass(
      ClassDeclarationEnd node, Token startInclusive, Token endInclusive) {
    // TODO(jensj): Possibly sort stuff inside of this too.
    handleData(FuzzOriginalType.Class, FuzzSorterState.sortableRest,
        startInclusive, endInclusive);
  }

  @override
  void visitEnum(EnumEnd node, Token startInclusive, Token endInclusive) {
    handleData(FuzzOriginalType.Enum, FuzzSorterState.sortableRest,
        startInclusive, endInclusive);
  }

  @override
  void visitExtension(
      ExtensionDeclarationEnd node, Token startInclusive, Token endInclusive) {
    // TODO(jensj): Possibly sort stuff inside of this too.
    handleData(FuzzOriginalType.Extension, FuzzSorterState.sortableRest,
        startInclusive, endInclusive);
  }

  @override
  void visitLibraryName(
      LibraryNameEnd node, Token startInclusive, Token endInclusive) {
    handleData(FuzzOriginalType.LibraryName, FuzzSorterState.nonSortable,
        startInclusive, endInclusive);
  }

  @override
  void visitMetadata(
      MetadataEnd node, Token startInclusive, Token endInclusive) {
    if (metadataStart == null) {
      metadataStart = startInclusive;
      metadataEndInclusive = endInclusive;
    } else {
      metadataEndInclusive = endInclusive;
    }
  }

  @override
  void visitMixin(
      MixinDeclarationEnd node, Token startInclusive, Token endInclusive) {
    // TODO(jensj): Possibly sort stuff inside of this too.
    handleData(FuzzOriginalType.Mixin, FuzzSorterState.sortableRest,
        startInclusive, endInclusive);
  }

  @override
  void visitNamedMixin(
      NamedMixinApplicationEnd node, Token startInclusive, Token endInclusive) {
    // TODO(jensj): Possibly sort stuff inside of this too.
    handleData(FuzzOriginalType.Mixin, FuzzSorterState.sortableRest,
        startInclusive, endInclusive);
  }

  @override
  void visitPart(PartEnd node, Token startInclusive, Token endInclusive) {
    handleData(FuzzOriginalType.Part, FuzzSorterState.nonSortable,
        startInclusive, endInclusive);
  }

  @override
  void visitPartOf(PartOfEnd node, Token startInclusive, Token endInclusive) {
    handleData(FuzzOriginalType.PartOf, FuzzSorterState.nonSortable,
        startInclusive, endInclusive);
  }

  @override
  void visitTopLevelFields(
      TopLevelFieldsEnd node, Token startInclusive, Token endInclusive) {
    handleData(FuzzOriginalType.TopLevelFields, FuzzSorterState.sortableRest,
        startInclusive, endInclusive);
  }

  @override
  void visitTopLevelMethod(
      TopLevelMethodEnd node, Token startInclusive, Token endInclusive) {
    handleData(FuzzOriginalType.TopLevelMethod, FuzzSorterState.sortableRest,
        startInclusive, endInclusive);
  }

  @override
  void visitTypedef(TypedefEnd node, Token startInclusive, Token endInclusive) {
    handleData(FuzzOriginalType.TypeDef, FuzzSorterState.sortableRest,
        startInclusive, endInclusive);
  }
}

class SemiForceExperimentalInvalidationIncrementalCompiler
    extends IncrementalCompiler {
  @override
  final TestRecorderForTesting recorderForTesting =
      new TestRecorderForTesting();

  @override
  bool skipExperimentalInvalidationChecksForTesting = true;

  SemiForceExperimentalInvalidationIncrementalCompiler.fromComponent(
      CompilerContext context, Component? componentToInitializeFrom)
      : super.fromComponent(context, componentToInitializeFrom);
}

class _FakeFileSystem extends FileSystem {
  bool redirectAndRecord = true;
  final Map<Uri, Uint8List?> data = {};
  final FileSystem fs;
  _FakeFileSystem(this.fs);

  @override
  FileSystemEntity entityForUri(Uri uri) {
    return new _FakeFileSystemEntity(this, uri);
  }
}

class _FakeFileSystemEntity extends FileSystemEntity {
  final _FakeFileSystem fs;
  @override
  final Uri uri;
  _FakeFileSystemEntity(this.fs, this.uri);

  Future<void> _ensureCachedIfOk() async {
    if (fs.data.containsKey(uri)) return;
    if (!fs.redirectAndRecord) {
      throw "Asked for file in non-recording mode that wasn't known";
    }

    FileSystemEntity f = fs.fs.entityForUri(uri);
    if (!await f.exists()) {
      fs.data[uri] = null;
      return;
    }
    fs.data[uri] = (await f.readAsBytes()) as Uint8List;
  }

  @override
  Future<bool> exists() async {
    await _ensureCachedIfOk();
    Uint8List? data = fs.data[uri];
    if (data == null) return false;
    return true;
  }

  @override
  Future<bool> existsAsyncIfPossible() => exists();

  @override
  Future<List<int>> readAsBytes() async {
    await _ensureCachedIfOk();
    Uint8List? data = fs.data[uri];
    if (data == null) throw new FileSystemException(uri, "File doesn't exist.");
    return data;
  }

  @override
  Future<List<int>> readAsBytesAsyncIfPossible() => readAsBytes();

  @override
  Future<String> readAsString() async {
    await _ensureCachedIfOk();
    Uint8List? data = fs.data[uri];
    if (data == null) throw new FileSystemException(uri, "File doesn't exist.");
    return utf8.decode(data);
  }
}

Target createTarget(FolderOptions folderOptions, FastaContext context) {
  TestTargetFlags targetFlags = new TestTargetFlags(
    forceLateLoweringsForTesting: folderOptions.forceLateLowerings,
    forceLateLoweringSentinelForTesting:
        folderOptions.forceLateLoweringSentinel,
    forceStaticFieldLoweringForTesting: folderOptions.forceStaticFieldLowering,
    forceNoExplicitGetterCallsForTesting:
        folderOptions.forceNoExplicitGetterCalls,
    forceConstructorTearOffLoweringForTesting:
        folderOptions.forceConstructorTearOffLowering,
    soundNullSafety: context.soundNullSafety,
    supportedDartLibraries: {'_supported.by.target'},
    unsupportedDartLibraries: {'unsupported.by.target'},
  );
  Target target;
  switch (folderOptions.target) {
    case "vm":
      target = new TestVmTarget(targetFlags);
      break;
    case "none":
      target = new TestTargetWrapper(new NoneTarget(targetFlags), targetFlags);
      break;
    case "dart2js":
      target = new TestDart2jsTarget('dart2js', targetFlags,
          options: dart2jsOptions.CompilerOptions.parse(
              folderOptions.defines?.values.toList() ?? []));
      break;
    case "dartdevc":
      target = new TestDevCompilerTarget(targetFlags);
      break;
    case "wasm":
      target = new TestWasmTarget(targetFlags);
      break;
    default:
      throw new ArgumentError(
          "Unsupported test target '${folderOptions.target}'.");
  }
  return target;
}

Set<Uri> createUserLibrariesImportUriSet(
    Component component, UriTranslator uriTranslator,
    {Set<Library> excludedLibraries = const {}}) {
  Set<Uri> knownUris =
      component.libraries.map((Library library) => library.importUri).toSet();
  Set<Uri> userLibraries = component.libraries
      .where((Library library) =>
          !library.importUri.isScheme('dart') &&
          !library.importUri.isScheme('package') &&
          !excludedLibraries.contains(library))
      .map((Library library) => library.importUri)
      .toSet();
  // Mark custom "dart:" libraries defined in the test-specific libraries.json
  // file as user libraries.
  // Note that this method takes a uriTranslator directly because of
  // inconsistencies with targets (namely that test-specific libraries.json
  // specifies target 'none' even if the target is 'vm', which works because
  // the normal testing pipeline use target 'none' for the dill loader).
  userLibraries.addAll(uriTranslator.dartLibraries.allLibraries
      .map((LibraryInfo info) => info.importUri));
  return userLibraries.intersection(knownUris);
}

enum CompileMode {
  /// Compiles only the outline of the test and its linked dependencies.
  outline,

  /// Fully compiles the test but compiles only the outline of its linked
  /// dependencies.
  ///
  /// This mimics how modular compilation is performed with dartdevc.
  modular,

  /// Fully compiles the test and its linked dependencies.
  full,
}

CompileMode compileModeFromName(String? name) {
  for (CompileMode mode in CompileMode.values) {
    if (name == mode.name) {
      return mode;
    }
  }
  return CompileMode.outline;
}

class Outline extends Step<TestDescription, ComponentResult, FastaContext> {
  final CompileMode compileMode;

  const Outline(this.compileMode, {this.updateComments = false});

  final bool updateComments;

  @override
  String get name {
    switch (compileMode) {
      case CompileMode.outline:
        return "outline";
      case CompileMode.modular:
        return "modular";
      case CompileMode.full:
        return "compile";
    }
  }

  @override
  Future<Result<ComponentResult>> run(
      TestDescription description, FastaContext context) async {
    CompilationSetup compilationSetup =
        createCompilationSetup(description, context);

    if (compilationSetup.testOptions.linkDependencies.isNotEmpty &&
        compilationSetup.testOptions.component == null) {
      // Compile linked dependency.
      ProcessedOptions linkOptions = compilationSetup.options;
      if (compilationSetup.testOptions.nnbdMode != null) {
        linkOptions = compilationSetup.createProcessedOptions(
            compilationSetup.createCompilerOptions(
                compilationSetup.testOptions.nnbdMode!,
                compilationSetup.testOptions.allowedExperimentalFlags,
                compilationSetup.testOptions.experimentEnabledVersion,
                compilationSetup.testOptions.experimentReleasedVersion));
      }
      await CompilerContext.runWithOptions(linkOptions, (_) async {
        KernelTarget sourceTarget = await outlineInitialization(
            context,
            description,
            linkOptions,
            compilationSetup.testOptions.linkDependencies.toList());
        if (compilationSetup.testOptions.errors != null) {
          compilationSetup.errors.addAll(compilationSetup.testOptions.errors!);
        }
        BuildResult buildResult = await sourceTarget.buildOutlines();
        Component p = buildResult.component!;
        if (compileMode == CompileMode.full) {
          buildResult = await sourceTarget.buildComponent(
              macroApplications: buildResult.macroApplications,
              verify: compilationSetup.folderOptions.noVerify
                  ? false
                  : context.verify);
          p = buildResult.component!;
        }
        buildResult.macroApplications?.close();

        // To avoid possible crash in mixin transformation in the transformation
        // of the user of this linked dependency we have to transform this too.
        // We do that now.
        Target backendTarget = sourceTarget.backendTarget;
        if (backendTarget is TestTarget) {
          backendTarget.performModularTransformations = true;
        }
        try {
          sourceTarget.runBuildTransformations();
        } finally {
          if (backendTarget is TestTarget) {
            backendTarget.performModularTransformations = false;
          }
        }

        compilationSetup.testOptions.component = p;
        List<Library> keepLibraries = <Library>[];
        for (Library lib in p.libraries) {
          if (compilationSetup.testOptions.linkDependencies
              .contains(lib.importUri)) {
            keepLibraries.add(lib);
          }
        }
        p.libraries.clear();
        p.libraries.addAll(keepLibraries);
        compilationSetup.testOptions.errors = compilationSetup.errors.toList();
        compilationSetup.errors.clear();
      });
    }

    try {
      return await CompilerContext.runWithOptions(compilationSetup.options,
          (_) async {
        Component? alsoAppend = compilationSetup.testOptions.component;
        if (description.uri.pathSegments.last.endsWith(".no_link.dart")) {
          alsoAppend = null;
        }

        Set<Library>? excludedLibraries;
        if (compileMode == CompileMode.modular) {
          excludedLibraries = alsoAppend?.libraries.toSet();
        }
        excludedLibraries ??= const {};

        KernelTarget sourceTarget = await outlineInitialization(context,
            description, compilationSetup.options, <Uri>[description.uri],
            alsoAppend: alsoAppend);
        ValidatingInstrumentation instrumentation =
            new ValidatingInstrumentation();
        await instrumentation.loadExpectations(description.uri);
        sourceTarget.loader.instrumentation = instrumentation;
        BuildResult buildResult = await sourceTarget.buildOutlines();
        Component p = buildResult.component!;
        Set<Uri> userLibraries = createUserLibrariesImportUriSet(
            p, sourceTarget.uriTranslator,
            excludedLibraries: excludedLibraries);
        if (compileMode != CompileMode.outline) {
          buildResult = await sourceTarget.buildComponent(
              macroApplications: buildResult.macroApplications,
              verify: compilationSetup.folderOptions.noVerify
                  ? false
                  : context.verify,
              allowVerificationErrorForTesting: true);
          p = buildResult.component!;
          instrumentation.finish();
          if (instrumentation.hasProblems) {
            if (updateComments) {
              await instrumentation.fixSource(description.uri, false);
            } else {
              buildResult.macroApplications?.close();
              return new Result<ComponentResult>(
                  new ComponentResult(description, p, userLibraries,
                      compilationSetup, sourceTarget),
                  context.expectationSet["InstrumentationMismatch"],
                  instrumentation.problemsAsString,
                  autoFixCommand: '${UPDATE_COMMENTS}=true',
                  canBeFixWithUpdateExpectations: true);
            }
          }
        }
        buildResult.macroApplications?.close();
        return pass(new ComponentResult(
            description, p, userLibraries, compilationSetup, sourceTarget));
      });
    } catch (e, s) {
      return reportCrash(e, s);
    }
  }

  Future<KernelTarget> outlineInitialization(
      FastaContext context,
      TestDescription description,
      ProcessedOptions options,
      List<Uri> entryPoints,
      {Component? alsoAppend}) async {
    Component platform = context.loadPlatform(options.target, options.nnbdMode);
    Ticker ticker = new Ticker();
    UriTranslator uriTranslator =
        await context.computeUriTranslator(description);
    DillTarget dillTarget = new DillTarget(
      ticker,
      uriTranslator,
      options.target,
    );
    dillTarget.loader.appendLibraries(platform);
    if (alsoAppend != null) {
      dillTarget.loader.appendLibraries(alsoAppend);
    }
    KernelTarget sourceTarget = new KernelTarget(
        StandardFileSystem.instance, false, dillTarget, uriTranslator);

    sourceTarget.setEntryPoints(entryPoints);
    dillTarget.buildOutlines();
    return sourceTarget;
  }
}

class Transform extends Step<ComponentResult, ComponentResult, FastaContext> {
  const Transform();

  @override
  String get name => "transform component";

  @override
  Future<Result<ComponentResult>> run(
      ComponentResult result, FastaContext context) async {
    return await CompilerContext.runWithOptions(result.options, (_) async {
      Component component = result.component;
      KernelTarget sourceTarget = result.sourceTarget;
      Target backendTarget = sourceTarget.backendTarget;
      if (backendTarget is TestTarget) {
        backendTarget.performModularTransformations = true;
      }
      try {
        sourceTarget.runBuildTransformations();
      } finally {
        if (backendTarget is TestTarget) {
          backendTarget.performModularTransformations = false;
        }
      }
      if (backendTarget is TestTarget &&
          backendTarget.hasGlobalTransformation) {
        component =
            backendTarget.performGlobalTransformations(sourceTarget, component);
        // Clear the currently cached platform since the global transformation
        // might have modified it.
        context.clearPlatformCache(
            backendTarget, result.compilationSetup.options.nnbdMode);
      }

      return pass(new ComponentResult(result.description, component,
          result.userLibraries, result.compilationSetup, sourceTarget));
    });
  }
}

class Verify extends Step<ComponentResult, ComponentResult, FastaContext> {
  final VerificationStage stage;

  const Verify(this.stage);

  @override
  String get name => "verify";

  @override
  Future<Result<ComponentResult>> run(
      ComponentResult result, FastaContext context) async {
    FolderOptions folderOptions =
        context.computeFolderOptions(result.description);

    if (folderOptions.noVerify) {
      return pass(result);
    }

    Component component = result.component;
    StringBuffer messages = new StringBuffer();
    void Function(DiagnosticMessage)? previousOnDiagnostics =
        result.options.rawOptionsForTesting.onDiagnostic;
    result.options.rawOptionsForTesting.onDiagnostic =
        (DiagnosticMessage message) {
      if (messages.isNotEmpty) {
        messages.write("\n");
      }
      messages.writeAll(message.plainTextFormatted, "\n");
    };
    Result<ComponentResult> verifyResult = await CompilerContext.runWithOptions(
        result.options, (compilerContext) async {
      compilerContext.uriToSource.addAll(component.uriToSource);
      List<LocatedMessage> verificationErrors = verifyComponent(
          result.options.target, stage, component,
          skipPlatform: true);
      assert(verificationErrors.isEmpty || messages.isNotEmpty);
      if (messages.isEmpty) {
        return pass(result);
      } else {
        return new Result<ComponentResult>(
            null, context.expectationSet["VerificationError"], "$messages");
      }
    }, errorOnMissingInput: false);
    result.options.rawOptionsForTesting.onDiagnostic = previousOnDiagnostics;
    return verifyResult;
  }
}

mixin TestTarget on Target {
  bool performModularTransformations = false;

  @override
  void performModularTransformationsOnLibraries(
      Component component,
      CoreTypes coreTypes,
      ClassHierarchy hierarchy,
      List<Library> libraries,
      Map<String, String>? environmentDefines,
      DiagnosticReporter diagnosticReporter,
      ReferenceFromIndex? referenceFromIndex,
      {void Function(String msg)? logger,
      ChangedStructureNotifier? changedStructureNotifier}) {
    if (performModularTransformations) {
      super.performModularTransformationsOnLibraries(
          component,
          coreTypes,
          hierarchy,
          libraries,
          environmentDefines,
          diagnosticReporter,
          referenceFromIndex,
          logger: logger);
    }
  }

  bool get hasGlobalTransformation => false;

  Component performGlobalTransformations(
          KernelTarget kernelTarget, Component component) =>
      component;
}

class TestVmTarget extends VmTarget with TestTarget, TestTargetMixin {
  @override
  final TestTargetFlags flags;

  TestVmTarget(this.flags) : super(flags);
}

class TestWasmTarget extends WasmTarget with TestTarget, TestTargetMixin {
  @override
  final TestTargetFlags flags;

  TestWasmTarget(this.flags);
}

class EnsureNoErrors
    extends Step<ComponentResult, ComponentResult, FastaContext> {
  const EnsureNoErrors();

  @override
  String get name => "check errors";

  @override
  Future<Result<ComponentResult>> run(
      ComponentResult result, FastaContext context) {
    List<Iterable<String>> errors = result.compilationSetup.errors;
    return new Future.value(errors.isEmpty
        ? pass(result)
        : fail(
            result,
            "Unexpected errors:\n"
            "${errors.map((error) => error.join('\n')).join('\n\n')}"));
  }
}

class MatchHierarchy
    extends Step<ComponentResult, ComponentResult, FastaContext> {
  const MatchHierarchy();

  @override
  String get name => "check hierarchy";

  @override
  Future<Result<ComponentResult>> run(
      ComponentResult result, FastaContext context) {
    Component component = result.component;
    Uri uri =
        component.uriToSource.keys.firstWhere((uri) => uri.isScheme("file"));
    KernelTarget target = result.sourceTarget;
    ClassHierarchyBuilder hierarchy = target.loader.hierarchyBuilder;
    StringBuffer sb = new StringBuffer();
    for (ClassHierarchyNode node in hierarchy.nodes.values) {
      sb.writeln(node);
    }
    return context.match<ComponentResult>(
        ".hierarchy.expect", "$sb", uri, result);
  }
}

class UriConfiguration {
  final Uri? librariesSpecificationUri;
  final Uri? packageConfigUri;

  UriConfiguration(this.librariesSpecificationUri, this.packageConfigUri);

  @override
  int get hashCode =>
      librariesSpecificationUri.hashCode * 13 + packageConfigUri.hashCode * 17;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UriConfiguration &&
        librariesSpecificationUri == other.librariesSpecificationUri &&
        packageConfigUri == other.packageConfigUri;
  }
}

class NoneConstantsBackendWithJs extends NoneConstantsBackend {
  const NoneConstantsBackendWithJs({required bool supportsUnevaluatedConstants})
      : super(supportsUnevaluatedConstants: supportsUnevaluatedConstants);

  @override
  NumberSemantics get numberSemantics => NumberSemantics.js;
}

class TestDart2jsTarget extends Dart2jsTarget with TestTarget, TestTargetMixin {
  @override
  final TestTargetFlags flags;

  TestDart2jsTarget(String name, this.flags,
      {dart2jsOptions.CompilerOptions? options})
      : super(name, flags, options: options);
}

class TestDevCompilerTarget extends DevCompilerTarget
    with TestTarget, TestTargetMixin {
  @override
  final TestTargetFlags flags;

  TestDevCompilerTarget(this.flags) : super(flags);
}
