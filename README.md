![Caffeguard](docs/banner.png)

# Caffeguard

You keep your Mac awake with `caffeinate`, Amphetamine, KeepingYouAwake, Lungo, Theine,
Caffeinated or Raycast Coffee, so it does not go to sleep. You walk away. Someone sits
down at it.

Caffeguard catches them. It lives in your menu bar as a little shield. When your Mac is
kept awake and nobody has touched it for a few minutes, Caffeguard starts watching through
your webcam. If someone looks at the camera, it takes their photo, saves it, and turns every
screen into an intrusion alert. The default screen is bright red.

That's it.

## How to install

1. Download the `.dmg` file from the [latest release](../../releases/latest).
2. Open it and drag Caffeguard into Applications.
3. Open Caffeguard. It is signed and notarized by Apple, so it opens like any other app.
4. Pick the camera you want it to use and allow camera access. iPhone cameras are never
   offered.

## How to use it

1. Keep your Mac awake the way you normally do: `caffeinate`, Amphetamine, Raycast,
   anything. Caffeguard notices on its own. Apps that keep the Mac awake for their own
   reasons, like a video call or music, count too, because the Mac stays unlocked then
   as well.
2. Walk away.
3. After 5 minutes (you can change this) of nobody touching the Mac, the shield in the menu bar fills in. It is
   watching now.
4. If someone sits down and looks at the screen, they get an intrusion alert and you get their
   photo in `~/Pictures/Caffeguard`, or the folder you choose in **Settings… → General**.
5. The alert only goes away with your fingerprint (Touch ID) or your Mac password.
   Until then it keeps watching: if that person runs off and someone else sits down later,
   you get a photo of them too.

Things to know:

- Typing does not turn it off, because an intruder would type too. Letting the Mac sleep
  again turns it off, and so does unchecking **Enabled** in the menu.
- It will catch you too when you come back. Unlock the alert with your fingerprint,
  or uncheck **Enabled** before you leave the Mac awake and walk off.
- One person sitting there is one photo. A new photo needs the seat to be empty for 30
  seconds first.
- After you unlock the alert, it waits another quiet period before it watches again.
- Change the camera or the waiting time in **Settings…** from the menu bar shield. The
  waiting time can be anything from 1 second up, under **Custom**.
- **Settings → Intrusion Screen** has 20 themes for the red screen (Terminal, Crime Scene,
  Judgy Cat, Royal Decree and more), and you can put your own picture behind it. It can
  also play an alarm and lock the Mac.
- The menu shows when it last caught someone, with a little photo. Click it to open the photo.
- Turn on **Open at Login** so it is always running.
- Choose a photo destination in **Settings… → General**. Changing the folder only affects
  new photos; existing photos stay where they are. **Show Photos in Finder** opens the
  selected folder, and the last photo is read from there when the app starts.
- The camera is off unless it is watching. It never records video.

## Keep-awake apps

Caffeguard detects active macOS requests to prevent system or display sleep, so there
is nothing to configure for each keep-awake app. These include:

- `caffeinate`, built into macOS.
- [Amphetamine](https://apps.apple.com/app/amphetamine/id937984704).
- [KeepingYouAwake](https://keepingyouawake.app/).
- [Lungo](https://sindresorhus.com/lungo).
- [Theine](https://appahead.studio/apps/theine/).
- [Caffeinated by Yugen](https://apps.apple.com/app/id1362171212).
- [Raycast Coffee](https://www.raycast.com/mooxl/coffee).

Start a keep-awake session that prevents system or display sleep. KeepingYouAwake and
Raycast Coffee use `caffeinate` underneath and are detected through that process.
Paused or ended sessions do not count. Apps can be installed outside `/Applications`
or run through helpers; their names and locations do not need to match a list.

For Raycast Coffee, enable **Prevent system sleep** or **Prevent display sleep**.
Disk-only assertions and tools that only simulate mouse or keyboard input are not
supported triggers. Simulated input can also reset the idle timer, delaying arming.

## Intrusion screen

Open **Settings… → Intrusion Screen** to choose from 20 themes, add a wallpaper, and
write the message shown to an intruder. Leave the message blank to use the selected
theme’s message. The preview updates as you edit, and your choices are saved for the
next alert on every connected display.

Choose how to start verification: **Double-click**, **Any key**, or **Double-click or
any key** (the default). A single click does not start verification. Touch ID or your
Mac password is required to dismiss the alert; cancelling verification keeps the alert
visible. If **Lock the Mac** is enabled, logging back in also dismisses the alert.

## iMessage alerts

Caffeguard can text you each photo through this Mac's Messages app. In **Settings → Alerts**,
turn on **Text me a photo of each intrusion**, type your phone number or Apple ID, and click
**Send Test Message**. The first time, macOS asks to let Caffeguard control Messages; say yes.

## Email alerts

Caffeguard can email you each photo the moment it takes it, so you see who it was even if
they delete the file.

1. Turn on 2-Step Verification for your Google account, then
   [create an app password](https://myaccount.google.com/apppasswords). It is 16 letters.
2. Open **Settings… → Alerts** from the menu bar shield, turn on **Email me a photo of each
   intrusion**, and type your Gmail address and the app password.
3. Click **Send Test Email** to check it works.

The email goes from your Gmail address to itself. The app password is kept in your Mac's
keychain. Nothing is sent anywhere unless you turn this on.

## Build it yourself

You need macOS 15 or newer and Xcode.

```sh
swift test               # run the tests
scripts/install.sh       # build and install into /Applications
scripts/dmg.sh           # build build/Caffeguard-<version>.dmg
scripts/release.sh       # tag and publish a GitHub release with the DMG
```

The version number lives in `Support/Info.plist`. The icon and the DMG background are drawn
by `swift scripts/artwork.swift`.

## Releasing

Releases are signed with a Developer ID and notarized by Apple, so the DMG opens without
warnings. One-time setup on the Mac that builds releases:

1. Xcode → Settings → Accounts → your team → **Manage Certificates…** → **+** →
   **Developer ID Application**.
2. Create an app-specific password at [account.apple.com](https://account.apple.com), then:

   ```sh
   xcrun notarytool store-credentials caffeguard \
       --apple-id you@example.com --team-id YOURTEAMID --password <app-specific password>
   ```

After that, bump the version in `Support/Info.plist`, commit, push, and run
`scripts/release.sh`.
