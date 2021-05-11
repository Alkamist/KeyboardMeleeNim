# Keyboard Melee

This is a program that enables the use of a keyboard to play Super Smash Bros. Melee. It currently only works on Windows. It is not impossible to get it working on other operating systems, it's just that I don't have other systems to test on and I'm not sure how to intercept and block keyboard input on them. This is a project made for personal use, and while in my opinion it maintains fair practices, it makes no attempt to be tournament legal.

## How It Works

The program is written in Nim (my favorite programming language at the moment). The program is a simple .exe that calls the Windows API directly to intercept, block, and read keyboard input. It can then use that keyboard input to communicate with Slippi directly through Windows named pipes, or it can use the VJoy driver if you have it installed. It will create a config.json file when first run that stores keybinds and various other configuration options.

## Controlling Dolphin

#### Without VJoy:

If you aren't using VJoy, you must open the Slippi version of Dolphin FIRST, and then launch KeyboardMelee. Be aware that when the program is running, it will intercept and block your keyboard input. You can toggle it on and off with the 8 key on your keyboard to get control back. To control Dolphin, you must go into the "Controllers" menu, select "Standard Controller" on the port you want to control, open the "Configure" menu, and in the profile dropdown list on the right, select "slippibot" and click "Load".

#### With VJoy:

To use VJoy, open the config.json file that the program created, and change the  "useVJoy" field to true. You can then follow the same steps as the "Without VJoy" section, except you should load the "B0XX" profile instead of "slippibot". It is best to launch KeyboardMelee first in this case so Dolphin calibrates properly.

## How To Use

#### Left Hand Placement

Rest your left pinky on Caps Lock, and your thumb on the Space Bar. The rest of your fingers will use WASD like in most computer games.

#### Right Hand Placement

Rest your right pinky on Back Slash, thumb on Right Alt, ring finger on Right Bracket, middle finger on Left Bracket, and index finger on Semicolon.

#### Actions

The following are the controller functions that you can bind to keyboard keys:

- **Left**: Fast movement of the analog stick to the left.
- **Right**: Fast movement of the analog stick to the right.
- **Down**: Fast movement of the analog stick downward.
- **Up**: Slow movement of the analog stick upward. (to avoid tap jump)
- **SoftLeft**: Slow movement of the analog stick to the left.
- **SoftRight**: Slow movement of the analog stick to the right.
- **Mod1**: Limit analog stick movement to special angles that are longer in the X direction.
- **Mod2**: Limit analog stick movement to special angles that are longer in the Y direction.
- **CLeft**: Fast movement of the C stick to the left.
- **CRight**: Fast movement of the C stick to the right.
- **CDown**: Fast movement of the C stick downward.
- **CUp**: Fast movement of the C stick upward.
- **ShortHop**: Short hop or Y, depending on whether or not the short hop macro is active.
- **FullHop**: Full hop or X, depending on whether or not the short hop macro is active.
- **A**: A button.
- **B**: B button.
- **UpB**: Analog stick up and then B one frame later.
- **Z**: Z button.
- **Shield**: L button and some logic to allow shield dropping and prevent accidental rolls and spot dodges.
- **ToggleLightShield**: While holding shield, switch to full light shield.
- **AirDodge**: R button and some logic to enable easier wavedashing/wavelanding.
- **Start**: Start button.
- **DLeft**: D Left button.
- **DRight**: D Right button.
- **DDown**: D Down button.
- **DUp**: D Up button.
- **ChargeSmash**: Holding this will make the C stick directions charge smashes.

## Notes

If you aren't using a mechanical keyboard, you will most likely have problems with key rollover. This means that if you push too many keys at the same time, the keyboard won't register all of them.

My default keybinds depend on there being a Windows key right next to the Right Alt key. A lot of keyboards actually have an FN key there, which is usually the one key that can't be rebound unfortunately. I encourage you to experiment with different keybinds by opening up the config.json file. You can bind multiple keys to one action by separating them with commas. Take a look inside the source code at the "kbdinput.nim" file to find an enum with all of the key names for the keybinds.