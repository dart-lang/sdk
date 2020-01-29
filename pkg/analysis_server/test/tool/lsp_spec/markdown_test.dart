// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test/test.dart';

import '../../../tool/lsp_spec/markdown.dart';

void main() {
  group('markdown parser', () {
    test('extracts a typescript fenced block from Markdown', () {
      final String input = '''
```typescript
CONTENT
```
    ''';
      final List<String> output = extractTypeScriptBlocks(input);
      expect(output, hasLength(1));
      expect(output, contains('CONTENT'));
    });

    test('does not extract unknown code blocks', () {
      final String input = '''
```
CONTENT
```

```dart
CONTENT
```
    ''';
      final List<String> output = extractTypeScriptBlocks(input);
      expect(output, hasLength(0));
    });

    test('extracts multiple code blocks', () {
      final String input = '''
```typescript
CONTENT1
```

```typescript
CONTENT2
```
    ''';
      final List<String> output = extractTypeScriptBlocks(input);
      expect(output, hasLength(2));
      expect(output, contains('CONTENT1'));
      expect(output, contains('CONTENT2'));
    });
  });
}
