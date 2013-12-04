// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analyze_dart2js;

import "package:expect/expect.dart";
import '../../../sdk/lib/_internal/compiler/implementation/filenames.dart';
import 'analyze_helper.dart';
import "package:async_helper/async_helper.dart";

/**
 * Map of whitelisted warnings and errors.
 *
 * Only add a whitelisting together with a bug report to dartbug.com and add
 * the bug issue number as a comment on the whitelisting.
 *
 * Use an identifiable suffix of the file uri as key. Use a fixed substring of
 * the error/warning message in the list of whitelistings for each file.
 */
// TODO(johnniwinther): Support canonical URIs as keys and message kinds as
// values.
const Map<String,List<String>> WHITE_LIST = const {
  // The following notices go away when bug 15418 is fixed.
  "sdk/lib/_collection_dev/iterable.dart": const [
      "Info: This is the method declaration."],

  "sdk/lib/_internal/lib/interceptors.dart": const [
      "Info: This is the method declaration."],

  "sdk/lib/core/iterable.dart": const [
      "Info: This is the method declaration."],

  "sdk/lib/core/list.dart": const [
      "Info: This is the method declaration."],

  // Bug 15418.
  "sdk/lib/typed_data/dart2js/typed_data_dart2js.dart": const ["""
Warning: 'Uint64List' doesn't implement '[]'.
Try adding an implementation of '[]'.""", """
Warning: 'Uint64List' doesn't implement '[]='.
Try adding an implementation of '[]='.""", """
Warning: 'Uint64List' doesn't implement 'length'.
Try adding an implementation of 'length'.""", """
Warning: 'Uint64List' doesn't implement 'length'.
Try adding an implementation of 'length'.""", """
Warning: 'Uint64List' doesn't implement 'add'.
Try adding an implementation of 'add'.""", """
Warning: 'Uint64List' doesn't implement 'addAll'.
Try adding an implementation of 'addAll'.""", """
Warning: 'Uint64List' doesn't implement 'reversed'.
Try adding an implementation of 'reversed'.""", """
Warning: 'Uint64List' doesn't implement 'sort'.
Try adding an implementation of 'sort'.""", """
Warning: 'Uint64List' doesn't implement 'shuffle'.
Try adding an implementation of 'shuffle'.""", """
Warning: 'Uint64List' doesn't implement 'indexOf'.
Try adding an implementation of 'indexOf'.""", """
Warning: 'Uint64List' doesn't implement 'lastIndexOf'.
Try adding an implementation of 'lastIndexOf'.""", """
Warning: 'Uint64List' doesn't implement 'clear'.
Try adding an implementation of 'clear'.""", """
Warning: 'Uint64List' doesn't implement 'insert'.
Try adding an implementation of 'insert'.""", """
Warning: 'Uint64List' doesn't implement 'insertAll'.
Try adding an implementation of 'insertAll'.""", """
Warning: 'Uint64List' doesn't implement 'setAll'.
Try adding an implementation of 'setAll'.""", """
Warning: 'Uint64List' doesn't implement 'remove'.
Try adding an implementation of 'remove'.""", """
Warning: 'Uint64List' doesn't implement 'removeAt'.
Try adding an implementation of 'removeAt'.""", """
Warning: 'Uint64List' doesn't implement 'removeLast'.
Try adding an implementation of 'removeLast'.""", """
Warning: 'Uint64List' doesn't implement 'removeWhere'.
Try adding an implementation of 'removeWhere'.""", """
Warning: 'Uint64List' doesn't implement 'retainWhere'.
Try adding an implementation of 'retainWhere'.""", """
Warning: 'Uint64List' doesn't implement 'sublist'.
Try adding an implementation of 'sublist'.""", """
Warning: 'Uint64List' doesn't implement 'getRange'.
Try adding an implementation of 'getRange'.""", """
Warning: 'Uint64List' doesn't implement 'setRange'.
Try adding an implementation of 'setRange'.""", """
Warning: 'Uint64List' doesn't implement 'removeRange'.
Try adding an implementation of 'removeRange'.""", """
Warning: 'Uint64List' doesn't implement 'fillRange'.
Try adding an implementation of 'fillRange'.""", """
Warning: 'Uint64List' doesn't implement 'replaceRange'.
Try adding an implementation of 'replaceRange'.""", """
Warning: 'Uint64List' doesn't implement 'asMap'.
Try adding an implementation of 'asMap'.""", """
Warning: 'Uint64List' doesn't implement 'length'.
Try adding an implementation of 'length'.""", """
Warning: 'Uint64List' doesn't implement 'iterator'.
Try adding an implementation of 'iterator'.""", """
Warning: 'Uint64List' doesn't implement 'map'.
Try adding an implementation of 'map'.""", """
Warning: 'Uint64List' doesn't implement 'where'.
Try adding an implementation of 'where'.""", """
Warning: 'Uint64List' doesn't implement 'expand'.
Try adding an implementation of 'expand'.""", """
Warning: 'Uint64List' doesn't implement 'contains'.
Try adding an implementation of 'contains'.""", """
Warning: 'Uint64List' doesn't implement 'forEach'.
Try adding an implementation of 'forEach'.""", """
Warning: 'Uint64List' doesn't implement 'reduce'.
Try adding an implementation of 'reduce'.""", """
Warning: 'Uint64List' doesn't implement 'fold'.
Try adding an implementation of 'fold'.""", """
Warning: 'Uint64List' doesn't implement 'every'.
Try adding an implementation of 'every'.""", """
Warning: 'Uint64List' doesn't implement 'any'.
Try adding an implementation of 'any'.""", """
Warning: 'Uint64List' doesn't implement 'toList'.
Try adding an implementation of 'toList'.""", """
Warning: 'Uint64List' doesn't implement 'toSet'.
Try adding an implementation of 'toSet'.""", """
Warning: 'Uint64List' doesn't implement 'length'.
Try adding an implementation of 'length'.""", """
Warning: 'Uint64List' doesn't implement 'isEmpty'.
Try adding an implementation of 'isEmpty'.""", """
Warning: 'Uint64List' doesn't implement 'isNotEmpty'.
Try adding an implementation of 'isNotEmpty'.""", """
Warning: 'Uint64List' doesn't implement 'take'.
Try adding an implementation of 'take'.""", """
Warning: 'Uint64List' doesn't implement 'takeWhile'.
Try adding an implementation of 'takeWhile'.""", """
Warning: 'Uint64List' doesn't implement 'skip'.
Try adding an implementation of 'skip'.""", """
Warning: 'Uint64List' doesn't implement 'skipWhile'.
Try adding an implementation of 'skipWhile'.""", """
Warning: 'Uint64List' doesn't implement 'first'.
Try adding an implementation of 'first'.""", """
Warning: 'Uint64List' doesn't implement 'last'.
Try adding an implementation of 'last'.""", """
Warning: 'Uint64List' doesn't implement 'single'.
Try adding an implementation of 'single'.""", """
Warning: 'Uint64List' doesn't implement 'firstWhere'.
Try adding an implementation of 'firstWhere'.""", """
Warning: 'Uint64List' doesn't implement 'lastWhere'.
Try adding an implementation of 'lastWhere'.""", """
Warning: 'Uint64List' doesn't implement 'singleWhere'.
Try adding an implementation of 'singleWhere'.""", """
Warning: 'Uint64List' doesn't implement 'elementAt'.
Try adding an implementation of 'elementAt'.""", """
Warning: 'Uint64List' doesn't implement '[]='.
Try adding an implementation of '[]='.""", """
Warning: 'Uint64List' doesn't implement 'length'.
Try adding an implementation of 'length'.""", """
Warning: 'Uint64List' doesn't implement '[]'.
Try adding an implementation of '[]'.""", """
Warning: 'Int64List' doesn't implement '[]'.
Try adding an implementation of '[]'.""", """
Warning: 'Int64List' doesn't implement '[]='.
Try adding an implementation of '[]='.""", """
Warning: 'Int64List' doesn't implement 'length'.
Try adding an implementation of 'length'.""", """
Warning: 'Int64List' doesn't implement 'length'.
Try adding an implementation of 'length'.""", """
Warning: 'Int64List' doesn't implement 'add'.
Try adding an implementation of 'add'.""", """
Warning: 'Int64List' doesn't implement 'addAll'.
Try adding an implementation of 'addAll'.""", """
Warning: 'Int64List' doesn't implement 'reversed'.
Try adding an implementation of 'reversed'.""", """
Warning: 'Int64List' doesn't implement 'sort'.
Try adding an implementation of 'sort'.""", """
Warning: 'Int64List' doesn't implement 'shuffle'.
Try adding an implementation of 'shuffle'.""", """
Warning: 'Int64List' doesn't implement 'indexOf'.
Try adding an implementation of 'indexOf'.""", """
Warning: 'Int64List' doesn't implement 'lastIndexOf'.
Try adding an implementation of 'lastIndexOf'.""", """
Warning: 'Int64List' doesn't implement 'clear'.
Try adding an implementation of 'clear'.""", """
Warning: 'Int64List' doesn't implement 'insert'.
Try adding an implementation of 'insert'.""", """
Warning: 'Int64List' doesn't implement 'insertAll'.
Try adding an implementation of 'insertAll'.""", """
Warning: 'Int64List' doesn't implement 'setAll'.
Try adding an implementation of 'setAll'.""", """
Warning: 'Int64List' doesn't implement 'remove'.
Try adding an implementation of 'remove'.""", """
Warning: 'Int64List' doesn't implement 'removeAt'.
Try adding an implementation of 'removeAt'.""", """
Warning: 'Int64List' doesn't implement 'removeLast'.
Try adding an implementation of 'removeLast'.""", """
Warning: 'Int64List' doesn't implement 'removeWhere'.
Try adding an implementation of 'removeWhere'.""", """
Warning: 'Int64List' doesn't implement 'retainWhere'.
Try adding an implementation of 'retainWhere'.""", """
Warning: 'Int64List' doesn't implement 'sublist'.
Try adding an implementation of 'sublist'.""", """
Warning: 'Int64List' doesn't implement 'getRange'.
Try adding an implementation of 'getRange'.""", """
Warning: 'Int64List' doesn't implement 'setRange'.
Try adding an implementation of 'setRange'.""", """
Warning: 'Int64List' doesn't implement 'removeRange'.
Try adding an implementation of 'removeRange'.""", """
Warning: 'Int64List' doesn't implement 'fillRange'.
Try adding an implementation of 'fillRange'.""", """
Warning: 'Int64List' doesn't implement 'replaceRange'.
Try adding an implementation of 'replaceRange'.""", """
Warning: 'Int64List' doesn't implement 'asMap'.
Try adding an implementation of 'asMap'.""", """
Warning: 'Int64List' doesn't implement 'length'.
Try adding an implementation of 'length'.""", """
Warning: 'Int64List' doesn't implement 'iterator'.
Try adding an implementation of 'iterator'.""", """
Warning: 'Int64List' doesn't implement 'map'.
Try adding an implementation of 'map'.""", """
Warning: 'Int64List' doesn't implement 'where'.
Try adding an implementation of 'where'.""", """
Warning: 'Int64List' doesn't implement 'expand'.
Try adding an implementation of 'expand'.""", """
Warning: 'Int64List' doesn't implement 'contains'.
Try adding an implementation of 'contains'.""", """
Warning: 'Int64List' doesn't implement 'forEach'.
Try adding an implementation of 'forEach'.""", """
Warning: 'Int64List' doesn't implement 'reduce'.
Try adding an implementation of 'reduce'.""", """
Warning: 'Int64List' doesn't implement 'fold'.
Try adding an implementation of 'fold'.""", """
Warning: 'Int64List' doesn't implement 'every'.
Try adding an implementation of 'every'.""", """
Warning: 'Int64List' doesn't implement 'any'.
Try adding an implementation of 'any'.""", """
Warning: 'Int64List' doesn't implement 'toList'.
Try adding an implementation of 'toList'.""", """
Warning: 'Int64List' doesn't implement 'toSet'.
Try adding an implementation of 'toSet'.""", """
Warning: 'Int64List' doesn't implement 'length'.
Try adding an implementation of 'length'.""", """
Warning: 'Int64List' doesn't implement 'isEmpty'.
Try adding an implementation of 'isEmpty'.""", """
Warning: 'Int64List' doesn't implement 'isNotEmpty'.
Try adding an implementation of 'isNotEmpty'.""", """
Warning: 'Int64List' doesn't implement 'take'.
Try adding an implementation of 'take'.""", """
Warning: 'Int64List' doesn't implement 'takeWhile'.
Try adding an implementation of 'takeWhile'.""", """
Warning: 'Int64List' doesn't implement 'skip'.
Try adding an implementation of 'skip'.""", """
Warning: 'Int64List' doesn't implement 'skipWhile'.
Try adding an implementation of 'skipWhile'.""", """
Warning: 'Int64List' doesn't implement 'first'.
Try adding an implementation of 'first'.""", """
Warning: 'Int64List' doesn't implement 'last'.
Try adding an implementation of 'last'.""", """
Warning: 'Int64List' doesn't implement 'single'.
Try adding an implementation of 'single'.""", """
Warning: 'Int64List' doesn't implement 'firstWhere'.
Try adding an implementation of 'firstWhere'.""", """
Warning: 'Int64List' doesn't implement 'lastWhere'.
Try adding an implementation of 'lastWhere'.""", """
Warning: 'Int64List' doesn't implement 'singleWhere'.
Try adding an implementation of 'singleWhere'.""", """
Warning: 'Int64List' doesn't implement 'elementAt'.
Try adding an implementation of 'elementAt'.""", """
Warning: 'Int64List' doesn't implement '[]='.
Try adding an implementation of '[]='.""", """
Warning: 'Int64List' doesn't implement 'length'.
Try adding an implementation of 'length'.""", """
Warning: 'Int64List' doesn't implement '[]'.
Try adding an implementation of '[]'."""],
};

void main() {
  var uri = currentDirectory.resolve(
      'sdk/lib/_internal/compiler/implementation/dart2js.dart');
  asyncTest(() => analyze([uri], WHITE_LIST));
}
