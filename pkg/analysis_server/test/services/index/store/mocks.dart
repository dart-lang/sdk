// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.services.index.store.mocks;

import 'package:analysis_server/src/services/index/index.dart';
import 'package:analysis_server/src/services/index/store/codec.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:typed_mock/typed_mock.dart';


class MockContextCodec extends TypedMock implements ContextCodec {
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}


class MockElementCodec extends TypedMock implements ElementCodec {
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}


class MockInstrumentedAnalysisContextImpl extends TypedMock implements
    InstrumentedAnalysisContextImpl {
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}


class MockLocation extends TypedMock implements Location {
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}


class MockRelationshipCodec extends TypedMock implements RelationshipCodec {
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
