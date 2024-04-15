from tkinter import *
from tkinter import ttk
from dialogFileTree import *
from dialogTreeObjects import *
from guiUtils import *
import sys
import os

# the main window/container
class MainWindow:
    width = 960
    height = 540
    filepath = os.getcwd()
    
    level = ""
    interaction = ""
    tree = ""
    
    levelSelected = False
    interactionSelected = False
    treeSelected = False
    
    def __init__(self, root):
        self.root = root
        self.root.title("Dialog Tree Creator")
        # set filepath assuming this program is in dialog folder
        temp = self.filepath.split("\\")
        temp.pop()
        self.filepath = '\\'.join(temp)
        # selections for level, interaction, and name
        init_comboboxes()
        
        # possible subtree creator?
        
    def init_comboboxes(self):
        self.levelSelect = DropdownBox(self, get_dir_options())
        self.interactionSelect = DropdownBox(self, ["N/A"])
        self.nameSelect = DropdownBox(self, ["N/A"])
        
    def create_frame(self):
        self.frame = ttk.Frame(root)
        self.frame['padding'] = 5
        
    def get_dir_options(self, addition=None):
        path = self.filepath
        if addition != None:
            path = os.path.join(path,addition)
        return [f for f in os.listdir(path) if os.path.isdir(os.path.join(path, f))]
        
    def set_custom_filepath(self, filepath):
        self.filepath = filepath

# allows us to create/destroy selection boxes as needed
class DropdownBox:
    n = tk.StringVar()
    box = None
    def __init__(self, parent, options):
        self.box = ttk.Combobox(parent, width = 27, textvariable = self.n) 
        self.change_options(options)
    def change_options(self, options):
        self.box['values'] = options
        self.box.grid(column = 1, row = len(options))
       
# contains the tree editor
class TreeEditor:

# contains the node editor
class NodeEditor:

# contains the page editor
class PageEditor:

# contains the choice editor
class ChoiceEditor:
        
    # TODO : 
    # # filepath 
    # # tree character/environment
    # # node creator (node titles automatic), starts at page 1
    # # # speaker input
    # # # emotion input
    # # # text
    # # # if choices exist
    # # # # choice text
    # # # # choice emotion input
    # # # # # after these are entered, new corresponding node form automatically created
    # # # if no choices
    # # # # option to create another page of text

if __name__ == '__main__':
    # creates root window object
    root = Tk()
    # creates the window using that root
    app = MainWindow(root)
    # enters main functionality loop
    root.mainLoop()