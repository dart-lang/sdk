// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#import('dart:io');
#import('dart:uri');

#import('../../lib/compiler/implementation/util/uri_extras.dart');
#import('../../lib/compiler/implementation/filenames.dart');

main() {
  List<String> arguments = new Options().arguments;
  Uri cwd = getCurrentDirectory();
  String productDir = appendSlash(nativeToUriPath(arguments[0]));
  String dartVmPath = nativeToUriPath(arguments[1]);
  String productionName = nativeToUriPath(arguments[2]);
  String developerName = nativeToUriPath(arguments[3]);
  String dartdocName = nativeToUriPath(arguments[4]);
  String dartDir = appendSlash(nativeToUriPath(arguments[5]));

  Uri dartUri = cwd.resolve(dartDir);
  Uri productUri = cwd.resolve(productDir);

  Uri dartVmUri = productUri.resolve(dartVmPath);
  Uri productionUri = productUri.resolve(arguments[2]);
  Uri developerUri = productUri.resolve(arguments[3]);
  Uri dartdocUri = productUri.resolve(arguments[4]);

  List<String> productionScript = buildScript(
      'dart2js-production',
      dartUri, dartVmUri,
      'lib/compiler/implementation/dart2js.dart', '');
  writeScript(productionUri, productionScript);

  List<String> developerScript = buildScript(
      'dart2js-developer',
      dartUri, dartVmUri,
      'lib/compiler/implementation/dart2js.dart', ' --enable_checked_mode');
  writeScript(developerUri, developerScript);

  List<String> dartdocScript = buildScript(
      'dartdoc',
      dartUri, dartVmUri,
      'pkg/dartdoc/bin/dartdoc.dart', '');
  writeScript(dartdocUri, dartdocScript);
}

writeScript(Uri uri, List<String> scripts) {
  String unixScript = scripts[0];
  String batFile = scripts[1];
  var f = new File(uriPathToNative(uri.path));
  var stream = f.openSync(FileMode.WRITE);
  try {
    stream.writeStringSync(unixScript);
  } finally {
    stream.closeSync();
  }

  f = new File('${uriPathToNative(uri.path)}.bat');
  stream = f.openSync(FileMode.WRITE);
  try {
    stream.writeStringSync(batFile);
  } finally {
    stream.closeSync();
  }

  if (Platform.operatingSystem != 'windows') {
    onExit(ProcessResult result) {
      if (result.exitCode != 0) {
        print(result.stdout);
        print(result.stderr);
        exit(result.exitCode);
      }
    }
    Process.run('/bin/chmod', ['+x', uri.path]).then(onExit);
  }
}

List<String> buildScript(String name,
                         Uri dartUri, Uri dartVmLocation,
                         String entrypoint, String options) {
  bool isWindows = (Platform.operatingSystem == 'windows');
  Uri uri = dartUri.resolve(entrypoint);
  String path = relativize(dartVmLocation, uri, isWindows);
  String pathWin = path.replaceAll("/", "\\");

  print('dartUri = $dartUri');
  print('dartVmLocation = $dartVmLocation');
  print('${name}Uri = $uri');
  print('${name}Path = $path');
  print('${name}PathWin = $pathWin');

  // Tell the VM to grow the heap more aggressively. This should only
  // be necessary temporarily until the VM is better at detecting how
  // applications use memory.
  // TODO(ahe): Remove this option.
  options = ' --heap_growth_rate=32$options';

  return [
'''
#!/bin/bash
# Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

# Setting BIN_DIR this way is ugly, but is needed to handle the case where
# dart-sdk/bin has been symlinked to. On MacOS, readlink doesn't work
# with this case.
BIN_DIR="\$(cd "\${0%/*}" ; pwd -P)"

unset COLORS
if test -t 1; then
  # Stdout is a terminal.
  if test 8 -le `tput colors`; then
    # Stdout has at least 8 colors, so enable colors.
    COLORS="--enable-diagnostic-colors"
  fi
fi
exec "\$BIN_DIR"/dart$options "\$BIN_DIR/$path" \$COLORS "\$@"
''',
'''
@echo off
REM Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
REM for details. All rights reserved. Use of this source code is governed by a
REM BSD-style license that can be found in the LICENSE file.

set SCRIPTPATH=%~dp0

REM Does the path have a trailing slash? If so, remove it.
if %SCRIPTPATH:~-1%==\ set SCRIPTPATH=%SCRIPTPATH:~0,-1%

set arguments=%*

"%SCRIPTPATH%\dart.exe"$options "%SCRIPTPATH%$pathWin" %arguments%
'''.replaceAll('\n', '\r\n')];
}
