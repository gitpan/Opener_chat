del *.bak
del command.txt
rd tmp /q/s
rd chats /s/q
rd logs	/q/s
taskkill /im perl.exe /f
for /r %%i in (.svn) do rd %%i /s/q
taskkill /im cmd.exe /f
