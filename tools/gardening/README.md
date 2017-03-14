# Gardening Tools

This directory is created for gathering all tools doing gardening in one place.
Every tools or script, big or small should go here, and over time, hopefully
we will have useful collection of tools that support every part of the 
gardening work.

The current tools are:

#### compare_failures ####
Compares the test log of a build step with previous builds. Use this to detect 
flakiness of failures, especially timeouts.

Usage:

    compare_failures.dart <stdio-url>
    
where `<stdio-url>` is a url for a test log (".../logs/stdio") from the 
buildbot. 