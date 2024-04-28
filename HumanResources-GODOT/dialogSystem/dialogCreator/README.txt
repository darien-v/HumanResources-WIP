TO USE TWINETODIALOG:
- Download the latest version of Twine (Twinery)
- Create your dialog tree in twine using the following formatting for each node:
-- ">" signifies the start of a new page. should be written as ">[speaker],[emotion]"
-- "%" is an operator symbol. in Human Resources, it'll always be followed by "increment," but you can make it apply to other functions
-- "$CHOICES" indicates the page/node ends in choices. This should be after the last page in the node
-- "[[target]]" connects the node to its target node, while "[[choice->target]]" connects a choice to its target node
- Export the dialog tree as a .twee file
- Follow the command line instructions
- ???
- Profit


WHAT IS THE GUI THING:
- experimental, trying to make our own gui for this type of system to remove twine as the middleman.
- not successful yet