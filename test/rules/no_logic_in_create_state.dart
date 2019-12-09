// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// test w/ `pub run test -N no_logic_in_create_state`


import 'package:flutter/widgets.dart';

class MyState extends State {
  int field;
}

class MyStatefulOK extends StatefulWidget {
  @override
  MyState createState() {
    return MyState();
  }
}

class MyStatefulOK2 extends StatefulWidget {
  @override
  MyState createState() => MyState();
}


MyState global;

class MyStatefulBad extends StatefulWidget {
  @override
  MyState createState() { // LINT
    // ignore: join_return_with_assignment
    global = MyState();
    return global;
  }
}

class MyStatefulBad2 extends StatefulWidget {
  MyState instance = MyState();
  @override
  MyState createState() {
    return instance; // LINT
  }
}

class MyStatefulBad3 extends StatefulWidget {
  @override
  MyState createState() {
    return MyState()..field = 0; // LINT
  }
}

class MyStatefulBad4 extends StatefulWidget {
  @override
  MyState createState() =>
    MyState()..field = 0; // LINT
}

class MyState2 extends State {
  int field;
  MyState2(this.field);
}

class MyStatefulBad5 extends StatefulWidget {
  @override
  MyState2 createState() => MyState2(1); // LINT
}
