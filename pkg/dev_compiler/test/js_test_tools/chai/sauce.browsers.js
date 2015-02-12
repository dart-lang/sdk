/**
 * @license
 * Copyright (c) 2014 The Polymer Project Authors. All rights reserved.
 * This code may only be used under the BSD style license found at http://polymer.github.io/LICENSE.txt
 * The complete set of authors may be found at http://polymer.github.io/AUTHORS.txt
 * The complete set of contributors may be found at http://polymer.github.io/CONTRIBUTORS.txt
 * Code distributed by Google as part of the polymer project is also
 * subject to an additional IP rights grant found at http://polymer.github.io/PATENTS.txt
 */


/*!
 * Chrome
 */

exports['SL_Chrome'] = {
    base: 'SauceLabs'
  , browserName: 'chrome'
};

/*!
 * Firefox
 */

/*!
 * TODO: Karma doesn't seem to like this, though sauce boots its up
 *

exports['SL_Firefox_23'] = {
    base: 'SauceLabs'
  , browserName: 'firefox'
  , platform: 'Windows XP'
  , version: '23'
};

*/

exports['SL_Firefox_22'] = {
    base: 'SauceLabs'
  , browserName: 'firefox'
  , platform: 'Windows 7'
  , version: '22'
};

/*!
 * Opera
 */

exports['SL_Opera_12'] = {
    base: 'SauceLabs'
  , browserName: 'opera'
  , platform: 'Windows 7'
  , version: '12'
};

exports['SL_Opera_11'] = {
    base: 'SauceLabs'
  , browserName: 'opera'
  , platform: 'Windows 7'
  , version: '11'
};

/*!
 * Internet Explorer
 */

exports['SL_IE_10'] = {
    base: 'SauceLabs'
  , browserName: 'internet explorer'
  , platform: 'Windows 2012'
  , version: '10'
};

/*!
 * Safari
 */

exports['SL_Safari_6'] = {
    base: 'SauceLabs'
  , browserName: 'safari'
  , platform: 'Mac 10.8'
  , version: '6'
};

exports['SL_Safari_5'] = {
    base: 'SauceLabs'
  , browserName: 'safari'
  , platform: 'Mac 10.6'
  , version: '5'
};

/*!
 * iPhone
 */

/*!
 * TODO: These take forever to boot or shut down. Causes timeout.
 *

exports['SL_iPhone_6'] = {
    base: 'SauceLabs'
  , browserName: 'iphone'
  , platform: 'Mac 10.8'
  , version: '6'
};

exports['SL_iPhone_5-1'] = {
    base: 'SauceLabs'
  , browserName: 'iphone'
  , platform: 'Mac 10.8'
  , version: '5.1'
};

exports['SL_iPhone_5'] = {
    base: 'SauceLabs'
  , browserName: 'iphone'
  , platform: 'Mac 10.6'
  , version: '5'
};

*/

/*!
 * Android
 */

/*!
 * TODO: fails because of error serialization
 *

exports['SL_Android_4'] = {
    base: 'SauceLabs'
  , browserName: 'android'
  , platform: 'Linux'
  , version: '4'
};

*/
