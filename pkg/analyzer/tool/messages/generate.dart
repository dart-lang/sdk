/// This file contains code to generate scanner and parser message
/// based on the information in pkg/front_end/messages.yaml.
///
/// For each message in messages.yaml that contains an 'index:' field,
/// this tool generates an error with the name specified by the 'analyzerCode:'
/// field and an entry in the fastaAnalyzerErrorList for that generated error.
/// The text in the 'analyzerCode:' field must contain the name of the class
/// containing the error and the name of the error separated by a `.`
/// (e.g. ParserErrorCode.EQUALITY_CANNOT_BE_EQUALITY_OPERAND).
///
/// It is expected that 'pkg/front_end/tool/fasta generate-messages'
/// has already been successfully run.
import 'dart:io';

import 'package:_fe_analyzer_shared/src/scanner/scanner.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/src/dart/error/syntactic_errors.dart';
import 'package:analyzer_utilities/package_root.dart' as pkg_root;
import 'package:analyzer_utilities/tools.dart';
import 'package:path/path.dart';
import 'package:yaml/yaml.dart' show loadYaml;

main() async {
  String analyzerPkgPath = normalize(join(pkg_root.packageRoot, 'analyzer'));
  String frontEndPkgPath = normalize(join(pkg_root.packageRoot, 'front_end'));
  String frontEndSharedPkgPath =
      normalize(join(pkg_root.packageRoot, '_fe_analyzer_shared'));

  Map<dynamic, dynamic> messagesYaml =
      loadYaml(File(join(frontEndPkgPath, 'messages.yaml')).readAsStringSync());
  String errorConverterSource = File(join(analyzerPkgPath,
          joinAll(posix.split('lib/src/fasta/error_converter.dart'))))
      .readAsStringSync();
  String syntacticErrorsSource = File(join(analyzerPkgPath,
          joinAll(posix.split('lib/src/dart/error/syntactic_errors.dart'))))
      .readAsStringSync();
  String parserSource = File(join(frontEndSharedPkgPath,
          joinAll(posix.split('lib/src/parser/parser.dart'))))
      .readAsStringSync();

  final codeGenerator = _SyntacticErrorGenerator(
      messagesYaml, errorConverterSource, syntacticErrorsSource, parserSource);

  await GeneratedContent.generateAll(analyzerPkgPath, <GeneratedContent>[
    GeneratedFile('lib/src/dart/error/syntactic_errors.g.dart',
        (String pkgPath) async {
      codeGenerator.generateFormatCode();
      return codeGenerator.out.toString();
    }),
  ]);

  codeGenerator
    ..checkForManualChanges()
    ..printSummary();
}

const invalidAnalyzerCode = """
Error: Expected the text in the 'analyzerCode:' field to contain
       the name of the class containing the error
       and the name of the error separated by a `.`
       (e.g. ParserErrorCode.EQUALITY_CANNOT_BE_EQUALITY_OPERAND).
""";

const shouldRunFastaGenerateMessagesFirst = """
Error: After modifying messages.yaml, run this first:
       pkg/front_end/tool/fasta generate-messages
""";

/// Return an entry containing 2 strings,
/// the name of the class containing the error and the name of the error,
/// or throw an exception if 'analyzerCode:' field is invalid.
List<String> nameForEntry(Map entry) {
  final analyzerCode = entry['analyzerCode'];
  if (analyzerCode is String) {
    if (!analyzerCode.startsWith('ParserErrorCode.')) {
      throw invalidAnalyzerCode;
    }
    List<String> name = analyzerCode.split('.');
    if (name.length != 2 || name[1].isEmpty) {
      throw invalidAnalyzerCode;
    }
    return name;
  }
  throw invalidAnalyzerCode;
}

class _SyntacticErrorGenerator {
  final Map messagesYaml;
  final String errorConverterSource;
  final String syntacticErrorsSource;
  final String parserSource;
  final translatedEntries = <Map>[];
  final translatedFastaErrorCodes = <String>{};
  final out = StringBuffer('''
//
// THIS FILE IS GENERATED. DO NOT EDIT.
//
// Instead modify 'pkg/front_end/messages.yaml' and run
// 'dart pkg/analyzer/tool/messages/generate.dart' to update.

part of 'syntactic_errors.dart';

''');

  _SyntacticErrorGenerator(this.messagesYaml, this.errorConverterSource,
      this.syntacticErrorsSource, this.parserSource);

  void checkForManualChanges() {
    // Check for ParserErrorCodes that could be removed from
    // error_converter.dart now that those ParserErrorCodes are auto generated.
    int converterCount = 0;
    for (Map entry in translatedEntries) {
      final name = nameForEntry(entry);
      final errorCode = name[1];
      if (errorConverterSource.contains('"$errorCode"')) {
        if (converterCount == 0) {
          print('');
          print('The following ParserErrorCodes could be removed'
              ' from error_converter.dart:');
        }
        print('  $errorCode');
        ++converterCount;
      }
    }
    if (converterCount > 3) {
      print('  $converterCount total');
    }

    // Check that the public ParserErrorCodes have been updated
    // to reference the generated codes.
    int publicCount = 0;
    for (Map entry in translatedEntries) {
      final name = nameForEntry(entry);
      final errorCode = name[1];
      if (!syntacticErrorsSource.contains(' _$errorCode')) {
        if (publicCount == 0) {
          print('');
          print('The following ParserErrorCodes should be updated'
              ' in syntactic_errors.dart');
          print('to reference the associated generated error code:');
        }
        print('  static const ParserErrorCode $errorCode = _$errorCode;');
        ++publicCount;
      }
    }

    // Fail if there are manual changes to be made, but do so
    // in a fire and forget manner so that the files are still generated.
    if (converterCount > 0 || publicCount > 0) {
      print('');
      throw 'Error: missing manual code changes';
    }
  }

  void generateErrorCodes() {
    final sortedErrorCodes = <String>[];
    final entryMap = <String, Map>{};
    for (var entry in translatedEntries) {
      final name = nameForEntry(entry);
      final errorCode = name[1];
      sortedErrorCodes.add(errorCode);
      if (entryMap[errorCode] == null) {
        entryMap[errorCode] = entry;
      } else {
        throw 'Error: Duplicate error code $errorCode';
      }
    }
    sortedErrorCodes.sort();
    for (var errorCode in sortedErrorCodes) {
      final entry = entryMap[errorCode];
      final className = nameForEntry(entry)[0];
      out.writeln();
      out.writeln('const $className _$errorCode =');
      out.writeln('$className(');
      out.writeln("'$errorCode',");
      out.writeln('r"${entry['template']}"');
      final tip = entry['tip'];
      if (tip is String) {
        out.writeln(',correction: "$tip"');
      }
      final hasPublishedDocs = entry['hasPublishedDocs'];
      if (hasPublishedDocs is bool && hasPublishedDocs) {
        out.writeln(',hasPublishedDocs:true');
      }
      out.writeln(');');
    }
  }

  void generateFastaAnalyzerErrorCodeList() {
    final sorted = List<Map>.filled(translatedEntries.length, null);
    for (var entry in translatedEntries) {
      var index = entry['index'];
      if (index is int && index >= 1 && index <= sorted.length) {
        if (sorted[index - 1] == null) {
          sorted[index - 1] = entry;
          continue;
        }
      }
      throw shouldRunFastaGenerateMessagesFirst;
    }
    out.writeln('final fastaAnalyzerErrorCodes = <ErrorCode>[null,');
    for (var entry in sorted) {
      List<String> name = nameForEntry(entry);
      out.writeln('_${name[1]},');
    }
    out.writeln('];');
  }

  void generateFormatCode() {
    messagesYaml.forEach((name, entry) {
      if (entry is Map) {
        if (entry['index'] is int) {
          if (entry['analyzerCode'] is String) {
            translatedFastaErrorCodes.add(name);
            translatedEntries.add(entry);
          } else {
            throw invalidAnalyzerCode;
          }
        }
      }
    });
    generateFastaAnalyzerErrorCodeList();
    generateErrorCodes();
  }

  void printSummary() {
    // Build a map of error message to ParserErrorCode
    final messageToName = <String, String>{};
    for (ErrorCode errorCode in errorCodeValues) {
      if (errorCode is ParserErrorCode) {
        String message = errorCode.message.replaceAll(RegExp(r'\{\d+\}'), '');
        messageToName[message] = errorCode.name;
      }
    }

    String messageFromEntryTemplate(Map entry) {
      String template = entry['template'];
      String message = template.replaceAll(RegExp(r'#\w+'), '');
      return message;
    }

    // Remove entries that have already been translated
    for (Map entry in translatedEntries) {
      messageToName.remove(messageFromEntryTemplate(entry));
    }

    // Print the # of autogenerated ParserErrorCodes.
    print('${translatedEntries.length} of ${messageToName.length}'
        ' ParserErrorCodes generated.');

    // List the ParserErrorCodes that could easily be auto generated
    // but have not been already.
    final analyzerToFasta = <String, List<String>>{};
    messagesYaml.forEach((fastaName, entry) {
      if (entry is Map) {
        final analyzerName = messageToName[messageFromEntryTemplate(entry)];
        if (analyzerName != null) {
          analyzerToFasta
              .putIfAbsent(analyzerName, () => <String>[])
              .add(fastaName);
        }
      }
    });
    if (analyzerToFasta.isNotEmpty) {
      print('');
      print('The following ParserErrorCodes could be auto generated:');
      for (String analyzerName in analyzerToFasta.keys.toList()..sort()) {
        List<String> fastaNames = analyzerToFasta[analyzerName];
        if (fastaNames.length == 1) {
          print('  $analyzerName = ${fastaNames.first}');
        } else {
          print('  $analyzerName = $fastaNames');
        }
      }
      if (analyzerToFasta.length > 3) {
        print('  ${analyzerToFasta.length} total');
      }
    }

    // List error codes in the parser that have not been translated.
    final untranslatedFastaErrorCodes = <String>{};
    Token token = scanString(parserSource).tokens;
    while (!token.isEof) {
      if (token.isIdentifier) {
        String fastaErrorCode;
        String lexeme = token.lexeme;
        if (lexeme.length > 7) {
          if (lexeme.startsWith('message')) {
            fastaErrorCode = lexeme.substring(7);
          } else if (lexeme.length > 8) {
            if (lexeme.startsWith('template')) {
              fastaErrorCode = lexeme.substring(8);
            }
          }
        }
        if (fastaErrorCode != null &&
            !translatedFastaErrorCodes.contains(fastaErrorCode)) {
          untranslatedFastaErrorCodes.add(fastaErrorCode);
        }
      }
      token = token.next;
    }
    if (untranslatedFastaErrorCodes.isNotEmpty) {
      print('');
      print('The following error codes in the parser are not auto generated:');
      final sorted = untranslatedFastaErrorCodes.toList()..sort();
      for (String fastaErrorCode in sorted) {
        String analyzerCode = '';
        String template = '';
        var entry = messagesYaml[fastaErrorCode];
        if (entry is Map) {
          if (entry['index'] is! int && entry['analyzerCode'] is String) {
            analyzerCode = entry['analyzerCode'];
            template = entry['template'];
          }
        }
        print('  ${fastaErrorCode.padRight(30)} --> $analyzerCode'
            '\n      $template');
      }
    }
  }
}
