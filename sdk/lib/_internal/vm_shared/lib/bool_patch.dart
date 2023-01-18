// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:_internal" show patch;

@patch
@pragma("vm:entry-point")
class bool {
  @patch
  @pragma("vm:external-name", "Bool_fromEnvironment")
  external const factory bool.fromEnvironment(String name,
      {bool defaultValue = false});

  @patch
  @pragma("vm:external-name", "Bool_hasEnvironment")
  external const factory bool.hasEnvironment(String name);

  @patch
  int get hashCode => this ? 1231 : 1237;

  int get _identityHashCode => this ? 1231 : 1237;

  @patch
  static bool parse(String source, {bool? caseSensitive}) {
    if (source == null) throw new ArgumentError("The source must not be null");
    if (source.isEmpty) throw new ArgumentError("The source must not be empty");
    //The caseSensitive defaults to true.
    if (caseSensitive == null || caseSensitive == true) return source == "true" ? true : source == "false" ? false : throw ArgumentError(source);     
    //Ignore case-sensitive when caseSensitive is false.                                      
    return _compareIgnoreCase(source, "true")? true : _compareIgnoreCase(source, "false")? false : throw ArgumentError(source);
  }

  @patch
  static bool? tryParse(String source, {bool? caseSensitive}) {
    if (source == null) throw new ArgumentError("The source must not be null");
    if (source.isEmpty) throw new ArgumentError("The source must not be empty");
    //The caseSensitive defaults to true.
    if (caseSensitive == null || caseSensitive == true) return source == "true" ? true : source == "false" ? false : null;     
    //Ignore case-sensitive when caseSensitive is false.                                      
    return _compareIgnoreCase(source, "true")? true : _compareIgnoreCase(source, "false")? false : null;
  }

  static bool _compareIgnoreCase(String input, String lowerCaseTarget) {
   if (input.length != lowerCaseTarget.length) return false;
   for (var i = 0; i < input.length; i++) {
     if (input.codeUnitAt(i) | 0x20 != lowerCaseTarget.codeUnitAt(i)) {
       return false;
     }
   }
   return true;
  }
}
