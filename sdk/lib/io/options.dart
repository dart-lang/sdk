// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart.io;

@deprecated
/**
 * Deprecated: the Options object allows accessing the arguments which
 * have been passed to the current isolate.
 *
 * This class has been replaced by making the arguments an optional parameter
 * to main.  The other members, executable, script, and versione, are already
 * available on Platform (which will move to the dart:plaform library).
 *
 * This class will be removed on October 28, 2013.
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


  /**
   * Returns the version of the current Dart runtime.
   */
  String get version;
}

class _OptionsImpl implements Options {
  List<String> _arguments = null;

  // This arguments singleton is written to by the embedder if applicable.
  static List<String> _nativeArguments = const [];

  List<String> get arguments {
    if (_arguments == null) {
      // On first access make a copy of the native arguments.
      _arguments = _nativeArguments.sublist(0, _nativeArguments.length);
    }
    return _arguments;
  }

  String get executable => Platform.executable;
  String get script => Platform.script;
  String get version => Platform.version;
}
