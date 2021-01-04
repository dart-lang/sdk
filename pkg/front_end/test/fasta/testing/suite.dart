// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE.md file.

library fasta.testing.suite;

import 'dart:convert' show jsonDecode;

import 'dart:io' show Directory, File, Platform;

import 'package:_fe_analyzer_shared/src/util/colors.dart' as colors;

import 'package:front_end/src/api_prototype/compiler_options.dart'
    show
        CompilerOptions,
        DiagnosticMessage,
        parseExperimentalArguments,
        parseExperimentalFlags;

import 'package:front_end/src/api_prototype/compiler_options.dart'
    show CompilerOptions, DiagnosticMessage;

import 'package:front_end/src/api_prototype/constant_evaluator.dart'
    show ConstantEvaluator, ErrorReporter, EvaluationMode;

import 'package:front_end/src/api_prototype/experimental_flags.dart'
    show
        AllowedExperimentalFlags,
        ExperimentalFlag,
        defaultAllowedExperimentalFlags,
        isExperimentEnabled;

import 'package:front_end/src/api_prototype/standard_file_system.dart'
    show StandardFileSystem;

import 'package:front_end/src/base/libraries_specification.dart'
    show LibraryInfo;

import 'package:front_end/src/base/processed_options.dart'
    show ProcessedOptions;

import 'package:front_end/src/compute_platform_binaries_location.dart'
    show computePlatformBinariesLocation;

import 'package:front_end/src/base/command_line_options.dart';

import 'package:front_end/src/base/nnbd_mode.dart';

import 'package:front_end/src/fasta/compiler_context.dart' show CompilerContext;

import 'package:front_end/src/fasta/dill/dill_target.dart' show DillTarget;

import 'package:front_end/src/fasta/kernel/class_hierarchy_builder.dart'
    show ClassHierarchyNode;

import 'package:front_end/src/fasta/kernel/kernel_builder.dart'
    show ClassHierarchyBuilder;

import 'package:front_end/src/fasta/kernel/kernel_target.dart'
    show KernelTarget;

import 'package:front_end/src/fasta/messages.dart' show LocatedMessage;

import 'package:front_end/src/fasta/ticker.dart' show Ticker;

import 'package:front_end/src/fasta/uri_translator.dart' show UriTranslator;

import 'package:front_end/src/fasta/kernel/verifier.dart' show verifyComponent;

import 'package:kernel/ast.dart'
    show
        AwaitExpression,
        BasicLiteral,
        Component,
        Constant,
        ConstantExpression,
        Expression,
        FileUriExpression,
        FileUriNode,
        InvalidExpression,
        Library,
        Member,
        Node,
        NonNullableByDefaultCompiledMode,
        TreeNode,
        UnevaluatedConstant,
        Version,
        Visitor;

import 'package:kernel/class_hierarchy.dart' show ClassHierarchy;

import 'package:kernel/core_types.dart' show CoreTypes;

import 'package:kernel/kernel.dart'
    show RecursiveVisitor, loadComponentFromBytes;

import 'package:kernel/reference_from_index.dart' show ReferenceFromIndex;

import 'package:kernel/target/changed_structure_notifier.dart'
    show ChangedStructureNotifier;

import 'package:kernel/target/targets.dart'
    show
        ConstantsBackend,
        DiagnosticReporter,
        NoneConstantsBackend,
        NoneTarget,
        LateLowering,
        Target,
        TargetFlags;

import 'package:kernel/target/targets.dart'
    show
        ConstantsBackend,
        DiagnosticReporter,
        NoneConstantsBackend,
        NoneTarget,
        NumberSemantics,
        Target,
        TargetFlags;

import 'package:kernel/type_environment.dart'
    show StaticTypeContext, TypeEnvironment;

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

import '../../utils/kernel_chain.dart'
    show
        ComponentResult,
        KernelTextSerialization,
        MatchContext,
        MatchExpectation,
        Print,
        TypeCheck,
        WriteDill;

import '../../utils/validating_instrumentation.dart'
    show ValidatingInstrumentation;

export 'package:testing/testing.dart' show Chain, runMe;

const String ENABLE_FULL_COMPILE = " full compile ";

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
  }
]
''';

const String KERNEL_TEXT_SERIALIZATION = " kernel text serialization ";

final Expectation runtimeError = ExpectationSet.Default["RuntimeError"];

const String experimentalFlagOptions = '--enable-experiment=';
const String overwriteCurrentSdkVersion = '--overwrite-current-sdk-version=';
const String noVerifyCmd = '--no-verify';

/// Options used for all tests within a given folder.
///
/// This is used for instance for defining target, mode, and experiment specific
/// test folders.
class FolderOptions {
  final Map<ExperimentalFlag, bool> _explicitExperimentalFlags;
  final int forceLateLowerings;
  final bool forceLateLoweringSentinel;
  final bool forceStaticFieldLowering;
  final bool forceNoExplicitGetterCalls;
  final bool nnbdAgnosticMode;
  final Map<String, String> defines;
  final bool noVerify;
  final String target;
  final String overwriteCurrentSdkVersion;

  FolderOptions(this._explicitExperimentalFlags,
      {this.forceLateLowerings: LateLowering.none,
      this.forceLateLoweringSentinel: false,
      this.forceStaticFieldLowering: false,
      this.forceNoExplicitGetterCalls: false,
      this.nnbdAgnosticMode: false,
      this.defines: const {},
      this.noVerify: false,
      this.target: "vm",
      // can be null
      this.overwriteCurrentSdkVersion})
      : assert(forceLateLowerings != null),
        assert(forceLateLoweringSentinel != null),
        assert(forceStaticFieldLowering != null),
        assert(forceNoExplicitGetterCalls != null),
        assert(nnbdAgnosticMode != null),
        assert(
            // no this doesn't make any sense but left to underline
            // that this is allowed to be null!
            defines != null || defines == null),
        assert(noVerify != null),
        assert(target != null);

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
  final NnbdMode nnbdMode;
  final AllowedExperimentalFlags allowedExperimentalFlags;
  final Map<ExperimentalFlag, Version> experimentEnabledVersion;
  final Map<ExperimentalFlag, Version> experimentReleasedVersion;
  Component component;
  List<Iterable<String>> errors;

  TestOptions(this.linkDependencies,
      {this.nnbdMode,
      this.allowedExperimentalFlags,
      this.experimentEnabledVersion,
      this.experimentReleasedVersion})
      : assert(linkDependencies != null);
}

class FastaContext extends ChainContext with MatchContext {
  final Uri baseUri;
  final List<Step> steps;
  final Uri vm;
  final bool onlyCrashes;
  final Map<ExperimentalFlag, bool> explicitExperimentalFlags;
  final bool skipVm;
  final bool verify;
  final bool weak;
  final Map<Component, KernelTarget> componentToTarget =
      <Component, KernelTarget>{};
  final Map<Component, List<Iterable<String>>> componentToDiagnostics =
      <Component, List<Iterable<String>>>{};
  final Uri platformBinaries;
  final Map<UriConfiguration, UriTranslator> _uriTranslators = {};
  final Map<Uri, FolderOptions> _folderOptions = {};
  final Map<Uri, TestOptions> _testOptions = {};
  final Map<Uri, Uri> _librariesJson = {};

  @override
  final bool updateExpectations;

  @override
  String get updateExpectationsOption => '${UPDATE_EXPECTATIONS}=true';

  @override
  final ExpectationSet expectationSet =
      new ExpectationSet.fromJsonList(jsonDecode(EXPECTATIONS));

  Uri platformUri;

  Component platform;

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
      bool kernelTextSerialization,
      bool fullCompile,
      this.verify,
      this.weak)
      : steps = <Step>[
          new Outline(fullCompile, updateComments: updateComments),
          const Print(),
          new Verify(fullCompile)
        ] {
    String fullPrefix;
    String outlinePrefix;
    if (weak) {
      fullPrefix = '.weak';
      outlinePrefix = '.weak.outline';
    } else {
      fullPrefix = '.strong';
      outlinePrefix = '.outline';
    }

    if (!fullCompile) {
      // If not doing a full compile this is the only expect file so we run the
      // extra constant evaluation now. If we do a full compilation, we'll do
      // if after the transformation. That also ensures we don't get the same
      // 'extra constant evaluation' output twice (in .transformed and not).
      steps.add(const StressConstantEvaluatorStep());
    }
    if (!ignoreExpectations) {
      steps.add(new MatchExpectation(
          fullCompile ? "$fullPrefix.expect" : "$outlinePrefix.expect",
          serializeFirst: false,
          isLastMatchStep: updateExpectations));
      if (!updateExpectations) {
        steps.add(new MatchExpectation(
            fullCompile ? "$fullPrefix.expect" : "$outlinePrefix.expect",
            serializeFirst: true,
            isLastMatchStep: true));
      }
    }
    steps.add(const TypeCheck());
    steps.add(const EnsureNoErrors());
    if (kernelTextSerialization) {
      steps.add(const KernelTextSerialization());
    }
    if (fullCompile) {
      steps.add(const Transform());
      steps.add(const StressConstantEvaluatorStep());
      if (!ignoreExpectations) {
        steps.add(new MatchExpectation("$fullPrefix.transformed.expect",
            serializeFirst: false, isLastMatchStep: updateExpectations));
        if (!updateExpectations) {
          steps.add(new MatchExpectation("$fullPrefix.transformed.expect",
              serializeFirst: true, isLastMatchStep: true));
        }
      }
      steps.add(const EnsureNoErrors());
      if (!skipVm) {
        steps.add(const WriteDill());
        steps.add(const Run());
      }
    }
  }

  FolderOptions _computeFolderOptions(Directory directory) {
    FolderOptions folderOptions = _folderOptions[directory.uri];
    if (folderOptions == null) {
      int forceLateLowering = LateLowering.none;
      bool forceLateLoweringSentinel = false;
      bool forceStaticFieldLowering = false;
      bool forceNoExplicitGetterCalls = false;
      bool nnbdAgnosticMode = false;
      bool noVerify = false;
      Map<String, String> defines = {};
      String target = "vm";
      if (directory.uri == baseUri) {
        folderOptions = new FolderOptions({},
            forceLateLowerings: forceLateLowering,
            forceLateLoweringSentinel: forceLateLoweringSentinel,
            forceStaticFieldLowering: forceStaticFieldLowering,
            forceNoExplicitGetterCalls: forceNoExplicitGetterCalls,
            nnbdAgnosticMode: nnbdAgnosticMode,
            defines: defines,
            noVerify: noVerify,
            target: target);
      } else {
        File optionsFile =
            new File.fromUri(directory.uri.resolve('folder.options'));
        if (optionsFile.existsSync()) {
          List<String> experimentalFlagsArguments = [];
          String overwriteCurrentSdkVersionArgument = null;
          for (String line in optionsFile.readAsStringSync().split('\n')) {
            line = line.trim();
            if (line.startsWith(experimentalFlagOptions)) {
              experimentalFlagsArguments =
                  line.substring(experimentalFlagOptions.length).split('\n');
            } else if (line.startsWith(overwriteCurrentSdkVersion)) {
              overwriteCurrentSdkVersionArgument =
                  line.substring(overwriteCurrentSdkVersion.length);
            } else if (line.startsWith(Flags.forceLateLoweringSentinel)) {
              forceLateLoweringSentinel = true;
            } else if (line.startsWith('${Flags.forceLateLowering}=')) {
              int mask = int.parse(
                  line.substring('${Flags.forceLateLowering}='.length));
              forceLateLowering = mask;
            } else if (line.startsWith(Flags.forceLateLowering)) {
              forceLateLowering = LateLowering.all;
            } else if (line.startsWith(Flags.forceStaticFieldLowering)) {
              forceStaticFieldLowering = true;
            } else if (line.startsWith(Flags.forceNoExplicitGetterCalls)) {
              forceNoExplicitGetterCalls = true;
            } else if (line.startsWith(Flags.forceNoExplicitGetterCalls)) {
              forceNoExplicitGetterCalls = true;
            } else if (line.startsWith(Flags.nnbdAgnosticMode)) {
              nnbdAgnosticMode = true;
            } else if (line.startsWith(Flags.noDefines)) {
              if (defines == null) {
                throw "Specifying ${Flags.noDefines} several times "
                    "is unsupported.";
              }
              if (defines.isNotEmpty) {
                throw "Can't have no defines and specific defines "
                    "at the same time.";
              }
              defines = null;
            } else if (line.startsWith("-D")) {
              if (defines == null) {
                throw "Can't have no defines and specific defines "
                    "at the same time.";
              }
              String define = line.substring(2); // removes "-D".
              int index = define.indexOf('=');
              String name;
              String expression;
              if (index != -1) {
                name = define.substring(0, index);
                expression = define.substring(index + 1);
              } else {
                name = define;
                expression = define;
              }
              if (defines.containsKey(name)) {
                throw "Defining '$name' several times is unsupported.";
              }
              defines[name] = expression;
            } else if (line.startsWith(noVerifyCmd)) {
              noVerify = true;
            } else if (line.startsWith(Flags.target) &&
                line.indexOf('=') == Flags.target.length) {
              target = line.substring(Flags.target.length + 1);
            } else if (line.isNotEmpty) {
              throw new UnsupportedError("Unsupported test option '$line'");
            }
          }

          folderOptions = new FolderOptions(
              parseExperimentalFlags(
                  parseExperimentalArguments(experimentalFlagsArguments),
                  onError: (String message) => throw new ArgumentError(message),
                  onWarning: (String message) =>
                      throw new ArgumentError(message)),
              forceLateLowerings: forceLateLowering,
              forceLateLoweringSentinel: forceLateLoweringSentinel,
              forceStaticFieldLowering: forceStaticFieldLowering,
              forceNoExplicitGetterCalls: forceNoExplicitGetterCalls,
              nnbdAgnosticMode: nnbdAgnosticMode,
              defines: defines,
              noVerify: noVerify,
              target: target,
              overwriteCurrentSdkVersion: overwriteCurrentSdkVersionArgument);
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
    UriTranslator uriTranslator = _uriTranslators[uriConfiguration];
    if (uriTranslator == null) {
      Uri sdk = Uri.base.resolve("sdk/");
      Uri packages = Uri.base.resolve(".packages");
      FolderOptions folderOptions = computeFolderOptions(description);
      CompilerOptions compilerOptions = new CompilerOptions()
        ..onDiagnostic = (DiagnosticMessage message) {
          throw message.plainTextFormatted.join("\n");
        }
        ..sdkRoot = sdk
        ..packagesFileUri = uriConfiguration.packageConfigUri ?? packages
        ..environmentDefines = folderOptions.defines
        ..explicitExperimentalFlags = folderOptions
            .computeExplicitExperimentalFlags(explicitExperimentalFlags)
        ..nnbdMode = weak
            ? NnbdMode.Weak
            : (folderOptions.nnbdAgnosticMode
                ? NnbdMode.Agnostic
                : NnbdMode.Strong)
        ..librariesSpecificationUri =
            uriConfiguration.librariesSpecificationUri;
      if (folderOptions.overwriteCurrentSdkVersion != null) {
        compilerOptions.currentSdkVersion =
            folderOptions.overwriteCurrentSdkVersion;
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
    TestOptions testOptions = _testOptions[directory.uri];
    if (testOptions == null) {
      File optionsFile =
          new File.fromUri(directory.uri.resolve('test.options'));
      Set<Uri> linkDependencies = new Set<Uri>();
      NnbdMode nnbdMode;
      AllowedExperimentalFlags allowedExperimentalFlags;
      Map<ExperimentalFlag, Version> experimentEnabledVersion;
      Map<ExperimentalFlag, Version> experimentReleasedVersion;
      if (optionsFile.existsSync()) {
        for (String line in optionsFile.readAsStringSync().split('\n')) {
          line = line.trim();
          if (line.isEmpty) continue;
          if (line.startsWith(Flags.nnbdAgnosticMode)) {
            if (nnbdMode != null) {
              throw new UnsupportedError(
                  'Nnbd mode $nnbdMode already specified.');
            }
            nnbdMode = NnbdMode.Agnostic;
          } else if (line.startsWith(Flags.nnbdStrongMode)) {
            if (nnbdMode != null) {
              throw new UnsupportedError(
                  'Nnbd mode $nnbdMode already specified.');
            }
            nnbdMode = NnbdMode.Strong;
          } else if (line.startsWith(Flags.nnbdWeakMode)) {
            if (nnbdMode != null) {
              throw new UnsupportedError(
                  'Nnbd mode $nnbdMode already specified.');
            }
            nnbdMode = NnbdMode.Weak;
          } else if (line == '--fix-nnbd-release-version') {
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
          } else {
            Uri uri = description.uri.resolve(line);
            if (uri.scheme != 'package') {
              File f = new File.fromUri(uri);
              if (!f.existsSync()) {
                throw new UnsupportedError("No file found: $f ($line)");
              }
              uri = f.uri;
            }
            linkDependencies.add(uri);
          }
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
  Uri computeLibrariesSpecificationUri(TestDescription description) {
    Directory directory = new File.fromUri(description.uri).parent;
    if (_librariesJson.containsKey(directory.uri)) {
      return _librariesJson[directory.uri];
    } else {
      Uri librariesJson;
      File jsonFile = new File.fromUri(directory.uri.resolve('libraries.json'));
      if (jsonFile.existsSync()) {
        librariesJson = jsonFile.uri;
      }
      return _librariesJson[directory.uri] = librariesJson;
    }
  }

  /// Custom package config used for [description].
  Uri computePackageConfigUri(TestDescription description) {
    Uri packageConfig =
        description.uri.resolve(".dart_tool/package_config.json");
    return new File.fromUri(packageConfig).existsSync() ? packageConfig : null;
  }

  UriConfiguration computeUriConfiguration(TestDescription description) {
    Uri librariesSpecificationUri =
        computeLibrariesSpecificationUri(description);
    Uri packageConfigUri = computePackageConfigUri(description);
    return new UriConfiguration(librariesSpecificationUri, packageConfigUri);
  }

  Expectation get verificationError => expectationSet["VerificationError"];

  Future ensurePlatformUris() async {
    if (platformUri == null) {
      platformUri = platformBinaries.resolve("vm_platform_strong.dill");
    }
  }

  Future<Component> loadPlatform() async {
    if (platform == null) {
      await ensurePlatformUris();
      platform = loadComponentFromBytes(
          new File.fromUri(platformUri).readAsBytesSync());
    }
    return platform;
  }

  @override
  Result processTestResult(
      TestDescription description, Result result, bool last) {
    if (onlyCrashes) {
      Expectation outcome = result.outcome;
      if (outcome == Expectation.Crash || outcome == verificationError) {
        return result;
      }
      return result.copyWithOutcome(Expectation.Pass);
    }
    return super.processTestResult(description, result, last);
  }

  @override
  Set<Expectation> processExpectedOutcomes(
      Set<Expectation> outcomes, TestDescription description) {
    if (skipVm && outcomes.length == 1 && outcomes.single == runtimeError) {
      return new Set<Expectation>.from([Expectation.Pass]);
    } else {
      return outcomes;
    }
  }

  static Future<FastaContext> create(
      Chain suite, Map<String, String> environment) async {
    Uri vm = Uri.base.resolveUri(new Uri.file(Platform.resolvedExecutable));
    Map<ExperimentalFlag, bool> experimentalFlags = <ExperimentalFlag, bool>{};

    void addForcedExperimentalFlag(String name, ExperimentalFlag flag) {
      if (environment.containsKey(name)) {
        experimentalFlags[flag] = environment[name] == "true";
      }
    }

    addForcedExperimentalFlag(
        "enableExtensionMethods", ExperimentalFlag.extensionMethods);
    addForcedExperimentalFlag(
        "enableNonNullable", ExperimentalFlag.nonNullable);

    bool weak = environment["weak"] == "true";
    bool onlyCrashes = environment["onlyCrashes"] == "true";
    bool ignoreExpectations = environment["ignoreExpectations"] == "true";
    bool updateExpectations = environment[UPDATE_EXPECTATIONS] == "true";
    bool updateComments = environment[UPDATE_COMMENTS] == "true";
    bool skipVm = environment["skipVm"] == "true";
    bool verify = environment["verify"] != "false";
    bool kernelTextSerialization =
        environment.containsKey(KERNEL_TEXT_SERIALIZATION);
    String platformBinaries = environment["platformBinaries"];
    if (platformBinaries != null && !platformBinaries.endsWith('/')) {
      platformBinaries = '$platformBinaries/';
    }
    return new FastaContext(
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
        kernelTextSerialization,
        environment.containsKey(ENABLE_FULL_COMPILE),
        verify,
        weak);
  }
}

class Run extends Step<ComponentResult, int, FastaContext> {
  const Run();

  String get name => "run";

  bool get isAsync => true;

  bool get isRuntime => true;

  Future<Result<int>> run(ComponentResult result, FastaContext context) async {
    FolderOptions folderOptions =
        context.computeFolderOptions(result.description);
    Map<ExperimentalFlag, bool> experimentalFlags = folderOptions
        .computeExplicitExperimentalFlags(context.explicitExperimentalFlags);
    switch (folderOptions.target) {
      case "vm":
        if (context.platformUri == null) {
          throw "Executed `Run` step before initializing the context.";
        }
        File generated = new File.fromUri(result.outputUri);
        StdioProcess process;
        try {
          var args = <String>[];
          if (experimentalFlags[ExperimentalFlag.nonNullable] == true) {
            args.add("--enable-experiment=non-nullable");
            if (!context.weak) {
              args.add("--sound-null-safety");
            }
          }
          args.add(generated.path);
          process = await StdioProcess.run(context.vm.toFilePath(), args);
          print(process.output);
        } finally {
          await generated.parent.delete(recursive: true);
        }
        Result<int> runResult = process.toResult();
        if (result.component.mode == NonNullableByDefaultCompiledMode.Invalid) {
          // In this case we expect and want a runtime error.
          if (runResult.outcome == ExpectationSet.Default["RuntimeError"]) {
            // We convert this to pass because that's exactly what we'd expect.
            return pass(0);
          } else {
            // Different outcome - that's a failure!
            return new Result<int>(runResult.output,
                ExpectationSet.Default["MissingRuntimeError"], runResult.error);
          }
        }
        return runResult;
      case "none":
      case "noneWithJs":
        return pass(0);
      default:
        throw new ArgumentError(
            "Unsupported run target '${folderOptions.target}'.");
    }
  }
}

class StressConstantEvaluatorStep
    extends Step<ComponentResult, ComponentResult, FastaContext> {
  const StressConstantEvaluatorStep();

  String get name => "stress constant evaluator";

  Future<Result<ComponentResult>> run(
      ComponentResult result, FastaContext context) async {
    KernelTarget target = result.sourceTarget;
    ConstantsBackend constantsBackend =
        target.backendTarget.constantsBackend(target.loader.coreTypes);
    TypeEnvironment environment =
        new TypeEnvironment(target.loader.coreTypes, target.loader.hierarchy);
    StressConstantEvaluatorVisitor stressConstantEvaluatorVisitor =
        new StressConstantEvaluatorVisitor(
      constantsBackend,
      result.options.environmentDefines,
      target.isExperimentEnabledGlobally(ExperimentalFlag.tripleShift),
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
    return pass(result);
  }
}

class StressConstantEvaluatorVisitor extends RecursiveVisitor<Node>
    implements ErrorReporter {
  ConstantEvaluator constantEvaluator;
  ConstantEvaluator constantEvaluatorWithEmptyEnvironment;
  int tries = 0;
  int success = 0;
  List<String> output = [];

  StressConstantEvaluatorVisitor(
      ConstantsBackend backend,
      Map<String, String> environmentDefines,
      bool enableTripleShift,
      TypeEnvironment typeEnvironment,
      bool desugarSets,
      bool errorOnUnevaluatedConstant,
      EvaluationMode evaluationMode) {
    constantEvaluator = new ConstantEvaluator(
        backend, environmentDefines, typeEnvironment, this,
        enableTripleShift: enableTripleShift,
        errorOnUnevaluatedConstant: errorOnUnevaluatedConstant,
        evaluationMode: evaluationMode);
    constantEvaluatorWithEmptyEnvironment = new ConstantEvaluator(
        backend, {}, typeEnvironment, this,
        enableTripleShift: enableTripleShift,
        errorOnUnevaluatedConstant: errorOnUnevaluatedConstant,
        evaluationMode: evaluationMode);
  }

  Library currentLibrary;
  Library visitLibrary(Library node) {
    currentLibrary = node;
    node.visitChildren(this);
    currentLibrary = null;
    return node;
  }

  Member currentMember;

  Node defaultMember(Member node) {
    Member prevCurrentMember = currentMember;
    currentMember = node;
    node.visitChildren(this);
    currentMember = prevCurrentMember;
    return node;
  }

  Node defaultExpression(Expression node) {
    if (node is BasicLiteral) return node;
    if (node is InvalidExpression) return node;
    if (node is ConstantExpression) {
      bool evaluate = false;
      if (node.constant is UnevaluatedConstant) {
        UnevaluatedConstant unevaluatedConstant = node.constant;
        if (unevaluatedConstant.expression is! InvalidExpression) {
          evaluate = true;
        }
      }
      if (!evaluate) return node;
      if (constantEvaluator.environmentDefines != null) {
        throw "Unexpected UnevaluatedConstant "
            "when the environment is not null.";
      }
    }

    // Try to evaluate it as a constant.
    tries++;
    StaticTypeContext staticTypeContext;
    if (currentMember == null) {
      staticTypeContext = new StaticTypeContext.forAnnotations(
          currentLibrary, constantEvaluator.typeEnvironment);
    } else {
      staticTypeContext = new StaticTypeContext(
          currentMember, constantEvaluator.typeEnvironment);
    }
    Constant x = constantEvaluator.evaluate(staticTypeContext, node);
    bool evaluatedWithEmptyEnvironment = false;
    if (x is UnevaluatedConstant && x.expression is! InvalidExpression) {
      // try with an environment
      if (constantEvaluator.environmentDefines != null) {
        throw "Unexpected UnevaluatedConstant (with an InvalidExpression in "
            "it) when the environment is not null.";
      }
      x = constantEvaluatorWithEmptyEnvironment.evaluate(
          new StaticTypeContext(
              currentMember, constantEvaluator.typeEnvironment),
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
      TreeNode n = node;
      while (n != null && n is! FileUriNode) {
        n = n.parent;
      }
      if (n == null) return "(unknown location)";
      FileUriNode fileUriNode = n;
      return ("(unknown position in ${fileUriNode.fileUri})");
    }
  }

  @override
  void report(LocatedMessage message, List<LocatedMessage> context) {
    // ignored.
  }

  @override
  void reportInvalidExpression(InvalidExpression node) {
    // ignored.
  }
}

class Outline extends Step<TestDescription, ComponentResult, FastaContext> {
  final bool fullCompile;

  const Outline(this.fullCompile, {this.updateComments: false});

  final bool updateComments;

  String get name {
    return fullCompile ? "compile" : "outline";
  }

  bool get isCompiler => fullCompile;

  Future<Result<ComponentResult>> run(
      TestDescription description, FastaContext context) async {
    List<Iterable<String>> errors = <Iterable<String>>[];

    Uri librariesSpecificationUri =
        context.computeLibrariesSpecificationUri(description);
    TestOptions testOptions = context.computeTestOptions(description);
    FolderOptions folderOptions = context.computeFolderOptions(description);
    Map<ExperimentalFlag, bool> experimentalFlags = folderOptions
        .computeExplicitExperimentalFlags(context.explicitExperimentalFlags);
    NnbdMode nnbdMode = context.weak ||
            !isExperimentEnabled(ExperimentalFlag.nonNullable,
                explicitExperimentalFlags: experimentalFlags)
        ? NnbdMode.Weak
        : (folderOptions.nnbdAgnosticMode
            ? NnbdMode.Agnostic
            : NnbdMode.Strong);
    List<Uri> inputs = <Uri>[description.uri];

    ProcessedOptions createProcessedOptions(
        NnbdMode nnbdMode,
        AllowedExperimentalFlags allowedExperimentalFlags,
        Map<ExperimentalFlag, Version> experimentEnabledVersion,
        Map<ExperimentalFlag, Version> experimentReleasedVersion) {
      CompilerOptions compilerOptions = new CompilerOptions()
        ..onDiagnostic = (DiagnosticMessage message) {
          errors.add(message.plainTextFormatted);
        }
        ..environmentDefines = folderOptions.defines
        ..explicitExperimentalFlags = experimentalFlags
        ..nnbdMode = nnbdMode
        ..librariesSpecificationUri = librariesSpecificationUri
        ..allowedExperimentalFlagsForTesting = allowedExperimentalFlags
        ..experimentEnabledVersionForTesting = experimentEnabledVersion
        ..experimentReleasedVersionForTesting = experimentReleasedVersion;
      if (folderOptions.overwriteCurrentSdkVersion != null) {
        compilerOptions.currentSdkVersion =
            folderOptions.overwriteCurrentSdkVersion;
      }
      return new ProcessedOptions(options: compilerOptions, inputs: inputs);
    }

    // Disable colors to ensure that expectation files are the same across
    // platforms and independent of stdin/stderr.
    colors.enableColors = false;

    ProcessedOptions options = createProcessedOptions(
        nnbdMode,
        testOptions.allowedExperimentalFlags,
        testOptions.experimentEnabledVersion,
        testOptions.experimentReleasedVersion);

    if (testOptions.linkDependencies.isNotEmpty &&
        testOptions.component == null) {
      // Compile linked dependency.
      ProcessedOptions linkOptions = options;
      if (testOptions.nnbdMode != null) {
        linkOptions = createProcessedOptions(
            testOptions.nnbdMode,
            testOptions.allowedExperimentalFlags,
            testOptions.experimentEnabledVersion,
            testOptions.experimentReleasedVersion);
      }
      await CompilerContext.runWithOptions(linkOptions, (_) async {
        KernelTarget sourceTarget = await outlineInitialization(context,
            description, folderOptions, testOptions.linkDependencies.toList());
        if (testOptions.errors != null) {
          errors.addAll(testOptions.errors);
        }
        Component p = await sourceTarget.buildOutlines();
        if (fullCompile) {
          p = await sourceTarget.buildComponent(
              verify: folderOptions.noVerify ? false : context.verify);
        }

        // To avoid possible crash in mixin transformation in the transformation
        // of the user of this linked dependency we have to transform this too.
        // We do that now.
        Target backendTarget = sourceTarget.backendTarget;
        if (backendTarget is TestVmTarget) {
          backendTarget.enabled = true;
        }
        try {
          if (sourceTarget.loader.coreTypes != null) {
            sourceTarget.runBuildTransformations();
          }
        } finally {
          if (backendTarget is TestVmTarget) {
            backendTarget.enabled = false;
          }
        }

        testOptions.component = p;
        List<Library> keepLibraries = <Library>[];
        for (Library lib in p.libraries) {
          if (testOptions.linkDependencies.contains(lib.importUri)) {
            keepLibraries.add(lib);
          }
        }
        p.libraries.clear();
        p.libraries.addAll(keepLibraries);
        testOptions.errors = errors.toList();
        errors.clear();
      });
    }

    return await CompilerContext.runWithOptions(options, (_) async {
      Component alsoAppend = testOptions.component;
      if (description.uri.pathSegments.last.endsWith(".no_link.dart")) {
        alsoAppend = null;
      }
      KernelTarget sourceTarget = await outlineInitialization(
          context, description, folderOptions, <Uri>[description.uri],
          alsoAppend: alsoAppend);
      ValidatingInstrumentation instrumentation =
          new ValidatingInstrumentation();
      await instrumentation.loadExpectations(description.uri);
      sourceTarget.loader.instrumentation = instrumentation;
      Component p = await sourceTarget.buildOutlines();
      context.componentToTarget.clear();
      context.componentToTarget[p] = sourceTarget;
      context.componentToDiagnostics.clear();
      context.componentToDiagnostics[p] = errors;
      Set<Uri> userLibraries = p.libraries
          .where((Library library) =>
              library.importUri.scheme != 'dart' &&
              library.importUri.scheme != 'package')
          .map((Library library) => library.importUri)
          .toSet();
      // Mark custom dart: libraries defined in the test-specific libraries.json
      // file as user libraries.
      UriTranslator uriTranslator = sourceTarget.uriTranslator;
      userLibraries.addAll(uriTranslator.dartLibraries.allLibraries
          .map((LibraryInfo info) => info.importUri));
      if (fullCompile) {
        p = await sourceTarget.buildComponent(
            verify: folderOptions.noVerify ? false : context.verify);
        instrumentation.finish();
        if (instrumentation.hasProblems) {
          if (updateComments) {
            await instrumentation.fixSource(description.uri, false);
          } else {
            return new Result<ComponentResult>(
                new ComponentResult(
                    description, p, userLibraries, options, sourceTarget),
                context.expectationSet["InstrumentationMismatch"],
                instrumentation.problemsAsString,
                autoFixCommand: '${UPDATE_COMMENTS}=true');
          }
        }
      }
      return pass(new ComponentResult(
          description, p, userLibraries, options, sourceTarget));
    });
  }

  Future<KernelTarget> outlineInitialization(
      FastaContext context,
      TestDescription description,
      FolderOptions testOptions,
      List<Uri> entryPoints,
      {Component alsoAppend}) async {
    Component platform = await context.loadPlatform();
    Ticker ticker = new Ticker();
    UriTranslator uriTranslator =
        await context.computeUriTranslator(description);
    TargetFlags targetFlags = new TargetFlags(
      forceLateLoweringsForTesting: testOptions.forceLateLowerings,
      forceLateLoweringSentinelForTesting:
          testOptions.forceLateLoweringSentinel,
      forceStaticFieldLoweringForTesting: testOptions.forceStaticFieldLowering,
      forceNoExplicitGetterCallsForTesting:
          testOptions.forceNoExplicitGetterCalls,
      enableNullSafety: !context.weak,
    );
    Target target;
    switch (testOptions.target) {
      case "vm":
        target = new TestVmTarget(targetFlags);
        break;
      case "none":
        target = new NoneTarget(targetFlags);
        break;
      case "noneWithJs":
        target = new NoneWithJsTarget(targetFlags);
        break;
      default:
        throw new ArgumentError(
            "Unsupported test target '${testOptions.target}'.");
    }
    DillTarget dillTarget = new DillTarget(
      ticker,
      uriTranslator,
      target,
    );
    dillTarget.loader.appendLibraries(platform);
    if (alsoAppend != null) {
      dillTarget.loader.appendLibraries(alsoAppend);
    }
    KernelTarget sourceTarget = new KernelTarget(
        StandardFileSystem.instance, false, dillTarget, uriTranslator);

    sourceTarget.setEntryPoints(entryPoints);
    await dillTarget.buildOutlines();
    return sourceTarget;
  }
}

class Transform extends Step<ComponentResult, ComponentResult, FastaContext> {
  const Transform();

  String get name => "transform component";

  Future<Result<ComponentResult>> run(
      ComponentResult result, FastaContext context) async {
    Component component = result.component;
    KernelTarget sourceTarget = context.componentToTarget[component];
    context.componentToTarget.remove(component);
    Target backendTarget = sourceTarget.backendTarget;
    if (backendTarget is TestVmTarget) {
      backendTarget.enabled = true;
    }
    try {
      if (sourceTarget.loader.coreTypes != null) {
        sourceTarget.runBuildTransformations();
      }
    } finally {
      if (backendTarget is TestVmTarget) {
        backendTarget.enabled = false;
      }
    }
    List<String> errors = VerifyTransformed.verify(component);
    if (errors.isNotEmpty) {
      return new Result<ComponentResult>(
          result,
          context.expectationSet["TransformVerificationError"],
          errors.join('\n'));
    }
    return pass(result);
  }
}

class Verify extends Step<ComponentResult, ComponentResult, FastaContext> {
  final bool fullCompile;

  const Verify(this.fullCompile);

  String get name => "verify";

  Future<Result<ComponentResult>> run(
      ComponentResult result, FastaContext context) async {
    FolderOptions folderOptions =
        context.computeFolderOptions(result.description);

    if (folderOptions.noVerify) {
      return pass(result);
    }

    Component component = result.component;
    StringBuffer messages = new StringBuffer();
    ProcessedOptions options = new ProcessedOptions(
        options: new CompilerOptions()
          ..onDiagnostic = (DiagnosticMessage message) {
            if (messages.isNotEmpty) {
              messages.write("\n");
            }
            messages.writeAll(message.plainTextFormatted, "\n");
          });
    return await CompilerContext.runWithOptions(options,
        (compilerContext) async {
      compilerContext.uriToSource.addAll(component.uriToSource);
      List<LocatedMessage> verificationErrors = verifyComponent(component,
          isOutline: !fullCompile, skipPlatform: true);
      assert(verificationErrors.isEmpty || messages.isNotEmpty);
      if (messages.isEmpty) {
        return pass(result);
      } else {
        return new Result<ComponentResult>(
            null, context.expectationSet["VerificationError"], "$messages");
      }
    }, errorOnMissingInput: false);
  }
}

/// Visitor that checks that the component has been transformed properly.
// TODO(johnniwinther): Add checks for all nodes that are unsupported after
// transformation.
class VerifyTransformed extends Visitor<void> {
  List<String> errors = [];

  @override
  void defaultNode(Node node) {
    node.visitChildren(this);
  }

  @override
  void visitAwaitExpression(AwaitExpression node) {
    errors.add("ERROR: Untransformed await expression: $node");
  }

  static List<String> verify(Component component) {
    VerifyTransformed visitor = new VerifyTransformed();
    component.accept(visitor);
    return visitor.errors;
  }
}

class TestVmTarget extends VmTarget {
  bool enabled = false;

  TestVmTarget(TargetFlags flags) : super(flags);

  String get name => "vm";

  @override
  void performModularTransformationsOnLibraries(
      Component component,
      CoreTypes coreTypes,
      ClassHierarchy hierarchy,
      List<Library> libraries,
      Map<String, String> environmentDefines,
      DiagnosticReporter diagnosticReporter,
      ReferenceFromIndex referenceFromIndex,
      {void logger(String msg),
      ChangedStructureNotifier changedStructureNotifier}) {
    if (enabled) {
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
}

class EnsureNoErrors
    extends Step<ComponentResult, ComponentResult, FastaContext> {
  const EnsureNoErrors();

  String get name => "check errors";

  Future<Result<ComponentResult>> run(
      ComponentResult result, FastaContext context) async {
    List<Iterable<String>> errors =
        context.componentToDiagnostics[result.component];
    return errors.isEmpty
        ? pass(result)
        : fail(
            result,
            "Unexpected errors:\n"
            "${errors.map((error) => error.join('\n')).join('\n\n')}");
  }
}

class MatchHierarchy
    extends Step<ComponentResult, ComponentResult, FastaContext> {
  const MatchHierarchy();

  String get name => "check hierarchy";

  Future<Result<ComponentResult>> run(
      ComponentResult result, FastaContext context) async {
    Component component = result.component;
    Uri uri =
        component.uriToSource.keys.firstWhere((uri) => uri?.scheme == "file");
    KernelTarget target = context.componentToTarget[component];
    ClassHierarchyBuilder hierarchy = target.loader.builderHierarchy;
    StringBuffer sb = new StringBuffer();
    for (ClassHierarchyNode node in hierarchy.nodes.values) {
      sb.writeln(node);
    }
    return context.match<ComponentResult>(
        ".hierarchy.expect", "$sb", uri, result);
  }
}

class UriConfiguration {
  final Uri librariesSpecificationUri;
  final Uri packageConfigUri;

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

class NoneWithJsTarget extends NoneTarget {
  NoneWithJsTarget(TargetFlags flags) : super(flags);

  @override
  ConstantsBackend constantsBackend(CoreTypes coreTypes) =>
      const NoneConstantsBackendWithJs(supportsUnevaluatedConstants: true);
}

class NoneConstantsBackendWithJs extends NoneConstantsBackend {
  const NoneConstantsBackendWithJs({bool supportsUnevaluatedConstants})
      : super(supportsUnevaluatedConstants: supportsUnevaluatedConstants);

  @override
  NumberSemantics get numberSemantics => NumberSemantics.js;
}
