// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart.core;

/**
 * The Options object allows accessing the arguments which have been passed to
 * the current isolate.
 */
abstract class Options {
  /**
   * A newly constructed Options object contains the arguments exactly as they
   * have been passed to the isolate.
   */
  factory Options() => new _OptionsImpl();

  /**
   * Returns a list of arguments that have been passed to this isolate. Any
   * modifications to the list will be contained to the options object owning
   * this list.
   *
   * If the execution environment does not support [arguments] an empty list
   * is returned.
   */
  List<String> get arguments;

  /**
   * Returns the path of the executable used to run the script in this
   * isolate.
   *
   * If the execution environment does not support [executable] an empty
   * string is returned.
   */
  String get executable;

  /**
   * Returns the path of the script being run in this isolate.
   *
   * If the executable environment does not support [script] an empty
   * string is returned.
   */
  String get script;
}

class _OptionsImpl implements Options {
  List<String> get arguments {
    if (_arguments == null) {
      // On first access make a copy of the native arguments.
      _arguments = _nativeArguments.getRange(0, _nativeArguments.length);
    }
    return _arguments;
  }

  String get executable {
    return _nativeExecutable;
  }

  String get script {
    return _nativeScript;
  }

  List<String> _arguments = null;

  // This arguments singleton is written to by the embedder if applicable.
  static List<String> _nativeArguments = const [];

  // This executable singleton is written to by the embedder if applicable.
  static String _nativeExecutable = '';

  // This script singleton is written to by the embedder if applicable.
  static String _nativeScript = '';
}
