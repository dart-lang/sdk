This is an Eclipse workspace for Helios Service Release 2.

HOW TO

1. When you open Eclipse the first time, it will ask you to create a
   workspace or select an existing one. You can use this directory as
   workspace, or you can choose a different one.

2. If you're already using Eclipse, you can either switch to a new
   workspace (File > Switch Workspace) or use your current workspace.

3. Add the folloing "Path Variable" to your workspace:
   (Open Preferences... > General > Workspace > Linked Resources)
   DART_TRUNK: point to the root of your checkout
   D8_EXEC: for example DART_TRUNK/compiler/out/Release_dartc/d8

4. Add a "Classpath Variable" to your workspace called DART_TRUNK
   that points to the same directory as your DART_TRUNK path variable.
   (Open Preferences... > Java > Build Path > Classpath Variables).

5. Regardless if you're using this directory as a workspace, you have
   to import the projects (File > Import... > General > Existing
   Projects into Workspace).

6. Click "Next >"

7. Select root directory. Browse to: compiler/eclipse.workspace.

8. It should find and select three projects (dartc and tests).

9. Click Finish. (At this point Eclipse may get stuck, if so, exit
   Eclipse by right-clicking on the dock icon, and restart).

10. Repeat steps 5-9, to import the project in third_party/closure-compiler-src

11. Open the "build.xml" file in the "closure-compiler-src" project.

12. In the Outline view, right-click on the "jar [default]" target, and select
    "Run as..." > "Ant Build". (This will build its version of Rhino and JarJar 
    it).

13. Open Preferences... > Java > Compiler > Errors/Warnings > Potential
    programming problems. Change "Serializable class without
    serialVersionUID" to "Ignore".

14. Open Preferences... > Java > Code Style > Formatter and click
    "Import...". Open the file GoogleCodeStyle.xml in this directory.

15. Import the launch configuration (File > Import... > Run/Debug >
    Launch Configurations).

16. Click "Next >"

17. In SVN, browse to: compiler/eclipse.workspace/tests.

18. Select "tests".

19. Click Finish.

20. Try running the tests: Run > Run History > dartc test suites.
