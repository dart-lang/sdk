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

class MessageTestDescription extends TestDescription {
  @override
  final Uri uri;

  @override
  final String shortName;

  final String name;

  final Map data;

  final Example example;

  final String problem;

  MessageTestDescription(this.uri, this.shortName, this.name, this.data,
      this.example, this.problem);
}

class MessageTestSuite extends ChainContext {
  final List<Step> steps = const <Step>[
    const Validate(),
    const Compile(),
  ];

  /// Convert all the examples found in `messages.yaml` to a test
  /// description. In addition, for each problem found, create a test
  /// description that has a problem. This problem will then be reported as a
  /// failure by the [Validate] step that can be suppressed via the status
  /// file.
  Stream<MessageTestDescription> list(Chain suite) async* {
    Uri uri = suite.uri.resolve("messages.yaml");
    File file = new File.fromUri(uri);
    Map yaml = loadYaml(await file.readAsString());
    for (String name in yaml.keys) {
      var data = yaml[name];
      if (data is String) continue;

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
                int i = 0;
                examples.add(new BytesExample("bytes${++i}", name, bytes));
              }
            } else {
              examples.add(new BytesExample("bytes", name, value));
            }
            break;

          case "declaration":
            if (value is List) {
              int i = 0;
              for (String declaration in value) {
                examples.add(new DeclarationExample(
                    "declaration${++i}", name, declaration));
              }
            } else {
              examples.add(new DeclarationExample("declaration", name, value));
            }
            break;

          case "expression":
            if (value is List) {
              int i = 0;
              for (String expression in value) {
                examples.add(new ExpressionExample(
                    "expression${++i}", name, expression));
              }
            } else {
              examples.add(new ExpressionExample("expression", name, value));
            }
            break;

          case "script":
            if (value is List) {
              int i = 0;
              for (String script in value) {
                examples.add(new ScriptExample("script${++i}", name, script));
              }
            } else {
              examples.add(new ScriptExample("script", name, value));
            }
            break;

          case "statement":
            if (value is List) {
              int i = 0;
              for (String statement in value) {
                examples.add(
                    new StatementExample("statement${++i}", name, statement));
              }
            } else {
              examples.add(new StatementExample("statement", name, value));
            }
            break;

          default:
            unknownKeys.add(key);
        }
      }

      MessageTestDescription createDescription(
          String subName, Example example, String problem) {
        String shortName = "$name/$subName";
        if (problem != null) {
          String base = "${Uri.base}";
          String filename = "$uri";
          if (filename.startsWith(base)) {
            filename = filename.substring(base.length);
          }
          var location = data.span.start;
          int line = location.line;
          int column = location.column;
          problem = "$filename:$line:$column: error:\n$problem";
        }
        return new MessageTestDescription(uri.resolve("#$shortName"), shortName,
            name, data, example, problem);
      }

      for (Example example in examples) {
        yield createDescription(example.name, example, null);
      }

      if (unknownKeys.isNotEmpty) {
        yield createDescription(
            "knownKeys", null, "Unknown keys: ${unknownKeys.join(' ')}");
      }

      if (examples.isEmpty) {
        yield createDescription("example", null, "No example for $name");
      }

      if (analyzerCode == null) {
        yield createDescription(
            "analyzerCode", null, "No analyzer code for $name");
      } else {
        if (dart2jsCode == null) {
          yield createDescription(
              "dart2jsCode", null, "No dart2js code for $name");
        }
      }
    }
  }
}

abstract class Example {
  final String name;

  final String expectedCode;

  Example(this.name, this.expectedCode);

  Uint8List get bytes;
}

class BytesExample extends Example {
  @override
  final Uint8List bytes;

  BytesExample(String name, String code, List bytes)
      : bytes = new Uint8List.fromList(bytes),
        super(name, code);
}

class DeclarationExample extends Example {
  final String declaration;

  DeclarationExample(String name, String code, this.declaration)
      : super(name, code);

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

  StatementExample(String name, String code, this.statement)
      : super(name, code);

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

  ExpressionExample(String name, String code, this.expression)
      : super(name, code);

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

  ScriptExample(String name, String code, this.script) : super(name, code);

  @override
  Uint8List get bytes {
    return new Uint8List.fromList(utf8.encode(script));
  }
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
    // TODO(ahe): This is where I should actually compile the example and
    // verify that only one message is reported, and it is the expected
    // message.
    if (example is! BytesExample) {
      print(utf8.decode(example.bytes));
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
