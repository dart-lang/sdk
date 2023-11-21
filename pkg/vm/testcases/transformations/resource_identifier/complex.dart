// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'package:meta/meta.dart' show ResourceIdentifier;

void main() {
  print(OtherClass().someMethod(argument: 'argument!'));
}

class OtherClass {
  final AssetBundle bundle = AssetBundle();

  String string = 'somestring';

  AnotherClass object = AnotherClass();

  Future<String> someMethod({required String argument}) async {
    return await generate(
      bundle,
      [argument],
      string,
      object,
      42,
    );
  }

  @ResourceIdentifier('myresourceid')
  static Future<String> generate(AssetBundle bundle, List args, String string,
      AnotherClass object, int index) async {
    final message = await bundle.byIndex(string: string, index: index);
    return message.generateString(args, object: object);
  }
}

class AssetBundle {
  Message byIndex({required String string, required int index}) {
    return Message();
  }
}

class Message {
  Future<String> generateString(List args,
      {required AnotherClass object}) async {
    return args.firstOrNull.toString();
  }
}

class SomeClass {}

class AnotherClass {}
