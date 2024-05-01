for now the filesystem is something like

Area/Level Name
-> Environmental
-- --> default.json (holds all default environment dialogue for the area)
-- --> any other special ones you may need
-> NPC
-- --> name
-- -- --> interaction.json

the *idea* is that different dialogue trees will be in their own files
the framework is there but i havent coded the actual doing of this

also, yes. there can be multiple dialogue trees in one file. the npc will likely 
hold the name of the next dialogue tree in some way.

for the interactions themselves, it's a complex thing. just look at the example.
yes there is a reason why it's Like That and it's because i dont want to write more conditionals