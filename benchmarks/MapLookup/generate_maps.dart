// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

void main() {
  final buffer = StringBuffer();
  buffer.write('''
// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

  ''');

  generateMap(buffer, 'const1', 1, isConst: true);
  generateMap(buffer, 'final1', 1, isConst: false);
  generateMap(buffer, 'const5', 5, isConst: true);
  generateMap(buffer, 'final5', 5, isConst: false);
  generateMap(buffer, 'const10', 10, isConst: true);
  generateMap(buffer, 'final10', 10, isConst: false);
  generateMap(buffer, 'const100', 100, isConst: true);
  generateMap(buffer, 'final100', 100, isConst: false);

  for (final folder in ['dart', 'dart2']) {
    final path = Platform.script.resolve('$folder/maps.dart').toFilePath();
    File(path).writeAsStringSync(buffer.toString());
    Process.runSync(Platform.executable, ['format', path]);
    print('Generated $path.');
  }
}

void generateMap(StringBuffer buffer, String name, int mapSize,
    {bool isConst = true}) {
  final constOrFinal = isConst ? 'const' : 'final';
  buffer.write('$constOrFinal $name = <String, String>{');
  for (int i = 0; i < mapSize; i++) {
    buffer.write("'$i': '${i + 1}',");
  }
  buffer.write('};');
  buffer.write('\n\n');
}
