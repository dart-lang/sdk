// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/src/dart/analysis/driver_event.dart' as events;
import 'package:analyzer/src/dart/analysis/results.dart';
import 'package:analyzer/src/utilities/extensions/file_system.dart';
import 'package:test/test.dart';

import '../../../util/element_printer.dart';
import '../../../util/tree_string_sink.dart';
import '../../summary/resolved_ast_printer.dart';

sealed class DriverEvent {}

class DriverEventsPrinter {
  final ResolvedLibraryResultPrinterConfiguration configuration;
  final TreeStringSink sink;
  final ElementPrinter elementPrinter;
  final IdProvider idProvider;

  DriverEventsPrinter({
    required this.configuration,
    required this.sink,
    required this.elementPrinter,
    required this.idProvider,
  });

  void write(List<DriverEvent> events) {
    for (final event in events) {
      _writeEvent(event);
    }
  }

  void _writeEvent(DriverEvent event) {
    switch (event) {
      case GetResolvedLibraryByUriEvent():
        _writeGetResolvedLibraryByUri(event);
      case GetResolvedUnitEvent():
        _writeGetResolvedUnit(event);
      case ResultStreamEvent():
        _writeResultStreamEvent(event);
      default:
        throw UnimplementedError('${event.runtimeType}');
    }
  }

  void _writeGetResolvedLibraryByUri(GetResolvedLibraryByUriEvent event) {
    sink.writelnWithIndent('[future] getResolvedLibraryByUri');
    sink.withIndent(() {
      sink.writelnWithIndent('name: ${event.name}');
      final result = event.result;
      switch (result) {
        case NotLibraryButAugmentationResult():
          sink.writelnWithIndent('NotLibraryButAugmentationResult');
        case ResolvedLibraryResult():
          ResolvedLibraryResultPrinter(
            configuration: configuration,
            sink: sink,
            idProvider: idProvider,
            elementPrinter: ElementPrinter(
              sink: sink,
              configuration: ElementPrinterConfiguration(),
              selfUriStr: null,
            ),
          ).write(result);
        default:
          throw UnimplementedError('${result.runtimeType}');
      }
    });
  }

  void _writeGetResolvedUnit(GetResolvedUnitEvent event) {
    sink.writelnWithIndent('[future] getResolvedUnit');
    sink.withIndent(() {
      sink.writelnWithIndent('name: ${event.name}');
      _writeResolvedUnitResult(event.result);
    });
  }

  void _writeResolvedUnitResult(SomeResolvedUnitResult result) {
    ResolvedUnitResultPrinter(
      configuration: configuration.unitConfiguration,
      sink: sink,
      elementPrinter: elementPrinter,
      idProvider: idProvider,
      libraryElement: null,
    ).write(result);
  }

  void _writeResultStreamEvent(ResultStreamEvent event) {
    final object = event.object;
    switch (object) {
      case events.ComputeAnalysis():
        sink.writelnWithIndent('[operation] computeAnalysisResult');
        sink.withIndent(() {
          final file = object.file.resource;
          sink.writelnWithIndent('file: ${file.posixPath}');
          final libraryFile = object.library.file.resource;
          sink.writelnWithIndent('library: ${libraryFile.posixPath}');
        });
      case events.ComputeResolvedLibrary():
        sink.writelnWithIndent('[operation] computeResolvedLibrary');
        sink.withIndent(() {
          final fileState = object.library.file;
          final file = fileState.resource;
          sink.writelnWithIndent('library: ${file.posixPath}');
        });
      case ResolvedUnitResult():
        sink.writelnWithIndent('[stream]');
        sink.withIndent(() {
          _writeResolvedUnitResult(object);
        });
      default:
        throw UnimplementedError('${object.runtimeType}');
    }
  }
}

/// The result of `getResolvedLibraryByUri`.
final class GetResolvedLibraryByUriEvent extends DriverEvent {
  final String name;
  final SomeResolvedLibraryResult result;

  GetResolvedLibraryByUriEvent({
    required this.name,
    required this.result,
  });
}

/// The result of `getResolvedUnit`.
final class GetResolvedUnitEvent extends DriverEvent {
  final String name;
  final SomeResolvedUnitResult result;

  GetResolvedUnitEvent({
    required this.name,
    required this.result,
  });
}

class IdProvider {
  final Map<Object, String> _map = Map.identity();

  String operator [](Object object) {
    return _map[object] ??= '#${_map.length}';
  }

  String? existing(Object object) {
    return _map[object];
  }
}

class ResolvedLibraryResultPrinter {
  final ResolvedLibraryResultPrinterConfiguration configuration;
  final TreeStringSink sink;
  final ElementPrinter elementPrinter;
  final IdProvider idProvider;

  late final LibraryElement _libraryElement;

  ResolvedLibraryResultPrinter({
    required this.configuration,
    required this.sink,
    required this.elementPrinter,
    required this.idProvider,
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

    sink.writelnWithIndent('ResolvedLibraryResult');
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
      idProvider: idProvider,
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
  final LibraryElement? libraryElement;
  final IdProvider idProvider;

  ResolvedUnitResultPrinter({
    required this.configuration,
    required this.sink,
    required this.elementPrinter,
    required this.libraryElement,
    required this.idProvider,
  });

  void write(SomeResolvedUnitResult result) {
    switch (result) {
      case ResolvedUnitResultImpl():
        _writeResolvedUnitResult(result);
      default:
        throw UnimplementedError('${result.runtimeType}');
    }
  }

  void _writeAnalysisError(AnalysisError e) {
    sink.writelnWithIndent('${e.offset} +${e.length} ${e.errorCode.name}');
  }

  void _writeResolvedUnitResult(ResolvedUnitResultImpl result) {
    if (idProvider.existing(result) case final id?) {
      sink.writelnWithIndent('ResolvedUnitResult $id');
      return;
    }

    final id = idProvider[result];
    sink.writelnWithIndent('ResolvedUnitResult $id');

    sink.withIndent(() {
      sink.writelnWithIndent('path: ${result.file.posixPath}');
      expect(result.path, result.file.path);

      sink.writelnWithIndent('uri: ${result.uri}');

      // Don't write, just check.
      if (libraryElement != null) {
        expect(result.libraryElement, same(libraryElement));
      }

      sink.writeFlags({
        'exists': result.exists,
        'isAugmentation': result.isAugmentation,
        'isLibrary': result.isLibrary,
        'isMacroAugmentation': result.isMacroAugmentation,
        'isPart': result.isPart,
      });

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

/// The event of received an object into the `results` stream.
final class ResultStreamEvent extends DriverEvent {
  final Object object;

  ResultStreamEvent({
    required this.object,
  });
}
