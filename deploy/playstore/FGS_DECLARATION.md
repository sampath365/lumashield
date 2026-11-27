# Foreground service declaration (FOREGROUND_SERVICE_SPECIAL_USE)

Play Console asks for this under **Policy → App content → Foreground service
permissions** because the manifest declares
`android.permission.FOREGROUND_SERVICE_SPECIAL_USE`.

## 1. Which task to select

Select **Other**. None of the predefined categories fit: this is not media
playback, location, camera, microphone, data sync, connected device, health or
remote messaging. The service exists to keep a screen overlay alive.

Then paste the text from section 2 into the description box.

## 2. Description (paste this)

> LumaShield is a blue light filter. The service keeps a non touchable overlay
> drawn above other apps so the user's screen stays warm while they read, watch
> or work in any app. It starts the moment the user enables protection or a
> scheduled boundary arrives at sunset, because the benefit is continuous:
> pausing would expose the user to full blue light mid session, and restarting
> would flash the screen. The overlay and the notification are removed the
> moment protection is turned off.

If the field accepts more text, use this longer version:

> LumaShield is a blue light filter for eye comfort. While protection is on, a
> foreground service holds a full screen overlay (TYPE_APPLICATION_OVERLAY) that
> tints every app with a warm, adjustable colour. The overlay is not touchable
> and does not read screen content; it only dims and warms the display.
>
> The task must start immediately and run continuously:
>
> - The user enables the filter, or a schedule boundary (sunset or a custom
>   time) fires, and protection is expected from that second. Delaying it means
>   the user keeps reading under blue light they asked to remove.
> - The overlay has to stay while the user switches between apps. Stopping and
>   restarting the service on every app switch would flash the screen and lose
>   the user's place in their work.
> - Pausing is user initiated only, through the notification action or the app,
>   which removes the overlay immediately and stops the service. Nothing is left
>   running in the background.
>
> Battery cost is deliberately minimal: the service does no polling, draws one
> static view and updates once a minute for the eye comfort score.

## 3. Video

Two options:

**A. Record it on your phone (best for the declaration).** 30 to 60 seconds,
screen recording only, no narration. Upload as **unlisted** on YouTube and paste
the link.

**B. Use the generated demo** at `deploy/playstore/video/fgs-demo.mp4`
(22 seconds, 1080x1920, built by `python3 tool/video/build_fgs_demo.py`). It is
composed from the app's own screenshots plus a mock browser tinted with the same
colour maths, so it shows the behaviour accurately, but it is not a literal
device recording. Use it for the store listing or social posts; if you submit it
for the declaration, say that it is a product demo rather than a screen capture.

Shot list for option A:

Shot list:

| Time | Do this | The reviewer sees |
| --- | --- | --- |
| 0:00 | Open LumaShield, filter on, drag the ring to 100% | the app and the warm setting |
| 0:06 | Press Home, open Chrome or Photos | the whole screen is warm, including another app |
| 0:14 | Pull the notification shade, tap **Pause** | the tint disappears while still in Chrome |
| 0:20 | Tap **Resume** | the tint returns immediately |
| 0:26 | Switch to a second app (YouTube, Settings) | the tint follows across apps |
| 0:34 | Open LumaShield and turn protection off | overlay gone, notification gone |
| 0:40 | End | |

Tips that get these approved:

- Keep the video under one minute and show the notification action; that is the
  proof the user controls it.
- Do not add music or claims about health benefits.
- Show the real device, not an emulator.
- Make sure the tint is obvious: 100% reduction at 1900K is unmistakable on
  camera.

## 4. If the declaration is rejected

Play occasionally rejects SPECIAL_USE for filters. If that happens, reply in the
appeal thread with the same explanation plus the video and the fact that the
service stops the moment the overlay is removed. A second option is to ship the
same app without a foreground service (the overlay still works, but Android may
kill it under memory pressure) and drop the permission; that is a worse
experience for the user, so appeal first.
