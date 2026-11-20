# Projectile Tracker

Projectile Tracker is a small World of Warcraft: Forever addon (interface 16001). It displays the remaining stack count from the character's Ammo slot, with an arrow or bullet icon based on the equipped ammo type.

## Install

Copy the `ProjectileTracker` folder into `Interface/AddOns` in your WoW: Forever installation. The folder should contain `ProjectileTracker.toc`, `ProjectileTracker.lua`, and `ProjectileTrackerIcon.png`. Enable it on the character selection screen.

## Use

- Click the minimap button to open options. It registers with LibDBIcon when that library is available for broad minimap-collector compatibility, and otherwise uses a standalone draggable button.
- Use the options to show or hide the counter, ammo icon, background and border; choose a background colour and opacity; and set the font size.
- Enable **Move counter** to drag the counter. With this disabled, the counter is click-through. Its position is saved between sessions. The options panel is scaled up for easier reading.

The display starts centered near the lower middle of the screen, with white text, a dark translucent background, a subtle border, and compact spacing. The counter uses the in-game arrow and bullet artwork.

The addon icon is ProjectileTrackerIcon.png; it is also used by the minimap button.
