// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:analyzer/file_system/physical_file_system.dart';
import 'package:analyzer_utilities/package_root.dart' as package_root;

import '../messages/error_code_documentation_info.dart';
import '../messages/error_code_info.dart';

/// Generate the file `diagnostics.md` based on the documentation associated
/// with the declarations of the error codes.
Future<void> main() async {
  var sink = File(computeOutputPath()).openWrite();
  var generator = DocumentationGenerator();
  generator.writeDocumentation(sink);
  await sink.flush();
  await sink.close();
}

/// Compute the path to the file into which documentation is being generated.
String computeOutputPath() {
  var pathContext = PhysicalResourceProvider.INSTANCE.pathContext;
  var packageRoot = pathContext.normalize(package_root.packageRoot);
  var analyzerPath = pathContext.join(packageRoot, 'analyzer');
  return pathContext.join(
      analyzerPath, 'tool', 'diagnostics', 'diagnostics.md');
}

/// An information holder containing information about a diagnostic that was
/// extracted from the instance creation expression.
class DiagnosticInformation {
  /// The name of the diagnostic.
  final String name;

  /// The messages associated with the diagnostic.
  List<String> messages;

  /// The previous names by which this diagnostic has been known.
  List<String> previousNames = [];

  /// The documentation text associated with the diagnostic.
  String? documentation;

  /// Initialize a newly created information holder with the given [name] and
  /// [message].
  DiagnosticInformation(this.name, String message) : messages = [message];

  /// Return `true` if this diagnostic has documentation.
  bool get hasDocumentation => documentation != null;

  /// Add the [message] to the list of messages associated with the diagnostic.
  void addMessage(String message) {
    if (!messages.contains(message)) {
      messages.add(message);
    }
  }

  void addPreviousName(String previousName) {
    if (!previousNames.contains(previousName)) {
      previousNames.add(previousName);
    }
  }

  /// Return the full documentation for this diagnostic.
  void writeOn(StringSink sink) {
    messages.sort();
    sink.writeln('### ${name.toLowerCase()}');
    for (var previousName in previousNames) {
      sink.writeln();
      var previousInLowerCase = previousName.toLowerCase();
      sink.writeln('<a id="$previousInLowerCase" aria-hidden="true"></a>'
          '_(Previously known as `$previousInLowerCase`)_');
    }
    for (String message in messages) {
      sink.writeln();
      for (String line in _split('_${_escape(message)}_')) {
        sink.writeln(line);
      }
    }
    sink.writeln();
    sink.writeln(documentation!);
  }

  /// Return a version of the [text] in which characters that have special
  /// meaning in markdown have been escaped.
  String _escape(String text) {
    return text.replaceAll('_', '\\_');
  }

  /// Split the [message] into multiple lines, each of which is less than 80
  /// characters long.
  List<String> _split(String message) {
    // This uses a brute force approach because we don't expect to have messages
    // that need to be split more than once.
    int length = message.length;
    if (length <= 80) {
      return [message];
    }
    int endIndex = message.lastIndexOf(' ', 80);
    if (endIndex < 0) {
      return [message];
    }
    return [message.substring(0, endIndex), message.substring(endIndex + 1)];
  }
}

/// A class used to generate diagnostic documentation.
class DocumentationGenerator {
  /// A map from the name of a diagnostic to the information about that
  /// diagnostic.
  Map<String, DiagnosticInformation> infoByName = {};

  /// Initialize a newly created documentation generator.
  DocumentationGenerator() {
    for (var classEntry in analyzerMessages.entries) {
      _extractAllDocs(classEntry.key, classEntry.value);
    }
    for (var errorClass in errorClasses) {
      if (errorClass.includeCfeMessages) {
        _extractAllDocs(
            errorClass.name, cfeToAnalyzerErrorCodeTables.analyzerCodeToInfo);
        // Note: only one error class has the `includeCfeMessages` flag set;
        // verify_diagnostics_test.dart verifies this. So we can safely break.
        break;
      }
    }
  }

  /// Write the documentation to the file at the given [outputPath].
  void writeDocumentation(StringSink sink) {
    _writeHeader(sink);
    _writeGlossary(sink);
    _writeDiagnostics(sink);
  }

  /// Extract documentation from all of the files containing the definitions of
  /// diagnostics.
  void _extractAllDocs(String className, Map<String, ErrorCodeInfo> messages) {
    for (var errorEntry in messages.entries) {
      var errorName = errorEntry.key;
      var errorCodeInfo = errorEntry.value;
      if (errorCodeInfo is AliasErrorCodeInfo) {
        continue;
      }
      var name = errorCodeInfo.sharedName ?? errorName;
      var info = infoByName[name];
      var message = convertTemplate(
          errorCodeInfo.computePlaceholderToIndexMap(),
          errorCodeInfo.problemMessage);
      if (info == null) {
        info = DiagnosticInformation(name, message);
        infoByName[name] = info;
      } else {
        info.addMessage(message);
      }
      var previousName = errorCodeInfo.previousName;
      if (previousName != null) {
        info.addPreviousName(previousName);
      }
      var docs = _extractDoc('$className.$errorName', errorCodeInfo);
      if (docs.isNotEmpty) {
        if (info.documentation != null) {
          throw StateError(
              'Documentation defined multiple times for ${info.name}');
        }
        info.documentation = docs;
      }
    }
  }

  /// Extract documentation from the given [errorCodeInfo].
  String _extractDoc(String errorCode, ErrorCodeInfo errorCodeInfo) {
    var parsedComment =
        parseErrorCodeDocumentation(errorCode, errorCodeInfo.documentation);
    if (parsedComment == null) {
      return '';
    }
    return [
      for (var documentationPart in parsedComment)
        documentationPart.formatForDocumentation()
    ].join('\n');
  }

  /// Write the documentation for all of the diagnostics.
  void _writeDiagnostics(StringSink sink) {
    sink.write('''

## Diagnostics

The analyzer produces the following diagnostics for code that
doesn't conform to the language specification or
that might work in unexpected ways.

[ffi]: https://dart.dev/guides/libraries/c-interop
[IEEE 754]: https://en.wikipedia.org/wiki/IEEE_754
[irrefutable pattern]: https://dart.dev/resources/glossary#irrefutable-pattern
[meta-doNotStore]: https://pub.dev/documentation/meta/latest/meta/doNotStore-constant.html
[meta-factory]: https://pub.dev/documentation/meta/latest/meta/factory-constant.html
[meta-immutable]: https://pub.dev/documentation/meta/latest/meta/immutable-constant.html
[meta-internal]: https://pub.dev/documentation/meta/latest/meta/internal-constant.html
[meta-literal]: https://pub.dev/documentation/meta/latest/meta/literal-constant.html
[meta-mustCallSuper]: https://pub.dev/documentation/meta/latest/meta/mustCallSuper-constant.html
[meta-optionalTypeArgs]: https://pub.dev/documentation/meta/latest/meta/optionalTypeArgs-constant.html
[meta-sealed]: https://pub.dev/documentation/meta/latest/meta/sealed-constant.html
[meta-useResult]: https://pub.dev/documentation/meta/latest/meta/useResult-constant.html
[meta-UseResult]: https://pub.dev/documentation/meta/latest/meta/UseResult-class.html
[meta-visibleForOverriding]: https://pub.dev/documentation/meta/latest/meta/visibleForOverriding-constant.html
[meta-visibleForTesting]: https://pub.dev/documentation/meta/latest/meta/visibleForTesting-constant.html
[refutable pattern]: https://dart.dev/resources/glossary#refutable-pattern
''');
    var errorCodes = infoByName.keys.toList();
    errorCodes.sort();
    for (String errorCode in errorCodes) {
      var info = infoByName[errorCode]!;
      if (info.hasDocumentation) {
        sink.writeln();
        info.writeOn(sink);
      }
    }
  }

  /// Link to the glossary.
  void _writeGlossary(StringSink sink) {
    sink.write(r'''

[constant context]: /resources/glossary#constant-context
[definite assignment]: /resources/glossary#definite-assignment
[mixin application]: /resources/glossary#mixin-application
[override inference]: /resources/glossary#override-inference
[part file]: /resources/glossary#part-file
[potentially non-nullable]: /resources/glossary#potentially-non-nullable
[public library]: /resources/glossary#public-library
''');
  }

  /// Write the header of the file.
  void _writeHeader(StringSink sink) {
    sink.write('''
---
title: Diagnostic messages
description: Details for diagnostics produced by the Dart analyzer.
body_class: highlight-diagnostics
---
{%- comment %}
WARNING: Do NOT EDIT this file directly. It is autogenerated by the script in
`pkg/analyzer/tool/diagnostics/generate.dart` in the sdk repository.
Update instructions: https://github.com/dart-lang/site-www/issues/1949
{% endcomment -%}

This page lists diagnostic messages produced by the Dart analyzer,
with details about what those messages mean and how you can fix your code.
For more information about the analyzer, see
[Customizing static analysis](/tools/analysis).
''');
  }
}
