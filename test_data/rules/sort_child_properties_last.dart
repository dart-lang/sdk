// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// test w/ `dart test -N sort_child_properties_last`

// ignore_for_file: prefer_expression_function_bodies

import 'package:flutter/widgets.dart';

class W0 extends Widget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Center(), // OK
      ),
    );
  }
}

class W1 extends Widget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Center(), // LINT
        key: 0,
      ),
    );
  }
}

class W2 extends Widget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        key: 0,
        child: Center(), // OK
      ),
    );
  }
}

class W3 extends Widget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        key: 0,
        child: Center(
          child: Column(
            key: 0,
            children: [], // OK
          ),
        ),
      ),
    );
  }
}

class W4 extends Widget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        key: 0,
        child: Center(
          child: Column(
            children: [], // LINT
            key: 0,
          ),
        ),
      ),
    );
  }
}

/// see: https://dart-review.googlesource.com/c/sdk/+/161624
nestedChildren() {
  Column(
    children: [ // LINT
      Column(
        children: [ // LINT
          Text('a'),
        ],
        crossAxisAlignment: CrossAxisAlignment.center,
      ),
      Text('b'),
      Text('c'),
      Text('d'),
    ],
    crossAxisAlignment: CrossAxisAlignment.center,
  );
}

class WithClosure extends Widget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        key: 0,
        child: Center( // OK
          child: Column(
            key: 0,
            children: [],
          ),
        ),
        onPress: () {
          // some code
        },
      ),
    );
  }
}

class WithSeveralWidgetCreation extends Widget {
  WithSeveralWidgetCreation({
    this.header,
    this.child,
    this.boldFooter,
    this.onFooterClick,
    this.footer,
  });
  final Widget? header;
  final Widget? child;
  final bool? boldFooter;
  final void Function()? onFooterClick;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    WithSeveralWidgetCreation(
      header: Text('a'),
      child: Text('b'), // OK
      footer: Text('c'), // LINT
      boldFooter: true,
    );
    WithSeveralWidgetCreation(
      header: Text('a'),
      child: Text('b'), // OK
      footer: Text('c'), // OK
      onFooterClick: (){},
    );
    return null;
  }
}
