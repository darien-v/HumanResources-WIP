#!/usr/bin/python3
import sys
import os
import tkinter as tk
import tkinter.ttk as ttk
from tkinter.messagebox import *
from dialogFileTree import *
from dialogTreeObjects import *
from dialogNodeEditor import *
from dialogTreeCompiler import *
from guiUtils import *


class DialogTreeGenerator:
    treeTabs = {}
    characters = []
    emotions = []
    def __init__(self, master=None):
        self.root = tk.Tk() if master is None else tk.Toplevel(master)
        self.master = master
        self.root.configure(height=540, width=960)
        self.mainFrame = ttk.Frame(self.root, name="mainframe")
        self.mainFrame.configure(height=540, width=960)
        self.mainTabs = ttk.Notebook(self.mainFrame, name="maintabs")
        self.mainTabs.configure(height=540, width=960)
        self.initializerFrame = ttk.Frame(
            self.mainTabs, name="initializerframe")
        self.initializerFrame.configure(height=540, width=960)
        frame32 = ttk.Frame(self.initializerFrame)
        frame32.configure(height=200, width=200)
        self.characterController = ttk.Labelframe(
            frame32, name="charactercontroller")
        self.characterController.configure(
            height=200, text='', width=200)
            
        # treeview containing character names
        self.characterList = ttk.Treeview(
            self.characterController, name="characterlist")
        self.characterList.configure(selectmode="extended")
        self.characterList_cols = []
        self.characterList_dcols = []
        self.characterList.configure(
            columns=self.characterList_cols,
            displaycolumns=self.characterList_dcols)
        self.characterList.column(
            "#0",
            anchor="w",
            stretch=True,
            width=200,
            minwidth=20)
        self.characterList.heading(
            "#0", anchor="w", text='Available Characters')
        self.characterList.pack(expand=True, fill="y", side="top")
        self.characterInput = ttk.Entry(
            self.characterController, name="characterinput")
        _text_ = 'New Character'
        self.characterInput = ttk.Entry(
            self.characterController, name="characterinput")
        _text_ = 'New Character'
        self.characterInput.delete("0", "end")
        self.characterInput.insert("0", _text_)
        self.characterInput.pack(fill="x", side="top")
        self.importCharacters = ttk.Button(
            self.characterController, name="importcharacters")
        self.importCharacters.configure(text='Import from File')
        self.importCharacters.pack(expand=True, fill="x", side="left")
        self.importCharacters.configure(command=lambda:self.importList(self.characterList))
        self.addName = ttk.Button(self.characterController, name="addname")
        self.addName.configure(text='Add Manually')
        self.addName.pack(expand=True, fill="x", side="left")
        self.addName.configure(command=lambda:self.addItem(self.characterInput, self.characterList, "character"))
        self.characterController.pack(anchor="n", fill="y", side="left")
        self.characterController.pack_propagate(0)
        self.emotionController = ttk.Labelframe(
            frame32, name="emotioncontroller")
        self.emotionController.configure(
            height=200, text='', width=200)
            
        # treeview containing emotion keywords
        self.emotionList = ttk.Treeview(
            self.emotionController, name="emotionlist")
        self.emotionList.configure(selectmode="extended")
        self.emotionList_cols = []
        self.emotionList_dcols = []
        self.emotionList.configure(
            columns=self.emotionList_cols,
            displaycolumns=self.emotionList_dcols)
        self.emotionList.column(
            "#0",
            anchor="w",
            stretch=True,
            width=200,
            minwidth=20)
        self.emotionList.heading(
            "#0", anchor="w", text='Available Emotions')
        self.emotionList.pack(expand=True, fill="y", side="top")
        self.emotionInput = ttk.Entry(
            self.emotionController, name="emotioninput")
        _text_ = 'New Character'
        self.emotionInput.delete("0", "end")
        self.emotionInput.insert("0", _text_)
        self.emotionInput.pack(fill="x", side="top")
        self.importEmotion = ttk.Button(
            self.emotionController, name="importemotion")
        self.importEmotion.configure(text='Import from File')
        self.importEmotion.pack(expand=True, fill="x", side="left")
        self.importEmotion.configure(command=lambda:self.importList(self.emotionList))
        self.addEmotion = ttk.Button(self.emotionController, name="addemotion")
        self.addEmotion.configure(text='Add Manually')
        self.addEmotion.pack(expand=True, fill="x", side="left")
        self.addEmotion.configure(command=lambda:self.addItem(self.emotionInput, self.emotionList, "emotion"))
        self.emotionController.pack(anchor="n", fill="y", side="left")
        self.emotionController.pack_propagate(0)
        frame32.pack(anchor="w", expand=False, fill="both", side="left")
        frame33 = ttk.Frame(self.initializerFrame)
        frame33.configure(height=200, width=200)
        labelframe3 = ttk.Labelframe(frame33)
        labelframe3.configure(
            height=200,
            text='Initialize New Tree',
            width=200)
        self.treeName = ttk.Entry(labelframe3)
        _text_ = 'treename'
        self.treeName.delete("0", "end")
        self.treeName.insert("0", _text_)
        self.treeName.pack(fill="x", side="top")
        self.treeCreator = ttk.Button(labelframe3, name="treecreator")
        self.treeCreator.configure(text='Create Tree')
        self.treeCreator.pack(side="top")
        self.treeCreator.configure(command=self.createTree)
        self.treeImporter = ttk.Button(labelframe3, name="treeimporter")
        self.treeImporter.configure(text='Import Tree(s) From File')
        self.treeImporter.pack(side="top")
        self.treeImporter.configure(command=self.importTrees)
        labelframe3.pack(expand=True, fill="both", side="top")
        frame33.pack(expand=True, fill="both", side="left")
        self.initializerFrame.pack(side="top")
        self.mainTabs.add(self.initializerFrame, text='Initialize')
        
        self.compilerTab = DialogTreeCompiler(self.mainTabs, master)
        
        self.mainTabs.pack(side="top")
        self.mainFrame.pack(side="top")

        # Main widget
        self.mainwindow = self.root

    def run(self):
        self.mainwindow.mainloop()

    def importList(self):
        pass

    def addItem(self, textbox, tree, type_):
        textInput = retrieve_text_input(textbox)
        if type_ == "character":
            if textInput in self.characters:
                showerror('Name In Use', 'This value has already been added!')
                return
            self.characters.append(textInput)
        else:
            if textInput in self.emotions:
                showerror('Name In Use', 'This value has already been added!')
                return
            self.emotions.append(textInput)
        tree.insert("", tk.END, text=textInput)

    def createTree(self):
        text = retrieve_text_input(self.treeName)
        if text == "" or text in self.treeTabs.keys():
            showerror('Name In Use', 'This tree name is already in use, and thus unavailable!')
            return
        tree = dialogTree(text)
        self.treeTabs[text] = [tree, DialogNodeEditor(self.mainTabs, self.master, tree)]

    def importTrees(self):
        pass

if __name__ == "__main__":
    app = DialogTreeGenerator()
    app.run()
