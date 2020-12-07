// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:convert" show utf8;

import 'dart:io' show File, Platform;

import "dart:typed_data" show Uint8List;

import 'package:_fe_analyzer_shared/src/messages/diagnostic_message.dart'
    show DiagnosticMessage, getMessageCodeObject;

import 'package:_fe_analyzer_shared/src/messages/severity.dart'
    show Severity, severityEnumValues;

import 'package:kernel/ast.dart' show Location, Source;

import "package:kernel/target/targets.dart" show TargetFlags;

import "package:testing/testing.dart"
    show Chain, ChainContext, Expectation, Result, Step, TestDescription, runMe;

import "package:vm/target/vm.dart" show VmTarget;

import "package:yaml/yaml.dart" show YamlList, YamlMap, YamlNode, loadYamlNode;

import 'package:front_end/src/api_prototype/compiler_options.dart'
    show CompilerOptions;

import 'package:front_end/src/api_prototype/experimental_flags.dart'
    show ExperimentalFlag;

import 'package:front_end/src/api_prototype/memory_file_system.dart'
    show MemoryFileSystem;

import 'package:front_end/src/base/nnbd_mode.dart' show NnbdMode;

import 'package:front_end/src/compute_platform_binaries_location.dart'
    show computePlatformBinariesLocation;

import 'package:front_end/src/fasta/command_line_reporting.dart'
    as command_line_reporting;

import 'package:front_end/src/fasta/hybrid_file_system.dart'
    show HybridFileSystem;

import "../../tool/_fasta/entry_points.dart" show BatchCompiler;

import '../spell_checking_utils.dart' as spell;

class MessageTestDescription extends TestDescription {
  @override
  final Uri uri;

  @override
  final String shortName;

  final String name;

  final YamlMap data;

  final Example example;

  final String problem;

  MessageTestDescription(this.uri, this.shortName, this.name, this.data,
      this.example, this.problem);
}

class Configuration {
  final NnbdMode nnbdMode;

  const Configuration(this.nnbdMode);

  CompilerOptions apply(CompilerOptions options) {
    if (nnbdMode != null) {
      options.explicitExperimentalFlags[ExperimentalFlag.nonNullable] = true;
      options.nnbdMode = nnbdMode;
    } else {
      options.explicitExperimentalFlags[ExperimentalFlag.nonNullable] = false;
    }
    return options;
  }

  static const Configuration defaultConfiguration = const Configuration(null);
}

class MessageTestSuite extends ChainContext {
  final List<Step> steps = const <Step>[
    const Validate(),
    const Compile(),
  ];

  final MemoryFileSystem fileSystem;

  final BatchCompiler compiler;

  final bool fastOnly;
  final bool interactive;

  final Set<String> reportedWords = {};
  final Set<String> reportedWordsDenylisted = {};

  @override
  Future<void> postRun() {
    String dartPath = Platform.resolvedExecutable;
    Uri suiteUri =
        spell.repoDir.resolve("pkg/front_end/test/fasta/messages_suite.dart");
    File suiteFile = new File.fromUri(suiteUri).absolute;
    if (!suiteFile.existsSync()) {
      throw "Specified suite path is invalid.";
    }
    String suitePath = suiteFile.path;
    spell.spellSummarizeAndInteractiveMode(
        reportedWords,
        reportedWordsDenylisted,
        [spell.Dictionaries.cfeMessages],
        interactive,
        '"$dartPath" "$suitePath" -DfastOnly=true -Dinteractive=true');
    return null;
  }

  MessageTestSuite(this.fastOnly, this.interactive)
      : fileSystem = new MemoryFileSystem(Uri.parse("org-dartlang-fasta:///")),
        compiler = new BatchCompiler(null);

  @override
  Set<Expectation> processExpectedOutcomes(
      Set<Expectation> outcomes, TestDescription description) {
    if (description.shortName.contains("/spelling")) {
      return {Expectation.Pass};
    }
    return outcomes;
  }

  /// Convert all the examples found in `messages.yaml` to a test
  /// description. In addition, create a test description for each kind of
  /// problem that a message can have. This problem will then be reported as a
  /// failure by the [Validate] step that can be suppressed via the status
  /// file.
  Stream<MessageTestDescription> list(Chain suite) async* {
    Uri uri = suite.uri.resolve("messages.yaml");
    File file = new File.fromUri(uri);
    String fileContent = file.readAsStringSync();
    YamlMap messages = loadYamlNode(fileContent, sourceUrl: uri);
    for (String name in messages.keys) {
      YamlNode messageNode = messages.nodes[name];
      var message = messageNode.value;
      if (message is String) continue;

      List<String> unknownKeys = <String>[];
      bool exampleAllowMoreCodes = false;
      List<Example> examples = <Example>[];
      String externalTest;
      bool frontendInternal = false;
      List<String> analyzerCodes;
      Severity severity;
      YamlNode badSeverity;
      YamlNode unnecessarySeverity;
      List<String> badHasPublishedDocsValue = <String>[];
      List<String> spellingMessages;
      const String spellingPostMessage = "\nIf the word(s) look okay, update "
          "'spell_checking_list_messages.txt' or "
          "'spell_checking_list_common.txt'.";
      Configuration configuration;

      Source source;
      List<String> formatSpellingMistakes(spell.SpellingResult spellResult,
          int offset, String message, String messageForDenyListed) {
        if (source == null) {
          List<int> bytes = file.readAsBytesSync();
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
        for (int i = 0; i < spellResult.misspelledWords.length; i++) {
          Location location = source.getLocation(
              uri, offset + spellResult.misspelledWordsOffset[i]);
          bool denylisted = spellResult.misspelledWordsDenylisted[i];
          String messageToUse = message;
          if (denylisted) {
            messageToUse = messageForDenyListed;
            reportedWordsDenylisted.add(spellResult.misspelledWords[i]);
          } else {
            reportedWords.add(spellResult.misspelledWords[i]);
          }
          result.add(command_line_reporting.formatErrorMessage(
              source.getTextLine(location.line),
              location,
              spellResult.misspelledWords[i].length,
              relativize(uri),
              "$messageToUse: '${spellResult.misspelledWords[i]}'."));
        }
        return result;
      }

      for (String key in message.keys) {
        YamlNode node = message.nodes[key];
        var value = node.value;
        // When positions matter, use node.span.text.
        // When using node.span.text, replace r"\n" with "\n\n" to replace two
        // characters with two characters without actually having the string
        // "backslash n".
        switch (key) {
          case "template":
            spell.SpellingResult spellingResult = spell.spellcheckString(
                node.span.text.replaceAll(r"\n", "\n\n"),
                dictionaries: const [
                  spell.Dictionaries.common,
                  spell.Dictionaries.cfeMessages
                ]);
            if (spellingResult.misspelledWords != null) {
              spellingMessages ??= <String>[];
              spellingMessages.addAll(formatSpellingMistakes(
                  spellingResult,
                  node.span.start.offset,
                  "Template has the following word that is "
                      "not in our dictionary",
                  "Template has the following word that is "
                      "on our deny-list"));
            }
            break;

          case "tip":
            spell.SpellingResult spellingResult = spell.spellcheckString(
                node.span.text.replaceAll(r"\n", "\n\n"),
                dictionaries: const [
                  spell.Dictionaries.common,
                  spell.Dictionaries.cfeMessages
                ]);
            if (spellingResult.misspelledWords != null) {
              spellingMessages ??= <String>[];
              spellingMessages.addAll(formatSpellingMistakes(
                  spellingResult,
                  node.span.start.offset,
                  "Tip has the following word that is "
                      "not in our dictionary",
                  "Tip has the following word that is "
                      "on our deny-list"));
            }
            break;

          case "severity":
            severity = severityEnumValues[value];
            if (severity == null) {
              badSeverity = node;
            } else if (severity == Severity.error) {
              unnecessarySeverity = node;
            }
            break;

          case "frontendInternal":
            frontendInternal = value;
            break;

          case "analyzerCode":
            analyzerCodes = value is String
                ? <String>[value]
                : new List<String>.from(value);
            break;

          case "exampleAllowMoreCodes":
            exampleAllowMoreCodes = value;
            break;

          case "bytes":
            YamlList list = node;
            if (list.first is List) {
              for (YamlList bytes in list.nodes) {
                int i = 0;
                examples.add(new BytesExample("bytes${++i}", name, bytes));
              }
            } else {
              examples.add(new BytesExample("bytes", name, list));
            }
            break;

          case "declaration":
            if (node is YamlList) {
              int i = 0;
              for (YamlNode declaration in node.nodes) {
                examples.add(new DeclarationExample(
                    "declaration${++i}", name, declaration));
              }
            } else {
              examples.add(new DeclarationExample("declaration", name, node));
            }
            break;

          case "expression":
            if (node is YamlList) {
              int i = 0;
              for (YamlNode expression in node.nodes) {
                examples.add(new ExpressionExample(
                    "expression${++i}", name, expression));
              }
            } else {
              examples.add(new ExpressionExample("expression", name, node));
            }
            break;

          case "script":
            if (node is YamlList) {
              int i = 0;
              for (YamlNode script in node.nodes) {
                examples
                    .add(new ScriptExample("script${++i}", name, script, this));
              }
            } else {
              examples.add(new ScriptExample("script", name, node, this));
            }
            break;

          case "statement":
            if (node is YamlList) {
              int i = 0;
              for (YamlNode statement in node.nodes) {
                examples.add(
                    new StatementExample("statement${++i}", name, statement));
              }
            } else {
              examples.add(new StatementExample("statement", name, node));
            }
            break;

          case "external":
            externalTest = node.value;
            break;

          case "index":
            // index is validated during generation
            break;

          case "hasPublishedDocs":
            if (value != true) {
              badHasPublishedDocsValue.add(name);
            }
            break;

          case "configuration":
            if (value == "nnbd-weak") {
              configuration = const Configuration(NnbdMode.Weak);
            } else if (value == "nnbd-strong") {
              configuration = const Configuration(NnbdMode.Strong);
            } else {
              throw new ArgumentError("Unknown configuration '$value'.");
            }
            break;

          default:
            unknownKeys.add(key);
        }
      }

      if (exampleAllowMoreCodes) {
        // Update all examples.
        for (Example example in examples) {
          example.allowMoreCodes = exampleAllowMoreCodes;
        }
      }
      for (Example example in examples) {
        example.configuration =
            configuration ?? Configuration.defaultConfiguration;
      }

      MessageTestDescription createDescription(
          String subName, Example example, String problem,
          {location}) {
        String shortName = "$name/$subName";
        if (problem != null) {
          String filename = relativize(uri);
          location ??= message.span.start;
          int line = location.line + 1;
          int column = location.column;
          problem = "$filename:$line:$column: error:\n$problem";
        }
        return new MessageTestDescription(uri.resolve("#$shortName"), shortName,
            name, messageNode, example, problem);
      }

      if (!fastOnly) {
        for (Example example in examples) {
          yield createDescription(example.name, example, null);
        }
        // "Wrap" example as a part.
        for (Example example in examples) {
          yield createDescription(
              "part_wrapped_${example.name}",
              new PartWrapExample("part_wrapped_${example.name}", name,
                  exampleAllowMoreCodes, example),
              null);
        }
      }

      yield createDescription(
          "knownKeys",
          null,
          unknownKeys.isNotEmpty
              ? "Unknown keys: ${unknownKeys.join(' ')}."
              : null);

      yield createDescription(
          'hasPublishedDocs',
          null,
          badHasPublishedDocsValue.isNotEmpty
              ? "Bad hasPublishedDocs value (only 'true' supported) in:"
                  " ${badHasPublishedDocsValue.join(', ')}"
              : null);

      yield createDescription(
          "severity",
          null,
          badSeverity != null
              ? "Unknown severity: '${badSeverity.value}'."
              : null,
          location: badSeverity?.span?.start);

      yield createDescription(
          "unnecessarySeverity",
          null,
          unnecessarySeverity != null
              ? "The 'ERROR' severity is the default and not necessary."
              : null,
          location: unnecessarySeverity?.span?.start);

      yield createDescription(
          "spelling",
          null,
          spellingMessages != null
              ? spellingMessages.join("\n") + spellingPostMessage
              : null);

      bool exampleAndAnalyzerCodeRequired = severity != Severity.context &&
          severity != Severity.internalProblem &&
          severity != Severity.ignored;

      yield createDescription(
          "externalExample",
          null,
          exampleAndAnalyzerCodeRequired &&
                  externalTest != null &&
                  !(new File.fromUri(suite.uri.resolve(externalTest))
                      .existsSync())
              ? "Given external example for $name points to a nonexisting file "
                  "(${suite.uri.resolve(externalTest)})."
              : null);

      yield createDescription(
          "example",
          null,
          exampleAndAnalyzerCodeRequired &&
                  examples.isEmpty &&
                  externalTest == null
              ? "No example for $name, please add at least one example."
              : null);

      yield createDescription(
          "analyzerCode",
          null,
          exampleAndAnalyzerCodeRequired &&
                  !frontendInternal &&
                  analyzerCodes == null
              ? "No analyzer code for $name."
                  "\nTry running"
                  " <BUILDDIR>/dart-sdk/bin/dartanalyzer --format=machine"
                  " on an example to find the code."
                  " The code is printed just before the file name."
              : null);
    }
  }

  String formatProblems(
      String message, Example example, List<DiagnosticMessage> messages) {
    var span = example.node.span;
    StringBuffer buffer = new StringBuffer();
    buffer
      ..write(relativize(span.sourceUrl))
      ..write(":")
      ..write(span.start.line + 1)
      ..write(":")
      ..write(span.start.column)
      ..write(": error: ")
      ..write(message);
    buffer.write("\n${span.text}");
    for (DiagnosticMessage message in messages) {
      buffer.write("\nCode: ${getMessageCodeObject(message).name}");
      buffer.write("\n  > ");
      buffer.write(
          message.plainTextFormatted.join("\n").replaceAll("\n", "\n  > "));
    }

    return "$buffer";
  }
}

abstract class Example {
  final String name;

  final String expectedCode;

  bool allowMoreCodes = false;

  Configuration configuration;

  Example(this.name, this.expectedCode);

  YamlNode get node;

  Uint8List get bytes;

  Map<String, Uint8List> get scripts {
    return {mainFilename: bytes};
  }

  String get mainFilename => "main.dart";
}

class BytesExample extends Example {
  @override
  final YamlList node;

  @override
  final Uint8List bytes;

  BytesExample(String name, String code, this.node)
      : bytes = new Uint8List.fromList(node.cast<int>()),
        super(name, code);
}

class DeclarationExample extends Example {
  @override
  final YamlNode node;

  final String declaration;

  DeclarationExample(String name, String code, this.node)
      : declaration = node.value,
        super(name, code);

  @override
  Uint8List get bytes {
    return new Uint8List.fromList(utf8.encode("""
$declaration

main() {
}
"""));
  }
}

class StatementExample extends Example {
  @override
  final YamlNode node;

  final String statement;

  StatementExample(String name, String code, this.node)
      : statement = node.value,
        super(name, code);

  @override
  Uint8List get bytes {
    return new Uint8List.fromList(utf8.encode("""
main() {
  $statement
}
"""));
  }
}

class ExpressionExample extends Example {
  @override
  final YamlNode node;

  final String expression;

  ExpressionExample(String name, String code, this.node)
      : expression = node.value,
        super(name, code);

  @override
  Uint8List get bytes {
    return new Uint8List.fromList(utf8.encode("""
main() {
  $expression;
}
"""));
  }
}

class ScriptExample extends Example {
  @override
  final YamlNode node;

  final Object script;

  ScriptExample(String name, String code, this.node, MessageTestSuite suite)
      : script = node.value,
        super(name, code) {
    if (script is! String && script is! Map) {
      throw suite.formatProblems(
          "A script must be either a String or a Map in $code:",
          this, <DiagnosticMessage>[]);
    }
  }

  @override
  Uint8List get bytes => throw "Unsupported: ScriptExample.bytes";

  @override
  Map<String, Uint8List> get scripts {
    Object script = this.script;
    if (script is Map) {
      var scriptFiles = <String, Uint8List>{};
      script.forEach((fileName, value) {
        scriptFiles[fileName] = new Uint8List.fromList(utf8.encode(value));
        print("$fileName => $value\n\n======\n\n");
      });
      return scriptFiles;
    } else {
      return {mainFilename: new Uint8List.fromList(utf8.encode(script))};
    }
  }
}

class PartWrapExample extends Example {
  final Example example;
  @override
  final bool allowMoreCodes;

  PartWrapExample(String name, String code, this.allowMoreCodes, this.example)
      : super(name, code) {
    configuration = example.configuration;
  }

  @override
  Uint8List get bytes => throw "Unsupported: PartWrapExample.bytes";

  @override
  String get mainFilename => "main_wrapped.dart";

  @override
  Map<String, Uint8List> get scripts {
    Map<String, Uint8List> wrapped = example.scripts;

    var scriptFiles = <String, Uint8List>{};
    scriptFiles.addAll(wrapped);

    // Create a new main file
    // TODO: Technically we should find a un-used name.
    if (scriptFiles.containsKey(mainFilename)) {
      throw "Framework failure: "
          "Wanted to create wrapper file, but the file already exists!";
    }
    scriptFiles[mainFilename] = new Uint8List.fromList(utf8.encode("""
      part "${example.mainFilename}";
    """));

    // Modify the original main file to be part of the wrapper and add lots of
    // gunk so every actual position in the file is not a valid position in the
    // wrapper.
    scriptFiles[example.mainFilename] = new Uint8List.fromList(utf8.encode("""
      part of "${mainFilename}";
      // La la la la la la la la la la la la la.
      // La la la la la la la la la la la la la.
      // La la la la la la la la la la la la la.
      // La la la la la la la la la la la la la.
      // La la la la la la la la la la la la la.
    """) + scriptFiles[example.mainFilename]);

    return scriptFiles;
  }

  @override
  YamlNode get node => example.node;
}

class Validate extends Step<MessageTestDescription, Example, MessageTestSuite> {
  const Validate();

  String get name => "validate";

  Future<Result<Example>> run(
      MessageTestDescription description, MessageTestSuite suite) async {
    if (description.problem != null) {
      return fail(null, description.problem);
    } else {
      return pass(description.example);
    }
  }
}

class Compile extends Step<Example, Null, MessageTestSuite> {
  const Compile();

  String get name => "compile";

  Future<Result<Null>> run(Example example, MessageTestSuite suite) async {
    if (example == null) return pass(null);
    String dir = "${example.expectedCode}/${example.name}";
    example.scripts.forEach((String fileName, Uint8List bytes) {
      Uri uri = suite.fileSystem.currentDirectory.resolve("$dir/$fileName");
      suite.fileSystem.entityForUri(uri).writeAsBytesSync(bytes);
    });
    Uri main = suite.fileSystem.currentDirectory
        .resolve("$dir/${example.mainFilename}");
    Uri output =
        suite.fileSystem.currentDirectory.resolve("$dir/main.dart.dill");

    // Setup .packages if it (or package_config.json) doesn't exist.
    Uri dotPackagesUri =
        suite.fileSystem.currentDirectory.resolve("$dir/.packages");
    Uri packageConfigJsonUri = suite.fileSystem.currentDirectory
        .resolve("$dir/.dart_tool/package_config.json");
    if (!await suite.fileSystem.entityForUri(dotPackagesUri).exists() &&
        !await suite.fileSystem.entityForUri(packageConfigJsonUri).exists()) {
      suite.fileSystem.entityForUri(dotPackagesUri).writeAsBytesSync([]);
    }

    print("Compiling $main");
    List<DiagnosticMessage> messages = <DiagnosticMessage>[];

    await suite.compiler.batchCompile(
        example.configuration.apply(new CompilerOptions()
          ..sdkSummary = computePlatformBinariesLocation(forceBuildDir: true)
              .resolve("vm_platform_strong.dill")
          ..target = new VmTarget(new TargetFlags())
          ..fileSystem = new HybridFileSystem(suite.fileSystem)
          ..packagesFileUri = dotPackagesUri
          ..onDiagnostic = messages.add
          ..environmentDefines = const {}),
        main,
        output);

    List<DiagnosticMessage> unexpectedMessages = <DiagnosticMessage>[];
    if (example.allowMoreCodes) {
      List<DiagnosticMessage> messagesFiltered = <DiagnosticMessage>[];
      for (DiagnosticMessage message in messages) {
        if (getMessageCodeObject(message).name == example.expectedCode) {
          messagesFiltered.add(message);
        }
      }
      messages = messagesFiltered;
    }
    for (DiagnosticMessage message in messages) {
      if (getMessageCodeObject(message).name != example.expectedCode) {
        unexpectedMessages.add(message);
      }
    }
    if (unexpectedMessages.isEmpty) {
      switch (messages.length) {
        case 0:
          return fail(
              null,
              suite.formatProblems("No message reported in ${example.name}:",
                  example, messages));
        case 1:
          return pass(null);
        default:
          return fail(
              null,
              suite.formatProblems(
                  "Message reported multiple times in ${example.name}:",
                  example,
                  messages));
      }
    }
    return fail(
        null,
        suite.formatProblems("Too many messages reported in ${example.name}:",
            example, messages));
  }
}

Future<MessageTestSuite> createContext(
    Chain suite, Map<String, String> environment) async {
  final bool fastOnly = environment["fastOnly"] == "true";
  final bool interactive = environment["interactive"] == "true";
  return new MessageTestSuite(fastOnly, interactive);
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

main([List<String> arguments = const []]) =>
    runMe(arguments, createContext, configurationPath: "../../testing.json");
