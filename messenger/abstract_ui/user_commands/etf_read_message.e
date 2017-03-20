note
	description: ""
	author: ""
	date: "$Date$"
	revision: "$Revision$"

class
	ETF_READ_MESSAGE
inherit
	ETF_READ_MESSAGE_INTERFACE
		redefine read_message end
create
	make
feature -- command
	read_message(uid: INTEGER_64 ; mid: INTEGER_64)
		require else
			read_message_precond(uid, mid)
    	do
			if not model.is_positive_num (uid) or not model.is_positive_num (mid) then
				model.set_error_flag (0)
			elseif not model.user_exists (uid) then
				model.set_error_flag (4)
			elseif not model.message_exists (mid) then
				model.set_error_flag (9)
			elseif not model.user_authorized_access (uid, mid) then
				model.set_error_flag (10)
			elseif model.message_was_read (uid, mid) then
				model.set_error_flag (11)
			else
				model.read_message (uid, mid)
			end
			etf_cmd_container.on_change.notify ([Current])
    	end

end
