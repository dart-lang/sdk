// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * This is a library that provides messages for a German locale. All the
 * messages from the main program should be duplicated here with the same
 * function name. Note that the library name is significant, as it's looked
 * up based on a naming convention.
 */

#library('messages_de');
#import('../../lib/intl.dart');

runAt(time, day) => Intl.message('Ausgedruckt am $time am $day.', name: 'runAt',
    args: [time, day]);
