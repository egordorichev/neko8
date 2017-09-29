#!/bin/bash

#Select a message program
msg=""
if [[ -z "`which zenity`" ]]
then
	if [[ -z "`which xmessage`" ]]
	then
		msg="echo"
	else
		msg="xmessage"
	fi
else msg="zenity --info --text";fi

if [[ -z "`which love`" ]]
then
	#Love is not installed
	$msg "LÖVE not installed, please install from http://love2d.org"
else
	#Love is installed: which version?
	love_version="`love --version | grep 0.10.2`"
	if [[ -z $love_version ]]
	then
		#Not 0.10.2
		$msg "LÖVE 0.10.2 is required. Currently installed: `love --version`. Please install LOVE2d v0.10.2 from http://love2d.org."
	else
		#0.10.2 installed, launch LIKO-12
		love .
	fi
fi
