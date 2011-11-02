// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#library("StatusFileParserTest");

#import("../../../tools/testing/dart/status_file_parser.dart");


main() {
  ReadConfigurationInto("tests/co19/co19-compiler.status", new List<Section>());
  ReadConfigurationInto("tests/co19/co19-runtime.status", new List<Section>());
  ReadConfigurationInto("tests/corelib/corelib.status", new List<Section>());
  ReadConfigurationInto("tests/isolate/isolate.status", new List<Section>());
  ReadConfigurationInto("tests/language/language.status", new List<Section>());
  ReadConfigurationInto("tests/standalone/standalone.status",
                        new List<Section>());
  ReadConfigurationInto("tests/stub-generator/stub-generator.status",
                        new List<Section>());
  ReadConfigurationInto("samples/tests/samples/samples.status",
                        new List<Section>());
  ReadConfigurationInto("runtime/tests/vm/vm.status", new List<Section>());
  ReadConfigurationInto("frog/tests/frog/frog.status", new List<Section>());
  ReadConfigurationInto("compiler/tests/dartc/dartc.status",
                        new List<Section>());
  ReadConfigurationInto("client/tests/client/client.status",
                        new List<Section>());
  ReadConfigurationInto("client/tests/dartc/dartc.status",
                        new List<Section>());
}
