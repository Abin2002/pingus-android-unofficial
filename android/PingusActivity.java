package org.pingus.game;

import android.os.Bundle;
import android.system.Os;
import android.view.Gravity;
import android.widget.TextView;

import java.io.File;
import java.io.FileNotFoundException;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.io.PrintWriter;
import java.io.StringWriter;
import java.text.SimpleDateFormat;
import java.util.Date;
import java.util.Locale;

import org.libsdl.app.SDLActivity;

/**
 * Launcher for the Pingus Android port (DEBUG build with startup logging).
 *
 * The game data ships inside the APK under assets/data (Pingus needs real
 * files, it cannot read directly from the APK), so on the first run it is
 * extracted to the app's private files dir. Afterwards the native game is
 * started with --datadir/--userdir pointing at the private storage.
 *
 * Debug log: /sdcard/Android/data/org.pingus.game/files/pingus-debug.log
 */
public class PingusActivity extends SDLActivity {

    private static final String DATA_VERSION = "0.7.6-1";

    private String mDataDir;
    private String mUserDir;
    private File mLogFile;

    private void dlog(String msg) {
        try {
            String ts = new SimpleDateFormat("HH:mm:ss.SSS", Locale.US).format(new Date());
            FileOutputStream out = new FileOutputStream(mLogFile, true);
            out.write((ts + " [java] " + msg + "\n").getBytes("UTF-8"));
            out.close();
        } catch (Exception ignored) {}
    }

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        File extDir = getExternalFilesDir(null);
        if (extDir == null) extDir = getFilesDir();
        mLogFile = new File(extDir, "pingus-debug.log");
        // fresh log per launch
        try { new FileOutputStream(mLogFile, false).close(); } catch (Exception ignored) {}

        final File logFile = mLogFile;
        Thread.setDefaultUncaughtExceptionHandler(new Thread.UncaughtExceptionHandler() {
            @Override
            public void uncaughtException(Thread t, Throwable e) {
                try {
                    StringWriter sw = new StringWriter();
                    e.printStackTrace(new PrintWriter(sw));
                    FileOutputStream out = new FileOutputStream(logFile, true);
                    out.write(("JAVA CRASH on thread " + t.getName() + ":\n" + sw.toString() + "\n").getBytes("UTF-8"));
                    out.close();
                } catch (Exception ignored) {}
            }
        });

        dlog("onCreate: entry BUILD=debug34, filesDir=" + getFilesDir().getAbsolutePath()
             + " extDir=" + extDir.getAbsolutePath());

        try {
            Os.setenv("PINGUS_DEBUG_LOG", mLogFile.getAbsolutePath(), true);
            dlog("onCreate: PINGUS_DEBUG_LOG=" + mLogFile.getAbsolutePath());
            // Try OpenSL ES for real audio (was dummy due to CFI crash with default driver)
            Os.setenv("SDL_AUDIODRIVER", "opensles", true);
            dlog("onCreate: SDL_AUDIODRIVER=opensles");
            // Ensure touches generate mouse events for the SDL 1.2 game
            Os.setenv("SDL_TOUCH_MOUSE_EVENTS", "1", true);
            dlog("onCreate: SDL_TOUCH_MOUSE_EVENTS=1");
            // Force landscape orientation (SDL2 overrides manifest)
            Os.setenv("SDL_ORIENTATIONS", "LandscapeLeft LandscapeRight", true);
            dlog("onCreate: SDL_ORIENTATIONS=landscape");


        } catch (Exception e) {
            dlog("onCreate: setenv failed: " + e);
        }

        String base = getFilesDir().getAbsolutePath() + "/pingus";
        mDataDir = base + "/data";
        mUserDir = base + "/user";

        File marker = new File(base + "/.extracted-" + DATA_VERSION);
        dlog("onCreate: marker exists=" + marker.exists());
        if (!marker.exists()) {
            TextView tv = null;
            try {
                tv = new TextView(this);
                tv.setText("Extracting Pingus game data...\n(first run only, please wait)");
                tv.setGravity(Gravity.CENTER);
                setContentView(tv);
            } catch (Exception e) {
                tv = null; // continue silently without the notice
            }

            try {
                dlog("extract: deleting old data dir");
                deleteRecursive(new File(mDataDir));
                dlog("extract: copying assets");
                long t0 = System.currentTimeMillis();
                int count = copyAssets("data", new File(mDataDir));
                dlog("extract: copied " + count + " files in "
                     + (System.currentTimeMillis() - t0) + "ms");
                new File(mUserDir).mkdirs();
                marker.getParentFile().mkdirs();
                marker.createNewFile();
                dlog("extract: marker written, done");
            } catch (IOException e) {
                dlog("extract FAILED: " + e);
                if (tv != null) {
                    tv.setText("Failed to extract game data:\n" + e.getMessage());
                }
                super.onCreate(savedInstanceState);
                finish();
                return;
            }
        } else {
            new File(mUserDir).mkdirs();
        }

        dlog("onCreate: calling super.onCreate (SDL init starts)");
        super.onCreate(savedInstanceState);
        dlog("onCreate: super.onCreate returned");
    }

    @Override
    protected String[] getLibraries() {
        return new String[] {
            "SDL2",
            "SDL2_image",
            "SDL2_mixer",
            "SDL",      // sdl12-compat, provides the SDL 1.2 API Pingus uses
            "main"      // libmain.so, the game itself
        };
    }

    @Override
    protected String[] getArguments() {
        dlog("getArguments: datadir=" + mDataDir + " userdir=" + mUserDir);
        return new String[] {
            "--datadir", mDataDir,
            "--userdir", mUserDir
        };
    }

    /** Copies assets, returns number of files copied. */
    private int copyAssets(String assetPath, File dest) throws IOException {
        String[] list = getAssets().list(assetPath);
        if (list != null && list.length > 0) {
            dest.mkdirs();
            int n = 0;
            for (String name : list) {
                n += copyAssets(assetPath + "/" + name, new File(dest, name));
            }
            return n;
        }
        // Either a file or an empty directory: try opening it as a file.
        InputStream in;
        try {
            in = getAssets().open(assetPath);
        } catch (FileNotFoundException e) {
            dest.mkdirs();
            return 0;
        }
        dest.getParentFile().mkdirs();
        OutputStream out = new FileOutputStream(dest);
        byte[] buf = new byte[65536];
        int n;
        while ((n = in.read(buf)) > 0) {
            out.write(buf, 0, n);
        }
        in.close();
        out.close();
        return 1;
    }

    private static void deleteRecursive(File f) {
        if (f.isDirectory()) {
            File[] kids = f.listFiles();
            if (kids != null) {
                for (File k : kids) deleteRecursive(k);
            }
        }
        f.delete();
    }

    @Override
    public void setOrientationBis(int w, int h, boolean resizable, String hint) {
        // Force landscape, ignore SDL2's orientation logic
        setRequestedOrientation(android.content.pm.ActivityInfo.SCREEN_ORIENTATION_SENSOR_LANDSCAPE);
    }

    @Override
    public void onWindowFocusChanged(boolean hasFocus) {
        super.onWindowFocusChanged(hasFocus);
        if (hasFocus) {
            hideKeyboard();
        }
    }

    @Override
    protected void onResume() {
        super.onResume();
        // Hide keyboard again after resume, with a delay to catch late shows
        getWindow().getDecorView().postDelayed(new Runnable() {
            @Override
            public void run() {
                hideKeyboard();
            }
        }, 500);
    }

    private void hideKeyboard() {
        // Hide the soft keyboard - the game doesn't need text input
        android.view.inputmethod.InputMethodManager imm =
            (android.view.inputmethod.InputMethodManager) getSystemService(INPUT_METHOD_SERVICE);
        if (imm != null) {
            imm.hideSoftInputFromWindow(getWindow().getDecorView().getWindowToken(), 0);
        }
        getWindow().setSoftInputMode(
            android.view.WindowManager.LayoutParams.SOFT_INPUT_STATE_ALWAYS_HIDDEN);
    }
}
