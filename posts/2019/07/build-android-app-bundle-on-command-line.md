---
title: Build an Android App Bundle (*.aab) from the command line
date: 2019-07-11
language: en
tags: android
...

Here's how I'm building an Android App Bundle (*.aab) file from the command line,
without Gradle:

1. Get the necessary tools: `aapt2` and `bundletool`.  `aapt2` is the
   second version of the Android Asset Packaging Tool.  It's available
   (I used manual download from Maven)
   [here](https://developer.android.com/studio/command-line/aapt2).
   The downloaded jar file contained the `aapt2` executable.
   `bundletool` is used to work with App bundles, available from [it's
   GitHub repository](https://github.com/google/bundletool/releases).
   I downloaded `bundletool-all-0.10.0.jar`, which can be run with
   `java -jar path/to/above/bundletool.jar`.  Apart from these two the
   following steps need `javac` (the Java compiler), `jarsigner` (part
   of the JDK for me), `dx` (part of the Android SDK build tools; used
   to convert Java bytecode to Dalvik bytecode) and `zip`/`unzip`.

2. "Compile" all resources using `aapt2`:  Every resource file of the
   base module needs to be compiled:
   
   ~~~
   aapt2 compile project/app/src/main/res/**/* -o compiled_resources
   ~~~
   
   This fills the `compiled_resources` directory with files such as
   `layout_activity_main.xml.flat`.

3. "Link" the resources into a temporary APK, generating the `R.java`
   file along the way and converting the resources into protobuf
   format:
   
   ~~~
   aapt2 link --proto-format -o temporary.apk \
              -I android_sdk/platforms/android-NN/android.jar \
              --manifest project/app/src/main/AndroidManifest.xml \
              -R compiled_resources/*.flat \
              --auto-add-overlay --java gen
   ~~~
   
   This creates the `temporary.apk` which contains the resources and
   the manifest in protobuf (Google Protocol Buffers) format and also
   generates `R.java` (under `gen/my/package/R.java`) which is used by
   Java code to reference resources.  It needs to "include" (it
   doesn't really contain it, just cross-checks references) the
   `android.jar` for the target platform (part of the Android SDK).
   
4. Compile the Java source files.  Since `R.java` is now generated, I
   can compile the Java sources:
   
   ~~~
   javac -source 1.7 -target 1.7 \
         -bootclasspath $JAVA_HOME/jre/lib/rt.jar \
         -classpath android_sdk/platforms/android-NN/android.jar \
         -d classes \
         gen/**/*.java project/app/src/main/java/**/*.java
   ~~~
   
   This creates `.class` files in the `classes` directory.  Depending
   on dependencies the classpath needs to include other paths/jars.

5. Extract the previously generated temporary APK:

    ~~~
    unzip temporary.apk -d staging   
    ~~~
   
   An APK is nothing but a fancy zip file, so this puts all contents
   of the `temporary.apk` into the `staging` directory.

6. Prepare files to be bundled as the base module.  The end result is
   a `staging` directory which can be zipped as a base module.  First
   step is to move the `staging/AndroidManifest.xml` into
   `staging/manifest/` (a directory to be created).  Next I create
   `stating/dex/` and use `dx` to convert the Java bytecode (in the
   `.class` files) to Dalvik bytecode (suitable for running on
   Android):
   
   ~~~
   dx --dex --output=staging/dex/classes.dex classes/
   ~~~

7. Create a zip file of the contents of the base module:
   `(cd staging; zip -r ../base.zip *)`

8. Build the bundle: `bundletool build-bundle --modules=base.zip --output=bundle.aab`

9. Sign it: `jarsigner -keystore mykeystore.jks bundle.aab my-id`

Done :)
