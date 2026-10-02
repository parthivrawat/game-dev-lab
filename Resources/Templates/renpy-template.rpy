# Visual Novel Template — a Ren'Py skeleton for the VN track.
# Copy this file as game/script.rpy into a new Ren'Py project, then
# replace the story labels with your own.
#
# This template runs with ZERO image files — it defines placeholder
# art in code. When you have real art, drop PNGs into game/images/
# with matching names and delete the `image` lines below:
#     images/bg room.png
#     images/eileen happy.png
#     images/eileen concerned.png


## ---- Placeholder images ----------------------------------------------------
## Ren'Py auto-loads game/images/*.png by filename. These `image` statements
## stand in for real art so the script runs standalone — a scene/show command
## errors if its image isn't defined, so never ship a script without these
## (or the real files).

image bg room = Solid("#2e2e44")
image eileen happy = Text("Eileen\n:)", size=40, color="#c8ffc8", text_align=0.5)
image eileen concerned = Text("Eileen\n:(", size=40, color="#ffc8c8", text_align=0.5)


## ---- Characters -------------------------------------------------------------
## Short name = Character("Display Name", color="#rrggbb")

define e = Character("Eileen", color="#c8ffc8")
define m = Character("You", color="#c8c8ff")
## Narrator needs no definition — a bare "..." line is narration.


## ---- Game variables ----------------------------------------------------------
## `default` (not `$ x = ...`) marks variables Ren'Py should save/rollback.

default friendship = 0
default has_key = False


## ---- Story --------------------------------------------------------------------
## `label start:` is where every Ren'Py game begins.

label start:

    scene bg room
    with dissolve

    show eileen happy
    e "Hello! Welcome to your first visual novel."

    "She waits for your answer."

    menu:
        "What do you say?"

        "Say hello back.":
            m "Hi! Great to be here."
            $ friendship += 1
            e "Nice to meet you!"

        "Stay silent.":
            e "Oh... the quiet type. Interesting."
            $ friendship -= 1

    jump explore_room


label explore_room:

    "There's a small brass key on the table."

    menu:
        "Take the key?"

        "Take it.":
            $ has_key = True
            "You pocket the key. It feels heavier than it looks."

        "Leave it.":
            "You leave the key where it lies."

    jump ending_check


label ending_check:
    ## Branch on the state you've built — this is the whole VN trick:
    ## choices set variables, variables pick endings.

    if has_key and friendship > 0:
        jump ending_good
    elif has_key:
        jump ending_neutral
    else:
        jump ending_bad


label ending_good:
    ## show eileen happy
    e "You got the key AND you were nice about it."
    e "Best ending unlocked!"

    ## A `label` does NOT stop execution — without `return` (or `jump`)
    ## the script falls through into the next label and every ending
    ## would play in sequence.


label ending_neutral:
    ## show eileen concerned
    e "You have the key, but... you could have been friendlier."
    e "Neutral ending."


label ending_bad:
    ## show eileen concerned
    e "No key, no hello. A bold strategy."
    e "Bad ending."
