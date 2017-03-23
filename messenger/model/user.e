note
	description: "Summary description for {USER}."
	author: "DNSheng"
	date: "$Date$"
	revision: "$Revision$"

class
	USER

inherit
	COMPARABLE
		redefine
			is_less
		end

create
	make

feature {NONE} -- Initialization

	make (a_user_id: INTEGER_64; a_user_name: STRING)
		do
				user_id 	:= a_user_id
				user_name 	:= a_user_name

				create user_messages.make (0)
				create {ARRAYED_LIST[INTEGER_64]} membership.make (0)
		end

feature {USER} -- Features

	user_id:		INTEGER_64
	user_name: 		STRING
	user_messages:		HASH_TABLE[STRING, INTEGER_64]
	membership:		LIST[INTEGER_64]				-- Sort based on IDs

feature -- Visible Queries

	get_id: INTEGER_64
		do
			Result := user_id
		end

	get_name: STRING
		do
			Result := user_name
		end

	is_less alias "<" (other: like Current): BOOLEAN
		do
			Result := user_name < other.user_name
		end

feature {MESSENGER} -- Defensive Export Queries

	has_message (a_mid: INTEGER_64): BOOLEAN
		do
			Result := user_messages.has (a_mid)
		end

	message_was_read (a_mid: INTEGER_64): BOOLEAN
		do
			Result := user_messages.at (a_mid) ~ "read"
		end

	message_deletable (a_mid: INTEGER_64): BOOLEAN
		do
			Result := user_messages.at (a_mid) ~ "read" or
					  user_messages.at (a_mid) ~ "unread"
		end

	has_new_messages: BOOLEAN
		do
			Result := across user_messages as msg some msg.item ~ "unread" end
		end

	has_old_messages: BOOLEAN
		do
			Result := across user_messages as msg some msg.item ~ "read" end
		end

	get_memberships: LIST[INTEGER_64]
		do
			Result := membership
		end

	get_user_messages: HASH_TABLE[STRING, INTEGER_64]
		do
			Result := user_messages
		end

	membership_count: INTEGER
		do
			Result := membership.count
		end

feature -- Visible Commands

	read_message (a_message_id: INTEGER_64)
		do
			user_messages.at (a_message_id) := "read"
		end

	add_message (a_message_id: INTEGER_64)
		do
			user_messages.force ("unread", a_message_id)
		end

	delete_message (a_message_id: INTEGER_64)
		do
			user_messages.remove (a_message_id)
		end

	add_membership (a_gid: INTEGER_64)
		do
			membership.force (a_gid)
		end

end
