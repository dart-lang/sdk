// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * The command line and other arguments passed to the test runner are
 * gathered into a global [Configuration] instance that controls the
 * execution. For details on the various options here see
 * [getOptionParser].
 */
class Configuration {
  final String unittestPath;
  final bool runInBrowser;
  final bool runIsolated;
  final bool verbose;
  final bool immediateOutput;
  final bool layoutText;
  final bool layoutPixel;
  final bool produceSummary;
  final bool includeTime;
  final bool listFiles;
  final bool listTests;
  final bool listGroups;
  final String listFormat;
  final String passFormat;
  final String failFormat;
  final String errorFormat;
  final List includeFilter;
  final List excludeFilter;
  final int timeout;
  final String runtime;
  final bool checkedMode;
  final bool keepTests;
  final bool stopOnFailure;
  final int maxTasks;
  final String outputStream;
  final String logStream;
  final String tempDir;
  final bool regenerate;
  String dart2jsPath;
  String drtPath;
  String dartPath;
  bool filtering;

  Configuration(ArgParser parser, ArgResults options) :
    unittestPath = makePathAbsolute(options['unittest']),
    runIsolated = options['isolate'],
    runInBrowser = (options['runtime'] != 'vm'),
    verbose = (options['log'] != 'none' && !options['list-groups']),
    immediateOutput = options['immediate'],
    layoutText = options['layout-text'],
    layoutPixel = options['layout-pixel'],
    produceSummary = options['summary'],
    includeTime = options['time'],
    listFiles = options['list-files'],
    listTests = options['list-tests'],
    listGroups = options['list-groups'],
    listFormat = options['list-format'],
    passFormat = options['pass-format'],
    failFormat = options['fail-format'],
    errorFormat = options['error-format'],
    includeFilter = options['include'],
    excludeFilter = options['exclude'],
    timeout = int.parse(options['timeout']),
    runtime = options['runtime'],
    checkedMode = options['checked'],
    keepTests = (options['keep-files'] &&
            !(options['list-groups'] || options['list-tests'])),
    stopOnFailure = options['stop-on-failure'],
    maxTasks = int.parse(options['tasks']),
    outputStream = options['out'],
    logStream = options['log'],
    tempDir = options['tempdir'],
    regenerate = options['regenerate'] {
    filtering = (includeFilter.length > 0 || excludeFilter.length > 0);
    var dartsdk = options['dartsdk'];
    var pathSep = Platform.pathSeparator;

    if (dartsdk == null ||
        parser.getDefault('dart2js') != options['dart2js']) {
      dart2jsPath = options['dart2js'];
    } else {
      dart2jsPath = '$dartsdk${pathSep}dart-sdk${pathSep}bin${pathSep}dart2js';
    }

    if (dartsdk == null ||
        parser.getDefault('dart') != options['dart']) {
      dartPath = options['dart'];
    } else {
      dartPath = '$dartsdk${pathSep}dart-sdk${pathSep}bin${pathSep}dart';
    }

    if (dartsdk == null ||
        parser.getDefault('drt') != options['drt']) {
      drtPath = options['drt'];
    } else {
      drtPath = '$dartsdk${pathSep}chromium${pathSep}DumpRenderTree';
    }
  }
}
