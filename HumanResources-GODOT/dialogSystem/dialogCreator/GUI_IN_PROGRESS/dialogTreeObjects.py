import sys

# dialog tree object to store all the nodes and print to file
class dialogTree:
    def __init__(self, title, inputDict=None):
        self.title = title
        self.nodes = []
        self.key = "dialog"
        self.title = "None"
        if inputDict != None:
            self.from_dict(inputDict)
    def __str__(self):
        string = '{\n\t' + f'"{self.key}": \n\t' + '{\n\n'
        nodeString = [f'\t\t{str(node)}' for node in self.nodes]
        nodeString = ',\n\n'.join(nodeString)
        string = string + nodeString + "\n\n\t}\n}"
        return string
    def set_custom_key(self, key):
        self.key = key
    def add_node(self, node):
        self.nodes.append(node)
    def delete_node(self, index):
        node = self.nodes.pop(index, None)
        del node
    def from_dict(self, inputDict):
        # keys are node titles
        for key in inputDict.keys():
            self.nodes.append(dialogNode(key, inputDict[key]))
    def create_file(self, filepath):
        filepath = filepath + f'/{self.title}.json'
        stdout_default = sys.stdout
        with open(filepath, 'w') as f:
            sys.stdout = f
            print(self)
            sys.stdout = stdout_default
    
# dialog node object to store related pages, allow choice traversal
class dialogNode:
    def __init__(self, title, inputDict=None):
        self.title = title
        self.pages = []
        self.newPagesPossible = True
        self.toNodes = set([])
        self.fromNodes = set([])
        if inputDict != None:
            self.from_dict(inputDict)
    def __str__(self):
        # dialog last page will be relevant
        if len(self.pages) > 0:
            self.pages[-1].lastPage = True
        string = f'\t"{self.title}": \n\t\t\t[\n'
        pageString = [f'{str(page)}' for page in self.pages]
        pageString = ',\n'.join(pageString)
        string = string + pageString + "\n\t\t\t]"
        return string
    def connect_to(self, node):
        self.toNodes.add(node)
        node.fromNodes.add(self)
    def connect_from(self, node):
        self.fromNodes.add(node)
        node.toNodes.add(self)
    def print_title(self):
        return self.title
    def add_page(self, page):
        self.pages.append(page)
    def delete_page(self, index):
        self.pages.pop(index, None)
        del page
    def toggle_new_pages(self):
        self.newPagesPossible = not self.newPagesPossible
    def from_dict(self, inputDict):
        for page in inputDict:
            self.pages.append(dialogPage(self, page))

# dialog page object to store actual dialog data
class dialogPage:
    def __init__(self, parent_node, inputDict=None):
        self.parent_node = parent_node
        self.choices = []
        self.hasChoices = False
        self.lastPage = False
        self.speaker = "none"
        self.emotion = "none"
        self.text = "filler"
        self.target = None
        if inputDict != None:
            self.from_dict(inputDict)
    def __str__(self):
        string = [  
                    f'\n\t\t\t\t\t"speaker":"{self.speaker}"',
                    f'\t\t\t\t\t"emotion":"{self.emotion}"',
                    f'\t\t\t\t\t"text":"{self.text}"'
                 ]
        if self.target != None:
            string.append(f'\t\t\t\t\t"target":"{self.target}"')
        # if there are any choices, append them
        # choices only displayed on last page in node as they cause branching
        elif len(self.choices) > 0:
            choiceString = [f'{str(choice)}' for choice in self.choices]
            choiceString = ',\n'.join(choiceString)
            choiceString = '\t\t\t\t\t"choices":\n\t\t\t\t\t[\n' + choiceString + '\n\t\t\t\t\t]'
            string.append(choiceString)
        string = ',\n'.join(string)
        string += '\n\t\t\t\t}'
        return '\t\t\t\t{' + string
    def set_speaker(self, speaker):
        self.speaker = speaker
    def set_emotion(self, emotion):
        self.emotion = emotion
    def set_text(self, text):
        self.text = text
    def add_choice(self, choice):
        self.choices.append(choice)
        self.hasChoices = True
    def delete_choice(self, index):
        choice = self.choices.pop(index, None)
        del choice
        if len(self.choices) == 0:
            self.hasChoices = False
    def from_dict(self, inputDict):
        self.set_speaker(inputDict['speaker'])
        self.set_emotion(inputDict['emotion'])
        self.set_text(inputDict['text'])
        if 'target' in inputDict.keys():
            self.target = inputDict['target']
        elif 'choices' in inputDict.keys():
            for choice in inputDict['choices']:
                self.choices.append(dialogChoice(self.parent_node, choice))
        
# dialog choice object to store choice data/outcomes
class dialogChoice:
    def __init__(self, parent_node, inputDict=None):
        self.parent_node = parent_node
        self.text = "filler"
        self.emotion = "default"
        self.consequence = "none"
        self.target_node = None
        if inputDict != None:
            self.from_dict(inputDict)
    def __str__(self):
        string = [
                    '\t\t\t\t\t\t{',
                    f'\t\t\t\t\t\t"emotion":"{self.emotion}",',
                    f'\t\t\t\t\t\t"text":"{self.text}",',
                    f'\t\t\t\t\t\t"consequence":"{self.consequence}",',
                    f'\t\t\t\t\t\t"target":"{self.target_node}"'
                 ]
        string = '\n\t'.join(string)
        string += '\n\t\t\t\t\t\t}'
        return string
    def set_emotion(self, emotion):
        self.emotion = emotion
    def set_text(self, text):
        self.text = text
    def set_consequence(self, consequence):
        self.consequence = consequence
    def set_target_node(self, node):
        self.target_node = node
    def from_dict(self, inputDict):
        self.set_emotion(inputDict['emotion'])
        self.set_text(inputDict['text'])
        self.set_consequence(inputDict['consequence'])
        self.set_target_node(inputDict['target'])