// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.serialization_test_data;

const List<Test> TESTS = const <Test>[
  const Test(const {
    'main.dart': 'main() {}'
  }),

  const Test(const {
    'main.dart': 'main() => print("Hello World");'
  }),

  const Test(const {
    'main.dart': 'main() => print("Hello World", 0);'
  },
  expectedWarningCount: 1,
  expectedInfoCount: 1),

  const Test(const {
    'main.dart': r'''
main() {
  String text = "Hello World";
  print('$text');
}'''
  }),

  const Test(const {
    'main.dart': r'''
main() {
  String text = "Hello World";
  print('$text', text);
}'''
  },
  expectedWarningCount: 1,
  expectedInfoCount: 1),

  const Test(const {
    'main.dart': r'''
main(List<String> arguments) {
  print(arguments);
}'''
  }),

  const Test(const {
      'main.dart': r'''
main(List<String> arguments) {
  for (int i = 0; i < arguments.length; i++) {
    print(arguments[i]);
  }
}'''
    }),

  const Test(const {
    'main.dart': r'''
main(List<String> arguments) {
  for (String argument in arguments) {
    print(argument);
  }
}'''
  }),

  const Test(const {
    'main.dart': r'''
class Class {}
main() {
  print(new Class());
}'''
  }),

  const Test(const {
    'main.dart': r'''
class Class implements Function {}
main() {
  print(new Class());
}'''
  },
  expectedWarningCount: 1),

  const Test(const {
    'main.dart': r'''
class Class implements Function {
  call() {}
}
main() {
  print(new Class()());
}'''
  }),

  const Test(const {
    'main.dart': r'''
class Class implements Comparable<Class> {
  int compareTo(Class other) => 0;
}
main() {
  print(new Class());
}'''
  }),

  const Test(const {
    'main.dart': r'''
class Class implements Comparable<Class, Class> {
  int compareTo(other) => 0;
}
main() {
  print(new Class());
}'''
  },
  expectedWarningCount: 1),

  const Test(const {
    'main.dart': r'''
class Class implements Comparable<Class> {
  int compareTo(String other) => 0;
}
main() {
  print(new Class().compareTo(null));
}'''
  },
  expectedWarningCount: 1,
  expectedInfoCount: 1),

  const Test(const {
    'main.dart': r'''
class Class implements Comparable {
  bool compareTo(a, b) => true;
}
main() {
  print(new Class().compareTo(null, null));
}'''
  },
  expectedWarningCount: 1,
  expectedInfoCount: 1),

  const Test(const {
    'main.dart': r'''
import 'dart:math';

class MyRandom implements Random {
  int nextInt(int max) {
    return max.length;
  }
  bool nextBool() => true;
  double nextDouble() => 0.0;
}
main() {
  new MyRandom().nextInt(0);
}'''
  },
  expectedWarningCount: 1,
  expectedInfoCount: 0),

  const Test(const {
    'main.dart': r'''
import 'dart:math';

class MyRandom implements Random {
  int nextInt(int max) {
    return max.length;
  }
  bool nextBool() => true;
  double nextDouble() => 0.0;
}
main() {
  new MyRandom();
}'''
  }),

  const Test(const {
    'main.dart': r'''
import 'dart:math';

class MyRandom implements Random {
  int nextInt(int max) {
    return max.length;
  }
  bool nextBool() => true;
  double nextDouble() => 0.0;
}
main() {
  // Invocation of `MyRandom.nextInt` is only detected knowing the actual 
  // implementation class for `List` and the world impact of its `shuffle` 
  // method.  
  [].shuffle(new MyRandom());
}'''
  },
  expectedWarningCount: 1,
  expectedInfoCount: 0),

  const Test(const {
    'main.dart': '''
main() {
  loop: for (var a in []) {
    for (var b in []) {
      continue loop;
    }
    break;
  }      
}'''
  }),

];

class Test {
  final Map sourceFiles;
  final int expectedErrorCount;
  final int expectedWarningCount;
  final int expectedHintCount;
  final int expectedInfoCount;

  const Test(this.sourceFiles, {
    this.expectedErrorCount: 0,
    this.expectedWarningCount: 0,
    this.expectedHintCount: 0,
    this.expectedInfoCount: 0});
}
