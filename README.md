# Repair-DevelopmentEnvironment.ps1

Configuring a development environment shouldn't take hours or days, and shouldn't require lots of manual steps.

This repository contains a set of useful base scripts to help you automate this in your team.

## How this would work on your project

When a new developer joins your project:

    C:\code> git clone git@github.com:corporate/SomeProject.git
    Cloning into 'SomeProject'...
    Receiving objects: 100%, done.
    
    C:\code> cd SomeProject
    
    C:\code\SomeProject> Repair-DevelopmentEnvironment.ps1
    Problem: IIS site missing for www.site.localtest.me
    Fix applied: IIS site created for www.site.localtest.me
    
    Problem: SSL binding missing for www.site.localtest.me
    Fix applied: SSL binding added for www.site.localtest.me
    
    Problem: IIS site missing for services.site.localtest.me
    Fix applied: IIS site created for services.site.localtest.me
    
    All environment tests now passing (fixes were applied)
    
When you've just pulled new code, then your environment broke because another developer introduced a new dependency:

    C:\code\SomeProject> git pull
    
    C:\code\SomeProject> Repair-DevelopmentEnvironment.ps1
    Problem: Back connection hostname missing for service.site.localtest.me
    Fix applied: Back connection hostname added for service.site.localtest.me
    
    All environment tests now passing (fixes were applied)

When you're not sure if it's your environment or your code that's broken:

    C:\code\SomeProject> Repair-DevelopmentEnvironment.ps1
    
    All environment tests pass. If your code isn't working, then either this script is incomplete or your code is broken. Either way, you need to go and fix something. :)

## How to add this to your project

1. Download the contents of this repository
2. Copy everything except `README.md` into the root of your project's working copy
3. Commit everything into _your_ repository
4. Modify `Repair-DevelopmentEnvironment.ps1` to contain the rules that you need
5. Do not modify `RepairDevelopmentEnvironmentModules` directly, or you will lose the ability to upgrade our helpers

## How to upgrade in future

1. Run your existing `Repair-DevelopmentEnvironment.ps1` to make sure it is passing
2. Download the contents of this repository again
3. Copy the `RepairDevelopmentEnvironmentModules` folder across to your project's working copy (do not copy `Repair-DevelopmentEnvironment.ps1`: ours is just a template)
4. Run your existing `Repair-DevelopmentEnvironment.ps1` to make sure it is passing
5. Commit everything into _your_ repository

## How to write new test and fix scripts

We keep the test and fix scripts in modules, separate from the `Repair-DevelopmentEnvironment.ps1`. This way, we can all work together on GitHub to write and improve them independently of each of our own projects.
