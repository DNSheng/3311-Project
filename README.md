# 3311-Project

A simple messaging program. Current planning is in the docs/ folder.

Currently matches oracle (as of March 28) and thus considered finished.

Notes:

	Originally there was an OUTPUT class
		- Handled errors and general printing
		- Received information to print from MESSENGER
		- Running from CL gave void safety exceptions
			- get_user_list
			- get_group_list
			- get_message_list
		- Running from GUI didn't give exceptions
			- Thus, likely an ETF problem
