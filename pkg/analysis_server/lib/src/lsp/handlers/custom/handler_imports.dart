// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/lsp_protocol/protocol.dart' hide Element;
import 'package:analysis_server/src/lsp/constants.dart';
import 'package:analysis_server/src/lsp/handlers/custom/abstract_go_to.dart';
import 'package:analysis_server/src/lsp/mapping.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';

typedef _ImportRecord =
    ({ImportDirective directive, LibraryImportElement import});

class ImportsHandler extends AbstractGoToHandler {
  ImportsHandler(super.server);

  @override
  Method get handlesMessage => CustomMethods.imports;

  @override
  bool get requiresTrustedCaller => false;

  /// Returns the import directives that import the given [element].
  /// Although the base class supports returning a single element?, this
  /// handler is documented to return a list of elements.
  /// If no element is found, an empty list is returned.
  /// Changing this to return a single element could be a breaking change for
  /// clients.
  @override
  Either2<Location?, List<Location>> findRelatedLocations(
    Element element,
    ResolvedLibraryResult libraryResult,
    ResolvedUnitResult unit,
    String? prefix,
  ) {
    var elementName = element.name;
    if (elementName == null) {
      return Either2.t1(null);
    }

    var imports = _getImports(libraryResult);

    var directives = <ImportDirective>[];
    for (var (:directive, :import) in imports) {
      Element? namespaceElement;

      if (prefix == null) {
        namespaceElement = import.namespace.get(elementName);
      } else {
        namespaceElement = import.namespace.getPrefixed(prefix, elementName);
      }

      if (element is MultiplyDefinedElement) {
        if (element.conflictingElements.contains(namespaceElement)) {
          directives.add(directive);
        }
      } else if (namespaceElement == element) {
        directives.add(directive);
      }
    }
    return Either2.t2(directives.map(_importToLocation).nonNulls.toList());
  }

  List<_ImportRecord> _getImports(ResolvedLibraryResult libraryResult) {
    // TODO(dantup): Confirm that `units.first` is always the containing
    // library.
    var containingUnit = libraryResult.units.firstOrNull?.unit;
    if (containingUnit == null) {
      return const [];
    }
    var directives = containingUnit.directives.whereType<ImportDirective>();
    var imports = <_ImportRecord>[];
    for (var directive in directives) {
      if (directive.element case var import?) {
        imports.add((directive: directive, import: import));
      }
    }
    return imports;
  }

  Location? _importToLocation(ImportDirective directive) {
    var sourcePath = directive.element?.declaration.source?.fullName;
    if (sourcePath == null) {
      return null;
    }

    // TODO(FMorschel): Remove this when migrating to the new element model.
    var locationLineInfo = server.getLineInfo(sourcePath);
    if (locationLineInfo == null) {
      return null;
    }

    return Location(
      uri: uriConverter.toClientUri(sourcePath),
      range: toRange(locationLineInfo, directive.offset, directive.length),
    );
  }
}
