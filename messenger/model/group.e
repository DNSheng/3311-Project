note
	description: "Summary description for {GROUP}."
	author: ""
	date: "$Date$"
	revision: "$Revision$"

class
	GROUP

inherit
	COMPARABLE
		redefine
			is_less
		end

create
	make

feature {NONE} -- Initialization

	make (a_group_id: INTEGER_64; a_group_name: STRING)
		do
			group_id	:= a_group_id
			group_name	:= a_group_name
			create {ARRAYED_LIST[INTEGER_64]} group_members.make (0)
		end

feature {GROUP} -- Attributes

	group_id:			INTEGER_64
	group_name:			STRING
	group_members:		LIST[INTEGER_64]

feature -- Visible Commands

	register_user (a_uid: INTEGER_64)
	do
		group_members.force (a_uid)
	end

feature -- Visible Queries

	get_id: INTEGER_64
		do
			Result := group_id
		end

	get_name: STRING
		do
			Result := group_name
		end

	get_members: LIST[INTEGER_64]
		do
			Result := group_members
		end

	is_a_member (a_uid: INTEGER_64): BOOLEAN
		do
			Result := across group_members as member some member.item = a_uid end
		end

	is_less alias "<" (other: like CURRENT): BOOLEAN
		do
			if group_name < other.group_name then
				Result := true
			elseif group_name ~ other.group_name then
				Result := group_id < other.group_id
			else
				Result := false
			end
		end

end
