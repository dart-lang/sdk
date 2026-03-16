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
import 'package:analyzer/src/dart/analysis/file_state.dart';
import 'package:analyzer/src/dart/analysis/library_graph.dart';
import 'package:analyzer/src/dart/analysis/results.dart';
import 'package:analyzer/src/dart/analysis/status.dart';
import 'package:analyzer/src/error/inference_error.dart';
import 'package:analyzer/src/fine/library_manifest.dart';
import 'package:analyzer/src/fine/lookup_name.dart';
import 'package:analyzer/src/fine/manifest_ast.dart';
import 'package:analyzer/src/fine/manifest_context.dart';
import 'package:analyzer/src/fine/manifest_id.dart';
import 'package:analyzer/src/fine/manifest_item.dart';
import 'package:analyzer/src/fine/manifest_type.dart';
import 'package:analyzer/src/fine/requirement_failure.dart';
import 'package:analyzer/src/fine/requirements.dart';
import 'package:analyzer/src/summary/api_signature.dart';
import 'package:analyzer/src/summary/idl.dart';
import 'package:analyzer/src/utilities/extensions/file_system.dart';
import 'package:analyzer_utilities/testing/tree_string_sink.dart';
import 'package:collection/collection.dart';
import 'package:test/test.dart';

import '../../../util/element_printer.dart';
import '../../summary/element_text.dart';
import '../../summary/resolved_ast_printer.dart';

class BundleRequirementsPrinter extends ManifestPrinter {
  BundleRequirementsPrinter({
    required super.configuration,
    required super.sink,
    required super.idProvider,
  });

  void write(RequirementsManifest requirements) {
    sink.writelnWithIndent('requirements');
    sink.withIndent(() {
      var libEntries = requirements.libraries.sorted;

      libEntries.removeWhere((entry) {
        var ignored = configuration.requirements.ignoredLibraries;
        return ignored.contains(entry.key);
      });

      sink.writeElements('libraries', libEntries, (libEntry) {
        var libraryUri = libEntry.key;
        var libraryRequirements = libEntry.value;
        sink.writelnWithIndent('$libraryUri');
        sink.withIndent(() {
          if (libraryRequirements.name case var name?) {
            sink.writelnWithIndent('name: $name');
          }
          if (libraryRequirements.isOriginNotExistingFile case var value?) {
            if (value) {
              sink.writelnWithIndent('isOriginNotExistingFile: $value');
            }
          }
          if (libraryRequirements.isSynthetic case var value?) {
            if (value) {
              sink.writelnWithIndent('isSynthetic: $value');
            }
          }
          if (libraryRequirements.featureSet != null) {
            sink.writelnWithIndent('featureSet: <not-null>');
          }
          if (libraryRequirements.languageVersion != null) {
            sink.writelnWithIndent('languageVersion: <not-null>');
          }
          if (libraryRequirements.libraryMetadataId case var id?) {
            var idStr = idProvider.manifestId(id);
            sink.writelnWithIndent('libraryMetadataId: $idStr');
          }
          _writeExportMap(libraryRequirements);
          _writeLibraryDeclaredItems(libraryRequirements);
          _writeInstanceItems(libraryRequirements);
          _writeInterfaceItems(libraryRequirements);
          _writeExportedExtensions(libraryRequirements);
          _writeExportedLibraryUris(libraryRequirements);
        });
      });

      _writeExportRequirements(requirements);
      _writeOpaqueApiUses(requirements);
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

  void _writeExportedExtensions(LibraryRequirements requirements) {
    _writelnIdListIfNotNull(
      'exportedExtensions',
      requirements.exportedExtensions,
    );
  }

  void _writeExportedLibraryUris(LibraryRequirements requirements) {
    if (requirements.exportedLibraryUris case var uriList?) {
      if (uriList.isNotEmpty) {
        var uriListStr = uriList.join(' ');
        sink.writelnWithIndent('exportedLibraryUris: $uriListStr');
      }
    }
  }

  void _writeExportMap(LibraryRequirements requirements) {
    _writelnIdField('exportMapId', requirements.exportMapId);

    sink.writeElements(
      'exportMap',
      requirements.exportMap.sorted,
      _writelnIdLookupNameEntry,
    );

    sink.writeElements(
      'reExportDeprecatedOnly',
      requirements.reExportDeprecatedOnly.sorted,
      (entry) {
        sink.writelnWithIndent('${entry.key}: ${entry.value}');
      },
    );
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
                _writelnIdLookupNameEntry(entry);
              }
            });
          },
        );
      });
    });
  }

  void _writeInstanceItems(LibraryRequirements requirements) {
    var instanceEntries = requirements.instances.sorted;
    sink.writeElements('instances', instanceEntries, (instanceEntry) {
      var instanceRequirements = instanceEntry.value;
      sink.writelnWithIndent(instanceEntry.key.asString);

      sink.withIndent(() {
        void writeRequestedDeclared(
          String name,
          Map<LookupName, ManifestItemId?> nameToIdMap,
        ) {
          sink.writeElements(
            name,
            nameToIdMap.sorted,
            _writelnIdLookupNameEntry,
          );
        }

        writeRequestedDeclared(
          'requestedDeclaredFields',
          instanceRequirements.requestedDeclaredFields,
        );
        writeRequestedDeclared(
          'requestedDeclaredGetters',
          instanceRequirements.requestedDeclaredGetters,
        );
        writeRequestedDeclared(
          'requestedDeclaredSetters',
          instanceRequirements.requestedDeclaredSetters,
        );
        writeRequestedDeclared(
          'requestedDeclaredMethods',
          instanceRequirements.requestedDeclaredMethods,
        );
      });

      sink.withIndent(() {
        _writelnIdListIfNotNull(
          'allDeclaredFields',
          instanceRequirements.allDeclaredFields,
        );
        _writelnIdListIfNotNull(
          'allDeclaredGetters',
          instanceRequirements.allDeclaredGetters,
        );
        _writelnIdListIfNotNull(
          'allDeclaredSetters',
          instanceRequirements.allDeclaredSetters,
        );
        _writelnIdListIfNotNull(
          'allDeclaredMethods',
          instanceRequirements.allDeclaredMethods,
        );
      });
    });
  }

  void _writeInterfaceItems(LibraryRequirements requirements) {
    var interfaceEntries = requirements.interfaces.sorted;
    sink.writeElements('interfaces', interfaceEntries, (interfaceEntry) {
      sink.writelnWithIndent(interfaceEntry.key.asString);
      sink.withIndent(() {
        var requirements = interfaceEntry.value;
        if (requirements.interfaceId case var id?) {
          var idStr = idProvider.manifestId(id);
          sink.writelnWithIndent('interfaceId: $idStr');
        }
        if (requirements.hasNonFinalField case var value?) {
          sink.writelnWithIndent('hasNonFinalField: $value');
        }
        _writelnIdListIfNotNull(
          'allDeclaredConstructors',
          requirements.allDeclaredConstructors,
        );
        _writelnIdListIfNotNull(
          'allInheritedConstructors',
          requirements.allInheritedConstructors,
        );
        if (requirements.allSubtypesRequested) {
          _writelnIdListOrNull('allSubtypes', requirements.allSubtypes);
        }
        _writelnIdListIfNotNull(
          'directSubtypesOfSealed',
          requirements.directSubtypesOfSealed,
        );
        sink.writeElements(
          'requestedConstructors',
          requirements.requestedConstructors.sorted,
          _writelnIdLookupNameEntry,
        );
        sink.writeElements(
          'methods',
          requirements.methods.sorted,
          _writelnIdLookupNameEntry,
        );
        sink.writeElements(
          'implementedMethods',
          requirements.implementedMethods.sorted,
          _writelnIdLookupNameEntry,
        );
        sink.writeElements(
          'superMethods',
          requirements.superMethods.entries.toList(),
          (superEntry) {
            var index = superEntry.key;
            var nameToId = superEntry.value;
            sink.writelnWithIndent('[$index]');
            sink.withIndent(() {
              for (var entry in nameToId.sorted) {
                _writelnIdLookupNameEntry(entry);
              }
            });
          },
        );
      });
    });
  }

  void _writeLibraryDeclaredItems(LibraryRequirements requirements) {
    ({
      'requestedDeclaredClasses': requirements.requestedDeclaredClasses,
      'requestedDeclaredEnums': requirements.requestedDeclaredEnums,
      'requestedDeclaredExtensions': requirements.requestedDeclaredExtensions,
      'requestedDeclaredExtensionTypes':
          requirements.requestedDeclaredExtensionTypes,
      'requestedDeclaredMixins': requirements.requestedDeclaredMixins,
      'requestedDeclaredTypeAliases': requirements.requestedDeclaredTypeAliases,
      'requestedDeclaredFunctions': requirements.requestedDeclaredFunctions,
      'requestedDeclaredVariables': requirements.requestedDeclaredVariables,
      'requestedDeclaredGetters': requirements.requestedDeclaredGetters,
      'requestedDeclaredSetters': requirements.requestedDeclaredSetters,
    }).forEach((name, value) {
      sink.writeElements(name, value.sorted, _writelnIdLookupNameEntry);
    });

    ({
      'allDeclaredClasses': requirements.allDeclaredClasses,
      'allDeclaredEnums': requirements.allDeclaredEnums,
      'allDeclaredExtensions': requirements.allDeclaredExtensions,
      'allDeclaredExtensionTypes': requirements.allDeclaredExtensionTypes,
      'allDeclaredMixins': requirements.allDeclaredMixins,
      'allDeclaredTypeAliases': requirements.allDeclaredTypeAliases,
      'allDeclaredFunctions': requirements.allDeclaredFunctions,
      'allDeclaredVariables': requirements.allDeclaredVariables,
      'allDeclaredGetters': requirements.allDeclaredGetters,
      'allDeclaredSetters': requirements.allDeclaredSetters,
    }).forEach((name, value) {
      _writelnIdListIfNotNull(name, value);
    });
  }

  void _writeOpaqueApiUses(RequirementsManifest requirements) {
    var usages = requirements.opaqueApiUses.sortedBy((e) {
      return '${e.targetRuntimeType}.${e.methodName}';
    });
    sink.writeElements('opaqueApiUses', usages, (usage) {
      sink.writelnWithIndent('${usage.targetRuntimeType}.${usage.methodName}');
      sink.withIndent(() {
        if (usage.targetElementLibraryUri case var libraryUri?) {
          sink.writelnWithIndent('targetElementLibraryUri: $libraryUri');
        }
        if (usage.targetElementName case var elementName?) {
          sink.writelnWithIndent('targetElementName: $elementName');
        }
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

  void _writeCheckLibraryDiagnosticsRequirements(
    events.CheckLibraryDiagnosticsRequirements event,
  ) {
    if (configuration.withCheckLibraryDiagnosticsRequirements ||
        event.failure != null) {
      sink.writelnWithIndent('[operation] checkLibraryDiagnosticsRequirements');
      sink.withIndent(() {
        sink.writelnNamedFilePath('library', event.library.file);
        if (event.failure case var failure?) {
          _writeRequirementFailure(failure);
        } else {
          sink.writelnWithIndent('failure: null');
        }
      });
    }
  }

  void _writeCheckLinkedBundleRequirements(
    events.CheckLinkedBundleRequirements event,
  ) {
    if (configuration.withCheckLinkedBundleRequirements ||
        event.failure != null) {
      sink.writelnWithIndent('[operation] checkLinkedBundleRequirements');
      sink.withIndent(() {
        _writeLibraryCycle(event.cycle);
        if (event.failure case var failure?) {
          _writeRequirementFailure(failure);
        } else {
          sink.writelnWithIndent('failure: null');
        }
      });
    }
  }

  void _writeDiagnostic(Diagnostic d) {
    sink.writelnWithIndent(
      '${d.offset} +${d.length} ${d.diagnosticCode.lowerCaseName.toUpperCase()}',
    );
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
      case MissingSdkLibraryResultImpl():
        _writeMissingSdkLibraryResult(result);
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
    if (!configuration.withGetLibraryByUri) {
      return;
    }

    _writeGetEvent(event);
    if (configuration.withGetLibraryByUriElement) {
      sink.withIndent(() {
        _writeLibraryElementResult(event.result);
      });
    }
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
        case MissingSdkLibraryResultImpl():
          _writeMissingSdkLibraryResult(result);
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

  void _writeLibraryCycle(LibraryCycle cycle) {
    var uriStrList = cycle.libraries
        .map((library) => library.file.uriStr)
        .sorted();
    for (var uriStr in uriStrList) {
      sink.writelnWithIndent(uriStr);
    }
  }

  void _writeLibraryElementResult(SomeLibraryElementResult result) {
    switch (result) {
      case CannotResolveUriResult():
        sink.writelnWithIndent('CannotResolveUriResult');
      case MissingSdkLibraryResultImpl():
        _writeMissingSdkLibraryResult(result);
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
    if (!configuration.withLinkLibraryCycle) {
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
            ).write(manifest.instance);
          });
        }
      }
      _writeRequirements(object.requirements);
    });
  }

  void _writeMissingSdkLibraryResult(MissingSdkLibraryResultImpl result) {
    var id = idProvider[result];
    sink.writelnWithIndent('MissingSdkLibraryResult $id');

    sink.withIndent(() {
      sink.writelnWithIndent('missingUri: ${result.missingUri}');
    });
  }

  void _writeRequirementFailure(RequirementFailure failure) {
    switch (failure) {
      case LibraryMissing():
        sink.writelnWithIndent('libraryMissing');
        sink.writeProperties({'uri': failure.uri});
      case LibraryNameMismatch():
        sink.writelnWithIndent('libraryNameMismatch');
        sink.writeProperties({
          'libraryUri': failure.libraryUri,
          'expected': failure.expected ?? '<null>',
          'actual': failure.actual ?? '<null>',
        });
      case LibraryIsOriginNotExistingFileMismatch():
        sink.writelnWithIndent('libraryIsOriginNotExistingFileMismatch');
        sink.writeProperties({
          'libraryUri': failure.libraryUri,
          'expected': failure.expected,
          'actual': failure.actual,
        });
      case LibraryFeatureSetMismatch():
        sink.writelnWithIndent('libraryFeatureSetMismatch');
        sink.writeProperties({'libraryUri': failure.libraryUri});
      case LibraryIsSyntheticMismatch():
        sink.writelnWithIndent('libraryIsSyntheticMismatch');
        sink.writeProperties({
          'libraryUri': failure.libraryUri,
          'expected': failure.expected,
          'actual': failure.actual,
        });
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
      case ExportedExtensionsMismatch():
        sink.writelnWithIndent('exportedExtensionsMismatch');
        sink.writeProperties({
          'libraryUri': failure.libraryUri,
          'expectedIds': failure.expectedIds.asString(idProvider),
          'actualIds': failure.actualIds.asString(idProvider),
        });
      case LibraryExportedUrisMismatch():
        sink.writelnWithIndent('libraryExportedUrisMismatch');
        sink.writeProperties({
          'libraryUri': failure.libraryUri,
          'expected': failure.expected.join(' '),
          'actual': failure.actual.join(' '),
        });
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
      case ImplementedMethodIdMismatch():
        sink.writelnWithIndent('implementedMethodIdMismatch');
        sink.writeProperties({
          'libraryUri': failure.libraryUri,
          'interfaceName': failure.interfaceName.asString,
          'methodName': failure.methodName.asString,
          'expectedId': idProvider.manifestId(failure.expectedId),
          'actualId': idProvider.manifestId(failure.actualId),
        });
      case SuperImplementedMethodIdMismatch():
        sink.writelnWithIndent('superImplementedMethodIdMismatch');
        sink.writeProperties({
          'libraryUri': failure.libraryUri,
          'interfaceName': failure.interfaceName.asString,
          'superIndex': failure.superIndex,
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
      case LibraryChildrenIdsMismatch():
        sink.writelnWithIndent('libraryChildrenIdsMismatch');
        sink.writeProperties({
          'libraryUri': failure.libraryUri,
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
      case InterfaceChildrenIdsMismatch():
        sink.writelnWithIndent('interfaceChildrenIdsMismatch');
        sink.writeProperties({
          'libraryUri': failure.libraryUri,
          'interfaceName': failure.interfaceName.asString,
          'childrenPropertyName': failure.childrenPropertyName,
          'expectedIds': failure.expectedIds.asString(idProvider),
          'actualIds': failure.actualIds.asString(idProvider),
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
      case InterfaceHasNonFinalFieldMismatch():
        sink.writelnWithIndent('interfaceHasNonFinalFieldMismatch');
        sink.writeProperties({
          'libraryUri': failure.libraryUri,
          'interfaceName': failure.interfaceName.asString,
          'expected': failure.expected,
          'actual': failure.actual,
        });
      case TopLevelIdMismatch():
        sink.writelnWithIndent('topLevelIdMismatch');
        sink.writeProperties({
          'libraryUri': failure.libraryUri,
          'name': failure.name.asString,
          'expectedId': idProvider.manifestId(failure.expectedId),
          'actualId': idProvider.manifestId(failure.actualId),
        });
      case TopLevelNotInstance():
        sink.writelnWithIndent('topLevelNotInstance');
        sink.writeProperties({
          'libraryUri': failure.libraryUri,
          'name': failure.name.asString,
        });
      case TopLevelNotInterface():
        // TODO(scheglov): Handle this case.
        throw UnimplementedError();
      case OpaqueApiUseFailure():
        var sortedUses = failure.uses.sortedBy((e) {
          return '${e.targetRuntimeType}.${e.methodName}';
        });
        sink.writeElements('opaqueApiUseFailure', sortedUses, (use) {
          sink.writelnWithIndent('${use.targetRuntimeType}.${use.methodName}');
          sink.withIndent(() {
            if (use.targetElementLibraryUri case var libraryUri?) {
              sink.writelnWithIndent('targetElementLibraryUri: $libraryUri');
            }
            if (use.targetElementName case var elementName?) {
              sink.writelnWithIndent('targetElementName: $elementName');
            }
          });
        });
      case LibraryLanguageVersionMismatch():
        sink.writelnWithIndent('libraryLanguageVersionMismatch');
        sink.writeProperties({'libraryUri': failure.libraryUri});
      case LibraryMetadataMismatch():
        sink.writelnWithIndent('libraryMetadataMismatch');
        sink.writeProperties({'libraryUri': failure.libraryUri});
      case ReExportDeprecatedOnlyMismatch():
        sink.writelnWithIndent('reExportDeprecatedOnlyMismatch');
        sink.writeProperties({
          'libraryUri': failure.libraryUri,
          'name': failure.name.asString,
          'expected': failure.expected,
          'actual': failure.actual,
        });
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
      case MissingSdkLibraryResultImpl():
        _writeMissingSdkLibraryResult(result);
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
    switch (result) {
      case MissingSdkLibraryResultImpl():
        _writeMissingSdkLibraryResult(result);
      case ResolvedUnitResultImpl():
        ResolvedUnitResultPrinter(
          configuration: configuration.libraryConfiguration.unitConfiguration,
          sink: sink,
          elementPrinter: elementPrinter,
          idProvider: idProvider,
          libraryElement: null,
        ).write(result);
      default:
        throw UnimplementedError('${result.runtimeType}');
    }
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
      case events.CheckLibraryDiagnosticsRequirements():
        _writeCheckLibraryDiagnosticsRequirements(object);
      case events.CheckLinkedBundleRequirements():
        _writeCheckLinkedBundleRequirements(object);
      case events.LinkLibraryCycle():
        _writeLinkLibraryCycle(object);
      case events.ReuseLinkedBundle():
        _writeReuseLinkedBundle(object);
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

  void _writeReuseLinkedBundle(events.ReuseLinkedBundle event) {
    const printName = 'reuseLinkedBundle';
    if (event.cycle.isSdk) {
      sink.writelnWithIndent('[operation] $printName SDK');
    } else {
      sink.writelnWithIndent('[operation] $printName');
      sink.withIndent(() {
        _writeLibraryCycle(event.cycle);
      });
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
  var requirements = RequirementPrinterConfiguration();

  var withAnalyzeFileEvents = true;
  var withCheckLibraryDiagnosticsRequirements = false;
  var withCheckLinkedBundleRequirements = false;
  var withElementManifests = false;
  var withGetErrorsEvents = true;
  var withGetLibraryByUri = true;
  var withGetLibraryByUriElement = true;
  var withLibraryManifest = false;
  var withLinkLibraryCycle = false;
  var withResultRequirements = false;
  var withSchedulerStatus = true;
  var withStreamResolvedUnitResults = true;

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
  final Map<Hash, String> _hashIdMap = {};

  String operator [](Object object) {
    return _map[object] ??= '#${_map.length}';
  }

  String? existing(Object object) {
    return _map[object];
  }

  String hashId(Hash hash) {
    return _hashIdMap[hash] ??= '#H${_hashIdMap.length}';
  }

  String manifestId(ManifestItemId? id) {
    if (id == null) return '<null>';
    return _manifestIdMap[id] ??= '#M${_manifestIdMap.length}';
  }
}

class LibraryManifestPrinter extends ManifestPrinter {
  LibraryManifestPrinter({
    required super.configuration,
    required super.sink,
    required super.idProvider,
  });

  void write(LibraryManifest manifest) {
    _writelnHashField('hashForRequirements', manifest.hashForRequirements);

    if (manifest.name case var name?) {
      sink.writelnWithIndent('name: $name');
    }
    sink.writeFlags({
      'isOriginNotExistingFile': manifest.isOriginNotExistingFile,
      'isSynthetic': manifest.isSynthetic,
    });

    var libraryMetadata = manifest.libraryMetadata;
    if (!libraryMetadata.isEmpty) {
      var idStr = idProvider.manifestId(libraryMetadata.id);
      sink.writelnWithIndent('libraryMetadata: $idStr');
    }

    var declaredConflicts = manifest.declaredConflicts.sorted;
    sink.writeElements('declaredConflicts', declaredConflicts, (entry) {
      _writelnIdLookupName(entry.key, entry.value);
    });

    var classEntries = manifest.declaredClasses.sorted;
    sink.writeElements('declaredClasses', classEntries, (entry) {
      var item = entry.value;
      _writelnIdLookupName(entry.key, item.id);
      _writeClassItem(item);
    });

    var enumEntries = manifest.declaredEnums.sorted;
    sink.writeElements('declaredEnums', enumEntries, (entry) {
      var item = entry.value;
      _writelnIdLookupName(entry.key, item.id);
      _writeEnumItem(item);
    });

    var extensionEntries = manifest.declaredExtensions.sorted;
    sink.writeElements('declaredExtensions', extensionEntries, (entry) {
      var item = entry.value;
      _writelnIdLookupName(entry.key, item.id);
      _writeExtensionItem(item);
    });

    var extensionTypeEntries = manifest.declaredExtensionTypes.sorted;
    sink.writeElements('declaredExtensionTypes', extensionTypeEntries, (entry) {
      var item = entry.value;
      _writelnIdLookupName(entry.key, item.id);
      _writeExtensionTypeItem(item);
    });

    var mixinEntries = manifest.declaredMixins.sorted;
    sink.writeElements('declaredMixins', mixinEntries, (entry) {
      var item = entry.value;
      _writelnIdLookupName(entry.key, item.id);
      _writeMixinItem(item);
    });

    var typeAliasEntries = manifest.declaredTypeAliases.sorted;
    sink.writeElements('declaredTypeAliases', typeAliasEntries, (entry) {
      var item = entry.value;
      _writelnIdLookupName(entry.key, item.id);
      _writeTypeAliasItem(item);
    });

    var getterEntries = manifest.declaredGetters.sorted;
    sink.writeElements('declaredGetters', getterEntries, (entry) {
      var item = entry.value;
      _writelnIdLookupName(entry.key, item.id);
      _writeGetterItem(item);
    });

    var setterEntries = manifest.declaredSetters.sorted;
    sink.writeElements('declaredSetters', setterEntries, (entry) {
      var item = entry.value;
      _writelnIdLookupName(entry.key, item.id);
      _writeSetterItem(item);
    });

    var functionEntries = manifest.declaredFunctions;
    sink.writeElements('declaredFunctions', functionEntries.sorted, (entry) {
      var item = entry.value;
      _writelnIdLookupName(entry.key, item.id);
      _writeTopLevelFunctionItem(item);
    });

    var variableEntries = manifest.declaredVariables;
    sink.writeElements('declaredVariables', variableEntries.sorted, (entry) {
      var item = entry.value;
      _writelnIdLookupName(entry.key, item.id);
      _writeTopLevelVariableItem(item);
    });

    _writelnIdField('exportMapId', manifest.exportMapId);
    sink.writeElements(
      'exportMap',
      manifest.exportMap.sorted,
      _writelnIdLookupNameEntry,
    );

    var reExportEntries = manifest.reExportMap.sorted;
    if (reExportEntries.isNotEmpty) {
      sink.writelnWithIndent('reExportMap');
      sink.withIndent(() {
        for (var entry in reExportEntries) {
          _writelnIdLookupName(entry.key, entry.value);
        }
      });
    }

    if (manifest.reExportDeprecatedOnly.isNotEmpty) {
      var namesStr = manifest.reExportDeprecatedOnly
          .sorted(LookupName.compare)
          .map((e) => e.asString)
          .join(' ');
      sink.writelnWithIndent('reExportDeprecatedOnly: $namesStr');
    }

    var exportedExtensionIds = manifest.exportedExtensions;
    if (exportedExtensionIds.ids.isNotEmpty) {
      var idListStr = exportedExtensionIds.asString(idProvider);
      sink.writelnWithIndent('exportedExtensions: $idListStr');
    }

    if (manifest.exportedLibraryUris.isNotEmpty) {
      var uriListStr = manifest.exportedLibraryUris.join(' ');
      sink.writelnWithIndent('exportedLibraryUris: $uriListStr');
    }
  }

  Map<String, bool> _executableItemFlags(ExecutableItem item) {
    return {
      'hasEnclosingTypeParameterReference':
          item.flags.hasEnclosingTypeParameterReference,
      'hasImplicitReturnType': item.flags.hasImplicitReturnType,
      'invokesSuperSelf': item.flags.invokesSuperSelf,
      'isAbstract': item.flags.isAbstract,
      'isExtensionTypeMember': item.flags.isExtensionTypeMember,
      'isExternal': item.flags.isExternal,
      'isSimplyBounded': item.flags.isSimplyBounded,
      'isStatic': item.flags.isStatic,
    };
  }

  Map<String, bool> _variableItemFlags(VariableItem item) {
    return {
      'hasInitializer': item.flags.hasInitializer,
      'hasImplicitType': item.flags.hasImplicitType,
      'isConst': item.flags.isConst,
      'isFinal': item.flags.isFinal,
      'isLate': item.flags.isLate,
      'isStatic': item.flags.isStatic,
      'shouldUseTypeForInitializerInference':
          item.flags.shouldUseTypeForInitializerInference,
    };
  }

  void _writeClassItem(ClassItem item) {
    if (configuration.withElementManifests) {
      sink.withIndent(() {
        sink.writeFlags({
          'hasNonFinalField': item.hasNonFinalField,
          'isAbstract': item.flags.isAbstract,
          'isBase': item.flags.isBase,
          'isFinal': item.flags.isFinal,
          'isInterface': item.flags.isInterface,
          'isMixinApplication': item.flags.isMixinApplication,
          'isMixinClass': item.flags.isMixinClass,
          'isSealed': item.flags.isSealed,
          'isSimplyBounded': item.flags.isSimplyBounded,
        });
        _writeMetadata(item);
        _writeTypeParameters(item.typeParameters);
        _writeNamedType('supertype', item.supertype);
        _writeTypeList('mixins', item.mixins);
        _writeTypeList('interfaces', item.interfaces);
        _writelnIdListIfNotNull('allSubtypes', item.allSubtypes);
        _writelnIdListIfNotNull(
          'directSubtypesOfSealed',
          item.directSubtypesOfSealed,
        );
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
        sink.writeFlags({
          'hasNonFinalField': item.hasNonFinalField,
          'isSimplyBounded': item.flags.isSimplyBounded,
        });
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
        sink.writeFlags({'isSimplyBounded': item.flags.isSimplyBounded});
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
        sink.writeFlags({
          'hasImplementsSelfReference': item.flags.hasImplementsSelfReference,
          'hasNonFinalField': item.hasNonFinalField,
          'hasRepresentationSelfReference':
              item.flags.hasRepresentationSelfReference,
          'isSimplyBounded': item.flags.isSimplyBounded,
        });
        _writeMetadata(item);
        _writeTypeParameters(item.typeParameters);
        _writeNamedType('representationType', item.representationType);
        _writeNamedType('typeErasure', item.typeErasure);
        _writeTypeList('interfaces', item.interfaces);
      });
    }

    sink.withIndent(() {
      _writeInstanceItemMembers(item);
      _writeInterfaceItemInterface(item);
    });
  }

  void _writeGetterItem(GetterItem item) {
    if (configuration.withElementManifests) {
      sink.withIndent(() {
        sink.writeFlags({
          ..._executableItemFlags(item),
          'isOriginDeclaration': item.flags.isOriginDeclaration,
          'isOriginInterface': item.flags.isOriginInterface,
          'isOriginVariable': item.flags.isOriginVariable,
        });
        _writeMetadata(item);
        _writeNamedType('returnType', item.functionType.returnType);
      });
    }
  }

  void _writeInstanceItemMembers(InstanceItem item) {
    var ignored = configuration.ignoredManifestInstanceMemberNames;

    void writeDeclaredItems<T extends ManifestItem>(
      String name,
      Map<LookupName, T> declared,
      void Function(T) writeItem,
    ) {
      var declaredEntries = declared.sorted.whereNot((entry) {
        return ignored.contains(entry.key.asString);
      }).toList();

      sink.writeElements(name, declaredEntries, (entry) {
        var item = entry.value;
        _writelnIdLookupName(entry.key, item.id);
        if (configuration.withElementManifests) {
          sink.withIndent(() => writeItem(item));
        }
      });
    }

    var conflicts = item.declaredConflicts.sorted;
    sink.writeElements('declaredConflicts', conflicts, (entry) {
      _writelnIdField(entry.key.asString, entry.value);
    });

    writeDeclaredItems('declaredFields', item.declaredFields, (item) {
      sink.writeFlags({
        ..._variableItemFlags(item),
        'hasEnclosingTypeParameterReference':
            item.flags.hasEnclosingTypeParameterReference,
        'isAbstract': item.flags.isAbstract,
        'isCovariant': item.flags.isCovariant,
        'isEnumConstant': item.flags.isEnumConstant,
        'isExternal': item.flags.isExternal,
        'isOriginDeclaration': item.flags.isOriginDeclaration,
        'isOriginDeclaringFormalParameter':
            item.flags.isOriginDeclaringFormalParameter,
        'isOriginEnumValues': item.flags.isOriginEnumValues,
        'isOriginExtensionTypeRecoveryRepresentation':
            item.flags.isOriginExtensionTypeRecoveryRepresentation,
        'isOriginGetterSetter': item.flags.isOriginGetterSetter,
        'isPromotable': item.flags.isPromotable,
      });
      _writeMetadata(item);
      _writeNamedType('type', item.type);
      _writeNode('constInitializer', item.constInitializer);
      _writeTopLevelInferenceError('inferenceError', item.typeInferenceError);
    });

    writeDeclaredItems('declaredGetters', item.declaredGetters, (item) {
      sink.writeFlags({
        ..._executableItemFlags(item),
        'isOriginDeclaration': item.flags.isOriginDeclaration,
        'isOriginInterface': item.flags.isOriginInterface,
        'isOriginVariable': item.flags.isOriginVariable,
      });
      _writeMetadata(item);
      _writeNamedType('returnType', item.functionType.returnType);
    });

    writeDeclaredItems('declaredSetters', item.declaredSetters, (item) {
      sink.writeFlags({
        ..._executableItemFlags(item),
        'isOriginDeclaration': item.flags.isOriginDeclaration,
        'isOriginInterface': item.flags.isOriginInterface,
        'isOriginVariable': item.flags.isOriginVariable,
      });
      _writeMetadata(item);
      _writeNamedType('functionType', item.functionType);
    });

    writeDeclaredItems('declaredMethods', item.declaredMethods, (item) {
      sink.writeFlags({
        ..._executableItemFlags(item),
        'isOperatorEqualWithParameterTypeFromObject':
            item.flags.isOperatorEqualWithParameterTypeFromObject,
        'isOriginDeclaration': item.flags.isOriginDeclaration,
        'isOriginInterface': item.flags.isOriginInterface,
      });
      _writeMetadata(item);
      _writeNamedType('functionType', item.functionType);
      _writeTopLevelInferenceError('inferenceError', item.typeInferenceError);
    });

    writeDeclaredItems('declaredConstructors', item.declaredConstructors, (
      item,
    ) {
      sink.withIndent(() {
        sink.writeFlags({
          ..._executableItemFlags(item),
          'isConst': item.flags.isConst,
          'isFactory': item.flags.isFactory,
          'isOriginDeclaration': item.flags.isOriginDeclaration,
          'isOriginImplicitDefault': item.flags.isOriginImplicitDefault,
          'isOriginMixinApplication': item.flags.isOriginMixinApplication,
          'isPrimary': item.flags.isPrimary,
        });
        _writeMetadata(item);
        _writeNamedType('functionType', item.functionType);
        _writelnNamedElement(
          'redirectedConstructor',
          item.redirectedConstructor,
        );
        _writelnNamedElement('superConstructor', item.superConstructor);
      });
    });

    var inheritedConstructors = item.inheritedConstructors.sorted.whereNot((
      entry,
    ) {
      return ignored.contains(entry.key.asString);
    }).toList();
    sink.writeElements('inheritedConstructors', inheritedConstructors, (entry) {
      super._writelnIdLookupName(entry.key, entry.value);
    });
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
              _writelnIdLookupName(entry.key, entry.value);
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

    var implementedEntries = notIgnored(interface.implemented);
    if (implementedEntries.isNotEmpty) {
      sink.withIndent(() {
        sink.writelnWithIndent('implemented');
        sink.withIndent(() {
          for (var entry in implementedEntries) {
            _writelnIdLookupName(entry.key, entry.value);
          }
        });
      });
    }

    var superImplementedLayers = interface.superImplemented
        .map((layer) => notIgnored(layer))
        .toList();
    if (superImplementedLayers.any((layer) => layer.isNotEmpty)) {
      sink.withIndent(() {
        sink.writelnWithIndent('superImplemented');
        sink.withIndent(() {
          for (var i = 0; i < superImplementedLayers.length; i++) {
            var layerEntries = superImplementedLayers[i];
            if (layerEntries.isNotEmpty) {
              sink.writelnWithIndent('[$i]');
              sink.withIndent(() {
                for (var entry in layerEntries) {
                  _writelnIdLookupName(entry.key, entry.value);
                }
              });
            }
          }
        });
      });
    }

    var inheritedEntries = notIgnored(interface.inherited);
    if (inheritedEntries.isNotEmpty) {
      sink.withIndent(() {
        sink.writelnWithIndent('inherited');
        sink.withIndent(() {
          for (var entry in inheritedEntries) {
            _writelnIdLookupName(entry.key, entry.value);
          }
        });
      });
    }
  }

  void _writelnElement(ManifestElement element) {
    var parts = [
      element.libraryUri,
      element.kind.name,
      element.topLevelName,
      ?element.memberName,
    ];
    var idStr = idProvider.manifestId(element.id);
    sink.writeln('(${parts.join(', ')}) $idStr');
  }

  void _writelnNamedElement(String name, ManifestElement? element) {
    if (element != null) {
      sink.writeWithIndent('$name: ');
      _writelnElement(element);
    }
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
        sink.writeFlags({
          'hasNonFinalField': item.hasNonFinalField,
          'isBase': item.flags.isBase,
          'isSimplyBounded': item.flags.isSimplyBounded,
        });
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
                case ManifestAstElementKind.never_:
                  sink.writelnWithIndent('$index = Never');
                case ManifestAstElementKind.multiplyDefined:
                  sink.writelnWithIndent('$index = multiplyDefined');
                case ManifestAstElementKind.formalParameter:
                  sink.writelnWithIndent('$index = formalParameter $rawIndex');
                case ManifestAstElementKind.importPrefix:
                  sink.writelnWithIndent('$index = importPrefix');
                case ManifestAstElementKind.methodOfUnnamedExtension:
                  sink.writelnWithIndent('$index = methodOfUnnamedExtension');
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

  void _writeSetterItem(SetterItem item) {
    if (configuration.withElementManifests) {
      sink.withIndent(() {
        sink.writeFlags({
          ..._executableItemFlags(item),
          'isOriginDeclaration': item.flags.isOriginDeclaration,
          'isOriginInterface': item.flags.isOriginInterface,
          'isOriginVariable': item.flags.isOriginVariable,
        });
        _writeMetadata(item);
        _writeNamedType('functionType', item.functionType);
      });
    }
  }

  void _writeTopLevelFunctionItem(TopLevelFunctionItem item) {
    if (configuration.withElementManifests) {
      sink.withIndent(() {
        sink.writeFlags({
          ..._executableItemFlags(item),
          'isOriginDeclaration': item.flags.isOriginDeclaration,
          'isOriginLoadLibrary': item.flags.isOriginLoadLibrary,
        });
        _writeMetadata(item);
        _writeNamedType('functionType', item.functionType);
      });
    }
  }

  void _writeTopLevelInferenceError(
    String name,
    TopLevelInferenceError? error,
  ) {
    switch (error) {
      case null:
        break;
      case TopLevelInferenceErrorDependencyCycle(:var cycle):
        sink.writelnWithIndent('$name: dependencyCycle(${cycle.join(', ')})');
        throw UnimplementedError();
      case TopLevelInferenceErrorNoCombinedSuperSignature(
        :var candidateSignatures,
      ):
        sink.writelnWithIndent(
          '$name: overrideNoCombinedSuperSignature($candidateSignatures)',
        );
    }
  }

  void _writeTopLevelVariableItem(TopLevelVariableItem item) {
    if (configuration.withElementManifests) {
      sink.withIndent(() {
        sink.writeFlags({
          ..._variableItemFlags(item),
          'isExternal': item.flags.isExternal,
          'isOriginDeclaration': item.flags.isOriginDeclaration,
          'isOriginGetterSetter': item.flags.isOriginGetterSetter,
        });
        _writeMetadata(item);
        _writeNamedType('type', item.type);
        _writeNode('constInitializer', item.constInitializer);
        _writeTopLevelInferenceError('inferenceError', item.typeInferenceError);
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
            sink.writeIf(field.isRequired, 'required ');
            sink.writeIf(field.isInitializingFormal, 'this ');
            sink.writeIf(field.isSuperFormal, 'super ');
            _writeType(field.type);
            sink.withIndent(() {
              _writeNode('defaultValue', field.defaultValue);
            });
          });
          sink.writeElements('named', type.named, (field) {
            sink.writeWithIndent('${field.name}: ');
            sink.writeIf(field.isRequired, 'required ');
            sink.writeIf(field.isInitializingFormal, 'this ');
            sink.writeIf(field.isSuperFormal, 'super ');
            _writeType(field.type);
            sink.withIndent(() {
              _writeNode('defaultValue', field.defaultValue);
            });
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
        sink.writeFlags({
          'isProperRename': item.flags.isProperRename,
          'isSimplyBounded': item.flags.isSimplyBounded,
        });
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
    var indexed = typeParameters.indexed.toList();
    sink.writeElements('typeParameters', indexed, (pair) {
      var typeParameter = pair.$2;
      sink.writeIndentedLine(() {
        sink.write('#${pair.$1} ');
        sink.write(typeParameter.variance.name);
      });
      sink.withIndent(() {
        _writeNamedType('bound', typeParameter.bound);
      });
    });
  }
}

class ManifestPrinter {
  final DriverEventsPrinterConfiguration configuration;
  final TreeStringSink sink;
  final IdProvider idProvider;

  ManifestPrinter({
    required this.configuration,
    required this.sink,
    required this.idProvider,
  });

  void _writelnHashField(String name, Hash hash) {
    var hashId = idProvider.hashId(hash);
    sink.writelnWithIndent('$name: $hashId');
  }

  void _writelnIdField(String name, ManifestItemId? id) {
    var idStr = id != null ? idProvider.manifestId(id) : '<null>';
    sink.writelnWithIndent('$name: $idStr');
  }

  void _writelnIdListIfNotNull(String name, ManifestItemIdList? idList) {
    if (idList != null) {
      var idListStr = idList.asString(idProvider);
      sink.writelnWithIndent('$name: $idListStr');
    }
  }

  void _writelnIdListOrNull(String name, ManifestItemIdList? idList) {
    if (idList != null) {
      var idListStr = idList.asString(idProvider);
      sink.writelnWithIndent('$name: $idListStr');
    } else {
      sink.writelnWithIndent('$name: <null>');
    }
  }

  void _writelnIdLookupName(LookupName name, ManifestItemId? id) {
    // TODO(fshcheglov): Use this in _writeInstanceItemMembers.
    _writelnIdField(name.asString, id);
  }

  void _writelnIdLookupNameEntry(MapEntry<LookupName, ManifestItemId?> entry) {
    _writelnIdLookupName(entry.key, entry.value);
  }
}

class RequirementPrinterConfiguration {
  var ignoredLibraries = <Uri>{
    Uri.parse('dart:_internal'),
    Uri.parse('dart:async'),
    Uri.parse('dart:core'),
    Uri.parse('dart:math'),
  };
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
      case ResolvedLibraryResultImpl():
        _writeResolvedLibraryResult(result);
      default:
        throw UnimplementedError('${result.runtimeType}');
    }
  }

  void _writeResolvedLibraryResult(ResolvedLibraryResultImpl result) {
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

  void _writeResolvedUnitResult(ResolvedUnitResultImpl result) {
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

  void write(ResolvedUnitResultImpl result) {
    _writeResolvedUnitResult(result);
  }

  void _writeDiagnostic(Diagnostic d) {
    sink.writelnWithIndent(
      '${d.offset} +${d.length} ${d.diagnosticCode.lowerCaseName.toUpperCase()}',
    );
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
    if (ids.isNotEmpty) {
      return ids.map((id) => idProvider.manifestId(id)).join(' ');
    } else {
      return '[]';
    }
  }
}

extension on ManifestItemIdList? {
  String asString(IdProvider idProvider) {
    return this?.asString(idProvider) ?? '<null>';
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

extension on TreeStringSink {
  void writelnNamedFilePath(String name, FileState fileState) {
    writelnWithIndent('$name: ${fileState.resource.posixPath}');
  }
}
