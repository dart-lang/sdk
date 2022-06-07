// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.17

/*member: main:**/
void main() {
  final x1 = XX();
  x1.assignUseBar();
  x1.assignUseFoo();
  x1.useBar();
  x1.useFoo();
}

class XX {
  late int foo;
  late final int bar;

  @pragma('dart2js:noInline')
  /*member: XX.useFoo:
      SsaLateFieldOptimizer.pre=[HFieldGet=3,HLateReadCheck=3],
      SsaLateFieldOptimizer.post=[HFieldGet=3,HLateReadCheck=1],
  */
  void useFoo() {
    use(foo, foo, effect(), foo, foo, effect(), foo, foo);
  }

  @pragma('dart2js:noInline')
  /*member: XX.useBar:
      SsaLateFieldOptimizer.pre=[HFieldGet=3,HLateReadCheck=3],
      SsaLateFieldOptimizer.post=[HFieldGet=1,HLateReadCheck=1],
  */
  void useBar() {
    use(bar, bar, effect(), bar, bar, effect(), bar, bar);
  }

  @pragma('dart2js:noInline')
  /*member: XX.assignUseFoo:
      SsaLateFieldOptimizer.pre=[HFieldGet=3,HLateReadCheck=3],
      SsaLateFieldOptimizer.post=[HFieldGet=3],
  */
  void assignUseFoo() {
    foo = 200;
    use(effect(), foo, effect(), foo, foo, effect(), foo, foo);
  }

  @pragma('dart2js:noInline')
  /*member: XX.assignUseBar:
      SsaLateFieldOptimizer.pre=
          [HFieldGet=4,HLateReadCheck=3,HLateWriteOnceCheck=1],
      SsaLateFieldOptimizer.post=[HFieldGet=1,HLateWriteOnceCheck=1],
  */
  void assignUseBar() {
    bar = 100;
    use(effect(), bar, effect(), bar, bar, effect(), bar, bar);
  }

  @pragma('dart2js:noInline')
  /*member: XX.use:**/
  void use(int a1, int a2, int a3, int a4, int a5, int a6, int a7, int a8) {
    print([a1, a2, a3, a4, a5, a6, a7, a8]);
  }

  @pragma('dart2js:noInline')
  /*member: XX.effect:**/
  int effect() {
    foo++;
    return 0;
  }
}
