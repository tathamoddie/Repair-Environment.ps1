# Repair-DevelopmentEnvironment

Configuring a development environment shouldn't take hours or days, and shouldn't require lots of manual steps.

This repository contains a set of useful base scripts to help you automate this in your team.

## How You Use Them

When you're joining a new project:

    C:\code> git clone git@github.com:corporate/SomeProject.git
    Cloning into 'SomeProject'...
    Receiving objects: 100%, done.
    
    C:\code> cd SomeProject
    
    C:\code\SomeProject> Repair-DevelopmentEnvironment.ps1 -Confirm:$false
    Problem: IIS site missing for www.site.localtest.me
    Fixed: IIS site created for www.site.localtest.me
    
    Problem: SSL binding missing for www.site.localtest.me
    Fixed: SSL binding added for www.site.localtest.me
    
    Problem: IIS site missing for services.site.localtest.me
    Fixed: IIS site created for services.site.localtest.me
    
    All tests now passing (with fixes)
    
When you've just pulled, then your environment broke:

    C:\code\SomeProject> git pull
    
    C:\code\SomeProject> Repair-DevelopmentEnvironment.ps1
    Problem: Back connection hostname missing for service.site.localtest.me
    Fixed: Back connection hostname added for service.site.localtest.me
    
    All tests now passing (with fixes)
