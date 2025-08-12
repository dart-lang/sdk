// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/base/analyzer_public_api.dart';

/// Analysis data for which we have a modification time.
@AnalyzerPublicApi(
  message: 'exposed by package:analyzer/source/timestamped_data.dart',
)
class TimestampedData<E> {
  /// The modification time of the source from which the data was created.
  final int modificationTime;

  /// The data that was created from the source.
  final E data;

  /// Initialize a newly created holder to associate the given [data] with the
  /// given [modificationTime].
  TimestampedData(this.modificationTime, this.data);
}
