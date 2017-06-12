// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of base;

// TODO(jacobr): cache these results.
// TODO(jacobr): figure out how to test this.
/**
 * Utils for device detection.
 */
class Device {
  /**
   * The regular expression for detecting an iPhone or iPod.
   */
  static final _IPHONE_REGEX = new RegExp('iPhone|iPod');

  /**
   * The regular expression for detecting an iPhone or iPod or iPad.
   */
  static final _MOBILE_SAFARI_REGEX = new RegExp('iPhone|iPod|iPad');

  /**
   * The regular expression for detecting an iPhone or iPod or iPad simulator.
   */
  static final _APPLE_SIM_REGEX = new RegExp('iP.*Simulator');

  /**
   * Gets the browser's user agent. Using this function allows tests to inject
   * the user agent.
   * Returns the user agent.
   */
  static String get userAgent => window.navigator.userAgent;

  /**
   * Determines if the current device is an iPhone or iPod.
   * Returns true if the current device is an iPhone or iPod.
   */
  static bool get isIPhone => _IPHONE_REGEX.hasMatch(userAgent);

  /**
   * Determines if the current device is an iPad.
   * Returns true if the current device is an iPad.
   */
  static bool get isIPad => userAgent.contains("iPad", 0);

  /**
   * Determines if the current device is running Firefox.
   */
  static bool get isFirefox => userAgent.contains("Firefox", 0);

  /**
   * Determines if the current device is an iPhone or iPod or iPad.
   * Returns true if the current device is an iPhone or iPod or iPad.
   */
  static bool get isMobileSafari => _MOBILE_SAFARI_REGEX.hasMatch(userAgent);

  /**
   * Determines if the current device is the iP* Simulator.
   * Returns true if the current device is an iP* Simulator.
   */
  static bool get isAppleSimulator => _APPLE_SIM_REGEX.hasMatch(userAgent);

  /**
   * Determines if the current device is an Android.
   * Returns true if the current device is an Android.
   */
  static bool get isAndroid => userAgent.contains("Android", 0);

  /**
   * Determines if the current device is WebOS WebKit.
   * Returns true if the current device is WebOS WebKit.
   */
  static bool get isWebOs => userAgent.contains("webOS", 0);

  static bool _supportsTouch;
  static bool get supportsTouch {
    if (_supportsTouch == null) {
      _supportsTouch = isMobileSafari || isAndroid;
    }
    return _supportsTouch;
  }
}
