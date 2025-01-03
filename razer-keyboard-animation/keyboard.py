import time
import colorsys
import random
from pynput.keyboard import Key, Listener

from openrazer.client import DeviceManager
from openrazer.client import constants as razer_constants
# from openrazer_daemon.keyboard import KEY_MAPPING

color_reactive = (5, 80, 50)
colors_reactive = [(5, 80, 50), (20, 56, 70), (30, 75, 150)]
color_static = (0, 15, 55)

KEY_MAPPING = { "Key.esc" : (0, 1),
                "Key.f1" : (0, 3),
                "Key.f2" : (0, 4),
                "Key.f3" : (0, 5),
                "Key.f4" : (0, 6),
                "Key.f5" : (0, 7),
                "Key.f6" : (0, 8),
                "Key.f7" : (0, 9),
                "Key.f8" : (0, 10),
                "Key.f9" : (0, 11),
                "Key.f10" : (0, 12),
                "Key.f11" : (0, 13),
                "Key.f12" : (0, 14),
                "Key.print_screen" : (0,15),
                "Key.scroll_lock" : (0,16),
                "Key.pause" : (0,17),
                "Key.media_volume_down" : (0,21),
                "Key.media_volume_up" : (0,21),
                "['^']" : (1,1),
                "'1'" : (1,2),
                "'2'" : (1,3),
                "'3'" : (1,4),
                "'4'" : (1,5),
                "'5'" : (1,6),
                "'6'" : (1,7),
                "'7'" : (1,8),
                "'8'" : (1,9),
                "'9'" : (1,10),
                "'0'" : (1,11),
                "'ß'" : (1,12),
                "['´']" : (1, 13),
                "Key.backspace" : (1,14),
                "Key.tab" : (2,1),
                "'q'" : (2,2),
                "'w'" : (2,3),
                "'e'" : (2,4),
                "'r'" : (2,5),
                "'t'" : (2,6),
                "'z'" : (2,7),
                "'u'" : (2,8),
                "'i'" : (2,9),
                "'o'" : (2,10),
                "'p'" : (2,11),
                "'ü'" : (2,12),
                "'+'" : (2,13),
                "Key.caps_lock" : (3,1),
                "'a'" : (3,2),
                "'s'" : (3,3),
                "'d'" : (3,4),
                "'f'" : (3,5),
                "'g'" : (3,6),
                "'h'" : (3,7),
                "'j'" : (3,8),
                "'k'" : (3,9),
                "'l'" : (3,10),
                "'ö'" : (3,11),
                "'ä'" : (3,12),
                "'#'" : (3,13),
                "Key.shift" : (4,1),
                "'<'" : (4,2),
                "'y'" : (4,3),
                "'x'" : (4,4),
                "'c'" : (4,5),
                "'v'" : (4,6),
                "'b'" : (4,7),
                "'n'" : (4,8),
                "'m'" : (4,9),
                "','" : (4,10),
                "'.'" : (4,11),
                "'-'" : (4,12),
                "Key.shift_r" : (4,14),
                "Key.up" : (4,16),
                "Key.ctrl" : (5,1),
                "Key.cmd" : (5,2),
                "Key.alt" : (5,3),
                "Key.space" : (5,7),
                "<65027>" : (5,11),
                "Key.menu" : (5,14),
                "Key.left" : (5,15),
                "Key.down" : (5,16),
                "Key.right" : (5,17),
                "Key.ctrl_r" : (5,14),
}


# Create a DeviceManager. This is used to get specific devices
device_manager = DeviceManager()

print("Found {} Razer devices".format(len(device_manager.devices)))

devices = device_manager.devices
for device in devices:
    if not device.fx.advanced:
        print("Skipping device " + device.name + " (" + device.serial + ")")
        devices.remove(device)

# Disable daemon effect syncing.
# Without this, the daemon will try to set the lighting effect to every device.
device_manager.sync_effects = False

def reactivePress(key):
    for device in devices:
        if device.name == "Razer Mamba Tournament Edition":
            continue
        try:
            xy = KEY_MAPPING.get(str(key))
            device.fx.advanced.matrix[xy[0], xy[1]] = color_reactive
            update()
        except Exception as e:
            print(e)
            continue

def reactiveRelease(key):
    for device in devices:
        if device.name == "Razer Mamba Tournament Edition":
            continue
        try:
            xy = KEY_MAPPING.get(str(key))
            device.fx.advanced.matrix[xy[0], xy[1]] = color_static
            update()
        except Exception as e:
            print(e)
            continue

def default():
    # Set random colors for each zone of each device
    for device in devices:
        if device.name == "Razer Mamba Tournament Edition":
            continue
        rows, cols = device.fx.advanced.rows, device.fx.advanced.cols

        for row in range(rows):
            for col in range(cols):
                device.fx.advanced.matrix[row, col] = color_static
        update()

def update():
    device.fx.advanced.draw()
default()

def on_press(key):
    reactivePress(key)

def on_release(key):
    reactiveRelease(key)



# Set random colors for each zone of each device
for device in devices:
    if device.name == "Razer Mamba Tournament Edition":
        continue
    rows, cols = device.fx.advanced.rows, device.fx.advanced.cols
    for row in range(rows):
        for col in range(cols):
            device.fx.advanced.matrix[row, col] = color_static

    while True:
        active = []
        for i in range(random.randint(0, 10)):
            r = random.randint(0, rows - 1)
            c = random.randint(0, cols - 1)
            device.fx.advanced.matrix[r, c] = random.choice(colors_reactive)
            active.append([r, c])
            update()
            time.sleep(0.05)
        for j in range(random.randint(0, len(active))):
            choice = random.choice(active)
            #active.remove(choice)
            device.fx.advanced.matrix[choice[0], choice[1]] = color_static
            update()
            time.sleep(0.05)


# Collect events until released
#with Listener(
#        on_press=on_press,
#        on_release=on_release) as listener:
#    listener.join()
#
