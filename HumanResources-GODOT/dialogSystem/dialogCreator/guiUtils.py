from tkinter import *
from tkinter import ttk
import sys
import os

def hide_widget(widget):
    widget.pack_forget()
def show_widget(widget):
    widget.pack()
def delete_widget(widget):
    widget.destroy()