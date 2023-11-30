// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/src/utilities/extensions/file_system.dart';
import 'package:test/test.dart';

import '../../../util/element_printer.dart';
import '../../../util/tree_string_sink.dart';
import '../../summary/resolved_ast_printer.dart';

class ResolvedLibraryResultPrinter {
  final ResolvedLibraryResultPrinterConfiguration configuration;
  final TreeStringSink sink;
  final ElementPrinter elementPrinter;

  late final LibraryElement _libraryElement;

  ResolvedLibraryResultPrinter({
    required this.configuration,
    required this.sink,
    required this.elementPrinter,
  });

  void write(SomeResolvedLibraryResult result) {
    switch (result) {
      case ResolvedLibraryResult():
        _writeResolvedLibraryResult(result);
      default:
        throw UnimplementedError('${result.runtimeType}');
    }
  }

  void _writeResolvedLibraryResult(ResolvedLibraryResult result) {
    _libraryElement = result.element;

    sink.writeln('ResolvedLibraryResult');
    sink.withIndent(() {
      elementPrinter.writeNamedElement('element', result.element);
      sink.writeElements('units', result.units, _writeResolvedUnitResult);
    });
  }

  void _writeResolvedUnitResult(ResolvedUnitResult result) {
    ResolvedUnitResultPrinter(
      configuration: configuration.unitConfiguration,
      sink: sink,
      elementPrinter: elementPrinter,
      libraryElement: _libraryElement,
    ).write(result);
  }
}

class ResolvedLibraryResultPrinterConfiguration {
  var unitConfiguration = ResolvedUnitResultPrinterConfiguration();
}

class ResolvedUnitResultPrinter {
  final ResolvedUnitResultPrinterConfiguration configuration;
  final TreeStringSink sink;
  final ElementPrinter elementPrinter;
  final LibraryElement libraryElement;

  ResolvedUnitResultPrinter({
    required this.configuration,
    required this.sink,
    required this.elementPrinter,
    required this.libraryElement,
  });

  void write(SomeResolvedUnitResult result) {
    switch (result) {
      case ResolvedUnitResult():
        _writeResolvedUnitResult(result);
      default:
        throw UnimplementedError('${result.runtimeType}');
    }
  }

  void _writeAnalysisError(AnalysisError e) {
    sink.writelnWithIndent('${e.offset} +${e.length} ${e.errorCode.name}');
  }

  void _writeResolvedUnitResult(ResolvedUnitResult result) {
    sink.writelnWithIndent(result.file.posixPath);
    expect(result.path, result.file.path);

    // Don't write, just check.
    expect(result.libraryElement, same(libraryElement));

    sink.withIndent(() {
      sink.writeFlags({
        'exists': result.exists,
        'isAugmentation': result.isAugmentation,
        'isLibrary': result.isLibrary,
        'isMacroAugmentation': result.isMacroAugmentation,
        'isPart': result.isPart,
      });
      sink.writelnWithIndent('uri: ${result.uri}');

      if (configuration.withContentPredicate(result)) {
        sink.writelnWithIndent('content');
        sink.writeln('---');
        sink.write(result.content);
        sink.writeln('---');
      }

      sink.writeElements('errors', result.errors, _writeAnalysisError);

      final nodeToWrite = configuration.nodeSelector(result);
      if (nodeToWrite != null) {
        sink.writeWithIndent('selectedNode: ');
        nodeToWrite.accept(
          ResolvedAstPrinter(
            sink: sink,
            elementPrinter: elementPrinter,
            configuration: configuration.nodeConfiguration,
          ),
        );
      }
    });
  }
}

class ResolvedUnitResultPrinterConfiguration {
  var nodeConfiguration = ResolvedNodeTextConfiguration();
  AstNode? Function(ResolvedUnitResult) nodeSelector = (_) => null;
  bool Function(ResolvedUnitResult) withContentPredicate = (_) => false;
}
