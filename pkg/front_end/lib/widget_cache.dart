// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/class_hierarchy.dart';
import 'package:kernel/kernel.dart';

/// Provides support for "single widget reloads" in Flutter, by determining if
/// a partial component contains single change to the class body of a
/// StatelessWidget, StatefulWidget, or State subtype.
class WidgetCache {
  /// Create a [WidgetCache] from a [Component] containing the flutter
  /// framework.
  WidgetCache(Component fullComponent) {
    Library frameworkLibrary;
    for (Library library in fullComponent.libraries) {
      if (library?.importUri == _frameworkLibrary) {
        frameworkLibrary = library;
        break;
      }
    }
    if (frameworkLibrary == null) {
      return;
    }
    _locatedClassDeclarations(frameworkLibrary);
    _frameworkTypesLocated =
        _statefulWidget != null && _state != null && _statelessWidget != null;
  }

  static const String _stateClassName = 'State';
  static const String _statefulWidgetClassName = 'StatefulWidget';
  static const String _statelessWidgetClassName = 'StatelessWidget';

  Class _statelessWidget;
  Class _state;
  Class _statefulWidget;
  bool _frameworkTypesLocated = false;

  static final Uri _frameworkLibrary =
      Uri.parse('package:flutter/src/widgets/framework.dart');

  /// Mark [uri] as invalidated.
  void invalidate(Uri uri) {
    _invalidatedLibraries.add(uri);
  }

  /// Reset the invalidated libraries.
  void reset() {
    _invalidatedLibraries.clear();
  }

  final List<Uri> _invalidatedLibraries = <Uri>[];

  /// Determine if any changes to [partialComponent] were located entirely
  /// within the class body of a single `StatefulWidget`, `StatelessWidget` or
  /// `State` subtype.
  ///
  /// Returns the class name if located, otherwise `null`.
  String checkSingleWidgetTypeModified(
    Component lastGoodComponent,
    Component partialComponent,
    ClassHierarchy classHierarchy,
  ) {
    if (!_frameworkTypesLocated ||
        lastGoodComponent == null ||
        _invalidatedLibraries.length != 1) {
      return null;
    }
    Uri importUri = _invalidatedLibraries[0];
    Library library;
    for (Library candidateLibrary in partialComponent.libraries) {
      if (candidateLibrary.importUri == importUri) {
        library = candidateLibrary;
        break;
      }
    }
    if (library == null) {
      return null;
    }
    List<int> oldSource = lastGoodComponent.uriToSource[library.fileUri].source;
    List<int> newSource = partialComponent.uriToSource[library.fileUri].source;
    // Library was added and does not exist in the old component.
    if (oldSource == null) {
      return null;
    }
    int newStartIndex = 0;
    int newEndIndex = newSource.length - 1;
    int oldStartIndex = 0;
    int oldEndIndex = oldSource.length - 1;

    while (newStartIndex < newEndIndex && oldStartIndex < oldEndIndex) {
      if (newSource[newStartIndex] != oldSource[oldStartIndex]) {
        break;
      }
      newStartIndex += 1;
      oldStartIndex += 1;
    }
    while (newEndIndex > newStartIndex && oldEndIndex > oldStartIndex) {
      if (newSource[newEndIndex] != oldSource[oldEndIndex]) {
        break;
      }
      newEndIndex -= 1;
      oldEndIndex -= 1;
    }

    Class newClass =
        _locateContainingClass(library, newStartIndex, newEndIndex);
    if (newClass == null) {
      return null;
    }

    Library oldLibrary =
        lastGoodComponent.libraries.firstWhere((Library library) {
      return library.importUri == importUri;
    });

    Class oldClass =
        _locateContainingClass(oldLibrary, oldStartIndex, oldEndIndex);

    if (oldClass == null || oldClass.name != newClass.name) {
      return null;
    }

    // Update the class references to stateless, stateful, and state classes.
    for (Library library in classHierarchy.knownLibraries) {
      if (library?.importUri == _frameworkLibrary) {
        _locatedClassDeclarations(library);
      }
    }

    if (classHierarchy.isSubclassOf(newClass, _statelessWidget) ||
        classHierarchy.isSubclassOf(newClass, _statefulWidget)) {
      if (classHierarchy.isExtended(newClass) ||
          classHierarchy.isUsedAsMixin(newClass)) {
        return null;
      }
      return newClass.name;
    }

    // For changes to State classes, locate the name of the corresponding
    // StatefulWidget that is provided as a type parameter. If the bounds are
    // StatefulWidget itself, fail as that indicates the type was not
    // specified.
    Supertype stateSuperType =
        classHierarchy.getClassAsInstanceOf(newClass, _state);
    if (stateSuperType != null) {
      if (stateSuperType.typeArguments.length != 1) {
        return null;
      }
      DartType widgetType = stateSuperType.typeArguments[0];
      if (widgetType is InterfaceType) {
        Class statefulWidgetType = widgetType.classNode;
        if (statefulWidgetType.name == _statefulWidgetClassName) {
          return null;
        }
        if (classHierarchy.isExtended(statefulWidgetType) ||
            classHierarchy.isUsedAsMixin(statefulWidgetType)) {
          return null;
        }
        return statefulWidgetType.name;
      }
    }

    return null;
  }

  // Locate the that fully contains the edit range, or null.
  Class _locateContainingClass(
      Library library, int startOffset, int endOffset) {
    for (Class classDeclaration in library.classes) {
      if (classDeclaration.startFileOffset <= startOffset &&
          classDeclaration.fileEndOffset >= endOffset) {
        return classDeclaration;
      }
    }
    return null;
  }

  void _locatedClassDeclarations(Library library) {
    for (Class classDeclaration in library.classes) {
      if (classDeclaration.name == _statelessWidgetClassName) {
        _statelessWidget = classDeclaration;
      } else if (classDeclaration.name == _statefulWidgetClassName) {
        _statefulWidget = classDeclaration;
      } else if (classDeclaration.name == _stateClassName) {
        _state = classDeclaration;
      }
    }
  }
}
