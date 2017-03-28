note
	description: "Stores users, groups, messages. Handles commands. Prints."
	author: "DNSheng"
	date: "$Date$"
	revision: "$Revision$"

class
	MESSENGER

inherit
	ANY
		redefine
			out
		end

create {MESSENGER_ACCESS}
	make

------------------------------------------------------------------------
--INITIALIZATION
------------------------------------------------------------------------

feature {NONE}
	make
		do
			-- Printing Attributes
			status_counter		:= 0
			print_state		:= 0
			preview_length		:= 15
			status_message		:= "OK"
			error_message		:= ""

			-- Model attributes
			message_list_key	:= 1

			create {ARRAYED_LIST[TUPLE [user: USER; user_id: INTEGER_64]]} user_list.make (0)
			create {ARRAYED_LIST[TUPLE [group: GROUP; group_id: INTEGER_64]]} group_list.make (0)
			create {ARRAYED_LIST[TUPLE [message: MESSAGE; message_id: INTEGER_64]]} message_list.make (0)
		end

------------------------------------------------------------------------
--ATTRIBUTES
------------------------------------------------------------------------

feature {MESSENGER}

	message_list_key:		INTEGER_64
	user_list:			LIST[TUPLE [user: USER; user_id: INTEGER_64]]
	group_list:			LIST[TUPLE [group: GROUP; group_id: INTEGER_64]]
	message_list:			LIST[TUPLE [message: MESSAGE; message_id: INTEGER_64]]

------------------------------------------------------------------------
--MODEL COMMANDS
------------------------------------------------------------------------

feature

	reset
		do
			make
		end

	add_group (a_gid: INTEGER_64; a_group_name: STRING)
		local
			l_group: GROUP
		do
			create l_group.make (a_gid, a_group_name)
			group_list.force (l_group, a_gid)
		end

	add_user (a_uid: INTEGER_64; a_user_name: STRING)
		local
			l_user: USER
		do
			create l_user.make (a_uid, a_user_name)
			user_list.force (l_user, a_uid)
		end

	register_user (a_uid, a_gid: INTEGER_64)
		local
			l_message: MESSAGE
		do
			-- Register user in group
			get_group (a_gid).register_user (a_uid)
			-- Let user know they are in a group
			get_user (a_uid).add_membership (a_gid)
			-- Add messages from that group to the user
			across
				message_list as msg
			loop
				l_message := msg.item.message
				if l_message.get_message_group = a_gid then
					get_user (a_uid).add_message (msg.item.message_id)
					-- All past messages sent to the group are set to unavailable
					get_user (a_uid).delete_message (msg.item.message_id)
				end
			end
		end

	send_message (a_uid, a_gid: INTEGER_64; a_txt: STRING)
		local
			l_message: MESSAGE
			l_user: USER
		do
			create l_message.make (a_uid, a_gid, a_txt)
			-- Put message in list
			message_list.force (l_message, message_list_key)
			-- Give all users in group access to the message
			across
				user_list as user
			loop
				l_user := user.item.user
				if l_user.in_group (a_gid) then
					l_user.add_message (message_list_key)
				end
			end
			-- Set sender of message to have 'read' the message
			get_user (a_uid).read_message (message_list_key)
			-- Increment message key (message_id)
			message_list_key := message_list_key + 1
		end

	read_message (a_uid, a_mid: INTEGER_64)
		do
			-- Set message as read
			get_user (a_uid).read_message (a_mid)
			-- Prepare variables for printing
			print_state		:= 7
			list_user_id		:= a_uid
			list_message_id		:= a_mid
		end

	delete_message (a_uid, a_mid: INTEGER_64)
		do
			get_user (a_uid).delete_message (a_mid)
		end

	set_message_preview (a_n: INTEGER_64)
		do
			preview_length := a_n
		end

	list_groups
		do
			print_state := 3
		end

	list_new_messages (a_uid: INTEGER_64)
		do
			list_user_id := a_uid
			print_state := 4
		end

	list_old_messages (a_uid: INTEGER_64)
		do
			list_user_id := a_uid
			print_state := 5
		end

	list_users
		do
			print_state := 6
		end

------------------------------------------------------------------------
--PRINTING
------------------------------------------------------------------------

feature {MESSENGER} -- Printing Attributes

	status_message:				STRING
	error_message:				STRING
	print_state:				INTEGER_64
	status_counter:				INTEGER_64
	preview_length:				INTEGER_64
	list_user_id:				INTEGER_64
	list_message_id:			INTEGER_64

feature {MESSENGER} -- Printing Commands

	internal_reset
	do
		-- Reset printing variables after model prints
		print_state 			:= 1
		list_user_id			:= 0
		list_message_id			:= 0
		error_message			:= ""
		status_message			:= "OK"
		status_counter			:= status_counter + 1
	end

feature -- Visible Printing Commands

	set_error_flag (a_error_flag: INTEGER)
	do
		inspect a_error_flag
			when  0 then error_message := "ID must be a positive integer."
			when  1 then error_message := "ID already in use."
			when  2 then error_message := "User name must start with a letter."
			when  3 then error_message := "Group name must start with a letter."
			when  4 then error_message := "User with this ID does not exist."
			when  5 then error_message := "Group with this ID does not exist."
			when  6 then error_message := "This registration already exists."
			when  7 then error_message := "A message may not be an empty string."
			when  8 then error_message := "User not authorized to send messages to the specified group."
			when  9 then error_message := "Message with this ID does not exist."
			when 10 then error_message := "User not authorized to access this message."
			when 11 then error_message := "Message has already been read. See `list_old_messages'."
			when 12 then error_message := "Message with this ID not found in old/read messages."
			when 13 then error_message := "Message length must be greater than zero."
			when 14 then error_message := "Message with this ID unavailable."
		end
		print_state	:= 2
		status_message	:= "ERROR "
	end

feature -- Visible Printing Queries

	print_output: STRING
	do
		inspect print_state
			when 0 then Result := print_initial_state
			when 1 then Result := print_default_state
			when 2 then Result := print_error_state
			when 3 then Result := print_list_groups
			when 4 then Result := print_list_new_messages
			when 5 then Result := print_list_old_messages
			when 6 then Result := print_list_users
			when 7 then Result := print_read_message
		end
		internal_reset
	end

	out: STRING
		do
			-- If-statement fixes double printing of initial_state at start
			if status_counter = 0 then
				create Result.make_from_string (print_output)
			else
				create Result.make_from_string (print_initial_state)
				Result.append (print_output)
			end
		end

feature {MESSENGER} -- Hidden Printing Query Blocks


	print_error_message: STRING
	do
		create Result.make_from_string ("  ")
		Result.append (error_message)
	end

	print_status_message: STRING
	do
		create Result.make_from_string ("  ")
		Result.append (status_counter.out)
		Result.append (":  ")
		Result.append (status_message)
		Result.append ("%N")
	end

	print_users: STRING
	local
		l_user: USER
		l_sorted_users: SORTED_TWO_WAY_LIST[INTEGER_64]
	do
		create Result.make_from_string ("  ")
		Result.append ("Users:%N")

		if user_list.count > 0 then
			-- SORT
			create l_sorted_users.make
			across
				user_list as user
			loop
				l_sorted_users.extend (user.item.user_id)
			end
			-- LIST
			across
				l_sorted_users as user
			loop
				l_user := get_user (user.item)
				Result.append ("    ")
				Result.append (print_id_name (l_user.get_id, l_user.get_name))
			end
		end
	end

	print_groups: STRING
	local
		l_group: GROUP
		l_sorted_groups: SORTED_TWO_WAY_LIST[INTEGER_64]
	do
		create Result.make_from_string ("  ")
		Result.append ("Groups:%N")
		
		if group_list.count > 0 then
			-- SORT
			create l_sorted_groups.make
			across
				group_list as group
			loop
				l_sorted_groups.extend (group.item.group_id)
			end
			-- LIST
			across
				l_sorted_groups as group
			loop
				l_group := get_group (group.item)
				Result.append ("    ")
				Result.append (print_id_name (l_group.get_id, l_group.get_name))
			end
		end
	end

	print_registrations: STRING
	local
		l_group_print_count: INTEGER
		l_user: USER
		l_sorted_groups: SORTED_TWO_WAY_LIST[INTEGER_64]
	do
		create Result.make_from_string ("  ")
		Result.append ("Registrations:%N")
		
		if user_list.count > 0 and registrations_exist then
			across
				user_list as user
			loop
				-- Print for users that are group members
				l_user := user.item.user

				if l_user.membership_count > 0 then
					l_group_print_count := l_user.membership_count
					Result.append ("      [")
					Result.append (user.item.user_id.out)
					Result.append (", ")
					Result.append (l_user.get_name)
					Result.append ("]->{")
					-- SORT
					create l_sorted_groups.make
					across
						l_user.get_memberships as group
					loop
						l_sorted_groups.extend (group.item)
					end
					-- LIST
					across
						l_sorted_groups as group
					loop
						Result.append (group.item.out)
						Result.append ("->")
						Result.append (get_group (group.item).get_name)
						-- Deal with ending line for each user
						if l_group_print_count > 1 then
							Result.append (", ")
						else
							Result.append ("}")
						end
						l_group_print_count := l_group_print_count - 1
					end

					Result.append ("%N")
				end
			end
		end
	end

	print_all_messages: STRING
		-- Sorted by default, given how we message IDs are auto-assigned by message_list_key
	do
		create Result.make_from_string ("  ")
		Result.append ("All messages:%N")
		if message_list.count > 0 then
			across
				message_list as msg
			loop
				Result.append (print_message (msg.item.message_id, msg.item.message))
			end
		end
	end

	print_message_state: STRING
		-- Only prints message states for people who are in groups
	local
		l_mid: INTEGER_64
		l_user: USER
	do
		create Result.make_from_string ("  ")
		Result.append ("Message state:%N")
		
		if user_list.count > 0 and message_list.count > 0 then
			across
				message_list as msg
			loop
				l_mid := msg.item.message_id
				-- For each message and each user, print if user is in a group
				across
					user_list as user
				loop
					l_user := user.item.user
					if l_user.membership_count > 0 then
						Result.append ("      (")
						Result.append (l_user.get_id.out)
						Result.append (", ")
						Result.append (l_mid.out)
						Result.append (")->")
						-- Print message state for user
						if l_user.message_was_read (l_mid) then
							Result.append ("read")
						elseif l_user.message_unread (l_mid) then
							Result.append ("unread")
						else
							Result.append ("unavailable")
						end
						Result.append ("%N")
					end
				end
			end
		end
	end

	print_id_name (a_id: INTEGER_64; a_name: STRING): STRING
	do
		create Result.make_from_string ("  ")
		Result.append (a_id.out)
		Result.append ("->")
		Result.append (a_name)
		Result.append ("%N")
	end

	print_message (a_mid: INTEGER_64; a_msg: MESSAGE): STRING
	local
		l_string: STRING
	do
		create Result.make_from_string ("      ")
		Result.append (a_mid.out)
		Result.append ("->[sender: ")
		Result.append (a_msg.get_message_sender.out)
		Result.append (", group: ")
		Result.append (a_msg.get_message_group.out)
		Result.append (", content: %"")

		l_string := a_msg.get_message_content

		if l_string.count <= preview_length then
			Result.append (l_string)
		else
			Result.append (l_string.substring (1, preview_length.as_integer_32))
			Result.append ("...")
		end

		Result.append ("%"]%N")
	end

feature {MESSENGER} -- Main Printing Queries

	print_initial_state: STRING
		do
			create Result.make_from_string (print_status_message)
		end

	print_default_state: STRING
		do
			create Result.make_from_string (print_users)
			Result.append (print_groups)
			Result.append (print_registrations)
			Result.append (print_all_messages)
			Result.append (print_message_state)
		end

	print_error_state: STRING
		do
			create Result.make_from_string (print_error_message)
			Result.append ("%N")
		end

	print_list_users: STRING
		local
			l_user: USER
			l_sorted_users: SORTED_TWO_WAY_LIST[USER]
		do
			create Result.make_empty
			
			if user_list.count > 0 then
				-- SORTING
				create l_sorted_users.make
				across
					user_list as user
				loop
					l_sorted_users.extend (user.item.user)
				end
				-- LISTING
				across
					l_sorted_users as user
				loop
					l_user := user.item
					Result.append (print_id_name (l_user.get_id, l_user.get_name))
				end
			else
				Result.append ("  There are no users registered in the system yet.%N")
			end
		end

	print_list_groups: STRING
		local
			l_group: GROUP
			l_sorted_groups: SORTED_TWO_WAY_LIST[GROUP]
		do
			create Result.make_empty
			
			if group_list.count > 0 then
				-- SORTING (ALPHABETICALLY)
				create l_sorted_groups.make
				across
					group_list as group
				loop
					l_sorted_groups.extend (group.item.group)
				end
				-- LISTING
				across
					l_sorted_groups as group
				loop
					l_group := group.item
					Result.append (print_id_name (l_group.get_id, l_group.get_name))
				end
			else
				Result.append ("  There are no groups registered in the system yet.%N")
			end
		end

	print_list_new_messages: STRING
		local
			l_user: USER
		do
			create Result.make_empty

			l_user := get_user (list_user_id)

			if l_user.has_new_messages then
				Result.append ("  New/unread messages for user [")
				Result.append (list_user_id.out)
				Result.append (", ")
				Result.append (l_user.get_name)
				Result.append ("]:%N")

				across
					l_user.get_user_messages as msg
				loop
					if msg.item ~ "unread" then
						Result.append (print_message (msg.key, get_message (msg.key)))
					end
				end

			else
				Result.append ("  There are no new messages for this user.%N")
			end
		end

	print_list_old_messages: STRING
		local
			l_user: USER
		do
			create Result.make_empty

			l_user := get_user (list_user_id)

			if l_user.has_old_messages then
				Result.append ("  Old/read messages for user [")
				Result.append (list_user_id.out)
				Result.append (", ")
				Result.append (l_user.get_name)
				Result.append ("]:%N")

				across
					l_user.get_user_messages as msg
				loop
					if msg.item ~ "read" then
						Result.append (print_message (msg.key, get_message (msg.key)))
					end
				end
			else
				Result.append ("  There are no old messages for this user.%N")
			end
		end

	print_read_message: STRING
		local
			l_user: USER
			l_message: MESSAGE
		do
			l_user := get_user (list_user_id)
			l_message := get_message (list_message_id)

			create Result.make_from_string ("  Message for user [")
			Result.append (list_user_id.out)
			Result.append (", ")
			Result.append (l_user.get_name)
			Result.append ("]: [")
			Result.append (list_message_id.out)
			Result.append (", %"")
			Result.append (l_message.get_message_content)
			Result.append ("%"]%N")
			
			Result.append (print_default_state)
		end

------------------------------------------------------------------------
--INTERNAL INFORMATION QUERIES
------------------------------------------------------------------------

feature {MESSENGER}

	get_user (a_uid: INTEGER_64): USER
		local
			l_user: USER
		do
			create l_user.make (0, "")		-- VEVI Compiler

			across
				user_list as usr
			loop
				if usr.item.user_id = a_uid then
					l_user := usr.item.user
				end
			end

			Result := l_user
		end

	get_group (a_gid: INTEGER_64): GROUP
		local
			l_group: GROUP
		do
			create l_group.make (0, "")		-- VEVI Compiler

			across
				group_list as grp
			loop
				if grp.item.group_id = a_gid then
					l_group := grp.item.group
				end
			end

			Result := l_group
		end

	get_message (a_mid: INTEGER_64): MESSAGE
		local
			l_message: MESSAGE
		do
			create l_message.make (0, 0, "")	-- VEVI Compiler

			across
				message_list as msg
			loop
				if msg.item.message_id = a_mid then
					l_message := msg.item.message
				end
			end

			Result := l_message
		end

------------------------------------------------------------------------
--INTERNAL INFORMATION COMMANDS
------------------------------------------------------------------------

feature {MESSENGER}

	registrations_exist: BOOLEAN
	do
		Result := across user_list as user some user.item.user.get_memberships.count > 0 end
	end

------------------------------------------------------------------------
--DEFENSIVE CHECKS
------------------------------------------------------------------------

feature {ETF_COMMAND}

	is_positive_num (a_num: INTEGER_64): BOOLEAN
	do
		Result := a_num.as_integer_32 > 0
	end

	is_unused_uid (a_uid: INTEGER_64): BOOLEAN
	do
		Result := across user_list as usr all usr.item.user_id /= a_uid end
	end

	is_unused_gid (a_gid: INTEGER_64): BOOLEAN
	do
		Result := across group_list as grp all grp.item.group_id /= a_gid end
	end

	is_valid_name (a_name: STRING): BOOLEAN
	do
		Result := not a_name.is_empty and a_name.at (1).is_alpha
	end

	user_exists (a_uid: INTEGER_64): BOOLEAN
	do
		Result := across user_list as usr some usr.item.user_id = a_uid end
	end

	group_exists (a_gid: INTEGER_64): BOOLEAN
	do
		Result := across group_list as grp some grp.item.group_id = a_gid end
	end

	user_is_member (a_uid, a_gid: INTEGER_64): BOOLEAN
	do
		Result := get_group (a_gid).is_a_member (a_uid)
	end

	is_empty_msg (a_msg: STRING): BOOLEAN
	do
		Result := a_msg.count.is_greater (0)
	end

	user_authorized_send (a_uid, a_gid: INTEGER_64): BOOLEAN
	do
		Result := user_is_member (a_uid, a_gid)
	end

	message_exists (a_mid: INTEGER_64): BOOLEAN
	do
		Result := across message_list as msg some msg.item.message_id = a_mid  end
	end

	user_authorized_access (a_uid, a_mid: INTEGER_64): BOOLEAN
	do
		Result := get_user (a_uid).has_message (a_mid)
	end

	message_was_read (a_uid, a_mid: INTEGER_64): BOOLEAN
	do
		Result := get_user (a_uid).message_was_read (a_mid)
	end

	message_deletable (a_uid, a_mid: INTEGER_64): BOOLEAN
	do
		Result := get_user (a_uid).message_deletable (a_mid)
	end

	appropriate_msg_length (a_message: STRING): BOOLEAN
	do
		Result := a_message.count > 0
	end

	message_available (a_uid, a_mid: INTEGER_64): BOOLEAN
	do
		Result := get_user (a_uid).message_unread (a_mid) or
				  get_user (a_uid).message_was_read (a_mid)
	end

end
