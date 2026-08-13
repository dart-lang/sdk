// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// VMOptions=--profiler --profile-vm=true
// VMOptions=--profiler --profile-vm=false

main() {
  for (var i = 0; i < 100; i++) {
    foo1();
  }
}

@pragma("vm:never-inline")
foo1() => foo2();
@pragma("vm:never-inline")
foo2() => foo3();
@pragma("vm:never-inline")
foo3() => foo4();
@pragma("vm:never-inline")
foo4() => foo5();
@pragma("vm:never-inline")
foo5() => foo6();
@pragma("vm:never-inline")
foo6() => foo7();
@pragma("vm:never-inline")
foo7() => foo8();
@pragma("vm:never-inline")
foo8() => foo9();
@pragma("vm:never-inline")
foo9() => foo10();
@pragma("vm:never-inline")
foo10() => foo11();
@pragma("vm:never-inline")
foo11() => foo12();
@pragma("vm:never-inline")
foo12() => foo13();
@pragma("vm:never-inline")
foo13() => foo14();
@pragma("vm:never-inline")
foo14() => foo15();
@pragma("vm:never-inline")
foo15() => foo16();
@pragma("vm:never-inline")
foo16() => foo17();
@pragma("vm:never-inline")
foo17() => foo18();
@pragma("vm:never-inline")
foo18() => foo19();
@pragma("vm:never-inline")
foo19() => foo20();
@pragma("vm:never-inline")
foo20() => foo21();
@pragma("vm:never-inline")
foo21() => foo22();
@pragma("vm:never-inline")
foo22() => foo23();
@pragma("vm:never-inline")
foo23() => foo24();
@pragma("vm:never-inline")
foo24() => foo25();
@pragma("vm:never-inline")
foo25() => foo26();
@pragma("vm:never-inline")
foo26() => foo27();
@pragma("vm:never-inline")
foo27() => foo28();
@pragma("vm:never-inline")
foo28() => foo29();
@pragma("vm:never-inline")
foo29() => foo30();
@pragma("vm:never-inline")
foo30() => foo31();
@pragma("vm:never-inline")
foo31() => foo32();
@pragma("vm:never-inline")
foo32() => foo33();
@pragma("vm:never-inline")
foo33() => foo34();
@pragma("vm:never-inline")
foo34() => foo35();
@pragma("vm:never-inline")
foo35() => foo36();
@pragma("vm:never-inline")
foo36() => foo37();
@pragma("vm:never-inline")
foo37() => foo38();
@pragma("vm:never-inline")
foo38() => foo39();
@pragma("vm:never-inline")
foo39() => foo40();
@pragma("vm:never-inline")
foo40() => foo41();
@pragma("vm:never-inline")
foo41() => foo42();
@pragma("vm:never-inline")
foo42() => foo43();
@pragma("vm:never-inline")
foo43() => foo44();
@pragma("vm:never-inline")
foo44() => foo45();
@pragma("vm:never-inline")
foo45() => foo46();
@pragma("vm:never-inline")
foo46() => foo47();
@pragma("vm:never-inline")
foo47() => foo48();
@pragma("vm:never-inline")
foo48() => foo49();
@pragma("vm:never-inline")
foo49() => foo50();
@pragma("vm:never-inline")
foo50() => foo51();
@pragma("vm:never-inline")
foo51() => foo52();
@pragma("vm:never-inline")
foo52() => foo53();
@pragma("vm:never-inline")
foo53() => foo54();
@pragma("vm:never-inline")
foo54() => foo55();
@pragma("vm:never-inline")
foo55() => foo56();
@pragma("vm:never-inline")
foo56() => foo57();
@pragma("vm:never-inline")
foo57() => foo58();
@pragma("vm:never-inline")
foo58() => foo59();
@pragma("vm:never-inline")
foo59() => foo60();
@pragma("vm:never-inline")
foo60() => foo61();
@pragma("vm:never-inline")
foo61() => foo62();
@pragma("vm:never-inline")
foo62() => foo63();
@pragma("vm:never-inline")
foo63() => foo64();

int global = 0;
@pragma("vm:never-inline")
foo64() {
  for (int i = 0; i < 1000000; i++) {
    global = global ^ (global + i);
  }
}
