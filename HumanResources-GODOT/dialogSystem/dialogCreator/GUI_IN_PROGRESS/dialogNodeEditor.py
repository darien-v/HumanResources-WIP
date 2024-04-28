#!/usr/bin/python3
import sys
import os
import tkinter as tk
import tkinter.ttk as ttk
from dialogFileTree import *
from dialogTreeObjects import *
from guiUtils import *
from tkinter.messagebox import *

# the main node editor
class DialogNodeEditor:
    nodes = {}
    currentNode = 0
    currentPage = 0
    parentTree = None
    def __init__(self, mainTabs, master, parentTree):
        # get the parent tree's name
        self.parentTree = parentTree
        name = parentTree.title
        # the treeview shows all available nodes which will be saved into the tree
        self.treeFrame = ttk.Frame(mainTabs, name=f"{name}Frame")
        self.treeFrame.configure(height=540, width=960)
        self.nodePanes = ttk.Panedwindow(
            self.treeFrame, orient="horizontal", name="nodepanes")
        self.nodePanes.configure(height=200, width=200)
        frame2 = ttk.Frame(self.nodePanes)
        frame2.configure(height=200, width=200)
        self.titleFrame = ttk.Frame(frame2, name="titleframe")
        self.titleFrame.configure(height=100, width=200)
        
        # user can change the tree name if desired
        self.treeName = ttk.Entry(self.titleFrame, name="treename")
        _text_ = f'{name}'
        self.treeName.delete("0", "end")
        self.treeName.insert("0", _text_)
        self.treeName.pack(
            anchor="n",
            expand=True,
            fill="x",
            padx=10,
            pady=10,
            side="left")
            
        # button to update tree name
        # TODO: connect to parent to check tree name validity
        self.treeEditorButton = ttk.Button(self.titleFrame, name="treeeditorbutton")
        self.treeEditorButton.configure(text='Update Name')
        self.treeEditorButton.pack(anchor="n", pady=10, side="left")
        self.treeEditorButton.configure(command=self.updateTreeName)
        self.titleFrame.pack(fill="x", side="top")
        
        # setting up the node tree
        self.nodeTreePaneFrame = ttk.Frame(frame2, name="nodetreepaneframe")
        self.nodeTreePaneFrame.configure(height=200, width=200)
        self.nodeTree = ttk.Treeview(self.nodeTreePaneFrame, name="nodetree")
        self.nodeTree.configure(height=525, selectmode="extended")
        self.nodeTree_cols = []
        self.nodeTree_dcols = []
        self.nodeTree.configure(
            columns=self.nodeTree_cols,
            displaycolumns=self.nodeTree_dcols)
        self.nodeTree.column(
            "#0",
            anchor="w",
            stretch=True,
            width=350,
            minwidth=350)
        self.nodeTree.heading("#0", anchor="w", text='Nodes')
        self.nodeTree.pack(expand=False, fill="both", side="top")
        self.nodeTreePaneFrame.pack(expand=True, fill="both", side="top")
        self.nodeTreePaneFrame.pack_propagate(0)
        frame2.pack(side="top")
        self.nodeTree.bind("<Double-Button>", self.onNodeTreeClick) 
        
        # this side of the display will show the info for the selected node
        self.nodePanes.add(frame2, weight="1")
        self.nodeFrame = ttk.Labelframe(self.nodePanes, name="nodeframe")
        self.nodeFrame.configure(
            height=200,
            relief="raised",
            text='SelectedNode',
            width=540)
        self.nodeInfo = ttk.Frame(self.nodeFrame, name="nodeinfo")
        self.nodeInfo.configure(height=175, relief="sunken", width=540)
        self.nodeProps = ttk.Labelframe(self.nodeInfo, name="nodeprops")
        self.nodeProps.configure(
            height=200,
            padding=10,
            text='properties',
            width=250)
        # the name 
        self.nodeTitle = ttk.Entry(self.nodeProps, name="nodetitle")
        self.nodeName = tk.StringVar(value='Start')
        self.nodeTitle.configure(textvariable=self.nodeName)
        _text_ = 'Start'
        self.nodeTitle.delete("0", "end")
        self.nodeTitle.insert("0", _text_)
        self.nodeTitle.pack(anchor="w", side="top")
        # does this node have choices?
        self.hasChoices = ttk.Checkbutton(self.nodeProps, name="haschoices")
        self.nodeChoiceToggle = tk.StringVar()
        self.hasChoices.configure(
            text='Choice-Driven',
            variable=self.nodeChoiceToggle)
        self.hasChoices.pack(anchor="w", pady=10, side="top")
        self.hasChoices.configure(command=self.nodeToggleChoices)
        # add/create the node's ultimate target
        self.targetControl = ttk.Frame(self.nodeProps)
        self.targetControl.pack(anchor="w", side="top")
        self.nodeTargetName = ttk.Entry(self.targetControl, name="nodetargetname")
        self.nodeTargetName.pack(anchor="n", side="left")
        self.addNodeTarget = ttk.Button(self.targetControl, name="addnodetarget")
        self.addNodeTarget.configure(text='Add Target')
        self.addNodeTarget.pack(anchor="n", side="left", expand=True, fill='both')
        self.addNodeTarget.configure(command=self.targetConnector)
        # save the changes or delete the node
        self.nodeEditorButton = ttk.Button(
            self.nodeProps, name="nodeeditorbutton")
        self.nodeEditorButton.configure(text='Save Changes')
        self.nodeEditorButton.pack(anchor="n", pady=5, side="left")
        self.nodeEditorButton.configure(command=self.saveSelectedNode)
        self.nodeDeleter = ttk.Button(self.nodeProps, name="nodedeleter")
        self.nodeDeleter.configure(text='Delete Node')
        self.nodeDeleter.pack(anchor="n", pady=5, side="left")
        self.nodeDeleter.configure(command=self.deleteSelectedNode)
        self.nodeProps.pack(anchor="n", padx=10, pady=10, side="left")
        self.nodeProps.pack_propagate(0)
        # this tree shows the selected node's "from" nodes
        self.fromNodeTree = ttk.Treeview(self.nodeInfo, name="fromnodetree")
        self.fromNodeTree.configure(selectmode="extended")
        self.fromNodeTree_cols = []
        self.fromNodeTree_dcols = []
        self.fromNodeTree.configure(
            columns=self.fromNodeTree_cols,
            displaycolumns=self.fromNodeTree_dcols)
        self.fromNodeTree.column(
            "#0",
            anchor="w",
            stretch=True,
            width=150,
            minwidth=20)
        self.fromNodeTree.heading("#0", anchor="w", text='From Nodes')
        self.fromNodeTree.pack(
            expand=True,
            fill="x",
            padx=5,
            pady=10,
            side="left")
        self.fromNodeTree.bind("<Double-Button>", self.onFromNodeTreeClick) 
        # this tree shows the selected node's "to" nodes/targets
        self.toNodeTree = ttk.Treeview(self.nodeInfo, name="tonodetree")
        self.toNodeTree.configure(selectmode="extended")
        self.toNodeTree_cols = []
        self.toNodeTree_dcols = []
        self.toNodeTree.configure(
            columns=self.toNodeTree_cols,
            displaycolumns=self.toNodeTree_dcols)
        self.toNodeTree.column(
            "#0",
            anchor="w",
            stretch=True,
            width=150,
            minwidth=20)
        self.toNodeTree.heading("#0", anchor="w", text='To Nodes')
        self.toNodeTree.pack(
            expand=True,
            fill="x",
            padx=5,
            pady=10,
            side="left")
        self.nodeInfo.pack(expand=False, fill="x", side="top")
        self.nodeInfo.pack_propagate(0)
        self.toNodeTree.bind("<Double-Button>", self.onToNodeTreeClick) 
        
        # the dialog page info 
        self.pagesFrame = ttk.Labelframe(self.nodeFrame, name="pagesframe")
        self.pagesFrame.configure(height=200, text='Dialog Pages', width=200)
        self.pagePanes = ttk.Panedwindow(
            self.pagesFrame, orient="horizontal", name="pagepanes")
        self.pagePanes.configure(height=200, width=200)
        frame16 = ttk.Frame(self.pagePanes)
        frame16.configure(height=200, width=200)
        frame17 = ttk.Frame(frame16)
        frame17.configure(height=200, width=200)
        # select what page we're looking at
        self.pageSelector = ttk.Spinbox(frame17, name="pageselector")
        self.pageSelector.configure(takefocus=False, validate="none", width=3)
        self.pageSelector.configure(takefocus=False, validate="none", width=3, from_=0, to=0)
        _text_ = 0
        self.pageSelector.delete("0", "end")
        self.pageSelector.insert("0", _text_)
        self.pageSelector.pack(anchor="n", side="left")
        # select who is speaking on this page
        self.speakerSelector = ttk.Combobox(frame17, name="speakerselector")
        self.speakerSelector.configure(width=10)
        self.speakerSelector.pack(anchor="n", side="left")
        # select what emotion the sprite will show
        self.emotionSelector = ttk.Combobox(frame17, name="emotionselector")
        self.emotionSelector.configure(width=10)
        self.emotionSelector.pack(anchor="n", side="left")
        frame17.pack(anchor="w", expand=False, side="top")
        # decide if this page has choices at the end
        # only selectable if the node is choice driven
        checkbutton8 = ttk.Checkbutton(frame17)
        self.choiceToggle = tk.StringVar()
        checkbutton8.configure(
            text='Choices @ End',
            variable=self.choiceToggle)
        checkbutton8.pack(anchor="n", side="left")
        checkbutton8.configure(command=self.toggleChoices)
        # allows users to add a choice
        button10 = ttk.Button(frame17)
        button10.configure(default="disabled", text='Add Choice')
        button10.pack(anchor="n", padx=5, side="left")
        button10.configure(command=self.addChoice)
        frame13 = ttk.Frame(frame16)
        frame13.configure(height=200, width=200)
        frame22 = ttk.Frame(frame13)
        frame22.configure(height=200, width=200)
        # the box with the dialog
        entry11 = ttk.Entry(frame22)
        entry11.configure(justify="left", width=50)
        _text_ = 'dialog'
        entry11.delete("0", "end")
        entry11.insert("0", _text_)
        entry11.pack(expand=True, fill="both", side="top")
        frame22.pack(expand=True, fill="both", side="top")
        # save/new/delete
        self.pageEditorButton = ttk.Button(frame13, name="pageeditorbutton")
        self.pageEditorButton.configure(text='Save Changes')
        self.pageEditorButton.pack(anchor="n", side="left")
        self.pageEditorButton.configure(command=self.savePageChanges)
        self.newPageCreator = ttk.Button(frame13, name="newpagecreator")
        self.newPageCreator.configure(text='New Page')
        self.newPageCreator.pack(anchor="n", side="left")
        self.newPageCreator.configure(command=self.createPage)
        self.pageDeleter = ttk.Button(frame13, name="pagedeleter")
        self.pageDeleter.configure(text='Delete Page')
        self.pageDeleter.pack(anchor="n", side="left")
        self.pageDeleter.configure(command=self.deletePage)
        frame13.pack(anchor="w", expand=True, fill="both", side="top")
        frame16.pack(expand=True, fill="both", side="left")
        self.pagePanes.add(frame16, weight="1")
        
        # the pane that will have the choice info
        frame4 = ttk.Frame(self.pagePanes)
        frame4.configure(height=200, width=200)
        self.pageChoiceTabs = ttk.Notebook(frame4, name="pagechoicetabs")
        self.pageChoiceTabs.configure(height=200, width=200)
        self.pageChoiceTabs.pack(expand=True, fill="both", side="top")
        frame4.pack(expand=True, fill="both", side="left")
        self.pagePanes.add(frame4, weight="1")
        self.pagePanes.pack(
            expand=True,
            fill="both",
            padx=10,
            pady=10,
            side="left")
        self.pagesFrame.pack(
            expand=True,
            fill="both",
            padx=10,
            pady=10,
            side="top")
        self.nodeFrame.pack(expand=True, fill="both", side="top")
        self.nodeFrame.pack_propagate(0)
        self.nodePanes.add(self.nodeFrame, weight="1")
        self.nodePanes.pack(expand=True, fill="both", side="left")
        self.treeFrame.pack(side="top")
        mainTabs.add(self.treeFrame, text=f'{name}')
        
        # initializes the node page with a starting node and the tree name
        self.initializeTree()
        
        # for trees, on double click, open selected node
        self.trees = [self.nodeTree, self.toNodeTree, self.fromNodeTree]
        
        
    # initialize the tree's starting values/node
    def initializeTree(self):
        iid = self.nodeTree.insert("", tk.END, text="Start")
        self.parentTree.add_node(dialogNode("Start"))
        self.nodes["Start"] = {'id':iid}
        
    # double click to travel to a selected node
    def onNodeTreeClick(self, event):
        self.onDoubleClick(event, self.nodeTree)
    def onFromNodeTreeClick(self, event):
        self.onDoubleClick(event, self.fromNodeTree)
    def onToNodeTreeClick(self, event):
        self.onDoubleClick(event, self.toNodeTree)
    def onDoubleClick(self, event, tree):
        item = retrieve_tree_selection(tree)
        print("you clicked on", item) #TODO: make it so that node gets travelled to 
        
    def updateTreeName(self):
        pass

    def nodeToggleChoices(self):
        pass

    def saveSelectedNode(self):
        pass

    def deleteSelectedNode(self):
        title = retrieve_text_input(self.nodeTitle)
        print(title)
        if title == "Start":
            showerror('Deletion Impossible', 'Cannot delete starting node!')
        else:
            index = 0
            try:
                index = self.nodeTree.index(self.nodes[title]['id'])
            except:
                showerror('Deletion Impossible', 'Node does not exist!')
                return
            self.parentTree.delete_node(index)

    def targetConnector(self):
        targetName = retrieve_text_input(self.nodeTargetName)
        if len(targetName) <= 0 or targetName == "":
            showerror('Creation Impossible', 'Must provide a name!')
            return
        print(targetName)

    def toggleChoices(self):
        pass

    def addChoice(self):
        pass

    def savePageChanges(self):
        pass

    def createPage(self):
        pass

    def deletePage(self):
        if self.currentPage == 0:
            showerror('Deletion Impossible', 'Cannot delete starting page!')
        

# choice editor
class ChoiceEditor:
    parentPage = None
    def __init__(self, parentPage, pageChoiceTabs=None, master=None):
        self.parentPage = parentPage
        frame5 = ttk.Frame(self.pageChoiceTabs)
        frame5.configure(height=200, width=200)
        frame23 = ttk.Frame(frame5)
        frame23.configure(height=200, width=200)
        self.choiceEmotion = ttk.Combobox(frame23, name="choiceemotion")
        self.choiceEmotion.pack(anchor="n", side="left")
        self.interactionTypeSelector = ttk.Combobox(
            frame23, name="interactiontypeselector")
        self.interactionTypeSelector.configure(
            values='Neutral Positive Negative')
        self.interactionTypeSelector.pack(anchor="n", side="left")
        self.interactionStrengthSelector = ttk.Combobox(
            frame23, name="interactionstrengthselector")
        self.interactionStrengthSelector.configure(values='Weak Normal Strong')
        self.interactionStrengthSelector.pack(anchor="n", side="left")
        frame23.pack(anchor="w", expand=False, fill="x", side="top")
        frame24 = ttk.Frame(frame5)
        frame24.configure(height=200, width=200)
        self.choiceText = ttk.Entry(frame24, name="choicetext")
        _text_ = 'choice text'
        self.choiceText.delete("0", "end")
        self.choiceText.insert("0", _text_)
        self.choiceText.pack(expand=True, fill="both", side="top")
        frame24.pack(anchor="w", expand=True, fill="both", side="top")
        frame26 = ttk.Frame(frame5)
        frame26.configure(height=200, width=200)
        self.choiceTarget = ttk.Entry(frame26, name="choicetarget")
        _text_ = 'ChoiceTarget'
        self.choiceTarget.delete("0", "end")
        self.choiceTarget.insert("0", _text_)
        self.choiceTarget.pack(anchor="n", expand=True, fill="x", side="left")
        self.addChoiceTarget = ttk.Button(frame26, name="addchoicetarget")
        self.addChoiceTarget.configure(text='Add/Set Target')
        self.addChoiceTarget.pack(anchor="n", side="left")
        self.addChoiceTarget.configure(command=self.targetConnector)
        frame26.pack(anchor="w", fill="x", side="top")
        frame28 = ttk.Frame(frame5)
        frame28.configure(height=200, width=200)
        self.choiceEditorButton = ttk.Button(
            frame28, name="choiceeditorbutton")
        self.choiceEditorButton.configure(text='Save Changes')
        self.choiceEditorButton.pack(anchor="n", side="left")
        self.choiceEditorButton.configure(command=self.saveChoice)
        self.choiceDeleter = ttk.Button(frame28, name="choicedeleter")
        self.choiceDeleter.configure(text='Delete Choice')
        self.choiceDeleter.pack(anchor="n", side="left")
        self.choiceDeleter.configure(command=self.deleteChoice)
        frame28.pack(anchor="w", side="top")
        frame5.pack(expand=True, fill="both", ipadx=10, ipady=10, side="top")
        frame5.pack_propagate(0)
        self.pageChoiceTabs.add(frame5, text='Choice1')
        
    def saveChoice(self):
        pass

    def deleteChoice(self):
        pass