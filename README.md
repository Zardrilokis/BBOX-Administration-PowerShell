# BBOX-Administration-Powershell

This is my first shared programm on Github :)
So I would ask you to be indulgent with the way it has been developed.
I remain however interested in your constructive comments to help me improve it.

This Tool is based and developed in PowerShell to get BBOX information.
It is only avalaible in english.
It can be used only with a Bouygues Telecom (BYTEL) router.
I can't test this program with all BYTEL routers.
So please find below all router and API version and firmware i can tested :

Bbox_Model	  Firmware_Version	Connexion_Type	OS_Version	  PowerShell_Version Chrome_Version	ChromeDriver_Version
Fast5330b-r1	20.8.8	          FTTH	          Windows10Pro	5.1.19041.1682	   103.0.5060.134	71.0.3578.33
Fast5330b-r1	20.6.8	          FTTH	          Windows10Pro	5.1.19041.1320	   97.0.4692.71
Fast5330b-r1	20.2.34	          FTTH	          Windows10Pro	5.1.18362.1171	   97.0.4692.71
Fast5330b-r1	19.2.12	          FTTH	          Windows10Pro	5.1.18362.1171	   97.0.4692.71
Fast5330b-r1	18.5.4	          FTTH	          Windows10Pro	5.1.18362.1171	   97.0.4692.71
Fast5330b-r1	18.2.12	          FTTH	          Windows10Pro	5.1.18362.1171	   97.0.4692.71
Fast5330b-r1	17.13.8	          FTTH	          Windows10Pro	5.1.18362.1171	   97.0.4692.71
Fast5330b-r1	17.13.4	          FTTH	          Windows10Pro	5.1.18362.1171	   97.0.4692.71
Fast5330b-r1	17.13.4	          FTTH	          Windows10Pro	5.1.18362.1171	   97.0.4692.71
Fast5330b-r1	17.10.10	        FTTH	          Windows10Pro	5.1.18362.1171	   97.0.4692.71

What composed this program ?

This program use :

- API rest developed by Bouygues Télécom (https://api.bbox.fr/doc/apirouter/index.html)
- Microsoft Powershell in version 5.1.xxxxx.xxxx
- Powershell web request with Chrome Driver Service (https://chromedriver.chromium.org)

For the moment, this version can only :
- GET
- DOWNLOAD

In the future, you will do these actions :
- GET
- PUT
- POST
- DELETE
- DOWNLOAD

In summary, Collect, Modify, Remove, BBOX information using Bytel API Web request, with PowerShell script.

How to use ?

It is very simple !

1) Dowload all files as zip file : https://github.com/Zardrilokis/BBOX-Administration-Powershell/archive/main.zip
2) Unzip archive.
3) Open a powershell console
4) Enter the command line : cd "this is the path where files are unziped"
5) Run the script with the command line : .\BBOX-Administration.ps1
6) The script runs and checks some settings and ask you some informations.

What actions are required by user ?

- Enter his bbox password to allow the program to connect to the bbox web interface.
- Select the connexion type (Local/remotly).
- If remotly, enter external DNS and port number;
- Choose the action his wants the programm do.

If the user wants to quit the program, he can use the "Cancel" button when program asking action or press "CTRL" + "break" keyboard keys.

Enjoy your first experience with this program :)
