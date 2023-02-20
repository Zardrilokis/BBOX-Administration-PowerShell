# BBOX-Administration-Powershell

This is my first shared programm on Github :)
So I would ask you to be indulgent with the way it has been developed.
I remain however interested in your constructive comments to help me improve it.

This Tool is based and developed in PowerShell to get BBOX information.
It is only avalaible in english.
It can be used only with a Bouygues Telecom (BYTEL) router.
I can't test this program with all BYTEL routers.
So please find below all router and API version and firmware i can tested on my side :

https://github.com/Zardrilokis/BBOX-Administration-Powershell/blob/main/Ressources/TestedEnvironnement.csv

What composed this program ?

This program use :

End version 2.3 : 
- API rest developed by Bouygues Télécom (https://api.bbox.fr/doc/apirouter/index.html)
- Microsoft Powershell in version 5.1.xxxxx.xxxx
- Powershell web request with Chrome Driver Service (https://chromedriver.chromium.org)
- Custom Powershell Module

Since version 2.4 : 
- Microsoft Powershell in version 7.0.xxxxx.xxxx
- Powershell Module : https://github.com/echalone/PowerShell_Credential_Manager (More Secure)

For the moment, All versions can only :
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
- If remotly, enter external DNS and port number.
- Choose the action his wants the programm do.

If the user wants to quit the program, he can use the "Cancel" button when program asking action or press "CTRL" + "break" keyboard keys if there is a while in the programm.

Don't forget to have a look at : https://github.com/Zardrilokis/BBOX-Administration-Powershell/wiki

Enjoy your first experience with this program :)
