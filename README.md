# Blood Altar Automation Script
This is an OpenComputers script to automate the Blood Altar provided by Blood Magic in Minecraft. Specifically, this script is designed to be used in the modpack GT New Horizons.

This script fully automates a single blood altar with a connected Well of Suffering, EEC and World Accelerators for the altar and ritual. It will periodically check an input chest for items, craft them a single time, output the new items, then refill the player's soul network with a blood orb. While idle, it will passively refill the player's soul network.

# Installation
Just copy the lua files in this repo to a folder on an OC computer, either by using the internet card and wget or by copying the file contents one at a file and using the insert key to paste it into an `edit` window. Note that when copying the files manually, only 256 or 257 lines will be inserted.

# Setup
This script contains a lot of functionality, although the underlying principles are simple. The core of the build is a blood altar of arbitrary tier, with a well of suffering and an EEC in ritual mode. World accelerators should be connected to the altar and ritual, but they aren't required. Everything for this build can be placed below the altar, although that makes it slightly more expensive due to the required remote comparator, transvector interface, and MFU.

The OC network must have the following components: a translocator, an adapter, and a redstone I/O. The translocator must be connected to three chests/buffers as well as the altar (altar may be connected through a transvector interface). The adapter must be connected to the altar (may be connected through an MFU). A comparator must read from the altar and feed into the redstone I/O without redstone strength loss (may be a remote comparator).

A line of redstone (ideally red alloy wire) should lead from the redstone I/O to the ritual, world accelerators, and EEC. This line acts as an on/off switch. I prefer to make it `Disable with Redstone` so that a power level cover can be used to shut the system down too, but this is configurable in the config script.

The translocator chests represent the following: an input (fed by an ME interface), a staging buffer (used to store orbs and altar products), and an output (used to push items back to the ME system). The chests can be any size, although the staging chest should be at least a vanilla chest. Blocking mode can be used on the ME interface, although the script will move items from the input chest in stacks. If a stack of 64 slates is inserted into the chest, thhe whole stack will be inserted into the altar. If blocking mode isn't enabled, consider setting stack merging to "Insert to empty slots only" in the interface if the stack size needs to be a specific amount.

Set the stack size in recipes so that your soul network is never close to being empty. The overhead in moving items is a few ticks, so there is little point in optimizing this.

The computers used for my build were tier 3, although lower tiers may work. They have not been tested, but this script isn't very expensive in memory usage. YMMV.

## Configuration
This script comes with a REPL configuration script called `blood_altar_config.lua` which significantly simplifies setup. Running the script and saving will generate the config file `/etc/blood-altar.cfg`. The config can be hand edited, although this is not recommended since the contents are subject to change and there is no documentation for the format. Just read the code if you really want to edit it manually.

Once the script is started, set the various components and the transvector/redstone I/O sides. All options must be set for this script to work. The config script should be fairly self explanatory. If something isn't clear, send me a message on discord or open an issue.

It is not recommended to start the `blood_altar.lua` script on boot, since it does not poll for events and therefore will not respect ctrl + alt + c interrupts.

## How it works
The script has two states, active and idle. The script starts in the active state. In this state, the script will finish whatever item is held in the altar. If this item is a blood orb, it will wait until the owner's soul network is full. Otherwise, it will wait until the item changes, which signifies that a craft has finished. Once the current item has finished, the script will move the item into the staging chest. Any non-orb items will then be moved to the output chest, but a single orb matching the configuration will be kept in the staging chest.

Next, the script will look for an input; if the item in the altar was an orb, it will look for a stack in the input chest. If the item wasn't an orb, it will look for an orb in the staging chest to refill the owner's soul network. While in the active state, the script will keep alternating between orbs and items until all items in the input chest are consumed.

Once the input chest is empty, the script will enter the idle state. In this state, the script will keep a blood orb in the altar. It will periodically check the owner's soul network to see if it needs to be topped up. If the soul network does, the script will activate the altar until the soul network is full.

The script will leave the idle state if an item is detected in the input chest.

If the item in the altar is removed at any time, the script will likely exit. A manual state will be implemented at some point.
