// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Extension type that uses a list as a stack.
extension type LocalStack<T>(List<T> _list) {
  /// Return `true` if the stack is not empty.
  ///
  /// ```
  /// DartDocTest(LocalStack<int>([]).hasCurrent, false)
  /// DartDocTest(LocalStack<int>([0]).hasCurrent, true)
  /// DartDocTest(LocalStack<int>([0, 1]).hasCurrent, true)
  /// ```
  bool get hasCurrent => _list.isNotEmpty;

  /// Return the current top of the stack.
  ///
  /// ```
  /// DartDocTestThrows(LocalStack<int>([]).current)
  /// DartDocTest(LocalStack<int>([0]).current, 0)
  /// DartDocTest(LocalStack<int>([0, 1]).current, 1)
  /// ```
  T get current => _list.last;

  /// Return `true` if the stack has more than one element.
  ///
  /// ```
  /// DartDocTest(LocalStack<int>([]).hasPrevious, false)
  /// DartDocTest(LocalStack<int>([0]).hasPrevious, false)
  /// DartDocTest(LocalStack<int>([0, 1]).hasPrevious, true)
  /// ```
  bool get hasPrevious => _list.length > 1;

  /// Returns the second-most element on the stack.
  ///
  /// ```
  /// DartDocTestThrows(LocalStack<int>([]).previous)
  /// DartDocTestThrows(LocalStack<int>([0]).previous)
  /// DartDocTest(LocalStack<int>([0, 1]).previous, 0)
  /// DartDocTest(LocalStack<int>([0, 1, 2]).previous, 1)
  /// ```
  T get previous => _list[_list.length - 2];

  /// Puts [element] on the top of the stack.
  ///
  /// ```
  /// DartDocTest((LocalStack<int>([])..push(0)).current, 0)
  /// DartDocTest((LocalStack<int>([])..push(0)..push(1)).current, 1)
  /// DartDocTest(
  ///   (LocalStack<int>([])..push(0)..pop()..push(1)).hasPrevious,
  ///   false
  /// )
  /// ```
  void push(T element) {
    _list.add(element);
  }

  /// Pops the top of the stack.
  ///
  /// ```
  /// DartDocTestThrows(LocalStack<int>([]).pop())
  /// DartDocTest(LocalStack<int>([0]).pop(), 0)
  /// DartDocTest((LocalStack<int>([0, 1, 2])..pop()).pop(), 1)
  /// ```
  T pop() {
    return _list.removeLast();
  }

  /// Return `true` if the stack is empty.
  ///
  /// ```
  /// DartDocTest(LocalStack<int>([]).isEmpty, true)
  /// DartDocTest(LocalStack<int>([0]).isEmpty, false)
  /// DartDocTest(LocalStack<int>([0, 1]).isEmpty, false)
  /// ```
  bool get isEmpty => _list.isEmpty;

  /// Return `true` if the stack contains a single element.
  ///
  /// ```
  /// DartDocTest(LocalStack<int>([]).isSingular, false)
  /// DartDocTest(LocalStack<int>([0]).isSingular, true)
  /// DartDocTest(LocalStack<int>([0, 1]).isSingular, false)
  /// ```
  bool get isSingular => _list.length == 1;
}
