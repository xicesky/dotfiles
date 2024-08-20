#!/bin/bash

session="mx-initial"

if ! tmux list-sessions | grep -q "$SESSION" ; then
    # Start New Session with our name
    tmux new-session -d -s "$session"

    # Name first Window and start zsh
    tmux rename-window -t "$session:1" 'Main'
    tmux send-keys -t 'Main' 'zsh' C-m 'clear' C-m

    # Create new pane for chrome
    tmux new-window -t "$session:2" -n 'Chrome'
    tmux send-keys -t 'Chrome' 'google-chrome' C-m

    # Create new pane for idea
    tmux new-window -t "$session:3" -n 'Idea'
    tmux send-keys -t 'Idea' 'idea' C-m
fi

# Attach Session, on the Main window
tmux attach-session -t "$session:1"
