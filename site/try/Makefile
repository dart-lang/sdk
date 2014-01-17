# Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE

# TODO(ahe): Convert this to GYP.

all:
	../../sdk/bin/dart -Dlist_all_libraries=true ../../sdk/lib/_internal/compiler/samples/jsonify/jsonify.dart sdk.dart
	../../sdk/bin/dart jsonify.dart > sdk.json
	../../sdk/bin/dart2js -Denable_ir=false leap.dart -oleap.dart.js
