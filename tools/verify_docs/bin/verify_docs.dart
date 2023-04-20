// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Read the ../README.md file for the recognized syntax.

import 'dart:collection';
import 'dart:io';

import 'package:_fe_analyzer_shared/src/sdk/allowed_experiments.dart';
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
import 'package:analyzer/src/dart/analysis/experiments.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/util/comment.dart';
import 'package:path/path.dart' as path;

final libDir = Directory(path.join('sdk', 'lib'));
void main(List<String> args) async {
  if (!libDir.existsSync()) {
    print('Please run this tool from the root of the sdk repository.');
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
      : args.map(parseArg).toList();
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
    hadErrors |= !(await validateLibrary(dir));
  }

  exitCode = hadErrors ? 1 : 0;
}

Future<bool> validateLibrary(Directory dir) async {
  final libName = path.basename(dir.path);

  final analysisHelper = AnalysisHelper(libName);

  print('## dart:$libName');
  print('');

  var validDocs = true;

  for (final file in dir
      .listSync(recursive: true)
      .whereType<File>()
      .where((file) => file.path.endsWith('.dart'))) {
    validDocs &= await verifyFile(analysisHelper, libName, file, dir);
  }

  return validDocs;
}

final Future<AllowedExperiments> allowedExperiments = () async {
  final allowedExperimentsFile =
      File('sdk/lib/_internal/allowed_experiments.json');
  final contents = await allowedExperimentsFile.readAsString();
  return parseAllowedExperiments(contents);
}();

Future<bool> verifyFile(
  AnalysisHelper analysisHelper,
  String coreLibName,
  File file,
  Directory parent,
) async {
  final text = file.readAsStringSync();
  var parseResult = parseString(
    content: text,
    featureSet: FeatureSet.fromEnableFlags2(
      sdkLanguageVersion: ExperimentStatus.currentVersion,
      flags: (await allowedExperiments).sdkDefaultExperiments,
    ),
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
  return !visitor.hadErrors;
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
  bool hadErrors = false;

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
      final codeFenceSuffix = text
          .substring(offset + sampleStart.length, text.indexOf('\n', offset))
          .trim();

      offset = text.indexOf('\n', offset) + 1;
      final end = text.indexOf(sampleEnd, offset);

      var snippet = text.substring(offset, end);
      snippet = snippet.substring(0, snippet.lastIndexOf('\n'));

      List<String> lines = snippet.split('\n');
      var startLineNumber = commentLineStart +
          text.substring(0, offset - 1).split('\n').length -
          1;
      if (codeFenceSuffix == "continued") {
        if (samples.isEmpty) {
          throw "Continued code block without previous code";
        }
        samples.last = samples.last.append(lines, startLineNumber);
      } else {
        final directives = Set.unmodifiable(codeFenceSuffix.split(' '));
        samples.add(
          CodeSample(
            [for (var e in lines) '  ${cleanDocLine(e)}'],
            coreLibName: coreLibName,
            directives: directives,
            lineStartOffset: startLineNumber,
          ),
        );
      }

      offset = text.indexOf(sampleStart, offset);
    }
  }

  // RegExp detecting various top-level declarations or `main(`.
  //
  // If the top-level declaration is `library` or `import`,
  // then match 1 (`libdecl`) will be non-null.
  // This is a sign that no auto-imports should be added.
  //
  // If an import declaration is included in the sample, no
  // assumed-declarations are added.
  // Use the `import:foo` template to import other `dart:` libraries
  // instead of writing them explicitly to.
  //
  // Captures:
  // 1/libdecl: Non-null if matching a `library` declaration.
  // 2: Internal use, quote around import URI.
  // 3/importuri: Import URI.
  final _toplevelDeclarationRE = RegExp(r'^\s*(?:'
      r'library\b(?<libdecl>)|'
      r'''import (['"])(?<importuri>.*?)\2|'''
      r'final class\b|class\b|mixin\b|enum\b|extension\b|typedef\b|.*\bmain\('
      r')');

  validateCodeSample(CodeSample sample) async {
    final lines = sample.lines;

    // The default imports includes the library itself
    // and any import directives.
    Set<String> autoImports = sample.imports;

    // One of 'none', 'top, 'main', or 'expression'.
    String template;

    bool hasImport = false;

    final templateDirective = sample.templateDirective;
    if (templateDirective != null) {
      template = templateDirective;
    } else {
      // Scan lines for top-level declarations.
      bool hasTopDeclaration = false;
      bool hasLibraryDeclaration = false;
      for (var line in lines) {
        var topDeclaration = _toplevelDeclarationRE.firstMatch(line);
        if (topDeclaration != null) {
          hasTopDeclaration = true;
          hasLibraryDeclaration |=
              (topDeclaration.namedGroup("libdecl") != null);
          var importDecl = topDeclaration.namedGroup("importuri");
          if (importDecl != null) {
            hasImport = true;
            if (importDecl.startsWith('dart:')) {
              // Remove explicit imports from automatic imports
              // to avoid duplicate import warnings.
              autoImports.remove(importDecl.substring('dart:'.length));
            }
          }
        }
      }
      if (hasLibraryDeclaration) {
        template = 'none';
      } else if (hasTopDeclaration) {
        template = 'top';
      } else if (lines.length == 1 && !lines.first.contains(';')) {
        // If single line with no `;`, assume expression.
        template = 'expression';
      } else {
        // Otherwise default to `main`.
        template = 'main';
      }
    }

    var buffer = StringBuffer();

    if (template != 'none') {
      for (var library in autoImports) {
        buffer.writeln("import 'dart:$library';");
      }
      if (!hasImport) {
        buffer.write(sampleAssumptions ?? '');
      }
    }
    if (template == 'none' || template == 'top') {
      buffer.writeAllLines(lines);
    } else if (template == 'main') {
      buffer
        ..writeln('void main() async {')
        ..writeAllLines(lines)
        ..writeln('}');
    } else if (template == 'expression') {
      assert(lines.isNotEmpty);
      buffer
        ..writeln('void main() async =>')
        ..writeAllLines(lines.take(lines.length - 1))
        ..writeln("${lines.last.trimRight()};");
    } else {
      throw 'unexpected template directive: $template';
    }

    final text = buffer.toString();

    final result = await analysisHelper.resolveFile(text);

    if (result is ResolvedUnitResult) {
      var errors = SplayTreeSet<AnalysisError>.from(
        result.errors,
        (a, b) {
          var value = a.offset.compareTo(b.offset);
          if (value == 0) {
            value = a.message.compareTo(b.message);
          }
          return value;
        },
      );

      // Filter out unused imports, since we speculatively add imports to some
      // samples.
      errors.removeWhere(
        (e) => e.errorCode == WarningCode.UNUSED_IMPORT,
      );

      // Also, don't worry about 'unused_local_variable' and related; this may
      // be intentional in samples.
      errors.removeWhere(
        (e) =>
            e.errorCode == HintCode.UNUSED_LOCAL_VARIABLE ||
            e.errorCode == WarningCode.UNUSED_ELEMENT,
      );

      // Handle edge case around dart:_http
      errors.removeWhere((e) {
        if (e.message.contains("'dart:_http'")) {
          return e.errorCode == HintCode.UNNECESSARY_IMPORT ||
              e.errorCode == CompileTimeErrorCode.IMPORT_INTERNAL_LIBRARY;
        }
        return false;
      });

      if (errors.isNotEmpty) {
        print('$filePath:${sample.lineStartOffset}: ${errors.length} errors');

        hadErrors = true;

        for (final error in errors) {
          final location = result.lineInfo.getLocation(error.offset);
          print(
            '  ${_severity(error.severity)}: ${error.message} '
            '[$location] (${error.errorCode.name.toLowerCase()})',
          );
        }
        print('');

        // Print out the code sample.
        print(sample.lines
            .map((line) =>
                '  >${line.length >= 5 ? line.substring(5) : line.trimLeft()}')
            .join('\n'));
        print('');
      }
    } else {
      throw 'unexpected result type: $result';
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
  /// Currently valid template names.
  static const validTemplates = ['none', 'top', 'main', 'expression'];

  final String coreLibName;
  final Set<String> directives;
  final List<String> lines;
  final int lineStartOffset;

  CodeSample(
    this.lines, {
    required this.coreLibName,
    this.directives = const {},
    required this.lineStartOffset,
  });

  String get text => lines.join('\n');

  bool get hasTemplateDirective => templateDirective != null;

  /// The specified template, or `null` if no template is specified.
  ///
  /// A specified template must be of [validTemplates].
  String? get templateDirective {
    const prefix = 'template:';

    for (var directive in directives) {
      if (directive.startsWith(prefix)) {
        var result = directive.substring(prefix.length);
        if (!validTemplates.contains(result)) {
          throw "Invalid template name: $result";
        }
        return result;
      }
    }
    return null;
  }

  /// The implicit or explicitly requested imports.
  Set<String> get imports => {
        if (coreLibName != 'internal' && coreLibName != 'core') coreLibName,
        for (var directive in directives)
          if (directive.startsWith('import:'))
            directive.substring('import:'.length)
      };

  /// Creates a new code sample by appending [lines] to this sample.
  ///
  /// The new sample only differs from this sample in that it has
  /// more lines appended, first `this.lines`, then a gap of `  //` lines
  /// and then [lines].
  CodeSample append(List<String> lines, int lineStartOffset) {
    var gapSize = lineStartOffset - (this.lineStartOffset + this.lines.length);
    return CodeSample(
        [...this.lines, for (var i = 0; i < gapSize; i++) "  //", ...lines],
        coreLibName: coreLibName,
        directives: directives,
        lineStartOffset: this.lineStartOffset);
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
  late final String separator = resourceProvider.pathContext.separator;
  late final pathRoot = Directory('sdk${separator}lib$separator').absolute.path;
  late AnalysisContextCollection collection;
  int index = 0;

  AnalysisHelper(this.libraryName) {
    resourceProvider.pathContext;

    collection = AnalysisContextCollection(
      includedPaths: ['$pathRoot$libraryName'],
      resourceProvider: resourceProvider,
    );
  }

  Future<SomeResolvedUnitResult> resolveFile(String contents) async {
    final samplePath = '$pathRoot$libraryName$separator'
        'sample_${index++}.dart';
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

// Helper function to make things easier to read.
extension on StringBuffer {
  /// Write every line, right-trimmed, of [lines] with a newline after.
  void writeAllLines(Iterable<String> lines) {
    for (var line in lines) {
      writeln(line.trimRight());
    }
  }
}

/// Interprets [arg] as directory containing a platform library.
///
/// If [arg] is `dart:foo`, the directory is the default directory for
/// the `dart:foo` library source.
/// Otherwise, if [arg] is a directory (relative to the current directory)
/// which exists, that is the result.
/// Otherwise, if [arg] is the name of a platform library,
/// like `foo` where `dart:foo` is a platform library,
/// the result is the default directory for that library's source.
/// Otherwise it's treated as a directory relative to the current directory,
/// which doesn't exist (but that's what the error will refer to).
Directory parseArg(String arg) {
  if (arg.startsWith('dart:')) {
    return Directory(path.join(libDir.path, arg.substring('dart:'.length)));
  }
  var dir = Directory(arg);
  if (dir.existsSync()) return dir;
  var relDir = Directory(path.join(libDir.path, arg));
  if (relDir.existsSync()) return relDir;
  return dir;
}
