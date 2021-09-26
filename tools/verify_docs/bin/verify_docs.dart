// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

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
  print('For documentation about how to author dart: code samples,'
      ' see tools/verify_docs/README.md');

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

  print('## dart:$libName');
  print('');

  var hadErrors = false;

  for (final file in dir
      .listSync(recursive: true)
      .whereType<File>()
      .where((file) => file.path.endsWith('.dart'))) {
    hadErrors |= await verifyFile(libName, file, dir);
  }

  return hadErrors;
}

Future<bool> verifyFile(String coreLibName, File file, Directory parent) async {
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
    // todo: have a better failure mode
    throw Exception(syntacticErrors);
  }

  var visitor = ValidateCommentCodeSamplesVisitor(
    coreLibName,
    file.path,
    parseResult.lineInfo,
  );
  await visitor.process(parseResult);
  if (visitor.errors.isNotEmpty) {
    print('${path.relative(file.path, from: parent.parent.path)}');
    print('${visitor.errors.toString()}');
  }

  return visitor.errors.isEmpty;
}

/// todo: doc
class ValidateCommentCodeSamplesVisitor extends GeneralizingAstVisitor {
  final String coreLibName;
  final String filePath;
  final LineInfo lineInfo;

  ValidateCommentCodeSamplesVisitor(
    this.coreLibName,
    this.filePath,
    this.lineInfo,
  );

  final List<CodeSample> samples = [];
  final StringBuffer errors = StringBuffer();

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
    // todo: ignore (or fail?) doc comments on non-public symbols
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
      offset = text.indexOf('\n', offset) + 1;
      final end = text.indexOf(sampleEnd, offset);

      var snippet = text.substring(offset, end);
      snippet = snippet.substring(0, snippet.lastIndexOf('\n'));

      List<String> lines = snippet.split('\n');

      // TODO(devoncarew): Also look for template directives.

      samples.add(
        CodeSample(
          coreLibName,
          lines.map((e) => '  ${cleanDocLine(e)}').join('\n'),
          commentLineStart +
              text.substring(0, offset - 1).split('\n').length -
              1,
        ),
      );

      offset = text.indexOf(sampleStart, offset);
    }
  }

  Future validateCodeSample(CodeSample sample) async {
    // TODO(devoncarew): Support <!-- template: none --> ?
    // TODO(devoncarew): Support <!-- template: main --> ?

    final resourceProvider =
        OverlayResourceProvider(PhysicalResourceProvider.INSTANCE);

    var text = sample.text;
    final lines = sample.text.split('\n').map((l) => l.trim()).toList();

    final hasImports = text.contains("import '") || text.contains('import "');
    var useDefaultTemplate = true;

    if (lines.any((line) =>
        line.startsWith('class ') ||
        line.startsWith('enum ') ||
        line.startsWith('extension '))) {
      useDefaultTemplate = false;
    }

    if (lines
        .any((line) => line.startsWith('main(') || line.contains(' main('))) {
      useDefaultTemplate = false;
    }

    if (!hasImports) {
      if (useDefaultTemplate) {
        text = "main() async {\n${text.trimRight()}\n}\n";
      }

      if (sample.coreLibName != 'internal') {
        text = "import 'dart:${sample.coreLibName}';\n$text";
      }
    }

    // Note: the file paths used below will currently only work on posix
    // filesystems.
    final sampleFilePath = '/sample.dart';

    resourceProvider.setOverlay(
      sampleFilePath,
      content: text,
      modificationStamp: 0,
    );

    // TODO(devoncarew): refactor to use AnalysisContextCollection to avoid
    // re-creating analysis contexts.
    final result = await resolveFile2(
      path: sampleFilePath,
      resourceProvider: resourceProvider,
    );

    resourceProvider.removeOverlay(sampleFilePath);

    if (result is ResolvedUnitResult) {
      // Filter out unused imports, since we speculatively add imports to some
      // samples.
      var errors =
          result.errors.where((e) => e.errorCode != HintCode.UNUSED_IMPORT);

      // Also, don't worry about 'unused_local_variable' and related; this may
      // be intentional in samples.
      errors = errors.where(
        (e) =>
            e.errorCode != HintCode.UNUSED_LOCAL_VARIABLE &&
            e.errorCode != HintCode.UNUSED_ELEMENT,
      );

      if (errors.isNotEmpty) {
        print('$filePath:${sample.lineStart}: ${errors.length} errors');

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
  final String text;
  final int lineStart;

  CodeSample(this.coreLibName, this.text, this.lineStart);
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
