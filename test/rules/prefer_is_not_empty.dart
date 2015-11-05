// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

bool lne = ![].isEmpty; //LINT [12:11]
bool mne = !{}.isEmpty; //LINT
bool ine = !iterable.isEmpty; //LINT

bool le = [].isEmpty;
bool me = {}.isEmpty;
bool ie = iterable.isEmpty;

Iterable get iterable => [];
