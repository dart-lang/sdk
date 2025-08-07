// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/diagnostic/diagnostic.dart';
import 'package:analyzer/src/dart/analysis/driver_event.dart' as events;
import 'package:analyzer/src/dart/analysis/library_graph.dart';
import 'package:analyzer/src/dart/analysis/results.dart';
import 'package:analyzer/src/dart/analysis/status.dart';
import 'package:analyzer/src/fine/library_manifest.dart';
import 'package:analyzer/src/fine/lookup_name.dart';
import 'package:analyzer/src/fine/manifest_ast.dart';
import 'package:analyzer/src/fine/manifest_context.dart';
import 'package:analyzer/src/fine/manifest_id.dart';
import 'package:analyzer/src/fine/manifest_item.dart';
import 'package:analyzer/src/fine/manifest_type.dart';
import 'package:analyzer/src/fine/requirement_failure.dart';
import 'package:analyzer/src/fine/requirements.dart';
import 'package:analyzer/src/summary/idl.dart';
import 'package:analyzer/src/utilities/extensions/file_system.dart';
import 'package:analyzer_utilities/testing/tree_string_sink.dart';
import 'package:collection/collection.dart';
import 'package:test/test.dart';

import '../../../util/element_printer.dart';
import '../../summary/element_text.dart';
import '../../summary/resolved_ast_printer.dart';

class BundleRequirementsPrinter {
  final DriverEventsPrinterConfiguration configuration;
  final TreeStringSink sink;
  final IdProvider idProvider;

  BundleRequirementsPrinter({
    required this.configuration,
    required this.sink,
    required this.idProvider,
  });

  void write(RequirementsManifest requirements) {
    sink.writelnWithIndent('requirements');
    sink.withIndent(() {
      _writeTopLevels(requirements);
      _writeInstanceItems(requirements);
      _writeInterfaceItems(requirements);
      _writeExportRequirements(requirements);
    });
  }

  void _writeExportCombinators(ExportRequirement requirement) {
    sink.writeElements('combinators', requirement.combinators, (combinator) {
      switch (combinator) {
        case ExportRequirementHideCombinator():
          var baseNames = combinator.hiddenBaseNames.sorted();
          sink.writelnWithIndent('hide ${baseNames.join(', ')}');
        case ExportRequirementShowCombinator():
          var baseNames = combinator.shownBaseNames.sorted();
          sink.writelnWithIndent('show ${baseNames.join(', ')}');
      }
    });
  }

  void _writeExportRequirements(RequirementsManifest requirements) {
    var exportRequirements = requirements.exportRequirements.sortedBy(
      (requirement) => requirement.libraryUri.toString(),
    );

    sink.writeElements('exportRequirements', exportRequirements, (
      libraryRequirements,
    ) {
      sink.writelnWithIndent(libraryRequirements.libraryUri);
      sink.withIndent(() {
        if (libraryRequirements.declaredTopNames.isNotEmpty) {
          var declaredTopNamesStr = libraryRequirements.declaredTopNames
              .map((lookupName) => lookupName.asString)
              .join(' ');
          sink.writelnWithIndent('declaredTopNames: $declaredTopNamesStr');
        }
        sink.writeElements(
          'exports',
          libraryRequirements.exports.sortedBy(
            (export) => export.exportedUri.toString(),
          ),
          (fragment) {
            sink.writelnWithIndent(fragment.exportedUri);
            sink.withIndent(() {
              _writeExportCombinators(fragment);
              for (var entry in fragment.exportedIds.sorted) {
                _writeNamedId(entry);
              }
            });
          },
        );
      });
    });
  }

  void _writeInstanceItems(RequirementsManifest requirements) {
    var libEntries = requirements.instances.sorted;

    libEntries.removeWhere((entry) {
      var ignored = configuration.requirements.ignoredLibraries;
      return ignored.contains(entry.key);
    });

    sink.writeElements('instances', libEntries, (libEntry) {
      var interfaceEntries = libEntry.value.sorted;
      sink.writeElements('${libEntry.key}', interfaceEntries, (instanceEntry) {
        var instanceRequirements = instanceEntry.value;
        sink.writelnWithIndent(instanceEntry.key.asString);

        sink.withIndent(() {
          void writeRequested(
            String name,
            Map<LookupName, ManifestItemId?> nameToIdMap,
          ) {
            sink.writeElements(name, nameToIdMap.sorted, _writeNamedId);
          }

          writeRequested(
            'requestedFields',
            instanceRequirements.requestedFields,
          );
          writeRequested(
            'requestedGetters',
            instanceRequirements.requestedGetters,
          );
          writeRequested(
            'requestedSetters',
            instanceRequirements.requestedSetters,
          );
          writeRequested(
            'requestedMethods',
            instanceRequirements.requestedMethods,
          );
        });

        sink.withIndent(() {
          void writeAllDeclared(String name, ManifestItemIdList? idList) {
            if (idList != null && idList.ids.isNotEmpty) {
              var idListStr = idList.asString(idProvider);
              sink.writelnWithIndent('$name: $idListStr');
            }
          }

          writeAllDeclared(
            'allDeclaredFields',
            instanceRequirements.allDeclaredFields,
          );
          writeAllDeclared(
            'allDeclaredGetters',
            instanceRequirements.allDeclaredGetters,
          );
          writeAllDeclared(
            'allDeclaredSetters',
            instanceRequirements.allDeclaredSetters,
          );
          writeAllDeclared(
            'allDeclaredMethods',
            instanceRequirements.allDeclaredMethods,
          );
        });
      });
    });
  }

  void _writeInterfaceItems(RequirementsManifest requirements) {
    var libEntries = requirements.interfaces.sorted;

    libEntries.removeWhere((entry) {
      var ignored = configuration.requirements.ignoredLibraries;
      return ignored.contains(entry.key);
    });

    sink.writeElements('interfaces', libEntries, (libEntry) {
      var interfaceEntries = libEntry.value.sorted;
      sink.writeElements('${libEntry.key}', interfaceEntries, (interfaceEntry) {
        sink.writelnWithIndent(interfaceEntry.key.asString);
        sink.withIndent(() {
          var requirements = interfaceEntry.value;
          if (requirements.interfaceId case var id?) {
            var idStr = idProvider.manifestId(id);
            sink.writelnWithIndent('interfaceId: $idStr');
          }
          sink.writeElements(
            'constructors',
            requirements.constructors.sorted,
            _writeNamedId,
          );
          sink.writeElements(
            'methods',
            requirements.methods.sorted,
            _writeNamedId,
          );
        });
      });
    });
  }

  void _writeNamedId(MapEntry<LookupName, ManifestItemId?> entry) {
    if (entry.value case var id?) {
      var idStr = idProvider.manifestId(id);
      sink.writelnWithIndent('${entry.key}: $idStr');
    } else {
      sink.writelnWithIndent('${entry.key}: <null>');
    }
  }

  void _writeTopLevels(RequirementsManifest requirements) {
    var libEntries = requirements.topLevels.sorted;
    sink.writeElements('topLevels', libEntries, (libEntry) {
      var topEntries = libEntry.value.sorted;
      sink.writeElements('${libEntry.key}', topEntries, (entry) {
        _writeNamedId(entry);
      });
    });
  }
}

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

  void _writeAnalyzeFileEvent(events.AnalyzeFile object) {
    if (!configuration.withAnalyzeFileEvents) {
      return;
    }

    sink.writelnWithIndent('[operation] analyzeFile');
    sink.withIndent(() {
      var file = object.file.resource;
      sink.writelnWithIndent('file: ${file.posixPath}');
      var libraryFile = object.library.file.resource;
      sink.writelnWithIndent('library: ${libraryFile.posixPath}');
    });
  }

  void _writeCannotReuseLinkedBundle(events.CannotReuseLinkedBundle event) {
    sink.writelnWithIndent('[operation] cannotReuseLinkedBundle');
    sink.withIndent(() {
      _writeRequirementFailure(event.failure);
    });
  }

  void _writeDiagnostic(Diagnostic d) {
    sink.writelnWithIndent('${d.offset} +${d.length} ${d.diagnosticCode.name}');
  }

  void _writeErrorsEvent(GetErrorsEvent event) {
    if (!configuration.withGetErrorsEvents) {
      return;
    }

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
            'isPart': result.isPart,
          });

          if (configuration.errorsConfiguration.withContentPredicate(result)) {
            sink.writelnWithIndent('content');
            sink.writeln('---');
            sink.write(result.content);
            sink.writeln('---');
          }

          sink.writeElements('errors', result.diagnostics, _writeDiagnostic);
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

  void _writeGetErrorsCannotReuse(events.GetErrorsCannotReuse event) {
    sink.writelnWithIndent('[operation] getErrorsCannotReuse');
    sink.withIndent(() {
      _writeRequirementFailure(event.failure);
    });
  }

  void _writeGetEvent(GetDriverEvent event) {
    sink.writelnWithIndent('[future] ${event.methodName} ${event.name}');
  }

  void _writeGetLibraryByUriEvent(GetLibraryByUriEvent event) {
    if (!configuration.withGetLibraryByUri) {
      return;
    }

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
      case LibraryElementResultImpl():
        writeLibrary(
          sink: sink,
          library: result.element,
          configuration: configuration.elementTextConfiguration,
        );
      default:
        throw UnimplementedError('${result.runtimeType}');
    }
  }

  void _writeLinkLibraryCycle(events.LinkLibraryCycle object) {
    if (!configuration.withLinkBundleEvents) {
      return;
    }

    const printName = 'linkLibraryCycle';
    if (object.cycle.isSdk) {
      sink.writelnWithIndent('[operation] $printName SDK');
      return;
    }

    sink.writelnWithIndent('[operation] $printName');
    sink.withIndent(() {
      var sortedLibraries = object.cycle.libraries.sortedBy(
        (libraryKind) => libraryKind.file.uriStr,
      );
      for (var libraryKind in sortedLibraries) {
        sink.writelnWithIndent(libraryKind.file.uriStr);
        if (configuration.withLibraryManifest) {
          sink.withIndent(() {
            var libraryElement = object.elementFactory.libraryOfUri2(
              libraryKind.file.uri,
            );
            var manifest = libraryElement.manifest!;
            LibraryManifestPrinter(
              configuration: configuration,
              sink: sink,
              idProvider: idProvider,
            ).write(manifest);
          });
        }
      }
      _writeRequirements(object.requirements);
    });
  }

  void _writeProduceErrorsCannotReuse(events.ProduceErrorsCannotReuse event) {
    sink.writelnWithIndent('[operation] produceErrorsCannotReuse');
    sink.withIndent(() {
      _writeRequirementFailure(event.failure);
    });
  }

  void _writeRequirementFailure(RequirementFailure failure) {
    switch (failure) {
      case LibraryMissing():
        // TODO(scheglov): Handle this case.
        throw UnimplementedError();
      case ExportCountMismatch():
        sink.writelnWithIndent('exportCountMismatch');
        sink.writeProperties({
          'fragmentUri': failure.fragmentUri,
          'exportedUri': failure.exportedUri,
          'expected': failure.expectedCount,
          'actual': failure.actualCount,
        });
      case ExportIdMismatch():
        sink.writelnWithIndent('exportIdMismatch');
        sink.writeProperties({
          'fragmentUri': failure.fragmentUri,
          'exportedUri': failure.exportedUri,
          'name': failure.name.asString,
          'expectedId': idProvider.manifestId(failure.expectedId),
          'actualId': idProvider.manifestId(failure.actualId),
        });
      case ExportLibraryMissing():
        // TODO(scheglov): Handle this case.
        throw UnimplementedError();
      case InstanceFieldIdMismatch():
        sink.writelnWithIndent('instanceFieldIdMismatch');
        sink.writeProperties({
          'libraryUri': failure.libraryUri,
          'interfaceName': failure.interfaceName.asString,
          'fieldName': failure.fieldName.asString,
          'expectedId': idProvider.manifestId(failure.expectedId),
          'actualId': idProvider.manifestId(failure.actualId),
        });
      case InstanceMethodIdMismatch():
        sink.writelnWithIndent('instanceMethodIdMismatch');
        sink.writeProperties({
          'libraryUri': failure.libraryUri,
          'interfaceName': failure.interfaceName.asString,
          'methodName': failure.methodName.asString,
          'expectedId': idProvider.manifestId(failure.expectedId),
          'actualId': idProvider.manifestId(failure.actualId),
        });
      case InstanceChildrenIdsMismatch():
        sink.writelnWithIndent('instanceChildrenIdsMismatch');
        sink.writeProperties({
          'libraryUri': failure.libraryUri,
          'instanceName': failure.instanceName.asString,
          'childrenPropertyName': failure.childrenPropertyName,
          'expectedIds': failure.expectedIds.asString(idProvider),
          'actualIds': failure.actualIds.asString(idProvider),
        });
      case InterfaceIdMismatch():
        sink.writelnWithIndent('interfaceIdMismatch');
        sink.writeProperties({
          'libraryUri': failure.libraryUri,
          'interfaceName': failure.interfaceName.asString,
          'expectedId': idProvider.manifestId(failure.expectedId),
          'actualId': idProvider.manifestId(failure.actualId),
        });
      case InterfaceConstructorIdMismatch():
        sink.writelnWithIndent('interfaceConstructorIdMismatch');
        sink.writeProperties({
          'libraryUri': failure.libraryUri,
          'interfaceName': failure.interfaceName.asString,
          'constructorName': failure.constructorName.asString,
          'expectedId': idProvider.manifestId(failure.expectedId),
          'actualId': idProvider.manifestId(failure.actualId),
        });
      case TopLevelIdMismatch():
        sink.writelnWithIndent('topLevelIdMismatch');
        sink.writeProperties({
          'libraryUri': failure.libraryUri,
          'name': failure.name.asString,
          'expectedId': idProvider.manifestId(failure.expectedId),
          'actualId': idProvider.manifestId(failure.actualId),
        });
      case TopLevelNotInterface():
        // TODO(scheglov): Handle this case.
        throw UnimplementedError();
    }
  }

  void _writeRequirements(RequirementsManifest? requirements) {
    if (!configuration.withResultRequirements) {
      return;
    }

    if (requirements == null) {
      return;
    }

    BundleRequirementsPrinter(
      configuration: configuration,
      sink: sink,
      idProvider: idProvider,
    ).write(requirements);
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
        _writeAnalyzeFileEvent(object);
      case events.AnalyzedLibrary():
        sink.writelnWithIndent('[operation] analyzedLibrary');
        sink.withIndent(() {
          var libraryFile = object.library.file;
          sink.writelnWithIndent('file: ${libraryFile.resource.posixPath}');
          _writeRequirements(object.requirements);
        });
      case events.CannotReuseLinkedBundle():
        _writeCannotReuseLinkedBundle(object);
      case events.GetErrorsCannotReuse():
        _writeGetErrorsCannotReuse(object);
      case events.ProduceErrorsCannotReuse():
        _writeProduceErrorsCannotReuse(object);
      case events.LinkLibraryCycle():
        _writeLinkLibraryCycle(object);
      case events.ReuseLinkLibraryCycleBundle():
        _writeReuseLinkLibraryCycleBundle(object);
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

  void _writeReuseLinkLibraryCycleBundle(
    events.ReuseLinkLibraryCycleBundle event,
  ) {
    if (configuration.withLinkBundleEvents) {
      const printName = 'readLibraryCycleBundle';
      if (event.cycle.isSdk) {
        sink.writelnWithIndent('[operation] $printName SDK');
      } else {
        sink.writelnWithIndent('[operation] $printName');
        sink.withIndent(() {
          var uriStrList =
              event.cycle.libraries
                  .map((library) => library.file.uriStr)
                  .sorted();
          for (var uriStr in uriStrList) {
            sink.writelnWithIndent(uriStr);
          }
        });
      }
    }
  }

  void _writeSchedulerStatusEvent(SchedulerStatusEvent event) {
    if (!configuration.withSchedulerStatus) {
      return;
    }

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

    sink.writeFlags({'isLibrary': result.isLibrary, 'isPart': result.isPart});

    var libraryFragment = result.fragment;

    elementPrinter.writeNamedFragment(
      'enclosing',
      libraryFragment.enclosingFragment,
    );

    var elementsToWrite = configuration.unitElementConfiguration
        .elementSelector(libraryFragment);
    elementPrinter.writeElementList2('selectedElements', elementsToWrite);
  }
}

class DriverEventsPrinterConfiguration {
  var libraryConfiguration = ResolvedLibraryResultPrinterConfiguration();
  var unitElementConfiguration = UnitElementPrinterConfiguration();
  var errorsConfiguration = ErrorsResultPrinterConfiguration();
  var elementTextConfiguration = ElementTextConfiguration();
  var withAnalyzeFileEvents = true;
  var withGetErrorsEvents = true;
  var withGetLibraryByUri = true;
  var withElementManifests = false;
  var withLibraryManifest = false;
  var withLinkBundleEvents = false;
  var withResultRequirements = false;
  var withSchedulerStatus = true;
  var withStreamResolvedUnitResults = true;
  var requirements = RequirementPrinterConfiguration();

  var ignoredManifestInstanceMemberNames = <String>{
    '==',
    'hashCode',
    'noSuchMethod',
    'runtimeType',
    'toString',
    'new',
  };

  void includeDefaultConstructors() {
    ignoredManifestInstanceMemberNames.remove('new');
  }
}

class ErrorsResultPrinterConfiguration {
  bool Function(FileResult) withContentPredicate = (_) => false;
}

/// The result of `getCachedResolvedUnit`.
final class GetCachedResolvedUnitEvent extends GetDriverEvent {
  final SomeResolvedUnitResult? result;

  GetCachedResolvedUnitEvent({required super.name, required this.result});

  @override
  String get methodName => 'getCachedResolvedUnit';
}

sealed class GetDriverEvent extends DriverEvent {
  final String name;

  GetDriverEvent({required this.name});

  String get methodName;
}

/// The result of `getErrors`.
final class GetErrorsEvent extends GetDriverEvent {
  final SomeErrorsResult result;

  GetErrorsEvent({required super.name, required this.result});

  @override
  String get methodName => 'getErrors';
}

/// The result of `getIndex`.
final class GetIndexEvent extends GetDriverEvent {
  final AnalysisDriverUnitIndex? result;

  GetIndexEvent({required super.name, required this.result});

  @override
  String get methodName => 'getIndex';
}

/// The result of `getLibraryByUri`.
final class GetLibraryByUriEvent extends GetDriverEvent {
  final SomeLibraryElementResult result;

  GetLibraryByUriEvent({required super.name, required this.result});

  @override
  String get methodName => 'getLibraryByUri';
}

/// The result of `getResolvedLibraryByUri`.
final class GetResolvedLibraryByUriEvent extends GetDriverEvent {
  final SomeResolvedLibraryResult result;

  GetResolvedLibraryByUriEvent({required super.name, required this.result});

  @override
  String get methodName => 'getResolvedLibraryByUri';
}

/// The result of `getResolvedLibrary`.
final class GetResolvedLibraryEvent extends GetDriverEvent {
  final SomeResolvedLibraryResult result;

  GetResolvedLibraryEvent({required super.name, required this.result});

  @override
  String get methodName => 'getResolvedLibrary';
}

/// The result of `getResolvedUnit`.
final class GetResolvedUnitEvent extends GetDriverEvent {
  final SomeResolvedUnitResult result;

  GetResolvedUnitEvent({required super.name, required this.result});

  @override
  String get methodName => 'getResolvedUnit';
}

/// The result of `getUnitElement`.
final class GetUnitElementEvent extends GetDriverEvent {
  final SomeUnitElementResult result;

  GetUnitElementEvent({required super.name, required this.result});

  @override
  String get methodName => 'getUnitElement';
}

class IdProvider {
  final Map<Object, String> _map = Map.identity();
  final Map<ManifestItemId, String> _manifestIdMap = {};

  String operator [](Object object) {
    return _map[object] ??= '#${_map.length}';
  }

  String? existing(Object object) {
    return _map[object];
  }

  String manifestId(ManifestItemId? id) {
    if (id == null) return '<null>';
    return _manifestIdMap[id] ??= '#M${_manifestIdMap.length}';
  }
}

class LibraryManifestPrinter {
  final DriverEventsPrinterConfiguration configuration;
  final TreeStringSink sink;
  final IdProvider idProvider;

  LibraryManifestPrinter({
    required this.configuration,
    required this.sink,
    required this.idProvider,
  });

  void write(LibraryManifest manifest) {
    var classEntries = manifest.declaredClasses.sorted;
    sink.writeElements('declaredClasses', classEntries, (entry) {
      var item = entry.value;
      _writeNamedId(entry.key, item.id);
      _writeClassItem(item);
    });

    var enumEntries = manifest.declaredEnums.sorted;
    sink.writeElements('declaredEnums', enumEntries, (entry) {
      var item = entry.value;
      _writeNamedId(entry.key, item.id);
      _writeEnumItem(item);
    });

    var extensionEntries = manifest.declaredExtensions.sorted;
    sink.writeElements('declaredExtensions', extensionEntries, (entry) {
      var item = entry.value;
      _writeNamedId(entry.key, item.id);
      _writeExtensionItem(item);
    });

    var extensionTypeEntries = manifest.declaredExtensionTypes.sorted;
    sink.writeElements('declaredExtensionTypes', extensionTypeEntries, (entry) {
      var item = entry.value;
      _writeNamedId(entry.key, item.id);
      _writeExtensionTypeItem(item);
    });

    var mixinEntries = manifest.declaredMixins.sorted;
    sink.writeElements('declaredMixins', mixinEntries, (entry) {
      var item = entry.value;
      _writeNamedId(entry.key, item.id);
      _writeMixinItem(item);
    });

    var typeAliasEntries = manifest.declaredTypeAliases.sorted;
    sink.writeElements('declaredTypeAliases', typeAliasEntries, (entry) {
      var item = entry.value;
      _writeNamedId(entry.key, item.id);
      _writeTypeAliasItem(item);
    });

    var getterEntries = manifest.declaredGetters.sorted;
    sink.writeElements('declaredGetters', getterEntries, (entry) {
      var item = entry.value;
      _writeNamedId(entry.key, item.id);
      _writeTopLevelGetterItem(item);
    });

    var setterEntries = manifest.declaredSetters.sorted;
    sink.writeElements('declaredSetters', setterEntries, (entry) {
      var item = entry.value;
      _writeNamedId(entry.key, item.id);
      _writeTopLevelSetterItem(item);
    });

    var functionEntries = manifest.declaredFunctions;
    sink.writeElements('declaredFunctions', functionEntries.sorted, (entry) {
      var item = entry.value;
      _writeNamedId(entry.key, item.id);
      _writeTopLevelFunctionItem(item);
    });

    var variableEntries = manifest.declaredVariables;
    sink.writeElements('declaredVariables', variableEntries.sorted, (entry) {
      var item = entry.value;
      _writeNamedId(entry.key, item.id);
      _writeTopLevelVariableItem(item);
    });

    var reExportEntries = manifest.reExportMap.sorted;
    if (reExportEntries.isNotEmpty) {
      sink.writelnWithIndent('reExportMap');
      sink.withIndent(() {
        for (var entry in reExportEntries) {
          _writeNamedId(entry.key, entry.value);
        }
      });
    }
  }

  void _writeClassItem(ClassItem item) {
    if (configuration.withElementManifests) {
      sink.withIndent(() {
        _writeMetadata(item);
        _writeTypeParameters(item.typeParameters);
        _writeNamedType('supertype', item.supertype);
        _writeTypeList('mixins', item.mixins);
        _writeTypeList('interfaces', item.interfaces);
      });
    }

    sink.withIndent(() {
      _writeInstanceItemMembers(item);
      _writeInterfaceItemInterface(item);
    });
  }

  void _writeEnumItem(EnumItem item) {
    if (configuration.withElementManifests) {
      sink.withIndent(() {
        _writeMetadata(item);
        _writeTypeParameters(item.typeParameters);
        _writeTypeList('mixins', item.mixins);
        _writeTypeList('interfaces', item.interfaces);
      });
    }

    sink.withIndent(() {
      _writeInstanceItemMembers(item);
      _writeInterfaceItemInterface(item);
    });
  }

  void _writeExtensionItem(ExtensionItem item) {
    if (configuration.withElementManifests) {
      sink.withIndent(() {
        _writeMetadata(item);
        _writeTypeParameters(item.typeParameters);
        _writeNamedType('extendedType', item.extendedType);
      });
    }

    sink.withIndent(() {
      _writeInstanceItemMembers(item);
    });
  }

  void _writeExtensionTypeItem(ExtensionTypeItem item) {
    if (configuration.withElementManifests) {
      sink.withIndent(() {
        _writeMetadata(item);
        _writeTypeParameters(item.typeParameters);
        _writeTypeList('interfaces', item.interfaces);
      });
    }

    sink.withIndent(() {
      _writeInstanceItemMembers(item);
      _writeInterfaceItemInterface(item);
    });
  }

  void _writeInstanceItemMembers(InstanceItem item) {
    var ignored = configuration.ignoredManifestInstanceMemberNames;

    void writeDeclaredDuplicateNames() {
      var conflicts = item.declaredConflicts.sorted;
      if (conflicts.isNotEmpty) {
        sink.writelnWithIndent('declaredConflicts');
        sink.withIndent(() {
          for (var entry in conflicts) {
            var name = entry.key.asString;
            var idStr = idProvider.manifestId(entry.value);
            sink.writelnWithIndent('$name: $idStr');
          }
        });
      }
    }

    void writeDeclaredFields() {
      var declaredFields =
          item.declaredFields.sorted.whereNot((entry) {
            return ignored.contains(entry.key.asString);
          }).toList();

      if (declaredFields.isNotEmpty) {
        sink.writelnWithIndent('declaredFields');
        sink.withIndent(() {
          for (var entry in declaredFields) {
            var name = entry.key.asString;
            var item = entry.value;
            var idStr = idProvider.manifestId(item.id);
            sink.writelnWithIndent('$name: $idStr');
            if (configuration.withElementManifests) {
              sink.withIndent(() {
                _writeMetadata(item);
                _writeNamedType('type', item.type);
                _writeNode('constInitializer', item.constInitializer);
              });
            }
          }
        });
      }
    }

    void writeDeclaredGetters() {
      var declaredGetters =
          item.declaredGetters.sorted.whereNot((entry) {
            return ignored.contains(entry.key.asString);
          }).toList();

      if (declaredGetters.isNotEmpty) {
        sink.writelnWithIndent('declaredGetters');
        sink.withIndent(() {
          for (var entry in declaredGetters) {
            var name = entry.key.asString;
            var item = entry.value;
            var idStr = idProvider.manifestId(item.id);
            sink.writelnWithIndent('$name: $idStr');
            if (configuration.withElementManifests) {
              sink.withIndent(() {
                _writeMetadata(item);
                _writeNamedType('returnType', item.returnType);
              });
            }
          }
        });
      }
    }

    void writeDeclaredSetters() {
      var declaredSetters =
          item.declaredSetters.sorted.whereNot((entry) {
            return ignored.contains(entry.key.asString);
          }).toList();

      if (declaredSetters.isNotEmpty) {
        sink.writelnWithIndent('declaredSetters');
        sink.withIndent(() {
          for (var entry in declaredSetters) {
            var name = entry.key.asString;
            var item = entry.value;
            var idStr = idProvider.manifestId(item.id);
            sink.writelnWithIndent('$name: $idStr');
            if (configuration.withElementManifests) {
              sink.withIndent(() {
                _writeMetadata(item);
                _writeNamedType('valueType', item.valueType);
              });
            }
          }
        });
      }
    }

    void writeDeclaredMethods() {
      var declaredMethods =
          item.declaredMethods.sorted.whereNot((entry) {
            return ignored.contains(entry.key.asString);
          }).toList();

      if (declaredMethods.isNotEmpty) {
        sink.writelnWithIndent('declaredMethods');
        sink.withIndent(() {
          for (var entry in declaredMethods) {
            var name = entry.key.asString;
            var item = entry.value;
            var idStr = idProvider.manifestId(item.id);
            sink.writelnWithIndent('$name: $idStr');
            if (configuration.withElementManifests) {
              sink.withIndent(() {
                _writeMetadata(item);
                _writeNamedType('functionType', item.functionType);
              });
            }
          }
        });
      }
    }

    void writeDeclaredConstructors() {
      var declaredConstructors =
          item.declaredConstructors.sorted.whereNot((entry) {
            return ignored.contains(entry.key.asString);
          }).toList();

      if (declaredConstructors.isNotEmpty) {
        sink.writelnWithIndent('declaredConstructors');
        sink.withIndent(() {
          for (var entry in declaredConstructors) {
            var name = entry.key.asString;
            var item = entry.value;
            var idStr = idProvider.manifestId(item.id);
            sink.writelnWithIndent('$name: $idStr');
            if (configuration.withElementManifests) {
              sink.withIndent(() {
                sink.withIndent(() {
                  _writeMetadata(item);
                  _writeNamedType('functionType', item.functionType);
                });
              });
            }
          }
        });
      }
    }

    void writeInheritedConstructors() {
      var inheritedConstructors =
          item.inheritedConstructors.sorted.whereNot((entry) {
            return ignored.contains(entry.key.asString);
          }).toList();

      if (inheritedConstructors.isNotEmpty) {
        sink.writelnWithIndent('inheritedConstructors');
        sink.withIndent(() {
          for (var entry in inheritedConstructors) {
            var name = entry.key.asString;
            var idStr = idProvider.manifestId(entry.value);
            sink.writelnWithIndent('$name: $idStr');
          }
        });
      }
    }

    writeDeclaredDuplicateNames();
    writeDeclaredFields();
    writeDeclaredGetters();
    writeDeclaredSetters();
    writeDeclaredMethods();
    writeDeclaredConstructors();
    writeInheritedConstructors();
  }

  void _writeInterfaceItemInterface(InterfaceItem item) {
    var ignored = configuration.ignoredManifestInstanceMemberNames;

    List<MapEntry<LookupName, V>> notIgnored<V>(Map<LookupName, V> map) {
      return map.sorted.whereNot((entry) {
        return ignored.contains(entry.key.asString);
      }).toList();
    }

    var interface = item.interface;
    var idStr = idProvider.manifestId(interface.id);
    sink.writelnWithIndent('interface: $idStr');

    var mapEntries = notIgnored(interface.map);
    if (mapEntries.isNotEmpty) {
      sink.withIndent(() {
        if (mapEntries.isNotEmpty) {
          sink.writelnWithIndent('map');
          sink.withIndent(() {
            for (var entry in mapEntries) {
              _writeNamedId(entry.key, entry.value);
            }
          });
        }

        var combinedIds = interface.combinedIds;
        if (combinedIds.isNotEmpty) {
          sink.writelnWithIndent('combinedIds');
          sink.withIndent(() {
            for (var entry in combinedIds.entries) {
              var idListStr = entry.key.ids
                  .map((id) => idProvider.manifestId(id))
                  .join(', ');
              var idStr = idProvider.manifestId(entry.value);
              sink.writelnWithIndent('[$idListStr]: $idStr');
            }
          });
        }
      });
    }
  }

  void _writelnElement(ManifestElement element) {
    var parts = [
      element.libraryUri,
      element.kind.name,
      element.topLevelName,
      if (element.memberName case var memberName?) memberName,
    ];
    var idStr = idProvider.manifestId(element.id);
    sink.writeln('(${parts.join(', ')}) $idStr');
  }

  void _writeMetadata(ManifestItem item) {
    if (configuration.withElementManifests) {
      sink.writeElements(
        'metadata',
        item.metadata.annotations.indexed.toList(),
        (indexed) {
          _writeNode('[${indexed.$1}]', indexed.$2.ast);
        },
      );
    }
  }

  void _writeMixinItem(MixinItem item) {
    if (configuration.withElementManifests) {
      sink.withIndent(() {
        _writeMetadata(item);
        _writeTypeParameters(item.typeParameters);
        _writeTypeList('superclassConstraints', item.superclassConstraints);
        _writeTypeList('interfaces', item.interfaces);
      });
    }

    sink.withIndent(() {
      _writeInstanceItemMembers(item);
      _writeInterfaceItemInterface(item);
    });
  }

  void _writeNamedId(LookupName name, ManifestItemId id) {
    var idStr = idProvider.manifestId(id);
    sink.writelnWithIndent('$name: $idStr');
  }

  void _writeNamedType(String name, ManifestType? type) {
    sink.writeWithIndent('$name: ');
    if (type != null) {
      _writeType(type);
    } else {
      sink.writeln('<null>');
    }
  }

  void _writeNode(String name, ManifestNode? node) {
    if (node != null) {
      sink.writelnWithIndent(name);
      sink.withIndent(() {
        if (node.isValid) {
          sink.writelnWithIndent('tokenBuffer: ${node.tokenBuffer}');
          sink.writelnWithIndent('tokenLengthList: ${node.tokenLengthList}');

          if (node.elements.isNotEmpty) {
            sink.writelnWithIndent('elements');
            sink.withIndent(() {
              for (var (index, element) in node.elements.indexed) {
                sink.writeWithIndent('[$index] ');
                _writelnElement(element);
              }
            });
          }

          if (node.elementIndexList.isNotEmpty) {
            sink.writeElements('elementIndexList', node.elementIndexList, (
              index,
            ) {
              var (kind, rawIndex) = ManifestAstElementKind.decode(index);
              switch (kind) {
                case ManifestAstElementKind.null_:
                  sink.writelnWithIndent('$index = null');
                case ManifestAstElementKind.dynamic_:
                  sink.writelnWithIndent('$index = dynamic');
                case ManifestAstElementKind.formalParameter:
                  sink.writelnWithIndent('$index = formalParameter $rawIndex');
                case ManifestAstElementKind.importPrefix:
                  sink.writelnWithIndent('$index = importPrefix');
                case ManifestAstElementKind.typeParameter:
                  sink.writelnWithIndent('$index = typeParameter $rawIndex');
                case ManifestAstElementKind.regular:
                  sink.writelnWithIndent('$index = element $rawIndex');
              }
            });
          }
        } else {
          sink.writelnWithIndent('isValid: ${node.isValid}');
        }
      });
    }
  }

  void _writeTopLevelFunctionItem(TopLevelFunctionItem item) {
    if (configuration.withElementManifests) {
      sink.withIndent(() {
        _writeMetadata(item);
        _writeNamedType('functionType', item.functionType);
      });
    }
  }

  void _writeTopLevelGetterItem(TopLevelGetterItem item) {
    if (configuration.withElementManifests) {
      sink.withIndent(() {
        _writeMetadata(item);
        _writeNamedType('returnType', item.returnType);
      });
    }
  }

  void _writeTopLevelSetterItem(TopLevelSetterItem item) {
    if (configuration.withElementManifests) {
      sink.withIndent(() {
        _writeMetadata(item);
        _writeNamedType('valueType', item.valueType);
      });
    }
  }

  void _writeTopLevelVariableItem(TopLevelVariableItem item) {
    if (configuration.withElementManifests) {
      sink.withIndent(() {
        _writeMetadata(item);
        _writeNamedType('type', item.type);
        _writeNode('constInitializer', item.constInitializer);
      });
    }
  }

  void _writeType(ManifestType type) {
    void writeNullabilitySuffix() {
      if (type.nullabilitySuffix == NullabilitySuffix.question) {
        sink.write('?');
      }
    }

    switch (type) {
      case ManifestDynamicType():
        sink.writeln('dynamic');
      case ManifestFunctionType():
        sink.writeln('FunctionType');
        sink.withIndent(() {
          _writeTypeParameters(type.typeParameters);
          sink.writeElements('positional', type.positional, (field) {
            sink.writeIndent();
            if (field.isRequired) {
              sink.write('required ');
            }
            _writeType(field.type);
          });
          sink.writeElements('named', type.named, (field) {
            sink.writeWithIndent('${field.name}: ');
            if (field.isRequired) {
              sink.write('required ');
            }
            _writeType(field.type);
          });
          _writeNamedType('returnType', type.returnType);
        });
      case ManifestInterfaceType():
        var element = type.element;
        sink.write(element.topLevelName);
        writeNullabilitySuffix();
        sink.write(' @ ');
        sink.writeln(element.libraryUri);
        sink.withIndent(() {
          for (var argument in type.arguments) {
            sink.writeIndent();
            _writeType(argument);
          }
        });
      case ManifestInvalidType():
        sink.writeln('InvalidType');
      case ManifestNeverType():
        sink.write('Never');
        writeNullabilitySuffix();
        sink.writeln();
      case ManifestRecordType():
        sink.writeln('RecordType');
        sink.withIndent(() {
          sink.writeElements('positional', type.positionalFields, (field) {
            sink.writeIndentedLine(() {
              _writeType(field);
            });
          });
          sink.writeElements('named', type.namedFields, (field) {
            sink.writeIndentedLine(() {
              sink.write('${field.name}: ');
              _writeType(field.type);
            });
          });
        });
      case ManifestTypeParameterType():
        sink.write('typeParameter#${type.index}');
        writeNullabilitySuffix();
        sink.writeln();
      case ManifestVoidType():
        sink.writeln('void');
    }
  }

  void _writeTypeAliasItem(TypeAliasItem item) {
    if (configuration.withElementManifests) {
      sink.withIndent(() {
        _writeMetadata(item);
        _writeTypeParameters(item.typeParameters);
        _writeNamedType('aliasedType', item.aliasedType);
      });
    }
  }

  void _writeTypeList(String name, List<ManifestType> types) {
    sink.writeElements(name, types, (type) {
      sink.writeIndent();
      _writeType(type);
    });
  }

  void _writeTypeParameters(List<ManifestTypeParameter> typeParameters) {
    sink.writeElements('typeParameters', typeParameters, (typeParameter) {
      _writeNamedType('bound', typeParameter.bound);
    });
  }
}

class RequirementPrinterConfiguration {
  var ignoredLibraries = <Uri>{Uri.parse('dart:core')};
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
      elementPrinter.writeNamedElement2('element', result.element);
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

  void _writeDiagnostic(Diagnostic d) {
    sink.writelnWithIndent('${d.offset} +${d.length} ${d.diagnosticCode.name}');
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
        'isPart': result.isPart,
      });

      if (configuration.withContentPredicate(result)) {
        sink.writelnWithIndent('content');
        sink.writeln('---');
        sink.write(result.content);
        sink.writeln('---');
      }

      sink.writeElements('errors', result.diagnostics, _writeDiagnostic);

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
      sink.writeElements('selectedTypes', typesToWrite.entries.toList(), (
        entry,
      ) {
        sink.writeIndent();
        sink.write('${entry.key}: ');
        elementPrinter.writeType(entry.value);
      });

      var variableTypesToWrite = configuration.variableTypesSelector(result);
      sink.writeElements('selectedVariableTypes', variableTypesToWrite, (
        variable,
      ) {
        sink.writeIndent();
        sink.write('${variable.name}: ');
        if (variable is LocalVariableElement) {
          elementPrinter.writeType(variable.type);
        } else if (variable is TopLevelVariableElement) {
          elementPrinter.writeType(variable.type);
        }
      });
    });
  }
}

class ResolvedUnitResultPrinterConfiguration {
  var nodeConfiguration = ResolvedNodeTextConfiguration();
  AstNode? Function(ResolvedUnitResult) nodeSelector = (_) => null;
  Map<String, DartType> Function(ResolvedUnitResult) typesSelector = (_) => {};
  List<Element> Function(ResolvedUnitResult) variableTypesSelector = (_) => [];
  bool Function(FileResult) withContentPredicate = (_) => false;
}

/// The event of received an object into the `results` stream.
final class ResultStreamEvent extends DriverEvent {
  final Object object;

  ResultStreamEvent({required this.object});
}

final class SchedulerStatusEvent extends DriverEvent {
  final AnalysisStatus status;

  SchedulerStatusEvent(this.status);
}

class UnitElementPrinterConfiguration {
  List<Element> Function(LibraryFragment) elementSelector = (_) => [];
}

extension on ManifestItemIdList {
  String asString(IdProvider idProvider) {
    return ids.map((id) => idProvider.manifestId(id)).join(' ');
  }
}

extension on LibraryCycle {
  bool get isSdk {
    return libraries.any((library) => library.file.uri.isScheme('dart'));
  }
}

extension<V> on Map<LookupName, V> {
  List<MapEntry<LookupName, V>> get sorted {
    return entries.sortedByCompare((entry) => entry.key, LookupName.compare);
  }
}

extension<V> on Map<Uri, V> {
  List<MapEntry<Uri, V>> get sorted {
    return entries.sortedBy((entry) => entry.key.toString());
  }
}
