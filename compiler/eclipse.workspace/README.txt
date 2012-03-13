This is an Eclipse workspace for Helios Service Release 2.

HOW TO

1. When you open Eclipse the first time, it will ask you to create a
   workspace or select an existing one. You can use this directory as
   workspace, or you can choose a different one.

2. If you're already using Eclipse, you can either switch to a new
   workspace (File > Switch Workspace) or use your current workspace.

3. Add the following "Path Variable" to your workspace:
   (Open Preferences... > General > Workspace > Linked Resources)
   DART_TRUNK: point to the root of your checkout
  

4. Add a "Classpath Variable" to your workspace called DART_TRUNK
   that points to the same directory as your DART_TRUNK path variable.
   (Open Preferences... > Java > Build Path > Classpath Variables).

5. Regardless if you're using this directory as a workspace, you have
   to import the projects (File > Import... > General > Existing
   Projects into Workspace).

6. Click "Next >"

7. Select root directory. Browse to: compiler/eclipse.workspace.

8. It should find and select two projects (dartc and tests).

9. Click Finish. (At this point Eclipse may get stuck, if so, exit
   Eclipse by right-clicking on the dock icon, and restart).

10. Open Preferences... > Java > Compiler > Errors/Warnings > Potential
    programming problems. Change "Serializable class without
    serialVersionUID" to "Ignore".

11. Import the launch configuration (File > Import... > Run/Debug >
    Launch Configurations).

12. Click "Next >"

13. In SVN, browse to: compiler/eclipse.workspace/tests.

14. Select "tests".

15. Click Finish.

16. Try running the tests: Run > Run History > dartc test suites.
