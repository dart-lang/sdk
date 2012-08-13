// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#library('dart:core');

#import('coreimpl.dart');

#import('js_helper.dart'); // TODO(ahe): remove this import.

#source('../../../../corelib/src/bool.dart');
#source('../../../../corelib/src/collection.dart');
#source('../../../../corelib/src/comparable.dart');
#source('../../../../corelib/unified/core/date.dart');
#source('../../../../corelib/src/double.dart');
#source('../../../../corelib/src/duration.dart');
#source('../../../../corelib/src/exceptions.dart');
#source('../../../../corelib/unified/core/expando.dart');
#source('../../../../corelib/src/expect.dart');
#source('../../../../corelib/src/function.dart');
#source('../../../../corelib/src/future.dart');
#source('../../../../corelib/src/hashable.dart');
#source('../../../../corelib/src/int.dart');
#source('../../../../corelib/src/iterable.dart');
#source('../../../../corelib/src/iterator.dart');
#source('../../../../corelib/src/list.dart');
#source('../../../../corelib/src/map.dart');
#source('../../../../corelib/src/math.dart');
#source('../../../../corelib/src/num.dart');
#source('../../../../corelib/src/options.dart');
#source('../../../../corelib/src/pattern.dart');
#source('../../../../corelib/src/queue.dart');
#source('../../../../corelib/src/regexp.dart');
#source('../../../../corelib/src/set.dart');
#source('../../../../corelib/src/stopwatch.dart');
#source('../../../../corelib/src/string.dart');
#source('../../../../corelib/src/string_buffer.dart');
#source('../../../../corelib/src/strings.dart');
#source('mock.dart');

void print(var obj) {
  if (obj is String) {
    Primitives.printString(obj);
  } else {
    Primitives.printString(obj.toString());
  }
}

class Object {
  String toString() => Primitives.objectToString(this);

  void noSuchMethod(String name, List args) {
    throw new NoSuchMethodException(this, name, args);
  }
}
