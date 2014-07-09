# changelog

This file contains highlights of what changes on each version of the observe
package.

#### Pub version 0.10.0+3
  * minor changes to documentation, deprecated `discardListChages` in favor of
    `discardListChanges` (the former had a typo).

#### Pub version 0.10.0
  * package:observe no longer declares @MirrorsUsed. The package uses mirrors
    for development time, but assumes frameworks (like polymer) and apps that
    use it directly will either generate code that replaces the use of mirrors,
    or add the @MirrorsUsed declaration themselves. For convinience, you can
    import 'package:observe/mirrors_used.dart', and that will add a @MirrorsUsed
    annotation that preserves properties and classes labeled with @reflectable
    and properties labeled with @observable.
