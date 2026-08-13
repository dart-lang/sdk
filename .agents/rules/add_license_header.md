---
trigger: glob
description: Ensure standard Dart license header on newly created Dart files.
globs: *.dart
---

# License Header Rule

Whenever you create a new Dart (`.dart`) file in this repository, you MUST include the standard Dart project license header at the very top (line 1).

Replace `<CURRENT_YEAR>` with the actual current year (e.g., 2026).

```dart
// Copyright (c) <CURRENT_YEAR>, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
```

## Requirements
- Insert at line 1.
- Ensure a blank line follows the license header before any other code or comments.
