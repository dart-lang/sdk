// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test/test.dart';

import '../../../tool/lsp_spec/markdown.dart';

void main() {
  group('markdown parser', () {
    test('extracts a typescript fenced block from Markdown', () {
      final input = '''
```typescript
CONTENT
```
    ''';
      final output = extractTypeScriptBlocks(input);
      expect(output, hasLength(1));
      expect(output, contains('CONTENT'));
    });

    test('does not extract unknown code blocks', () {
      final input = '''
```
CONTENT
```

```dart
CONTENT
```
    ''';
      final output = extractTypeScriptBlocks(input);
      expect(output, hasLength(0));
    });

    test('extracts multiple code blocks', () {
      final input = '''
```typescript
CONTENT1
```

```typescript
CONTENT2
```
    ''';
      final output = extractTypeScriptBlocks(input);
      expect(output, hasLength(2));
      expect(output, contains('CONTENT1'));
      expect(output, contains('CONTENT2'));
    });
  });
}
