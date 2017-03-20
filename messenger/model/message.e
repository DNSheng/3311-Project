note
	description: "Summary description for {MESSAGE}."
	author: ""
	date: "$Date$"
	revision: "$Revision$"

class
	MESSAGE

create
	make

feature {NONE} -- Initialization

	make (a_message_sender, a_group_id: INTEGER_64; a_message_content: STRING)
		do
			message_group	:= a_group_id
			message_sender	:= a_message_sender
			message_content	:= a_message_content
		end

feature {MESSAGE} -- Attributes

	message_group:		INTEGER_64
	message_sender:		INTEGER_64
	message_content:	STRING

feature {MESSENGER}

	get_message_group: INTEGER_64
	do
		Result := message_group
	end

	get_message_sender: INTEGER_64
	do
		Result := message_sender
	end

	get_message_content: STRING
	do
		Result := message_content
	end

end
