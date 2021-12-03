// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'shared.dart';

/*member: step:member_unit=1{step1, step2a, step2b, step3}*/
step() => [
      step12a(),
      step12b(),
      step13(),
      step12ab(),
      step12a3(),
      step12b3(),
      step12ab3(),
    ];
