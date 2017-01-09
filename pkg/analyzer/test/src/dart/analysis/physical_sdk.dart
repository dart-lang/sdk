// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/file_system/physical_file_system.dart';
import 'package:analyzer/src/dart/sdk/sdk.dart';
import 'package:analyzer/src/generated/sdk.dart';

final DartSdk sdk = new FolderBasedDartSdk(PhysicalResourceProvider.INSTANCE,
    FolderBasedDartSdk.defaultSdkDirectory(PhysicalResourceProvider.INSTANCE))
  ..useSummary = true;
