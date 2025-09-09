// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';

const nullConst = null;

const intConst = 0;

const stringConst = "";

const list1 = <Object?>[nullConst, intConst, stringConst];

const list2 = <Object?>[?nullConst, intConst, stringConst];

const list3 = <Object?>[null, nullConst, intConst, stringConst];

const list4 = <Object?>[?null, ?nullConst, intConst, stringConst];

const list5 = <Object?>[
  nullConst,
  intConst,
  stringConst,
  nullConst,
  intConst,
  stringConst,
];

const list6 = <Object?>[
  ?nullConst,
  intConst,
  stringConst,
  ?nullConst,
  intConst,
  stringConst,
];

const list7 = <Object?>[
  null,
  nullConst,
  intConst,
  stringConst,
  null,
  nullConst,
  intConst,
  stringConst,
];

const list8 = <Object?>[
  ?null,
  ?nullConst,
  intConst,
  stringConst,
  ?null,
  ?nullConst,
  intConst,
  stringConst,
];

const set1 = <Object?>{nullConst, intConst, stringConst};

const set2 = <Object?>{?nullConst, intConst, stringConst};

const set3 = <Object?>{?null, intConst, stringConst};

const set4 = <Object?>{?null, ?nullConst, intConst, stringConst};

const map1 = <Object?, Object?>{nullConst: 1, intConst: 1, stringConst: 1};

const map2 = <Object?, Object?>{?nullConst: 1, intConst: 1, stringConst: 1};

const map3 = <Object?, Object?>{?null: 1, intConst: 1, stringConst: 1};

const map4 = <Object?, Object?>{
  ?null: 1,
  ?nullConst: 1,
  intConst: 1,
  stringConst: 1,
};

const map5 = <Object?, Object?>{
  null: 1,
  ?nullConst: 1,
  intConst: 1,
  stringConst: 1,
};

const map6 = <Object?, Object?>{
  ?null: 1,
  nullConst: 1,
  intConst: 1,
  stringConst: 1,
};

const map7 = <Object?, Object?>{
  null: 1,
  nullConst: ?nullConst,
  intConst: 1,
  stringConst: 1,
};

const map8 = <Object?, Object?>{
  null: ?null,
  nullConst: nullConst,
  intConst: 1,
  stringConst: 1,
};

const map9 = <Object?, Object?>{?null: null, nullConst: ?nullConst, null: null};

main() {
  Expect.identical(list1, const <Object?>[null, 0, ""]);
  Expect.identical(list2, const <Object?>[0, ""]);
  Expect.identical(list3, const <Object?>[null, null, 0, ""]);
  Expect.identical(list4, const <Object?>[0, ""]);
  Expect.identical(list5, const <Object?>[null, 0, "", null, 0, ""]);
  Expect.identical(list6, const <Object?>[0, "", 0, ""]);
  Expect.identical(list7, const <Object?>[
    null,
    null,
    0,
    "",
    null,
    null,
    0,
    "",
  ]);
  Expect.identical(list8, const <Object?>[0, "", 0, ""]);

  Expect.identical(set1, const <Object?>{null, 0, ""});
  Expect.identical(set2, const <Object?>{0, ""});
  Expect.identical(set3, const <Object?>{0, ""});
  Expect.identical(set4, const <Object?>{0, ""});

  Expect.identical(map1, const <Object?, Object?>{null: 1, 0: 1, "": 1});
  Expect.identical(map2, const <Object?, Object?>{0: 1, "": 1});
  Expect.identical(map3, const <Object?, Object?>{0: 1, "": 1});
  Expect.identical(map4, const <Object?, Object?>{0: 1, "": 1});
  Expect.identical(map5, const <Object?, Object?>{null: 1, 0: 1, "": 1});
  Expect.identical(map6, const <Object?, Object?>{null: 1, 0: 1, "": 1});
  Expect.identical(map7, const <Object?, Object?>{null: 1, 0: 1, "": 1});
  Expect.identical(map8, const <Object?, Object?>{null: null, 0: 1, "": 1});
  Expect.identical(map9, const <Object?, Object?>{null: null});
}
