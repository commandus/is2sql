is2sql 
======

is2sql Version 1.11 Copyright (c) 1999, 2000, 2001 Andrei Ivanov

Purpose
---
Provides an easy way to build web- based application. Creates dynamic web pages interacts with databases - now directly to Interbase or via BDE in manner of Allaire's Cold Fusion.

Known bugs
---
If compiler corresponds 'Symbol ... is not defined' check uses clause in appropriate
unit. I can not check everything in all of VCL version.

How to compile it
---
You must have Delphi 3, 4, 5 or 6.

Set Project|Options|Directories/Conditionals|Conditional defines
 - USE_BDE or
 - USE_IB or 
 - USE_NCOCI (not recommended)
(for use BDE, Interbase Express or Oracle NCOCI respectively)
Rebuild project (choose Project|Build).
In previous version of Delphi (3 or 4) add or remove units in USES clause 
like webbroker if applicable.

How to debug
---
To debug an dll, choose Run|Parameters and set your app's run parameters:
Microsoft IIS server:
    Host Application: c:\winnt\system32\inetsrv\inetinfo.exe
    Run Parameters:   -e w3svc
  Personal Web Server:
    Host Application: C:\Program Files\WEBSVR\SYSTEM\Inetsw95.exe
    Run Parameters:   -w3svc
  Netscape webs:
  see "Debugging ISAPI and NSAPI applications" in Delphi help

You can compile TestISAPI.dpr - simple utility calls ISAPI/NSAPI DLL 
(source included in util\isapitest folder)
  TestISAPI.dpr:
    Host Application: C:\Source\util\isapitest\testisapi.exe
    Run Parameters:
    Choose DLL file name

Documentation
---
Sorry, no english version is available.
If you can read russian, open \doc\index.htm in your browser.


Examples
---
Now is not available except bad sample in \demo\ folder.
