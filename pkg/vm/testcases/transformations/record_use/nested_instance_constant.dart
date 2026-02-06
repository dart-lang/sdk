// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:meta/meta.dart' show RecordUse;

void main() {
  // Refers to a const Wrapper instance, which contains a Recorded instance.
  // It should still be recorded.
  useRecorded(_wrapper);
}

void useRecorded(Wrapper wrapper) {
  // We only record used things (including fields), so we have to use the
  // wrapped object.
  print(wrapper.recorded);
}

@RecordUse()
class Recorded {
  final String id;
  const Recorded(this.id);
}

class Wrapper {
  final Recorded recorded;
  const Wrapper(this.recorded);
}

const _wrapper = const Wrapper(Recorded('id'));
