// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/src/dart/analysis/driver_event.dart' as events;
import 'package:analyzer/src/dart/analysis/results.dart';
import 'package:analyzer/src/dart/analysis/status.dart';
import 'package:analyzer/src/summary/idl.dart';
import 'package:analyzer/src/utilities/extensions/file_system.dart';
import 'package:analyzer_utilities/testing/tree_string_sink.dart';
import 'package:test/test.dart';

import '../../../util/element_printer.dart';
import '../../summary/resolved_ast_printer.dart';

sealed class DriverEvent {}

class DriverEventsPrinter {
  final DriverEventsPrinterConfiguration configuration;
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
    for (var event in events) {
      _writeEvent(event);
    }
  }

  void _writeAnalysisError(AnalysisError e) {
    sink.writelnWithIndent('${e.offset} +${e.length} ${e.errorCode.name}');
  }

  void _writeErrorsEvent(GetErrorsEvent event) {
    _writeGetEvent(event);
    sink.withIndent(() {
      _writeErrorsResult(event.result);
    });
  }

  void _writeErrorsResult(SomeErrorsResult result) {
    switch (result) {
      case ErrorsResultImpl():
        var id = idProvider[result];
        sink.writelnWithIndent('ErrorsResult $id');

        sink.withIndent(() {
          sink.writelnWithIndent('path: ${result.file.posixPath}');
          expect(result.path, result.file.path);

          sink.writelnWithIndent('uri: ${result.uri}');

          sink.writeFlags({
            'isLibrary': result.isLibrary,
            'isMacroPart': result.isMacroPart,
            'isPart': result.isPart,
          });

          if (configuration.errorsConfiguration.withContentPredicate(result)) {
            sink.writelnWithIndent('content');
            sink.writeln('---');
            sink.write(result.content);
            sink.writeln('---');
          }

          sink.writeElements('errors', result.errors, _writeAnalysisError);
        });
      default:
        throw UnimplementedError('${result.runtimeType}');
    }
  }

  void _writeEvent(DriverEvent event) {
    switch (event) {
      case GetCachedResolvedUnitEvent():
        _writeGetCachedResolvedUnit(event);
      case GetErrorsEvent():
        _writeErrorsEvent(event);
      case GetIndexEvent():
        _writeIndexEvent(event);
      case GetLibraryByUriEvent():
        _writeGetLibraryByUriEvent(event);
      case GetResolvedLibraryEvent():
        _writeGetResolvedLibrary(event);
      case GetResolvedLibraryByUriEvent():
        _writeGetResolvedLibraryByUri(event);
      case GetResolvedUnitEvent():
        _writeGetResolvedUnit(event);
      case GetUnitElementEvent():
        _writeGetUnitElementEvent(event);
      case ResultStreamEvent():
        _writeResultStreamEvent(event);
      case SchedulerStatusEvent():
        _writeSchedulerStatusEvent(event);
    }
  }

  void _writeGetCachedResolvedUnit(GetCachedResolvedUnitEvent event) {
    _writeGetEvent(event);
    sink.withIndent(() {
      if (event.result case var result?) {
        _writeResolvedUnitResult(result);
      } else {
        sink.writelnWithIndent('null');
      }
    });
  }

  void _writeGetEvent(GetDriverEvent event) {
    sink.writelnWithIndent('[future] ${event.methodName} ${event.name}');
  }

  void _writeGetLibraryByUriEvent(GetLibraryByUriEvent event) {
    _writeGetEvent(event);
    sink.withIndent(() {
      _writeLibraryElementResult(event.result);
    });
  }

  void _writeGetResolvedLibrary(GetResolvedLibraryEvent event) {
    _writeGetEvent(event);
    sink.withIndent(() {
      _writeResolvedLibraryResult(event.result);
    });
  }

  void _writeGetResolvedLibraryByUri(GetResolvedLibraryByUriEvent event) {
    _writeGetEvent(event);
    sink.withIndent(() {
      _writeResolvedLibraryResult(event.result);
    });
  }

  void _writeGetResolvedUnit(GetResolvedUnitEvent event) {
    _writeGetEvent(event);
    sink.withIndent(() {
      _writeResolvedUnitResult(event.result);
    });
  }

  void _writeGetUnitElementEvent(GetUnitElementEvent event) {
    _writeGetEvent(event);
    sink.withIndent(() {
      var result = event.result;
      switch (result) {
        case UnitElementResult():
          _writeUnitElementResult(result);
        default:
          throw UnimplementedError('${result.runtimeType}');
      }
    });
  }

  void _writeIndexEvent(GetIndexEvent event) {
    _writeGetEvent(event);
    sink.withIndent(() {
      if (event.result case var result?) {
        sink.writeElements('strings', result.strings, (str) {
          sink.writelnWithIndent(str);
        });
      }
    });
  }

  void _writeLibraryElementResult(SomeLibraryElementResult result) {
    switch (result) {
      case CannotResolveUriResult():
        sink.writelnWithIndent('CannotResolveUriResult');
      case NotLibraryButPartResult():
        sink.writelnWithIndent('NotLibraryButPartResult');
      default:
        throw UnimplementedError('${result.runtimeType}');
    }
  }

  void _writeResolvedLibraryResult(SomeResolvedLibraryResult result) {
    switch (result) {
      case CannotResolveUriResult():
        sink.writelnWithIndent('CannotResolveUriResult');
      case NotLibraryButPartResult():
        sink.writelnWithIndent('NotLibraryButPartResult');
      case ResolvedLibraryResult():
        ResolvedLibraryResultPrinter(
          configuration: configuration.libraryConfiguration,
          sink: sink,
          idProvider: idProvider,
          elementPrinter: ElementPrinter(
            sink: sink,
            configuration: ElementPrinterConfiguration(),
          ),
        ).write(result);
      default:
        throw UnimplementedError('${result.runtimeType}');
    }
  }

  void _writeResolvedUnitResult(SomeResolvedUnitResult result) {
    ResolvedUnitResultPrinter(
      configuration: configuration.libraryConfiguration.unitConfiguration,
      sink: sink,
      elementPrinter: elementPrinter,
      idProvider: idProvider,
      libraryElement: null,
    ).write(result);
  }

  void _writeResultStreamEvent(ResultStreamEvent event) {
    var object = event.object;
    switch (object) {
      case events.AnalyzeFile():
        sink.writelnWithIndent('[operation] analyzeFile');
        sink.withIndent(() {
          var file = object.file.resource;
          sink.writelnWithIndent('file: ${file.posixPath}');
          var libraryFile = object.library.file.resource;
          sink.writelnWithIndent('library: ${libraryFile.posixPath}');
        });
      case ErrorsResult():
        sink.writelnWithIndent('[stream]');
        sink.withIndent(() {
          _writeErrorsResult(object);
        });
      case events.GetErrorsFromBytes():
        sink.writelnWithIndent('[operation] getErrorsFromBytes');
        sink.withIndent(() {
          var file = object.file.resource;
          sink.writelnWithIndent('file: ${file.posixPath}');
          var libraryFile = object.library.file.resource;
          sink.writelnWithIndent('library: ${libraryFile.posixPath}');
        });
      case ResolvedUnitResult():
        if (!configuration.withStreamResolvedUnitResults) {
          return;
        }
        sink.writelnWithIndent('[stream]');
        sink.withIndent(() {
          _writeResolvedUnitResult(object);
        });
      default:
        throw UnimplementedError('${object.runtimeType}');
    }
  }

  void _writeSchedulerStatusEvent(SchedulerStatusEvent event) {
    sink.writeIndentedLine(() {
      sink.write('[status] ');
      switch (event.status) {
        case AnalysisStatusIdle():
          sink.write('idle');
        case AnalysisStatusWorking():
          sink.write('working');
      }
    });
  }

  void _writeUnitElementResult(UnitElementResult result) {
    sink.writelnWithIndent('path: ${result.file.posixPath}');
    expect(result.path, result.file.path);

    sink.writelnWithIndent('uri: ${result.uri}');

    sink.writeFlags({
      'isLibrary': result.isLibrary,
      'isMacroPart': result.isMacroPart,
      'isPart': result.isPart,
    });

    var unitElement = result.element;

    elementPrinter.writeNamedElement(
      'enclosing',
      unitElement.enclosingElement3,
    );

    var elementsToWrite =
        configuration.unitElementConfiguration.elementSelector(unitElement);
    elementPrinter.writeElementList('selectedElements', elementsToWrite);
  }
}

class DriverEventsPrinterConfiguration {
  var libraryConfiguration = ResolvedLibraryResultPrinterConfiguration();
  var unitElementConfiguration = UnitElementPrinterConfiguration();
  var errorsConfiguration = ErrorsResultPrinterConfiguration();
  var withStreamResolvedUnitResults = true;
}

class ErrorsResultPrinterConfiguration {
  bool Function(FileResult) withContentPredicate = (_) => false;
}

/// The result of `getCachedResolvedUnit`.
final class GetCachedResolvedUnitEvent extends GetDriverEvent {
  final SomeResolvedUnitResult? result;

  GetCachedResolvedUnitEvent({
    required super.name,
    required this.result,
  });

  @override
  String get methodName => 'getCachedResolvedUnit';
}

sealed class GetDriverEvent extends DriverEvent {
  final String name;

  GetDriverEvent({
    required this.name,
  });

  String get methodName;
}

/// The result of `getErrors`.
final class GetErrorsEvent extends GetDriverEvent {
  final SomeErrorsResult result;

  GetErrorsEvent({
    required super.name,
    required this.result,
  });

  @override
  String get methodName => 'getErrors';
}

/// The result of `getIndex`.
final class GetIndexEvent extends GetDriverEvent {
  final AnalysisDriverUnitIndex? result;

  GetIndexEvent({
    required super.name,
    required this.result,
  });

  @override
  String get methodName => 'getIndex';
}

/// The result of `getLibraryByUri`.
final class GetLibraryByUriEvent extends GetDriverEvent {
  final SomeLibraryElementResult result;

  GetLibraryByUriEvent({
    required super.name,
    required this.result,
  });

  @override
  String get methodName => 'getLibraryByUri';
}

/// The result of `getResolvedLibraryByUri`.
final class GetResolvedLibraryByUriEvent extends GetDriverEvent {
  final SomeResolvedLibraryResult result;

  GetResolvedLibraryByUriEvent({
    required super.name,
    required this.result,
  });

  @override
  String get methodName => 'getResolvedLibraryByUri';
}

/// The result of `getResolvedLibrary`.
final class GetResolvedLibraryEvent extends GetDriverEvent {
  final SomeResolvedLibraryResult result;

  GetResolvedLibraryEvent({
    required super.name,
    required this.result,
  });

  @override
  String get methodName => 'getResolvedLibrary';
}

/// The result of `getResolvedUnit`.
final class GetResolvedUnitEvent extends GetDriverEvent {
  final SomeResolvedUnitResult result;

  GetResolvedUnitEvent({
    required super.name,
    required this.result,
  });

  @override
  String get methodName => 'getResolvedUnit';
}

/// The result of `getUnitElement`.
final class GetUnitElementEvent extends GetDriverEvent {
  final SomeUnitElementResult result;

  GetUnitElementEvent({
    required super.name,
    required this.result,
  });

  @override
  String get methodName => 'getUnitElement';
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
    if (idProvider.existing(result) case var id?) {
      sink.writelnWithIndent('ResolvedLibraryResult $id');
      return;
    }

    _libraryElement = result.element;

    var id = idProvider[result];
    sink.writelnWithIndent('ResolvedLibraryResult $id');

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
    if (idProvider.existing(result) case var id?) {
      sink.writelnWithIndent('ResolvedUnitResult $id');
      return;
    }

    var id = idProvider[result];
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
        'isLibrary': result.isLibrary,
        'isMacroPart': result.isMacroPart,
        'isPart': result.isPart,
      });

      if (configuration.withContentPredicate(result)) {
        sink.writelnWithIndent('content');
        sink.writeln('---');
        sink.write(result.content);
        sink.writeln('---');
      }

      sink.writeElements('errors', result.errors, _writeAnalysisError);

      var nodeToWrite = configuration.nodeSelector(result);
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

      var typesToWrite = configuration.typesSelector(result);
      sink.writeElements(
        'selectedTypes',
        typesToWrite.entries.toList(),
        (entry) {
          sink.writeIndent();
          sink.write('${entry.key}: ');
          elementPrinter.writeType(entry.value);
        },
      );

      var variableTypesToWrite = configuration.variableTypesSelector(result);
      sink.writeElements(
        'selectedVariableTypes',
        variableTypesToWrite,
        (variable) {
          sink.writeIndent();
          sink.write('${variable.name}: ');
          elementPrinter.writeType(variable.type);
        },
      );
    });
  }
}

class ResolvedUnitResultPrinterConfiguration {
  var nodeConfiguration = ResolvedNodeTextConfiguration();
  AstNode? Function(ResolvedUnitResult) nodeSelector = (_) => null;
  Map<String, DartType> Function(ResolvedUnitResult) typesSelector = (_) => {};
  List<VariableElement> Function(ResolvedUnitResult) variableTypesSelector =
      (_) => [];
  bool Function(FileResult) withContentPredicate = (_) => false;
}

/// The event of received an object into the `results` stream.
final class ResultStreamEvent extends DriverEvent {
  final Object object;

  ResultStreamEvent({
    required this.object,
  });
}

final class SchedulerStatusEvent extends DriverEvent {
  final AnalysisStatus status;

  SchedulerStatusEvent(this.status);
}

class UnitElementPrinterConfiguration {
  List<Element> Function(CompilationUnitElement) elementSelector = (_) => [];
}
