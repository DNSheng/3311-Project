# 3311-Project

A simple messaging program. Current planning is in the docs/ folder.

TODO:
	
	Fix 'print_initial_state' occurring twice when starting program
	
	Contract checks (require, ensure) for every feature/command

	Acceptance Tests (To be done later)

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
	
	The error message for read_message() uses a ` (tilted apostrophe)
	instead of a ' (straight apostrophe) in the beginning. Fixed to
	match oracle, but likely a mistake.
