// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/testing/annotated_code_helper.dart';
import 'package:_fe_analyzer_shared/src/testing/id.dart';
import 'package:_fe_analyzer_shared/src/testing/id_testing.dart';

Map<Uri, List<Annotation>> computeAnnotationsPerUri<T>(
    Map<String, MemberAnnotations<IdValue>> expectedMaps,
    Uri mainUri,
    Map<String, Map<Uri, Map<Id, ActualData<T>>>> actualData,
    DataInterpreter<T> dataInterpreter) {
  Set<Uri> uriSet = {};
  Set<String> actualMarkers = actualData.keys.toSet();
  Map<Uri, Map<Id, Map<String, IdValue>>> idValuePerUri = {};
  Map<Uri, Map<Id, Map<String, ActualData<T>>>> actualDataPerUri = {};

  void addData(String marker, Uri uri, Map<Id, IdValue> data) {
    assert(uri != null);
    uriSet.add(uri);
    Map<Id, Map<String, IdValue>> idValuePerId = idValuePerUri[uri] ??= {};
    data.forEach((Id id, IdValue value) {
      Map<String, IdValue> idValuePerMarker = idValuePerId[id] ??= {};
      idValuePerMarker[marker] = value;
    });
  }

  expectedMaps.forEach((String marker, MemberAnnotations<IdValue> annotations) {
    annotations.forEach((Uri uri, Map<Id, IdValue> data) {
      addData(marker, uri, data);
    });
    addData(marker, mainUri, annotations.globalData);
  });

  actualData
      .forEach((String marker, Map<Uri, Map<Id, ActualData<T>>> dataPerUri) {
    dataPerUri.forEach((Uri uri, Map<Id, ActualData<T>> dataMap) {
      assert(uri != null);
      uriSet.add(uri);
      dataMap.forEach((Id id, ActualData<T> data) {
        Map<Id, Map<String, ActualData<T>>> actualDataPerId =
            actualDataPerUri[uri] ??= {};
        Map<String, ActualData<T>> actualDataPerMarker =
            actualDataPerId[id] ??= {};
        actualDataPerMarker[marker] = data;
      });
    });
  });

  Map<Uri, List<Annotation>> result = {};
  for (Uri uri in uriSet) {
    Map<Id, Map<String, IdValue>> idValuePerId = idValuePerUri[uri] ?? {};
    Map<Id, Map<String, ActualData<T>>> actualDataPerId =
        actualDataPerUri[uri] ?? {};
    result[uri] = _computeAnnotations(expectedMaps.keys, actualMarkers,
        idValuePerId, actualDataPerId, dataInterpreter,
        sortMarkers: false);
  }
  return result;
}

List<Annotation> _computeAnnotations<T>(
    Iterable<String> supportedMarkers,
    Set<String> actualMarkers,
    Map<Id, Map<String, IdValue>> idValuePerId,
    Map<Id, Map<String, ActualData<T>>> actualDataPerId,
    DataInterpreter<T> dataInterpreter,
    {String prefix: '/*',
    String suffix: '*/',
    bool sortMarkers: true}) {
  Annotation createAnnotationFromData(
      ActualData<T> actualData, Annotation annotation) {
    return new Annotation(
        annotation?.lineNo ?? -1,
        annotation?.columnNo ?? -1,
        annotation?.offset ?? actualData.offset,
        annotation?.prefix ?? prefix,
        IdValue.idToString(
            actualData.id, dataInterpreter.getText(actualData.value)),
        annotation?.suffix ?? suffix);
  }

  Set<Id> idSet = {}..addAll(idValuePerId.keys)..addAll(actualDataPerId.keys);
  List<Annotation> result = <Annotation>[];
  for (Id id in idSet) {
    Map<String, IdValue> idValuePerMarker = idValuePerId[id] ?? {};
    Map<String, ActualData<T>> actualDataPerMarker = actualDataPerId[id] ?? {};

    Map<String, Annotation> newAnnotationsPerMarker = {};
    for (String marker in supportedMarkers) {
      IdValue idValue = idValuePerMarker[marker];
      ActualData<T> actualData = actualDataPerMarker[marker];
      if (idValue != null && actualData != null) {
        if (dataInterpreter.isAsExpected(actualData.value, idValue.value) ==
            null) {
          // Use existing annotation.
          newAnnotationsPerMarker[marker] = idValue.annotation;
        } else {
          newAnnotationsPerMarker[marker] =
              createAnnotationFromData(actualData, idValue.annotation);
        }
      } else if (idValue != null && !actualMarkers.contains(marker)) {
        // Use existing annotation if no actual data is provided for this
        // marker.
        newAnnotationsPerMarker[marker] = idValue.annotation;
      } else if (actualData != null) {
        newAnnotationsPerMarker[marker] =
            createAnnotationFromData(actualData, null);
      }
    }

    Map<String, Map<String, Annotation>> groupedByText = {};
    newAnnotationsPerMarker.forEach((String marker, Annotation annotation) {
      Map<String, Annotation> byText = groupedByText[annotation.text] ??= {};
      byText[marker] = annotation;
    });
    groupedByText.forEach((String text, Map<String, Annotation> annotations) {
      Set<String> markers = annotations.keys.toSet();
      if (markers.isNotEmpty) {
        String prefix;
        if (markers.length == supportedMarkers.length) {
          // Don't use prefix for annotations that match all markers.
          prefix = '';
        } else {
          Iterable<String> usedMarkers = markers;
          if (sortMarkers) {
            usedMarkers = usedMarkers.toList()..sort();
          }
          prefix = '${usedMarkers.join('|')}.';
        }
        Annotation firstAnnotation = annotations.values.first;
        result.add(new Annotation(
            firstAnnotation.lineNo,
            firstAnnotation.columnNo,
            firstAnnotation.offset,
            firstAnnotation.prefix,
            '$prefix$text',
            firstAnnotation.suffix));
      }
    });
  }
  return result;
}

bool setEquals<E>(Set<E> a, Set<E> b) {
  return a.length == b.length && a.containsAll(b);
}
