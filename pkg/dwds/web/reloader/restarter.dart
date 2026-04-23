// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:js_interop';

abstract class Restarter {
  /// Attempts to perform a hot restart.
  ///
  /// [reloadedSourcesPath] is the path to a JSONified list of maps that
  /// represents the sources that were reloaded in this restart and follows the
  /// following format:
  ///
  /// ```json
  /// [
  ///   {
  ///     "src": "<base_uri>/<file_name>",
  ///     "module": "<module_name>",
  ///     "libraries": ["<lib1>", "<lib2>"],
  ///   },
  /// ]
  /// ```
  ///
  /// `src`: A string that corresponds to the file path containing a DDC library
  /// bundle.
  /// `module`: The name of the library bundle in `src`.
  /// `libraries`: An array of strings containing the libraries that were
  /// compiled in `src`.
  ///
  /// Returns a record containing whether the hot restart succeeded and either
  /// the JS version of the list of maps from [reloadedSourcesPath] if
  /// [reloadedSourcesPath] is non-null and null otherwise.
  Future<(bool, JSArray<JSObject>?)> restart({
    String? runId,
    Future? readyToRunMain,
    String? reloadedSourcesPath,
  });

  /// After a previous call to [hotReloadStart], completes the hot
  /// reload by pushing the libraries into the Dart runtime.
  Future<void> hotReloadEnd();

  /// Using [reloadedSourcesPath] as the path to a JSONified list of maps which
  /// follows the following format:
  ///
  /// ```json
  /// [
  ///   {
  ///     "src": "<base_uri>/<file_name>",
  ///     "module": "<module_name>",
  ///     "libraries": ["<lib1>", "<lib2>"],
  ///   },
  /// ]
  /// ```
  ///
  /// computes the sources and libraries to reload, loads them into the page,
  /// and returns a JS version of the list of maps.
  ///
  /// `src`: A string that corresponds to the file path containing a DDC library
  /// bundle.
  /// `module`: The name of the library bundle in `src`.
  /// `libraries`: An array of strings containing the libraries that were
  /// compiled in `src`.
  Future<JSArray<JSObject>> hotReloadStart(String reloadedSourcesPath);
}
