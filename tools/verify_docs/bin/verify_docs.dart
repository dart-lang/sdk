// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/diagnostic/diagnostic.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/file_system/overlay_file_system.dart';
import 'package:analyzer/file_system/physical_file_system.dart';
import 'package:analyzer/source/line_info.dart';
import 'package:analyzer/src/dart/error/hint_codes.dart';
import 'package:analyzer/src/util/comment.dart';
import 'package:path/path.dart' as path;

void main(List<String> args) async {
  final libDir = Directory('sdk/lib');
  if (!libDir.existsSync()) {
    print('Please run this tool from the root of the sdk repo.');
    exit(1);
  }

  print('Validating the dartdoc code samples from the dart: libraries.');
  print('');
  print('To run this tool, run `dart tools/verify_docs/bin/verify_docs.dart`.');
  print('');
  print('For documentation about how to author dart: code samples,'
      ' see tools/verify_docs/README.md.');
  print('');

  final coreLibraries = args.isEmpty
      ? libDir.listSync().whereType<Directory>().toList()
      : args.map((arg) => Directory(arg)).toList();
  coreLibraries.sort((a, b) => a.path.compareTo(b.path));

  // Skip some dart: libraries.
  const skipLibraries = {
    'html',
    'indexed_db',
    'svg',
    'vmservice',
    'web_audio',
    'web_gl',
    'web_sql'
  };
  coreLibraries.removeWhere(
    (lib) => skipLibraries.contains(path.basename(lib.path)),
  );

  var hadErrors = false;
  for (final dir in coreLibraries) {
    hadErrors |= await validateLibrary(dir);
  }

  exitCode = hadErrors ? 1 : 0;
}

Future<bool> validateLibrary(Directory dir) async {
  final libName = path.basename(dir.path);

  final analysisHelper = AnalysisHelper(libName);

  print('## dart:$libName');
  print('');

  var hadErrors = false;

  for (final file in dir
      .listSync(recursive: true)
      .whereType<File>()
      .where((file) => file.path.endsWith('.dart'))) {
    hadErrors |= await verifyFile(analysisHelper, libName, file, dir);
  }

  return hadErrors;
}

Future<bool> verifyFile(
  AnalysisHelper analysisHelper,
  String coreLibName,
  File file,
  Directory parent,
) async {
  final text = file.readAsStringSync();
  var parseResult = parseString(
    content: text,
    featureSet: FeatureSet.latestLanguageVersion(),
    path: file.path,
    throwIfDiagnostics: false,
  );

  // Throw if there are syntactic errors.
  var syntacticErrors = parseResult.errors.where((error) {
    return error.errorCode.type == ErrorType.SYNTACTIC_ERROR;
  }).toList();
  if (syntacticErrors.isNotEmpty) {
    throw Exception(syntacticErrors);
  }

  final sampleAssumptions = findFileAssumptions(text);

  var visitor = ValidateCommentCodeSamplesVisitor(
    analysisHelper,
    coreLibName,
    file.path,
    parseResult.lineInfo,
    sampleAssumptions,
  );
  await visitor.process(parseResult);
  if (visitor.errors.isNotEmpty) {
    print('${path.relative(file.path, from: parent.parent.path)}');
    print('${visitor.errors.toString()}');
  }

  return visitor.errors.isEmpty;
}

/// Visit a compilation unit and validate the code samples found in dartdoc
/// comments.
class ValidateCommentCodeSamplesVisitor extends GeneralizingAstVisitor {
  final AnalysisHelper analysisHelper;
  final String coreLibName;
  final String filePath;
  final LineInfo lineInfo;
  final String? sampleAssumptions;

  final List<CodeSample> samples = [];
  final StringBuffer errors = StringBuffer();

  ValidateCommentCodeSamplesVisitor(
    this.analysisHelper,
    this.coreLibName,
    this.filePath,
    this.lineInfo,
    this.sampleAssumptions,
  );

  Future process(ParseStringResult parseResult) async {
    // collect code samples
    visitCompilationUnit(parseResult.unit);

    // analyze them
    for (CodeSample sample in samples) {
      await validateCodeSample(sample);
    }
  }

  @override
  void visitAnnotatedNode(AnnotatedNode node) {
    _handleDocumentableNode(node);
    super.visitAnnotatedNode(node);
  }

  void _handleDocumentableNode(AnnotatedNode node) {
    final docComment = node.documentationComment;
    if (docComment == null || !docComment.isDocumentation) {
      return;
    }

    const sampleStart = '```dart';
    const sampleEnd = '```';

    final text = getCommentNodeRawText(docComment)!;
    final commentOffset = docComment.offset;
    final commentLineStart = lineInfo.getLocation(commentOffset).lineNumber;
    if (!text.contains(sampleStart)) {
      return;
    }

    var offset = text.indexOf(sampleStart);
    while (offset != -1) {
      // Collect template directives, like "```dart import:async".
      final codeFenceSuffix = text.substring(
          offset + sampleStart.length, text.indexOf('\n', offset));
      final directives = Set.unmodifiable(codeFenceSuffix.trim().split(' '));

      offset = text.indexOf('\n', offset) + 1;
      final end = text.indexOf(sampleEnd, offset);

      var snippet = text.substring(offset, end);
      snippet = snippet.substring(0, snippet.lastIndexOf('\n'));

      List<String> lines = snippet.split('\n');

      samples.add(
        CodeSample(
          lines.map((e) => '  ${cleanDocLine(e)}').join('\n'),
          coreLibName: coreLibName,
          directives: directives,
          lineStartOffset: commentLineStart +
              text.substring(0, offset - 1).split('\n').length -
              1,
        ),
      );

      offset = text.indexOf(sampleStart, offset);
    }
  }

  Future validateCodeSample(CodeSample sample) async {
    var text = sample.text;
    final lines = sample.text.split('\n').map((l) => l.trim()).toList();

    final hasImports = text.contains("import '") || text.contains('import "');

    // One of 'none', 'main', or 'expression'.
    String? template;

    if (sample.hasTemplateDirective) {
      template = sample.templateDirective;
    } else {
      // If there's no explicit template, auto-detect one.
      if (lines.any((line) =>
          line.startsWith('class ') ||
          line.startsWith('enum ') ||
          line.startsWith('extension '))) {
        template = 'none';
      } else if (lines
          .any((line) => line.startsWith('main(') || line.contains(' main('))) {
        template = 'none';
      } else if (lines.length == 1 && !lines.first.trim().endsWith(';')) {
        template = 'expression';
      } else {
        template = 'main';
      }
    }

    final assumptions = sampleAssumptions ?? '';

    if (!hasImports) {
      if (template == 'none') {
        // just use the sample text as is
      } else if (template == 'main') {
        text = "${assumptions}main() async {\n${text.trimRight()}\n}\n";
      } else if (template == 'expression') {
        text = "${assumptions}main() async {\n${text.trimRight()}\n;\n}\n";
      } else {
        throw 'unexpected template directive: $template';
      }

      for (final directive
          in sample.directives.where((str) => str.startsWith('import:'))) {
        final libName = directive.substring('import:'.length);
        text = "import 'dart:$libName';\n$text";
      }

      if (sample.coreLibName != 'internal') {
        text = "import 'dart:${sample.coreLibName}';\n$text";
      }
    }

    final result = await analysisHelper.resolveFile(text);

    if (result is ResolvedUnitResult) {
      // Filter out unused imports, since we speculatively add imports to some
      // samples.
      var errors = result.errors.where(
        (e) => e.errorCode != HintCode.UNUSED_IMPORT,
      );

      // Also, don't worry about 'unused_local_variable' and related; this may
      // be intentional in samples.
      errors = errors.where(
        (e) =>
            e.errorCode != HintCode.UNUSED_LOCAL_VARIABLE &&
            e.errorCode != HintCode.UNUSED_ELEMENT,
      );

      // Remove warnings about deprecated member use from the same library.
      errors = errors.where(
        (e) =>
            e.errorCode != HintCode.DEPRECATED_MEMBER_USE_FROM_SAME_PACKAGE &&
            e.errorCode !=
                HintCode.DEPRECATED_MEMBER_USE_FROM_SAME_PACKAGE_WITH_MESSAGE,
      );

      if (errors.isNotEmpty) {
        print('$filePath:${sample.lineStartOffset}: ${errors.length} errors');

        errors = errors.toList()
          ..sort(
            (a, b) => a.offset - b.offset,
          );

        for (final error in errors) {
          final location = result.lineInfo.getLocation(error.offset);
          print(
            '  ${_severity(error.severity)}: ${error.message} '
            '[$location] (${error.errorCode.name.toLowerCase()})',
          );
        }
        print('');

        // Print out the code sample.
        print(sample.text
            .split('\n')
            .map((line) =>
                '  >${line.length >= 5 ? line.substring(5) : line.trimLeft()}')
            .join('\n'));
        print('');
      }
    } else {
      throw 'unexpected result type: ${result}';
    }

    return;
  }
}

String cleanDocLine(String line) {
  var copy = line.trimLeft();
  if (copy.startsWith('///')) {
    copy = copy.substring(3);
  } else if (copy.startsWith('*')) {
    copy = copy.substring(1);
  }
  return copy.padLeft(line.length, ' ');
}

class CodeSample {
  final String coreLibName;
  final Set<String> directives;
  final String text;
  final int lineStartOffset;

  CodeSample(
    this.text, {
    required this.coreLibName,
    this.directives = const {},
    required this.lineStartOffset,
  });

  bool get hasTemplateDirective => templateDirective != null;

  String? get templateDirective {
    const prefix = 'template:';

    String? match = directives.cast<String?>().firstWhere(
        (directive) => directive!.startsWith(prefix),
        orElse: () => null);
    return match == null ? match : match.substring(prefix.length);
  }
}

/// Find and return any '// Examples can assume:' sample text.
String? findFileAssumptions(String text) {
  var inAssumptions = false;
  var assumptions = <String>[];

  for (final line in text.split('\n')) {
    if (line == '// Examples can assume:') {
      inAssumptions = true;
    } else if (line.trim().isEmpty && inAssumptions) {
      inAssumptions = false;
    } else if (inAssumptions) {
      assumptions.add(line.substring('// '.length));
    }
  }

  return '${assumptions.join('\n')}\n';
}

String _severity(Severity severity) {
  switch (severity) {
    case Severity.info:
      return 'info';
    case Severity.warning:
      return 'warning';
    case Severity.error:
      return 'error';
  }
}

class AnalysisHelper {
  final String libraryName;
  final resourceProvider =
      OverlayResourceProvider(PhysicalResourceProvider.INSTANCE);
  late AnalysisContextCollection collection;
  int index = 0;

  AnalysisHelper(this.libraryName) {
    collection = AnalysisContextCollection(
      includedPaths: ['/$libraryName'],
      resourceProvider: resourceProvider,
    );
  }

  Future<SomeResolvedUnitResult> resolveFile(String contents) async {
    final samplePath = '/$libraryName/sample_${index++}.dart';
    resourceProvider.setOverlay(
      samplePath,
      content: contents,
      modificationStamp: 0,
    );

    var analysisContext = collection.contextFor(samplePath);
    var analysisSession = analysisContext.currentSession;
    return await analysisSession.getResolvedUnit(samplePath);
  }
}
