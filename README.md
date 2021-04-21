
# Keyboard Melee

This is a program that enables the use of a keyboard to play Super Smash Bros. Melee. It currently only works on Windows. It is not impossible to get it working on other operating systems, it's just that I don't have other systems to test on and I'm not sure how to intercept and block keyboard input on them. This is a project made for personal use, and while in my opinion it maintains fair practices, it makes no attempt to be tournament legal.

## How It Works

The program is written in Nim (my favorite programming language at the moment). The program is a simple .exe that calls the Windows API directly to intercept, block, and read keyboard input. It can then use that keyboard input to communicate with Slippi directly through Windows named pipes, or it can use the VJoy driver if you have it installed. It will create a config.json file when first run that stores keybinds and various other configuration options.

## How To Use

#### Without VJoy:

If you aren't using VJoy, you must open the Slippi version of Dolphin first, and then launch the .exe. Be aware that when the program is running, it will intercept and block your keyboard input. You can toggle it on and off with the 8 key on your keyboard to get control back. To control Dolphin, you must go into the "Controllers" menu, select "Standard Controller" on the port you want to control, open the "Configure" menu, and in the profile dropdown list on the right, select "slippibot" and click "Load".

#### With VJoy:

To use VJoy, open the config.json file that the program created, and change the  "useVJoy" field to true. You can then follow the same steps as the "Without VJoy" section, except you should load the "B0XX" profile instead of "slippibot".

## The Layout

#### The layout is very similar to the B0XX layout, with a few changes:

- Up is moved to the left hand in standard WASD fashion.
- C Stick inputs are moved to the right index finger. (This isn't ideal but needs to be done to work on a normal keyboard layout)
- B is moved to the right thumb.
- When shielding, analog stick movement is limited to prevent accidental rolls and spotdodges, while also allowing shield dropping by simply pushing down. (Rolling and spotdodging is done with the C Stick)
- While holding either of the analog modifiers, the C Stick buttons become tilt buttons. The A button only outputs neutral attacks. (This functionality is toggleable in the config.json file)
- The main jump button only short hops, while full hops can be performed with the right pinky. (This functionality is toggleable in the config.json file)
- If airdodging straight to the left or the right with the right hand shield button, a long distance waveland/wavedash angle will be performed instead of dodging straight.

## Notes

If you aren't using a mechanical keyboard, you will most likely have problems with key rollover. This means that if you push too many keys at the same time, the keyboard won't register all of them.

My default keybinds depend on there being a Windows key right next to the Right Alt key. A lot of keyboards actually have an FN key there, which is usually the one key that can't be rebound unfortunately. I encourage you to experiment with different keybinds by opening up the config.json file. You can bind multiple keys to one action by separating them with commas. Take a look inside the source code at the "kbdinput.nim" file to find an enum with all of the key names for the keybinds.