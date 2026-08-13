// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

extension type S1(num id) implements String /* Error */ {}

extension type S2(int id) implements num /* Ok */ {}

extension type V1(num id) {}

extension type V2(String id) implements V1 /* Error */ {}

extension type V3(int id) implements V1 /* Ok */ {}

extension type W1<T>(T id) {}

extension type W2(String id) implements W1<num> /* Error */ {}

extension type W3(int id) implements W1<num> /* Ok */ {}
