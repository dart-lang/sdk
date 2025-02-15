// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/element/element2.dart';
import 'package:analyzer/dart/element/visitor.dart';
import 'package:analyzer/dart/element/visitor2.dart';

/// Returns the fragment that is either [fragment], or one of its direct or
/// indirect children, and has the given [nameOffset].
Fragment? findFragmentByNameOffset(LibraryFragment fragment, int nameOffset) {
  return _FragmentByNameOffsetVisitor(nameOffset).search(fragment);
}

/// Uses [processor] to visit all of the children of [element].
/// If [processor] returns `true`, then children of a child are visited too.
void visitChildren2(Element2 element, BoolElementProcessor2 processor) {
  element.visitChildren2(_ElementVisitorAdapter2(processor));
}

/// An [Element2] processor function type.
/// If `true` is returned, children of [element] will be visited.
typedef BoolElementProcessor2 = bool Function(Element2 element);

/// A [GeneralizingElementVisitor] adapter for [BoolElementProcessor2].
class _ElementVisitorAdapter2 extends GeneralizingElementVisitor2<void> {
  final BoolElementProcessor2 processor;

  _ElementVisitorAdapter2(this.processor);

  @override
  void visitElement(Element2 element) {
    var visitChildren = processor(element);
    if (visitChildren == true) {
      element.visitChildren2(this);
    }
  }
}

/// A visitor that finds the deep-most fragment that contains the [nameOffset].
class _FragmentByNameOffsetVisitor {
  final int nameOffset;

  _FragmentByNameOffsetVisitor(this.nameOffset);

  Fragment? search(LibraryFragment fragment) => _searchIn(fragment);

  Fragment? _searchIn(Fragment fragment) {
    if (fragment.nameOffset2 == nameOffset) {
      return fragment;
    }
    for (var child in fragment.children3) {
      var result = _searchIn(child);
      if (result != null) {
        return result;
      }
    }
    return null;
  }
}
