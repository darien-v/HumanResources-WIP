'''

                            Online Python Compiler.
                Code, Compile, Run and Debug python program online.
Write your code in this editor and press "Run" button to execute it.

'''
from dialogTreeObjects import *
import sys
import os

if __name__ == "__main__":
    tree = {}
    lines = []
 
    validFile = False
    filename = ""
    filepath = ""
    while validFile == False:
        print("type the name of the .twee file! this will also be used as the dialog tree title :)\n")
        print("file should be in the same folder as this program!\n")
        filename = input()
        print(filename)
        if '.twee' in filename:
            validFile = True
        else:
            print("please make sure you provide a *.twee file!! :(")
    validFile = False
    while validFile == False:
        print("type the absolute path of the directory the result should be saved in!\n")
        filepath = input()
        if os.path.exists(filepath):
            validFile = True
        else:
            print("it doesnt seem like that directory exists! :(\n")
    
    
    # get all the lines 
    with open(filename) as file:
        lines = [x.strip() for x in file.readlines() if x != '\n']
        
    filename = filename.replace('.twee','.json')
    filepath = f"{filepath}/{filename}"
        
    # the title and data are the first 10 lines. we dont need those
    lines = lines[10:]
    
    # now look for dialog nodes and pages
    maxLines = len(lines)
    choicesIndicated = False
    index = 0 
    increment = False
    
    while index < maxLines:
        # get line
        line = lines[index]
        # '::' marks node start
        if line[0:2] == "::":
            line = line.split(' ')
            node_title = line[1]
            print(node_title)
            if node_title not in tree.keys():
                tree[node_title] = []
            index += 1
            print(f"New Node: {node_title}")
            checking = True
            # we are checking node contents
            while checking and index < maxLines:
                line = lines[index]
                # if the line starts with '>', it's page start
                if line[0] == '>':
                    print(f"New Page: {line}")
                    line = line.replace('>','').split(',')
                    page = {"speaker":line[0],"emotion":line[1]}
                    tree[node_title].append(page)
                # if the line starts with %, it's an operator
                # have yet to figure out how to format that
                elif line[0] == '%':
                    print(f"Operator")
                    increment = True
                    index += 1
                    continue
                # if the line starts with $, it's choices
                elif line[0] == '$':
                    print(f"Choices indicated: {line}")
                    choicesIndicated = True
                    tree[node_title][-1]["choices"] = []
                # if the line starts with [[, it's a target
                elif line[0:2] == '[[':
                    line = (line.replace('[[', '')).replace(']]','')
                    if not choicesIndicated:
                        print(f"Non-Choice Target: {line}")
                        tree[node_title][-1]["target"] = line
                    else:
                        print(f"Choice Target: {line}")
                        line = line.split('->')
                        temp = line[0].split('//')
                        tempNode = None
                        choice = {"emotion":temp[1],"text":temp[0],"target":line[1],"consequence":"none"}
                        # check if line has a consequence
                        if len(line) == 3:
                            if "CONSEQUENCE" in line[2]:
                                choice["consequence"] = (line[2].split('_'))[-1]
                        tree[node_title][-1]["choices"].append(choice)
                # if '::', we've gone too far
                elif line[0:2] == '::':
                    print("newNode")
                    choicesIndicated = False
                    checking = False
                    break
                # if no special prefix, it's just text
                else:
                    print(f"Page text: {line}")
                    tree[node_title][-1]["text"] = line
                index += 1
        else:
            index += 1
    
    treeObject = dialogTree(filename,tree)
    if increment:
        treeObject.key = treeObject.key + '+'
    
    with open(filepath, "w") as sys.stdout:
        print(treeObject)
        #for key in tree:
         #   print(tree[key])