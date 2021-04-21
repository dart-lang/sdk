// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:meta/meta.dart';

class Navigator extends StatefulWidget {
  static NavigatorState of(
    BuildContext context, {
    bool rootNavigator = false,
    bool nullOk = false,
  }) =>
      null;

  @optionalTypeArgs
  static Future<T> pushNamed<T extends Object?>(
    BuildContext context,
    String routeName, {
    Object? arguments,
  }) =>
      null;

  @optionalTypeArgs
  static Future<T> pushReplacementNamed<T extends Object?, TO extends Object?>(
    BuildContext context,
    String routeName, {
    TO result,
    Object arguments,
  }) =>
      null;

  @optionalTypeArgs
  static Future<T> pushNamedAndRemoveUntil<T extends Object>(
    BuildContext context,
    String newRouteName,
    RoutePredicate predicate, {
    Object arguments,
  }) =>
      null;

  @optionalTypeArgs
  static Future<T> push<T extends Object>(
          BuildContext context, Route<T> route) =>
      null;
  @optionalTypeArgs
  static Future<T> pushReplacement<T extends Object, TO extends Object>(
          BuildContext context, Route<T> newRoute,
          {TO result}) =>
      null;

  @optionalTypeArgs
  static Future<T> pushAndRemoveUntil<T extends Object>(
          BuildContext context, Route<T> newRoute, RoutePredicate predicate) =>
      null;

  @optionalTypeArgs
  static Future<bool> maybePop<T extends Object>(BuildContext context,
          [T result]) =>
      null;

  @optionalTypeArgs
  static Future<T> popAndPushNamed<T extends Object, TO extends Object>(
    BuildContext context,
    String routeName, {
    TO result,
    Object arguments,
  }) =>
      null;
}

class NavigatorState extends State<Navigator> {
  @optionalTypeArgs
  Future<T> pushNamed<T extends Object>(
    String routeName, {
    Object arguments,
  }) =>
      null;

  @optionalTypeArgs
  Future<T> pushReplacementNamed<T extends Object, TO extends Object>(
    String routeName, {
    TO result,
    Object arguments,
  }) =>
      null;

  @optionalTypeArgs
  Future<T> popAndPushNamed<T extends Object, TO extends Object>(
    String routeName, {
    TO result,
    Object arguments,
  }) =>
      null;

  @optionalTypeArgs
  Future<T> pushNamedAndRemoveUntil<T extends Object>(
    String newRouteName,
    RoutePredicate predicate, {
    Object arguments,
  }) =>
      null;

  @optionalTypeArgs
  Future<T> push<T extends Object>(Route<T> route) => null;

  @optionalTypeArgs
  Future<T> pushReplacement<T extends Object, TO extends Object>(
          Route<T> newRoute,
          {TO result}) =>
      null;

  @optionalTypeArgs
  Future<T> pushAndRemoveUntil<T extends Object>(
          Route<T> newRoute, RoutePredicate predicate) =>
      null;

  @optionalTypeArgs
  Future<bool> maybePop<T extends Object>([T result]) async => null;
}

typedef RoutePredicate = bool Function(Route<dynamic> route);

abstract class Route<T> {}
