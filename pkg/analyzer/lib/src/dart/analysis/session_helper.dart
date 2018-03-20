// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analyzer/dart/analysis/session.dart';
import 'package:analyzer/dart/element/element.dart';

/// A wrapper around [AnalysisSession] that provides additional utilities.
///
/// The methods in this class that return analysis results will throw an
/// [InconsistentAnalysisException] if the result to be returned might be
/// inconsistent with any previously returned results.
class AnalysisSessionHelper {
  final AnalysisSession session;

  AnalysisSessionHelper(this.session);

  /// Return the [ClassElement] with the given [className] that is exported
  /// from the library with the given [libraryUri], or `null` if the library
  /// does not export a class with such name.
  Future<ClassElement> getClass(String libraryUri, String className) async {
    var libraryElement = await session.getLibraryByUri(libraryUri);
    var element = libraryElement.exportNamespace.get(className);
    if (element is ClassElement) {
      return element;
    } else {
      return null;
    }
  }
}
