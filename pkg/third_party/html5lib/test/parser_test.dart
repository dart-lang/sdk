library parser_test;

import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as pathos;
import 'package:unittest/unittest.dart';
import 'package:html5lib/dom.dart';
import 'package:html5lib/parser.dart';
import 'package:html5lib/parser_console.dart' as parser_console;
import 'package:html5lib/src/inputstream.dart' as inputstream;
import 'support.dart';

// Run the parse error checks
// TODO(jmesserly): presumably we want this on by default?
final checkParseErrors = false;

String namespaceHtml(String expected) {
  // TODO(jmesserly): this is a workaround for http://dartbug.com/2979
  // We can't do regex replace directly =\
  // final namespaceExpected = new RegExp(@"^(\s*)<(\S+)>", multiLine: true);
  // return expected.replaceAll(namespaceExpected, @"$1<html $2>");
  final namespaceExpected = new RegExp(r"^(\|\s*)<(\S+)>");
  var lines =  expected.split("\n");
  for (int i = 0; i < lines.length; i++) {
    var match = namespaceExpected.firstMatch(lines[i]);
    if (match != null) {
      lines[i] = "${match[1]}<html ${match[2]}>";
    }
  }
  return lines.join("\n");
}

void runParserTest(String groupName, String innerHTML, String input,
    String expected, List errors, TreeBuilderFactory treeCtor,
    bool namespaceHTMLElements) {

  // XXX - move this out into the setup function
  // concatenate all consecutive character tokens into a single token
  var builder = treeCtor(namespaceHTMLElements);
  var parser = new HtmlParser(input, tree: builder);

  Node document;
  if (innerHTML != null) {
    document = parser.parseFragment(innerHTML);
  } else {
    document = parser.parse();
  }

  var output = testSerializer(document);

  if (namespaceHTMLElements) {
    expected = namespaceHtml(expected);
  }

  expect(output, equals(expected), reason:
      "\n\nInput:\n$input\n\nExpected:\n$expected\n\nReceived:\n$output");

  if (checkParseErrors) {
    expect(parser.errors.length, equals(errors.length), reason:
        "\n\nInput:\n$input\n\nExpected errors (${errors.length}):\n"
        "${errors.join('\n')}\n\n"
        "Actual errors (${parser.errors.length}):\n"
        "${parser.errors.map((e) => '$e').join('\n')}");
  }
}


void main() {

  test('dart:io', () {
    // ensure IO support is unregistered
    expect(inputstream.consoleSupport,
        new isInstanceOf<inputstream.ConsoleSupport>());
    var file = new File('$testDataDir/parser_feature/raw_file.html').openSync();
    expect(() => parse(file), throwsA(new isInstanceOf<ArgumentError>()));
    parser_console.useConsole();
    expect(parse(file).body.innerHtml.trim(), 'Hello world!');
  });

  for (var path in getDataFiles('tree-construction')) {
    if (!path.endsWith('.dat')) continue;

    var tests = new TestData(path, "data");
    var testName = pathos.basenameWithoutExtension(path);

    group(testName, () {
      int index = 0;
      for (var testData in tests) {
        var input = testData['data'];
        var errors = testData['errors'];
        var innerHTML = testData['document-fragment'];
        var expected = testData['document'];
        if (errors != null) {
          errors = errors.split("\n");
        }

        for (var treeCtor in treeTypes.values) {
          for (var namespaceHTMLElements in const [false, true]) {
            test(_nameFor(input), () {
              runParserTest(testName, innerHTML, input, expected, errors,
                  treeCtor, namespaceHTMLElements);
            });
          }
        }

        index++;
      }
    });
  }
}

/// Extract the name for the test based on the test input data.
_nameFor(String input) {
  // Using JSON.decode to unescape other unicode characters
  var escapeQuote = input
      .replaceAll(new RegExp('\\\\.'), '_')
      .replaceAll(new RegExp('\u0000'), '_')
      .replaceAll('"', '\\"')
      .replaceAll(new RegExp('[\n\r\t]'),'_');
  return JSON.decode('"$escapeQuote"');
}
