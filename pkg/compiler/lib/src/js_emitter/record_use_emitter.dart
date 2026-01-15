// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Emitter for recorded uses of definitions annotated with `@RecordUse()`.
///
/// See [documentation](../../../doc/record_uses.md) for examples.
///
/// To appear in the output, arguments must be primitive constants i.e. int,
/// double, String, bool, null. Other constants (e.g. enums, const objects) will
/// simply be missing as though they were not constants.
library;

import 'dart:io';

import 'package:compiler/src/elements/entities.dart';
import 'package:compiler/src/io/source_information.dart';
// ignore: implementation_imports
import 'package:front_end/src/api_unstable/dart2js.dart' show relativizeUri;
import 'package:compiler/src/deferred_load/output_unit.dart';
import 'package:compiler/src/js_model/js_world.dart';
import 'package:record_use/record_use_internal.dart';

import '../js/js.dart' as js;
import '../universe/recorded_use.dart'
    show RecordedCallWithArguments, RecordedTearOff, RecordedUse;

class _AnnotationMonitor implements js.JavaScriptAnnotationMonitor {
  final RecordUseCollector _collector;
  final String _filename;
  _AnnotationMonitor(this._collector, this._filename);

  @override
  void onAnnotations(List<Object> annotations) {
    for (Object annotation in annotations) {
      if (annotation is RecordedUse) {
        _collector._register(_filename, annotation);
      }
    }
  }
}

class RecordUseCollector {
  RecordUseCollector(this._closedWorld);

  final JClosedWorld _closedWorld;

  final Map<FunctionEntity, List<CallReference>> callMap = {};

  js.JavaScriptAnnotationMonitor monitorFor(String fileName) {
    return _AnnotationMonitor(this, fileName);
  }

  Location _recordUseLocation(SourceInformation sourceInformation) {
    SourceLocation? sourceLocation =
        sourceInformation.startPosition ??
        sourceInformation.innerPosition ??
        sourceInformation.endPosition;
    if (sourceLocation == null) {
      throw UnsupportedError('Source location is null.');
    }
    final sourceUri = sourceLocation.sourceUri;
    if (sourceUri == null) {
      throw UnsupportedError('Source uri is null.');
    }

    // Is [sourceUri] normalized in some way or does that need to be done
    // here?
    return Location(
      uri: relativizeUri(Uri.base, sourceUri, Platform.isWindows),
    );
  }

  void _register(String loadingUnit, RecordedUse recordedUse) {
    final location = _recordUseLocation(recordedUse.sourceInformation);
    final callReference = switch (recordedUse) {
      RecordedCallWithArguments() => CallWithArguments(
        loadingUnit: loadingUnit,
        namedArguments: {},
        positionalArguments: recordedUse.arguments,
        location: location,
      ),
      RecordedTearOff() => CallTearOff(
        loadingUnit: loadingUnit,
        location: location,
      ),
    };
    callMap.putIfAbsent(recordedUse.function, () => []).add(callReference);
  }

  Map<String, dynamic> finish(
    Map<String, String> environment,
    Map<OutputUnit, String> outputUnitToName,
  ) => Recordings(
    metadata: Metadata.fromJson({
      'comment': 'Resources referenced by annotated resource identifiers',
      'AppTag': 'TBD',
      'environment': environment,
      "version": version.toString(),
    }),
    callsForDefinition: callMap.map(
      (key, value) => MapEntry(
        Definition(
          identifier: Identifier(
            name: key.name!,
            scope: key.enclosingClass?.name,
            importUri: relativizeUri(
              Uri.base,
              key.library.canonicalUri,
              Platform.isWindows,
            ),
          ),
          loadingUnit:
              outputUnitToName[_closedWorld.outputUnitData.outputUnitForMember(
                key,
              )]!,
        ),
        value,
      ),
    ),
    instancesForDefinition: {},
  ).toJson();
}
