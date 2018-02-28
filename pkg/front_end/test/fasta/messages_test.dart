// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:async" show Future, Stream;

import "dart:convert" show utf8;

import "dart:io" show File;

import "dart:typed_data" show Uint8List;

import "package:testing/testing.dart"
    show Chain, ChainContext, Result, Step, TestDescription, runMe;

import "package:yaml/yaml.dart" show loadYaml;

part "messages_exceptions.dart";

final Set<String> messagesWithoutExamples =
    new Set<String>.from(listOfMessagesWithoutExamples);

final Set<String> messagesWithoutAnalyzerCode =
    new Set<String>.from(listOfMessagesWithoutAnalyzerCode);

class MessageTestDescription extends TestDescription {
  @override
  final Uri uri;

  @override
  final String shortName;

  final Map data;

  MessageTestDescription(this.uri, this.shortName, this.data);
}

class MessageTestSuite extends ChainContext {
  final List<Step> steps = const <Step>[
    const ValidateMessage(),
    const CompileExamples(),
  ];

  Stream<MessageTestDescription> list(Chain suite) async* {
    Uri uri = suite.uri.resolve("messages.yaml");
    File file = new File.fromUri(uri);
    Map yaml = loadYaml(await file.readAsString());
    for (String key in yaml.keys) {
      var data = yaml[key];
      if (data is String) continue;
      yield new MessageTestDescription(uri.resolve("#$key"), key, data);
    }
  }
}

abstract class Example {
  final String expectedCode;

  Example(this.expectedCode);

  Uint8List get bytes;
}

class BytesExample extends Example {
  @override
  final Uint8List bytes;

  BytesExample(String code, List bytes)
      : bytes = new Uint8List.fromList(bytes),
        super(code);
}

class DeclarationExample extends Example {
  final String declaration;

  DeclarationExample(String code, this.declaration) : super(code);

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
  final String statement;

  StatementExample(String code, this.statement) : super(code);

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
  final String expression;

  ExpressionExample(String code, this.expression) : super(code);

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
  final String script;

  ScriptExample(String code, this.script) : super(code);

  @override
  Uint8List get bytes {
    return new Uint8List.fromList(utf8.encode(script));
  }
}

class ValidateMessage
    extends Step<MessageTestDescription, List<Example>, MessageTestSuite> {
  const ValidateMessage();

  String get name => "validate";

  Future<Result<List<Example>>> run(
      MessageTestDescription description, MessageTestSuite suite) async {
    Map data = description.data;
    String name = description.shortName;

    List<String> unknownKeys = <String>[];
    List<Example> examples = <Example>[];
    String analyzerCode;
    String dart2jsCode;

    for (String key in data.keys) {
      var value = data[key];
      switch (key) {
        case "template":
        case "tip":
        case "severity":
          break;

        case "analyzerCode":
          analyzerCode = value;
          break;

        case "dart2jsCode":
          dart2jsCode = value;
          break;

        case "bytes":
          if (value.first is List) {
            for (List bytes in value) {
              examples.add(new BytesExample(name, bytes));
            }
          } else {
            examples.add(new BytesExample(name, value));
          }
          break;

        case "declaration":
          if (value is List) {
            for (String declaration in value) {
              examples.add(new DeclarationExample(name, declaration));
            }
          } else {
            examples.add(new DeclarationExample(name, value));
          }
          break;

        case "expression":
          if (value is List) {
            for (String expression in value) {
              examples.add(new ExpressionExample(name, expression));
            }
          } else {
            examples.add(new ExpressionExample(name, value));
          }
          break;

        case "script":
          if (value is List) {
            for (String script in value) {
              examples.add(new ScriptExample(name, script));
            }
          } else {
            examples.add(new ScriptExample(name, value));
          }
          break;

        case "statement":
          if (value is List) {
            for (String statement in value) {
              examples.add(new StatementExample(name, statement));
            }
          } else {
            examples.add(new StatementExample(name, value));
          }
          break;

        default:
          unknownKeys.add(key);
      }
    }

    if (unknownKeys.isNotEmpty) {
      return fail(null, "Unknown keys: ${unknownKeys.join(' ')}");
    }

    if (examples.isEmpty) {
      if (!messagesWithoutExamples.contains(name)) {
        return fail(null, "No example for $name");
      }
    } else {
      if (messagesWithoutExamples.contains(name)) {
        return fail(
            null, "$name can be removed from listOfMessagesWithoutExamples");
      }
    }

    if (analyzerCode == null) {
      if (!messagesWithoutAnalyzerCode.contains(name)) {
        return fail(null, "No analyzer code for $name");
      }
    } else {
      if (messagesWithoutAnalyzerCode.contains(name)) {
        return fail(
            null, "$name can be removed fro listOfMessagesWithoutAnalyzerCode");
      }
      if (dart2jsCode == null) {
        return fail(null, "No dart2js code for $name");
      }
    }

    return pass(examples);
  }
}

class CompileExamples extends Step<List<Example>, Null, MessageTestSuite> {
  const CompileExamples();

  String get name => "compile";

  Future<Result<Null>> run(
      List<Example> examples, MessageTestSuite suite) async {
    for (Example example in examples) {
      // TODO(ahe): This is where I should actually compile the examples and
      // verify that only one message is reported, and it is the expected
      // message.
      if (example is! BytesExample) {
        print(utf8.decode(example.bytes));
      }
    }
    return pass(null);
  }
}

Future<MessageTestSuite> createContext(
    Chain suite, Map<String, String> environment) async {
  return new MessageTestSuite();
}

main([List<String> arguments = const []]) =>
    runMe(arguments, createContext, "../../testing.json");
