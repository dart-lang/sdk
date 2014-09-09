// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/** The entry point for the command-line version analyzer2dart. */
library analyzer2dart.cmdline;

import 'dart:io';

import 'package:analyzer/file_system/physical_file_system.dart';
import 'package:analyzer/src/generated/element.dart';
import 'package:analyzer/src/generated/sdk.dart';
import 'package:analyzer/src/generated/sdk_io.dart';
import 'package:analyzer/src/generated/source_io.dart';
import 'package:compiler/implementation/source_file_provider.dart';

import '../lib/src/closed_world.dart';
import '../lib/src/driver.dart';
import '../lib/src/converted_world.dart';
import '../lib/src/dart_backend.dart';

void main(List<String> args) {
  // TODO(paulberry): hacky
  String path = args[0];

  PhysicalResourceProvider provider = PhysicalResourceProvider.INSTANCE;
  DartSdk sdk = DirectoryBasedDartSdk.defaultSdk;
  // TODO(johnniwinther): Support user specified output Uri.
  // TODO(johnniwinther): Integrate messaging.
  RandomAccessFileOutputProvider outputProvider =
      new RandomAccessFileOutputProvider(
          Uri.base.resolve('out.dart'),
          Uri.base.resolve('out.dart.map'),
          onInfo: (message) => print(message),
          onFailure: (message) {
            print(message);
            exit(1);
          });

  Driver analyzer2Dart = new Driver(provider, sdk, outputProvider);

  // Tell the analysis server about the root
  Source source = analyzer2Dart.setRoot(path);

  // Get the library element associated with the source.
  FunctionElement entryPointElement = analyzer2Dart.resolveEntryPoint(source);

  // TODO(brianwilkerson,paulberry,johnniwinther): Perform tree-growing by
  // visiting the ast and feeding the dependencies into a work queue (enqueuer).
  ClosedWorld world = analyzer2Dart.computeWorld(entryPointElement);

  // TODO(brianwilkerson,paulberry,johnniwinther): Convert the ast into cps by
  // visiting the ast and invoking the ir builder.
  // TODO(johnniwinther): Convert the analyzer element model into the dart2js
  // element model to fit the needs of the cps encoding above.
  ConvertedWorld convertedWorld = convertWorld(world);

  // TODO(johnniwinther): Feed the cps ir into the new dart2dart backend to
  // generate dart file(s).
  compileToDart(analyzer2Dart, convertedWorld);
}

