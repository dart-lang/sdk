// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:convert" show utf8, json;
import 'dart:io' show File, Platform;
import "dart:typed_data" show Uint8List;

import 'package:_fe_analyzer_shared/src/messages/diagnostic_message.dart'
    show
        CfeDiagnosticMessage,
        getMessageCodeObject,
        getMessageRelatedInformation;
import 'package:_fe_analyzer_shared/src/messages/severity.dart'
    show CfeSeverity;
import 'package:analyzer_utilities/message_examples.dart';
import 'package:analyzer_utilities/messages.dart';
import 'package:analyzer_testing/utilities/extensions/string.dart';
import 'package:front_end/src/api_prototype/compiler_options.dart'
    show CompilerOptions, parseExperimentalArguments, parseExperimentalFlags;
import 'package:front_end/src/api_prototype/experimental_flags.dart'
    show ExperimentalFlag, defaultExperimentalFlags;
import 'package:front_end/src/api_prototype/memory_file_system.dart'
    show MemoryFileSystem;
import 'package:front_end/src/base/command_line_reporting.dart'
    as command_line_reporting;
import 'package:front_end/src/base/hybrid_file_system.dart'
    show HybridFileSystem;
import 'package:front_end/src/base/messages.dart';
import 'package:front_end/src/compute_platform_binaries_location.dart'
    show computePlatformBinariesLocation;
import 'package:kernel/ast.dart' show Location, Source;
import "package:kernel/target/targets.dart" show TargetFlags;
import "package:testing/testing.dart"
    show
        Chain,
        ChainContext,
        Expectation,
        Result,
        Step,
        TestDescription,
        ExpectationSet;
import "package:vm/modular/target/vm.dart" show VmTarget;
import "package:yaml/yaml.dart" show loadYamlNode;

import "../tool/entry_points.dart" show BatchCompiler;
import 'spell_checking_utils.dart' as spell;
import 'utils/suite_utils.dart' show internalMain;

enum KnownExpectation {
  missingExample,
  spellingError,
  missingExternalFile,
  noMessageReported,
  hasCorrectButAlsoOthers,
  hasTooManyCorrect,
  hasTooManyCorrectAndAlsoOthers,
  hasOnlyUnrelatedMessages;

  Expectation expectation(ChainContext context) => context.expectationSet[name];
}

class MessageTestDescription extends TestDescription {
  @override
  final Uri uri;

  @override
  final String shortName;

  final String name;

  final CfeStyleMessage message;

  final Example? example;

  final ({String message, KnownExpectation expectation})? problem;

  new(
    this.uri,
    this.shortName,
    this.name,
    this.message,
    this.example,
    this.problem,
  );
}

class MessageTestSuite extends ChainContext {
  @override
  final List<Step> steps = const <Step>[const Validate(), const Compile()];

  final MemoryFileSystem fileSystem;

  final BatchCompiler compiler;

  final bool fastOnly;
  final bool interactive;
  final bool justAddEverything;
  final bool skipSpellCheck;

  final Map<String, List<String>?> reportedWordsAndAlternatives = {};
  final Set<String> reportedWordsDenylisted = {};

  @override
  final ExpectationSet expectationSet = new ExpectationSet.fromJsonList([
    for (KnownExpectation expectation in KnownExpectation.values)
      {"name": expectation.name, "group": "Fail"},
  ]);

  @override
  Future<void> postRun() {
    String dartPath = Platform.resolvedExecutable;
    Uri suiteUri = spell.repoDir.resolve(
      "pkg/front_end/test/messages_suite.dart",
    );
    File suiteFile = new File.fromUri(suiteUri).absolute;
    if (!suiteFile.existsSync()) {
      throw "Specified suite path is invalid.";
    }
    String suitePath = suiteFile.path;
    spell.spellSummarizeAndInteractiveMode(
      reportedWordsAndAlternatives,
      reportedWordsDenylisted,
      [spell.Dictionaries.cfeMessages],
      interactive,
      justAddEverything,
      '"$dartPath" "$suitePath" -DfastOnly=true -Dinteractive=true',
    );
    return new Future.value();
  }

  new(
    this.fastOnly,
    this.interactive,
    this.justAddEverything,
    this.skipSpellCheck,
  ) : fileSystem = new MemoryFileSystem(Uri.parse("org-dartlang-cfe:///")),
      compiler = new BatchCompiler(null);

  @override
  Set<Expectation> processExpectedOutcomes(
    Set<Expectation> outcomes,
    TestDescription description,
  ) {
    if (description.shortName.contains("/spelling")) {
      return {Expectation.pass};
    }
    return outcomes;
  }

  /// Convert all the examples found in `messages.yaml` to a test
  /// description. In addition, create a test description for each kind of
  /// problem that a message can have. This problem will then be reported as a
  /// failure by the [Validate] step that can be suppressed via the status
  /// file.
  @override
  Future<List<MessageTestDescription>> list(Chain suite) {
    List<MessageTestDescription> result = [];
    var rootString = suite.root.toString();
    for (var subRoot in suite.subRoots) {
      var subRootString = subRoot.toString();
      if (!subRootString.startsWith(rootString)) {
        throw StateError(
          'Expected sub-root ${json.encode(subRootString)} to start with '
          '${json.encode(rootString)}',
        );
      }
      if (!subRootString.endsWith('/')) {
        throw StateError(
          'Expected sub-root ${json.encode(subRootString)} to end with "/"',
        );
      }
      var prefix = subRootString.substring(rootString.length);
      result.addAll(_ListSubRoot(subRoot, prefix: prefix));
    }
    return Future.value(result);
  }

  List<MessageTestDescription> _ListSubRoot(
    Uri root, {
    required String prefix,
  }) {
    List<MessageTestDescription> result = [];
    Uri uri = root.resolve("messages.yaml");
    File file = new File.fromUri(uri);
    String fileContent = file.readAsStringSync();
    CfeStyleMessage Function(MessageYaml) decodeMessage = switch (prefix) {
      "_fe_analyzer_shared/" => SharedMessage.new,
      "front_end/" => FrontEndMessage.new,
      _ => throw new StateError("Unexpected sub-root ${json.encode(prefix)}"),
    };
    List<CfeStyleMessage> messages = decodeCfeStyleMessagesYaml(
      loadYamlNode(fileContent, sourceUrl: uri),
      decodeMessage: decodeMessage,
      path: uri.toFilePath(),
    );
    for (CfeStyleMessage message in messages) {
      String camelCaseName = message.keyString;
      try {
        // TODO(paulberry): switch CFE to camelCase conventions.
        var name = camelCaseName.toSnakeCase().toPascalCase();

        bool exampleAllowOtherCodes = message.exampleAllowOtherCodes;
        bool exampleAllowMultipleReports = message.exampleAllowMultipleReports;
        bool includeErrorContext = message.includeErrorContext;
        List<Example> examples = <Example>[
          for (MessageExample example in message.examples)
            new MessageYamlExample(name, example),
        ];
        String? externalTest = message.externalExample;
        CfeSeverity? severity = switch (message.cfeSeverity) {
          String cfeSeverity => CfeSeverity.values.byName(cfeSeverity),
          null => null,
        };
        List<String>? spellingMessages;
        const String spellingPostMessage =
            "\nIf the word(s) look okay, update "
            "'spell_checking_list_messages.txt' or "
            "'spell_checking_list_common.txt'.";
        Map<ExperimentalFlag, bool>? experimentalFlags =
            message.experiments.isEmpty
            ? null
            : parseExperimentalFlags(
                parseExperimentalArguments(message.experiments),
                onError: (message) => throw new ArgumentError(message),
              );

        Source? source;
        List<String> formatSpellingMistakes(
          spell.SpellingResult spellResult,
          int offset,
          String message,
          String messageForDenyListed,
        ) {
          if (source == null) {
            Uint8List bytes = file.readAsBytesSync();
            List<int> lineStarts = <int>[];
            int indexOf = 0;
            while (indexOf >= 0) {
              lineStarts.add(indexOf);
              indexOf = bytes.indexOf(10, indexOf + 1);
            }
            lineStarts.add(bytes.length);
            source = new Source(lineStarts, bytes, uri, uri);
          }
          List<String> result = <String>[];
          for (int i = 0; i < spellResult.misspelledWords!.length; i++) {
            Location location = source!.getLocation(
              uri,
              offset + spellResult.misspelledWordsOffset![i],
            );
            bool denylisted = spellResult.misspelledWordsDenylisted![i];
            String messageToUse = message;
            if (denylisted) {
              messageToUse = messageForDenyListed;
              reportedWordsDenylisted.add(spellResult.misspelledWords![i]);
            } else {
              reportedWordsAndAlternatives[spellResult.misspelledWords![i]] =
                  spellResult.misspelledWordsAlternatives![i];
            }
            result.add(
              command_line_reporting.formatErrorMessage(
                source!.getTextLine(location.line),
                location,
                spellResult.misspelledWords![i].length,
                relativize(uri),
                "$messageToUse: '${spellResult.misspelledWords![i]}'.",
              ),
            );
          }
          return result;
        }

        if (!skipSpellCheck) {
          for (var (span, key) in [
            (message.problemMessageSpan, "problemMessage"),
            (message.correctionMessageSpan, "correctionMessage"),
          ]) {
            if (span == null) continue;
            // When positions matter, use span.text.
            // When using span.text, replace r"\n" with "\n\n" to replace two
            // characters with two characters without actually having the
            // string "backslash n".
            spell.SpellingResult spellingResult = spell.spellcheckString(
              span.text
                  .replaceAll(placeholderPattern, '*')
                  .replaceAll(r"\n", "\n\n"),
              dictionaries: const [
                spell.Dictionaries.common,
                spell.Dictionaries.cfeMessages,
              ],
            );
            if (spellingResult.misspelledWords != null) {
              spellingMessages ??= <String>[];
              spellingMessages.addAll(
                formatSpellingMistakes(
                  spellingResult,
                  span.start.offset,
                  "$key has the following word that is "
                      "not in our dictionary",
                  "$key has the following word that is "
                      "on our deny-list",
                ),
              );
            }
          }
        }

        if (exampleAllowOtherCodes) {
          // Update all examples.
          for (Example example in examples) {
            example.allowOtherCodes = exampleAllowOtherCodes;
          }
        }
        if (exampleAllowMultipleReports) {
          // Update all examples.
          for (Example example in examples) {
            example.allowMultipleReports = exampleAllowMultipleReports;
          }
        }
        if (includeErrorContext) {
          // Update all examples.
          for (Example example in examples) {
            example.includeErrorContext = includeErrorContext;
          }
        }

        for (Example example in examples) {
          example.experimentalFlags =
              experimentalFlags ?? defaultExperimentalFlags;
        }

        MessageTestDescription createDescription(
          String subName,
          Example? example,
          ({String message, KnownExpectation expectation})? problem, {
          location,
        }) {
          String shortName = "$prefix$name/$subName";
          if (problem != null) {
            String filename = relativize(uri);
            location ??= message.valueSpan.start;
            int line = location.line + 1;
            int column = location.column;
            problem = (
              message: "$filename:$line:$column: error:\n${problem.message}",
              expectation: problem.expectation,
            );
          }
          return new MessageTestDescription(
            uri.resolve("#$shortName"),
            shortName,
            name,
            message,
            example,
            problem,
          );
        }

        if (!fastOnly) {
          for (Example example in examples) {
            result.add(createDescription(example.name, example, null));
          }
          // "Wrap" example as a part.
          for (Example example in examples) {
            Script originalMainScript = example.scripts[example.mainFilename]!;
            String? originalSource = originalMainScript.sourceWithoutPreamble;
            if (originalSource != null &&
                (originalSource.contains("import ") ||
                    originalSource.contains("part ") ||
                    originalSource.contains("export ") ||
                    originalSource.contains("library "))) {
              continue;
            }
            result.add(
              createDescription(
                "part_wrapped_${example.name}",
                new PartWrapExample(
                  "part_wrapped_${example.name}",
                  name,
                  exampleAllowOtherCodes,
                  exampleAllowMultipleReports,
                  includeErrorContext,
                  example,
                ),
                null,
              ),
            );
          }
        }

        result.add(
          createDescription(
            "spelling",
            null,
            spellingMessages != null
                ? (
                    expectation: KnownExpectation.spellingError,
                    message: spellingMessages.join("\n") + spellingPostMessage,
                  )
                : null,
          ),
        );

        bool exampleRequired =
            severity != CfeSeverity.context &&
            severity != CfeSeverity.internalProblem &&
            severity != CfeSeverity.ignored;

        result.add(
          createDescription(
            "externalExample",
            null,
            exampleRequired &&
                    externalTest != null &&
                    !(new File.fromUri(root.resolve(externalTest)).existsSync())
                ? (
                    expectation: KnownExpectation.missingExternalFile,
                    message:
                        "Given external example for $name points to a "
                        "nonexisting file  "
                        "(${root.resolve(externalTest)}).",
                  )
                : null,
          ),
        );

        result.add(
          createDescription(
            "example",
            null,
            exampleRequired && examples.isEmpty && externalTest == null
                ? (
                    expectation: KnownExpectation.missingExample,
                    message:
                        "No example for $name, please add at least one "
                        "example.",
                  )
                : null,
          ),
        );
      } catch (e, st) {
        Error.throwWithStackTrace('While processing $camelCaseName: $e', st);
      }
    }
    return result;
  }

  String formatProblems(
    String message,
    Example example,
    List<CfeDiagnosticMessage> messages,
  ) {
    var span = example.sourceExample.span;
    StringBuffer buffer = new StringBuffer();
    buffer
      ..write(relativize(span.sourceUrl!))
      ..write(":")
      ..write(span.start.line + 1)
      ..write(":")
      ..write(span.start.column)
      ..write(": error: ")
      ..write(message);
    buffer.write("\n${span.text}");
    for (CfeDiagnosticMessage message in messages) {
      buffer.write("\nCode: ${getMessageCodeObject(message)!.name}");
      buffer.write("\n  > ");
      buffer.write(
        message.plainTextFormatted.join("\n").replaceAll("\n", "\n  > "),
      );
    }

    return "$buffer";
  }
}

abstract class Example {
  final String name;

  final String expectedCode;

  bool allowOtherCodes = false;
  bool allowMultipleReports = false;
  bool includeErrorContext = false;

  Map<ExperimentalFlag, bool>? experimentalFlags;

  new(this.name, this.expectedCode);

  /// The example from `messages.yaml` that this example is derived from.
  MessageExample get sourceExample;

  Map<String, Script> get scripts;

  String get mainFilename => "main.dart";
}

/// An [Example] that directly corresponds to an example in `messages.yaml`.
class MessageYamlExample extends Example {
  @override
  final MessageExample sourceExample;

  new(String code, this.sourceExample) : super(sourceExample.name, code);

  @override
  String get mainFilename => MessageExample.mainFileName;

  @override
  Map<String, Script> get scripts {
    switch (sourceExample) {
      case BytesExample(:var bytes):
        return {mainFilename: new Script(bytes, '', null)};
      case SourceExample(:var files):
        return {
          for (var MapEntry(key: fileName, value: source) in files.entries)
            fileName: new Script.fromSource(source),
        };
    }
  }
}

class PartWrapExample extends Example {
  final Example example;
  @override
  final bool allowOtherCodes;

  @override
  final bool allowMultipleReports;

  @override
  final bool includeErrorContext;

  new(
    String name,
    String code,
    this.allowOtherCodes,
    this.allowMultipleReports,
    this.includeErrorContext,
    this.example,
  ) : super(name, code) {
    experimentalFlags = example.experimentalFlags;
  }

  @override
  String get mainFilename => "main_wrapped.dart";

  @override
  Map<String, Script> get scripts {
    Map<String, Script> wrapped = example.scripts;

    Map<String, Script> scriptFiles = <String, Script>{};
    scriptFiles.addAll(wrapped);

    // Create a new main file
    // TODO: Technically we should find a un-used name.
    if (scriptFiles.containsKey(mainFilename)) {
      throw "Framework failure: "
          "Wanted to create wrapper file, but the file already exists!";
    }
    Script originalMainScript = scriptFiles[example.mainFilename]!;
    String preamble = originalMainScript.preamble;
    scriptFiles[mainFilename] = new Script.fromSource("""
${preamble}part "${example.mainFilename}";
    """);

    // Modify the original main file to be part of the wrapper and add lots of
    // gunk so every actual position in the file is not a valid position in the
    // wrapper.
    String? originalMainSource = originalMainScript.sourceWithoutPreamble;
    String partPrefix =
        """
${preamble}part of "${mainFilename}";
// La la la la la la la la la la la la la.
// La la la la la la la la la la la la la.
// La la la la la la la la la la la la la.
// La la la la la la la la la la la la la.
// La la la la la la la la la la la la la.

""";
    if (originalMainSource != null) {
      scriptFiles[example.mainFilename] = new Script.fromSource(
        '$partPrefix$originalMainSource',
      );
    } else {
      scriptFiles[example.mainFilename] = new Script(
        new Uint8List.fromList(
          utf8.encode(partPrefix) + originalMainScript.bytes,
        ),
        '',
        null,
      );
    }

    return scriptFiles;
  }

  @override
  MessageExample get sourceExample => example.sourceExample;
}

class Validate
    extends Step<MessageTestDescription, Example?, MessageTestSuite> {
  const new();

  @override
  String get name => "validate";

  @override
  Future<Result<Example?>> run(
    MessageTestDescription description,
    MessageTestSuite suite,
  ) {
    if (description.problem != null) {
      return new Future.value(
        new Result(
          null,
          description.problem!.expectation.expectation(suite),
          description.problem!.message,
        ),
      );
    } else {
      return new Future.value(pass(description.example));
    }
  }
}

class Compile extends Step<Example?, Null, MessageTestSuite> {
  const new();

  @override
  String get name => "compile";

  @override
  Future<Result<Null>> run(Example? example, MessageTestSuite suite) async {
    if (example == null) return pass(null);
    String dir = "${example.expectedCode}/${example.name}";
    example.scripts.forEach((String fileName, Script script) {
      Uri uri = suite.fileSystem.currentDirectory.resolve("$dir/$fileName");
      suite.fileSystem.entityForUri(uri).writeAsBytesSync(script.bytes);
    });
    Uri main = suite.fileSystem.currentDirectory.resolve(
      "$dir/${example.mainFilename}",
    );
    Uri output = suite.fileSystem.currentDirectory.resolve(
      "$dir/main.dart.dill",
    );

    // Setup .dart_tool/package_config.json if it doesn't exist.
    Uri packageConfigUri = suite.fileSystem.currentDirectory.resolve(
      "$dir/.dart_tool/package_config.json",
    );
    if (!await suite.fileSystem.entityForUri(packageConfigUri).exists()) {
      suite.fileSystem
          .entityForUri(packageConfigUri)
          .writeAsStringSync('{"configVersion": 2, "packages": []}');
    }

    print("Compiling $main");
    List<CfeDiagnosticMessage> rawMessages = <CfeDiagnosticMessage>[];

    await suite.compiler.batchCompile(
      new CompilerOptions()
        ..sdkSummary = computePlatformBinariesLocation(forceBuildDir: true)
            .resolve("vm_platform.dill")
        ..explicitExperimentalFlags = example.experimentalFlags ?? {}
        ..target = new VmTarget(new TargetFlags())
        ..fileSystem = new HybridFileSystem(suite.fileSystem)
        ..packagesFileUri = packageConfigUri
        ..onDiagnostic = rawMessages.add
        ..environmentDefines = const {}
        ..omitPlatform = true,
      main,
      output,
    );

    List<CfeDiagnosticMessage> unexpectedMessages = <CfeDiagnosticMessage>[];
    List<CfeDiagnosticMessage> expectedMessages = <CfeDiagnosticMessage>[];
    for (CfeDiagnosticMessage message in rawMessages) {
      if (getMessageCodeObject(message)!.name == example.expectedCode) {
        expectedMessages.add(message);
      } else {
        unexpectedMessages.add(message);
      }
      // Include contexts if asked.
      if (example.includeErrorContext) {
        for (CfeDiagnosticMessage context
            in getMessageRelatedInformation(message) ??
                const <CfeDiagnosticMessage>[]) {
          if (getMessageCodeObject(context)!.name == example.expectedCode) {
            expectedMessages.add(context);
          } else {
            unexpectedMessages.add(context);
          }
        }
      }
    }
    if (example.allowOtherCodes) {
      unexpectedMessages = [];
    }
    if (example.allowMultipleReports) {
      List<CfeDiagnosticMessage> removeDuplicateCodes(
        List<CfeDiagnosticMessage> messages,
      ) {
        Set<String> seenCodes = {};
        List<CfeDiagnosticMessage> result = [];
        for (CfeDiagnosticMessage message in messages) {
          if (seenCodes.add(getMessageCodeObject(message)!.name)) {
            result.add(message);
          }
        }
        return result;
      }

      expectedMessages = removeDuplicateCodes(expectedMessages);
      unexpectedMessages = removeDuplicateCodes(unexpectedMessages);
    }
    if (unexpectedMessages.isEmpty) {
      switch (expectedMessages.length) {
        case 0:
          return new Result(
            null,
            KnownExpectation.noMessageReported.expectation(suite),
            suite.formatProblems(
              "No message reported in ${example.name}:",
              example,
              expectedMessages,
            ),
          );
        case 1:
          return pass(null);
        default:
          return new Result(
            null,
            KnownExpectation.hasTooManyCorrect.expectation(suite),
            suite.formatProblems(
              "Correct message reported multiple times in ${example.name}. "
              "Maybe add `exampleAllowMultipleReports: true`.",
              example,
              expectedMessages,
            ),
          );
      }
    } else if (expectedMessages.isEmpty) {
      // Has unexpected messages and no expected message.
      return new Result(
        null,
        KnownExpectation.hasOnlyUnrelatedMessages.expectation(suite),
        suite.formatProblems(
          "Got only unrelated codes in ${example.name}:",
          example,
          unexpectedMessages,
        ),
      );
    } else if (expectedMessages.length == 1) {
      // Has unexpected messages and 1 expected message.
      return new Result(
        null,
        KnownExpectation.hasCorrectButAlsoOthers.expectation(suite),
        suite.formatProblems(
          "Got correct code, but also others in ${example.name}. "
          "Maybe add `exampleAllowOtherCodes: true`.",
          example,
          [...expectedMessages, ...unexpectedMessages],
        ),
      );
    } else {
      // Has unexpected messages and more than 1 unexpected message.
      return new Result(
        null,
        KnownExpectation.hasTooManyCorrectAndAlsoOthers.expectation(suite),
        suite.formatProblems(
          "Has too many correct codes and other codes in ${example.name}. "
          "Maybe add `exampleAllowOtherCodes: true` and "
          "`exampleAllowMultipleReports: true`.",
          example,
          [...expectedMessages, ...unexpectedMessages],
        ),
      );
    }
  }
}

Future<MessageTestSuite> createContext(
  Chain suite,
  Map<String, String> environment,
) {
  final bool fastOnly = environment["fastOnly"] == "true";
  final bool interactive = environment["interactive"] == "true";
  final bool justAddEverything = environment["justAddEverything"] == "true";
  final bool skipSpellCheck = environment["skipSpellCheck"] == "true";
  return new Future.value(
    new MessageTestSuite(
      fastOnly,
      interactive,
      justAddEverything,
      skipSpellCheck,
    ),
  );
}

String relativize(Uri uri) {
  String base = "${Uri.base}";
  String filename = "$uri";
  if (filename.startsWith(base)) {
    return filename.substring(base.length);
  } else {
    return filename;
  }
}

class Script {
  final Uint8List bytes;
  final String preamble;
  final String? sourceWithoutPreamble;

  new(this.bytes, this.preamble, this.sourceWithoutPreamble);

  factory fromSource(String source) {
    List<String> lines = source.split('\n');
    String firstLine = lines.first;
    String preamble;
    String sourceWithoutPreamble;
    if (firstLine.trim().startsWith('//') && firstLine.contains('@dart=')) {
      preamble = '$firstLine\n';
      sourceWithoutPreamble = lines.skip(1).join('\n');
    } else {
      preamble = '';
      sourceWithoutPreamble = source;
    }
    return new Script(utf8.encode(source), preamble, sourceWithoutPreamble);
  }
}

Future<void> main([List<String> arguments = const []]) async {
  await internalMain(
    createContext,
    arguments: arguments,
    displayName: "messages suite",
    configurationPath: "../testing.json",
  );
}
