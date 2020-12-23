---
title: Using adb to transfer an Android app (apk and obb files) between devices
tags: [android, linux]
date: 2020-12-23
language: en
...

**Backstory:** I have a (Amazon - so FireOs technically) tablet and want to have
a specific app (Lego Boost Star Wars) on that device.  The app is available for
download via the Google Play Store.  I can install the app on my smartphone.
Installing the app via the Play Store on the table requires me to install the
Google Play Store app on the tablet first.  There are howto's for that; but in
the case of that specific tablet it just didn't work.  And: Installing the Play
Store app (and the required other Google apps) seems like a bit of an *overkill*
for just getting one app to that device.  Alternatively I could trust one of the
hundreds of more or less shady online Play Store download and totally not virus
transmission serivces. *No thank you.*

*I can install the app on my smartphone.*

Well ... am I able to get the app "out" of my smartphone and "in" the tablet?
**Yes!**  As it turns out this was fairly easy once I knew about the correct
paths. *Step by step:*

1. Preparation: Enable developer settings / mode on both devices; enable USB
   debugging and connect to laptop (running Linux; should work the same on
   Windows though) with a working adb installation.
2. Find the APK of the app on the phone:  Use `adb -t <TRANSPORT_ID_PHONE> shell`
   to open a shell on the phone, then enter `pm list packages -f | grep lego` to
   get the location of the apk file:

   ~~~
   #phone# pm list packages -f | grep lego
   package:/data/app/com.lego.boost.boost-92CgdA2ln-n4V_2TXlhQTA==/base.apk=com.lego.boost.boost
   package:/data/app/com.lego.boost.starwars-nNr5IayJsqUaHo9FIUU-lQ==/base.apk=com.lego.boost.starwars
   ~~~

   The second line is for the app (the first is of another lego app).  The
   syntax is:

   ~~~
   package:<PATH-to-APK>=<APP-IDENTIFIER>
   ~~~

   (If someone knows the correct term for `APP-IDENTIFIER` please let me know!)
3. Pull the APK from the phone to the laptop:

   ~~~
   #laptop# adb -t <TRANSPORT_ID_PHONE> pull <PATH-to-APK> the.apk
   ~~~
4. Install the APK on the tablet:

   ~~~
   #laptop# adb -t <TRANSPORT_ID_TABLET> install the.apk
   ~~~
5. In case of the Lego Boost Star Wars app (which is built with Unity) there
   is an additional OBB file (with all the data in it) which needs to be
   transferred.  OBB files are in `/storage/self/primary/Android/obb/<APP-IDENTIFIER>` on my
   smartphone and tablet.

   ~~~
   #laptop# adb -t <TRANSPORT_ID_PHONE> pull /storage/self/primary/Android/obb/com.lego.boost.starwars/main.10025.com.lego.boost.starwars.obb
   #laptop# adb -t <TRANSPORT_ID_TABLET> shell
   #tablet# mkdir /storage/self/primary/Android/obb/com.lego.boost.starwars
   #tablet# exit
   #laptop# adb -t <TRANSPORT_ID_TABLET> push main.10025.com.lego.boost.starwars.obb /storage/self/primary/Android/obb/com.lego.boost.starwars/
   ~~~

*Done.*

**Attention:** This only works because my phone and tablet are both relatively
compatible architectures.  Otherwise the native part of the app (remember: Unity,
so there are native libraries/JNI involved) wouldn't be able to run.
