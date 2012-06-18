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
  String dartDir = appendSlash(nativeToUriPath(arguments[4]));

  Uri dartUri = cwd.resolve(dartDir);
  Uri productUri = cwd.resolve(productDir);

  Uri dartVmUri = productUri.resolve(dartVmPath);
  Uri productionUri = productUri.resolve(arguments[2]);
  Uri developerUri = productUri.resolve(arguments[3]);
  List<String> productionScript = buildScript(dartUri, dartVmUri, '');
  List<String> developerScript = buildScript(dartUri, dartVmUri,
                                             ' --enable_checked_mode');

  writeScript(productionUri, productionScript);
  writeScript(developerUri, developerScript);
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

List<String> buildScript(Uri dartUri, Uri dartVmLocation, String options) {
  Uri dart2jsUri = dartUri.resolve('lib/compiler/implementation/dart2js.dart');
  String dart2jsPath = relativize(dartVmLocation, dart2jsUri);
  String dart2jsPathWin = dart2jsPath.replaceAll("/", "\\");

  print('dartUri = $dartUri');
  print('dartVmLocation = $dartVmLocation');
  print('dart2jsUri = $dart2jsUri');
  print('dart2jsPath = $dart2jsPath');
  print('dart2jsPathWin = $dart2jsPathWin');

  options = ' $options';

  // Tell the VM to grow the heap more aggressively. This should only
  // be necessary temporarily until the VM is better at detecting how
  // applications use memory.
  // TODO(ahe): Remove this option.
  options = ' --heap_growth_rate=32$options';

  return [
'''
#!/bin/sh
# Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

BIN_DIR=`dirname \$0`
exec \$BIN_DIR/dart$options \$BIN_DIR/$dart2jsPath "\$@"
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

"%SCRIPTPATH%\dart.exe"$options "%SCRIPTPATH%$dart2jsPathWin" %arguments%
'''.replaceAll('\n', '\r\n')];
}
