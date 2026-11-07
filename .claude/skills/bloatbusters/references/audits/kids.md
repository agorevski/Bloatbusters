# Audit: setting up a phone or tablet for a child

Use this when a parent wants a child's phone or tablet (for example a Samsung Galaxy Tab) to be safer, simpler, and lighter. Most of the protection comes from the official parental-control tools, set up by the parent in Settings. Bloatbusters checks where the device stands, removes clutter and sideloading paths, and guides the rest.

Use only official parental controls (Family Link, Samsung Kids, Kids Space, Digital Wellbeing). Never install third-party monitoring or "spy" apps. They collect a lot of data, many of them are stalkerware (`audits/adware.md`), and they make a device less safe. For teenagers, suggest that the parent talk with the teen about which controls are on.

## 1. Establish the setup

Ask, in one message:

- The child's age (it decides which tools fit) and whether the device is **their own** or **shared** with a parent.
- Whether the child has their own Google account, and whether it is already supervised with Family Link.
- What the parent wants: time limits, app approval, content filtering, no purchases, no ads, simpler home screen, or a locked single app for a young child.

Then check the device:

```bash
adb -s SERIAL shell 'getprop ro.build.characteristics; getprop ro.config.low_ram; getprop ro.product.manufacturer'   # "tablet", low-RAM, OEM
adb -s SERIAL shell pm list users                                                                                      # SKILL.md §3
adb -s SERIAL shell pm list packages --user 0 | grep -iE "kids|familylink|wellbeing" > SESSION/kids_pkgs.txt; cat SESSION/kids_pkgs.txt
adb -s SERIAL shell dumpsys account | grep -oE "type=[A-Za-z0-9._]+" | sort | uniq -c                                  # account types only, never names
```

Matches such as Samsung Kids, Google Kids Space (`com.google.android.apps.kids.home`), and Digital Wellbeing (`com.google.android.apps.wellbeing`, or Samsung's own) show what's available. Package names vary by OEM, so confirm with the user. If anything here looks like a supervision or device-management component, it's in the protected snapshot. Never change it.

**Shared tablet with a separate user for the child:** Bloatbusters changes only user 0 (SKILL.md §3), which is usually the parent. It cannot inspect or change the child's user over ADB. Guide the parent through Settings inside the child's user instead, or suggest Samsung Kids / Kids Space inside the parent's user, which keeps everything in user 0.

**Supervised devices:** Family Link may block Developer options, so USB debugging may be unavailable. The parent may need to allow it in Family Link for the session. Turn it back off at wrap-up (§4).

## 2. Read-only checks

Run the checks from the other audits that matter most on a child's device, and summarize them together:

| Check | Source | Child-device finding |
|---|---|---|
| Install unknown apps grants | `audits/privacy.md` (`REQUEST_INSTALL_PACKAGES`) | Any grant at all. Children's devices should have none |
| Sideloaded apps | `audits/security.md` (`installer=null`) | Any app the parent didn't knowingly install |
| Overlay, full-screen-intent, and notification-heavy apps | `audits/adware.md`, `audits/notifications.md` | Free games with pop-up ads are the most common problem on kids' tablets |
| Third-party launchers or "kids launchers" | `audits/launcher.md` §1 (`query-activities`) | Unknown-publisher kids launchers are a data-collection risk |
| Private DNS | `audits/privacy.md` | Off or Automatic: no family filter in place |
| Developer options / ADB | `audits/security.md` | On because of this session. Must be off afterward |
| Browsers | `pm list packages --user 0` and the BROWSER role from SKILL.md §3 | More than one browser makes filtering harder |
| Patch level and updates | `audits/security.md` | Older tablets often fall out of support first. Say so |

## 3. Recommend

Group the recommendations by tool, Settings-guided unless noted. Each one is a numbered item the parent approves (`reporting.md`).

**Parental-control foundation (pick what fits the age):**

1. **Google Family Link** (all Android devices). The child has their own Google account, supervised from the parent's Family Link app. It covers app approval, daily limits and bedtime, Play content ratings, purchase approval, and device location. Set up on the child's device: Settings → Google → Parental controls. Under-13 accounts are supervised by default in most regions, and teens can opt in.
2. **Samsung Kids** (Galaxy phones and tablets). It's a separate, child-only home screen with its own app list, playtime limits, and a parent PIN to exit. Quick panel → Samsung Kids, or Settings → Digital Wellbeing and parental controls → Samsung Kids. If it's missing, it's in the Galaxy Store. Good for younger children on a shared tablet, because it stays in the parent's user.
3. **Google Kids Space** (only on tablets that ship with it, including Pixel Tablet and several Lenovo and onn. models). It's a kids' home screen tied to a supervised account. It can't be installed on other tablets.
4. **App pinning for toddlers:** lock the screen to one app (for example a video or drawing app) until a PIN is entered. Pixel: Settings → Security & privacy → More security & privacy → App pinning. Samsung: Settings → Security and privacy → More security settings → Pin app. Turn on "Ask for PIN before unpinning".

**Purchases and content:**

5. **Play Store purchase authentication:** Play Store → profile → Settings → Authentication → Require authentication for purchases → For all purchases through Google Play on this device. Family Link purchase approval also covers this for supervised accounts. Galaxy Store has its own setting.
6. **Play Store content ratings:** set in Family Link for supervised accounts, or Play Store → Settings → Family → Parental controls on the device (PIN-protected).
7. **YouTube:** YouTube Kids, or a supervised YouTube experience through Family Link, instead of the regular app.

**Network filtering (optional):**

8. **Private DNS with a family filter** blocks adult content, and many ads, in every app and browser. The parent chooses the provider. Common DNS-over-TLS hostnames: `family.adguard-dns.com` (AdGuard Family), `family.cloudflare-dns.com` (Cloudflare for Families), `family-filter-dns.cleanbrowsing.org` (CleanBrowsing Family). Same trade-offs and procedure as `audits/privacy.md` (two settings, two undo steps, then verify). Anyone who can open Settings can turn it off, so it's a filter, not a lock. It doesn't apply when the device is connected to a VPN.

**Close sideloading and stranger paths:**

9. **Turn off "Install unknown apps"** for every app that has it (Settings → Apps → Special app access → Install unknown apps, or the AppOps change in `audits/security.md`).
10. **Samsung Auto Blocker** (One UI 6+): turn it back on after the session (Settings → Security and privacy → Auto Blocker). It blocks app installs from unauthorized sources and commands over USB. It also blocks USB debugging, so it must be off again to run `undo.sh` later. Tell the parent.
11. **Quick Share / Nearby Share:** set "Who can share with you" to Contacts or Your devices, not Everyone. Pixel: Settings → Connected devices → Connection preferences → Quick Share. Samsung: Quick panel → Quick Share → Contacts only.
12. **Lock screen:** make sure a PIN is set, so the device can't be reset or reconfigured without the parent, and so app pinning is meaningful.

**Lighter and calmer:**

13. Remove or disable apps the child shouldn't use or doesn't need: duplicate browsers, preinstalled social, shopping, and trial apps, and game hubs (`audits/unused-apps.md`, `changes.md`). Family Link "block app" is an alternative the parent controls from their own phone.
14. Silence game and promo notifications (`audits/notifications.md`). Turn on bedtime / wind-down in Digital Wellbeing.
15. On low-RAM tablets, apply the `audits/launcher.md` §2 steps. Don't install a third-party launcher as a "kids mode"; use items 2–4 instead.
16. Kids' tablets that live on a charger: turn on charging protection (`audits/battery.md`).

## 4. Wrap-up for a child's device

In addition to SKILL.md §4:

- Turn off **USB debugging, Wireless debugging, and Developer options**, and revoke USB debugging authorizations. A child's device should not stay open to ADB. Tell the parent that `undo.sh` needs USB debugging (and, on Samsung, Auto Blocker off) temporarily.
- If Family Link allowed Developer options for this session, switch that back.
- List which controls are now on and where the parent manages each one (Family Link app, Samsung Kids parental controls, Play Store settings, Private DNS).
