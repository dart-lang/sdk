This is a rough experiment at more deeply integrating dart into a browser
in order to simplify the dev experience.  It currently provides a simple
playground for interactively messing around with dart code and an extension
to chrome to automatically compile and run .dart files.  The goal is to
provide the infrastructure to build browser extensions to chrome and other
easily extensible browsers (such as FireFox) that will make it very easy to
experiment with code and later full pages that incorporate the dart language.

Note: All commands below must be run from the dart/frog directory.  They have
not been hardened for launch from other locations.

First, you need to build tip.js by hand - bootstrapping, ya'know.

> ./frog.py --out=tip/tip.js --compile-only tip/tip.dart

Then you need to start the local server:

> ./frog.py tip/toss.dart

Finally, navigate to the appropriate page in chrome:

http://localhost:1337/frog/tip/tip.html

You should see the editor.

The part that sucks right now is that until we are properly bootstrapped, you
will need to rebuild tip.js by hand (the first step above) in order to see
changes.

