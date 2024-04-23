#!/usr/bin/python3
from dialogFileTree import *
from dialogTreeObjects import *
from guiUtils import *
import sys
import os
import tkinter as tk
import tkinter.ttk as ttk

# the page to save trees to file
class DialogTreeCompiler:
    trees = []
    def __init__(self, mainTabs=None, master=None):
        self.frame7 = ttk.Frame(mainTabs, name="frame7")
        self.frame7.configure(height=540, width=960)
        frame34 = ttk.Frame(self.frame7)
        frame34.configure(height=200, width=200)
        treeview3 = ttk.Treeview(frame34)
        treeview3.configure(selectmode="extended")
        treeview3_cols = []
        treeview3_dcols = []
        treeview3.configure(
            columns=treeview3_cols,
            displaycolumns=treeview3_dcols)
        treeview3.column(
            "#0",
            anchor="w",
            stretch=True,
            width=200,
            minwidth=20)
        treeview3.heading("#0", anchor="center", text='Available Trees')
        treeview3.pack(expand=True, fill="both", side="left")
        frame34.pack(expand=True, fill="both", side="left")
        frame36 = ttk.Frame(self.frame7)
        frame36.configure(height=200, width=200)
        self.treeSaver = ttk.Button(frame36, name="treesaver")
        self.treeSaver.configure(text='Save Selected Trees')
        self.treeSaver.pack(anchor="n", expand=True, side="left")
        self.treeSaver.configure(command=self.saveSelectedTrees)
        checkbutton1 = ttk.Checkbutton(frame36)
        self.treesOneFile = tk.StringVar()
        checkbutton1.configure(
            text='Save to One File',
            variable=self.treesOneFile)
        checkbutton1.pack(anchor="n", expand=True, side="left")
        checkbutton1.configure(command=self.treeCompiler)
        frame36.pack(expand=True, fill="both", side="left")
        self.frame7.pack(side="top")
        mainTabs.add(self.frame7, text='Finalize')
        
    def add_tree(tree):
        trees.append(tree)

    def saveSelectedTrees(self):
        pass

    def treeCompiler(self):
        pass